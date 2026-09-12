using HabitTracker.Web.Infrastructure;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using System.Security.Claims;
using System.Threading.Tasks;
using System.Collections.Generic;
using MediatR;
using HabitTracker.Application.Features.Users.Queries;
using HabitTracker.Application.Features.Users.Commands;

namespace HabitTracker.Web.Endpoints.V1
{
    public class Users : EndpointGroupBase
    {
        public override void Map(RouteGroupBuilder app)
        {
            app.RequireAuthorization();
            app.MapGet("/me", GetMe);
            app.MapPut("/me/cosmetics", UpdateCosmetics);
        }

        public async Task<IResult> GetMe(ISender sender, ClaimsPrincipal user)
        {
            var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null) return Results.Unauthorized();

            var query = new GetMeQuery { UserId = userId };
            var result = await sender.Send(query);
            
            if (result == null)
            {
                return Results.NotFound();
            }

            return Results.Ok(result);
        }

        public async Task<IResult> UpdateCosmetics(ISender sender, ClaimsPrincipal user, UpdateCosmeticsRequest req)
        {
            var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null) return Results.Unauthorized();

            var command = new UpdateCosmeticsCommand 
            { 
                UserId = userId,
                UnlockedEmojis = req.UnlockedEmojis,
                AvatarBorderColor = req.AvatarBorderColor
            };

            await sender.Send(command);
            return Results.Ok();
        }
    }

    public class UpdateCosmeticsRequest
    {
        public List<string>? UnlockedEmojis { get; set; }
        public string? AvatarBorderColor { get; set; }
    }
}
