using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Analytics.Queries.GetHeatmap
{
    public class HeatmapItemDto
    {
        public DateTime Date { get; set; }
        public int Count { get; set; }
    }

    public record GetHeatmapQuery() : IRequest<List<HeatmapItemDto>>;

    public class GetHeatmapQueryHandler : IRequestHandler<GetHeatmapQuery, List<HeatmapItemDto>>
    {
        private readonly IEventRepository _eventRepository;

        public GetHeatmapQueryHandler(IEventRepository eventRepository)
        {
            _eventRepository = eventRepository;
        }

        public async Task<List<HeatmapItemDto>> Handle(GetHeatmapQuery request, CancellationToken cancellationToken)
        {
            var allEvents = await _eventRepository.GetAllAsync();
            
            var completedEvents = allEvents.Where(e => e.IsCompleted);

            var heatmap = completedEvents
                .GroupBy(e => e.StartTime.Date)
                .Select(g => new HeatmapItemDto
                {
                    Date = g.Key,
                    Count = g.Count()
                })
                .OrderBy(x => x.Date)
                .ToList();

            return heatmap;
        }
    }
}
