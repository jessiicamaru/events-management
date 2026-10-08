namespace HabitTracker.Domain.Interfaces
{
    /// <summary>
    /// A chat model that can call tools. The assistant's harness talks to this and nothing
    /// else, so the provider behind it — DeepSeek, Claude, a scripted fake in tests — can be
    /// swapped without touching the harness.
    /// </summary>
    public interface ILanguageModel
    {
        /// <summary>
        /// One model call: the reply to <paramref name="request"/>, which is either text or a
        /// request to run tools.
        /// </summary>
        /// <exception cref="LanguageModelException">The provider could not be reached or refused the request.</exception>
        Task<ModelResponse> CompleteAsync(ModelRequest request, CancellationToken cancellationToken);
    }

    public enum ModelRole
    {
        User,
        Assistant,
        Tool,
    }

    /// <param name="ArgumentsJson">The arguments exactly as the model wrote them, a JSON object.</param>
    public sealed record ModelToolCall(string Id, string Name, string ArgumentsJson);

    /// <summary>One message of the conversation sent to, or received from, the model.</summary>
    /// <param name="ToolCalls">On an assistant message: the tools it asked for.</param>
    /// <param name="ToolCallId">On a tool message: the call it answers.</param>
    /// <param name="ProviderData">Opaque data the same provider needs back later; see <c>AssistantMessage.ProviderData</c>.</param>
    public sealed record ModelMessage(
        ModelRole Role,
        string? Content,
        IReadOnlyList<ModelToolCall>? ToolCalls = null,
        string? ToolCallId = null,
        string? ProviderData = null);

    /// <param name="ParametersSchemaJson">A JSON Schema object describing the arguments.</param>
    public sealed record ModelToolDefinition(string Name, string Description, string ParametersSchemaJson);

    public sealed record ModelRequest(
        string SystemPrompt,
        IReadOnlyList<ModelToolDefinition> Tools,
        IReadOnlyList<ModelMessage> Messages);

    public enum ModelStopReason
    {
        /// <summary>The model finished its reply.</summary>
        EndTurn,

        /// <summary>The model wants tools run; the reply carries the calls.</summary>
        ToolUse,

        /// <summary>The reply was cut off at the output limit.</summary>
        MaxTokens,

        /// <summary>The provider declined to answer, e.g. a content filter.</summary>
        Refusal,
    }

    public sealed record ModelUsage(int InputTokens, int OutputTokens, int CachedInputTokens);

    public sealed record ModelResponse(ModelMessage Message, ModelStopReason StopReason, ModelUsage Usage);

    /// <summary>The model provider failed: unreachable, timed out, rejected the key, or returned something unreadable.</summary>
    public class LanguageModelException : Exception
    {
        public LanguageModelException(string message, Exception? inner = null) : base(message, inner) { }
    }
}
