using HabitTracker.Domain.Entities;

namespace HabitTracker.Application.Common
{
    /// <summary>
    /// What a squad membership entitles its holder to do.
    /// </summary>
    /// <remarks>
    /// One place, because the rule was written inline at every call site and was wrong — or
    /// missing — at several. `GET /api/v1/event-categories?squadId=<any>` returned any squad's
    /// categories to any signed-in caller, and the update and delete handlers tested
    /// <c>category.UserId != request.UserId &amp;&amp; category.SquadId != request.SquadId</c>,
    /// which is false whenever both squad ids are null — so a stranger could rename and delete
    /// another user's *personal* categories too. Both measured against a running server.
    ///
    /// A membership row exists from the moment someone asks to join, so
    /// <see cref="SquadMember.IsApproved"/> has to be checked as well as the role: a pending
    /// request is not membership.
    /// </remarks>
    public static class SquadAccess
    {
        /// <summary>Can see the squad's shared data.</summary>
        public static bool CanRead(SquadMember? membership) =>
            membership != null && membership.IsApproved;

        /// <summary>Can add to the squad's shared data.</summary>
        /// <remarks>
        /// Any approved member. Squads here are small groups sharing a calendar, and a member
        /// who cannot add a category cannot categorise the events they are expected to run.
        /// </remarks>
        public static bool CanContribute(SquadMember? membership) => CanRead(membership);

        /// <summary>
        /// Can change or remove the squad's shared data — the leader only.
        /// </summary>
        /// <remarks>
        /// Stricter than <see cref="CanContribute"/> on purpose: deleting a shared category
        /// reassigns or unsets it on every member's events, which is not something one member
        /// should be able to do to everybody else.
        /// </remarks>
        public static bool CanManage(SquadMember? membership) =>
            CanRead(membership) && membership!.Role == SquadMember.LeaderRole;
    }
}
