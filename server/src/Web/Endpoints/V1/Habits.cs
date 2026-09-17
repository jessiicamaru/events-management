using HabitTracker.Application.Features.Habits.Commands;
using HabitTracker.Application.Features.Habits.Queries;
using HabitTracker.Domain.Entities;
using HabitTracker.Web.Infrastructure;
using MediatR;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Routing;
using System.Security.Claims;

namespace HabitTracker.Web.Endpoints.V1;

public class Habits : EndpointGroupBase
{
    public override string GroupDescription => "Habits Endpoints";

    public override void Map(RouteGroupBuilder groupBuilder)
    {
        groupBuilder.RequireAuthorization();
        groupBuilder.MapGet("", GetHabits);
        groupBuilder.MapPost("", CreateHabit);
    }

    public async Task<Results<Ok<IEnumerable<Habit>>, UnauthorizedHttpResult>> GetHabits(ISender sender, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        var habits = await sender.Send(new GetHabitsQuery { UserId = userId });
        return TypedResults.Ok(habits);
    }

    public async Task<Results<Created<Guid>, UnauthorizedHttpResult>> CreateHabit(ISender sender, CreateHabitCommand command, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        command.UserId = userId;
        var id = await sender.Send(command);
        return TypedResults.Created($"/api/v1/habits/{id}", id);
    }
}
