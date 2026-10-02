using System;

namespace HabitTracker.Domain.Entities
{
    public class GoogleCalendarChannel
    {
        public string Id { get; set; } = string.Empty; // Channel ID
        public string ResourceId { get; set; } = string.Empty; // Google Resource ID
        public string UserId { get; set; } = string.Empty;
        public ApplicationUser? User { get; set; }
        public DateTime Expiration { get; set; }
    }
}
