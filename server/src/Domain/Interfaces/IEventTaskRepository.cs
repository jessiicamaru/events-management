using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;

namespace HabitTracker.Domain.Interfaces
{
    public interface IEventTaskRepository
    {
        Task<EventTask?> GetByIdAsync(Guid id);
        Task<IEnumerable<EventTask>> GetByEventIdAsync(Guid eventId);
        Task AddAsync(EventTask task);
        Task UpdateAsync(EventTask task);
        Task DeleteAsync(Guid id);
        Task UpdateOrderAsync(List<EventTask> tasks);
    }
}
