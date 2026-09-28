using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;
using System.Threading.Tasks;
using System;
using HabitTracker.Domain.Interfaces;
using HabitTracker.Domain.Entities;
using System.Linq;

namespace HabitTracker.Web.Hubs
{
    [Authorize]
    public class SocialHub : Hub
    {
        private readonly ISquadRepository _squadRepository;

        public SocialHub(ISquadRepository squadRepository)
        {
            _squadRepository = squadRepository;
        }

        public override async Task OnConnectedAsync()
        {
            var userId = Context.User?.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId != null)
            {
                Console.WriteLine($"User {userId} connected to SocialHub");
            }
            await base.OnConnectedAsync();
        }

        public async Task JoinSquadGroup(string squadId)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"Squad_{squadId}");
        }

        public async Task SendPoke(string squadId, string targetUserId)
        {
            var senderId = Context.User?.FindFirstValue(ClaimTypes.NameIdentifier);
            if (senderId != null)
            {
                await Clients.Group($"Squad_{squadId}").SendAsync("ReceivePoke", senderId, targetUserId);
            }
        }

        public async Task SendReaction(string squadId, string targetUserId, string emoji)
        {
            var senderId = Context.User?.FindFirstValue(ClaimTypes.NameIdentifier);
            if (senderId != null)
            {
                await Clients.Group($"Squad_{squadId}").SendAsync("ReceiveReaction", senderId, targetUserId, emoji);
            }
        }

        public async Task SendMessage(string squadId, string message)
        {
            var senderId = Context.User?.FindFirstValue(ClaimTypes.NameIdentifier);
            if (senderId == null) return;

            if (Guid.TryParse(squadId, out Guid squadGuid))
            {
                var msg = new SquadChatMessage
                {
                    SquadId = squadGuid,
                    SenderUserId = senderId,
                    Message = message,
                    SentAt = DateTime.UtcNow,
                    IsSystemMessage = false
                };

                await _squadRepository.SaveChatMessageAsync(msg);

                var members = await _squadRepository.GetSquadMembersAsync(squadGuid);
                var member = members.FirstOrDefault(m => m.UserId == senderId);
                var senderName = member?.Nickname ?? member?.User?.DisplayName ?? member?.User?.Email?.Split('@').First() ?? "Unknown";

                await Clients.Group($"Squad_{squadId}").SendAsync("ReceiveMessage", new
                {
                    Id = msg.Id,
                    SquadId = msg.SquadId,
                    SenderUserId = msg.SenderUserId,
                    SenderDisplayName = senderName,
                    Message = msg.Message,
                    SentAt = msg.SentAt,
                    IsSystemMessage = msg.IsSystemMessage
                });
            }
        }
    }
}
