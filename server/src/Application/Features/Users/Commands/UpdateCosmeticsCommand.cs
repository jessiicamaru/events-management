using HabitTracker.Domain.Interfaces;
using MediatR;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;

namespace HabitTracker.Application.Features.Users.Commands
{
    public class UpdateCosmeticsCommand : IRequest
    {
        public string UserId { get; set; } = string.Empty;
        public string? AvatarBorderColor { get; set; }
        public List<string>? UnlockedEmojis { get; set; }
    }

    public class UpdateCosmeticsCommandHandler : IRequestHandler<UpdateCosmeticsCommand>
    {
        private readonly IUserRepository _repository;

        public UpdateCosmeticsCommandHandler(IUserRepository repository)
        {
            _repository = repository;
        }

        public async Task Handle(UpdateCosmeticsCommand request, CancellationToken cancellationToken)
        {
            var user = await _repository.GetByIdAsync(request.UserId);
            if (user == null) throw new System.Exception("User not found");

            if (request.AvatarBorderColor != null)
            {
                user.AvatarBorderColor = request.AvatarBorderColor;
            }

            if (request.UnlockedEmojis != null)
            {
                user.UnlockedEmojis = request.UnlockedEmojis;
            }

            await _repository.UpdateAsync(user);
        }
    }
}
