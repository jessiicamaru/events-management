using System;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Squads.Commands
{
    public class ApproveMemberCommand : IRequest
    {
        public Guid SquadId { get; set; }
        public string TargetUserId { get; set; } = string.Empty;
        public string ActionByUserId { get; set; } = string.Empty;
    }

    public class ApproveMemberCommandHandler : IRequestHandler<ApproveMemberCommand>
    {
        private readonly ISquadRepository _repository;

        public ApproveMemberCommandHandler(ISquadRepository repository)
        {
            _repository = repository;
        }

        public async Task Handle(ApproveMemberCommand request, CancellationToken cancellationToken)
        {
            var callerMembership = await _repository.GetMembershipAsync(request.SquadId, request.ActionByUserId);
            if (callerMembership == null || callerMembership.Role != SquadMember.LeaderRole || !callerMembership.IsApproved)
            {
                throw new Exception("Only approved Leaders can approve members");
            }

            var targetMembership = await _repository.GetMembershipAsync(request.SquadId, request.TargetUserId);
            if (targetMembership == null) throw new Exception("Join request not found");
            if (targetMembership.IsApproved) throw new Exception("User is already approved");

            var squad = await _repository.GetSquadByIdAsync(request.SquadId);
            if (squad == null) throw new Exception("Squad not found");

            var count = await _repository.GetMemberCountAsync(request.SquadId);
            if (count >= squad.MaxMembers) throw new Exception("Squad is full. Cannot approve.");

            targetMembership.IsApproved = true;
            await _repository.UpdateMemberAsync(targetMembership);
        }
    }
}
