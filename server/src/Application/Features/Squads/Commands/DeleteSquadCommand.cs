using System;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Squads.Commands
{
    public class DeleteSquadCommand : IRequest
    {
        public Guid SquadId { get; set; }
        public string ActionByUserId { get; set; } = string.Empty;
    }

    public class DeleteSquadCommandHandler : IRequestHandler<DeleteSquadCommand>
    {
        private readonly ISquadRepository _repository;

        public DeleteSquadCommandHandler(ISquadRepository repository)
        {
            _repository = repository;
        }

        public async Task Handle(DeleteSquadCommand request, CancellationToken cancellationToken)
        {
            var callerMembership = await _repository.GetMembershipAsync(request.SquadId, request.ActionByUserId);
            if (callerMembership == null || callerMembership.Role != SquadMember.LeaderRole || !callerMembership.IsApproved)
            {
                throw new Exception("Only approved Leaders can delete the squad");
            }

            var squad = await _repository.GetSquadByIdAsync(request.SquadId);
            if (squad == null)
            {
                throw new Exception("Squad not found");
            }

            await _repository.DeleteSquadAsync(request.SquadId);
        }
    }
}
