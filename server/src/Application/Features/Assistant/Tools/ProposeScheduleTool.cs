using System.Globalization;
using System.Text.Json;
using HabitTracker.Application.Common;
using HabitTracker.Application.Features.Assistant.Harness;
using HabitTracker.Application.Features.Assistant.Scheduling;
using HabitTracker.Application.Features.Events.Queries;
using HabitTracker.Application.Features.Habits.Queries;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Assistant.Tools
{
    /// <summary>
    /// Suggests when a repeating session fits, within the times the user offers, and records it
    /// as a proposal the app shows with an "Add to calendar" button. Writes nothing to the
    /// calendar: applying is the user's tap (<c>ApplyAssistantProposalCommand</c>).
    /// </summary>
    public class ProposeScheduleTool : IAssistantTool
    {
        public const int MaxTitleLength = 100;
        public const int MinDurationMinutes = 5;
        public const int MaxDurationMinutes = 240;
        public const int MaxWindows = 3;

        /// <summary>The best option and one alternative from another window, at most.</summary>
        public const int MaxProposals = 2;

        /// <summary>Clash dates listed per option; the count covers the rest.</summary>
        public const int MaxConflictsListed = 6;

        private static readonly string[] DayNames = { "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" };
        private static readonly IReadOnlyList<int> DefaultReminders = new[] { 15 };

        private readonly ISender _sender;
        private readonly IAssistantRepository _repository;

        public ProposeScheduleTool(ISender sender, IAssistantRepository repository)
        {
            _sender = sender;
            _repository = repository;
        }

        public string Name => "propose_schedule";

        public string Description =>
            "Propose a repeating session for the user to add to their calendar, e.g. 45 minutes of running every day " +
            "between 05:00 and 06:00 or 18:00 and 19:00. Finds the start time in each window that clashes with the fewest " +
            "existing events over the next 14 days. This does NOT add anything: the app shows each proposal as a card with an " +
            "add button, and only the user's tap adds it. If similarHabits comes back and the user did not " +
            "say, ask whether to use that habit (call again with its habitId) or keep a new one.";

        public string ParametersSchemaJson => """
            {
              "type": "object",
              "properties": {
                "title": { "type": "string", "description": "Name of the session, e.g. 'Chạy bộ'." },
                "durationMinutes": { "type": "integer", "minimum": 5, "maximum": 240 },
                "days": {
                  "type": "array",
                  "items": { "type": "string", "enum": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"] },
                  "description": "Weekdays it repeats on. All seven for every day."
                },
                "windows": {
                  "type": "array",
                  "items": {
                    "type": "object",
                    "properties": {
                      "start": { "type": "string", "description": "HH:mm, local" },
                      "end": { "type": "string", "description": "HH:mm, local" }
                    },
                    "required": ["start", "end"],
                    "additionalProperties": false
                  },
                  "description": "Times of day the user is willing to use, most preferred first. 1 to 3."
                },
                "startDate": { "type": "string", "description": "First day, yyyy-MM-dd. Default: tomorrow." },
                "habitId": { "type": "string", "description": "An existing habit to schedule, from get_habits. Omit to create a new habit named title." },
                "reminders": {
                  "type": "array",
                  "items": { "type": "integer", "enum": [0, 5, 15, 30, 60] },
                  "description": "Minutes before the start. Default [15]."
                }
              },
              "required": ["title", "durationMinutes", "days", "windows"],
              "additionalProperties": false
            }
            """;

        public async Task<ToolResult> ExecuteAsync(ToolContext context, JsonElement arguments, CancellationToken cancellationToken)
        {
            if (!TryRead(arguments, context, out var request, out var error)) return ToolResult.Error(error!);

            var habits = (await _sender.Send(new GetHabitsQuery { UserId = context.UserId }, cancellationToken)).ToList();
            Habit? habit = null;
            if (request.HabitId is { } habitId)
            {
                habit = habits.FirstOrDefault(h => h.Id == habitId);
                if (habit == null) return ToolResult.Error("There is no habit with that habitId. Use get_habits.");
            }

            var dates = SchedulePlanner.PlannedDates(request.FirstDate, request.Days);
            if (dates.Count == 0) return ToolResult.Error("None of those days falls in the next 14 days.");

            var from = SchedulePlanner.ToUtc(dates[0], TimeSpan.Zero, context.LocalOffset);
            var to = SchedulePlanner.ToUtc(dates[^1].AddDays(1), TimeSpan.Zero, context.LocalOffset);
            var events = await _sender.Send(
                new GetEventsQuery { UserId = context.UserId, StartTime = from, EndTime = to }, cancellationToken);
            var booked = RecurrenceExpander.Expand(events, from, to, context.LocalOffset)
                // A session already filed under the same habit is not a clash with itself.
                .Where(o => habit == null || o.Event.HabitId != habit.Id.ToString())
                .ToList();

            var options = SchedulePlanner.BestPerWindow(
                request.Windows, TimeSpan.FromMinutes(request.DurationMinutes), dates, booked, context.LocalOffset);

            var proposals = new List<object>();
            foreach (var option in options.Take(MaxProposals))
            {
                var payload = new ScheduleProposal(
                    Title: habit?.Name ?? request.Title,
                    DurationMinutes: request.DurationMinutes,
                    StartLocal: option.Start.ToString(@"hh\:mm", CultureInfo.InvariantCulture),
                    Days: request.Days.Order().ToList(),
                    FirstDate: dates[0].ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
                    RecurrenceRule: ScheduleProposal.RuleFor(request.Days),
                    Reminders: request.Reminders,
                    HabitId: habit?.Id,
                    HabitName: habit?.Name,
                    CategoryId: habit?.CategoryId,
                    Conflicts: option.Conflicts
                        .Select(c => new ScheduleConflict(c.Date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture), c.Title))
                        .ToList());

                var proposal = new AssistantProposal
                {
                    UserId = context.UserId,
                    ConversationId = context.ConversationId,
                    ToolCallId = context.ToolCallId,
                    PayloadJson = payload.ToJson(),
                    CreatedAt = context.NowUtc,
                };
                await _repository.AddProposalAsync(proposal);

                proposals.Add(new
                {
                    proposalId = proposal.Id,
                    title = payload.Title,
                    start = payload.StartLocal,
                    end = payload.EndLocal,
                    days = payload.Days.Select(d => DayNames[d - 1]),
                    firstDate = payload.FirstDate,
                    clashes = option.Conflicts.Count,
                    clashDates = option.Conflicts.Take(MaxConflictsListed)
                        .Select(c => new { date = c.Date.ToString("yyyy-MM-dd (ddd)", CultureInfo.InvariantCulture), with = c.Title }),
                });
            }

            if (proposals.Count == 0)
            {
                return ToolResult.Error($"No window can hold {request.DurationMinutes} minutes. Ask for a longer window.");
            }

            return ToolResult.Ok(new
            {
                proposals,
                checkedDays = dates.Count,
                similarHabits = habit != null
                    ? null
                    : habits.Where(h => Similar(h.Name, request.Title))
                        .Select(h => new { id = h.Id, name = h.Name, days = h.TargetDays.Order().Select(d => DayNames[d - 1]) })
                        .ToList(),
                note = "Nothing is added yet. The app shows each proposal as a card with an add button; tell the " +
                       "user to tap it, without quoting its label (the app's language may differ). Never say it has been added.",
            });
        }

        private sealed record Request(
            string Title, int DurationMinutes, IReadOnlyList<int> Days, IReadOnlyList<TimeWindow> Windows,
            DateOnly FirstDate, Guid? HabitId, IReadOnlyList<int> Reminders);

        private static bool TryRead(JsonElement a, ToolContext context, out Request request, out string? error)
        {
            request = null!;
            error = null;

            var title = a.TryGetProperty("title", out var t) && t.ValueKind == JsonValueKind.String ? t.GetString()!.Trim() : "";
            if (title.Length == 0 || title.Length > MaxTitleLength)
            {
                error = $"'title' is required, at most {MaxTitleLength} characters.";
                return false;
            }

            if (!a.TryGetProperty("durationMinutes", out var d) || d.ValueKind != JsonValueKind.Number
                || !d.TryGetInt32(out var duration) || duration < MinDurationMinutes || duration > MaxDurationMinutes)
            {
                error = $"'durationMinutes' is required, from {MinDurationMinutes} to {MaxDurationMinutes}.";
                return false;
            }

            var days = new List<int>();
            if (a.TryGetProperty("days", out var ds) && ds.ValueKind == JsonValueKind.Array)
            {
                foreach (var day in ds.EnumerateArray())
                {
                    var index = Array.IndexOf(DayNames, day.GetString());
                    if (index < 0)
                    {
                        error = "'days' holds weekday names: Mon, Tue, Wed, Thu, Fri, Sat, Sun.";
                        return false;
                    }
                    if (!days.Contains(index + 1)) days.Add(index + 1);
                }
            }
            if (days.Count == 0)
            {
                error = "'days' is required: the weekdays it repeats on.";
                return false;
            }

            var windows = new List<TimeWindow>();
            if (a.TryGetProperty("windows", out var ws) && ws.ValueKind == JsonValueKind.Array)
            {
                foreach (var w in ws.EnumerateArray())
                {
                    if (!TryTime(w, "start", out var start) || !TryTime(w, "end", out var end) || end <= start)
                    {
                        error = "Each window needs 'start' and 'end' as HH:mm, end after start.";
                        return false;
                    }
                    windows.Add(new TimeWindow(start, end));
                }
            }
            if (windows.Count == 0 || windows.Count > MaxWindows)
            {
                error = $"'windows' is required: 1 to {MaxWindows} times of day.";
                return false;
            }

            var today = DateOnly.FromDateTime(context.NowUtc + context.LocalOffset);
            var first = today.AddDays(1);
            if (a.TryGetProperty("startDate", out var sd) && sd.ValueKind == JsonValueKind.String)
            {
                if (!DateOnly.TryParseExact(sd.GetString(), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out first)
                    || first < today)
                {
                    error = "'startDate' is yyyy-MM-dd, today or later.";
                    return false;
                }
            }

            Guid? habitId = null;
            if (a.TryGetProperty("habitId", out var h) && h.ValueKind == JsonValueKind.String)
            {
                if (!Guid.TryParse(h.GetString(), out var parsed))
                {
                    error = "'habitId' is not an id. Use get_habits.";
                    return false;
                }
                habitId = parsed;
            }

            var reminders = DefaultReminders;
            if (a.TryGetProperty("reminders", out var r) && r.ValueKind == JsonValueKind.Array)
            {
                var values = r.EnumerateArray().Where(v => v.ValueKind == JsonValueKind.Number).Select(v => v.GetInt32()).ToList();
                if (values.Any(v => !ReminderOptions.AllowedMinutesBefore.Contains(v)))
                {
                    error = "'reminders' may only hold 0, 5, 15, 30 or 60.";
                    return false;
                }
                reminders = ReminderOptions.Normalise(values);
            }

            request = new Request(title, duration, days, windows, first, habitId, reminders);
            return true;
        }

        private static bool TryTime(JsonElement w, string name, out TimeSpan time)
        {
            time = default;
            return w.TryGetProperty(name, out var v) && v.ValueKind == JsonValueKind.String
                && TimeSpan.TryParseExact(v.GetString(), @"hh\:mm", CultureInfo.InvariantCulture, out time)
                && time < TimeSpan.FromDays(1);
        }

        /// <summary>"Chạy bộ" and "Chạy bộ buổi sáng" are the same habit as far as asking goes.</summary>
        private static bool Similar(string habitName, string title)
        {
            var a = habitName.Trim().ToLowerInvariant();
            var b = title.Trim().ToLowerInvariant();
            return a.Contains(b) || b.Contains(a);
        }
    }
}
