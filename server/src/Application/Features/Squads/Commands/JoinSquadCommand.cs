using HabitTracker.Domain.Interfaces;
using MediatR;
using System.Threading;
using System.Threading.Tasks;

namespace HabitTracker.Application.Features.Squads.Commands
{
    public class JoinSquadCommand : IRequest
    {
        public System.Guid SquadId { get; set; }
        public string UserId { get; set; } = string.Empty;
    }

    public class JoinSquadCommandHandler : IRequestHandler<JoinSquadCommand>
    {
        private readonly ISquadRepository _repository;

        public JoinSquadCommandHandler(ISquadRepository repository)
        {
            _repository = repository;
        }

        public async Task Handle(JoinSquadCommand request, CancellationToken cancellationToken)
        {
            var exists = await _repository.IsUserInAnySquadAsync(request.UserId);
            if (exists) throw new System.Exception("Already in a squad");

            var squad = await _repository.GetSquadByIdAsync(request.SquadId);
            if (squad == null) throw new System.Exception("Squad not found");

            var count = await _repository.GetMemberCountAsync(request.SquadId);
            if (squad.IsBuddyMode && count >= 2) throw new System.Exception("Buddy squad is full");
            if (!squad.IsBuddyMode && count >= 5) throw new System.Exception("Squad is full");

            await _repository.AddMemberAsync(request.SquadId, request.UserId, "Member");
        }
    }
}
