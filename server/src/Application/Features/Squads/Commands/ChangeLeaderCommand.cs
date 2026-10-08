using System;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Squads.Commands
{
    public class ChangeLeaderCommand : IRequest
    {
        public Guid SquadId { get; set; }
        public string TargetUserId { get; set; } = string.Empty;
        public string ActionByUserId { get; set; } = string.Empty;
    }

    public class ChangeLeaderCommandHandler : IRequestHandler<ChangeLeaderCommand>
    {
        private readonly ISquadRepository _repository;

        public ChangeLeaderCommandHandler(ISquadRepository repository)
        {
            _repository = repository;
        }

        public async Task Handle(ChangeLeaderCommand request, CancellationToken cancellationToken)
        {
            if (request.TargetUserId == request.ActionByUserId)
            {
                throw new Exception("You are already the Leader");
            }

            var callerMembership = await _repository.GetMembershipAsync(request.SquadId, request.ActionByUserId);
            if (callerMembership == null || callerMembership.Role != SquadMember.LeaderRole || !callerMembership.IsApproved)
            {
                throw new Exception("Only approved Leaders can change the Leader");
            }

            var targetMembership = await _repository.GetMembershipAsync(request.SquadId, request.TargetUserId);
            if (targetMembership == null || !targetMembership.IsApproved)
            {
                throw new Exception("Target user must be an approved member of the squad");
            }

            callerMembership.Role = SquadMember.MemberRole;
            targetMembership.Role = SquadMember.LeaderRole;

            await _repository.UpdateMemberAsync(callerMembership);
            await _repository.UpdateMemberAsync(targetMembership);
        }
    }
}
