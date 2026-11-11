using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Application.Features.Assistant.Commands;
using HabitTracker.Application.Features.Assistant.Scheduling;
using HabitTracker.Application.Features.Events.Commands;
using HabitTracker.Application.Features.Habits.Commands;
using HabitTracker.Application.Tests.TestDoubles;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;
using Moq;
using Xunit;

namespace HabitTracker.Application.Tests.Features.Assistant
{
    public class AssistantProposalCommandsTests
    {
        private const string UserId = "user-1";

        private readonly InMemoryAssistantRepository _repository = new();
        private readonly Mock<ISender> _sender = new();
        private readonly Mock<IEventRepository> _events = new();
        private readonly FixedTimeProvider _clock = new(new DateTime(2026, 9, 28, 7, 0, 0, DateTimeKind.Utc));
        private readonly Guid _createdHabit = Guid.NewGuid();
        private readonly Guid _createdEvent = Guid.NewGuid();
        private readonly List<object> _sent = new();

        public AssistantProposalCommandsTests()
        {
            _sender.Setup(s => s.Send(It.IsAny<CreateHabitCommand>(), It.IsAny<CancellationToken>()))
                .Callback<IRequest<Guid?>, CancellationToken>((c, _) => _sent.Add(c))
                .ReturnsAsync(_createdHabit);
            _sender.Setup(s => s.Send(It.IsAny<CreateEventCommand>(), It.IsAny<CancellationToken>()))
                .Callback<IRequest<Guid?>, CancellationToken>((c, _) => _sent.Add(c))
                .ReturnsAsync(_createdEvent);
            _sender.Setup(s => s.Send(It.IsAny<DeleteEventCommand>(), It.IsAny<CancellationToken>()))
                .Callback<IRequest<bool>, CancellationToken>((c, _) => _sent.Add(c))
                .ReturnsAsync(true);
            _sender.Setup(s => s.Send(It.IsAny<DeleteHabitCommand>(), It.IsAny<CancellationToken>()))
                .Callback<IRequest<bool>, CancellationToken>((c, _) => _sent.Add(c))
                .ReturnsAsync(true);
            _events.Setup(r => r.GetEventsForUserAsync(UserId, It.IsAny<DateTime?>(), It.IsAny<DateTime?>()))
                .ReturnsAsync(new List<Event>());
        }

        private AssistantProposal Propose(Guid? habitId = null, string userId = UserId, string status = AssistantProposalStatus.Pending)
        {
            var plan = new ScheduleProposal(
                "Chạy bộ", 45, "05:00", new[] { 1, 2, 3, 4, 5, 6, 7 }, "2026-09-29", "RRULE:FREQ=DAILY",
                new[] { 15 }, habitId, habitId == null ? null : "Chạy bộ buổi sáng", null, Array.Empty<ScheduleConflict>());
            var proposal = new AssistantProposal { UserId = userId, ToolCallId = "c", PayloadJson = plan.ToJson(), Status = status };
            _repository.Proposals.Add(proposal);
            return proposal;
        }

        private ApplyAssistantProposalCommandHandler Apply =>
            new(_repository, _sender.Object, new PassThroughUnitOfWork(), _clock);

        private UndoAssistantProposalCommandHandler Undo =>
            new(_repository, _events.Object, _sender.Object, new PassThroughUnitOfWork(), _clock);

        // ── Apply ────────────────────────────────────────────────────────────────────────

        [Fact]
        public async Task Apply_ShouldCreateTheHabit_ThenItsRepeatingEvent_AtTheLocalTime()
        {
            var proposal = Propose();

            var result = await Apply.Handle(new ApplyAssistantProposalCommand(UserId, proposal.Id), CancellationToken.None);

            result.Outcome.Should().Be(ProposalActionOutcome.Done);
            var habit = _sent.OfType<CreateHabitCommand>().Single();
            habit.Name.Should().Be("Chạy bộ");
            habit.TargetDays.Should().Equal(1, 2, 3, 4, 5, 6, 7);
            habit.UserId.Should().Be(UserId);

            var ev = _sent.OfType<CreateEventCommand>().Single();
            ev.StartTime.Should().Be(new DateTime(2026, 9, 28, 22, 0, 0, DateTimeKind.Utc), "05:00 on the 29th, UTC+7");
            (ev.EndTime - ev.StartTime).Should().Be(TimeSpan.FromMinutes(45));
            ev.RecurrenceRule.Should().Be("RRULE:FREQ=DAILY");
            ev.HabitId.Should().Be(_createdHabit.ToString());
            ev.ReminderMinutesBefore.Should().Equal(15);
            ev.UserId.Should().Be(UserId);

            proposal.Status.Should().Be(AssistantProposalStatus.Applied);
            proposal.CreatedEventId.Should().Be(_createdEvent);
            proposal.CreatedHabitId.Should().Be(_createdHabit);
            result.Proposal!.Status.Should().Be(AssistantProposalStatus.Applied);
        }

        [Fact]
        public async Task Apply_ShouldUseAnExistingHabit_WithoutCreatingOne()
        {
            var existing = Guid.NewGuid();
            var proposal = Propose(existing);

            await Apply.Handle(new ApplyAssistantProposalCommand(UserId, proposal.Id), CancellationToken.None);

            _sent.OfType<CreateHabitCommand>().Should().BeEmpty();
            _sent.OfType<CreateEventCommand>().Single().HabitId.Should().Be(existing.ToString());
            proposal.CreatedHabitId.Should().BeNull("undo must not delete a habit it did not make");
        }

        [Fact]
        public async Task Apply_ShouldHappenOnce_ASecondTapFindsItAlreadyAdded()
        {
            var proposal = Propose();
            await Apply.Handle(new ApplyAssistantProposalCommand(UserId, proposal.Id), CancellationToken.None);

            var again = await Apply.Handle(new ApplyAssistantProposalCommand(UserId, proposal.Id), CancellationToken.None);

            again.Outcome.Should().Be(ProposalActionOutcome.AlreadyResolved);
            _sent.OfType<CreateEventCommand>().Should().ContainSingle();
        }

        [Fact]
        public async Task Apply_ShouldNotFindSomeoneElsesProposal()
        {
            var theirs = Propose(userId: "user-2");

            var result = await Apply.Handle(new ApplyAssistantProposalCommand(UserId, theirs.Id), CancellationToken.None);

            result.Outcome.Should().Be(ProposalActionOutcome.NotFound);
            _sent.Should().BeEmpty();
        }

        [Fact]
        public async Task Apply_ShouldLeaveTheProposalPending_WhenTheEventIsRefused()
        {
            _sender.Setup(s => s.Send(It.IsAny<CreateEventCommand>(), It.IsAny<CancellationToken>())).ReturnsAsync((Guid?)null);
            var proposal = Propose();

            var result = await Apply.Handle(new ApplyAssistantProposalCommand(UserId, proposal.Id), CancellationToken.None);

            result.Outcome.Should().Be(ProposalActionOutcome.Refused);
            proposal.Status.Should().Be(AssistantProposalStatus.Pending);
            proposal.CreatedHabitId.Should().BeNull();
        }

        [Fact]
        public async Task Apply_ShouldRollBackTheNewHabit_WhenTheEventIsRefused()
        {
            // The unit of work rolls back only on an exception; returning would commit the habit.
            _sender.Setup(s => s.Send(It.IsAny<CreateEventCommand>(), It.IsAny<CancellationToken>())).ReturnsAsync((Guid?)null);
            var unitOfWork = new RecordingUnitOfWork();
            var proposal = Propose();

            await new ApplyAssistantProposalCommandHandler(_repository, _sender.Object, unitOfWork, _clock)
                .Handle(new ApplyAssistantProposalCommand(UserId, proposal.Id), CancellationToken.None);

            unitOfWork.RolledBack.Should().BeTrue();
        }

        // ── Dismiss ──────────────────────────────────────────────────────────────────────

        [Fact]
        public async Task Dismiss_ShouldCloseAPendingProposal_WithoutWritingAnything()
        {
            var proposal = Propose();

            var result = await new DismissAssistantProposalCommandHandler(_repository, _clock)
                .Handle(new DismissAssistantProposalCommand(UserId, proposal.Id), CancellationToken.None);

            result.Outcome.Should().Be(ProposalActionOutcome.Done);
            proposal.Status.Should().Be(AssistantProposalStatus.Dismissed);
            _sent.Should().BeEmpty();
        }

        // ── Undo ─────────────────────────────────────────────────────────────────────────

        [Fact]
        public async Task Undo_ShouldDeleteTheWholeSeries_AndTheHabitItCreated()
        {
            var proposal = Propose();
            await Apply.Handle(new ApplyAssistantProposalCommand(UserId, proposal.Id), CancellationToken.None);
            _sent.Clear();

            var result = await Undo.Handle(new UndoAssistantProposalCommand(UserId, proposal.Id), CancellationToken.None);

            result.Outcome.Should().Be(ProposalActionOutcome.Done);
            var delete = _sent.OfType<DeleteEventCommand>().Single();
            delete.EventId.Should().Be(_createdEvent);
            delete.DeleteScope.Should().Be("AllOccurrences");
            _sent.OfType<DeleteHabitCommand>().Single().Id.Should().Be(_createdHabit);
            proposal.Status.Should().Be(AssistantProposalStatus.Undone);
        }

        [Fact]
        public async Task Undo_ShouldRefuse_OnceADayOfTheEventHoldsTheUsersOwnState()
        {
            var proposal = Propose();
            await Apply.Handle(new ApplyAssistantProposalCommand(UserId, proposal.Id), CancellationToken.None);
            _events.Setup(r => r.GetEventsForUserAsync(UserId, It.IsAny<DateTime?>(), It.IsAny<DateTime?>()))
                .ReturnsAsync(new List<Event> { new() { ParentEventId = _createdEvent, IsCompleted = true } });
            _sent.Clear();

            var result = await Undo.Handle(new UndoAssistantProposalCommand(UserId, proposal.Id), CancellationToken.None);

            result.Outcome.Should().Be(ProposalActionOutcome.HasActivity);
            _sent.Should().BeEmpty();
            proposal.Status.Should().Be(AssistantProposalStatus.Applied);
        }

        [Fact]
        public async Task Undo_ShouldOnlyTakeBackSomethingThatWasAdded()
        {
            var proposal = Propose();

            var result = await Undo.Handle(new UndoAssistantProposalCommand(UserId, proposal.Id), CancellationToken.None);

            result.Outcome.Should().Be(ProposalActionOutcome.AlreadyResolved);
            _sent.Should().BeEmpty();
        }

        private sealed class RecordingUnitOfWork : IUnitOfWork
        {
            public bool RolledBack { get; private set; }

            public async Task<T> ExecuteInTransactionAsync<T>(Func<Task<T>> operation, CancellationToken cancellationToken = default)
            {
                try
                {
                    return await operation();
                }
                catch
                {
                    RolledBack = true;
                    throw;
                }
            }
        }
    }
}
