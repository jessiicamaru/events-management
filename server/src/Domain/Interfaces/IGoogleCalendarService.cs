using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;

namespace HabitTracker.Domain.Interfaces
{
    public interface IGoogleCalendarService
    {
        Task<string?> ExchangeCodeForRefreshTokenAsync(string userId, string authCode, CancellationToken cancellationToken);
        Task<bool> SyncEventsAsync(string userId, string refreshToken, DateTime? syncStart, DateTime? syncEnd, CancellationToken cancellationToken);
        Task<string?> PushInsertAsync(string userId, string refreshToken, Guid eventId, string payload, CancellationToken cancellationToken);
        Task PushUpdateAsync(string userId, string refreshToken, string googleEventId, string payload, CancellationToken cancellationToken);
        Task PushDeleteAsync(string userId, string refreshToken, string googleEventId, CancellationToken cancellationToken);
        Task<GoogleCalendarChannel?> WatchCalendarAsync(string userId, string refreshToken, string webhookUrl, CancellationToken cancellationToken);
        Task StopWatchingCalendarAsync(string refreshToken, string channelId, string resourceId, CancellationToken cancellationToken);
    }
}
