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
    public class HabitTaskRepository : IHabitTaskRepository
    {
        private readonly ApplicationDbContext _context;

        public HabitTaskRepository(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<HabitTask?> GetByIdAsync(Guid id)
        {
            return await _context.HabitTasks.Include(t => t.Habit).FirstOrDefaultAsync(t => t.Id == id);
        }

        public async Task<IEnumerable<HabitTask>> GetByHabitIdAsync(Guid habitId)
        {
            return await _context.HabitTasks
                .Where(t => t.HabitId == habitId)
                .OrderBy(t => t.Order)
                .ToListAsync();
        }

        public async Task AddAsync(HabitTask task)
        {
            await _context.HabitTasks.AddAsync(task);
            await _context.SaveChangesAsync();
        }

        public async Task UpdateAsync(HabitTask task)
        {
            _context.HabitTasks.Update(task);
            await _context.SaveChangesAsync();
        }

        public async Task DeleteAsync(Guid id)
        {
            var task = await GetByIdAsync(id);
            if (task != null)
            {
                _context.HabitTasks.Remove(task);
                await _context.SaveChangesAsync();
            }
        }

        public async Task UpdateOrderAsync(List<HabitTask> tasks)
        {
            _context.HabitTasks.UpdateRange(tasks);
            await _context.SaveChangesAsync();
        }
    }
}
