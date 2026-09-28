using HabitTracker.Domain.Entities;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace HabitTracker.Domain.Interfaces
{
    public interface ISquadRepository
    {
        Task<List<Squad>> GetSquadsByUserIdAsync(string userId);
        Task<Squad?> GetSquadByIdAsync(Guid squadId);
        Task<List<SquadMember>> GetSquadMembersAsync(Guid squadId);
        Task<SquadMember?> GetMembershipAsync(Guid squadId, string userId);
        Task<List<SquadMember>> GetPendingMembersAsync(Guid squadId);
        Task<Squad> CreateSquadAsync(Squad squad, string adminUserId);
        Task AddMemberAsync(Guid squadId, string userId, string role, bool isApproved);
        Task<int> GetMemberCountAsync(Guid squadId);
        Task UpdateAsync(Squad squad);
        Task UpdateMemberAsync(SquadMember member);
        Task RemoveMemberAsync(Guid squadId, string userId);
        Task<List<SquadChatMessage>> GetChatMessageHistoryAsync(Guid squadId, int limit = 50);
        Task SaveChatMessageAsync(SquadChatMessage message);
    }
}
