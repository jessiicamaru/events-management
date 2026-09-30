using HabitTracker.Domain.Interfaces;
using MediatR;
using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace HabitTracker.Application.Features.Events.Commands
{
    public class DeleteEventCommand : IRequest<bool>
    {
        public Guid EventId { get; set; }
        public string? UserId { get; set; } // Set by endpoint from ClaimsPrincipal
        public string? DeleteScope { get; set; } // "ThisOccurrence", "ThisAndFuture", "AllOccurrences"
        public DateTime? OriginalOccurrenceDate { get; set; }

        public DeleteEventCommand(Guid eventId, string? userId = null, string? deleteScope = null, DateTime? originalOccurrenceDate = null)
        {
            EventId = eventId;
            UserId = userId;
            DeleteScope = deleteScope;
            OriginalOccurrenceDate = originalOccurrenceDate;
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

            var deleteScope = request.DeleteScope ?? "AllOccurrences";

            if (!string.IsNullOrEmpty(existingEvent.RecurrenceRule) && deleteScope == "ThisOccurrence")
            {
                // 1. Add exception date to master event
                var exceptionDateUtc = (request.OriginalOccurrenceDate ?? existingEvent.StartTime).ToUniversalTime();
                var exceptionDateStr = exceptionDateUtc.ToString("yyyy-MM-ddTHH:mm:ssZ");

                if (string.IsNullOrEmpty(existingEvent.RecurrenceExceptionDates))
                {
                    existingEvent.RecurrenceExceptionDates = exceptionDateStr;
                }
                else if (!existingEvent.RecurrenceExceptionDates.Contains(exceptionDateStr))
                {
                    existingEvent.RecurrenceExceptionDates += "," + exceptionDateStr;
                }
                await _eventRepository.UpdateAsync(existingEvent);
                return true;
            }
            else if (!string.IsNullOrEmpty(existingEvent.RecurrenceRule) && deleteScope == "ThisAndFuture")
            {
                // 1. Truncate master event series recurrence rule
                var splitDate = (request.OriginalOccurrenceDate ?? existingEvent.StartTime).ToUniversalTime();
                var oldRule = existingEvent.RecurrenceRule;
                var parts = oldRule.Split(';').Where(p => !p.StartsWith("UNTIL=") && !p.StartsWith("COUNT="));
                var untilDate = splitDate.AddSeconds(-1).ToString("yyyyMMddTHHmmssZ");
                existingEvent.RecurrenceRule = string.Join(";", parts) + ";UNTIL=" + untilDate;
                await _eventRepository.UpdateAsync(existingEvent);

                // 2. Delete any child exceptions from this date forward
                if (!string.IsNullOrEmpty(request.UserId))
                {
                    var allEvents = await _eventRepository.GetEventsForUserAsync(request.UserId);
                    var childExceptionsToDelete = allEvents.Where(e => e.ParentEventId == existingEvent.Id && e.ExceptionDate >= splitDate);
                    foreach (var childEvent in childExceptionsToDelete)
                    {
                        await _eventRepository.DeleteAsync(childEvent.Id);
                    }
                }
                return true;
            }
            else
            {
                // AllOccurrences or normal single event deletion
                // If it is a master event, also delete all child exceptions
                if (!string.IsNullOrEmpty(existingEvent.RecurrenceRule) && !string.IsNullOrEmpty(request.UserId))
                {
                    var allEvents = await _eventRepository.GetEventsForUserAsync(request.UserId);
                    var childExceptionsToDelete = allEvents.Where(e => e.ParentEventId == existingEvent.Id);
                    foreach (var childEvent in childExceptionsToDelete)
                    {
                        await _eventRepository.DeleteAsync(childEvent.Id);
                    }
                }

                await _eventRepository.DeleteAsync(request.EventId);
                return true;
            }
        }
    }
}
