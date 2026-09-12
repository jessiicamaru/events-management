using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;
using System.Threading.Tasks;
using System;

namespace HabitTracker.Web.Hubs
{
    [Authorize]
    public class SocialHub : Hub
    {
        public override async Task OnConnectedAsync()
        {
            var userId = Context.User?.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId != null)
            {
                // In a real app we might get the squad id from DB and add to group
                // For now, we can just log connection
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
            await Clients.Group($"Squad_{squadId}").SendAsync("ReceivePoke", senderId, targetUserId);
        }

        public async Task SendReaction(string squadId, string targetUserId, string emoji)
        {
            var senderId = Context.User?.FindFirstValue(ClaimTypes.NameIdentifier);
            await Clients.Group($"Squad_{squadId}").SendAsync("ReceiveReaction", senderId, targetUserId, emoji);
        }
    }
}
