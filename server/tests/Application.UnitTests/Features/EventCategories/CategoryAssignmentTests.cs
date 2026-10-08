using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Application.Common;
using HabitTracker.Application.Features.EventCategories.Commands;
using HabitTracker.Application.Features.Events.Commands;
using HabitTracker.Application.Features.Habits.Commands;
using HabitTracker.Application.Tests.TestDoubles;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using Moq;
using Xunit;

namespace HabitTracker.Application.UnitTests.Features.EventCategories
{
    /// <summary>
    /// The second door to a category: pointing an event or a habit at it, and moving rows onto
    /// it when another category is deleted.
    /// </summary>
    /// <remarks>
    /// Review round 1 of this branch. Closing the four category endpoints left event and habit
    /// writes storing any <c>CategoryId</c>, and plan-vs-actual reading the category's name back
    /// through the event — so a category id was enough to learn a name, and a removed squad
    /// member kept seeing the squad's categories. And the replacement check tested readability
    /// only, so a leader could move every member's rows onto the leader's personal category.
    /// </remarks>
    public class CategoryAssignmentTests
    {
        private const string Me = "me";
        private const string SomeoneElse = "someone-else";
        private const string Leader = "leader";
        private const string Member = "member";

        private static readonly Guid SquadId = Guid.NewGuid();
        private static readonly Guid OtherSquadId = Guid.NewGuid();

        private readonly Mock<IEventCategoryRepository> _categories = new();
        private readonly Mock<ISquadRepository> _squads = new();

        private readonly EventCategory _mine;
        private readonly EventCategory _theirs;
        private readonly EventCategory _squadCategory;

        public CategoryAssignmentTests()
        {
            _mine = Stored(new EventCategory { Id = Guid.NewGuid(), Name = "Mine", UserId = Me });
            _theirs = Stored(new EventCategory { Id = Guid.NewGuid(), Name = "Theirs", UserId = SomeoneElse });
            _squadCategory = Stored(new EventCategory { Id = Guid.NewGuid(), Name = "Squad", SquadId = SquadId });

            Membership(SquadId, Leader, SquadMember.LeaderRole);
            Membership(OtherSquadId, Leader, SquadMember.LeaderRole);
            Membership(SquadId, Member, SquadMember.MemberRole);
        }

        private EventCategory Stored(EventCategory category)
        {
            _categories.Setup(r => r.GetByIdAsync(category.Id)).ReturnsAsync(category);
            return category;
        }

        private void Membership(Guid squadId, string userId, string role) =>
            _squads.Setup(r => r.GetMembershipAsync(squadId, userId)).ReturnsAsync(
                new SquadMember { SquadId = squadId, UserId = userId, Role = role, IsApproved = true });

        private Task<bool> CanAssign(Guid? category, Guid? current, string user) =>
            EventCategoryAccess.CanAssignAsync(category, current, user, _categories.Object, _squads.Object);

        // ---- the rule --------------------------------------------------------------------

        [Fact]
        public async Task OwnCategory_AndNoCategory_AreAlwaysAssignable()
        {
            (await CanAssign(_mine.Id, null, Me)).Should().BeTrue();
            (await CanAssign(null, _mine.Id, Me)).Should().BeTrue("clearing a category is never a grant");
        }

        [Fact]
        public async Task SomeoneElsesCategory_IsNot()
        {
            (await CanAssign(_theirs.Id, null, Me)).Should().BeFalse();
        }

        [Fact]
        public async Task ACategoryThatDoesNotExist_IsNot()
        {
            (await CanAssign(Guid.NewGuid(), null, Me)).Should().BeFalse();
        }

        [Fact]
        public async Task ASquadCategory_NeedsMembership()
        {
            (await CanAssign(_squadCategory.Id, null, Member)).Should().BeTrue();
            (await CanAssign(_squadCategory.Id, null, Me)).Should().BeFalse();
        }

        [Fact]
        public async Task KeepingTheCategoryARowAlreadyHas_IsAllowed_EvenWhenItIsNoLongerVisible()
        {
            // A member who has left the squad still owns their old events. Refusing every edit that
            // re-sends the same category would lock them out of their own data; not seeing the
            // category any more is enforced where it is read.
            (await CanAssign(_squadCategory.Id, _squadCategory.Id, Me)).Should().BeTrue();
        }

        // ---- the replacement ---------------------------------------------------------------

        [Fact]
        public async Task ALeaderCannotMoveASquadsRowsOntoTheirOwnPersonalCategory()
        {
            var leadersOwn = Stored(new EventCategory { Id = Guid.NewGuid(), UserId = Leader });

            (await EventCategoryAccess.CanReplaceAsync(_squadCategory, leadersOwn, Leader, _squads.Object))
                .Should().BeFalse("those rows belong to every member, not to the leader");
        }

        [Fact]
        public async Task ALeaderCannotMoveOneSquadsRowsIntoAnotherSquad_EvenOneTheyAlsoLead()
        {
            var otherSquads = Stored(new EventCategory { Id = Guid.NewGuid(), SquadId = OtherSquadId });

            (await EventCategoryAccess.CanReplaceAsync(_squadCategory, otherSquads, Leader, _squads.Object))
                .Should().BeFalse();
        }

        [Fact]
        public async Task SameScopeReplacementsAreAllowed()
        {
            var sameSquad = Stored(new EventCategory { Id = Guid.NewGuid(), SquadId = SquadId });
            var alsoMine = Stored(new EventCategory { Id = Guid.NewGuid(), UserId = Me });

            (await EventCategoryAccess.CanReplaceAsync(_squadCategory, sameSquad, Leader, _squads.Object))
                .Should().BeTrue();
            (await EventCategoryAccess.CanReplaceAsync(_mine, alsoMine, Me, _squads.Object))
                .Should().BeTrue();
        }

        [Fact]
        public async Task DeleteRefusesTheLeadersPersonalReplacement_AndMovesNothing()
        {
            // The handler, not just the rule: nothing is reassigned or deleted.
            var leadersOwn = Stored(new EventCategory { Id = Guid.NewGuid(), UserId = Leader });

            var ok = await new DeleteEventCategoryCommandHandler(_categories.Object, _squads.Object)
                .Handle(new DeleteEventCategoryCommand
                {
                    Id = _squadCategory.Id,
                    UserId = Leader,
                    ReplacementCategoryId = leadersOwn.Id
                }, CancellationToken.None);

            ok.Should().BeFalse();
            _categories.Verify(r => r.ReassignCategoryAsync(It.IsAny<Guid>(), It.IsAny<Guid>()), Times.Never);
            _categories.Verify(r => r.DeleteAsync(It.IsAny<Guid>()), Times.Never);
        }

        // ---- the handlers are wired to it -------------------------------------------------

        private CreateEventCommandHandler CreateEventHandler(Mock<IEventRepository> events) => new(
            events.Object,
            new Mock<IHabitTaskRepository>().Object,
            new Mock<IEventTaskRepository>().Object,
            new Mock<IUserRepository>().Object,
            new Mock<IGoogleCalendarOutboxRepository>().Object,
            _categories.Object,
            _squads.Object);

        [Fact]
        public async Task CreatingAnEventOnSomeoneElsesCategory_IsRefused_AndNothingIsSaved()
        {
            var events = new Mock<IEventRepository>();

            var id = await CreateEventHandler(events).Handle(new CreateEventCommand
            {
                Title = "Attach",
                StartTime = DateTime.UtcNow,
                EndTime = DateTime.UtcNow.AddHours(1),
                UserId = Me,
                CategoryId = _theirs.Id
            }, CancellationToken.None);

            id.Should().BeNull();
            events.Verify(r => r.AddAsync(It.IsAny<Event>()), Times.Never);
        }

        [Fact]
        public async Task CreatingAnEventOnOwnCategory_Works()
        {
            var events = new Mock<IEventRepository>();

            var id = await CreateEventHandler(events).Handle(new CreateEventCommand
            {
                Title = "Mine",
                StartTime = DateTime.UtcNow,
                EndTime = DateTime.UtcNow.AddHours(1),
                UserId = Me,
                CategoryId = _mine.Id
            }, CancellationToken.None);

            id.Should().NotBeNull();
            events.Verify(r => r.AddAsync(It.Is<Event>(e => e.CategoryId == _mine.Id)), Times.Once);
        }

        [Fact]
        public async Task MovingAnEventOntoSomeoneElsesCategory_IsRefused()
        {
            var ev = new Event
            {
                Id = Guid.NewGuid(),
                UserId = Me,
                CategoryId = _mine.Id,
                StartTime = DateTime.UtcNow,
                EndTime = DateTime.UtcNow.AddHours(1),
                HabitId = string.Empty
            };
            var events = new Mock<IEventRepository>();
            events.Setup(r => r.GetByIdAsync(ev.Id)).ReturnsAsync(ev);

            var handler = new UpdateEventCommandHandler(
                events.Object,
                new Mock<IUserRepository>().Object,
                new Mock<IGoogleCalendarOutboxRepository>().Object,
                new OccurrenceMaterializer(events.Object, new Mock<IEventTaskRepository>().Object, new PassThroughUnitOfWork()),
                _categories.Object,
                _squads.Object);

            var ok = await handler.Handle(new UpdateEventCommand
            {
                EventId = ev.Id,
                Title = "Moved",
                StartTime = ev.StartTime,
                EndTime = ev.EndTime,
                UserId = Me,
                CategoryId = _theirs.Id
            }, CancellationToken.None);

            ok.Should().BeFalse();
            ev.CategoryId.Should().Be(_mine.Id, "nothing was written");
            events.Verify(r => r.UpdateAsync(It.IsAny<Event>()), Times.Never);
        }

        [Fact]
        public async Task HabitsAreHeldToTheSameRule()
        {
            var habits = new Mock<IHabitRepository>();
            var habit = new Habit { Id = Guid.NewGuid(), UserId = Me, CategoryId = _mine.Id, TargetDays = new List<int>() };
            habits.Setup(r => r.GetByIdAsync(habit.Id)).ReturnsAsync(habit);

            var created = await new CreateHabitCommandHandler(habits.Object, _categories.Object, _squads.Object)
                .Handle(new CreateHabitCommand { Name = "H", UserId = Me, CategoryId = _theirs.Id },
                    CancellationToken.None);

            var updated = await new UpdateHabitCommandHandler(habits.Object, _categories.Object, _squads.Object)
                .Handle(new UpdateHabitCommand { Id = habit.Id, Name = "H", UserId = Me, CategoryId = _theirs.Id },
                    CancellationToken.None);

            created.Should().BeNull();
            updated.Should().BeFalse();
            habit.CategoryId.Should().Be(_mine.Id);
            habits.Verify(r => r.AddAsync(It.IsAny<Habit>()), Times.Never);
        }
    }
}
