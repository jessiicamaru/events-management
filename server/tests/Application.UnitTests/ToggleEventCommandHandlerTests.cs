using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Application.Features.Events.Commands;
using HabitTracker.Application.Tests.TestDoubles;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using Moq;
using Xunit;

namespace HabitTracker.Application.Tests
{
    public class ToggleEventCommandHandlerTests
    {
        private readonly Mock<IEventRepository> _mockEventRepo;
        private readonly Mock<IHabitRepository> _mockHabitRepo;
        private readonly Mock<IUserRepository> _mockUserRepo;
        private readonly Mock<ISquadRepository> _mockSquadRepo;
        private readonly ToggleEventCommandHandler _handler;

        public ToggleEventCommandHandlerTests()
        {
            _mockEventRepo = new Mock<IEventRepository>();
            _mockHabitRepo = new Mock<IHabitRepository>();
            _mockUserRepo = new Mock<IUserRepository>();
            _mockSquadRepo = new Mock<ISquadRepository>();

            // Sensible empty defaults so a test only sets up what it actually cares about.
            _mockEventRepo.Setup(r => r.GetCompletedEventsForUserAsync(It.IsAny<string>()))
                .ReturnsAsync(new List<Event>());
            _mockEventRepo.Setup(r => r.GetCompletedEventsForHabitAsync(It.IsAny<Guid>()))
                .ReturnsAsync(new List<Event>());
            _mockSquadRepo.Setup(r => r.GetSquadsByUserIdAsync(It.IsAny<string>()))
                .ReturnsAsync(new List<Squad>());

            _handler = new ToggleEventCommandHandler(
                _mockEventRepo.Object,
                _mockHabitRepo.Object,
                _mockUserRepo.Object,
                _mockSquadRepo.Object,
                new PassThroughUnitOfWork());
        }

        /// <summary>Builds a UTC instant whose UTC+7 local date is <paramref name="daysAgo"/> days back.</summary>
        private static DateTime LocalDay(int daysAgo)
        {
            var localToday = DateTime.UtcNow.AddHours(7).Date;
            return DateTime.SpecifyKind(localToday.AddDays(-daysAgo).AddHours(12).AddHours(-7), DateTimeKind.Utc);
        }

        [Fact]
        public async Task Handle_RefusesToMarkAWholeSeriesDone_ButAllowsUndoingIt()
        {
            // Marking the series row done marked every day of it done. A day is completed on
            // its own event; un-completing stays allowed to repair series completed before.
            var series = new Event
            {
                Id = Guid.NewGuid(),
                RecurrenceRule = "RRULE:FREQ=DAILY",
                StartTime = LocalDay(30),
                UserId = "user123",
                HabitId = string.Empty
            };
            _mockEventRepo.Setup(r => r.GetByIdAsync(series.Id)).ReturnsAsync(series);

            var complete = await _handler.Handle(new ToggleEventCommand(series.Id, true, "user123"), CancellationToken.None);

            complete.Should().BeFalse();
            series.IsCompleted.Should().BeFalse();
            _mockEventRepo.Verify(r => r.UpdateAsync(It.IsAny<Event>()), Times.Never);

            series.IsCompleted = true;
            var undo = await _handler.Handle(new ToggleEventCommand(series.Id, false, "user123"), CancellationToken.None);

            undo.Should().BeTrue();
            series.IsCompleted.Should().BeFalse();
        }

        [Fact]
        public async Task Handle_ShouldToggleEventAndRecalculateStreaksAndAwardXP()
        {
            // Arrange
            var habitId = Guid.NewGuid();
            var eventId = Guid.NewGuid();
            var userId = "user123";

            var habit = new Habit { Id = habitId, CurrentStreak = 0, LongestStreak = 0 };

            var evt = new Event
            {
                Id = eventId,
                HabitId = habitId.ToString(),
                IsCompleted = false,
                StartTime = LocalDay(1),
                UserId = userId
            };

            var alreadyDone = new Event
            {
                Id = Guid.NewGuid(),
                HabitId = habitId.ToString(),
                IsCompleted = true,
                StartTime = LocalDay(2),
                UserId = userId
            };

            var user = new ApplicationUser { Id = userId, TotalXP = 50 };
            var squadId = Guid.NewGuid();
            var squad = new Squad { Id = squadId, TotalSquadXP = 100 };
            var membership = new SquadMember { SquadId = squadId, UserId = userId, IsApproved = true, XpContributionEnabled = true };

            _mockEventRepo.Setup(r => r.GetByIdAsync(eventId)).ReturnsAsync(evt);
            _mockEventRepo.Setup(r => r.GetCompletedEventsForUserAsync(userId)).ReturnsAsync(new List<Event> { alreadyDone });
            _mockEventRepo.Setup(r => r.GetCompletedEventsForHabitAsync(habitId)).ReturnsAsync(new List<Event> { alreadyDone });
            _mockHabitRepo.Setup(r => r.GetByIdAsync(habitId)).ReturnsAsync(habit);
            _mockUserRepo.Setup(r => r.GetByIdAsync(userId)).ReturnsAsync(user);
            _mockSquadRepo.Setup(r => r.GetSquadsByUserIdAsync(userId)).ReturnsAsync(new List<Squad> { squad });
            _mockSquadRepo.Setup(r => r.GetMembershipAsync(squadId, userId)).ReturnsAsync(membership);

            var command = new ToggleEventCommand(eventId, true, userId);

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().BeTrue();
            evt.IsCompleted.Should().BeTrue();

            // Streaks should be 2 because we have completions on day -2 and day -1
            habit.CurrentStreak.Should().Be(2);
            habit.LongestStreak.Should().Be(2);

            // XP should be awarded: base 10 + (2-1)*2 = 12 XP
            user.TotalXP.Should().Be(62); // 50 + 12
            squad.TotalSquadXP.Should().Be(112); // 100 + 12

            // ...and recorded on the event, so it can be refunded exactly later.
            evt.AwardedXp.Should().Be(12);

            _mockEventRepo.Verify(r => r.UpdateAsync(evt), Times.Once);
            _mockHabitRepo.Verify(r => r.UpdateAsync(habit), Times.Once);
            _mockUserRepo.Verify(r => r.UpdateAsync(user), Times.Once);
            _mockSquadRepo.Verify(r => r.UpdateAsync(squad), Times.Once);
        }

        [Fact]
        public async Task Handle_ShouldRefundExactlyWhatWasAwarded_WhenToggleOff()
        {
            // Arrange
            var habitId = Guid.NewGuid();
            var eventId = Guid.NewGuid();
            var userId = "user123";

            var habit = new Habit { Id = habitId, CurrentStreak = 2, LongestStreak = 2 };

            var evt = new Event
            {
                Id = eventId,
                HabitId = habitId.ToString(),
                IsCompleted = true,
                AwardedXp = 12, // what the completion actually granted
                StartTime = LocalDay(1),
                UserId = userId
            };

            var otherDone = new Event
            {
                Id = Guid.NewGuid(),
                HabitId = habitId.ToString(),
                IsCompleted = true,
                StartTime = LocalDay(2),
                UserId = userId
            };

            var user = new ApplicationUser { Id = userId, TotalXP = 62 };
            var squadId = Guid.NewGuid();
            var squad = new Squad { Id = squadId, TotalSquadXP = 112 };
            var membership = new SquadMember { SquadId = squadId, UserId = userId, IsApproved = true, XpContributionEnabled = true };

            _mockEventRepo.Setup(r => r.GetByIdAsync(eventId)).ReturnsAsync(evt);
            _mockEventRepo.Setup(r => r.GetCompletedEventsForHabitAsync(habitId)).ReturnsAsync(new List<Event> { otherDone, evt });
            _mockHabitRepo.Setup(r => r.GetByIdAsync(habitId)).ReturnsAsync(habit);
            _mockUserRepo.Setup(r => r.GetByIdAsync(userId)).ReturnsAsync(user);
            _mockSquadRepo.Setup(r => r.GetSquadsByUserIdAsync(userId)).ReturnsAsync(new List<Squad> { squad });
            _mockSquadRepo.Setup(r => r.GetMembershipAsync(squadId, userId)).ReturnsAsync(membership);

            var command = new ToggleEventCommand(eventId, false, userId);

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().BeTrue();
            evt.IsCompleted.Should().BeFalse();

            // Only day -2 remains completed, which is older than yesterday, so the streak resets.
            habit.CurrentStreak.Should().Be(0);

            user.TotalXP.Should().Be(50); // 62 - 12
            squad.TotalSquadXP.Should().Be(100); // 112 - 12
            evt.AwardedXp.Should().Be(0);

            _mockEventRepo.Verify(r => r.UpdateAsync(evt), Times.Once);
            _mockHabitRepo.Verify(r => r.UpdateAsync(habit), Times.Once);
            _mockUserRepo.Verify(r => r.UpdateAsync(user), Times.Once);
            _mockSquadRepo.Verify(r => r.UpdateAsync(squad), Times.Once);
        }

        [Fact]
        public async Task Handle_ShouldConserveXp_WhenTheStreakGrowsBetweenToggleOnAndToggleOff()
        {
            // Regression test for the XP asymmetry: XP used to be recalculated from the streak as
            // it stood at the moment of un-ticking, so a user who stayed consistent in between
            // lost more XP than the completion ever granted (measured: +10 then -18 = net -8).
            var eventId = Guid.NewGuid();
            var userId = "user123";

            var evt = new Event
            {
                Id = eventId,
                HabitId = string.Empty, // no habit: isolate the XP maths
                IsCompleted = false,
                StartTime = LocalDay(0),
                UserId = userId
            };

            var user = new ApplicationUser { Id = userId, TotalXP = 100 };
            var completedSoFar = new List<Event>();

            _mockEventRepo.Setup(r => r.GetByIdAsync(eventId)).ReturnsAsync(evt);
            _mockEventRepo.Setup(r => r.GetCompletedEventsForUserAsync(userId)).ReturnsAsync(() => completedSoFar);
            _mockUserRepo.Setup(r => r.GetByIdAsync(userId)).ReturnsAsync(user);

            var xpAtStart = user.TotalXP;

            // 1. Complete it. Nothing else is done yet, so the streak is 1 and the award is 10.
            await _handler.Handle(new ToggleEventCommand(eventId, true, userId), CancellationToken.None);
            var xpAfterOn = user.TotalXP;

            xpAfterOn.Should().Be(110);
            evt.AwardedXp.Should().Be(10);

            // 2. The user keeps the habit for four more days — exactly what the app encourages.
            completedSoFar.AddRange(Enumerable.Range(1, 4).Select(d => new Event
            {
                Id = Guid.NewGuid(),
                IsCompleted = true,
                StartTime = LocalDay(d),
                UserId = userId
            }));

            // 3. They un-tick the original event. The refund must match the award, not the
            //    now-larger streak.
            await _handler.Handle(new ToggleEventCommand(eventId, false, userId), CancellationToken.None);

            user.TotalXP.Should().Be(xpAtStart, "a complete/un-complete pair must be XP-neutral");
            evt.AwardedXp.Should().Be(0);
        }

        [Fact]
        public async Task Handle_ShouldReturnFalse_WhenEventNotFound()
        {
            // Arrange
            _mockEventRepo.Setup(r => r.GetByIdAsync(It.IsAny<Guid>())).ReturnsAsync((Event?)null);

            var command = new ToggleEventCommand(Guid.NewGuid(), true, "user123");

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().BeFalse();
            _mockEventRepo.Verify(r => r.UpdateAsync(It.IsAny<Event>()), Times.Never);
        }

        [Fact]
        public async Task Handle_ShouldReturnFalse_WhenUserIdMismatch()
        {
            // Arrange
            var eventId = Guid.NewGuid();
            var evt = new Event
            {
                Id = eventId,
                UserId = "user123",
                IsCompleted = false
            };

            _mockEventRepo.Setup(r => r.GetByIdAsync(eventId)).ReturnsAsync(evt);

            var command = new ToggleEventCommand(eventId, true, "different_user");

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().BeFalse();
            _mockEventRepo.Verify(r => r.UpdateAsync(It.IsAny<Event>()), Times.Never);
        }

        [Fact]
        public async Task Handle_ShouldThrow_WhenUserIdIsMissing()
        {
            // The command used to default UserId to "", which paired badly with handlers that
            // treated an empty UserId as "no filter".
            var act = async () => await _handler.Handle(
                new ToggleEventCommand(Guid.NewGuid(), true, string.Empty), CancellationToken.None);

            await act.Should().ThrowAsync<ArgumentException>();
            _mockEventRepo.Verify(r => r.GetByIdAsync(It.IsAny<Guid>()), Times.Never);
        }

        [Fact]
        public async Task Handle_ShouldCalculateStreakCorrectlyAcrossUtcDayBoundary_UsingUtcPlus7()
        {
            // Arrange
            var habitId = Guid.NewGuid();
            var eventId1 = Guid.NewGuid();
            var eventId2 = Guid.NewGuid();
            var userId = "user123";

            var habit = new Habit { Id = habitId, CurrentStreak = 0, LongestStreak = 0 };

            // Calculate base date for the test relative to UtcNow
            var todayLocal = DateTime.UtcNow.AddHours(7).Date;
            var ev1Time = DateTime.SpecifyKind(todayLocal.AddDays(-1).AddHours(23).AddHours(-7), DateTimeKind.Utc);
            var ev2Time = DateTime.SpecifyKind(todayLocal.AddHours(6).AddHours(-7), DateTimeKind.Utc);

            // Event 1: Yesterday at 11:00 PM local (Yesterday at 4:00 PM UTC)
            var ev1 = new Event
            {
                Id = eventId1,
                HabitId = habitId.ToString(),
                IsCompleted = true,
                StartTime = ev1Time,
                UserId = userId
            };

            // Event 2: Today at 6:00 AM local (Yesterday at 11:00 PM UTC)
            var ev2 = new Event
            {
                Id = eventId2,
                HabitId = habitId.ToString(),
                IsCompleted = false, // To be completed now
                StartTime = ev2Time,
                UserId = userId
            };

            var user = new ApplicationUser { Id = userId, TotalXP = 50 };

            _mockEventRepo.Setup(r => r.GetByIdAsync(eventId2)).ReturnsAsync(ev2);
            _mockEventRepo.Setup(r => r.GetCompletedEventsForUserAsync(userId)).ReturnsAsync(new List<Event> { ev1 });
            _mockEventRepo.Setup(r => r.GetCompletedEventsForHabitAsync(habitId)).ReturnsAsync(new List<Event> { ev1 });
            _mockHabitRepo.Setup(r => r.GetByIdAsync(habitId)).ReturnsAsync(habit);
            _mockUserRepo.Setup(r => r.GetByIdAsync(userId)).ReturnsAsync(user);

            var command = new ToggleEventCommand(eventId2, true, userId);

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().BeTrue();
            ev2.IsCompleted.Should().BeTrue();

            // Under UTC: Event 1 and Event 2 would share a date, so the streak would stay 1.
            // Under UTC+7 they are consecutive local days, so the streak becomes 2.
            habit.CurrentStreak.Should().Be(2);
            habit.LongestStreak.Should().Be(2);
        }
    }
}
