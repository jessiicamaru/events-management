using System;
using System.Collections.Generic;
using System.Linq;
using FluentAssertions;
using HabitTracker.Application.Common;
using HabitTracker.Domain.Entities;
using Xunit;

namespace HabitTracker.Application.Tests.Common
{
    public class HabitAdherenceTests
    {
        private static readonly TimeSpan Offset = StreakCalculator.DefaultDayBoundaryOffset;

        // 14:00 on Monday 28 September 2026, local.
        private static readonly DateTime Now = Utc(2026, 9, 28, 14, 0);

        // 00:00 on Monday 14 September 2026, local.
        private static readonly DateTime From = Utc(2026, 9, 14, 0, 0);

        private readonly Habit _run = new() { Name = "Chạy bộ" };
        private readonly List<Event> _events = new();

        /// <summary>A local wall-clock time as UTC.</summary>
        private static DateTime Utc(int year, int month, int day, int hour, int minute) =>
            DateTime.SpecifyKind(new DateTime(year, month, day, hour, minute, 0) - Offset, DateTimeKind.Utc);

        /// <summary>
        /// Runs at 06:00 local on Mon, Wed and Fri from 14 September. 06:00 local is 23:00 UTC
        /// the day before, so a weekday or hour read in UTC lands on the wrong one.
        /// </summary>
        private Event AddRunSeries()
        {
            var series = new Event
            {
                Title = "Chạy bộ",
                HabitId = _run.Id.ToString(),
                StartTime = Utc(2026, 9, 14, 6, 0),
                EndTime = Utc(2026, 9, 14, 6, 45),
                RecurrenceRule = "RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR",
            };
            _events.Add(series);
            return series;
        }

        /// <summary>A day of <paramref name="series"/> split off and marked done, as completing it does.</summary>
        private void CompleteDay(Event series, DateTime occurrenceUtc)
        {
            _events.Add(new Event
            {
                Title = series.Title,
                HabitId = series.HabitId,
                ParentEventId = series.Id,
                ExceptionDate = occurrenceUtc,
                StartTime = occurrenceUtc,
                EndTime = occurrenceUtc + (series.EndTime - series.StartTime),
                IsCompleted = true,
            });
        }

        private Event AddOneOff(DateTime startUtc, int minutes, bool done, Habit? habit = null)
        {
            var ev = new Event
            {
                Title = "Buổi lẻ",
                HabitId = (habit ?? _run).Id.ToString(),
                StartTime = startUtc,
                EndTime = startUtc.AddMinutes(minutes),
                IsCompleted = done,
            };
            _events.Add(ev);
            return ev;
        }

        private HabitAdherenceResult Run(params Habit[] extra) =>
            HabitAdherence.Compute(new[] { _run }.Concat(extra), _events, From, Now, Offset)[0];

        [Fact]
        public void ShouldCountEveryDayOfASeries_WithCompletionFromItsSplitOffDays()
        {
            var series = AddRunSeries();
            CompleteDay(series, Utc(2026, 9, 16, 6, 0));
            CompleteDay(series, Utc(2026, 9, 21, 6, 0));

            var result = Run();

            // 14, 16, 18, 21, 23, 25 and 28 September: 06:00 today is already over.
            result.Total.Should().Be(new AdherenceCount(7, 2));
            result.Total.Missed.Should().Be(5);
            result.Total.RatePercent.Should().Be(29);
            result.LastDone.Should().Be(new DateOnly(2026, 9, 21));
            result.MissedDates.Should().Equal(
                new DateOnly(2026, 9, 14), new DateOnly(2026, 9, 18), new DateOnly(2026, 9, 23),
                new DateOnly(2026, 9, 25), new DateOnly(2026, 9, 28));
        }

        [Fact]
        public void ShouldSplitByLocalWeekdayAndHour()
        {
            var series = AddRunSeries();
            CompleteDay(series, Utc(2026, 9, 16, 6, 0));
            CompleteDay(series, Utc(2026, 9, 21, 6, 0));

            var result = Run();

            result.ByWeekday.Should().Equal(new Dictionary<int, AdherenceCount>
            {
                [1] = new(3, 1),
                [3] = new(2, 1),
                [5] = new(2, 0),
            });
            result.ByHour.Should().Equal(new Dictionary<int, AdherenceCount> { [6] = new(7, 2) });
        }

        [Fact]
        public void ShouldNotPlanADeletedDay()
        {
            var series = AddRunSeries();
            RecurrenceExceptions.Add(series, Utc(2026, 9, 18, 6, 0));

            Run().Total.Planned.Should().Be(6);
        }

        [Fact]
        public void ShouldCountASessionOnceItIsOverOrDone_NotWhileItIsStillToCome()
        {
            AddOneOff(Utc(2026, 9, 27, 9, 0), 30, done: false);   // yesterday: missed
            AddOneOff(Utc(2026, 9, 28, 13, 30), 60, done: false); // running now: not yet missed
            AddOneOff(Utc(2026, 9, 28, 18, 0), 30, done: false);  // this evening: not yet missed
            AddOneOff(Utc(2026, 9, 28, 20, 0), 30, done: true);   // this evening, done early: kept

            Run().Total.Should().Be(new AdherenceCount(2, 1));
        }

        [Fact]
        public void ShouldLeaveOutSessionsBeforeTheWindow()
        {
            AddOneOff(Utc(2026, 9, 13, 23, 45), 30, done: true); // runs past midnight into the window
            AddOneOff(Utc(2026, 9, 14, 0, 0), 30, done: true);

            Run().Total.Should().Be(new AdherenceCount(1, 1));
        }

        [Fact]
        public void ShouldCountOnlyTheHabitsOwnSessions_AndGiveNoRateWhenNoneWerePlanned()
        {
            var read = new Habit { Name = "Đọc sách" };
            AddOneOff(Utc(2026, 9, 20, 21, 0), 30, done: true, habit: read);
            _events.Add(new Event
            {
                Title = "Họp",
                StartTime = Utc(2026, 9, 22, 9, 0),
                EndTime = Utc(2026, 9, 22, 10, 0),
            });

            var results = HabitAdherence.Compute(new[] { _run, read }, _events, From, Now, Offset);

            results[0].Total.Should().Be(new AdherenceCount(0, 0));
            results[0].Total.RatePercent.Should().BeNull();
            results[0].LastDone.Should().BeNull();
            results[1].Habit.Should().BeSameAs(read);
            results[1].Total.Should().Be(new AdherenceCount(1, 1));
        }

        [Fact]
        public void EndOfLocalDay_ShouldBeTheNextLocalMidnight()
        {
            HabitAdherence.EndOfLocalDay(Now, Offset).Should().Be(Utc(2026, 9, 29, 0, 0));
            // 23:30 local is still the same day, although in UTC it is 16:30.
            HabitAdherence.EndOfLocalDay(Utc(2026, 9, 28, 23, 30), Offset).Should().Be(Utc(2026, 9, 29, 0, 0));
        }
    }
}
