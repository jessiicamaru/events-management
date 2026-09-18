using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using HabitTracker.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace HabitTracker.Infrastructure.Repositories
{
    public class EventTaskRepository : IEventTaskRepository
    {
        private readonly ApplicationDbContext _context;

        public EventTaskRepository(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<EventTask?> GetByIdAsync(Guid id)
        {
            return await _context.EventTasks.Include(t => t.Event).FirstOrDefaultAsync(t => t.Id == id);
        }

        public async Task<IEnumerable<EventTask>> GetByEventIdAsync(Guid eventId)
        {
            return await _context.EventTasks
                .Where(t => t.EventId == eventId)
                .OrderBy(t => t.Order)
                .ToListAsync();
        }

        public async Task AddAsync(EventTask task)
        {
            await _context.EventTasks.AddAsync(task);
            await _context.SaveChangesAsync();
        }

        public async Task UpdateAsync(EventTask task)
        {
            _context.EventTasks.Update(task);
            await _context.SaveChangesAsync();
        }

        public async Task DeleteAsync(Guid id)
        {
            var task = await GetByIdAsync(id);
            if (task != null)
            {
                _context.EventTasks.Remove(task);
                await _context.SaveChangesAsync();
            }
        }

        public async Task UpdateOrderAsync(List<EventTask> tasks)
        {
            _context.EventTasks.UpdateRange(tasks);
            await _context.SaveChangesAsync();
        }
    }
}
