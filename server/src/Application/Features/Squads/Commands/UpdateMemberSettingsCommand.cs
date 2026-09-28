using System;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Squads.Commands
{
    public class UpdateMemberSettingsCommand : IRequest
    {
        public Guid SquadId { get; set; }
        public string UserId { get; set; } = string.Empty;
        public string? Nickname { get; set; }
        public bool IsMuted { get; set; }
        public bool XpContributionEnabled { get; set; }
    }

    public class UpdateMemberSettingsCommandHandler : IRequestHandler<UpdateMemberSettingsCommand>
    {
        private readonly ISquadRepository _repository;

        public UpdateMemberSettingsCommandHandler(ISquadRepository repository)
        {
            _repository = repository;
        }

        public async Task Handle(UpdateMemberSettingsCommand request, CancellationToken cancellationToken)
        {
            var membership = await _repository.GetMembershipAsync(request.SquadId, request.UserId);
            if (membership == null || !membership.IsApproved)
            {
                throw new Exception("Membership not found or not approved");
            }

            membership.Nickname = request.Nickname;
            membership.IsMuted = request.IsMuted;
            membership.XpContributionEnabled = request.XpContributionEnabled;

            await _repository.UpdateMemberAsync(membership);
        }
    }
}
