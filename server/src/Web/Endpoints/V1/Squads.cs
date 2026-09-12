using HabitTracker.Web.Infrastructure;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using System.Security.Claims;
using System.Threading.Tasks;
using MediatR;
using HabitTracker.Application.Features.Squads.Queries;
using HabitTracker.Application.Features.Squads.Commands;

namespace HabitTracker.Web.Endpoints.V1
{
    public class Squads : EndpointGroupBase
    {
        public override void Map(RouteGroupBuilder app)
        {
            app.RequireAuthorization();
            app.MapGet("/", GetMySquad);
            app.MapPost("/", CreateSquad);
            app.MapPost("/join", JoinSquad);
        }

        public async Task<IResult> GetMySquad(ISender sender, ClaimsPrincipal user)
        {
            var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null) return Results.Unauthorized();

            var query = new GetMySquadQuery { UserId = userId };
            var result = await sender.Send(query);

            if (result == null)
            {
                return Results.NotFound();
            }

            return Results.Ok(result);
        }

        public async Task<IResult> CreateSquad(ISender sender, ClaimsPrincipal user, CreateSquadRequest req)
        {
            var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null) return Results.Unauthorized();

            var command = new CreateSquadCommand 
            { 
                Name = req.Name,
                IsBuddyMode = req.IsBuddyMode,
                AdminUserId = userId
            };

            try
            {
                var result = await sender.Send(command);
                return Results.Ok(result);
            }
            catch (System.Exception ex)
            {
                return Results.BadRequest(ex.Message);
            }
        }

        public async Task<IResult> JoinSquad(ISender sender, ClaimsPrincipal user, JoinSquadRequest req)
        {
            var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null) return Results.Unauthorized();

            var command = new JoinSquadCommand 
            { 
                SquadId = req.SquadId,
                UserId = userId
            };

            try
            {
                await sender.Send(command);
                return Results.Ok();
            }
            catch (System.Exception ex)
            {
                return Results.BadRequest(ex.Message);
            }
        }
    }

    public class CreateSquadRequest
    {
        public string Name { get; set; } = string.Empty;
        public bool IsBuddyMode { get; set; } = true;
    }

    public class JoinSquadRequest
    {
        public System.Guid SquadId { get; set; }
    }
}
