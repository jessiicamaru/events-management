using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using HabitTracker.Application.Features.Assistant;
using HabitTracker.Domain.Interfaces;

namespace HabitTracker.Infrastructure.Ai
{
    /// <summary>
    /// <see cref="ILanguageModel"/> over DeepSeek's chat completions API, which follows the
    /// OpenAI shape: <c>tools</c> in, <c>tool_calls</c> out, tool results sent back as
    /// <c>role: "tool"</c> messages.
    /// </summary>
    /// <remarks>
    /// With thinking on, a reply carries <c>reasoning_content</c>. It is kept as the message's
    /// provider data and sent back on the assistant message that made the tool calls, which the
    /// API accepts (measured) and which keeps the model's reasoning across a tool round-trip.
    /// </remarks>
    public class DeepSeekLanguageModel : ILanguageModel
    {
        public const string DefaultBaseUrl = "https://api.deepseek.com";
        public const string DefaultModel = "deepseek-flash";
        public const string ReasoningOff = "none";

        private const string ReasoningKey = "reasoning_content";

        private readonly HttpClient _http;
        private readonly AssistantOptions _options;

        public DeepSeekLanguageModel(HttpClient http, AssistantOptions options)
        {
            _http = http;
            _options = options;
        }

        public async Task<ModelResponse> CompleteAsync(ModelRequest request, CancellationToken cancellationToken)
        {
            var baseUrl = string.IsNullOrWhiteSpace(_options.BaseUrl) ? DefaultBaseUrl : _options.BaseUrl.TrimEnd('/');
            using var message = new HttpRequestMessage(HttpMethod.Post, $"{baseUrl}/chat/completions")
            {
                Content = new StringContent(BuildBody(request).ToJsonString(), Encoding.UTF8, "application/json"),
            };
            message.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _options.ApiKey);

            using var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
            timeout.CancelAfter(TimeSpan.FromSeconds(_options.RequestTimeoutSeconds));

            string body;
            try
            {
                using var response = await _http.SendAsync(message, timeout.Token);
                body = await response.Content.ReadAsStringAsync(timeout.Token);
                if (!response.IsSuccessStatusCode)
                {
                    // The status and the provider's error, never the request: it holds the key.
                    throw new LanguageModelException($"DeepSeek returned {(int)response.StatusCode}: {Truncate(body)}");
                }
            }
            catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested)
            {
                throw new LanguageModelException($"DeepSeek did not answer within {_options.RequestTimeoutSeconds} s.");
            }
            catch (HttpRequestException ex)
            {
                throw new LanguageModelException("DeepSeek could not be reached.", ex);
            }

            return ParseResponse(body);
        }

        /// <summary>The request body. Public for tests: the wire shape is the contract with the provider.</summary>
        public JsonObject BuildBody(ModelRequest request)
        {
            var messages = new JsonArray { new JsonObject { ["role"] = "system", ["content"] = request.SystemPrompt } };
            foreach (var m in request.Messages)
            {
                messages.Add(ToWire(m));
            }

            var body = new JsonObject
            {
                ["model"] = string.IsNullOrWhiteSpace(_options.Model) ? DefaultModel : _options.Model,
                ["messages"] = messages,
                ["max_tokens"] = _options.MaxOutputTokens,
            };

            if (request.Tools.Count > 0)
            {
                body["tools"] = new JsonArray(request.Tools.Select(t => (JsonNode)new JsonObject
                {
                    ["type"] = "function",
                    ["function"] = new JsonObject
                    {
                        ["name"] = t.Name,
                        ["description"] = t.Description,
                        ["parameters"] = JsonNode.Parse(t.ParametersSchemaJson),
                    },
                }).ToArray());
            }

            var effort = string.IsNullOrWhiteSpace(_options.ReasoningEffort) ? ReasoningOff : _options.ReasoningEffort;
            if (string.Equals(effort, ReasoningOff, StringComparison.OrdinalIgnoreCase))
            {
                body["thinking"] = new JsonObject { ["type"] = "disabled" };
            }
            else
            {
                body["thinking"] = new JsonObject { ["type"] = "enabled" };
                body["reasoning_effort"] = effort;
            }

            return body;
        }

        /// <summary>Reads a completion. Public for tests.</summary>
        public static ModelResponse ParseResponse(string body)
        {
            JsonNode? root;
            try
            {
                root = JsonNode.Parse(body);
            }
            catch (JsonException ex)
            {
                throw new LanguageModelException("DeepSeek returned something that is not JSON.", ex);
            }

            var choice = root?["choices"]?[0];
            var wire = choice?["message"];
            if (wire == null) throw new LanguageModelException($"DeepSeek returned no message: {Truncate(body)}");

            var toolCalls = wire["tool_calls"]?.AsArray()
                .Select(c => new ModelToolCall(
                    c!["id"]!.GetValue<string>(),
                    c["function"]!["name"]!.GetValue<string>(),
                    c["function"]!["arguments"]?.GetValue<string>() ?? "{}"))
                .ToList();

            var reasoning = wire[ReasoningKey]?.GetValue<string>();
            var providerData = string.IsNullOrEmpty(reasoning)
                ? null
                : new JsonObject { [ReasoningKey] = reasoning }.ToJsonString();

            var stop = choice!["finish_reason"]?.GetValue<string>() switch
            {
                "stop" => ModelStopReason.EndTurn,
                "tool_calls" => ModelStopReason.ToolUse,
                "length" => ModelStopReason.MaxTokens,
                "content_filter" => ModelStopReason.Refusal,
                var other => throw new LanguageModelException($"DeepSeek stopped with '{other}'."),
            };

            var usage = root!["usage"];
            return new ModelResponse(
                new ModelMessage(
                    ModelRole.Assistant,
                    wire["content"]?.GetValue<string>(),
                    toolCalls is { Count: > 0 } ? toolCalls : null,
                    ProviderData: providerData),
                stop,
                new ModelUsage(
                    usage?["prompt_tokens"]?.GetValue<int>() ?? 0,
                    usage?["completion_tokens"]?.GetValue<int>() ?? 0,
                    usage?["prompt_cache_hit_tokens"]?.GetValue<int>() ?? 0));
        }

        private static JsonObject ToWire(ModelMessage m)
        {
            switch (m.Role)
            {
                case ModelRole.User:
                    return new JsonObject { ["role"] = "user", ["content"] = m.Content ?? string.Empty };

                case ModelRole.Tool:
                    return new JsonObject
                    {
                        ["role"] = "tool",
                        ["tool_call_id"] = m.ToolCallId,
                        ["content"] = m.Content ?? string.Empty,
                    };

                default:
                    var wire = new JsonObject { ["role"] = "assistant", ["content"] = m.Content ?? string.Empty };
                    if (m.ToolCalls is { Count: > 0 })
                    {
                        wire["tool_calls"] = new JsonArray(m.ToolCalls.Select(c => (JsonNode)new JsonObject
                        {
                            ["id"] = c.Id,
                            ["type"] = "function",
                            ["function"] = new JsonObject { ["name"] = c.Name, ["arguments"] = c.ArgumentsJson },
                        }).ToArray());

                        var reasoning = ReadReasoning(m.ProviderData);
                        if (reasoning != null) wire[ReasoningKey] = reasoning;
                    }
                    return wire;
            }
        }

        private static string? ReadReasoning(string? providerData)
        {
            if (string.IsNullOrEmpty(providerData)) return null;
            try
            {
                return JsonNode.Parse(providerData)?[ReasoningKey]?.GetValue<string>();
            }
            catch (JsonException)
            {
                // Written by another provider's adapter; not ours to send.
                return null;
            }
        }

        private static string Truncate(string text, int max = 300) =>
            text.Length <= max ? text : text[..max] + "…";
    }
}
