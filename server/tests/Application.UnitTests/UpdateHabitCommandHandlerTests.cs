using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Application.Features.Habits.Commands;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using Moq;
using Xunit;

namespace HabitTracker.Application.Tests
{
    public class UpdateHabitCommandHandlerTests
    {
        [Fact]
        public async Task Handle_ShouldUpdateHabit_WhenHabitExistsAndUserOwnsIt()
        {
            // Arrange
            var mockRepo = new Mock<IHabitRepository>();
            var habitId = Guid.NewGuid();
            var userId = "user-123";
            var habit = new Habit
            {
                Id = habitId,
                Name = "Old Name",
                Category = "Learning",
                TargetDays = new List<int> { 1, 2 },
                UserId = userId
            };

            mockRepo.Setup(r => r.GetByIdAsync(habitId))
                .ReturnsAsync(habit);

            mockRepo.Setup(r => r.UpdateAsync(It.IsAny<Habit>()))
                .Returns(Task.CompletedTask);

            var handler = new UpdateHabitCommandHandler(mockRepo.Object);

            var command = new UpdateHabitCommand
            {
                Id = habitId,
                Name = "New Name",
                Category = "Health",
                TargetDays = new List<int> { 1, 2, 3 },
                UserId = userId
            };

            // Act
            var result = await handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().BeTrue();
            habit.Name.Should().Be("New Name");
            habit.Category.Should().Be("Health");
            habit.TargetDays.Should().BeEquivalentTo(new[] { 1, 2, 3 });
            mockRepo.Verify(r => r.UpdateAsync(habit), Times.Once);
        }

        [Fact]
        public async Task Handle_ShouldReturnFalse_WhenHabitDoesNotExist()
        {
            // Arrange
            var mockRepo = new Mock<IHabitRepository>();
            mockRepo.Setup(r => r.GetByIdAsync(It.IsAny<Guid>()))
                .ReturnsAsync((Habit?)null);

            var handler = new UpdateHabitCommandHandler(mockRepo.Object);
            var command = new UpdateHabitCommand
            {
                Id = Guid.NewGuid(),
                UserId = "user-123"
            };

            // Act
            var result = await handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().BeFalse();
            mockRepo.Verify(r => r.UpdateAsync(It.IsAny<Habit>()), Times.Never);
        }

        [Fact]
        public async Task Handle_ShouldReturnFalse_WhenUserDoesNotOwnHabit()
        {
            // Arrange
            var mockRepo = new Mock<IHabitRepository>();
            var habitId = Guid.NewGuid();
            var habit = new Habit
            {
                Id = habitId,
                Name = "Old Name",
                UserId = "other-user"
            };

            mockRepo.Setup(r => r.GetByIdAsync(habitId))
                .ReturnsAsync(habit);

            var handler = new UpdateHabitCommandHandler(mockRepo.Object);
            var command = new UpdateHabitCommand
            {
                Id = habitId,
                UserId = "user-123"
            };

            // Act
            var result = await handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().BeFalse();
            mockRepo.Verify(r => r.UpdateAsync(It.IsAny<Habit>()), Times.Never);
        }
    }
}
