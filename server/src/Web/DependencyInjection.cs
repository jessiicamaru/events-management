using Microsoft.Extensions.DependencyInjection;

namespace HabitTracker.Web;

public static class DependencyInjection
{
    public static IServiceCollection AddWebServices(this IServiceCollection services)
    {
        services.AddEndpointsApiExplorer();
        services.AddSwaggerGen();
        services.AddAuthorization();
        services.AddSignalR();
        // Replaces the Application's silent default, so the app sees the assistant's progress.
        services.AddScoped<HabitTracker.Application.Features.Assistant.Harness.IAssistantProgress,
            HabitTracker.Web.Hubs.AssistantHubProgress>();
        services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(typeof(DependencyInjection).Assembly));
        
        services.AddCors(options =>
        {
            options.AddPolicy("AllowFlutter", policy =>
            {
                policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader();
            });
        });

        services.AddApiVersioning(options =>
        {
            options.ReportApiVersions = true;
        }).AddApiExplorer(options =>
        {
            options.GroupNameFormat = "'v'VVV";
            options.SubstituteApiVersionInUrl = true;
        });

        return services;
    }
}
