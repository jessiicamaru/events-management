using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Application.Features.Assistant.Commands;
using HabitTracker.Application.Features.Assistant.Harness;
using HabitTracker.Application.Features.Assistant.Queries;
using HabitTracker.Application.Tests.TestDoubles;
using HabitTracker.Domain.Entities;
using HabitTracker.Web.Endpoints.V1;
using HabitTracker.Web.Hubs;
using MediatR;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Moq;
using Xunit;

namespace HabitTracker.Application.Tests.Web
{
    public class AssistantEndpointTests
    {
        private static ClaimsPrincipal SignedIn(string userId) =>
            new(new ClaimsIdentity(new[] { new Claim(ClaimTypes.NameIdentifier, userId) }, "test"));

        private static Mock<ISender> SenderReturning(AssistantTurnResult result, Action<SendAssistantMessageCommand>? capture = null)
        {
            var sender = new Mock<ISender>();
            sender.Setup(s => s.Send(It.IsAny<SendAssistantMessageCommand>(), It.IsAny<CancellationToken>()))
                .Callback<IRequest<AssistantTurnResult>, CancellationToken>((c, _) => capture?.Invoke((SendAssistantMessageCommand)c))
                .ReturnsAsync(result);
            return sender;
        }

        [Fact]
        public async Task SendMessage_ShouldActForTheUserInTheToken()
        {
            SendAssistantMessageCommand? sent = null;
            var sender = SenderReturning(new AssistantTurnResult(AssistantTurnStatus.Completed, "ok"), c => sent = c);
            var conversationId = Guid.NewGuid();

            await new Assistant().SendMessage(
                conversationId, sender.Object, new SendAssistantMessageRequest("hi"), SignedIn("user-1"), CancellationToken.None);

            sent.Should().Be(new SendAssistantMessageCommand("user-1", conversationId, "hi"));
        }

        [Fact]
        public async Task SendMessage_ShouldReturnTheReply_WithTheToolsItUsed()
        {
            var sender = SenderReturning(new AssistantTurnResult(AssistantTurnStatus.Completed, "Mai trống.", new[] { "get_events" }));

            var response = await new Assistant().SendMessage(
                Guid.NewGuid(), sender.Object, new SendAssistantMessageRequest("mai?"), SignedIn("user-1"), CancellationToken.None);

            var ok = response.Result.Should().BeOfType<Ok<AssistantReplyDto>>().Subject;
            ok.Value!.Should().BeEquivalentTo(new AssistantReplyDto("Completed", "Mai trống.", new[] { "get_events" }));
        }

        [Theory]
        [InlineData(AssistantTurnStatus.NotConfigured, StatusCodes.Status503ServiceUnavailable)]
        [InlineData(AssistantTurnStatus.Disabled, StatusCodes.Status403Forbidden)]
        [InlineData(AssistantTurnStatus.DailyLimitReached, StatusCodes.Status429TooManyRequests)]
        [InlineData(AssistantTurnStatus.ModelUnavailable, StatusCodes.Status502BadGateway)]
        public async Task SendMessage_ShouldAnswerARefusalWithItsStatusCode_AndNameItInTheTitle(AssistantTurnStatus status, int code)
        {
            var response = await new Assistant().SendMessage(
                Guid.NewGuid(), SenderReturning(new AssistantTurnResult(status)).Object,
                new SendAssistantMessageRequest("hi"), SignedIn("user-1"), CancellationToken.None);

            var problem = response.Result.Should().BeOfType<ProblemHttpResult>().Subject;
            problem.StatusCode.Should().Be(code);
            problem.ProblemDetails.Title.Should().Be(status.ToString());
        }

        [Fact]
        public async Task SendMessage_ShouldAnswer404_ForAConversationThatIsNotTheCallers()
        {
            var response = await new Assistant().SendMessage(
                Guid.NewGuid(), SenderReturning(new AssistantTurnResult(AssistantTurnStatus.ConversationNotFound)).Object,
                new SendAssistantMessageRequest("hi"), SignedIn("user-1"), CancellationToken.None);

            response.Result.Should().BeOfType<NotFound>();
        }

        [Theory]
        [InlineData("")]
        [InlineData("   ")]
        public async Task SendMessage_ShouldRejectAnEmptyMessage_WithoutRunningATurn(string text)
        {
            var sender = new Mock<ISender>(MockBehavior.Strict);

            var response = await new Assistant().SendMessage(
                Guid.NewGuid(), sender.Object, new SendAssistantMessageRequest(text), SignedIn("user-1"), CancellationToken.None);

            response.Result.Should().BeOfType<BadRequest<string>>();
        }

        [Fact]
        public async Task SendMessage_ShouldRejectATooLongMessage()
        {
            var text = new string('a', SendAssistantMessageCommandHandler.MaxTextLength + 1);

            var response = await new Assistant().SendMessage(
                Guid.NewGuid(), new Mock<ISender>(MockBehavior.Strict).Object,
                new SendAssistantMessageRequest(text), SignedIn("user-1"), CancellationToken.None);

            response.Result.Should().BeOfType<BadRequest<string>>();
        }

        [Fact]
        public async Task UpdateSettings_ShouldActForTheUserInTheToken_AndRecordConsentOnce()
        {
            var repository = new InMemoryAssistantRepository();
            var clock = new FixedTimeProvider(new DateTime(2026, 10, 5, 3, 0, 0, DateTimeKind.Utc));
            var handler = new UpdateAiSettingsCommandHandler(repository, clock);

            var first = await handler.Handle(new UpdateAiSettingsCommand("user-1", true, false), CancellationToken.None);
            clock.UtcNow = clock.UtcNow.AddDays(1);
            await handler.Handle(new UpdateAiSettingsCommand("user-1", false, false), CancellationToken.None);
            var again = await handler.Handle(new UpdateAiSettingsCommand("user-1", true, true), CancellationToken.None);

            first.ConsentedAt.Should().Be(new DateTime(2026, 10, 5, 3, 0, 0, DateTimeKind.Utc));
            again.ConsentedAt.Should().Be(first.ConsentedAt, "turning it off and on again keeps the original consent");
            again.AlwaysConfirm.Should().BeTrue();
        }

        [Theory]
        [InlineData("/socialHub", true)]
        [InlineData("/socialHub/negotiate", true)]
        [InlineData("/assistantHub", true)]
        [InlineData("/assistantHub/negotiate", true)]
        [InlineData("/api/v1/events", false)]
        [InlineData("/assistantHubX", false)]
        public void HubTokenPaths_ShouldAcceptAQueryTokenOnlyOnTheHubs(string path, bool accepted)
        {
            HubTokenPaths.AcceptsQueryToken(new PathString(path)).Should().Be(accepted);
        }

        [Fact]
        public async Task GetMessages_ShouldHideToolResults_AndAssistantStepsWithNoText()
        {
            var repository = new InMemoryAssistantRepository();
            var conversation = repository.AddConversation("user-1");
            await repository.AppendMessagesAsync(conversation.Id, new List<AssistantMessage>
            {
                new() { Role = AssistantRoles.User, Content = "mai?" },
                new() { Role = AssistantRoles.Assistant, Content = null, ToolCallsJson = "[]" },
                new() { Role = AssistantRoles.Tool, Content = """{"events":[]}""", ToolName = "get_events" },
                new() { Role = AssistantRoles.Assistant, Content = "Mai trống." },
            });

            var messages = await new GetAssistantMessagesQueryHandler(repository)
                .Handle(new GetAssistantMessagesQuery("user-1", conversation.Id), CancellationToken.None);

            messages!.Select(m => (m.Role, m.Content, m.ToolName)).Should().Equal(
                ("user", "mai?", null),
                ("tool", null, "get_events"),
                ("assistant", "Mai trống.", null));
            (await new GetAssistantMessagesQueryHandler(repository)
                .Handle(new GetAssistantMessagesQuery("user-2", conversation.Id), CancellationToken.None)).Should().BeNull();
        }
    }
}
