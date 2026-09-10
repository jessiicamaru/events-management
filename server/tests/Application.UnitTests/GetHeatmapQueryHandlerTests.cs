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
        [Fact]
        public async Task Handle_ShouldReturnGroupedHeatmapData()
        {
            // Arrange
            var mockRepo = new Mock<IEventRepository>();
            var today = DateTime.UtcNow.Date;

            var events = new List<Event>
            {
                new Event { Id = Guid.NewGuid(), IsCompleted = true, StartTime = today },
                new Event { Id = Guid.NewGuid(), IsCompleted = true, StartTime = today.AddHours(2) },
                new Event { Id = Guid.NewGuid(), IsCompleted = false, StartTime = today.AddHours(4) }, // Should be ignored
                new Event { Id = Guid.NewGuid(), IsCompleted = true, StartTime = today.AddDays(-1) }
            };

            mockRepo.Setup(r => r.GetAllAsync()).ReturnsAsync(events);

            var handler = new GetHeatmapQueryHandler(mockRepo.Object);
            var query = new GetHeatmapQuery();

            // Act
            var result = await handler.Handle(query, CancellationToken.None);

            // Assert
            result.Should().NotBeNull();
            result.Count.Should().Be(2);

            result[0].Date.Should().Be(today.AddDays(-1));
            result[0].Count.Should().Be(1);

            result[1].Date.Should().Be(today);
            result[1].Count.Should().Be(2);
        }
    }
}
