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
        private readonly Mock<IGoogleCalendarOutboxRepository> _mockOutboxRepo;
        private readonly CompleteEventSessionCommandHandler _handler;

        public CompleteEventSessionCommandTests()
        {
            _mockEventRepo = new Mock<IEventRepository>();
            _mockHabitRepo = new Mock<IHabitRepository>();
            _mockUserRepo = new Mock<IUserRepository>();
            _mockSquadRepo = new Mock<ISquadRepository>();
            _mockOutboxRepo = new Mock<IGoogleCalendarOutboxRepository>();

            // Sensible empty defaults so a test only sets up what it actually cares about.
            _mockEventRepo.Setup(r => r.GetCompletedEventsForUserAsync(It.IsAny<string>()))
                .ReturnsAsync(new System.Collections.Generic.List<Event>());
            _mockEventRepo.Setup(r => r.GetCompletedEventsForHabitAsync(It.IsAny<Guid>()))
                .ReturnsAsync(new System.Collections.Generic.List<Event>());
            _mockSquadRepo.Setup(r => r.GetSquadsByUserIdAsync(It.IsAny<string>()))
                .ReturnsAsync(new System.Collections.Generic.List<Squad>());

            _handler = new CompleteEventSessionCommandHandler(
                _mockEventRepo.Object,
                _mockHabitRepo.Object,
                _mockUserRepo.Object,
                _mockSquadRepo.Object,
                _mockOutboxRepo.Object,
                new HabitTracker.Application.Tests.TestDoubles.PassThroughUnitOfWork());
        }

        [Fact]
        public async Task Handle_ShouldReturnFalse_WhenEventDoesNotExist()
        {
            // Arrange
            var command = new CompleteEventSessionCommand { EventId = Guid.NewGuid(), ActualDuration = TimeSpan.FromMinutes(25), UserId = "user1" };
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
            var ev = new Event { Id = eventId, UserId = "user1", HabitId = habitId, IsCompleted = false, StartTime = DateTime.UtcNow, EndTime = DateTime.UtcNow.AddMinutes(30) };
            var command = new CompleteEventSessionCommand { EventId = eventId, UserId = "user1", ActualDuration = TimeSpan.FromMinutes(25), UpdateCalendar = true };
            
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

        [Fact]
        public async Task Handle_ShouldReturnFalse_WhenUserIdMismatch()
        {
            // Arrange
            var eventId = Guid.NewGuid();
            var habitId = Guid.NewGuid().ToString();
            var ev = new Event { Id = eventId, UserId = "user1", HabitId = habitId, IsCompleted = false };
            var command = new CompleteEventSessionCommand { EventId = eventId, UserId = "different_user", ActualDuration = TimeSpan.FromMinutes(25) };

            _mockEventRepo.Setup(repo => repo.GetByIdAsync(eventId)).ReturnsAsync(ev);

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            Assert.False(result);
            _mockEventRepo.Verify(repo => repo.UpdateAsync(It.IsAny<Event>()), Times.Never);
        }

        [Fact]
        public async Task Handle_ShouldAwardXPToUserAndApprovedSquads_WhenUserAndSquadsExist()
        {
            // Arrange
            var eventId = Guid.NewGuid();
            var habitId = Guid.NewGuid().ToString();
            var userId = "user1";
            var squadId1 = Guid.NewGuid();
            var squadId2 = Guid.NewGuid();

            var ev = new Event { Id = eventId, UserId = userId, HabitId = habitId, IsCompleted = false, StartTime = DateTime.UtcNow, EndTime = DateTime.UtcNow.AddMinutes(30) };
            var command = new CompleteEventSessionCommand { EventId = eventId, UserId = userId, ActualDuration = TimeSpan.FromMinutes(25) };

            var user = new ApplicationUser { Id = userId, TotalXP = 50 };
            var squad1 = new Squad { Id = squadId1, TotalSquadXP = 100 };
            var squad2 = new Squad { Id = squadId2, TotalSquadXP = 200 };

            var membership1 = new SquadMember { SquadId = squadId1, UserId = userId, IsApproved = true, XpContributionEnabled = true };
            var membership2 = new SquadMember { SquadId = squadId2, UserId = userId, IsApproved = true, XpContributionEnabled = false }; // contribution disabled

            _mockEventRepo.Setup(repo => repo.GetByIdAsync(eventId)).ReturnsAsync(ev);
            _mockEventRepo.Setup(repo => repo.UpdateAsync(ev)).Returns(Task.CompletedTask);
            _mockHabitRepo.Setup(repo => repo.GetByIdAsync(It.IsAny<Guid>())).ReturnsAsync(new Habit { Id = Guid.Parse(habitId) });
            _mockUserRepo.Setup(repo => repo.GetByIdAsync(userId)).ReturnsAsync(user);
            _mockUserRepo.Setup(repo => repo.UpdateAsync(user)).Returns(Task.CompletedTask);
            
            _mockSquadRepo.Setup(repo => repo.GetSquadsByUserIdAsync(userId)).ReturnsAsync(new System.Collections.Generic.List<Squad> { squad1, squad2 });
            _mockSquadRepo.Setup(repo => repo.GetMembershipAsync(squadId1, userId)).ReturnsAsync(membership1);
            _mockSquadRepo.Setup(repo => repo.GetMembershipAsync(squadId2, userId)).ReturnsAsync(membership2);
            _mockSquadRepo.Setup(repo => repo.UpdateAsync(It.IsAny<Squad>())).Returns(Task.CompletedTask);

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            Assert.True(result);
            Assert.Equal(60, user.TotalXP); // 50 + 10
            Assert.Equal(110, squad1.TotalSquadXP); // 100 + 10 (contribution enabled)
            Assert.Equal(200, squad2.TotalSquadXP); // 200 (contribution disabled, should not change)

            // The award is recorded on the event so un-completing it refunds this exact amount.
            Assert.Equal(10, ev.AwardedXp);

            _mockUserRepo.Verify(repo => repo.UpdateAsync(user), Times.Once);
            _mockSquadRepo.Verify(repo => repo.UpdateAsync(squad1), Times.Once);
            _mockSquadRepo.Verify(repo => repo.UpdateAsync(squad2), Times.Never);
        }
    }
}
