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
        public List<string> UnlockedEmojis { get; set; } = new();
        public string? AvatarBorderColor { get; set; }
    }

    public class SquadDto
    {
        public System.Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public bool IsBuddyMode { get; set; }
        public int TotalSquadXP { get; set; }
        public string UnlockedHeatmapColor { get; set; } = string.Empty;
        public List<SquadMemberDto> Members { get; set; } = new();
    }

    public class GetMySquadQuery : IRequest<SquadDto?>
    {
        public string UserId { get; set; } = string.Empty;
    }

    public class GetMySquadQueryHandler : IRequestHandler<GetMySquadQuery, SquadDto?>
    {
        private readonly ISquadRepository _repository;

        public GetMySquadQueryHandler(ISquadRepository repository)
        {
            _repository = repository;
        }

        public async Task<SquadDto?> Handle(GetMySquadQuery request, CancellationToken cancellationToken)
        {
            var squad = await _repository.GetSquadByUserIdAsync(request.UserId);
            if (squad == null) return null;

            var members = await _repository.GetSquadMembersAsync(squad.Id);

            return new SquadDto
            {
                Id = squad.Id,
                Name = squad.Name,
                IsBuddyMode = squad.IsBuddyMode,
                TotalSquadXP = squad.TotalSquadXP,
                UnlockedHeatmapColor = squad.UnlockedHeatmapColor,
                Members = members.Select(sm => new SquadMemberDto
                {
                    UserId = sm.UserId,
                    Role = sm.Role,
                    Email = sm.User?.Email ?? string.Empty,
                    TotalXP = sm.User?.TotalXP ?? 0,
                    UnlockedEmojis = sm.User?.UnlockedEmojis ?? new List<string>(),
                    AvatarBorderColor = sm.User?.AvatarBorderColor
                }).ToList()
            };
        }
    }
}
