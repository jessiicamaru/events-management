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
            app.MapPut("/me", UpdateProfile);
            app.MapPost("/me/change-password", ChangePassword);
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

        public async Task<IResult> UpdateProfile(ISender sender, ClaimsPrincipal user, UpdateProfileRequest req)
        {
            var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null) return Results.Unauthorized();

            var command = new UpdateProfileCommand 
            { 
                UserId = userId,
                DisplayName = req.DisplayName,
                Bio = req.Bio,
                DateOfBirth = req.DateOfBirth,
                Gender = req.Gender,
                PhoneNumber = req.PhoneNumber,
                Avatar = req.Avatar
            };

            var success = await sender.Send(command);
            if (!success) return Results.NotFound();

            return Results.Ok();
        }

        public async Task<IResult> ChangePassword(ISender sender, ClaimsPrincipal user, ChangePasswordRequest req)
        {
            var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null) return Results.Unauthorized();

            var command = new ChangePasswordCommand 
            { 
                UserId = userId,
                CurrentPassword = req.CurrentPassword,
                NewPassword = req.NewPassword
            };

            var result = await sender.Send(command);
            if (!result.Succeeded)
            {
                return Results.BadRequest(result.Errors);
            }

            return Results.Ok();
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

    public class UpdateProfileRequest
    {
        public string? DisplayName { get; set; }
        public string? Bio { get; set; }
        public System.DateTime? DateOfBirth { get; set; }
        public string? Gender { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Avatar { get; set; }
    }

    public class ChangePasswordRequest
    {
        public string CurrentPassword { get; set; } = string.Empty;
        public string NewPassword { get; set; } = string.Empty;
    }

    public class UpdateCosmeticsRequest
    {
        public List<string>? UnlockedEmojis { get; set; }
        public string? AvatarBorderColor { get; set; }
    }
}
