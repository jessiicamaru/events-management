using System;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Squads.Commands
{
    public class UpdateSquadSettingsCommand : IRequest
    {
        public Guid SquadId { get; set; }
        public string Name { get; set; } = string.Empty;
        public int MaxMembers { get; set; }
        public bool RequireApproval { get; set; }
        public string ActionByUserId { get; set; } = string.Empty;
    }

    public class UpdateSquadSettingsCommandHandler : IRequestHandler<UpdateSquadSettingsCommand>
    {
        private readonly ISquadRepository _repository;

        public UpdateSquadSettingsCommandHandler(ISquadRepository repository)
        {
            _repository = repository;
        }

        public async Task Handle(UpdateSquadSettingsCommand request, CancellationToken cancellationToken)
        {
            var callerMembership = await _repository.GetMembershipAsync(request.SquadId, request.ActionByUserId);
            if (callerMembership == null || callerMembership.Role != "Leader" || !callerMembership.IsApproved)
            {
                throw new Exception("Only approved Leaders can update squad settings");
            }

            var squad = await _repository.GetSquadByIdAsync(request.SquadId);
            if (squad == null) throw new Exception("Squad not found");

            if (request.MaxMembers < 2 || request.MaxMembers > 10)
            {
                throw new Exception("Max members must be between 2 and 10");
            }

            var currentCount = await _repository.GetMemberCountAsync(request.SquadId);
            if (request.MaxMembers < currentCount)
            {
                throw new Exception("Cannot reduce capacity limit below current member count (" + currentCount + ")");
            }

            squad.Name = request.Name;
            squad.MaxMembers = request.MaxMembers;
            squad.RequireApproval = request.RequireApproval;

            await _repository.UpdateAsync(squad);
        }
    }
}
