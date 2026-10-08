using System;
using System.Linq;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Domain.Entities;
using HabitTracker.Infrastructure.Data;
using HabitTracker.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace HabitTracker.Application.Tests.Infrastructure
{
    public class AssistantRepositoryTests
    {
        private readonly ApplicationDbContext _context = new(
            new DbContextOptionsBuilder<ApplicationDbContext>()
                .UseInMemoryDatabase(Guid.NewGuid().ToString())
                .Options);

        private readonly AssistantRepository _repository;

        public AssistantRepositoryTests()
        {
            _repository = new AssistantRepository(_context);
        }

        private static AssistantMessage Message(string role, string content, DateTime? at = null) =>
            new() { Role = role, Content = content, CreatedAt = at ?? DateTime.UtcNow };

        [Fact]
        public async Task AppendMessages_ShouldNumberMessagesInOrder_AcrossCalls()
        {
            var conversation = await _repository.CreateConversationAsync("user-1");

            await _repository.AppendMessagesAsync(conversation.Id, new[] { Message(AssistantRoles.User, "a") });
            await _repository.AppendMessagesAsync(conversation.Id, new[]
            {
                Message(AssistantRoles.Assistant, "b"),
                Message(AssistantRoles.Tool, "c"),
            });

            var messages = await _repository.GetMessagesAsync(conversation.Id);
            messages.Select(m => (m.Sequence, m.Content)).Should().Equal((0, "a"), (1, "b"), (2, "c"));
        }

        [Fact]
        public async Task AppendMessages_ShouldMoveTheConversationToTheTopOfTheList()
        {
            var older = await _repository.CreateConversationAsync("user-1");
            var newer = await _repository.CreateConversationAsync("user-1");

            await _repository.AppendMessagesAsync(older.Id, new[]
            {
                Message(AssistantRoles.User, "hi", DateTime.UtcNow.AddMinutes(10)),
            });

            var list = await _repository.GetConversationsAsync("user-1", 10);
            list.Select(c => c.Id).Should().Equal(older.Id, newer.Id);
        }

        [Fact]
        public async Task GetConversation_ShouldNotReturnSomeoneElsesConversation()
        {
            var theirs = await _repository.CreateConversationAsync("user-2");

            (await _repository.GetConversationAsync(theirs.Id, "user-1")).Should().BeNull();
            (await _repository.GetConversationAsync(theirs.Id, "user-2")).Should().NotBeNull();
        }

        [Fact]
        public async Task CountUserMessagesSince_ShouldCountOnlyTheUsersOwnMessages_FromThatInstant()
        {
            var since = new DateTime(2026, 10, 4, 17, 0, 0, DateTimeKind.Utc);
            var mine = await _repository.CreateConversationAsync("user-1");
            var theirs = await _repository.CreateConversationAsync("user-2");

            await _repository.AppendMessagesAsync(mine.Id, new[]
            {
                Message(AssistantRoles.User, "yesterday", since.AddMinutes(-1)),
                Message(AssistantRoles.User, "today", since),
                Message(AssistantRoles.Assistant, "reply", since.AddMinutes(1)),
                Message(AssistantRoles.User, "again", since.AddMinutes(2)),
            });
            await _repository.AppendMessagesAsync(theirs.Id, new[] { Message(AssistantRoles.User, "not mine", since.AddMinutes(3)) });

            (await _repository.CountUserMessagesSinceAsync("user-1", since)).Should().Be(2);
        }

        [Fact]
        public async Task SaveSettings_ShouldCreateThenUpdateOneRowPerUser()
        {
            await _repository.SaveSettingsAsync(new UserAiSettings { UserId = "user-1", AssistantEnabled = true });
            _context.ChangeTracker.Clear();
            await _repository.SaveSettingsAsync(new UserAiSettings { UserId = "user-1", AssistantEnabled = false, AlwaysConfirm = true });

            _context.UserAiSettings.Should().ContainSingle();
            var saved = await _repository.GetSettingsAsync("user-1");
            saved!.AssistantEnabled.Should().BeFalse();
            saved.AlwaysConfirm.Should().BeTrue();
        }
    }
}
