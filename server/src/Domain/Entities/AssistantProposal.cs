namespace HabitTracker.Domain.Entities
{
    /// <summary>
    /// Something the assistant suggested adding to the calendar, waiting for the user.
    /// </summary>
    /// <remarks>
    /// The assistant never writes to the calendar itself: a tool records a proposal, the app
    /// shows it as a card with an "Add to calendar" button, and only that tap creates the
    /// event. The proposal keeps what it created, so the same card can undo it.
    /// </remarks>
    public class AssistantProposal
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string UserId { get; set; } = string.Empty;
        public Guid ConversationId { get; set; }
        public AssistantConversation? Conversation { get; set; }

        /// <summary>The tool call that made it — ties the card to its place in the conversation.</summary>
        public string ToolCallId { get; set; } = string.Empty;

        /// <summary>What applying it creates, as JSON. Its shape belongs to the tool that wrote it.</summary>
        public string PayloadJson { get; set; } = "{}";

        /// <summary><see cref="AssistantProposalStatus"/>.</summary>
        public string Status { get; set; } = AssistantProposalStatus.Pending;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? ResolvedAt { get; set; }

        /// <summary>The repeating event applying it created, for undo.</summary>
        public Guid? CreatedEventId { get; set; }

        /// <summary>The habit applying it created, if it made a new one, for undo.</summary>
        public Guid? CreatedHabitId { get; set; }
    }

    public static class AssistantProposalStatus
    {
        public const string Pending = "pending";
        public const string Applied = "applied";
        public const string Dismissed = "dismissed";
        public const string Undone = "undone";
    }
}
