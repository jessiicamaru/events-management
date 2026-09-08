using System;
using System.Collections.Generic;

namespace HabitTracker.Domain.Entities
{
    public class Habit
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string Name { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty; // AI categorized
        public List<int> TargetDays { get; set; } = new(); // 1=Monday...7=Sunday
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
