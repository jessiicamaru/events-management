using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text.Json;
using FluentAssertions;
using HabitTracker.Application.Common;
using HabitTracker.Domain.Entities;
using Xunit;

namespace HabitTracker.Application.Tests.Common
{
    public class RecurrenceExpanderTests
    {
        private static readonly TimeSpan Offset = StreakCalculator.DefaultDayBoundaryOffset;
        private static readonly TimeSpan Duration = TimeSpan.FromMinutes(30);
        private const string WallFormat = "yyyy-MM-dd'T'HH:mm";

        // ── Parity with the client ────────────────────────────────────────────────────────

        public static IEnumerable<object[]> FixtureCases() =>
            LoadFixture().Select(c => new object[] { c.Name });

        /// <summary>
        /// The server's half of the parity check; the client's is
        /// <c>recurrence_expansion_parity_test.dart</c>. A case marked <c>clientGap</c> is a
        /// valid rule the client cannot expand yet, and the server is held to the right answer.
        /// </summary>
        [Theory]
        [MemberData(nameof(FixtureCases))]
        public void Expand_ShouldMatchTheSharedFixture(string name)
        {
            var testCase = LoadFixture().Single(c => c.Name == name);
            var series = Series(testCase.Rule, Utc(testCase.Start), testCase.Exceptions.Select(Utc));
            var children = testCase.Children.Select(wall => DayOf(series, Utc(wall)));

            var occurrences = RecurrenceExpander.Expand(
                children.Prepend(series), Utc(testCase.RangeStart), Utc(testCase.RangeEnd));

            occurrences.Where(o => o.IsSeriesDay)
                .Select(o => Wall(o.Start))
                .Should().Equal(testCase.Expected);
        }

        // ── What the fixture leaves to the server ─────────────────────────────────────────

        [Fact]
        public void Expand_ShouldIncludeAnOccurrenceStartingExactlyAtTheWindowStart_AndExcludeOneAtItsEnd()
        {
            var series = Series("FREQ=DAILY", Utc("2026-10-05T06:00"));

            var occurrences = RecurrenceExpander.Expand(
                new[] { series }, Utc("2026-10-05T06:00"), Utc("2026-10-07T06:00"));

            occurrences.Select(o => Wall(o.Start)).Should().Equal("2026-10-05T06:00", "2026-10-06T06:00");
        }

        [Fact]
        public void Expand_ShouldGiveEachDayTheSeriesDuration_AndPointBackAtTheSeries()
        {
            var series = Series("FREQ=DAILY", Utc("2026-10-05T06:00"));

            var day = RecurrenceExpander.Expand(
                new[] { series }, Utc("2026-10-06T00:00"), Utc("2026-10-06T23:59")).Single();

            day.Event.Should().BeSameAs(series);
            day.IsSeriesDay.Should().BeTrue();
            (day.End - day.Start).Should().Be(Duration);
            day.Start.Kind.Should().Be(DateTimeKind.Utc);
        }

        [Fact]
        public void Expand_ShouldIncludeAUtcUntilThatFallsOnTheNextUtcDay_WhenItIsStillTheSameLocalEvening()
        {
            // 06:00 local on the 7th is 23:00Z on the 6th, and UNTIL is 23:30Z on the 6th: the
            // 7th is inside it. Reading UNTIL as a wall-clock time would drop the 7th.
            var series = Series("FREQ=DAILY;UNTIL=20261006T233000Z", Utc("2026-10-05T06:00"));

            var occurrences = RecurrenceExpander.Expand(
                new[] { series }, Utc("2026-10-01T00:00"), Utc("2026-10-10T00:00"));

            occurrences.Select(o => Wall(o.Start)).Should().Equal(
                "2026-10-05T06:00", "2026-10-06T06:00", "2026-10-07T06:00");
        }

        [Fact]
        public void Expand_ShouldReturnTheSplitOffDayItself_InPlaceOfTheSeriesDay()
        {
            var series = Series("FREQ=DAILY", Utc("2026-10-05T06:00"));
            var moved = DayOf(series, Utc("2026-10-06T06:00"));
            moved.StartTime = Utc("2026-10-06T19:00");
            moved.EndTime = moved.StartTime + Duration;

            var occurrences = RecurrenceExpander.Expand(
                new[] { series, moved }, Utc("2026-10-06T00:00"), Utc("2026-10-06T23:59"));

            occurrences.Should().ContainSingle();
            occurrences[0].Event.Should().BeSameAs(moved);
            occurrences[0].IsSeriesDay.Should().BeFalse();
            Wall(occurrences[0].Start).Should().Be("2026-10-06T19:00");
        }

        [Fact]
        public void Expand_ShouldReturnAOneOffEvent_OnlyWhenItOverlapsTheWindow()
        {
            var inside = OneOff(Utc("2026-10-06T09:00"));
            var runningIn = OneOff(Utc("2026-10-05T23:45"));
            var before = OneOff(Utc("2026-10-04T09:00"));
            var after = OneOff(Utc("2026-10-07T09:00"));

            var occurrences = RecurrenceExpander.Expand(
                new[] { inside, runningIn, before, after }, Utc("2026-10-06T00:00"), Utc("2026-10-07T00:00"));

            occurrences.Select(o => o.Event).Should().Equal(runningIn, inside);
            occurrences.Should().OnlyContain(o => !o.IsSeriesDay);
        }

        [Fact]
        public void Expand_ShouldTreatAnEmptyRuleAsAOneOffEvent()
        {
            var ev = Series(string.Empty, Utc("2026-10-06T06:00"));

            var occurrences = RecurrenceExpander.Expand(
                new[] { ev }, Utc("2026-10-06T00:00"), Utc("2026-10-07T00:00"));

            occurrences.Should().ContainSingle().Which.IsSeriesDay.Should().BeFalse();
        }

        [Fact]
        public void Expand_ShouldOrderEverythingByStart()
        {
            var evening = Series("FREQ=DAILY", Utc("2026-10-05T20:00"));
            var morning = Series("FREQ=DAILY", Utc("2026-10-05T06:00"));
            var noon = OneOff(Utc("2026-10-06T12:00"));

            var occurrences = RecurrenceExpander.Expand(
                new[] { evening, noon, morning }, Utc("2026-10-06T00:00"), Utc("2026-10-07T00:00"));

            occurrences.Select(o => Wall(o.Start)).Should().Equal(
                "2026-10-06T06:00", "2026-10-06T12:00", "2026-10-06T20:00");
        }

        [Fact]
        public void Expand_ShouldEvaluateTheRuleOnTheGivenOffset()
        {
            // Monday 05:00 at UTC+7 is Sunday 22:00Z. Evaluated at UTC+0 the same stored instant
            // is a Sunday, so BYDAY=MO must not produce it.
            var series = Series("FREQ=WEEKLY;BYDAY=MO", Utc("2026-10-05T05:00"));

            var atUtc = RecurrenceExpander.Expand(
                new[] { series }, Utc("2026-10-01T00:00"), Utc("2026-10-14T00:00"), TimeSpan.Zero);

            atUtc.Select(o => o.Start.DayOfWeek).Should().OnlyContain(day => day == DayOfWeek.Monday);
        }

        [Fact]
        public void RuleOccurrences_ShouldIgnoreTheExceptionList()
        {
            var series = Series("FREQ=DAILY", Utc("2026-10-05T06:00"), new[] { Utc("2026-10-06T06:00") });

            var starts = RecurrenceExpander.RuleOccurrences(series, Utc("2026-10-05T00:00"), Utc("2026-10-08T00:00"));

            starts.Select(Wall).Should().Equal("2026-10-05T06:00", "2026-10-06T06:00", "2026-10-07T06:00");
        }

        // ── Helpers ────────────────────────────────────────────────────────────────────────

        private sealed record FixtureCase(
            string Name, string Rule, string Start, string RangeStart, string RangeEnd,
            IReadOnlyList<string> Exceptions, IReadOnlyList<string> Children, IReadOnlyList<string> Expected);

        private static IReadOnlyList<FixtureCase> LoadFixture()
        {
            var path = Path.Combine(AppContext.BaseDirectory, "Fixtures", "recurrence-expansion.json");
            using var document = JsonDocument.Parse(File.ReadAllText(path));

            return document.RootElement.GetProperty("cases").EnumerateArray()
                .Select(c => new FixtureCase(
                    c.GetProperty("name").GetString()!,
                    c.GetProperty("rule").GetString()!,
                    c.GetProperty("start").GetString()!,
                    c.GetProperty("rangeStart").GetString()!,
                    c.GetProperty("rangeEnd").GetString()!,
                    Strings(c, "exceptions"),
                    Strings(c, "children"),
                    Strings(c, "expected")))
                .ToList();
        }

        private static IReadOnlyList<string> Strings(JsonElement element, string property) =>
            element.TryGetProperty(property, out var array)
                ? array.EnumerateArray().Select(v => v.GetString()!).ToList()
                : Array.Empty<string>();

        /// <summary>A fixture wall-clock time (UTC+7) as a UTC instant.</summary>
        private static DateTime Utc(string wall) =>
            DateTime.SpecifyKind(
                DateTime.ParseExact(wall, WallFormat, CultureInfo.InvariantCulture) - Offset,
                DateTimeKind.Utc);

        private static string Wall(DateTime utc) =>
            (utc + Offset).ToString(WallFormat, CultureInfo.InvariantCulture);

        private static Event Series(string rule, DateTime startUtc, IEnumerable<DateTime>? exceptions = null)
        {
            var series = new Event
            {
                Title = "Series",
                StartTime = startUtc,
                EndTime = startUtc + Duration,
                RecurrenceRule = rule,
            };
            foreach (var exception in exceptions ?? Array.Empty<DateTime>())
            {
                RecurrenceExceptions.Add(series, exception);
            }
            return series;
        }

        private static Event DayOf(Event series, DateTime occurrenceUtc) => new()
        {
            Title = series.Title,
            StartTime = occurrenceUtc,
            EndTime = occurrenceUtc + Duration,
            ParentEventId = series.Id,
            ExceptionDate = occurrenceUtc,
        };

        private static Event OneOff(DateTime startUtc) => new()
        {
            Title = "One-off",
            StartTime = startUtc,
            EndTime = startUtc + Duration,
        };
    }
}
