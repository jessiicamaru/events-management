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
    public class CreateHabitCommandHandlerTests
    {
        [Fact]
        public async Task Handle_ShouldAssignCorrectCategoryAndReturnId()
        {
            // Arrange
            var mockRepo = new Mock<IHabitRepository>();
            Habit? savedHabit = null;

            mockRepo.Setup(r => r.AddAsync(It.IsAny<Habit>()))
                .Callback<Habit>(h => savedHabit = h)
                .Returns(Task.CompletedTask);


            // Categories are validated now; these tests are about the fields being saved, so
            // any id they name resolves to a category the caller owns. Refusals are covered in
            // EventCategoryAuthorizationTests.
            var mockCategories = new Mock<IEventCategoryRepository>();
            mockCategories.Setup(r => r.GetByIdAsync(It.IsAny<Guid>()))
                .ReturnsAsync((Guid id) => new EventCategory { Id = id, UserId = "user-1" });

            var handler = new CreateHabitCommandHandler(
                mockRepo.Object, mockCategories.Object, new Mock<ISquadRepository>().Object);
            var categoryId = Guid.NewGuid();

            var command = new CreateHabitCommand
            {
                Name = "Daily Workout",
                TargetDays = new List<int> { 1, 3, 5 },
                CategoryId = categoryId,
                UserId = "user-1"
            };

            // Act
            var result = await handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().NotBeEmpty();
            savedHabit.Should().NotBeNull();
            savedHabit!.Name.Should().Be("Daily Workout");
            savedHabit.TargetDays.Should().BeEquivalentTo(new[] { 1, 3, 5 });

            savedHabit.CategoryId.Should().Be(categoryId);

            mockRepo.Verify(r => r.AddAsync(It.IsAny<Habit>()), Times.Once);
        }
    }
}
