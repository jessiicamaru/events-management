using System;
using System.Collections.Generic;
using System.Linq;
using FluentAssertions;
using HabitTracker.Application.Common;
using HabitTracker.Application.Features.Assistant.Scheduling;
using HabitTracker.Domain.Entities;
using Xunit;

namespace HabitTracker.Application.Tests.Features.Assistant
{
    public class SchedulePlannerTests
    {
        private static readonly TimeSpan Offset = StreakCalculator.DefaultDayBoundaryOffset;
        private static readonly TimeSpan FortyFive = TimeSpan.FromMinutes(45);

        // Tuesday 29 September 2026 — the day after the seeded "today".
        private static readonly DateOnly Tuesday = new(2026, 9, 29);
        private static readonly int[] EveryDay = { 1, 2, 3, 4, 5, 6, 7 };

        private static TimeWindow Window(int fromHour, int toHour) =>
            new(TimeSpan.FromHours(fromHour), TimeSpan.FromHours(toHour));

        /// <summary>Gym on Tue/Thu/Sat 17:30–18:30 local, as a series — expanded like the tool does.</summary>
        private static IReadOnlyList<EventOccurrence> GymSeries(IReadOnlyList<DateOnly> dates)
        {
            var gym = new Event
            {
                Title = "Gym",
                StartTime = SchedulePlanner.ToUtc(new DateOnly(2026, 9, 1), new TimeSpan(17, 30, 0), Offset),
                EndTime = SchedulePlanner.ToUtc(new DateOnly(2026, 9, 1), new TimeSpan(18, 30, 0), Offset),
                RecurrenceRule = "RRULE:FREQ=WEEKLY;BYDAY=TU,TH,SA",
            };
            return RecurrenceExpander.Expand(
                new[] { gym },
                SchedulePlanner.ToUtc(dates[0], TimeSpan.Zero, Offset),
                SchedulePlanner.ToUtc(dates[^1].AddDays(1), TimeSpan.Zero, Offset));
        }

        [Fact]
        public void PlannedDates_ShouldKeepOnlyTheChosenWeekdays_OverTheHorizon()
        {
            var dates = SchedulePlanner.PlannedDates(Tuesday, new[] { 1, 3, 5 });

            dates.Should().HaveCount(6);
            dates.Should().OnlyContain(d => d.DayOfWeek == DayOfWeek.Monday || d.DayOfWeek == DayOfWeek.Wednesday || d.DayOfWeek == DayOfWeek.Friday);
            dates[0].Should().Be(new DateOnly(2026, 9, 30), "the first Wednesday on or after the start");
        }

        [Fact]
        public void BestPerWindow_ShouldPickTheFreeMorning_AndReportTheEveningsClashWithTheSeriesDays()
        {
            var dates = SchedulePlanner.PlannedDates(Tuesday, EveryDay);

            var options = SchedulePlanner.BestPerWindow(
                new[] { Window(18, 19), Window(5, 6) }, FortyFive, dates, GymSeries(dates), Offset);

            options[0].Start.Should().Be(TimeSpan.FromHours(5), "the free window wins, although listed second");
            options[0].Conflicts.Should().BeEmpty();
            options[0].WindowIndex.Should().Be(1);

            var evening = options[1];
            evening.Start.Should().Be(TimeSpan.FromHours(18));
            evening.Conflicts.Should().HaveCount(6, "Tue, Thu and Sat, over two weeks");
            evening.Conflicts.Should().OnlyContain(c => c.Title == "Gym");
            evening.Conflicts.Select(c => c.Date.DayOfWeek).Distinct()
                .Should().BeEquivalentTo(new[] { DayOfWeek.Tuesday, DayOfWeek.Thursday, DayOfWeek.Saturday });
        }

        [Fact]
        public void BestPerWindow_ShouldMoveLaterInsideAWindow_ToClearAClash()
        {
            // 18:00–20:00 can hold 45 minutes after gym ends at 18:30.
            var dates = SchedulePlanner.PlannedDates(Tuesday, EveryDay);

            var option = SchedulePlanner.BestPerWindow(
                new[] { Window(18, 20) }, FortyFive, dates, GymSeries(dates), Offset).Single();

            option.Start.Should().Be(new TimeSpan(18, 30, 0));
            option.Conflicts.Should().BeEmpty();
        }

        [Fact]
        public void BestPerWindow_ShouldPreferTheUsersFirstWindow_WhenBothAreFree()
        {
            var dates = SchedulePlanner.PlannedDates(Tuesday, EveryDay);

            var options = SchedulePlanner.BestPerWindow(
                new[] { Window(18, 19), Window(5, 6) }, FortyFive, dates, Array.Empty<EventOccurrence>(), Offset);

            options.Select(o => o.WindowIndex).Should().Equal(0, 1);
            options[0].Start.Should().Be(TimeSpan.FromHours(18));
        }

        [Fact]
        public void BestPerWindow_ShouldSkipAWindowTooShortForTheSession()
        {
            var dates = SchedulePlanner.PlannedDates(Tuesday, EveryDay);

            var options = SchedulePlanner.BestPerWindow(
                new[] { new TimeWindow(TimeSpan.FromHours(5), new TimeSpan(5, 30, 0)) }, FortyFive, dates,
                Array.Empty<EventOccurrence>(), Offset);

            options.Should().BeEmpty();
        }

        [Fact]
        public void ToUtc_ShouldReadTheTimeAsLocal()
        {
            SchedulePlanner.ToUtc(Tuesday, TimeSpan.FromHours(5), Offset)
                .Should().Be(new DateTime(2026, 9, 28, 22, 0, 0, DateTimeKind.Utc));
        }
    }
}
