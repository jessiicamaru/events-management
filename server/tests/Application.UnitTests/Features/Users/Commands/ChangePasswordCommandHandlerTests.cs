using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Application.Features.Users.Commands;
using HabitTracker.Domain.Entities;
using Microsoft.AspNetCore.Identity;
using Moq;
using Xunit;

namespace HabitTracker.Application.UnitTests.Features.Users.Commands
{
    public class ChangePasswordCommandHandlerTests
    {
        private readonly Mock<UserManager<ApplicationUser>> _userManagerMock;
        private readonly ChangePasswordCommandHandler _handler;

        public ChangePasswordCommandHandlerTests()
        {
            var storeMock = new Mock<IUserStore<ApplicationUser>>();
            _userManagerMock = new Mock<UserManager<ApplicationUser>>(
                storeMock.Object, null!, null!, null!, null!, null!, null!, null!, null!);
            
            _handler = new ChangePasswordCommandHandler(_userManagerMock.Object);
        }

        [Fact]
        public async Task Handle_ShouldReturnFailedResult_WhenUserDoesNotExist()
        {
            // Arrange
            _userManagerMock.Setup(m => m.FindByIdAsync("user1")).ReturnsAsync((ApplicationUser?)null);

            var command = new ChangePasswordCommand { UserId = "user1", CurrentPassword = "Old", NewPassword = "New" };

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            result.Succeeded.Should().BeFalse();
        }

        [Fact]
        public async Task Handle_ShouldChangePassword_WhenUserExists()
        {
            // Arrange
            var user = new ApplicationUser { Id = "user1" };
            _userManagerMock.Setup(m => m.FindByIdAsync("user1")).ReturnsAsync(user);
            _userManagerMock.Setup(m => m.ChangePasswordAsync(user, "Old", "New"))
                .ReturnsAsync(IdentityResult.Success);

            var command = new ChangePasswordCommand { UserId = "user1", CurrentPassword = "Old", NewPassword = "New" };

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            result.Succeeded.Should().BeTrue();
            _userManagerMock.Verify(m => m.ChangePasswordAsync(user, "Old", "New"), Times.Once);
        }
    }
}
