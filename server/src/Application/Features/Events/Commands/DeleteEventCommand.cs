using HabitTracker.Domain.Interfaces;
using MediatR;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace HabitTracker.Application.Features.Events.Commands
{
    public class DeleteEventCommand : IRequest<bool>
    {
        public Guid EventId { get; set; }
        public string? UserId { get; set; } // Set by endpoint from ClaimsPrincipal

        public DeleteEventCommand(Guid eventId, string? userId = null)
        {
            EventId = eventId;
            UserId = userId;
        }
    }

    public class DeleteEventCommandHandler : IRequestHandler<DeleteEventCommand, bool>
    {
        private readonly IEventRepository _eventRepository;

        public DeleteEventCommandHandler(IEventRepository eventRepository)
        {
            _eventRepository = eventRepository;
        }

        public async Task<bool> Handle(DeleteEventCommand request, CancellationToken cancellationToken)
        {
            var existingEvent = await _eventRepository.GetByIdAsync(request.EventId);
            if (existingEvent == null)
            {
                return false;
            }

            // Only the owner can delete the event
            if (existingEvent.UserId != request.UserId)
            {
                return false;
            }

            await _eventRepository.DeleteAsync(request.EventId);
            return true;
        }
    }
}
