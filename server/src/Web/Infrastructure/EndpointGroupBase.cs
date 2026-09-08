using Asp.Versioning;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Routing;

namespace HabitTracker.Web.Infrastructure;

public abstract class EndpointGroupBase
{
    public virtual string? GroupName { get; }
    public virtual string? GroupDescription { get; }
    public virtual ApiVersion Version => new(1, 0);
    public abstract void Map(RouteGroupBuilder groupBuilder);
}
