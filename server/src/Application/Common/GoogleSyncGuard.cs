using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;

namespace HabitTracker.Application.Common
{
    /// <summary>
    /// Decides whether a change to an event can be sent to Google as an Update.
    /// </summary>
    public static class GoogleSyncGuard
    {
        /// <summary>
        /// True when Google has the event (it has a <see cref="Event.GoogleEventId"/>) or is
        /// about to (its Insert is still queued).
        /// </summary>
        /// <remarks>
        /// Otherwise an Update can never succeed: the sync worker throws "missing
        /// GoogleEventId" and retries it until it gives up. That is the normal state of a day
        /// split off a series for local reasons — a ticked task, a finished session — which
        /// Google was deliberately never told about.
        /// </remarks>
        public static async Task<bool> GoogleKnowsAsync(
            Event ev,
            IGoogleCalendarOutboxRepository outbox,
            CancellationToken cancellationToken = default)
        {
            if (!string.IsNullOrEmpty(ev.GoogleEventId)) return true;

            return await outbox.HasPendingInsertAsync(ev.Id, cancellationToken);
        }
    }
}
