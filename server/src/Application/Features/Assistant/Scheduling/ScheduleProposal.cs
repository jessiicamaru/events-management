using System.Globalization;
using System.Text.Json;
using System.Text.Json.Serialization;
using HabitTracker.Application.Features.Assistant.Harness;
using HabitTracker.Domain.Entities;

namespace HabitTracker.Application.Features.Assistant.Scheduling
{
    /// <summary>
    /// What a <c>propose_schedule</c> proposal creates when applied: a repeating event, on a
    /// new habit or an existing one. Stored as <see cref="AssistantProposal.PayloadJson"/>.
    /// </summary>
    /// <param name="StartLocal">Time of day, "HH:mm", local.</param>
    /// <param name="Days">1 = Monday … 7 = Sunday.</param>
    /// <param name="FirstDate">The first day, "yyyy-MM-dd" — always one of <paramref name="Days"/>.</param>
    /// <param name="HabitId">The existing habit it joins; null means applying creates a habit named <paramref name="Title"/>.</param>
    public sealed record ScheduleProposal(
        string Title,
        int DurationMinutes,
        string StartLocal,
        IReadOnlyList<int> Days,
        string FirstDate,
        string RecurrenceRule,
        IReadOnlyList<int> Reminders,
        Guid? HabitId,
        string? HabitName,
        Guid? CategoryId,
        IReadOnlyList<ScheduleConflict> Conflicts)
    {
        private static readonly string[] ByDay = { "MO", "TU", "WE", "TH", "FR", "SA", "SU" };

        [JsonIgnore]
        public TimeSpan Start => TimeSpan.ParseExact(StartLocal, @"hh\:mm", CultureInfo.InvariantCulture);

        [JsonIgnore]
        public DateOnly First => DateOnly.ParseExact(FirstDate, "yyyy-MM-dd", CultureInfo.InvariantCulture);

        [JsonIgnore]
        public string EndLocal => (Start + TimeSpan.FromMinutes(DurationMinutes)).ToString(@"hh\:mm", CultureInfo.InvariantCulture);

        /// <summary>Every day as FREQ=DAILY, otherwise the weekdays as BYDAY — the shapes the app writes too.</summary>
        public static string RuleFor(IReadOnlyCollection<int> days) =>
            days.Count == 7
                ? "RRULE:FREQ=DAILY"
                : "RRULE:FREQ=WEEKLY;BYDAY=" + string.Join(',', days.Order().Select(d => ByDay[d - 1]));

        public string ToJson() => JsonSerializer.Serialize(this, ToolJson.Options);

        public static ScheduleProposal FromJson(string json) =>
            JsonSerializer.Deserialize<ScheduleProposal>(json, ToolJson.Options)
            ?? throw new InvalidOperationException("Empty proposal payload.");
    }

    /// <param name="Date">"yyyy-MM-dd".</param>
    public sealed record ScheduleConflict(string Date, string Title);
}
