using System;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Application.Features.EventCategories.Commands;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using Moq;
using Xunit;

namespace HabitTracker.Application.UnitTests.Features.EventCategories
{
    public class CreateEventCategoryCommandHandlerTests
    {
        private readonly Mock<IEventCategoryRepository> _mockRepository;
        private readonly CreateEventCategoryCommandHandler _handler;

        public CreateEventCategoryCommandHandlerTests()
        {
            _mockRepository = new Mock<IEventCategoryRepository>();
            _handler = new CreateEventCategoryCommandHandler(_mockRepository.Object);
        }

        [Fact]
        public async Task Handle_ValidRequest_CreatesCategory()
        {
            // Arrange
            var command = new CreateEventCategoryCommand
            {
                Name = "Work",
                ColorPreset = "Blue",
                UserId = "user-123"
            };

            _mockRepository.Setup(r => r.AddAsync(It.IsAny<EventCategory>()))
                .ReturnsAsync((EventCategory category) => category);

            // Act
            var result = await _handler.Handle(command, CancellationToken.None);

            // Assert
            Assert.NotEqual(Guid.Empty, result);
            _mockRepository.Verify(r => r.AddAsync(It.Is<EventCategory>(c => 
                c.Name == "Work" && 
                c.ColorPreset == "Blue" && 
                c.UserId == "user-123"
            )), Times.Once);
        }
    }
}
