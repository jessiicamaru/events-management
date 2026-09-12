using HabitTracker.Application.Features.Users.Commands;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using Moq;
using Xunit;
using FluentAssertions;
using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace HabitTracker.Application.UnitTests.Features.Users.Commands
{
    public class UpdateCosmeticsCommandHandlerTests
    {
        private readonly Mock<IUserRepository> _repositoryMock;
        private readonly UpdateCosmeticsCommandHandler _handler;

        public UpdateCosmeticsCommandHandlerTests()
        {
            _repositoryMock = new Mock<IUserRepository>();
            _handler = new UpdateCosmeticsCommandHandler(_repositoryMock.Object);
        }

        [Fact]
        public async Task Handle_UserNotFound_ThrowsException()
        {
            // Arrange
            var command = new UpdateCosmeticsCommand { UserId = "user1", AvatarBorderColor = "#FFF" };
            _repositoryMock.Setup(repo => repo.GetByIdAsync("user1")).ReturnsAsync((ApplicationUser?)null);

            // Act
            Func<Task> act = async () => await _handler.Handle(command, CancellationToken.None);

            // Assert
            await act.Should().ThrowAsync<Exception>().WithMessage("User not found");
        }

        [Fact]
        public async Task Handle_ValidUser_UpdatesCosmetics()
        {
            // Arrange
            var command = new UpdateCosmeticsCommand 
            { 
                UserId = "user1", 
                AvatarBorderColor = "#FFF",
                UnlockedEmojis = new List<string> { "🚀" }
            };

            var user = new ApplicationUser { Id = "user1", TotalXP = 100 };
            _repositoryMock.Setup(repo => repo.GetByIdAsync("user1")).ReturnsAsync(user);

            // Act
            await _handler.Handle(command, CancellationToken.None);

            // Assert
            user.AvatarBorderColor.Should().Be("#FFF");
            user.UnlockedEmojis.Should().Contain("🚀");
            _repositoryMock.Verify(repo => repo.UpdateAsync(user), Times.Once);
        }
    }
}
