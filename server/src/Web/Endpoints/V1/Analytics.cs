using HabitTracker.Application.Features.Analytics.Queries.GetHeatmap;
using HabitTracker.Web.Infrastructure;
using MediatR;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Routing;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace HabitTracker.Web.Endpoints.V1;

public class Analytics : EndpointGroupBase
{
    public override string GroupDescription => "Analytics Endpoints";

    public override void Map(RouteGroupBuilder groupBuilder)
    {
        groupBuilder.MapGet("heatmap", GetHeatmap);
    }

    public async Task<Ok<List<HeatmapItemDto>>> GetHeatmap(ISender sender)
    {
        var heatmap = await sender.Send(new GetHeatmapQuery());
        return TypedResults.Ok(heatmap);
    }
}
