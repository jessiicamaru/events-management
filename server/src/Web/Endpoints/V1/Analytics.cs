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
    }

    public async Task<Results<Ok<List<HeatmapItemDto>>, UnauthorizedHttpResult>> GetHeatmap(ISender sender, ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return TypedResults.Unauthorized();

        var heatmap = await sender.Send(new GetHeatmapQuery(userId));
        return TypedResults.Ok(heatmap);
    }
}
