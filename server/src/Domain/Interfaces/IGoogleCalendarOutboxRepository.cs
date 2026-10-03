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
    }
}
