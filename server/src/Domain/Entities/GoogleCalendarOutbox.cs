using System;

namespace HabitTracker.Domain.Entities
{
    public class GoogleCalendarOutbox
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string UserId { get; set; } = string.Empty;
        public ApplicationUser? User { get; set; }
        public Guid EventId { get; set; }
        public string? GoogleEventId { get; set; }
        public string Action { get; set; } = string.Empty; // "Insert", "Update", "Delete"
        public string Payload { get; set; } = string.Empty; // JSON serialized fields
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? ProcessedAt { get; set; }
        public string? Error { get; set; }
        public int RetryCount { get; set; } = 0;
    }
}
