using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Domain.Entities;
using HabitTracker.Domain.Interfaces;
using Microsoft.Extensions.Configuration;
using Google.Apis.Auth.OAuth2;
using Google.Apis.Auth.OAuth2.Flows;
using Google.Apis.Auth.OAuth2.Responses;
using Google.Apis.Calendar.v3;
using Google.Apis.Services;

namespace HabitTracker.Infrastructure.Services
{
    public class GoogleCalendarService : IGoogleCalendarService
    {
        private readonly IEventRepository _eventRepository;
        private readonly IConfiguration _configuration;

        public GoogleCalendarService(IEventRepository eventRepository, IConfiguration configuration)
        {
            _eventRepository = eventRepository;
            _configuration = configuration;
        }

        public async Task<string?> ExchangeCodeForRefreshTokenAsync(string userId, string authCode, CancellationToken cancellationToken)
        {
            try
            {
                var clientId = _configuration["GoogleCalendar:ClientId"];
                var clientSecret = _configuration["GoogleCalendar:ClientSecret"];
                var redirectUri = _configuration["GoogleCalendar:RedirectUri"] ?? "postmessage";

                var flow = new GoogleAuthorizationCodeFlow(new GoogleAuthorizationCodeFlow.Initializer
                {
                    ClientSecrets = new ClientSecrets
                    {
                        ClientId = clientId,
                        ClientSecret = clientSecret
                    },
                    Scopes = new[] { CalendarService.Scope.Calendar }
                });

                var tokenResponse = await flow.ExchangeCodeForTokenAsync(
                    userId: userId,
                    code: authCode,
                    redirectUri: redirectUri,
                    cancellationToken
                );

                return tokenResponse?.RefreshToken;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Google Auth Exchange Error: {ex}");
                return null;
            }
        }

        public async Task<bool> SyncEventsAsync(string userId, string refreshToken, CancellationToken cancellationToken)
        {
            try
            {
                var clientId = _configuration["GoogleCalendar:ClientId"];
                var clientSecret = _configuration["GoogleCalendar:ClientSecret"];

                var flow = new GoogleAuthorizationCodeFlow(new GoogleAuthorizationCodeFlow.Initializer
                {
                    ClientSecrets = new ClientSecrets
                    {
                        ClientId = clientId,
                        ClientSecret = clientSecret
                    },
                    Scopes = new[] { CalendarService.Scope.Calendar }
                });

                var tokenResponse = new TokenResponse
                {
                    RefreshToken = refreshToken
                };

                var credential = new UserCredential(flow, userId, tokenResponse);
                await credential.RefreshTokenAsync(cancellationToken);

                var calendarService = new CalendarService(new BaseClientService.Initializer
                {
                    HttpClientInitializer = credential,
                    ApplicationName = "Habit Tracker"
                });

                var listRequest = calendarService.Events.List("primary");
                listRequest.TimeMinDateTimeOffset = DateTime.UtcNow.AddDays(-30);
                listRequest.TimeMaxDateTimeOffset = DateTime.UtcNow.AddDays(60);
                listRequest.SingleEvents = true;
                listRequest.ShowDeleted = false;

                var googleEventsList = await listRequest.ExecuteAsync(cancellationToken);
                var googleEvents = googleEventsList.Items ?? new List<Google.Apis.Calendar.v3.Data.Event>();

                var localEvents = await _eventRepository.GetEventsForUserAsync(userId);
                var localGoogleEvents = localEvents.Where(e => !string.IsNullOrEmpty(e.GoogleEventId)).ToList();

                var googleEventIds = googleEvents.Select(ge => ge.Id).ToHashSet();

                // 1. Delete events locally that were removed in Google Calendar
                foreach (var localEvent in localGoogleEvents)
                {
                    if (!googleEventIds.Contains(localEvent.GoogleEventId!))
                    {
                        await _eventRepository.DeleteAsync(localEvent.Id);
                    }
                }

                // 2. Add or Update events
                foreach (var googleEvent in googleEvents)
                {
                    var existingLocalEvent = localGoogleEvents.FirstOrDefault(le => le.GoogleEventId == googleEvent.Id);

                    DateTime startTime = DateTime.UtcNow;
                    DateTime endTime = DateTime.UtcNow.AddHours(1);

                    if (googleEvent.Start != null)
                    {
                        if (googleEvent.Start.DateTimeDateTimeOffset.HasValue)
                            startTime = googleEvent.Start.DateTimeDateTimeOffset.Value.UtcDateTime;
                        else if (!string.IsNullOrEmpty(googleEvent.Start.Date))
                            startTime = DateTime.SpecifyKind(DateTime.Parse(googleEvent.Start.Date), DateTimeKind.Utc);
                    }

                    if (googleEvent.End != null)
                    {
                        if (googleEvent.End.DateTimeDateTimeOffset.HasValue)
                            endTime = googleEvent.End.DateTimeDateTimeOffset.Value.UtcDateTime;
                        else if (!string.IsNullOrEmpty(googleEvent.End.Date))
                            endTime = DateTime.SpecifyKind(DateTime.Parse(googleEvent.End.Date), DateTimeKind.Utc);
                    }

                    var targetDuration = endTime - startTime;

                    if (existingLocalEvent != null)
                    {
                        existingLocalEvent.Title = googleEvent.Summary ?? "(No Title)";
                        existingLocalEvent.StartTime = startTime;
                        existingLocalEvent.EndTime = endTime;
                        existingLocalEvent.TargetDuration = targetDuration;

                        await _eventRepository.UpdateAsync(existingLocalEvent);
                    }
                    else
                    {
                        var newEvent = new Event
                        {
                            Id = Guid.NewGuid(),
                            Title = googleEvent.Summary ?? "(No Title)",
                            StartTime = startTime,
                            EndTime = endTime,
                            TargetDuration = targetDuration,
                            UserId = userId,
                            GoogleEventId = googleEvent.Id,
                            IsCompleted = false,
                            HabitId = string.Empty
                        };

                        await _eventRepository.AddAsync(newEvent);
                    }
                }

                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Google Sync Events Error: {ex}");
                return false;
            }
        }
    }
}
