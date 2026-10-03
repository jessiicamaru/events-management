using HabitTracker.Application.Common;
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

        public async Task<UserProfileDto?> Handle(GetMeQuery request, CancellationToken cancellationToken)
        {
            var appUser = await _repository.GetByIdAsync(request.UserId);
            if (appUser == null) return null;

            var completedEvents = await _eventRepository.GetCompletedEventsForUserAsync(request.UserId);
            int activityStreak = StreakCalculator.FromEvents(completedEvents).Current;

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
