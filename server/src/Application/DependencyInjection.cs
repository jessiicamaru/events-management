using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using System.Reflection;

namespace HabitTracker.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(Assembly.GetExecutingAssembly()));

        // Scoped like the repositories and unit of work it uses.
        services.AddScoped<Common.OccurrenceMaterializer>();

        services.TryAddSingleton(TimeProvider.System);

        // The assistant: its loop, and the tools it may use. A tool is registered here to exist.
        services.AddScoped<Features.Assistant.Harness.AssistantHarness>();
        services.TryAddScoped<Features.Assistant.Harness.IAssistantProgress, Features.Assistant.Harness.NoAssistantProgress>();
        services.AddScoped<Features.Assistant.Harness.IAssistantTool, Features.Assistant.Tools.GetEventsTool>();
        services.AddScoped<Features.Assistant.Harness.IAssistantTool, Features.Assistant.Tools.GetHabitsTool>();
        services.AddScoped<Features.Assistant.Harness.IAssistantTool, Features.Assistant.Tools.GetCategoriesTool>();
        services.AddScoped<Features.Assistant.Harness.IAssistantTool, Features.Assistant.Tools.GetStatsTool>();
        return services;
    }
}
