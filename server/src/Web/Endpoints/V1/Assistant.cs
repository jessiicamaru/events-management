using HabitTracker.Application.Features.Assistant.Commands;
using HabitTracker.Application.Features.Assistant.Harness;
using HabitTracker.Application.Features.Assistant.Queries;
using HabitTracker.Web.Infrastructure;
using MediatR;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Routing;
using System.Security.Claims;

namespace HabitTracker.Web.Endpoints.V1;

public record SendAssistantMessageRequest(string Text);

public record UpdateAiSettingsRequest(bool AssistantEnabled, bool AlwaysConfirm);

/// <param name="Status">An <see cref="AssistantTurnStatus"/> name; the app words it for the user.</param>
public record AssistantReplyDto(string Status, string? Reply, IReadOnlyList<string> ToolsUsed);

/// <summary>
/// The assistant. A turn runs inside the POST that sends the message and returns the reply;
/// progress meanwhile goes over <c>/assistantHub</c>.
/// </summary>
public class Assistant : EndpointGroupBase
{
    public override string GroupDescription => "Assistant Endpoints";

    public override void Map(RouteGroupBuilder groupBuilder)
    {
        groupBuilder.RequireAuthorization();
        groupBuilder.MapGet("settings", GetSettings);
        groupBuilder.MapPut("settings", UpdateSettings);
        groupBuilder.MapGet("conversations", GetConversations);
        groupBuilder.MapPost("conversations", CreateConversation);
        groupBuilder.MapGet("conversations/{id:guid}/messages", GetMessages);
        groupBuilder.MapPost("conversations/{id:guid}/messages", SendMessage);
    }

    public async Task<Results<Ok<AiSettingsDto>, UnauthorizedHttpResult>> GetSettings(ISender sender, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        return TypedResults.Ok(await sender.Send(new GetAiSettingsQuery(userId)));
    }

    public async Task<Results<Ok<AiSettingsDto>, UnauthorizedHttpResult>> UpdateSettings(
        ISender sender, UpdateAiSettingsRequest request, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        return TypedResults.Ok(await sender.Send(
            new UpdateAiSettingsCommand(userId, request.AssistantEnabled, request.AlwaysConfirm)));
    }

    public async Task<Results<Ok<IReadOnlyList<AssistantConversationDto>>, UnauthorizedHttpResult>> GetConversations(
        ISender sender, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        return TypedResults.Ok(await sender.Send(new GetAssistantConversationsQuery(userId)));
    }

    public async Task<Results<Created<Guid>, UnauthorizedHttpResult>> CreateConversation(ISender sender, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        var id = await sender.Send(new CreateAssistantConversationCommand(userId));
        return TypedResults.Created($"/api/v1/assistant/conversations/{id}", id);
    }

    public async Task<Results<Ok<IReadOnlyList<AssistantMessageDto>>, NotFound, UnauthorizedHttpResult>> GetMessages(
        Guid id, ISender sender, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        var messages = await sender.Send(new GetAssistantMessagesQuery(userId, id));
        return messages == null ? TypedResults.NotFound() : TypedResults.Ok(messages);
    }

    public async Task<Results<Ok<AssistantReplyDto>, BadRequest<string>, NotFound, ProblemHttpResult, UnauthorizedHttpResult>> SendMessage(
        Guid id, ISender sender, SendAssistantMessageRequest request, ClaimsPrincipal user, CancellationToken cancellationToken)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        if (string.IsNullOrWhiteSpace(request.Text) || request.Text.Length > SendAssistantMessageCommandHandler.MaxTextLength)
        {
            return TypedResults.BadRequest(
                $"Text is required and at most {SendAssistantMessageCommandHandler.MaxTextLength} characters.");
        }

        var result = await sender.Send(new SendAssistantMessageCommand(userId, id, request.Text), cancellationToken);

        return result.Status switch
        {
            AssistantTurnStatus.ConversationNotFound => TypedResults.NotFound(),
            AssistantTurnStatus.NotConfigured => Problem(StatusCodes.Status503ServiceUnavailable, result.Status),
            AssistantTurnStatus.Disabled => Problem(StatusCodes.Status403Forbidden, result.Status),
            AssistantTurnStatus.DailyLimitReached => Problem(StatusCodes.Status429TooManyRequests, result.Status),
            AssistantTurnStatus.ModelUnavailable => Problem(StatusCodes.Status502BadGateway, result.Status),
            _ => TypedResults.Ok(new AssistantReplyDto(
                result.Status.ToString(), result.Reply, result.ToolsUsed ?? Array.Empty<string>())),
        };
    }

    /// <summary>A refusal the app can recognise by its title — the status name — and word for the user.</summary>
    private static ProblemHttpResult Problem(int statusCode, AssistantTurnStatus status) =>
        TypedResults.Problem(statusCode: statusCode, title: status.ToString());
}
