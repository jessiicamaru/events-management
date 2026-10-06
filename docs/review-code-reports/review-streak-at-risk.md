# Code review: `feat/streak-at-risk`

Base: `13b0f52` (local `main`, merge of PR #26) · Reviewed by: Claude Code

| Round | Commit | Date | Outcome |
| --- | --- | --- | --- |
| 1 | `622eb9b` feat(home): nudge a streak that is about to break, and reorganise the docs | 2026-09-12 | 0 HIGH, 2 MEDIUM, 5 LOW, 6 INFO — **MEDIUM 1 and 2 block merge** |
| 2 | uncommitted working tree (fixes applied on top of `622eb9b`) | 2026-09-12 | 11 closed (both MEDIUM), 2 INFO open by choice; 1 finding **corrected** (5) and 1 **re-explained** (7). No new findings. **Nothing blocking.** |

> `git log main..HEAD` returns exactly one commit, so `main` is the branch's real base and
> the three-dot diff is its real scope. No drift adjustment needed.

---

# Round 2 — uncommitted working tree

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
- **One notification for the evening, not one per habit**, with a fixed id so re-planning
  replaces rather than stacks.
- **A habit with nothing booked is deliberately not flagged**, with the reason recorded in
  three places instead of left implicit.
- **`ReminderKind` defaults to `eventReminder`** and was folded into `==`, `hashCode` and
  `toString` in the same edit, so no existing call site changed meaning.

After 2 rounds: 13 findings, 11 closed, 2 open by choice (11, the notification payload —
nothing reads payloads yet, and the encoding should be chosen with the tap handler; and 13,
the double occurrence expansion — measured to cost one comparison for 20 hours of the day).
**No HIGH, no MEDIUM left. Does not block merge.**

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
