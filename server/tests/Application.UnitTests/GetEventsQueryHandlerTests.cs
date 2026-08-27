using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Application.Features.Events.Queries;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using Moq;
using Xunit;

namespace HabitTracker.Application.Tests
{
    public class GetEventsQueryHandlerTests
    {
        [Fact]
        public async Task Handle_ShouldReturnAllEvents()
        {
            // Arrange
            var mockRepo = new Mock<IEventRepository>();
            var events = new List<Event>
            {
                new Event { Id = Guid.NewGuid(), Title = "Event 1" },
                new Event { Id = Guid.NewGuid(), Title = "Event 2" }
            };
            
            mockRepo.Setup(r => r.GetAllAsync()).ReturnsAsync(events);

            var handler = new GetEventsQueryHandler(mockRepo.Object);
            var query = new GetEventsQuery();

            // Act
            var result = await handler.Handle(query, CancellationToken.None);

            // Assert
            result.Should().NotBeNull();
            result.Count().Should().Be(2);
            result.Select(e => e.Title).Should().Contain(new[] { "Event 1", "Event 2" });
            
            mockRepo.Verify(r => r.GetAllAsync(), Times.Once);
        }
    }
}
