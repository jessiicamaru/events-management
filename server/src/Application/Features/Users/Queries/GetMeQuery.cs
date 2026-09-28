using HabitTracker.Domain.Interfaces;
using MediatR;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Linq;

namespace HabitTracker.Application.Features.Users.Queries
{
    public class UserProfileDto
    {
        public string Id { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public int TotalXP { get; set; }
        public int CurrentStreak { get; set; }
        public List<string> UnlockedEmojis { get; set; } = new();
        public string? AvatarBorderColor { get; set; }
        public string? DisplayName { get; set; }
        public string? Bio { get; set; }
        public System.DateTime? DateOfBirth { get; set; }
        public string? Gender { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Avatar { get; set; }
        public string? GoogleEmail { get; set; }
    }

    public class GetMeQuery : IRequest<UserProfileDto?>
    {
        public string UserId { get; set; } = string.Empty;
    }

    public class GetMeQueryHandler : IRequestHandler<GetMeQuery, UserProfileDto?>
    {
        private readonly IUserRepository _repository;
        private readonly IEventRepository _eventRepository;

        public GetMeQueryHandler(IUserRepository repository, IEventRepository eventRepository)
        {
            _repository = repository;
            _eventRepository = eventRepository;
        }

        private static System.DateTime ToLocalTimeUtc7(System.DateTime dt)
        {
            if (dt.Kind == System.DateTimeKind.Utc) return dt.AddHours(7);
            if (dt.Kind == System.DateTimeKind.Local) return dt.ToUniversalTime().AddHours(7);
            return System.DateTime.SpecifyKind(dt, System.DateTimeKind.Utc).AddHours(7);
        }

        private int CalculateActivityStreak(IEnumerable<Domain.Entities.Event> completedEvents)
        {
            if (!completedEvents.Any()) return 0;

            var completionDates = completedEvents
                .Select(e => ToLocalTimeUtc7(e.StartTime).Date)
                .Distinct()
                .OrderBy(d => d)
                .ToList();

            int currentStreak = 0;
            int tempStreak = 0;
            System.DateTime? previousDate = null;

            foreach (var date in completionDates)
            {
                if (previousDate == null)
                {
                    tempStreak = 1;
                }
                else
                {
                    if (date == previousDate.Value.AddDays(1))
                    {
                        tempStreak++;
                    }
                    else
                    {
                        tempStreak = 1;
                    }
                }
                previousDate = date;
            }

            var today = ToLocalTimeUtc7(System.DateTime.UtcNow).Date;
            if (previousDate.HasValue && (previousDate.Value == today || previousDate.Value == today.AddDays(-1)))
            {
                currentStreak = tempStreak;
            }
            else
            {
                currentStreak = 0;
            }

            return currentStreak;
        }

        public async Task<UserProfileDto?> Handle(GetMeQuery request, CancellationToken cancellationToken)
        {
            var appUser = await _repository.GetByIdAsync(request.UserId);
            if (appUser == null) return null;

            var allEvents = await _eventRepository.GetEventsForUserAsync(request.UserId);
            var completedEvents = allEvents.Where(e => e.IsCompleted);
            int activityStreak = CalculateActivityStreak(completedEvents);

            return new UserProfileDto
            {
                Id = appUser.Id,
                Email = appUser.Email ?? string.Empty,
                TotalXP = appUser.TotalXP,
                CurrentStreak = activityStreak,
                UnlockedEmojis = appUser.UnlockedEmojis,
                AvatarBorderColor = appUser.AvatarBorderColor,
                DisplayName = appUser.DisplayName,
                Bio = appUser.Bio,
                DateOfBirth = appUser.DateOfBirth,
                Gender = appUser.Gender,
                PhoneNumber = appUser.PhoneNumber,
                Avatar = appUser.Avatar,
                GoogleEmail = appUser.GoogleEmail
            };
        }
    }
}
