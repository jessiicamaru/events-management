using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Habits.Queries
{
    public class GetHabitsQuery : IRequest<IEnumerable<Habit>> { }

    public class GetHabitsQueryHandler : IRequestHandler<GetHabitsQuery, IEnumerable<Habit>>
    {
        private readonly IHabitRepository _repository;

        public GetHabitsQueryHandler(IHabitRepository repository)
        {
            _repository = repository;
        }

        public async Task<IEnumerable<Habit>> Handle(GetHabitsQuery request, CancellationToken cancellationToken)
        {
            return await _repository.GetAllAsync();
        }
    }
}
