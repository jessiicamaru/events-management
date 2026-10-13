using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Application.Features.Assistant;
using HabitTracker.Application.Features.Assistant.Harness;
using HabitTracker.Application.Tests.TestDoubles;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using Xunit;
using static HabitTracker.Application.Tests.TestDoubles.ScriptedLanguageModel;

namespace HabitTracker.Application.Tests.Features.Assistant
{
    public class AssistantHarnessTests
    {
        private const string UserId = "user-1";

        // 10:00 on Monday 5 October 2026 in UTC+7.
        private static readonly DateTime Now = new(2026, 10, 5, 3, 0, 0, DateTimeKind.Utc);

        private readonly ScriptedLanguageModel _model = new();
        private readonly InMemoryAssistantRepository _repository = new();
        private readonly FixedTimeProvider _clock = new(Now);
        private readonly AssistantOptions _options = new() { ApiKey = "test-key", MaxToolCallsPerTurn = 4, DailyMessageLimit = 3, HistoryMessages = 40 };
        private readonly RecordingTool _events = new("get_events");
        private readonly RecordingTool _habits = new("get_habits");
        private readonly AssistantConversation _conversation;

        public AssistantHarnessTests()
        {
            _conversation = _repository.AddConversation(UserId);
            _repository.Settings.Add(new UserAiSettings { UserId = UserId, AssistantEnabled = true });
        }

        private AssistantHarness Harness(IAssistantProgress? progress = null) =>
            new(_model, _repository, new IAssistantTool[] { _events, _habits }, progress ?? new NoAssistantProgress(), _options, _clock);

        private Task<AssistantTurnResult> Send(string text = "Mai mình có lịch gì?") =>
            Harness().RunTurnAsync(UserId, _conversation.Id, text, CancellationToken.None);

        // ── Answering ────────────────────────────────────────────────────────────────────

        [Fact]
        public async Task RunTurn_ShouldReturnTheModelsReply_AndStoreBothMessages()
        {
            _model.Replies("Mai bạn trống lịch.");

            var result = await Send("Mai mình có lịch gì?");

            result.Status.Should().Be(AssistantTurnStatus.Completed);
            result.Reply.Should().Be("Mai bạn trống lịch.");
            _repository.Messages.Select(m => (m.Role, m.Content)).Should().Equal(
                (AssistantRoles.User, "Mai mình có lịch gì?"),
                (AssistantRoles.Assistant, "Mai bạn trống lịch."));
        }

        [Fact]
        public async Task RunTurn_ShouldTellTheModelTheUsersLocalTime_WithoutStoringIt()
        {
            _model.Replies("ok");

            await Send("Hôm nay thứ mấy?");

            var sent = _model.Requests.Single().Messages.Single();
            sent.Content.Should().StartWith("[Context: the user's local time is 2026-10-05T10:00+07:00, a Monday.]");
            sent.Content.Should().EndWith("Hôm nay thứ mấy?");
            _repository.Messages[0].Content.Should().Be("Hôm nay thứ mấy?");
        }

        [Fact]
        public async Task RunTurn_ShouldKeepTheSystemPromptFreeOfPerTurnData_SoItCanBeCached()
        {
            _model.Replies("a").Replies("b");

            await Send("một");
            _clock.UtcNow = Now.AddHours(5);
            await Send("hai");

            _model.Requests[0].SystemPrompt.Should().Be(_model.Requests[1].SystemPrompt);
            // The first message is sent the same way the second time, so the prefix is stable.
            _model.Requests[1].Messages[0].Should().Be(_model.Requests[0].Messages[0]);
        }

        // ── Tools ────────────────────────────────────────────────────────────────────────

        [Fact]
        public async Task RunTurn_ShouldRunTheToolTheModelAsksFor_AndSendItsResultBack()
        {
            _model.CallsTools(Call("get_events", new { from = "2026-10-06T00:00+07:00", to = "2026-10-07T00:00+07:00" }, "c1"))
                  .Replies("Mai bạn chạy bộ lúc 06:00.");

            var result = await Send();

            result.Status.Should().Be(AssistantTurnStatus.Completed);
            result.ToolsUsed.Should().Equal("get_events");
            _events.Calls.Should().ContainSingle();
            _events.Calls[0].Arguments.GetProperty("from").GetString().Should().Be("2026-10-06T00:00+07:00");

            var second = _model.Requests[1].Messages;
            second.Select(m => m.Role).Should().Equal(ModelRole.User, ModelRole.Assistant, ModelRole.Tool);
            second[1].ToolCalls!.Single().Id.Should().Be("c1");
            second[2].ToolCallId.Should().Be("c1");
            second[2].Content.Should().Be("""{"ok":true}""");
        }

        [Fact]
        public async Task RunTurn_ShouldRunToolsAsTheSignedInUser_WhateverTheArgumentsSay()
        {
            _model.CallsTools(Call("get_events", new { userId = "someone-else", from = "x", to = "y" }))
                  .Replies("ok");

            await Send();

            _events.Calls.Single().Context.UserId.Should().Be(UserId);
        }

        [Fact]
        public async Task RunTurn_ShouldAnswerEveryCall_WhenTheModelAsksForSeveralAtOnce()
        {
            _model.CallsTools(Call("get_events", id: "a"), Call("get_habits", id: "b"))
                  .Replies("ok");

            await Send();

            var toolMessages = _model.Requests[1].Messages.Where(m => m.Role == ModelRole.Tool).ToList();
            toolMessages.Select(m => m.ToolCallId).Should().Equal("a", "b");
            _repository.Messages.Where(m => m.Role == AssistantRoles.Tool).Select(m => m.ToolName)
                .Should().Equal("get_events", "get_habits");
        }

        [Fact]
        public async Task RunTurn_ShouldReportAnUnknownToolToTheModel_AndCarryOn()
        {
            _model.CallsTools(Call("delete_everything", id: "x")).Replies("Mình không làm được việc đó.");

            var result = await Send();

            result.Status.Should().Be(AssistantTurnStatus.Completed);
            _model.Requests[1].Messages.Last().Content.Should().Contain("There is no tool called 'delete_everything'");
        }

        [Fact]
        public async Task RunTurn_ShouldReportArgumentsThatAreNotJson_AndCarryOn()
        {
            _model.CallsTools(new ModelToolCall("x", "get_events", "{not json")).Replies("ok");

            await Send();

            _events.Calls.Should().BeEmpty();
            _model.Requests[1].Messages.Last().Content.Should().Contain("not valid JSON");
        }

        [Fact]
        public async Task RunTurn_ShouldTurnAToolsExceptionIntoAnErrorResult_AndCarryOn()
        {
            var failing = new RecordingTool("get_events", (_, _) => throw new InvalidOperationException("database down"));
            var harness = new AssistantHarness(_model, _repository, new IAssistantTool[] { failing }, new NoAssistantProgress(), _options, _clock);
            _model.CallsTools(Call("get_events")).Replies("Mình chưa xem được lịch.");

            var result = await harness.RunTurnAsync(UserId, _conversation.Id, "lịch?", CancellationToken.None);

            result.Status.Should().Be(AssistantTurnStatus.Completed);
            var sent = _model.Requests[1].Messages.Last().Content;
            sent.Should().Contain("failed").And.NotContain("database down");
        }

        [Fact]
        public async Task RunTurn_ShouldStop_WhenTheModelKeepsCallingTools_WithoutStoringAnUnansweredCall()
        {
            for (var i = 0; i < 10; i++) _model.CallsTools(Call("get_events"));

            var result = await Send();

            result.Status.Should().Be(AssistantTurnStatus.StepLimitReached);
            result.ToolsUsed.Should().HaveCount(_options.MaxToolCallsPerTurn);
            _events.Calls.Should().HaveCount(_options.MaxToolCallsPerTurn);
            EveryStoredCallHasItsResult().Should().BeTrue();
        }

        [Fact]
        public async Task RunTurn_ShouldReportProgressForEachTool()
        {
            var progress = new RecordingProgress();
            _model.CallsTools(Call("get_events"), Call("get_habits")).Replies("ok");

            await Harness(progress).RunTurnAsync(UserId, _conversation.Id, "hi", CancellationToken.None);

            progress.Events.Should().Equal(
                "start get_events", "finish get_events", "start get_habits", "finish get_habits");
        }

        // ── Refusing before the model is called ──────────────────────────────────────────

        [Fact]
        public async Task RunTurn_ShouldRefuse_WhenNoKeyIsConfigured()
        {
            _options.ApiKey = "";

            (await Send()).Status.Should().Be(AssistantTurnStatus.NotConfigured);
            _model.Requests.Should().BeEmpty();
        }

        [Fact]
        public async Task RunTurn_ShouldRefuse_WhenTheUserHasNotTurnedTheAssistantOn()
        {
            _repository.Settings.Clear();

            (await Send()).Status.Should().Be(AssistantTurnStatus.Disabled);
            _repository.Messages.Should().BeEmpty();
        }

        [Fact]
        public async Task RunTurn_ShouldRefuse_AConversationThatIsNotTheCallers()
        {
            var theirs = _repository.AddConversation("user-2");

            var result = await Harness().RunTurnAsync(UserId, theirs.Id, "hi", CancellationToken.None);

            result.Status.Should().Be(AssistantTurnStatus.ConversationNotFound);
            _repository.Messages.Should().BeEmpty();
        }

        [Fact]
        public async Task RunTurn_ShouldRefuse_OnceTheDailyLimitIsUsed_AndCountFromLocalMidnight()
        {
            _model.Replies("1").Replies("2").Replies("3").Replies("4");
            // 23:30 on the 4th, local: yesterday, so it does not count.
            _clock.UtcNow = new DateTime(2026, 10, 4, 16, 30, 0, DateTimeKind.Utc);
            await Send();
            // 01:00 on the 5th, local: today — though still the 4th in UTC, which is the mistake
            // this pins. Counting from UTC midnight would leave it out and allow one more message.
            _clock.UtcNow = new DateTime(2026, 10, 4, 18, 0, 0, DateTimeKind.Utc);
            await Send();
            _clock.UtcNow = Now;

            for (var i = 1; i < _options.DailyMessageLimit; i++)
            {
                (await Send()).Status.Should().Be(AssistantTurnStatus.Completed);
            }

            (await Send()).Status.Should().Be(AssistantTurnStatus.DailyLimitReached);
        }

        // ── Failures and history ─────────────────────────────────────────────────────────

        [Fact]
        public async Task RunTurn_ShouldKeepTheUsersMessage_WhenTheModelFails()
        {
            _model.Fails();

            var result = await Send("còn đó không?");

            result.Status.Should().Be(AssistantTurnStatus.ModelUnavailable);
            _repository.Messages.Should().ContainSingle().Which.Content.Should().Be("còn đó không?");
        }

        [Theory]
        [InlineData(ModelStopReason.MaxTokens, AssistantTurnStatus.Truncated)]
        [InlineData(ModelStopReason.Refusal, AssistantTurnStatus.Refused)]
        public async Task RunTurn_ShouldReportHowTheModelStopped(ModelStopReason stop, AssistantTurnStatus expected)
        {
            _model.Replies("…", stop);

            (await Send()).Status.Should().Be(expected);
        }

        [Fact]
        public async Task RunTurn_ShouldNeverStartTheHistoryWithAToolResultOrItsCall()
        {
            _options.HistoryMessages = 3;
            _model.CallsTools(Call("get_events")).Replies("first");
            await Send("một");
            _model.Replies("second");

            await Send("hai");

            // Stored: user, assistant(call), tool, assistant, user. The last 3 would begin at the
            // tool result; the harness moves forward to the next user message instead.
            var sent = _model.Requests.Last().Messages;
            sent.First().Role.Should().Be(ModelRole.User);
            sent.Should().ContainSingle().Which.Content.Should().EndWith("hai");
        }

        private bool EveryStoredCallHasItsResult()
        {
            var answered = _repository.Messages.Where(m => m.Role == AssistantRoles.Tool).Select(m => m.ToolCallId).ToHashSet();
            return _repository.Messages
                .Where(m => m.ToolCallsJson != null)
                .SelectMany(m => System.Text.Json.JsonSerializer.Deserialize<List<ModelToolCall>>(m.ToolCallsJson!, ToolJson.Options)!)
                .All(c => answered.Contains(c.Id));
        }

        private sealed class RecordingProgress : IAssistantProgress
        {
            public List<string> Events { get; } = new();

            public Task ToolStartedAsync(string userId, Guid conversationId, string toolName)
            {
                Events.Add($"start {toolName}");
                return Task.CompletedTask;
            }

            public Task ToolFinishedAsync(string userId, Guid conversationId, string toolName, bool failed)
            {
                Events.Add($"finish {toolName}");
                return Task.CompletedTask;
            }
        }
    }
}
