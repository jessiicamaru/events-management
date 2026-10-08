using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;
using System.Threading.Tasks;
using System;
using HabitTracker.Application.Common;
using HabitTracker.Domain.Interfaces;
using HabitTracker.Domain.Entities;
using System.Linq;

namespace HabitTracker.Web.Hubs
{
    /// <summary>
    /// Real-time squad features (chat, pokes, reactions) and the calendar-updated push.
    /// </summary>
    /// <remarks>
    /// <para>
    /// <c>[Authorize]</c> only proves the caller is signed in. Every squad method must also prove the
    /// caller belongs to <em>that</em> squad — they did not, so any signed-in user who knew a squad's
    /// id could join its group and receive its live chat, and post messages, pokes and reactions
    /// into it. Found while documenting the authorization work (review of
    /// <c>fix/squad-category-authorization</c>, round 3); the REST chat-history endpoint already
    /// checked membership, the hub did not.
    /// </para>
    /// <para>
    /// A refusal throws <see cref="HubException"/>, which SignalR returns to the caller's invocation
    /// as an error; nothing is saved or broadcast.
    /// </para>
    /// </remarks>
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

        /// <summary>The SignalR group of a squad, spelt one way whatever the client sent.</summary>
        public static string GroupName(Guid squadId) => $"Squad_{squadId}";

        public async Task JoinSquadGroup(string squadId)
        {
            var squadGuid = await RequireMembershipAsync(squadId);

            await Groups.AddToGroupAsync(Context.ConnectionId, GroupName(squadGuid));
        }

        public async Task SendPoke(string squadId, string targetUserId)
        {
            var squadGuid = await RequireMembershipAsync(squadId);
            var members = await _squadRepository.GetSquadMembersAsync(squadGuid);
            var sender = members.FirstOrDefault(m => m.UserId == CallerId);
            var target = RequireApprovedTarget(members, targetUserId);

            var messageText = $"{DisplayName(sender)} đã chọc {DisplayName(target)} ✋";

            await SaveAndBroadcastSystemMessageAsync(squadGuid, messageText);
        }

        public async Task SendReaction(string squadId, string targetUserId, string emoji)
        {
            var squadGuid = await RequireMembershipAsync(squadId);
            var members = await _squadRepository.GetSquadMembersAsync(squadGuid);
            var sender = members.FirstOrDefault(m => m.UserId == CallerId);
            var target = RequireApprovedTarget(members, targetUserId);

            var messageText = $"{DisplayName(sender)} đã thả biểu cảm {emoji} cho {DisplayName(target)}";

            await SaveAndBroadcastSystemMessageAsync(squadGuid, messageText);
        }

        public async Task SendMessage(string squadId, string message)
        {
            var squadGuid = await RequireMembershipAsync(squadId);
            var senderId = CallerId!;

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

            await Clients.Group(GroupName(squadGuid)).SendAsync("ReceiveMessage", new
            {
                Id = msg.Id,
                SquadId = msg.SquadId,
                SenderUserId = msg.SenderUserId,
                SenderDisplayName = DisplayName(member),
                Message = msg.Message,
                SentAt = msg.SentAt,
                IsSystemMessage = msg.IsSystemMessage
            });
        }

        private string? CallerId => Context.User?.FindFirstValue(ClaimTypes.NameIdentifier);

        /// <summary>
        /// The squad's id, if the caller is an approved member of it; otherwise throws. The same rule
        /// as the REST side (<see cref="SquadAccess.CanRead"/>): a pending join request is not
        /// membership.
        /// </summary>
        private async Task<Guid> RequireMembershipAsync(string squadId)
        {
            var callerId = CallerId;
            if (callerId == null || !Guid.TryParse(squadId, out var squadGuid))
            {
                throw new HubException("Not a member of this squad.");
            }

            var membership = await _squadRepository.GetMembershipAsync(squadGuid, callerId);
            if (!SquadAccess.CanRead(membership))
            {
                // The same message for "no such squad" and "not yours", so the hub does not confirm
                // that a squad id exists.
                throw new HubException("Not a member of this squad.");
            }

            return squadGuid;
        }

        /// <summary>
        /// A poke or reaction names its target in a message every member sees, so the target has to
        /// be a member too — otherwise a member could write anyone's name into the squad's chat.
        /// </summary>
        private static SquadMember RequireApprovedTarget(
            System.Collections.Generic.IEnumerable<SquadMember> members,
            string targetUserId)
        {
            var target = members.FirstOrDefault(m => m.UserId == targetUserId);
            if (!SquadAccess.CanRead(target))
            {
                throw new HubException("That user is not a member of this squad.");
            }

            return target!;
        }

        private async Task SaveAndBroadcastSystemMessageAsync(Guid squadId, string text)
        {
            var msg = new SquadChatMessage
            {
                SquadId = squadId,
                SenderUserId = null,
                Message = text,
                SentAt = DateTime.UtcNow,
                IsSystemMessage = true
            };

            await _squadRepository.SaveChatMessageAsync(msg);

            await Clients.Group(GroupName(squadId)).SendAsync("ReceiveMessage", new
            {
                Id = msg.Id,
                SquadId = msg.SquadId,
                SenderUserId = msg.SenderUserId,
                SenderDisplayName = "System",
                Message = msg.Message,
                SentAt = msg.SentAt,
                IsSystemMessage = msg.IsSystemMessage
            });
        }

        private static string DisplayName(SquadMember? member) =>
            member?.Nickname
            ?? member?.User?.DisplayName
            ?? member?.User?.Email?.Split('@').First()
            ?? "Unknown";
    }
}
