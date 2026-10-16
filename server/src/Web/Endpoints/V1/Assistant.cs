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
/// <param name="Proposals">What the assistant proposed this turn, shown as cards with an "Add to calendar" button.</param>
public record AssistantReplyDto(
    string Status, string? Reply, IReadOnlyList<string> ToolsUsed, IReadOnlyList<AssistantProposalDto> Proposals);

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
        groupBuilder.MapPost("proposals/{id:guid}/apply", ApplyProposal);
        groupBuilder.MapPost("proposals/{id:guid}/dismiss", DismissProposal);
        groupBuilder.MapPost("proposals/{id:guid}/undo", UndoProposal);
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
                result.Status.ToString(),
                result.Reply,
                result.ToolsUsed ?? Array.Empty<string>(),
                (result.Proposals ?? Array.Empty<Domain.Entities.AssistantProposal>()).Select(AssistantProposalDto.From).ToList())),
        };
    }

    /// <summary>The user tapped "Add to calendar" on a proposal: creates it. Only this ever writes what the assistant suggested.</summary>
    public Task<Results<Ok<AssistantProposalDto>, NotFound, Conflict<AssistantProposalDto>, ProblemHttpResult, UnauthorizedHttpResult>> ApplyProposal(
        Guid id, ISender sender, ClaimsPrincipal user) =>
        RunProposalAction(user, userId => sender.Send(new ApplyAssistantProposalCommand(userId, id)));

    public Task<Results<Ok<AssistantProposalDto>, NotFound, Conflict<AssistantProposalDto>, ProblemHttpResult, UnauthorizedHttpResult>> DismissProposal(
        Guid id, ISender sender, ClaimsPrincipal user) =>
        RunProposalAction(user, userId => sender.Send(new DismissAssistantProposalCommand(userId, id)));

    public Task<Results<Ok<AssistantProposalDto>, NotFound, Conflict<AssistantProposalDto>, ProblemHttpResult, UnauthorizedHttpResult>> UndoProposal(
        Guid id, ISender sender, ClaimsPrincipal user) =>
        RunProposalAction(user, userId => sender.Send(new UndoAssistantProposalCommand(userId, id)));

    /// <summary>
    /// 409 when the card is out of date (already added, dismissed or undone), with the proposal
    /// as it now stands so the app can redraw it; 409 titled HasActivity when undo would delete
    /// days the user has already worked on; 422 when the event could not be created.
    /// </summary>
    private static async Task<Results<Ok<AssistantProposalDto>, NotFound, Conflict<AssistantProposalDto>, ProblemHttpResult, UnauthorizedHttpResult>> RunProposalAction(
        ClaimsPrincipal user, Func<string, Task<ProposalActionResult>> action)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        var result = await action(userId);
        return result.Outcome switch
        {
            ProposalActionOutcome.Done => TypedResults.Ok(result.Proposal!),
            ProposalActionOutcome.NotFound => TypedResults.NotFound(),
            ProposalActionOutcome.AlreadyResolved => TypedResults.Conflict(result.Proposal!),
            ProposalActionOutcome.HasActivity => TypedResults.Problem(statusCode: StatusCodes.Status409Conflict, title: result.Outcome.ToString()),
            _ => TypedResults.Problem(statusCode: StatusCodes.Status422UnprocessableEntity, title: result.Outcome.ToString()),
        };
    }

    /// <summary>A refusal the app can recognise by its title — the status name — and word for the user.</summary>
    private static ProblemHttpResult Problem(int statusCode, AssistantTurnStatus status) =>
        TypedResults.Problem(statusCode: statusCode, title: status.ToString());
}
