using System;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Application.Common;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.EventCategories.Commands
{
    /// <summary>
    /// Creates a personal category, or a shared one for a squad the caller belongs to.
    /// </summary>
    /// <remarks>
    /// Returns null when the caller is not an approved member of <see cref="SquadId"/>. The
    /// endpoint used to carry a comment saying "ideally check if user is admin of squad. For
    /// now, let anyone add to squad" — measured against a running server: any signed-in caller
    /// could plant a category in any squad.
    /// </remarks>
    public class CreateEventCategoryCommand : IRequest<Guid?>
    {
        public string Name { get; set; } = string.Empty;
        public string ColorPreset { get; set; } = "Slate";

        /// <summary>Owner of a personal category; null for a squad one.</summary>
        public string? UserId { get; set; }

        public Guid? SquadId { get; set; }

        /// <summary>
        /// Who is asking, always — stamped by the endpoint from the token. Needed separately
        /// from <see cref="UserId"/>, which is null for a squad category and so cannot be what
        /// a membership check reads.
        /// </summary>
        public string? CallerUserId { get; set; }
    }

    public class CreateEventCategoryCommandHandler
        : IRequestHandler<CreateEventCategoryCommand, Guid?>
    {
        private readonly IEventCategoryRepository _repository;
        private readonly ISquadRepository _squadRepository;

        public CreateEventCategoryCommandHandler(
            IEventCategoryRepository repository,
            ISquadRepository squadRepository)
        {
            _repository = repository;
            _squadRepository = squadRepository;
        }

        public async Task<Guid?> Handle(
            CreateEventCategoryCommand request,
            CancellationToken cancellationToken)
        {
            if (string.IsNullOrEmpty(request.CallerUserId)) return null;

            if (request.SquadId.HasValue)
            {
                var membership = await _squadRepository.GetMembershipAsync(
                    request.SquadId.Value, request.CallerUserId);

                if (!SquadAccess.CanContribute(membership)) return null;
            }
            else if (request.UserId != request.CallerUserId)
            {
                // A personal category belongs to whoever asked for it, never to an id the
                // request supplied.
                return null;
            }

            var category = new EventCategory
            {
                Name = request.Name,
                ColorPreset = request.ColorPreset,
                UserId = request.UserId,
                SquadId = request.SquadId
            };

            await _repository.AddAsync(category);

            return category.Id;
        }
    }
}
