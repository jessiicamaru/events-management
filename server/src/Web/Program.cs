using HabitTracker.Application;
using HabitTracker.Infrastructure;
using HabitTracker.Web;
using HabitTracker.Web.Infrastructure;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Hosting;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container from each layer
builder.Services.AddApplicationServices();
builder.Services.AddInfrastructureServices(builder.Configuration);
builder.Services.AddWebServices();

builder.Services.AddAuthorizationBuilder();
builder.Services.AddIdentityApiEndpoints<HabitTracker.Domain.Entities.ApplicationUser>()
    .AddEntityFrameworkStores<HabitTracker.Infrastructure.Data.ApplicationDbContext>();
var app = builder.Build();

// Initialise and seed database
using (var scope = app.Services.CreateScope())
{
    var initialiser = scope.ServiceProvider.GetRequiredService<HabitTracker.Infrastructure.Data.ApplicationDbContextInitialiser>();
    await initialiser.InitialiseAsync();
    // await initialiser.SeedAsync();
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowFlutter");
app.UseHttpsRedirection();

// Middleware hỗ trợ SignalR WebSocket lấy token từ query string gắn vào Header Authorization
app.Use(async (context, next) =>
{
    var accessToken = context.Request.Query["access_token"];
    var path = context.Request.Path;
    if (!string.IsNullOrEmpty(accessToken) && HabitTracker.Web.Hubs.HubTokenPaths.AcceptsQueryToken(path))
    {
        context.Request.Headers["Authorization"] = $"Bearer {accessToken}";
    }
    await next();
});

app.UseAuthentication();
app.UseAuthorization();

// Map Minimal APIs
app.MapEndpoints();
app.MapGroup("/api/v1").MapIdentityApi<HabitTracker.Domain.Entities.ApplicationUser>();
app.MapHub<HabitTracker.Web.Hubs.SocialHub>(HabitTracker.Web.Hubs.HubTokenPaths.SocialHub);
app.MapHub<HabitTracker.Web.Hubs.AssistantHub>(HabitTracker.Web.Hubs.AssistantHub.Path);

app.Run();
