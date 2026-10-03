using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;
using Microsoft.Extensions.DependencyInjection;

namespace HabitTracker.Application.Features.Events.Queries
{
    public class GetEventsQuery : IRequest<IEnumerable<Event>>
    {
        public string UserId { get; set; } = string.Empty;
        public DateTime? StartTime { get; set; }
        public DateTime? EndTime { get; set; }
    }

    public class GetEventsQueryHandler : IRequestHandler<GetEventsQuery, IEnumerable<Event>>
    {
        private readonly IEventRepository _repository;
        private readonly IUserRepository _userRepository;
        private readonly IGoogleCalendarSyncCacheRepository _syncCacheRepository;
        private readonly IServiceScopeFactory _scopeFactory;

        public GetEventsQueryHandler(
            IEventRepository repository,
            IUserRepository userRepository,
            IGoogleCalendarSyncCacheRepository syncCacheRepository,
            IServiceScopeFactory scopeFactory)
        {
            _repository = repository;
            _userRepository = userRepository;
            _syncCacheRepository = syncCacheRepository;
            _scopeFactory = scopeFactory;
        }

        public async Task<IEnumerable<Event>> Handle(GetEventsQuery request, CancellationToken cancellationToken)
        {
            // Refuse rather than widen: an unset UserId used to fall back to every user's events,
            // so one forgotten assignment turned into a cross-user data leak.
            if (string.IsNullOrEmpty(request.UserId))
            {
                throw new ArgumentException("UserId is required.", nameof(request));
            }

            // 1. Stale: Lấy dữ liệu local và trả về ngay lập tức để UI hiển thị tức thì
            var localEvents = await _repository.GetEventsForUserAsync(request.UserId, request.StartTime, request.EndTime);

            // 2. Revalidate: Nếu người dùng liên kết Google Calendar, kích hoạt đồng bộ ngầm
            if (request.StartTime.HasValue && request.EndTime.HasValue)
            {
                var user = await _userRepository.GetByIdAsync(request.UserId);
                if (user != null && !string.IsNullOrEmpty(user.GoogleRefreshToken))
                {
                    var isSynced = await _syncCacheRepository.IsRangeSyncedAsync(
                        request.UserId, 
                        request.StartTime.Value, 
                        request.EndTime.Value, 
                        cancellationToken);

                    if (!isSynced)
                    {
                        var startTime = request.StartTime.Value;
                        var endTime = request.EndTime.Value;
                        var userId = request.UserId;
                        var refreshToken = user.GoogleRefreshToken;

                        // Chạy ngầm tiến trình gọi API Google trong scope độc lập
                        _ = Task.Run(async () =>
                        {
                            using var scope = _scopeFactory.CreateScope();
                            var googleCalendarService = scope.ServiceProvider.GetRequiredService<IGoogleCalendarService>();
                            var scopedSyncCacheRepo = scope.ServiceProvider.GetRequiredService<IGoogleCalendarSyncCacheRepository>();
                            try
                            {
                                await googleCalendarService.SyncEventsAsync(userId, refreshToken, startTime, endTime, CancellationToken.None);
                                await scopedSyncCacheRepo.SaveSyncRangeAsync(userId, startTime, endTime, CancellationToken.None);
                            }
                            catch (Exception ex)
                            {
                                Console.WriteLine($"Background SWR Google Sync Failed: {ex.Message}");
                            }
                        });
                    }
                }
            }

            return localEvents;
        }
    }
}
