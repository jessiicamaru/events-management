using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Habits.Commands
{
    public class UpdateHabitCommand : IRequest<bool>
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public List<int> TargetDays { get; set; } = new();
        public string UserId { get; set; } = string.Empty;
    }

    public class UpdateHabitCommandHandler : IRequestHandler<UpdateHabitCommand, bool>
    {
        private readonly IHabitRepository _repository;

        public UpdateHabitCommandHandler(IHabitRepository repository)
        {
            _repository = repository;
        }

        public async Task<bool> Handle(UpdateHabitCommand request, CancellationToken cancellationToken)
        {
            var habit = await _repository.GetByIdAsync(request.Id);
            if (habit == null || habit.UserId != request.UserId)
            {
                return false;
            }

            habit.Name = request.Name;
            habit.Category = request.Category;
            habit.TargetDays = request.TargetDays;

            await _repository.UpdateAsync(habit);
            return true;
        }
    }
}
