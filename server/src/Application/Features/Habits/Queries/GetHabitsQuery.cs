using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using MediatR;

namespace HabitTracker.Application.Features.Habits.Queries
{
    public class GetHabitsQuery : IRequest<IEnumerable<Habit>> 
    {
        public string UserId { get; set; } = string.Empty;
    }

    public class GetHabitsQueryHandler : IRequestHandler<GetHabitsQuery, IEnumerable<Habit>>
    {
        private readonly IHabitRepository _repository;

        public GetHabitsQueryHandler(IHabitRepository repository)
        {
            _repository = repository;
        }

        public async Task<IEnumerable<Habit>> Handle(GetHabitsQuery request, CancellationToken cancellationToken)
        {
            // Refuse rather than widen: an unset UserId used to fall back to every user's habits,
            // so one forgotten assignment turned into a cross-user data leak.
            if (string.IsNullOrEmpty(request.UserId))
                throw new ArgumentException("UserId is required.", nameof(request));

            return await _repository.GetHabitsForUserAsync(request.UserId);
        }
    }
}
