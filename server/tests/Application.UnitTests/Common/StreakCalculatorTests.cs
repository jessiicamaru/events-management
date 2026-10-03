using System;
using System.Collections.Generic;
using System.Linq;
using FluentAssertions;
using HabitTracker.Application.Common;
using HabitTracker.Domain.Entities;
using Xunit;

namespace HabitTracker.Application.Tests.Common
{
    public class StreakCalculatorTests
    {
        /// <summary>A UTC instant whose UTC+7 calendar day is <paramref name="daysAgo"/> days back.</summary>
        private static DateTime LocalDay(int daysAgo, int localHour = 12)
        {
            var localToday = DateTime.UtcNow.Add(StreakCalculator.DefaultDayBoundaryOffset).Date;
            return DateTime.SpecifyKind(
                localToday.AddDays(-daysAgo).AddHours(localHour).Subtract(StreakCalculator.DefaultDayBoundaryOffset),
                DateTimeKind.Utc);
        }

        [Fact]
        public void FromStartTimes_ShouldReturnZero_WhenThereAreNoCompletions()
        {
            var result = StreakCalculator.FromStartTimes(Array.Empty<DateTime>());

            result.Should().Be(StreakResult.None);
        }

        [Fact]
        public void FromStartTimes_ShouldCountConsecutiveDaysEndingToday()
        {
            var result = StreakCalculator.FromStartTimes(new[] { LocalDay(2), LocalDay(1), LocalDay(0) });

            result.Current.Should().Be(3);
            result.Longest.Should().Be(3);
        }

        [Fact]
        public void FromStartTimes_ShouldKeepTheStreakAlive_WhenTheLastDayWasYesterday()
        {
            // The user still has today to keep it going, so it has not broken yet.
            var result = StreakCalculator.FromStartTimes(new[] { LocalDay(2), LocalDay(1) });

            result.Current.Should().Be(2);
        }

        [Fact]
        public void FromStartTimes_ShouldReportZeroCurrent_ButKeepLongest_WhenTheStreakIsStale()
        {
            // Last activity was 5 days ago: the current streak is dead, the record still stands.
            var result = StreakCalculator.FromStartTimes(new[] { LocalDay(6), LocalDay(5) });

            result.Current.Should().Be(0);
            result.Longest.Should().Be(2);
        }

        [Fact]
        public void FromStartTimes_ShouldTreatSeveralCompletionsOnOneDayAsOneDay()
        {
            var result = StreakCalculator.FromStartTimes(new[]
            {
                LocalDay(0, localHour: 8),
                LocalDay(0, localHour: 13),
                LocalDay(0, localHour: 21)
            });

            result.Current.Should().Be(1);
            result.Longest.Should().Be(1);
        }

        [Fact]
        public void FromStartTimes_ShouldReportTheLongestRunEvenWhenItIsNotTheCurrentOne()
        {
            // A 4-day run a while back, then a gap, then 1 day today.
            var startTimes = new[] { LocalDay(20), LocalDay(19), LocalDay(18), LocalDay(17), LocalDay(0) };

            var result = StreakCalculator.FromStartTimes(startTimes);

            result.Current.Should().Be(1);
            result.Longest.Should().Be(4);
        }

        [Fact]
        public void FromStartTimes_ShouldSplitDaysOnTheUtcPlus7Boundary_NotTheUtcBoundary()
        {
            // 23:00 local yesterday and 06:00 local today are the same UTC day but different
            // local days, so they form a 2-day streak.
            var yesterdayLate = LocalDay(1, localHour: 23);
            var todayEarly = LocalDay(0, localHour: 6);

            var result = StreakCalculator.FromStartTimes(new[] { yesterdayLate, todayEarly });

            result.Current.Should().Be(2);

            // Under a UTC day boundary the same two instants collapse into one day.
            var underUtc = StreakCalculator.FromStartTimes(new[] { yesterdayLate, todayEarly }, TimeSpan.Zero);
            underUtc.Longest.Should().Be(1);
        }

        [Fact]
        public void ToLocalDate_ShouldTreatUnspecifiedKindAsUtc()
        {
            var utc = new DateTime(2026, 5, 4, 20, 0, 0, DateTimeKind.Utc);
            var unspecified = new DateTime(2026, 5, 4, 20, 0, 0, DateTimeKind.Unspecified);

            StreakCalculator.ToLocalDate(unspecified).Should().Be(StreakCalculator.ToLocalDate(utc));

            // 20:00 UTC is 03:00 the next day at UTC+7.
            StreakCalculator.ToLocalDate(utc).Should().Be(new DateTime(2026, 5, 5));
        }

        [Fact]
        public void FromEvents_ShouldReadTheStartTimeOfEachEvent()
        {
            var events = new List<Event>
            {
                new Event { Id = Guid.NewGuid(), IsCompleted = true, StartTime = LocalDay(1) },
                new Event { Id = Guid.NewGuid(), IsCompleted = true, StartTime = LocalDay(0) }
            };

            StreakCalculator.FromEvents(events).Current.Should().Be(2);
        }
    }
}
