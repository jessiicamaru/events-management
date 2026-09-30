using System;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Application.Features.GoogleCalendar.Commands;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using Moq;
using Xunit;

namespace HabitTracker.Application.Tests
{
    public class GoogleCalendarCommandTests
    {
        private readonly Mock<IUserRepository> _mockUserRepo;
        private readonly Mock<IGoogleCalendarService> _mockGoogleCalendarService;

        public GoogleCalendarCommandTests()
        {
            _mockUserRepo = new Mock<IUserRepository>();
            _mockGoogleCalendarService = new Mock<IGoogleCalendarService>();
        }

        [Fact]
        public async Task Connect_ShouldUpdateUserTokensOnSuccess()
        {
            // Arrange
            var user = new ApplicationUser { Id = "user-123", Email = "test@example.com" };
            _mockUserRepo.Setup(r => r.GetByIdAsync("user-123")).ReturnsAsync(user);
            _mockGoogleCalendarService.Setup(s => s.ExchangeCodeForRefreshTokenAsync("user-123", "auth-code-123", It.IsAny<CancellationToken>()))
                .ReturnsAsync("refresh-token-123");

            var handler = new ConnectGoogleCalendarCommandHandler(_mockUserRepo.Object, _mockGoogleCalendarService.Object);
            var command = new ConnectGoogleCalendarCommand
            {
                UserId = "user-123",
                AuthCode = "auth-code-123",
                GoogleEmail = "google@example.com"
            };

            // Act
            var result = await handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().BeTrue();
            user.GoogleRefreshToken.Should().Be("refresh-token-123");
            user.GoogleEmail.Should().Be("google@example.com");
            _mockUserRepo.Verify(r => r.UpdateAsync(user), Times.Once);
        }

        [Fact]
        public async Task Connect_ShouldReturnFalseIfUserNotFound()
        {
            // Arrange
            _mockUserRepo.Setup(r => r.GetByIdAsync("user-123")).ReturnsAsync((ApplicationUser?)null);
            var handler = new ConnectGoogleCalendarCommandHandler(_mockUserRepo.Object, _mockGoogleCalendarService.Object);
            var command = new ConnectGoogleCalendarCommand { UserId = "user-123", AuthCode = "code", GoogleEmail = "email" };

            // Act
            var result = await handler.Handle(command, CancellationToken.None);

            // Assert
            result.Should().BeFalse();
        }

        [Fact]
        public async Task Disconnect_ShouldClearUserTokens()
        {
            // Arrange
            var user = new ApplicationUser 
            { 
                Id = "user-123", 
                GoogleEmail = "google@example.com", 
                GoogleRefreshToken = "token" 
            };
            _mockUserRepo.Setup(r => r.GetByIdAsync("user-123")).ReturnsAsync(user);
            var handler = new DisconnectGoogleCalendarCommandHandler(_mockUserRepo.Object);

            // Act
            var result = await handler.Handle(new DisconnectGoogleCalendarCommand { UserId = "user-123" }, CancellationToken.None);

            // Assert
            result.Should().BeTrue();
            user.GoogleRefreshToken.Should().BeNull();
            user.GoogleEmail.Should().BeNull();
            _mockUserRepo.Verify(r => r.UpdateAsync(user), Times.Once);
        }

        [Fact]
        public async Task Sync_ShouldCallGoogleCalendarService()
        {
            // Arrange
            var user = new ApplicationUser 
            { 
                Id = "user-123", 
                GoogleRefreshToken = "refresh-token" 
            };
            _mockUserRepo.Setup(r => r.GetByIdAsync("user-123")).ReturnsAsync(user);
            _mockGoogleCalendarService.Setup(s => s.SyncEventsAsync("user-123", "refresh-token", It.IsAny<DateTime?>(), It.IsAny<DateTime?>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(true);

            var handler = new SyncGoogleCalendarCommandHandler(_mockUserRepo.Object, _mockGoogleCalendarService.Object);

            // Act
            var result = await handler.Handle(new SyncGoogleCalendarCommand { UserId = "user-123" }, CancellationToken.None);

            // Assert
            result.Should().BeTrue();
            _mockGoogleCalendarService.Verify(s => s.SyncEventsAsync("user-123", "refresh-token", It.IsAny<DateTime?>(), It.IsAny<DateTime?>(), It.IsAny<CancellationToken>()), Times.Once);
        }

        [Fact]
        public async Task Sync_ShouldReturnFalseIfRefreshTokenMissing()
        {
            // Arrange
            var user = new ApplicationUser { Id = "user-123" }; // No token
            _mockUserRepo.Setup(r => r.GetByIdAsync("user-123")).ReturnsAsync(user);
            var handler = new SyncGoogleCalendarCommandHandler(_mockUserRepo.Object, _mockGoogleCalendarService.Object);

            // Act
            var result = await handler.Handle(new SyncGoogleCalendarCommand { UserId = "user-123" }, CancellationToken.None);

            // Assert
            result.Should().BeFalse();
        }
    }
}
