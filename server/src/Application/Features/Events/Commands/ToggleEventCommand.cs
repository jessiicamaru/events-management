using System;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;
using System.Linq;

namespace HabitTracker.Application.Features.Events.Commands
{
    public record ToggleEventCommand(Guid Id, bool IsCompleted) : IRequest<bool>;

    public class ToggleEventCommandHandler : IRequestHandler<ToggleEventCommand, bool>
    {
        private readonly IEventRepository _eventRepository;
        private readonly IHabitRepository _habitRepository;

        public ToggleEventCommandHandler(IEventRepository eventRepository, IHabitRepository habitRepository)
        {
            _eventRepository = eventRepository;
            _habitRepository = habitRepository;
        }

        public async Task<bool> Handle(ToggleEventCommand request, CancellationToken cancellationToken)
        {
            var evt = await _eventRepository.GetByIdAsync(request.Id);
            if (evt == null) return false;

            evt.IsCompleted = request.IsCompleted;
            await _eventRepository.UpdateAsync(evt);
            
            // Recalculate streaks for the associated habit
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

        private async Task RecalculateStreaks(Habit habit)
        {
            var allEvents = await _eventRepository.GetAllAsync();
            var completedEvents = allEvents
                .Where(e => e.HabitId == habit.Id.ToString() && e.IsCompleted)
                .OrderBy(e => e.StartTime)
                .ToList();

            if (!completedEvents.Any())
            {
                habit.CurrentStreak = 0;
                return;
            }

            var completionDates = completedEvents
                .Select(e => e.StartTime.Date)
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

            var today = DateTime.UtcNow.Date;
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
