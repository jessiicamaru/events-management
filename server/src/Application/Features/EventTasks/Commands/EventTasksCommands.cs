using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.EventTasks.Commands
{
    public class CreateEventTaskCommand : IRequest<Guid>
    {
        public Guid EventId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int Order { get; set; }
        public Priority Priority { get; set; }
        public int? EstimatedMinutes { get; set; }
        public string UserId { get; set; } = string.Empty;
    }

    public class CreateEventTaskCommandHandler : IRequestHandler<CreateEventTaskCommand, Guid>
    {
        private readonly IEventRepository _eventRepository;
        private readonly IEventTaskRepository _eventTaskRepository;

        public CreateEventTaskCommandHandler(IEventRepository eventRepository, IEventTaskRepository eventTaskRepository)
        {
            _eventRepository = eventRepository;
            _eventTaskRepository = eventTaskRepository;
        }

        public async Task<Guid> Handle(CreateEventTaskCommand request, CancellationToken cancellationToken)
        {
            var evt = await _eventRepository.GetByIdAsync(request.EventId);
            if (evt == null || evt.UserId != request.UserId) throw new UnauthorizedAccessException();

            var task = new EventTask
            {
                EventId = request.EventId,
                Title = request.Title,
                Description = request.Description,
                Order = request.Order,
                Priority = request.Priority,
                EstimatedMinutes = request.EstimatedMinutes,
                IsCompleted = false
            };

            await _eventTaskRepository.AddAsync(task);
            return task.Id;
        }
    }

    public class UpdateEventTaskCommand : IRequest<bool>
    {
        public Guid Id { get; set; }
        public Guid EventId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public Priority Priority { get; set; }
        public int? EstimatedMinutes { get; set; }
        public string UserId { get; set; } = string.Empty;
    }

    public class UpdateEventTaskCommandHandler : IRequestHandler<UpdateEventTaskCommand, bool>
    {
        private readonly IEventRepository _eventRepository;
        private readonly IEventTaskRepository _eventTaskRepository;

        public UpdateEventTaskCommandHandler(IEventRepository eventRepository, IEventTaskRepository eventTaskRepository)
        {
            _eventRepository = eventRepository;
            _eventTaskRepository = eventTaskRepository;
        }

        public async Task<bool> Handle(UpdateEventTaskCommand request, CancellationToken cancellationToken)
        {
            var evt = await _eventRepository.GetByIdAsync(request.EventId);
            if (evt == null || evt.UserId != request.UserId) return false;

            var task = await _eventTaskRepository.GetByIdAsync(request.Id);
            if (task == null || task.EventId != request.EventId) return false;

            task.Title = request.Title;
            task.Description = request.Description;
            task.Priority = request.Priority;
            task.EstimatedMinutes = request.EstimatedMinutes;

            await _eventTaskRepository.UpdateAsync(task);
            return true;
        }
    }

    public class ToggleEventTaskCommand : IRequest<bool>
    {
        public Guid Id { get; set; }
        public Guid EventId { get; set; }
        public bool IsCompleted { get; set; }
        public string UserId { get; set; } = string.Empty;
    }

    public class ToggleEventTaskCommandHandler : IRequestHandler<ToggleEventTaskCommand, bool>
    {
        private readonly IEventRepository _eventRepository;
        private readonly IEventTaskRepository _eventTaskRepository;

        public ToggleEventTaskCommandHandler(IEventRepository eventRepository, IEventTaskRepository eventTaskRepository)
        {
            _eventRepository = eventRepository;
            _eventTaskRepository = eventTaskRepository;
        }

        public async Task<bool> Handle(ToggleEventTaskCommand request, CancellationToken cancellationToken)
        {
            var evt = await _eventRepository.GetByIdAsync(request.EventId);
            if (evt == null || evt.UserId != request.UserId) return false;

            var task = await _eventTaskRepository.GetByIdAsync(request.Id);
            if (task == null || task.EventId != request.EventId) return false;

            task.IsCompleted = request.IsCompleted;
            await _eventTaskRepository.UpdateAsync(task);
            return true;
        }
    }

    public class DeleteEventTaskCommand : IRequest<bool>
    {
        public Guid Id { get; set; }
        public Guid EventId { get; set; }
        public string UserId { get; set; } = string.Empty;
    }

    public class DeleteEventTaskCommandHandler : IRequestHandler<DeleteEventTaskCommand, bool>
    {
        private readonly IEventRepository _eventRepository;
        private readonly IEventTaskRepository _eventTaskRepository;

        public DeleteEventTaskCommandHandler(IEventRepository eventRepository, IEventTaskRepository eventTaskRepository)
        {
            _eventRepository = eventRepository;
            _eventTaskRepository = eventTaskRepository;
        }

        public async Task<bool> Handle(DeleteEventTaskCommand request, CancellationToken cancellationToken)
        {
            var evt = await _eventRepository.GetByIdAsync(request.EventId);
            if (evt == null || evt.UserId != request.UserId) return false;

            var task = await _eventTaskRepository.GetByIdAsync(request.Id);
            if (task == null || task.EventId != request.EventId) return false;

            await _eventTaskRepository.DeleteAsync(request.Id);
            return true;
        }
    }
}
