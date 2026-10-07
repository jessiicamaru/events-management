using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using HabitTracker.Application.Features.EventCategories.Commands;
using HabitTracker.Application.Features.EventCategories.Queries;
using HabitTracker.Application.Features.Events.Commands;
using HabitTracker.Application.Features.Habits.Commands;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using HabitTracker.Web.Endpoints.V1;
using HabitTracker.Web.Hubs;
using MediatR;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.SignalR;
using Moq;
using Xunit;

namespace HabitTracker.Application.Tests.Web
{
    /// <summary>
    /// The outermost layer of the squad and category authorization: the SignalR hub, and the
    /// endpoints that turn a handler's "refused" into a status code.
    /// </summary>
    /// <remarks>
    /// Review of <c>fix/squad-category-authorization</c>, round 3. The hub checked no membership at
    /// all, so any signed-in user holding a squad id could read its live chat and post into it. And
    /// removing the null → 403 mapping from the event and habit create endpoints survived the whole
    /// suite — a handler could refuse and the endpoint would still answer 201.
    /// </remarks>
    public class SquadAuthorizationSurfaceTests
    {
        private const string Member = "member";
        private const string Outsider = "outsider";
        private const string Pending = "pending";

        private static readonly Guid SquadId = Guid.NewGuid();

        private static ClaimsPrincipal SignedIn(string userId) =>
            new(new ClaimsIdentity(new[] { new Claim(ClaimTypes.NameIdentifier, userId) }, "test"));

        // ---- the hub ---------------------------------------------------------------------

        private readonly Mock<ISquadRepository> _squads = new();
        private readonly Mock<IGroupManager> _groups = new();
        private readonly Mock<IClientProxy> _group = new();

        public SquadAuthorizationSurfaceTests()
        {
            var members = new List<SquadMember>
            {
                new() { SquadId = SquadId, UserId = Member, IsApproved = true, Nickname = "Mem" },
                new() { SquadId = SquadId, UserId = Pending, IsApproved = false, Nickname = "Pen" },
            };

            _squads.Setup(r => r.GetSquadMembersAsync(SquadId)).ReturnsAsync(members);
            _squads.Setup(r => r.GetMembershipAsync(SquadId, It.IsAny<string>()))
                .ReturnsAsync((Guid _, string userId) => members.FirstOrDefault(m => m.UserId == userId));
        }

        private SocialHub HubFor(string userId)
        {
            var context = new Mock<HubCallerContext>();
            context.Setup(c => c.User).Returns(SignedIn(userId));
            context.Setup(c => c.ConnectionId).Returns("connection-1");

            var clients = new Mock<IHubCallerClients>();
            clients.Setup(c => c.Group(It.IsAny<string>())).Returns(_group.Object);

            return new SocialHub(_squads.Object)
            {
                Context = context.Object,
                Groups = _groups.Object,
                Clients = clients.Object
            };
        }

        private void NothingWasBroadcastOrSaved()
        {
            _squads.Verify(r => r.SaveChatMessageAsync(It.IsAny<SquadChatMessage>()), Times.Never);
            _group.Verify(g => g.SendCoreAsync(It.IsAny<string>(), It.IsAny<object?[]>(), It.IsAny<CancellationToken>()),
                Times.Never);
        }

        [Fact]
        public async Task AnOutsiderCannotJoinASquadsLiveGroup()
        {
            var act = () => HubFor(Outsider).JoinSquadGroup(SquadId.ToString());

            await act.Should().ThrowAsync<HubException>();
            _groups.Verify(g => g.AddToGroupAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()),
                Times.Never);
        }

        [Fact]
        public async Task APendingRequestCannotJoinEither()
        {
            var act = () => HubFor(Pending).JoinSquadGroup(SquadId.ToString());

            await act.Should().ThrowAsync<HubException>();
        }

        [Fact]
        public async Task AMemberJoinsTheCanonicalGroup()
        {
            // Upper-case in, canonical name out: the same squad cannot be two groups.
            await HubFor(Member).JoinSquadGroup(SquadId.ToString().ToUpperInvariant());

            _groups.Verify(g => g.AddToGroupAsync("connection-1", SocialHub.GroupName(SquadId), It.IsAny<CancellationToken>()),
                Times.Once);
        }

        [Fact]
        public async Task AnOutsiderCannotPostIntoASquad()
        {
            var act = () => HubFor(Outsider).SendMessage(SquadId.ToString(), "planted");

            await act.Should().ThrowAsync<HubException>();
            NothingWasBroadcastOrSaved();
        }

        [Fact]
        public async Task AMemberCanPost()
        {
            await HubFor(Member).SendMessage(SquadId.ToString(), "hello");

            _squads.Verify(r => r.SaveChatMessageAsync(It.Is<SquadChatMessage>(m => m.Message == "hello")), Times.Once);
            _group.Verify(g => g.SendCoreAsync("ReceiveMessage", It.IsAny<object?[]>(), It.IsAny<CancellationToken>()),
                Times.Once);
        }

        [Fact]
        public async Task PokesAndReactionsNeedAMemberOnBothEnds()
        {
            await HubFor(Outsider).Invoking(h => h.SendPoke(SquadId.ToString(), Member))
                .Should().ThrowAsync<HubException>("the sender is not a member");
            await HubFor(Member).Invoking(h => h.SendPoke(SquadId.ToString(), Outsider))
                .Should().ThrowAsync<HubException>("the target is not a member");
            await HubFor(Member).Invoking(h => h.SendReaction(SquadId.ToString(), Pending, "👍"))
                .Should().ThrowAsync<HubException>("a pending request is not a member");

            NothingWasBroadcastOrSaved();
        }

        [Fact]
        public async Task AnUnparseableSquadIdIsRefused_LikeAnyOtherNonMember()
        {
            await HubFor(Member).Invoking(h => h.SendMessage("not-a-guid", "x"))
                .Should().ThrowAsync<HubException>();
            NothingWasBroadcastOrSaved();
        }

        // ---- the endpoints: a refusal must become a status, not a 201 ----------------------

        [Fact]
        public async Task CreateEvent_AnswersForbidden_WhenTheHandlerRefuses()
        {
            var sender = new Mock<ISender>();
            sender.Setup(s => s.Send(It.IsAny<CreateEventCommand>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync((Guid?)null);

            var result = await new Events().CreateEvent(sender.Object, new CreateEventCommand(), SignedIn(Member));

            result.Result.Should().BeOfType<ForbidHttpResult>();
        }

        [Fact]
        public async Task CreateHabit_AnswersForbidden_WhenTheHandlerRefuses()
        {
            var sender = new Mock<ISender>();
            sender.Setup(s => s.Send(It.IsAny<CreateHabitCommand>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync((Guid?)null);

            var result = await new Habits().CreateHabit(sender.Object, new CreateHabitCommand(), SignedIn(Member));

            result.Result.Should().BeOfType<ForbidHttpResult>();
        }

        [Fact]
        public async Task CategoryListAndCreate_AnswerForbidden_WhenTheHandlerRefuses()
        {
            var sender = new Mock<ISender>();
            sender.Setup(s => s.Send(It.IsAny<GetEventCategoriesQuery>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync((IEnumerable<EventCategory>?)null);
            sender.Setup(s => s.Send(It.IsAny<CreateEventCategoryCommand>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync((Guid?)null);

            var endpoint = new EventCategoriesEndpoint();
            var list = await endpoint.GetCategories(sender.Object, SignedIn(Outsider), SquadId);
            var create = await endpoint.CreateCategory(sender.Object,
                new CreateEventCategoryCommand { SquadId = SquadId }, SignedIn(Outsider));

            list.Result.Should().BeOfType<ForbidHttpResult>();
            create.Result.Should().BeOfType<ForbidHttpResult>();
        }

        [Fact]
        public async Task CreateEvent_StillAnswersCreated_WhenTheHandlerAccepts()
        {
            var id = Guid.NewGuid();
            var sender = new Mock<ISender>();
            sender.Setup(s => s.Send(It.IsAny<CreateEventCommand>(), It.IsAny<CancellationToken>()))
                .ReturnsAsync(id);

            var result = await new Events().CreateEvent(sender.Object, new CreateEventCommand(), SignedIn(Member));

            result.Result.Should().BeOfType<Created<Guid>>().Which.Value.Should().Be(id);
        }
    }
}
