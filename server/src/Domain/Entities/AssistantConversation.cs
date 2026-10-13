namespace HabitTracker.Domain.Entities
{
    /// <summary>One chat with the assistant. Belongs to one user; its messages are its history.</summary>
    public class AssistantConversation
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string UserId { get; set; } = string.Empty;
        public ApplicationUser? User { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        /// <summary>When a message was last added — what "most recent" conversations sort by.</summary>
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public ICollection<AssistantMessage> Messages { get; set; } = new List<AssistantMessage>();
    }
}
