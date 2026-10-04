using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Application.Common;
using HabitTracker.Application.Features.Analytics.Queries.GetActivitySummary;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using Moq;
using Xunit;

namespace HabitTracker.Application.Tests.Features
{
    public class GetActivitySummaryQueryHandlerTests
    {
        private const string UserId = "user-1";

        private readonly Mock<IEventRepository> _repository = new();

        private GetActivitySummaryQueryHandler CreateHandler() => new(_repository.Object);

        /// <summary>Today under the UTC+7 boundary the handler works in.</summary>
        private static DateTime Today =>
            StreakCalculator.ToLocalDate(DateTime.UtcNow, StreakCalculator.DefaultDayBoundaryOffset);

        private void RepositoryReturns(params DailyActivity[] rows)
        {
            _repository
                .Setup(r => r.GetDailyActivityAsync(
                    It.IsAny<string>(), It.IsAny<DateTime>(), It.IsAny<DateTime>()))
                .ReturnsAsync(rows);
        }

        [Fact]
        public async Task ReturnsOneEntryPerDay_IncludingDaysWithNothing()
        {
            // The database only returns days that have rows. A chart needs the gaps too,
            // otherwise a quiet week is drawn as if it were a busy one.
            RepositoryReturns(new DailyActivity
            {
                Date = Today,
                Scheduled = 2,
                Completed = 1,
                FocusMinutes = 50
            });

            var result = await CreateHandler()
                .Handle(new GetActivitySummaryQuery(UserId, 7), CancellationToken.None);

            result.Days.Should().HaveCount(7);
            result.Days.Count(d => d.Scheduled == 0).Should().Be(6);
        }

        [Fact]
        public async Task DaysAreOldestFirstAndEndToday()
        {
            RepositoryReturns();

            var result = await CreateHandler()
                .Handle(new GetActivitySummaryQuery(UserId, 5), CancellationToken.None);

            result.Days.Should().BeInAscendingOrder(d => d.Date);
            result.Days.Last().Date.Should().Be(Today);
            result.Days.First().Date.Should().Be(Today.AddDays(-4));
        }

        [Fact]
        public async Task TotalsAddUpAcrossTheWindow()
        {
            RepositoryReturns(
                new DailyActivity { Date = Today, Scheduled = 3, Completed = 2, FocusMinutes = 40 },
                new DailyActivity
                {
                    Date = Today.AddDays(-1),
                    Scheduled = 1,
                    Completed = 1,
                    FocusMinutes = 25
                });

            var result = await CreateHandler()
                .Handle(new GetActivitySummaryQuery(UserId, 7), CancellationToken.None);

            result.TotalScheduled.Should().Be(4);
            result.TotalCompleted.Should().Be(3);
            result.TotalFocusMinutes.Should().Be(65);
            result.BestFocusMinutes.Should().Be(40);
        }

        [Fact]
        public async Task IgnoresRowsOutsideTheWindow()
        {
            // The repository filters by date, but a row landing outside the requested
            // window must not silently inflate the totals if it ever does come back.
            RepositoryReturns(
                new DailyActivity { Date = Today, Scheduled = 1, Completed = 1, FocusMinutes = 10 },
                new DailyActivity
                {
                    Date = Today.AddDays(-30),
                    Scheduled = 99,
                    Completed = 99,
                    FocusMinutes = 999
                });

            var result = await CreateHandler()
                .Handle(new GetActivitySummaryQuery(UserId, 3), CancellationToken.None);

            result.TotalScheduled.Should().Be(1);
            result.TotalFocusMinutes.Should().Be(10);
        }

        [Theory]
        [InlineData(0, GetActivitySummaryQueryHandler.MinDays)]
        [InlineData(-5, GetActivitySummaryQueryHandler.MinDays)]
        [InlineData(5000, GetActivitySummaryQueryHandler.MaxDays)]
        public async Task ClampsTheRequestedWindow(int requested, int expectedDays)
        {
            RepositoryReturns();

            var result = await CreateHandler()
                .Handle(new GetActivitySummaryQuery(UserId, requested), CancellationToken.None);

            result.Days.Should().HaveCount(expectedDays);
        }

        [Fact]
        public async Task AsksTheRepositoryForTheSignedInUserOnly()
        {
            RepositoryReturns();

            await CreateHandler()
                .Handle(new GetActivitySummaryQuery(UserId, 7), CancellationToken.None);

            _repository.Verify(
                r => r.GetDailyActivityAsync(UserId, It.IsAny<DateTime>(), It.IsAny<DateTime>()),
                Times.Once);
        }

        [Fact]
        public async Task RequestsAWindowThatCoversWholeLocalDays()
        {
            // The rows are stored in UTC but the days are UTC+7, so the window has to be
            // shifted. Getting this wrong clips the first and last day by seven hours,
            // which quietly drops early-morning events from the chart.
            DateTime? from = null;
            DateTime? to = null;

            _repository
                .Setup(r => r.GetDailyActivityAsync(
                    It.IsAny<string>(), It.IsAny<DateTime>(), It.IsAny<DateTime>()))
                .Callback<string, DateTime, DateTime>((_, f, t) => { from = f; to = t; })
                .ReturnsAsync(Array.Empty<DailyActivity>());

            await CreateHandler()
                .Handle(new GetActivitySummaryQuery(UserId, 7), CancellationToken.None);

            var offset = StreakCalculator.DefaultDayBoundaryOffset;
            from.Should().Be(Today.AddDays(-6) - offset);
            to.Should().Be(Today.AddDays(1) - offset);
            (to!.Value - from!.Value).Should().Be(TimeSpan.FromDays(7));
        }

        [Fact]
        public async Task ThrowsWhenTheUserIdIsMissing()
        {
            var act = () => CreateHandler()
                .Handle(new GetActivitySummaryQuery("", 7), CancellationToken.None);

            await act.Should().ThrowAsync<ArgumentException>();
        }
    }
}
