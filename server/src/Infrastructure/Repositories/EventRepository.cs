using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using HabitTracker.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace HabitTracker.Infrastructure.Repositories
{
    public class EventRepository : IEventRepository
    {
        private readonly ApplicationDbContext _context;

        public EventRepository(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<Event>> GetCompletedEventsForUserAsync(string userId)
        {
            return await _context.Events
                .AsNoTracking()
                .Where(e => e.UserId == userId && e.IsCompleted)
                .ToListAsync();
        }

        public async Task<Event?> GetOccurrenceChildAsync(Guid seriesId, DateTime occurrenceStartUtc)
        {
            var utc = occurrenceStartUtc.Kind == DateTimeKind.Utc
                ? occurrenceStartUtc
                : DateTime.SpecifyKind(occurrenceStartUtc, DateTimeKind.Utc);
            var minuteStart = new DateTime(utc.Year, utc.Month, utc.Day, utc.Hour, utc.Minute, 0, DateTimeKind.Utc);
            var minuteEnd = minuteStart.AddMinutes(1);

            return await _context.Events
                .Where(e => e.ParentEventId == seriesId
                    && e.ExceptionDate >= minuteStart
                    && e.ExceptionDate < minuteEnd)
                .OrderBy(e => e.CreatedAt)
                .FirstOrDefaultAsync();
        }

        public async Task<IEnumerable<DailyActivity>> GetDailyActivityAsync(string userId, DateTime fromUtc, DateTime toUtc)
        {
            // Written as SQL rather than as a LINQ GroupBy on purpose. EF silently falls
            // back to client evaluation for some grouped projections, which would mean
            // loading every row to count it — the exact thing this method exists to avoid.
            // Spelled out, the plan is a HashAggregate over the Events table.
            //
            // The interpolated values are parameterised by SqlQuery; this is not string
            // concatenation.
            //
            // `+ interval '7 hours'` is the UTC+7 day boundary shared with
            // StreakCalculator.DefaultDayBoundaryOffset. If that ever becomes a per-user
            // setting, both have to move together.
            return await _context.Database
                .SqlQuery<DailyActivity>(
                    $"""
                    SELECT
                        (("StartTime" AT TIME ZONE 'UTC') + interval '7 hours')::date AS "Date",
                        COUNT(*)::int AS "Scheduled",
                        COUNT(*) FILTER (WHERE "IsCompleted")::int AS "Completed",
                        COALESCE(ROUND(SUM(EXTRACT(EPOCH FROM "ActualDuration")) / 60.0), 0)::int AS "FocusMinutes"
                    FROM "Events"
                    WHERE "UserId" = {userId}
                      AND "StartTime" >= {fromUtc}
                      AND "StartTime" < {toUtc}
                    GROUP BY 1
                    ORDER BY 1
                    """)
                .ToListAsync();
        }

        public async Task<IEnumerable<Event>> GetCompletedEventsForHabitAsync(Guid habitId)
        {
            var habitIdText = habitId.ToString();

            return await _context.Events
                .AsNoTracking()
                .Where(e => e.IsCompleted && e.HabitId != null && e.HabitId.ToLower() == habitIdText.ToLower())
                .OrderBy(e => e.StartTime)
                .ToListAsync();
        }

        public async Task<IEnumerable<Event>> GetEventsForUserAsync(string userId, DateTime? startTime = null, DateTime? endTime = null)
        {
            var query = _context.Events.Where(e => e.UserId == userId);

            if (startTime.HasValue && endTime.HasValue)
            {
                var start = startTime.Value;
                var end = endTime.Value;
                query = query.Where(e => 
                    (e.StartTime <= end && e.EndTime >= start) || 
                    (e.RecurrenceRule != null && e.StartTime <= end) ||
                    (e.ParentEventId != null));
            }

            return await query.ToListAsync();
        }

        public async Task<Event?> GetByIdAsync(Guid id)
        {
            return await _context.Events.FindAsync(id);
        }

        public async Task AddAsync(Event ev)
        {
            await _context.Events.AddAsync(ev);
            await _context.SaveChangesAsync();
        }

        public async Task UpdateAsync(Event ev)
        {
            _context.Events.Update(ev);
            await _context.SaveChangesAsync();
        }

        public async Task DeleteAsync(Guid id)
        {
            var ev = await _context.Events.FindAsync(id);
            if (ev != null)
            {
                _context.Events.Remove(ev);
                await _context.SaveChangesAsync();
            }
        }
    }
}
