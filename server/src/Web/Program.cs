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

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowFlutter");
app.UseHttpsRedirection();
app.UseAuthorization();

// Map Minimal APIs
app.MapEndpoints();

app.Run();
