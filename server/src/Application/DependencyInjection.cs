using Microsoft.Extensions.DependencyInjection;
using System.Reflection;

namespace HabitTracker.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(Assembly.GetExecutingAssembly()));

        // Scoped like the repositories and unit of work it uses.
        services.AddScoped<Common.OccurrenceMaterializer>();
        return services;
    }
}
