using MediatR;

namespace HabitTracker.Application.Features.GoogleCalendar.Events
{
    public class CalendarUpdatedEvent : INotification
    {
        public string UserId { get; }

        public CalendarUpdatedEvent(string userId)
        {
            UserId = userId;
        }
    }
}
