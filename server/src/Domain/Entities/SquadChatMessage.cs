using System;

namespace HabitTracker.Domain.Entities
{
    public class SquadChatMessage
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        
        public Guid SquadId { get; set; }
        public Squad? Squad { get; set; }

        public string? SenderUserId { get; set; }
        public ApplicationUser? Sender { get; set; }

        public string Message { get; set; } = string.Empty;
        public DateTime SentAt { get; set; } = DateTime.UtcNow;
        public bool IsSystemMessage { get; set; } = false;
    }
}
