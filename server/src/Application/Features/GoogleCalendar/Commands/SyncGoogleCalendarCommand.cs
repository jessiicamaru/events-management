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

        public SyncGoogleCalendarCommandHandler(IUserRepository userRepository, IGoogleCalendarService googleCalendarService)
        {
            _userRepository = userRepository;
            _googleCalendarService = googleCalendarService;
        }

        public async Task<bool> Handle(SyncGoogleCalendarCommand request, CancellationToken cancellationToken)
        {
            var user = await _userRepository.GetByIdAsync(request.UserId);
            if (user == null || string.IsNullOrEmpty(user.GoogleRefreshToken))
            {
                return false;
            }

            return await _googleCalendarService.SyncEventsAsync(user.Id, user.GoogleRefreshToken, null, null, cancellationToken);
        }
    }
}
