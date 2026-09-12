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
        public bool IsBuddyMode { get; set; }
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
            var exists = await _repository.IsUserInAnySquadAsync(request.AdminUserId);
            if (exists) throw new System.Exception("Already in a squad");

            var squad = new Squad
            {
                Name = request.Name,
                IsBuddyMode = request.IsBuddyMode
            };

            return await _repository.CreateSquadAsync(squad, request.AdminUserId);
        }
    }
}
