using System;
using System.Globalization;
using HabitTracker.Domain.Entities;

namespace HabitTracker.Application.Common
{
    /// <summary>
    /// The span of Google's calendar one incoming sync lists, and which local events that list
    /// can speak for.
    /// </summary>
    /// <remarks>
    /// <para>
    /// Incoming sync removes the synced events Google no longer has. It used to take "not in the
    /// list" as "gone", for every synced event the user had, while the list only covers a window
    /// — by default a week back and two weeks ahead, or just the range the calendar is showing.
    /// So each sync deleted the user's synced history and everything past the window, with its
    /// tasks and completion (roadmap 5.8).
    /// </para>
    /// <para>
    /// An event missing from the list is now only a <em>candidate</em>, and only if
    /// <see cref="CouldBeListed"/>: Google would have listed it had it still existed. Even then
    /// the service looks it up before deleting, because the local copy's time may be stale (moved
    /// on Google) and Google does not document how it filters a recurring series by time.
    /// </para>
    /// </remarks>
    public static class GoogleSyncWindow
    {
        /// <summary>How far back a sync looks when no range is asked for.</summary>
        public static readonly TimeSpan DefaultLookBack = TimeSpan.FromDays(7);

        /// <summary>How far ahead a sync looks when no range is asked for.</summary>
        public static readonly TimeSpan DefaultLookAhead = TimeSpan.FromDays(14);

        private const string UntilPart = "UNTIL=";
        private const string RulePrefix = "RRULE:";
        private const string UtcSuffix = "Z";

        /// <summary>
        /// RFC 5545's forms, plus the one the app's recurrence dialog writes — a space where the
        /// standard has <c>T</c> (<c>UNTIL=20260820 165959Z</c>).
        /// </summary>
        private static readonly string[] UntilFormats =
        {
            "yyyyMMdd'T'HHmmss'Z'", "yyyyMMdd' 'HHmmss'Z'", "yyyyMMdd'T'HHmmss", "yyyyMMdd",
        };

        /// <summary>
        /// Whether Google's list for [<paramref name="windowStart"/>, <paramref name="windowEnd"/>)
        /// would have contained <paramref name="local"/>, going by its stored times. Google keeps
        /// an event whose end is after the window's start and whose start is before the window's
        /// end, both exclusive.
        /// </summary>
        public static bool CouldBeListed(Event local, DateTime windowStart, DateTime windowEnd)
        {
            if (local.StartTime >= windowEnd) return false;

            var lastEnd = string.IsNullOrEmpty(local.RecurrenceRule)
                ? local.EndTime
                : SeriesLastEnd(local);

            return lastEnd > windowStart;
        }

        /// <summary>
        /// When a series' last day ends: its UNTIL plus one day's length, or never. A COUNT, or an
        /// UNTIL that cannot be read, counts as never — a wrong "never" costs one lookup, a wrong
        /// end date would hide a deletion. For the same reason an UNTIL that is not in UTC — a
        /// date, or a floating local time — is given a day's grace, the widest a time zone can
        /// move it.
        /// </summary>
        private static DateTime SeriesLastEnd(Event series)
        {
            var rule = series.RecurrenceRule!;
            if (rule.StartsWith(RulePrefix, StringComparison.OrdinalIgnoreCase))
            {
                rule = rule[RulePrefix.Length..];
            }

            foreach (var part in rule.Split(';', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries))
            {
                if (!part.StartsWith(UntilPart, StringComparison.OrdinalIgnoreCase)) continue;

                var value = part[UntilPart.Length..];
                if (DateTime.TryParseExact(
                        value,
                        UntilFormats,
                        CultureInfo.InvariantCulture,
                        DateTimeStyles.AdjustToUniversal | DateTimeStyles.AssumeUniversal,
                        out var until))
                {
                    var lastStart = value.EndsWith(UtcSuffix, StringComparison.OrdinalIgnoreCase) ? until : until.AddDays(1);
                    return lastStart + (series.EndTime - series.StartTime);
                }

                break;
            }

            return DateTime.MaxValue;
        }
    }
}
