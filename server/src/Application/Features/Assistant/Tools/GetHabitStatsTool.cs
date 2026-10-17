using System.Text.Json;
using HabitTracker.Application.Common;
using HabitTracker.Application.Features.Assistant.Harness;
using HabitTracker.Application.Features.Events.Queries;
using HabitTracker.Application.Features.Habits.Queries;
using MediatR;

namespace HabitTracker.Application.Features.Assistant.Tools
{
    /// <summary>
    /// How often each habit was kept over the last N days — planned, done, missed and the rate,
    /// overall and by weekday and start hour — counted on the server so the model never has to
    /// count sessions out of <c>get_events</c>, which it gets wrong.
    /// </summary>
    public class GetHabitStatsTool : IAssistantTool
    {
        public const int DefaultDays = 28;
        public const int MinDays = 1;
        public const int MaxDays = 90;

        /// <summary>How many of the latest missed dates a habit lists.</summary>
        public const int MaxMissedDates = 14;

        private static readonly string[] DayNames = { "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" };

        private readonly ISender _sender;

        public GetHabitStatsTool(ISender sender)
        {
            _sender = sender;
        }

        public string Name => "get_habit_stats";

        public string Description =>
            "How often each habit was kept over the last N days (1-90, default 28, counted from local midnight " +
            "N-1 days ago up to now): planned sessions, done, missed, ratePercent, lastDone, the latest missed dates, " +
            "and the same counts split by weekday and by the hour a session starts in (\"06:00-07:00\" holds a 06:50 " +
            "session; it is a range, not a start time). Days of repeating events are included, deleted days are not; a session " +
            "counts once it is over or done. Use it for any question about how often, which days or what time of " +
            "day the user keeps or skips a habit. Quote these numbers exactly; never count sessions from get_events.";

        public string ParametersSchemaJson => """
            {
              "type": "object",
              "properties": {
                "days": { "type": "integer", "minimum": 1, "maximum": 90, "description": "How many days back, today included. Default 28." },
                "habitId": { "type": "string", "description": "Only this habit, from get_habits. Omit for every habit." }
              },
              "additionalProperties": false
            }
            """;

        public async Task<ToolResult> ExecuteAsync(ToolContext context, JsonElement arguments, CancellationToken cancellationToken)
        {
            if (!ToolJson.TryGetInt(arguments, "days", MinDays, MaxDays, DefaultDays, out var days, out var error))
            {
                return ToolResult.Error(error!);
            }

            Guid? habitId = null;
            if (arguments.TryGetProperty("habitId", out var idValue) && idValue.ValueKind != JsonValueKind.Null)
            {
                if (idValue.ValueKind != JsonValueKind.String || !Guid.TryParse(idValue.GetString(), out var parsed))
                {
                    return ToolResult.Error("'habitId' is not an id. Use get_habits.");
                }
                habitId = parsed;
            }

            var habits = (await _sender.Send(new GetHabitsQuery { UserId = context.UserId }, cancellationToken)).ToList();
            if (habitId is { } id)
            {
                habits = habits.Where(h => h.Id == id).ToList();
                if (habits.Count == 0) return ToolResult.Error("There is no habit with that habitId. Use get_habits.");
            }

            var from = WindowStart(context.NowUtc, context.LocalOffset, days);
            var events = await _sender.Send(
                new GetEventsQuery { UserId = context.UserId, StartTime = from, EndTime = HabitAdherence.EndOfLocalDay(context.NowUtc, context.LocalOffset) }, cancellationToken);

            var results = HabitAdherence.Compute(habits, events, from, context.NowUtc, context.LocalOffset);
            var total = new AdherenceCount(results.Sum(r => r.Total.Planned), results.Sum(r => r.Total.Done));

            return ToolResult.Ok(new
            {
                from = ToolJson.Local(from, context.LocalOffset),
                to = ToolJson.Local(context.NowUtc, context.LocalOffset),
                days,
                total = Counts(total),
                habits = results.Select(r => new
                {
                    id = r.Habit.Id,
                    name = r.Habit.Name,
                    planned = r.Total.Planned,
                    done = r.Total.Done,
                    missed = r.Total.Missed,
                    ratePercent = r.Total.RatePercent,
                    lastDone = r.LastDone?.ToString("yyyy-MM-dd"),
                    recentMissed = r.MissedDates.TakeLast(MaxMissedDates).Select(d => d.ToString("yyyy-MM-dd")),
                    byWeekday = r.ByWeekday.OrderBy(d => d.Key).Select(d => new
                    {
                        day = DayNames[d.Key - 1],
                        planned = d.Value.Planned,
                        done = d.Value.Done,
                        ratePercent = d.Value.RatePercent,
                    }),
                    byHour = r.ByHour.OrderBy(h => h.Key).Select(h => new
                    {
                        hour = $"{h.Key:00}:00-{(h.Key + 1) % 24:00}:00",
                        planned = h.Value.Planned,
                        done = h.Value.Done,
                        ratePercent = h.Value.RatePercent,
                    }),
                }),
            });
        }

        /// <summary>Local midnight <paramref name="days"/> − 1 days before today, in UTC.</summary>
        public static DateTime WindowStart(DateTime nowUtc, TimeSpan offset, int days)
        {
            var today = DateOnly.FromDateTime(RecurrenceExceptions.ToUtc(nowUtc) + offset);
            var start = today.AddDays(-(days - 1)).ToDateTime(TimeOnly.MinValue) - offset;
            return DateTime.SpecifyKind(start, DateTimeKind.Utc);
        }

        private static object Counts(AdherenceCount count) => new
        {
            planned = count.Planned,
            done = count.Done,
            missed = count.Missed,
            ratePercent = count.RatePercent,
        };
    }
}
