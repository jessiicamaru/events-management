using HabitTracker.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;

namespace HabitTracker.Infrastructure.Data
{
    public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
    {
        /// <summary>
        /// Unique index allowing one event per series and minute of <see cref="Event.ExceptionDate"/>
        /// — one split-off day per day of a series. An expression index, so EF's model does not
        /// know it: it is created in the <c>AddOneEventPerSeriesDayIndex</c> migration, and
        /// <c>EventRepository.TryAddOccurrenceDayAsync</c> recognises its violation by this name.
        /// </summary>
        public const string OneEventPerSeriesDayIndex = "UX_Events_ParentEventId_ExceptionMinute";

        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }

        public DbSet<Habit> Habits { get; set; } = null!;
        public DbSet<HabitTask> HabitTasks { get; set; } = null!;
        public DbSet<Event> Events { get; set; } = null!;
        public DbSet<EventTask> EventTasks { get; set; } = null!;
        public DbSet<EventCategory> EventCategories { get; set; } = null!;
        public DbSet<GoogleCalendarSyncCache> GoogleCalendarSyncCaches { get; set; } = null!;
        public DbSet<GoogleCalendarOutbox> GoogleCalendarOutboxes { get; set; } = null!;
        public DbSet<GoogleCalendarChannel> GoogleCalendarChannels { get; set; } = null!;


        public DbSet<Squad> Squads { get; set; } = null!;
        public DbSet<SquadMember> SquadMembers { get; set; } = null!;
        public DbSet<SquadChatMessage> SquadChatMessages { get; set; } = null!;

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            
            modelBuilder.Entity<SquadMember>()
                .HasKey(sm => new { sm.SquadId, sm.UserId });
            modelBuilder.Entity<Habit>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Name).IsRequired().HasMaxLength(200);
                entity.HasOne(e => e.Category)
                      .WithMany()
                      .HasForeignKey(e => e.CategoryId)
                      .OnDelete(DeleteBehavior.SetNull);
            });

            modelBuilder.Entity<Event>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Title).IsRequired().HasMaxLength(200);
                entity.HasOne(e => e.Category)
                      .WithMany()
                      .HasForeignKey(e => e.CategoryId)
                      .OnDelete(DeleteBehavior.SetNull);
            });

            modelBuilder.Entity<EventCategory>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Name).IsRequired().HasMaxLength(100);
                entity.HasOne(e => e.User)
                      .WithMany()
                      .HasForeignKey(e => e.UserId)
                      .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(e => e.Squad)
                      .WithMany()
                      .HasForeignKey(e => e.SquadId)
                      .OnDelete(DeleteBehavior.Cascade);
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

            modelBuilder.Entity<SquadChatMessage>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Message).IsRequired().HasMaxLength(2000);
                entity.HasOne(e => e.Squad)
                      .WithMany()
                      .HasForeignKey(e => e.SquadId)
                      .OnDelete(DeleteBehavior.Cascade);
                entity.HasOne(e => e.Sender)
                      .WithMany()
                      .HasForeignKey(e => e.SenderUserId)
                      .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<GoogleCalendarSyncCache>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasOne(e => e.User)
                      .WithMany()
                      .HasForeignKey(e => e.UserId)
                      .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<GoogleCalendarOutbox>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasOne(e => e.User)
                      .WithMany()
                      .HasForeignKey(e => e.UserId)
                      .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<GoogleCalendarChannel>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasOne(e => e.User)
                      .WithMany()
                      .HasForeignKey(e => e.UserId)
                      .OnDelete(DeleteBehavior.Cascade);
            });
        }
    }
}
