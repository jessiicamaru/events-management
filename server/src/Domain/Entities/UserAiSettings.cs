namespace HabitTracker.Domain.Entities
{
    /// <summary>
    /// A user's choices about the assistant. No row means the defaults: the assistant is off.
    /// </summary>
    /// <remarks>
    /// Off by default because using it sends the user's calendar data to a third-party
    /// language model; that has to be the user's decision, recorded with when it was made.
    /// </remarks>
    public class UserAiSettings
    {
        public string UserId { get; set; } = string.Empty;
        public ApplicationUser? User { get; set; }

        public bool AssistantEnabled { get; set; }

        /// <summary>Ask before every change, not only the large ones. Used once the assistant can write.</summary>
        public bool AlwaysConfirm { get; set; }

        /// <summary>When the user first turned the assistant on.</summary>
        public DateTime? ConsentedAt { get; set; }

        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
}
