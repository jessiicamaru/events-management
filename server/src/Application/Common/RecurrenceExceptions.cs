using System;
using System.Globalization;
using System.Linq;
using HabitTracker.Domain.Entities;

namespace HabitTracker.Application.Common
{
    /// <summary>
    /// Reading and writing a series' <see cref="Event.RecurrenceExceptionDates"/> — the days
    /// the series itself no longer produces.
    /// </summary>
    /// <remarks>
    /// <para>
    /// A date is in that list when the day was deleted, edited on its own, or cancelled in
    /// Google. A day split off only locally — by a ticked task or a finished session — is
    /// never in it. That difference is what tells a "touched" day (which should keep following
    /// the series) from an edited one (which keeps its own content), so the list has to be
    /// read and written the same way everywhere.
    /// </para>
    /// <para>
    /// Matched to the minute, like every other occurrence comparison: an exception is recorded
    /// against a day's slot, and seconds carry no meaning there. The stored format is kept as it
    /// always was, so existing rows and the client's parser keep working.
    /// </para>
    /// </remarks>
    public static class RecurrenceExceptions
    {
        /// <summary>How a date is written into the list.</summary>
        public const string EntryFormat = "yyyy-MM-ddTHH:mm:ssZ";

        public static string ToEntry(DateTime occurrence) =>
            ToUtc(occurrence).ToString(EntryFormat, CultureInfo.InvariantCulture);

        /// <summary>Whether <paramref name="occurrence"/>'s slot is in the series' exception list.</summary>
        public static bool Contains(Event series, DateTime occurrence)
        {
            var stored = series.RecurrenceExceptionDates;
            if (string.IsNullOrEmpty(stored)) return false;

            var minute = TruncateToMinute(ToUtc(occurrence));

            return stored
                .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                .Any(raw => DateTime.TryParse(raw, CultureInfo.InvariantCulture,
                        DateTimeStyles.AdjustToUniversal | DateTimeStyles.AssumeUniversal, out var parsed)
                    && TruncateToMinute(parsed) == minute);
        }

        /// <summary>Adds <paramref name="occurrence"/>'s slot to the list, unless it is already there.</summary>
        public static void Add(Event series, DateTime occurrence)
        {
            if (Contains(series, occurrence)) return;

            var entry = ToEntry(occurrence);
            series.RecurrenceExceptionDates = string.IsNullOrEmpty(series.RecurrenceExceptionDates)
                ? entry
                : series.RecurrenceExceptionDates + "," + entry;
        }

        internal static DateTime ToUtc(DateTime value) => value.Kind switch
        {
            DateTimeKind.Utc => value,
            DateTimeKind.Local => value.ToUniversalTime(),
            _ => DateTime.SpecifyKind(value, DateTimeKind.Utc)
        };

        internal static DateTime TruncateToMinute(DateTime value) =>
            new(value.Year, value.Month, value.Day, value.Hour, value.Minute, 0, value.Kind);
    }
}
