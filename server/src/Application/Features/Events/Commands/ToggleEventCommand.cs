using System;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;
using System.Linq;

namespace HabitTracker.Application.Features.Events.Commands
{
    public record ToggleEventCommand(Guid Id, bool IsCompleted, string UserId = "") : IRequest<bool>;

    public class ToggleEventCommandHandler : IRequestHandler<ToggleEventCommand, bool>
    {
        private readonly IEventRepository _eventRepository;
        private readonly IHabitRepository _habitRepository;
        private readonly IUserRepository _userRepository;
        private readonly ISquadRepository _squadRepository;

        public ToggleEventCommandHandler(
            IEventRepository eventRepository, 
            IHabitRepository habitRepository,
            IUserRepository userRepository,
            ISquadRepository squadRepository)
        {
            _eventRepository = eventRepository;
            _habitRepository = habitRepository;
            _userRepository = userRepository;
            _squadRepository = squadRepository;
        }

        public async Task<bool> Handle(ToggleEventCommand request, CancellationToken cancellationToken)
        {
            var evt = await _eventRepository.GetByIdAsync(request.Id);
            if (evt == null || evt.UserId != request.UserId) return false;

            var wasCompleted = evt.IsCompleted;
            var isCompleted = request.IsCompleted;

            if (wasCompleted == isCompleted)
            {
                return true;
            }

            int xpGained = 10;
            if (!string.IsNullOrEmpty(evt.UserId))
            {
                var allEvents = (await _eventRepository.GetEventsForUserAsync(evt.UserId)).ToList();

                if (isCompleted)
                {
                    // Toggle ON: calculate streak (treat evt as completed)
                    var eventInList = allEvents.FirstOrDefault(e => e.Id == evt.Id);
                    if (eventInList != null)
                    {
                        eventInList.IsCompleted = true;
                    }
                    else
                    {
                        allEvents.Add(new Event { StartTime = evt.StartTime, IsCompleted = true });
                    }
                    var completedEvents = allEvents.Where(e => e.IsCompleted);
                    int userStreak = CalculateActivityStreak(completedEvents);
                    xpGained = 10 + Math.Max(0, (userStreak - 1) * 2);

                    var user = await _userRepository.GetByIdAsync(evt.UserId);
                    if (user != null)
                    {
                        user.TotalXP += xpGained;
                        await _userRepository.UpdateAsync(user);

                        var squads = await _squadRepository.GetSquadsByUserIdAsync(user.Id);
                        foreach (var squad in squads)
                        {
                            var membership = await _squadRepository.GetMembershipAsync(squad.Id, user.Id);
                            if (membership != null && membership.XpContributionEnabled && membership.IsApproved)
                            {
                                squad.TotalSquadXP += xpGained;
                                await _squadRepository.UpdateAsync(squad);
                            }
                        }
                    }
                }
                else
                {
                    // Toggle OFF: calculate streak before untoggling (treat evt as completed)
                    var eventInList = allEvents.FirstOrDefault(e => e.Id == evt.Id);
                    if (eventInList != null)
                    {
                        eventInList.IsCompleted = true;
                    }
                    var completedEvents = allEvents.Where(e => e.IsCompleted);
                    int userStreak = CalculateActivityStreak(completedEvents);
                    xpGained = 10 + Math.Max(0, (userStreak - 1) * 2);

                    var user = await _userRepository.GetByIdAsync(evt.UserId);
                    if (user != null)
                    {
                        user.TotalXP = Math.Max(0, user.TotalXP - xpGained);
                        await _userRepository.UpdateAsync(user);

                        var squads = await _squadRepository.GetSquadsByUserIdAsync(user.Id);
                        foreach (var squad in squads)
                        {
                            var membership = await _squadRepository.GetMembershipAsync(squad.Id, user.Id);
                            if (membership != null && membership.XpContributionEnabled && membership.IsApproved)
                            {
                                squad.TotalSquadXP = Math.Max(0, squad.TotalSquadXP - xpGained);
                                await _squadRepository.UpdateAsync(squad);
                            }
                        }
                    }
                }
            }

            // Perform DB update
            evt.IsCompleted = isCompleted;
            await _eventRepository.UpdateAsync(evt);

            // Recalculate streaks for the associated habit (if any)
            if (Guid.TryParse(evt.HabitId, out Guid habitId))
            {
                var habit = await _habitRepository.GetByIdAsync(habitId);
                if (habit != null)
                {
                    await RecalculateStreaks(habit);
                    await _habitRepository.UpdateAsync(habit);
                }
            }

            return true;
        }

        private int CalculateActivityStreak(IEnumerable<Event> completedEvents)
        {
            if (!completedEvents.Any()) return 0;

            var completionDates = completedEvents
                .Select(e => ToLocalTimeUtc7(e.StartTime).Date)
                .Distinct()
                .OrderBy(d => d)
                .ToList();

            int currentStreak = 0;
            int tempStreak = 0;
            DateTime? previousDate = null;

            foreach (var date in completionDates)
            {
                if (previousDate == null)
                {
                    tempStreak = 1;
                }
                else
                {
                    if (date == previousDate.Value.AddDays(1))
                    {
                        tempStreak++;
                    }
                    else
                    {
                        tempStreak = 1;
                    }
                }
                previousDate = date;
            }

            var today = ToLocalTimeUtc7(DateTime.UtcNow).Date;
            if (previousDate.HasValue && (previousDate.Value == today || previousDate.Value == today.AddDays(-1)))
            {
                currentStreak = tempStreak;
            }
            else
            {
                currentStreak = 0;
            }

            return currentStreak;
        }

        private static DateTime ToLocalTimeUtc7(DateTime dt)
        {
            if (dt.Kind == DateTimeKind.Utc) return dt.AddHours(7);
            if (dt.Kind == DateTimeKind.Local) return dt.ToUniversalTime().AddHours(7);
            return DateTime.SpecifyKind(dt, DateTimeKind.Utc).AddHours(7);
        }

        private async Task RecalculateStreaks(Habit habit)
        {
            var allEvents = await _eventRepository.GetAllAsync();
            var completedEvents = allEvents
                .Where(e => e.IsCompleted && string.Equals(e.HabitId, habit.Id.ToString(), StringComparison.OrdinalIgnoreCase))
                .OrderBy(e => e.StartTime)
                .ToList();

            if (!completedEvents.Any())
            {
                habit.CurrentStreak = 0;
                return;
            }

            var completionDates = completedEvents
                .Select(e => ToLocalTimeUtc7(e.StartTime).Date)
                .Distinct()
                .OrderBy(d => d)
                .ToList();

            int currentStreak = 0;
            int longestStreak = 0;
            int tempStreak = 0;
            DateTime? previousDate = null;

            foreach (var date in completionDates)
            {
                if (previousDate == null)
                {
                    tempStreak = 1;
                }
                else
                {
                    if (date == previousDate.Value.AddDays(1))
                    {
                        tempStreak++;
                    }
                    else
                    {
                        if (tempStreak > longestStreak) longestStreak = tempStreak;
                        tempStreak = 1;
                    }
                }
                previousDate = date;
            }

            if (tempStreak > longestStreak) longestStreak = tempStreak;

            var today = ToLocalTimeUtc7(DateTime.UtcNow).Date;
            if (previousDate.HasValue && (previousDate.Value == today || previousDate.Value == today.AddDays(-1)))
            {
                currentStreak = tempStreak;
            }
            else
            {
                currentStreak = 0;
            }

            habit.CurrentStreak = currentStreak;
            habit.LongestStreak = Math.Max(habit.LongestStreak, longestStreak);
        }
    }
}
