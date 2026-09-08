using System;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Events.Commands
{
    public class CreateEventCommand : IRequest<Guid>
    {
        public string Title { get; set; } = string.Empty;
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public string HabitId { get; set; } = string.Empty;
    }

    public class CreateEventCommandHandler : IRequestHandler<CreateEventCommand, Guid>
    {
        private readonly IEventRepository _repository;

        public CreateEventCommandHandler(IEventRepository repository)
        {
            _repository = repository;
        }

        public async Task<Guid> Handle(CreateEventCommand request, CancellationToken cancellationToken)
        {
            var ev = new Event
            {
                Title = request.Title,
                StartTime = request.StartTime,
                EndTime = request.EndTime,
                HabitId = request.HabitId
            };

            await _repository.AddAsync(ev);
            return ev.Id;
        }
    }
}
