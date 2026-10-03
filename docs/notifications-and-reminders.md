# Event reminders (local notifications)

Roadmap item 1.1. Branch `feat/event-reminders`.

Schedules on-device notifications before an event starts. **No server, no Firebase, no
FCM** — see *Why local, not push* below.

Reminders are a property of **each event**, not a global setting. One event can have
several ("1 hour, 30 min, 5 min before"), and a single day of a recurring series can
differ from the rest.

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

1. Create an event a few minutes out and set its reminder to **When the event starts**
   (the permission prompt appears the first time you add one).
2. Background the app and wait for it.
3. `adb shell dumpsys alarm | grep habit_tracker` lists the pending alarms, which is the
   quickest way to confirm something was actually registered without waiting.

**Do not trust emulator clock-jumping** (`adb shell date ...`) to test scheduling — it
does not reliably trigger `AlarmManager`, and a reminder that "fails" that way is
probably fine on a real device.

---

## Android permissions

`targetSdk` is 36 and the test device is API 37, so both of the modern gates apply.

| Permission | Since | Why | If refused |
| --- | --- | --- | --- |
| `POST_NOTIFICATIONS` | API 33 | Post anything at all | Nothing is delivered. A destructive toast says so when the reminder is added. |
| `SCHEDULE_EXACT_ALARM` | API 31 | Fire at the exact minute | Falls back to inexact: still delivered, may drift by minutes. A softer toast warns once. |
| `RECEIVE_BOOT_COMPLETED` | — | Re-register alarms after reboot | Reminders silently stop after a restart. |

**`USE_EXACT_ALARM` is deliberately not used.** It is granted automatically and never
revocable, which is tempting — but Google Play restricts it to alarm-clock and calendar
apps whose *core* purpose is exact timing, and a habit reminder is not that. Using it
risks a policy rejection. `SCHEDULE_EXACT_ALARM` is the honest choice, and the code
degrades gracefully when the user declines it.

Permission is requested the first time the user adds a reminder to an event, not at first
launch — an unexplained prompt on startup gets denied. With no settings screen, that is the
only moment with enough context. If notifications are blocked, a destructive toast says so;
if exact alarms are unavailable, a softer toast warns that reminders may arrive late.

---

## Design

```
events (eventsProvider) ──> ReminderPlanner.plan() ──> List<ScheduledReminder>
  each carrying its own          (pure, tested)                  │
  reminderMinutesBefore                                          v
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
| `core/notifications/reminder_sync_provider.dart` | Re-plans whenever events change. |
| `features/calendar/.../create_event_sheet.dart` | The per-event picker, and the permission prompt. |
| `Application/Common/ReminderOptions.cs` | Server-side allowed set and normalisation. |
| `features/calendar/domain/event_occurrence_expander.dart` | Shared recurrence expansion (see below). |

### Decisions worth knowing

**Cancel-then-reschedule, not diff.** `applyPlan` cancels everything and re-registers.
A diff would have to know which events changed, and Google Calendar sync mutates them
behind the app's back — wholesale replacement cannot leave a reminder for an event that
no longer exists.

**Stable ids, keyed on the offset too.** `reminderId(eventId, occurrenceStart, minutesBefore)`
hashes all three, masked to a positive 31-bit int (Android ids are 32-bit signed).
Re-planning reuses the same id and replaces the alarm rather than stacking a duplicate.
The offset is part of the key because without it an event's "1 hour before" and "5 min
before" would collide and only one would survive — a test covers exactly that.

**A 7-day horizon, capped at 250 reminders.** Android limits how many alarms an app may
hold, and the data changes daily, so scheduling further ahead would mostly be scheduling
things about to be rescheduled. The cap is well above the old 64 because one event may now
carry up to five reminders, so a week of a few daily habits multiplies quickly. Soonest
reminders win.

**Per event, opt-in, no global setting.** A new event starts with no reminders. There is
no app-wide on/off switch and no default lead time — an event with an empty set simply
contributes nothing to the plan, and if nothing has reminders the plan is empty and every
pending alarm is cancelled.

**Options: none, when it starts, 5, 15, 30 min, 1 hour.** Defined twice on purpose —
`AppConstants.reminderOptionsMinutes` for the picker and `ReminderOptions.AllowedMinutesBefore`
on the server, which rejects anything else rather than trusting the client. Both the planner
and the server drop unknown offsets, so a stale client degrades instead of failing.

**Per-occurrence overrides are free.** A recurring event stores one reminder set. To make
one day differ, the user edits that occurrence — which the app already implements as
`editScope: "ThisOccurrence"`, adding the date to the master's `RecurrenceExceptionDates`
and creating a child event. That child carries its own reminders, and the expander already
substitutes it for the master's occurrence. No override table, no new concept.

**Storage is `integer[]`, not a child table.** `Event.ReminderMinutesBefore` is a
`List<int>` mapped to a Postgres `integer[]`, the same as `Habit.TargetDays`. Avoids an
`.Include()` on every calendar fetch — events are read in bulk, and that path is already
the hot one.

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

## Does it survive the phone being off?

| Situation | Delivered? |
| --- | --- |
| Screen off / locked | Yes |
| App closed, swiped out of recents | Yes — the alarm lives in `AlarmManager`, not the app process |
| Airplane mode, no network | Yes. This is the payoff for local over FCM |
| Phone powered off | No. Nothing runs, and Android wipes every alarm on shutdown |

The boot receiver is what makes the last row survivable: on
`BOOT_COMPLETED` / `MY_PACKAGE_REPLACED` the plugin re-registers its cached notifications.
Without `RECEIVE_BOOT_COMPLETED` they would be gone permanently after one restart.

### Missed reminders fire in a burst after boot

`FlutterLocalNotificationsPlugin.zonedScheduleNotification` has **no past-time guard** — it
converts the stored time to epoch millis and hands it to `AlarmManager`, which fires
immediately for a time already gone. So a reminder whose moment passed while the phone was
off should fire as soon as the device boots, and several missed ones arrive together, each
still worded "Starts in 30 min" for something that already happened.

It self-heals the next time the app opens, because `applyPlan` cancels everything and
re-plans from scratch — but the burst lands first.

**Confidence: read from the plugin source, not observed.** Confirming it means rebooting a
device across a scheduled reminder. It also cannot be suppressed from Dart: the replay runs
in the plugin's native receiver before any app code.

### Two conditions that stop reminders entirely

- **Force stop** (Settings → App info → Force stop — not swiping it away) cancels all
  alarms on most Android versions. Nothing fires until the app is opened again.
- **Aggressive OEM battery managers** (Xiaomi, Samsung, Huawei, Oppo) are known to drop
  alarms for apps they judge idle. This is the usual reason a reminder app "works on my
  phone but not my friend's". Exempting the app from battery optimisation fixes it, but
  that is a prompt the user has to accept.

Neither is a bug in this feature, and neither is worked around.

---

## Not done

- **No test-notification button.** It lived on the reminders settings screen, which was
  removed when reminders became per-event. Worth re-adding somewhere if permission
  problems turn out to be common.
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
| `flutter test` | 89 passed |
| `dotnet test` | 68 passed (+10 `ReminderOptions`) |
| Migration on 95 existing events | all got `{}`, zero nulls |
| `HomeWidgetService` existing tests | 5 still pass after the refactor |
| `flutter build apk --debug` | succeeds (after the desugaring fix) |
| Cold launch on API 37 emulator | clean; plugin registers with no errors |
| Manual testing of the per-event picker | done by the author |

Unit tests cover `ReminderPlanner` (lead time, completed events, past events, horizon,
recurring occurrences, ordering, the cap, id stability) and `EventOccurrenceExpander`
(pass-through, daily expansion, deleted occurrence, edited-child occurrence, sorting, and
both empty-result cases).

Notification *delivery* is not unit-tested — it is a platform channel. The test button in
settings exists for that reason.
