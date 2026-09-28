using System;

namespace HabitTracker.Domain.Entities
{
    public class SquadMember
    {
        public Guid SquadId { get; set; }
        public Squad? Squad { get; set; }

        public string UserId { get; set; } = string.Empty;
        public ApplicationUser? User { get; set; }

        public string Role { get; set; } = "Member"; // "Leader", "Member"
        public string? Nickname { get; set; }
        public bool IsMuted { get; set; } = false;
        public bool XpContributionEnabled { get; set; } = true;
        public bool IsApproved { get; set; } = true;
        public DateTime JoinedAt { get; set; } = DateTime.UtcNow;
    }
}
