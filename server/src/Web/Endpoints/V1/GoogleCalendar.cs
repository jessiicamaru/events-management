using HabitTracker.Web.Infrastructure;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using System.Security.Claims;
using System.Threading.Tasks;
using MediatR;
using HabitTracker.Application.Features.GoogleCalendar.Commands;

namespace HabitTracker.Web.Endpoints.V1
{
    public class GoogleCalendar : EndpointGroupBase
    {
        public override string GroupName => "google-calendar";

        public override void Map(RouteGroupBuilder app)
        {
            app.RequireAuthorization();
            app.MapPost("/connect", Connect);
            app.MapPost("/sync", Sync);
            app.MapPost("/disconnect", Disconnect);
        }

        public async Task<IResult> Connect(ISender sender, ClaimsPrincipal user, ConnectGoogleCalendarRequest req)
        {
            var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null) return Results.Unauthorized();

            var command = new ConnectGoogleCalendarCommand
            {
                UserId = userId,
                AuthCode = req.AuthCode,
                GoogleEmail = req.GoogleEmail
            };

            var success = await sender.Send(command);
            if (!success) return Results.BadRequest("Failed to exchange authentication code.");

            // Perform an initial sync upon connecting
            await sender.Send(new SyncGoogleCalendarCommand { UserId = userId });

            return Results.Ok();
        }

        public async Task<IResult> Sync(ISender sender, ClaimsPrincipal user)
        {
            var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null) return Results.Unauthorized();

            var command = new SyncGoogleCalendarCommand { UserId = userId };
            var success = await sender.Send(command);
            
            if (!success) return Results.BadRequest("Failed to sync calendar.");

            return Results.Ok();
        }

        public async Task<IResult> Disconnect(ISender sender, ClaimsPrincipal user)
        {
            var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null) return Results.Unauthorized();

            var command = new DisconnectGoogleCalendarCommand { UserId = userId };
            var success = await sender.Send(command);

            if (!success) return Results.BadRequest("Failed to disconnect Google Calendar.");

            return Results.Ok();
        }
    }

    public class ConnectGoogleCalendarRequest
    {
        public string AuthCode { get; set; } = string.Empty;
        public string GoogleEmail { get; set; } = string.Empty;
    }
}
