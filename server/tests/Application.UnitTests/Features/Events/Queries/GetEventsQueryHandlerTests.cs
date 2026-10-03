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
        private readonly Mock<IUserRepository> _mockUserRepo;
        private readonly Mock<IGoogleCalendarSyncCacheRepository> _mockSyncCacheRepo;
        private readonly Mock<Microsoft.Extensions.DependencyInjection.IServiceScopeFactory> _mockScopeFactory;
        private readonly GetEventsQueryHandler _handler;

        public GetEventsQueryHandlerTests()
        {
            _mockEventRepo = new Mock<IEventRepository>();
            _mockUserRepo = new Mock<IUserRepository>();
            _mockSyncCacheRepo = new Mock<IGoogleCalendarSyncCacheRepository>();
            _mockScopeFactory = new Mock<Microsoft.Extensions.DependencyInjection.IServiceScopeFactory>();
            _handler = new GetEventsQueryHandler(
                _mockEventRepo.Object,
                _mockUserRepo.Object,
                _mockSyncCacheRepo.Object,
                _mockScopeFactory.Object);
        }

        [Fact]
        public async Task Handle_ShouldThrow_WhenUserIdIsEmpty()
        {
            // An unset UserId used to fall back to every user's events. Refusing is the safe
            // direction: a forgotten assignment must fail, not widen the query.
            var query = new GetEventsQuery { UserId = string.Empty };

            await Assert.ThrowsAsync<ArgumentException>(
                () => _handler.Handle(query, CancellationToken.None));

            _mockEventRepo.Verify(
                repo => repo.GetEventsForUserAsync(It.IsAny<string>(), It.IsAny<DateTime?>(), It.IsAny<DateTime?>()),
                Times.Never);
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
            _mockEventRepo.Verify(repo => repo.GetEventsForUserAsync("user123"), Times.Once);
        }
    }
}
