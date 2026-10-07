using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using HabitTracker.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Npgsql;

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

        public async Task<IEnumerable<PlanVsActual>> GetPlanVsActualByHabitAsync(
            string userId, DateTime fromUtc, DateTime toUtc)
        {
            // SQL rather than a LINQ GroupBy, for the reason spelled out on
            // GetDailyActivityAsync: EF quietly evaluates some grouped projections on the
            // client, which would load every event to add up two columns. Interpolated values
            // are parameterised by SqlQuery.
            //
            // Only rows with an ActualDuration take part, so both sides describe the same
            // sessions — see PlanVsActual. The join is on text because Event.HabitId is text
            // while Habits.Id is a uuid; casting the uuid keeps the comparison off the
            // column that has the index.
            return await _context.Database
                .SqlQuery<PlanVsActual>(
                    $"""
                    SELECT
                        h."Id"::text AS "GroupId",
                        h."Name" AS "GroupName",
                        COUNT(*)::int AS "Sessions",
                        COALESCE(ROUND(SUM(EXTRACT(EPOCH FROM e."TargetDuration")) / 60.0), 0)::int AS "PlannedMinutes",
                        COALESCE(ROUND(SUM(EXTRACT(EPOCH FROM e."ActualDuration")) / 60.0), 0)::int AS "ActualMinutes"
                    FROM "Events" e
                    JOIN "Habits" h ON h."Id"::text = e."HabitId"
                    WHERE e."UserId" = {userId}
                      AND e."StartTime" >= {fromUtc}
                      AND e."StartTime" < {toUtc}
                      AND e."ActualDuration" IS NOT NULL
                    GROUP BY h."Id", h."Name"
                    ORDER BY SUM(EXTRACT(EPOCH FROM e."ActualDuration")) DESC, h."Name"
                    """)
                .ToListAsync();
        }

        public async Task<IEnumerable<PlanVsActual>> GetPlanVsActualByCategoryAsync(
            string userId, DateTime fromUtc, DateTime toUtc)
        {
            // Events with no category drop out of the join rather than forming a row: the
            // client decides what to call them, and usually does not show them at all.
            return await _context.Database
                .SqlQuery<PlanVsActual>(
                    $"""
                    SELECT
                        c."Id"::text AS "GroupId",
                        c."Name" AS "GroupName",
                        COUNT(*)::int AS "Sessions",
                        COALESCE(ROUND(SUM(EXTRACT(EPOCH FROM e."TargetDuration")) / 60.0), 0)::int AS "PlannedMinutes",
                        COALESCE(ROUND(SUM(EXTRACT(EPOCH FROM e."ActualDuration")) / 60.0), 0)::int AS "ActualMinutes"
                    FROM "Events" e
                    JOIN "EventCategories" c ON c."Id" = e."CategoryId"
                    WHERE e."UserId" = {userId}
                      AND e."StartTime" >= {fromUtc}
                      AND e."StartTime" < {toUtc}
                      AND e."ActualDuration" IS NOT NULL
                    GROUP BY c."Id", c."Name"
                    ORDER BY SUM(EXTRACT(EPOCH FROM e."ActualDuration")) DESC, c."Name"
                    """)
                .ToListAsync();
        }

        public async Task<PlanVsActual> GetPlanVsActualTotalsAsync(
            string userId, DateTime fromUtc, DateTime toUtc)
        {
            // No join: a finished session counts whether or not it has a habit or a category.
            // The groupings above each miss some of them, so the totals cannot be derived
            // from either without under-counting.
            var rows = await _context.Database
                .SqlQuery<PlanVsActual>(
                    $"""
                    SELECT
                        '' AS "GroupId",
                        '' AS "GroupName",
                        COUNT(*)::int AS "Sessions",
                        COALESCE(ROUND(SUM(EXTRACT(EPOCH FROM e."TargetDuration")) / 60.0), 0)::int AS "PlannedMinutes",
                        COALESCE(ROUND(SUM(EXTRACT(EPOCH FROM e."ActualDuration")) / 60.0), 0)::int AS "ActualMinutes"
                    FROM "Events" e
                    WHERE e."UserId" = {userId}
                      AND e."StartTime" >= {fromUtc}
                      AND e."StartTime" < {toUtc}
                      AND e."ActualDuration" IS NOT NULL
                    """)
                .ToListAsync();

            return rows.FirstOrDefault() ?? new PlanVsActual();
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

        public async Task<IEnumerable<Event>> GetChildrenAsync(Guid seriesId)
        {
            return await _context.Events
                .Where(e => e.ParentEventId == seriesId)
                .ToListAsync();
        }

        public async Task<bool> TryAddOccurrenceDayAsync(Event day)
        {
            await _context.Events.AddAsync(day);
            try
            {
                // Inside a transaction EF saves behind a savepoint and rolls back to it on
                // failure, so the caller's transaction is still usable after this returns false.
                await _context.SaveChangesAsync();
                return true;
            }
            catch (DbUpdateException ex) when (ex.InnerException is PostgresException
            {
                SqlState: PostgresErrorCodes.UniqueViolation,
                ConstraintName: ApplicationDbContext.OneEventPerSeriesDayIndex
            })
            {
                // Still tracked as Added: the next SaveChanges would try to insert it again.
                _context.Entry(day).State = EntityState.Detached;
                return false;
            }
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
            //
            // Scheduled/completed count one-off events only. A repeating event is one row
            // dated on its first day, so counting rows counted each series once, there, and
            // counted only the days somebody had touched (split off) — which pushed the
            // completion rate towards 100%. Repeating days are counted by the client instead,
            // which expands the series with the same code that draws Home and schedules
            // reminders. Focus minutes still come from every row: only a finished session
            // writes ActualDuration, whichever kind of event it was on.
            return await _context.Database
                .SqlQuery<DailyActivity>(
                    $"""
                    SELECT
                        (("StartTime" AT TIME ZONE 'UTC') + interval '7 hours')::date AS "Date",
                        COUNT(*) FILTER (WHERE "ParentEventId" IS NULL AND COALESCE("RecurrenceRule", '') = '')::int AS "OneOffScheduled",
                        COUNT(*) FILTER (WHERE "ParentEventId" IS NULL AND COALESCE("RecurrenceRule", '') = '' AND "IsCompleted")::int AS "OneOffCompleted",
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
