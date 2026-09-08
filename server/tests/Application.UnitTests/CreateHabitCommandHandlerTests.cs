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

            var handler = new CreateHabitCommandHandler(mockRepo.Object);

            var command = new CreateHabitCommand
            {
                Name = "Daily Workout",
                TargetDays = new List<int> { 1, 3, 5 }
            };

            // Act
            var result = await handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().NotBeEmpty();
            savedHabit.Should().NotBeNull();
            savedHabit!.Name.Should().Be("Daily Workout");
            savedHabit.TargetDays.Should().BeEquivalentTo(new[] { 1, 3, 5 });
            
            // "Workout" should be categorized as Health by our mock AI logic
            savedHabit.Category.Should().Be("Health");
            
            mockRepo.Verify(r => r.AddAsync(It.IsAny<Habit>()), Times.Once);
        }
    }
}
