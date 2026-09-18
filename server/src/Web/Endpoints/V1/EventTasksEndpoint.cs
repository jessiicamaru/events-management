using HabitTracker.Application.Features.EventTasks.Commands;
using HabitTracker.Application.Features.EventTasks.Queries;
using HabitTracker.Domain.Entities;
using HabitTracker.Web.Infrastructure;
using MediatR;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Routing;
using System.Security.Claims;

namespace HabitTracker.Web.Endpoints.V1;

public class EventTasksEndpoint : EndpointGroupBase
{
    public override string GroupName => "events";
    public override string GroupDescription => "Event Tasks Endpoints";

    public override void Map(RouteGroupBuilder groupBuilder)
    {
        groupBuilder.RequireAuthorization();
        
        // Base route: /api/v1/eventtasks
        groupBuilder.MapGet("{eventId:guid}/tasks", GetEventTasks);
        groupBuilder.MapPost("{eventId:guid}/tasks", CreateEventTask);
        groupBuilder.MapPut("{eventId:guid}/tasks/{taskId:guid}", UpdateEventTask);
        groupBuilder.MapPatch("{eventId:guid}/tasks/{taskId:guid}/toggle", ToggleEventTask);
        groupBuilder.MapDelete("{eventId:guid}/tasks/{taskId:guid}", DeleteEventTask);
    }

    public async Task<Results<Ok<IEnumerable<EventTask>>, UnauthorizedHttpResult>> GetEventTasks(Guid eventId, ISender sender, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        var tasks = await sender.Send(new GetEventTasksQuery { EventId = eventId, UserId = userId });
        return TypedResults.Ok(tasks);
    }

    public async Task<Results<Created<Guid>, UnauthorizedHttpResult>> CreateEventTask(Guid eventId, ISender sender, CreateEventTaskCommand command, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        command.EventId = eventId;
        command.UserId = userId;
        var id = await sender.Send(command);
        return TypedResults.Created($"/api/v1/eventtasks/events/{eventId}/tasks/{id}", id);
    }

    public async Task<Results<Ok, NotFound, UnauthorizedHttpResult>> UpdateEventTask(Guid eventId, Guid taskId, ISender sender, UpdateEventTaskCommand command, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        command.Id = taskId;
        command.EventId = eventId;
        command.UserId = userId;
        var success = await sender.Send(command);
        if (!success) return TypedResults.NotFound();

        return TypedResults.Ok();
    }

    public async Task<Results<Ok, NotFound, UnauthorizedHttpResult>> ToggleEventTask(Guid eventId, Guid taskId, ISender sender, ToggleEventTaskCommand command, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        command.Id = taskId;
        command.EventId = eventId;
        command.UserId = userId;
        var success = await sender.Send(command);
        if (!success) return TypedResults.NotFound();

        return TypedResults.Ok();
    }

    public async Task<Results<NoContent, NotFound, UnauthorizedHttpResult>> DeleteEventTask(Guid eventId, Guid taskId, ISender sender, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        var success = await sender.Send(new DeleteEventTaskCommand { Id = taskId, EventId = eventId, UserId = userId });
        if (!success) return TypedResults.NotFound();

        return TypedResults.NoContent();
    }
}
