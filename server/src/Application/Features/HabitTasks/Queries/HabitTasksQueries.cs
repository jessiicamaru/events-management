using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.HabitTasks.Queries
{
    public class GetHabitTasksQuery : IRequest<IEnumerable<HabitTask>>
    {
        public Guid HabitId { get; set; }
        public string UserId { get; set; } = string.Empty;
    }

    public class GetHabitTasksQueryHandler : IRequestHandler<GetHabitTasksQuery, IEnumerable<HabitTask>>
    {
        private readonly IHabitRepository _habitRepository;
        private readonly IHabitTaskRepository _habitTaskRepository;

        public GetHabitTasksQueryHandler(IHabitRepository habitRepository, IHabitTaskRepository habitTaskRepository)
        {
            _habitRepository = habitRepository;
            _habitTaskRepository = habitTaskRepository;
        }

        public async Task<IEnumerable<HabitTask>> Handle(GetHabitTasksQuery request, CancellationToken cancellationToken)
        {
            var habit = await _habitRepository.GetByIdAsync(request.HabitId);
            if (habit == null || habit.UserId != request.UserId) return new List<HabitTask>();

            return await _habitTaskRepository.GetByHabitIdAsync(request.HabitId);
        }
    }
}
