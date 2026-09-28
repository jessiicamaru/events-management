using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using HabitTracker.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace HabitTracker.Infrastructure.Repositories
{
    public class GoogleCalendarSyncCacheRepository : IGoogleCalendarSyncCacheRepository
    {
        private readonly ApplicationDbContext _context;

        public GoogleCalendarSyncCacheRepository(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<GoogleCalendarSyncCache>> GetForUserAsync(string userId, CancellationToken cancellationToken = default)
        {
            return await _context.GoogleCalendarSyncCaches
                .Where(c => c.UserId == userId)
                .ToListAsync(cancellationToken);
        }

        public async Task<bool> IsRangeSyncedAsync(string userId, DateTime startTime, DateTime endTime, CancellationToken cancellationToken = default)
        {
            return await _context.GoogleCalendarSyncCaches
                .AnyAsync(c => c.UserId == userId && c.SyncedFrom <= startTime && c.SyncedTo >= endTime, cancellationToken);
        }

        public async Task SaveSyncRangeAsync(string userId, DateTime startTime, DateTime endTime, CancellationToken cancellationToken = default)
        {
            var caches = await _context.GoogleCalendarSyncCaches
                .Where(c => c.UserId == userId)
                .ToListAsync(cancellationToken);

            var overlapping = caches.Where(c => c.SyncedFrom <= endTime && c.SyncedTo >= startTime).ToList();

            var mergedStart = startTime;
            var mergedEnd = endTime;

            if (overlapping.Any())
            {
                var minOverlappingStart = overlapping.Min(c => c.SyncedFrom);
                var maxOverlappingEnd = overlapping.Max(c => c.SyncedTo);
                mergedStart = minOverlappingStart < startTime ? minOverlappingStart : startTime;
                mergedEnd = maxOverlappingEnd > endTime ? maxOverlappingEnd : endTime;

                _context.GoogleCalendarSyncCaches.RemoveRange(overlapping);
            }

            await _context.GoogleCalendarSyncCaches.AddAsync(new GoogleCalendarSyncCache
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                SyncedFrom = mergedStart,
                SyncedTo = mergedEnd,
                LastSyncedAt = DateTime.UtcNow
            }, cancellationToken);

            await _context.SaveChangesAsync(cancellationToken);
        }
    }
}
