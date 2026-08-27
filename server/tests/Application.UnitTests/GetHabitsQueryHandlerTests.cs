using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Application.Features.Habits.Queries;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using Moq;
using Xunit;

namespace HabitTracker.Application.Tests
{
    public class GetHabitsQueryHandlerTests
    {
        [Fact]
        public async Task Handle_ShouldReturnAllHabits()
        {
            // Arrange
            var mockRepo = new Mock<IHabitRepository>();
            var habits = new List<Habit>
            {
                new Habit { Id = Guid.NewGuid(), Name = "Habit 1" },
                new Habit { Id = Guid.NewGuid(), Name = "Habit 2" }
            };
            
            mockRepo.Setup(r => r.GetAllAsync()).ReturnsAsync(habits);

            var handler = new GetHabitsQueryHandler(mockRepo.Object);
            var query = new GetHabitsQuery();

            // Act
            var result = await handler.Handle(query, CancellationToken.None);

            // Assert
            result.Should().NotBeNull();
            result.Count().Should().Be(2);
            result.Select(h => h.Name).Should().Contain(new[] { "Habit 1", "Habit 2" });
            
            mockRepo.Verify(r => r.GetAllAsync(), Times.Once);
        }
    }
}
