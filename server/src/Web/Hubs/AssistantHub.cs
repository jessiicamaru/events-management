using HabitTracker.Application.Features.Assistant.Harness;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace HabitTracker.Web.Hubs
{
    /// <summary>
    /// Progress of the assistant's turns, pushed to the user who asked. Clients only listen:
    /// the hub has no methods to call, and every push goes to <c>Clients.User</c> — the
    /// signed-in user's own connections — so nobody can subscribe to someone else's turn.
    /// </summary>
    [Authorize]
    public class AssistantHub : Hub
    {
        public const string Path = "/assistantHub";

        public const string ToolStarted = "assistant.toolStarted";
        public const string ToolFinished = "assistant.toolFinished";
    }

    /// <summary><see cref="IAssistantProgress"/> over <see cref="AssistantHub"/>.</summary>
    public class AssistantHubProgress : IAssistantProgress
    {
        private readonly IHubContext<AssistantHub> _hub;

        public AssistantHubProgress(IHubContext<AssistantHub> hub)
        {
            _hub = hub;
        }

        public Task ToolStartedAsync(string userId, Guid conversationId, string toolName) =>
            _hub.Clients.User(userId).SendAsync(AssistantHub.ToolStarted, new { conversationId, tool = toolName });

        public Task ToolFinishedAsync(string userId, Guid conversationId, string toolName, bool failed) =>
            _hub.Clients.User(userId).SendAsync(AssistantHub.ToolFinished, new { conversationId, tool = toolName, failed });
    }

    /// <summary>
    /// The hubs a client may authenticate to with <c>?access_token=</c>. The Flutter SignalR
    /// client cannot set headers, so the token comes as a query string and is copied into the
    /// Authorization header — for these paths only, so a token in a URL is accepted nowhere else.
    /// </summary>
    public static class HubTokenPaths
    {
        public const string SocialHub = "/socialHub";

        private static readonly string[] Paths = { SocialHub, AssistantHub.Path };

        public static bool AcceptsQueryToken(Microsoft.AspNetCore.Http.PathString path) =>
            Paths.Any(p => path.StartsWithSegments(p));
    }
}
