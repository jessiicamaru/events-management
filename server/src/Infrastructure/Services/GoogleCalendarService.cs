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
                var redirectUri = _configuration["GoogleCalendar:RedirectUri"];
                if (string.IsNullOrWhiteSpace(redirectUri))
                {
                    redirectUri = "http://localhost:5000";
                }

                using var httpClient = new System.Net.Http.HttpClient();
                var requestBody = new Dictionary<string, string>
                {
                    { "code", authCode },
                    { "client_id", clientId ?? "" },
                    { "client_secret", clientSecret ?? "" },
                    { "redirect_uri", redirectUri },
                    { "grant_type", "authorization_code" },
                };

                var response = await httpClient.PostAsync(
                    "https://oauth2.googleapis.com/token",
                    new System.Net.Http.FormUrlEncodedContent(requestBody),
                    cancellationToken
                );

                var responseContent = await response.Content.ReadAsStringAsync(cancellationToken);

                if (!response.IsSuccessStatusCode)
                {
                    Console.WriteLine($"Google Auth Exchange Error: {responseContent}");
                    return null;
                }

                var json = System.Text.Json.JsonDocument.Parse(responseContent);
                var refreshToken = json.RootElement.TryGetProperty("refresh_token", out var rt) ? rt.GetString() : null;
                Console.WriteLine($"Google Auth Exchange: Success, got refresh_token={refreshToken != null}");
                return refreshToken;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Google Auth Exchange Error: {ex.Message}");
                return null;
            }
        }


        private static DateTime GetGoogleDateTime(Google.Apis.Calendar.v3.Data.EventDateTime? googleTime)
        {
            if (googleTime == null) return DateTime.UtcNow;
            if (googleTime.DateTimeDateTimeOffset.HasValue)
                return googleTime.DateTimeDateTimeOffset.Value.UtcDateTime;
            if (!string.IsNullOrEmpty(googleTime.Date))
                return DateTime.SpecifyKind(DateTime.Parse(googleTime.Date), DateTimeKind.Utc);
            return DateTime.UtcNow;
        }

        public async Task<bool> SyncEventsAsync(string userId, string refreshToken, DateTime? syncStart, DateTime? syncEnd, CancellationToken cancellationToken)
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
                listRequest.TimeMinDateTimeOffset = syncStart ?? DateTime.UtcNow.AddDays(-7);
                listRequest.TimeMaxDateTimeOffset = syncEnd ?? DateTime.UtcNow.AddDays(14);
                listRequest.SingleEvents = false;
                listRequest.ShowDeleted = true;

                var googleEventsList = await listRequest.ExecuteAsync(cancellationToken);
                var googleEvents = googleEventsList.Items ?? new List<Google.Apis.Calendar.v3.Data.Event>();

                var localEvents = await _eventRepository.GetEventsForUserAsync(userId);
                var localGoogleEvents = localEvents.Where(e => !string.IsNullOrEmpty(e.GoogleEventId)).ToList();

                var googleEventIds = googleEvents.Select(ge => ge.Id).ToHashSet();

                // 1. Delete events locally that are no longer in Google Calendar or are marked cancelled (for non-recurring events)
                foreach (var localEvent in localGoogleEvents)
                {
                    var matchingGe = googleEvents.FirstOrDefault(ge => ge.Id == localEvent.GoogleEventId);
                    if (matchingGe == null || (matchingGe.Status == "cancelled" && string.IsNullOrEmpty(matchingGe.RecurringEventId)))
                    {
                        await _eventRepository.DeleteAsync(localEvent.Id);
                    }
                }

                // Refresh local google events list
                localEvents = await _eventRepository.GetEventsForUserAsync(userId);
                localGoogleEvents = localEvents.Where(e => !string.IsNullOrEmpty(e.GoogleEventId)).ToList();

                // 2. Separate Google Events into Masters, Exceptions, and regular events
                var masterEvents = googleEvents.Where(ge => ge.Status != "cancelled" && ge.Recurrence != null && ge.Recurrence.Any()).ToList();
                var exceptionEvents = googleEvents.Where(ge => ge.RecurringEventId != null).ToList();
                var regularEvents = googleEvents.Where(ge => ge.Status != "cancelled" && (ge.Recurrence == null || !ge.Recurrence.Any()) && ge.RecurringEventId == null).ToList();

                // 3. Process Master Events
                foreach (var ge in masterEvents)
                {
                    var existingLocal = localGoogleEvents.FirstOrDefault(le => le.GoogleEventId == ge.Id && le.ParentEventId == null);
                    var rrule = ge.Recurrence.First();
                    
                    DateTime startTime = GetGoogleDateTime(ge.Start);
                    DateTime endTime = GetGoogleDateTime(ge.End);
                    var targetDuration = endTime - startTime;

                    if (existingLocal != null)
                    {
                        existingLocal.Title = ge.Summary ?? "(No Title)";
                        existingLocal.StartTime = startTime;
                        existingLocal.EndTime = endTime;
                        existingLocal.TargetDuration = targetDuration;
                        existingLocal.RecurrenceRule = rrule;
                        await _eventRepository.UpdateAsync(existingLocal);
                    }
                    else
                    {
                        var newEvent = new Event
                        {
                            Id = Guid.NewGuid(),
                            Title = ge.Summary ?? "(No Title)",
                            StartTime = startTime,
                            EndTime = endTime,
                            TargetDuration = targetDuration,
                            UserId = userId,
                            GoogleEventId = ge.Id,
                            RecurrenceRule = rrule,
                            IsCompleted = false,
                            HabitId = string.Empty
                        };
                        await _eventRepository.AddAsync(newEvent);
                        localGoogleEvents.Add(newEvent); // Add to local list to be referenced as parent
                    }
                }

                // 4. Process Exceptions
                foreach (var ge in exceptionEvents)
                {
                    var localMaster = localGoogleEvents.FirstOrDefault(le => le.GoogleEventId == ge.RecurringEventId && le.ParentEventId == null);
                    if (localMaster == null) continue;

                    var originalDate = GetGoogleDateTime(ge.OriginalStartTime ?? ge.Start);
                    var originalDateStr = originalDate.ToString("yyyy-MM-ddTHH:mm:ssZ");

                    if (ge.Status == "cancelled")
                    {
                        // Add exception date to master EXDATE list
                        if (string.IsNullOrEmpty(localMaster.RecurrenceExceptionDates))
                        {
                            localMaster.RecurrenceExceptionDates = originalDateStr;
                        }
                        else if (!localMaster.RecurrenceExceptionDates.Contains(originalDateStr))
                        {
                            localMaster.RecurrenceExceptionDates += "," + originalDateStr;
                        }
                        await _eventRepository.UpdateAsync(localMaster);

                        var existingExceptionLocal = localGoogleEvents.FirstOrDefault(le => le.GoogleEventId == ge.Id);
                        if (existingExceptionLocal != null)
                        {
                            await _eventRepository.DeleteAsync(existingExceptionLocal.Id);
                        }
                    }
                    else
                    {
                        var existingExceptionLocal = localGoogleEvents.FirstOrDefault(le => le.GoogleEventId == ge.Id);
                        DateTime startTime = GetGoogleDateTime(ge.Start);
                        DateTime endTime = GetGoogleDateTime(ge.End);
                        var targetDuration = endTime - startTime;

                        if (existingExceptionLocal != null)
                        {
                            existingExceptionLocal.Title = ge.Summary ?? "(No Title)";
                            existingExceptionLocal.StartTime = startTime;
                            existingExceptionLocal.EndTime = endTime;
                            existingExceptionLocal.TargetDuration = targetDuration;
                            existingExceptionLocal.ExceptionDate = originalDate;
                            await _eventRepository.UpdateAsync(existingExceptionLocal);
                        }
                        else
                        {
                            var newException = new Event
                            {
                                Id = Guid.NewGuid(),
                                Title = ge.Summary ?? "(No Title)",
                                StartTime = startTime,
                                EndTime = endTime,
                                TargetDuration = targetDuration,
                                UserId = userId,
                                GoogleEventId = ge.Id,
                                ParentEventId = localMaster.Id,
                                ExceptionDate = originalDate,
                                IsCompleted = false,
                                HabitId = string.Empty
                            };
                            await _eventRepository.AddAsync(newException);
                        }

                        if (string.IsNullOrEmpty(localMaster.RecurrenceExceptionDates))
                        {
                            localMaster.RecurrenceExceptionDates = originalDateStr;
                        }
                        else if (!localMaster.RecurrenceExceptionDates.Contains(originalDateStr))
                        {
                            localMaster.RecurrenceExceptionDates += "," + originalDateStr;
                        }
                        await _eventRepository.UpdateAsync(localMaster);
                    }
                }

                // 5. Process Regular Events
                foreach (var ge in regularEvents)
                {
                    var existingLocal = localGoogleEvents.FirstOrDefault(le => le.GoogleEventId == ge.Id && le.ParentEventId == null);
                    DateTime startTime = GetGoogleDateTime(ge.Start);
                    DateTime endTime = GetGoogleDateTime(ge.End);
                    var targetDuration = endTime - startTime;

                    if (existingLocal != null)
                    {
                        existingLocal.Title = ge.Summary ?? "(No Title)";
                        existingLocal.StartTime = startTime;
                        existingLocal.EndTime = endTime;
                        existingLocal.TargetDuration = targetDuration;
                        await _eventRepository.UpdateAsync(existingLocal);
                    }
                    else
                    {
                        var newEvent = new Event
                        {
                            Id = Guid.NewGuid(),
                            Title = ge.Summary ?? "(No Title)",
                            StartTime = startTime,
                            EndTime = endTime,
                            TargetDuration = targetDuration,
                            UserId = userId,
                            GoogleEventId = ge.Id,
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
