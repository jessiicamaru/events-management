using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Application.Common;
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
            _events.Setup(r => r.AddAsync(It.IsAny<Event>()))
                .Callback<Event>(_addedEvents.Add)
                .Returns(Task.CompletedTask);
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
            var seriesId = Guid.NewGuid();
            var localOnly = new Event { Id = Guid.NewGuid(), ParentEventId = seriesId, ExceptionDate = Friday.AddSeconds(30) };
            var googleKnown = new Event { Id = Guid.NewGuid(), ParentEventId = seriesId, ExceptionDate = Friday, GoogleEventId = "g1" };
            var otherSeries = new Event { Id = Guid.NewGuid(), ParentEventId = Guid.NewGuid(), ExceptionDate = Friday };
            var otherDay = new Event { Id = Guid.NewGuid(), ParentEventId = seriesId, ExceptionDate = Friday.AddDays(1) };

            var events = new[] { googleKnown, otherSeries, otherDay, localOnly };

            OccurrenceMaterializer.FindLocalOnlyDay(events, seriesId, Friday).Should().BeSameAs(localOnly);
            OccurrenceMaterializer.FindLocalOnlyDay(events, seriesId, Friday.AddDays(2)).Should().BeNull();
        }
    }
}
