using System;
using System.Text.Json.Serialization;

namespace HabitTracker.Domain.Entities
{
    public class HabitTask
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid HabitId { get; set; }
        
        [JsonIgnore]
        public Habit? Habit { get; set; }
        
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int Order { get; set; }
        public Priority Priority { get; set; } = Priority.Medium;
        public int? EstimatedMinutes { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }

    public enum Priority
    {
        Low,
        Medium,
        High
    }
}
