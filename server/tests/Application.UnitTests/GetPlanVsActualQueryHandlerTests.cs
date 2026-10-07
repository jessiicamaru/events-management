using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Application.Common;
using HabitTracker.Application.Features.Analytics.Queries.GetPlanVsActual;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using Moq;
using Xunit;

namespace HabitTracker.Application.Tests
{
    public class GetPlanVsActualQueryHandlerTests
    {
        private const string UserId = "user-1";

        private readonly Mock<IEventRepository> _events = new();
        private readonly GetPlanVsActualQueryHandler _handler;

        private (DateTime From, DateTime To)? _window;

        public GetPlanVsActualQueryHandlerTests()
        {
            _events.Setup(r => r.GetPlanVsActualByHabitAsync(
                    It.IsAny<string>(), It.IsAny<DateTime>(), It.IsAny<DateTime>()))
                .Callback<string, DateTime, DateTime>((_, from, to) => _window = (from, to))
                .ReturnsAsync(new List<PlanVsActual>());
            _events.Setup(r => r.GetPlanVsActualByCategoryAsync(
                    It.IsAny<string>(), It.IsAny<DateTime>(), It.IsAny<DateTime>()))
                .ReturnsAsync(new List<PlanVsActual>());
            _events.Setup(r => r.GetPlanVsActualTotalsAsync(
                    It.IsAny<string>(), It.IsAny<DateTime>(), It.IsAny<DateTime>()))
                .ReturnsAsync(new PlanVsActual());

            _handler = new GetPlanVsActualQueryHandler(_events.Object);
        }

        private static PlanVsActual Row(
            string name,
            int planned,
            int actual,
            int sessions = 1,
            string? id = null) =>
            new()
            {
                GroupId = id ?? name.ToLowerInvariant(),
                GroupName = name,
                Sessions = sessions,
                PlannedMinutes = planned,
                ActualMinutes = actual
            };

        private void HabitRows(params PlanVsActual[] rows) =>
            _events.Setup(r => r.GetPlanVsActualByHabitAsync(UserId, It.IsAny<DateTime>(), It.IsAny<DateTime>()))
                .ReturnsAsync(rows.ToList());

        private void Totals(int sessions, int planned, int actual) =>
            _events.Setup(r => r.GetPlanVsActualTotalsAsync(UserId, It.IsAny<DateTime>(), It.IsAny<DateTime>()))
                .ReturnsAsync(new PlanVsActual
                {
                    Sessions = sessions,
                    PlannedMinutes = planned,
                    ActualMinutes = actual
                });

        private void CategoryRows(params PlanVsActual[] rows) =>
            _events.Setup(r => r.GetPlanVsActualByCategoryAsync(UserId, It.IsAny<DateTime>(), It.IsAny<DateTime>()))
                .ReturnsAsync(rows.ToList());

        private Task<PlanVsActualDto> Handle(int days = 14) =>
            _handler.Handle(new GetPlanVsActualQuery(UserId, days), CancellationToken.None);

        [Fact]
        public async Task PassesThroughBothGroupings_WithTheRepositorysOrder()
        {
            HabitRows(Row("Reading", planned: 90, actual: 54, sessions: 3), Row("Running", 60, 65, 2));
            CategoryRows(Row("Study", 90, 54, 3));

            var result = await Handle();

            result.ByHabit.Select(i => i.Name).Should().Equal("Reading", "Running");
            result.ByHabit[0].PlannedMinutes.Should().Be(90);
            result.ByHabit[0].ActualMinutes.Should().Be(54);
            result.ByHabit[0].Sessions.Should().Be(3);
            result.ByCategory.Should().ContainSingle().Which.Name.Should().Be("Study");
        }

        [Fact]
        public async Task TotalsCountEverySession_NotASumOfEitherGrouping()
        {
            // Neither grouping sees every session: an event need not have a habit, and need
            // not have a category. Summing one of them under-counts, summing both
            // double-counts. The groupings here deliberately disagree with the totals.
            HabitRows(Row("Reading", 90, 54, 3), Row("Running", 60, 65, 2));
            CategoryRows(Row("Study", 500, 500, 50));
            Totals(sessions: 7, planned: 210, actual: 149);

            var result = await Handle();

            result.TotalSessions.Should().Be(7);
            result.TotalPlannedMinutes.Should().Be(210);
            result.TotalActualMinutes.Should().Be(149);
        }

        [Fact]
        public async Task ReportsSessionsWithNoHabit_InsteadOfNothingAtAll()
        {
            // Measured on the dev database: the only account with sessions in the last
            // 14 days had 15, all on plain calendar events, so the habit join matched none.
            // Derived totals made that user's card say "nothing here yet".
            Totals(sessions: 15, planned: 900, actual: 790);

            var result = await Handle();

            result.ByHabit.Should().BeEmpty();
            result.TotalSessions.Should().Be(15);
            result.TotalActualMinutes.Should().Be(790);
        }

        [Fact]
        public async Task ReturnsEmptyTotals_WhenNothingWasFinishedInTheWindow()
        {
            Totals(sessions: 0, planned: 0, actual: 0);

            var result = await Handle();

            result.ByHabit.Should().BeEmpty();
            result.ByCategory.Should().BeEmpty();
            result.TotalPlannedMinutes.Should().Be(0);
            result.TotalActualMinutes.Should().Be(0);
            result.TotalSessions.Should().Be(0);
        }

        [Theory]
        [InlineData(0, GetPlanVsActualQueryHandler.MinDays)]
        [InlineData(-5, GetPlanVsActualQueryHandler.MinDays)]
        [InlineData(14, 14)]
        [InlineData(500, GetPlanVsActualQueryHandler.MaxDays)]
        public async Task ClampsTheWindow(int asked, int expectedDays)
        {
            await Handle(asked);

            _window.Should().NotBeNull();
            var span = _window!.Value.To - _window.Value.From;
            span.Should().Be(TimeSpan.FromDays(expectedDays));
        }

        [Fact]
        public async Task AsksForTheSameWindowTheActivityCardUses()
        {
            // Both cards sit on the same screen saying "last 14 days"; if the two windows
            // disagreed by an hour, their numbers would disagree too.
            await Handle(14);

            var offset = StreakCalculator.DefaultDayBoundaryOffset;
            var today = StreakCalculator.ToLocalDate(DateTime.UtcNow, offset);

            _window!.Value.From.Should().Be(today.AddDays(-13) - offset);
            _window.Value.To.Should().Be(today.AddDays(1) - offset);
        }

        [Fact]
        public async Task RefusesAQueryWithNoUser()
        {
            var act = () => _handler.Handle(new GetPlanVsActualQuery(string.Empty, 14), CancellationToken.None);

            await act.Should().ThrowAsync<ArgumentException>();
        }
    }
}
