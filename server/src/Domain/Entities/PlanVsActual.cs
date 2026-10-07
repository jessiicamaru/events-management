namespace HabitTracker.Domain.Entities
{
    /// <summary>
    /// Booked time against recorded time for one habit or one category, aggregated by the
    /// database.
    /// </summary>
    /// <remarks>
    /// Not a table — the shape a <c>GROUP BY</c> returns, like
    /// <see cref="DailyActivity"/>, and in Domain for the same reason:
    /// <see cref="Interfaces.IEventRepository"/> returns it.
    ///
    /// Only events with an <see cref="Event.ActualDuration"/> are counted, so the two sides
    /// describe the same sessions. Counting every booked event's target against the recorded
    /// time of the few that were done would read as "you always overrun", when the real
    /// answer is "you did four of the nine you booked" — which the activity card already says.
    /// </remarks>
    public class PlanVsActual
    {
        /// <summary>The habit's or category's id, as text — the grouping key.</summary>
        public string GroupId { get; set; } = string.Empty;

        /// <summary>Its name, for the label.</summary>
        public string GroupName { get; set; } = string.Empty;

        /// <summary>How many finished sessions are behind these numbers.</summary>
        public int Sessions { get; set; }

        /// <summary>Total <see cref="Event.TargetDuration"/> of those sessions, in whole minutes.</summary>
        public int PlannedMinutes { get; set; }

        /// <summary>Total <see cref="Event.ActualDuration"/> of those sessions, in whole minutes.</summary>
        public int ActualMinutes { get; set; }
    }
}
