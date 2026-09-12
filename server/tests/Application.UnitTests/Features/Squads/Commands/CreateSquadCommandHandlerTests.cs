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
    public class CreateSquadCommandHandlerTests
    {
        private readonly Mock<ISquadRepository> _repositoryMock;
        private readonly CreateSquadCommandHandler _handler;

        public CreateSquadCommandHandlerTests()
        {
            _repositoryMock = new Mock<ISquadRepository>();
            _handler = new CreateSquadCommandHandler(_repositoryMock.Object);
        }

        [Fact]
        public async Task Handle_UserAlreadyInSquad_ThrowsException()
        {
            // Arrange
            var command = new CreateSquadCommand { Name = "Test", IsBuddyMode = true, AdminUserId = "user1" };
            _repositoryMock.Setup(repo => repo.IsUserInAnySquadAsync("user1")).ReturnsAsync(true);

            // Act
            Func<Task> act = async () => await _handler.Handle(command, CancellationToken.None);

            // Assert
            await act.Should().ThrowAsync<Exception>().WithMessage("Already in a squad");
        }

        [Fact]
        public async Task Handle_ValidRequest_CreatesSquad()
        {
            // Arrange
            var command = new CreateSquadCommand { Name = "Test", IsBuddyMode = true, AdminUserId = "user1" };
            _repositoryMock.Setup(repo => repo.IsUserInAnySquadAsync("user1")).ReturnsAsync(false);
            
            var expectedSquad = new Squad { Id = Guid.NewGuid(), Name = "Test", IsBuddyMode = true };
            _repositoryMock.Setup(repo => repo.CreateSquadAsync(It.IsAny<Squad>(), "user1")).ReturnsAsync(expectedSquad);

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().BeEquivalentTo(expectedSquad);
            _repositoryMock.Verify(repo => repo.CreateSquadAsync(It.Is<Squad>(s => s.Name == "Test" && s.IsBuddyMode == true), "user1"), Times.Once);
        }
    }
}
