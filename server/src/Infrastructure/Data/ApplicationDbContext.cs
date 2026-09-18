using HabitTracker.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;

namespace HabitTracker.Infrastructure.Data
{
    public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }

        public DbSet<Habit> Habits { get; set; } = null!;
        public DbSet<HabitTask> HabitTasks { get; set; } = null!;
        public DbSet<Event> Events { get; set; } = null!;
        public DbSet<EventTask> EventTasks { get; set; } = null!;

        public DbSet<Squad> Squads { get; set; } = null!;
        public DbSet<SquadMember> SquadMembers { get; set; } = null!;

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            
            modelBuilder.Entity<SquadMember>()
                .HasKey(sm => new { sm.SquadId, sm.UserId });
            modelBuilder.Entity<Habit>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Name).IsRequired().HasMaxLength(200);
            });

            modelBuilder.Entity<Event>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Title).IsRequired().HasMaxLength(200);
            });

            modelBuilder.Entity<HabitTask>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Title).IsRequired().HasMaxLength(200);
                entity.HasOne(t => t.Habit)
                      .WithMany(h => h.Tasks)
                      .HasForeignKey(t => t.HabitId)
                      .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<EventTask>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Title).IsRequired().HasMaxLength(200);
                entity.HasOne(t => t.Event)
                      .WithMany(ev => ev.Tasks)
                      .HasForeignKey(t => t.EventId)
                      .OnDelete(DeleteBehavior.Cascade);
            });
        }
    }
}
