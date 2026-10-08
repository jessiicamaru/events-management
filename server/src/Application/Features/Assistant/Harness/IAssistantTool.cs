using System.Text.Json;

namespace HabitTracker.Application.Features.Assistant.Harness
{
    /// <summary>
    /// Something the assistant can do. Each tool wraps a command or query the app already has,
    /// so the assistant never reaches the database any other way.
    /// </summary>
    /// <remarks>
    /// No tool takes a user id. The harness passes the signed-in user in
    /// <see cref="ToolContext"/>, so whatever the model writes, it can only act for that user.
    /// </remarks>
    public interface IAssistantTool
    {
        /// <summary>The name the model calls it by. Lower snake case.</summary>
        string Name { get; }

        /// <summary>What it does and when to use it — the model reads this to decide.</summary>
        string Description { get; }

        /// <summary>A JSON Schema object for the arguments.</summary>
        string ParametersSchemaJson { get; }

        /// <summary>
        /// Runs the tool. Bad arguments come back as <see cref="ToolResult.Error"/> rather than an
        /// exception, so the model can read what was wrong and try again.
        /// </summary>
        Task<ToolResult> ExecuteAsync(ToolContext context, JsonElement arguments, CancellationToken cancellationToken);
    }

    /// <param name="UserId">The signed-in user, from the token.</param>
    /// <param name="NowUtc">The turn's clock, so every tool in a turn agrees on "now".</param>
    /// <param name="LocalOffset">The offset "local time" means — the app-wide UTC+7 for now.</param>
    public sealed record ToolContext(string UserId, DateTime NowUtc, TimeSpan LocalOffset);

    /// <summary>What a tool returns to the model: a JSON document.</summary>
    public sealed record ToolResult(string Json, bool IsError)
    {
        public static ToolResult Ok(object value) => new(JsonSerializer.Serialize(value, ToolJson.Options), false);

        public static ToolResult Error(string message) =>
            new(JsonSerializer.Serialize(new { error = message }, ToolJson.Options), true);
    }
}
