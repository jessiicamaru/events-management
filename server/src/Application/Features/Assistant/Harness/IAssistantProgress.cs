namespace HabitTracker.Application.Features.Assistant.Harness
{
    /// <summary>
    /// Where the harness reports a turn's progress while it runs, so the app can show
    /// "looking at your calendar…" instead of a silent wait. The web layer pushes these over
    /// SignalR; the final reply is also the HTTP response, so a dropped connection loses
    /// nothing but the progress.
    /// </summary>
    public interface IAssistantProgress
    {
        Task ToolStartedAsync(string userId, Guid conversationId, string toolName);

        Task ToolFinishedAsync(string userId, Guid conversationId, string toolName, bool failed);
    }

    /// <summary>Reports nothing. For tests, and anywhere progress has no audience.</summary>
    public sealed class NoAssistantProgress : IAssistantProgress
    {
        public Task ToolStartedAsync(string userId, Guid conversationId, string toolName) => Task.CompletedTask;

        public Task ToolFinishedAsync(string userId, Guid conversationId, string toolName, bool failed) => Task.CompletedTask;
    }
}
