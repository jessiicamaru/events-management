using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.EventTasks.Queries
{
    public class GetEventTasksQuery : IRequest<IEnumerable<EventTask>>
    {
        public Guid EventId { get; set; }
        public string UserId { get; set; } = string.Empty;
    }

    public class GetEventTasksQueryHandler : IRequestHandler<GetEventTasksQuery, IEnumerable<EventTask>>
    {
        private readonly IEventRepository _eventRepository;
        private readonly IEventTaskRepository _eventTaskRepository;

        public GetEventTasksQueryHandler(IEventRepository eventRepository, IEventTaskRepository eventTaskRepository)
        {
            _eventRepository = eventRepository;
            _eventTaskRepository = eventTaskRepository;
        }

        public async Task<IEnumerable<EventTask>> Handle(GetEventTasksQuery request, CancellationToken cancellationToken)
        {
            var evt = await _eventRepository.GetByIdAsync(request.EventId);
            if (evt == null || evt.UserId != request.UserId) return new List<EventTask>();

            return await _eventTaskRepository.GetByEventIdAsync(request.EventId);
        }
    }
}
