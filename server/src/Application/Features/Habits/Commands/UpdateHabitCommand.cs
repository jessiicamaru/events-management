using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Application.Common;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Habits.Commands
{
    public class UpdateHabitCommand : IRequest<bool>
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public List<int> TargetDays { get; set; } = new();
        public string UserId { get; set; } = string.Empty;
        public Guid? CategoryId { get; set; }
    }

    public class UpdateHabitCommandHandler : IRequestHandler<UpdateHabitCommand, bool>
    {
        private readonly IHabitRepository _repository;
        private readonly IEventCategoryRepository _categoryRepository;
        private readonly ISquadRepository _squadRepository;

        public UpdateHabitCommandHandler(
            IHabitRepository repository,
            IEventCategoryRepository categoryRepository,
            ISquadRepository squadRepository)
        {
            _repository = repository;
            _categoryRepository = categoryRepository;
            _squadRepository = squadRepository;
        }

        public async Task<bool> Handle(UpdateHabitCommand request, CancellationToken cancellationToken)
        {
            var habit = await _repository.GetByIdAsync(request.Id);
            if (habit == null || habit.UserId != request.UserId)
            {
                return false;
            }

            if (!await EventCategoryAccess.CanAssignAsync(
                    request.CategoryId, habit.CategoryId, request.UserId,
                    _categoryRepository, _squadRepository))
            {
                return false;
            }

            habit.Name = request.Name;
            habit.TargetDays = request.TargetDays;
            habit.CategoryId = request.CategoryId;

            await _repository.UpdateAsync(habit);
            return true;
        }
    }
}
