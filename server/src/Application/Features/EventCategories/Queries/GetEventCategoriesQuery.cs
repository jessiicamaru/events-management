using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.EventCategories.Queries
{
    public class GetEventCategoriesQuery : IRequest<IEnumerable<EventCategory>>
    {
        public string? UserId { get; set; }
        public Guid? SquadId { get; set; }
    }

    public class GetEventCategoriesQueryHandler : IRequestHandler<GetEventCategoriesQuery, IEnumerable<EventCategory>>
    {
        private readonly IEventCategoryRepository _repository;

        public GetEventCategoriesQueryHandler(IEventCategoryRepository repository)
        {
            _repository = repository;
        }

        public async Task<IEnumerable<EventCategory>> Handle(GetEventCategoriesQuery request, CancellationToken cancellationToken)
        {
            if (request.SquadId.HasValue)
            {
                return await _repository.GetBySquadIdAsync(request.SquadId.Value);
            }
            
            if (!string.IsNullOrEmpty(request.UserId))
            {
                return await _repository.GetByUserIdAsync(request.UserId);
            }

            return new List<EventCategory>();
        }
    }
}
