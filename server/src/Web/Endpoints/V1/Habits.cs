using HabitTracker.Application.Features.Habits.Commands;
using HabitTracker.Application.Features.Habits.Queries;
using HabitTracker.Domain.Entities;
using HabitTracker.Web.Infrastructure;
using MediatR;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Routing;

namespace HabitTracker.Web.Endpoints.V1;

public class Habits : EndpointGroupBase
{
    public override string GroupDescription => "Habits Endpoints";

    public override void Map(RouteGroupBuilder groupBuilder)
    {
        groupBuilder.MapGet("", GetHabits);
        groupBuilder.MapPost("", CreateHabit);
    }

    public async Task<Ok<IEnumerable<Habit>>> GetHabits(ISender sender)
    {
        var habits = await sender.Send(new GetHabitsQuery());
        return TypedResults.Ok(habits);
    }

    public async Task<Created<Guid>> CreateHabit(ISender sender, CreateHabitCommand command)
    {
        var id = await sender.Send(command);
        return TypedResults.Created($"/api/v1/habits/{id}", id);
    }
}
