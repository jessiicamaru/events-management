using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using Google.Apis.Calendar.v3;
using Google.Apis.Http;
using Google.Apis.Services;
using HabitTracker.Domain.Entities;
using HabitTracker.Infrastructure.Data;
using HabitTracker.Infrastructure.Repositories;
using HabitTracker.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Xunit;

namespace HabitTracker.Application.Tests.Infrastructure
{
    /// <summary>
    /// Incoming sync lists one window of Google's calendar and removes the local events Google no
    /// longer has. It used to compare <em>every</em> synced event with that one window, and read only
    /// the first page of the list, so events outside the window — the user's history, or next
    /// month when the calendar asked for this one — and events on a later page were deleted
    /// (roadmap 5.8). These tests run the real <see cref="GoogleCalendarService.SyncEventsAsync"/>
    /// against a fake Google.
    /// </summary>
    public class GoogleCalendarSyncRemovalTests
    {
        private const string UserId = "user-1";
        private static readonly DateTime WindowStart = new(2026, 9, 1, 0, 0, 0, DateTimeKind.Utc);
        private static readonly DateTime WindowEnd = new(2026, 9, 22, 0, 0, 0, DateTimeKind.Utc);

        private readonly ApplicationDbContext _context = new(
            new DbContextOptionsBuilder<ApplicationDbContext>()
                .UseInMemoryDatabase(Guid.NewGuid().ToString())
                .Options);

        private readonly FakeGoogle _google = new();
        private readonly TestableGoogleCalendarService _service;

        public GoogleCalendarSyncRemovalTests()
        {
            _service = new TestableGoogleCalendarService(
                new EventRepository(_context),
                new ConfigurationBuilder().Build(),
                _google);
        }

        private async Task<Event> SeedLinkedAsync(
            string? googleId, DateTime start, TimeSpan? length = null, string? recurrenceRule = null, Guid? parentId = null)
        {
            var ev = new Event
            {
                Title = googleId ?? "local only",
                StartTime = start,
                EndTime = start + (length ?? TimeSpan.FromHours(1)),
                UserId = UserId,
                GoogleEventId = googleId,
                RecurrenceRule = recurrenceRule,
                ParentEventId = parentId,
                ExceptionDate = parentId == null ? null : start,
            };
            _context.Events.Add(ev);
            await _context.SaveChangesAsync();
            _context.ChangeTracker.Clear();
            return ev;
        }

        private Task<bool> SyncAsync() =>
            _service.SyncEventsAsync(UserId, "refresh-token", WindowStart, WindowEnd, CancellationToken.None);

        private Task<bool> Exists(Guid id) => _context.Events.AsNoTracking().AnyAsync(e => e.Id == id);

        // --- Events Google's list could not have contained ---------------------------------------

        [Fact]
        public async Task AnEventBeforeTheWindow_IsKept()
        {
            var history = await SeedLinkedAsync("old", WindowStart.AddDays(-30));

            (await SyncAsync()).Should().BeTrue();

            (await Exists(history.Id)).Should().BeTrue("the list only covered the window, so its absence says nothing");
            _google.LookedUp.Should().BeEmpty();
        }

        [Fact]
        public async Task AnEventAfterTheWindow_IsKept()
        {
            // The calendar's month view revalidates just the month it shows.
            var nextMonth = await SeedLinkedAsync("later", WindowEnd.AddDays(20));

            (await SyncAsync()).Should().BeTrue();

            (await Exists(nextMonth.Id)).Should().BeTrue();
            _google.LookedUp.Should().BeEmpty();
        }

        [Fact]
        public async Task AnEventEndingExactlyAtTheWindowStart_IsKept()
        {
            // Google filters by end time > timeMin, exclusive.
            var ev = await SeedLinkedAsync("edge", WindowStart.AddHours(-1));

            (await SyncAsync()).Should().BeTrue();

            (await Exists(ev.Id)).Should().BeTrue();
            _google.LookedUp.Should().BeEmpty();
        }

        [Fact]
        public async Task ASeriesThatEndedBeforeTheWindow_IsKept()
        {
            var series = await SeedLinkedAsync(
                "finished-series", WindowStart.AddDays(-60), recurrenceRule: "RRULE:FREQ=DAILY;UNTIL=20260810T000000Z");

            (await SyncAsync()).Should().BeTrue();

            (await Exists(series.Id)).Should().BeTrue();
            _google.LookedUp.Should().BeEmpty();
        }

        [Fact]
        public async Task AnEventOnALaterPage_IsKeptAndUpdated()
        {
            // "The number of events in the resulting page may be less than this value, or none at
            // all, even if there are more events matching the query" — Events: list reference.
            var ev = await SeedLinkedAsync("paged", WindowStart.AddDays(3));
            _google.Pages.Clear();
            _google.Pages.Add(new List<object>());
            _google.Pages.Add(new List<object> { FakeGoogle.Item("paged", WindowStart.AddDays(3), "Renamed on Google") });

            (await SyncAsync()).Should().BeTrue();

            var stored = await _context.Events.AsNoTracking().SingleOrDefaultAsync(e => e.Id == ev.Id);
            stored.Should().NotBeNull();
            stored!.Title.Should().Be("Renamed on Google");
            _google.ListPageTokens.Should().Equal(null, "page-1");
        }

        // --- Events inside the window that Google did not list -----------------------------------

        [Fact]
        public async Task AnEventDeletedOnGoogle_IsRemoved()
        {
            var ev = await SeedLinkedAsync("gone", WindowStart.AddDays(2));
            _google.Lookups["gone"] = HttpStatusCode.NotFound;

            (await SyncAsync()).Should().BeTrue();

            (await Exists(ev.Id)).Should().BeFalse();
        }

        [Fact]
        public async Task AnEventGoogleNoLongerHasAtAll_IsRemoved()
        {
            var ev = await SeedLinkedAsync("purged", WindowStart.AddDays(2));
            _google.Lookups["purged"] = HttpStatusCode.Gone;

            (await SyncAsync()).Should().BeTrue();

            (await Exists(ev.Id)).Should().BeFalse();
        }

        [Fact]
        public async Task AnEventGoogleReportsCancelledWhenLookedUp_IsRemoved()
        {
            var ev = await SeedLinkedAsync("cancelled-on-lookup", WindowStart.AddDays(2));
            _google.CancelledOnLookup.Add("cancelled-on-lookup");

            (await SyncAsync()).Should().BeTrue();

            (await Exists(ev.Id)).Should().BeFalse();
        }

        [Fact]
        public async Task AnEventMovedOutOfTheWindowOnGoogle_IsKept_AtItsNewTime()
        {
            // Review round 1, R1: the lookup's answer was used for its status only, so the local copy
            // stayed at the old time, reminder included, and was looked up again on every sync.
            var ev = await SeedLinkedAsync("moved", WindowStart.AddDays(2));
            var newStart = WindowEnd.AddDays(20);
            _google.Found["moved"] = FakeGoogle.Item("moved", newStart, "Moved on Google");

            (await SyncAsync()).Should().BeTrue();

            var stored = await _context.Events.AsNoTracking().SingleAsync(e => e.Id == ev.Id);
            stored.StartTime.Should().Be(newStart);
            stored.Title.Should().Be("Moved on Google");

            _google.LookedUp.Clear();
            (await SyncAsync()).Should().BeTrue();
            _google.LookedUp.Should().BeEmpty("its stored time is outside the window now");
        }

        [Fact]
        public async Task ATentativeEvent_IsKept()
        {
            var ev = await SeedLinkedAsync("tentative", WindowStart.AddDays(2));
            _google.Found["tentative"] = FakeGoogle.Item("tentative", WindowStart.AddDays(2), status: "tentative");

            (await SyncAsync()).Should().BeTrue();

            (await Exists(ev.Id)).Should().BeTrue();
        }

        [Fact]
        public async Task AGoogleErrorWhileChecking_KeepsTheEvent_AndTheSyncCarriesOn()
        {
            var unsure = await SeedLinkedAsync("unsure", WindowStart.AddDays(2));
            var listed = await SeedLinkedAsync("listed", WindowStart.AddDays(4));
            _google.Lookups["unsure"] = HttpStatusCode.InternalServerError;
            _google.Pages[0].Add(FakeGoogle.Item("listed", WindowStart.AddDays(4), "Renamed on Google"));

            (await SyncAsync()).Should().BeTrue();

            (await Exists(unsure.Id)).Should().BeTrue("deleting on an error is how history was lost");
            (await _context.Events.AsNoTracking().SingleAsync(e => e.Id == listed.Id)).Title.Should().Be("Renamed on Google");
        }

        [Fact]
        public async Task ANetworkErrorWhileChecking_KeepsTheEvent_AndTheSyncCarriesOn()
        {
            // Review round 1, R2: only Google's own errors were caught, so a dropped connection
            // ended the sync before any listed change was applied.
            var unsure = await SeedLinkedAsync("offline", WindowStart.AddDays(2));
            var listed = await SeedLinkedAsync("listed", WindowStart.AddDays(4));
            _google.Unreachable.Add("offline");
            _google.Pages[0].Add(FakeGoogle.Item("listed", WindowStart.AddDays(4), "Renamed on Google"));

            (await SyncAsync()).Should().BeTrue();

            (await Exists(unsure.Id)).Should().BeTrue();
            (await _context.Events.AsNoTracking().SingleAsync(e => e.Id == listed.Id)).Title.Should().Be("Renamed on Google");
        }

        [Fact]
        public async Task AfterALookupFails_TheRestAreKeptWithoutAsking()
        {
            // The same failure would repeat for each, a timeout at a time.
            var first = await SeedLinkedAsync("first", WindowStart.AddDays(2));
            var second = await SeedLinkedAsync("second", WindowStart.AddDays(4));
            _google.Unreachable.Add("first");
            _google.Unreachable.Add("second");

            (await SyncAsync()).Should().BeTrue();

            _google.LookedUp.Should().HaveCount(1);
            (await Exists(first.Id)).Should().BeTrue();
            (await Exists(second.Id)).Should().BeTrue();
        }

        [Fact]
        public async Task ASeriesCancelledOnGoogle_TakesItsDaysWithIt_WhateverTheirDate()
        {
            // Review round 1, R3: the parent link is not cascaded, so a day outside the window lost
            // its series and stayed on the calendar as a one-off event.
            var series = await SeedLinkedAsync("series", WindowStart.AddDays(-60), recurrenceRule: "RRULE:FREQ=DAILY");
            var editedDay = await SeedLinkedAsync("series_20260710T000000Z", WindowStart.AddDays(-50), parentId: series.Id);
            var localOnlyDay = await SeedLinkedAsync(null, WindowStart.AddDays(-40), parentId: series.Id);
            _google.Pages[0].Add(FakeGoogle.Item("series", WindowStart.AddDays(-60), status: "cancelled"));

            (await SyncAsync()).Should().BeTrue();

            (await Exists(series.Id)).Should().BeFalse();
            (await Exists(editedDay.Id)).Should().BeFalse();
            (await Exists(localOnlyDay.Id)).Should().BeFalse();
            _google.LookedUp.Should().BeEmpty();
        }

        [Fact]
        public async Task AnOpenEndedSeriesThatBeganBeforeTheWindow_IsCheckedAndRemovedWhenGone()
        {
            // Its first day is outside the window, but its later days are inside, so Google should
            // have listed it: it is a candidate, and the lookup decides.
            var series = await SeedLinkedAsync("series", WindowStart.AddDays(-60), recurrenceRule: "RRULE:FREQ=DAILY");
            _google.Lookups["series"] = HttpStatusCode.NotFound;

            (await SyncAsync()).Should().BeTrue();

            (await Exists(series.Id)).Should().BeFalse();
        }

        [Fact]
        public async Task AnEventListedAsCancelled_IsRemovedWithoutALookup()
        {
            var ev = await SeedLinkedAsync("listed-cancelled", WindowStart.AddDays(2));
            _google.Pages[0].Add(FakeGoogle.Item("listed-cancelled", WindowStart.AddDays(2), status: "cancelled"));

            (await SyncAsync()).Should().BeTrue();

            (await Exists(ev.Id)).Should().BeFalse();
            _google.LookedUp.Should().BeEmpty();
        }

        [Fact]
        public async Task TheDefaultWindow_KeepsLastMonthsHistory()
        {
            // The webhook and the manual sync pass no window: -7 to +14 days from now.
            var history = await SeedLinkedAsync("last-month", DateTime.UtcNow.AddDays(-30));

            var before = DateTime.UtcNow;
            (await _service.SyncEventsAsync(UserId, "refresh-token", null, null, CancellationToken.None))
                .Should().BeTrue();

            (await Exists(history.Id)).Should().BeTrue();
            _google.LookedUp.Should().BeEmpty();
            var list = _google.ListQueries.Single();
            DateTimeOffset.Parse(list["timeMin"]!).UtcDateTime.Should().BeCloseTo(before.AddDays(-7), TimeSpan.FromMinutes(1));
            DateTimeOffset.Parse(list["timeMax"]!).UtcDateTime.Should().BeCloseTo(before.AddDays(14), TimeSpan.FromMinutes(1));
        }

        [Fact]
        public async Task TheListAsksForTheWindow_WithDeletedEvents_AndSeriesUnexpanded()
        {
            // Deleted events are what step 1 and step 4 act on, and an expanded list would have no
            // series to match the local ones against.
            (await SyncAsync()).Should().BeTrue();

            var list = _google.ListQueries.Single();
            DateTimeOffset.Parse(list["timeMin"]!).UtcDateTime.Should().Be(WindowStart);
            DateTimeOffset.Parse(list["timeMax"]!).UtcDateTime.Should().Be(WindowEnd);
            list["showDeleted"].Should().Be("true");
            list["singleEvents"].Should().Be("false");
        }

        [Fact]
        public async Task ARepeatedPageToken_EndsTheListing()
        {
            // Review round 1, R6: nothing stopped the loop, and the real callers cannot cancel it.
            _google.RepeatToken = true;

            (await SyncAsync()).Should().BeTrue();

            _google.ListQueries.Should().HaveCount(2);
        }

        // --- Test doubles ------------------------------------------------------------------------

        private sealed class TestableGoogleCalendarService : GoogleCalendarService
        {
            private readonly FakeGoogle _google;

            public TestableGoogleCalendarService(
                EventRepository repository, IConfiguration configuration, FakeGoogle google)
                : base(repository, configuration)
            {
                _google = google;
            }

            protected override Task<CalendarService> GetCalendarServiceAsync(
                string userId, string refreshToken, CancellationToken cancellationToken) =>
                Task.FromResult(new CalendarService(new BaseClientService.Initializer
                {
                    ApplicationName = "tests",
                    HttpClientFactory = new FakeHttpClientFactory(_google),
                }));
        }

        private sealed class FakeHttpClientFactory : HttpClientFactory
        {
            private readonly HttpMessageHandler _handler;

            public FakeHttpClientFactory(HttpMessageHandler handler) => _handler = handler;

            protected override HttpMessageHandler CreateHandler(CreateHttpClientArgs args) => _handler;
        }

        /// <summary>Answers Events: list page by page, and Events: get per id.</summary>
        private sealed class FakeGoogle : HttpMessageHandler
        {
            private const string EventsPath = "/calendar/v3/calendars/primary/events";

            /// <summary>One entry per list page; the default is a single empty page.</summary>
            public List<List<object>> Pages { get; } = new() { new List<object>() };

            /// <summary>Status returned for a lookup; ids not in here exist (200, confirmed).</summary>
            public Dictionary<string, HttpStatusCode> Lookups { get; } = new();

            public HashSet<string> CancelledOnLookup { get; } = new();

            /// <summary>What a lookup returns for an id, instead of a confirmed event in the window.</summary>
            public Dictionary<string, object> Found { get; } = new();

            /// <summary>Ids whose lookup fails before Google answers, as a dropped connection does.</summary>
            public HashSet<string> Unreachable { get; } = new();

            /// <summary>Answer every list page with the same token.</summary>
            public bool RepeatToken { get; set; }

            public List<string> LookedUp { get; } = new();
            public List<string?> ListPageTokens { get; } = new();
            public List<System.Collections.Specialized.NameValueCollection> ListQueries { get; } = new();

            public static object Item(string id, DateTime start, string? summary = null, string status = "confirmed") => new
            {
                id,
                status,
                summary = summary ?? id,
                start = new { dateTime = start.ToString("yyyy-MM-ddTHH:mm:ssZ") },
                end = new { dateTime = start.AddHours(1).ToString("yyyy-MM-ddTHH:mm:ssZ") },
            };

            protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
            {
                var uri = request.RequestUri!;
                if (uri.AbsolutePath == EventsPath)
                {
                    var query = System.Web.HttpUtility.ParseQueryString(uri.Query);
                    var token = query["pageToken"];
                    ListPageTokens.Add(token);
                    ListQueries.Add(query);
                    if (RepeatToken)
                    {
                        return Json(HttpStatusCode.OK, new { kind = "calendar#events", items = new List<object>(), nextPageToken = "page-0" });
                    }

                    var index = token == null ? 0 : int.Parse(token["page-".Length..]);
                    var next = index + 1 < Pages.Count ? $"page-{index + 1}" : null;
                    return Json(HttpStatusCode.OK, new { kind = "calendar#events", items = Pages[index], nextPageToken = next });
                }

                if (uri.AbsolutePath.StartsWith(EventsPath + "/"))
                {
                    var id = Uri.UnescapeDataString(uri.AbsolutePath[(EventsPath.Length + 1)..]);
                    LookedUp.Add(id);
                    if (Unreachable.Contains(id))
                    {
                        throw new HttpRequestException("No connection.");
                    }

                    if (Found.TryGetValue(id, out var item))
                    {
                        return Json(HttpStatusCode.OK, item);
                    }

                    if (Lookups.TryGetValue(id, out var status))
                    {
                        return Json(status, new { error = new { code = (int)status, message = status.ToString() } });
                    }

                    var found = Item(id, WindowStart, status: CancelledOnLookup.Contains(id) ? "cancelled" : "confirmed");
                    return Json(HttpStatusCode.OK, found);
                }

                throw new InvalidOperationException($"Unexpected request to Google: {request.Method} {uri}");
            }

            private static Task<HttpResponseMessage> Json(HttpStatusCode status, object body) =>
                Task.FromResult(new HttpResponseMessage(status)
                {
                    Content = new StringContent(JsonSerializer.Serialize(body), Encoding.UTF8, "application/json"),
                });
        }
    }
}
