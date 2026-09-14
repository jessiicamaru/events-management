using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Events.Queries
{
    public class GetEventsQuery : IRequest<IEnumerable<Event>>
    {
        public string UserId { get; set; } = string.Empty;
    }

    public class GetEventsQueryHandler : IRequestHandler<GetEventsQuery, IEnumerable<Event>>
    {
        private readonly IEventRepository _repository;

        public GetEventsQueryHandler(IEventRepository repository)
        {
            _repository = repository;
        }

        public async Task<IEnumerable<Event>> Handle(GetEventsQuery request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrEmpty(request.UserId))
            {
                return await _repository.GetAllAsync();
            }
            return await _repository.GetEventsForUserAsync(request.UserId);
        }
    }
}
