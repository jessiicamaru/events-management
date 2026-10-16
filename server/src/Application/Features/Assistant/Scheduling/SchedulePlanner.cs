using HabitTracker.Application.Common;

namespace HabitTracker.Application.Features.Assistant.Scheduling
{
    /// <summary>A time of day the user is willing to use, e.g. 05:00–06:00, in local time.</summary>
    public sealed record TimeWindow(TimeSpan Start, TimeSpan End);

    /// <summary>A day on which a candidate slot overlaps something already booked.</summary>
    public sealed record SlotConflict(DateOnly Date, string Title);

    /// <summary>The best start time found inside one window, and what it would clash with.</summary>
    /// <param name="WindowIndex">Which of the user's windows it came from, in the order they gave them.</param>
    public sealed record SlotOption(TimeSpan Start, int WindowIndex, IReadOnlyList<SlotConflict> Conflicts);

    /// <summary>
    /// Finds when a repeating session fits: for each window the user offers, the start time
    /// that clashes with the fewest booked occurrences over the coming days.
    /// </summary>
    /// <remarks>
    /// Pure, so it is tested without a database. Clashes are judged against occurrences —
    /// repeating events already expanded into days — so a Tuesday gym session blocks Tuesdays
    /// and nothing else.
    /// </remarks>
    public static class SchedulePlanner
    {
        /// <summary>Candidate start times are tried at this spacing inside a window.</summary>
        public static readonly TimeSpan Step = TimeSpan.FromMinutes(15);

        /// <summary>How many days ahead a slot is checked for clashes.</summary>
        public const int HorizonDays = 14;

        /// <summary>The dates from <paramref name="first"/> over the horizon that fall on <paramref name="isoDays"/> (1 = Monday).</summary>
        public static IReadOnlyList<DateOnly> PlannedDates(DateOnly first, IReadOnlyCollection<int> isoDays, int horizonDays = HorizonDays) =>
            Enumerable.Range(0, horizonDays)
                .Select(first.AddDays)
                .Where(d => isoDays.Contains(IsoDay(d)))
                .ToList();

        /// <summary>
        /// The best option in each window that can hold <paramref name="duration"/>, best first:
        /// fewest clashing days, then the user's order of windows. Inside a window the earliest
        /// start wins a tie.
        /// </summary>
        public static IReadOnlyList<SlotOption> BestPerWindow(
            IReadOnlyList<TimeWindow> windows,
            TimeSpan duration,
            IReadOnlyList<DateOnly> dates,
            IReadOnlyList<EventOccurrence> booked,
            TimeSpan localOffset)
        {
            var options = new List<SlotOption>();

            for (var w = 0; w < windows.Count; w++)
            {
                SlotOption? best = null;
                for (var start = windows[w].Start; start + duration <= windows[w].End; start += Step)
                {
                    var conflicts = ConflictsAt(start, duration, dates, booked, localOffset);
                    if (best == null || conflicts.Count < best.Conflicts.Count)
                    {
                        best = new SlotOption(start, w, conflicts);
                    }

                    if (best.Conflicts.Count == 0) break;
                }

                if (best != null) options.Add(best);
            }

            return options
                .OrderBy(o => o.Conflicts.Count)
                .ThenBy(o => o.WindowIndex)
                .ToList();
        }

        /// <summary>1 = Monday … 7 = Sunday, as <c>Habit.TargetDays</c> stores it.</summary>
        public static int IsoDay(DateOnly date) => date.DayOfWeek == DayOfWeek.Sunday ? 7 : (int)date.DayOfWeek;

        /// <summary>The UTC instant of <paramref name="time"/> on <paramref name="date"/>, local time.</summary>
        public static DateTime ToUtc(DateOnly date, TimeSpan time, TimeSpan localOffset) =>
            DateTime.SpecifyKind(date.ToDateTime(TimeOnly.MinValue) + time - localOffset, DateTimeKind.Utc);

        private static IReadOnlyList<SlotConflict> ConflictsAt(
            TimeSpan start,
            TimeSpan duration,
            IReadOnlyList<DateOnly> dates,
            IReadOnlyList<EventOccurrence> booked,
            TimeSpan localOffset)
        {
            var conflicts = new List<SlotConflict>();
            foreach (var date in dates)
            {
                var from = ToUtc(date, start, localOffset);
                var to = from + duration;
                var clash = booked.FirstOrDefault(o => o.Start < to && o.End > from);
                if (clash != null) conflicts.Add(new SlotConflict(date, clash.Event.Title));
            }

            return conflicts;
        }
    }
}
