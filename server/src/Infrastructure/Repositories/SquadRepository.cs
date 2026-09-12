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

        public async Task<Squad?> GetSquadByUserIdAsync(string userId)
        {
            var membership = await _context.SquadMembers
                .Include(sm => sm.Squad)
                .FirstOrDefaultAsync(sm => sm.UserId == userId);
            
            return membership?.Squad;
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

        public async Task<bool> IsUserInAnySquadAsync(string userId)
        {
            return await _context.SquadMembers.AnyAsync(sm => sm.UserId == userId);
        }

        public async Task<Squad> CreateSquadAsync(Squad squad, string adminUserId)
        {
            _context.Squads.Add(squad);
            _context.SquadMembers.Add(new SquadMember
            {
                Squad = squad,
                UserId = adminUserId,
                Role = "Admin"
            });
            await _context.SaveChangesAsync();
            return squad;
        }

        public async Task AddMemberAsync(Guid squadId, string userId, string role)
        {
            _context.SquadMembers.Add(new SquadMember
            {
                SquadId = squadId,
                UserId = userId,
                Role = role
            });
            await _context.SaveChangesAsync();
        }

        public async Task<int> GetMemberCountAsync(Guid squadId)
        {
            return await _context.SquadMembers.CountAsync(sm => sm.SquadId == squadId);
        }

        public async Task UpdateAsync(Squad squad)
        {
            _context.Squads.Update(squad);
            await _context.SaveChangesAsync();
        }
    }
}
