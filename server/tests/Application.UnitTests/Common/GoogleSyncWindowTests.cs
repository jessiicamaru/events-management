using System;
using FluentAssertions;
using HabitTracker.Application.Common;
using HabitTracker.Domain.Entities;
using Xunit;

namespace HabitTracker.Application.Tests.Common
{
    public class GoogleSyncWindowTests
    {
        private static readonly DateTime WindowStart = new(2026, 9, 1, 0, 0, 0, DateTimeKind.Utc);
        private static readonly DateTime WindowEnd = new(2026, 9, 22, 0, 0, 0, DateTimeKind.Utc);

        private static Event At(DateTime start, string? rule = null) => new()
        {
            StartTime = start,
            EndTime = start.AddHours(1),
            RecurrenceRule = rule,
        };

        private static bool CouldBeListed(Event ev) => GoogleSyncWindow.CouldBeListed(ev, WindowStart, WindowEnd);

        [Fact]
        public void AnEventInsideTheWindow_CouldBeListed() =>
            CouldBeListed(At(WindowStart.AddDays(3))).Should().BeTrue();

        [Fact]
        public void AnEventOverlappingTheWindowStart_CouldBeListed() =>
            CouldBeListed(At(WindowStart.AddMinutes(-30))).Should().BeTrue();

        [Fact]
        public void BothBoundsAreExclusive()
        {
            CouldBeListed(At(WindowStart.AddHours(-1))).Should().BeFalse("it ends exactly when the window starts");
            CouldBeListed(At(WindowEnd)).Should().BeFalse("it starts exactly when the window ends");
        }

        [Fact]
        public void AnOpenEndedSeriesThatBeganEarlier_CouldBeListed() =>
            CouldBeListed(At(WindowStart.AddDays(-90), "RRULE:FREQ=WEEKLY")).Should().BeTrue();

        [Fact]
        public void ASeriesStartingAfterTheWindow_CannotBeListed() =>
            CouldBeListed(At(WindowEnd.AddDays(1), "RRULE:FREQ=DAILY")).Should().BeFalse();

        [Theory]
        [InlineData("RRULE:FREQ=DAILY;UNTIL=20260820T235959Z", false)] // Google's form, ended in August
        [InlineData("FREQ=DAILY;INTERVAL=1;UNTIL=20260820T235959Z", false)] // the client's form
        [InlineData("RRULE:FREQ=DAILY;UNTIL=20260905T000000Z", true)] // runs into the window
        [InlineData("RRULE:FREQ=DAILY;UNTIL=20260820", false)] // date only
        [InlineData("RRULE:FREQ=DAILY;COUNT=10", true)] // unknown end without expanding: ask
        [InlineData("RRULE:FREQ=DAILY;UNTIL=garbage", true)] // unreadable: ask
        public void ASeriesThatBeganEarlier_DependsOnWhenItEnds(string rule, bool expected) =>
            CouldBeListed(At(WindowStart.AddDays(-60), rule)).Should().Be(expected);

        [Fact]
        public void ADateOnlyUntil_IncludesThatWholeDay()
        {
            // UNTIL=20260831 still has a day on 31 August, 23:30–00:30, which reaches into September.
            var series = At(new DateTime(2026, 8, 1, 23, 30, 0, DateTimeKind.Utc), "RRULE:FREQ=DAILY;UNTIL=20260831");

            CouldBeListed(series).Should().BeTrue();
        }

        [Fact]
        public void TheLastDaysLengthCounts()
        {
            // Last day starts 31 August 23:00 and lasts two hours, so it ends inside the window.
            var series = new Event
            {
                StartTime = new DateTime(2026, 8, 1, 23, 0, 0, DateTimeKind.Utc),
                EndTime = new DateTime(2026, 8, 2, 1, 0, 0, DateTimeKind.Utc),
                RecurrenceRule = "RRULE:FREQ=DAILY;UNTIL=20260831T230000Z",
            };

            CouldBeListed(series).Should().BeTrue();
        }
    }
}
