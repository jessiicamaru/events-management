using HabitTracker.Application.Features.Analytics.Queries.GetActivitySummary;
using HabitTracker.Application.Features.Analytics.Queries.GetHeatmap;
using HabitTracker.Application.Features.Analytics.Queries.GetPlanVsActual;
using HabitTracker.Web.Infrastructure;
using MediatR;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Routing;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;

namespace HabitTracker.Web.Endpoints.V1;

public class Analytics : EndpointGroupBase
{
    public override string GroupDescription => "Analytics Endpoints";

    public override void Map(RouteGroupBuilder groupBuilder)
    {
        groupBuilder.RequireAuthorization();
        groupBuilder.MapGet("heatmap", GetHeatmap);
        groupBuilder.MapGet("summary", GetActivitySummary);
        groupBuilder.MapGet("plan-vs-actual", GetPlanVsActual);
    }

    /// <summary>
    /// Per-day scheduled/completed counts and focus minutes for the signed-in user.
    /// </summary>
    public async Task<Results<Ok<ActivitySummaryDto>, UnauthorizedHttpResult>> GetActivitySummary(
        ISender sender,
        ClaimsPrincipal user,
        int days = 14)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        // userId comes from the token, never from the query string — the same rule the
        // heatmap endpoint follows since it was found returning every user's data.
        var summary = await sender.Send(new GetActivitySummaryQuery(userId, days));
        return TypedResults.Ok(summary);
    }

    /// <summary>
    /// Booked time against recorded time, per habit and per category, for the signed-in user.
    /// </summary>
    public async Task<Results<Ok<PlanVsActualDto>, UnauthorizedHttpResult>> GetPlanVsActual(
        ISender sender,
        ClaimsPrincipal user,
        int days = 14)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        // userId from the token, never the query string — see GetActivitySummary.
        var report = await sender.Send(new GetPlanVsActualQuery(userId, days));
        return TypedResults.Ok(report);
    }

    public async Task<Results<Ok<List<HeatmapItemDto>>, UnauthorizedHttpResult>> GetHeatmap(ISender sender, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        var heatmap = await sender.Send(new GetHeatmapQuery(userId));
        return TypedResults.Ok(heatmap);
    }
}
