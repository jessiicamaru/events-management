using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using HabitTracker.Domain.Entities;
using Ical.Net.CalendarComponents;
using Ical.Net.DataTypes;

namespace HabitTracker.Application.Common
{
    /// <summary>
    /// One concrete occurrence: a single event, a split-off day, or one day of a series.
    /// </summary>
    /// <param name="Event">
    /// The row it comes from. For a day of a series this is the <b>series</b> row, so every day
    /// of it shares that row's id — which is why <paramref name="IsSeriesDay"/> is needed to
    /// address one day.
    /// </param>
    /// <param name="Start">Start of this occurrence, in UTC.</param>
    /// <param name="End">End of this occurrence, in UTC.</param>
    /// <param name="IsSeriesDay">
    /// True when this is a day the series itself produces; <paramref name="Start"/> is then the
    /// value an "edit this occurrence" request carries as its original occurrence date.
    /// </param>
    public sealed record EventOccurrence(Event Event, DateTime Start, DateTime End, bool IsSeriesDay);

    /// <summary>
    /// Turns stored events into the concrete occurrences that fall in a window — the server's
    /// counterpart of the client's <c>EventOccurrenceExpander</c>.
    /// </summary>
    /// <remarks>
    /// <para>
    /// A repeating event is one row plus an RRULE. The client has always expanded it, so the
    /// server could not answer "what is happening this week" on its own. Anything that reasons
    /// about days — free time, what was done or missed, an assistant moving "this week's runs" —
    /// needs that answer, and it has to be the <b>same</b> answer the calendar shows. The rules
    /// are therefore the client's, checked against it by a shared fixture
    /// (<c>test-fixtures/recurrence-expansion.json</c>):
    /// </para>
    /// <list type="bullet">
    /// <item>Rules are evaluated in local wall-clock time, so BYDAY and "every day at 06:00"
    /// mean the user's Monday and 06:00. Local is the app-wide UTC+7 day boundary
    /// (<see cref="StreakCalculator.DefaultDayBoundaryOffset"/>) unless an offset is given.</item>
    /// <item>A day in the series' exception list is dropped (<see cref="RecurrenceExceptions"/>).</item>
    /// <item>A day that already has its own event — split off or edited — is dropped, and that
    /// event is returned as it is instead (<see cref="OccurrenceMaterializer.StandsFor"/>).</item>
    /// <item>A day of a series starts undone: completion lives on a split-off day's own event.</item>
    /// <item>A rule that cannot be read produces no days, as on the client (roadmap 5.3a).</item>
    /// </list>
    /// <para>
    /// Events that do not repeat are returned when they overlap the window. The client passes
    /// them all through and leaves windowing to the caller; the server always wants a window,
    /// so it applies one here.
    /// </para>
    /// </remarks>
    public static class RecurrenceExpander
    {
        private const string RulePrefix = "RRULE:";
        private const string UntilKey = "UNTIL=";
        private const string UtcUntilFormat = "yyyyMMdd'T'HHmmss'Z'";
        private const string LocalUntilFormat = "yyyyMMdd'T'HHmmss";

        /// <summary>
        /// Every occurrence of <paramref name="events"/> starting in
        /// [<paramref name="fromUtc"/>, <paramref name="toUtc"/>), plus non-repeating events that
        /// overlap it, ordered by start.
        /// </summary>
        public static IReadOnlyList<EventOccurrence> Expand(
            IEnumerable<Event> events,
            DateTime fromUtc,
            DateTime toUtc,
            TimeSpan? localOffset = null)
        {
            ArgumentNullException.ThrowIfNull(events);

            var all = events as IReadOnlyCollection<Event> ?? events.ToList();
            var offset = localOffset ?? StreakCalculator.DefaultDayBoundaryOffset;
            var from = RecurrenceExceptions.ToUtc(fromUtc);
            var to = RecurrenceExceptions.ToUtc(toUtc);
            var result = new List<EventOccurrence>();

            foreach (var ev in all)
            {
                if (OccurrenceMaterializer.IsSeries(ev))
                {
                    result.AddRange(ExpandSeries(ev, all, from, to, offset));
                    continue;
                }

                var start = RecurrenceExceptions.ToUtc(ev.StartTime);
                var end = RecurrenceExceptions.ToUtc(ev.EndTime);
                if (start < to && end > from)
                {
                    result.Add(new EventOccurrence(ev, start, end, IsSeriesDay: false));
                }
            }

            return result.OrderBy(o => o.Start).ToList();
        }

        /// <summary>
        /// The start times, in UTC, that <paramref name="series"/>' rule produces in the window —
        /// before exceptions and split-off days are taken out. Empty when the rule cannot be read.
        /// </summary>
        public static IReadOnlyList<DateTime> RuleOccurrences(
            Event series,
            DateTime fromUtc,
            DateTime toUtc,
            TimeSpan? localOffset = null)
        {
            ArgumentNullException.ThrowIfNull(series);

            var offset = localOffset ?? StreakCalculator.DefaultDayBoundaryOffset;
            var pattern = ParseRule(series.RecurrenceRule, offset);
            if (pattern == null) return Array.Empty<DateTime>();

            var from = RecurrenceExceptions.ToUtc(fromUtc);
            var to = RecurrenceExceptions.ToUtc(toUtc);
            var localStart = RecurrenceExceptions.ToUtc(series.StartTime) + offset;

            // Floating (zone-less) times: the rule runs on the wall clock, and UNTIL was moved
            // onto the same clock by ParseRule.
            var calendarEvent = new CalendarEvent { DtStart = new CalDateTime(localStart) };
            calendarEvent.RecurrenceRules.Add(pattern);

            try
            {
                // Enumerated from the series' own start, so COUNT is counted from there and not
                // from the window.
                return calendarEvent.GetOccurrences()
                    .Select(o => DateTime.SpecifyKind(o.Period.StartTime.Value - offset, DateTimeKind.Utc))
                    .TakeWhile(start => start < to)
                    .Where(start => start >= from)
                    .ToList();
            }
            catch (Exception ex) when (ex is ArgumentException or FormatException or InvalidOperationException)
            {
                return Array.Empty<DateTime>();
            }
        }

        private static IEnumerable<EventOccurrence> ExpandSeries(
            Event series,
            IReadOnlyCollection<Event> all,
            DateTime from,
            DateTime to,
            TimeSpan offset)
        {
            var duration = RecurrenceExceptions.ToUtc(series.EndTime) - RecurrenceExceptions.ToUtc(series.StartTime);

            foreach (var start in RuleOccurrences(series, from, to, offset))
            {
                if (RecurrenceExceptions.Contains(series, start)) continue;
                if (OccurrenceMaterializer.FindDay(all, series, start) != null) continue;

                yield return new EventOccurrence(series, start, start + duration, IsSeriesDay: true);
            }
        }

        /// <summary>
        /// Reads a stored rule, with or without its <c>RRULE:</c> prefix. A UTC UNTIL is moved
        /// onto the local wall clock the rule is evaluated on. Null when there is nothing usable.
        /// </summary>
        private static RecurrencePattern? ParseRule(string? stored, TimeSpan offset)
        {
            if (string.IsNullOrWhiteSpace(stored)) return null;

            var rule = stored.Trim();
            if (rule.StartsWith(RulePrefix, StringComparison.OrdinalIgnoreCase))
            {
                rule = rule[RulePrefix.Length..];
            }

            var parts = rule.Split(';', StringSplitOptions.RemoveEmptyEntries)
                .Select(part => ToLocalUntil(part, offset));

            try
            {
                return new RecurrencePattern(string.Join(';', parts));
            }
            catch (Exception ex) when (ex is ArgumentException or FormatException or InvalidOperationException)
            {
                return null;
            }
        }

        private static string ToLocalUntil(string part, TimeSpan offset)
        {
            if (!part.StartsWith(UntilKey, StringComparison.OrdinalIgnoreCase)) return part;

            var value = part[UntilKey.Length..];
            if (!DateTime.TryParseExact(value, UtcUntilFormat, CultureInfo.InvariantCulture,
                    DateTimeStyles.AdjustToUniversal | DateTimeStyles.AssumeUniversal, out var utc))
            {
                // A date or a floating date-time is already on the wall clock.
                return part;
            }

            return UntilKey + (utc + offset).ToString(LocalUntilFormat, CultureInfo.InvariantCulture);
        }
    }
}
