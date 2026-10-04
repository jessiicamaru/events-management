using System;

namespace HabitTracker.Domain.Entities
{
    /// <summary>
    /// One day's worth of a user's activity, aggregated by the database.
    /// </summary>
    /// <remarks>
    /// Not a table — this is the shape a <c>GROUP BY</c> returns. It lives in Domain
    /// because <see cref="Interfaces.IEventRepository"/> returns it, and Domain may not
    /// reference Infrastructure.
    /// </remarks>
    public class DailyActivity
    {
        /// <summary>
        /// The calendar day, under the same UTC+7 day boundary that
        /// <c>StreakCalculator</c> uses. They have to agree: a dashboard that counted
        /// a late-evening event on the following day would contradict the streak
        /// shown next to it.
        /// </summary>
        public DateTime Date { get; set; }

        /// <summary>Events starting on this day, completed or not.</summary>
        public int Scheduled { get; set; }

        /// <summary>Of those, the ones marked complete.</summary>
        public int Completed { get; set; }

        /// <summary>
        /// Total recorded focus time on this day, in whole minutes, from
        /// <see cref="Event.ActualDuration"/>. Only a finished focus session writes
        /// that field, so this counts time actually spent rather than time booked.
        /// </summary>
        public int FocusMinutes { get; set; }
    }
}
