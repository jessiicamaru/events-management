using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using HabitTracker.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace HabitTracker.Infrastructure.Repositories
{
    public class HabitRepository : IHabitRepository
    {
        private readonly ApplicationDbContext _context;

        public HabitRepository(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<Habit>> GetAllAsync()
        {
            return await _context.Habits.ToListAsync();
        }

        public async Task<Habit?> GetByIdAsync(Guid id)
        {
            return await _context.Habits.FindAsync(id);
        }

        public async Task AddAsync(Habit habit)
        {
            await _context.Habits.AddAsync(habit);
            await _context.SaveChangesAsync();
        }

        public async Task UpdateAsync(Habit habit)
        {
            _context.Habits.Update(habit);
            await _context.SaveChangesAsync();
        }

        public async Task DeleteAsync(Guid id)
        {
            var habit = await _context.Habits.FindAsync(id);
            if (habit != null)
            {
                _context.Habits.Remove(habit);
                await _context.SaveChangesAsync();
            }
        }
    }
}
