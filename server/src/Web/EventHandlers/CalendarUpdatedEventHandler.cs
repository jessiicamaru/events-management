using MediatR;
using Microsoft.AspNetCore.SignalR;
using HabitTracker.Application.Features.GoogleCalendar.Events;
using HabitTracker.Web.Hubs;
using System.Threading;
using System.Threading.Tasks;

namespace HabitTracker.Web.EventHandlers
{
    public class CalendarUpdatedEventHandler : INotificationHandler<CalendarUpdatedEvent>
    {
        private readonly IHubContext<SocialHub> _hubContext;

        public CalendarUpdatedEventHandler(IHubContext<SocialHub> hubContext)
        {
            _hubContext = hubContext;
        }

        public async Task Handle(CalendarUpdatedEvent notification, CancellationToken cancellationToken)
        {
            await _hubContext.Clients.User(notification.UserId).SendAsync("CalendarUpdated", cancellationToken);
        }
    }
}
