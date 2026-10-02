using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.GoogleCalendar.Commands
{
    public class SyncGoogleCalendarCommand : IRequest<bool>
    {
        public string UserId { get; set; } = string.Empty;
    }

    public class SyncGoogleCalendarCommandHandler : IRequestHandler<SyncGoogleCalendarCommand, bool>
    {
        private readonly IUserRepository _userRepository;
        private readonly IGoogleCalendarService _googleCalendarService;
        private readonly IGoogleCalendarChannelRepository _channelRepository;
        private readonly Microsoft.Extensions.Configuration.IConfiguration _configuration;

        public SyncGoogleCalendarCommandHandler(
            IUserRepository userRepository, 
            IGoogleCalendarService googleCalendarService,
            IGoogleCalendarChannelRepository channelRepository,
            Microsoft.Extensions.Configuration.IConfiguration configuration)
        {
            _userRepository = userRepository;
            _googleCalendarService = googleCalendarService;
            _channelRepository = channelRepository;
            _configuration = configuration;
        }

        public async Task<bool> Handle(SyncGoogleCalendarCommand request, CancellationToken cancellationToken)
        {
            var user = await _userRepository.GetByIdAsync(request.UserId);
            if (user == null || string.IsNullOrEmpty(user.GoogleRefreshToken))
            {
                return false;
            }

            var isSynced = await _googleCalendarService.SyncEventsAsync(user.Id, user.GoogleRefreshToken, null, null, cancellationToken);

            var webhookBaseUrl = _configuration["GoogleCalendar:WebhookBaseUrl"];
            if (isSynced && !string.IsNullOrEmpty(webhookBaseUrl))
            {
                try
                {
                    var existingChannel = await _channelRepository.GetByUserIdAsync(user.Id, cancellationToken);
                    if (existingChannel == null || existingChannel.Expiration < System.DateTime.UtcNow.AddHours(24))
                    {
                        var callbackUrl = $"{webhookBaseUrl.TrimEnd('/')}/api/v1/webhooks/google-calendar";
                        var newChannel = await _googleCalendarService.WatchCalendarAsync(user.Id, user.GoogleRefreshToken, callbackUrl, cancellationToken);
                        if (newChannel != null)
                        {
                            if (existingChannel != null)
                            {
                                await _googleCalendarService.StopWatchingCalendarAsync(user.GoogleRefreshToken, existingChannel.Id, existingChannel.ResourceId, cancellationToken);
                            }
                            await _channelRepository.SaveChannelAsync(newChannel, cancellationToken);
                        }
                    }
                }
                catch (System.Exception ex)
                {
                    System.Console.WriteLine($"Webhook Registration Error: {ex.Message}");
                }
            }

            return isSynced;
        }
    }
}
