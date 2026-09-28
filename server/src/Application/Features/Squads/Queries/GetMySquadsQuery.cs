using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Squads.Queries
{
    public class MySquadSummaryDto
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public int MemberCount { get; set; }
        public int MaxMembers { get; set; }
        public int TotalSquadXP { get; set; }
    }

    public class GetMySquadsQuery : IRequest<List<MySquadSummaryDto>>
    {
        public string UserId { get; set; } = string.Empty;
    }

    public class GetMySquadsQueryHandler : IRequestHandler<GetMySquadsQuery, List<MySquadSummaryDto>>
    {
        private readonly ISquadRepository _repository;

        public GetMySquadsQueryHandler(ISquadRepository repository)
        {
            _repository = repository;
        }

        public async Task<List<MySquadSummaryDto>> Handle(GetMySquadsQuery request, CancellationToken cancellationToken)
        {
            var squads = await _repository.GetSquadsByUserIdAsync(request.UserId);
            var summaries = new List<MySquadSummaryDto>();

            foreach (var squad in squads)
            {
                var count = await _repository.GetMemberCountAsync(squad.Id);
                summaries.Add(new MySquadSummaryDto
                {
                    Id = squad.Id,
                    Name = squad.Name,
                    MemberCount = count,
                    MaxMembers = squad.MaxMembers,
                    TotalSquadXP = squad.TotalSquadXP
                });
            }

            return summaries;
        }
    }
}
