using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;

namespace HabitTracker.Domain.Interfaces
{
    public interface IHabitTaskRepository
    {
        Task<HabitTask?> GetByIdAsync(Guid id);
        Task<IEnumerable<HabitTask>> GetByHabitIdAsync(Guid habitId);
        Task AddAsync(HabitTask task);
        Task UpdateAsync(HabitTask task);
        Task DeleteAsync(Guid id);
        Task UpdateOrderAsync(List<HabitTask> tasks);
    }
}
