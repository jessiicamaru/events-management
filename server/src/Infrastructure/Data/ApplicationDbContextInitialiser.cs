using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using HabitTracker.Domain.Entities;

namespace HabitTracker.Infrastructure.Data
{
    public class ApplicationDbContextInitialiser
    {
        private readonly ILogger<ApplicationDbContextInitialiser> _logger;
        private readonly ApplicationDbContext _context;

        public ApplicationDbContextInitialiser(ILogger<ApplicationDbContextInitialiser> logger, ApplicationDbContext context)
        {
            _logger = logger;
            _context = context;
        }

        public async Task InitialiseAsync()
        {
            try
            {
                await _context.Database.MigrateAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "An error occurred while initialising the database.");
                throw;
            }
        }

        public async Task SeedAsync()
        {
            try
            {
                await TrySeedAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "An error occurred while seeding the database.");
                throw;
            }
        }

        private async Task TrySeedAsync()
        {
            // Default data
            // Seed Mock Data if empty (Force clear for now)
            _context.Events.RemoveRange(_context.Events);
            _context.Habits.RemoveRange(_context.Habits);
            await _context.SaveChangesAsync();

            if (!_context.Habits.Any())
            {
                var habit1 = new Habit { Id = Guid.NewGuid(), Name = "Morning Run", Category = "Health", TargetDays = new List<int> { 1, 3, 5 } };
                var habit2 = new Habit { Id = Guid.NewGuid(), Name = "Read 10 pages", Category = "Learning", TargetDays = new List<int> { 1, 2, 3, 4, 5, 6, 7 } };
                var habit3 = new Habit { Id = Guid.NewGuid(), Name = "Team Standup", Category = "Work", TargetDays = new List<int> { 1, 2, 3, 4, 5 } };
                var habit4 = new Habit { Id = Guid.NewGuid(), Name = "Meditation", Category = "Wellness", TargetDays = new List<int> { 1, 3, 5, 7 } };
                var habit5 = new Habit { Id = Guid.NewGuid(), Name = "Gym Workout", Category = "Health", TargetDays = new List<int> { 2, 4, 6 } };
                var habit6 = new Habit { Id = Guid.NewGuid(), Name = "Deep Work", Category = "Work", TargetDays = new List<int> { 2, 4 } };
                
                _context.Habits.AddRange(habit1, habit2, habit3, habit4, habit5, habit6);

                // Add events spanning current week
                var today = DateTime.UtcNow.Date;
                var startOfWeek = today.AddDays(-(int)today.DayOfWeek + (int)DayOfWeek.Monday);
                
                var events = new List<Event>();
                var rand = new Random(42);

                for (int i = 0; i < 7; i++)
                {
                    var currentDay = startOfWeek.AddDays(i);
                    // Add Morning Run
                    if (habit1.TargetDays.Contains((int)currentDay.DayOfWeek == 0 ? 7 : (int)currentDay.DayOfWeek))
                        events.Add(new Event { Id = Guid.NewGuid(), Title = habit1.Name, HabitId = habit1.Id.ToString(), StartTime = currentDay.AddHours(6), EndTime = currentDay.AddHours(7), IsCompleted = rand.NextDouble() > 0.5 });
                    
                    // Add Standup
                    if (habit3.TargetDays.Contains((int)currentDay.DayOfWeek == 0 ? 7 : (int)currentDay.DayOfWeek))
                        events.Add(new Event { Id = Guid.NewGuid(), Title = habit3.Name, HabitId = habit3.Id.ToString(), StartTime = currentDay.AddHours(9), EndTime = currentDay.AddHours(9.5), IsCompleted = rand.NextDouble() > 0.2 });

                    // Add Deep Work
                    if (habit6.TargetDays.Contains((int)currentDay.DayOfWeek == 0 ? 7 : (int)currentDay.DayOfWeek))
                        events.Add(new Event { Id = Guid.NewGuid(), Title = habit6.Name, HabitId = habit6.Id.ToString(), StartTime = currentDay.AddHours(14), EndTime = currentDay.AddHours(16), IsCompleted = false });

                    // Add Reading
                    events.Add(new Event { Id = Guid.NewGuid(), Title = habit2.Name, HabitId = habit2.Id.ToString(), StartTime = currentDay.AddHours(20), EndTime = currentDay.AddHours(21), IsCompleted = currentDay < today });
                }

                _context.Events.AddRange(events);
                await _context.SaveChangesAsync();
            }
        }
    }
}
