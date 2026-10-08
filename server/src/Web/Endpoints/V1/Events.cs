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
        groupBuilder.MapPost("{id}/occurrences", MaterializeOccurrence);
        groupBuilder.MapDelete("{id}", DeleteEvent);
        groupBuilder.MapPut("{id}", UpdateEvent);
    }

    public async Task<IResult> GetEvents(
        ISender sender, 
        System.Security.Claims.ClaimsPrincipal user,
        DateTime? startTime = null,
        DateTime? endTime = null)
    {
        var userId = user.FindFirstValue(System.Security.Claims.ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        var events = await sender.Send(new GetEventsQuery 
        { 
            UserId = userId,
            StartTime = startTime,
            EndTime = endTime
        });
        return TypedResults.Ok(events);
    }

    public async Task<Results<Created<Guid>, ForbidHttpResult, UnauthorizedHttpResult>> CreateEvent(ISender sender, CreateEventCommand command, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(System.Security.Claims.ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        command.UserId = userId;
        var id = await sender.Send(command);

        // Null means the category is not one this caller may use.
        if (id == null) return TypedResults.Forbid();

        return TypedResults.Created($"/api/v1/events/{id}", id.Value);
    }

    public async Task<Results<Ok, NotFound, UnauthorizedHttpResult>> ToggleEvent(ISender sender, Guid id, [Microsoft.AspNetCore.Mvc.FromBody] ToggleEventRequest request, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        var result = await sender.Send(new ToggleEventCommand(id, request.IsCompleted, userId));
        if (!result) return TypedResults.NotFound();
        return TypedResults.Ok();
    }
    public async Task<Results<Ok, NotFound, UnauthorizedHttpResult>> CompleteSession(ISender sender, Guid id, [Microsoft.AspNetCore.Mvc.FromBody] CompleteEventSessionRequest request, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        var result = await sender.Send(new CompleteEventSessionCommand 
        { 
            EventId = id, 
            ActualDuration = request.ActualDuration, 
            UpdateCalendar = request.UpdateCalendar,
            OccurrenceStart = request.OccurrenceStart,
            UserId = userId
        });
        if (!result) return TypedResults.NotFound();
        return TypedResults.Ok();
    }

    /// <summary>
    /// Gives one day of a repeating series its own event (with a copy of the series'
    /// tasks) and returns its id. Idempotent: asking again for the same day returns the
    /// same event. Never sent to Google.
    /// </summary>
    public async Task<Results<Ok<Guid>, NotFound, UnauthorizedHttpResult>> MaterializeOccurrence(
        ISender sender,
        Guid id,
        [Microsoft.AspNetCore.Mvc.FromBody] MaterializeOccurrenceRequest request,
        ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        var childId = await sender.Send(new MaterializeOccurrenceCommand(id, request.OccurrenceStart, userId));
        if (childId == null) return TypedResults.NotFound();
        return TypedResults.Ok(childId.Value);
    }

    public async Task<Results<Ok, NotFound, UnauthorizedHttpResult>> DeleteEvent(
        ISender sender, 
        Guid id, 
        string? deleteScope, 
        DateTime? originalOccurrenceDate, 
        ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(System.Security.Claims.ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        var result = await sender.Send(new DeleteEventCommand(id, userId, deleteScope, originalOccurrenceDate));
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
            CategoryId = request.CategoryId,
            TargetDuration = request.TargetDuration,
            UserId = userId,
            EditScope = request.EditScope,
            OriginalOccurrenceDate = request.OriginalOccurrenceDate,
            RecurrenceRule = request.RecurrenceRule,
            ReminderMinutesBefore = request.ReminderMinutesBefore
        };

        var result = await sender.Send(command);
        if (!result) return TypedResults.NotFound();
        return TypedResults.Ok();
    }
}

public record UpdateEventRequest(
    string Title, 
    DateTime StartTime, 
    DateTime EndTime, 
    string HabitId, 
    Guid? CategoryId, 
    TimeSpan? TargetDuration,
    string? EditScope = null,
    DateTime? OriginalOccurrenceDate = null,
    string? RecurrenceRule = null,
    // Null = not supplied, keep what is stored; an empty list = "no reminders".
    // Missing from this record until now, so every reminder edit was dropped here even
    // though the command and the client both handled it.
    List<int>? ReminderMinutesBefore = null
);

public record ToggleEventRequest(bool IsCompleted);
