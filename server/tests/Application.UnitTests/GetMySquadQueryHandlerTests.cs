using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Application.Features.Squads.Queries;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using Moq;
using Xunit;

namespace HabitTracker.Application.Tests
{
    public class GetMySquadQueryHandlerTests
    {
        [Fact]
        public async Task Handle_ShouldReturnSquadDetailsAndComputeMemberActivityStreaks()
        {
            // Arrange
            var mockSquadRepo = new Mock<ISquadRepository>();
            var mockHabitRepo = new Mock<IHabitRepository>();
            var mockEventRepo = new Mock<IEventRepository>();

            var userId = "user123";
            var squadId = Guid.NewGuid();
            var squad = new Squad { Id = squadId, Name = "Alpha Squad", MaxMembers = 5, RequireApproval = false };

            var callerMembership = new SquadMember { SquadId = squadId, UserId = userId, IsApproved = true };
            var member = new SquadMember 
            { 
                SquadId = squadId, 
                UserId = userId, 
                Role = "Leader", 
                IsApproved = true,
                XpContributionEnabled = true,
                User = new ApplicationUser { Id = userId, Email = "user@test.com", TotalXP = 150 }
            };

            var members = new List<SquadMember> { member };

            // Calculate base date for the test relative to UtcNow
            var todayLocal = DateTime.UtcNow.AddHours(7).Date;
            var ev1Time = DateTime.SpecifyKind(todayLocal.AddDays(-1).AddHours(15).AddHours(-7), DateTimeKind.Utc);
            var ev2Time = DateTime.SpecifyKind(todayLocal.AddHours(2).AddHours(-7), DateTimeKind.Utc);

            // Standalone and Habit events completed by the user
            var events = new List<Event>
            {
                // Completed on yesterday local
                new Event { Id = Guid.NewGuid(), UserId = userId, IsCompleted = true, StartTime = ev1Time },
                // Completed on today local
                new Event { Id = Guid.NewGuid(), UserId = userId, IsCompleted = true, StartTime = ev2Time }
            };

            mockSquadRepo.Setup(r => r.GetSquadByIdAsync(squadId)).ReturnsAsync(squad);
            mockSquadRepo.Setup(r => r.GetMembershipAsync(squadId, userId)).ReturnsAsync(callerMembership);
            mockSquadRepo.Setup(r => r.GetSquadMembersAsync(squadId)).ReturnsAsync(members);
            mockEventRepo.Setup(r => r.GetEventsForUserAsync(userId)).ReturnsAsync(events);

            var handler = new GetMySquadQueryHandler(mockSquadRepo.Object, mockHabitRepo.Object, mockEventRepo.Object);
            var query = new GetMySquadQuery { UserId = userId, SquadId = squadId };

            // Act
            var result = await handler.Handle(query, CancellationToken.None);

            // Assert
            result.Should().NotBeNull();
            result!.Name.Should().Be("Alpha Squad");
            result.Members.Should().HaveCount(1);
            
            var memberDto = result.Members.First();
            memberDto.UserId.Should().Be(userId);
            memberDto.Email.Should().Be("user@test.com");
            memberDto.TotalXP.Should().Be(150);

            // Yesterday and today (local time offset +7) are consecutive, so streak should be 2.
            memberDto.CurrentStreak.Should().Be(2);

            mockSquadRepo.Verify(r => r.GetSquadByIdAsync(squadId), Times.Once);
            mockSquadRepo.Verify(r => r.GetMembershipAsync(squadId, userId), Times.Once);
            mockSquadRepo.Verify(r => r.GetSquadMembersAsync(squadId), Times.Once);
            mockEventRepo.Verify(r => r.GetEventsForUserAsync(userId), Times.Once);
        }
    }
}
