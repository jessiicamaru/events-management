using System;
using System.Collections.Generic;
using Microsoft.AspNetCore.Identity;

namespace HabitTracker.Domain.Entities
{
    public class ApplicationUser : IdentityUser
    {
        public int TotalXP { get; set; } = 0;
        public int CurrentLevel { get; set; } = 1;
        public List<string> UnlockedEmojis { get; set; } = new List<string> { "🔥", "👍", "👏" };
        public string AvatarBorderColor { get; set; } = "#cccccc";
        public string? DisplayName { get; set; }
        public string? Bio { get; set; }
        public DateTime? DateOfBirth { get; set; }
        public string? Gender { get; set; }
        public string? Avatar { get; set; }
    }
}
