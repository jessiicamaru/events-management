using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Application.Common;
using HabitTracker.Application.Features.Assistant.Harness;
using HabitTracker.Application.Features.Assistant.Scheduling;
using HabitTracker.Application.Features.Assistant.Tools;
using HabitTracker.Application.Features.Events.Queries;
using HabitTracker.Application.Features.Habits.Queries;
using HabitTracker.Application.Tests.TestDoubles;
using HabitTracker.Domain.Entities;
using MediatR;
using Moq;
using Xunit;

namespace HabitTracker.Application.Tests.Features.Assistant
{
    public class ProposeScheduleToolTests
    {
        private const string UserId = "user-1";
        private static readonly TimeSpan Offset = StreakCalculator.DefaultDayBoundaryOffset;
        private static readonly Guid ConversationId = Guid.NewGuid();

        // 14:00 on Monday 28 September 2026, local.
        private static readonly ToolContext Context =
            new(UserId, new DateTime(2026, 9, 28, 7, 0, 0, DateTimeKind.Utc), Offset, ConversationId, "call-1");

        private readonly Mock<ISender> _sender = new();
        private readonly InMemoryAssistantRepository _repository = new();
        private readonly List<Habit> _habits = new();
        private readonly List<Event> _events = new();

        public ProposeScheduleToolTests()
        {
            _sender.Setup(s => s.Send(It.IsAny<GetHabitsQuery>(), It.IsAny<CancellationToken>())).ReturnsAsync(() => _habits);
            _sender.Setup(s => s.Send(It.IsAny<GetEventsQuery>(), It.IsAny<CancellationToken>())).ReturnsAsync(() => _events);
        }

        private ProposeScheduleTool Tool => new(_sender.Object, _repository);

        private static JsonElement Args(object value) => JsonSerializer.SerializeToElement(value);

        private static object DailyRun(object? extra = null) => new
        {
            title = "Chạy bộ",
            durationMinutes = 45,
            days = new[] { "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" },
            windows = new[] { new { start = "05:00", end = "06:00" }, new { start = "18:00", end = "19:00" } },
        };

        private void AddGym()
        {
            var gym = new Habit { Name = "Gym" };
            _habits.Add(gym);
            _events.Add(new Event
            {
                Title = "Gym",
                HabitId = gym.Id.ToString(),
                StartTime = new DateTime(2026, 9, 1, 10, 30, 0, DateTimeKind.Utc), // 17:30 local
                EndTime = new DateTime(2026, 9, 1, 11, 30, 0, DateTimeKind.Utc),
                RecurrenceRule = "RRULE:FREQ=WEEKLY;BYDAY=TU,TH,SA",
            });
        }

        [Fact]
        public async Task ShouldRecordTheFreeMorningFirst_AndTheClashingEveningAsTheAlternative()
        {
            AddGym();

            var result = await Tool.ExecuteAsync(Context, Args(DailyRun()), CancellationToken.None);

            result.IsError.Should().BeFalse(result.Json);
            _repository.Proposals.Should().HaveCount(2);
            var morning = ScheduleProposal.FromJson(_repository.Proposals[0].PayloadJson);
            morning.StartLocal.Should().Be("05:00");
            morning.EndLocal.Should().Be("05:45");
            morning.Conflicts.Should().BeEmpty();
            morning.RecurrenceRule.Should().Be("RRULE:FREQ=DAILY");
            morning.FirstDate.Should().Be("2026-09-29", "tomorrow by default");
            morning.HabitId.Should().BeNull("a new habit, named after the title, is created on apply");

            var evening = ScheduleProposal.FromJson(_repository.Proposals[1].PayloadJson);
            evening.StartLocal.Should().Be("18:00");
            evening.Conflicts.Should().HaveCount(6).And.OnlyContain(c => c.Title == "Gym");
        }

        [Fact]
        public async Task ShouldFileEachProposalUnderItsConversationAndCall_AsPending_AndWriteNoEvent()
        {
            await Tool.ExecuteAsync(Context, Args(DailyRun()), CancellationToken.None);

            _repository.Proposals.Should().OnlyContain(p =>
                p.UserId == UserId && p.ConversationId == ConversationId && p.ToolCallId == "call-1"
                && p.Status == AssistantProposalStatus.Pending);
            _sender.Verify(s => s.Send(It.IsAny<IRequest<Guid?>>(), It.IsAny<CancellationToken>()), Times.Never,
                "proposing creates nothing; only applying does");
        }

        [Fact]
        public async Task ShouldTellTheModelNothingWasAdded_AndNameSimilarHabits()
        {
            _habits.Add(new Habit { Name = "Chạy bộ buổi sáng", TargetDays = new List<int> { 1, 3, 5 } });

            var result = JsonDocument.Parse((await Tool.ExecuteAsync(Context, Args(DailyRun()), CancellationToken.None)).Json).RootElement;

            result.GetProperty("note").GetString().Should().Contain("Nothing is added yet");
            result.GetProperty("similarHabits")[0].GetProperty("name").GetString().Should().Be("Chạy bộ buổi sáng");
            result.GetProperty("proposals")[0].GetProperty("proposalId").GetGuid().Should().Be(_repository.Proposals[0].Id);
        }

        [Fact]
        public async Task ShouldScheduleOnAnExistingHabit_WithoutCountingItsOwnSessionsAsClashes()
        {
            var run = new Habit { Name = "Chạy bộ buổi sáng", CategoryId = Guid.NewGuid() };
            _habits.Add(run);
            _events.Add(new Event
            {
                Title = run.Name,
                HabitId = run.Id.ToString(),
                StartTime = new DateTime(2026, 9, 27, 22, 0, 0, DateTimeKind.Utc), // 05:00 local
                EndTime = new DateTime(2026, 9, 27, 22, 40, 0, DateTimeKind.Utc),
                RecurrenceRule = "RRULE:FREQ=DAILY",
            });

            await Tool.ExecuteAsync(Context, Args(new
            {
                title = "Chạy bộ",
                durationMinutes = 45,
                days = new[] { "Mon", "Wed", "Fri" },
                windows = new[] { new { start = "05:00", end = "06:00" } },
                habitId = run.Id,
            }), CancellationToken.None);

            var plan = ScheduleProposal.FromJson(_repository.Proposals.Single().PayloadJson);
            plan.HabitId.Should().Be(run.Id);
            plan.Title.Should().Be("Chạy bộ buổi sáng");
            plan.CategoryId.Should().Be(run.CategoryId);
            plan.StartLocal.Should().Be("05:00");
            plan.Conflicts.Should().BeEmpty();
            plan.RecurrenceRule.Should().Be("RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR");
            plan.FirstDate.Should().Be("2026-09-30", "the first Wednesday from tomorrow");
        }

        [Theory]
        [InlineData("""{"durationMinutes":45,"days":["Mon"],"windows":[{"start":"05:00","end":"06:00"}]}""", "'title' is required")]
        [InlineData("""{"title":"x","durationMinutes":1,"days":["Mon"],"windows":[{"start":"05:00","end":"06:00"}]}""", "'durationMinutes'")]
        [InlineData("""{"title":"x","durationMinutes":45,"days":["Monday"],"windows":[{"start":"05:00","end":"06:00"}]}""", "weekday names")]
        [InlineData("""{"title":"x","durationMinutes":45,"days":["Mon"],"windows":[{"start":"06:00","end":"05:00"}]}""", "end after start")]
        [InlineData("""{"title":"x","durationMinutes":45,"days":["Mon"],"windows":[{"start":"05:00","end":"05:30"}]}""", "No window can hold")]
        [InlineData("""{"title":"x","durationMinutes":45,"days":["Mon"],"windows":[{"start":"05:00","end":"06:00"}],"startDate":"2026-09-01"}""", "today or later")]
        [InlineData("""{"title":"x","durationMinutes":45,"days":["Mon"],"windows":[{"start":"05:00","end":"06:00"}],"reminders":[10]}""", "0, 5, 15, 30 or 60")]
        [InlineData("""{"title":"x","durationMinutes":45,"days":["Mon"],"windows":[{"start":"05:00","end":"06:00"}],"habitId":"00000000-0000-0000-0000-000000000001"}""", "no habit with that habitId")]
        public async Task ShouldExplainBadArguments_AndProposeNothing(string json, string expected)
        {
            var result = await Tool.ExecuteAsync(Context, JsonDocument.Parse(json).RootElement, CancellationToken.None);

            result.IsError.Should().BeTrue();
            result.Json.Should().Contain(expected);
            _repository.Proposals.Should().BeEmpty();
        }
    }
}
