using System;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.EventCategories.Commands
{
    public class CreateEventCategoryCommand : IRequest<Guid>
    {
        public string Name { get; set; } = string.Empty;
        public string ColorPreset { get; set; } = "Slate";
        public string? UserId { get; set; }
        public Guid? SquadId { get; set; }
    }

    public class CreateEventCategoryCommandHandler : IRequestHandler<CreateEventCategoryCommand, Guid>
    {
        private readonly IEventCategoryRepository _repository;

        public CreateEventCategoryCommandHandler(IEventCategoryRepository repository)
        {
            _repository = repository;
        }

        public async Task<Guid> Handle(CreateEventCategoryCommand request, CancellationToken cancellationToken)
        {
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
