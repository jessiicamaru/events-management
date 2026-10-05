using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;

namespace HabitTracker.Application.Common
{
    /// <summary>
    /// Gives one day of a repeating series its own event, so that day can hold its own
    /// state.
    /// </summary>
    /// <remarks>
    /// <para>
    /// A repeating event is stored as one row, and every day of it shares that row's id.
    /// Anything stored against the id — its tasks, whether it is completed, the focus time —
    /// was therefore shared by every day: ticking a task on Monday ticked it on Tuesday, and
    /// finishing one session completed the whole series, which also hid it from "up next"
    /// and stopped its reminders.
    /// </para>
    /// <para>
    /// The model the app follows is a chain of templates: a habit's task list is copied into
    /// each event made from it, and adjusted there. A series is one more link in that chain —
    /// each day gets its own copy of the series' tasks, fresh and unticked, the first time
    /// the user does something to that day.
    /// </para>
    /// <para>
    /// The day becomes a child event (<see cref="Event.ParentEventId"/> +
    /// <see cref="Event.ExceptionDate"/>), the same shape "edit this occurrence" already
    /// produces, and the client already shows such a child in place of the series' day.
    /// </para>
    /// <para>
    /// It is <b>local only</b>. Nothing is sent to Google, and the series' exception dates
    /// are not touched: ticking a task on a work meeting must not change that meeting in the
    /// user's Google Calendar, and an exception date on the series would — the next push of
    /// the series would carry it, and Google would cancel that day. The day is sent to
    /// Google only if the user later edits it, like any other edited occurrence.
    /// </para>
    /// </remarks>
    public class OccurrenceMaterializer
    {
        private readonly IEventRepository _eventRepository;
        private readonly IEventTaskRepository _taskRepository;
        private readonly IUnitOfWork _unitOfWork;

        public OccurrenceMaterializer(
            IEventRepository eventRepository,
            IEventTaskRepository taskRepository,
            IUnitOfWork unitOfWork)
        {
            _eventRepository = eventRepository;
            _taskRepository = taskRepository;
            _unitOfWork = unitOfWork;
        }

        /// <summary>Whether <paramref name="ev"/> is a series row rather than a single event or a split-off day.</summary>
        public static bool IsSeries(Event ev) =>
            !string.IsNullOrEmpty(ev.RecurrenceRule) && ev.ParentEventId == null;

        /// <summary>
        /// The event standing for <paramref name="occurrenceStart"/> of <paramref name="series"/>:
        /// the existing child if the day was already split off, otherwise a new one with a
        /// copy of the series' tasks.
        /// </summary>
        /// <returns>
        /// Null when <paramref name="series"/> is not a series, or the date cannot be one of its
        /// days: before the series starts, after its UNTIL, or a day the user deleted.
        /// </returns>
        /// <remarks>
        /// Safe to call repeatedly for the same day, and concurrently: the second call finds
        /// the first call's child. The date is not checked against the full repeat rule — that needs a
        /// recurrence engine the server does not have — so a caller could split off a date the
        /// rule would never produce. Such a child is harmless: it shows as a one-off event.
        /// </remarks>
        public async Task<Event?> FindOrCreateAsync(
            Event series,
            DateTime occurrenceStart,
            CancellationToken cancellationToken = default)
        {
            if (!IsSeries(series)) return null;

            var startUtc = ToUtc(occurrenceStart);

            var existing = await _eventRepository.GetOccurrenceChildAsync(series.Id, startUtc);
            if (existing != null) return existing;

            if (!CouldBeOccurrence(series, startUtc)) return null;

            return await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                var child = new Event
                {
                    Id = Guid.NewGuid(),
                    Title = series.Title,
                    StartTime = startUtc,
                    EndTime = startUtc + (series.EndTime - series.StartTime),
                    HabitId = series.HabitId,
                    CategoryId = series.CategoryId,
                    TargetDuration = series.TargetDuration,
                    ReminderMinutesBefore = series.ReminderMinutesBefore.ToList(),
                    UserId = series.UserId,
                    ParentEventId = series.Id,
                    ExceptionDate = startUtc,
                    IsCompleted = false
                };

                // The lookup above and this add are two steps: a second request for the same
                // day (another device, or a ticked task racing a finished session) can add
                // its child in between. The database allows one, so the loser takes the
                // winner's child — with the winner's copy of the tasks — instead of a duplicate.
                if (!await _eventRepository.TryAddOccurrenceDayAsync(child))
                {
                    return await _eventRepository.GetOccurrenceChildAsync(series.Id, startUtc);
                }

                // The series' tasks are the template for each day. The copy starts unticked
                // whatever the template says: it is a new day.
                var template = await _taskRepository.GetByEventIdAsync(series.Id);
                foreach (var task in template.OrderBy(t => t.Order))
                {
                    await _taskRepository.AddAsync(new EventTask
                    {
                        Id = Guid.NewGuid(),
                        EventId = child.Id,
                        Title = task.Title,
                        Description = task.Description,
                        Order = task.Order,
                        Priority = task.Priority,
                        EstimatedMinutes = task.EstimatedMinutes,
                        IsCompleted = false
                    });
                }

                return child;
            }, cancellationToken);
        }

        /// <summary>
        /// Whether <paramref name="day"/> is a day of <paramref name="series"/> that was split off
        /// only locally — by a ticked task or a finished session — rather than edited.
        /// </summary>
        /// <remarks>
        /// Told apart by the series' exception list (<see cref="RecurrenceExceptions"/>): splitting
        /// a day off never adds it there, while editing, promoting or deleting a day always does.
        /// A local-only day is the series' day with some state attached, so it should keep
        /// following the series; an edited day keeps its own content.
        /// </remarks>
        public static bool IsLocalOnlyDay(Event day, Event series) =>
            day.ParentEventId == series.Id
            && !RecurrenceExceptions.Contains(series, day.ExceptionDate ?? day.StartTime);

        /// <summary>
        /// The local-only day of <paramref name="series"/> standing for
        /// <paramref name="occurrenceUtc"/>, if there is one.
        /// </summary>
        /// <remarks>
        /// <para>
        /// Used by the Google sync when Google reports its own version of that day, so the sync
        /// can adopt the local day rather than add a second one beside it — or remove it, if
        /// Google cancelled the day.
        /// </para>
        /// <para>
        /// A day with no <see cref="Event.GoogleEventId"/> is not necessarily local-only: an
        /// edited day waiting for its Insert looks the same. Only the exception list tells them
        /// apart, so it must be checked <b>before</b> the sync appends the date to it — otherwise
        /// a cancellation that Google sends back for an edit would delete the edited day.
        /// </para>
        /// </remarks>
        public static Event? FindLocalOnlyDay(IEnumerable<Event> events, Event series, DateTime occurrenceUtc) =>
            events.FirstOrDefault(e =>
                e.ParentEventId == series.Id
                && string.IsNullOrEmpty(e.GoogleEventId)
                && StandsFor(e, occurrenceUtc)
                && IsLocalOnlyDay(e, series));

        /// <summary>
        /// The event standing for <paramref name="occurrenceUtc"/> of <paramref name="series"/>,
        /// local-only or edited, if there is one. There is at most one: the database allows one
        /// event per day of a series.
        /// </summary>
        public static Event? FindDay(IEnumerable<Event> events, Event series, DateTime occurrenceUtc) =>
            events.FirstOrDefault(e => e.ParentEventId == series.Id && StandsFor(e, occurrenceUtc));

        /// <summary>
        /// Whether <paramref name="day"/> stands for the occurrence at <paramref name="occurrenceUtc"/>,
        /// to the minute — the precision the database's one-event-per-day rule and the client use.
        /// </summary>
        public static bool StandsFor(Event day, DateTime occurrenceUtc) =>
            day.ExceptionDate != null
            && TruncateToMinute(ToUtc(day.ExceptionDate.Value)) == TruncateToMinute(ToUtc(occurrenceUtc));

        private static bool CouldBeOccurrence(Event series, DateTime startUtc)
        {
            if (TruncateToMinute(startUtc) < TruncateToMinute(ToUtc(series.StartTime))) return false;

            var until = ParseUntil(series.RecurrenceRule!);
            if (until != null && startUtc > until) return false;

            // A date in the exception list was deleted, or has its own event already (found above).
            return !RecurrenceExceptions.Contains(series, startUtc);
        }

        private static DateTime? ParseUntil(string rule)
        {
            var part = rule.Replace("RRULE:", string.Empty)
                .Split(';')
                .FirstOrDefault(p => p.StartsWith("UNTIL=", StringComparison.OrdinalIgnoreCase));
            if (part == null) return null;

            var value = part["UNTIL=".Length..];
            string[] formats = { "yyyyMMdd'T'HHmmss'Z'", "yyyyMMdd'T'HHmmss", "yyyyMMdd" };

            return DateTime.TryParseExact(value, formats, CultureInfo.InvariantCulture,
                DateTimeStyles.AdjustToUniversal | DateTimeStyles.AssumeUniversal, out var until)
                // A date-only UNTIL includes that whole day.
                ? (value.Length == 8 ? until.AddDays(1).AddTicks(-1) : until)
                : null;
        }

        private static DateTime ToUtc(DateTime value) => RecurrenceExceptions.ToUtc(value);

        private static DateTime TruncateToMinute(DateTime value) => RecurrenceExceptions.TruncateToMinute(value);
    }
}
