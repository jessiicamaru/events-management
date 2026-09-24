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
        public Guid? CategoryId { get; set; }
        public string UserId { get; set; } = string.Empty;
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
