# Code review: `main` (whole-codebase audit)

Base: `e306dcb` (HEAD of `main`, 2026-08-02) · Reviewed by: Claude Code

| Round | Commit | Date | Outcome |
| --- | --- | --- | --- |
| 1 | `e306dcb` chore(agents): move AGENTS.md project rules to rules/project-rules.md | 2026-09-09 | 11 findings: 2 HIGH, 3 MEDIUM, 3 LOW, 3 INFO. Both HIGH reproduced against a running server / handler. Build + both test suites green. |
| 2 | working tree on `fix/codebase-audit-round-1` (uncommitted) | 2026-09-09 | F1–F5 fixed at the author's request (F6–F11 deliberately out of scope, still open). All 5 re-verified against a running server. **0 HIGH, 0 MEDIUM open.** Backend tests 45 → 49, all green. |
| 3 | working tree on `fix/codebase-audit-round-1` (round 2 landed as `6825065`) | 2026-09-09 | Remaining F6–F11 fixed. **All 11 findings closed**, with two carve-outs stated below (per-user timezone, credential rotation). `flutter analyze` 50 → **0**; backend tests 49 → 58. |

> **Base note.** This is not a branch/PR review. There is no feature branch open — `main` is
> the only branch and the working tree is clean except for two untracked paths (`CLAUDE.md`,
> `docs/review-code-convention/`). So there is no meaningful diff to review. Instead the base
> is the whole tree at `e306dcb`, and every finding below is stated as pre-existing on `main`,
> not introduced by any one change. Where a finding has a likely origin commit, it is named.
> Because there is no "before" commit to compare against, the usual "is this the branch's fault
> or pre-existing?" check does not apply — everything here is by definition pre-existing.

---

# Round 3 — review of the working tree on `fix/codebase-audit-round-1`

Round 2's work landed as `6825065`. This round covers the findings it deliberately left open.

## Status of round 2's open findings

| # | Finding | Status |
| --- | --- | --- |
| 6 | UTC+7 offset and streak loop copy-pasted into 4 files | ✅ **Closed** (with a stated carve-out) — one `StreakCalculator`; `grep -c ToLocalTimeUtc7 server/src` → **0** |
| 7 | Debug toast, magic numbers/strings, `TODO_SQUAD_ID` | ✅ **Closed** — toast removed, constants moved to `AppConstants`, string translated, real squad id passed |
| 8 | 50 analyzer issues | ✅ **Closed** — `flutter analyze` reports **No issues found** |
| 9 | `walkthrough.md` 74 commits stale | ✅ **Closed differently** — the author said the folder is no longer used, so `docs/project-walkthrough/` was deleted rather than updated |
| 10 | `project-plan.md` describes unbuilt features | ✅ **Closed** — both sections annotated as NOT IMPLEMENTED, with what exists instead |
| 11 | Committed secrets, no CI | ✅ **Closed** (with a stated carve-out) — secrets moved to gitignored files, CI workflow added |

### Finding 6 — closed, minus the product decision

`Application/Common/StreakCalculator.cs` is now the only definition of a streak. The four
private `ToLocalTimeUtc7` copies and the two variants of the streak loop are gone:

```
$ grep -rn "ToLocalTimeUtc7" server/src --include=*.cs | wc -l
0
$ grep -rln "StreakCalculator" server/src --include=*.cs
server/src/Application/Common/StreakCalculator.cs
server/src/Application/Features/Events/Commands/CompleteEventSessionCommand.cs
server/src/Application/Features/Events/Commands/ToggleEventCommand.cs
server/src/Application/Features/Squads/Queries/GetMySquadQuery.cs
server/src/Application/Features/Users/Queries/GetMeQuery.cs
```

Nine unit tests (`Common/StreakCalculatorTests.cs`) pin the behaviour that was previously
implicit: same-day duplicates collapse, a streak stays alive if it reaches yesterday, the
longest run is reported even when it is not the current one, and — the case the old code was
written for — 23:00 and 06:00 either side of midnight UTC+7 count as two days.

**Carve-out, unchanged from round 2.** `DefaultDayBoundaryOffset` is still a single app-wide
UTC+7. Streaks and heatmaps are still off by a day for users outside that zone. What changed is
that it is now *one* constant with a documented seam (every method takes an optional offset)
instead of four hardcoded copies. Choosing device-timezone versus a profile setting is a product
decision that would change every existing user's streak, so it stays open. It is recorded in the
review's action list rather than decided here.

While replacing the copies, `GetMeQuery` and `GetMySquadQuery` also moved from
`GetEventsForUserAsync(userId)` + in-memory `.Where(e => e.IsCompleted)` to the SQL-filtered
`GetCompletedEventsForUserAsync` — the same class of fix as F4, in two places round 2 did not
touch. Note `GetMySquadQuery` still issues one such query **per squad member**; that N+1 is
pre-existing and not addressed here.

### Finding 7 — closed

- The `Debug` / `Offset: … -> NULL` toast is gone. An unresolvable drop now falls back silently
  to the day already on screen, which the handler already defaulted to.
- `Offset(70, 35)`, `Duration(hours: 1)` and the `'hover_preview'` id moved into `AppConstants`
  (`draggedHabitCentreOffset`, `defaultDroppedEventDuration`, `hoverPreviewEventId`) — the last
  of which `calendar_event_data_source.dart` also keyed off as a bare literal, so the two are
  now tied to one constant.
- `'Drop to schedule'` became the `drop_to_schedule` translation key (en + vi).
- `TODO_SQUAD_ID` is gone. `AddCategoryDialog` takes a `squadId`, asserts it is present when
  `isSquad` is true, and `CategoryManagementScreen` passes the real `activeSquadIdProvider`
  value — disabling the button when the user has no squad, rather than writing a broken record.

### Finding 8 — closed

```
$ flutter analyze
No issues found! (ran in 59.4s)      # was: 50 issues found
```

Two of these deserve naming rather than counting:

- The 19 `use_build_context_synchronously` were real. Most took a `context.mounted` guard, but
  in `google_calendar_sync_screen.dart` and `edit_habit_dialog.dart` a guard would have been
  wrong: the code shows a toast *after* popping its own dialog, so the context is legitimately
  dead and the toast would simply never appear. Those use the capture-before-await pattern
  (`final toaster = ShadToaster.of(context);` before the first `await`), which fixes the bug
  rather than silencing it — the toaster lives above the dialog and outlives it.
- `intl`, `collection` and `syncfusion_flutter_core` were imported but not declared, resolving
  only through other packages' transitive deps. Now direct dependencies, so a version change
  elsewhere cannot break the build.

The two `avoid_renaming_method_parameters` are **suppressed, not fixed**, with the reason in the
code: the lint wants the parameter renamed to `state`, which inside a Riverpod notifier would
shadow the notifier's own `state` property and silently change what the method body reads.

### Finding 9 — closed differently

Round 1 recommended regenerating the walkthrough. The author's answer during round 3 was that the
folder is no longer used for tracking project state, so `docs/project-walkthrough/` was removed
outright — including the 105 KB `compact_context.json` that round 1 flagged separately. Deleting
a stale map is a better outcome than refreshing one nobody reads.

Two action items lived only in that file. The still-relevant one (the Pomodoro TODO at
`timer_notifier.dart`) remains as a `// TODO` in the code; the "local database" half of it is
obsolete and is now explained in `project-plan.md` (F10). The Android application-id and signing
items were template placeholders, unrelated to this review.

### Finding 10 — closed

`docs/project-plan.md` now marks both claims, with the verification date and what exists instead:
the `isar`/`hive` offline-first line is struck through and annotated, and the `data/` layer in the
directory tree carries a note that no feature has one and that providers call `ApiService`
directly.

### Finding 11 — closed, minus the rotation

| | Before | After |
| --- | --- | --- |
| `appsettings.json` | live Google `ClientSecret`, DB password | empty placeholders + a pointer to the example file |
| `appsettings.Development.json` | tracked, DB password | untracked (`git rm --cached`), gitignored |
| `docker-compose.yml` | literal `NGROK_AUTHTOKEN` and domain | `${NGROK_AUTHTOKEN}` / `${NGROK_DOMAIN}` from a gitignored `.env` |
| new, committed | — | `appsettings.Development.example.json`, `.env.example` |
| CI | none | `.github/workflows/ci.yml` |

Verified that no secret remains in a tracked file:

```
# each <...> below stands for the real value, kept out of this file on purpose
$ for p in "<google-client-secret>" "<ngrok-token>" "<db-password>" "<ngrok-domain>"; do
    echo "$p -> $(git grep -l "$p" -- . | wc -l)"; done
<google-client-secret> -> 0
<ngrok-token>          -> 0
<db-password>          -> 0
<ngrok-domain>         -> 0

$ git check-ignore -v server/src/Web/appsettings.Development.json .env
.gitignore:236: server/src/Web/appsettings.Development.json
.gitignore:239: .env
```

Local development still works: the real values were written into the now-gitignored
`appsettings.Development.json` and `.env`, and the server was restarted to confirm it boots,
connects to Postgres and still answers `401` on both `/analytics/heatmap` and `/habits`.

`Infrastructure/DependencyInjection.cs` no longer falls back to a guessed
`Password=postgres` when the connection string is missing — that turned a missing setting into a
confusing Postgres auth error. It now throws with instructions, verified by forcing the case:

```
$ ConnectionStrings__DefaultConnection= dotnet run --project src/Web/ --no-launch-profile
Unhandled exception. System.InvalidOperationException: ConnectionStrings:DefaultConnection is not
configured. Copy src/Web/appsettings.Development.example.json to appsettings.Development.json and
fill it in, or set the connection string via user-secrets or the
ConnectionStrings__DefaultConnection environment variable.
```

The CI workflow runs `dotnet build`/`dotnet test` and `flutter pub get`/`analyze`/`test` on push
and pull request, plus a check that committed `*.g.dart` / `*.freezed.dart` are up to date — the
generated files are in git, so a stale one otherwise only fails on someone else's machine. **The
workflow has not been executed**: it cannot run until this branch is pushed, so it is reviewed
code, not verified behaviour.

**Carve-out.** The exposed Google `ClientSecret` and ngrok token are still valid and still in git
history. Removing them from the working tree does not revoke them. They must be rotated in the
Google Cloud console and the ngrok dashboard by hand; nothing in this change can do that.

Documentation added alongside: the README gained a *Configuration & secrets* section and a
*Google Calendar sync* setup section (previously undocumented — round 1 called this the hardest
part of setup with no instructions at all), including the failure mode where a wrong
`WebhookBaseUrl` or a stopped tunnel makes sync fail silently while SWR still refreshes on open.
`CLAUDE.md` and `docs/google-calendar-sync-architecture.md` were updated to point at the new
config layout.

## Round 3 verification

| Item | Round 2 | Round 3 |
| --- | --- | --- |
| `dotnet build` | 0 errors | 0 errors (same 6 pre-existing `NU1603`) |
| `dotnet test` | 49 passed | **58 passed** (+9 `StreakCalculator` tests) |
| `flutter analyze` | 50 issues | **No issues found** |
| `flutter test` | 58 passed | 58 passed |
| `ToLocalTimeUtc7` copies | 4 | **0** |
| Secrets in tracked files | 3 live values | **0** |
| Server boots from split config | n/a | yes — Postgres connected, `401` still enforced on both endpoints |
| Missing-config failure mode | silent wrong password | explicit `InvalidOperationException` with instructions |
| CI | none | workflow committed (**not yet executed**) |

## Still open after round 3

Neither is a defect this change could close:

1. **Streak day boundary** — a product decision (device timezone vs profile setting). The seam
   exists; the choice does not.
2. **Credential rotation** — manual, in the Google Cloud console and ngrok dashboard.

---

# Round 2 — review of the working tree on `fix/codebase-audit-round-1`

Scope agreed with the author: **F1–F5 only**. F6–F11 were explicitly left for later and are
still open — see "Deliberately not fixed" below. No frontend file was touched.

## Status of round 1 findings

| # | Finding | Status |
| --- | --- | --- |
| 1 | `/analytics/heatmap` unauthenticated + aggregates all users | ✅ **Closed** — 401 without a token; two accounts now each see `count:1` where both previously saw `count:2` |
| 2 | Toggle-off removes more XP than toggle-on granted | ✅ **Closed** — award now stored on the event; measured ON/OFF pair is XP-neutral |
| 3 | One toggle writes in three separate transactions | ✅ **Closed** — EF transaction log shows one `Beginning transaction` … `Committed transaction` around all three writes |
| 4 | Toggle reads the whole `Events` table | ✅ **Closed** — every `FROM "Events"` in a toggle now carries a `WHERE`; `GetAllAsync` deleted from both repository interfaces |
| 5 | Empty `UserId` treated as "return everything" | ✅ **Closed** — all four entry points throw `ArgumentException`; the `= ""` default is gone from `ToggleEventCommand` |
| 6-11 | UTC+7 duplication, debug toast, analyzer issues, docs, secrets, CI | ⏸️ **Out of scope this round** — unchanged, still open |

### Finding 1 — closed

`Web/Endpoints/V1/Analytics.cs` now calls `RequireAuthorization()` and passes the caller's
claim; `GetHeatmapQuery` takes a required `UserId` and reads
`GetCompletedEventsForUserAsync(userId)` instead of `GetAllAsync()`.

Re-ran the exact probe from round 1 — two fresh accounts, one completed event each on the same
unused date (2032-05-06), heatmap read once per account:

| Check | Round 1 | Round 2 |
| --- | --- | --- |
| `GET /analytics/heatmap` with no token | `200 OK` + every user's data | `401 Unauthorized` |
| user A's heatmap for the shared date | `count:2` (A + B) | `count:1` |
| user B's heatmap for the shared date | `count:2` (A + B) | `count:1` |

The anonymous request is refused, and neither user can see the other's activity.

### Finding 2 — closed

`Event.AwardedXp` (new column) records what a completion actually granted; toggling off refunds
that stored number and clears it. The ~60 lines of duplicated ON/OFF branching are gone, replaced
by `AwardXpAsync` / `RefundXp` / `ApplyXpAsync`, with the maths itself moved into
`Application/Common/XpRules.cs` so the award and the refund cannot drift apart.

Re-ran round 1's scenario end to end through the API (complete one event, keep the habit four more
days, then un-tick the first event):

| Step | Round 1 | Round 2 |
| --- | --- | --- |
| after completing the event | +10 XP | +10 XP |
| after 4 more days | streak bonuses accrue | streak bonuses accrue (total 50) |
| after un-ticking that same event | −18 XP → **net −8** | −10 XP → **net 0** (50 → 40) |

The refund now matches the award exactly. The unit test
`Handle_ShouldConserveXp_WhenTheStreakGrowsBetweenToggleOnAndToggleOff` locks this in — it is the
probe from round 1, kept as a regression test, and it fails against the old handler.

**Migration note.** `20260909153849_AddAwardedXpToEvent` adds the column and backfills
`AwardedXp = 10` for rows already completed. The streak at the time of those completions is not
recoverable, so the base award is used; under-refunding is the safe direction, since the bug being
fixed was over-refunding. Applied to the local database successfully.

### Finding 3 — closed

New `IUnitOfWork.ExecuteInTransactionAsync` (implemented in `Infrastructure/Data/UnitOfWork.cs`,
joining an outer transaction if one is already open). `ToggleEventCommandHandler` and
`CompleteEventSessionCommandHandler` now wrap their whole operation in it.

Measured with `Microsoft.EntityFrameworkCore.Database.Transaction` logging at Debug — one toggle,
event attached to a habit:

| Round 1 | Round 2 |
| --- | --- |
| `UPDATE "AspNetUsers" … @p0` (batch 1) | `Beginning transaction` |
| `UPDATE "Events" … @p0` (batch 2) | `UPDATE "Events"` |
| `UPDATE "Habits" … @p0` (batch 3) | `UPDATE "AspNetUsers"` |
| no transaction — 3 independent commits | `UPDATE "Habits"` |
| | `Committing transaction` / `Committed transaction` |

Round 1's related observation — the "pretend" mutation `eventInList.IsCompleted = true` leaking to
the database via the next unrelated `SaveChanges` — is also gone: the streak input is now read
through `AsNoTracking()` repository methods, and the toggled event is folded into a scratch list
rather than mutated.

### Finding 4 — closed

`GetAllAsync()` is deleted from `IEventRepository` and `IHabitRepository`, so the unbounded read is
no longer reachable. Replaced by `GetCompletedEventsForUserAsync(userId)` and
`GetCompletedEventsForHabitAsync(habitId)`, both filtered in SQL and `AsNoTracking`.

Every `FROM "Events"` issued by one toggle, from the server log:

```
FROM "Events" AS e WHERE e."Id" = @p
FROM "Events" AS e WHERE e."UserId" = @userId AND e."IsCompleted"
FROM "Events" AS e WHERE e."IsCompleted" AND lower(e."HabitId") = @ToLower
```

Round 1 had a fourth: `FROM "Events" AS e` with no `WHERE` at all. It is gone.

Honest note on cost: the statement count for one toggle went from 6 to 10, because the handler now
issues two narrow, indexed reads where it previously did one unfiltered table load, and the
transaction adds round-trips. The win is that cost now scales with the user's own history instead
of the size of the whole table — the point of the finding. Adding an index on
`Events(UserId, IsCompleted)` and `Events(HabitId, IsCompleted)` is the obvious follow-up and is
**not** done in this round.

### Finding 5 — closed

`GetEventsQuery`, `GetHabitsQuery`, `GetHeatmapQuery` and `ToggleEventCommand` all throw
`ArgumentException` on an empty `UserId`, and `ToggleEventCommand`'s `string UserId = ""` default
parameter is removed so the compiler now requires a caller to supply one. Four unit tests assert
the throw and that no repository call is made.

## Deliberately not fixed

Not defects left unaddressed by accident — the author scoped this round to F1–F5.

- **F6 (UTC+7 duplication)** — still copy-pasted in `GetMySquadQuery` and `GetMeQuery`. The two
  event handlers now share a private `StreakEndingToday` helper each, which reduced the four
  streak-loop copies to a cleaner shape, but the offset is still hardcoded `+7` in four files.
  Fixing it properly needs a product decision first: does a user's day boundary follow their
  device or a profile setting? Making that call unilaterally would change behaviour for every
  existing user's streak.
- **F7, F8** — frontend only; no Flutter file was touched this round. `flutter analyze` is
  unchanged at 50 issues.
- **F9, F10, F11** — docs, secrets and CI. The committed Google `ClientSecret` and ngrok token are
  still live and still in git history; rotating them is not something this change can do.

## Round 2 verification

| Item | Round 1 | Round 2 |
| --- | --- | --- |
| `dotnet build` | 0 errors, 6 `NU1603` warnings | 0 errors, same 6 `NU1603` warnings (unchanged, pre-existing) |
| `dotnet test` | 45 passed / 0 failed | **49 passed / 0 failed** |
| `flutter analyze` | 50 issues (1 warning, 49 info) | 50 issues — unchanged, no frontend file touched |
| `flutter test` | 58 passed | 58 passed |
| `dotnet ef database update` | n/a | migration applied, incl. backfill |
| Heatmap without token | `200 OK` + all users | `401 Unauthorized` |
| Heatmap per user (shared date) | both saw `count:2` | each sees `count:1` |
| XP for a complete/un-complete pair | net **−8** | net **0** |
| Transaction around one toggle | none (3 commits) | 1 begin → 3 updates → commit |
| Unbounded `FROM "Events"` reads | 1 per toggle | 0 |

Test count change explained: +5 new tests (2 heatmap, 1 habits, 2 toggle incl. the XP regression),
−1 file removed. `GetEventsQueryHandlerTests.cs` at the test-project root was deleted — its single
test asserted the `GetAllAsync` fallback that F5 removes, and the copy under
`Features/Events/Queries/` covers the same handler properly. That also clears the duplicate class
name flagged in round 1's out-of-scope notes.

## Round 2 test-data note

The runtime checks in this round registered more throwaway accounts on the local `habit-tracker`
database (`vfy_*`, `xp_*`, `sql_*`, `tx_*`, `tx2_*`, all `@example.com`), with events dated 2031–2032.
The cleanup SQL at the end of this file covers them.

---

# Round 1 — review `e306dcb`

Kept as the record. See the overview table for the current status of each finding.

## Scope

Whole tree. 98 backend `.cs` files (excluding `obj/`, `bin/`, `Migrations/`) and 88 hand-written
Dart files (excluding generated `*.g.dart` / `*.freezed.dart`, ~13.6k lines).

Reviewed by logical area, not file by file:

| Area | What was read |
| --- | --- |
| Backend domain / CQRS | `Application/Features/**` — Events, Habits, Analytics, Squads, Users, GoogleCalendar |
| Backend edge | `Web/Endpoints/V1/*.cs`, `Web/Infrastructure/*.cs`, `Program.cs`, `Web/Hubs/SocialHub.cs` |
| Backend data | `Infrastructure/Repositories/*.cs`, `ApplicationDbContext.cs`, `GoogleCalendarSyncWorker.cs` |
| Flutter state / network | `core/network/*`, `core/routing/app_router.dart`, `features/calendar/presentation/events_provider.dart` |
| Flutter features | calendar drag-and-drop, home widget bridge, settings/Google sync screen |
| Docs | `docs/*.md`, `docs/project-walkthrough/walkthrough.md`, `README.md`, `.agents/rules/project-rules.md` |

## Parts verified as correct

### Endpoint auto-discovery by reflection

`Web/Infrastructure/WebApplicationExtensions.cs:24-46` finds every non-abstract `EndpointGroupBase`
in the assembly, groups by `ApiVersion`, and mounts each at `/api/v{version}/{groupname}`. Verified
against the running server — `api-supported-versions: 1.0` comes back on responses, and the routes
resolve without any manual registration:

```
$ curl -s -i http://localhost:5000/api/v1/habits | head -3
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Bearer
```

The 401 (not a 404) proves the group was discovered and mounted, and that its
`RequireAuthorization()` is in force. This is a good design for this codebase: adding an endpoint
group is one file with no wiring, so the usual "forgot to register it" bug class does not exist.

### Auth is genuinely enforced on the groups that ask for it

`groupBuilder.RequireAuthorization()` at the group level (e.g. `Endpoints/V1/Habits.cs:22`) covers
every route in the group, so an individual route cannot be forgotten. Measured — see the 401 above.
9 of 10 endpoint groups do this. The tenth is finding 1.

### The SignalR query-string token middleware is ordered correctly

`Program.cs:37-48` copies `?access_token=` into the `Authorization` header for `/socialHub`, and it
sits **before** `app.UseAuthentication()` at line 50. That order is required — if it ran after,
the token would never be seen. This was fixed deliberately in `1e9c2b4`
("fix(backend): add UseAuthentication and SignalR query token extraction middleware"), and the
current order is right.

### The webhook's background scope handling is correct

`stale-while-revalidate-sync.md` §3A documents that the webhook must not reuse the request's
`ISender` after the response completes, and `GetEventsQuery` (`Features/Events/Queries/GetEventsQuery.cs:28`)
does inject `IServiceScopeFactory` rather than capturing the scoped sender. This is the right fix
for `ObjectDisposedException`, and the doc explains the reasoning — good practice worth keeping.

### Ownership checks on mutating commands

`ToggleEventCommand` (`ToggleEventCommand.cs:34`) checks `evt.UserId != request.UserId` and returns
false, and the endpoint overwrites `command.UserId` from the token claim before sending
(`Endpoints/V1/Events.cs:51`). So a client cannot toggle another user's event by sending a forged
`UserId` in the body. Confirmed by the existing test `Handle_ShouldReturnFalse_WhenUserIdMismatch`,
which passes.

## Round 1 findings

### 1 [HIGH] `/api/v1/analytics/heatmap` is unauthenticated and returns every user's activity

`Web/Endpoints/V1/Analytics.cs:17-21` is the only endpoint group that never calls
`RequireAuthorization()`:

```csharp
public override void Map(RouteGroupBuilder groupBuilder)
{
    groupBuilder.MapGet("heatmap", GetHeatmap);   // no RequireAuthorization()
}
```

And `Application/Features/Analytics/Queries/GetHeatmap/GetHeatmapQuery.cs:17,30-31` has no
`UserId` on the query at all — it reads the whole table and groups it:

```csharp
public record GetHeatmapQuery() : IRequest<List<HeatmapItemDto>>;
...
var allEvents = await _eventRepository.GetAllAsync();
var completedEvents = allEvents.Where(e => e.IsCompleted);   // no per-user filter
```

Reproduced against the running server, with `/api/v1/habits` as a negative control to show that
auth does work elsewhere:

```
$ curl -s -i http://localhost:5000/api/v1/analytics/heatmap | head -2
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8

$ curl -s -i http://localhost:5000/api/v1/habits | head -2
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Bearer
```

Then proved that the numbers really do mix accounts. Two fresh accounts were registered, each
completed exactly one event on the same unused date (2031-03-05), and the heatmap was read each
time **with no `Authorization` header at all**:

| Step | Anonymous heatmap entry for 2031-03-05 |
| --- | --- |
| baseline | (absent) |
| after user A completes 1 event | `"date":"2031-03-05T00:00:00Z","count":1` |
| after user B (different account) completes 1 event | `"date":"2031-03-05T00:00:00Z","count":2` |

The count went 1 → 2 because of a *second, unrelated* user. So one anonymous request returns the
combined daily activity of the entire user base.

Impact: any person on the network can read how active every user is, day by day, with no account.
It also means each user's own heatmap in the app is wrong — it shows global activity, not theirs.
That second part is a visible product bug, not only a security one.

**Fix** — two lines, both needed:

```csharp
// Analytics.cs
public override void Map(RouteGroupBuilder groupBuilder)
{
    groupBuilder.RequireAuthorization();
    groupBuilder.MapGet("heatmap", GetHeatmap);
}
```

```csharp
// GetHeatmapQuery.cs
public record GetHeatmapQuery(string UserId) : IRequest<List<HeatmapItemDto>>;
// handler: await _eventRepository.GetEventsForUserAsync(request.UserId)  -- not GetAllAsync()
```

and pass `user.FindFirstValue(ClaimTypes.NameIdentifier)` from the endpoint, as every other group
already does.

Mitigating factor: none. The endpoint is reachable on the default dev configuration with
`AllowAnyOrigin()` CORS.

### 2 [HIGH] Toggling an event off can remove more XP than turning it on ever gave

`Features/Events/Commands/ToggleEventCommand.cs:58-60` and `:88-90` both compute the XP amount
from the streak **at the moment of the click**, on both the ON and the OFF path:

```csharp
int userStreak = CalculateActivityStreak(completedEvents);
xpGained = 10 + Math.Max(0, (userStreak - 1) * 2);
```

Nothing records how much XP was actually awarded when the event was completed. So if the streak
grows between the ON and the OFF, the OFF subtracts the *larger* current amount.

Reproduced with a temporary probe driving the real `ToggleEventCommandHandler` (mocked repos,
Moq — same setup as the existing tests). The scenario is ordinary use: complete today's event,
keep the habit for four more days, then un-tick that first event.

```
XP start                      : 100
XP after toggle ON            : 110   (awarded 10)
XP after toggle OFF (same evt): 92    (removed 18)
NET change for a ON->OFF pair : -8    (expected 0)

Assert.Equal() Failure: Values differ
Expected: 100
Actual:   92
```

The user was punished 8 XP for ticking and un-ticking the same box, purely because they had been
consistent in between. The effect grows with the streak: at a 10-day streak, an ON/OFF pair costs
18 XP.

Impact: every user's `TotalXP` drifts downward over time, and `CurrentLevel` is derived from it.
This is silent — nothing logs it and no test catches it. It is data corruption, not just a display
bug, and it gets worse the more engaged the user is.

**Fix**: store the awarded amount and refund exactly that.

```csharp
// Domain/Entities/Event.cs
public int AwardedXp { get; set; }

// ToggleEventCommand handler
if (isCompleted) { evt.AwardedXp = 10 + Math.Max(0, (streak - 1) * 2); delta = evt.AwardedXp; }
else            { delta = -evt.AwardedXp; evt.AwardedXp = 0; }
```

This also removes the need to recalculate the streak at all on the OFF path, which deletes the
duplicated ~55-line branch (see finding 6).

Why the existing tests miss it: `ToggleEventCommandHandlerTests.Handle_ShouldDeductXP_WhenToggleOff`
builds a scenario where the streak is 2 on **both** the ON and the OFF, so award and refund happen
to match (12 and 12) and the test passes. It locks in the symmetric case only. A negative control
confirms this — the probe above uses the same handler and mocks, and fails.

### 3 [MEDIUM] One toggle request writes in three separate transactions

Every repository method ends with its own `SaveChangesAsync()` — e.g.
`Infrastructure/Repositories/EventRepository.cs:53-57`:

```csharp
public async Task UpdateAsync(Event ev)
{
    _context.Events.Update(ev);
    await _context.SaveChangesAsync();
}
```

`ToggleEventCommandHandler.Handle` calls `_userRepository.UpdateAsync`, then
`_eventRepository.UpdateAsync`, then `_habitRepository.UpdateAsync`. There is no `IUnitOfWork` and
no explicit transaction anywhere in the solution.

Measured from the server's own EF SQL log for a single `PUT /api/v1/events/{id}/toggle` request
(toggle OFF, event attached to a habit). Every `UPDATE` restarts its parameter numbering at `@p0`,
which means three distinct `SaveChangesAsync()` calls, i.e. three transactions:

```
20:  UPDATE "AspNetUsers" SET "AccessFailedCount" = @p0, ... , "TotalXP" = @p21, ...
30:  UPDATE "Events"      SET "ActualDuration"    = @p0, ... , "IsCompleted" = @p7, ...
44:  UPDATE "Habits"      SET "CategoryId"        = @p0, ... , "CurrentStreak" = @p2, ...
```

Impact: if the process dies or the DB connection drops between statements, the user keeps the XP
but the event is not marked complete (or the habit streak is left stale). There is no way to detect
or repair this afterwards, because nothing records that the operation was half-applied. Combined
with finding 2, XP drift has a second, independent cause.

A related detail found in the same logs: because all repositories share one scoped `DbContext`,
the *in-memory only* mutation at `ToggleEventCommand.cs:52-56` (`eventInList.IsCompleted = true`,
which exists purely to make the streak maths treat the event as done) is picked up by EF change
tracking and written out by the **next** unrelated `SaveChanges`. On the toggle-ON path the log
shows it riding along inside the user's batch, with the parameter numbering continuing rather than
restarting:

```
UPDATE "AspNetUsers" SET ... @p26
UPDATE "Events" SET "IsCompleted" = @p27
WHERE "Id" = @p28;
```

The final stored value happens to be correct on the ON path, so this is not a live data bug today —
but a "pretend" mutation reaching the database is fragile, and it would become a real bug the moment
that simulation value differs from the intended one.

**Fix**: inject `ApplicationDbContext` (or an `IUnitOfWork`) into the handler, drop
`SaveChangesAsync()` from the individual repository methods, and call it once at the end of the
handler. For the tracked-entity issue, load the streak input with `.AsNoTracking()` so the
simulation cannot be persisted.

### 4 [MEDIUM] Toggling one checkbox reads the whole `Events` table

`ToggleEventCommand.cs:190` (inside `RecalculateStreaks`) and
`CompleteEventSessionCommand.cs:178` both call:

```csharp
var allEvents = await _eventRepository.GetAllAsync();
```

`EventRepository.GetAllAsync()` is `_context.Events.ToListAsync()` — every event of **every** user,
filtered afterwards in C#. `GetHeatmapQuery` does the same (see finding 1).

Measured from the SQL log of one toggle request on an event that has a habit attached. The query
appears with no `WHERE` clause at all:

```
SELECT e."Id", e."ActualDuration", ... , e."UserId"
FROM "Events" AS e            <-- no WHERE: full table
```

The same request also issues `SELECT ... FROM "Events" AS e WHERE e."UserId" = @userId` — every
event the user has ever had, with no date bound — to compute the streak. Total for one checkbox
tap on a nearly empty account: 6 SQL statements.

Impact: cost grows with total rows in the table, not with the user's data. On a shared database
this degrades for every user as soon as any user has a lot of history. It is invisible in
development because the seed data is small.

**Fix**: add `GetCompletedEventsForHabitAsync(Guid habitId)` and
`GetCompletedEventsForUserSinceAsync(string userId, DateTime since)` to `IEventRepository`, filter
in SQL, and delete `GetAllAsync()` from the interface so it cannot be reached for. A streak only
needs history back to the first gap — roughly the last N days, not all time.

### 5 [MEDIUM] An empty `UserId` is treated as "return everything"

Two query handlers use the same fallback — `Features/Habits/Queries/GetHabitsQuery.cs:25-28`:

```csharp
if (string.IsNullOrEmpty(request.UserId))
    return await _repository.GetAllAsync();

return await _repository.GetHabitsForUserAsync(request.UserId);
```

and `Features/Events/Queries/GetEventsQuery.cs:40-43`, identically. `ToggleEventCommand.cs:11`
carries the same idea into a command signature: `string UserId = ""` as a **default parameter**.

Not currently reachable: every endpoint sets `UserId` from the token claim before sending, and the
401 control in finding 1 shows the auth layer holds. So this is a latent risk, not a live leak —
stated here so it is not mistaken for a proven exploit.

Impact: the safe direction and the unsafe direction are the wrong way round. A future endpoint,
background job, or MediatR call that forgets one line silently returns every user's data instead of
failing loudly. Finding 1 is exactly this class of mistake, already realised once in `Analytics.cs`.

**Fix**: make the empty case throw (`ArgumentException`) rather than widen the query, remove the
`= ""` default from `ToggleEventCommand`, and delete `GetAllAsync()` from both repository
interfaces once findings 1 and 4 no longer need it.

### 6 [LOW] The UTC+7 offset and the streak algorithm are copy-pasted into four files

`ToLocalTimeUtc7` appears as a private static method, character-for-character, in four places:

| File | Line |
| --- | --- |
| `Features/Events/Commands/ToggleEventCommand.cs` | 181 |
| `Features/Events/Commands/CompleteEventSessionCommand.cs` | 169 |
| `Features/Squads/Queries/GetMySquadQuery.cs` | 58 |
| `Features/Users/Queries/GetMeQuery.cs` | 43 |

```csharp
if (dt.Kind == DateTimeKind.Utc) return dt.AddHours(7);
```

The streak loop itself (`completionDates` → consecutive-day walk → "today or yesterday" check) is
duplicated across the same four files, in two slightly different variants —
`CalculateActivityStreak` tracks only the current streak, `RecalculateStreaks` also tracks the
longest.

Impact: two separate problems. First, `+7` is hardcoded, so streaks, heatmaps and the "today or
yesterday" check are off by one day for any user outside UTC+7 — and the app already ships an
`en_US` locale and a language switcher, so non-VN users are expected. Second, any fix to the streak
rule has to be made four times, and the two variants will drift apart.

Note this is deliberate, not accidental — there is a passing test
(`Handle_ShouldCalculateStreakCorrectlyAcrossUtcDayBoundary_UsingUtcPlus7`) that locks the +7
behaviour in. So the fix must change that test too, and should not be done without deciding the
product question first (does a user's day boundary follow their device, or their profile?).

**Fix**: one `StreakCalculator` in the Application layer taking the day boundary as a parameter;
store an IANA timezone on `ApplicationUser` and pass it in.

### 7 [LOW] A debug toast and hardcoded strings ship in the drag-and-drop path

`features/calendar/presentation/widgets/calendar_workspace.dart:193-198`, in the `onAcceptWithDetails`
handler that runs when a habit is dropped onto the calendar:

```dart
ShadToaster.of(context).show(
  ShadToast.destructive(
    title: const Text('Debug'),
    description: Text('Offset: $centerOffset -> NULL'),
  ),
);
```

A real user who drops a habit on a spot the calendar cannot resolve gets a red error toast reading
`Debug` / `Offset: Offset(70.0, 35.0) -> NULL`.

In the same handler: `const Offset(70, 35)` (unexplained centring constants),
`title: 'Drop to schedule'` at line 168 and `Duration(hours: 1)` at line 170 are hardcoded rather
than going through `AppConstants` and the translation map. `AppConstants` already exists and already
holds `borderRadius`, `defaultPomodoroDurationMinutes` and similar. Separately,
`features/settings/presentation/widgets/add_category_dialog.dart:51` still passes the literal string
`'TODO_SQUAD_ID'` as a squad id.

These break project rules 4 (no magic numbers/strings) and 9 in `.agents/rules/project-rules.md`.

Impact: low individually — but the `Debug` toast is user-visible and the `TODO_SQUAD_ID` string is
a latent bug the moment that code path runs for a squad category.

**Fix**: replace the toast with a silent fallback to `widget.displayDate` (the handler already has
one), move the constants into `AppConstants`, add `drop_to_schedule` to `AppTranslations`, and
resolve the real squad id in `add_category_dialog.dart`.

### 8 [LOW] 50 analyzer issues, including 8 `avoid_print` and 19 `use_build_context_synchronously`

`flutter analyze` is clean of errors but reports 50 issues (1 warning, 49 info):

| Rule | Count |
| --- | --- |
| `use_build_context_synchronously` | 19 |
| `avoid_print` | 8 |
| `deprecated_member_use` (`withOpacity`) | 5 |
| `depend_on_referenced_packages` (`intl`, `collection`) | 5 |
| `curly_braces_in_flow_control_structures` | 4 |
| `unnecessary_underscores` | 3 |
| others (`use_null_aware_elements`, `avoid_renaming_method_parameters`, `unused_import`, `sort_child_properties_last`) | 6 |

Two of these are worth separating from the noise:

- `depend_on_referenced_packages` for `intl` — `lib/main.dart:12` and
  `features/home_widget/home_widget_service.dart:7` import `package:intl` but `intl` is **not** in
  `pubspec.yaml`. It resolves today only because `syncfusion_flutter_calendar` happens to pull it
  in. If that transitive dependency changes version or drops `intl`, the app stops compiling. Add
  `intl` to `dependencies` explicitly.
- `avoid_print` — `print()` in production code paths including
  `features/calendar/presentation/events_provider.dart:66` (logs on every SignalR calendar push)
  and `features/squads/presentation/providers/squad_chat_provider.dart:96`.

Project rule 16 requires static analysis before a task is marked done. 50 standing issues means the
signal is already lost — a new real problem will not stand out.

**Fix**: clear the list once, then keep it at zero. The `unused_import` warning and the
`curly_braces` / `unnecessary_underscores` items are mechanical. `use_build_context_synchronously`
needs real `if (!context.mounted) return;` guards — worth doing, since these are genuine
use-after-dispose risks in async dialog flows.

### 9 [INFO] `walkthrough.md` is 74 commits behind and is the first thing a new developer reads

`docs/project-walkthrough/walkthrough.md:4` declares its own position:

```
> **Current Branch:** `feature/habit-tasks-and-event-checklist` | **Last Analyzed Commit:** `c31a74f...`
```

Measured:

```
$ git log --oneline c31a74f..HEAD | wc -l
74
```

Everything built in those 74 commits is missing from it: the entire Google Calendar bi-directional
sync (`1c9d7c0`, `9fe5334`, `3572b24`, PRs #21/#22), the Android home widgets (`e012368`,
`1a60b46`, `2a8164b`), and the profile/cosmetics and XP work. The file still names a branch that no
longer exists.

Impact: this is the highest-cost documentation problem, because the file *looks* authoritative and
current. Someone joining will build a mental model that is missing the two most complex subsystems
in the project.

**Fix**: regenerate it against `e306dcb`, or add a dated "last verified" banner at the top so a
reader can judge it. Also worth deciding whether
`docs/project-walkthrough/compact_context.json` (105 KB of machine-generated JSON) belongs in git —
no human reads it, and it makes diffs noisy.

### 10 [INFO] `project-plan.md` describes two things that were never built

`docs/project-plan.md:1.1` specifies `isar` or `hive` for "offline-first capability & Pomodoro
state", and §2 shows a `data/` layer inside every feature folder.

Measured — neither exists:

```
$ grep -E "isar|hive|sqflite|drift" apps/pubspec.yaml    # no matches
$ find apps/lib/features -type d -name data              # no matches
```

There is no local database and no repository layer in the Flutter app; providers call `ApiService`
directly, and `ApiService` is a single 358-line class holding every endpoint for every feature.

Impact: a new developer will look for a cache layer that does not exist, and the documented
architecture cannot be used to judge whether new code follows the plan. Note also `timer_notifier.dart:64`
carries `// TODO: update the attached EventModel status and update the local database` — a TODO
pointing at a database that was never added.

**Fix**: mark both sections as "planned, not implemented" with a date, or remove them. If
offline-first is still wanted, it needs its own decision record — retro-fitting it on top of the
current SWR + SignalR sync is a significant piece of design, not a library swap.

### 11 [INFO] Live credentials are committed, and there is no CI

`server/src/Web/appsettings.json` contains a real Google OAuth `ClientSecret`
(`GOCSPX-...`) and `docker-compose.yml:8` contains a real `NGROK_AUTHTOKEN`. Both are in git
history, so rotating them requires new credentials, not just a commit that deletes the lines.

There is no `.github/` directory, so nothing enforces project rules 11, 14 and 16 (tests and static
analysis before "done") — they rely entirely on the developer remembering.

**Fix**: rotate both secrets; move them to user-secrets / environment variables and commit an
`appsettings.Development.json.example` instead. Add a small workflow running `dotnet build`,
`dotnet test`, `flutter analyze` and `flutter test` on pull requests, so the rules become real.

## Round 1 verification

| Item | Result |
| --- | --- |
| `dotnet build` (5 projects) | Build succeeded — 0 errors, 6 warnings (all `NU1603`, Google.Apis.Calendar.v3 1.68.0.3411 → 1.68.0.3430; pre-existing, dependency resolution only) |
| `dotnet test` (Application.UnitTests) | **45 passed**, 0 failed, 0 skipped (2 s) |
| `flutter analyze` | 50 issues — 1 warning, 49 info, 0 errors (196 s). See finding 8 |
| `flutter test` | **58 passed**, all green (21 s) |
| Runtime smoke test | Server started against local Postgres, migrations applied, endpoints answered on `:5000` |
| Auth negative control | `/api/v1/habits` → 401 without token; `/api/v1/analytics/heatmap` → 200 without token (finding 1) |
| XP conservation probe | ON/OFF pair on one event: net **−8 XP** (finding 2) |
| SQL cost of one toggle | 6 statements, incl. 1 unbounded `FROM "Events"` full-table read (finding 4) |
| Transaction boundaries | 3 independent `SaveChanges` batches per toggle (finding 3) |

Test suites and the build were **already green before this review and are still green after it** —
no source file was modified. The temporary probe used for finding 2 was deleted; `git status` after
cleanup shows only the two untracked paths that existed at the start.

## Priority table

| # | Severity | Category | Area | Est. fix cost |
| --- | --- | --- | --- | --- |
| 1 | HIGH | Security / correctness | `Analytics.cs`, `GetHeatmapQuery.cs` | ~15 min (2 lines + pass the claim through) |
| 2 | HIGH | Data corruption | `ToggleEventCommand.cs` + migration | ~2 h (column, migration, handler, update 1 test) |
| 3 | MEDIUM | Consistency | all repositories + handlers | ~1 day (introduce unit of work, touches every handler) |
| 4 | MEDIUM | Performance | `IEventRepository` + 3 call sites | ~3 h |
| 5 | MEDIUM | Security (latent) | 2 query handlers, 1 command | ~30 min, do together with 1 and 4 |
| 6 | LOW | Duplication / i18n-correctness | 4 Application files | ~4 h, needs a product decision on timezone first |
| 7 | LOW | Polish / rule compliance | `calendar_workspace.dart`, `add_category_dialog.dart` | ~1 h |
| 8 | LOW | Hygiene | Flutter-wide | ~3 h (19 `context.mounted` guards are the bulk) |
| 9-11 | INFO | Docs / process | `docs/`, repo root | ~2 h + credential rotation |

Suggested order: 1 → 2 → 5 → 4 → 3. Findings 1, 4 and 5 all touch `GetAllAsync()`, so doing them in
one pass lets that method be deleted from both repository interfaces, which structurally prevents
the whole class of bug.

## Out-of-scope notes

- The `NU1603` warnings are a NuGet resolution artefact of the pinned
  `Google.Apis.Calendar.v3 1.68.0.3411` not existing on the feed; they predate this review and are
  not caused by any code here.
- The overlapping Google Calendar sync triggers (server-side SWR in `GetEventsQuery`, the client's
  `_triggerBackgroundSync()` in `events_provider.dart:79-105`, the webhook, and the SignalR push —
  with two independent one-minute TTLs, one in `GoogleCalendarSyncCaches` and one in the client's
  `GoogleCalendarSyncTracker`) are a design concern, not a defect. Nothing was observed
  misbehaving, and `45adcc5` explicitly made the tracker `keepAlive` to stop a loop. Flagged for a
  future design discussion, not as a finding.
- `EventRepository.GetEventsForUserAsync` (`EventRepository.cs:26-38`) has a clause
  `|| (e.ParentEventId != null)` with no date bound, which appears to return every recurrence
  override regardless of the requested range. This was **not** measured — reproducing it needs a
  recurring event with an edited occurrence — so it is recorded as an observation to verify, not a
  finding.
- Test file placement is inconsistent (8 files at the root of `Application.UnitTests/`, 11 under a
  `Features/` mirror, with two different files both named `GetEventsQueryHandlerTests.cs`). Cosmetic
  only; no test is missing or duplicated in behaviour.

---

# Conclusion

The architecture is sound and the layering is real, not decorative: `Domain` has no framework
references, handlers depend only on interfaces, and the reflection-based endpoint discovery removes
a whole class of registration bug. The Google Calendar work in particular shows careful thinking —
the outbox for writes, the scope-factory fix for background work after the response completes, and
the SignalR push to close the loop are all the right shapes, and they are documented well enough
that the reasoning survives.

Design decisions that hold up under scrutiny:

- **Group-level `RequireAuthorization()`** — one call covers every route in the group, so an
  individual endpoint cannot be forgotten. Verified by a 401 negative control.
- **Endpoint auto-discovery** — adding an endpoint is one file with zero wiring.
- **`IServiceScopeFactory` for post-response work** — the correct fix for `ObjectDisposedException`,
  and the doc explains why.
- **Server-side ownership checks on mutating commands** — the endpoint overwrites `UserId` from the
  token, so a forged body cannot touch another user's data.

What lets it down is the layer below the architecture: the write path has no transaction boundary,
several read paths reach for the whole table, and the XP rules are computed twice from mutable state
instead of being recorded once. Findings 2, 3 and 4 all come from the same root cause — business
state is derived on every request rather than stored — so fixing that idea fixes three findings.

After 3 rounds: 11 findings, **11 closed, 0 open. No longer blocks merge.** Two carve-outs are
stated rather than fixed, because neither is a code change: the streak day boundary is a product
decision (device timezone vs profile setting), and the exposed credentials must be rotated by
hand in the Google Cloud console and ngrok dashboard — removing them from the working tree does
not revoke them, and they remain in git history.

One finding closed differently from the recommendation. Round 1 proposed regenerating the stale
walkthrough; the author's answer in round 3 was that the folder is not used at all any more, so it
was deleted instead. Deleting a map nobody reads beats refreshing it, and it is worth recording as
a case where the review's proposed fix was not the right one.

Round 2 confirmed the root-cause reading from round 1: findings 2, 3 and 4 really were one idea —
business state derived on every request instead of recorded once. Storing `AwardedXp` fixed the XP
asymmetry (F2) and simultaneously removed the reason to recompute the streak on the un-complete
path, which is what had been pulling in the full-table read (F4) and the extra writes (F3).
One change, three findings.

Process observations:

- The existing test suite is genuine, not decorative — 45 backend and 58 Flutter tests, all
  passing, with real assertions. But `Handle_ShouldDeductXP_WhenToggleOff` is a good example of a
  vacuous pass: it constructs the one scenario where the buggy maths is symmetric, so it confirms
  the implementation rather than the requirement. The negative control (same handler, same mocks,
  realistic scenario) fails immediately.
- The commit history is clear about root causes — `9fe5334` ("fix webhook scope disposal") and
  `45adcc5` ("keepAlive to prevent infinite sync loops") name the actual mechanism rather than the
  symptom, which made this review much faster.
- Project rules 11/14/16 are well written but unenforced. The 50 standing analyzer issues and the
  74-commit-stale walkthrough are both what happens when a good rule has no CI behind it.

## Commands run to verify

### Round 1

```
git log --oneline c31a74f..HEAD | wc -l                          # 74 — walkthrough staleness (finding 9)
git rev-parse --short HEAD                                       # e306dcb — the reviewed base
dotnet build                                                     # 0 errors, 6 NU1603 warnings
dotnet test --nologo                                             # 45 passed, 0 failed
flutter analyze                                                  # 50 issues (1 warning, 49 info)
flutter test                                                     # 58 passed
dotnet run --project src/Web/                                    # live server on :5000 against local Postgres
curl -s -i http://localhost:5000/api/v1/analytics/heatmap        # 200 OK, no token       (finding 1)
curl -s -i http://localhost:5000/api/v1/habits                   # 401 — negative control (finding 1)
# register 2 accounts, complete 1 event each on 2031-03-05, read heatmap anonymously between steps
#   -> count 1 then 2: proves cross-user aggregation             (finding 1)
dotnet test --filter "FullyQualifiedName~ZZ_TempXpAsymmetryProbe"  # net -8 XP; probe deleted after (finding 2)
grep -c "Executed DbCommand" server.log                          # 6 SQL statements for one toggle (finding 4)
grep 'UPDATE "' server.log                                       # 3 batches, each from @p0       (finding 3)
grep -E "isar|hive|sqflite|drift" apps/pubspec.yaml              # no matches                     (finding 10)
find apps/lib/features -type d -name data                        # no matches                     (finding 10)
git status --short                                               # clean after probe cleanup
```

### Round 2

```
git checkout -b fix/codebase-audit-round-1
dotnet build                                                     # 0 errors after each edit pass
dotnet test --nologo                                             # 49 passed / 0 failed
dotnet ef migrations add AddAwardedXpToEvent --project src/Infrastructure --startup-project src/Web
dotnet ef database update --project src/Infrastructure --startup-project src/Web   # + backfill
flutter analyze                                                  # 50 issues — unchanged baseline
flutter test                                                     # 58 passed
dotnet run --project src/Web/                                    # live server for re-verification
curl -s -i http://localhost:5000/api/v1/analytics/heatmap        # 401 now                    (F1)
# 2 accounts, 1 completed event each on a shared date, heatmap read per account -> 1 and 1  (F1)
# complete 1 event (+10), 4 more days, un-tick the first -> 50 then 40, net 0               (F2)
env "Logging__LogLevel__Microsoft.EntityFrameworkCore.Database.Transaction=Debug" dotnet run --project src/Web/
grep -oE '(Beginning|Committing|Committed) transaction|UPDATE "[A-Za-z]+"' server4.log  # 1 tx  (F3)
grep -A1 'FROM "Events" AS e' server2.log                        # every read has a WHERE     (F4)
```

### Test data note

The runtime checks in both rounds registered throwaway accounts on the local `habit-tracker`
database, each with one or two events dated 2031–2032. They are harmless but can be removed:

```sql
-- covers round 1 (probe_*) and round 2 (vfy_*, xp_*, sql_*, tx_*, tx2_*)
DELETE FROM "Events" WHERE "UserId" IN (SELECT "Id" FROM "AspNetUsers" WHERE "Email" LIKE '%@example.com');
DELETE FROM "Habits" WHERE "UserId" IN (SELECT "Id" FROM "AspNetUsers" WHERE "Email" LIKE '%@example.com');
DELETE FROM "AspNetUsers" WHERE "Email" LIKE '%@example.com';
```
