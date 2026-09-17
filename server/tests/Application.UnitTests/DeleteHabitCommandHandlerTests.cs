using System;
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
    public class DeleteHabitCommandHandlerTests
    {
        [Fact]
        public async Task Handle_ShouldDeleteHabit_WhenHabitExistsAndUserOwnsIt()
        {
            // Arrange
            var mockRepo = new Mock<IHabitRepository>();
            var habitId = Guid.NewGuid();
            var userId = "user-123";
            var habit = new Habit
            {
                Id = habitId,
                Name = "Morning Run",
                UserId = userId
            };

            mockRepo.Setup(r => r.GetByIdAsync(habitId))
                .ReturnsAsync(habit);

            mockRepo.Setup(r => r.DeleteAsync(habitId))
                .Returns(Task.CompletedTask);

            var handler = new DeleteHabitCommandHandler(mockRepo.Object);
            var command = new DeleteHabitCommand
            {
                Id = habitId,
                UserId = userId
            };

            // Act
            var result = await handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().BeTrue();
            mockRepo.Verify(r => r.DeleteAsync(habitId), Times.Once);
        }

        [Fact]
        public async Task Handle_ShouldReturnFalse_WhenHabitDoesNotExist()
        {
            // Arrange
            var mockRepo = new Mock<IHabitRepository>();
            mockRepo.Setup(r => r.GetByIdAsync(It.IsAny<Guid>()))
                .ReturnsAsync((Habit?)null);

            var handler = new DeleteHabitCommandHandler(mockRepo.Object);
            var command = new DeleteHabitCommand
            {
                Id = Guid.NewGuid(),
                UserId = "user-123"
            };

            // Act
            var result = await handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().BeFalse();
            mockRepo.Verify(r => r.DeleteAsync(It.IsAny<Guid>()), Times.Never);
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
                Name = "Morning Run",
                UserId = "other-user"
            };

            mockRepo.Setup(r => r.GetByIdAsync(habitId))
                .ReturnsAsync(habit);

            var handler = new DeleteHabitCommandHandler(mockRepo.Object);
            var command = new DeleteHabitCommand
            {
                Id = habitId,
                UserId = "user-123"
            };

            // Act
            var result = await handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().BeFalse();
            mockRepo.Verify(r => r.DeleteAsync(It.IsAny<Guid>()), Times.Never);
        }
    }
}
