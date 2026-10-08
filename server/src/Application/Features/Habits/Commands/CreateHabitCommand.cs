using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Application.Common;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Habits.Commands
{
    /// <remarks>
    /// Returns null when <c>CategoryId</c> names a category the caller may not use — see
    /// <see cref="EventCategoryAccess.CanAssignAsync"/>.
    /// </remarks>
    public class CreateHabitCommand : IRequest<Guid?>
    {
        public string Name { get; set; } = string.Empty;
        public List<int> TargetDays { get; set; } = new();
        public Guid? CategoryId { get; set; }
        public string UserId { get; set; } = string.Empty;
    }

    public class CreateHabitCommandHandler : IRequestHandler<CreateHabitCommand, Guid?>
    {
        private readonly IHabitRepository _repository;
        private readonly IEventCategoryRepository _categoryRepository;
        private readonly ISquadRepository _squadRepository;

        public CreateHabitCommandHandler(
            IHabitRepository repository,
            IEventCategoryRepository categoryRepository,
            ISquadRepository squadRepository)
        {
            _repository = repository;
            _categoryRepository = categoryRepository;
            _squadRepository = squadRepository;
        }

        public async Task<Guid?> Handle(CreateHabitCommand request, CancellationToken cancellationToken)
        {
            if (!await EventCategoryAccess.CanAssignAsync(
                    request.CategoryId, currentCategoryId: null, request.UserId,
                    _categoryRepository, _squadRepository))
            {
                return null;
            }

            var habit = new Habit
            {
                Name = request.Name,
                TargetDays = request.TargetDays,
                CategoryId = request.CategoryId,
                UserId = request.UserId
            };

            await _repository.AddAsync(habit);
            return habit.Id;
        }
    }
}
