# Code review: `feat/plan-vs-actual`

Base: `a1fbea1` (tip of `feat/streak-at-risk`) · Reviewed by: Claude Code

| Round | Commit | Date | Outcome |
| --- | --- | --- | --- |
| 1 | `cdee12e` feat(analytics): show booked time against the time it actually took | 2026-09-12 | 0 HIGH, 1 MEDIUM, 1 LOW, 2 INFO — **MEDIUM 1 blocks merge** |

> **The base is not `main`.** This branch is stacked on the unmerged `feat/streak-at-risk`:
> `git merge-base HEAD feat/streak-at-risk` is `a1fbea1`, which is that branch's tip. A
> three-dot diff against `main` pulls in 4 unrelated commits and 2 582 lines of
> streak-at-risk work, all of it already reviewed in `review-streak-at-risk.md` (rounds 1-5).
> Everything below is measured on `a1fbea1...HEAD`, which is exactly one commit, `cdee12e`.
> `46ab5a5` — which addresses that report's round-5 findings 19 and 20 — sits on the
> streak branch, not this one, and belongs to that review.

---

# Round 1 — review `cdee12e`

## Scope

15 files, +1 072 / −6. A full-stack vertical slice: one query, one endpoint, one card.

| File | Change |
| --- | --- |
| `server/src/Domain/Entities/PlanVsActual.cs` | +34 — new. The shape a `GROUP BY` returns, like `DailyActivity` |
| `server/src/Domain/Interfaces/IEventRepository.cs` | +18 — `GetPlanVsActualByHabitAsync`, `…ByCategoryAsync` |
| `server/src/Infrastructure/Repositories/EventRepository.cs` | +59 — the two raw SQL aggregates |
| `server/src/Application/.../GetPlanVsActual/GetPlanVsActualQuery.cs` | +118 — new. Two DTOs, the query, the handler |
| `server/src/Web/Endpoints/V1/Analytics.cs` | +18 — `GET plan-vs-actual` on the existing group |
| `server/tests/.../GetPlanVsActualQueryHandlerTests.cs` | +142 — 9 handler tests, repository mocked |
| `apps/lib/features/home/domain/models/plan_vs_actual.dart` | +81 — new. `PlanVsActualItem`, `PlanVsActual`, `ratio` |
| `apps/lib/features/home/presentation/widgets/plan_vs_actual_card.dart` | +280 — new. Card, rows, ratio bar, category toggle, error row |
| `apps/lib/features/home/presentation/providers/plan_vs_actual_provider.dart` | +22 — new. `FutureProvider.autoDispose`, retry off |
| `apps/lib/core/network/api_service.dart` | +11 — `fetchPlanVsActual` |
| `apps/lib/core/localization/locale_provider.dart` | +54 — 13 keys × en/vi |
| `apps/lib/features/home/presentation/home_screen.dart` | +7 — the card, and the provider in pull-to-refresh |
| `apps/test/.../plan_vs_actual_test.dart`, `plan_vs_actual_card_test.dart` | +211 — 5 model + 7 widget tests |
| `docs/feature-roadmap.md` | +23/−6 — 2.1 closed, limits recorded |

## Parts verified as correct

### The two new SQL aggregates run against the real schema — verified, because nothing in the repo can

CLAUDE.md is explicit that the test project's InMemory provider "only covers plain LINQ: SQL,
indexes and constraint errors need a real Postgres", and the 9 new server tests mock
`IEventRepository`. So this SQL had never been executed by anything. I ran both methods
through the real `EventRepository` against the dev database (temporary read-only probe, since
deleted):

```
PROBE byHabit rows=3
PROBE   habit 'Read 10 pages' sessions=31 planned=1860 actual=1012
PROBE   habit 'Morning Run'   sessions=13 planned=780  actual=574
PROBE   habit 'Team Standup'  sessions=21 planned=630  actual=480
PROBE byCategory rows=0
```

Both execute. Column quoting, the `::text` join, `EXTRACT(EPOCH FROM …)/60.0`, the
`COALESCE`/`ROUND`/`::int` stack and `SqlQuery<PlanVsActual>` materialisation all work, and
the ordering claim holds — 1012, 574, 480 is descending by recorded time, as
`ORDER BY SUM(…) DESC, h."Name"` promises.

### The window is the same one the activity card uses, not a second definition

`GetPlanVsActualQuery.cs:88-91` goes through `StreakCalculator.DefaultDayBoundaryOffset` and
`ToLocalDate`, and `MinDays`/`MaxDays` are `= GetActivitySummaryQueryHandler.MinDays/MaxDays`
rather than copies. Two cards on one screen that both say "last 14 days" cannot disagree,
and the clamp is tested (`ClampsTheWindow`, `AsksForTheSameWindowTheActivityCardUses`).
Measured window at review time: `2026-08-29T17:00:00Z .. 2026-09-12T17:00:00Z` — 14 days of
UTC+7 local days, correct.

### Only finished sessions take part, and the reasoning is right

`WHERE e."ActualDuration" IS NOT NULL` on both queries. The entity's remarks and the roadmap
both explain why: comparing every booked event's target against the recorded time of the few
that were done would read as "you always overrun", when the real answer is "you did 4 of the
9 you booked" — which the activity card already gives. Correct call, and it keeps the two
sides of the comparison describing the same sessions.

### Zero `TargetDuration` was anticipated and handled

`TargetDuration` is a non-nullable `TimeSpan`, so an event that never got one carries
`00:00:00` rather than NULL — `COALESCE` would not have saved it. `PlanVsActualItem.ratio`
(`plan_vs_actual.dart:30`) returns `null` rather than `0` or infinity, the card prints
`home_plan_actual_no_target` instead of drawing a bar, and a test covers it (`a habit with no
booked time gets no bar and says why`). The doc comment even says the server "should not send
but can". Nothing in the dev DB currently has a zero target (`with TargetDuration = 0 → 0`),
so this was reasoned out rather than hit.

### The endpoint follows the project's conventions exactly

`Analytics` already subclasses `EndpointGroupBase`, so `plan-vs-actual` needed no
registration. `RequireAuthorization()` is on the group, `userId` comes from
`ClaimsPrincipal.FindFirstValue(ClaimTypes.NameIdentifier)` and never from the query string
(with the comment recording that the heatmap endpoint was once found returning every user's
data), and the return is a `Results<Ok<…>, UnauthorizedHttpResult>` union. The handler also
rejects an empty `UserId` (`RefusesAQueryWithNoUser`).

### The two repository calls are sequential on purpose, and must stay that way

`GetPlanVsActualQuery.cs:93-94` awaits them one after the other. They share one
`ApplicationDbContext`, which is not thread-safe, so `Task.WhenAll` here would be a bug —
worth recording so a future "optimisation" does not introduce one.

### The provider is shaped like its neighbour, including the parts that are easy to get wrong

`FutureProvider.autoDispose` with `retry: (_, _) => null`, and it deliberately does **not**
watch `eventsProvider` — which would turn every SignalR push and background sync into another
request. The card offers its own "Try again", and a test asserts the absence of automatic
retry (`offers a retry when the request fails, and does not retry on its own`). Pull-to-refresh
invalidates it alongside the other three.

### i18n is complete

All 13 new keys carry both locales — checked mechanically rather than by eye:

```
home_plan_actual_title en=1 vi=1      home_plan_actual_over en=1 vi=1
home_plan_actual_subtitle en=1 vi=1   home_plan_actual_under en=1 vi=1
home_plan_actual_headline en=1 vi=1   home_plan_actual_as_booked en=1 vi=1
home_plan_actual_pair en=1 vi=1       home_plan_actual_no_target en=1 vi=1
home_plan_actual_sessions en=1 vi=1   home_plan_actual_show_categories en=1 vi=1
home_plan_actual_empty en=1 vi=1      home_plan_actual_hide_categories en=1 vi=1
home_plan_actual_error en=1 vi=1
```

Counts go through `{n}`/`{d}`/`{s}` params, so no string is assembled by concatenation. The
ratio bar clamps to `0.0..1.0` and recolours above 1.0 instead of overflowing its track
(`plan_vs_actual_card.dart:200-210`) — the one place an unbounded ratio could have broken
layout.

## Round 1 findings

### 1 [MEDIUM] A finished session with no habit is counted nowhere, so the card tells a user with data that they have none

`EventRepository.cs:46` joins habits with an **inner** join:

```sql
FROM "Events" e
JOIN "Habits" h ON h."Id"::text = e."HabitId"
```

`Event.HabitId` is a non-nullable `string` defaulting to `string.Empty`
(`Event.cs:11`), and `CreateEventCommand` passes it straight through
(`CreateEventCommand.cs:26,66`) — so a calendar event with no habit is normal, not
corrupt data. `CompleteEventSessionCommand` writes `ActualDuration` on any event and only
touches the habit if one parses (`CompleteEventSessionCommand.cs:95,133`), so such an event
can absolutely be a finished focus session. `''` matches no `uuid::text`, so every one of
them drops out of the join.

That alone would only shorten the habit list. The consequence is larger because the totals
are derived from that grouping (`GetPlanVsActualQuery.cs:102-104`):

```csharp
result.TotalSessions = result.ByHabit.Sum(i => i.Sessions);
result.TotalPlannedMinutes = result.ByHabit.Sum(i => i.PlannedMinutes);
result.TotalActualMinutes = result.ByHabit.Sum(i => i.ActualMinutes);
```

with the reason given on the DTO: *"an event has at most one habit, so that grouping counts
every session exactly once."* The premise is half right. An event has **at most** one habit —
which is the argument against double-counting — but it may have **none**, and the habit
grouping then counts it **zero** times.

Measured on the dev database, per user, over all finished sessions:

```
PROBE per-user 48a67a1e-231e-4601-a20d-f783e7539784 all=17 withHabit=0  actualAll=855 actualWithHabit=0
PROBE per-user u1                                   all=65 withHabit=65 actualAll=2066 actualWithHabit=2066
PROBE   HabitId = '' (standalone event)        = 17
PROBE   HabitId set but no such habit (orphan) = 0
```

And inside the card's **live 14-day window** at review time:

```
PROBE window 2026-08-29T17:00:00Z .. 2026-09-12T17:00:00Z
PROBE in-window 48a67a1e-231e-4601-a20d-f783e7539784 inWindow=15 withHabit=0 actualAll=790
```

`u1` — the seeded demo user, every one of whose events has a habit — has nothing in the
window. The only account with data in the window right now has **15 finished sessions and 790
recorded minutes, none of them reachable by the habit join**. For that user the server returns
`ByHabit: []`, `TotalSessions: 0`, `TotalPlannedMinutes: 0`, `TotalActualMinutes: 0`.

The client then turns zero totals into the empty state. `PlanVsActual.isEmpty` is
`totalSessions == 0` (`plan_vs_actual.dart:64`) and the card branches on it before rendering
anything, category rows included (`plan_vs_actual_card.dart:58-63`). Measured with a widget
probe, feeding the card exactly what the server produces for such a user — except with
categories present, to show that even the fallback view is unreachable:

```
PROBE isEmpty=true byCategory=2 categoryActualMinutes=790
PROBE rendered: "Planned vs actual"
PROBE rendered: "Finished sessions, last 14 days"
PROBE rendered: "Finish a focus session and the comparison shows up here."
PROBE shows "Deep work"? false
```

The card says *"Finish a focus session and the comparison shows up here"* to a user who
finished fifteen.

Impact: for anyone who tracks focus time on plain calendar events rather than habit-linked
ones, the feature is invisible and looks broken — and the copy blames them for it. It is not
a rare shape: 17 of the 82 finished sessions in the dev database are exactly this. The second
trigger is deletion — a habit removed while its events remain would move that habit's history
into the same blind spot (0 such rows today, so unverified in practice, but the same inner
join). The reason this was not caught is that `u1`, the user everything is demonstrated
against, has a habit on every event.

The premise is repeated in three places, so all three need the same correction:
`PlanVsActualDto.Total*`'s summary (`GetPlanVsActualQuery.cs:33-36`), the roadmap's "Limits
worth knowing" (`feature-roadmap.md`: *"the totals come from the habit grouping, because an
event has at most one habit but a category can be shared"*), and the handler test
`TotalsComeFromTheHabitGrouping_SoNoSessionIsCountedTwice`, which pins the current behaviour
and would have to change with it.

**Fix** — the totals should come from the sessions, not from one grouping of them. Cheapest
version that keeps one round trip per grouping: have the repository also return the window's
unguarded totals, or compute them from a third tiny aggregate with no join at all:

```sql
SELECT COUNT(*)::int                                                        AS "Sessions",
       COALESCE(ROUND(SUM(EXTRACT(EPOCH FROM e."TargetDuration"))/60.0),0)::int AS "PlannedMinutes",
       COALESCE(ROUND(SUM(EXTRACT(EPOCH FROM e."ActualDuration"))/60.0),0)::int AS "ActualMinutes"
FROM "Events" e
WHERE e."UserId" = {userId} AND e."StartTime" >= {fromUtc} AND e."StartTime" < {toUtc}
  AND e."ActualDuration" IS NOT NULL
```

That makes the headline honest without double-counting anything, and `isEmpty` then means
what it says. Separately decide what the *list* does with habitless sessions — leaving them
out of `ByHabit` is defensible (there is no habit to name), but then the card needs a row or
a footnote for "not linked to a habit", the way the category grouping deliberately leaves
uncategorised events to the client. Whichever way that goes, a handler test with a habit
grouping that does **not** account for every session is the test that is missing.

### 2 [LOW] The category query runs on every load and returns nothing for any user in the database

`GetPlanVsActualByCategoryAsync` is awaited unconditionally on every request
(`GetPlanVsActualQuery.cs:94`), and the card only ever reveals it when there is more than one
category (`plan_vs_actual_card.dart:91`):

```dart
if (report.byCategory.length > 1) ...[
```

Measured: `byCategory rows=0` for the user with data, and `habitless but has a category = 0`
— no finished session in the dev database carries a `CategoryId` at all. So today the second
query is a round trip that returns an empty set, feeding a view that would stay hidden even
if it returned one row.

Impact: small and not wrong — a second aggregate over an indexed window, once per visit to
Home (the provider is `autoDispose` and does not watch `eventsProvider`, so it is not
per-rebuild). Worth recording for two reasons: the untested half of the feature is the half
with no data behind it, and `ORDER BY … , c."Name"` plus the `length > 1` gate means nobody
has seen this path render. If categories are not part of how this product is actually used,
the honest move is to drop the grouping rather than carry a query and 100 lines of card for
it; if they are, it needs a fixture with two categories in the widget tests — which, to be
fair, `the category view is behind a tap, and only with several categories` already provides
synthetically.

### 3 [INFO] This is the third consumer of the hardcoded UTC+7 day boundary

`GetPlanVsActualQuery.cs:88` takes `StreakCalculator.DefaultDayBoundaryOffset`, which is the
right thing to do — it reuses the shared definition instead of inventing a fourth. But
roadmap 5.1 currently describes "two clocks to reconcile, not one" (the server's UTC+7 day
and the streak-at-risk cutoff's device-local hour). It is now three: this card's 14-day window
is also filed under UTC+7, so for a user outside that zone the window is shifted by up to a
day at both ends, and the "last 14 days" this card shows is the same 14 days the activity card
shows but not the same 14 days the user lived. No code change — 5.1's inventory should gain
this consumer so whoever does it knows what moves.

### 4 [INFO] `plan_vs_actual_card_test.dart` imports its fixture from another test file

`plan_vs_actual_card_test.dart:9`:

```dart
import '../domain/plan_vs_actual_test.dart' show serverResponse;
```

It works and it keeps one definition of the server's payload shape, which is the right
instinct. But it makes the domain test file a de-facto fixture library, so running the card
test compiles and registers the domain test's `main()` too, and a rename in one test file
breaks another. `test/test_utils.dart` is where this project already puts shared test
scaffolding — `serverResponse` belongs there, or in a `test/fixtures/` file next to it.

## Round 1 verification

| Item | Result |
| --- | --- |
| `dotnet build` | 0 warnings, 0 errors (14.9 s) |
| `dotnet test` | **153 pass / 0 fail** (144 before this branch; +9 handler tests) |
| `flutter analyze` | `No issues found!` |
| `flutter test` | **246 pass / 0 fail** (234 before this branch; +12 model and widget tests) |
| Both new SQL queries executed against real Postgres | ✔ both run; 3 habit rows, 0 category rows |
| Ordering claim ("busiest first") | ✔ 1012 / 574 / 480 recorded minutes, descending |
| Window at review time | ✔ `2026-08-29T17:00Z .. 2026-09-12T17:00Z` — 14 UTC+7 days |
| Endpoint auth | ✔ `RequireAuthorization()` on the group; `userId` from the token only |
| i18n | ✔ 13/13 keys with en + vi |
| Finished sessions the totals can see | **65 of 82** across the DB; **0 of 15** in the live window |
| `git status --porcelain` after probes | empty (probe files deleted) |

## Out-of-scope notes

- **The raw SQL in `EventRepository` has no executing test, and that predates this branch.**
  The only test file that ever constructs the real `EventRepository` was my temporary probe;
  `GetDailyActivityAsync` established the pattern and its handler test mocks the repository
  too. So this branch follows the house style rather than breaking it — but it doubles the
  amount of SQL that `dotnet build` and all 153 tests would pass straight over. A renamed
  column would ship green. Worth a single integration test project against a real Postgres at
  some point; not this branch's debt to pay alone.
- **`u1` is the only well-populated account and it is unrepresentative.** Every one of its 65
  finished sessions has a habit and none carry a category, which is exactly the shape that
  hides finding 1 and leaves finding 2 unexercised. A seed user with a habitless tracked
  session and two categories would have caught both before review.
- Findings 11 and 13 of `review-streak-at-risk.md` remain open by choice there; nothing in
  this branch touches them.
