using HabitTracker.Domain.Entities;

namespace HabitTracker.Domain.Interfaces
{
    public interface IAssistantRepository
    {
        Task<AssistantConversation> CreateConversationAsync(string userId);

        /// <summary>The conversation, only if it belongs to <paramref name="userId"/>; otherwise null.</summary>
        Task<AssistantConversation?> GetConversationAsync(Guid conversationId, string userId);

        /// <summary>The user's conversations, most recently used first.</summary>
        Task<IReadOnlyList<AssistantConversation>> GetConversationsAsync(string userId, int limit);

        /// <summary>The conversation's messages in order.</summary>
        Task<IReadOnlyList<AssistantMessage>> GetMessagesAsync(Guid conversationId);

        /// <summary>
        /// Appends <paramref name="messages"/> in order after the existing ones, numbering them,
        /// and marks the conversation as updated.
        /// </summary>
        Task AppendMessagesAsync(Guid conversationId, IReadOnlyList<AssistantMessage> messages);

        /// <summary>How many messages the user has sent to the assistant since <paramref name="sinceUtc"/>, across conversations.</summary>
        Task<int> CountUserMessagesSinceAsync(string userId, DateTime sinceUtc);

        Task<UserAiSettings?> GetSettingsAsync(string userId);

        Task SaveSettingsAsync(UserAiSettings settings);
    }
}
