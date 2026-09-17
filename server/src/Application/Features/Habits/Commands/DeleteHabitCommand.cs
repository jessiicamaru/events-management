using System;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Habits.Commands
{
    public class DeleteHabitCommand : IRequest<bool>
    {
        public Guid Id { get; set; }
        public string UserId { get; set; } = string.Empty;
    }

    public class DeleteHabitCommandHandler : IRequestHandler<DeleteHabitCommand, bool>
    {
        private readonly IHabitRepository _repository;

        public DeleteHabitCommandHandler(IHabitRepository repository)
        {
            _repository = repository;
        }

        public async Task<bool> Handle(DeleteHabitCommand request, CancellationToken cancellationToken)
        {
            var habit = await _repository.GetByIdAsync(request.Id);
            if (habit == null || habit.UserId != request.UserId)
            {
                return false;
            }

            await _repository.DeleteAsync(request.Id);
            return true;
        }
    }
}
