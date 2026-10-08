using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Application.Common;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.EventCategories.Queries
{
    /// <summary>
    /// The caller's own categories, or one squad's shared ones.
    /// </summary>
    /// <remarks>
    /// Returns null when the caller is not an approved member of the squad they asked about,
    /// which the endpoint turns into 403. Null rather than an empty list: "you may not see
    /// this" and "there is nothing here" are different answers, and the client renders the
    /// second as an empty state.
    /// </remarks>
    public class GetEventCategoriesQuery : IRequest<IEnumerable<EventCategory>?>
    {
        public string? UserId { get; set; }
        public Guid? SquadId { get; set; }
    }

    public class GetEventCategoriesQueryHandler
        : IRequestHandler<GetEventCategoriesQuery, IEnumerable<EventCategory>?>
    {
        private readonly IEventCategoryRepository _repository;
        private readonly ISquadRepository _squadRepository;

        public GetEventCategoriesQueryHandler(
            IEventCategoryRepository repository,
            ISquadRepository squadRepository)
        {
            _repository = repository;
            _squadRepository = squadRepository;
        }

        public async Task<IEnumerable<EventCategory>?> Handle(
            GetEventCategoriesQuery request,
            CancellationToken cancellationToken)
        {
            if (string.IsNullOrEmpty(request.UserId)) return null;

            if (request.SquadId.HasValue)
            {
                // Before this check the squad id came straight off the query string and was
                // used unvalidated, so any signed-in caller could read any squad's categories.
                var membership = await _squadRepository.GetMembershipAsync(
                    request.SquadId.Value, request.UserId);

                if (!SquadAccess.CanRead(membership)) return null;

                return await _repository.GetBySquadIdAsync(request.SquadId.Value);
            }

            return await _repository.GetByUserIdAsync(request.UserId);
        }
    }
}
