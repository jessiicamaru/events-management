using HabitTracker.Application.Features.Events.Commands;
using HabitTracker.Application.Features.Events.Queries;
using HabitTracker.Domain.Entities;
using HabitTracker.Web.Infrastructure;
using MediatR;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Routing;
using System.Security.Claims;

namespace HabitTracker.Web.Endpoints.V1;

public class Events : EndpointGroupBase
{
    public override string GroupDescription => "Events Endpoints";

    public override void Map(RouteGroupBuilder groupBuilder)
    {
        groupBuilder.RequireAuthorization();
        groupBuilder.MapGet("", GetEvents);
        groupBuilder.MapPost("", CreateEvent);
        groupBuilder.MapPut("{id}/toggle", ToggleEvent);
        groupBuilder.MapPut("{id}/complete-session", CompleteSession);
        groupBuilder.MapDelete("{id}", DeleteEvent);
        groupBuilder.MapPut("{id}", UpdateEvent);
    }

    public async Task<IResult> GetEvents(ISender sender, System.Security.Claims.ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(System.Security.Claims.ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        var events = await sender.Send(new GetEventsQuery { UserId = userId });
        return TypedResults.Ok(events);
    }

    public async Task<Results<Created<Guid>, UnauthorizedHttpResult>> CreateEvent(ISender sender, CreateEventCommand command, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(System.Security.Claims.ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        command.UserId = userId;
        var id = await sender.Send(command);
        return TypedResults.Created($"/api/v1/events/{id}", id);
    }

    public async Task<Results<Ok, NotFound>> ToggleEvent(ISender sender, Guid id, [Microsoft.AspNetCore.Mvc.FromBody] ToggleEventRequest request)
    {
        var result = await sender.Send(new ToggleEventCommand(id, request.IsCompleted));
        if (!result) return TypedResults.NotFound();
        return TypedResults.Ok();
    }
    public async Task<Results<Ok, NotFound>> CompleteSession(ISender sender, Guid id, [Microsoft.AspNetCore.Mvc.FromBody] CompleteEventSessionRequest request)
    {
        var result = await sender.Send(new CompleteEventSessionCommand 
        { 
            EventId = id, 
            ActualDuration = request.ActualDuration, 
            UpdateCalendar = request.UpdateCalendar 
        });
        if (!result) return TypedResults.NotFound();
        return TypedResults.Ok();
    }

    public async Task<Results<Ok, NotFound, UnauthorizedHttpResult>> DeleteEvent(ISender sender, Guid id, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(System.Security.Claims.ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        var result = await sender.Send(new DeleteEventCommand(id, userId));
        if (!result) return TypedResults.NotFound();
        return TypedResults.Ok();
    }

    public async Task<Results<Ok, NotFound, UnauthorizedHttpResult>> UpdateEvent(ISender sender, Guid id, [Microsoft.AspNetCore.Mvc.FromBody] UpdateEventRequest request, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(System.Security.Claims.ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        var command = new UpdateEventCommand
        {
            EventId = id,
            Title = request.Title,
            StartTime = request.StartTime,
            EndTime = request.EndTime,
            HabitId = request.HabitId,
            TargetDuration = request.TargetDuration,
            UserId = userId
        };

        var result = await sender.Send(command);
        if (!result) return TypedResults.NotFound();
        return TypedResults.Ok();
    }
}

public record UpdateEventRequest(string Title, DateTime StartTime, DateTime EndTime, string HabitId, TimeSpan? TargetDuration);

public record ToggleEventRequest(bool IsCompleted);
