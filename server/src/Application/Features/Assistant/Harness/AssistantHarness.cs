using System.Text.Json;
using HabitTracker.Application.Common;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;

namespace HabitTracker.Application.Features.Assistant.Harness
{
    public enum AssistantTurnStatus
    {
        /// <summary>The model answered.</summary>
        Completed,

        /// <summary>The answer was cut off at the output limit; what there is was kept.</summary>
        Truncated,

        /// <summary>The provider declined to answer.</summary>
        Refused,

        /// <summary>The model kept calling tools past <see cref="AssistantOptions.MaxToolCallsPerTurn"/>.</summary>
        StepLimitReached,

        /// <summary>The provider failed; the user's message is kept so they can retry.</summary>
        ModelUnavailable,

        /// <summary>No API key is configured on the server.</summary>
        NotConfigured,

        /// <summary>The user has not turned the assistant on.</summary>
        Disabled,

        DailyLimitReached,

        ConversationNotFound,
    }

    /// <param name="Reply">The assistant's text for this turn, if it wrote any.</param>
    /// <param name="ToolsUsed">The tools that ran this turn, in order.</param>
    public sealed record AssistantTurnResult(
        AssistantTurnStatus Status,
        string? Reply = null,
        IReadOnlyList<string>? ToolsUsed = null);

    /// <summary>
    /// The assistant's loop: send the conversation to the model, run the tools it asks for,
    /// send their results back, and repeat until it answers.
    /// </summary>
    /// <remarks>
    /// <para>
    /// Rules the loop keeps whatever the model does:
    /// </para>
    /// <list type="bullet">
    /// <item>Every tool call gets exactly one result, sent back together — a provider rejects
    /// a conversation with an unanswered call.</item>
    /// <item>A tool runs as the signed-in user (<see cref="ToolContext"/>); no argument can
    /// change whose data it touches.</item>
    /// <item>An unknown tool or bad arguments come back to the model as an error result, so it
    /// can correct itself, instead of failing the turn.</item>
    /// <item>The history is append-only, and each message is saved as soon as it exists.</item>
    /// </list>
    /// <para>
    /// This version has read tools only. Writing tools, and the confirmation and undo they
    /// need, come on top of this loop.
    /// </para>
    /// </remarks>
    public class AssistantHarness
    {
        private readonly ILanguageModel _model;
        private readonly IAssistantRepository _repository;
        private readonly IReadOnlyList<IAssistantTool> _tools;
        private readonly IAssistantProgress _progress;
        private readonly AssistantOptions _options;
        private readonly TimeProvider _clock;

        public AssistantHarness(
            ILanguageModel model,
            IAssistantRepository repository,
            IEnumerable<IAssistantTool> tools,
            IAssistantProgress progress,
            AssistantOptions options,
            TimeProvider clock)
        {
            _model = model;
            _repository = repository;
            _tools = tools.ToList();
            _progress = progress;
            _options = options;
            _clock = clock;
        }

        public async Task<AssistantTurnResult> RunTurnAsync(
            string userId, Guid conversationId, string text, CancellationToken cancellationToken)
        {
            if (string.IsNullOrEmpty(userId)) throw new ArgumentException("UserId is required.", nameof(userId));

            if (!_options.IsConfigured) return new(AssistantTurnStatus.NotConfigured);

            var settings = await _repository.GetSettingsAsync(userId);
            if (settings is not { AssistantEnabled: true }) return new(AssistantTurnStatus.Disabled);

            if (await _repository.GetConversationAsync(conversationId, userId) == null)
            {
                return new(AssistantTurnStatus.ConversationNotFound);
            }

            var nowUtc = _clock.GetUtcNow().UtcDateTime;
            var offset = StreakCalculator.DefaultDayBoundaryOffset;
            var startOfLocalDay = DateTime.SpecifyKind(StreakCalculator.ToLocalDate(nowUtc, offset) - offset, DateTimeKind.Utc);
            if (await _repository.CountUserMessagesSinceAsync(userId, startOfLocalDay) >= _options.DailyMessageLimit)
            {
                return new(AssistantTurnStatus.DailyLimitReached);
            }

            var history = (await _repository.GetMessagesAsync(conversationId)).ToList();
            var userMessage = new AssistantMessage { Role = AssistantRoles.User, Content = text, CreatedAt = nowUtc };
            await _repository.AppendMessagesAsync(conversationId, new[] { userMessage });
            history.Add(userMessage);

            var context = new ToolContext(userId, nowUtc, offset);
            var definitions = _tools
                .Select(t => new ModelToolDefinition(t.Name, t.Description, t.ParametersSchemaJson))
                .ToList();
            var toolsUsed = new List<string>();

            while (true)
            {
                ModelResponse response;
                try
                {
                    response = await _model.CompleteAsync(
                        new ModelRequest(AssistantPrompt.System, definitions, ToModelMessages(history, offset)),
                        cancellationToken);
                }
                catch (LanguageModelException)
                {
                    return new(AssistantTurnStatus.ModelUnavailable, ToolsUsed: toolsUsed);
                }

                var calls = response.Message.ToolCalls ?? Array.Empty<ModelToolCall>();
                var assistantMessage = new AssistantMessage
                {
                    Role = AssistantRoles.Assistant,
                    Content = response.Message.Content,
                    ToolCallsJson = calls.Count == 0 ? null : JsonSerializer.Serialize(calls, ToolJson.Options),
                    ProviderData = response.Message.ProviderData,
                    CreatedAt = _clock.GetUtcNow().UtcDateTime,
                };

                if (response.StopReason != ModelStopReason.ToolUse || calls.Count == 0)
                {
                    await _repository.AppendMessagesAsync(conversationId, new[] { assistantMessage });
                    return new(StatusFor(response.StopReason), response.Message.Content, toolsUsed);
                }

                if (toolsUsed.Count + calls.Count > _options.MaxToolCallsPerTurn)
                {
                    // Not saved: an assistant message whose calls go unanswered would make every
                    // later request in this conversation invalid.
                    return new(AssistantTurnStatus.StepLimitReached, ToolsUsed: toolsUsed);
                }

                var results = new List<AssistantMessage>(calls.Count);
                foreach (var call in calls)
                {
                    await _progress.ToolStartedAsync(userId, conversationId, call.Name);
                    var result = await RunToolAsync(call, context, cancellationToken);
                    await _progress.ToolFinishedAsync(userId, conversationId, call.Name, result.IsError);

                    toolsUsed.Add(call.Name);
                    results.Add(new AssistantMessage
                    {
                        Role = AssistantRoles.Tool,
                        ToolCallId = call.Id,
                        ToolName = call.Name,
                        Content = result.Json,
                        CreatedAt = _clock.GetUtcNow().UtcDateTime,
                    });
                }

                // The call and its answers are saved together, so the stored history never holds
                // a call without its result.
                await _repository.AppendMessagesAsync(conversationId, results.Prepend(assistantMessage).ToList());
                history.Add(assistantMessage);
                history.AddRange(results);
            }
        }

        private async Task<ToolResult> RunToolAsync(ModelToolCall call, ToolContext context, CancellationToken cancellationToken)
        {
            var tool = _tools.FirstOrDefault(t => t.Name == call.Name);
            if (tool == null)
            {
                return ToolResult.Error($"There is no tool called '{call.Name}'.");
            }

            JsonElement arguments;
            try
            {
                using var document = JsonDocument.Parse(string.IsNullOrWhiteSpace(call.ArgumentsJson) ? "{}" : call.ArgumentsJson);
                arguments = document.RootElement.Clone();
            }
            catch (JsonException)
            {
                return ToolResult.Error("The arguments were not valid JSON.");
            }

            if (arguments.ValueKind != JsonValueKind.Object)
            {
                return ToolResult.Error("The arguments must be a JSON object.");
            }

            try
            {
                return await tool.ExecuteAsync(context, arguments, cancellationToken);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                // One tool failing should not end the turn: the model can tell the user it
                // could not look that up. The detail stays on the server.
                return ToolResult.Error($"The tool '{call.Name}' failed. Tell the user it could not be done right now.");
            }
        }

        /// <summary>
        /// The stored history as the model sees it: the latest <see cref="AssistantOptions.HistoryMessages"/>
        /// messages, starting at a user message so no tool result is sent without its call.
        /// </summary>
        private List<ModelMessage> ToModelMessages(IReadOnlyList<AssistantMessage> history, TimeSpan offset)
        {
            var start = Math.Max(0, history.Count - _options.HistoryMessages);
            while (start < history.Count && history[start].Role != AssistantRoles.User) start++;

            return history.Skip(start).Select(m => m.Role switch
            {
                AssistantRoles.User => new ModelMessage(
                    ModelRole.User, AssistantPrompt.TurnContext(m.CreatedAt, offset) + "\n" + m.Content),
                AssistantRoles.Tool => new ModelMessage(ModelRole.Tool, m.Content, ToolCallId: m.ToolCallId),
                _ => new ModelMessage(
                    ModelRole.Assistant,
                    m.Content,
                    ToolCalls: m.ToolCallsJson == null
                        ? null
                        : JsonSerializer.Deserialize<List<ModelToolCall>>(m.ToolCallsJson, ToolJson.Options),
                    ProviderData: m.ProviderData),
            }).ToList();
        }

        private static AssistantTurnStatus StatusFor(ModelStopReason reason) => reason switch
        {
            ModelStopReason.MaxTokens => AssistantTurnStatus.Truncated,
            ModelStopReason.Refusal => AssistantTurnStatus.Refused,
            _ => AssistantTurnStatus.Completed,
        };
    }
}
