using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Habits.Commands
{
    public class CreateHabitCommand : IRequest<Guid>
    {
        public string Name { get; set; } = string.Empty;
        public List<int> TargetDays { get; set; } = new();
    }

    public class CreateHabitCommandHandler : IRequestHandler<CreateHabitCommand, Guid>
    {
        private readonly IHabitRepository _repository;

        public CreateHabitCommandHandler(IHabitRepository repository)
        {
            _repository = repository;
        }

        public async Task<Guid> Handle(CreateHabitCommand request, CancellationToken cancellationToken)
        {
            // AI Categorization Mock Logic
            string category = "General";
            var lowerName = request.Name.ToLower();
            if (lowerName.Contains("read") || lowerName.Contains("study")) category = "Learning";
            else if (lowerName.Contains("workout") || lowerName.Contains("run")) category = "Health";

            var habit = new Habit
            {
                Name = request.Name,
                TargetDays = request.TargetDays,
                Category = category
            };

            await _repository.AddAsync(habit);
            return habit.Id;
        }
    }
}
