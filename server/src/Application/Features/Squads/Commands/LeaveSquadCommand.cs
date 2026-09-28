using System;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Interfaces;
using MediatR;
using System.Linq;

namespace HabitTracker.Application.Features.Squads.Commands
{
    public class LeaveSquadCommand : IRequest
    {
        public Guid SquadId { get; set; }
        public string UserId { get; set; } = string.Empty;
    }

    public class LeaveSquadCommandHandler : IRequestHandler<LeaveSquadCommand>
    {
        private readonly ISquadRepository _repository;

        public LeaveSquadCommandHandler(ISquadRepository repository)
        {
            _repository = repository;
        }

        public async Task Handle(LeaveSquadCommand request, CancellationToken cancellationToken)
        {
            var membership = await _repository.GetMembershipAsync(request.SquadId, request.UserId);
            if (membership == null) throw new Exception("You are not a member of this squad");

            var members = await _repository.GetSquadMembersAsync(request.SquadId);
            var approvedMembers = members.Where(m => m.IsApproved).ToList();

            if (membership.Role == "Leader" && approvedMembers.Count(m => m.Role == "Leader") == 1)
            {
                // If this is the only leader, transfer leader to another approved member if any, or delete squad
                var nextLeader = approvedMembers.FirstOrDefault(m => m.UserId != request.UserId);
                if (nextLeader != null)
                {
                    nextLeader.Role = "Leader";
                    await _repository.UpdateMemberAsync(nextLeader);
                }
                // (Optional: If no members left, Squad will just be empty or we could delete it, but removing member is fine)
            }

            await _repository.RemoveMemberAsync(request.SquadId, request.UserId);
        }
    }
}
