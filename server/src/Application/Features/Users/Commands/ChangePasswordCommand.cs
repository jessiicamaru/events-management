using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Identity;
using HabitTracker.Domain.Entities;
using MediatR;

namespace HabitTracker.Application.Features.Users.Commands
{
    public class ChangePasswordCommand : IRequest<IdentityResult>
    {
        public string UserId { get; set; } = string.Empty;
        public string CurrentPassword { get; set; } = string.Empty;
        public string NewPassword { get; set; } = string.Empty;
    }

    public class ChangePasswordCommandHandler : IRequestHandler<ChangePasswordCommand, IdentityResult>
    {
        private readonly UserManager<ApplicationUser> _userManager;

        public ChangePasswordCommandHandler(UserManager<ApplicationUser> userManager)
        {
            _userManager = userManager;
        }

        public async Task<IdentityResult> Handle(ChangePasswordCommand request, CancellationToken cancellationToken)
        {
            var user = await _userManager.FindByIdAsync(request.UserId);
            if (user == null)
            {
                return IdentityResult.Failed(new IdentityError { Description = "User not found" });
            }

            return await _userManager.ChangePasswordAsync(user, request.CurrentPassword, request.NewPassword);
        }
    }
}
