using HabitTracker.Application.Features.HabitTasks.Commands;
using HabitTracker.Application.Features.HabitTasks.Queries;
using HabitTracker.Domain.Entities;
using HabitTracker.Web.Infrastructure;
using MediatR;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Routing;
using System.Security.Claims;

namespace HabitTracker.Web.Endpoints.V1;

public class HabitTasks : EndpointGroupBase
{
    public override string GroupName => "habits";
    public override string GroupDescription => "Habit Tasks Endpoints";

    public override void Map(RouteGroupBuilder groupBuilder)
    {
        groupBuilder.RequireAuthorization();
        
        // Base route: /api/v1/habittasks
        groupBuilder.MapGet("{habitId:guid}/tasks", GetHabitTasks);
        groupBuilder.MapPost("{habitId:guid}/tasks", CreateHabitTask);
        groupBuilder.MapPut("{habitId:guid}/tasks/{taskId:guid}", UpdateHabitTask);
        groupBuilder.MapDelete("{habitId:guid}/tasks/{taskId:guid}", DeleteHabitTask);
        groupBuilder.MapPut("{habitId:guid}/tasks/reorder", ReorderHabitTasks);
    }

    public async Task<Results<Ok<IEnumerable<HabitTask>>, UnauthorizedHttpResult>> GetHabitTasks(Guid habitId, ISender sender, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        var tasks = await sender.Send(new GetHabitTasksQuery { HabitId = habitId, UserId = userId });
        return TypedResults.Ok(tasks);
    }

    public async Task<Results<Created<Guid>, UnauthorizedHttpResult>> CreateHabitTask(Guid habitId, ISender sender, CreateHabitTaskCommand command, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        command.HabitId = habitId;
        command.UserId = userId;
        var id = await sender.Send(command);
        return TypedResults.Created($"/api/v1/habittasks/habits/{habitId}/tasks/{id}", id);
    }

    public async Task<Results<Ok, NotFound, UnauthorizedHttpResult>> UpdateHabitTask(Guid habitId, Guid taskId, ISender sender, UpdateHabitTaskCommand command, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        command.Id = taskId;
        command.HabitId = habitId;
        command.UserId = userId;
        var success = await sender.Send(command);
        if (!success) return TypedResults.NotFound();

        return TypedResults.Ok();
    }

    public async Task<Results<NoContent, NotFound, UnauthorizedHttpResult>> DeleteHabitTask(Guid habitId, Guid taskId, ISender sender, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        var success = await sender.Send(new DeleteHabitTaskCommand { Id = taskId, HabitId = habitId, UserId = userId });
        if (!success) return TypedResults.NotFound();

        return TypedResults.NoContent();
    }

    public async Task<Results<Ok, NotFound, UnauthorizedHttpResult>> ReorderHabitTasks(Guid habitId, ISender sender, List<TaskOrderDto> tasks, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        var command = new ReorderHabitTasksCommand { HabitId = habitId, Tasks = tasks, UserId = userId };
        var success = await sender.Send(command);
        if (!success) return TypedResults.NotFound();

        return TypedResults.Ok();
    }
}
