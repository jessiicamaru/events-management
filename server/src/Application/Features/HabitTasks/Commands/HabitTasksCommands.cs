using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.HabitTasks.Commands
{
    public class CreateHabitTaskCommand : IRequest<Guid>
    {
        public Guid HabitId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int Order { get; set; }
        public Priority Priority { get; set; }
        public int? EstimatedMinutes { get; set; }
        public string UserId { get; set; } = string.Empty;
    }

    public class CreateHabitTaskCommandHandler : IRequestHandler<CreateHabitTaskCommand, Guid>
    {
        private readonly IHabitRepository _habitRepository;
        private readonly IHabitTaskRepository _habitTaskRepository;

        public CreateHabitTaskCommandHandler(IHabitRepository habitRepository, IHabitTaskRepository habitTaskRepository)
        {
            _habitRepository = habitRepository;
            _habitTaskRepository = habitTaskRepository;
        }

        public async Task<Guid> Handle(CreateHabitTaskCommand request, CancellationToken cancellationToken)
        {
            var habit = await _habitRepository.GetByIdAsync(request.HabitId);
            if (habit == null || habit.UserId != request.UserId) throw new UnauthorizedAccessException();

            var task = new HabitTask
            {
                HabitId = request.HabitId,
                Title = request.Title,
                Description = request.Description,
                Order = request.Order,
                Priority = request.Priority,
                EstimatedMinutes = request.EstimatedMinutes
            };

            await _habitTaskRepository.AddAsync(task);
            return task.Id;
        }
    }

    public class UpdateHabitTaskCommand : IRequest<bool>
    {
        public Guid Id { get; set; }
        public Guid HabitId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public Priority Priority { get; set; }
        public int? EstimatedMinutes { get; set; }
        public string UserId { get; set; } = string.Empty;
    }

    public class UpdateHabitTaskCommandHandler : IRequestHandler<UpdateHabitTaskCommand, bool>
    {
        private readonly IHabitRepository _habitRepository;
        private readonly IHabitTaskRepository _habitTaskRepository;

        public UpdateHabitTaskCommandHandler(IHabitRepository habitRepository, IHabitTaskRepository habitTaskRepository)
        {
            _habitRepository = habitRepository;
            _habitTaskRepository = habitTaskRepository;
        }

        public async Task<bool> Handle(UpdateHabitTaskCommand request, CancellationToken cancellationToken)
        {
            var habit = await _habitRepository.GetByIdAsync(request.HabitId);
            if (habit == null || habit.UserId != request.UserId) return false;

            var task = await _habitTaskRepository.GetByIdAsync(request.Id);
            if (task == null || task.HabitId != request.HabitId) return false;

            task.Title = request.Title;
            task.Description = request.Description;
            task.Priority = request.Priority;
            task.EstimatedMinutes = request.EstimatedMinutes;

            await _habitTaskRepository.UpdateAsync(task);
            return true;
        }
    }

    public class DeleteHabitTaskCommand : IRequest<bool>
    {
        public Guid Id { get; set; }
        public Guid HabitId { get; set; }
        public string UserId { get; set; } = string.Empty;
    }

    public class DeleteHabitTaskCommandHandler : IRequestHandler<DeleteHabitTaskCommand, bool>
    {
        private readonly IHabitRepository _habitRepository;
        private readonly IHabitTaskRepository _habitTaskRepository;

        public DeleteHabitTaskCommandHandler(IHabitRepository habitRepository, IHabitTaskRepository habitTaskRepository)
        {
            _habitRepository = habitRepository;
            _habitTaskRepository = habitTaskRepository;
        }

        public async Task<bool> Handle(DeleteHabitTaskCommand request, CancellationToken cancellationToken)
        {
            var habit = await _habitRepository.GetByIdAsync(request.HabitId);
            if (habit == null || habit.UserId != request.UserId) return false;

            var task = await _habitTaskRepository.GetByIdAsync(request.Id);
            if (task == null || task.HabitId != request.HabitId) return false;

            await _habitTaskRepository.DeleteAsync(request.Id);
            return true;
        }
    }

    public class ReorderHabitTasksCommand : IRequest<bool>
    {
        public Guid HabitId { get; set; }
        public List<TaskOrderDto> Tasks { get; set; } = new();
        public string UserId { get; set; } = string.Empty;
    }

    public class TaskOrderDto
    {
        public Guid Id { get; set; }
        public int Order { get; set; }
    }

    public class ReorderHabitTasksCommandHandler : IRequestHandler<ReorderHabitTasksCommand, bool>
    {
        private readonly IHabitRepository _habitRepository;
        private readonly IHabitTaskRepository _habitTaskRepository;

        public ReorderHabitTasksCommandHandler(IHabitRepository habitRepository, IHabitTaskRepository habitTaskRepository)
        {
            _habitRepository = habitRepository;
            _habitTaskRepository = habitTaskRepository;
        }

        public async Task<bool> Handle(ReorderHabitTasksCommand request, CancellationToken cancellationToken)
        {
            var habit = await _habitRepository.GetByIdAsync(request.HabitId);
            if (habit == null || habit.UserId != request.UserId) return false;

            var tasks = (await _habitTaskRepository.GetByHabitIdAsync(request.HabitId)).ToList();
            
            foreach (var update in request.Tasks)
            {
                var task = tasks.FirstOrDefault(t => t.Id == update.Id);
                if (task != null)
                {
                    task.Order = update.Order;
                }
            }

            await _habitTaskRepository.UpdateOrderAsync(tasks);
            return true;
        }
    }
}
