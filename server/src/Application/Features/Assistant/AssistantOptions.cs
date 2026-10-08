namespace HabitTracker.Application.Features.Assistant
{
    /// <summary>
    /// The <c>Assistant</c> configuration section. The API key lives in the gitignored
    /// <c>appsettings.Development.json</c> (or an environment variable), never in a tracked file.
    /// </summary>
    /// <remarks>
    /// Without a key the rest of the app runs normally and the assistant's endpoints answer
    /// 503 — unlike the database, the assistant is optional.
    /// </remarks>
    public class AssistantOptions
    {
        public const string SectionName = "Assistant";

        /// <summary>Which <c>ILanguageModel</c> to use: <see cref="Providers"/>.</summary>
        public string Provider { get; set; } = Providers.DeepSeek;

        public string ApiKey { get; set; } = string.Empty;

        /// <summary>Empty means the provider's default endpoint.</summary>
        public string BaseUrl { get; set; } = string.Empty;

        /// <summary>Empty means the provider adapter's default model.</summary>
        public string Model { get; set; } = string.Empty;

        /// <summary>
        /// How hard the model thinks before answering, where the provider supports it: <c>none</c>
        /// turns thinking off. A cost and latency lever — chosen by the evaluation, not by guess.
        /// </summary>
        public string ReasoningEffort { get; set; } = "none";

        public int MaxOutputTokens { get; set; } = 2048;

        /// <summary>Tool calls allowed in one turn before the harness stops the loop.</summary>
        public int MaxToolCallsPerTurn { get; set; } = 10;

        /// <summary>Messages a user may send to the assistant per local day, across conversations.</summary>
        public int DailyMessageLimit { get; set; } = 50;

        /// <summary>How many of the latest stored messages are sent as history.</summary>
        public int HistoryMessages { get; set; } = 40;

        public int RequestTimeoutSeconds { get; set; } = 90;

        public bool IsConfigured => !string.IsNullOrWhiteSpace(ApiKey);

        public static class Providers
        {
            public const string DeepSeek = "DeepSeek";
        }
    }
}
