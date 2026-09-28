using HabitTracker.Domain.Interfaces;
using MediatR;
using System.Threading;
using System.Threading.Tasks;
using System.Linq;
using System.Collections.Generic;

namespace HabitTracker.Application.Features.Squads.Queries
{
    public class SquadMemberDto
    {
        public string UserId { get; set; } = string.Empty;
        public string Role { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public int TotalXP { get; set; }
        public int CurrentStreak { get; set; }
        public List<string> UnlockedEmojis { get; set; } = new();
        public string? AvatarBorderColor { get; set; }
        public string? Nickname { get; set; }
        public bool IsMuted { get; set; }
        public bool XpContributionEnabled { get; set; }
        public bool IsApproved { get; set; }
    }

    public class SquadDto
    {
        public System.Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public int MaxMembers { get; set; }
        public bool RequireApproval { get; set; }
        public int TotalSquadXP { get; set; }
        public string UnlockedHeatmapColor { get; set; } = string.Empty;
        public List<SquadMemberDto> Members { get; set; } = new();
    }

    public class GetMySquadQuery : IRequest<SquadDto?>
    {
        public string UserId { get; set; } = string.Empty;
        public System.Guid? SquadId { get; set; }
    }

    public class GetMySquadQueryHandler : IRequestHandler<GetMySquadQuery, SquadDto?>
    {
        private readonly ISquadRepository _repository;
        private readonly IHabitRepository _habitRepository;

        public GetMySquadQueryHandler(ISquadRepository repository, IHabitRepository habitRepository)
        {
            _repository = repository;
            _habitRepository = habitRepository;
        }

        public async Task<SquadDto?> Handle(GetMySquadQuery request, CancellationToken cancellationToken)
        {
            HabitTracker.Domain.Entities.Squad? squad = null;
            if (request.SquadId.HasValue)
            {
                squad = await _repository.GetSquadByIdAsync(request.SquadId.Value);
            }
            else
            {
                var squads = await _repository.GetSquadsByUserIdAsync(request.UserId);
                squad = squads.FirstOrDefault();
            }

            if (squad == null) return null;

            // Verify the user is a member of the squad
            var callerMembership = await _repository.GetMembershipAsync(squad.Id, request.UserId);
            if (callerMembership == null) return null;

            var members = await _repository.GetSquadMembersAsync(squad.Id);
            var memberDtos = new List<SquadMemberDto>();

            foreach (var sm in members)
            {
                var habits = await _habitRepository.GetHabitsForUserAsync(sm.UserId);
                int maxStreak = habits.Any() ? habits.Max(h => h.CurrentStreak) : 0;

                memberDtos.Add(new SquadMemberDto
                {
                    UserId = sm.UserId,
                    Role = sm.Role,
                    Email = sm.User?.Email ?? string.Empty,
                    TotalXP = sm.User?.TotalXP ?? 0,
                    CurrentStreak = maxStreak,
                    UnlockedEmojis = sm.User?.UnlockedEmojis ?? new List<string>(),
                    AvatarBorderColor = sm.User?.AvatarBorderColor,
                    Nickname = sm.Nickname,
                    IsMuted = sm.IsMuted,
                    XpContributionEnabled = sm.XpContributionEnabled,
                    IsApproved = sm.IsApproved
                });
            }

            return new SquadDto
            {
                Id = squad.Id,
                Name = squad.Name,
                MaxMembers = squad.MaxMembers,
                RequireApproval = squad.RequireApproval,
                TotalSquadXP = squad.TotalSquadXP,
                UnlockedHeatmapColor = squad.UnlockedHeatmapColor,
                Members = memberDtos
            };
        }
    }
}
