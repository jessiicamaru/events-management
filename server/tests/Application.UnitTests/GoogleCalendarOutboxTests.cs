using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Application.Features.Events.Commands;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using HabitTracker.Infrastructure.Services;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace HabitTracker.Application.Tests
{
    public class GoogleCalendarOutboxTests
    {
        [Fact]
        public async Task CreateEvent_ShouldEnqueueInsertAction_WhenUserHasGoogleRefreshToken()
        {
            // Arrange
            var mockRepo = new Mock<IEventRepository>();
            var mockHabitTaskRepo = new Mock<IHabitTaskRepository>();
            var mockEventTaskRepo = new Mock<IEventTaskRepository>();
            var mockUserRepo = new Mock<IUserRepository>();
            var mockOutboxRepo = new Mock<IGoogleCalendarOutboxRepository>();

            var user = new ApplicationUser { Id = "user-123", GoogleRefreshToken = "token-123" };
            mockUserRepo.Setup(r => r.GetByIdAsync("user-123")).ReturnsAsync(user);

            var handler = new CreateEventCommandHandler(
                mockRepo.Object,
                mockHabitTaskRepo.Object,
                mockEventTaskRepo.Object,
                mockUserRepo.Object,
                mockOutboxRepo.Object,
                new Mock<IEventCategoryRepository>().Object,
                new Mock<ISquadRepository>().Object);

            var command = new CreateEventCommand
            {
                Title = "Workout",
                StartTime = DateTime.UtcNow,
                EndTime = DateTime.UtcNow.AddHours(1),
                UserId = "user-123"
            };

            // Act
            await handler.Handle(command, CancellationToken.None);

            // Assert
            mockOutboxRepo.Verify(r => r.EnqueueAsync(
                "user-123",
                It.IsAny<Guid>(),
                null,
                "Insert",
                It.Is<string>(p => p.Contains("Workout")),
                It.IsAny<CancellationToken>()), Times.Once);
        }

        [Fact]
        public async Task OutboxWorker_ShouldCallPushInsert_AndSaveGoogleEventId()
        {
            // Arrange
            var mockOutboxRepo = new Mock<IGoogleCalendarOutboxRepository>();
            var mockUserRepo = new Mock<IUserRepository>();
            var mockGoogleService = new Mock<IGoogleCalendarService>();
            var mockEventRepo = new Mock<IEventRepository>();

            var item = new GoogleCalendarOutbox
            {
                Id = Guid.NewGuid(),
                UserId = "user-123",
                EventId = Guid.NewGuid(),
                Action = "Insert",
                Payload = "{}"
            };

            mockOutboxRepo.Setup(r => r.GetUnprocessedAsync(It.IsAny<int>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(new List<GoogleCalendarOutbox> { item });

            var user = new ApplicationUser { Id = "user-123", GoogleRefreshToken = "token-abc" };
            mockUserRepo.Setup(r => r.GetByIdAsync("user-123")).ReturnsAsync(user);

            mockGoogleService.Setup(s => s.PushInsertAsync("user-123", "token-abc", item.EventId, item.Payload, It.IsAny<CancellationToken>()))
                .ReturnsAsync("google-event-id-999");

            var localEvent = new Event { Id = item.EventId };
            mockEventRepo.Setup(r => r.GetByIdAsync(item.EventId)).ReturnsAsync(localEvent);

            var serviceProvider = new ServiceCollection();
            serviceProvider.AddSingleton(mockOutboxRepo.Object);
            serviceProvider.AddSingleton(mockUserRepo.Object);
            serviceProvider.AddSingleton(mockGoogleService.Object);
            serviceProvider.AddSingleton(mockEventRepo.Object);

            var mockScope = new Mock<IServiceScope>();
            mockScope.Setup(s => s.ServiceProvider).Returns(serviceProvider.BuildServiceProvider());

            var mockScopeFactory = new Mock<IServiceScopeFactory>();
            mockScopeFactory.Setup(f => f.CreateScope()).Returns(mockScope.Object);

            var logger = new Mock<ILogger<GoogleCalendarSyncWorker>>();
            var worker = new GoogleCalendarSyncWorkerTestsWrapper(mockScopeFactory.Object, logger.Object);

            // Act
            await worker.TriggerProcessOutboxQueueAsync(CancellationToken.None);

            // Assert
            mockGoogleService.Verify(s => s.PushInsertAsync("user-123", "token-abc", item.EventId, item.Payload, It.IsAny<CancellationToken>()), Times.Once);
            localEvent.GoogleEventId.Should().Be("google-event-id-999");
            mockEventRepo.Verify(r => r.UpdateAsync(localEvent), Times.Once);
            item.ProcessedAt.Should().NotBeNull();
            item.GoogleEventId.Should().Be("google-event-id-999");
            mockOutboxRepo.Verify(r => r.UpdateAsync(item, It.IsAny<CancellationToken>()), Times.Once);
        }

        private class GoogleCalendarSyncWorkerTestsWrapper : GoogleCalendarSyncWorker
        {
            public GoogleCalendarSyncWorkerTestsWrapper(IServiceScopeFactory scopeFactory, ILogger<GoogleCalendarSyncWorker> logger)
                : base(scopeFactory, logger) { }

            public Task TriggerProcessOutboxQueueAsync(CancellationToken token)
            {
                var method = typeof(GoogleCalendarSyncWorker).GetMethod("ProcessOutboxQueueAsync", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
                return (Task)method!.Invoke(this, new object[] { token })!;
            }
        }
    }
}
