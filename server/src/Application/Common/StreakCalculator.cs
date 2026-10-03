using System;
using System.Collections.Generic;
using System.Linq;
using HabitTracker.Domain.Entities;

namespace HabitTracker.Application.Common
{
    /// <summary>Current and longest run of consecutive active days.</summary>
    public readonly record struct StreakResult(int Current, int Longest)
    {
        public static StreakResult None => new(0, 0);
    }

    /// <summary>
    /// One definition of "what counts as a streak", shared by every handler that reports one.
    /// It used to be copy-pasted into four files, in two subtly different variants, so a fix had
    /// to be made four times.
    /// </summary>
    public static class StreakCalculator
    {
        /// <summary>
        /// Offset used to decide which calendar day an event belongs to.
        /// <para>
        /// This is a single app-wide value (UTC+7), which is where the app started. It is wrong
        /// for users outside that zone: their streaks and heatmaps shift by a day. Fixing that
        /// properly means deciding whose day boundary wins — the device's or a profile setting —
        /// and then storing a timezone per user. Until that product decision is made, this
        /// constant is the one place to change it, and every caller can pass an explicit offset.
        /// </para>
        /// </summary>
        public static readonly TimeSpan DefaultDayBoundaryOffset = TimeSpan.FromHours(7);

        /// <summary>The calendar day an instant falls on, under the given day boundary.</summary>
        public static DateTime ToLocalDate(DateTime dt, TimeSpan? dayBoundaryOffset = null)
        {
            var offset = dayBoundaryOffset ?? DefaultDayBoundaryOffset;

            var utc = dt.Kind switch
            {
                DateTimeKind.Utc => dt,
                DateTimeKind.Local => dt.ToUniversalTime(),
                _ => DateTime.SpecifyKind(dt, DateTimeKind.Utc)
            };

            return utc.Add(offset).Date;
        }

        /// <summary>Streaks for a set of completed events, keyed on their start time.</summary>
        public static StreakResult FromEvents(
            IEnumerable<Event> completedEvents,
            TimeSpan? dayBoundaryOffset = null)
        {
            ArgumentNullException.ThrowIfNull(completedEvents);

            return FromStartTimes(completedEvents.Select(e => e.StartTime), dayBoundaryOffset);
        }

        /// <summary>Streaks for a set of completion instants.</summary>
        public static StreakResult FromStartTimes(
            IEnumerable<DateTime> startTimes,
            TimeSpan? dayBoundaryOffset = null)
        {
            ArgumentNullException.ThrowIfNull(startTimes);

            var offset = dayBoundaryOffset ?? DefaultDayBoundaryOffset;

            var completionDates = startTimes
                .Select(t => ToLocalDate(t, offset))
                .Distinct()
                .OrderBy(d => d)
                .ToList();

            if (completionDates.Count == 0)
            {
                return StreakResult.None;
            }

            var longest = 0;
            var run = 0;
            DateTime? previous = null;

            foreach (var date in completionDates)
            {
                run = previous.HasValue && date == previous.Value.AddDays(1) ? run + 1 : 1;

                if (run > longest) longest = run;
                previous = date;
            }

            // A streak only "counts" while it is still alive: it must reach today, or yesterday
            // (the user still has today to keep it going).
            var today = ToLocalDate(DateTime.UtcNow, offset);
            var isAlive = previous!.Value == today || previous.Value == today.AddDays(-1);

            return new StreakResult(isAlive ? run : 0, longest);
        }
    }
}
