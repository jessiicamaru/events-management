using HabitTracker.Application.Features.EventCategories.Commands;
using HabitTracker.Application.Features.EventCategories.Queries;
using HabitTracker.Web.Infrastructure;
using MediatR;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
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

    public async Task<IResult> GetCategories(ISender sender, ClaimsPrincipal user, Guid? squadId)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        var categories = await sender.Send(new GetEventCategoriesQuery { UserId = userId, SquadId = squadId });
        return TypedResults.Ok(categories);
    }

    public async Task<Results<Created<Guid>, UnauthorizedHttpResult>> CreateCategory(ISender sender, CreateEventCategoryCommand command, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        if (command.SquadId == null)
        {
            command.UserId = userId; // It's a personal category
        }
        else
        {
            // Ideally check if user is admin of squad. For now, let anyone add to squad.
            command.UserId = null; // Squad categories don't belong to a specific user
        }

        var id = await sender.Send(command);
        return TypedResults.Created($"/api/v1/event-categories/{id}", id);
    }

    public async Task<Results<Ok, NotFound, UnauthorizedHttpResult>> UpdateCategory(ISender sender, Guid id, [Microsoft.AspNetCore.Mvc.FromBody] UpdateEventCategoryRequest request, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        var command = new UpdateEventCategoryCommand
        {
            Id = id,
            Name = request.Name,
            ColorPreset = request.ColorPreset,
            UserId = userId,
            SquadId = request.SquadId
        };

        var result = await sender.Send(command);
        if (!result) return TypedResults.NotFound();
        return TypedResults.Ok();
    }

    public async Task<Results<Ok, NotFound, UnauthorizedHttpResult>> DeleteCategory(ISender sender, Guid id, ClaimsPrincipal user, Guid? squadId)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        var command = new DeleteEventCategoryCommand
        {
            Id = id,
            UserId = userId,
            SquadId = squadId
        };

        var result = await sender.Send(command);
        if (!result) return TypedResults.NotFound();
        return TypedResults.Ok();
    }
}

public record UpdateEventCategoryRequest(string Name, string ColorPreset, Guid? SquadId);
