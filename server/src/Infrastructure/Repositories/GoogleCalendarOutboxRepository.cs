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
    public class GoogleCalendarOutboxRepository : IGoogleCalendarOutboxRepository
    {
        private readonly ApplicationDbContext _context;

        public GoogleCalendarOutboxRepository(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task EnqueueAsync(string userId, Guid eventId, string? googleEventId, string action, string payload, CancellationToken cancellationToken = default)
        {
            var entry = new GoogleCalendarOutbox
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                EventId = eventId,
                GoogleEventId = googleEventId,
                Action = action,
                Payload = payload,
                CreatedAt = DateTime.UtcNow,
                ProcessedAt = null,
                RetryCount = 0
            };

            await _context.GoogleCalendarOutboxes.AddAsync(entry, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
        }

        public async Task<IEnumerable<GoogleCalendarOutbox>> GetUnprocessedAsync(int limit = 50, CancellationToken cancellationToken = default)
        {
            return await _context.GoogleCalendarOutboxes
                .Where(x => x.ProcessedAt == null && x.RetryCount < GoogleCalendarOutbox.MaxRetries)
                .OrderBy(x => x.CreatedAt)
                .Take(limit)
                .ToListAsync(cancellationToken);
        }

        public async Task<bool> HasPendingInsertAsync(Guid eventId, CancellationToken cancellationToken = default)
        {
            // An Insert the worker gave up on is not pending: it will never run. Counted as
            // pending, it made the event look known to Google for good, so every later edit
            // queued an Update that could only fail, and the day was never sent again.
            return await _context.GoogleCalendarOutboxes
                .AnyAsync(x => x.EventId == eventId
                    && x.Action == "Insert"
                    && x.ProcessedAt == null
                    && x.RetryCount < GoogleCalendarOutbox.MaxRetries, cancellationToken);
        }

        public async Task UpdateAsync(GoogleCalendarOutbox entry, CancellationToken cancellationToken = default)
        {
            _context.GoogleCalendarOutboxes.Update(entry);
            await _context.SaveChangesAsync(cancellationToken);
        }
    }
}
