# Code review: `feat/streak-at-risk`

Base: `13b0f52` (local `main`, merge of PR #26) · Reviewed by: Claude Code

| Round | Commit | Date | Outcome |
| --- | --- | --- | --- |
| 1 | `622eb9b` feat(home): nudge a streak that is about to break, and reorganise the docs | 2026-09-12 | 0 HIGH, 2 MEDIUM, 5 LOW, 6 INFO — **MEDIUM 1 and 2 block merge** |
| 2 | uncommitted working tree (fixes applied on top of `622eb9b`) | 2026-09-12 | 11 closed (both MEDIUM), 2 INFO open by choice; 1 finding **corrected** (5) and 1 **re-explained** (7). No new findings. **Nothing blocking.** |
| 3 | `2473aa2` fix(home): address the review of the streak-at-risk nudge (round 2, now committed) | 2026-09-12 | Round 2 re-verified independently, all 11 closures hold, 0 re-opened. 5 new: 1 MEDIUM, 1 LOW, 3 INFO — **MEDIUM 14 blocks merge** |
| 4 | uncommitted working tree (fixes for round 3) | 2026-09-12 | 4 closed (the MEDIUM and 3 INFO), 1 closed by decision (15, the planner now reaches two evenings). 1 round-3 claim **qualified** (the probe technique). No new findings. **Nothing blocking.** |
| 5 | `5de7052` fix(notifications): plan the nudge two evenings ahead, and take the clock off the wall (round 4, now committed) | 2026-09-12 | Round 4 re-verified independently, all 5 closures hold, 0 re-opened; finding 14 confirmed by the clock (suite run at 22:04). 2 new LOW, both doc/guard-rail. **Nothing blocking.** |
| 6 | uncommitted working tree (fixes for round 5) | 2026-09-12 | Both LOW closed, one with a test that fails if the constant is raised. Round 5's two load-bearing claims re-verified against the server. No new findings. **Nothing blocking.** |

> `main` is the branch's real base: `git log main..HEAD` is `622eb9b` (round 1), `2473aa2`
> (round 2's fixes), `53cd5cc` (the report), `5de7052` (round 4's fixes) — so the three-dot
> diff is the branch's real scope. No drift adjustment needed.

---

# Round 6 — uncommitted working tree (fixes for round 5)

Round 5's two findings, fixed. Both rested on a claim about code this branch does not touch,
so both claims were checked against the source before acting.

## Status of round 5 findings

| # | Finding | Status |
| --- | --- | --- |
| 19 | [LOW] `streakNudgeEvenings` documents the wrong upper bound | ✅ **Closed** — the comment now names the server's grace as the limit, and a test pins the value |
| 20 | [LOW] "At most one nudge" still stated in four places | ✅ **Closed** — all four rewritten |
| 11, 13 | open by choice since round 2 | ⚠️ Unchanged |

### Finding 19 — closed, and the claim behind it verified

The finding's load-bearing claim is about the server, so it was read there rather than taken
from the report. `StreakCalculator.cs:90-93`:

```csharp
// A streak only "counts" while it is still alive: it must reach today, or yesterday
// (the user still has today to keep it going).
var today = ToLocalDate(DateTime.UtcNow, offset);
var isAlive = previous!.Value == today || previous.Value == today.AddDays(-1);
```

So a `currentStreak` the client planned from is true for today and tomorrow, and wrong from
the day after — which is exactly two evenings. Round 5 is right, and right about the id space
being slack rather than binding (`0x7FFFFFF0 + 1 = 2 147 483 633`, 14 below the ceiling, so
16 evenings would fit).

Fixed where the next person will look: the constant's own comment now leads with "Two is the
ceiling, and the limit is the server's", explains what a D+2 nudge would claim, and demotes
the id space to a parenthesis. The same sentence is recorded in roadmap 5.1, next to the two
clocks it already reconciles.

And pinned, because round 5's point was that nothing failed if the value moved — `evenings` is
a parameter and the test that exercises it passes its own value:

| | Before | After |
| --- | --- | --- |
| `streakNudgeEvenings = 5` | whole suite passes; 3 of the 5 alarms protect a dead streak | **2 tests fail**, naming the server's grace as the reason |

### Finding 20 — closed: four statements, all four rewritten

| Where | Now reads |
| --- | --- |
| `app_constants.dart:79-82` | "one nudge per planned evening ([streakNudgeEvenings]), at consecutive ids from this base" |
| `streak_nudge_planner.dart:15` | "One nudge per evening in range, never one per habit" — keeping the claim that is still true, that several habits share one notification |
| `notifications-and-reminders.md:164` | "event reminders plus up to `streakNudgeEvenings` nudges" |
| `notifications-and-reminders.md:179` | **Ids.** — a fixed base plus the evening's index, replacing **A fixed id.** eight lines above the paragraph that contradicted it |

`grep -rn "at most one nudge" apps/lib docs` now returns nothing outside this report.

## Round 6 verification

| Item | Round 5 | Round 6 |
| --- | --- | --- |
| `flutter test` | 234 pass / 0 fail | **235 pass / 0 fail** (the new ceiling test) |
| `flutter analyze` | `No issues found!` | `No issues found!` |
| Negative control: `streakNudgeEvenings = 5` | suite passed — the finding | **2 tests fail** |
| `grep -rn "at most one nudge"` outside this report | 4 hits | **0** |
| `StreakCalculator` grace read at source | quoted by round 5 | ✔ re-read: `isAlive` is today or yesterday |
| `dotnet test` | not re-run | not re-run — still 0 server files in `main...HEAD` |

## Round 6 notes

- Both findings were documentation-shaped, and both were created by round 4's behaviour
  change rather than by the original commit — the pattern round 5 names (a correct change
  leaving the sentences that explained the old design standing next to it) is now at three
  occurrences across the branch, and the fix each time was cheap.
- Finding 19 is the only one of the 20 that protects a future change rather than current
  behaviour, and it is the one that got a test.

---

# Round 5 — review `5de7052`, independent verification of round 4

Round 4 was written against an uncommitted tree; that tree is now `5de7052`
(`fix(notifications): plan the nudge two evenings ahead, and take the clock off the wall`)
and `git status` is clean. Every round-4 claim was re-run here.

This round had one advantage round 4 did not: it ran at **22:04 local**, inside the
20:00–23:59 window round 3 predicted would fail. So finding 14 could be verified the direct
way — by the clock — instead of by the lowered-cutoff proxy.

## Verifying round 4's claims

| Round 4 claimed | I verified with | Result |
| --- | --- | --- |
| `flutter test` → 234 pass / 0 fail | `flutter test` at 22:04 local | ✔ `00:28 +234: All tests passed!` |
| `flutter analyze` → clean | `flutter analyze` | ✔ `No issues found! (ran in 8.8s)` |
| Finding 14 closed — the hour cannot reach the tests | ran the whole suite **after 20:00** (22:04:10 → 22:04:45) | ✔ 234 pass — see below for the before/after |
| …by taking the scheduling path off the wall clock | `grep -n 'DateTime.now()\|clock.now()'` over the four streak source files and their three test files | ✔ no wall-clock read left on the path; only comments mention `DateTime.now()` |
| Finding 15 closed — two evenings are planned | probe: habit booked tonight and tomorrow, planned 09:00 | ✔ `9/12 20:00 id=2147483632`, `9/13 20:00 id=2147483633` |
| …each evening gets its own id | same probe | ✔ distinct, consecutive from the base |
| Finding 16 closed — `fakeAsync(initialTime:)` | read `home_clock_provider_test.dart:13-16,42` | ✔ both tests pinned to a fixed morning |
| Finding 17 closed — `4 million×` | `reminder_planner.dart:180`; `1073741824 / 250 = 4294967` | ✔ |
| Finding 18 closed — uses `commonTestOverrides` | `reminder_sync_provider_test.dart:15,112`; the local copy is gone | ✔ |
| "the cutoff-moved probe also fails 5 tests, and they hardcode the hour" | `flutter test` with `streakAtRiskHour = 17` | ✔ **229 pass / 5 fail**, all 5 in `streak_at_risk_test.dart`, all 5 asserting the hour itself |
| "`grep -rn 'DateTime.now()' test/` → 9 hits in 5 files" | same grep | ✔ 9 hits, 5 files; the only streak-path one is `home_screen_test.dart:36` |
| `dotnet test` not re-run, 0 server files | `git diff --name-only main...HEAD` → no `server/` entry | ✔ |

### Finding 14 — measured before and after, at the same instant

Round 3 proved this by lowering the cutoff, because it ran at 18:0x. Running at 22:0x, the
real comparison is available. `2473aa2`'s three files (provider, planner, test) checked out
into the tree, run, then restored:

| Same instant, 22:07 local | Result |
| --- | --- |
| `2473aa2` (round 3's state) | **3 fail** — `sends event reminders and the streak nudge in ONE applyPlan call`, `builds the nudge body from the habit…`, `names the other habits at risk…` |
| `5de7052` (now) | **0 fail** (234 pass, whole suite, 22:04) |

The three failures are exactly the three round 3 named, so round 3's count was right and its
proxy was measuring the right thing. Round 4's qualification of that probe is also right, and
worth keeping: with the constant lowered, five tests in `streak_at_risk_test.dart` fail
because they hardcode 20:00 in their fixtures, not because they read a clock. The probe is
sound for the scheduling tests and is not a general clock-dependence detector.

Round 4's five closures all hold. Two new findings, both LOW, both about what the
two-evening change did to the statements around it.

## New findings

### 19 [LOW] `streakNudgeEvenings` documents the wrong upper bound — the real limit is 2, and it is on the server

`app_constants.dart:97-98` closes the new constant's comment with the constraint to respect
when changing it:

> Ids run from [streakNudgeNotificationId] upwards, one per evening, so this must stay
> small enough that they do not run past the signed 32-bit ceiling.

That constraint is real but slack. Measured: `0x7FFFFFF0 + 2 - 1 = 2 147 483 633` against a
ceiling of `2 147 483 647` — **14 spare**, so the id space alone permits 16 evenings.

The binding constraint is somewhere else entirely, and unmentioned:
`StreakCalculator.FromStartTimes` (`server/src/Application/Common/StreakCalculator.cs:88-89`)

```csharp
var today = ToLocalDate(DateTime.UtcNow, offset);
var isAlive = previous!.Value == today || previous.Value == today.AddDays(-1);
```

A streak whose last completion was day D reports `currentStreak > 0` on D and on D+1, and
`0` from D+2. The planner decides every evening in range from the habit list as it stands at
planning time, and `StreakAtRisk.evaluate` gates on `currentStreak > 0` — confirmed by
holding the events fixed and setting the streak to 0, which takes the plan from 2 nudges to
**0**. So planning D and D+1 is exactly as far as today's streak value stays true. **Two is
the maximum truthful value, and it matches `isAlive`'s one-day grace by coincidence of
reading, not by anything written down.**

Nothing stops it moving. `evenings` is a named parameter with the constant as its default,
and the test that exercises it (`stays inside the evenings it was given`) passes its own
value — so no test fails if the constant changes. Measured with the parameter alone, no
source edit:

```
PROBE evenings=2 -> 9/12 id=2147483632, 9/13 id=2147483633
PROBE evenings=4 -> 9/12 id=2147483632, 9/13 id=2147483633, 9/14 id=2147483634, 9/15 id=2147483635
```

At `evenings = 4`, the 9/14 and 9/15 alarms are scheduled for days on which the streak they
are protecting is already dead under the server's own rule — the notification would read
"Still open today — finish it to keep your streak" about a streak that broke two nights
earlier. That is the failure mode round 1's finding 1 was about: a nudge that is wrong on its
face is how the switch gets turned off, and it is on by default.

Impact: none today, because the value is 2. It is a trap for the next change, and the comment
points the reader at the wrong guard rail — "plenty of room below 2^31" invites 5.

**Fix**: say which limit actually binds, in the constant's comment and in the roadmap 5.1
note where the two clocks are already reconciled:

> Two, and two is the ceiling: `StreakCalculator` reports a streak as alive on the
> completion day and the day after, so a nudge planned further out than D+1 can fire about a
> streak that is already broken. Raising this needs the server's `isAlive` grace raised
> first. (The id space allows 16, which is not the binding constraint.)

Worth a test as well, since nothing currently pins it — a one-liner asserting
`streakNudgeEvenings <= 2` with that reason as the `reason:` string would fail the day
somebody bumps it.

### 20 [LOW] "At most one nudge" is still stated in four places, and the docs now contradict themselves eight lines apart

Round 4 changed the invariant from one pending nudge at a fixed id to `streakNudgeEvenings`
nudges at consecutive ids, and updated the paragraphs it added without revisiting the ones
that asserted the old rule:

| Where | Says | Now |
| --- | --- | --- |
| `app_constants.dart:80-81` | "there is **at most one nudge pending at a time**, and replanning must replace it rather than stack a second one" | up to 2, at 2 ids — and this is the comment on `streakNudgeNotificationId`, directly above the new `streakNudgeEvenings` that broke it |
| `streak_nudge_planner.dart:15` | "**At most one nudge exists at a time.**" | class doc of the file round 4 rewrote |
| `notifications-and-reminders.md:164` | "one list — event reminders plus **at most one nudge** — and applies it once" | up to 2 |
| `notifications-and-reminders.md:179` | "**A fixed id.** There is at most one nudge pending, so re-planning must replace it rather than stack a second" | the id is no longer fixed |

The last one is the sharp edge: eight lines below it, at `:187`, the same section says "Each
evening gets its own id (`streakNudgeNotificationId + n`), or the second would overwrite the
first." A reader gets both rules in one screen, and the wrong one comes first and is bolded
as a heading.

The second sentence of the planner's class doc is still right and should stay — "Several
habits at risk are one notification, not one each" is a different claim, and true.

Impact: documentation only, but this is the third round in a row with a finding in this class
(round 1's finding 6, round 3's finding 17), and all three were in comments that justify a
design decision rather than in prose nobody reads. The id comment is the one that tells the
next person why the nudge id sits above the mask; a reader who believes "fixed, one at a
time" will not think to check that `+ evening` stays below the ceiling — which is finding 19.

**Fix**: four edits. `at most one nudge pending at a time` → `one nudge per planned evening
(AppConstants.streakNudgeEvenings), at consecutive ids from this base`; the planner's
`At most one nudge exists at a time.` → `One nudge per evening in range, never one per
habit.`; `plus at most one nudge` → `plus up to streakNudgeEvenings nudges`; and turn the
**A fixed id** paragraph into **Ids** — a fixed base plus the evening index — or delete it,
since `:187` already says it correctly.

## Round 5 verification

| Item | Round 4 | Round 5 |
| --- | --- | --- |
| `flutter test` | 234 pass / 0 fail (at 18:12) | **234 pass / 0 fail (at 22:04 — after the cutoff)** |
| `2473aa2` at the same instant | not measured | **3 fail** — the before/after round 3 predicted |
| `flutter test`, cutoff moved into the past | 229 pass / 5 fail | **229 pass / 5 fail** — reproduced, all 5 hardcode the hour |
| `flutter analyze` | `No issues found!` | `No issues found!` |
| Wall-clock reads on the streak path | — | **0** in `lib/`, 0 in its three test files |
| Nudges planned at 09:00, booked tonight + tomorrow | 2 | **2**, ids `…632`/`…633`, distinct days |
| Nudge ids vs the 32-bit ceiling | "must stay small enough" | **14 spare at 2; 16 evenings would fit** — finding 19 |
| Plan size with a full calendar | 251 (round 1, one nudge) | **252** (250 event reminders + 2 nudges); both nudges still survive the cap |
| Round 4 findings re-opened | — | **0** |
| `dotnet test` | not re-run | not re-run — 0 server files in `main...HEAD` |
| `git status --porcelain` after probes | empty | empty (constant restored, reverted files restored, scratch tests deleted) |

## Round 5 notes

- Findings 19 and 20 are the same shape: round 4's change was right, and the sentences
  explaining the old design were left standing next to it. Neither changes behaviour.
- `home_screen_test.dart:36` still reads the real `DateTime.now()` on purpose (a fixed date
  would drift out of "today"), so `HomeScreen` renders against the real hour in tests. That is
  now empirically covered on both sides of the cutoff — the suite passed at 18:0x in round 3
  and at 22:04 here — but it holds because those fixtures happen to raise no at-risk card, not
  by construction. If an at-risk fixture is ever added there, it needs `withClock`.
- Findings 11 and 13 remain open by choice on round 2's reasoning. 13 (double expansion) is
  slightly worse now — the planner runs one `expand` per evening, so two instead of one per
  re-plan — and still not worth coupling `HomeAgenda` and `StreakAtRisk` to fix.
- **Nothing blocking.** 19 and 20 are both worth doing before merge because they are comment
  edits and one test, and 19 is the one that protects the next change.

---

# Round 4 — uncommitted working tree (now committed as `5de7052`)

Round 3's findings, fixed on top of `2473aa2`. Nothing in round 3 was taken on trust: the
blocking finding was reproduced here before being fixed, and every fix has a negative control.

## Status of round 3 findings

| # | Finding | Status |
| --- | --- | --- |
| 14 | [MEDIUM] `reminderSyncProvider` tests fail from 20:00 onwards, so CI fails a sixth of the day | ✅ **Closed** — the scheduling path reads `clock.now()`; the tests pin it |
| 15 | [LOW] The nudge is only ever planned for today, so a day without the app gets none | ✅ **Closed by decision** — the planner now reaches `AppConstants.streakNudgeEvenings` (2) evenings |
| 16 | [INFO] `home_clock_provider_test` throws for one minute a day | ✅ **Closed** — `fakeAsync(initialTime: …)` |
| 17 | [INFO] The id-space comment is out by a factor of 100 | ✅ **Closed** — now "4 million×" |
| 18 | [INFO] The test file re-declares the locale overrides | ✅ **Closed** — uses `commonTestOverrides` |
| 11, 13 | open by choice in round 2 | ⚠️ Unchanged |

### Finding 14 — closed: the scheduling path has a clock

Reproduced first, with round 3's own technique (the cutoff moved into the past rather than
the clock into the future — the same comparison). Local time was 18:12:

```
$ sed -i 's/streakAtRiskHour = 20;/streakAtRiskHour = 17;/' lib/core/utils/app_constants.dart
$ flutter test test/core/notifications/reminder_sync_provider_test.dart test/features/home/presentation/home_clock_provider_test.dart
00:00 +8 -3: Some tests failed.
```

`reminder_sync_provider.dart:139` now reads `clock.now()`, the way `homeClockProvider`
already did, and the test file pins both the fixtures and the provider's clock
(`withClock(Clock.fixed(…))` inside `settle`, fixtures built from one fixed morning).

| | Before 20:00 local | From 20:00 local |
| --- | --- | --- |
| `reminderSyncProvider` tests, round 3 | 6 pass | 3 pass, 3 fail |
| `reminderSyncProvider` tests, now | 22 pass (file total) | 22 pass — the hour cannot reach them |

Negative control: `clock.now()` back to `DateTime.now()` → 2 tests fail.

### Finding 15 — closed by decision: the nudge reaches two evenings

Round 3 left this as "decide it and write it down, either is legitimate". Decided: extend it.
`StreakNudgePlanner.plan` walks `StreakAtRisk.nextCutoffAfter` for
`AppConstants.streakNudgeEvenings` (2) evenings, skipping any with nothing at risk, and gives
each its own id (`streakNudgeNotificationId + n`) so the second cannot overwrite the first.

| | Round 3 | Now |
| --- | --- | --- |
| Planned at 09:00, habit booked tonight and tomorrow | 1 nudge (tonight) | **2** (tonight 20:00, tomorrow 20:00) |
| Planned at 23:30, habit booked tomorrow | none | **1** (tomorrow 20:00) |
| Tonight done, tomorrow booked | 1 (tonight, wrongly) | **1** (tomorrow only) |

Why extend rather than document the limit: planning only today's cutoff meant the feature
covered exactly the days the app was already opened before 20:00, and the evening after a
quiet day is the one that needs it. Tomorrow's nudge assumes tomorrow's booked habits are not
done, which they cannot be yet; completing one re-plans the set and drops it. The cost is at
most one extra pending alarm.

Written down as round 3 asked: the "How far ahead it reaches" paragraph in
`notifications-and-reminders.md`, the constant's own comment, and roadmap 1.2 — which now also
records what is still true, that a phone left unopened for longer than two days stops getting
a nudge.

Negative controls: planning from `cutoffFor` instead of `nextCutoffAfter` → 2 fail; one
evening instead of the constant → 3 fail; one shared id → 1 fails.

### Findings 16, 17, 18 — closed

`fakeAsync(initialTime: morning, …)` in both tests of `home_clock_provider_test`, so the
step back from the cutoff can no longer go negative; `40 000×` → `4 million×` in
`reminder_planner.dart:180` (`1 073 741 824 / 250 = 4 294 967`, as round 2's write-up had it);
and the local `commonOverridesForLocale` is gone in favour of `commonTestOverrides`.

## A round-3 claim qualified

Round 3 measured finding 14 by lowering `streakAtRiskHour`. Run against the **whole** suite
that probe also fails 5 tests in `streak_at_risk_test.dart` — and those are not clock-dependent
at all: they build fixed `DateTime`s and assert behaviour either side of 20:00, so moving the
constant invalidates their premise by construction. The probe is sound for the scheduling
tests round 3 used it on, and it is not a general "clock dependence" detector. Checked the
other way round: `grep -rn 'DateTime.now()' test/` now returns 9 hits in 5 files, and the only
one on a streak path is `home_screen_test.dart:36`, which reads the clock on purpose (a fixed
date would drift out of "today") and renders no at-risk card in its fixtures.

## Round 4 verification

| Item | Round 3 | Round 4 |
| --- | --- | --- |
| `flutter test` | 230 pass / 0 fail | **234 pass / 0 fail** (4 new tests) |
| `flutter test`, cutoff moved into the past | 227 pass / 3 fail | **229 pass / 5 fail** — all 5 are the hardcoded-hour tests above; the 3 scheduling failures are gone |
| `flutter analyze` | `No issues found!` | `No issues found!` |
| Negative controls | — | 4 of 4 caught (clock, `nextCutoffAfter`, the evening count, the shared id) |
| `dotnet test` | not re-run | not re-run — still 0 server files in `main...HEAD` |
| `git status --porcelain` after probes | empty | empty (constant restored) |

---

# Round 3 — review `2473aa2`, independent verification of round 2

Round 2 was written against an uncommitted tree. That tree is now `2473aa2`
(`fix(home): address the review of the streak-at-risk nudge`) and `git status` is clean, so
this round reviews the same code round 2 claimed to, as a commit. Nothing below is carried
over from round 2 on trust: every claim was re-run here.

## Verifying round 2's claims

| Round 2 claimed | I verified with | Result |
| --- | --- | --- |
| `flutter test` → 230 pass / 0 fail | `flutter test` | ✔ `00:27 +230: All tests passed!` |
| `flutter analyze` → clean | `flutter analyze` | ✔ `No issues found! (ran in 53.2s)` |
| Finding 1 closed — a habit ticked today is not flagged | read `streak_at_risk.dart:85-94`; the `mine.any(isCompleted)` guard is there, with its three tests | ✔ |
| Finding 7 closed — the watch is narrowed | `reminder_sync_provider.dart:136-138` is `appSettingsProvider.select((s) => s.streakNudges)` | ✔ |
| …and `AppSettings` gained `==`/`hashCode` | `app_settings_provider.dart:30-41` | ✔ |
| Finding 10 closed — the id spaces are disjoint | `eventReminderIdMask = 0x3FFFFFFF` (max 1 073 741 823) vs `streakNudgeNotificationId = 0x7FFFFFF0` (2 147 483 632) | ✔ disjoint by construction |
| Finding 4 closed — Home wakes at the cutoff | `home_clock_provider.dart:182-191`, one `Timer` to `nextCutoffAfter`, `ref.onDispose(timer.cancel)` | ✔ — but its test has a wall-clock edge, see **16** |
| Finding 6 closed — the docs match the feature | read the new "The evening streak nudge" section and the rewritten gap bullet in `notifications-and-reminders.md` | ✔ |
| "2^30 is still about four million times the 250 cap" | `1073741824 / 250 = 4294967` | ✔ in the report — ✘ in the source comment it summarises, see **17** |
| `dotnet test` → 144 pass | **not re-run.** `git diff --name-only main...HEAD` piped through `grep -c '^server/'` → `0` | no server file is in this branch's diff |

Round 2's fixes hold. The findings below are new, and three of them are in code round 2
added.

## New findings

### 14 [MEDIUM] The new `reminderSyncProvider` tests fail every day from 20:00 onwards, and CI runs in UTC

`reminder_sync_provider_test.dart:62-63` builds its fixtures from the wall clock:

```dart
final soon = DateTime.now().add(const Duration(days: 1)).copyWith(hour: 9, minute: 0);
final today = DateTime.now();
```

and `reminderSyncProvider` reads the wall clock too (`reminder_sync_provider.dart:139`):

```dart
final now = DateTime.now();
```

`StreakNudgePlanner.plan` returns `const []` once the cutoff has passed
(`streak_nudge_planner.dart:37-38`), so every assertion about a nudge in that file is
implicitly asserting *"this suite is being run before 20:00 local"*. Three of the six
`reminderSyncProvider` tests are.

Reproduced with the only lever available without changing the system clock — moving the
cutoff into the past instead of moving `now` into the future, which is the same comparison.
Local time was 18:0x, so `streakAtRiskHour = 17` reproduces exactly what 20:00 does:

```
$ sed -i 's/streakAtRiskHour = 20;/streakAtRiskHour = 17;/' lib/core/utils/app_constants.dart
$ flutter test test/core/notifications/reminder_sync_provider_test.dart
00:00 +1 -2: builds the nudge body from the habit, not from minutesBefore [E]
  Expected: contains 'Still open today — finish it to keep your streak'
    Actual: []
00:00 +1 -3: names the other habits at risk in the body when there are several [E]
  Expected: contains 'Still open today, with 2 more — finish them to keep your streaks'
    Actual: []
00:00 +6 -3: Some tests failed.
```

(The constant is restored; `git status --porcelain` is empty.)

The third casualty is `sends event reminders and the streak nudge in ONE applyPlan call` —
the test written specifically to hold down the thing `CLAUDE.md` and the commit message both
single out as easy to get wrong.

| | Before 20:00 local | From 20:00 local |
| --- | --- | --- |
| `reminderSyncProvider` tests | 6 pass | **3 pass, 3 fail** |

Impact: `.github/workflows/ci.yml:72` runs `flutter test` on `ubuntu-latest`, whose clock is
UTC. So **every push landing between 20:00 and 23:59 UTC fails CI** — a sixth of the day — on
a branch nobody touched. For a maintainer in UTC+7 that window is 03:00–06:59 local, so it
will look like a flake that never reproduces. It also means the project rule "run
`flutter test` and report results before calling anything done" is being satisfied by a gate
that only tells the truth 20 hours a day, and a real regression in the combined plan would be
indistinguishable from the hour.

**Fix** — the technique is already in this branch. Round 2 made `homeClockProvider` testable
by reading `clock.now()`; the scheduling path did not get the same treatment. Give it the
same:

```dart
// reminder_sync_provider.dart
import 'package:clock/clock.dart';
...
-  final now = DateTime.now();
+  final now = clock.now();
```

then pin the fixtures and wrap each test body:

```dart
final at9am = DateTime(2026, 9, 12, 9, 0);
...
await withClock(Clock.fixed(at9am), () async { await settle(container); ... });
```

`clock` is already a direct dependency (`pubspec.yaml`, added in round 2). This also unlocks
the case that currently cannot be tested at all and that finding 15 is about: what the
provider does *after* the cutoff.

### 15 [LOW] The nudge only exists on days the app is opened before 20:00 — nothing is ever scheduled for tomorrow

`StreakNudgePlanner.plan` asks `StreakAtRisk.cutoffFor(now)`, which is *today's* cutoff by
construction (`streak_at_risk.dart:105-112`), and returns empty once it has passed. Nothing
plans a day ahead. Measured — a habit with a live streak booked at 21:00 for three straight
evenings, none completed:

```
PROBE now=2026-09-12 09:00 -> fireAt 2026-09-12 20:00
PROBE now=2026-09-12 19:59 -> fireAt 2026-09-12 20:00
PROBE now=2026-09-12 20:01 -> NO NUDGE
PROBE now=2026-09-12 21:30 -> NO NUDGE
PROBE now=2026-09-12 23:59 -> NO NUDGE
```

At 20:01 the planner returns nothing at all — not "nothing for tonight", nothing. The
contrast with the other planner at the same instant, on the same three events, is the point:

```
PROBE eventReminder fireAt=2026-09-12 20:45
PROBE eventReminder fireAt=2026-09-13 20:45
PROBE eventReminder fireAt=2026-09-14 20:45
PROBE total=3
```

`ReminderPlanner` reaches seven days out (`AppConstants.reminderHorizon`); the nudge reaches
the end of the current evening. And since `reminderSyncProvider` re-runs only when events,
habits, the locale or the switch change — there is no timer on it — the pending nudge set is
whatever the last pre-cutoff run of the app left behind.

Impact: a user whose last session on Saturday was at 21:00, and who does not open the app at
all on Sunday, gets no nudge on Sunday evening — the day they most needed one. The feature
silently covers only days the app was already used. This is not a bug in any single function;
it is a consequence of planning "today's cutoff" that nothing states. The docs come close and
stop short — `notifications-and-reminders.md` says "nothing is scheduled once the cutoff has
passed — Home still shows the card", which reads as *for tonight* but actually means *at
all*.

Mitigating: planning tomorrow's nudge is not free, because tomorrow's completion state is
unknowable and every booked habit with a live streak would qualify. It is self-correcting
(any session tomorrow re-plans and drops it), but it is a real design decision, not an
oversight to patch blindly.

**Fix**: decide it and write it down. Either extend the planner to the next cutoff as well —
cheap, at most one extra alarm, self-correcting — or add one sentence to the "What it
deliberately does not do" list in `notifications-and-reminders.md` and to roadmap 1.2's
"Still open" paragraph, saying the nudge covers only days the app runs before the cutoff. The
second is a legitimate answer; leaving it unsaid is not.

### 16 [INFO] `home_clock_provider_test` throws outright for one minute a day

Same root cause as 14, narrower window. `home_clock_provider_test.dart:20-23`:

```dart
final untilCutoff = cutoff.difference(first);
async.elapse(untilCutoff - const Duration(minutes: 1));
```

`fakeAsync` starts its clock at the real `DateTime.now()`, so between 19:59:00 and 19:59:59
local `untilCutoff` is under a minute and the subtraction goes negative. Measured:

```
PROBE now=2026-09-12 19:59:30 untilCutoff=0:00:30  minusOneMinute=-0:00:30
PROBE negative elapse: THROWS -> Invalid argument (duration): may not be negative
```

Not a failed expectation — an `ArgumentError` out of the test body. One minute in 1440, so it
will essentially never be seen; worth fixing in the same pass as 14 because it is the same
fix. `fakeAsync` takes an `initialTime`, so pinning it removes the dependency entirely.

### 17 [INFO] The id-space comment is out by a factor of 100, and contradicts the report that justified it

`reminder_planner.dart:180`:

> and the space is still 40 000× the reminder cap.

`0x3FFFFFFF + 1 = 1 073 741 824`; the cap is 250; the ratio is **4 294 967**. Round 2's own
write-up says "about four million times the 250 cap", which is right — the number that landed
in the source is not. Harmless arithmetic, but this is the sentence justifying the bit that
was deliberately given up in finding 10's fix, so it is the one that has to be right. Change
`40 000×` to `4 million×`.

### 18 [INFO] The new test file re-declares the locale overrides `test_utils.dart` already exports

`reminder_sync_provider_test.dart:311-313` ends with a local `commonOverridesForLocale`,
which is a subset of `commonTestOverrides` in `test/test_utils.dart:8-11` — the helper
`CLAUDE.md` names for exactly this ("use `commonTestOverrides` from `test/test_utils.dart`
for locale"). No behavioural difference today; it is a second place to update when the locale
setup changes, and a grep for the canonical name will not find this file.

## Round 3 verification

| Item | Round 2 | Round 3 |
| --- | --- | --- |
| `flutter test` (at 18:0x local) | 230 pass / 0 fail | **230 pass / 0 fail** — reproduced |
| `flutter test` (cutoff in the past) | not measured | **227 pass / 3 fail** — finding 14 |
| `flutter analyze` | `No issues found!` | `No issues found!` |
| `dotnet test` | 144 pass / 0 fail | not re-run — 0 server files in `main...HEAD` |
| `git status --porcelain` after probes | — | empty (constant restored, scratch tests deleted) |
| Nudge scheduled at 20:01 with 3 evenings booked | not measured | **none**, vs 3 event reminders — finding 15 |
| Round 2 findings re-opened | — | **0** |

## Round 3 notes

- Findings 14 and 16 are both in test code round 2 added, and both come from the same
  omission: the clock was made injectable on the display path (`homeClockProvider`) and left
  as `DateTime.now()` on the scheduling path. One import fixes the class of problem.
- Finding 15 is the only one about shipped behaviour, and it is a decision to record rather
  than a defect to patch.
- Findings 11 and 13 stay open by choice on round 2's reasoning, which I re-read and agree
  with; nothing has changed that would reopen them.
- **Blocking: 14.** 15–18 are not.

---

# Round 2 — uncommitted working tree (now committed as `2473aa2`)

Fixes applied on top of `622eb9b`, not yet committed (no git operations without being asked).
Everything below was re-measured on the working tree; nothing is carried over from round 1 on
trust.

## Status of round 1 findings

| # | Finding | Status |
| --- | --- | --- |
| 1 | [MEDIUM] A habit already done today is still flagged if a second slot is open | ✅ **Closed** — rule changed, 3 tests, negative control |
| 2 | [MEDIUM] Every line of new wiring is untested | ✅ **Closed** — 21 tests across 3 new files; 4 negative controls |
| 3 | [LOW] Cutoff is device-local, the streak day is UTC+7; the claim said "same decision" | ✅ **Closed** — claim corrected in the constant and in roadmap 1.2/5.1, with the measured table |
| 4 | [LOW] The card cannot appear at 20:00 on an open screen | ✅ **Closed** — `homeClockProvider`, tested with `fake_async` |
| 5 | [LOW] `onTapHabit` promises the habit's day | ⚠️ **Corrected, then closed as INFO** — my impact claim was wrong; see below |
| 6 | [LOW] `notifications-and-reminders.md` contradicts the shipped feature | ✅ **Closed** — gap bullet rewritten, new section added |
| 7 | [LOW] A theme change re-registers every alarm | ✅ **Closed** — but by `.select`, not by `==`; see below |
| 8 | [INFO] The notification names one habit, the card names all | ✅ **Closed** — `alsoAtRisk` + a second copy string |
| 9 | [INFO] A `{hour}` param the string does not contain | ✅ **Closed** — param dropped |
| 10 | [INFO] The nudge id sits inside the event-reminder id space | ✅ **Closed** — the spaces are now disjoint by construction |
| 11 | [INFO] The nudge payload is a habit id in an event-id field | ⚠️ **Open by choice** — see below |
| 12 | [INFO] Roadmap dated a day ahead | ✅ **Closed** |
| 13 | [INFO] Home expands occurrences twice per build | ⚠️ **Open by choice** — measurement below |

### Finding 1 — closed: the rule now asks the streak's question

`streak_at_risk.dart:81-88` replaces "has an unfinished occurrence" with "has nothing
completed, and has an unfinished occurrence":

```dart
final mine = today.where((o) => o.habitId == habit.id).toList();

// One completion is all the streak needs for the day, so a habit already ticked has
// nothing at risk however much else is still booked.
if (mine.any((o) => o.isCompleted)) continue;
```

Re-measured on the case from round 1 — morning slot done at 07:00, evening slot open at
21:00, evaluated at 20:00:

| | Round 1 | Round 2 |
| --- | --- | --- |
| `StreakAtRisk.evaluate` | `[HabitAtRisk(Read, streak: 5)]` | **`[]`** |
| `StreakNudgePlanner.plan` | one `ScheduledReminder` at 20:00 | **`[]`** |

Three tests lock it, and the second is the negative control for the first — the completion
has to be *this habit's*:

```
+ ignores a habit already ticked today, even with another slot open
+ still flags a habit whose only completed slot belongs to another habit
+ schedules nothing when the habit was ticked at another slot today   (planner)
```

Negative control: deleting the new `continue` line fails 2 tests (`+21 -2`).

### Finding 2 — closed: 21 tests over the wiring, and one of them was vacuous until a control caught it

Three new files:

| File | Tests | What it holds down |
| --- | --- | --- |
| `test/core/notifications/reminder_sync_provider_test.dart` | 9 | one `applyPlan` carrying both kinds; the switch; the body branch; the narrowed watch; habits still loading |
| `test/features/settings/presentation/streak_nudge_setting_test.dart` | 10 | the `?? true` default, read-back, persistence, `AppSettings` equality, and the switch **on the real `SettingsScreen`** |
| `test/features/home/presentation/home_clock_provider_test.dart` | 2 | the cutoff wake-up and its timer cleanup |

The first draft of the settings file tested the switch against a hand-rolled copy of the
widget, which could not have caught the real screen being rewired; it now drives
`SettingsScreen` itself, finding the tile by its label and tapping the `ShadSwitch` inside it.

Worth recording, because it is exactly the failure mode the convention warns about: the test
*"a theme change does not notify a streakNudges listener"* **passed with `AppSettings ==`
deleted**. Riverpod's `select` compares the extracted `bool`, so that test was measuring
`select`, not the equality it claimed to prove. Only the negative control exposed it. It is
now two tests, one per mechanism:

| Test | Fails when you remove |
| --- | --- |
| a whole-object watcher ignores a write that changed nothing | `AppSettings ==` |
| a selected watcher ignores a change to another field | — (holds either way; documents `select`) |
| an unrelated settings change does not re-register every alarm | `.select(...)` in `reminderSyncProvider` |

### Finding 5 — corrected: my round-1 impact claim was wrong

I wrote that tapping the card "becomes wrong as soon as a user taps it after browsing next
week". That does not happen. `/calendar` is a plain `GoRoute` under a plain `ShellRoute`
(`app_router.dart:58-71`), so `CalendarScreen` is rebuilt on every navigation and its
`_displayDate` field initialises to `DateTime.now()` (`calendar_screen.dart:30`). Every
at-risk row is by definition today's, so the destination is already correct — there is no
browsed date to carry over.

What was actually wrong is only the doc comment, which promised "that habit's day — the
occurrence that would keep the streak" when all rows go to the same place. Both that comment
and the call site now say what the code does. Downgraded to INFO and closed on that basis; no
behaviour change was needed or made.

### Finding 7 — closed, but the mechanism is not the one I named

I attributed the rebuild to `AppSettings` having no `==`. That is true and worth fixing, but
it is **not** what was exposing `reminderSyncProvider`: even with perfect value equality, a
theme change genuinely produces a different `AppSettings`, so a whole-object watcher re-runs
either way. The fix that protects this provider is narrowing the watch:

```dart
final nudgesOn = ref.watch(
  appSettingsProvider.select((settings) => settings.streakNudges),
);
```

Both were applied — `==`/`hashCode` for every other whole-object watcher and for no-op
writes, `.select` for this one — and each now has the test that fails when *it* is removed
(table above). Measured: with the plan built and a live subscription, two unrelated settings
writes (theme mode, then primary colour) leave the `applyPlan` call count at **1**, and the
following `streakNudges` write takes it to **2**.

### Finding 10 — closed: the two id spaces are now disjoint by construction

`reminderId` masks with `AppConstants.eventReminderIdMask` (`0x3FFFFFFF`) instead of
`0x7FFFFFFF`, putting every hashed id at or below 1 073 741 823 and leaving everything above
it for fixed ids such as `streakNudgeNotificationId` (`0x7FFFFFF0`). A test asserts the
property directly and over 20 000 distinct event ids:

```
the nudge id is outside the space event reminders hash into
```

Negative control: restoring the `0x7FFFFFFF` mask fails that test. The 31-bit claim in
`notifications-and-reminders.md` was updated in the same pass — it would otherwise have
become the next round's doc-drift finding. Losing a bit is free here: `seenIds` already
dedupes within the plan, and 2^30 is still about four million times the 250 cap.

### Finding 4 — closed: Home now wakes up at the cutoff

`homeClockProvider` (new) hands Home its `now` and schedules one timer to
`StreakAtRisk.nextCutoffAfter(now)`, invalidating itself there. One timer, not a ticking
clock. It reads `clock.now()` rather than `DateTime.now()` so that the value and the timer
share a clock, which is what makes it testable — measured with `fake_async`:

```
elapse(untilCutoff - 1 min)  -> 0 emissions   (no ticking in between)
elapse(1 min 1 s)            -> 1 emission    (the cutoff rebuilt Home once)
elapse(23 h)                 -> 1 emission    (re-armed for tomorrow, not a loop)
elapse(2 h)                  -> 2 emissions
```

The first draft of this used `DateTime.now()` and the test measured 7 emissions instead of 1,
because `fake_async` moves timers but not the real clock — the provider kept rescheduling the
same already-past cutoff. That is a test artefact rather than a production bug (the real clock
does advance), but it is what drove the switch to an injectable clock.

`nextCutoffAfter` is pure and separately tested, including that it is *strictly* in the
future at all 24 hours of the day — a non-strict version would schedule a zero-delay timer
and spin — and that it crosses a month end. Negative controls: removing the timer fails the
first test; removing `ref.onDispose(timer.cancel)` fails both.

### Findings 11 and 13 — open by choice

**11 (payload).** The nudge still puts a habit id in `payload`. Nothing reads notification
payloads (`grep -rn "payload" apps/lib` — one write, no reader), so any encoding chosen now
would be guessed against a tap-handling design that does not exist. Whoever adds that handler
has to decide how a nudge differs from an event reminder anyway, and `ReminderKind` is
already there to key it on.

**13 (double expansion).** Home still expands occurrences twice per build. Measured rather
than assumed: below the cutoff `evaluate` returns at its first line without expanding
anything, so for 20 hours of the day the second pass costs one comparison. Collapsing them
would mean threading one expansion through `HomeAgenda` and `StreakAtRisk`, coupling two
things that are currently independent and pure, for no measurable gain.

## Round 2 verification

| Item | Round 1 | Round 2 |
| --- | --- | --- |
| `flutter test` | 200 pass / 0 fail | **230 pass / 0 fail** (+30) |
| `flutter analyze` | `No issues found!` | `No issues found!` |
| `dotnet test` | 144 pass / 0 fail | 144 pass / 0 fail (server still untouched) |
| Negative controls | 3 breaks, 3 caught | **7 breaks, 7 caught** (see below) |
| Finding 1 repro (morning done, evening open) | flagged + nudged | **not flagged, not nudged** |
| `applyPlan` calls after two unrelated settings writes | not measured | **1**, then 2 after a `streakNudges` write |
| Nudge id vs 20 000 hashed reminder ids | collision possible (p = 2^-31) | **impossible** — disjoint ranges |
| Home wake-up at the cutoff | never | **1 emission, re-armed daily** |

### Negative controls, round 2

| Deliberate break | Caught by |
| --- | --- |
| Remove the `mine.any(isCompleted)` guard | 2 tests (`+21 -2`) |
| Split `applyPlan` into two calls | 3 tests (`+5 -3`) |
| Delete `AppSettings ==` / `hashCode` | 2 tests (`+8 -2`) |
| Drop the `.select` narrowing | 1 test (`+8 -1`) |
| Widen the id mask back to `0x7FFFFFFF` | 1 test (`+8 -1`) |
| Remove the cutoff timer | 1 test |
| Remove `ref.onDispose(timer.cancel)` | 2 tests |

The third and fourth rows are the pair that mattered: before the rewrite, deleting `==`
failed only one test and the `select` removal failed none.

## Round 2 notes

- **Two packages became direct dependencies.** `clock` (main) and `fake_async` (dev), both
  already in the lock file as transitive deps of `flutter_test`, now declared explicitly
  because `lib/` and `test/` import them directly. `clock` is what makes a wall-clock timer
  testable without waiting for real time; nothing else in the app uses it yet.
- **`ScheduledReminder` gained a second kind-specific field** (`alsoAtRisk`, alongside
  `minutesBefore`, which is already unused for nudges). Folded into `==`, `hashCode` and
  `toString` like `kind` was. If a third kind arrives, this class wants splitting rather than
  a third such field.
- **Files changed in round 2**: 11 modified, 4 added (1 source, 3 test), plus this report.

---

# Round 1 — review `622eb9b`

## Scope

22 files, +958 / −146. Nine of them are documentation moves and rewrites with no code in
them; the feature itself is eight source files and three test files.

| File | Change |
| --- | --- |
| `apps/lib/features/habits/domain/streak_at_risk.dart` | +102 — new. `HabitAtRisk`, `StreakAtRisk.evaluate`, `StreakAtRisk.cutoffFor` |
| `apps/lib/core/notifications/streak_nudge_planner.dart` | +65 — new. One nudge per evening, or none |
| `apps/lib/features/home/presentation/widgets/streak_at_risk_card.dart` | +104 — new. The Home card and its rows |
| `apps/lib/core/notifications/reminder_planner.dart` | +23/−6 — `ReminderKind` enum; `kind` on `ScheduledReminder`, folded into `==`/`hashCode`/`toString` |
| `apps/lib/core/notifications/reminder_sync_provider.dart` | +31/−5 — combines both plans into one `applyPlan`; nudge body branch in `buildReminderBody` |
| `apps/lib/features/home/presentation/home_screen.dart` | +19 — evaluates and renders the card above the agenda |
| `apps/lib/features/settings/.../app_settings_provider.dart` | +19/−2 — `streakNudges` flag, default on, persisted |
| `apps/lib/features/settings/presentation/settings_screen.dart` | +22 — the switch |
| `apps/lib/core/utils/app_constants.dart` | +14 — `streakAtRiskHour = 20`, `streakNudgeNotificationId = 0x7FFFFFF0` |
| `apps/lib/core/localization/locale_provider.dart` | +16 — 4 keys × en/vi |
| `apps/test/…` (3 files) | +326 — 17 new tests |
| `README.md`, `docs/README.md`, `docs/archive/README.md`, `docs/workflow.md`, `docs/feature-roadmap.md`, `CLAUDE.md` | +353/−146 — README rewritten, docs index added, three planning docs moved to `archive/`, roadmap 1.2 closed |

## Parts verified as correct

### The nudge survives the reminder cap, which is the failure mode it was most exposed to

`ReminderPlanner.plan` truncates at `AppConstants.maxScheduledReminders`
(`reminder_planner.dart:143`). Because the nudge is spread into the list *after* that
call rather than planned inside it (`reminder_sync_provider.dart:64-73`), a user with a
full calendar cannot lose it. Measured — 290 events each carrying one reminder, plus one
at-risk habit:

```
CAP: maxScheduledReminders = 250
CAP: event reminders planned = 250
CAP: combined plan length    = 251
CAP: nudge present           = true
```

Had the nudge been appended before truncation it would have been the 251st entry sorted by
`fireAt` (20:00 is later than every flood reminder) and silently dropped. The ordering here
is right.

### One `applyPlan` for both plans is not a style choice, it is required

`NotificationService.applyPlan:181` opens with `_plugin.cancelAll()`. Two separate calls
would mean whichever ran second wiped the first — the commit message says this and it is
accurate. The same property is what makes the settings switch work without any explicit
cancel: flipping it off makes `StreakNudgePlanner.plan` return `const []`, the next
`applyPlan` cancels everything and re-registers only the event reminders, and the pending
nudge is gone. No teardown code needed.

### Repeating series and split-off days are handled by reuse, not by a second implementation

`StreakAtRisk.evaluate:64-72` goes through `EventOccurrenceExpander.expand`, so a day that
was split off the series (`ParentEventId` + `ExceptionDate`) substitutes for the series'
own occurrence and carries its own `isCompleted`. This is the trap described in `CLAUDE.md`
— a series is one row and every day of it reaches the client under the series' id — and the
branch avoids it by not iterating raw events at all. The branch's own test
(`streak_at_risk_test.dart:96-120`) covers both directions, and it is not vacuous: see the
negative controls below.

### `ReminderKind` was added without changing what any existing call site means

`kind` defaults to `ReminderKind.eventReminder` (`reminder_planner.dart:45`), and it was
added to `==`, `hashCode` **and** `toString` in the same edit. `buildReminderBody` branches
on the kind before touching `minutesBefore`, so a nudge can never render "in 0 minutes".
The branch's own test locks this (`streak_nudge_planner_test.dart:88-103`).

### The tests are not vacuous

Three negative controls, each restored afterwards:

| Deliberate break | Result |
| --- | --- |
| `!o.isCompleted` filter dropped from the occurrence query | 3 tests fail (`+11 -3`) |
| `local.hour < cutoffHour` → `< cutoffHour - 1` | 1 test fails (`+7 -1`) |
| `currentStreak <= 0` → `< 0` | 1 test fails (`+7 -1`) |

`git status --porcelain` is empty after restoring; the tree the numbers below were measured
on is the committed one.

### Not flagging a habit with nothing booked today

Deliberate, stated in the source (`streak_at_risk.dart:41-44`), the commit message and the
roadmap entry, with the reason: whether an unbooked day breaks a streak is roadmap 5.1's
day-boundary question. Correct call — the alternative nags people about habits they never
planned for today, and it would have to guess at a rule the backend does not have.

## Round 1 findings

### 1 [MEDIUM] A habit that is already done today is still flagged, and still nudged, if it has a second slot open

`streak_at_risk.dart:77-85`:

```dart
final unfinished = today
    .where((o) => o.habitId == habit.id && !o.isCompleted)
    .toList()
```

The rule is "does this habit have *an* unfinished occurrence today". The streak's rule is
not that. `StreakCalculator.FromStartTimes`
(`server/src/Application/Common/StreakCalculator.cs:68-71`) runs
`.Select(ToLocalDate).Distinct()` — **one** completion secures the calendar day, and a
second slot on the same day contributes nothing. Measured directly against the server's own
calculator (temporary xunit probe, since removed):

```
morning only, evening still open : Current=5 Longest=5
morning + evening on past days   : Current=5 Longest=5
=> a second slot on the same day adds nothing: True
```

So for a habit booked twice a day — a run in the morning and one in the evening, the exact
shape the "earliest unfinished one today" comment in `HabitAtRisk.occurrence` anticipates —
the streak is already safe the moment the morning slot is ticked. The branch still reports
it as at risk. Measured on the client, morning done at 07:00 and evening open at 21:00:

```
A: atRisk = [HabitAtRisk(Read, streak: 5)]
A: nudge  = [ScheduledReminder(id: 2147483632, eventId: habit-1, fireAt: 2026-09-11 20:00:00.000,
             minutesBefore: 0, kind: streakAtRisk)]
```

Impact: the card says "Streak about to break" and the 20:00 notification says "Still open
today — finish it to keep your streak" about a streak that is in no danger. This is the one
failure mode a nudge feature cannot afford — a notification that is wrong on its face is
how users turn the switch off, and the switch is on by default. It hits anyone who books a
habit more than once a day, which the code itself is built to handle (`unfinished.first`,
the sort, the `picks the earliest unfinished slot` test).

The existing test `ignores a habit that is already done today`
(`streak_at_risk_test.dart:72-80`) passes only because its fixture has a single event. Add
a second, open one and it flags.

**Fix** — ask the streak's question instead of the calendar's:

```dart
final mine = today.where((o) => o.habitId == habit.id).toList();

// One completion secures the calendar day (StreakCalculator distincts on date), so a
// habit already ticked today has nothing at risk, whatever else is still booked.
if (mine.any((o) => o.isCompleted)) continue;

final unfinished = mine.where((o) => !o.isCompleted).toList()
  ..sort((a, b) => a.startTime.compareTo(b.startTime));
```

Plus a test with two slots, the earlier one completed, asserting empty.

### 2 [MEDIUM] Every line of new wiring is untested, including the one the commit message calls out as subtle

17 tests were added, and they are good tests — but all 17 land on the two pure functions and
the card. Nothing reaches:

| New code | Test |
| --- | --- |
| `reminder_sync_provider.dart:63-73` — the combined plan | none |
| `reminder_sync_provider.dart:17-23` — the `streakAtRisk` body branch | none |
| `AppSettingsNotifier.updateStreakNudges` (`app_settings_provider.dart:87-91`) | none |
| `_streakNudgesKey` read-back with the `?? true` default (`:70`) | none |
| the Settings switch (`settings_screen.dart:124-141`) | none |

Confirmed: `grep -rln "reminderSyncProvider\|streakNudges\|updateStreakNudges" apps/test/`
returns nothing. `settings_screen_test.dart` renders the screen, so the switch is proven not
to throw, but nothing asserts it exists, reflects the stored value, or writes one.

This matters more than the usual coverage gap for two reasons. First, the project rule is
explicit: "Every new handler/repository/widget gets tests in the same step." Second, the
combined-plan line is the one the commit message and `CLAUDE.md` both single out as the
thing that is easy to get wrong — "planned separately, the second would wipe the first" —
and it is the one line with nothing holding it in place. A future refactor that splits the
two `applyPlan` calls apart again would pass all 200 tests.

Impact: a regression in the switch (stored value ignored, write not persisted) or in the
plan composition ships silently.

**Fix**: a `ProviderContainer` test over `reminderSyncProvider` with `eventsProvider`,
`habitsProvider` and `appSettingsProvider` overridden and a fake `NotificationService`
recording what `applyPlan` received — asserting the list contains both kinds, and contains
no nudge when `streakNudges` is false. Plus a `SharedPreferences.setMockInitialValues`
test over `updateStreakNudges` / the `?? true` default, and one `settings_screen_test`
case tapping the switch.

### 3 [LOW] The cutoff is device-local, the streak's day is a fixed UTC+7 — the commit message says these are the same decision

`AppConstants.streakAtRiskHour`'s doc comment and the roadmap entry both argue the fixed
hour is right because "it is the same decision as roadmap 5.1's day boundary — better made
once, for both". It is not currently the same decision, and the two are made in different
clocks. `StreakAtRisk.evaluate:55` uses `now.toLocal()` — the device's zone.
`StreakCalculator.DefaultDayBoundaryOffset` is a hardcoded `TimeSpan.FromHours(7)`, applied
server-side to every user regardless of where they are.

Measured — the same 20:00 device-local cutoff, resolved to the day the server counts it on:

| Device zone | 20:00 local, in UTC | Server's calendar day |
| --- | --- | --- |
| UTC+7 | 2026-09-11T13:00Z | 2026-09-11 |
| UTC+0 | 2026-09-11T20:00Z | **2026-09-12** |
| UTC−5 | 2026-09-12T01:00Z | **2026-09-12** |
| UTC−8 | 2026-09-12T04:00Z | **2026-09-12** |

For every user west of UTC+7, the nudge fires inside what the backend already counts as the
next day, and the completion it asks for is recorded against that next day. The streak
usually still survives (the offset shifts every day uniformly, and `isAlive` accepts today
or yesterday), so this is not an outright break — but the card's local "today" window and
the server's streak day are two different 24-hour windows, and the habits the card reads
`currentStreak` from were computed in the second one.

Impact: latent, and bounded, but the roadmap now records 5.1 as partly decided by this
branch when the decision was actually made twice, differently. The next person reading
"better made once, for both" will believe the hard part is done.

**Fix**: no code change needed now — this is 5.1's work. Change the claim: say the hour is
fixed *pending* 5.1, and that it is currently device-local while the streak day is UTC+7,
so 5.1 has to reconcile them. Roadmap 5.1 should gain that as an explicit sub-point.

### 4 [LOW] The card cannot appear at 20:00 on a screen that is already open

`home_screen.dart:42` reads `final now = DateTime.now();` inside `build`, and
`StreakAtRisk.evaluate` is called with it. Home rebuilds only when one of the providers it
watches changes. There is no ticker: `grep -rn "Timer.periodic\|Stream.periodic" apps/lib`
returns two hits, both inside the pomodoro and focus-session timers, neither of which Home
watches.

So a user sitting on Home from 19:50 sees nothing happen at 20:00. The card appears the
next time something else rebuilds the screen — a tab switch, a pull-to-refresh, a SignalR
push, or reopening the app.

Impact: small, and partly covered by the notification firing at the same moment. Worth
noting because the card is the *primary* surface (the notification is opt-out, the card is
not) and because the comment at `:41` — "Read once per build, and pass it down" — explains
why `now` is read once but not that nothing causes that build.

**Fix**: if it is worth fixing at all, the cheapest version is a one-shot timer to the next
cutoff that invalidates a trivial `clockProvider`. Or leave it and say so in the roadmap
entry, alongside the widget gap already listed there.

### 5 [LOW] `onTapHabit` promises the habit's day and delivers the calendar's default date

`streak_at_risk_card.dart:22-23` documents the callback as "Opens that habit's day — the
occurrence that would keep the streak". The only caller discards it
(`home_screen.dart:88`):

```dart
onTapHabit: (_) => context.go('/calendar'),
```

`/calendar` opens on whatever date the calendar provider currently holds. `HabitAtRisk`
carries `occurrence.startTime` precisely so the destination could be that day, and the card
renders that time in each row — so the row shows 21:00, and tapping it may land on a
different date entirely.

The card test `tapping a habit reports which one` (`streak_at_risk_card_test.dart:64-73`)
asserts the callback receives the habit, which locks in a contract nothing uses.

Impact: cosmetic today, because the calendar almost always sits on today. It becomes wrong
as soon as a user taps the card after browsing next week.

**Fix**: either pass the date through (`context.go('/calendar?date=...')`, if the route
takes one) or correct the doc comment to "Opens the calendar" and drop the parameter.

### 6 [LOW] `docs/notifications-and-reminders.md` now contradicts the branch, and the new index points readers straight at it

`docs/notifications-and-reminders.md:258-260`, in its "Known gaps" list:

> **No reminders for habits that have no event.** Reminders attach to scheduled events.
> A habit with `TargetDays` but nothing on the calendar gets nothing. Roadmap 1.2
> (streak-at-risk) is the feature that covers that case.

Roadmap 1.2 is marked done by this branch, and it explicitly does **not** cover that case —
`streak_at_risk.dart:41-44` and the roadmap's own "Still open" paragraph both say a habit
with nothing booked is deliberately not flagged. The doc was not touched by this branch
(`git diff --stat` confirms), and nothing else in it mentions the nudge: the flow diagram
at `:81`, the cancel-then-reschedule note at `:101` and the copy note at `:143` all describe
event reminders only.

Meanwhile the new `docs/README.md` lists that file as the thing to read when "Working on
reminders **or the streak nudge**".

Impact: the index makes a promise the document does not keep, and the document makes a
claim the branch falsified. The docs reorganisation is otherwise careful — every other link
in the new `README.md` and `docs/archive/README.md` resolves (checked; the only stale
`docs/project-plan.md` references left in the repo are inside
`review-main-codebase-audit.md`, which is a historical record and correctly left alone).

**Fix**: add a short section to `notifications-and-reminders.md` covering
`StreakNudgePlanner`, the fixed id, the settings switch and why both plans go through one
`applyPlan`; and rewrite that gap bullet to say 1.2 shipped and still does not cover an
unbooked habit, pointing at 5.1.

### 7 [LOW] Changing the accent colour cancels and re-registers every pending notification

`reminder_sync_provider.dart:64` does `ref.watch(appSettingsProvider).streakNudges`, which
subscribes to the whole `AppSettings` object, not the field. `AppSettings` has no
`operator ==` or `hashCode` (confirmed by grep over `app_settings_provider.dart`), so
`copyWith` always yields an instance Riverpod considers changed. `updateThemeMode` and
`updatePrimaryColor` therefore re-run `reminderSyncProvider`, which calls `applyPlan`, which
calls `cancelAll()` and re-schedules the lot — up to 251 alarms, measured above.

Impact: a burst of platform-channel work on an unrelated settings tap, and a window during
which no alarm is registered. Not a correctness bug — `applyPlan` is idempotent and the
window is milliseconds — but it is the same class of problem as the "a theme change every
month cancelled every pending reminder" line already in `feature-roadmap.md`'s 1.1 note.

**Fix**: give `AppSettings` `==`/`hashCode` (or make it `freezed`, which the codebase
already uses elsewhere), and select the field:
`ref.watch(appSettingsProvider.select((s) => s.streakNudges))`.

### 8 [INFO] The notification names one habit; the card names all of them

`streak_nudge_planner.dart:52` sets `title: first.habit.name`. With three habits at risk the
notification reads "Run" / "Still open today — finish it to keep your streak" while the card
lists Run, Read and Meditate. One notification for the evening is the right call and the
tests lock it (`several habits at risk are still one notification`), but the title makes it
look like a single-habit alert. A count in the body ("Run and 2 more…") would match what the
card shows.

### 9 [INFO] `buildReminderBody` passes a `{hour}` the nudge string does not contain

`reminder_sync_provider.dart:18-23` calls
`translate('streak_nudge_body', params: {'hour': …})`. `streak_nudge_body` has no `{hour}`
placeholder in either locale, so `translate`'s `replaceAll` loop is a no-op. Measured:

```
D: en body = "Still open today — finish it to keep your streak"
D: en raw  = "Still open today — finish it to keep your streak"
D: vi body = "Hôm nay vẫn chưa xong — hoàn thành để giữ chuỗi"
D: vi raw  = "Hôm nay vẫn chưa xong — hoàn thành để giữ chuỗi"
```

Harmless, and it silently starts working if the copy ever gains the placeholder — but right
now it reads as if the hour appears in the body when it does not. (`streak_nudge_desc` in
Settings does use `{hour}`, correctly.) Either drop the param or put the hour in the copy.

### 10 [INFO] The nudge id sits inside the event-reminder id space

`ReminderPlanner.reminderId:169` returns `Object.hash(...) & 0x7FFFFFFF`, i.e.
`0 … 2147483647`. `AppConstants.streakNudgeNotificationId` is `0x7FFFFFF0` = `2147483632` —
inside that range. `ReminderPlanner`'s own `seenIds` set dedupes within the event reminders,
but the nudge is spread in outside it, so a collision would mean one silently overwrites the
other in `zonedSchedule`.

The probability is `2^-31` per reminder — with a full 250-reminder plan, about one user-day
in 9 million. Searched 400 000 synthetic event ids for a collision and found none, as
expected. Not worth code churn; worth a line in the constant's doc comment saying the id is
inside the hash range rather than reserved outside it, since the comment currently implies
the opposite by contrast ("Fixed, unlike event reminders, which derive theirs from the
occurrence"). A negative id would be genuinely reserved.

### 11 [INFO] The nudge's notification payload is a habit id in an event-id field

`notification_service.dart:196` sets `payload: reminder.eventId`, and the nudge puts
`first.habit.id` there (`streak_nudge_planner.dart:47`, with a comment explaining why).
Nothing reads notification payloads today — `grep -rn "payload" apps/lib` finds only this
line and the unrelated home-widget JSON — so it is inert. It becomes a real bug the day a
tap handler routes on the payload as an event id, which is the obvious next step for this
subsystem.

### 12 [INFO] Roadmap dated a day ahead of the commit

`docs/feature-roadmap.md:6` says **Last updated: 2026-09-13**; `622eb9b` is dated
2026-09-12.

### 13 [INFO] Home expands every occurrence twice per build

`HomeAgenda.build` and `StreakAtRisk.evaluate` each call `EventOccurrenceExpander.expand`
over the same `eventsAsync.value` (`home_screen.dart:45-55`), with different ranges. Pure
and cheap at current data sizes, and the second one exits before expanding for 20 hours of
the day (`evaluate:57` returns early below the cutoff), so this is a note rather than a
problem.

## Round 1 verification

| Item | Result |
| --- | --- |
| `flutter test` (whole suite) | **200 pass / 0 fail** — 183 on base + 17 new |
| `flutter analyze` | `No issues found!` (28.0s) |
| `dotnet test` (`-o /tmp/servertest`) | **144 pass / 0 fail** — unchanged; the branch touches no server code |
| Negative controls on the new tests | 3 deliberate breaks, 3 caught |
| Nudge vs `maxScheduledReminders` cap | survives — 250 + 1 = 251, nudge present |
| Server streak semantics probe | one completion per day secures it; a second slot adds nothing |
| Doc links in `README.md`, `docs/README.md`, `docs/archive/README.md` | all resolve |
| Working tree after all probes | `git status --porcelain` empty |

## Out-of-scope notes

- **`StreakCalculator.DefaultDayBoundaryOffset` is a hardcoded UTC+7** and wrong for users
  outside that zone. Pre-existing, documented in place in `StreakCalculator.cs:20-30`, and
  already roadmap 5.1. Finding 3 is about this branch's *claim* regarding it, not about the
  offset itself.
- **The two stale `docs/project-plan.md` references** at
  `review-main-codebase-audit.md:120` and `:805` point at a file this branch moved to
  `docs/archive/`. Review reports are a historical record under this project's own
  convention, so leaving them is correct — noted only so a later reader does not "fix" them.
- **`AppSettings` has never had value equality**; finding 7 is the first consumer for which
  it costs something.

## Priority

| # | Severity | Category | Estimated fix |
| --- | --- | --- | --- |
| 1 | MEDIUM | Correctness — false nudge | 4 lines + 1 test |
| 2 | MEDIUM | Test coverage / project rule | ~3 test files, half a day |
| 3 | LOW | Doc claim vs reality | edit 2 doc paragraphs |
| 6 | LOW | Doc drift | one new doc section + 1 bullet |
| 5 | LOW | Contract vs caller | 1 line, either direction |
| 7 | LOW | Efficiency | `==` + `.select`, ~10 lines |
| 4 | LOW | UX timing | leave, or a one-shot timer |
| 8–13 | INFO | — | comment-level |

---

# Conclusion

The branch does what it claims and puts it at the right layer. `StreakAtRisk` and
`StreakNudgePlanner` are pure, take their clock as a parameter, and hold the whole rule
between them; the widgets and the provider carry no policy. Routing the evaluation through
`EventOccurrenceExpander` rather than over raw event rows is the decision that keeps
repeating series and split-off days correct for free, and it is the one place this codebase
most reliably punishes a second implementation.

Design decisions that hold up:

- **The nudge is spread in after `ReminderPlanner`'s cap**, so a full calendar cannot push
  it out — measured at exactly the boundary.
- **Both plans go through one `applyPlan`**, which `cancelAll()` makes mandatory rather than
  tidy, and which also gives the settings switch its teardown for free.
- **One notification per evening, not one per habit**, with an id derived from the evening
  so re-planning replaces rather than stacks, and tomorrow's cannot overwrite tonight's.
- **A habit with nothing booked is deliberately not flagged**, with the reason recorded in
  three places instead of left implicit.
- **`ReminderKind` defaults to `eventReminder`** and was folded into `==`, `hashCode` and
  `toString` in the same edit, so no existing call site changed meaning.

After 6 rounds: 20 findings, 18 closed, 2 open by choice (11, the notification payload —
nothing reads payloads yet, and the encoding should be chosen with the tap handler; and 13,
the double occurrence expansion — measured to cost one comparison for 20 hours of the day).
**No HIGH, no MEDIUM left. Does not block merge.**

Rounds 3 and 4 were worth the extra pass. Round 3 caught the one thing the suite could not
tell anyone — three tests that only held before 20:00, on a project whose CI runs in UTC — and
it caught it by re-running round 2's claims rather than reading them. Round 4 closed that with
the technique the branch had already introduced for the display path, and took round 3's open
design question (the nudge reaching only today) as a decision to make rather than a note to
file: the planner now covers two evenings, which is what makes the feature work on the day
after a quiet one. The bug class behind findings 14 and 16 is the same one round 1 and 2 kept
finding in this branch — time read from the wall clock in code that decides by comparing
against a cutoff — and it is now injectable on both paths.

Rounds 5 and 6 found no behaviour left to fix and went after the statements around it instead:
the comment on the nudge id still described one pending notification, and the new constant's
comment pointed at the 32-bit ceiling when the limit that actually binds is the server's
one-day streak grace. Both were created by round 4's own fix. The second is the more useful
finding of the two, because "raise it if you want more evenings" would have been a reasonable
next change and the code would not have stopped it — so it is now the one invariant in this
feature held by an assertion rather than by a comment.

Round 1's finding 1 was the one that mattered: the rule the branch implemented ("an
unfinished occurrence today") was not the rule the streak uses ("any completion today"), and
the gap showed the moment a habit was booked twice in a day — a shape the code was otherwise
built to handle, down to the `unfinished.first` sort. It produced a confidently wrong
notification, on by default. Round 2 changed the rule to the streak's, re-measured the exact
case that was broken, and locked it with a test plus its own negative control.

Finding 2 was the project's own rule, and closing it changed the shape of the branch more
than any single bug fix: 21 tests now cover the wiring that had none, including the combined
`applyPlan` the commit message itself flagged as subtle. Two of those tests only became real
tests because a negative control showed the first drafts were vacuous — one asserted value
equality but was actually measuring Riverpod's `select`, and the switch test drove a
hand-rolled copy of the widget rather than `SettingsScreen`. Both are recorded in round 2
rather than quietly fixed, because the convention is right that a vacuous pass is the common
failure here and it caught two in one branch.

Two round-1 findings did not survive contact with the code as written up. Finding 5's impact
claim was wrong — `CalendarScreen` is rebuilt on every navigation under a plain `ShellRoute`,
so the destination was already correct and only the doc comment over-promised. Finding 7 named
the wrong mechanism: `AppSettings` equality is worth having, but `.select` is what actually
keeps a theme tap from re-registering every alarm. Both are corrected in round 2 rather than
left standing.

Process note: the commit message states the rule, the rejected alternative (per-habit
threshold) and the deliberate omission (unbooked habits), and the roadmap entry repeats the
omission rather than declaring 1.2 closed cleanly. That is the right instinct — finding 3
existed only because one sentence in that otherwise honest write-up claimed more than the code
did, and round 2 replaced it with the measured timezone table in roadmap 5.1, where the next
person to touch the day boundary will find it.

## Commands run to verify

### Round 1

```
git log main..HEAD                                            # one commit; main is the real base
git diff --stat main...HEAD                                   # 22 files, +958/-146
flutter analyze                                               # No issues found (28.0s)
flutter test                                                  # 200 pass / 0 fail
dotnet test -o /tmp/servertest                                # 144 pass / 0 fail, server untouched
flutter test test/zz_review_repro_test.dart                   # repros A-D (temp file, removed)
flutter test test/zz_cap_test.dart                            # nudge vs the 250 cap (temp, removed)
dotnet test --filter FullyQualifiedName~ZzReviewStreakProbe \
  --logger "console;verbosity=detailed"                       # server streak semantics (temp, removed)
sed -i 's/&& !o.isCompleted//' streak_at_risk.dart            # negative control 1 -> +11 -3
sed -i 's/< cutoffHour/< cutoffHour - 1/' streak_at_risk.dart # negative control 2 -> +7 -1
sed -i 's/currentStreak <= 0/currentStreak < 0/' streak_at_risk.dart  # control 3 -> +7 -1
grep -rln "reminderSyncProvider|streakNudges" apps/test/      # nothing - finding 2
grep -rn "Timer.periodic|Stream.periodic" apps/lib            # only pomodoro/focus - finding 4
grep -n "operator ==|hashCode" app_settings_provider.dart     # none - finding 7
grep -rn "payload" apps/lib --include=*.dart                  # one write, no reader - finding 11
grep -oE "\]\([^)]+\)" README.md | sort -u                    # doc links all resolve
git status --porcelain                                        # empty after every probe
```

### Round 2

```
flutter analyze                                               # No issues found
flutter test                                                  # 230 pass / 0 fail
dotnet test -o /tmp/servertest                                # 144 pass / 0 fail
flutter test test/core/notifications/reminder_sync_provider_test.dart      # 9 pass
flutter test test/features/settings/presentation/streak_nudge_setting_test.dart  # 10 pass
flutter test test/features/home/presentation/home_clock_provider_test.dart # 2 pass
# negative controls, each reverted immediately after
python -c "...drop mine.any(isCompleted)..."  && flutter test  # +21 -2
python -c "...split applyPlan in two..."      && flutter test  # +5 -3
python -c "...delete AppSettings =="          && flutter test  # +8 -2
python -c "...drop .select..."                && flutter test  # +8 -1
sed -i 's/0x3FFFFFFF/0x7FFFFFFF/' app_constants.dart && flutter test  # +8 -1
python -c "...remove the cutoff timer..."     && flutter test  # 1 test
python -c "...remove ref.onDispose..."        && flutter test  # 2 tests
grep -n "ShellRoute|StatefulShellRoute" app_router.dart       # plain ShellRoute - finding 5
git status --porcelain                                        # no stray probe files
```

### Round 3

As recorded in that round's own write-up:

```
flutter test                                                  # 230 pass / 0 fail
flutter analyze                                               # No issues found (53.2s)
sed -i 's/streakAtRiskHour = 20;/streakAtRiskHour = 17;/' app_constants.dart
flutter test test/core/notifications/reminder_sync_provider_test.dart  # +6 -3 -> finding 14
# probe scripts for the nudge horizon and the fakeAsync edge (temp files, removed)
git diff --name-only main...HEAD | grep -c '^server/'         # 0 - dotnet test not re-run
git status --porcelain                                        # empty (constant restored)
```

### Round 4

```
sed -i 's/streakAtRiskHour = 20;/.. = 17;/' app_constants.dart && flutter test <2 files>
                                                              # +8 -3: finding 14 reproduced
flutter analyze                                               # No issues found (146.6s)
flutter test                                                  # 234 pass / 0 fail
flutter test <the two notification files>                      # 22 pass
sed -i '.. = 17;' && flutter test                             # 229 pass / 5 fail: all 5 are
                                                              # hardcoded-hour tests, see above
grep -rn "DateTime.now()" test/                               # 9 hits / 5 files, none on a
                                                              # streak path except by design
python scratchpad/negative_controls (4 mutations)             # clock -> 2 fail; cutoffFor -> 2;
                                                              # 1 evening -> 3; shared id -> 1
git status --porcelain                                        # constant restored after probes
```

### Round 5

As recorded in that round's own write-up (run at 22:04 local, after the cutoff):

```
flutter test                                                  # 234 pass / 0 fail at 22:04
flutter analyze                                               # No issues found (8.8s)
git checkout 2473aa2 -- <3 files> && flutter test <2 files>    # 3 fail: the before/after
sed -i 's/streakAtRiskHour = 20;/.. = 17;/' && flutter test    # 229 pass / 5 fail, reproduced
grep -n 'DateTime.now()\|clock.now()' <4 src + 3 test files>  # no wall-clock read on the path
probe: plan at 09:00 / evenings=2 vs 4                        # ids ...632/...633 (+634/635)
probe: 250 event reminders + nudges                           # 252, both nudges survive the cap
git status --porcelain                                        # empty after every probe
```

### Round 6

```
sed -n 78,95p server/src/Application/Common/StreakCalculator.cs  # isAlive: today or yesterday
grep -rn "at most one nudge" apps/lib docs                    # 4 hits before, 0 after
flutter test test/core/notifications/streak_nudge_planner_test.dart  # 14 pass
sed -i 's/streakNudgeEvenings = 2;/.. = 5;/' && flutter test <planner file>
                                                              # 2 fail - the new ceiling test
flutter analyze                                               # No issues found (6.5s)
flutter test                                                  # 235 pass / 0 fail
git status --porcelain                                        # constant restored
```
