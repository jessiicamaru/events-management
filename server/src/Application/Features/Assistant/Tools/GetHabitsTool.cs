using System.Text.Json;
using HabitTracker.Application.Features.Assistant.Harness;
using HabitTracker.Application.Features.Habits.Queries;
using MediatR;

namespace HabitTracker.Application.Features.Assistant.Tools
{
    /// <summary>The user's habits, with the days they aim for and their streaks.</summary>
    public class GetHabitsTool : IAssistantTool
    {
        private static readonly string[] DayNames = { "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" };

        private readonly ISender _sender;

        public GetHabitsTool(ISender sender)
        {
            _sender = sender;
        }

        public string Name => "get_habits";

        public string Description =>
            "List the user's habits: id, name, category, the weekdays they aim to do it (targetDays), " +
            "current and longest streak in days, and the habit's task checklist.";

        public string ParametersSchemaJson => """
            { "type": "object", "properties": {}, "additionalProperties": false }
            """;

        public async Task<ToolResult> ExecuteAsync(ToolContext context, JsonElement arguments, CancellationToken cancellationToken)
        {
            var habits = await _sender.Send(new GetHabitsQuery { UserId = context.UserId }, cancellationToken);

            return ToolResult.Ok(new
            {
                habits = habits.Select(h => new
                {
                    id = h.Id,
                    name = h.Name,
                    category = h.Category?.Name,
                    // Stored 1 = Monday … 7 = Sunday.
                    targetDays = h.TargetDays.Where(d => d is >= 1 and <= 7).Order().Select(d => DayNames[d - 1]),
                    currentStreak = h.CurrentStreak,
                    longestStreak = h.LongestStreak,
                    tasks = h.Tasks.Count == 0 ? null : h.Tasks.OrderBy(t => t.Order).Select(t => new
                    {
                        title = t.Title,
                        estimatedMinutes = t.EstimatedMinutes,
                    }),
                }),
            });
        }
    }
}
