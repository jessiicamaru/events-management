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

        /// <summary>
        /// The child event that stands in for one occurrence of a repeating series, if that
        /// day has been split off — matched to the minute on <see cref="Event.ExceptionDate"/>,
        /// the same precision the client uses to substitute it for the series' occurrence.
        /// </summary>
        Task<Event?> GetOccurrenceChildAsync(Guid seriesId, DateTime occurrenceStartUtc);

        /// <summary>Every day that has been split off <paramref name="seriesId"/>, tracked for update.</summary>
        Task<IEnumerable<Event>> GetChildrenAsync(Guid seriesId);

        /// <summary>
        /// Adds a day split off a series (<see cref="Event.ParentEventId"/> +
        /// <see cref="Event.ExceptionDate"/>), unless that day of the series already has an event.
        /// </summary>
        /// <returns>
        /// False, having added nothing, when another event already stands for the same minute
        /// of the same series — typically one added a moment earlier by a concurrent request.
        /// Read it back with <see cref="GetOccurrenceChildAsync"/>.
        /// </returns>
        /// <remarks>
        /// The database enforces one event per series and minute, so a check followed by a plain
        /// <see cref="AddAsync"/> can still fail when two requests split off the same day at once
        /// (two devices, or a ticked task racing a finished session). Safe inside a transaction:
        /// the transaction stays usable after a refused add.
        /// </remarks>
        Task<bool> TryAddOccurrenceDayAsync(Event day);

        Task<Event?> GetByIdAsync(Guid id);
        Task AddAsync(Event ev);
        Task UpdateAsync(Event ev);
        Task DeleteAsync(Guid id);
    }
}
