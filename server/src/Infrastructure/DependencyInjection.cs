using HabitTracker.Domain.Interfaces;
using HabitTracker.Infrastructure.Data;
using HabitTracker.Infrastructure.Repositories;
using HabitTracker.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace HabitTracker.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructureServices(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection");

        // Fail loudly. The old fallback silently guessed a password, so a missing setting
        // surfaced later as a confusing authentication error from Postgres.
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                "ConnectionStrings:DefaultConnection is not configured. Copy " +
                "src/Web/appsettings.Development.example.json to appsettings.Development.json " +
                "and fill it in, or set the connection string via user-secrets or the " +
                "ConnectionStrings__DefaultConnection environment variable.");
        }
        
        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseNpgsql(connectionString));



        services.AddScoped<IUnitOfWork, UnitOfWork>();

        services.AddScoped<IHabitRepository, HabitRepository>();
        services.AddScoped<IEventRepository, EventRepository>();
        services.AddScoped<IEventCategoryRepository, EventCategoryRepository>();
        services.AddScoped<IUserRepository, UserRepository>();
        services.AddScoped<ISquadRepository, SquadRepository>();
        services.AddScoped<IHabitTaskRepository, HabitTaskRepository>();
        services.AddScoped<IEventTaskRepository, EventTaskRepository>();
        services.AddScoped<IGoogleCalendarSyncCacheRepository, GoogleCalendarSyncCacheRepository>();
        services.AddScoped<IGoogleCalendarOutboxRepository, GoogleCalendarOutboxRepository>();
        services.AddScoped<IGoogleCalendarChannelRepository, GoogleCalendarChannelRepository>();
        services.AddScoped<IGoogleCalendarService, GoogleCalendarService>();
        services.AddScoped<ApplicationDbContextInitialiser>();

        services.AddHostedService<GoogleCalendarSyncWorker>();

        return services;
    }
}
