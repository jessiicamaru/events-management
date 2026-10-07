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
        private readonly IEventCategoryRepository _categoryRepository;
        private readonly ISquadRepository _squadRepository;

        public UpdateEventCommandHandler(
            IEventRepository eventRepository,
            IUserRepository userRepository,
            IGoogleCalendarOutboxRepository outboxRepository,
            OccurrenceMaterializer materializer,
            IEventCategoryRepository categoryRepository,
            ISquadRepository squadRepository)
        {
            _eventRepository = eventRepository;
            _userRepository = userRepository;
            _outboxRepository = outboxRepository;
            _materializer = materializer;
            _categoryRepository = categoryRepository;
            _squadRepository = squadRepository;
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

            // Every path below writes request.CategoryId somewhere — the day, the series, a new
            // series — so it is checked once, here. "Keeping" a category is exempt, but only when
            // the rows that will receive it already have it: see CategoryBeingReplacedAsync.
            var categoryBeingReplaced = await CategoryBeingReplacedAsync(existingEvent, request);
            if (!await EventCategoryAccess.CanAssignAsync(
                    request.CategoryId, categoryBeingReplaced, request.UserId,
                    _categoryRepository, _squadRepository))
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
                var splitDateUtc = (request.OriginalOccurrenceDate ?? request.StartTime).ToUniversalTime();
                await SplitSeriesAsync(existingEvent, request, splitDateUtc, hasGoogle, cancellationToken);
                return true;
            }

            // AllOccurrences or normal update
            var editedSlotUtc = (request.OriginalOccurrenceDate ?? existingEvent.StartTime).ToUniversalTime();
            await UpdateWholeEventAsync(existingEvent, request, editedSlotUtc, hasGoogle, cancellationToken);
            return true;
        }

        /// <summary>
        /// The category on the row this edit will actually overwrite — what "keeping the
        /// category" has to be measured against.
        /// </summary>
        /// <remarks>
        /// Usually the event itself. Not for a split-off day edited with "all occurrences" or
        /// "this and future": that writes the request's category onto the <b>series</b> (and,
        /// through <see cref="FollowSeriesAsync"/>, onto every local-only day). Measured against
        /// the day, a member who had left a squad could keep the squad's category on one day and
        /// spread it to the whole series — rows that never had it. Review round 3, N1.
        /// </remarks>
        private async Task<Guid?> CategoryBeingReplacedAsync(Event existingEvent, UpdateEventCommand request)
        {
            var spreadsToSeries = existingEvent.ParentEventId != null
                && (request.EditScope == AllOccurrences || request.EditScope == ThisAndFuture);

            if (!spreadsToSeries) return existingEvent.CategoryId;

            var parent = await _eventRepository.GetByIdAsync(existingEvent.ParentEventId!.Value);
            return parent != null && parent.UserId == request.UserId
                ? parent.CategoryId
                : existingEvent.CategoryId;
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
                var oldSlotUtc = (day.ExceptionDate ?? day.StartTime).ToUniversalTime();
                var dayWasEdited = RecurrenceExceptions.Contains(parent!, oldSlotUtc);
                var googleHasDay = hasGoogle
                    && await GoogleSyncGuard.GoogleKnowsAsync(day, _outboxRepository, cancellationToken);

                var seriesNowHoldingDay = request.EditScope == AllOccurrences
                    ? await UpdateWholeEventAsync(parent!, request, oldSlotUtc, hasGoogle, cancellationToken, excludeDayId: day.Id)
                    : await SplitSeriesAsync(parent!, request, oldSlotUtc, hasGoogle, cancellationToken, excludeDayId: day.Id);

                // Keep the day on the slot it was moved to, so it still stands in for the
                // series' occurrence there instead of showing next to it — unless another day
                // of the series already holds that slot (dragged onto a day that was ticked,
                // say). The database allows one event per day of a series, so that day keeps
                // it, and this one moves without taking over the slot.
                ApplyDayFields(day, request);
                var holder = await _eventRepository.GetOccurrenceChildAsync(seriesNowHoldingDay.Id, day.StartTime);
                var slotIsFree = holder == null || holder.Id == day.Id;
                if (slotIsFree)
                {
                    day.ParentEventId = seriesNowHoldingDay.Id;
                    day.ExceptionDate = day.StartTime;
                }
                await _eventRepository.UpdateAsync(day);

                if (slotIsFree && (dayWasEdited || googleHasDay))
                {
                    // Still an edited day on its new slot: the next series edit must leave its
                    // content alone (it follows the exception list), and Google must drop the
                    // series' own instance there.
                    RecurrenceExceptions.Add(seriesNowHoldingDay, day.StartTime);
                    await _eventRepository.UpdateAsync(seriesNowHoldingDay);
                }

                if (googleHasDay)
                {
                    // Google has this day as an event of its own. Before, only the series was
                    // pushed: the day stayed at its old time in Google while the series gained
                    // an instance on the same date, so Google showed two events and the app one.
                    await EnqueueMasterWithExceptionsAsync(request.UserId!, seriesNowHoldingDay, cancellationToken);
                    await EnqueueUpdateAsync(request.UserId!, day, cancellationToken);
                }

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

            RecurrenceExceptions.Add(series, occurrenceUtc);
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
            DateTime splitDate,
            bool hasGoogle,
            CancellationToken cancellationToken,
            Guid? excludeDayId = null)
        {
            // 1. Truncate current master recurrence rule to end before this occurrence
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

            // Days split off locally from this date on belong to the new series now. Left on
            // the old one, which ends before them, they would show next to the new series' days.
            await FollowSeriesAsync(series, newMasterEvent, splitDate, newMasterEvent.StartTime,
                excludeDayId, onlyFromUtc: splitDate);

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
            DateTime editedSlotUtc,
            bool hasGoogle,
            CancellationToken cancellationToken,
            Guid? excludeDayId = null)
        {
            var wasSeries = OccurrenceMaterializer.IsSeries(existingEvent);

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

            if (wasSeries)
            {
                await FollowSeriesAsync(existingEvent, existingEvent, editedSlotUtc, existingEvent.StartTime,
                    excludeDayId, onlyFromUtc: null);
            }

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
        /// Keeps the days split off <paramref name="from"/> only locally in step with a change
        /// to the series: same title, category, habit, reminders and length, the same shift in
        /// time of day, and, for "this and future", the new series as their parent.
        /// </summary>
        /// <remarks>
        /// <para>
        /// A day is split off just because a task was ticked or a session finished there, so it
        /// is still the series' day and must look like it. Left as a snapshot, moving the series
        /// from 07:00 to 08:00 left that day at 07:00 and no longer hid the series' own 08:00
        /// day: the day showed twice, with two reminders.
        /// </para>
        /// <para>
        /// Edited days are skipped: the user changed them on purpose. They are the ones in the
        /// series' exception list (<see cref="OccurrenceMaterializer.IsLocalOnlyDay"/>).
        /// A day the series no longer produces after the change (before its new start), or
        /// whose new slot another day of the series already holds, is left where it was, as
        /// history.
        /// </para>
        /// </remarks>
        private async Task FollowSeriesAsync(
            Event from,
            Event to,
            DateTime editedSlotUtc,
            DateTime newStart,
            Guid? excludeDayId,
            DateTime? onlyFromUtc)
        {
            var shift = TimeOfDayShift(editedSlotUtc, newStart.ToUniversalTime());
            var length = to.EndTime - to.StartTime;
            var seriesStartUtc = to.StartTime.ToUniversalTime().AddMinutes(-1);
            var days = (await _eventRepository.GetChildrenAsync(from.Id)).ToList();

            foreach (var day in days)
            {
                if (day.Id == excludeDayId) continue;
                if (!OccurrenceMaterializer.IsLocalOnlyDay(day, from)) continue;

                var slot = (day.ExceptionDate ?? day.StartTime).ToUniversalTime();
                if (onlyFromUtc != null && slot < onlyFromUtc.Value) continue;

                var newSlot = slot + shift;
                if (newSlot < seriesStartUtc) continue;

                // One event per day of a series (the database enforces it). A day already on the
                // new slot — an edited one, or one this loop has moved there — keeps it, and
                // this one stays where it was, as history.
                if (OccurrenceMaterializer.FindDay(days.Where(other => other.Id != day.Id), to, newSlot) != null) continue;

                day.ParentEventId = to.Id;
                day.StartTime = newSlot;
                day.EndTime = newSlot + length;
                day.ExceptionDate = newSlot;
                day.Title = to.Title;
                day.HabitId = to.HabitId;
                day.CategoryId = to.CategoryId;
                day.TargetDuration = to.TargetDuration;
                day.ReminderMinutesBefore = to.ReminderMinutesBefore.ToList();
                await _eventRepository.UpdateAsync(day);
            }
        }

        /// <summary>
        /// How far an edit moved the time of day, ignoring any change of date: dragging
        /// Wednesday 07:00 to Thursday 08:00 moves every day by one hour, not by 25.
        /// Kept within 12 hours either way, so a move across midnight goes the short way round.
        /// </summary>
        public static TimeSpan TimeOfDayShift(DateTime fromUtc, DateTime toUtc)
        {
            var shift = TimeSpan.FromTicks((toUtc - fromUtc).Ticks % TimeSpan.TicksPerDay);

            if (shift > TimeSpan.FromHours(12)) return shift - TimeSpan.FromDays(1);
            if (shift <= TimeSpan.FromHours(-12)) return shift + TimeSpan.FromDays(1);
            return shift;
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
            RecurrenceExceptions.Add(series, (day.ExceptionDate ?? day.StartTime).ToUniversalTime());
            await _eventRepository.UpdateAsync(series);

            await EnqueueMasterWithExceptionsAsync(userId, series, cancellationToken);
            await EnqueueExceptionInsertAsync(userId, day, cancellationToken);
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
