using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Squads.Queries
{
    public class SquadChatMessageDto
    {
        public Guid Id { get; set; }
        public Guid SquadId { get; set; }
        public string? SenderUserId { get; set; }
        public string SenderDisplayName { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public DateTime SentAt { get; set; }
        public bool IsSystemMessage { get; set; }
    }

    public class GetChatHistoryQuery : IRequest<List<SquadChatMessageDto>>
    {
        public Guid SquadId { get; set; }
        public string UserId { get; set; } = string.Empty; // to verify access
    }

    public class GetChatHistoryQueryHandler : IRequestHandler<GetChatHistoryQuery, List<SquadChatMessageDto>>
    {
        private readonly ISquadRepository _repository;

        public GetChatHistoryQueryHandler(ISquadRepository repository)
        {
            _repository = repository;
        }

        public async Task<List<SquadChatMessageDto>> Handle(GetChatHistoryQuery request, CancellationToken cancellationToken)
        {
            var membership = await _repository.GetMembershipAsync(request.SquadId, request.UserId);
            if (membership == null || !membership.IsApproved)
            {
                throw new Exception("You are not an approved member of this squad");
            }

            var messages = await _repository.GetChatMessageHistoryAsync(request.SquadId);
            var members = await _repository.GetSquadMembersAsync(request.SquadId);
            var memberDict = members.ToDictionary(m => m.UserId);

            return messages.Select(m =>
            {
                string senderName = "System";
                if (!m.IsSystemMessage && m.SenderUserId != null && memberDict.TryGetValue(m.SenderUserId, out var member))
                {
                    senderName = member.Nickname ?? member.User?.DisplayName ?? member.User?.Email?.Split('@').First() ?? "Unknown";
                }

                return new SquadChatMessageDto
                {
                    Id = m.Id,
                    SquadId = m.SquadId,
                    SenderUserId = m.SenderUserId,
                    SenderDisplayName = senderName,
                    Message = m.Message,
                    SentAt = m.SentAt,
                    IsSystemMessage = m.IsSystemMessage
                };
            }).ToList();
        }
    }
}
