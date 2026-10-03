# Code review: `feat/home-page`

Base: `0347d45` (local `main`, merge of PR #24) · Reviewed by: Claude Code (5 parallel reviewers + consolidating verification pass)

| Round | Commit | Date | Outcome |
| --- | --- | --- | --- |
| 1 | `28b3568` fix(events): per-day tasks and completion (5 commits) | 2026-09-11 | 1 HIGH, 4 MEDIUM, 12 LOW, 9 INFO — **blocks merge** |
| 2 | `867cc20` fix(events): address review round 1 | 2026-09-11 | HIGH and 3 MEDIUM closed, 1 MEDIUM half-closed (integration tests); LOWs open; new: 1 LOW, 2 INFO — **no HIGH; one MEDIUM half-open** |

> Base is local `main`, not `origin/main`: the remote was unreachable from this network
> (`git fetch` timed out on port 443). Local `main` is the PR #24 merge pulled on 2026-09-10,
> and `git log main..HEAD` shows exactly the 5 commits of this branch, so the diff is the
> branch's real scope.

---

# Round 2 — review `867cc20`

Fixes for round 1's HIGH and four MEDIUMs, in one commit on top of `94ed6d4`. The LOW findings
were not in scope for this round; the few that changed are noted in the table.

## Status of round 1 findings

| # | Finding | Status |
| --- | --- | --- |
| 1 | [HIGH] A split-off day shows twice after the series is edited | ✅ **Closed** — unit tests, negative control, live on :5099 |
| 2 | [MEDIUM] Inbound sync deletes an edited day whose Insert is queued | ✅ **Closed** — the decision is unit-tested with a negative control; the sync call site was not run against Google |
| 3 | [MEDIUM] "All" / "this and future" on a Google-known day never pushes it | ✅ **Closed** — unit tests, negative control |
| 4 | [MEDIUM] Activity card counts rows, not scheduled days | ✅ **Closed** — unit and widget tests, negative control, live |
| 5 | [MEDIUM] Google-connected and failure paths untested | ⚠️ **Half-closed** — the listed tests exist and the key survivors are now caught; repository SQL and the inbound sync path still have no integration test |
| 6 | [LOW] Every Home fetch starts a Google sync | ⚠️ Still open |
| 7 | [LOW] Dead-lettered Insert counts as pending | ⚠️ Still open |
| 8 | [LOW] Details dialog acts on the series after a tick | ⚠️ Still open |
| 9 | [LOW] Edit sheet ticks the series template | ⚠️ Still open |
| 10 | [LOW] No unique index on split-off days | ⚠️ Still open (needs a migration) |
| 11 | [LOW] Toast titled with the raw key `error` | ⚠️ **Half-closed** — fixed at the site this branch added; the 4 pre-existing sites remain |
| 12 | [LOW] XP farming through arbitrary dates | ⚠️ Still open |
| 13 | [LOW] Rule violations return 404 | ⚠️ Still open |
| 14 | [LOW] "Update calendar" on a series day never reaches Google | ⚠️ Still open |
| 15 | [LOW] The same rules written in several places | ⚠️ **Half-closed** — the exception list has one reader/writer (`RecurrenceExceptions`) and `Delete` uses `IsSeries`; scope/outbox literals and the SQL `interval '7 hours'` remain |
| 16 | [LOW] Docs out of date | ⚠️ **Half-closed** — `CLAUDE.md` fixed; `notifications-and-reminders.md`, the expander comment and the two unused keys remain |
| 17 | [LOW] Weak and clock-dependent assertions | ⚠️ Still open (the one vacuous `Times.Never` test in finding 5 is fixed) |

### Finding 1 — closed: touched days follow the series

The fix uses a rule the design already guaranteed and nothing used: a day split off locally is
never in the series' `RecurrenceExceptionDates`, and an edited, promoted or deleted day always is.
`OccurrenceMaterializer.IsLocalOnlyDay` reads it.

`UpdateEventCommandHandler.FollowSeriesAsync` (called from `UpdateWholeEventAsync` for a series,
and from `SplitSeriesAsync`) applies a series edit to every local-only child: the same shift in
time of day (`TimeOfDayShift`, which ignores the date and takes the short way across midnight),
title, category, habit, reminders and length, and `ExceptionDate` moves with it. For "this and
future", children from the split date on are re-parented to the new series. Edited days are
skipped. A day the series no longer produces after the edit (before its new start) is left as
history.

| Before | After |
| --- | --- |
| Wednesday 07:00 "Jog" **and** 08:00 "Jog (renamed)" — two reminders | Wednesday 08:00 "Jog (renamed)" only |

Measured:
- `AllOccurrences_TouchedDaysFollowTheSeries_EditedDaysKeepTheirOwn`: the touched Friday moves
  10:00 → 11:00 with the new title and a 90-minute length; the edited Thursday keeps 15:00 and
  "Moved by hand"; Monday, now before the series' start, stays as history.
- `ThisAndFuture_TouchedDaysAfterTheSplitMoveToTheNewSeries`: Friday joins the new series, Monday
  stays with the old one.
- Negative control: skipping `FollowSeriesAsync` fails the first test.
- Live on :5099 against the real database (throwaway account, deleted afterwards): tomorrow split
  off, series moved 10:00 → 11:00 with "all occurrences" from today →
  `tomorrow moved to 11:00 (2026-09-12T11:00:00Z)`, `exceptionDate` follows, new title, and it is
  still not in the series' exception list.

### Finding 2 — closed: sync can't delete an edited day any more

`FindLocalOnlyDay` now takes the series and also requires `IsLocalOnlyDay`. In
`GoogleCalendarService`, it is called once per exception, **before** the cancelled branch appends
the date — afterwards every day on that date would look edited. The non-cancelled (adopt) branch
uses the same lookup, so an edited day waiting for its Insert is not adopted either.

- `FindLocalOnlyDay_IgnoresAnEditedDayWaitingForItsInsert`: a child without `GoogleEventId` whose
  date is in the exception list → not found.
- Negative control: dropping the `IsLocalOnlyDay` condition fails that test.
- Not run: the sync call site itself, which needs Google. The ordering is by reading the code;
  finding 5's integration-test gap still applies here.

### Finding 3 — closed: the day is pushed too

In `UpdateSplitOffDayAsync`'s "all / this and future" branch, when Google has the day (or the day
was edited), its new slot is added to the holding series' exception list, and both the series
(with exceptions) and the day are queued as Updates. A local-only day still sends nothing.

- `AllOccurrences_FromAGoogleKnownDay_PushesThatDayToo` and
  `AllOccurrences_FromALocalOnlyDay_SendsNothingForTheDay`.
- Negative control: removing the push fails the first.

### Finding 4 — closed: the card counts days

The SQL now counts scheduled/completed for one-off events only
(`"ParentEventId" IS NULL AND COALESCE("RecurrenceRule", '') = ''`); focus minutes still come
from every row. The fields are renamed `oneOffScheduled` / `oneOffCompleted`, so the contract says
what it counts. The client adds repeating days in `ActivitySummary.withRepeatingDays`, expanding
every series over the 14-day window with `EventOccurrenceExpander` — split-off days stand in for
the days they replace, deleted days drop out. It needs no extra request: `GetEventsForUserAsync`
returns every series and every child whatever the date range (`EventRepository.cs:94-97`).

| Before | After |
| --- | --- |
| 7 days of a daily habit, 3 done → "3 of 3 · 100%" | "3 of 7 · 43%" |

- 6 unit tests on `withRepeatingDays` (every day counted; 3 of 7; a moved split-off day counted
  once on its own day; merged with one-off counts, focus untouched; deleted and non-rule days
  skipped; one-off events not counted twice) and a card test (`1 of 3 · 33%`).
- Negative control: returning the server numbers unchanged fails 6 tests.
- Live: the wire now carries `oneOffScheduled`/`oneOffCompleted`, and with a series, a split-off
  day and one one-off event, `totalOneOffScheduled` is 1.

### Finding 5 — half-closed: the gaps the mutation run found

Added: Google-connected "edit this occurrence" (untouched day → `[series/Update, day/Insert]` in
that order; Google-known day → Update, no Insert; queued Insert → Update); per-day reminders with
and without a value sent; deleting a Google-known day sends exactly one Delete;
`MaterializeOccurrenceCommandHandler` (own series, another user's series writes nothing, missing,
no user); a normal Google-known event still gets its Update on completion, and the existing
`Times.Never` test now asserts the handler got that far; endpoint mapping tests
(`EventsEndpointMappingTests`) including a reflection check that fails when a command gains a
field its request record lacks; client wire tests for `completeSession` and
`materializeOccurrence`; the checklist when the split is refused.

Round 1 survivors, re-run as mutations in this round:

| Mutation | Round 1 | Round 2 |
| --- | --- | --- |
| Insert and Update swapped (`UpdateEventCommand`) | survived | **caught** (3 tests) |
| JSON key `occurrenceStart` renamed (`api_service.dart`) | survived | **caught** |
| Endpoint drops `ReminderMinutesBefore` (the original bug) | not tested | **caught** |
| Checklist toast key | — | **caught** |

The other survivors (M1, M4, M5, M7, M13, F8) each have a test aimed at them now; those mutations
were not re-run. The reflection check's "field missing from the record" case holds by
construction and was not run as a mutation. Still missing: an integration test project for the
repository SQL (`GetDailyActivityAsync`, `GetOccurrenceChildAsync`, `GetChildrenAsync`,
`HasPendingInsertAsync`) and for the inbound sync path.

## New findings

### N1 [LOW] Changing the repeat rule leaves touched days on days the new rule skips

*Introduced in round 2.* `FollowSeriesAsync` shifts local-only days but does not check them
against the new rule. Changing a daily series to weekdays only leaves a touched Saturday in
place, now a standalone event on a day the series no longer has. The server has no recurrence
engine to check with. Rare (it needs a rule change after days were touched ahead). **Fix
options:** on a rule change, leave future local-only days to the client to hide, or delete those
that no longer fall on a produced weekday for `WEEKLY;BYDAY` rules.

### N2 [INFO] Dashboard days: server by UTC+7, client by device-local day

*Introduced in round 2.* One-off counts are grouped by the server's UTC+7 day, repeating days by
the device's local day. Identical for users in UTC+7; elsewhere a late-evening day can land one
day apart in the two halves. This is the same seam as roadmap 5.1 (a fixed day boundary for
streaks).

### N3 [INFO] `dotnet test` now builds `Web`

*Introduced in round 2.* The test project references `Web` for the mapping tests, so a plain
`dotnet test` fails with MSB3027 while a backend started from `src/Web` holds its files. Documented
in `CLAUDE.md`: use `dotnet test -o <dir>` or stop the backend. CI is unaffected.

## Round 2 verification

| Item | Round 1 | Round 2 |
| --- | --- | --- |
| `dotnet test` (Application.UnitTests) | 99 pass / 0 fail | **132 pass / 0 fail** (built with `-o`; a backend held `src/Web/bin` earlier in the session) |
| `flutter test` | 172 pass / 0 fail | **183 pass / 0 fail** |
| `flutter analyze` | No issues | No issues |
| `dotnet build` (Web, separate output) | 0 errors | 0 errors |
| Codegen | current | no annotated provider touched; no `*.g.dart` change |
| Negative controls, server | 6 caught | + 5: follow-series, `FindLocalOnlyDay` rule, day push, Insert/Update swap, endpoint mapping — all caught |
| Negative controls, client | 3 caught | + 3: repeating-day counting, toast key, JSON key — all caught |
| Live on :5099 | 17 / 17 | **8 / 8 new + 17 / 17 round 1 re-run**; probe accounts deleted |
| E2E, iOS | not run | not run |

---

# Round 1 — review `28b3568`

Kept as the record.

## How this round was run

Five reviewers ran in parallel, one lens each: correctness (bug hunt), security, API/data
contracts, test coverage, and project conventions. Each was told to measure rather than infer,
and to label every finding "introduced" or "pre-existing" by checking against `main`.

Their output was not taken at face value. Every finding below was re-checked in this pass —
reproduced, or confirmed in the code. Findings that did not survive are listed under
"Rejected or downgraded". One correction to the reviewers' evidence: some of them ran `psql`
inside the Docker container without `-h`, which queries the restored dump on port 5433, not
the database the app uses (native Postgres on 5432). Findings resting only on that data were
re-checked against 5432.

## Scope

5 commits, 63 files (excluding generated `*.g.dart`), +5316 / −589.

| Area | Files | Change |
| --- | --- | --- |
| Tooling | `.gitattributes` | +15 — pins `*.dart` and the desktop plugin registrants to LF |
| Home screen | `apps/lib/features/home/**` (10 files), `app_router.dart`, `calendar_screen.dart`, `calendar_toolbar.dart`, `command_center_panel.dart` (deleted) | New landing tab; up-next / later today / unbooked habits / activity card; command-centre panel removed from the calendar |
| Fetch range | `events_provider.dart` (`eventsFetchRange`), `app_constants.dart` | `eventsProvider` always includes now −1 day .. now +8 days |
| Dashboard | `GetActivitySummaryQuery.cs`, `EventRepository.GetDailyActivityAsync`, `Analytics.cs`, `DailyActivity.cs`, `activity_summary*.dart` | `GET /analytics/summary`, raw-SQL `GROUP BY`, 14-day card |
| Login | `login_screen.dart`, `app_constants.dart` | Lands on `/home` (`AppConstants.landingRoute`) |
| Per-day state | `OccurrenceMaterializer.cs`, `MaterializeOccurrenceCommand.cs`, `GoogleSyncGuard.cs`, `UpdateEventCommand.cs` (+297/−136), `DeleteEventCommand.cs`, `CompleteEventSessionCommand.cs`, `ToggleEventCommand.cs`, `GoogleCalendarService.cs`, `event_occurrence.dart`, `event_tasks_checklist.dart`, `calendar_event_data_source.dart`, `event_occurrence_expander.dart`, `post_session_dialog.dart` | Split one day off a series into its own event with a copy of the tasks; local-only until edited |
| Endpoint fix | `Web/Endpoints/V1/Events.cs` | `UpdateEventRequest` gains `ReminderMinutesBefore` |
| Tests | 20 test files (+2,700 lines) | See verification |

## Parts verified as correct

### Ownership on every new write path
`MaterializeOccurrenceCommand.cs:41` rejects `series.UserId != request.UserId`. The new child
path in `UpdateEventCommand.cs:111-113` and `DeleteEventCommand.cs:64-67` checks the parent's
owner before touching it. `userId` comes only from the token on both new endpoints. The security
reviewer checked the local data: 4 child rows, 0 whose owner differs from its parent, 0 orphans.
Children can't be created from the client with an arbitrary `ParentEventId`
(`CreateEventCommand` does not accept one).

### The dashboard SQL is parameterised and scoped
`EventRepository.cs:56-71` uses `Database.SqlQuery<T>(FormattableString)`, so `{userId}`,
`{fromUtc}` and `{toUtc}` are sent as parameters, not concatenated. `RequireAuthorization()` is
on the group, and `days` is clamped to 1..90. The plan is a real `HashAggregate` (measured in
the earlier session), not an in-memory group.

### Wire contracts match on both sides
All request and response shapes were checked field by field by the contracts reviewer:
`ActivitySummaryDto`/`ActivitySummary.fromJson` (9 keys), `Ok<Guid>` as a bare JSON string,
`occurrenceStart` omitted when null, and `UpdateEventRequest`'s 10 fields against the 10 keys
the client sends. `DailyActivity` is not mapped by EF (`FindEntityType` returns false; no
migration or snapshot change).

### The core fix does what it claims
Measured live in the previous session against a real server and database (17 checks), then
spot-checked here: ticking a task on one day does not tick it on the next day or on the series
template; completing a session completes that day only; the series refuses to be completed
whole; "update calendar" resizes only that day. Reminder edits reach the database on this
branch and are dropped on `main`:

| Server | Asked for | Stored |
| --- | --- | --- |
| `main` (:5000) | `[60]` | `[15]` — dropped |
| this branch (:5099) | `[60]` | `[60]` — saved |

### Structure that holds up
- The delete recursion into the parent is one level deep: it only recurses when
  `parent.ParentEventId == null`, and a nested child falls through to a plain delete.
- The materializer running inside `CompleteEventSession`'s transaction joins it
  (`UnitOfWork.cs:27-30`), so a new day rolls back with the XP and streak writes.
- `SplitSeriesAsync` and `UpdateWholeEventAsync` are behaviour-identical to the branches they
  were extracted from (diffed against `git show main:…/UpdateEventCommand.cs`).
- Riverpod 3.2.1 keeps the notifier instance across `invalidateSelf`, so the in-flight dedupe
  map in `EventsNotifier.materializeOccurrence` survives the reload it triggers.
- Inbound sync's non-cancelled branch adopts a local-only day instead of inserting a second
  one — that closes a duplicate `main` had.

## Round 1 findings

### 1 [HIGH] A split-off day keeps a frozen copy of the series, so editing the series shows that day twice

*Introduced.* `server/src/Application/Features/Events/Commands/UpdateEventCommand.cs:259-300`
(`UpdateWholeEventAsync` changes the series row only) and `:200-257` (`SplitSeriesAsync`
re-parents nothing). `OccurrenceMaterializer.cs:92-130` copies title, time, category and
reminders into the child. The client hides a series day only when a child's `exceptionDate`
matches it to the minute (`event_occurrence_expander.dart:112-127`).

Every ticked task or finished session now creates such a child, and nothing marks it as
"only touched, not edited". So when the series is later moved (07:00 → 08:00) with "all
occurrences" from another day, the child stays at 07:00 with the old title, and the series'
08:00 day is no longer hidden. Reproduced with the real expander and reminder planner:

```
Wednesday -> jog-wed  "Jog" at 2026-09-16 07:00:00.000
Wednesday -> jog      "Jog (renamed)" at 2026-09-16 08:00:00.000
Wednesday reminders -> [jog-wed@6:45, jog@7:45]
```

"This and future" has the same effect: children after the split stay attached to the old
series (now ending before them), and the new series draws those days again.

Impact: every user who ticks a task ahead of time, or has a touched day after the edit point,
gets duplicate events on Home and in the widgets, and **two reminders at different times**.
The roadmap (5.6c) recorded "stays at the old time" but missed the duplicate.

**Fix:** no new column is needed — the design already has the discriminator. A day split off
locally is never in the series' `RecurrenceExceptionDates`; an edited or promoted day always is.
So:
- In `UpdateWholeEventAsync` (series target), for each child whose `ExceptionDate` is *not* in
  the series' exception dates: apply the series' title, category, habit, reminders and duration,
  shift its time by the same time-of-day delta, and move `ExceptionDate` with it.
- In `SplitSeriesAsync`, re-parent such children at or after the split date to the new series,
  with the same shift.
- Add tests for both, with a second touched day that is *not* the edited one.

### 2 [MEDIUM] An inbound sync can delete a day the user just edited, with its tasks

*Introduced.* `server/src/Infrastructure/Services/GoogleCalendarService.cs:224-231`, using
`OccurrenceMaterializer.FindLocalOnlyDay` (`OccurrenceMaterializer.cs:142-151`).

`FindLocalOnlyDay` treats "has a parent, no `GoogleEventId`" as "Google never heard of it". That
is also the state of an *edited* day whose Insert is still queued. Editing one occurrence queues
[master Update, day Insert]; `PushUpdateAsync` (`GoogleCalendarService.cs:413-431`, confirmed)
cancels the Google instance for every exception date. From then until the Insert saves its
`GoogleEventId`, every sync takes the new cancelled branch, matches the edited day, and deletes
it — tasks, completion and habit link included. If the Insert fails for good, this repeats on
every sync. On `main`, that branch only deleted a row whose `GoogleEventId == ge.Id`.

Not reproduced live (needs a Google account); the mechanism is confirmed in the code on both
sides.

**Fix** (from the bug hunt, and consistent with the invariant in finding 1): compute
`dayWasAlreadyExcluded = localMaster.RecurrenceExceptionDates?.Contains(originalDateStr)` before
the branch appends the date, and only delete the local-only match when it was *not* already
excluded. Add a sync test for "cancelled instance + child whose Insert is pending".

### 3 [MEDIUM] "All occurrences" / "this and future" on a Google-known day never pushes that day

*Introduced — a regression against `main`.* `UpdateEventCommand.cs:115-130`.

The new branch updates the series (which pushes the series), re-anchors the day and returns —
without queueing anything for the day. On `main`, any update of a child went through the plain
branch and queued an `Update` with its `GoogleEventId`. An edited day exists in Google as its
own event, so after this change Google keeps it at the old time while the series gains an
uncancelled instance on the same date: two events in Google, one in the app.

**Fix:** after re-anchoring, if `GoogleSyncGuard.GoogleKnowsAsync(day)`, add the new slot to
the series' exception dates, then `EnqueueMasterWithExceptionsAsync(series)` and
`EnqueueUpdateAsync(day)`. Add a test next to `AllOccurrences_FromASplitOffDay_…` with
`GoogleEventId` set.

### 4 [MEDIUM] The activity card counts stored rows, not scheduled days, so its completion rate is inflated

*Introduced with the feature.* `EventRepository.cs:62-68`; `DailyActivity.cs:23` documents
`Scheduled` as "events starting on this day"; the client's `completionRate`
(`activity_summary.dart:56`).

A series is one row whose `StartTime` is its first day, so it counts once, on that day, and
never again. Each touched day adds a row of its own. The effect is worse than the roadmap note
(2.0) says: completed days are always touched (completing splits the day off), but scheduled
days that nobody touched are not counted at all. So the rate drifts towards 100% — "3 of 3"
where the truth is "3 of 7". A user whose events are all repeating and untouched sees the empty
state.

**Fix options**, to decide:
- Cheapest and honest: exclude series rows from the counts
  (`NOT ("RecurrenceRule" <> '' AND "ParentEventId" IS NULL)`), and replace "x of y · rate" with
  "x completed" until scheduled days can be counted properly.
- Proper: count scheduled occurrences — a recurrence engine on the server (e.g. Ical.Net), or
  a client-side count over a fetched 14-day window.

### 5 [MEDIUM] The Google-connected paths and the failure paths are not tested

*Introduced; project rule 11.* The test-coverage reviewer ran mutations on a scratch copy of the
code (not the repository). These deliberate breaks left **every test green**:

| Line broken | Consequence no test catches |
| --- | --- |
| `UpdateEventCommand.cs:185` — Insert and Update swapped for an edited occurrence | duplicate or lost event in Google |
| `UpdateEventCommand.cs:139` — no Update for a day Google already has | edit never reaches Google |
| `UpdateEventCommand.cs:173` — per-day reminders ignored | the #24 feature silently breaks |
| `GoogleSyncGuard.cs:30` — queued Insert ignored | the "Insert still pending" branch is never true in any test |
| `CompleteEventSessionCommand.cs:119` — never push to Google | "update calendar" stops reaching Google for normal events |
| `DeleteEventCommand.cs:104` — no Delete for a day Google has | deleted day stays in Google |
| `MaterializeOccurrenceCommand.cs:41` — ownership check removed | splitting another user's series |
| `api_service.dart:148` — JSON key `occurrenceStart` renamed | completing a series day returns 404 |
| `event_tasks_checklist.dart:73` — catch rethrows | an error toast is never checked |

`Handle_DoesNotQueueAGoogleUpdate_ForADayGoogleNeverSaw` also passes vacuously when the handler
fails early: it asserts `Times.Never` without checking the result.

Findings 2 and 3 sit exactly in this untested area, which is the evidence that the gap matters.

**Fix:** add, at minimum:
- `OccurrenceEditAndDeleteTests`: Google-connected "edit this occurrence" (untouched day →
  `[series/Update, day/Insert]`; Google-known day → `day/Update`, no Insert; pending Insert →
  Update); per-day reminders kept; deleting a Google-known day queues exactly one Delete.
- `MaterializeOccurrenceCommandHandler` tests: another user's series, missing series, own series.
- `CompleteEventSession`: a normal Google-known event queues its Update; assert `result` in the
  `Times.Never` test.
- Endpoint mapping: call `Events.UpdateEvent` / `CompleteSession` directly with a mocked
  `ISender` and assert the command fields — this would have caught the dropped reminders.
- Client: Dio-interceptor tests for `completeSession` (body has `occurrenceStart` in UTC, no
  key when null) and `materializeOccurrence`; a checklist test where materialize throws a 404.

### 6 [LOW] Every events fetch from Home starts a Google sync

*Introduced.* `events_provider.dart` (`eventsFetchRange`); the cache check is
`GoogleCalendarSyncCacheRepository.cs:33-36` (`SyncedTo >= endTime`).

The window's end is `now + 8 days`, so it moves forward every second and every fetch misses the
server's 1-minute sync cache. `GetEventsQuery.cs:62-83` then starts a background Google List.
On `main`, Home sent no range, and the server never ran that sync. Checked for the worst case:
the background revalidation does **not** publish `CalendarUpdatedEvent` (only
`SyncGoogleCalendarCommand.cs:74` does), so there is no refetch loop — one extra Google call per
fetch.

**Fix:** snap the window to whole days (`DateTime(now.year, now.month, now.day)` ± the window),
and add a test that two calls seconds apart return the same range.

### 7 [LOW] An Insert that failed for good counts as "pending" forever

*Introduced.* `GoogleCalendarOutboxRepository.cs:53` checks `ProcessedAt == null`; the worker
gives up at `RetryCount >= 5` without setting it (`:44`, confirmed). `GoogleKnowsAsync` then stays
true, so later edits queue Updates that fail five times each, and promotion is never retried.
Rare precondition (an Insert has to fail five times).

**Fix:** add `&& x.RetryCount < MaxRetries`, one constant shared with `GetUnprocessedAsync`.

### 8 [LOW] After ticking a task in the details dialog, its Delete and "this and future" still target the series day

*Introduced.* `event_details_dialog.dart:70,112-167`; `DeleteEventCommand.cs:130-161`.

The dialog holds the series-day snapshot. Ticking a task inside it splits the day off, but the
dialog's buttons still send the series id. "Delete this occurrence" then adds the exception date
and leaves the new child on the calendar, after showing "Event deleted". "This and future"
leaves the child on the old series, so that day shows twice.

**Fix:** resolve it once on the server: for a series request with `OriginalOccurrenceDate`, look
up `GetOccurrenceChildAsync` first and, if a child exists, handle the request as the child. This
also makes every other stale client reference safe.

### 9 [LOW] The edit sheet still ticks the series' shared task list

*Introduced (incomplete fix).* `create_event_sheet.dart:488-489` → `event_tasks_editor.dart:174`
(confirmed). For a series day the editor gets the series id, and its checkboxes toggle the
template. The checklist now ignores template ticks, but the editor shows them on every day.

**Fix:** hide the checkboxes in the editor when editing a series day — there the list is a
template.

### 10 [LOW] Splitting off a day is check-then-insert with no unique index

*Introduced (the invariant now matters); duplicate data is pre-existing.*
`OccurrenceMaterializer.cs:87-130`. Indexes on `Events` (checked on 5432): `PK_Events`,
`IX_Events_UserId`, `IX_Events_CategoryId`, `IX_Events_ParentEventId` — none unique. The
database already holds a triple duplicate from `main`'s "edit this occurrence":

```
 parent   |     ExceptionDate      | count
 da2c839d | 2026-12-05 14:00:00+07 |     3
```

The client dedupes taps; two devices or a split-off overlapping a session completion can still
race. **Fix:** clean up duplicates, then a partial unique index on
(`ParentEventId`, minute of `ExceptionDate`) where `ParentEventId IS NOT NULL`; on `23505`,
re-read the existing child. Needs a migration, so it can be its own PR.

### 11 [LOW] The checklist's error toast is titled with the raw key `error`

*1 of 5 sites introduced.* `event_tasks_checklist.dart:76`. The key is `error_title`
(`locale_provider.dart:754`); `'error'` does not exist, so the title reads "error" in both
languages. The other 4 sites (`calendar_workspace.dart:274,313`, `create_event_sheet.dart:403`,
`event_details_dialog.dart:181`) are pre-existing. Separately, when `copiedTaskFor` finds no
copy (`:67`), the tick is dropped with no message. **Fix:** `error_title` at all 5 sites, and a
toast for the no-copy case.

### 12 [LOW] XP can be farmed through arbitrary occurrence dates

*The path is introduced; the capability is pre-existing.* `OccurrenceMaterializer.cs:153-161`
does not check a date against the repeat rule (documented), and there is no upper bound without
`UNTIL`. Each `complete-session` with a new `occurrenceStart` (09:00, 09:01, …) creates a new day
and awards XP, including squad XP. On `main` the same is possible with create → complete →
delete (delete never refunds, no rate limiting anywhere). Only the caller's own and their squads'
totals are affected.

**Fix:** accept completion only within a window around now (e.g. ±1 day); refund `AwardedXp` on
delete; consider a rate limit on the events group.

### 13 [LOW] Rule violations return 404

*Introduced.* `CompleteEventSessionCommand.cs:78`, `ToggleEventCommand.cs:50` and the
materialize handler return `false`/`null`, mapped to `NotFound` (`Events.cs:64,80,99`). An old
app build finishing a session on a series gets "Not Found" and loses the focus time. Rejecting
is right — the old behaviour was the bug — only the status is misleading. **Fix:** 422 with a
code such as `occurrence_required`.

### 14 [LOW] "Update calendar" on a series day never reaches Google

*Introduced.* `CompleteEventSessionCommand.cs:97-103,119`. The child is local-only, so
`GoogleKnowsAsync` is false and the resize stays in the app; a later Google change to that day
overwrites it. **Fix:** when `UpdateCalendar` is set on a local-only day, promote it as
`UpdateSplitOffDayAsync` already does.

### 15 [LOW] The same rules are written in several places

*Introduced (adds to an existing pattern); project rules 3–4.* The exception-date append and
the Google payloads are extracted into helpers in `UpdateEventCommand` but written again inline
in `DeleteEventCommand.cs:87-99,113-121`. Their dedupe relies on the `"yyyy-MM-ddTHH:mm:ssZ"`
string being byte-identical at 5 sites. The "is series" check is written inline in `Delete`
(`:64-67`) and as `OccurrenceMaterializer.IsSeries` elsewhere. Scope strings are private consts
in `Update` and literals in `Delete`. The UTC+7 boundary is `interval '7 hours'` in SQL and
`StreakCalculator.DefaultDayBoundaryOffset` in the handler. **Fix:** one
`RecurrenceExceptions.Add` helper with a const format; `Event.IsSeries` as a get-only property on
the entity; public scope and outbox-action constants; pass the offset into the SQL as a
parameter.

### 16 [LOW] Docs and comments no longer match the code

*Introduced.* `CLAUDE.md:87` still says login lands on `/calendar` with four tabs (confirmed).
`docs/notifications-and-reminders.md:152-161` says the command-centre panel was not migrated.
`event_occurrence_expander.dart:10-12` counts the panel's copy twice (`HomeAgenda` never had a
copy). Two translation keys have no use: `home_starts_at`, `home_activity_chart_caption`
(0 references, confirmed). **Fix:** update the passages; delete the keys.

### 17 [LOW] Weak and clock-dependent assertions

*Introduced.*
- `home_screen_test.dart:272`: `find.text('Later today')` always matches, since the header
  renders with no events; after 22:30 local the test proves nothing about separating later
  events.
- `event_tasks_checklist_test.dart:128-132`: the template starts `[true, false]` and the tap
  sends `true`, so "template untouched" holds even if the code ticked the template; only the
  `toggleCalls` assertion protects it.
- `OccurrenceEditAndDeleteTests.cs:177`: asserts a value that is already true before the call.
- `home_screen_test.dart:19-22`: the catch-all mock returns `Future<List<dynamic>>`, which fails
  the typed forwarder, so the Up Next card's checklist only ever renders its error state in
  these tests (reproduced by the reviewer: `type 'Future<List<dynamic>>' is not a subtype of
  type 'Future<List<EventTaskModel>>'`).
- `GetActivitySummaryQueryHandlerTests` and `home_screen_test` read the clock separately from the
  code under test.

**Fix:** a fixed clock (`TimeProvider` / a clock provider), a typed fake for the Home tests that
throws on unexpected calls, and assertions scoped to the card they are about.

### INFO

- **Your running backend (:5000) is older than this branch.** Its Swagger has no
  `/events/{id}/occurrences` and ignores `occurrenceStart`. Against it, the new app fails the
  first tick on a series day, and **finishing a session there completes the whole series**.
  Restart it before testing.
- `ActualDuration` is not validated (pre-existing). A huge value makes this user's own dashboard
  query fail with `integer out of range` (measured); negative values pass through. Validate
  `0 < d <= 24h`.
- `HabitId` from the client is not ownership-checked before streak recalculation (pre-existing;
  needs a leaked habit GUID).
- `category_list_view.dart:89,114` counts "affected events" from the fetched window, which is
  now bounded, so it undercounts.
- "All occurrences" re-anchors the series start to the edited day, dropping earlier days
  (pre-existing). This branch makes it reachable from a split-off day too.
- `HomeAgenda`'s 7-day look-ahead and the "seven days" in `home_nothing_ahead_hint` are
  literals next to the new window constants.
- Smaller convention items: `'/home'` spelled in three places; unnamed spacing in
  `activity_summary_card.dart:188`; the split-off flow lives in the checklist's `State`;
  `UpdateSplitOffDayAsync` writes into the incoming command (`:117`); `onStartPomodoro` is unused;
  the `== AppLocale.en ? 'en_US' : 'vi'` ternary now has 6 copies.
- `OccurrenceMaterializer` is registered in DI with no smoke test; four handlers would fail at
  runtime without that line, while the unit tests construct them by hand.

### Rejected or downgraded in verification

| Reviewer claim | Verdict |
| --- | --- |
| A refetch loop from Home via the sync cache | Rejected: the background revalidation does not publish `CalendarUpdatedEvent` — one extra call, no loop (finding 6) |
| "Test gap on Google edit paths" as HIGH | Downgraded to MEDIUM (finding 5): a missing test is not itself broken behaviour; the real Google bugs are findings 2 and 3 |
| Duplicated rules as MEDIUM | Downgraded to LOW (finding 15): the formats agree today; it is a trap, not a bug |
| Dead-lettered Insert as MEDIUM | Downgraded to LOW (finding 7): needs five failed Inserts first |
| "dung has 0 activity rows in 14 days" | Data came from the dump on :5433, which has no demo data. The finding (4) still stands on its mechanism |

## Round 1 verification

| Item | Result |
| --- | --- |
| `dotnet test` (Application.UnitTests) | 99 pass / 0 fail (was 78 on `main`) |
| `flutter test` | 172 pass / 0 fail (was 89 on `main`) |
| `flutter analyze` | No issues found |
| `dotnet build` | 0 errors; only the pre-existing NU1603 package warnings |
| Codegen current | `events_provider.g.dart` regenerated; a second `build_runner` run changes nothing |
| Negative controls, server | Caught: series guard, completing the series row, missing exception date on delete, tick carried into the copy, Google push for an unseen day, toggle series guard |
| Negative controls, client | 3 of 3 caught (template mode, calendar hiding, post-session day) |
| Mutation run (test-coverage reviewer, scratch copy) | 8 caught, 14 survived — see finding 5 |
| Live end-to-end (previous session) | 17 of 17 checks against a real server and database |
| Reminder-edit fix, live | `main` drops `[60]`, branch stores `[60]` |
| Finding 1 reproduction | Wednesday drawn twice, two reminders (06:45, 07:45) |
| Security | Ownership on every new path; SQL parameterised; no secrets in the diff (`local-dev/`, `.env`, `appsettings.Development.json` gitignored) |
| E2E (`integration_test/`) | **Not run** — needs a device |
| iOS | **Not run** |

## Out-of-scope notes

Visible while reviewing, not caused by this branch (confirmed against `main`):

- Syncfusion hides exception days by *date* (`appointment_helper.dart:1749-1763`), the expander
  by *minute*, so after a time change the calendar and Home can disagree on hidden days.
- "This and future" never re-parented *edited* children after the split (finding 1 covers the
  locally split ones).
- `custom_recurrence_dialog.dart:56` writes `UNTIL` with Dart's `toString()`, which puts a space
  where the `T` should be (`UNTIL=20261230 170000Z`), so the server's UNTIL check never applies
  to rules the app creates.
- Edited days pushed to Google become standalone Google events, and sync step 5
  (`GoogleCalendarService.cs:296`, `ParentEventId == null`) imports each one back as a second
  local event.
- The heatmap still groups in memory (roadmap 5.6b).

## Priority

| # | Severity | Category | Fix cost |
| --- | --- | --- | --- |
| 1 | HIGH | correctness — duplicate days, double reminders | medium (two methods + tests) |
| 2 | MEDIUM | data loss, Google users | small (one condition + test) |
| 3 | MEDIUM | Google duplicate, regression | small |
| 4 | MEDIUM | misleading numbers | small (honest label) / large (real counts) |
| 5 | MEDIUM | test gaps | medium (~15 tests) |
| 6 | LOW | extra Google calls | small |
| 7–9 | LOW | correctness edges | small each |
| 10 | LOW | race + existing duplicates | medium (migration) |
| 11–17 | LOW | UX, abuse, contracts, conventions, docs, tests | small each |

---

# Conclusion

The branch does what it claims at the right layer. The home screen, the bounded fetch range,
and — most important — per-day tasks and completion for repeating events all work on the paths
they were built for, verified live and by negative controls. The reminder-edit fix closes a bug
that was already on `main`.

Decisions that hold up:
- Splitting a day off into the existing child-event shape reuses machinery the client already
  understood, instead of adding a new model.
- Keeping split-off days local-only protects users' Google Calendars (including work meetings)
  from edits they never made.
- Aggregating in parameterised SQL instead of in memory; keeping `HomeAgenda` pure and tested.

What doesn't hold up yet: the split-off day is a snapshot that nothing keeps in step with its
series (finding 1), and the Google-connected edges around it were never exercised (findings 2,
3, 5). The fix for 1 and 2 is the same idea — "local-only means not in the series' exception
dates" — which the design already guarantees and nothing yet uses.

After 1 round: 17 findings (1 HIGH, 4 MEDIUM, 12 LOW) plus INFO notes, none closed yet.
**1 HIGH and 4 MEDIUM open. Blocks merge.**

**Round 2.** The HIGH and three MEDIUMs are closed, each checked by a test that fails when the
fix is removed and, where it touches data, by a live run against the real database. Findings 1
and 2 were closed by the same rule, as round 1 predicted: "local-only means not in the series'
exception list" — now read and written through one helper instead of five string copies.
Finding 4 went further than round 1's cheap option: the card now shows correct counts, not a
softened label, because the client already held everything needed to count repeating days.

Finding 5 is half-closed. The tests it asked for exist, and the round 1 mutations that mattered
most (the Insert/Update swap, the renamed JSON key) are now caught, but there is still no
integration test for the repository SQL or for the inbound Google sync path. That path carries
finding 2's fix, and its call-site ordering is verified by reading, not by running.

After 2 rounds: 17 + 3 findings. Closed: 4 (findings 1–4). Half-closed: 4 (5, 11, 15, 16). Open:
10 LOW and N1 (LOW), plus INFO notes. **No HIGH remains. One MEDIUM is half-open** — the missing
integration tests, which is a test gap, not a known bug. Whether that blocks merge is a call for
the author: the behaviour it would cover is unit-tested at the decision point.

## Commands run to verify

### Round 1

```
git log --oneline main..HEAD                                  # 5 commits, the branch's real scope
git diff --numstat main...HEAD                                # 63 files, +5316/-589 (excl. generated)
git fetch origin                                              # timed out: remote unreachable, local main used
cd server/tests/Application.UnitTests && dotnet test          # 99 pass
cd apps && flutter test                                       # 172 pass
cd apps && flutter analyze                                    # no issues
dotnet build src/Web/Web.csproj -o /tmp/webcheck              # 0 errors (separate output; :5000 holds the default bin)
psql -h host.docker.internal -p 5432 ... GROUP BY "ParentEventId","ExceptionDate" HAVING COUNT(*)>1
                                                              # da2c839d x3 (finding 10)
psql ... SELECT indexname FROM pg_indexes WHERE tablename='Events'   # no unique index
grep -rn "new CalendarUpdatedEvent" server/src                # only SyncGoogleCalendarCommand: no loop (finding 6)
sed -n '405,440p' .../GoogleCalendarService.cs                # PushUpdateAsync cancels instances (finding 2)
grep -n "RetryCount < 5\|ProcessedAt == null" .../GoogleCalendarOutboxRepository.cs   # finding 7
grep -rn "translate('error')" apps/lib                        # 5 sites, key missing (finding 11)
flutter test test/_probe/stale_day_probe_test.dart            # finding 1 reproduced; probe deleted
```

Reviewer commands (not re-run here unless listed above): targeted `dotnet test --filter` runs
(42 pass), targeted `flutter test` runs (28–40 pass), a mutation run over a `git archive` copy in
the scratchpad (22 mutations), read-only SQL, and EF/`fsi` probes of the JSON and date shapes.

### Round 2

```
dotnet test tests/Application.UnitTests -o /tmp/servertest    # 132 pass (was 99)
cd apps && flutter test                                       # 183 pass (was 172)
cd apps && flutter analyze                                    # no issues
dotnet build src/Web/Web.csproj -o /tmp/webcheck2             # 0 errors
python scratchpad/negative_controls.py                        # 4 server mutations: 1, 1, 1, 3 tests fail; restored
python scratchpad/negative_controls_app.py                    # 3 client mutations: 6, 1, 1 tests fail; restored
dotnet test ... --filter EventsEndpointMappingTests           # with the ReminderMinutesBefore mapping line removed: fails; restored
dotnet /tmp/webcheck2/Web.dll  (ASPNETCORE_URLS=:5099)        # new server beside the author's
python scratchpad/live_round2_check.py                        # 8/8
python scratchpad/live_occurrence_check.py                    # round 1's 17/17 still pass
psql ... DELETE ... probe_r2_% / probe_occ_%                  # probe accounts removed; 0 left
grep -rn 'yyyy-MM-ddTHH:mm:ssZ' server/src                    # only RecurrenceExceptions.cs
```
