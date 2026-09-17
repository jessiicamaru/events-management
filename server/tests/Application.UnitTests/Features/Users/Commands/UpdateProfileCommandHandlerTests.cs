using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Application.Features.Users.Commands;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using Moq;
using Xunit;

namespace HabitTracker.Application.UnitTests.Features.Users.Commands
{
    public class UpdateProfileCommandHandlerTests
    {
        private readonly Mock<IUserRepository> _repositoryMock;
        private readonly UpdateProfileCommandHandler _handler;

        public UpdateProfileCommandHandlerTests()
        {
            _repositoryMock = new Mock<IUserRepository>();
            _handler = new UpdateProfileCommandHandler(_repositoryMock.Object);
        }

        [Fact]
        public async Task Handle_ShouldReturnFalse_WhenUserDoesNotExist()
        {
            // Arrange
            _repositoryMock.Setup(repo => repo.GetByIdAsync("user1")).ReturnsAsync((ApplicationUser?)null);

            var command = new UpdateProfileCommand { UserId = "user1" };

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().BeFalse();
        }

        [Fact]
        public async Task Handle_ShouldUpdateProfileFields_WhenUserExists()
        {
            // Arrange
            var birthDate = new System.DateTime(2000, 1, 1);
            var newBirthDate = new System.DateTime(1999, 12, 31);
            var user = new ApplicationUser 
            { 
                Id = "user1", 
                DisplayName = "Old Name",
                Bio = "Old Bio",
                DateOfBirth = birthDate,
                Gender = "Male",
                PhoneNumber = "123456",
                Avatar = "avatar_1"
            };

            _repositoryMock.Setup(repo => repo.GetByIdAsync("user1")).ReturnsAsync(user);
            _repositoryMock.Setup(repo => repo.UpdateAsync(user)).Returns(Task.CompletedTask);

            var command = new UpdateProfileCommand
            {
                UserId = "user1",
                DisplayName = "New Name",
                Bio = "New Bio",
                DateOfBirth = newBirthDate,
                Gender = "Female",
                PhoneNumber = "654321",
                Avatar = "avatar_2"
            };

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().BeTrue();
            user.DisplayName.Should().Be("New Name");
            user.Bio.Should().Be("New Bio");
            user.DateOfBirth.Should().Be(newBirthDate);
            user.Gender.Should().Be("Female");
            user.PhoneNumber.Should().Be("654321");
            user.Avatar.Should().Be("avatar_2");

            _repositoryMock.Verify(repo => repo.UpdateAsync(user), Times.Once);
        }
    }
}
