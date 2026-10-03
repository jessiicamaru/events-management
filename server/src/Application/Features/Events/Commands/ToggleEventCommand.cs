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
    public record ToggleEventCommand(Guid Id, bool IsCompleted, string UserId) : IRequest<bool>;

    public class ToggleEventCommandHandler : IRequestHandler<ToggleEventCommand, bool>
    {
        private readonly IEventRepository _eventRepository;
        private readonly IHabitRepository _habitRepository;
        private readonly IUserRepository _userRepository;
        private readonly ISquadRepository _squadRepository;
        private readonly IUnitOfWork _unitOfWork;

        public ToggleEventCommandHandler(
            IEventRepository eventRepository,
            IHabitRepository habitRepository,
            IUserRepository userRepository,
            ISquadRepository squadRepository,
            IUnitOfWork unitOfWork)
        {
            _eventRepository = eventRepository;
            _habitRepository = habitRepository;
            _userRepository = userRepository;
            _squadRepository = squadRepository;
            _unitOfWork = unitOfWork;
        }

        public async Task<bool> Handle(ToggleEventCommand request, CancellationToken cancellationToken)
        {
            if (string.IsNullOrEmpty(request.UserId))
            {
                throw new ArgumentException("UserId is required.", nameof(request));
            }

            var evt = await _eventRepository.GetByIdAsync(request.Id);
            if (evt == null || evt.UserId != request.UserId) return false;

            if (evt.IsCompleted == request.IsCompleted)
            {
                return true;
            }

            // Every write below belongs to one logical operation: the event, the user's XP, each
            // squad's XP and the habit's streak. Without a transaction a failure part-way through
            // leaves XP granted for an event that is still not marked complete.
            return await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                var xpDelta = request.IsCompleted
                    ? await AwardXpAsync(evt)
                    : RefundXp(evt);

                evt.IsCompleted = request.IsCompleted;
                await _eventRepository.UpdateAsync(evt);

                if (xpDelta != 0 && !string.IsNullOrEmpty(evt.UserId))
                {
                    await ApplyXpAsync(evt.UserId, xpDelta);
                }

                // Recalculate streaks for the associated habit (if any)
                if (Guid.TryParse(evt.HabitId, out Guid habitId))
                {
                    var habit = await _habitRepository.GetByIdAsync(habitId);
                    if (habit != null)
                    {
                        await RecalculateStreaks(habit, evt, request.IsCompleted);
                        await _habitRepository.UpdateAsync(habit);
                    }
                }

                return true;
            }, cancellationToken);
        }

        /// <summary>
        /// Works out the award for completing <paramref name="evt"/> and records it on the event,
        /// so that un-completing it later refunds this exact amount rather than whatever the
        /// streak happens to be at that point.
        /// </summary>
        private async Task<int> AwardXpAsync(Event evt)
        {
            if (string.IsNullOrEmpty(evt.UserId))
            {
                return 0;
            }

            var completedEvents = (await _eventRepository.GetCompletedEventsForUserAsync(evt.UserId)).ToList();

            // The event is not completed in the database yet, so add it to the scratch list to
            // score the streak as it will stand once this toggle is applied.
            completedEvents.Add(new Event { StartTime = evt.StartTime, IsCompleted = true });

            var awarded = XpRules.ForStreak(CalculateActivityStreak(completedEvents));
            evt.AwardedXp = awarded;

            return awarded;
        }

        /// <summary>Gives back exactly what this event granted when it was completed.</summary>
        private static int RefundXp(Event evt)
        {
            var refund = evt.AwardedXp;
            evt.AwardedXp = 0;

            return -refund;
        }

        private async Task ApplyXpAsync(string userId, int xpDelta)
        {
            var user = await _userRepository.GetByIdAsync(userId);
            if (user == null) return;

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

        private int CalculateActivityStreak(IEnumerable<Event> completedEvents)
        {
            var completionDates = completedEvents
                .Select(e => ToLocalTimeUtc7(e.StartTime).Date)
                .Distinct()
                .OrderBy(d => d)
                .ToList();

            return StreakEndingToday(completionDates, out _);
        }

        private static DateTime ToLocalTimeUtc7(DateTime dt)
        {
            if (dt.Kind == DateTimeKind.Utc) return dt.AddHours(7);
            if (dt.Kind == DateTimeKind.Local) return dt.ToUniversalTime().AddHours(7);
            return DateTime.SpecifyKind(dt, DateTimeKind.Utc).AddHours(7);
        }

        /// <summary>
        /// Walks an ordered, de-duplicated list of completion dates and returns the run length
        /// that ends today or yesterday (0 otherwise). <paramref name="longestStreak"/> receives
        /// the longest run seen anywhere in the list.
        /// </summary>
        private static int StreakEndingToday(IReadOnlyList<DateTime> completionDates, out int longestStreak)
        {
            longestStreak = 0;

            if (completionDates.Count == 0)
            {
                return 0;
            }

            int tempStreak = 0;
            DateTime? previousDate = null;

            foreach (var date in completionDates)
            {
                if (previousDate == null || date != previousDate.Value.AddDays(1))
                {
                    tempStreak = 1;
                }
                else
                {
                    tempStreak++;
                }

                if (tempStreak > longestStreak) longestStreak = tempStreak;
                previousDate = date;
            }

            var today = ToLocalTimeUtc7(DateTime.UtcNow).Date;
            var endsRecently = previousDate.HasValue
                && (previousDate.Value == today || previousDate.Value == today.AddDays(-1));

            return endsRecently ? tempStreak : 0;
        }

        /// <summary>
        /// Recomputes the habit's streaks from its own completed events. The toggled event is
        /// folded in by hand because the repository read reflects the pre-toggle state.
        /// </summary>
        private async Task RecalculateStreaks(Habit habit, Event toggled, bool isNowCompleted)
        {
            var completedEvents = (await _eventRepository.GetCompletedEventsForHabitAsync(habit.Id)).ToList();

            var completionDates = completedEvents
                .Where(e => e.Id != toggled.Id)
                .Select(e => ToLocalTimeUtc7(e.StartTime).Date)
                .ToList();

            if (isNowCompleted)
            {
                completionDates.Add(ToLocalTimeUtc7(toggled.StartTime).Date);
            }

            var orderedDates = completionDates
                .Distinct()
                .OrderBy(d => d)
                .ToList();

            habit.CurrentStreak = StreakEndingToday(orderedDates, out var longestStreak);
            habit.LongestStreak = Math.Max(habit.LongestStreak, longestStreak);
        }
    }
}
