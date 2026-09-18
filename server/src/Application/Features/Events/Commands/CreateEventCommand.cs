using System;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;
using System.Linq;

namespace HabitTracker.Application.Features.Events.Commands
{
    public class CreateEventCommand : IRequest<Guid>
    {
        public string Title { get; set; } = string.Empty;
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public string HabitId { get; set; } = string.Empty;
        public TimeSpan? TargetDuration { get; set; }
        public string UserId { get; set; } = string.Empty;
    }

    public class CreateEventCommandHandler : IRequestHandler<CreateEventCommand, Guid>
    {
        private readonly IEventRepository _repository;
        private readonly IHabitTaskRepository _habitTaskRepository;
        private readonly IEventTaskRepository _eventTaskRepository;

        public CreateEventCommandHandler(IEventRepository repository, IHabitTaskRepository habitTaskRepository, IEventTaskRepository eventTaskRepository)
        {
            _repository = repository;
            _habitTaskRepository = habitTaskRepository;
            _eventTaskRepository = eventTaskRepository;
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
                UserId = request.UserId
            };

            await _repository.AddAsync(ev);

            if (Guid.TryParse(request.HabitId, out var parsedHabitId))
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
