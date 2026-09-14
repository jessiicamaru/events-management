using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Application.Features.Events.Queries;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using Moq;
using Xunit;

namespace HabitTracker.Application.UnitTests.Features.Events.Queries
{
    public class GetEventsQueryHandlerTests
    {
        private readonly Mock<IEventRepository> _mockEventRepo;
        private readonly GetEventsQueryHandler _handler;

        public GetEventsQueryHandlerTests()
        {
            _mockEventRepo = new Mock<IEventRepository>();
            _handler = new GetEventsQueryHandler(_mockEventRepo.Object);
        }

        [Fact]
        public async Task Handle_ShouldReturnAllEvents_WhenUserIdIsEmpty()
        {
            // Arrange
            var query = new GetEventsQuery { UserId = string.Empty };
            var events = new List<Event> 
            { 
                new Event { Id = Guid.NewGuid(), Title = "Event 1" },
                new Event { Id = Guid.NewGuid(), Title = "Event 2" }
            };
            
            _mockEventRepo.Setup(repo => repo.GetAllAsync()).ReturnsAsync(events);

            // Act
            var result = await _handler.Handle(query, CancellationToken.None);

            // Assert
            Assert.Equal(2, result.Count());
            _mockEventRepo.Verify(repo => repo.GetAllAsync(), Times.Once);
            _mockEventRepo.Verify(repo => repo.GetEventsForUserAsync(It.IsAny<string>()), Times.Never);
        }

        [Fact]
        public async Task Handle_ShouldReturnUserEvents_WhenUserIdIsProvided()
        {
            // Arrange
            var query = new GetEventsQuery { UserId = "user123" };
            var events = new List<Event> 
            { 
                new Event { Id = Guid.NewGuid(), Title = "Event 1", UserId = "user123" },
            };
            
            _mockEventRepo.Setup(repo => repo.GetEventsForUserAsync("user123")).ReturnsAsync(events);

            // Act
            var result = await _handler.Handle(query, CancellationToken.None);

            // Assert
            Assert.Single(result);
            _mockEventRepo.Verify(repo => repo.GetAllAsync(), Times.Never);
            _mockEventRepo.Verify(repo => repo.GetEventsForUserAsync("user123"), Times.Once);
        }
    }
}
