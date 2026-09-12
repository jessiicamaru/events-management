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
        private readonly Mock<IEventRepository> _mockEventRepo;
        private readonly Mock<IHabitRepository> _mockHabitRepo;
        private readonly Mock<IUserRepository> _mockUserRepo;
        private readonly Mock<ISquadRepository> _mockSquadRepo;
        private readonly CompleteEventSessionCommandHandler _handler;

        public CompleteEventSessionCommandTests()
        {
            _mockEventRepo = new Mock<IEventRepository>();
            _mockHabitRepo = new Mock<IHabitRepository>();
            _mockUserRepo = new Mock<IUserRepository>();
            _mockSquadRepo = new Mock<ISquadRepository>();
            _handler = new CompleteEventSessionCommandHandler(
                _mockEventRepo.Object, 
                _mockHabitRepo.Object,
                _mockUserRepo.Object,
                _mockSquadRepo.Object);
        }

        [Fact]
        public async Task Handle_ShouldReturnFalse_WhenEventDoesNotExist()
        {
            // Arrange
            var command = new CompleteEventSessionCommand { EventId = Guid.NewGuid(), ActualDuration = TimeSpan.FromMinutes(25) };
            _mockEventRepo.Setup(repo => repo.GetByIdAsync(command.EventId)).ReturnsAsync((Event?)null);

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
            
            _mockEventRepo.Setup(repo => repo.GetByIdAsync(eventId)).ReturnsAsync(ev);
            _mockEventRepo.Setup(repo => repo.UpdateAsync(ev)).Returns(Task.CompletedTask);
            _mockHabitRepo.Setup(repo => repo.GetByIdAsync(It.IsAny<Guid>())).ReturnsAsync(new Habit { Id = Guid.Parse(habitId) });

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            Assert.True(result);
            Assert.True(ev.IsCompleted);
            Assert.Equal(TimeSpan.FromMinutes(25), ev.ActualDuration);
            // EndTime should be updated because UpdateCalendar is true
            _mockEventRepo.Verify(repo => repo.UpdateAsync(It.IsAny<Event>()), Times.Once);
        }
    }
}
