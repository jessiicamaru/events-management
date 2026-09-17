using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Users.Commands
{
    public class UpdateProfileCommand : IRequest<bool>
    {
        public string UserId { get; set; } = string.Empty;
        public string? DisplayName { get; set; }
        public string? Bio { get; set; }
        public System.DateTime? DateOfBirth { get; set; }
        public string? Gender { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Avatar { get; set; }
    }

    public class UpdateProfileCommandHandler : IRequestHandler<UpdateProfileCommand, bool>
    {
        private readonly IUserRepository _repository;

        public UpdateProfileCommandHandler(IUserRepository repository)
        {
            _repository = repository;
        }

        public async Task<bool> Handle(UpdateProfileCommand request, CancellationToken cancellationToken)
        {
            var user = await _repository.GetByIdAsync(request.UserId);
            if (user == null) return false;

            user.DisplayName = request.DisplayName;
            user.Bio = request.Bio;
            user.DateOfBirth = request.DateOfBirth;
            user.Gender = request.Gender;
            user.PhoneNumber = request.PhoneNumber;
            user.Avatar = request.Avatar;

            await _repository.UpdateAsync(user);
            return true;
        }
    }
}
