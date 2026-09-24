using System;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.EventCategories.Commands
{
    public class DeleteEventCategoryCommand : IRequest<bool>
    {
        public Guid Id { get; set; }
        public string? UserId { get; set; }
        public Guid? SquadId { get; set; }
        public Guid? ReplacementCategoryId { get; set; }
    }

    public class DeleteEventCategoryCommandHandler : IRequestHandler<DeleteEventCategoryCommand, bool>
    {
        private readonly IEventCategoryRepository _repository;

        public DeleteEventCategoryCommandHandler(IEventCategoryRepository repository)
        {
            _repository = repository;
        }

        public async Task<bool> Handle(DeleteEventCategoryCommand request, CancellationToken cancellationToken)
        {
            var category = await _repository.GetByIdAsync(request.Id);
            if (category == null) return false;

            // Basic authorization check
            if (category.UserId != request.UserId && category.SquadId != request.SquadId)
            {
                return false;
            }

            if (request.ReplacementCategoryId.HasValue)
            {
                var replacementCategory = await _repository.GetByIdAsync(request.ReplacementCategoryId.Value);
                if (replacementCategory != null && 
                    (replacementCategory.UserId == request.UserId || replacementCategory.SquadId == request.SquadId))
                {
                    await _repository.ReassignCategoryAsync(request.Id, request.ReplacementCategoryId.Value);
                }
            }

            await _repository.DeleteAsync(request.Id);
            return true;
        }
    }
}
