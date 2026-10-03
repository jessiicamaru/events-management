using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Application.Features.Analytics.Queries.GetHeatmap;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using Moq;
using Xunit;

namespace HabitTracker.Application.Tests
{
    public class GetHeatmapQueryHandlerTests
    {
        private const string UserId = "user123";

        [Fact]
        public async Task Handle_ShouldReturnGroupedHeatmapData()
        {
            // Arrange
            var mockRepo = new Mock<IEventRepository>();
            var today = DateTime.UtcNow.Date;

            var events = new List<Event>
            {
                new Event { Id = Guid.NewGuid(), UserId = UserId, IsCompleted = true, StartTime = today },
                new Event { Id = Guid.NewGuid(), UserId = UserId, IsCompleted = true, StartTime = today.AddHours(2) },
                new Event { Id = Guid.NewGuid(), UserId = UserId, IsCompleted = true, StartTime = today.AddDays(-1) }
            };

            mockRepo.Setup(r => r.GetCompletedEventsForUserAsync(UserId)).ReturnsAsync(events);

            var handler = new GetHeatmapQueryHandler(mockRepo.Object);

            // Act
            var result = await handler.Handle(new GetHeatmapQuery(UserId), CancellationToken.None);

            // Assert
            result.Should().NotBeNull();
            result.Count.Should().Be(2);

            result[0].Date.Should().Be(today.AddDays(-1));
            result[0].Count.Should().Be(1);

            result[1].Date.Should().Be(today);
            result[1].Count.Should().Be(2);
        }

        [Fact]
        public async Task Handle_ShouldOnlyReadTheRequestingUsersEvents()
        {
            // The heatmap used to read every event in the table, so one user's heatmap showed
            // the whole user base's activity. It must ask only for its own user's events.
            var mockRepo = new Mock<IEventRepository>();
            mockRepo.Setup(r => r.GetCompletedEventsForUserAsync(UserId)).ReturnsAsync(new List<Event>());

            var handler = new GetHeatmapQueryHandler(mockRepo.Object);

            await handler.Handle(new GetHeatmapQuery(UserId), CancellationToken.None);

            mockRepo.Verify(r => r.GetCompletedEventsForUserAsync(UserId), Times.Once);
            mockRepo.Verify(r => r.GetCompletedEventsForUserAsync(It.Is<string>(id => id != UserId)), Times.Never);
        }

        [Fact]
        public async Task Handle_ShouldThrow_WhenUserIdIsMissing()
        {
            var mockRepo = new Mock<IEventRepository>();
            var handler = new GetHeatmapQueryHandler(mockRepo.Object);

            var act = async () => await handler.Handle(new GetHeatmapQuery(string.Empty), CancellationToken.None);

            await act.Should().ThrowAsync<ArgumentException>();
            mockRepo.Verify(r => r.GetCompletedEventsForUserAsync(It.IsAny<string>()), Times.Never);
        }
    }
}
