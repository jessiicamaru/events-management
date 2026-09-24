using System;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.EventCategories.Commands
{
    public class UpdateEventCategoryCommand : IRequest<bool>
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string ColorPreset { get; set; } = string.Empty;
        public string? UserId { get; set; }
        public Guid? SquadId { get; set; }
    }

    public class UpdateEventCategoryCommandHandler : IRequestHandler<UpdateEventCategoryCommand, bool>
    {
        private readonly IEventCategoryRepository _repository;

        public UpdateEventCategoryCommandHandler(IEventCategoryRepository repository)
        {
            _repository = repository;
        }

        public async Task<bool> Handle(UpdateEventCategoryCommand request, CancellationToken cancellationToken)
        {
            var category = await _repository.GetByIdAsync(request.Id);
            if (category == null) return false;

            if (category.UserId != request.UserId && category.SquadId != request.SquadId)
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
