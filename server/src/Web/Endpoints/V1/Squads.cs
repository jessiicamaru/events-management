using HabitTracker.Web.Infrastructure;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using System.Security.Claims;
using System.Threading.Tasks;
using MediatR;
using HabitTracker.Application.Features.Squads.Queries;
using HabitTracker.Application.Features.Squads.Commands;
using System;
using Microsoft.AspNetCore.Mvc;

namespace HabitTracker.Web.Endpoints.V1
{
    public class Squads : EndpointGroupBase
    {
        public override void Map(RouteGroupBuilder app)
        {
            app.RequireAuthorization();
            app.MapGet("/", GetMySquad);
            app.MapGet("/list", GetMySquads);
            app.MapPost("/", CreateSquad);
            app.MapPost("/join", JoinSquad);
            app.MapPost("/{id:guid}/approve/{targetUserId}", ApproveMember);
            app.MapPost("/{id:guid}/reject/{targetUserId}", RejectMember);
            app.MapDelete("/{id:guid}/leave", LeaveSquad);
            app.MapPut("/{id:guid}/settings", UpdateSquadSettings);
            app.MapPost("/{id:guid}/change-leader", ChangeLeader);
            app.MapPut("/{id:guid}/member-settings", UpdateMemberSettings);
            app.MapPut("/{id:guid}/member-nickname", ChangeMemberNickname);
            app.MapGet("/{id:guid}/chat-history", GetChatHistory);
        }

        public async Task<IResult> GetMySquad(ISender sender, ClaimsPrincipal user, [FromQuery] Guid? squadId)
        {
            var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null) return Results.Unauthorized();

            var query = new GetMySquadQuery { UserId = userId, SquadId = squadId };
            var result = await sender.Send(query);

            if (result == null)
            {
                return Results.NotFound();
            }

            return Results.Ok(result);
        }

        public async Task<IResult> GetMySquads(ISender sender, ClaimsPrincipal user)
        {
            var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null) return Results.Unauthorized();

            var query = new GetMySquadsQuery { UserId = userId };
            var result = await sender.Send(query);
            return Results.Ok(result);
        }

        public async Task<IResult> CreateSquad(ISender sender, ClaimsPrincipal user, CreateSquadRequest req)
        {
            var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null) return Results.Unauthorized();

            var command = new CreateSquadCommand 
            { 
                Name = req.Name,
                MaxMembers = req.MaxMembers,
                RequireApproval = req.RequireApproval,
                AdminUserId = userId
            };

            try
            {
                var result = await sender.Send(command);
                return Results.Ok(result);
            }
            catch (Exception ex)
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
                var isApproved = await sender.Send(command);
                return Results.Ok(new JoinSquadResponse { IsApproved = isApproved });
            }
            catch (Exception ex)
            {
                return Results.BadRequest(ex.Message);
            }
        }

        public async Task<IResult> ApproveMember(ISender sender, ClaimsPrincipal user, Guid id, string targetUserId)
        {
            var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null) return Results.Unauthorized();

            var command = new ApproveMemberCommand
            {
                SquadId = id,
                TargetUserId = targetUserId,
                ActionByUserId = userId
            };

            try
            {
                await sender.Send(command);
                return Results.Ok();
            }
            catch (Exception ex)
            {
                return Results.BadRequest(ex.Message);
            }
        }

        public async Task<IResult> RejectMember(ISender sender, ClaimsPrincipal user, Guid id, string targetUserId)
        {
            var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null) return Results.Unauthorized();

            var command = new RejectMemberCommand
            {
                SquadId = id,
                TargetUserId = targetUserId,
                ActionByUserId = userId
            };

            try
            {
                await sender.Send(command);
                return Results.Ok();
            }
            catch (Exception ex)
            {
                return Results.BadRequest(ex.Message);
            }
        }

        public async Task<IResult> LeaveSquad(ISender sender, ClaimsPrincipal user, Guid id)
        {
            var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null) return Results.Unauthorized();

            var command = new LeaveSquadCommand
            {
                SquadId = id,
                UserId = userId
            };

            try
            {
                await sender.Send(command);
                return Results.Ok();
            }
            catch (Exception ex)
            {
                return Results.BadRequest(ex.Message);
            }
        }

        public async Task<IResult> UpdateSquadSettings(ISender sender, ClaimsPrincipal user, Guid id, UpdateSquadSettingsRequest req)
        {
            var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null) return Results.Unauthorized();

            var command = new UpdateSquadSettingsCommand
            {
                SquadId = id,
                Name = req.Name,
                MaxMembers = req.MaxMembers,
                RequireApproval = req.RequireApproval,
                ActionByUserId = userId
            };

            try
            {
                await sender.Send(command);
                return Results.Ok();
            }
            catch (Exception ex)
            {
                return Results.BadRequest(ex.Message);
            }
        }

        public async Task<IResult> ChangeLeader(ISender sender, ClaimsPrincipal user, Guid id, ChangeLeaderRequest req)
        {
            var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null) return Results.Unauthorized();

            var command = new ChangeLeaderCommand
            {
                SquadId = id,
                TargetUserId = req.TargetUserId,
                ActionByUserId = userId
            };

            try
            {
                await sender.Send(command);
                return Results.Ok();
            }
            catch (Exception ex)
            {
                return Results.BadRequest(ex.Message);
            }
        }

        public async Task<IResult> UpdateMemberSettings(ISender sender, ClaimsPrincipal user, Guid id, UpdateMemberSettingsRequest req)
        {
            var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null) return Results.Unauthorized();

            var command = new UpdateMemberSettingsCommand
            {
                SquadId = id,
                UserId = userId,
                Nickname = req.Nickname,
                IsMuted = req.IsMuted,
                XpContributionEnabled = req.XpContributionEnabled
            };

            try
            {
                await sender.Send(command);
                return Results.Ok();
            }
            catch (Exception ex)
            {
                return Results.BadRequest(ex.Message);
            }
        }

        public async Task<IResult> ChangeMemberNickname(ISender sender, ClaimsPrincipal user, Guid id, ChangeMemberNicknameRequest req)
        {
            var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null) return Results.Unauthorized();

            var command = new ChangeMemberNicknameCommand
            {
                SquadId = id,
                TargetUserId = req.TargetUserId,
                NewNickname = req.NewNickname,
                ActionByUserId = userId
            };

            try
            {
                await sender.Send(command);
                return Results.Ok();
            }
            catch (Exception ex)
            {
                return Results.BadRequest(ex.Message);
            }
        }

        public async Task<IResult> GetChatHistory(ISender sender, ClaimsPrincipal user, Guid id)
        {
            var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
            if (userId == null) return Results.Unauthorized();

            var query = new GetChatHistoryQuery
            {
                SquadId = id,
                UserId = userId
            };

            try
            {
                var result = await sender.Send(query);
                return Results.Ok(result);
            }
            catch (Exception ex)
            {
                return Results.BadRequest(ex.Message);
            }
        }
    }

    public class CreateSquadRequest
    {
        public string Name { get; set; } = string.Empty;
        public int MaxMembers { get; set; } = 5;
        public bool RequireApproval { get; set; } = false;
    }

    public class JoinSquadRequest
    {
        public Guid SquadId { get; set; }
    }

    public class JoinSquadResponse
    {
        public bool IsApproved { get; set; }
    }

    public class UpdateSquadSettingsRequest
    {
        public string Name { get; set; } = string.Empty;
        public int MaxMembers { get; set; }
        public bool RequireApproval { get; set; }
    }

    public class ChangeLeaderRequest
    {
        public string TargetUserId { get; set; } = string.Empty;
    }

    public class UpdateMemberSettingsRequest
    {
        public string? Nickname { get; set; }
        public bool IsMuted { get; set; }
        public bool XpContributionEnabled { get; set; }
    }

    public class ChangeMemberNicknameRequest
    {
        public string TargetUserId { get; set; } = string.Empty;
        public string NewNickname { get; set; } = string.Empty;
    }
}
