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
    public class EventCategoryRepository : IEventCategoryRepository
    {
        private readonly ApplicationDbContext _context;

        public EventCategoryRepository(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<EventCategory?> GetByIdAsync(Guid id)
        {
            return await _context.EventCategories.FindAsync(id);
        }

        public async Task<IEnumerable<EventCategory>> GetByUserIdAsync(string userId)
        {
            return await _context.EventCategories
                .Where(c => c.UserId == userId)
                .ToListAsync();
        }

        public async Task<IEnumerable<EventCategory>> GetBySquadIdAsync(Guid squadId)
        {
            return await _context.EventCategories
                .Where(c => c.SquadId == squadId)
                .ToListAsync();
        }

        public async Task<EventCategory> AddAsync(EventCategory category)
        {
            _context.EventCategories.Add(category);
            await _context.SaveChangesAsync();
            return category;
        }

        public async Task UpdateAsync(EventCategory category)
        {
            _context.Entry(category).State = EntityState.Modified;
            await _context.SaveChangesAsync();
        }

        public async Task DeleteAsync(Guid id)
        {
            var category = await _context.EventCategories.FindAsync(id);
            if (category != null)
            {
                _context.EventCategories.Remove(category);
                await _context.SaveChangesAsync();
            }
        }
    }
}
