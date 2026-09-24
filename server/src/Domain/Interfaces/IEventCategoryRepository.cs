using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;

namespace HabitTracker.Domain.Interfaces
{
    public interface IEventCategoryRepository
    {
        Task<EventCategory?> GetByIdAsync(Guid id);
        Task<IEnumerable<EventCategory>> GetByUserIdAsync(string userId);
        Task<IEnumerable<EventCategory>> GetBySquadIdAsync(Guid squadId);
        Task<EventCategory> AddAsync(EventCategory category);
        Task UpdateAsync(EventCategory category);
        Task DeleteAsync(Guid id);
    }
}
