namespace HabitTracker.Application.Common
{
    /// <summary>
    /// Central definition of how completing an event converts into XP.
    /// Kept in one place so the award and the refund can never drift apart.
    /// </summary>
    public static class XpRules
    {
        /// <summary>XP granted for completing an event, before any streak bonus.</summary>
        public const int BaseXp = 10;

        /// <summary>Extra XP per day of the user's current activity streak, beyond the first day.</summary>
        public const int StreakBonusPerDay = 2;

        /// <summary>XP for completing an event while on a streak of <paramref name="activityStreak"/> days.</summary>
        public static int ForStreak(int activityStreak)
        {
            var bonusDays = activityStreak - 1;
            if (bonusDays < 0) bonusDays = 0;

            return BaseXp + (bonusDays * StreakBonusPerDay);
        }
    }
}
