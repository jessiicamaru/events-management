using System;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;
using System.Linq;

namespace HabitTracker.Application.Features.Events.Commands
{
    public record CompleteEventSessionRequest(TimeSpan ActualDuration, bool UpdateCalendar = false);

    public class CompleteEventSessionCommand : IRequest<bool>
    {
        public Guid EventId { get; set; }
        public TimeSpan ActualDuration { get; set; }
        public bool UpdateCalendar { get; set; }
        public string UserId { get; set; } = string.Empty;
    }

    public class CompleteEventSessionCommandHandler : IRequestHandler<CompleteEventSessionCommand, bool>
    {
        private readonly IEventRepository _eventRepository;
        private readonly IHabitRepository _habitRepository;
        private readonly IUserRepository _userRepository;
        private readonly ISquadRepository _squadRepository;

        public CompleteEventSessionCommandHandler(
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

        public async Task<bool> Handle(CompleteEventSessionCommand request, CancellationToken cancellationToken)
        {
            var ev = await _eventRepository.GetByIdAsync(request.EventId);
            if (ev == null || ev.UserId != request.UserId)
            {
                return false;
            }

            var wasCompleted = ev.IsCompleted;
            ev.IsCompleted = true;
            ev.ActualDuration = request.ActualDuration;

            if (request.UpdateCalendar)
            {
                var duration = request.ActualDuration < TimeSpan.FromMinutes(15) 
                    ? TimeSpan.FromMinutes(15) 
                    : request.ActualDuration;
                ev.EndTime = ev.StartTime.Add(duration);
            }

            await _eventRepository.UpdateAsync(ev);

            if (!wasCompleted)
            {
                // Recalculate streaks for the associated habit (if any)
                if (Guid.TryParse(ev.HabitId, out Guid habitId))
                {
                    var habit = await _habitRepository.GetByIdAsync(habitId);
                    if (habit != null)
                    {
                        await RecalculateStreaks(habit);
                        await _habitRepository.UpdateAsync(habit);
                    }
                }

                int xpGained = 10;
                // Calculate XP based on overall user activity streak
                if (!string.IsNullOrEmpty(ev.UserId))
                {
                    var allEvents = await _eventRepository.GetEventsForUserAsync(ev.UserId);
                    var completedEvents = allEvents.Where(e => e.IsCompleted);
                    int userStreak = CalculateActivityStreak(completedEvents);
                    xpGained = 10 + Math.Max(0, (userStreak - 1) * 2);

                    var user = await _userRepository.GetByIdAsync(ev.UserId);
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
