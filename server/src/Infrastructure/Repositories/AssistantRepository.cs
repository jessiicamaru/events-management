using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using HabitTracker.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace HabitTracker.Infrastructure.Repositories
{
    public class AssistantRepository : IAssistantRepository
    {
        private readonly ApplicationDbContext _context;

        public AssistantRepository(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<AssistantConversation> CreateConversationAsync(string userId)
        {
            var conversation = new AssistantConversation { UserId = userId };
            _context.AssistantConversations.Add(conversation);
            await _context.SaveChangesAsync();
            return conversation;
        }

        public Task<AssistantConversation?> GetConversationAsync(Guid conversationId, string userId) =>
            _context.AssistantConversations
                .AsNoTracking()
                .FirstOrDefaultAsync(c => c.Id == conversationId && c.UserId == userId);

        public async Task<IReadOnlyList<AssistantConversation>> GetConversationsAsync(string userId, int limit) =>
            await _context.AssistantConversations
                .AsNoTracking()
                .Where(c => c.UserId == userId)
                .OrderByDescending(c => c.UpdatedAt)
                .Take(limit)
                .ToListAsync();

        public async Task<IReadOnlyList<AssistantMessage>> GetMessagesAsync(Guid conversationId) =>
            await _context.AssistantMessages
                .AsNoTracking()
                .Where(m => m.ConversationId == conversationId)
                .OrderBy(m => m.Sequence)
                .ToListAsync();

        public async Task AppendMessagesAsync(Guid conversationId, IReadOnlyList<AssistantMessage> messages)
        {
            if (messages.Count == 0) return;

            var conversation = await _context.AssistantConversations.FirstAsync(c => c.Id == conversationId);
            var last = await _context.AssistantMessages
                .Where(m => m.ConversationId == conversationId)
                .Select(m => (int?)m.Sequence)
                .MaxAsync();

            var next = (last ?? -1) + 1;
            foreach (var message in messages)
            {
                message.ConversationId = conversationId;
                message.Sequence = next++;
                _context.AssistantMessages.Add(message);
            }

            conversation.UpdatedAt = messages.Max(m => m.CreatedAt);
            await _context.SaveChangesAsync();
        }

        public Task<int> CountUserMessagesSinceAsync(string userId, DateTime sinceUtc) =>
            _context.AssistantMessages
                .Where(m => m.Role == AssistantRoles.User
                    && m.CreatedAt >= sinceUtc
                    && m.Conversation!.UserId == userId)
                .CountAsync();

        public Task<UserAiSettings?> GetSettingsAsync(string userId) =>
            _context.UserAiSettings.AsNoTracking().FirstOrDefaultAsync(s => s.UserId == userId);

        public async Task SaveSettingsAsync(UserAiSettings settings)
        {
            var exists = await _context.UserAiSettings.AnyAsync(s => s.UserId == settings.UserId);
            if (exists)
            {
                _context.UserAiSettings.Update(settings);
            }
            else
            {
                _context.UserAiSettings.Add(settings);
            }

            await _context.SaveChangesAsync();
        }
    }
}
