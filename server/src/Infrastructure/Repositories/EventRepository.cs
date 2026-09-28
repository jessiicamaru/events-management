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

        public async Task<IEnumerable<Event>> GetAllAsync()
        {
            return await _context.Events.ToListAsync();
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
