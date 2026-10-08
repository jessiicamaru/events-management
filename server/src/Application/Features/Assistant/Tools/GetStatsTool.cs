using System.Text.Json;
using HabitTracker.Application.Features.Analytics.Queries.GetActivitySummary;
using HabitTracker.Application.Features.Analytics.Queries.GetPlanVsActual;
using HabitTracker.Application.Features.Assistant.Harness;
using MediatR;

namespace HabitTracker.Application.Features.Assistant.Tools
{
    /// <summary>
    /// The figures the Home screen shows, for a number of days: focus time, and booked against
    /// recorded time per habit and category.
    /// </summary>
    public class GetStatsTool : IAssistantTool
    {
        public const int DefaultDays = 7;

        private readonly ISender _sender;

        public GetStatsTool(ISender sender)
        {
            _sender = sender;
        }

        public string Name => "get_stats";

        public string Description =>
            "Statistics for the last N days (1-90, default 7): focus minutes per day and in total, the " +
            "best day, and for finished sessions the planned against actual minutes per habit and per " +
            "category. Counts of scheduled/completed cover one-off events only; days of repeating events " +
            "are not in them. Quote these numbers exactly; never estimate.";

        public string ParametersSchemaJson => """
            {
              "type": "object",
              "properties": {
                "days": { "type": "integer", "minimum": 1, "maximum": 90, "description": "How many days back from today, default 7." }
              },
              "additionalProperties": false
            }
            """;

        public async Task<ToolResult> ExecuteAsync(ToolContext context, JsonElement arguments, CancellationToken cancellationToken)
        {
            if (!ToolJson.TryGetInt(arguments, "days",
                    GetActivitySummaryQueryHandler.MinDays, GetActivitySummaryQueryHandler.MaxDays,
                    DefaultDays, out var days, out var error))
            {
                return ToolResult.Error(error!);
            }

            var summary = await _sender.Send(new GetActivitySummaryQuery(context.UserId, days), cancellationToken);
            var planVsActual = await _sender.Send(new GetPlanVsActualQuery(context.UserId, days), cancellationToken);

            return ToolResult.Ok(new
            {
                days,
                focusMinutesTotal = summary.TotalFocusMinutes,
                bestDayFocusMinutes = summary.BestFocusMinutes,
                oneOffScheduled = summary.TotalOneOffScheduled,
                oneOffCompleted = summary.TotalOneOffCompleted,
                focusMinutesByDay = summary.Days
                    .Where(d => d.FocusMinutes > 0)
                    .Select(d => new { date = d.Date.ToString("yyyy-MM-dd"), minutes = d.FocusMinutes }),
                finishedSessions = new
                {
                    count = planVsActual.TotalSessions,
                    plannedMinutes = planVsActual.TotalPlannedMinutes,
                    actualMinutes = planVsActual.TotalActualMinutes,
                    byHabit = planVsActual.ByHabit.Select(Item),
                    byCategory = planVsActual.ByCategory.Select(Item),
                },
            });
        }

        private static object Item(PlanVsActualItemDto item) => new
        {
            name = item.Name,
            sessions = item.Sessions,
            plannedMinutes = item.PlannedMinutes,
            actualMinutes = item.ActualMinutes,
        };
    }
}
