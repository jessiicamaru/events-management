using System;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Application.Common;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.EventCategories.Commands
{
    /// <summary>
    /// Deletes a category the caller is entitled to delete, optionally moving its events to
    /// another one first.
    /// </summary>
    /// <remarks>
    /// Same correction as <see cref="UpdateEventCategoryCommand"/>: rights come from the stored
    /// row. The replacement is checked the same way — before, a replacement the caller owned was
    /// accepted for somebody else's category, which moved the victim's events onto the caller's
    /// category.
    /// </remarks>
    public class DeleteEventCategoryCommand : IRequest<bool>
    {
        public Guid Id { get; set; }

        /// <summary>Who is asking, from the token.</summary>
        public string? UserId { get; set; }

        public Guid? ReplacementCategoryId { get; set; }
    }

    public class DeleteEventCategoryCommandHandler
        : IRequestHandler<DeleteEventCategoryCommand, bool>
    {
        private readonly IEventCategoryRepository _repository;
        private readonly ISquadRepository _squadRepository;

        public DeleteEventCategoryCommandHandler(
            IEventCategoryRepository repository,
            ISquadRepository squadRepository)
        {
            _repository = repository;
            _squadRepository = squadRepository;
        }

        public async Task<bool> Handle(
            DeleteEventCategoryCommand request,
            CancellationToken cancellationToken)
        {
            var category = await _repository.GetByIdAsync(request.Id);
            if (category == null) return false;

            if (!await EventCategoryAccess.CanManageAsync(
                    category, request.UserId, _squadRepository))
            {
                return false;
            }

            if (request.ReplacementCategoryId.HasValue)
            {
                var replacement = await _repository.GetByIdAsync(request.ReplacementCategoryId.Value);

                // The events being moved are the deleted category's, so the replacement has to
                // be one the caller may use — and refusing it outright beats silently deleting
                // without reassigning, which is what returning early used to do.
                if (replacement == null ||
                    !await EventCategoryAccess.CanReadAsync(replacement, request.UserId, _squadRepository))
                {
                    return false;
                }

                await _repository.ReassignCategoryAsync(request.Id, replacement.Id);
            }

            await _repository.DeleteAsync(request.Id);
            return true;
        }
    }
}
