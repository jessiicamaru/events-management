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
        private const string ThisOccurrence = "ThisOccurrence";
        private const string ThisAndFuture = "ThisAndFuture";
        private const string AllOccurrences = "AllOccurrences";

        private readonly IEventRepository _eventRepository;
        private readonly IUserRepository _userRepository;
        private readonly IGoogleCalendarOutboxRepository _outboxRepository;
        private readonly OccurrenceMaterializer _materializer;

        public UpdateEventCommandHandler(
            IEventRepository eventRepository,
            IUserRepository userRepository,
            IGoogleCalendarOutboxRepository outboxRepository,
            OccurrenceMaterializer materializer)
        {
            _eventRepository = eventRepository;
            _userRepository = userRepository;
            _outboxRepository = outboxRepository;
            _materializer = materializer;
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

            if (existingEvent.ParentEventId != null)
            {
                return await UpdateSplitOffDayAsync(existingEvent, request, hasGoogle, cancellationToken);
            }

            var editScope = request.EditScope ?? AllOccurrences;

            if (!string.IsNullOrEmpty(existingEvent.RecurrenceRule) && editScope == ThisOccurrence)
            {
                return await EditOneDayOfSeriesAsync(existingEvent, request, hasGoogle, cancellationToken);
            }

            if (!string.IsNullOrEmpty(existingEvent.RecurrenceRule) && editScope == ThisAndFuture)
            {
                await SplitSeriesAsync(existingEvent, request, hasGoogle, cancellationToken);
                return true;
            }

            // AllOccurrences or normal update
            await UpdateWholeEventAsync(existingEvent, request, hasGoogle, cancellationToken);
            return true;
        }

        /// <summary>
        /// An edit to a day that has its own event — split off by an earlier edit, or by a
        /// ticked task or finished session (<see cref="OccurrenceMaterializer"/>).
        /// </summary>
        /// <remarks>
        /// The calendar shows such a day in place of the series' day, so this is also where
        /// dragging "today" lands once today has been touched. "All occurrences" and "this and
        /// future" therefore mean the series, as they would for an untouched day — before,
        /// they changed only this one row. The day itself follows the move, keeping its tasks
        /// and completion.
        /// </remarks>
        private async Task<bool> UpdateSplitOffDayAsync(
            Event day,
            UpdateEventCommand request,
            bool hasGoogle,
            CancellationToken cancellationToken)
        {
            var parent = await _eventRepository.GetByIdAsync(day.ParentEventId!.Value);
            var parentIsSeries = parent != null
                && parent.UserId == request.UserId
                && OccurrenceMaterializer.IsSeries(parent);

            if (parentIsSeries && (request.EditScope == AllOccurrences || request.EditScope == ThisAndFuture))
            {
                request.OriginalOccurrenceDate = day.ExceptionDate ?? day.StartTime;

                var seriesNowHoldingDay = request.EditScope == AllOccurrences
                    ? await UpdateWholeEventAsync(parent!, request, hasGoogle, cancellationToken)
                    : await SplitSeriesAsync(parent!, request, hasGoogle, cancellationToken);

                // Keep the day on the slot it was moved to, so it still stands in for the
                // series' occurrence there instead of showing next to it.
                ApplyDayFields(day, request);
                day.ParentEventId = seriesNowHoldingDay.Id;
                day.ExceptionDate = day.StartTime;
                await _eventRepository.UpdateAsync(day);
                return true;
            }

            ApplyDayFields(day, request);
            await _eventRepository.UpdateAsync(day);

            if (!hasGoogle) return true;

            if (await GoogleSyncGuard.GoogleKnowsAsync(day, _outboxRepository, cancellationToken))
            {
                await EnqueueUpdateAsync(request.UserId!, day, cancellationToken);
                return true;
            }

            // A day split off locally, now actually edited: from here it behaves like any
            // edited occurrence and goes to Google as one. Until this edit there was nothing
            // for Google to know.
            if (parentIsSeries)
            {
                await PromoteToGoogleAsync(parent!, day, request.UserId!, cancellationToken);
            }

            return true;
        }

        /// <summary>"Edit this occurrence" on a series.</summary>
        private async Task<bool> EditOneDayOfSeriesAsync(
            Event series,
            UpdateEventCommand request,
            bool hasGoogle,
            CancellationToken cancellationToken)
        {
            var occurrenceUtc = (request.OriginalOccurrenceDate ?? series.StartTime).ToUniversalTime();

            // Reuses the day if it was already split off (by a ticked task, say) instead of
            // adding a second event for the same day, and brings the series' tasks with it.
            var day = await _materializer.FindOrCreateAsync(series, occurrenceUtc, cancellationToken);
            if (day == null) return false;

            var googleAlreadyHasDay = await GoogleSyncGuard.GoogleKnowsAsync(day, _outboxRepository, cancellationToken);

            ApplyDayFields(day, request);
            // The whole point of editing one occurrence: this child keeps its own reminder
            // set, so one day of a series can differ from the others.
            day.ReminderMinutesBefore = ReminderOptions.Normalise(
                request.ReminderMinutesBefore ?? series.ReminderMinutesBefore);
            await _eventRepository.UpdateAsync(day);

            AddExceptionDate(series, occurrenceUtc);
            await _eventRepository.UpdateAsync(series);

            if (hasGoogle)
            {
                // Master first, so Google drops the original day before the replacement lands.
                await EnqueueMasterWithExceptionsAsync(request.UserId!, series, cancellationToken);

                if (googleAlreadyHasDay)
                {
                    await EnqueueUpdateAsync(request.UserId!, day, cancellationToken);
                }
                else
                {
                    await EnqueueExceptionInsertAsync(request.UserId!, day, cancellationToken);
                }
            }

            return true;
        }

        /// <summary>"This and future" on a series: end it before the day, start a new one there.</summary>
        /// <returns>The new series.</returns>
        private async Task<Event> SplitSeriesAsync(
            Event series,
            UpdateEventCommand request,
            bool hasGoogle,
            CancellationToken cancellationToken)
        {
            // 1. Truncate current master recurrence rule to end before this occurrence
            var splitDate = (request.OriginalOccurrenceDate ?? request.StartTime).ToUniversalTime();
            var oldRule = series.RecurrenceRule!;
            var parts = oldRule.Split(';').Where(p => !p.StartsWith("UNTIL=") && !p.StartsWith("COUNT="));
            var untilDate = splitDate.AddSeconds(-1).ToString("yyyyMMddTHHmmssZ");
            series.RecurrenceRule = string.Join(";", parts) + ";UNTIL=" + untilDate;
            await _eventRepository.UpdateAsync(series);

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
                    request.ReminderMinutesBefore ?? series.ReminderMinutesBefore)
            };
            await _eventRepository.AddAsync(newMasterEvent);

            if (hasGoogle)
            {
                // Enqueue Update for Old Master (UNTIL rule updated)
                var oldMasterPayload = System.Text.Json.JsonSerializer.Serialize(new
                {
                    Title = series.Title,
                    StartTime = series.StartTime,
                    EndTime = series.EndTime,
                    RecurrenceRule = series.RecurrenceRule
                });
                await _outboxRepository.EnqueueAsync(request.UserId!, series.Id, series.GoogleEventId, "Update", oldMasterPayload, cancellationToken);

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

            return newMasterEvent;
        }

        /// <summary>"All occurrences", or an ordinary event.</summary>
        /// <returns>The event itself.</returns>
        private async Task<Event> UpdateWholeEventAsync(
            Event existingEvent,
            UpdateEventCommand request,
            bool hasGoogle,
            CancellationToken cancellationToken)
        {
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

            return existingEvent;
        }

        /// <summary>
        /// The fields an edit sets on a single day. Never the repeat rule: a day of a series is
        /// not a series itself.
        /// </summary>
        private static void ApplyDayFields(Event day, UpdateEventCommand request)
        {
            day.Title = request.Title;
            day.StartTime = request.StartTime.ToUniversalTime();
            day.EndTime = request.EndTime.ToUniversalTime();
            day.HabitId = request.HabitId;
            day.CategoryId = request.CategoryId;
            day.TargetDuration = request.TargetDuration ?? (day.EndTime - day.StartTime);

            if (request.ReminderMinutesBefore != null)
            {
                day.ReminderMinutesBefore = ReminderOptions.Normalise(request.ReminderMinutesBefore);
            }
        }

        private async Task PromoteToGoogleAsync(Event series, Event day, string userId, CancellationToken cancellationToken)
        {
            AddExceptionDate(series, (day.ExceptionDate ?? day.StartTime).ToUniversalTime());
            await _eventRepository.UpdateAsync(series);

            await EnqueueMasterWithExceptionsAsync(userId, series, cancellationToken);
            await EnqueueExceptionInsertAsync(userId, day, cancellationToken);
        }

        private static void AddExceptionDate(Event series, DateTime occurrenceUtc)
        {
            var exceptionDateStr = occurrenceUtc.ToString("yyyy-MM-ddTHH:mm:ssZ");

            if (string.IsNullOrEmpty(series.RecurrenceExceptionDates))
            {
                series.RecurrenceExceptionDates = exceptionDateStr;
            }
            else if (!series.RecurrenceExceptionDates.Contains(exceptionDateStr))
            {
                series.RecurrenceExceptionDates += "," + exceptionDateStr;
            }
        }

        private Task EnqueueMasterWithExceptionsAsync(string userId, Event series, CancellationToken cancellationToken)
        {
            // Update for the master, to sync its EXDATE list.
            var payload = System.Text.Json.JsonSerializer.Serialize(new
            {
                Title = series.Title,
                StartTime = series.StartTime,
                EndTime = series.EndTime,
                RecurrenceRule = series.RecurrenceRule,
                RecurrenceExceptionDates = series.RecurrenceExceptionDates
            });
            return _outboxRepository.EnqueueAsync(userId, series.Id, series.GoogleEventId, "Update", payload, cancellationToken);
        }

        private Task EnqueueExceptionInsertAsync(string userId, Event day, CancellationToken cancellationToken)
        {
            var payload = System.Text.Json.JsonSerializer.Serialize(new
            {
                Title = day.Title,
                StartTime = day.StartTime,
                EndTime = day.EndTime,
                ParentEventId = day.ParentEventId,
                ExceptionDate = day.ExceptionDate
            });
            return _outboxRepository.EnqueueAsync(userId, day.Id, null, "Insert", payload, cancellationToken);
        }

        private Task EnqueueUpdateAsync(string userId, Event ev, CancellationToken cancellationToken)
        {
            var payload = System.Text.Json.JsonSerializer.Serialize(new
            {
                Title = ev.Title,
                StartTime = ev.StartTime,
                EndTime = ev.EndTime,
                RecurrenceRule = ev.RecurrenceRule
            });
            return _outboxRepository.EnqueueAsync(userId, ev.Id, ev.GoogleEventId, "Update", payload, cancellationToken);
        }
    }
}
