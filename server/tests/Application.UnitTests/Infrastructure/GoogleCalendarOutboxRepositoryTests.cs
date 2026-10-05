using System;
using System.Linq;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Domain.Entities;
using HabitTracker.Infrastructure.Data;
using HabitTracker.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace HabitTracker.Application.Tests.Infrastructure
{
    public class GoogleCalendarOutboxRepositoryTests
    {
        private readonly ApplicationDbContext _context = new(
            new DbContextOptionsBuilder<ApplicationDbContext>()
                .UseInMemoryDatabase(Guid.NewGuid().ToString())
                .Options);

        private readonly GoogleCalendarOutboxRepository _repository;
        private readonly Guid _eventId = Guid.NewGuid();

        public GoogleCalendarOutboxRepositoryTests()
        {
            _repository = new GoogleCalendarOutboxRepository(_context);
        }

        private async Task QueueAsync(string action, int retryCount = 0, DateTime? processedAt = null)
        {
            _context.GoogleCalendarOutboxes.Add(new GoogleCalendarOutbox
            {
                UserId = "user-1",
                EventId = _eventId,
                Action = action,
                RetryCount = retryCount,
                ProcessedAt = processedAt
            });
            await _context.SaveChangesAsync();
        }

        [Fact]
        public async Task HasPendingInsert_ForAnInsertStillToBeTried()
        {
            await QueueAsync("Insert", retryCount: GoogleCalendarOutbox.MaxRetries - 1);

            (await _repository.HasPendingInsertAsync(_eventId)).Should().BeTrue();
        }

        [Fact]
        public async Task HasNoPendingInsert_OnceTheWorkerHasGivenUpOnIt()
        {
            // Review of feat/home-page, LOW 7: the worker stops at MaxRetries without setting
            // ProcessedAt. Counted as pending, the event looked known to Google for good, so
            // every later edit queued an Update that could only fail.
            await QueueAsync("Insert", retryCount: GoogleCalendarOutbox.MaxRetries);

            (await _repository.HasPendingInsertAsync(_eventId)).Should().BeFalse();
        }

        [Fact]
        public async Task HasNoPendingInsert_WhenItWasSentOrIsNotAnInsert()
        {
            await QueueAsync("Insert", processedAt: DateTime.UtcNow);
            await QueueAsync("Update");

            (await _repository.HasPendingInsertAsync(_eventId)).Should().BeFalse();
        }

        [Fact]
        public async Task GetUnprocessed_StopsAtTheSameRetryLimit()
        {
            await QueueAsync("Update", retryCount: GoogleCalendarOutbox.MaxRetries - 1);
            await QueueAsync("Update", retryCount: GoogleCalendarOutbox.MaxRetries);

            var queue = await _repository.GetUnprocessedAsync();

            queue.Select(x => x.RetryCount).Should().Equal(GoogleCalendarOutbox.MaxRetries - 1);
        }
    }
}
