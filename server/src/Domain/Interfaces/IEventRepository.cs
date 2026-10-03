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

        Task<Event?> GetByIdAsync(Guid id);
        Task AddAsync(Event ev);
        Task UpdateAsync(Event ev);
        Task DeleteAsync(Guid id);
    }
}
