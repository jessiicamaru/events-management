using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Application.Common;
using HabitTracker.Application.Features.Events.Commands;
using HabitTracker.Application.Tests.TestDoubles;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using Moq;
using Xunit;

namespace HabitTracker.Application.Tests.Features.Events.Commands
{
    /// <summary>
    /// Edits and deletes that touch one day of a repeating series — the day either still
    /// part of the series, or already split off into its own event.
    /// </summary>
    public class OccurrenceEditAndDeleteTests
    {
        private const string UserId = "user-1";

        private static readonly DateTime SeriesStart = new(2026, 5, 4, 10, 0, 0, DateTimeKind.Utc);
        private static readonly DateTime Friday = new(2026, 9, 11, 10, 0, 0, DateTimeKind.Utc);

        private readonly Mock<IEventRepository> _events = new();
        private readonly Mock<IEventTaskRepository> _tasks = new();
        private readonly Mock<IUserRepository> _users = new();
        private readonly Mock<IGoogleCalendarOutboxRepository> _outbox = new();
        private readonly List<Event> _added = new();
        private readonly List<(Guid EventId, string Action, string Payload)> _queued = new();

        public OccurrenceEditAndDeleteTests()
        {
            _events.Setup(r => r.AddAsync(It.IsAny<Event>()))
                .Callback<Event>(_added.Add)
                .Returns(Task.CompletedTask);
            _tasks.Setup(r => r.GetByEventIdAsync(It.IsAny<Guid>()))
                .ReturnsAsync(new List<EventTask>());
            _outbox.Setup(r => r.EnqueueAsync(
                    It.IsAny<string>(), It.IsAny<Guid>(), It.IsAny<string?>(), It.IsAny<string>(),
                    It.IsAny<string>(), It.IsAny<CancellationToken>()))
                .Callback<string, Guid, string?, string, string, CancellationToken>(
                    (_, id, _, action, payload, _) => _queued.Add((id, action, payload)))
                .Returns(Task.CompletedTask);
        }

        private void UserHasGoogle(bool connected) =>
            _users.Setup(r => r.GetByIdAsync(UserId)).ReturnsAsync(
                new ApplicationUser { Id = UserId, GoogleRefreshToken = connected ? "token" : null });

        private Event Series()
        {
            var series = new Event
            {
                Id = Guid.NewGuid(),
                Title = "Jogging",
                StartTime = SeriesStart,
                EndTime = SeriesStart.AddHours(1),
                RecurrenceRule = "RRULE:FREQ=DAILY",
                UserId = UserId,
                HabitId = string.Empty,
                GoogleEventId = "google-series"
            };
            _events.Setup(r => r.GetByIdAsync(series.Id)).ReturnsAsync(series);
            return series;
        }

        /// <summary>A day split off locally, by a ticked task or a finished session.</summary>
        private Event LocalOnlyDay(Event series)
        {
            var day = new Event
            {
                Id = Guid.NewGuid(),
                Title = series.Title,
                StartTime = Friday,
                EndTime = Friday.AddHours(1),
                ParentEventId = series.Id,
                ExceptionDate = Friday,
                UserId = UserId,
                HabitId = string.Empty
            };
            _events.Setup(r => r.GetByIdAsync(day.Id)).ReturnsAsync(day);
            _events.Setup(r => r.GetOccurrenceChildAsync(series.Id, Friday)).ReturnsAsync(day);
            return day;
        }

        private UpdateEventCommandHandler UpdateHandler() => new(
            _events.Object, _users.Object, _outbox.Object,
            new OccurrenceMaterializer(_events.Object, _tasks.Object, new PassThroughUnitOfWork()));

        private DeleteEventCommandHandler DeleteHandler() => new(
            _events.Object, _users.Object, _outbox.Object);

        private static UpdateEventCommand MoveTo(Guid id, DateTime start, string? scope) => new()
        {
            EventId = id,
            Title = "Jogging",
            StartTime = start,
            EndTime = start.AddHours(1),
            HabitId = string.Empty,
            UserId = UserId,
            EditScope = scope,
            OriginalOccurrenceDate = Friday
        };

        [Fact]
        public async Task EditThisOccurrence_ReusesADaySplitOffEarlier_InsteadOfAddingASecond()
        {
            UserHasGoogle(false);
            var series = Series();
            var day = LocalOnlyDay(series);

            var ok = await UpdateHandler().Handle(MoveTo(series.Id, Friday.AddHours(1), "ThisOccurrence"), CancellationToken.None);

            ok.Should().BeTrue();
            _added.Should().BeEmpty("the day already has its own event");
            day.StartTime.Should().Be(Friday.AddHours(1));
            series.RecurrenceExceptionDates.Should().Contain("2026-09-11T10:00:00Z");
        }

        [Fact]
        public async Task EditThisOccurrence_BringsTheSeriesTasksToTheNewDay()
        {
            UserHasGoogle(false);
            var series = Series();
            var copied = new List<EventTask>();
            _tasks.Setup(r => r.GetByEventIdAsync(series.Id)).ReturnsAsync(new List<EventTask>
            {
                new() { Id = Guid.NewGuid(), EventId = series.Id, Title = "Warm up", Order = 0 }
            });
            _tasks.Setup(r => r.AddAsync(It.IsAny<EventTask>()))
                .Callback<EventTask>(copied.Add)
                .Returns(Task.CompletedTask);

            await UpdateHandler().Handle(MoveTo(series.Id, Friday.AddHours(1), "ThisOccurrence"), CancellationToken.None);

            // Before, an edited day started with no tasks at all.
            copied.Select(t => t.Title).Should().Equal("Warm up");
            copied.Single().EventId.Should().Be(_added.Single().Id);
        }

        [Fact]
        public async Task EditingALocalOnlyDay_SendsItToGoogle_AsAnEditedOccurrence()
        {
            // Ticking a task split the day off without telling Google. Moving it is a real
            // edit, so from now on Google gets it like any edited occurrence.
            UserHasGoogle(true);
            var series = Series();
            var day = LocalOnlyDay(series);

            await UpdateHandler().Handle(MoveTo(day.Id, Friday.AddHours(2), "ThisOccurrence"), CancellationToken.None);

            series.RecurrenceExceptionDates.Should().Contain("2026-09-11T10:00:00Z");
            _queued.Should().Contain(q => q.EventId == series.Id && q.Action == "Update");
            _queued.Should().Contain(q => q.EventId == day.Id && q.Action == "Insert");
            _queued.Should().NotContain(q => q.EventId == day.Id && q.Action == "Update",
                "Google has no id for this day, so an Update could never succeed");
        }

        [Fact]
        public async Task AllOccurrences_FromASplitOffDay_ChangesTheSeries_AndTheDayFollows()
        {
            // Before, "all occurrences" on such a day changed that one row only.
            UserHasGoogle(false);
            var series = Series();
            var day = LocalOnlyDay(series);
            var newStart = Friday.AddHours(1);

            await UpdateHandler().Handle(MoveTo(day.Id, newStart, "AllOccurrences"), CancellationToken.None);

            series.StartTime.Should().Be(newStart);
            day.StartTime.Should().Be(newStart);
            day.ExceptionDate.Should().Be(newStart, "so it still stands in for the series' day");
            day.ParentEventId.Should().Be(series.Id);
        }

        [Fact]
        public async Task ThisAndFuture_FromASplitOffDay_MovesTheDayToTheNewSeries()
        {
            UserHasGoogle(false);
            var series = Series();
            var day = LocalOnlyDay(series);

            await UpdateHandler().Handle(MoveTo(day.Id, Friday.AddHours(1), "ThisAndFuture"), CancellationToken.None);

            var newSeries = _added.Single();
            series.RecurrenceRule.Should().Contain("UNTIL=");
            day.ParentEventId.Should().Be(newSeries.Id);
            day.ExceptionDate.Should().Be(newSeries.StartTime);
        }

        [Fact]
        public async Task DeletingASplitOffDay_KeepsTheSeriesDayFromComingBack()
        {
            UserHasGoogle(true);
            var series = Series();
            var day = LocalOnlyDay(series);

            var ok = await DeleteHandler().Handle(new DeleteEventCommand(day.Id, UserId), CancellationToken.None);

            ok.Should().BeTrue();
            _events.Verify(r => r.DeleteAsync(day.Id), Times.Once);
            _events.Verify(r => r.DeleteAsync(series.Id), Times.Never);
            series.RecurrenceExceptionDates.Should().Contain("2026-09-11T10:00:00Z");

            // Google only knows the series, so the day is cancelled through its EXDATEs.
            _queued.Should().ContainSingle(q => q.EventId == series.Id && q.Action == "Update")
                .Which.Payload.Should().Contain("2026-09-11T10:00:00Z");
        }

        [Fact]
        public async Task DeletingAllOccurrences_FromASplitOffDay_DeletesTheSeries()
        {
            UserHasGoogle(false);
            var series = Series();
            var day = LocalOnlyDay(series);
            _events.Setup(r => r.GetEventsForUserAsync(UserId, null, null))
                .ReturnsAsync(new List<Event> { series, day });

            await DeleteHandler().Handle(new DeleteEventCommand(day.Id, UserId, "AllOccurrences"), CancellationToken.None);

            _events.Verify(r => r.DeleteAsync(series.Id), Times.Once);
            _events.Verify(r => r.DeleteAsync(day.Id), Times.Once);
        }
    }
}
