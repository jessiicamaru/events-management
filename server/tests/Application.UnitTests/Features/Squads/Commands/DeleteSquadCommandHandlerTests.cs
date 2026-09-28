using HabitTracker.Application.Features.Squads.Commands;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using Moq;
using Xunit;
using FluentAssertions;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace HabitTracker.Application.UnitTests.Features.Squads.Commands
{
    public class DeleteSquadCommandHandlerTests
    {
        private readonly Mock<ISquadRepository> _repositoryMock;
        private readonly DeleteSquadCommandHandler _handler;

        public DeleteSquadCommandHandlerTests()
        {
            _repositoryMock = new Mock<ISquadRepository>();
            _handler = new DeleteSquadCommandHandler(_repositoryMock.Object);
        }

        [Fact]
        public async Task Handle_CallerIsLeader_DeletesSquad()
        {
            // Arrange
            var squadId = Guid.NewGuid();
            var userId = "user-leader";
            var command = new DeleteSquadCommand { SquadId = squadId, ActionByUserId = userId };

            var callerMembership = new SquadMember
            {
                SquadId = squadId,
                UserId = userId,
                Role = "Leader",
                IsApproved = true
            };

            var squad = new Squad { Id = squadId, Name = "Test Squad" };

            _repositoryMock.Setup(repo => repo.GetMembershipAsync(squadId, userId))
                .ReturnsAsync(callerMembership);
            _repositoryMock.Setup(repo => repo.GetSquadByIdAsync(squadId))
                .ReturnsAsync(squad);

            // Act
            await _handler.Handle(command, CancellationToken.None);

            // Assert
            _repositoryMock.Verify(repo => repo.DeleteSquadAsync(squadId), Times.Once);
        }

        [Fact]
        public async Task Handle_CallerIsNotLeader_ThrowsException()
        {
            // Arrange
            var squadId = Guid.NewGuid();
            var userId = "user-member";
            var command = new DeleteSquadCommand { SquadId = squadId, ActionByUserId = userId };

            var callerMembership = new SquadMember
            {
                SquadId = squadId,
                UserId = userId,
                Role = "Member",
                IsApproved = true
            };

            _repositoryMock.Setup(repo => repo.GetMembershipAsync(squadId, userId))
                .ReturnsAsync(callerMembership);

            // Act
            Func<Task> act = async () => await _handler.Handle(command, CancellationToken.None);

            // Assert
            await act.Should().ThrowAsync<Exception>().WithMessage("Only approved Leaders can delete the squad");
            _repositoryMock.Verify(repo => repo.DeleteSquadAsync(It.IsAny<Guid>()), Times.Never);
        }

        [Fact]
        public async Task Handle_CallerIsNotApproved_ThrowsException()
        {
            // Arrange
            var squadId = Guid.NewGuid();
            var userId = "user-leader";
            var command = new DeleteSquadCommand { SquadId = squadId, ActionByUserId = userId };

            var callerMembership = new SquadMember
            {
                SquadId = squadId,
                UserId = userId,
                Role = "Leader",
                IsApproved = false
            };

            _repositoryMock.Setup(repo => repo.GetMembershipAsync(squadId, userId))
                .ReturnsAsync(callerMembership);

            // Act
            Func<Task> act = async () => await _handler.Handle(command, CancellationToken.None);

            // Assert
            await act.Should().ThrowAsync<Exception>().WithMessage("Only approved Leaders can delete the squad");
            _repositoryMock.Verify(repo => repo.DeleteSquadAsync(It.IsAny<Guid>()), Times.Never);
        }

        [Fact]
        public async Task Handle_SquadNotFound_ThrowsException()
        {
            // Arrange
            var squadId = Guid.NewGuid();
            var userId = "user-leader";
            var command = new DeleteSquadCommand { SquadId = squadId, ActionByUserId = userId };

            var callerMembership = new SquadMember
            {
                SquadId = squadId,
                UserId = userId,
                Role = "Leader",
                IsApproved = true
            };

            _repositoryMock.Setup(repo => repo.GetMembershipAsync(squadId, userId))
                .ReturnsAsync(callerMembership);
            _repositoryMock.Setup(repo => repo.GetSquadByIdAsync(squadId))
                .ReturnsAsync((Squad?)null);

            // Act
            Func<Task> act = async () => await _handler.Handle(command, CancellationToken.None);

            // Assert
            await act.Should().ThrowAsync<Exception>().WithMessage("Squad not found");
            _repositoryMock.Verify(repo => repo.DeleteSquadAsync(It.IsAny<Guid>()), Times.Never);
        }
    }
}
