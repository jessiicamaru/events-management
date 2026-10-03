using System;

namespace HabitTracker.Domain.Entities
{
    public class Event
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string Title { get; set; } = string.Empty;
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public string HabitId { get; set; } = string.Empty;
        public bool IsCompleted { get; set; }

        /// <summary>
        /// XP actually granted to the user when this event was completed. Stored so that
        /// un-completing the event refunds exactly what was awarded, instead of
        /// recalculating from the streak as it stands at that later moment.
        /// Zero whenever <see cref="IsCompleted"/> is false.
        /// </summary>
        public int AwardedXp { get; set; }

        /// <summary>
        /// Minutes before <see cref="StartTime"/> at which to remind the user, one entry per
        /// reminder. `0` means "when it starts"; an empty list means no reminders.
        /// <para>
        /// Held on the event rather than in global settings so each event carries its own
        /// set. A single occurrence of a recurring event can differ simply by editing it
        /// with <c>editScope: "ThisOccurrence"</c> — that already creates a child event,
        /// which carries its own reminders.
        /// </para>
        /// <para>
        /// Reminders are scheduled on the device; the server only stores the preference.
        /// </para>
        /// </summary>
        public List<int> ReminderMinutesBefore { get; set; } = new();

        public TimeSpan TargetDuration { get; set; }
        public TimeSpan? ActualDuration { get; set; }
        public string? UserId { get; set; }
        public ApplicationUser? User { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public Guid? CategoryId { get; set; }
        public EventCategory? Category { get; set; }
        public ICollection<EventTask> Tasks { get; set; } = new List<EventTask>();
        
        // Google Calendar sync mapping
        public string? GoogleEventId { get; set; }

        // Recurrence properties
        public string? RecurrenceRule { get; set; }
        public Guid? ParentEventId { get; set; }
        public Event? ParentEvent { get; set; }
        public DateTime? ExceptionDate { get; set; }
        public string? RecurrenceExceptionDates { get; set; }
    }
}
