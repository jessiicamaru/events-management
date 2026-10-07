using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Application.Common;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Analytics.Queries.GetPlanVsActual
{
    public class PlanVsActualItemDto
    {
        public string Id { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;

        /// <summary>How many finished sessions these numbers come from.</summary>
        public int Sessions { get; set; }

        public int PlannedMinutes { get; set; }
        public int ActualMinutes { get; set; }
    }

    public class PlanVsActualDto
    {
        /// <summary>Busiest habit first, by recorded time.</summary>
        public List<PlanVsActualItemDto> ByHabit { get; set; } = new();

        /// <summary>The same sessions, grouped by category. Uncategorised events are absent.</summary>
        public List<PlanVsActualItemDto> ByCategory { get; set; } = new();

        /// <summary>
        /// Totals over the habit grouping, not the category one: an event has at most one
        /// habit, so that grouping counts every session exactly once.
        /// </summary>
        public int TotalPlannedMinutes { get; set; }
        public int TotalActualMinutes { get; set; }
        public int TotalSessions { get; set; }
    }

    /// <param name="Days">
    /// How many days of history to include, counting back from today inclusive. Clamped by
    /// the handler, with the same bounds as the activity summary.
    /// </param>
    public record GetPlanVsActualQuery(string UserId, int Days) : IRequest<PlanVsActualDto>;

    /// <summary>
    /// Booked time against recorded time — `TargetDuration` against `ActualDuration` — per
    /// habit and per category.
    /// </summary>
    /// <remarks>
    /// Both fields have been written on every focus session for as long as the feature has
    /// existed and have never been shown together. Only sessions that were finished take
    /// part, so the answer is "when you do this, it takes longer than you think", not "you
    /// skip things" — the activity card already covers the second.
    /// </remarks>
    public class GetPlanVsActualQueryHandler
        : IRequestHandler<GetPlanVsActualQuery, PlanVsActualDto>
    {
        /// <summary>
        /// Same bounds as <c>GetActivitySummaryQueryHandler</c>: one window definition for
        /// the dashboard, so two cards on the same screen cannot disagree about "last 14 days".
        /// </summary>
        public const int MinDays = GetActivitySummary.GetActivitySummaryQueryHandler.MinDays;
        public const int MaxDays = GetActivitySummary.GetActivitySummaryQueryHandler.MaxDays;

        private readonly IEventRepository _eventRepository;

        public GetPlanVsActualQueryHandler(IEventRepository eventRepository)
        {
            _eventRepository = eventRepository;
        }

        public async Task<PlanVsActualDto> Handle(
            GetPlanVsActualQuery request,
            CancellationToken cancellationToken)
        {
            if (string.IsNullOrEmpty(request.UserId))
            {
                throw new ArgumentException("UserId is required.", nameof(request));
            }

            var days = Math.Clamp(request.Days, MinDays, MaxDays);

            // The window is the user's day converted back to UTC, the same way the activity
            // summary does it, so both cards cover exactly the same hours.
            var offset = StreakCalculator.DefaultDayBoundaryOffset;
            var today = StreakCalculator.ToLocalDate(DateTime.UtcNow, offset);
            var fromUtc = today.AddDays(-(days - 1)) - offset;
            var toUtc = today.AddDays(1) - offset;

            var byHabit = await _eventRepository.GetPlanVsActualByHabitAsync(request.UserId, fromUtc, toUtc);
            var byCategory = await _eventRepository.GetPlanVsActualByCategoryAsync(request.UserId, fromUtc, toUtc);

            var result = new PlanVsActualDto
            {
                ByHabit = byHabit.Select(ToDto).ToList(),
                ByCategory = byCategory.Select(ToDto).ToList()
            };

            result.TotalSessions = result.ByHabit.Sum(i => i.Sessions);
            result.TotalPlannedMinutes = result.ByHabit.Sum(i => i.PlannedMinutes);
            result.TotalActualMinutes = result.ByHabit.Sum(i => i.ActualMinutes);

            return result;
        }

        private static PlanVsActualItemDto ToDto(PlanVsActual row) => new()
        {
            Id = row.GroupId,
            Name = row.GroupName,
            Sessions = row.Sessions,
            PlannedMinutes = row.PlannedMinutes,
            ActualMinutes = row.ActualMinutes
        };
    }
}
