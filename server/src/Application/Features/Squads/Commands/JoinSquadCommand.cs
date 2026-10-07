using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;
using System.Threading;
using System.Threading.Tasks;

namespace HabitTracker.Application.Features.Squads.Commands
{
    public class JoinSquadCommand : IRequest<bool>
    {
        public System.Guid SquadId { get; set; }
        public string UserId { get; set; } = string.Empty;
    }

    public class JoinSquadCommandHandler : IRequestHandler<JoinSquadCommand, bool>
    {
        private readonly ISquadRepository _repository;

        public JoinSquadCommandHandler(ISquadRepository repository)
        {
            _repository = repository;
        }

        public async Task<bool> Handle(JoinSquadCommand request, CancellationToken cancellationToken)
        {
            var membership = await _repository.GetMembershipAsync(request.SquadId, request.UserId);
            if (membership != null)
            {
                if (membership.IsApproved)
                    throw new System.Exception("Already a member of this squad");
                else
                    throw new System.Exception("Your request to join this squad is pending approval");
            }

            var squad = await _repository.GetSquadByIdAsync(request.SquadId);
            if (squad == null) throw new System.Exception("Squad not found");

            var count = await _repository.GetMemberCountAsync(request.SquadId);
            if (count >= squad.MaxMembers) throw new System.Exception("Squad is full");

            bool isApproved = !squad.RequireApproval;
            await _repository.AddMemberAsync(request.SquadId, request.UserId, SquadMember.MemberRole, isApproved);

            return isApproved;
        }
    }
}
