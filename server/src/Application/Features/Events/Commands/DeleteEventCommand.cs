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
        private readonly IUserRepository _userRepository;
        private readonly IGoogleCalendarOutboxRepository _outboxRepository;

        public DeleteEventCommandHandler(
            IEventRepository eventRepository,
            IUserRepository userRepository,
            IGoogleCalendarOutboxRepository outboxRepository)
        {
            _eventRepository = eventRepository;
            _userRepository = userRepository;
            _outboxRepository = outboxRepository;
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

            var user = await _userRepository.GetByIdAsync(request.UserId ?? string.Empty);
            bool hasGoogle = user != null && !string.IsNullOrEmpty(user.GoogleRefreshToken);

            // A day with its own event — split off by an edit, a ticked task or a finished
            // session. The calendar shows it in place of the series' day.
            if (existingEvent.ParentEventId != null)
            {
                var parent = await _eventRepository.GetByIdAsync(existingEvent.ParentEventId.Value);
                var parentIsSeries = parent != null
                    && parent.UserId == request.UserId
                    && !string.IsNullOrEmpty(parent.RecurrenceRule)
                    && parent.ParentEventId == null;

                if (parentIsSeries
                    && (request.DeleteScope == "AllOccurrences" || request.DeleteScope == "ThisAndFuture"))
                {
                    // Means the series, as it would for an untouched day. Before, only this one
                    // row was deleted and the rest of the series stayed.
                    return await Handle(
                        new DeleteEventCommand(
                            parent!.Id,
                            request.UserId,
                            request.DeleteScope,
                            existingEvent.ExceptionDate ?? existingEvent.StartTime),
                        cancellationToken);
                }

                await _eventRepository.DeleteAsync(existingEvent.Id);

                if (parentIsSeries)
                {
                    // Without this the series' own occurrence would reappear on that day:
                    // a day split off locally never added itself to the exception list.
                    var dayUtc = (existingEvent.ExceptionDate ?? existingEvent.StartTime).ToUniversalTime();
                    var dayStr = dayUtc.ToString("yyyy-MM-ddTHH:mm:ssZ");
                    if (string.IsNullOrEmpty(parent!.RecurrenceExceptionDates))
                    {
                        parent.RecurrenceExceptionDates = dayStr;
                    }
                    else if (!parent.RecurrenceExceptionDates.Contains(dayStr))
                    {
                        parent.RecurrenceExceptionDates += "," + dayStr;
                    }
                    await _eventRepository.UpdateAsync(parent);
                }

                if (hasGoogle)
                {
                    if (!string.IsNullOrEmpty(existingEvent.GoogleEventId))
                    {
                        // Google has this day as its own instance: deleting it cancels the day.
                        await _outboxRepository.EnqueueAsync(request.UserId!, existingEvent.Id, existingEvent.GoogleEventId, "Delete", string.Empty, cancellationToken);
                    }
                    else if (parentIsSeries)
                    {
                        // Google only knows the series: cancel the day through its EXDATE list,
                        // exactly as deleting an untouched day does.
                        var masterPayload = System.Text.Json.JsonSerializer.Serialize(new
                        {
                            Title = parent!.Title,
                            StartTime = parent.StartTime,
                            EndTime = parent.EndTime,
                            RecurrenceRule = parent.RecurrenceRule,
                            RecurrenceExceptionDates = parent.RecurrenceExceptionDates
                        });
                        await _outboxRepository.EnqueueAsync(request.UserId!, parent.Id, parent.GoogleEventId, "Update", masterPayload, cancellationToken);
                    }
                }

                return true;
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

                if (hasGoogle)
                {
                    // Enqueue Update for Master (to sync EXDATE)
                    var masterPayload = System.Text.Json.JsonSerializer.Serialize(new
                    {
                        Title = existingEvent.Title,
                        StartTime = existingEvent.StartTime,
                        EndTime = existingEvent.EndTime,
                        RecurrenceRule = existingEvent.RecurrenceRule,
                        RecurrenceExceptionDates = existingEvent.RecurrenceExceptionDates
                    });
                    await _outboxRepository.EnqueueAsync(request.UserId!, existingEvent.Id, existingEvent.GoogleEventId, "Update", masterPayload, cancellationToken);
                }

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

                if (hasGoogle)
                {
                    // Enqueue Update for Master (recurrence rule UNTIL updated)
                    var masterPayload = System.Text.Json.JsonSerializer.Serialize(new
                    {
                        Title = existingEvent.Title,
                        StartTime = existingEvent.StartTime,
                        EndTime = existingEvent.EndTime,
                        RecurrenceRule = existingEvent.RecurrenceRule
                    });
                    await _outboxRepository.EnqueueAsync(request.UserId!, existingEvent.Id, existingEvent.GoogleEventId, "Update", masterPayload, cancellationToken);
                }

                // 2. Delete any child exceptions from this date forward
                if (!string.IsNullOrEmpty(request.UserId))
                {
                    var allEvents = await _eventRepository.GetEventsForUserAsync(request.UserId);
                    var childExceptionsToDelete = allEvents.Where(e => e.ParentEventId == existingEvent.Id && e.ExceptionDate >= splitDate).ToList();
                    foreach (var childEvent in childExceptionsToDelete)
                    {
                        await _eventRepository.DeleteAsync(childEvent.Id);
                        if (hasGoogle && !string.IsNullOrEmpty(childEvent.GoogleEventId))
                        {
                            await _outboxRepository.EnqueueAsync(request.UserId!, childEvent.Id, childEvent.GoogleEventId, "Delete", string.Empty, cancellationToken);
                        }
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
                    var childExceptionsToDelete = allEvents.Where(e => e.ParentEventId == existingEvent.Id).ToList();
                    foreach (var childEvent in childExceptionsToDelete)
                    {
                        await _eventRepository.DeleteAsync(childEvent.Id);
                        if (hasGoogle && !string.IsNullOrEmpty(childEvent.GoogleEventId))
                        {
                            await _outboxRepository.EnqueueAsync(request.UserId!, childEvent.Id, childEvent.GoogleEventId, "Delete", string.Empty, cancellationToken);
                        }
                    }
                }

                await _eventRepository.DeleteAsync(request.EventId);

                if (hasGoogle && !string.IsNullOrEmpty(existingEvent.GoogleEventId))
                {
                    await _outboxRepository.EnqueueAsync(request.UserId!, existingEvent.Id, existingEvent.GoogleEventId, "Delete", string.Empty, cancellationToken);
                }

                return true;
            }
        }
    }
}
