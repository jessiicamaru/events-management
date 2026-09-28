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

            // Standalone and Habit events completed by the user
            var events = new List<Event>
            {
                // Completed on July 24
                new Event { Id = Guid.NewGuid(), UserId = userId, IsCompleted = true, StartTime = new DateTime(2026, 7, 24, 15, 0, 0, DateTimeKind.Utc) },
                // Completed on July 25
                new Event { Id = Guid.NewGuid(), UserId = userId, IsCompleted = true, StartTime = new DateTime(2026, 7, 25, 2, 0, 0, DateTimeKind.Utc) }
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

            // July 24 and July 25 (local time offset +7) are consecutive, so streak should be 2.
            memberDto.CurrentStreak.Should().Be(2);

            mockSquadRepo.Verify(r => r.GetSquadByIdAsync(squadId), Times.Once);
            mockSquadRepo.Verify(r => r.GetMembershipAsync(squadId, userId), Times.Once);
            mockSquadRepo.Verify(r => r.GetSquadMembersAsync(squadId), Times.Once);
            mockEventRepo.Verify(r => r.GetEventsForUserAsync(userId), Times.Once);
        }
    }
}
