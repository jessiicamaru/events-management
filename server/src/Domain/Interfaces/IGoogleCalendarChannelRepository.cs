using System;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;

namespace HabitTracker.Domain.Interfaces
{
    public interface IGoogleCalendarChannelRepository
    {
        Task SaveChannelAsync(GoogleCalendarChannel channel, CancellationToken cancellationToken = default);
        Task<GoogleCalendarChannel?> GetByIdAsync(string channelId, CancellationToken cancellationToken = default);
        Task<GoogleCalendarChannel?> GetByUserIdAsync(string userId, CancellationToken cancellationToken = default);
        Task DeleteAsync(string channelId, CancellationToken cancellationToken = default);
    }
}
