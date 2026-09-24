using System;

namespace HabitTracker.Domain.Entities
{
    public class EventCategory
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string Name { get; set; } = string.Empty;
        public string ColorPreset { get; set; } = "Slate"; // E.g., Slate, Red, Rose, Orange, Green, Blue, Yellow, Violet
        
        public string? UserId { get; set; }
        public ApplicationUser? User { get; set; }
        
        public Guid? SquadId { get; set; }
        public Squad? Squad { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
