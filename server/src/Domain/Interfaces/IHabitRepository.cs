using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;

namespace HabitTracker.Domain.Interfaces
{
    public interface IHabitRepository
    {
        Task<IEnumerable<Habit>> GetAllAsync();
        Task<Habit?> GetByIdAsync(Guid id);
        Task AddAsync(Habit habit);
        Task UpdateAsync(Habit habit);
        Task DeleteAsync(Guid id);
    }
}
