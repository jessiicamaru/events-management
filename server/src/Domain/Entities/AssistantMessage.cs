namespace HabitTracker.Domain.Entities
{
    /// <summary>
    /// One entry in a conversation's history, stored in a provider-neutral shape so the
    /// language model behind the assistant can change without migrating the history.
    /// </summary>
    /// <remarks>
    /// The history is append-only: a message is never edited once written. Besides being
    /// the honest record, that keeps each request's prefix stable, which is what a provider's
    /// prompt cache keys on.
    /// </remarks>
    public class AssistantMessage
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid ConversationId { get; set; }
        public AssistantConversation? Conversation { get; set; }

        /// <summary>Position in the conversation, from 0. Unique per conversation.</summary>
        public int Sequence { get; set; }

        /// <summary>Who wrote it: <see cref="AssistantRoles"/>.</summary>
        public string Role { get; set; } = AssistantRoles.User;

        public string? Content { get; set; }

        /// <summary>
        /// For an assistant message that asked for tools: the calls, as a JSON array of
        /// <c>{ id, name, arguments }</c>. Every call has exactly one tool message answering it.
        /// </summary>
        public string? ToolCallsJson { get; set; }

        /// <summary>For a tool message: the id of the call it answers.</summary>
        public string? ToolCallId { get; set; }

        /// <summary>For a tool message: which tool ran, so the history can be shown without parsing.</summary>
        public string? ToolName { get; set; }

        /// <summary>
        /// Whatever the provider needs back on a later request and nobody else reads — for
        /// DeepSeek, the reasoning behind a tool call. Opaque outside the adapter that wrote it.
        /// </summary>
        public string? ProviderData { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }

    /// <summary>The roles an <see cref="AssistantMessage"/> can have, as stored.</summary>
    public static class AssistantRoles
    {
        public const string User = "user";
        public const string Assistant = "assistant";
        public const string Tool = "tool";
    }
}
