using System;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;

namespace HabitTracker.Application.Common
{
    /// <summary>
    /// Who may touch a category: decided from the stored row, never from the request.
    /// </summary>
    /// <remarks>
    /// A category is either personal — owned by one user — or shared by a squad. Which one it
    /// is, is a property of the row; the caller only says which row. Letting the request carry
    /// the squad id was the bug: with both sides null the old equality check passed for
    /// anybody.
    /// </remarks>
    public static class EventCategoryAccess
    {
        /// <summary>Whether <paramref name="userId"/> may see <paramref name="category"/>.</summary>
        public static Task<bool> CanReadAsync(
            EventCategory category,
            string? userId,
            ISquadRepository squads) =>
            IsEntitledAsync(category, userId, squads, manage: false);

        /// <summary>
        /// Whether <paramref name="userId"/> may change or delete <paramref name="category"/> —
        /// its owner, or the squad's leader.
        /// </summary>
        public static Task<bool> CanManageAsync(
            EventCategory category,
            string? userId,
            ISquadRepository squads) =>
            IsEntitledAsync(category, userId, squads, manage: true);

        /// <summary>
        /// Whether <paramref name="userId"/> may point an event or a habit at
        /// <paramref name="categoryId"/>.
        /// </summary>
        /// <remarks>
        /// <para>
        /// Closing the category endpoints left a second door: event and habit writes stored any
        /// <c>CategoryId</c> they were given, and plan-vs-actual reads a category's name back
        /// through the event. So anyone holding a category id could attach a row to it and
        /// learn its name.
        /// </para>
        /// <para>
        /// Keeping the category a row already has is always allowed. A squad member who has
        /// since left still owns their old events, and refusing every edit that re-sends the
        /// same category would lock them out of their own data; what they may no longer do is
        /// see that category, which the read side enforces on its own.
        /// </para>
        /// </remarks>
        public static async Task<bool> CanAssignAsync(
            Guid? categoryId,
            Guid? currentCategoryId,
            string? userId,
            IEventCategoryRepository categories,
            ISquadRepository squads)
        {
            if (categoryId == null) return true;
            if (categoryId == currentCategoryId) return true;

            var category = await categories.GetByIdAsync(categoryId.Value);
            if (category == null) return false;

            return await CanReadAsync(category, userId, squads);
        }

        /// <summary>
        /// Whether <paramref name="replacement"/> may take over the rows of
        /// <paramref name="deleted"/>: it must be one the caller may use, and it must share the
        /// deleted category's scope.
        /// </summary>
        /// <remarks>
        /// Readability alone was the first version, and it let a leader move every member's
        /// events from a squad category onto the leader's own personal one — rows other people
        /// own, now under a category they cannot list. Same scope means the same squad, or the
        /// same owner's personal categories.
        /// </remarks>
        public static async Task<bool> CanReplaceAsync(
            EventCategory deleted,
            EventCategory replacement,
            string? userId,
            ISquadRepository squads)
        {
            var sameScope = deleted.SquadId.HasValue
                ? replacement.SquadId == deleted.SquadId
                : replacement.SquadId == null && replacement.UserId == deleted.UserId;

            return sameScope && await CanReadAsync(replacement, userId, squads);
        }

        private static async Task<bool> IsEntitledAsync(
            EventCategory category,
            string? userId,
            ISquadRepository squads,
            bool manage)
        {
            if (string.IsNullOrEmpty(userId)) return false;

            if (category.SquadId.HasValue)
            {
                var membership = await squads.GetMembershipAsync(category.SquadId.Value, userId);

                return manage ? SquadAccess.CanManage(membership) : SquadAccess.CanRead(membership);
            }

            return category.UserId == userId;
        }
    }
}
