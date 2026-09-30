using System;

namespace HabitTracker.Domain.Entities
{
    public class GoogleCalendarSyncCache
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string UserId { get; set; } = string.Empty;
        public ApplicationUser? User { get; set; }
        public DateTime SyncedFrom { get; set; }
        public DateTime SyncedTo { get; set; }
        public DateTime LastSyncedAt { get; set; } = DateTime.UtcNow;
    }
}
