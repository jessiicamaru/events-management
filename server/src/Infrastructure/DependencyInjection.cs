using HabitTracker.Application.Features.Assistant;
using HabitTracker.Domain.Interfaces;
using HabitTracker.Infrastructure.Ai;
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

        AddAssistant(services, configuration);

        return services;
    }

    /// <summary>
    /// The assistant's repository and language model. A missing key is not an error — the
    /// assistant is optional and answers 503 without one — but a key with an unknown provider
    /// is, because it would otherwise fail on the first message instead of at startup.
    /// </summary>
    private static void AddAssistant(IServiceCollection services, IConfiguration configuration)
    {
        var options = configuration.GetSection(AssistantOptions.SectionName).Get<AssistantOptions>() ?? new AssistantOptions();
        services.AddSingleton(options);
        services.AddScoped<IAssistantRepository, AssistantRepository>();

        if (options.IsConfigured
            && !string.Equals(options.Provider, AssistantOptions.Providers.DeepSeek, StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException(
                $"Assistant:Provider '{options.Provider}' is not supported. Use '{AssistantOptions.Providers.DeepSeek}'.");
        }

        // One long-lived client; the pooled-connection lifetime keeps DNS changes from sticking.
        var http = new HttpClient(new SocketsHttpHandler { PooledConnectionLifetime = TimeSpan.FromMinutes(5) })
        {
            // The adapter applies RequestTimeoutSeconds per call; this is only a backstop.
            Timeout = Timeout.InfiniteTimeSpan,
        };
        services.AddSingleton<ILanguageModel>(new DeepSeekLanguageModel(http, options));
    }
}
