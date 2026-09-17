using HabitTracker.Domain.Interfaces;
using MediatR;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace HabitTracker.Application.Features.Events.Commands
{
    public class UpdateEventCommand : IRequest<bool>
    {
        public Guid EventId { get; set; }
        public string Title { get; set; } = string.Empty;
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public string HabitId { get; set; } = string.Empty;
        public TimeSpan? TargetDuration { get; set; }
        public string? UserId { get; set; } // Set by endpoint from ClaimsPrincipal
    }

    public class UpdateEventCommandHandler : IRequestHandler<UpdateEventCommand, bool>
    {
        private readonly IEventRepository _eventRepository;

        public UpdateEventCommandHandler(IEventRepository eventRepository)
        {
            _eventRepository = eventRepository;
        }

        public async Task<bool> Handle(UpdateEventCommand request, CancellationToken cancellationToken)
        {
            var existingEvent = await _eventRepository.GetByIdAsync(request.EventId);
            if (existingEvent == null)
            {
                return false;
            }

            // Only the owner can update the event
            if (existingEvent.UserId != request.UserId)
            {
                return false; // Could also throw UnauthorizedAccessException
            }

            existingEvent.Title = request.Title;
            existingEvent.StartTime = request.StartTime.ToUniversalTime();
            existingEvent.EndTime = request.EndTime.ToUniversalTime();
            existingEvent.HabitId = request.HabitId;
            existingEvent.TargetDuration = request.TargetDuration ?? (request.EndTime.ToUniversalTime() - request.StartTime.ToUniversalTime());

            await _eventRepository.UpdateAsync(existingEvent);
            return true;
        }
    }
}
