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
        [Fact]
        public async Task Handle_ShouldToggleEventAndRecalculateStreaks()
        {
            // Arrange
            var mockEventRepo = new Mock<IEventRepository>();
            var mockHabitRepo = new Mock<IHabitRepository>();

            var habitId = Guid.NewGuid();
            var eventId = Guid.NewGuid();

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
                StartTime = DateTime.UtcNow.AddDays(-1)
            };

            var eventsList = new List<Event>
            {
                new Event { Id = Guid.NewGuid(), HabitId = habitId.ToString(), IsCompleted = true, StartTime = DateTime.UtcNow.AddDays(-2) },
                evt
            };

            mockEventRepo.Setup(r => r.GetByIdAsync(eventId)).ReturnsAsync(evt);
            mockEventRepo.Setup(r => r.GetAllAsync()).ReturnsAsync(eventsList);
            mockHabitRepo.Setup(r => r.GetByIdAsync(habitId)).ReturnsAsync(habit);

            var handler = new ToggleEventCommandHandler(mockEventRepo.Object, mockHabitRepo.Object);
            var command = new ToggleEventCommand(eventId, true);

            // Act
            var result = await handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().BeTrue();
            evt.IsCompleted.Should().BeTrue();
            
            // Streaks should be 2 because we have completions on day -2 and day -1
            habit.CurrentStreak.Should().Be(2);
            habit.LongestStreak.Should().Be(2);

            mockEventRepo.Verify(r => r.UpdateAsync(evt), Times.Once);
            mockHabitRepo.Verify(r => r.UpdateAsync(habit), Times.Once);
        }

        [Fact]
        public async Task Handle_ShouldReturnFalse_WhenEventNotFound()
        {
            // Arrange
            var mockEventRepo = new Mock<IEventRepository>();
            var mockHabitRepo = new Mock<IHabitRepository>();

            mockEventRepo.Setup(r => r.GetByIdAsync(It.IsAny<Guid>())).ReturnsAsync((Event?)null);

            var handler = new ToggleEventCommandHandler(mockEventRepo.Object, mockHabitRepo.Object);
            var command = new ToggleEventCommand(Guid.NewGuid(), true);

            // Act
            var result = await handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().BeFalse();
            mockEventRepo.Verify(r => r.UpdateAsync(It.IsAny<Event>()), Times.Never);
        }
    }
}
