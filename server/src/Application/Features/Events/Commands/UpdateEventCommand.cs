using HabitTracker.Domain.Interfaces;
using HabitTracker.Application.Common;
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

        /// <summary>Minutes before the start to remind; empty means no reminders.</summary>
        public List<int>? ReminderMinutesBefore { get; set; }
    }

    public class UpdateEventCommandHandler : IRequestHandler<UpdateEventCommand, bool>
    {
        private readonly IEventRepository _eventRepository;
        private readonly IUserRepository _userRepository;
        private readonly IGoogleCalendarOutboxRepository _outboxRepository;

        public UpdateEventCommandHandler(
            IEventRepository eventRepository,
            IUserRepository userRepository,
            IGoogleCalendarOutboxRepository outboxRepository)
        {
            _eventRepository = eventRepository;
            _userRepository = userRepository;
            _outboxRepository = outboxRepository;
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

            var user = await _userRepository.GetByIdAsync(request.UserId ?? string.Empty);
            bool hasGoogle = user != null && !string.IsNullOrEmpty(user.GoogleRefreshToken);

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
                    IsCompleted = false,
                    // The whole point of editing one occurrence: this child keeps its own
                    // reminder set, so one day of a series can differ from the others.
                    ReminderMinutesBefore = ReminderOptions.Normalise(
                        request.ReminderMinutesBefore ?? existingEvent.ReminderMinutesBefore)
                };
                await _eventRepository.AddAsync(exceptionEvent);

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

                    // Enqueue Insert for Exception Event
                    var excPayload = System.Text.Json.JsonSerializer.Serialize(new
                    {
                        Title = exceptionEvent.Title,
                        StartTime = exceptionEvent.StartTime,
                        EndTime = exceptionEvent.EndTime,
                        ParentEventId = exceptionEvent.ParentEventId,
                        ExceptionDate = exceptionEvent.ExceptionDate
                    });
                    await _outboxRepository.EnqueueAsync(request.UserId!, exceptionEvent.Id, null, "Insert", excPayload, cancellationToken);
                }

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
                    RecurrenceRule = request.RecurrenceRule ?? oldRule,
                    ReminderMinutesBefore = ReminderOptions.Normalise(
                        request.ReminderMinutesBefore ?? existingEvent.ReminderMinutesBefore)
                };
                await _eventRepository.AddAsync(newMasterEvent);

                if (hasGoogle)
                {
                    // Enqueue Update for Old Master (UNTIL rule updated)
                    var oldMasterPayload = System.Text.Json.JsonSerializer.Serialize(new
                    {
                        Title = existingEvent.Title,
                        StartTime = existingEvent.StartTime,
                        EndTime = existingEvent.EndTime,
                        RecurrenceRule = existingEvent.RecurrenceRule
                    });
                    await _outboxRepository.EnqueueAsync(request.UserId!, existingEvent.Id, existingEvent.GoogleEventId, "Update", oldMasterPayload, cancellationToken);

                    // Enqueue Insert for New Master Event
                    var newMasterPayload = System.Text.Json.JsonSerializer.Serialize(new
                    {
                        Title = newMasterEvent.Title,
                        StartTime = newMasterEvent.StartTime,
                        EndTime = newMasterEvent.EndTime,
                        RecurrenceRule = newMasterEvent.RecurrenceRule
                    });
                    await _outboxRepository.EnqueueAsync(request.UserId!, newMasterEvent.Id, null, "Insert", newMasterPayload, cancellationToken);
                }

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

                // Null = field not supplied, keep what is stored. An empty list is a
                // deliberate "no reminders" and must not be treated as missing.
                if (request.ReminderMinutesBefore != null)
                {
                    existingEvent.ReminderMinutesBefore =
                        ReminderOptions.Normalise(request.ReminderMinutesBefore);
                }

                await _eventRepository.UpdateAsync(existingEvent);

                if (hasGoogle)
                {
                    var payload = System.Text.Json.JsonSerializer.Serialize(new
                    {
                        Title = existingEvent.Title,
                        StartTime = existingEvent.StartTime,
                        EndTime = existingEvent.EndTime,
                        RecurrenceRule = existingEvent.RecurrenceRule
                    });
                    await _outboxRepository.EnqueueAsync(request.UserId!, existingEvent.Id, existingEvent.GoogleEventId, "Update", payload, cancellationToken);
                }

                return true;
            }
        }
    }
}
