using HabitTracker.Domain.Interfaces;
using HabitTracker.Domain.Entities;
using MediatR;
using System;
using System.Linq;
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
        public Guid? CategoryId { get; set; }
        public string? EditScope { get; set; } // "ThisOccurrence", "ThisAndFuture", "AllOccurrences"
        public DateTime? OriginalOccurrenceDate { get; set; }
        public string? RecurrenceRule { get; set; }
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
                return false;
            }

            var editScope = request.EditScope ?? "AllOccurrences";

            if (!string.IsNullOrEmpty(existingEvent.RecurrenceRule) && editScope == "ThisOccurrence")
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

                // 2. Create a new exception event pointing to the master
                var exceptionEvent = new Event
                {
                    Id = Guid.NewGuid(),
                    Title = request.Title,
                    StartTime = request.StartTime.ToUniversalTime(),
                    EndTime = request.EndTime.ToUniversalTime(),
                    HabitId = request.HabitId,
                    TargetDuration = request.TargetDuration ?? (request.EndTime.ToUniversalTime() - request.StartTime.ToUniversalTime()),
                    UserId = request.UserId,
                    CategoryId = request.CategoryId,
                    ParentEventId = existingEvent.Id,
                    ExceptionDate = exceptionDateUtc,
                    IsCompleted = false
                };
                await _eventRepository.AddAsync(exceptionEvent);
                return true;
            }
            else if (!string.IsNullOrEmpty(existingEvent.RecurrenceRule) && editScope == "ThisAndFuture")
            {
                // 1. Truncate current master recurrence rule to end before this occurrence
                var splitDate = (request.OriginalOccurrenceDate ?? request.StartTime).ToUniversalTime();
                var oldRule = existingEvent.RecurrenceRule;
                var parts = oldRule.Split(';').Where(p => !p.StartsWith("UNTIL=") && !p.StartsWith("COUNT="));
                var untilDate = splitDate.AddSeconds(-1).ToString("yyyyMMddTHHmmssZ");
                existingEvent.RecurrenceRule = string.Join(";", parts) + ";UNTIL=" + untilDate;
                await _eventRepository.UpdateAsync(existingEvent);

                // 2. Create new master event starting from request.StartTime with updated rule
                var newMasterEvent = new Event
                {
                    Id = Guid.NewGuid(),
                    Title = request.Title,
                    StartTime = request.StartTime.ToUniversalTime(),
                    EndTime = request.EndTime.ToUniversalTime(),
                    HabitId = request.HabitId,
                    TargetDuration = request.TargetDuration ?? (request.EndTime.ToUniversalTime() - request.StartTime.ToUniversalTime()),
                    UserId = request.UserId,
                    CategoryId = request.CategoryId,
                    RecurrenceRule = request.RecurrenceRule ?? oldRule
                };
                await _eventRepository.AddAsync(newMasterEvent);
                return true;
            }
            else
            {
                // AllOccurrences or normal update
                existingEvent.Title = request.Title;
                existingEvent.StartTime = request.StartTime.ToUniversalTime();
                existingEvent.EndTime = request.EndTime.ToUniversalTime();
                existingEvent.HabitId = request.HabitId;
                existingEvent.CategoryId = request.CategoryId;
                existingEvent.TargetDuration = request.TargetDuration ?? (request.EndTime.ToUniversalTime() - request.StartTime.ToUniversalTime());
                existingEvent.RecurrenceRule = request.RecurrenceRule ?? existingEvent.RecurrenceRule;

                await _eventRepository.UpdateAsync(existingEvent);
                return true;
            }
        }
    }
}
