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
