using System;
using System.Text.Json.Serialization;

namespace HabitTracker.Domain.Entities
{
    public class EventTask
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid EventId { get; set; }
        
        [JsonIgnore]
        public Event? Event { get; set; }
        
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int Order { get; set; }
        public Priority Priority { get; set; } = Priority.Medium;
        public int? EstimatedMinutes { get; set; }
        public bool IsCompleted { get; set; } = false;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
