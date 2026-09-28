using System;
using System.Threading;
using System.Threading.Tasks;
using System.Linq;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Squads.Commands
{
    public class ChangeMemberNicknameCommand : IRequest
    {
        public Guid SquadId { get; set; }
        public string TargetUserId { get; set; } = string.Empty;
        public string NewNickname { get; set; } = string.Empty;
        public string ActionByUserId { get; set; } = string.Empty;
    }

    public class ChangeMemberNicknameCommandHandler : IRequestHandler<ChangeMemberNicknameCommand>
    {
        private readonly ISquadRepository _repository;

        public ChangeMemberNicknameCommandHandler(ISquadRepository repository)
        {
            _repository = repository;
        }

        public async Task Handle(ChangeMemberNicknameCommand request, CancellationToken cancellationToken)
        {
            var callerMembership = await _repository.GetMembershipAsync(request.SquadId, request.ActionByUserId);
            if (callerMembership == null || !callerMembership.IsApproved)
            {
                throw new Exception("Only approved squad members can change nicknames");
            }

            var targetMembership = await _repository.GetMembershipAsync(request.SquadId, request.TargetUserId);
            if (targetMembership == null || !targetMembership.IsApproved)
            {
                throw new Exception("Target member not found in squad");
            }

            var originalNickname = targetMembership.Nickname;
            targetMembership.Nickname = string.IsNullOrWhiteSpace(request.NewNickname) ? null : request.NewNickname;
            await _repository.UpdateMemberAsync(targetMembership);

            // Generate system message
            var callerName = callerMembership.Nickname ?? callerMembership.User?.Email?.Split('@').First() ?? "Unknown";
            var targetName = originalNickname ?? targetMembership.User?.Email?.Split('@').First() ?? "Unknown";
            
            string systemMsgText = string.IsNullOrWhiteSpace(request.NewNickname)
                ? $"{callerName} đã gỡ biệt danh của {targetName}"
                : $"{callerName} đã đặt biệt danh cho {targetName} là '{request.NewNickname}'";

            var systemMessage = new SquadChatMessage
            {
                SquadId = request.SquadId,
                SenderUserId = null,
                Message = systemMsgText,
                IsSystemMessage = true,
                SentAt = DateTime.UtcNow
            };

            await _repository.SaveChatMessageAsync(systemMessage);
        }
    }
}
