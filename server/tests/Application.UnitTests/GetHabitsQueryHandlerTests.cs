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
        private const string UserId = "user123";

        [Fact]
        public async Task Handle_ShouldReturnOnlyTheRequestingUsersHabits()
        {
            // Arrange
            var mockRepo = new Mock<IHabitRepository>();
            var habits = new List<Habit>
            {
                new Habit { Id = Guid.NewGuid(), Name = "Habit 1", UserId = UserId },
                new Habit { Id = Guid.NewGuid(), Name = "Habit 2", UserId = UserId }
            };

            mockRepo.Setup(r => r.GetHabitsForUserAsync(UserId)).ReturnsAsync(habits);

            var handler = new GetHabitsQueryHandler(mockRepo.Object);
            var query = new GetHabitsQuery { UserId = UserId };

            // Act
            var result = await handler.Handle(query, CancellationToken.None);

            // Assert
            result.Should().NotBeNull();
            result.Count().Should().Be(2);
            result.Select(h => h.Name).Should().Contain(new[] { "Habit 1", "Habit 2" });

            mockRepo.Verify(r => r.GetHabitsForUserAsync(UserId), Times.Once);
        }

        [Fact]
        public async Task Handle_ShouldThrow_WhenUserIdIsMissing()
        {
            // An unset UserId used to fall back to every user's habits. Refusing is the safe
            // direction: a forgotten assignment must fail, not widen the query.
            var mockRepo = new Mock<IHabitRepository>();
            var handler = new GetHabitsQueryHandler(mockRepo.Object);

            var act = async () => await handler.Handle(new GetHabitsQuery(), CancellationToken.None);

            await act.Should().ThrowAsync<ArgumentException>();
            mockRepo.Verify(r => r.GetHabitsForUserAsync(It.IsAny<string>()), Times.Never);
        }
    }
}
