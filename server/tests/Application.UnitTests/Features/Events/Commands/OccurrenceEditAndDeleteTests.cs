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

        // ---- Round 2 of the review ------------------------------------------------------

        private static readonly DateTime Monday = new(2026, 9, 7, 10, 0, 0, DateTimeKind.Utc);
        private static readonly DateTime Wednesday = new(2026, 9, 9, 10, 0, 0, DateTimeKind.Utc);
        private static readonly DateTime Thursday = new(2026, 9, 10, 10, 0, 0, DateTimeKind.Utc);

        /// <summary>A day of <paramref name="series"/> with its own event.</summary>
        /// <param name="edited">Edited on its own, so its date is in the series' exception list.</param>
        private Event Day(Event series, DateTime slot, bool edited = false, string? googleEventId = null, string title = "Jogging")
        {
            var day = new Event
            {
                Id = Guid.NewGuid(),
                Title = title,
                StartTime = slot,
                EndTime = slot.AddHours(1),
                ParentEventId = series.Id,
                ExceptionDate = slot,
                UserId = UserId,
                HabitId = string.Empty,
                GoogleEventId = googleEventId,
                ReminderMinutesBefore = new List<int> { 30 }
            };
            if (edited) RecurrenceExceptions.Add(series, slot);

            _events.Setup(r => r.GetByIdAsync(day.Id)).ReturnsAsync(day);
            _events.Setup(r => r.GetOccurrenceChildAsync(series.Id, slot)).ReturnsAsync(day);
            return day;
        }

        private void ChildrenOf(Event series, params Event[] days) =>
            _events.Setup(r => r.GetChildrenAsync(series.Id)).ReturnsAsync(days.ToList());

        private static UpdateEventCommand Edit(
            Guid id, DateTime slot, DateTime newStart, string scope,
            TimeSpan? length = null, string title = "Jogging", List<int>? reminders = null) => new()
        {
            EventId = id,
            Title = title,
            StartTime = newStart,
            EndTime = newStart + (length ?? TimeSpan.FromHours(1)),
            HabitId = string.Empty,
            UserId = UserId,
            EditScope = scope,
            OriginalOccurrenceDate = slot,
            ReminderMinutesBefore = reminders
        };

        [Fact]
        public async Task AllOccurrences_TouchedDaysFollowTheSeries_EditedDaysKeepTheirOwn()
        {
            // Review round 1, finding 1 (HIGH): a day split off by a ticked task stayed a
            // frozen copy, so moving the series from 10:00 to 11:00 left it at 10:00 AND
            // un-hid the series' 11:00 day — the day showed twice, with two reminders.
            UserHasGoogle(false);
            var series = Series();
            var touchedFriday = Day(series, Friday);
            var touchedMonday = Day(series, Monday);
            var editedThursday = Day(series, Thursday, edited: true, title: "Moved by hand");
            editedThursday.StartTime = Thursday.AddHours(5);
            ChildrenOf(series, touchedFriday, touchedMonday, editedThursday);

            await UpdateHandler().Handle(
                Edit(series.Id, Wednesday, Wednesday.AddHours(1), "AllOccurrences",
                    length: TimeSpan.FromMinutes(90), title: "Jogging (renamed)"),
                CancellationToken.None);

            series.StartTime.Should().Be(Wednesday.AddHours(1));

            touchedFriday.StartTime.Should().Be(Friday.AddHours(1), "a touched day moves with its series");
            touchedFriday.ExceptionDate.Should().Be(Friday.AddHours(1), "so it still stands in for the series' day");
            touchedFriday.EndTime.Should().Be(Friday.AddHours(1).AddMinutes(90));
            touchedFriday.Title.Should().Be("Jogging (renamed)");

            editedThursday.StartTime.Should().Be(Thursday.AddHours(5), "an edited day keeps its own time");
            editedThursday.Title.Should().Be("Moved by hand");

            touchedMonday.StartTime.Should().Be(Monday,
                "the series now starts on Wednesday, so Monday is history, not a duplicate");
        }

        [Fact]
        public async Task ThisAndFuture_TouchedDaysAfterTheSplitMoveToTheNewSeries()
        {
            UserHasGoogle(false);
            var series = Series();
            var touchedFriday = Day(series, Friday);
            var touchedMonday = Day(series, Monday);
            ChildrenOf(series, touchedFriday, touchedMonday);

            await UpdateHandler().Handle(
                Edit(series.Id, Wednesday, Wednesday.AddHours(1), "ThisAndFuture"), CancellationToken.None);

            var newSeries = _added.Single();
            touchedFriday.ParentEventId.Should().Be(newSeries.Id,
                "left on the old series, which now ends before it, it would show next to the new series' day");
            touchedFriday.StartTime.Should().Be(Friday.AddHours(1));
            touchedMonday.ParentEventId.Should().Be(series.Id, "before the split it stays with the old series");
            touchedMonday.StartTime.Should().Be(Monday);
        }

        [Fact]
        public async Task AllOccurrences_FromAGoogleKnownDay_PushesThatDayToo()
        {
            // Review round 1, finding 3 (MEDIUM): only the series was pushed, so Google kept the
            // day at its old time while the series gained an instance on the same date.
            UserHasGoogle(true);
            var series = Series();
            var day = Day(series, Friday, edited: true, googleEventId: "g-day");
            ChildrenOf(series, day);

            await UpdateHandler().Handle(
                Edit(day.Id, Friday, Friday.AddHours(1), "AllOccurrences"), CancellationToken.None);

            series.RecurrenceExceptionDates.Should().Contain("2026-09-11T11:00:00Z",
                "the day's new slot must be dropped from the series in Google");
            _queued.Should().Contain(q => q.EventId == day.Id && q.Action == "Update");
            _queued.Should().Contain(q => q.EventId == series.Id && q.Action == "Update"
                && q.Payload.Contains("2026-09-11T11:00:00Z"));
        }

        [Fact]
        public async Task AllOccurrences_FromALocalOnlyDay_SendsNothingForTheDay()
        {
            UserHasGoogle(true);
            var series = Series();
            var day = Day(series, Friday);
            ChildrenOf(series, day);

            await UpdateHandler().Handle(
                Edit(day.Id, Friday, Friday.AddHours(1), "AllOccurrences"), CancellationToken.None);

            _queued.Should().NotContain(q => q.EventId == day.Id, "Google has never heard of this day");
            RecurrenceExceptions.Contains(series, Friday.AddHours(1)).Should().BeFalse("it is still only touched");
        }

        [Fact]
        public async Task EditThisOccurrence_GoogleConnected_DropsTheDayFromTheSeriesThenInsertsIt()
        {
            UserHasGoogle(true);
            var series = Series();

            await UpdateHandler().Handle(
                Edit(series.Id, Friday, Friday.AddHours(2), "ThisOccurrence"), CancellationToken.None);

            var created = _added.Single();
            _queued.Select(q => (q.EventId, q.Action)).Should().Equal(
                (series.Id, "Update"),
                (created.Id, "Insert"));
            _queued[0].Payload.Should().Contain("2026-09-11T10:00:00Z");
        }

        [Fact]
        public async Task EditThisOccurrence_OfADayGoogleHas_UpdatesItInsteadOfInsertingASecond()
        {
            UserHasGoogle(true);
            var series = Series();
            var day = Day(series, Friday, edited: true, googleEventId: "g-day");

            await UpdateHandler().Handle(
                Edit(series.Id, Friday, Friday.AddHours(2), "ThisOccurrence"), CancellationToken.None);

            _queued.Should().Contain(q => q.EventId == day.Id && q.Action == "Update");
            _queued.Should().NotContain(q => q.EventId == day.Id && q.Action == "Insert");
        }

        [Fact]
        public async Task EditThisOccurrence_WhileTheDaysInsertIsQueued_UpdatesIt()
        {
            UserHasGoogle(true);
            var series = Series();
            var day = Day(series, Friday, edited: true);
            _outbox.Setup(o => o.HasPendingInsertAsync(day.Id, It.IsAny<CancellationToken>())).ReturnsAsync(true);

            await UpdateHandler().Handle(
                Edit(series.Id, Friday, Friday.AddHours(2), "ThisOccurrence"), CancellationToken.None);

            _queued.Should().Contain(q => q.EventId == day.Id && q.Action == "Update");
            _queued.Should().NotContain(q => q.EventId == day.Id && q.Action == "Insert");
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task EditThisOccurrence_GivesTheDayItsOwnReminders(bool reminderSent)
        {
            UserHasGoogle(false);
            var series = Series();
            series.ReminderMinutesBefore = new List<int> { 30 };

            await UpdateHandler().Handle(
                Edit(series.Id, Friday, Friday, "ThisOccurrence", reminders: reminderSent ? new List<int> { 5 } : null),
                CancellationToken.None);

            _added.Single().ReminderMinutesBefore.Should().Equal(reminderSent ? new[] { 5 } : new[] { 30 });
            series.ReminderMinutesBefore.Should().Equal(30);
        }

        [Fact]
        public async Task DeletingADayGoogleHas_SendsOneDelete_AndNoSeriesUpdate()
        {
            UserHasGoogle(true);
            var series = Series();
            var day = Day(series, Friday, edited: true, googleEventId: "g-day");

            await DeleteHandler().Handle(new DeleteEventCommand(day.Id, UserId), CancellationToken.None);

            _queued.Should().ContainSingle()
                .Which.Should().Be((day.Id, "Delete", string.Empty));
        }
    }

    public class MaterializeOccurrenceCommandHandlerTests
    {
        private const string UserId = "user-1";
        private static readonly DateTime Friday = new(2026, 9, 11, 10, 0, 0, DateTimeKind.Utc);

        private readonly Mock<IEventRepository> _events = new();
        private readonly Mock<IEventTaskRepository> _tasks = new();

        private MaterializeOccurrenceCommandHandler Handler() => new(
            _events.Object,
            new OccurrenceMaterializer(_events.Object, _tasks.Object, new PassThroughUnitOfWork()));

        private Event SeriesOwnedBy(string owner)
        {
            var series = new Event
            {
                Id = Guid.NewGuid(),
                StartTime = Friday.AddDays(-30),
                EndTime = Friday.AddDays(-30).AddHours(1),
                RecurrenceRule = "RRULE:FREQ=DAILY",
                UserId = owner,
                HabitId = string.Empty
            };
            _events.Setup(r => r.GetByIdAsync(series.Id)).ReturnsAsync(series);
            _tasks.Setup(r => r.GetByEventIdAsync(series.Id)).ReturnsAsync(new List<EventTask>());
            return series;
        }

        [Fact]
        public async Task SplitsADayOffTheCallersOwnSeries()
        {
            var series = SeriesOwnedBy(UserId);

            var id = await Handler().Handle(new MaterializeOccurrenceCommand(series.Id, Friday, UserId), CancellationToken.None);

            id.Should().NotBeNull();
            _events.Verify(r => r.AddAsync(It.Is<Event>(e => e.ParentEventId == series.Id && e.UserId == UserId)), Times.Once);
        }

        [Fact]
        public async Task RefusesAnotherUsersSeries_WithoutWritingAnything()
        {
            var series = SeriesOwnedBy("someone-else");

            var id = await Handler().Handle(new MaterializeOccurrenceCommand(series.Id, Friday, UserId), CancellationToken.None);

            id.Should().BeNull();
            _events.Verify(r => r.AddAsync(It.IsAny<Event>()), Times.Never);
        }

        [Fact]
        public async Task ReturnsNothing_ForAMissingSeries()
        {
            var id = await Handler().Handle(new MaterializeOccurrenceCommand(Guid.NewGuid(), Friday, UserId), CancellationToken.None);

            id.Should().BeNull();
        }

        [Fact]
        public async Task Throws_WithoutAUser()
        {
            var act = () => Handler().Handle(new MaterializeOccurrenceCommand(Guid.NewGuid(), Friday, ""), CancellationToken.None);

            await act.Should().ThrowAsync<ArgumentException>();
        }
    }
}
