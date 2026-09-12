using System;

namespace HabitTracker.Domain.Entities
{
    public class SquadMember
    {
        public Guid SquadId { get; set; }
        public Squad? Squad { get; set; }

        public string UserId { get; set; } = string.Empty;
        public ApplicationUser? User { get; set; }

        public string Role { get; set; } = "Member"; // "Admin", "Member"
        public DateTime JoinedAt { get; set; } = DateTime.UtcNow;
    }
}
