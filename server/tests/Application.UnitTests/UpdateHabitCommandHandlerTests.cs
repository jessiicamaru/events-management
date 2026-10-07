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
                CategoryId = Guid.NewGuid(),
                TargetDays = new List<int> { 1, 2 },
                UserId = userId
            };

            mockRepo.Setup(r => r.GetByIdAsync(habitId))
                .ReturnsAsync(habit);

            mockRepo.Setup(r => r.UpdateAsync(It.IsAny<Habit>()))
                .Returns(Task.CompletedTask);


            // Categories are validated now; these tests are about the fields being saved, so
            // any id they name resolves to a category the caller owns. Refusals are covered in
            // EventCategoryAuthorizationTests.
            var mockCategories = new Mock<IEventCategoryRepository>();
            mockCategories.Setup(r => r.GetByIdAsync(It.IsAny<Guid>()))
                .ReturnsAsync((Guid id) => new EventCategory { Id = id, UserId = userId });

            var handler = new UpdateHabitCommandHandler(
                mockRepo.Object, mockCategories.Object, new Mock<ISquadRepository>().Object);

            var command = new UpdateHabitCommand
            {
                Id = habitId,
                Name = "New Name",
                CategoryId = Guid.NewGuid(),
                TargetDays = new List<int> { 1, 2, 3 },
                UserId = userId
            };

            // Act
            var result = await handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().BeTrue();
            habit.Name.Should().Be("New Name");
            habit.CategoryId.Should().Be(command.CategoryId);
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

            // Refused before the category is ever looked at.
            var handler = new UpdateHabitCommandHandler(
                mockRepo.Object,
                new Mock<IEventCategoryRepository>().Object,
                new Mock<ISquadRepository>().Object);
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

            // Refused before the category is ever looked at.
            var handler = new UpdateHabitCommandHandler(
                mockRepo.Object,
                new Mock<IEventCategoryRepository>().Object,
                new Mock<ISquadRepository>().Object);
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
