# Event reminders (local notifications)

Roadmap item 1.1. Branch `feat/event-reminders`.

Schedules an on-device notification a configurable number of minutes before an event
starts. **No server, no Firebase, no FCM** — see *Why local, not push* below.

---

## Why local, not push

"Push notification" usually means Firebase Cloud Messaging: a server sends a message to
Google, Google wakes the device. That is the wrong tool here, for three reasons:

1. **The device already knows the schedule.** Events are synced to the client anyway, so
   the phone can work out "remind me at 08:50" without being told.
2. **It would need a backend.** FCM means a Firebase project, a device-token table, a
   server-side scheduler, and a job that fans out reminders per user per event. All of
   that to deliver information the device already has.
3. **Local works offline.** The reminder fires on a flight, on the underground, with the
   backend down.

FCM becomes the right answer only for something the device *cannot* know — a squad-mate
poking you, for example. That is a separate feature.

### Testing in an emulator

Local notifications work in any emulator, including an image without Google Play
Services. Remote FCM push is the one that needs a Play-Services image — which is the
usual reason people think notifications are hard to test.

Verified on `emulator-5554`, `sdk gphone16k x86 64`, **Android 17 (API 37)**.

To exercise a reminder without waiting:

1. Settings → Reminders → enable, then **Send a test notification** (fires immediately,
   confirms the channel and permission are right).
2. For the scheduled path, create an event a few minutes out with the lead time set to
   "When the event starts", then background the app.
3. `adb shell dumpsys alarm | grep habit_tracker` lists the pending alarms if you want to
   confirm something was actually registered.

**Do not trust emulator clock-jumping** (`adb shell date ...`) to test scheduling — it
does not reliably trigger `AlarmManager`, and a reminder that "fails" that way is
probably fine on a real device.

---

## Android permissions

`targetSdk` is 36 and the test device is API 37, so both of the modern gates apply.

| Permission | Since | Why | If refused |
| --- | --- | --- | --- |
| `POST_NOTIFICATIONS` | API 33 | Post anything at all | Nothing is delivered. The settings screen shows a blocking warning. |
| `SCHEDULE_EXACT_ALARM` | API 31 | Fire at the exact minute | Falls back to inexact: still delivered, may drift by minutes. Warning shown. |
| `RECEIVE_BOOT_COMPLETED` | — | Re-register alarms after reboot | Reminders silently stop after a restart. |

**`USE_EXACT_ALARM` is deliberately not used.** It is granted automatically and never
revocable, which is tempting — but Google Play restricts it to alarm-clock and calendar
apps whose *core* purpose is exact timing, and a habit reminder is not that. Using it
risks a policy rejection. `SCHEDULE_EXACT_ALARM` is the honest choice, and the code
degrades gracefully when the user declines it.

Permission is requested when the user turns reminders **on**, not at first launch — an
unexplained prompt on startup gets denied.

---

## Design

```
events (eventsProvider) ──┐
                          ├──> ReminderPlanner.plan()  ──> List<ScheduledReminder>
reminder settings ────────┘         (pure, tested)                 │
                                                                   v
                                                      NotificationService.applyPlan()
                                                         (platform channel, untested)
```

Everything that decides **whether** a notification happens is pure and unit-tested
(`ReminderPlanner`). `NotificationService` only carries out the result. That split is the
point: the plugin is a platform channel and cannot be meaningfully unit-tested, so no
decisions live there.

| File | Role |
| --- | --- |
| `core/notifications/reminder_planner.dart` | Pure. Which reminders should exist. |
| `core/notifications/notification_service.dart` | Thin adapter over the plugin. |
| `core/notifications/reminder_sync_provider.dart` | Re-plans when events or settings change. |
| `features/settings/.../reminder_settings_provider.dart` | Enabled + lead time, in SharedPreferences. |
| `features/settings/presentation/reminder_settings_screen.dart` | UI, permission state, test button. |
| `features/calendar/domain/event_occurrence_expander.dart` | Shared recurrence expansion (see below). |

### Decisions worth knowing

**Cancel-then-reschedule, not diff.** `applyPlan` cancels everything and re-registers.
A diff would have to know which events changed, and Google Calendar sync mutates them
behind the app's back — wholesale replacement cannot leave a reminder for an event that
no longer exists.

**Stable ids.** `ReminderPlanner.reminderId(eventId, occurrenceStart)` hashes the event
id with the occurrence's start *minute*, masked to a positive 31-bit int (Android
requires a 32-bit signed id). Re-planning therefore reuses the same id and replaces the
alarm instead of stacking a duplicate next to it.

**A 7-day horizon, capped at 64 reminders.** Android limits how many alarms an app may
hold, and the data changes daily, so scheduling further ahead would mostly be scheduling
things that are about to be rescheduled. Soonest reminders win.

**Off by default.** Scheduling notifications a user never asked for is how apps get
uninstalled.

**Sync provider never invalidates what it watches.** It only writes to the plugin. The
audit previously found an infinite sync loop caused by a provider invalidating its own
dependency (`GoogleCalendarSyncTracker`); this one cannot do that.

**Notification copy lives in the translation map.** `applyPlan` takes a `bodyBuilder`
rather than formatting text itself — the service has no locale and should not own
user-facing strings. `translate()` gained an optional `params` argument for `{n}`
placeholders so counts stay inside the translated string.

---

## Shared recurrence expansion

Scheduling a reminder needs to know the concrete occurrences of a recurring event. That
expansion already existed **three times**: twice in `home_widget_service.dart` and once
in `command_center_panel.dart`.

Rather than add a fourth copy, it is now
`features/calendar/domain/event_occurrence_expander.dart`, with tests. Both copies in
`HomeWidgetService` were migrated (283 → 161 lines) and its 5 existing tests still pass.

**`command_center_panel.dart` was not migrated** — it is entangled with widget state, and
doing it here would have widened an already large change. Roadmap item 5.3.

### Measured limitation: a malformed RRULE hides the event

`SfCalendar.getRecurrenceDateTimeCollection` does **not** throw on a malformed rule — it
returns an empty collection. Measured:

```
rule="this is not an rrule" -> 0 occurrence(s)
rule=""                     -> 0 occurrence(s)
rule="FREQ=BOGUS"           -> 0 occurrence(s)
rule="FREQ=DAILY;COUNT=3"   -> 3 occurrence(s)
```

So an event with a corrupt rule disappears from every view that uses the expander, with
no error. This is **pre-existing** — the `catch` blocks in the original copies never
fired either.

It is not fixed here, on purpose: an empty result is indistinguishable from a rule that
legitimately has no occurrences in range (a spent `COUNT`), so "fall back to the base
event when empty" would duplicate real events. The proper fix is validating the rule when
it is saved. Both behaviours are locked by tests so a future change is deliberate.

---

## Build requirement

`flutter_local_notifications` uses `java.time`, which does not exist below API 26, so the
Gradle build needs core library desugaring. Without it the build fails with
*"Dependency ':flutter_local_notifications' requires core library desugaring to be
enabled"*. Added to `android/app/build.gradle.kts`:

```kotlin
compileOptions {
    isCoreLibraryDesugaringEnabled = true
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
```

---

## Not done

- **No reminders for habits that have no event.** Reminders attach to scheduled events.
  A habit with `TargetDays` but nothing on the calendar gets nothing. Roadmap 1.2
  (streak-at-risk) is the feature that covers that case.
- **No action buttons** ("complete", "snooze") on the notification.
- **No iOS verification.** The Darwin paths are written and permission handling is in
  place, but nothing has been run on an Apple device or simulator.
- **No quiet hours.** A 07:00 event reminds at 06:50 regardless.
- **Rescheduling depends on the app being opened.** Alarms survive reboot via the boot
  receiver, but a *new* event created on another device only produces a reminder once
  this app next runs and syncs. A background worker would fix it; that is a bigger change
  (WorkManager) and is not obviously worth it.

---

## Verification

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test` | 82 passed (was 58; +24 new) |
| `HomeWidgetService` existing tests | 5 still pass after the refactor |
| `flutter build apk --debug` | succeeds (after the desugaring fix) |
| Cold launch on API 37 emulator | see below |

Unit tests cover `ReminderPlanner` (lead time, completed events, past events, horizon,
recurring occurrences, ordering, the cap, id stability) and `EventOccurrenceExpander`
(pass-through, daily expansion, deleted occurrence, edited-child occurrence, sorting, and
both empty-result cases).

Notification *delivery* is not unit-tested — it is a platform channel. The test button in
settings exists for that reason.
