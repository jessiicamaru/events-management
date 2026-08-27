using System;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Application.Features.Events.Commands;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using Moq;
using Xunit;

namespace HabitTracker.Application.Tests
{
    public class CreateEventCommandHandlerTests
    {
        [Fact]
        public async Task Handle_ShouldCreateEventAndReturnId()
        {
            // Arrange
            var mockRepo = new Mock<IEventRepository>();
            Event? savedEvent = null;
            
            mockRepo.Setup(r => r.AddAsync(It.IsAny<Event>()))
                .Callback<Event>(e => savedEvent = e)
                .Returns(Task.CompletedTask);

            var handler = new CreateEventCommandHandler(mockRepo.Object);

            var command = new CreateEventCommand
            {
                Title = "Morning Run",
                StartTime = DateTime.UtcNow.AddHours(1),
                EndTime = DateTime.UtcNow.AddHours(2),
                HabitId = "habit-123"
            };

            // Act
            var result = await handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().NotBeEmpty();
            savedEvent.Should().NotBeNull();
            savedEvent!.Title.Should().Be("Morning Run");
            savedEvent.HabitId.Should().Be("habit-123");
            
            mockRepo.Verify(r => r.AddAsync(It.IsAny<Event>()), Times.Once);
        }
    }
}
