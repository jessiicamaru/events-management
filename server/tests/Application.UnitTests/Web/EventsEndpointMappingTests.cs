using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Application.Features.Events.Commands;
using HabitTracker.Web.Endpoints.V1;
using MediatR;
using Moq;
using Xunit;

namespace HabitTracker.Application.Tests.Web
{
    /// <summary>
    /// The endpoints copy a request record into a command by hand. That copy is where
    /// reminder edits were lost: <c>UpdateEventCommand</c> had the field and handled it, the
    /// client sent it, and <c>UpdateEventRequest</c> simply did not have it — so the value
    /// was dropped between two correct, tested pieces. These tests sit exactly there.
    /// </summary>
    public class EventsEndpointMappingTests
    {
        private static ClaimsPrincipal SignedIn(string userId) =>
            new(new ClaimsIdentity(new[] { new Claim(ClaimTypes.NameIdentifier, userId) }, "test"));

        /// <summary>
        /// Every value a client may set on the command must be receivable in the request.
        /// Fails the moment a command gains a field its request record lacks.
        /// </summary>
        [Theory]
        [InlineData(typeof(UpdateEventCommand), typeof(UpdateEventRequest))]
        [InlineData(typeof(CompleteEventSessionCommand), typeof(CompleteEventSessionRequest))]
        public void TheRequestCarriesEveryFieldTheCommandTakesFromTheClient(Type command, Type request)
        {
            // Set from the route or the token, never from the body.
            var serverOwned = new[] { "EventId", "UserId" };

            var commandFields = command.GetProperties()
                .Where(p => p.CanWrite && !serverOwned.Contains(p.Name))
                .Select(p => p.Name);
            var requestFields = request.GetProperties().Select(p => p.Name);

            commandFields.Should().BeSubsetOf(requestFields,
                $"{request.Name} must be able to carry everything {command.Name} accepts");
        }

        [Fact]
        public async Task UpdateEvent_PassesEveryFieldThrough()
        {
            UpdateEventCommand? sent = null;
            var sender = new Mock<ISender>();
            sender.Setup(s => s.Send(It.IsAny<UpdateEventCommand>(), It.IsAny<CancellationToken>()))
                .Callback<IRequest<bool>, CancellationToken>((c, _) => sent = (UpdateEventCommand)c)
                .ReturnsAsync(true);

            var id = Guid.NewGuid();
            var categoryId = Guid.NewGuid();
            var start = new DateTime(2026, 9, 11, 10, 0, 0, DateTimeKind.Utc);
            var request = new UpdateEventRequest(
                "Jogging", start, start.AddHours(1), "habit-1", categoryId, TimeSpan.FromMinutes(45),
                EditScope: "ThisOccurrence",
                OriginalOccurrenceDate: start,
                RecurrenceRule: "RRULE:FREQ=DAILY",
                ReminderMinutesBefore: new List<int> { 15, 5 });

            await new Events().UpdateEvent(sender.Object, id, request, SignedIn("user-1"));

            sent.Should().NotBeNull();
            sent!.EventId.Should().Be(id);
            sent.UserId.Should().Be("user-1", "the user comes from the token");
            sent.Title.Should().Be("Jogging");
            sent.StartTime.Should().Be(start);
            sent.EndTime.Should().Be(start.AddHours(1));
            sent.HabitId.Should().Be("habit-1");
            sent.CategoryId.Should().Be(categoryId);
            sent.TargetDuration.Should().Be(TimeSpan.FromMinutes(45));
            sent.EditScope.Should().Be("ThisOccurrence");
            sent.OriginalOccurrenceDate.Should().Be(start);
            sent.RecurrenceRule.Should().Be("RRULE:FREQ=DAILY");
            sent.ReminderMinutesBefore.Should().Equal(15, 5);
        }

        [Fact]
        public async Task CompleteSession_PassesTheDayThrough()
        {
            CompleteEventSessionCommand? sent = null;
            var sender = new Mock<ISender>();
            sender.Setup(s => s.Send(It.IsAny<CompleteEventSessionCommand>(), It.IsAny<CancellationToken>()))
                .Callback<IRequest<bool>, CancellationToken>((c, _) => sent = (CompleteEventSessionCommand)c)
                .ReturnsAsync(true);

            var id = Guid.NewGuid();
            var day = new DateTime(2026, 9, 11, 10, 0, 0, DateTimeKind.Utc);

            await new Events().CompleteSession(
                sender.Object, id,
                new CompleteEventSessionRequest(TimeSpan.FromMinutes(25), UpdateCalendar: true, OccurrenceStart: day),
                SignedIn("user-1"));

            sent.Should().NotBeNull();
            sent!.EventId.Should().Be(id);
            sent.UserId.Should().Be("user-1");
            sent.ActualDuration.Should().Be(TimeSpan.FromMinutes(25));
            sent.UpdateCalendar.Should().BeTrue();
            sent.OccurrenceStart.Should().Be(day);
        }
    }
}
