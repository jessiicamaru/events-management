using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Text.Json.Nodes;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Application.Features.Assistant;
using HabitTracker.Domain.Interfaces;
using HabitTracker.Infrastructure.Ai;
using Xunit;

namespace HabitTracker.Application.Tests.Infrastructure
{
    /// <summary>
    /// The wire shape is the contract with DeepSeek; these pin it. The shapes were measured
    /// against the live API before being written down here.
    /// </summary>
    public class DeepSeekLanguageModelTests
    {
        private readonly AssistantOptions _options = new() { ApiKey = "sk-test", RequestTimeoutSeconds = 5 };

        private static ModelRequest Request(params ModelMessage[] messages) => new(
            "system prompt",
            new[] { new ModelToolDefinition("get_events", "List events", """{"type":"object","properties":{}}""") },
            messages);

        // ── Request ──────────────────────────────────────────────────────────────────────

        [Fact]
        public void BuildBody_ShouldPutTheSystemPromptFirst_AndDescribeEachTool()
        {
            var body = new DeepSeekLanguageModel(new HttpClient(), _options)
                .BuildBody(Request(new ModelMessage(ModelRole.User, "xin chào")));

            body["model"]!.GetValue<string>().Should().Be(DeepSeekLanguageModel.DefaultModel);
            var messages = body["messages"]!.AsArray();
            messages[0]!["role"]!.GetValue<string>().Should().Be("system");
            messages[1]!["content"]!.GetValue<string>().Should().Be("xin chào");
            var tool = body["tools"]![0]!;
            tool["type"]!.GetValue<string>().Should().Be("function");
            tool["function"]!["name"]!.GetValue<string>().Should().Be("get_events");
            tool["function"]!["parameters"]!["type"]!.GetValue<string>().Should().Be("object");
        }

        [Fact]
        public void BuildBody_ShouldTurnThinkingOff_WhenReasoningEffortIsNone()
        {
            var body = new DeepSeekLanguageModel(new HttpClient(), _options).BuildBody(Request());

            body["thinking"]!["type"]!.GetValue<string>().Should().Be("disabled");
            body.ContainsKey("reasoning_effort").Should().BeFalse();
        }

        [Fact]
        public void BuildBody_ShouldTurnThinkingOn_WithTheConfiguredEffort()
        {
            _options.ReasoningEffort = "low";

            var body = new DeepSeekLanguageModel(new HttpClient(), _options).BuildBody(Request());

            body["thinking"]!["type"]!.GetValue<string>().Should().Be("enabled");
            body["reasoning_effort"]!.GetValue<string>().Should().Be("low");
        }

        [Fact]
        public void BuildBody_ShouldSendToolCallsAndResultsBack_WithTheReasoningBehindTheCall()
        {
            var call = new ModelToolCall("call_1", "get_events", """{"from":"a","to":"b"}""");
            var body = new DeepSeekLanguageModel(new HttpClient(), _options).BuildBody(Request(
                new ModelMessage(ModelRole.User, "mai?"),
                new ModelMessage(ModelRole.Assistant, null, new[] { call }, ProviderData: """{"reasoning_content":"need events"}"""),
                new ModelMessage(ModelRole.Tool, """{"events":[]}""", ToolCallId: "call_1")));

            var assistant = body["messages"]![2]!;
            assistant["tool_calls"]![0]!["id"]!.GetValue<string>().Should().Be("call_1");
            assistant["tool_calls"]![0]!["function"]!["arguments"]!.GetValue<string>().Should().Be("""{"from":"a","to":"b"}""");
            assistant["reasoning_content"]!.GetValue<string>().Should().Be("need events");
            var tool = body["messages"]![3]!;
            tool["role"]!.GetValue<string>().Should().Be("tool");
            tool["tool_call_id"]!.GetValue<string>().Should().Be("call_1");
        }

        [Fact]
        public void BuildBody_ShouldIgnoreProviderDataItCannotRead()
        {
            var call = new ModelToolCall("c", "get_events", "{}");
            var body = new DeepSeekLanguageModel(new HttpClient(), _options).BuildBody(Request(
                new ModelMessage(ModelRole.Assistant, null, new[] { call }, ProviderData: "not json")));

            body["messages"]![1]!.AsObject().ContainsKey("reasoning_content").Should().BeFalse();
        }

        // ── Response ─────────────────────────────────────────────────────────────────────

        [Fact]
        public void ParseResponse_ShouldReadToolCalls_ReasoningAndUsage()
        {
            // As returned by the live API (deepseek-flash, thinking on), trimmed.
            const string body = """
                {"choices":[{"index":0,"finish_reason":"tool_calls","message":{"role":"assistant","content":"",
                  "reasoning_content":"The user asks about tomorrow.",
                  "tool_calls":[{"index":0,"id":"call_00_D1","type":"function","function":{"name":"get_events",
                  "arguments":"{\"from\": \"2026-09-29T00:00:00+07:00\", \"to\": \"2026-09-29T23:59:59+07:00\"}"}}]}}],
                 "usage":{"prompt_tokens":361,"completion_tokens":124,"prompt_cache_hit_tokens":128}}
                """;

            var response = DeepSeekLanguageModel.ParseResponse(body);

            response.StopReason.Should().Be(ModelStopReason.ToolUse);
            var call = response.Message.ToolCalls!.Single();
            call.Id.Should().Be("call_00_D1");
            call.Name.Should().Be("get_events");
            JsonNode.Parse(call.ArgumentsJson)!["from"]!.GetValue<string>().Should().Be("2026-09-29T00:00:00+07:00");
            JsonNode.Parse(response.Message.ProviderData!)!["reasoning_content"]!.GetValue<string>()
                .Should().Be("The user asks about tomorrow.");
            response.Usage.Should().Be(new ModelUsage(361, 124, 128));
        }

        [Theory]
        [InlineData("stop", ModelStopReason.EndTurn)]
        [InlineData("length", ModelStopReason.MaxTokens)]
        [InlineData("content_filter", ModelStopReason.Refusal)]
        public void ParseResponse_ShouldMapTheFinishReason(string finish, ModelStopReason expected)
        {
            var body = $$$"""{"choices":[{"finish_reason":"{{{finish}}}","message":{"role":"assistant","content":"hi"}}]}""";

            DeepSeekLanguageModel.ParseResponse(body).StopReason.Should().Be(expected);
        }

        [Theory]
        [InlineData("""{"choices":[{"finish_reason":"insufficient_system_resource","message":{"content":""}}]}""")]
        [InlineData("""{"error":{"message":"bad"}}""")]
        [InlineData("<html>gateway</html>")]
        public void ParseResponse_ShouldFail_OnAnythingThatIsNotAnAnswer(string body)
        {
            var parse = () => DeepSeekLanguageModel.ParseResponse(body);

            parse.Should().Throw<LanguageModelException>();
        }

        // ── Transport ────────────────────────────────────────────────────────────────────

        [Fact]
        public async Task CompleteAsync_ShouldSendTheKeyAsABearerToken()
        {
            var handler = new StubHandler(HttpStatusCode.OK,
                """{"choices":[{"finish_reason":"stop","message":{"content":"ok"}}]}""");

            await new DeepSeekLanguageModel(new HttpClient(handler), _options).CompleteAsync(Request(), CancellationToken.None);

            handler.Requests.Single().Headers.Authorization!.ToString().Should().Be("Bearer sk-test");
            handler.Requests.Single().RequestUri!.ToString().Should().Be("https://api.deepseek.com/chat/completions");
        }

        [Fact]
        public async Task CompleteAsync_ShouldReportAnErrorStatus_WithoutTheKey()
        {
            var handler = new StubHandler(HttpStatusCode.Unauthorized, """{"error":{"message":"Authentication Fails"}}""");

            var call = () => new DeepSeekLanguageModel(new HttpClient(handler), _options).CompleteAsync(Request(), CancellationToken.None);

            (await call.Should().ThrowAsync<LanguageModelException>())
                .Which.Message.Should().Contain("401").And.NotContain("sk-test");
        }

        [Fact]
        public async Task CompleteAsync_ShouldReportATimeout_AsAModelFailure()
        {
            _options.RequestTimeoutSeconds = 1;
            var handler = new StubHandler(HttpStatusCode.OK, "{}", delay: TimeSpan.FromSeconds(10));

            var call = () => new DeepSeekLanguageModel(new HttpClient(handler), _options).CompleteAsync(Request(), CancellationToken.None);

            (await call.Should().ThrowAsync<LanguageModelException>()).Which.Message.Should().Contain("within 1 s");
        }

        private sealed class StubHandler : HttpMessageHandler
        {
            private readonly HttpStatusCode _status;
            private readonly string _body;
            private readonly TimeSpan _delay;

            public StubHandler(HttpStatusCode status, string body, TimeSpan? delay = null)
            {
                _status = status;
                _body = body;
                _delay = delay ?? TimeSpan.Zero;
            }

            public List<HttpRequestMessage> Requests { get; } = new();

            protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
            {
                Requests.Add(request);
                if (_delay > TimeSpan.Zero) await Task.Delay(_delay, cancellationToken);
                return new HttpResponseMessage(_status) { Content = new StringContent(_body, Encoding.UTF8, "application/json") };
            }
        }
    }
}
