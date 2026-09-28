using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;

namespace HabitTracker.Domain.Interfaces
{
    public interface IGoogleCalendarSyncCacheRepository
    {
        Task<IEnumerable<GoogleCalendarSyncCache>> GetForUserAsync(string userId, CancellationToken cancellationToken = default);
        Task<bool> IsRangeSyncedAsync(string userId, DateTime startTime, DateTime endTime, CancellationToken cancellationToken = default);
        Task SaveSyncRangeAsync(string userId, DateTime startTime, DateTime endTime, CancellationToken cancellationToken = default);
    }
}
