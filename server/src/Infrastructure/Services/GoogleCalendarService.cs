using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HabitTracker.Application.Common;
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

        /// <summary>
        /// The authorised Calendar client. Virtual so tests can hand the sync a client whose HTTP
        /// goes to a fake Google instead of the network.
        /// </summary>
        protected virtual async Task<CalendarService> GetCalendarServiceAsync(string userId, string refreshToken, CancellationToken cancellationToken)
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

            return new CalendarService(new BaseClientService.Initializer
            {
                HttpClientInitializer = credential,
                ApplicationName = "Habit Tracker"
            });
        }

        public async Task<bool> SyncEventsAsync(string userId, string refreshToken, DateTime? syncStart, DateTime? syncEnd, CancellationToken cancellationToken)
        {
            try
            {
                var calendarService = await GetCalendarServiceAsync(userId, refreshToken, cancellationToken);

                var windowStart = syncStart ?? DateTime.UtcNow - GoogleSyncWindow.DefaultLookBack;
                var windowEnd = syncEnd ?? DateTime.UtcNow + GoogleSyncWindow.DefaultLookAhead;
                var googleEvents = await ListWindowAsync(calendarService, windowStart, windowEnd, cancellationToken);

                var localEvents = await _eventRepository.GetEventsForUserAsync(userId);
                var localGoogleEvents = localEvents.Where(e => !string.IsNullOrEmpty(e.GoogleEventId)).ToList();

                // 1. Delete events locally that Google cancelled (non-recurring events and whole
                // series) or no longer has. The list covers only the window, so an event missing
                // from it is gone only if the window would have held it — and even then Google is
                // asked, because the local copy may be out of date (see GoogleSyncWindow). What the
                // lookup finds still on Google joins the list, so the steps below apply it.
                var deletedIds = new HashSet<Guid>();
                var lookupsAvailable = true;
                foreach (var localEvent in localGoogleEvents)
                {
                    if (deletedIds.Contains(localEvent.Id)) continue;

                    var matchingGe = googleEvents.FirstOrDefault(ge => ge.Id == localEvent.GoogleEventId);
                    bool gone;
                    if (matchingGe != null)
                    {
                        gone = matchingGe.Status == CancelledStatus && string.IsNullOrEmpty(matchingGe.RecurringEventId);
                    }
                    else if (!lookupsAvailable || !GoogleSyncWindow.CouldBeListed(localEvent, windowStart, windowEnd))
                    {
                        gone = false;
                    }
                    else
                    {
                        var lookup = await LookUpAsync(calendarService, localEvent.GoogleEventId!, cancellationToken);
                        gone = lookup.Outcome == LookupOutcome.Gone;
                        if (lookup.Outcome == LookupOutcome.Found) googleEvents.Add(lookup.Event!);
                        // One failure — offline, timed out, rate limited — is likely to repeat, so
                        // the rest are kept unasked rather than each waiting out the same error.
                        if (lookup.Outcome == LookupOutcome.Unknown) lookupsAvailable = false;
                    }

                    if (!gone) continue;

                    // A series takes its days with it, whatever their date: they cannot outlive it,
                    // and outside the window nothing else would remove them. Children first — the
                    // parent link is set to null, not cascaded, when the series goes.
                    foreach (var day in localEvents.Where(e => e.ParentEventId == localEvent.Id && !deletedIds.Contains(e.Id)))
                    {
                        await _eventRepository.DeleteAsync(day.Id);
                        deletedIds.Add(day.Id);
                    }

                    await _eventRepository.DeleteAsync(localEvent.Id);
                    deletedIds.Add(localEvent.Id);
                }

                // Refresh local google events list
                localEvents = await _eventRepository.GetEventsForUserAsync(userId);
                localGoogleEvents = localEvents.Where(e => !string.IsNullOrEmpty(e.GoogleEventId)).ToList();

                // 2. Separate Google Events into Masters, Exceptions, and regular events
                var masterEvents = googleEvents.Where(ge => ge.Status != CancelledStatus && ge.Recurrence != null && ge.Recurrence.Any()).ToList();
                var exceptionEvents = googleEvents.Where(ge => ge.RecurringEventId != null).ToList();
                var regularEvents = googleEvents.Where(ge => ge.Status != CancelledStatus && (ge.Recurrence == null || !ge.Recurrence.Any()) && ge.RecurringEventId == null).ToList();

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

                    // Looked up before this sync writes the date into the series' exception list.
                    // Afterwards every day on that date would look edited, and before it an edited
                    // day whose Insert is still queued looks local-only — only the list, read now,
                    // tells them apart (see FindLocalOnlyDay).
                    var localOnlyDay = OccurrenceMaterializer.FindLocalOnlyDay(localEvents, localMaster, originalDate);

                    if (ge.Status == CancelledStatus)
                    {
                        // Add exception date to master EXDATE list
                        RecurrenceExceptions.Add(localMaster, originalDate);
                        await _eventRepository.UpdateAsync(localMaster);

                        var existingExceptionLocal = localGoogleEvents.FirstOrDefault(le => le.GoogleEventId == ge.Id);
                        if (existingExceptionLocal != null)
                        {
                            await _eventRepository.DeleteAsync(existingExceptionLocal.Id);
                        }

                        // The day may also exist locally only, split off by a ticked task or a
                        // finished session. Google cancelled it, so it goes too, or a cancelled
                        // meeting would stay on the calendar. Not an edited day, though: Google
                        // reports that same cancellation back after every edit of one occurrence,
                        // and deleting the edited day there lost it along with its tasks.
                        if (localOnlyDay != null)
                        {
                            await _eventRepository.DeleteAsync(localOnlyDay.Id);
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
                        else if (localOnlyDay != null)
                        {
                            // Google changed a day the user had already split off locally.
                            // Adopt it instead of adding a second event for the same day, so its
                            // tasks and completion are kept.
                            localOnlyDay.GoogleEventId = ge.Id;
                            localOnlyDay.Title = ge.Summary ?? "(No Title)";
                            localOnlyDay.StartTime = startTime;
                            localOnlyDay.EndTime = endTime;
                            localOnlyDay.TargetDuration = targetDuration;
                            localOnlyDay.ExceptionDate = originalDate;
                            await _eventRepository.UpdateAsync(localOnlyDay);
                        }
                        // Nothing is added when the day already has an event Google has no id for
                        // — an edited day whose Insert is still queued. A second event for that
                        // day is what the database refuses, and the queued Insert sends the
                        // user's edit, which is the newer one, and links the two.
                        else if (OccurrenceMaterializer.FindDay(localEvents, localMaster, originalDate) == null)
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

                        RecurrenceExceptions.Add(localMaster, originalDate);
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

        private const string CancelledStatus = "cancelled";

        /// <summary>
        /// Every event Google lists for the window, across all pages. A page may hold fewer events
        /// than asked for, or none, while more remain; reading only the first one made every event
        /// on a later page look deleted.
        /// </summary>
        private static async Task<List<Google.Apis.Calendar.v3.Data.Event>> ListWindowAsync(
            CalendarService calendarService, DateTime windowStart, DateTime windowEnd, CancellationToken cancellationToken)
        {
            var events = new List<Google.Apis.Calendar.v3.Data.Event>();
            string? pageToken = null;

            do
            {
                var listRequest = calendarService.Events.List("primary");
                listRequest.TimeMinDateTimeOffset = windowStart;
                listRequest.TimeMaxDateTimeOffset = windowEnd;
                listRequest.SingleEvents = false;
                listRequest.ShowDeleted = true;
                listRequest.PageToken = pageToken;

                var page = await listRequest.ExecuteAsync(cancellationToken);
                if (page.Items != null) events.AddRange(page.Items);

                // Google does not repeat a token, but a loop that trusts it never ends if it did.
                if (page.NextPageToken == pageToken) break;
                pageToken = page.NextPageToken;
            }
            while (!string.IsNullOrEmpty(pageToken));

            return events;
        }

        private enum LookupOutcome
        {
            /// <summary>Cancelled, or not found at all (404, 410).</summary>
            Gone,
            /// <summary>Still on Google; <see cref="Lookup.Event"/> holds its current state.</summary>
            Found,
            /// <summary>Google could not be asked or did not answer.</summary>
            Unknown,
        }

        private sealed record Lookup(LookupOutcome Outcome, Google.Apis.Calendar.v3.Data.Event? Event = null);

        /// <summary>
        /// Asks Google for one event the list left out. Anything but a clear "gone" keeps the local
        /// event — a missed deletion is put right by a later sync, a wrong one loses the user's
        /// tasks and completion for good.
        /// </summary>
        private static async Task<Lookup> LookUpAsync(
            CalendarService calendarService, string googleEventId, CancellationToken cancellationToken)
        {
            try
            {
                var googleEvent = await calendarService.Events.Get("primary", googleEventId).ExecuteAsync(cancellationToken);
                return googleEvent.Status == CancelledStatus
                    ? new Lookup(LookupOutcome.Gone)
                    : new Lookup(LookupOutcome.Found, googleEvent);
            }
            catch (Google.GoogleApiException ex)
                when (ex.HttpStatusCode == System.Net.HttpStatusCode.NotFound || ex.HttpStatusCode == System.Net.HttpStatusCode.Gone)
            {
                return new Lookup(LookupOutcome.Gone);
            }
            catch (Exception ex) when (ex is Google.GoogleApiException
                                       || ex is System.Net.Http.HttpRequestException
                                       || (ex is TaskCanceledException && !cancellationToken.IsCancellationRequested))
            {
                Console.WriteLine($"Google Sync: kept {googleEventId}, lookup failed: {ex.GetType().Name} {ex.Message}");
                return new Lookup(LookupOutcome.Unknown);
            }
        }

        public async Task<string?> PushInsertAsync(string userId, string refreshToken, Guid eventId, string payload, CancellationToken cancellationToken)
        {
            var service = await GetCalendarServiceAsync(userId, refreshToken, cancellationToken);
            var data = System.Text.Json.JsonSerializer.Deserialize<PushPayload>(payload);
            if (data == null) return null;

            var googleEvent = new Google.Apis.Calendar.v3.Data.Event
            {
                Summary = data.Title,
                Start = new Google.Apis.Calendar.v3.Data.EventDateTime { DateTimeDateTimeOffset = data.StartTime },
                End = new Google.Apis.Calendar.v3.Data.EventDateTime { DateTimeDateTimeOffset = data.EndTime },
            };

            if (!string.IsNullOrEmpty(data.RecurrenceRule))
            {
                googleEvent.Recurrence = new List<string> { data.RecurrenceRule };
            }

            if (data.ParentEventId.HasValue && data.ExceptionDate.HasValue)
            {
                var parentLocal = await _eventRepository.GetByIdAsync(data.ParentEventId.Value);
                if (parentLocal != null && !string.IsNullOrEmpty(parentLocal.GoogleEventId))
                {
                    var instancesReq = service.Events.Instances("primary", parentLocal.GoogleEventId);
                    instancesReq.TimeMinDateTimeOffset = data.ExceptionDate.Value.AddMinutes(-5);
                    instancesReq.TimeMaxDateTimeOffset = data.ExceptionDate.Value.AddMinutes(5);
                    var instances = await instancesReq.ExecuteAsync(cancellationToken);
                    
                    var targetInstance = instances.Items?.FirstOrDefault(x => 
                        GetGoogleDateTime(x.OriginalStartTime ?? x.Start).Date == data.ExceptionDate.Value.Date);

                    if (targetInstance != null)
                    {
                        targetInstance.Summary = data.Title;
                        targetInstance.Start = googleEvent.Start;
                        targetInstance.End = googleEvent.End;
                        var updated = await service.Events.Update(targetInstance, "primary", targetInstance.Id).ExecuteAsync(cancellationToken);
                        return updated.Id;
                    }
                }
            }

            var inserted = await service.Events.Insert(googleEvent, "primary").ExecuteAsync(cancellationToken);
            return inserted.Id;
        }

        public async Task PushUpdateAsync(string userId, string refreshToken, string googleEventId, string payload, CancellationToken cancellationToken)
        {
            var service = await GetCalendarServiceAsync(userId, refreshToken, cancellationToken);
            var data = System.Text.Json.JsonSerializer.Deserialize<PushPayload>(payload);
            if (data == null) return;

            Google.Apis.Calendar.v3.Data.Event? existing = null;
            try
            {
                existing = await service.Events.Get("primary", googleEventId).ExecuteAsync(cancellationToken);
            }
            catch
            {
                // Ignored
            }

            if (existing != null)
            {
                existing.Summary = data.Title;
                existing.Start = new Google.Apis.Calendar.v3.Data.EventDateTime { DateTimeDateTimeOffset = data.StartTime };
                existing.End = new Google.Apis.Calendar.v3.Data.EventDateTime { DateTimeDateTimeOffset = data.EndTime };
                
                if (!string.IsNullOrEmpty(data.RecurrenceRule))
                {
                    existing.Recurrence = new List<string> { data.RecurrenceRule };
                }
                else
                {
                    existing.Recurrence = null;
                }

                if (!string.IsNullOrEmpty(data.RecurrenceExceptionDates))
                {
                    var exceptionDates = data.RecurrenceExceptionDates.Split(',');
                    foreach (var dateStr in exceptionDates)
                    {
                        if (DateTime.TryParse(dateStr, out var exDate))
                        {
                            var instancesReq = service.Events.Instances("primary", googleEventId);
                            instancesReq.TimeMinDateTimeOffset = exDate.AddMinutes(-5);
                            instancesReq.TimeMaxDateTimeOffset = exDate.AddMinutes(5);
                            var instances = await instancesReq.ExecuteAsync(cancellationToken);
                            var targetInstance = instances.Items?.FirstOrDefault(x => 
                                GetGoogleDateTime(x.OriginalStartTime ?? x.Start).Date == exDate.Date);

                            if (targetInstance != null && targetInstance.Status != CancelledStatus)
                            {
                                targetInstance.Status = CancelledStatus;
                                await service.Events.Update(targetInstance, "primary", targetInstance.Id).ExecuteAsync(cancellationToken);
                            }
                        }
                    }
                }

                await service.Events.Update(existing, "primary", googleEventId).ExecuteAsync(cancellationToken);
            }
        }

        public async Task PushDeleteAsync(string userId, string refreshToken, string googleEventId, CancellationToken cancellationToken)
        {
            var service = await GetCalendarServiceAsync(userId, refreshToken, cancellationToken);
            try
            {
                await service.Events.Delete("primary", googleEventId).ExecuteAsync(cancellationToken);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Google Push Delete Error: {ex.Message}");
            }
        }

        public async Task<GoogleCalendarChannel?> WatchCalendarAsync(string userId, string refreshToken, string webhookUrl, CancellationToken cancellationToken)
        {
            var service = await GetCalendarServiceAsync(userId, refreshToken, cancellationToken);
            
            var channelId = Guid.NewGuid().ToString();
            var channel = new Google.Apis.Calendar.v3.Data.Channel
            {
                Id = channelId,
                Type = "web_hook",
                Address = webhookUrl,
                Token = userId
            };

            try
            {
                var response = await service.Events.Watch(channel, "primary").ExecuteAsync(cancellationToken);
                
                var expirationTime = DateTime.UtcNow.AddDays(7);
                if (response.Expiration.HasValue)
                {
                    expirationTime = DateTimeOffset.FromUnixTimeMilliseconds(response.Expiration.Value).UtcDateTime;
                }

                return new GoogleCalendarChannel
                {
                    Id = response.Id,
                    ResourceId = response.ResourceId,
                    UserId = userId,
                    Expiration = expirationTime
                };
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Google Watch Calendar Error: {ex.Message}");
                return null;
            }
        }

        public async Task StopWatchingCalendarAsync(string refreshToken, string channelId, string resourceId, CancellationToken cancellationToken)
        {
            var flow = new GoogleAuthorizationCodeFlow(new GoogleAuthorizationCodeFlow.Initializer
            {
                ClientSecrets = new ClientSecrets
                {
                    ClientId = _configuration["GoogleCalendar:ClientId"],
                    ClientSecret = _configuration["GoogleCalendar:ClientSecret"]
                },
                Scopes = new[] { CalendarService.Scope.Calendar }
            });

            var tokenResponse = new TokenResponse { RefreshToken = refreshToken };
            var credential = new UserCredential(flow, "stop-watch", tokenResponse);
            await credential.RefreshTokenAsync(cancellationToken);

            var service = new CalendarService(new BaseClientService.Initializer
            {
                HttpClientInitializer = credential,
                ApplicationName = "Habit Tracker"
            });

            var channel = new Google.Apis.Calendar.v3.Data.Channel
            {
                Id = channelId,
                ResourceId = resourceId
            };

            try
            {
                await service.Channels.Stop(channel).ExecuteAsync(cancellationToken);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Google Stop Watch Error: {ex.Message}");
            }
        }

        private class PushPayload
        {
            public string Title { get; set; } = string.Empty;
            public DateTime StartTime { get; set; }
            public DateTime EndTime { get; set; }
            public string? RecurrenceRule { get; set; }
            public string? RecurrenceExceptionDates { get; set; }
            public Guid? ParentEventId { get; set; }
            public DateTime? ExceptionDate { get; set; }
        }
    }
}
