using HabitTracker.Application.Features.Analytics.Queries.GetActivitySummary;
using HabitTracker.Application.Features.Analytics.Queries.GetHeatmap;
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

    public async Task<Results<Ok<List<HeatmapItemDto>>, UnauthorizedHttpResult>> GetHeatmap(ISender sender, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        var heatmap = await sender.Send(new GetHeatmapQuery(userId));
        return TypedResults.Ok(heatmap);
    }
}
