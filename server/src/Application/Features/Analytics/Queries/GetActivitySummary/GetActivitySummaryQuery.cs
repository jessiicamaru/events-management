using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Application.Common;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Analytics.Queries.GetActivitySummary
{
    public class DailyActivityDto
    {
        public DateTime Date { get; set; }
        public int Scheduled { get; set; }
        public int Completed { get; set; }
        public int FocusMinutes { get; set; }
    }

    public class ActivitySummaryDto
    {
        /// <summary>
        /// One entry per day in the requested window, oldest first, including days with
        /// no activity. A chart needs the empty days: a gap in a bar chart is what
        /// "nothing happened" looks like, and silently dropping those days would
        /// compress the axis and misrepresent the shape.
        /// </summary>
        public List<DailyActivityDto> Days { get; set; } = new();

        public int TotalScheduled { get; set; }
        public int TotalCompleted { get; set; }
        public int TotalFocusMinutes { get; set; }

        /// <summary>The best single day of focus time in the window, in minutes.</summary>
        public int BestFocusMinutes { get; set; }
    }

    /// <param name="Days">
    /// How many days of history to return, counting back from today inclusive.
    /// Clamped by the handler.
    /// </param>
    public record GetActivitySummaryQuery(string UserId, int Days) : IRequest<ActivitySummaryDto>;

    public class GetActivitySummaryQueryHandler
        : IRequestHandler<GetActivitySummaryQuery, ActivitySummaryDto>
    {
        /// <summary>
        /// Bounds on the requested window. The lower bound keeps a malformed request from
        /// producing an empty chart; the upper bound keeps one client from asking for a
        /// decade of rows.
        /// </summary>
        public const int MinDays = 1;
        public const int MaxDays = 90;

        private readonly IEventRepository _eventRepository;

        public GetActivitySummaryQueryHandler(IEventRepository eventRepository)
        {
            _eventRepository = eventRepository;
        }

        public async Task<ActivitySummaryDto> Handle(
            GetActivitySummaryQuery request,
            CancellationToken cancellationToken)
        {
            if (string.IsNullOrEmpty(request.UserId))
            {
                throw new ArgumentException("UserId is required.", nameof(request));
            }

            var days = Math.Clamp(request.Days, MinDays, MaxDays);

            // The window is expressed in the user's day, then converted back to UTC for
            // the query, because that is how the rows are stored. Doing it the other way
            // round would cut the first and last day at the wrong hour.
            var offset = StreakCalculator.DefaultDayBoundaryOffset;
            var today = StreakCalculator.ToLocalDate(DateTime.UtcNow, offset);
            var firstDay = today.AddDays(-(days - 1));

            var fromUtc = firstDay - offset;
            var toUtc = today.AddDays(1) - offset;

            var rows = await _eventRepository.GetDailyActivityAsync(request.UserId, fromUtc, toUtc);
            var byDate = rows.ToDictionary(r => r.Date.Date);

            var result = new ActivitySummaryDto();

            for (var day = firstDay; day <= today; day = day.AddDays(1))
            {
                byDate.TryGetValue(day.Date, out var row);

                result.Days.Add(new DailyActivityDto
                {
                    Date = day,
                    Scheduled = row?.Scheduled ?? 0,
                    Completed = row?.Completed ?? 0,
                    FocusMinutes = row?.FocusMinutes ?? 0
                });
            }

            result.TotalScheduled = result.Days.Sum(d => d.Scheduled);
            result.TotalCompleted = result.Days.Sum(d => d.Completed);
            result.TotalFocusMinutes = result.Days.Sum(d => d.FocusMinutes);
            result.BestFocusMinutes = result.Days.Count == 0
                ? 0
                : result.Days.Max(d => d.FocusMinutes);

            return result;
        }
    }
}
