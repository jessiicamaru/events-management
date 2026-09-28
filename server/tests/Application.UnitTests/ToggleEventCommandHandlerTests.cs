using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Application.Features.Events.Commands;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using Moq;
using Xunit;

namespace HabitTracker.Application.Tests
{
    public class ToggleEventCommandHandlerTests
    {
        private readonly Mock<IEventRepository> _mockEventRepo;
        private readonly Mock<IHabitRepository> _mockHabitRepo;
        private readonly Mock<IUserRepository> _mockUserRepo;
        private readonly Mock<ISquadRepository> _mockSquadRepo;
        private readonly ToggleEventCommandHandler _handler;

        public ToggleEventCommandHandlerTests()
        {
            _mockEventRepo = new Mock<IEventRepository>();
            _mockHabitRepo = new Mock<IHabitRepository>();
            _mockUserRepo = new Mock<IUserRepository>();
            _mockSquadRepo = new Mock<ISquadRepository>();

            _handler = new ToggleEventCommandHandler(
                _mockEventRepo.Object,
                _mockHabitRepo.Object,
                _mockUserRepo.Object,
                _mockSquadRepo.Object);
        }

        [Fact]
        public async Task Handle_ShouldToggleEventAndRecalculateStreaksAndAwardXP()
        {
            // Arrange
            var habitId = Guid.NewGuid();
            var eventId = Guid.NewGuid();
            var userId = "user123";

            var habit = new Habit
            {
                Id = habitId,
                CurrentStreak = 0,
                LongestStreak = 0
            };

            var evt = new Event
            {
                Id = eventId,
                HabitId = habitId.ToString(),
                IsCompleted = false,
                StartTime = DateTime.UtcNow.AddDays(-1),
                UserId = userId
            };

            var eventsList = new List<Event>
            {
                new Event { Id = Guid.NewGuid(), HabitId = habitId.ToString(), IsCompleted = true, StartTime = DateTime.UtcNow.AddDays(-2), UserId = userId },
                evt
            };

            var user = new ApplicationUser { Id = userId, TotalXP = 50 };
            var squadId = Guid.NewGuid();
            var squad = new Squad { Id = squadId, TotalSquadXP = 100 };
            var membership = new SquadMember { SquadId = squadId, UserId = userId, IsApproved = true, XpContributionEnabled = true };

            _mockEventRepo.Setup(r => r.GetByIdAsync(eventId)).ReturnsAsync(evt);
            _mockEventRepo.Setup(r => r.GetAllAsync()).ReturnsAsync(eventsList);
            _mockEventRepo.Setup(r => r.GetEventsForUserAsync(userId)).ReturnsAsync(eventsList);
            _mockHabitRepo.Setup(r => r.GetByIdAsync(habitId)).ReturnsAsync(habit);
            _mockUserRepo.Setup(r => r.GetByIdAsync(userId)).ReturnsAsync(user);
            _mockSquadRepo.Setup(r => r.GetSquadsByUserIdAsync(userId)).ReturnsAsync(new List<Squad> { squad });
            _mockSquadRepo.Setup(r => r.GetMembershipAsync(squadId, userId)).ReturnsAsync(membership);

            var command = new ToggleEventCommand(eventId, true, userId);

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().BeTrue();
            evt.IsCompleted.Should().BeTrue();
            
            // Streaks should be 2 because we have completions on day -2 and day -1
            habit.CurrentStreak.Should().Be(2);
            habit.LongestStreak.Should().Be(2);

            // XP should be awarded: base 10 + (2-1)*2 = 12 XP
            user.TotalXP.Should().Be(62); // 50 + 12
            squad.TotalSquadXP.Should().Be(112); // 100 + 12

            _mockEventRepo.Verify(r => r.UpdateAsync(evt), Times.Once);
            _mockHabitRepo.Verify(r => r.UpdateAsync(habit), Times.Once);
            _mockUserRepo.Verify(r => r.UpdateAsync(user), Times.Once);
            _mockSquadRepo.Verify(r => r.UpdateAsync(squad), Times.Once);
        }

        [Fact]
        public async Task Handle_ShouldDeductXP_WhenToggleOff()
        {
            // Arrange
            var habitId = Guid.NewGuid();
            var eventId = Guid.NewGuid();
            var userId = "user123";

            var habit = new Habit
            {
                Id = habitId,
                CurrentStreak = 2,
                LongestStreak = 2
            };

            var evt = new Event
            {
                Id = eventId,
                HabitId = habitId.ToString(),
                IsCompleted = true, // Currently completed
                StartTime = DateTime.UtcNow.AddDays(-1),
                UserId = userId
            };

            var eventsList = new List<Event>
            {
                new Event { Id = Guid.NewGuid(), HabitId = habitId.ToString(), IsCompleted = true, StartTime = DateTime.UtcNow.AddDays(-2), UserId = userId },
                evt
            };

            var user = new ApplicationUser { Id = userId, TotalXP = 62 };
            var squadId = Guid.NewGuid();
            var squad = new Squad { Id = squadId, TotalSquadXP = 112 };
            var membership = new SquadMember { SquadId = squadId, UserId = userId, IsApproved = true, XpContributionEnabled = true };

            _mockEventRepo.Setup(r => r.GetByIdAsync(eventId)).ReturnsAsync(evt);
            _mockEventRepo.Setup(r => r.GetAllAsync()).ReturnsAsync(eventsList);
            _mockEventRepo.Setup(r => r.GetEventsForUserAsync(userId)).ReturnsAsync(eventsList);
            _mockHabitRepo.Setup(r => r.GetByIdAsync(habitId)).ReturnsAsync(habit);
            _mockUserRepo.Setup(r => r.GetByIdAsync(userId)).ReturnsAsync(user);
            _mockSquadRepo.Setup(r => r.GetSquadsByUserIdAsync(userId)).ReturnsAsync(new List<Squad> { squad });
            _mockSquadRepo.Setup(r => r.GetMembershipAsync(squadId, userId)).ReturnsAsync(membership);

            var command = new ToggleEventCommand(eventId, false, userId); // Toggle OFF

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().BeTrue();
            evt.IsCompleted.Should().BeFalse();
            
            // Streak should recalculate (without this event, only Day -2 remains completed). 
            // So streak drops to 1, and since Day -2 is older than yesterday, it resets to 0.
            habit.CurrentStreak.Should().Be(0);

            // XP should be deducted based on the streak BEFORE recalculation (which was 2 -> 12 XP)
            user.TotalXP.Should().Be(50); // 62 - 12
            squad.TotalSquadXP.Should().Be(100); // 112 - 12

            _mockEventRepo.Verify(r => r.UpdateAsync(evt), Times.Once);
            _mockHabitRepo.Verify(r => r.UpdateAsync(habit), Times.Once);
            _mockUserRepo.Verify(r => r.UpdateAsync(user), Times.Once);
            _mockSquadRepo.Verify(r => r.UpdateAsync(squad), Times.Once);
        }

        [Fact]
        public async Task Handle_ShouldReturnFalse_WhenEventNotFound()
        {
            // Arrange
            _mockEventRepo.Setup(r => r.GetByIdAsync(It.IsAny<Guid>())).ReturnsAsync((Event?)null);

            var command = new ToggleEventCommand(Guid.NewGuid(), true, "user123");

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().BeFalse();
            _mockEventRepo.Verify(r => r.UpdateAsync(It.IsAny<Event>()), Times.Never);
        }

        [Fact]
        public async Task Handle_ShouldReturnFalse_WhenUserIdMismatch()
        {
            // Arrange
            var eventId = Guid.NewGuid();
            var evt = new Event
            {
                Id = eventId,
                UserId = "user123",
                IsCompleted = false
            };

            _mockEventRepo.Setup(r => r.GetByIdAsync(eventId)).ReturnsAsync(evt);

            var command = new ToggleEventCommand(eventId, true, "different_user");

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().BeFalse();
            _mockEventRepo.Verify(r => r.UpdateAsync(It.IsAny<Event>()), Times.Never);
        }

        [Fact]
        public async Task Handle_ShouldCalculateStreakCorrectlyAcrossUtcDayBoundary_UsingUtcPlus7()
        {
            // Arrange
            var habitId = Guid.NewGuid();
            var eventId1 = Guid.NewGuid();
            var eventId2 = Guid.NewGuid();
            var userId = "user123";

            var habit = new Habit
            {
                Id = habitId,
                CurrentStreak = 0,
                LongestStreak = 0
            };

            // Calculate base date for the test relative to UtcNow
            var todayLocal = DateTime.UtcNow.AddHours(7).Date;
            var ev1Time = DateTime.SpecifyKind(todayLocal.AddDays(-1).AddHours(23).AddHours(-7), DateTimeKind.Utc);
            var ev2Time = DateTime.SpecifyKind(todayLocal.AddHours(6).AddHours(-7), DateTimeKind.Utc);

            // Event 1: Yesterday at 11:00 PM local (Yesterday at 4:00 PM UTC)
            var ev1 = new Event
            {
                Id = eventId1,
                HabitId = habitId.ToString(),
                IsCompleted = true,
                StartTime = ev1Time,
                UserId = userId
            };

            // Event 2: Today at 6:00 AM local (Yesterday at 11:00 PM UTC)
            var ev2 = new Event
            {
                Id = eventId2,
                HabitId = habitId.ToString(),
                IsCompleted = false, // To be completed now
                StartTime = ev2Time,
                UserId = userId
            };

            var eventsList = new List<Event> { ev1, ev2 };

            var user = new ApplicationUser { Id = userId, TotalXP = 50 };
            
            _mockEventRepo.Setup(r => r.GetByIdAsync(eventId2)).ReturnsAsync(ev2);
            _mockEventRepo.Setup(r => r.GetAllAsync()).ReturnsAsync(eventsList);
            _mockEventRepo.Setup(r => r.GetEventsForUserAsync(userId)).ReturnsAsync(eventsList);
            _mockHabitRepo.Setup(r => r.GetByIdAsync(habitId)).ReturnsAsync(habit);
            _mockUserRepo.Setup(r => r.GetByIdAsync(userId)).ReturnsAsync(user);
            _mockSquadRepo.Setup(r => r.GetSquadsByUserIdAsync(userId)).ReturnsAsync(new List<Squad>());

            var command = new ToggleEventCommand(eventId2, true, userId);

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().BeTrue();
            ev2.IsCompleted.Should().BeTrue();

            // Under UTC: Event 1 (July 24) and Event 2 (July 24) would have same date, streak remains 1.
            // Under UTC+7: Event 1 (July 24) and Event 2 (July 25) have different consecutive dates, streak becomes 2.
            habit.CurrentStreak.Should().Be(2);
            habit.LongestStreak.Should().Be(2);
        }
    }
}
