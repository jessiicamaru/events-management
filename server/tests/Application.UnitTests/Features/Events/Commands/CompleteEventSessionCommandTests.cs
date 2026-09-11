using System;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Application.Features.Events.Commands;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using Moq;
using Xunit;

namespace HabitTracker.Application.UnitTests.Features.Events.Commands
{
    public class CompleteEventSessionCommandTests
    {
        private readonly Mock<IEventRepository> _eventRepoMock;
        private readonly Mock<IHabitRepository> _habitRepoMock;
        private readonly CompleteEventSessionCommandHandler _handler;

        public CompleteEventSessionCommandTests()
        {
            _eventRepoMock = new Mock<IEventRepository>();
            _habitRepoMock = new Mock<IHabitRepository>();
            _handler = new CompleteEventSessionCommandHandler(_eventRepoMock.Object, _habitRepoMock.Object);
        }

        [Fact]
        public async Task Handle_ShouldReturnFalse_WhenEventDoesNotExist()
        {
            // Arrange
            var command = new CompleteEventSessionCommand { EventId = Guid.NewGuid(), ActualDuration = TimeSpan.FromMinutes(25) };
            _eventRepoMock.Setup(repo => repo.GetByIdAsync(command.EventId)).ReturnsAsync((Event)null);

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            Assert.False(result);
        }

        [Fact]
        public async Task Handle_ShouldReturnTrueAndCompleteEvent_WhenEventExists()
        {
            // Arrange
            var eventId = Guid.NewGuid();
            var habitId = Guid.NewGuid().ToString();
            var ev = new Event { Id = eventId, HabitId = habitId, IsCompleted = false, StartTime = DateTime.UtcNow, EndTime = DateTime.UtcNow.AddMinutes(30) };
            var command = new CompleteEventSessionCommand { EventId = eventId, ActualDuration = TimeSpan.FromMinutes(25), UpdateCalendar = true };
            
            _eventRepoMock.Setup(repo => repo.GetByIdAsync(eventId)).ReturnsAsync(ev);
            _eventRepoMock.Setup(repo => repo.UpdateAsync(ev)).Returns(Task.CompletedTask);
            _habitRepoMock.Setup(repo => repo.GetByIdAsync(It.IsAny<Guid>())).ReturnsAsync(new Habit { Id = Guid.Parse(habitId) });

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            Assert.True(result);
            Assert.True(ev.IsCompleted);
            Assert.Equal(TimeSpan.FromMinutes(25), ev.ActualDuration);
            // EndTime should be updated because UpdateCalendar is true
            _eventRepoMock.Verify(repo => repo.UpdateAsync(It.IsAny<Event>()), Times.Once);
        }
    }
}
