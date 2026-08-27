using HabitTracker.Domain.Interfaces;
using HabitTracker.Infrastructure.Data;
using HabitTracker.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace HabitTracker.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructureServices(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection") ?? "Host=localhost;Database=habit-tracker;Username=postgres;Password=postgres";
        
        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseNpgsql(connectionString));

        services.AddScoped<IHabitRepository, HabitRepository>();
        services.AddScoped<IEventRepository, EventRepository>();

        return services;
    }
}
