using System;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Squads.Commands
{
    public class RejectMemberCommand : IRequest
    {
        public Guid SquadId { get; set; }
        public string TargetUserId { get; set; } = string.Empty;
        public string ActionByUserId { get; set; } = string.Empty;
    }

    public class RejectMemberCommandHandler : IRequestHandler<RejectMemberCommand>
    {
        private readonly ISquadRepository _repository;

        public RejectMemberCommandHandler(ISquadRepository repository)
        {
            _repository = repository;
        }

        public async Task Handle(RejectMemberCommand request, CancellationToken cancellationToken)
        {
            if (request.TargetUserId == request.ActionByUserId)
            {
                throw new Exception("You cannot reject or kick yourself. Use Leave instead.");
            }

            var callerMembership = await _repository.GetMembershipAsync(request.SquadId, request.ActionByUserId);
            if (callerMembership == null || callerMembership.Role != "Leader" || !callerMembership.IsApproved)
            {
                throw new Exception("Only approved Leaders can reject or kick members");
            }

            var targetMembership = await _repository.GetMembershipAsync(request.SquadId, request.TargetUserId);
            if (targetMembership == null) throw new Exception("Member not found in squad");

            await _repository.RemoveMemberAsync(request.SquadId, request.TargetUserId);
        }
    }
}
