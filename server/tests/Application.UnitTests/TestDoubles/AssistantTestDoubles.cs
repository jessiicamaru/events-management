using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Application.Features.Assistant.Harness;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;

namespace HabitTracker.Application.Tests.TestDoubles
{
    /// <summary>
    /// A language model that plays back a script, and records every request it was sent — so a
    /// test decides exactly what "the model" does and checks what the harness showed it.
    /// </summary>
    public class ScriptedLanguageModel : ILanguageModel
    {
        private readonly Queue<Func<ModelRequest, ModelResponse>> _script = new();

        public List<ModelRequest> Requests { get; } = new();

        public ScriptedLanguageModel Replies(string text, ModelStopReason stop = ModelStopReason.EndTurn)
        {
            _script.Enqueue(_ => Response(new ModelMessage(ModelRole.Assistant, text), stop));
            return this;
        }

        public ScriptedLanguageModel CallsTools(params ModelToolCall[] calls)
        {
            _script.Enqueue(_ => Response(new ModelMessage(ModelRole.Assistant, null, calls), ModelStopReason.ToolUse));
            return this;
        }

        public ScriptedLanguageModel Fails()
        {
            _script.Enqueue(_ => throw new LanguageModelException("scripted failure"));
            return this;
        }

        public Task<ModelResponse> CompleteAsync(ModelRequest request, CancellationToken cancellationToken)
        {
            Requests.Add(request);
            if (_script.Count == 0) throw new InvalidOperationException("The model was called more times than scripted.");
            return Task.FromResult(_script.Dequeue()(request));
        }

        public static ModelToolCall Call(string name, object? arguments = null, string? id = null) =>
            new(id ?? $"call_{Guid.NewGuid():N}", name, JsonSerializer.Serialize(arguments ?? new { }));

        private static ModelResponse Response(ModelMessage message, ModelStopReason stop) =>
            new(message, stop, new ModelUsage(100, 20, 0));
    }

    /// <summary>A tool that records what it was given and returns a fixed result.</summary>
    public class RecordingTool : IAssistantTool
    {
        private readonly Func<ToolContext, JsonElement, ToolResult> _run;

        public RecordingTool(string name, Func<ToolContext, JsonElement, ToolResult>? run = null)
        {
            Name = name;
            _run = run ?? ((_, _) => ToolResult.Ok(new { ok = true }));
        }

        public string Name { get; }
        public string Description => $"The {Name} tool.";
        public string ParametersSchemaJson => """{ "type": "object", "properties": {} }""";

        public List<(ToolContext Context, JsonElement Arguments)> Calls { get; } = new();

        public Task<ToolResult> ExecuteAsync(ToolContext context, JsonElement arguments, CancellationToken cancellationToken)
        {
            Calls.Add((context, arguments.Clone()));
            return Task.FromResult(_run(context, arguments));
        }
    }

    /// <summary>The assistant repository in memory, with the same numbering and ownership rules.</summary>
    public class InMemoryAssistantRepository : IAssistantRepository
    {
        public List<AssistantConversation> Conversations { get; } = new();
        public List<AssistantMessage> Messages { get; } = new();
        public List<UserAiSettings> Settings { get; } = new();

        public AssistantConversation AddConversation(string userId)
        {
            var conversation = new AssistantConversation { UserId = userId };
            Conversations.Add(conversation);
            return conversation;
        }

        public Task<AssistantConversation> CreateConversationAsync(string userId) => Task.FromResult(AddConversation(userId));

        public Task<AssistantConversation?> GetConversationAsync(Guid conversationId, string userId) =>
            Task.FromResult(Conversations.FirstOrDefault(c => c.Id == conversationId && c.UserId == userId));

        public Task<IReadOnlyList<AssistantConversation>> GetConversationsAsync(string userId, int limit) =>
            Task.FromResult<IReadOnlyList<AssistantConversation>>(
                Conversations.Where(c => c.UserId == userId).OrderByDescending(c => c.UpdatedAt).Take(limit).ToList());

        public Task<IReadOnlyList<AssistantMessage>> GetMessagesAsync(Guid conversationId) =>
            Task.FromResult<IReadOnlyList<AssistantMessage>>(
                Messages.Where(m => m.ConversationId == conversationId).OrderBy(m => m.Sequence).ToList());

        public Task AppendMessagesAsync(Guid conversationId, IReadOnlyList<AssistantMessage> messages)
        {
            var next = Messages.Where(m => m.ConversationId == conversationId).Select(m => m.Sequence + 1).DefaultIfEmpty(0).Max();
            foreach (var message in messages)
            {
                message.ConversationId = conversationId;
                message.Sequence = next++;
                Messages.Add(message);
            }
            return Task.CompletedTask;
        }

        public Task<int> CountUserMessagesSinceAsync(string userId, DateTime sinceUtc)
        {
            var mine = Conversations.Where(c => c.UserId == userId).Select(c => c.Id).ToHashSet();
            return Task.FromResult(Messages.Count(m =>
                m.Role == AssistantRoles.User && m.CreatedAt >= sinceUtc && mine.Contains(m.ConversationId)));
        }

        public Task<UserAiSettings?> GetSettingsAsync(string userId) =>
            Task.FromResult(Settings.FirstOrDefault(s => s.UserId == userId));

        public Task SaveSettingsAsync(UserAiSettings settings)
        {
            Settings.RemoveAll(s => s.UserId == settings.UserId);
            Settings.Add(settings);
            return Task.CompletedTask;
        }
    }

    /// <summary>A clock that says what the test tells it to.</summary>
    public class FixedTimeProvider : TimeProvider
    {
        public FixedTimeProvider(DateTime utcNow)
        {
            UtcNow = DateTime.SpecifyKind(utcNow, DateTimeKind.Utc);
        }

        public DateTime UtcNow { get; set; }

        public override DateTimeOffset GetUtcNow() => new(UtcNow);
    }
}
