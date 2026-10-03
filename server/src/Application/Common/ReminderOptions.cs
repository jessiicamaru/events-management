using System.Collections.Generic;
using System.Linq;

namespace HabitTracker.Application.Common
{
    /// <summary>
    /// The reminder offsets an event may carry, and how a client-supplied set is cleaned up.
    ///
    /// Reminders fire on the device, so the server never acts on these values — but it is
    /// the only place both clients agree on, so validation belongs here rather than being
    /// trusted from whatever the app sent.
    /// </summary>
    public static class ReminderOptions
    {
        /// <summary>
        /// Minutes before the start that a reminder may be set for. `0` is "when it starts".
        /// An empty set on an event means no reminders at all.
        /// </summary>
        public static readonly IReadOnlySet<int> AllowedMinutesBefore =
            new HashSet<int> { 0, 5, 15, 30, 60 };

        /// <summary>One reminder per allowed offset is the natural ceiling.</summary>
        public static int MaxPerEvent => AllowedMinutesBefore.Count;

        /// <summary>
        /// Drops unknown offsets and duplicates, then orders earliest-first (largest offset
        /// first) so the stored list reads the way it is shown: "1 hour, 30 min, 5 min".
        ///
        /// Returns an empty list for null — "no reminders" is a valid choice, not a missing
        /// value to be defaulted.
        /// </summary>
        public static List<int> Normalise(IEnumerable<int>? minutesBefore)
        {
            if (minutesBefore == null) return new List<int>();

            return minutesBefore
                .Where(AllowedMinutesBefore.Contains)
                .Distinct()
                .OrderByDescending(m => m)
                .Take(MaxPerEvent)
                .ToList();
        }
    }
}
