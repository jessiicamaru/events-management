using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using HabitTracker.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace HabitTracker.Infrastructure.Repositories
{
    public class GoogleCalendarChannelRepository : IGoogleCalendarChannelRepository
    {
        private readonly ApplicationDbContext _context;

        public GoogleCalendarChannelRepository(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task SaveChannelAsync(GoogleCalendarChannel channel, CancellationToken cancellationToken = default)
        {
            var existing = await _context.GoogleCalendarChannels
                .FirstOrDefaultAsync(x => x.UserId == channel.UserId, cancellationToken);

            if (existing != null)
            {
                _context.GoogleCalendarChannels.Remove(existing);
            }

            await _context.GoogleCalendarChannels.AddAsync(channel, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
        }

        public async Task<GoogleCalendarChannel?> GetByIdAsync(string channelId, CancellationToken cancellationToken = default)
        {
            return await _context.GoogleCalendarChannels
                .FirstOrDefaultAsync(x => x.Id == channelId, cancellationToken);
        }

        public async Task<GoogleCalendarChannel?> GetByUserIdAsync(string userId, CancellationToken cancellationToken = default)
        {
            return await _context.GoogleCalendarChannels
                .FirstOrDefaultAsync(x => x.UserId == userId, cancellationToken);
        }

        public async Task DeleteAsync(string channelId, CancellationToken cancellationToken = default)
        {
            var channel = await _context.GoogleCalendarChannels
                .FirstOrDefaultAsync(x => x.Id == channelId, cancellationToken);

            if (channel != null)
            {
                _context.GoogleCalendarChannels.Remove(channel);
                await _context.SaveChangesAsync(cancellationToken);
            }
        }
    }
}
