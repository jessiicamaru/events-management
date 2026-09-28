using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;
using System.Threading;
using System.Threading.Tasks;

namespace HabitTracker.Application.Features.Squads.Commands
{
    public class CreateSquadCommand : IRequest<Squad>
    {
        public string Name { get; set; } = string.Empty;
        public int MaxMembers { get; set; }
        public bool RequireApproval { get; set; }
        public string AdminUserId { get; set; } = string.Empty;
    }

    public class CreateSquadCommandHandler : IRequestHandler<CreateSquadCommand, Squad>
    {
        private readonly ISquadRepository _repository;

        public CreateSquadCommandHandler(ISquadRepository repository)
        {
            _repository = repository;
        }

        public async Task<Squad> Handle(CreateSquadCommand request, CancellationToken cancellationToken)
        {
            if (request.MaxMembers < 2 || request.MaxMembers > 10)
            {
                throw new System.Exception("Max members must be between 2 and 10");
            }

            var squad = new Squad
            {
                Name = request.Name,
                MaxMembers = request.MaxMembers,
                RequireApproval = request.RequireApproval
            };

            return await _repository.CreateSquadAsync(squad, request.AdminUserId);
        }
    }
}
