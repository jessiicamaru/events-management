using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.GoogleCalendar.Commands
{
    public class DisconnectGoogleCalendarCommand : IRequest<bool>
    {
        public string UserId { get; set; } = string.Empty;
    }

    public class DisconnectGoogleCalendarCommandHandler : IRequestHandler<DisconnectGoogleCalendarCommand, bool>
    {
        private readonly IUserRepository _userRepository;

        public DisconnectGoogleCalendarCommandHandler(IUserRepository userRepository)
        {
            _userRepository = userRepository;
        }

        public async Task<bool> Handle(DisconnectGoogleCalendarCommand request, CancellationToken cancellationToken)
        {
            var user = await _userRepository.GetByIdAsync(request.UserId);
            if (user == null) return false;

            user.GoogleRefreshToken = null;
            user.GoogleEmail = null;

            await _userRepository.UpdateAsync(user);
            return true;
        }
    }
}
