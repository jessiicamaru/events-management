using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Application.Common;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;
using System.Linq;

namespace HabitTracker.Application.Features.Events.Commands
{
    /// <param name="OccurrenceStart">
    /// Required when the event is a repeating series: which day the session was for. That
    /// day is completed, not the series — see <see cref="OccurrenceMaterializer"/>.
    /// </param>
    public record CompleteEventSessionRequest(
        TimeSpan ActualDuration,
        bool UpdateCalendar = false,
        DateTime? OccurrenceStart = null);

    public class CompleteEventSessionCommand : IRequest<bool>
    {
        public Guid EventId { get; set; }
        public TimeSpan ActualDuration { get; set; }
        public bool UpdateCalendar { get; set; }
        public DateTime? OccurrenceStart { get; set; }
        public string UserId { get; set; } = string.Empty;
    }

    public class CompleteEventSessionCommandHandler : IRequestHandler<CompleteEventSessionCommand, bool>
    {
        /// <summary>A session shorter than this still books this much calendar time.</summary>
        private static readonly TimeSpan MinimumCalendarBlock = TimeSpan.FromMinutes(15);

        private readonly IEventRepository _eventRepository;
        private readonly IHabitRepository _habitRepository;
        private readonly IUserRepository _userRepository;
        private readonly ISquadRepository _squadRepository;
        private readonly IGoogleCalendarOutboxRepository _outboxRepository;
        private readonly IUnitOfWork _unitOfWork;
        private readonly OccurrenceMaterializer _materializer;

        public CompleteEventSessionCommandHandler(
            IEventRepository eventRepository,
            IHabitRepository habitRepository,
            IUserRepository userRepository,
            ISquadRepository squadRepository,
            IGoogleCalendarOutboxRepository outboxRepository,
            IUnitOfWork unitOfWork,
            OccurrenceMaterializer materializer)
        {
            _materializer = materializer;
            _eventRepository = eventRepository;
            _habitRepository = habitRepository;
            _userRepository = userRepository;
            _squadRepository = squadRepository;
            _outboxRepository = outboxRepository;
            _unitOfWork = unitOfWork;
        }

        public async Task<bool> Handle(CompleteEventSessionCommand request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrEmpty(request.UserId))
            {
                throw new ArgumentException("UserId is required.", nameof(request));
            }

            var target = await _eventRepository.GetByIdAsync(request.EventId);
            if (target == null || target.UserId != request.UserId)
            {
                return false;
            }

            // A series row is never completed: completing it completed every day at once,
            // hid the series from "up next" and stopped its reminders. The session was for
            // one day, so that day is split off and completed on its own.
            if (OccurrenceMaterializer.IsSeries(target) && request.OccurrenceStart == null)
            {
                return false;
            }

            // The event, the outbox row, the user's XP, squad XP and the habit streak are one
            // logical operation — see IUnitOfWork.
            return await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                var ev = OccurrenceMaterializer.IsSeries(target)
                    ? await _materializer.FindOrCreateAsync(target, request.OccurrenceStart!.Value, cancellationToken)
                    : target;
                if (ev == null) return false;

                var wasCompleted = ev.IsCompleted;

                ev.IsCompleted = true;
                ev.ActualDuration = request.ActualDuration;

                if (request.UpdateCalendar)
                {
                    var duration = request.ActualDuration < MinimumCalendarBlock
                        ? MinimumCalendarBlock
                        : request.ActualDuration;
                    ev.EndTime = ev.StartTime.Add(duration);
                }

                var user = await _userRepository.GetByIdAsync(request.UserId);

                if (!wasCompleted)
                {
                    // Record the award on the event so un-completing it later refunds this exact
                    // amount instead of recalculating from a streak that has since moved on.
                    ev.AwardedXp = XpRules.ForStreak(await CalculateActivityStreakAsync(ev));
                }

                await _eventRepository.UpdateAsync(ev);

                // Only when Google has the event. A day split off for this session was never
                // sent to Google, and an Update for it would fail in the sync worker.
                if (user != null && !string.IsNullOrEmpty(user.GoogleRefreshToken)
                    && await GoogleSyncGuard.GoogleKnowsAsync(ev, _outboxRepository, cancellationToken))
                {
                    var payload = System.Text.Json.JsonSerializer.Serialize(new
                    {
                        Title = ev.Title,
                        StartTime = ev.StartTime,
                        EndTime = ev.EndTime,
                        RecurrenceRule = ev.RecurrenceRule
                    });
                    await _outboxRepository.EnqueueAsync(request.UserId, ev.Id, ev.GoogleEventId, "Update", payload, cancellationToken);
                }

                if (!wasCompleted)
                {
                    if (Guid.TryParse(ev.HabitId, out Guid habitId))
                    {
                        var habit = await _habitRepository.GetByIdAsync(habitId);
                        if (habit != null)
                        {
                            await RecalculateStreaks(habit, ev);
                            await _habitRepository.UpdateAsync(habit);
                        }
                    }

                    if (user != null && ev.AwardedXp != 0)
                    {
                        await ApplyXpAsync(user, ev.AwardedXp);
                    }
                }

                return true;
            }, cancellationToken);
        }

        /// <summary>
        /// Scores the user's activity streak as it will stand once <paramref name="ev"/> counts
        /// as completed. The repository read still reflects the pre-completion state, so the
        /// event is folded into a scratch list rather than mutated in place.
        /// </summary>
        private async Task<int> CalculateActivityStreakAsync(Event ev)
        {
            if (string.IsNullOrEmpty(ev.UserId))
            {
                return 0;
            }

            var completedEvents = await _eventRepository.GetCompletedEventsForUserAsync(ev.UserId);

            var startTimes = completedEvents
                .Where(e => e.Id != ev.Id)
                .Select(e => e.StartTime)
                .Append(ev.StartTime);

            return StreakCalculator.FromStartTimes(startTimes).Current;
        }

        private async Task ApplyXpAsync(ApplicationUser user, int xpDelta)
        {
            user.TotalXP = Math.Max(0, user.TotalXP + xpDelta);
            await _userRepository.UpdateAsync(user);

            var squads = await _squadRepository.GetSquadsByUserIdAsync(user.Id);
            foreach (var squad in squads)
            {
                var membership = await _squadRepository.GetMembershipAsync(squad.Id, user.Id);
                if (membership != null && membership.XpContributionEnabled && membership.IsApproved)
                {
                    squad.TotalSquadXP = Math.Max(0, squad.TotalSquadXP + xpDelta);
                    await _squadRepository.UpdateAsync(squad);
                }
            }
        }

        private async Task RecalculateStreaks(Habit habit, Event completed)
        {
            var completedEvents = await _eventRepository.GetCompletedEventsForHabitAsync(habit.Id);

            var startTimes = completedEvents
                .Where(e => e.Id != completed.Id)
                .Select(e => e.StartTime)
                .Append(completed.StartTime);

            var streaks = StreakCalculator.FromStartTimes(startTimes);

            habit.CurrentStreak = streaks.Current;
            habit.LongestStreak = Math.Max(habit.LongestStreak, streaks.Longest);
        }
    }
}
