using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;

namespace HabitTracker.Domain.Interfaces
{
    public interface IEventRepository
    {
        Task<IEnumerable<Event>> GetEventsForUserAsync(string userId, DateTime? startTime = null, DateTime? endTime = null);

        /// <summary>
        /// Completed events belonging to one user, read-only. Used for streak and XP maths,
        /// so the entities are untracked — callers may treat them as a scratch copy without
        /// the change tracker writing those edits back to the database.
        /// </summary>
        Task<IEnumerable<Event>> GetCompletedEventsForUserAsync(string userId);

        /// <summary>
        /// Completed events attached to one habit, read-only (untracked). Filtered in SQL so
        /// the cost scales with the habit's history rather than the whole Events table.
        /// </summary>
        Task<IEnumerable<Event>> GetCompletedEventsForHabitAsync(Guid habitId);

        /// <summary>
        /// Per-day counts and focus minutes for one user, between <paramref name="fromUtc"/>
        /// (inclusive) and <paramref name="toUtc"/> (exclusive).
        /// </summary>
        /// <remarks>
        /// Aggregated by the database, not in memory: this powers a dashboard, and
        /// loading every event a user has ever had in order to count them would get
        /// slower for exactly the people who use the app most. Days with no events are
        /// absent from the result rather than present as zeroes — the caller fills the
        /// gaps, because only it knows the window it asked about.
        /// </remarks>
        Task<IEnumerable<DailyActivity>> GetDailyActivityAsync(string userId, DateTime fromUtc, DateTime toUtc);

        Task<Event?> GetByIdAsync(Guid id);
        Task AddAsync(Event ev);
        Task UpdateAsync(Event ev);
        Task DeleteAsync(Guid id);
    }
}
