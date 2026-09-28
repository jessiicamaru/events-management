using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using HabitTracker.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace HabitTracker.Infrastructure.Repositories
{
    public class SquadRepository : ISquadRepository
    {
        private readonly ApplicationDbContext _context;

        public SquadRepository(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<List<Squad>> GetSquadsByUserIdAsync(string userId)
        {
            return await _context.SquadMembers
                .Include(sm => sm.Squad)
                .Where(sm => sm.UserId == userId && sm.IsApproved)
                .Select(sm => sm.Squad!)
                .ToListAsync();
        }

        public async Task<Squad?> GetSquadByIdAsync(Guid squadId)
        {
            return await _context.Squads.FindAsync(squadId);
        }

        public async Task<List<SquadMember>> GetSquadMembersAsync(Guid squadId)
        {
            return await _context.SquadMembers
                .Include(sm => sm.User)
                .Where(sm => sm.SquadId == squadId)
                .ToListAsync();
        }

        public async Task<SquadMember?> GetMembershipAsync(Guid squadId, string userId)
        {
            return await _context.SquadMembers
                .Include(sm => sm.Squad)
                .Include(sm => sm.User)
                .FirstOrDefaultAsync(sm => sm.SquadId == squadId && sm.UserId == userId);
        }

        public async Task<List<SquadMember>> GetPendingMembersAsync(Guid squadId)
        {
            return await _context.SquadMembers
                .Include(sm => sm.User)
                .Where(sm => sm.SquadId == squadId && !sm.IsApproved)
                .ToListAsync();
        }

        public async Task<Squad> CreateSquadAsync(Squad squad, string adminUserId)
        {
            _context.Squads.Add(squad);
            _context.SquadMembers.Add(new SquadMember
            {
                Squad = squad,
                UserId = adminUserId,
                Role = "Leader",
                IsApproved = true
            });
            await _context.SaveChangesAsync();
            return squad;
        }

        public async Task AddMemberAsync(Guid squadId, string userId, string role, bool isApproved)
        {
            _context.SquadMembers.Add(new SquadMember
            {
                SquadId = squadId,
                UserId = userId,
                Role = role,
                IsApproved = isApproved
            });
            await _context.SaveChangesAsync();
        }

        public async Task<int> GetMemberCountAsync(Guid squadId)
        {
            return await _context.SquadMembers.CountAsync(sm => sm.SquadId == squadId && sm.IsApproved);
        }

        public async Task UpdateAsync(Squad squad)
        {
            _context.Squads.Update(squad);
            await _context.SaveChangesAsync();
        }

        public async Task UpdateMemberAsync(SquadMember member)
        {
            _context.SquadMembers.Update(member);
            await _context.SaveChangesAsync();
        }

        public async Task RemoveMemberAsync(Guid squadId, string userId)
        {
            var member = await _context.SquadMembers.FirstOrDefaultAsync(sm => sm.SquadId == squadId && sm.UserId == userId);
            if (member != null)
            {
                _context.SquadMembers.Remove(member);
                await _context.SaveChangesAsync();
            }
        }

        public async Task DeleteSquadAsync(Guid squadId)
        {
            var squad = await _context.Squads.FindAsync(squadId);
            if (squad != null)
            {
                _context.Squads.Remove(squad);
                await _context.SaveChangesAsync();
            }
        }

        public async Task<List<SquadChatMessage>> GetChatMessageHistoryAsync(Guid squadId, int limit = 50)
        {
            return await _context.SquadChatMessages
                .Include(scm => scm.Sender)
                .Where(scm => scm.SquadId == squadId)
                .OrderByDescending(scm => scm.SentAt)
                .Take(limit)
                .OrderBy(scm => scm.SentAt)
                .ToListAsync();
        }

        public async Task SaveChatMessageAsync(SquadChatMessage message)
        {
            _context.SquadChatMessages.Add(message);
            await _context.SaveChangesAsync();
        }
    }
}
