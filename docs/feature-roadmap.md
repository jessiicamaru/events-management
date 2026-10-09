# Feature roadmap

Idea backlog for the Habit Tracker, with enough grounding that each item can be picked up
without re-deriving it. Ordered by value ÷ effort within each section, not by excitement.

**Last updated:** 2026-09-13 · **Status key:** 🟢 done · 🟡 in progress · ⚪ not started

**Deliberately excluded: AI / LLM features.** Not wanted for this product. Nothing below
needs machine learning, a trained model, or a dataset — every "smart" item here is a SQL
aggregate or a small heuristic over data the app already stores.

---

## Why this list looks the way it does

The app already records several things it never shows the user. That is where the cheapest
wins are: no new data collection, no schema change, just a query and a chart.

| Field | Where it comes from | Currently | Could tell the user |
| --- | --- | --- | --- |
| `Event.ActualDuration` | every completed focus session | written, shown once in the post-session dialog, never aggregated | "You schedule 30 min for Reading, you average 18" |
| `EventTask.EstimatedMinutes` | task editor | written, never read back | how far off your time estimates are, by category |
| `Habit.TargetDays` | habit editor (1=Mon … 7=Sun) | used to suggest scheduling only | "You keep Mon–Wed 90%, Friday 20%" |
| `Event.StartTime` hour | every event | — | "85% of your 7am sessions finish; 40% of evening ones" |
| `Event.RecurrenceExceptionDates` | skipping an occurrence | rendering only | which occurrences get skipped, and when in the week |
| `Event.AwardedXp` | added 2026-09-09 (PR #23) | XP refunds | per-event effort signal over time |
| `Event.CreatedAt` vs `StartTime` | every event | — | how far ahead this user plans |

⚠️ **Hard constraint for anything in the Analytics section.** PR #23 fixed several handlers
that loaded the whole `Events` table into memory to compute one number. Analytics is exactly
where that instinct returns. Every panel must be a `GROUP BY` in Postgres returning a handful
of rows — never "fetch events, aggregate in C#". If a panel gets slow, add a nightly rollup
table; do not write a cleverer in-memory loop. See
`docs/review-code-reports/review-main-codebase-audit.md` findings 1 and 4.

---

## 1. Engagement — the loop

The app can track a habit but never asks for attention. This section is the biggest gap and
should come before charts.

### 🟢 1.1 Event reminders (local notifications)

**Done — PR #24.** See `docs/notifications-and-reminders.md` for the design, the Android
permission matrix, and how to test it on an emulator. PR #25 fixed two gaps found later:
reminder edits were dropped by the update endpoint, and browsing the calendar to another
month cancelled every pending reminder.

Scheduled on-device notifications a configurable number of minutes before an event starts.
No server, no FCM, works offline.

### 🟢 1.2 Streak-at-risk nudge

**Done — PR #27.** A habit counts as at risk when its streak is
alive, it has an unfinished occurrence today, and the local time has passed
`AppConstants.streakAtRiskHour` (20:00). `StreakAtRisk.evaluate` decides it, Home shows a
card above the agenda, and `StreakNudgePlanner` schedules one notification per evening at
the cutoff — one for the evening, not one per habit — for the next
`AppConstants.streakNudgeEvenings` (2) evenings, so a day the app is never opened still gets
its nudge. The switch is in Settings, on by default.

The threshold is a fixed hour, not a per-habit one: the data for the second exists, but a
single hour is what makes the rule explainable. It is *not* the same decision as 5.1's day
boundary — see the note there: the cutoff is device-local while the streak day is a
hardcoded UTC+7, so 5.1 still has both halves to reconcile.

A habit already ticked today is not flagged even if another slot is still open: the streak
needs one completion per calendar day (`StreakCalculator` distincts on date), so the open
slot is a plan not followed through rather than a streak about to break.

Still open: a habit with **nothing booked** today is not flagged, because whether its
streak survives an unplanned day is exactly 5.1. The Android widgets do not show it either
— they would need the habits request, which they do not make today. And the nudge reaches
two evenings, so a phone that never opens the app for longer than that stops getting one;
extending it is a matter of raising the constant, bounded by how many alarms Android allows.

### ⚪ 1.3 Weekly review

A Sunday screen: what you did this week, what slipped, pick ≤3 habits to focus on next week.

This is what turns the Analytics section from decoration into a loop — notice → nudge →
reflect → act. Build it *after* 2.1 and 2.2 exist, and reuse their queries rather than
writing new ones.

### ⚪ 1.4 Squad challenges

Time-boxed team goals ("the squad logs 100 sessions this month") on top of the squad XP that
already exists. Squads currently have infrastructure but little to actually do together.

- Needs a `SquadChallenge` entity: goal metric, target, window, progress.
- Reuse `TotalSquadXP` accounting rather than inventing a second scoring path.

---

## 2. Analytics

Read the hard constraint above before starting any of these.

### 🟢 2.0 Home-screen activity summary

`GET /api/v1/analytics/summary?days=N` → per-day one-off scheduled / completed and focus
minutes, one `GROUP BY` in Postgres (plan: `HashAggregate`), same UTC+7 day boundary as
streaks. Shown on the home screen as three tiles and a 14-day focus-time bar chart. Done in
PR #25.

Limits worth knowing before building on it:

- **Completion has no timestamp.** `IsCompleted` is one flag per row, so "completed on
  day X" means "the event *started* on day X".
- **Repeating days are counted by the client.** A series is one row, so the server counts
  one-off events only, and `ActivitySummary.withRepeatingDays` adds every day of every
  series by expanding it (a day completed = a split-off day with `IsCompleted`, see 5.6c).
  Anything else that wants per-day numbers for repeating events has the same choice:
  expand on the client, or add a completion log (one row per occurrence done).
- **Server and client disagree on "which day" outside UTC+7.** One-off events are grouped
  by the server's UTC+7 day, repeating days by the device's local day. Same seam as 5.1.
- **Meetings synced from Google count too**, and are rarely "completed", so they pull the
  rate down. Undecided whether the card should count only the user's own habits/events.
- Focus minutes have none of these problems — `ActualDuration` is written per focus session.

### 🟢 2.1 Plan vs actual time

**Done — PR #28.** `GET /api/v1/analytics/plan-vs-actual?days=N` → three aggregates in
Postgres (one joining `Habits`, one joining `EventCategories`, and the totals with no join),
shown on Home under the activity card: the totals as a sentence, then a bar per habit with
how far over or under it ran, and the same sessions by category behind a tap.

Only sessions with an `ActualDuration` take part, so both sides describe the same sessions.
Counting every booked event's target against the recorded time of the few that were done
would read as "you always overrun" when the honest answer is "you did 4 of the 9 you
booked" — which the activity card already says.

Limits worth knowing: a zero `TargetDuration` gives no ratio rather than 0% (the card says
so instead of drawing a bar); and **the totals are their own query, not a sum of either
grouping** —
an event need not have a habit or a category, so summing one under-counts and summing both
double-counts. Each grouping carries a row for what it cannot
show — "Not linked to a habit" and "No category" — derived on the client from what its rows
leave unaccounted, so either view adds up to the headline above it.

Review finding worth remembering: deriving the totals from the habit grouping made the card
say "nothing here yet" to the one account in the dev database with sessions in the window —
15 of them, 790 minutes, every one on a plain event.

### ⚪ 2.2 Completion rate by weekday and hour

Two views from `Habit.TargetDays` + `Event.StartTime` + `IsCompleted`:

- **By weekday** — planned days vs kept days per habit.
- **By hour** — which time of day actually works for this user.

Feeds 1.2 (when is "running out") and 3.1 (when to suggest scheduling).

### ⚪ 2.3 Recurring-series funnel

For one recurring habit: scheduled → completed → skipped → deleted. The recurrence rule gives
expected occurrences; `RecurrenceExceptionDates`, child exception events and `IsCompleted`
give the drop-off. Shows *where* a habit died, not just that it did.

### ⚪ 2.4 Category time budget over time

Hours per `EventCategory` per week/month, with a trend. Categories already carry colours, so
the chart is half-built. Answers "is my life drifting".

### ⚪ 2.5 Estimate accuracy

`EventTask.EstimatedMinutes` vs reality. Uncomfortable and compelling; cheap once 2.1 exists.

---

## 3. Scheduling

### ⚪ 3.1 Smart scheduling suggestion

"When should I do this habit?" = free slots in the calendar (Google Calendar events already
sync in) ∩ the user's historically best completion hour (2.2). Two queries and a sort; reads
as intelligence. Depends on 2.2.

### ⚪ 3.2 Habit templates / starter packs

A handful of pre-built habits with sensible `TargetDays` and durations, offered at first run.
Cheap, and the empty-state problem is real for a new user.

---

## 4. Platform and data

### ⚪ 4.1 Offline-first

`docs/archive/project-plan.md` specified `isar`/`hive` for this and it was never built — there is no
local database, and providers call `ApiService` directly. This is a design task, not a library
swap: it has to fit the existing stale-while-revalidate + SignalR sync
(`docs/stale-while-revalidate-sync.md`), and the Flutter side has no repository layer to put a
cache behind. Decide the conflict-resolution story before writing code.

Worth it if people use the app while commuting. Not worth it as a checkbox.

### ⚪ 4.2 Export

CSV for events/habits, ICS for the calendar. Cheap, and it makes the data feel like the
user's own.

### ⚪ 4.3 Streak / heatmap home widget

A third Android widget beside `TodayEventsWidget` and `UpNextWidget`. The heatmap query
already exists (`/api/v1/analytics/heatmap`, now per-user).

### ⚪ 4.4 iOS widget parity

Widgets are Android-only today. The Dart bridge in `features/home_widget/` is reusable; the
native side is not.

---

## 5. Technical debt worth scheduling

Carried over from the audit; these are not features but they block or slow the above.

### ⚪ 5.1 Decide the streak day boundary

`StreakCalculator.DefaultDayBoundaryOffset` is a single app-wide UTC+7, so streaks and
heatmaps are off by a day for any user outside that zone. The seam exists (every method takes
an optional offset); the product decision does not. **Device timezone or a profile setting?**
Either way it shifts every existing user's streak, so decide before the user base grows.

The server's streak grace also caps how far 1.2 may plan ahead: `StreakCalculator` counts a
streak as alive only while its last completion is today or yesterday, so a `currentStreak`
read now is true for today and tomorrow and no further. That is why
`AppConstants.streakNudgeEvenings` is 2 and cannot rise without raising the grace — a nudge
for D+2 can fire about a streak that is already broken.

Three things now read it, not one: the streak and heatmap queries, the activity summary's
14-day window, and 2.1's plan-vs-actual window. For a user outside UTC+7 the two dashboard
cards cover the same 14 days as each other but not the 14 days that user lived.

There are now **two** clocks to reconcile, not one. 1.2 added a second: the streak-at-risk
cutoff (`AppConstants.streakAtRiskHour`) is the *device's* local 20:00, while the day it is
protecting is the server's UTC+7 day. Measured — the same 20:00 device-local moment, and the
calendar day the backend files it under:

| Device zone | 20:00 local, in UTC | Server's day |
| --- | --- | --- |
| UTC+7 | 13:00Z | same day |
| UTC+0 | 20:00Z | **next day** |
| UTC−5 | 01:00Z | **next day** |
| UTC−8 | 04:00Z | **next day** |

So for everyone west of UTC+7 the nudge already fires inside what the server counts as
tomorrow. Streaks still survive (the shift is uniform day to day, and `isAlive` accepts today
or yesterday), but whatever this item decides has to set both the boundary and the cutoff,
and in the same clock.

### ⚪ 5.2 Flutter repository layer

`ApiService` is one class holding every endpoint for every feature. There is nowhere to put a
cache (4.1) and widget tests must mock HTTP rather than an interface. Split per feature behind
interfaces.

### 🟢 5.3 De-duplicate recurrence expansion

Done. All three copies now go through `EventOccurrenceExpander`: the two in
`home_widget_service.dart`, the reminder scheduler, and the one that lived in
`command_center_panel.dart` — removed on `feat/home-page` when that panel became the home
screen's `HomeAgenda`.

### ⚪ 5.3a A malformed RRULE silently hides an event

Found while extracting the expander. `SfCalendar.getRecurrenceDateTimeCollection` returns
an **empty collection** for a malformed rule rather than throwing — measured:
`'not an rrule'`, `''` and `'FREQ=BOGUS'` all give 0 occurrences. An event with a corrupt
rule therefore disappears from the calendar, the widgets and (now) reminders, with no
error anywhere.

Pre-existing: the `catch` blocks in the original three copies never fired either. Not
fixed in `feat/event-reminders` because an empty result is indistinguishable from a rule
that legitimately has no occurrences in range (a spent `COUNT`), so falling back to the
base event would duplicate real events. **The fix is to validate the rule when it is
saved**, not when it is expanded. Both behaviours are locked by tests so a change is
deliberate.

### ⚪ 5.4 Rotate the leaked credentials

The Google `ClientSecret` and ngrok token removed from the working tree in PR #23 are still
valid and still in git history. Removing them did not revoke them. Rotate by hand in the
Google Cloud console and the ngrok dashboard.

### 🟢 5.5 Squad category authorization

**Done — PR #29.** The untraced PUT/DELETE blast radius
turned out to be the worst part. Measured against a running server with two throwaway
accounts, before the fix any signed-in caller could:

| Action on someone else's data | Before | After |
| --- | --- | --- |
| list another squad's categories | 200, leaked | **403** |
| add a category to another squad | 201, planted | **403** |
| rename a squad category they are not in | 200 | **404** |
| rename another user's **personal** category | 200 | **404** |
| delete another user's **personal** category | 200 | **404** |

The personal-category holes came from the update and delete check,
`category.UserId != request.UserId && category.SquadId != request.SquadId`, which is false
whenever both squad ids are null — so it waved through everybody. The fix decides rights from
the stored row and ignores any squad id in the request (`EventCategoryAccess`), with one
place for what membership allows (`SquadAccess`): approved members read and add; only the
leader changes or deletes shared categories, because deleting one reassigns every member's
events. A pending join request is not membership. Update and delete answer 404 rather than
403, so they do not confirm that someone else's category exists.

The review found a second door to the same data, closed in the same branch: event and habit
writes stored any `CategoryId` they were given, and plan-vs-actual read the category's name
back through the event — so a removed squad member kept seeing the squad's categories, renames
included. Writes now go through `EventCategoryAccess.CanAssignAsync` (keeping a category a row
already has is allowed, so a removed member can still edit their own events), and the one
read-back query filters by visibility in SQL. A deleted category's replacement must share its
scope, so a leader cannot move a squad's rows onto a private category.

A third door, found while writing that rule down: the SignalR hub (`SocialHub`) checked no membership
at all, so any signed-in user holding a squad id could join its live chat and post into it. Every hub
method now requires approved membership of the squad it names, and pokes and reactions an approved
target. PR #29; review report `review-squad-category-authorization.md`, rounds 3–4.

### ⚪ 5.6 Audit the never-reviewed backend

`GoogleCalendarService.cs` (517 lines), `UpdateEventCommand`/`DeleteEventCommand` (the
recurrence scopes — the most intricate logic in the app), `Squads.cs` (358 lines), and the
event/habit task commands were never reviewed. 5.5 was found by glancing at one of them.

### ⚪ 5.6a A migration exists in the database but not in the codebase

Found while setting up the local Docker database from the original dump. The dump's
`__EFMigrationsHistory` has 18 rows; `server/src/Infrastructure/Migrations/` has 17. The
missing one is:

```
20260802120420_AddDailyAnalyticsTables
```

It created `DailyUserSummaries`, `DailyCategorySummaries` and
`HourlyActivityDistributions`, and they hold data (33 / 65 rows in the dump). So **the
analytics rollup groundwork for §2 was already started and never merged into this repo.**

Nothing breaks today — EF ignores history rows it does not recognise, so the app runs
against the restored database — but the model snapshot knows nothing about those tables,
so nothing maintains them. Before starting §2, decide whether to recover that migration
(the schema is reconstructable from the dump) or design the rollup fresh. See
`local-dev/README.md`.

### 🟢 5.6c Repeating events shared one state across every day

Fixed in PR #25. Tasks and completion were stored against the series id, which every day
shares: ticking a task on Monday ticked it on every day, and finishing one session
completed the whole series — hiding it from "up next" and stopping its reminders. A day is
now split off into its own event (with a copy of the series' tasks) the first time it is
changed. See `OccurrenceMaterializer` and the sync note in CLAUDE.md.

Days split off ahead of time follow later edits of their series (review round 2), and the
dashboard counts every day of a series (2.0). Since `fix/split-off-day-safety` the database
allows one event per day of a series, so two devices touching the same day at once no
longer create two copies of it.

Still open, in `docs/review-code-reports/review-home-page.md`: MEDIUM 5 is half-open —
the repository SQL and the inbound Google sync path still have no integration test, and
this area keeps gaining code that only a live run covers. LOW: after a task is ticked, the
details dialog still acts on the series (8); the edit sheet ticks the series' task template
(9); XP can be farmed through arbitrary occurrence dates (12); refusing to complete a
series returns 404 rather than 422 (13); "update calendar" on a series day never reaches
Google (14); changing the repeat rule leaves touched days on days the new rule skips (N1).

### ⚪ 5.6b The heatmap groups in memory

`GetHeatmapQuery` loads every completed event the user has and runs `GroupBy` in C#,
against the hard constraint at the top of this file. `EventRepository.GetDailyActivityAsync`
shows the SQL shape to move it to.

### ⚪ 5.7 Background sync has no logging

The webhook and SWR paths swallow exceptions into `Console.WriteLine` inside fire-and-forget
`Task.Run`. If Google sync breaks in production there is no signal — which matches the
"sometimes works" symptom the sync docs describe. Use `ILogger`.

### 🟢 5.8 Inbound sync deleted synced events outside its window

**Done — `fix/sync-window-deletion`.** Found while rewriting the sync documentation, by reading
`SyncEventsAsync`. The sync lists one window of Google's calendar (by default 7 days back to 14 days
ahead, or the range being browsed) but its removal step treated *every* synced local event missing
from that list as deleted. It also read only the first page of the list. So each sync deleted the
user's synced history, everything past the window, and any event on a later page, together with
their tasks and recorded focus time.

Reproduced with tests that run the real `SyncEventsAsync` against a fake Google HTTP layer: on the
old code 8 of 13 failed (history, next month, a finished series, an event on page two, an event
moved on Google, and one whose lookup errored were all deleted). Now an event missing from the list
is removed only if the window could have held it (`GoogleSyncWindow.CouldBeListed`) **and** Google,
asked directly, says it is cancelled or gone; every page is read. Not yet checked against a real
Google account — that needs a throwaway account and a refresh token.

The fix first suggested here, taking candidates from `GetEventsForUserAsync(userId, windowStart,
windowEnd)`, would not have been enough: that query returns every split-off day whatever its date.

---

## Suggested order

One loop at a time beats five disconnected features:

1. ~~**1.1 reminders**~~ — done (PR #24)
2. ~~**1.2 streak-at-risk**~~ — done (PR #27)
3. ~~**2.1 plan vs actual**~~ — done (PR #28)
4. **2.2 weekday/hour rates** — unlocks 1.2's threshold and 3.1
5. **1.3 weekly review** — wraps 2.1 and 2.2 into a habit of its own

~~**5.8**~~, which deleted synced history, is fixed. Slot **5.1** in before the user base grows, and
**5.4** whenever you next have ten minutes.
