using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;

namespace HabitTracker.Domain.Interfaces
{
    public interface IGoogleCalendarOutboxRepository
    {
        Task EnqueueAsync(string userId, Guid eventId, string? googleEventId, string action, string payload, CancellationToken cancellationToken = default);
        Task<IEnumerable<GoogleCalendarOutbox>> GetUnprocessedAsync(int limit = 50, CancellationToken cancellationToken = default);
        Task UpdateAsync(GoogleCalendarOutbox entry, CancellationToken cancellationToken = default);

        /// <summary>
        /// Whether an Insert for this event is still waiting to be sent. Together with
        /// <see cref="Entities.Event.GoogleEventId"/> it says whether Google knows, or is about
        /// to know, the event — an Update for an event it will never know cannot succeed.
        /// An Insert the worker has given up on (<see cref="GoogleCalendarOutbox.MaxRetries"/>)
        /// does not count.
        /// </summary>
        Task<bool> HasPendingInsertAsync(Guid eventId, CancellationToken cancellationToken = default);
    }
}
