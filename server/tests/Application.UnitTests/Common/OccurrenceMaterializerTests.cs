using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Application.Common;
using HabitTracker.Application.Features.Events.Commands;
using HabitTracker.Application.Tests.TestDoubles;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using Moq;
using Xunit;

namespace HabitTracker.Application.Tests.Common
{
    public class OccurrenceMaterializerTests
    {
        private readonly Mock<IEventRepository> _events = new();
        private readonly Mock<IEventTaskRepository> _tasks = new();
        private readonly List<Event> _addedEvents = new();
        private readonly List<EventTask> _addedTasks = new();
        private readonly OccurrenceMaterializer _materializer;

        private static readonly DateTime SeriesStart = new(2026, 5, 4, 10, 0, 0, DateTimeKind.Utc);
        private static readonly DateTime Friday = new(2026, 9, 11, 10, 0, 0, DateTimeKind.Utc);

        public OccurrenceMaterializerTests()
        {
            _events.Setup(r => r.TryAddOccurrenceDayAsync(It.IsAny<Event>()))
                .Callback<Event>(_addedEvents.Add)
                .ReturnsAsync(true);
            _tasks.Setup(r => r.AddAsync(It.IsAny<EventTask>()))
                .Callback<EventTask>(_addedTasks.Add)
                .Returns(Task.CompletedTask);
            _tasks.Setup(r => r.GetByEventIdAsync(It.IsAny<Guid>()))
                .ReturnsAsync(new List<EventTask>());

            _materializer = new OccurrenceMaterializer(_events.Object, _tasks.Object, new PassThroughUnitOfWork());
        }

        private static Event Series(string rule = "RRULE:FREQ=DAILY", string? exceptionDates = null) => new()
        {
            Id = Guid.NewGuid(),
            Title = "Jogging",
            StartTime = SeriesStart,
            EndTime = SeriesStart.AddHours(1),
            RecurrenceRule = rule,
            RecurrenceExceptionDates = exceptionDates,
            HabitId = "habit-1",
            UserId = "user-1",
            TargetDuration = TimeSpan.FromHours(1),
            ReminderMinutesBefore = new List<int> { 30, 5 },
            IsCompleted = true // a legacy completed series must not leak into the day
        };

        [Fact]
        public async Task CreatesAChildForThatDay_CopyingTheSeriesFields()
        {
            var series = Series();

            var day = await _materializer.FindOrCreateAsync(series, Friday);

            day.Should().NotBeNull();
            day!.ParentEventId.Should().Be(series.Id);
            day.ExceptionDate.Should().Be(Friday);
            day.StartTime.Should().Be(Friday);
            day.EndTime.Should().Be(Friday.AddHours(1));
            day.RecurrenceRule.Should().BeNull("a day of a series is not a series itself");
            day.GoogleEventId.Should().BeNull("it is local only");
            day.IsCompleted.Should().BeFalse();
            day.HabitId.Should().Be("habit-1");
            day.ReminderMinutesBefore.Should().Equal(30, 5);
            day.ReminderMinutesBefore.Should().NotBeSameAs(series.ReminderMinutesBefore);
        }

        [Fact]
        public async Task CopiesTheSeriesTasks_AllUnticked_InOrder()
        {
            // The series' tasks are the template for each day. A tick on the template —
            // from before this rule existed — must not carry into a new day.
            var series = Series();
            _tasks.Setup(r => r.GetByEventIdAsync(series.Id)).ReturnsAsync(new List<EventTask>
            {
                new() { Id = Guid.NewGuid(), EventId = series.Id, Title = "Run 5 km", Order = 1, IsCompleted = true, Priority = Priority.High, EstimatedMinutes = 35 },
                new() { Id = Guid.NewGuid(), EventId = series.Id, Title = "Warm up", Order = 0, IsCompleted = true, Description = "5 min" }
            });

            var day = await _materializer.FindOrCreateAsync(series, Friday);

            _addedTasks.Select(t => t.Title).Should().Equal("Warm up", "Run 5 km");
            _addedTasks.Should().OnlyContain(t => t.EventId == day!.Id);
            _addedTasks.Should().OnlyContain(t => !t.IsCompleted);
            _addedTasks[0].Description.Should().Be("5 min");
            _addedTasks[1].Priority.Should().Be(Priority.High);
            _addedTasks[1].EstimatedMinutes.Should().Be(35);
        }

        [Fact]
        public async Task ReturnsTheExistingChild_InsteadOfAddingASecond()
        {
            var series = Series();
            var existing = new Event { Id = Guid.NewGuid(), ParentEventId = series.Id, ExceptionDate = Friday };
            _events.Setup(r => r.GetOccurrenceChildAsync(series.Id, Friday)).ReturnsAsync(existing);

            var day = await _materializer.FindOrCreateAsync(series, Friday);

            day.Should().BeSameAs(existing);
            _addedEvents.Should().BeEmpty();
            _addedTasks.Should().BeEmpty();
        }

        [Fact]
        public async Task LosingARaceForTheDay_ReturnsTheWinnersChild_AndCopiesNoTasks()
        {
            // Two requests for the same day both pass the lookup; the database takes one
            // insert and refuses the other. The loser must hand back the winner's child, with
            // the winner's task copies, rather than fail or add a second set of tasks.
            var series = Series();
            var winner = new Event { Id = Guid.NewGuid(), ParentEventId = series.Id, ExceptionDate = Friday };
            _events.SetupSequence(r => r.GetOccurrenceChildAsync(series.Id, Friday))
                .ReturnsAsync((Event?)null)
                .ReturnsAsync(winner);
            _events.Setup(r => r.TryAddOccurrenceDayAsync(It.IsAny<Event>())).ReturnsAsync(false);
            _tasks.Setup(r => r.GetByEventIdAsync(series.Id)).ReturnsAsync(new List<EventTask>
            {
                new() { Id = Guid.NewGuid(), EventId = series.Id, Title = "Warm up" }
            });

            var day = await _materializer.FindOrCreateAsync(series, Friday);

            day.Should().BeSameAs(winner);
            _addedTasks.Should().BeEmpty();
        }

        [Fact]
        public async Task RefusesADayBeforeTheSeriesStarts()
        {
            (await _materializer.FindOrCreateAsync(Series(), SeriesStart.AddDays(-1))).Should().BeNull();
            _addedEvents.Should().BeEmpty();
        }

        [Fact]
        public async Task AcceptsTheFirstDayOfTheSeries()
        {
            (await _materializer.FindOrCreateAsync(Series(), SeriesStart)).Should().NotBeNull();
        }

        [Fact]
        public async Task RefusesADayAfterTheSeriesUntil()
        {
            var series = Series("FREQ=DAILY;UNTIL=20260910T235959Z");

            (await _materializer.FindOrCreateAsync(series, Friday)).Should().BeNull();
        }

        [Fact]
        public async Task TreatsADateOnlyUntilAsIncludingThatWholeDay()
        {
            var series = Series("FREQ=DAILY;UNTIL=20260911");

            (await _materializer.FindOrCreateAsync(series, Friday)).Should().NotBeNull();
        }

        [Fact]
        public async Task RefusesADayTheUserDeleted()
        {
            var series = Series(exceptionDates: "2026-09-10T10:00:00Z,2026-09-11T10:00:00Z");

            (await _materializer.FindOrCreateAsync(series, Friday)).Should().BeNull();
        }

        [Fact]
        public async Task RefusesSomethingThatIsNotASeries()
        {
            var single = new Event { Id = Guid.NewGuid(), StartTime = SeriesStart, EndTime = SeriesStart.AddHours(1) };
            var alreadyADay = Series();
            alreadyADay.ParentEventId = Guid.NewGuid();

            (await _materializer.FindOrCreateAsync(single, Friday)).Should().BeNull();
            (await _materializer.FindOrCreateAsync(alreadyADay, Friday)).Should().BeNull();
        }

        [Fact]
        public void FindLocalOnlyDay_MatchesToTheMinute_AndIgnoresDaysGoogleKnows()
        {
            var series = Series();
            var localOnly = new Event { Id = Guid.NewGuid(), ParentEventId = series.Id, ExceptionDate = Friday.AddSeconds(30) };
            var googleKnown = new Event { Id = Guid.NewGuid(), ParentEventId = series.Id, ExceptionDate = Friday, GoogleEventId = "g1" };
            var otherSeries = new Event { Id = Guid.NewGuid(), ParentEventId = Guid.NewGuid(), ExceptionDate = Friday };
            var otherDay = new Event { Id = Guid.NewGuid(), ParentEventId = series.Id, ExceptionDate = Friday.AddDays(1) };

            var events = new[] { googleKnown, otherSeries, otherDay, localOnly };

            OccurrenceMaterializer.FindLocalOnlyDay(events, series, Friday).Should().BeSameAs(localOnly);
            OccurrenceMaterializer.FindLocalOnlyDay(events, series, Friday.AddDays(2)).Should().BeNull();
        }

        [Fact]
        public void FindLocalOnlyDay_IgnoresAnEditedDayWaitingForItsInsert()
        {
            // An edited day has no GoogleEventId until its Insert is processed, so it looks
            // local-only by that field alone. Editing it put its date in the series' exception
            // list; that is what keeps a sync from deleting it when Google reports back the
            // cancellation the edit itself caused.
            var series = Series(exceptionDates: "2026-09-11T10:00:00Z");
            var editedAwaitingInsert = new Event { Id = Guid.NewGuid(), ParentEventId = series.Id, ExceptionDate = Friday };

            OccurrenceMaterializer.FindLocalOnlyDay(new[] { editedAwaitingInsert }, series, Friday)
                .Should().BeNull();
        }

        [Fact]
        public void FindDay_FindsEditedAndLocalOnlyDaysAlike_ToTheMinute()
        {
            // The sync uses it to avoid adding Google's version of a day next to an edited day
            // whose Insert is still queued — the one case FindLocalOnlyDay deliberately skips.
            var series = Series(exceptionDates: "2026-09-11T10:00:00Z");
            var editedAwaitingInsert = new Event { Id = Guid.NewGuid(), ParentEventId = series.Id, ExceptionDate = Friday.AddSeconds(59) };
            var otherSeries = new Event { Id = Guid.NewGuid(), ParentEventId = Guid.NewGuid(), ExceptionDate = Friday };
            var events = new[] { otherSeries, editedAwaitingInsert };

            OccurrenceMaterializer.FindDay(events, series, Friday).Should().BeSameAs(editedAwaitingInsert);
            OccurrenceMaterializer.FindDay(events, series, Friday.AddMinutes(1)).Should().BeNull();
            OccurrenceMaterializer.FindLocalOnlyDay(events, series, Friday).Should().BeNull();
        }

        [Fact]
        public void StandsFor_NeedsAnExceptionDate()
        {
            OccurrenceMaterializer.StandsFor(new Event { StartTime = Friday }, Friday).Should().BeFalse();
            OccurrenceMaterializer.StandsFor(new Event { ExceptionDate = Friday }, Friday).Should().BeTrue();
        }

        [Fact]
        public void IsLocalOnlyDay_TellsATouchedDayFromAnEditedOne()
        {
            var series = Series(exceptionDates: "2026-09-10T10:00:00Z");
            var touchedFriday = new Event { ParentEventId = series.Id, ExceptionDate = Friday };
            var editedThursday = new Event { ParentEventId = series.Id, ExceptionDate = Friday.AddDays(-1) };
            var someoneElses = new Event { ParentEventId = Guid.NewGuid(), ExceptionDate = Friday };

            OccurrenceMaterializer.IsLocalOnlyDay(touchedFriday, series).Should().BeTrue();
            OccurrenceMaterializer.IsLocalOnlyDay(editedThursday, series).Should().BeFalse();
            OccurrenceMaterializer.IsLocalOnlyDay(someoneElses, series).Should().BeFalse();
        }
    }

    public class RecurrenceExceptionsTests
    {
        private static readonly DateTime Friday = new(2026, 9, 11, 10, 0, 0, DateTimeKind.Utc);

        [Fact]
        public void Add_WritesTheFormatExistingRowsAndTheClientUse()
        {
            var series = new Event();

            RecurrenceExceptions.Add(series, Friday);

            series.RecurrenceExceptionDates.Should().Be("2026-09-11T10:00:00Z");
        }

        [Fact]
        public void Add_DoesNotRepeatADateAlreadyThere_ToTheMinute()
        {
            // The old writers deduped with a string Contains, so the same slot written with
            // different seconds would have been added twice.
            var series = new Event { RecurrenceExceptionDates = "2026-09-11T10:00:00Z" };

            RecurrenceExceptions.Add(series, Friday.AddSeconds(42));
            RecurrenceExceptions.Add(series, Friday.AddDays(1));

            series.RecurrenceExceptionDates.Should().Be("2026-09-11T10:00:00Z,2026-09-12T10:00:00Z");
        }

        [Theory]
        [InlineData("2026-09-11T10:00:00Z", true)]
        [InlineData("2026-09-10T10:00:00Z, 2026-09-11T10:00:00Z", true)]
        [InlineData("2026-09-11T10:01:00Z", false)]
        [InlineData("", false)]
        [InlineData("garbage,2026-09-11T10:00:00Z", true)]
        public void Contains_MatchesToTheMinute(string stored, bool expected)
        {
            var series = new Event { RecurrenceExceptionDates = stored };

            RecurrenceExceptions.Contains(series, Friday).Should().Be(expected);
        }

        [Theory]
        [InlineData(10, 11, 1)]      // 07:00 -> 08:00 style move
        [InlineData(10, 9, -1)]
        [InlineData(23, 1, 2)]       // across midnight, the short way
        [InlineData(1, 23, -2)]
        [InlineData(10, 10 + 24, 0)] // a change of date alone moves nothing
        public void TimeOfDayShift_IgnoresTheDateAndTakesTheShortWay(int fromHour, int toHour, int expectedHours)
        {
            var from = new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc).AddHours(fromHour);
            var to = new DateTime(2026, 9, 9, 0, 0, 0, DateTimeKind.Utc).AddHours(toHour);

            UpdateEventCommandHandler.TimeOfDayShift(from, to).Should().Be(TimeSpan.FromHours(expectedHours));
        }
    }
}
