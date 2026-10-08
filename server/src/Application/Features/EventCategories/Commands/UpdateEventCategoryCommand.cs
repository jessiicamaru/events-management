using System;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Application.Common;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.EventCategories.Commands
{
    /// <summary>Renames or recolours a category the caller is entitled to change.</summary>
    /// <remarks>
    /// The caller's rights are decided from the stored row, never from the request. The old
    /// check was
    /// <c>category.UserId != request.UserId &amp;&amp; category.SquadId != request.SquadId</c>,
    /// which is false whenever both squad ids are null — so any signed-in caller could rename
    /// another user's personal category, measured against a running server. A squad id in the
    /// body is ignored now; it told the server nothing it should trust.
    /// </remarks>
    public class UpdateEventCategoryCommand : IRequest<bool>
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string ColorPreset { get; set; } = string.Empty;

        /// <summary>Who is asking, from the token.</summary>
        public string? UserId { get; set; }
    }

    public class UpdateEventCategoryCommandHandler
        : IRequestHandler<UpdateEventCategoryCommand, bool>
    {
        private readonly IEventCategoryRepository _repository;
        private readonly ISquadRepository _squadRepository;

        public UpdateEventCategoryCommandHandler(
            IEventCategoryRepository repository,
            ISquadRepository squadRepository)
        {
            _repository = repository;
            _squadRepository = squadRepository;
        }

        public async Task<bool> Handle(
            UpdateEventCategoryCommand request,
            CancellationToken cancellationToken)
        {
            var category = await _repository.GetByIdAsync(request.Id);
            if (category == null) return false;

            if (!await EventCategoryAccess.CanManageAsync(
                    category, request.UserId, _squadRepository))
            {
                return false;
            }

            category.Name = request.Name;
            category.ColorPreset = request.ColorPreset;

            await _repository.UpdateAsync(category);
            return true;
        }
    }
}
