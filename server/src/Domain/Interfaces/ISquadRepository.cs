using HabitTracker.Domain.Entities;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace HabitTracker.Domain.Interfaces
{
    public interface ISquadRepository
    {
        Task<Squad?> GetSquadByUserIdAsync(string userId);
        Task<Squad?> GetSquadByIdAsync(Guid squadId);
        Task<List<SquadMember>> GetSquadMembersAsync(Guid squadId);
        Task<bool> IsUserInAnySquadAsync(string userId);
        Task<Squad> CreateSquadAsync(Squad squad, string adminUserId);
        Task AddMemberAsync(Guid squadId, string userId, string role);
        Task<int> GetMemberCountAsync(Guid squadId);
        Task UpdateAsync(Squad squad);
    }
}
