using System;

namespace HabitTracker.Domain.Entities
{
    public class Squad
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string Name { get; set; } = string.Empty;
        public bool IsBuddyMode { get; set; } = true;
        public int TotalSquadXP { get; set; } = 0;
        public string UnlockedHeatmapColor { get; set; } = "#22c55e"; // default green
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
