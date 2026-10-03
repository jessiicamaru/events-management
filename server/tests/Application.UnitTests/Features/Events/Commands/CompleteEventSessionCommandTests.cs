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
        private readonly Mock<IEventTaskRepository> _mockTaskRepo;
        private readonly CompleteEventSessionCommandHandler _handler;

        public CompleteEventSessionCommandTests()
        {
            _mockEventRepo = new Mock<IEventRepository>();
            _mockHabitRepo = new Mock<IHabitRepository>();
            _mockUserRepo = new Mock<IUserRepository>();
            _mockSquadRepo = new Mock<ISquadRepository>();
            _mockOutboxRepo = new Mock<IGoogleCalendarOutboxRepository>();
            _mockTaskRepo = new Mock<IEventTaskRepository>();
            _mockTaskRepo.Setup(r => r.GetByEventIdAsync(It.IsAny<Guid>()))
                .ReturnsAsync(new System.Collections.Generic.List<EventTask>());

            // Sensible empty defaults so a test only sets up what it actually cares about.
            _mockEventRepo.Setup(r => r.GetCompletedEventsForUserAsync(It.IsAny<string>()))
                .ReturnsAsync(new System.Collections.Generic.List<Event>());
            _mockEventRepo.Setup(r => r.GetCompletedEventsForHabitAsync(It.IsAny<Guid>()))
                .ReturnsAsync(new System.Collections.Generic.List<Event>());
            _mockSquadRepo.Setup(r => r.GetSquadsByUserIdAsync(It.IsAny<string>()))
                .ReturnsAsync(new System.Collections.Generic.List<Squad>());
            _mockEventRepo.Setup(r => r.TryAddOccurrenceDayAsync(It.IsAny<Event>()))
                .ReturnsAsync(true);

            _handler = new CompleteEventSessionCommandHandler(
                _mockEventRepo.Object,
                _mockHabitRepo.Object,
                _mockUserRepo.Object,
                _mockSquadRepo.Object,
                _mockOutboxRepo.Object,
                new HabitTracker.Application.Tests.TestDoubles.PassThroughUnitOfWork(),
                new HabitTracker.Application.Common.OccurrenceMaterializer(
                    _mockEventRepo.Object,
                    _mockTaskRepo.Object,
                    new HabitTracker.Application.Tests.TestDoubles.PassThroughUnitOfWork()));
        }

        private static Event DailySeries(string userId) => new()
        {
            Id = Guid.NewGuid(),
            Title = "Jogging",
            StartTime = new DateTime(2026, 5, 4, 10, 0, 0, DateTimeKind.Utc),
            EndTime = new DateTime(2026, 5, 4, 11, 0, 0, DateTimeKind.Utc),
            RecurrenceRule = "RRULE:FREQ=DAILY",
            UserId = userId,
            HabitId = string.Empty
        };

        [Fact]
        public async Task Handle_RefusesToCompleteAWholeSeries_WhenNoDayIsGiven()
        {
            // Completing the series row completed every day of it at once.
            var series = DailySeries("user1");
            _mockEventRepo.Setup(r => r.GetByIdAsync(series.Id)).ReturnsAsync(series);

            var result = await _handler.Handle(new CompleteEventSessionCommand
            {
                EventId = series.Id,
                ActualDuration = TimeSpan.FromMinutes(30),
                UserId = "user1"
            }, CancellationToken.None);

            Assert.False(result);
            Assert.False(series.IsCompleted);
            _mockEventRepo.Verify(r => r.UpdateAsync(It.IsAny<Event>()), Times.Never);
        }

        [Fact]
        public async Task Handle_CompletesOnlyTheGivenDay_OfASeries()
        {
            var series = DailySeries("user1");
            var originalEnd = series.EndTime;
            var day = new DateTime(2026, 9, 11, 10, 0, 0, DateTimeKind.Utc);
            _mockEventRepo.Setup(r => r.GetByIdAsync(series.Id)).ReturnsAsync(series);

            Event? created = null;
            _mockEventRepo.Setup(r => r.TryAddOccurrenceDayAsync(It.IsAny<Event>()))
                .Callback<Event>(e => created = e)
                .ReturnsAsync(true);

            var result = await _handler.Handle(new CompleteEventSessionCommand
            {
                EventId = series.Id,
                ActualDuration = TimeSpan.FromMinutes(20),
                UpdateCalendar = true,
                OccurrenceStart = day,
                UserId = "user1"
            }, CancellationToken.None);

            Assert.True(result);
            Assert.NotNull(created);
            Assert.Equal(series.Id, created!.ParentEventId);
            Assert.Equal(day, created.ExceptionDate);
            Assert.True(created.IsCompleted);
            Assert.Equal(TimeSpan.FromMinutes(20), created.ActualDuration);

            // The series itself is untouched: not completed, and "update calendar" resized the
            // day, not every day of the series.
            Assert.False(series.IsCompleted);
            Assert.Equal(originalEnd, series.EndTime);
            _mockEventRepo.Verify(r => r.UpdateAsync(series), Times.Never);
        }

        [Fact]
        public async Task Handle_DoesNotQueueAGoogleUpdate_ForADayGoogleNeverSaw()
        {
            // A day split off for this session was never sent to Google; an Update for it
            // fails in the sync worker ("missing GoogleEventId") until it gives up.
            var series = DailySeries("user1");
            series.GoogleEventId = "google-series";
            _mockEventRepo.Setup(r => r.GetByIdAsync(series.Id)).ReturnsAsync(series);
            _mockUserRepo.Setup(r => r.GetByIdAsync("user1"))
                .ReturnsAsync(new ApplicationUser { Id = "user1", GoogleRefreshToken = "token" });

            var result = await _handler.Handle(new CompleteEventSessionCommand
            {
                EventId = series.Id,
                ActualDuration = TimeSpan.FromMinutes(20),
                OccurrenceStart = new DateTime(2026, 9, 11, 10, 0, 0, DateTimeKind.Utc),
                UserId = "user1"
            }, CancellationToken.None);

            // Without this, an early `return false` would satisfy the Times.Never below as well.
            Assert.True(result);
            _mockEventRepo.Verify(r => r.TryAddOccurrenceDayAsync(It.Is<Event>(e => e.ParentEventId == series.Id)), Times.Once);

            _mockOutboxRepo.Verify(r => r.EnqueueAsync(
                It.IsAny<string>(), It.IsAny<Guid>(), It.IsAny<string?>(), It.IsAny<string>(),
                It.IsAny<string>(), It.IsAny<CancellationToken>()), Times.Never);
        }

        [Fact]
        public async Task Handle_StillQueuesAGoogleUpdate_ForAnEventGoogleHas()
        {
            // The guard above must not silence ordinary events: "update calendar" on an event
            // Google has has always been pushed.
            var ev = new Event
            {
                Id = Guid.NewGuid(),
                StartTime = new DateTime(2026, 9, 11, 10, 0, 0, DateTimeKind.Utc),
                EndTime = new DateTime(2026, 9, 11, 11, 0, 0, DateTimeKind.Utc),
                UserId = "user1",
                HabitId = string.Empty,
                GoogleEventId = "g1"
            };
            _mockEventRepo.Setup(r => r.GetByIdAsync(ev.Id)).ReturnsAsync(ev);
            _mockUserRepo.Setup(r => r.GetByIdAsync("user1"))
                .ReturnsAsync(new ApplicationUser { Id = "user1", GoogleRefreshToken = "token" });

            var result = await _handler.Handle(new CompleteEventSessionCommand
            {
                EventId = ev.Id,
                ActualDuration = TimeSpan.FromMinutes(40),
                UpdateCalendar = true,
                UserId = "user1"
            }, CancellationToken.None);

            Assert.True(result);
            _mockOutboxRepo.Verify(r => r.EnqueueAsync(
                "user1", ev.Id, "g1", "Update",
                It.Is<string>(p => p.Contains("EndTime")), It.IsAny<CancellationToken>()), Times.Once);
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
