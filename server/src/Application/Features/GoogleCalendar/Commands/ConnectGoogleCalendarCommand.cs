using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.GoogleCalendar.Commands
{
    public class ConnectGoogleCalendarCommand : IRequest<bool>
    {
        public string UserId { get; set; } = string.Empty;
        public string AuthCode { get; set; } = string.Empty;
        public string GoogleEmail { get; set; } = string.Empty;
    }

    public class ConnectGoogleCalendarCommandHandler : IRequestHandler<ConnectGoogleCalendarCommand, bool>
    {
        private readonly IUserRepository _userRepository;
        private readonly IGoogleCalendarService _googleCalendarService;

        public ConnectGoogleCalendarCommandHandler(IUserRepository userRepository, IGoogleCalendarService googleCalendarService)
        {
            _userRepository = userRepository;
            _googleCalendarService = googleCalendarService;
        }

        public async Task<bool> Handle(ConnectGoogleCalendarCommand request, CancellationToken cancellationToken)
        {
            var user = await _userRepository.GetByIdAsync(request.UserId);
            if (user == null) return false;

            var refreshToken = await _googleCalendarService.ExchangeCodeForRefreshTokenAsync(request.UserId, request.AuthCode, cancellationToken);

            if (!string.IsNullOrEmpty(refreshToken))
            {
                user.GoogleRefreshToken = refreshToken;
                user.GoogleEmail = request.GoogleEmail;
                await _userRepository.UpdateAsync(user);
                return true;
            }
            
            // Re-auth fallback: Google might not return a new refresh token if the app was already authorized.
            // In this case, we reuse the existing stored refresh token.
            if (!string.IsNullOrEmpty(user.GoogleRefreshToken))
            {
                user.GoogleEmail = request.GoogleEmail;
                await _userRepository.UpdateAsync(user);
                return true;
            }

            return false;
        }
    }
}
