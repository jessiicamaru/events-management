using HabitTracker.Application.Features.GoogleCalendar.Commands;
using HabitTracker.Domain.Interfaces;
using HabitTracker.Web.Infrastructure;
using MediatR;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.DependencyInjection;
using System.Threading.Tasks;

namespace HabitTracker.Web.Endpoints.V1;

public class GoogleCalendarWebhook : EndpointGroupBase
{
    public override string? GroupName => "webhooks";
    public override string GroupDescription => "Google Calendar Webhook Endpoint";

    public override void Map(RouteGroupBuilder groupBuilder)
    {
        // This endpoint must be public (Google calls it without authorization)
        groupBuilder.MapPost("google-calendar", HandleWebhook);
    }

    public async Task<IResult> HandleWebhook(
        HttpContext httpContext,
        IGoogleCalendarChannelRepository channelRepository,
        IServiceScopeFactory scopeFactory)
    {
        if (!httpContext.Request.Headers.TryGetValue("X-Goog-Channel-ID", out var channelIdValues))
        {
            return TypedResults.BadRequest("Missing X-Goog-Channel-ID header.");
        }

        var channelId = channelIdValues.ToString();
        var channel = await channelRepository.GetByIdAsync(channelId);
        if (channel == null)
        {
            return TypedResults.NotFound("Watch channel not found.");
        }

        if (httpContext.Request.Headers.TryGetValue("X-Goog-Resource-State", out var stateValues) && 
            stateValues.ToString() == "sync")
        {
            // Initial sync verification ping from Google
            return TypedResults.Ok();
        }

        // Offload sync to prevent blocking Google webhook and timeout
        // Use IServiceScopeFactory to avoid ObjectDisposedException
        _ = Task.Run(async () =>
        {
            using var scope = scopeFactory.CreateScope();
            var scopedSender = scope.ServiceProvider.GetRequiredService<ISender>();
            try
            {
                await scopedSender.Send(new SyncGoogleCalendarCommand { UserId = channel.UserId });
            }
            catch (System.Exception ex)
            {
                System.Console.WriteLine($"Webhook Incremental Sync Background Error: {ex.Message}");
            }
        });

        return TypedResults.Ok();
    }
}
