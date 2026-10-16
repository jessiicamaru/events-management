using HabitTracker.Application.Features.Assistant.Queries;
using HabitTracker.Application.Features.Assistant.Scheduling;
using HabitTracker.Application.Common;
using HabitTracker.Application.Features.Events.Commands;
using HabitTracker.Application.Features.Habits.Commands;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Assistant.Commands
{
    public enum ProposalActionOutcome
    {
        Done,

        /// <summary>No such proposal for this user.</summary>
        NotFound,

        /// <summary>Already added, dismissed or undone — the card is out of date.</summary>
        AlreadyResolved,

        /// <summary>Undo refused: a day of the created event already holds the user's own state.</summary>
        HasActivity,

        /// <summary>The event could not be created, e.g. its category is no longer the user's.</summary>
        Refused,
    }

    public sealed record ProposalActionResult(ProposalActionOutcome Outcome, AssistantProposalDto? Proposal = null);

    /// <summary>
    /// The user tapped "Add to calendar": creates what the proposal describes — a new habit if
    /// it names none, then its repeating event — through the app's own commands, so the event
    /// is validated, gets its habit's tasks, and reaches Google like any other.
    /// </summary>
    public record ApplyAssistantProposalCommand(string UserId, Guid ProposalId) : IRequest<ProposalActionResult>;

    public class ApplyAssistantProposalCommandHandler : IRequestHandler<ApplyAssistantProposalCommand, ProposalActionResult>
    {
        private readonly IAssistantRepository _repository;
        private readonly ISender _sender;
        private readonly IUnitOfWork _unitOfWork;
        private readonly TimeProvider _clock;

        public ApplyAssistantProposalCommandHandler(IAssistantRepository repository, ISender sender, IUnitOfWork unitOfWork, TimeProvider clock)
        {
            _repository = repository;
            _sender = sender;
            _unitOfWork = unitOfWork;
            _clock = clock;
        }

        public async Task<ProposalActionResult> Handle(ApplyAssistantProposalCommand request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrEmpty(request.UserId)) throw new ArgumentException("UserId is required.", nameof(request));

            var proposal = await _repository.GetProposalAsync(request.ProposalId, request.UserId);
            if (proposal == null) return new(ProposalActionOutcome.NotFound);
            if (proposal.Status != AssistantProposalStatus.Pending) return new(ProposalActionOutcome.AlreadyResolved, AssistantProposalDto.From(proposal));

            var plan = ScheduleProposal.FromJson(proposal.PayloadJson);
            var start = SchedulePlanner.ToUtc(plan.First, plan.Start, StreakCalculator.DefaultDayBoundaryOffset);
            var duration = TimeSpan.FromMinutes(plan.DurationMinutes);

            try
            {
                await _unitOfWork.ExecuteInTransactionAsync(
                    () => CreateAsync(proposal, plan, start, duration, request.UserId, cancellationToken),
                    cancellationToken);
            }
            catch (ApplyRefused)
            {
                return new(ProposalActionOutcome.Refused);
            }

            return new(ProposalActionOutcome.Done, AssistantProposalDto.From(proposal));
        }

        private async Task<bool> CreateAsync(
            AssistantProposal proposal, ScheduleProposal plan, DateTime start, TimeSpan duration,
            string userId, CancellationToken cancellationToken)
        {
            var habitId = plan.HabitId;
            Guid? createdHabitId = null;
            if (habitId == null)
            {
                habitId = createdHabitId = await _sender.Send(new CreateHabitCommand
                {
                    Name = plan.Title,
                    TargetDays = plan.Days.ToList(),
                    CategoryId = plan.CategoryId,
                    UserId = userId,
                }, cancellationToken);
                if (habitId == null) throw new ApplyRefused();
            }

            var eventId = await _sender.Send(new CreateEventCommand
            {
                Title = plan.Title,
                StartTime = start,
                EndTime = start + duration,
                HabitId = habitId.Value.ToString(),
                TargetDuration = duration,
                CategoryId = plan.CategoryId,
                RecurrenceRule = plan.RecurrenceRule,
                ReminderMinutesBefore = plan.Reminders.ToList(),
                UserId = userId,
            }, cancellationToken);

            // Thrown, not returned: the unit of work commits whatever the operation returns and
            // rolls back only on an exception, so a refused event must not leave its new habit
            // behind. The proposal is only touched once both exist.
            if (eventId == null) throw new ApplyRefused();

            proposal.CreatedHabitId = createdHabitId;
            proposal.CreatedEventId = eventId;
            proposal.Status = AssistantProposalStatus.Applied;
            proposal.ResolvedAt = _clock.GetUtcNow().UtcDateTime;
            await _repository.UpdateProposalAsync(proposal);
            return true;
        }

        /// <summary>A command refused part of the apply; unwinds the transaction.</summary>
        private sealed class ApplyRefused : Exception { }
    }

    /// <summary>The user tapped "Dismiss" on a proposal they do not want.</summary>
    public record DismissAssistantProposalCommand(string UserId, Guid ProposalId) : IRequest<ProposalActionResult>;

    public class DismissAssistantProposalCommandHandler : IRequestHandler<DismissAssistantProposalCommand, ProposalActionResult>
    {
        private readonly IAssistantRepository _repository;
        private readonly TimeProvider _clock;

        public DismissAssistantProposalCommandHandler(IAssistantRepository repository, TimeProvider clock)
        {
            _repository = repository;
            _clock = clock;
        }

        public async Task<ProposalActionResult> Handle(DismissAssistantProposalCommand request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrEmpty(request.UserId)) throw new ArgumentException("UserId is required.", nameof(request));

            var proposal = await _repository.GetProposalAsync(request.ProposalId, request.UserId);
            if (proposal == null) return new(ProposalActionOutcome.NotFound);
            if (proposal.Status != AssistantProposalStatus.Pending) return new(ProposalActionOutcome.AlreadyResolved, AssistantProposalDto.From(proposal));

            proposal.Status = AssistantProposalStatus.Dismissed;
            proposal.ResolvedAt = _clock.GetUtcNow().UtcDateTime;
            await _repository.UpdateProposalAsync(proposal);
            return new(ProposalActionOutcome.Done, AssistantProposalDto.From(proposal));
        }
    }

    /// <summary>
    /// Takes back an added proposal: deletes the event it created, and the habit if it made one.
    /// </summary>
    /// <remarks>
    /// Refused once any day of that event holds the user's own state — a ticked task, a
    /// finished session, an edit — because deleting the series takes those days with it.
    /// Deleting from the calendar remains possible; undo just will not do it silently.
    /// </remarks>
    public record UndoAssistantProposalCommand(string UserId, Guid ProposalId) : IRequest<ProposalActionResult>;

    public class UndoAssistantProposalCommandHandler : IRequestHandler<UndoAssistantProposalCommand, ProposalActionResult>
    {
        private const string AllOccurrences = "AllOccurrences";

        private readonly IAssistantRepository _repository;
        private readonly IEventRepository _events;
        private readonly ISender _sender;
        private readonly IUnitOfWork _unitOfWork;
        private readonly TimeProvider _clock;

        public UndoAssistantProposalCommandHandler(
            IAssistantRepository repository, IEventRepository events, ISender sender, IUnitOfWork unitOfWork, TimeProvider clock)
        {
            _repository = repository;
            _events = events;
            _sender = sender;
            _unitOfWork = unitOfWork;
            _clock = clock;
        }

        public async Task<ProposalActionResult> Handle(UndoAssistantProposalCommand request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrEmpty(request.UserId)) throw new ArgumentException("UserId is required.", nameof(request));

            var proposal = await _repository.GetProposalAsync(request.ProposalId, request.UserId);
            if (proposal == null) return new(ProposalActionOutcome.NotFound);
            if (proposal.Status != AssistantProposalStatus.Applied) return new(ProposalActionOutcome.AlreadyResolved, AssistantProposalDto.From(proposal));

            if (proposal.CreatedEventId is { } eventId)
            {
                var now = _clock.GetUtcNow().UtcDateTime;
                // Split-off days come back with any range: GetEventsForUserAsync returns every child row.
                var days = await _events.GetEventsForUserAsync(request.UserId, now, now);
                if (days.Any(e => e.ParentEventId == eventId)) return new(ProposalActionOutcome.HasActivity, AssistantProposalDto.From(proposal));
            }

            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                // Already deleted from the calendar counts as undone: false here just means "gone".
                if (proposal.CreatedEventId is { } createdEvent)
                {
                    await _sender.Send(new DeleteEventCommand(createdEvent, request.UserId, AllOccurrences), cancellationToken);
                }
                if (proposal.CreatedHabitId is { } createdHabit)
                {
                    await _sender.Send(new DeleteHabitCommand { Id = createdHabit, UserId = request.UserId }, cancellationToken);
                }

                proposal.Status = AssistantProposalStatus.Undone;
                proposal.ResolvedAt = _clock.GetUtcNow().UtcDateTime;
                await _repository.UpdateProposalAsync(proposal);
                return true;
            }, cancellationToken);

            return new(ProposalActionOutcome.Done, AssistantProposalDto.From(proposal));
        }
    }
}
