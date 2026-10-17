using System;
using System.Collections.Generic;
using System.Linq;
using HabitTracker.Domain.Entities;

namespace HabitTracker.Application.Common
{
    /// <summary>Sessions that were on the calendar and are over, and how many of them were done.</summary>
    public sealed record AdherenceCount(int Planned, int Done)
    {
        public int Missed => Planned - Done;

        /// <summary>Done as a whole percentage of planned; null when nothing was planned.</summary>
        public int? RatePercent => Planned == 0
            ? null
            : (int)Math.Round(100.0 * Done / Planned, MidpointRounding.AwayFromZero);
    }

    /// <summary>How one habit went over a window, overall and by local weekday and start hour.</summary>
    /// <param name="ByWeekday">Keyed 1 = Monday … 7 = Sunday; only days that had a session.</param>
    /// <param name="ByHour">Keyed by local start hour, 0–23; only hours that had a session.</param>
    /// <param name="LastDone">Local date of the latest done session in the window.</param>
    /// <param name="MissedDates">Local dates of the missed sessions, earliest first.</param>
    public sealed record HabitAdherenceResult(
        Habit Habit,
        AdherenceCount Total,
        IReadOnlyDictionary<int, AdherenceCount> ByWeekday,
        IReadOnlyDictionary<int, AdherenceCount> ByHour,
        DateOnly? LastDone,
        IReadOnlyList<DateOnly> MissedDates);

    /// <summary>
    /// Planned against kept sessions per habit (roadmap 2.2), counted from the occurrences the
    /// calendar shows.
    /// </summary>
    /// <remarks>
    /// <para>
    /// Most habits are repeating series, and a series is one row whose days exist only once
    /// expanded — so these counts cannot be a SQL <c>GROUP BY</c>, which sees one row per series
    /// (the reason <c>get_stats</c> leaves repeating days out). They are counted here, over one
    /// user's events in a bounded window, on the same expansion as the calendar
    /// (<see cref="RecurrenceExpander"/>): a deleted day is not planned, and a day's completion
    /// lives on its split-off event, since a day of the series itself starts undone.
    /// </para>
    /// <para>
    /// A session counts once it is over, or once it is done: one still running or later today is
    /// not yet missed, and one done early is already kept.
    /// </para>
    /// </remarks>
    public static class HabitAdherence
    {
        public static IReadOnlyList<HabitAdherenceResult> Compute(
            IEnumerable<Habit> habits,
            IEnumerable<Event> events,
            DateTime fromUtc,
            DateTime nowUtc,
            TimeSpan offset)
        {
            ArgumentNullException.ThrowIfNull(habits);
            ArgumentNullException.ThrowIfNull(events);

            var from = RecurrenceExceptions.ToUtc(fromUtc);
            var now = RecurrenceExceptions.ToUtc(nowUtc);

            var counted = RecurrenceExpander.Expand(events, from, EndOfLocalDay(now, offset), offset)
                .Where(o => o.Start >= from)
                .Select(o => new { o.Event.HabitId, Local = o.Start + offset, Done = IsDone(o), o.End })
                .Where(o => o.Done || o.End <= now)
                .ToLookup(o => o.HabitId, StringComparer.OrdinalIgnoreCase);

            return habits.Select(habit =>
            {
                var sessions = counted[habit.Id.ToString()].ToList();
                return new HabitAdherenceResult(
                    habit,
                    Count(sessions.Select(s => s.Done)),
                    sessions.GroupBy(s => IsoDay(s.Local))
                        .ToDictionary(g => g.Key, g => Count(g.Select(s => s.Done))),
                    sessions.GroupBy(s => s.Local.Hour)
                        .ToDictionary(g => g.Key, g => Count(g.Select(s => s.Done))),
                    sessions.Where(s => s.Done)
                        .Select(s => (DateOnly?)DateOnly.FromDateTime(s.Local))
                        .Max(),
                    sessions.Where(s => !s.Done)
                        .Select(s => DateOnly.FromDateTime(s.Local))
                        .Order()
                        .ToList());
            }).ToList();
        }

        /// <summary>
        /// The next local midnight after <paramref name="nowUtc"/>, in UTC — how far to load events,
        /// so a session later today that is already done is seen.
        /// </summary>
        public static DateTime EndOfLocalDay(DateTime nowUtc, TimeSpan offset)
        {
            var tomorrow = DateOnly.FromDateTime(RecurrenceExceptions.ToUtc(nowUtc) + offset).AddDays(1);
            return DateTime.SpecifyKind(tomorrow.ToDateTime(TimeOnly.MinValue) - offset, DateTimeKind.Utc);
        }

        /// <summary>A day of a series starts undone: completion lives on a split-off day's own row.</summary>
        private static bool IsDone(EventOccurrence occurrence) => !occurrence.IsSeriesDay && occurrence.Event.IsCompleted;

        private static AdherenceCount Count(IEnumerable<bool> done)
        {
            var list = done.ToList();
            return new AdherenceCount(list.Count, list.Count(d => d));
        }

        private static int IsoDay(DateTime local) => local.DayOfWeek == DayOfWeek.Sunday ? 7 : (int)local.DayOfWeek;
    }
}
