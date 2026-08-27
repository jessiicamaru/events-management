using System.Reflection;
using Asp.Versioning.Builder;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;

namespace HabitTracker.Web.Infrastructure;

public static class WebApplicationExtensions
{
    private static RouteGroupBuilder MapGroup(this WebApplication app, EndpointGroupBase group, ApiVersionSet versionSet)
    {
        var groupName = group.GroupName ?? group.GetType().Name;

        return app
            .MapGroup($"/api/v{{version:apiVersion}}/{groupName.Replace(" ", "").ToLower()}")
            .WithApiVersionSet(versionSet)
            .WithTags(groupName);
    }

    public static WebApplication MapEndpoints(this WebApplication app)
    {
        var assembly = Assembly.GetExecutingAssembly();

        var endpointGroups = assembly.GetExportedTypes()
            .Where(t => t.IsSubclassOf(typeof(EndpointGroupBase)) && !t.IsAbstract)
            .Select(t => Activator.CreateInstance(t) as EndpointGroupBase)
            .Where(i => i is not null)
            .GroupBy(i => i!.Version);

        foreach (var versionGroup in endpointGroups)
        {
            var versionSet = app.NewApiVersionSet()
                .HasApiVersion(versionGroup.Key)
                .ReportApiVersions()
                .Build();

            foreach (var instance in versionGroup)
            {
                instance!.Map(app.MapGroup(instance, versionSet));
            }
        }

        return app;
    }
}
