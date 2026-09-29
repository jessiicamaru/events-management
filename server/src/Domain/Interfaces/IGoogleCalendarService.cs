using System.Threading;
using System.Threading.Tasks;

namespace HabitTracker.Domain.Interfaces
{
    public interface IGoogleCalendarService
    {
        Task<string?> ExchangeCodeForRefreshTokenAsync(string userId, string authCode, CancellationToken cancellationToken);
        Task<bool> SyncEventsAsync(string userId, string refreshToken, CancellationToken cancellationToken);
    }
}
