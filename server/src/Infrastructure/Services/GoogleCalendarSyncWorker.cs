using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Interfaces;
using HabitTracker.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace HabitTracker.Infrastructure.Services
{
    public class GoogleCalendarSyncWorker : BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<GoogleCalendarSyncWorker> _logger;

        public GoogleCalendarSyncWorker(
            IServiceScopeFactory scopeFactory,
            ILogger<GoogleCalendarSyncWorker> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Google Calendar Sync Worker is starting.");

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await ProcessOutboxQueueAsync(stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error occurred executing Google Calendar Sync Outbox queue.");
                }

                await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
            }

            _logger.LogInformation("Google Calendar Sync Worker is stopping.");
        }

        private async Task ProcessOutboxQueueAsync(CancellationToken stoppingToken)
        {
            using var scope = _scopeFactory.CreateScope();
            var outboxRepository = scope.ServiceProvider.GetRequiredService<IGoogleCalendarOutboxRepository>();
            var userRepository = scope.ServiceProvider.GetRequiredService<IUserRepository>();
            var googleCalendarService = scope.ServiceProvider.GetRequiredService<IGoogleCalendarService>();
            var eventRepository = scope.ServiceProvider.GetRequiredService<IEventRepository>();

            var queue = await outboxRepository.GetUnprocessedAsync(20, stoppingToken);
            if (!queue.Any()) return;

            _logger.LogInformation("Processing {Count} Google Calendar Outbox items.", queue.Count());

            foreach (var item in queue)
            {
                if (stoppingToken.IsCancellationRequested) break;

                try
                {
                    var user = await userRepository.GetByIdAsync(item.UserId);
                    if (user == null || string.IsNullOrEmpty(user.GoogleRefreshToken))
                    {
                        item.ProcessedAt = DateTime.UtcNow;
                        item.Error = "User not found or Google Refresh Token is empty.";
                        await outboxRepository.UpdateAsync(item, stoppingToken);
                        continue;
                    }

                    if (item.Action == "Insert")
                    {
                        var googleId = await googleCalendarService.PushInsertAsync(
                            item.UserId,
                            user.GoogleRefreshToken,
                            item.EventId,
                            item.Payload,
                            stoppingToken);

                        if (!string.IsNullOrEmpty(googleId))
                        {
                            var localEvent = await eventRepository.GetByIdAsync(item.EventId);
                            if (localEvent != null)
                            {
                                localEvent.GoogleEventId = googleId;
                                await eventRepository.UpdateAsync(localEvent);
                            }
                            item.GoogleEventId = googleId;
                            item.ProcessedAt = DateTime.UtcNow;
                        }
                        else
                        {
                            throw new Exception("Google Calendar API returned empty ID on Insert.");
                        }
                    }
                    else if (item.Action == "Update")
                    {
                        if (string.IsNullOrEmpty(item.GoogleEventId))
                        {
                            // If we don't have GoogleEventId yet, wait for Insert or try to find it
                            var localEvent = await eventRepository.GetByIdAsync(item.EventId);
                            if (localEvent != null && !string.IsNullOrEmpty(localEvent.GoogleEventId))
                            {
                                item.GoogleEventId = localEvent.GoogleEventId;
                            }
                            else
                            {
                                throw new Exception("Cannot update event: missing GoogleEventId.");
                            }
                        }

                        await googleCalendarService.PushUpdateAsync(
                            item.UserId,
                            user.GoogleRefreshToken,
                            item.GoogleEventId,
                            item.Payload,
                            stoppingToken);

                        item.ProcessedAt = DateTime.UtcNow;
                    }
                    else if (item.Action == "Delete")
                    {
                        if (!string.IsNullOrEmpty(item.GoogleEventId))
                        {
                            await googleCalendarService.PushDeleteAsync(
                                item.UserId,
                                user.GoogleRefreshToken,
                                item.GoogleEventId,
                                stoppingToken);
                        }
                        item.ProcessedAt = DateTime.UtcNow;
                    }

                    item.Error = null;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to process Outbox item {Id}.", item.Id);
                    item.Error = ex.Message;
                    item.RetryCount++;
                }

                await outboxRepository.UpdateAsync(item, stoppingToken);
            }
        }
    }
}
