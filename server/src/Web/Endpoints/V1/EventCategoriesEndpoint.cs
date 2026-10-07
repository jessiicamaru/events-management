using HabitTracker.Application.Features.EventCategories.Commands;
using HabitTracker.Application.Features.EventCategories.Queries;
using HabitTracker.Domain.Entities;
using HabitTracker.Web.Infrastructure;
using MediatR;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Routing;
using System.Security.Claims;

namespace HabitTracker.Web.Endpoints.V1;

public class EventCategoriesEndpoint : EndpointGroupBase
{
    public override string GroupName => "event-categories";
    public override string GroupDescription => "Event Categories Endpoints";

    public override void Map(RouteGroupBuilder groupBuilder)
    {
        groupBuilder.RequireAuthorization();
        groupBuilder.MapGet("", GetCategories);
        groupBuilder.MapPost("", CreateCategory);
        groupBuilder.MapPut("{id}", UpdateCategory);
        groupBuilder.MapDelete("{id}", DeleteCategory);
    }

    public async Task<Results<Ok<IEnumerable<EventCategory>>, ForbidHttpResult, UnauthorizedHttpResult>> GetCategories(ISender sender, ClaimsPrincipal user, Guid? squadId)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        var categories = await sender.Send(new GetEventCategoriesQuery { UserId = userId, SquadId = squadId });

        // Null means "not your squad" — distinct from an empty list, which the client shows as
        // an empty state. Before, the squad id was used unvalidated and any caller could read
        // any squad's categories.
        if (categories == null) return TypedResults.Forbid();

        return TypedResults.Ok(categories);
    }

    public async Task<Results<Created<Guid>, ForbidHttpResult, UnauthorizedHttpResult>> CreateCategory(ISender sender, CreateEventCategoryCommand command, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        command.CallerUserId = userId;
        // A squad category belongs to the squad, not to one member; a personal one belongs to
        // whoever asked. Either way the handler checks the caller may do it — membership of the
        // squad used to be unchecked entirely.
        command.UserId = command.SquadId == null ? userId : null;

        var id = await sender.Send(command);
        if (id == null) return TypedResults.Forbid();

        return TypedResults.Created($"/api/v1/event-categories/{id}", id.Value);
    }

    public async Task<Results<Ok, NotFound, UnauthorizedHttpResult>> UpdateCategory(ISender sender, Guid id, [Microsoft.AspNetCore.Mvc.FromBody] UpdateEventCategoryRequest request, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        // request.SquadId is deliberately not passed on: whether this category is personal
        // or shared is a property of the stored row, and trusting the body for it was the bug.
        var command = new UpdateEventCategoryCommand
        {
            Id = id,
            Name = request.Name,
            ColorPreset = request.ColorPreset,
            UserId = userId
        };

        var result = await sender.Send(command);
        if (!result) return TypedResults.NotFound();
        return TypedResults.Ok();
    }

    public async Task<Results<Ok, NotFound, UnauthorizedHttpResult>> DeleteCategory(ISender sender, Guid id, ClaimsPrincipal user, [FromQuery] Guid? replacementCategoryId)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        // No squadId parameter: the row says whether this is a squad category, and the handler
        // checks the caller against it. A client may still send one; it is ignored.
        var command = new DeleteEventCategoryCommand
        {
            Id = id,
            UserId = userId,
            ReplacementCategoryId = replacementCategoryId
        };

        var result = await sender.Send(command);
        if (!result) return TypedResults.NotFound();
        return TypedResults.Ok();
    }
}

public record UpdateEventCategoryRequest(string Name, string ColorPreset, Guid? SquadId);
