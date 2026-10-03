using System.Collections.Generic;
using FluentAssertions;
using HabitTracker.Application.Common;
using Xunit;

namespace HabitTracker.Application.Tests.Common
{
    public class ReminderOptionsTests
    {
        [Fact]
        public void AllowedMinutesBefore_IsTheAgreedSet()
        {
            // The client offers exactly these; anything else is a bug or a stale client.
            ReminderOptions.AllowedMinutesBefore
                .Should()
                .BeEquivalentTo(new[] { 0, 5, 15, 30, 60 });
        }

        [Fact]
        public void Normalise_ReturnsEmpty_ForNull()
        {
            // "No reminders" is a real choice, so null must not be defaulted to something.
            ReminderOptions.Normalise(null).Should().BeEmpty();
        }

        [Fact]
        public void Normalise_ReturnsEmpty_ForAnEmptySet()
        {
            ReminderOptions.Normalise(new List<int>()).Should().BeEmpty();
        }

        [Fact]
        public void Normalise_OrdersEarliestReminderFirst()
        {
            // Stored the way it is displayed: "1 hour, 30 min, 5 min".
            ReminderOptions.Normalise(new[] { 5, 60, 30 })
                .Should()
                .Equal(60, 30, 5);
        }

        [Fact]
        public void Normalise_DropsDuplicates()
        {
            ReminderOptions.Normalise(new[] { 30, 30, 5, 5, 5 })
                .Should()
                .Equal(30, 5);
        }

        [Fact]
        public void Normalise_DropsOffsetsThatAreNotOffered()
        {
            // 10 and 45 are not in the option list; 7 is nonsense. Keep the valid ones
            // rather than rejecting the whole request - a stale client should degrade, not
            // fail.
            ReminderOptions.Normalise(new[] { 60, 45, 10, 5, 7 })
                .Should()
                .Equal(60, 5);
        }

        [Fact]
        public void Normalise_KeepsZero_WhichMeansWhenItStarts()
        {
            ReminderOptions.Normalise(new[] { 0 }).Should().Equal(0);
        }

        [Fact]
        public void Normalise_DropsNegativeOffsets()
        {
            // A reminder after the event has started is not a reminder.
            ReminderOptions.Normalise(new[] { -5, -60 }).Should().BeEmpty();
        }

        [Fact]
        public void Normalise_NeverExceedsMaxPerEvent()
        {
            var everyOption = new List<int> { 0, 5, 15, 30, 60 };

            ReminderOptions.Normalise(everyOption)
                .Should()
                .HaveCount(ReminderOptions.MaxPerEvent);
        }

        [Fact]
        public void MaxPerEvent_MatchesTheNumberOfOptions()
        {
            // One reminder per distinct offset is the natural ceiling; if the option list
            // grows, the cap should follow it rather than being a separate magic number.
            ReminderOptions.MaxPerEvent
                .Should()
                .Be(ReminderOptions.AllowedMinutesBefore.Count);
        }
    }
}
