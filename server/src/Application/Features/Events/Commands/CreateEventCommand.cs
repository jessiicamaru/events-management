using System;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Application.Common;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;
using System.Linq;

namespace HabitTracker.Application.Features.Events.Commands
{
    public class CreateEventTaskDto
    {
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public int Order { get; set; }
        public Priority Priority { get; set; }
        public int? EstimatedMinutes { get; set; }
    }

    public class CreateEventCommand : IRequest<Guid>
    {
        public string Title { get; set; } = string.Empty;
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public string HabitId { get; set; } = string.Empty;
        public TimeSpan? TargetDuration { get; set; }
        public string UserId { get; set; } = string.Empty;
        public Guid? CategoryId { get; set; }
        public List<CreateEventTaskDto>? Tasks { get; set; }
        public string? RecurrenceRule { get; set; }

        /// <summary>Minutes before the start to remind; empty means no reminders.</summary>
        public List<int>? ReminderMinutesBefore { get; set; }
    }

    public class CreateEventCommandHandler : IRequestHandler<CreateEventCommand, Guid>
    {
        private readonly IEventRepository _repository;
        private readonly IHabitTaskRepository _habitTaskRepository;
        private readonly IEventTaskRepository _eventTaskRepository;
        private readonly IUserRepository _userRepository;
        private readonly IGoogleCalendarOutboxRepository _outboxRepository;

        public CreateEventCommandHandler(
            IEventRepository repository, 
            IHabitTaskRepository habitTaskRepository, 
            IEventTaskRepository eventTaskRepository,
            IUserRepository userRepository,
            IGoogleCalendarOutboxRepository outboxRepository)
        {
            _repository = repository;
            _habitTaskRepository = habitTaskRepository;
            _eventTaskRepository = eventTaskRepository;
            _userRepository = userRepository;
            _outboxRepository = outboxRepository;
        }

        public async Task<Guid> Handle(CreateEventCommand request, CancellationToken cancellationToken)
        {
            var ev = new Event
            {
                Title = request.Title,
                StartTime = request.StartTime.ToUniversalTime(),
                EndTime = request.EndTime.ToUniversalTime(),
                HabitId = request.HabitId,
                TargetDuration = request.TargetDuration ?? request.EndTime.ToUniversalTime() - request.StartTime.ToUniversalTime(),
                UserId = request.UserId,
                CategoryId = request.CategoryId,
                RecurrenceRule = request.RecurrenceRule,
                ReminderMinutesBefore = ReminderOptions.Normalise(request.ReminderMinutesBefore)
            };

            await _repository.AddAsync(ev);

            var user = await _userRepository.GetByIdAsync(request.UserId);
            if (user != null && !string.IsNullOrEmpty(user.GoogleRefreshToken))
            {
                var payload = System.Text.Json.JsonSerializer.Serialize(new
                {
                    Title = ev.Title,
                    StartTime = ev.StartTime,
                    EndTime = ev.EndTime,
                    RecurrenceRule = ev.RecurrenceRule
                });
                await _outboxRepository.EnqueueAsync(request.UserId, ev.Id, null, "Insert", payload, cancellationToken);
            }

            if (request.Tasks != null && request.Tasks.Any())
            {
                foreach (var taskDto in request.Tasks)
                {
                    var eventTask = new EventTask
                    {
                        EventId = ev.Id,
                        Title = taskDto.Title,
                        Description = taskDto.Description,
                        Order = taskDto.Order,
                        Priority = taskDto.Priority,
                        EstimatedMinutes = taskDto.EstimatedMinutes,
                        IsCompleted = false
                    };
                    await _eventTaskRepository.AddAsync(eventTask);
                }
            }
            else if (Guid.TryParse(request.HabitId, out var parsedHabitId))
            {
                var templateTasks = (await _habitTaskRepository.GetByHabitIdAsync(parsedHabitId)).ToList();

                foreach (var templateTask in templateTasks)
                {
                    var eventTask = new EventTask
                    {
                        EventId = ev.Id,
                        Title = templateTask.Title,
                        Description = templateTask.Description,
                        Order = templateTask.Order,
                        Priority = templateTask.Priority,
                        EstimatedMinutes = templateTask.EstimatedMinutes,
                        IsCompleted = false
                    };
                    await _eventTaskRepository.AddAsync(eventTask);
                }
            }

            return ev.Id;
        }
    }
}
