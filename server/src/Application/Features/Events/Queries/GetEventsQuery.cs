using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;

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
        private readonly IGoogleCalendarService _googleCalendarService;
        private readonly IGoogleCalendarSyncCacheRepository _syncCacheRepository;

        public GetEventsQueryHandler(
            IEventRepository repository,
            IUserRepository userRepository,
            IGoogleCalendarService googleCalendarService,
            IGoogleCalendarSyncCacheRepository syncCacheRepository)
        {
            _repository = repository;
            _userRepository = userRepository;
            _googleCalendarService = googleCalendarService;
            _syncCacheRepository = syncCacheRepository;
        }

        public async Task<IEnumerable<Event>> Handle(GetEventsQuery request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrEmpty(request.UserId))
            {
                return await _repository.GetAllAsync();
            }

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
                        Console.WriteLine($"GetEventsQueryHandler: Range [{request.StartTime.Value:yyyy-MM-dd} to {request.EndTime.Value:yyyy-MM-dd}] not fully synced for User {request.UserId}. Triggering Google sync...");
                        await _googleCalendarService.SyncEventsAsync(
                            request.UserId, 
                            user.GoogleRefreshToken, 
                            request.StartTime.Value, 
                            request.EndTime.Value, 
                            cancellationToken);

                        await _syncCacheRepository.SaveSyncRangeAsync(
                            request.UserId, 
                            request.StartTime.Value, 
                            request.EndTime.Value, 
                            cancellationToken);
                    }
                }
            }

            return await _repository.GetEventsForUserAsync(request.UserId, request.StartTime, request.EndTime);
        }
    }
}
