using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Application.Features.EventCategories.Commands;
using HabitTracker.Application.Features.EventCategories.Queries;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using Moq;
using Xunit;

namespace HabitTracker.Application.UnitTests.Features.EventCategories
{
    /// <summary>
    /// Who may read, create, change and delete a category.
    /// </summary>
    /// <remarks>
    /// Every case here was reachable against a running server before this change: a non-member
    /// could list and rename a squad's categories and plant new ones in it, and — because the
    /// old check was an `&amp;&amp;` that both sides satisfied when the squad ids were null — any
    /// signed-in caller could rename and delete another user's *personal* categories.
    /// </remarks>
    public class EventCategoryAuthorizationTests
    {
        private const string Owner = "owner";
        private const string Stranger = "stranger";
        private const string Leader = "leader";
        private const string Member = "member";

        private static readonly Guid SquadId = Guid.NewGuid();

        private readonly Mock<IEventCategoryRepository> _categories = new();
        private readonly Mock<ISquadRepository> _squads = new();
        private readonly List<EventCategory> _added = new();
        private readonly List<(Guid From, Guid To)> _reassigned = new();

        public EventCategoryAuthorizationTests()
        {
            _categories.Setup(r => r.AddAsync(It.IsAny<EventCategory>()))
                .Callback<EventCategory>(_added.Add)
                .ReturnsAsync((EventCategory c) => c);
            _categories.Setup(r => r.ReassignCategoryAsync(It.IsAny<Guid>(), It.IsAny<Guid>()))
                .Callback<Guid, Guid>((from, to) => _reassigned.Add((from, to)))
                .Returns(Task.CompletedTask);
            _categories.Setup(r => r.GetBySquadIdAsync(SquadId))
                .ReturnsAsync(new List<EventCategory> { SquadCategory() });
            _categories.Setup(r => r.GetByUserIdAsync(Owner))
                .ReturnsAsync(new List<EventCategory> { PersonalCategory() });

            Membership(Leader, SquadMember.LeaderRole);
            Membership(Member, SquadMember.MemberRole);
        }

        private void Membership(string userId, string role, bool approved = true) =>
            _squads.Setup(r => r.GetMembershipAsync(SquadId, userId))
                .ReturnsAsync(new SquadMember
                {
                    SquadId = SquadId,
                    UserId = userId,
                    Role = role,
                    IsApproved = approved
                });

        private static EventCategory PersonalCategory() => new()
        {
            Id = Guid.NewGuid(),
            Name = "Victim personal",
            UserId = Owner,
            SquadId = null
        };

        private static EventCategory SquadCategory() => new()
        {
            Id = Guid.NewGuid(),
            Name = "Squad only",
            UserId = null,
            SquadId = SquadId
        };

        private void Stored(EventCategory category) =>
            _categories.Setup(r => r.GetByIdAsync(category.Id)).ReturnsAsync(category);

        private Task<IEnumerable<EventCategory>?> Read(string? userId, Guid? squadId) =>
            new GetEventCategoriesQueryHandler(_categories.Object, _squads.Object)
                .Handle(new GetEventCategoriesQuery { UserId = userId, SquadId = squadId },
                    CancellationToken.None);

        private Task<Guid?> Create(string caller, Guid? squadId) =>
            new CreateEventCategoryCommandHandler(_categories.Object, _squads.Object)
                .Handle(new CreateEventCategoryCommand
                {
                    Name = "New",
                    CallerUserId = caller,
                    UserId = squadId == null ? caller : null,
                    SquadId = squadId
                }, CancellationToken.None);

        private Task<bool> Rename(Guid id, string? caller) =>
            new UpdateEventCategoryCommandHandler(_categories.Object, _squads.Object)
                .Handle(new UpdateEventCategoryCommand
                {
                    Id = id,
                    Name = "Renamed",
                    ColorPreset = "Red",
                    UserId = caller
                }, CancellationToken.None);

        private Task<bool> Delete(Guid id, string? caller, Guid? replacement = null) =>
            new DeleteEventCategoryCommandHandler(_categories.Object, _squads.Object)
                .Handle(new DeleteEventCategoryCommand
                {
                    Id = id,
                    UserId = caller,
                    ReplacementCategoryId = replacement
                }, CancellationToken.None);

        // ---- reading -------------------------------------------------------------------

        [Fact]
        public async Task ReadingASquad_NeedsApprovedMembership()
        {
            (await Read(Member, SquadId)).Should().NotBeNull();
            (await Read(Leader, SquadId)).Should().NotBeNull();
            (await Read(Stranger, SquadId)).Should().BeNull("a non-member may not see it");
        }

        [Fact]
        public async Task APendingJoinRequestIsNotMembership()
        {
            // A membership row exists from the moment someone asks to join.
            Membership("pending", SquadMember.MemberRole, approved: false);

            (await Read("pending", SquadId)).Should().BeNull();
        }

        [Fact]
        public async Task ReadingWithoutASquad_ReturnsTheCallersOwn()
        {
            var own = await Read(Owner, null);

            own.Should().NotBeNull();
            own!.Single().UserId.Should().Be(Owner);
            _categories.Verify(r => r.GetByUserIdAsync(Owner), Times.Once);
        }

        [Fact]
        public async Task ReadingWithNoUser_IsRefused() =>
            (await Read(null, SquadId)).Should().BeNull();

        // ---- creating ------------------------------------------------------------------

        [Fact]
        public async Task CreatingInASquad_NeedsMembership()
        {
            (await Create(Member, SquadId)).Should().NotBeNull("a member may add one");
            (await Create(Stranger, SquadId)).Should().BeNull("a non-member may not");

            _added.Should().HaveCount(1);
            _added.Single().SquadId.Should().Be(SquadId);
            _added.Single().UserId.Should().BeNull("a squad category belongs to the squad");
        }

        [Fact]
        public async Task CreatingAPersonalCategory_IsAlwaysAllowed()
        {
            (await Create(Stranger, null)).Should().NotBeNull();
            _added.Single().UserId.Should().Be(Stranger);
        }

        // ---- renaming ------------------------------------------------------------------

        [Fact]
        public async Task RenamingAPersonalCategory_OnlyItsOwner()
        {
            var category = PersonalCategory();
            Stored(category);

            (await Rename(category.Id, Stranger)).Should().BeFalse();
            category.Name.Should().Be("Victim personal", "nothing was written");

            (await Rename(category.Id, Owner)).Should().BeTrue();
            category.Name.Should().Be("Renamed");
        }

        [Fact]
        public async Task RenamingASquadCategory_OnlyTheLeader()
        {
            var category = SquadCategory();
            Stored(category);

            (await Rename(category.Id, Stranger)).Should().BeFalse();
            (await Rename(category.Id, Member)).Should().BeFalse(
                "changing shared data is the leader's to do");
            category.Name.Should().Be("Squad only");

            (await Rename(category.Id, Leader)).Should().BeTrue();
            category.Name.Should().Be("Renamed");
        }

        [Fact]
        public async Task RenamingSomethingThatDoesNotExist_IsRefused() =>
            (await Rename(Guid.NewGuid(), Owner)).Should().BeFalse();

        // ---- deleting ------------------------------------------------------------------

        [Fact]
        public async Task DeletingAPersonalCategory_OnlyItsOwner()
        {
            var category = PersonalCategory();
            Stored(category);

            (await Delete(category.Id, Stranger)).Should().BeFalse();
            _categories.Verify(r => r.DeleteAsync(category.Id), Times.Never);

            (await Delete(category.Id, Owner)).Should().BeTrue();
            _categories.Verify(r => r.DeleteAsync(category.Id), Times.Once);
        }

        [Fact]
        public async Task DeletingASquadCategory_OnlyTheLeader()
        {
            var category = SquadCategory();
            Stored(category);

            (await Delete(category.Id, Member)).Should().BeFalse();
            (await Delete(category.Id, Leader)).Should().BeTrue();
        }

        [Fact]
        public async Task AReplacementMustAlsoBeTheCallers()
        {
            // Before, a replacement the caller owned was accepted for somebody else's category,
            // which moved the victim's events onto the caller's category.
            var victims = PersonalCategory();
            var mine = new EventCategory { Id = Guid.NewGuid(), Name = "Mine", UserId = Stranger };
            Stored(victims);
            Stored(mine);

            (await Delete(victims.Id, Stranger, replacement: mine.Id)).Should().BeFalse();
            _reassigned.Should().BeEmpty();
            _categories.Verify(r => r.DeleteAsync(victims.Id), Times.Never);
        }

        [Fact]
        public async Task AReplacementTheCallerCannotSee_RefusesTheWholeDelete()
        {
            // Refusing beats the old behaviour, which deleted the category anyway and left its
            // events with no category at all.
            var mine = PersonalCategory();
            var someoneElses = new EventCategory { Id = Guid.NewGuid(), UserId = Stranger };
            Stored(mine);
            Stored(someoneElses);

            (await Delete(mine.Id, Owner, replacement: someoneElses.Id)).Should().BeFalse();
            _reassigned.Should().BeEmpty();
            _categories.Verify(r => r.DeleteAsync(mine.Id), Times.Never);
        }

        [Fact]
        public async Task AValidReplacementIsUsed_ThenTheCategoryGoes()
        {
            var mine = PersonalCategory();
            var other = new EventCategory { Id = Guid.NewGuid(), UserId = Owner };
            Stored(mine);
            Stored(other);

            (await Delete(mine.Id, Owner, replacement: other.Id)).Should().BeTrue();
            _reassigned.Should().Equal((mine.Id, other.Id));
            _categories.Verify(r => r.DeleteAsync(mine.Id), Times.Once);
        }

        [Fact]
        public async Task ALeaderMayReplaceWithAnotherCategoryOfTheSameSquad()
        {
            var going = SquadCategory();
            var staying = SquadCategory();
            Stored(going);
            Stored(staying);

            (await Delete(going.Id, Leader, replacement: staying.Id)).Should().BeTrue();
            _reassigned.Should().Equal((going.Id, staying.Id));
        }
    }
}
