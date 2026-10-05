# Code review: `fix/split-off-day-safety`

Base: `78e7d8f` (local `main`, merge of PR #25) · Reviewed by: Claude Code (2 of 5 parallel reviewers finished; the other 3 lenses were run by the consolidating pass)

| Round | Commit | Date | Outcome |
| --- | --- | --- | --- |
| 1 | `b765db8` fix(events): one event per day of a series, and stop counting dead Inserts as pending | 2026-09-12 | 0 HIGH, 0 MEDIUM, 7 LOW, 5 INFO — **does not block merge** |
| 2 | `29fde93` fix(events): address the review of the split-off-day index | 2026-09-12 | 5 LOW closed (1, 2, 3, 5, 6), 2 LOW left open by choice; no new findings |

> The remote was unreachable from this network, so the base is local `main`. `git log main..HEAD`
> shows exactly this branch's commits, so the diff is the branch's real scope.
>
> **Coverage warning.** Five reviewers were launched (bugs, security, contracts, tests,
> conventions). The security and conventions lenses finished. The bugs, contracts and tests
> lenses were killed by a session limit before reporting, so the consolidating pass ran their
> highest-value checks itself (listed under "Lenses run by the consolidating pass"). Coverage of
> those three lenses is therefore thinner than on the `feat/home-page` review — the untested
> paths in finding 7 are where another look would pay off.

---

# Round 2 — review `29fde93`

## Status of round 1 findings

| # | Finding | Status |
| --- | --- | --- |
| 1 | [LOW] The migration keeps a different copy than the one the server writes to | ✅ **Closed** — ranking now prefers ticked tasks and breaks ties by the oldest; measured on a clone |
| 2 | [LOW] Deleted copies leave outbox rows behind, which still push to Google | ✅ **Closed** — deleted in the same statement; measured |
| 3 | [LOW] Nothing guards the index-name literal against drift from the const | ✅ **Closed** — `OneEventPerSeriesDayIndexTests` (3 tests) |
| 4 | [LOW] Expected conflicts are logged at Error with a stack trace (~8.4 KB each) | ⚠️ **Open by choice** — see below |
| 5 | [LOW] Two different "slot taken" checks in one handler, plus an inaccurate comment | ✅ **Closed** — `FollowSeriesAsync` uses `OccurrenceMaterializer.FindDay` |
| 6 | [LOW] An empty `else if` branch holding only a comment | ✅ **Closed** — inverted to `FindDay(...) == null` |
| 7 | [LOW] No automated test reaches the index, the 23505 path, the sync branch or the SQL | ⚠️ **Open by choice** — parent review MEDIUM 5, same gap |
| 8 | [INFO] Roadmap 5.3 "four copies", 5.6c open list incomplete | ✅ **Closed** — corrected |
| 9 | [INFO] InMemory package 10.0.5 vs EF 10.0.10 | ✅ **Closed** — pinned to 10.0.10 |
| 10 | [INFO] `"Insert"` stays a literal (parent review LOW 15) | ⚠️ Still open — pre-existing, 13 other sites |
| 11 | [INFO] Minute truncation written three ways | ⚠️ Still open — latent; callers pass UTC today |
| 12 | [INFO] Other writers can hit the index without catching it (a 500, not a duplicate) | ⚠️ Open by choice — `UpdateEventCommand` is not transactional; see round 1 |

### Finding 1 and 2 — closed: the duplicate cleanup keeps the right row and takes its outbox with it

`20260911164432_AddOneEventPerSeriesDayIndex.cs:30-63` is now one statement: a `ranked` CTE, a
`losers` CTE, a `DELETE` of the losers' outbox rows, then the `DELETE` of the losers. The ranking
gained a ticked-task count and the tie-break flipped from `"CreatedAt" DESC` to `"CreatedAt"`,
which is what `EventRepository.GetOccurrenceChildAsync:40` (`OrderBy(e => e.CreatedAt)`) has been
reading and writing all along.

Measured on a clone of the Docker database, seeded with both orderings
(`scratchpad/seed_dupes.sql`):

| Group | Rows | Kept before | Kept after |
| --- | --- | --- | --- |
| A: older copy has a ticked task, newer has nothing | 2 | the newer (task lost) | **the older, task intact** |
| B: newer copy has a ticked task, older has nothing | 2 | the newer | **the newer** |
| Pre-existing `da2c839d` "Yoga edit" triple | 3 | "Yoga edit 3" | **"Yoga edit 1"** (oldest, the one the server reads) |

```
keeper A kept its ticked task: 1
loser outbox row gone: true
after: orphan_outbox=4        # the same 4 as before the migration, all pre-existing
duplicate groups left: 0
```

Rows that must survive did: a day one minute later, another series' day on the same minute, and
rows with `ParentEventId` NULL on the same date (the last three measured by the security lens).

### Finding 4 — open by choice: the error log noise

Each refused insert writes two EF error entries, about 8.4 KB together (measured by the security
lens: 5 blocks = 41,885 bytes). No parameter values are exposed — they log as `'?'`, and Npgsql
redacts its DETAIL. Under a realistic flood (100 requests over 5 days) only **2** inserts were
actually refused, so the volume is small. `ON CONFLICT DO NOTHING` would remove both the
exception and the noise, but it means hand-written insert SQL for one entity, and the version
shipped here is measured correct. Revisit if the logs ever get loud.

### Finding 7 — open by choice: what still has no automated test

`EventRepository.TryAddOccurrenceDayAsync` (the 23505 catch, the detach), the index itself, the
dedupe SQL, and the inbound-sync branch. They are covered by the live runs in this report only.
This is parent review MEDIUM 5, still half-open, and this branch adds code to exactly those
surfaces. The honest fix is an integration test project against a real Postgres (Testcontainers
is not in the local NuGet cache, and CI has no Postgres service), which is its own piece of work.

## Round 2 verification

| Item | Round 1 | Round 2 |
| --- | --- | --- |
| `dotnet test` | 141 pass / 0 fail | **144 pass / 0 fail** |
| `dotnet build` | 0 errors, no new warnings | same |
| `flutter analyze` / `flutter test` | no issues / 183 pass | unchanged (no Dart change in round 2) |
| Migration on a clone, seeded duplicates | kept the newest | **kept the right copy in both orderings**, 0 duplicate groups left, loser's outbox row gone |
| `dotnet ef migrations has-pending-model-changes` | not run | "No changes have been made to the model since the last migration" |

---

# Round 1 — review `b765db8`

Kept as the record. See round 2 for current status.

## Scope

20 files (plus the generated migration Designer), +429 / −62 excluding the Designer:

| File | Change |
| --- | --- |
| `…/Migrations/20260911164432_AddOneEventPerSeriesDayIndex.cs` | +65 — deletes duplicate split-off days, adds a partial unique expression index |
| `…/Repositories/EventRepository.cs` | +23 — `TryAddOccurrenceDayAsync`: catches 23505 on that index, detaches, returns false |
| `…/Common/OccurrenceMaterializer.cs` | +30/−11 — the race loser returns the winner; `FindDay`, `StandsFor` |
| `…/Commands/UpdateEventCommand.cs` | +23/−7 — taken-slot guards in `FollowSeriesAsync` and `UpdateSplitOffDayAsync` |
| `…/Services/GoogleCalendarService.cs` | +8 — inbound sync does not add Google's day beside an edited day |
| `…/Repositories/GoogleCalendarOutboxRepository.cs` | +8/−2 — dead-lettered Inserts are not pending (parent LOW 7) |
| `Domain/…` (3 files), `ApplicationDbContext.cs` | +34 — the interface method, `MaxRetries`, the index-name const |
| `server/tests/…` (5 files) | +190/−6 — 9 new tests; EF InMemory provider added |
| `CLAUDE.md`, `docs/feature-roadmap.md`, `docs/notifications-and-reminders.md` | +44/−28 — parent LOW 16, roadmap status |
| `apps/lib/…` (2 files) | +4/−8 — expander comment, two unused translation keys removed |

## Parts verified as correct

### The race is actually fixed, and it was actually broken before

12 parallel `POST /events/{id}/occurrences` for the same day, 5 days, against a server on a clone
of the real database (the base build ran the same script on its own clone):

| | base `78e7d8f` | branch |
| --- | --- | --- |
| Copies of the day | 11–12, each with its own task copies | **1**, one copy of the 2 tasks, same id returned to all 12 |
| A finished session racing two ticks | 2–3 copies, only one completed | **1 copy, completed** |
| Refused inserts (Postgres log) | n/a (no index) | 65 during the run, all recovered |

The security lens reproduced this independently (12 materialize; 6 materialize + 6
complete-session; 100 requests over 5 days → 5 rows).

### Ownership is unchanged, and the winner lookup cannot cross users

Ownership is checked before any materialize (`MaterializeOccurrenceCommand.cs:40-41`, the
`target.UserId` check in `CompleteEventSessionCommand`, the owner and `parent.UserId` checks in
`UpdateEventCommand`). All 5 assignments of `ParentEventId` take the id from a series the caller
owns or from the per-user sync. Live: user B got 404 on user A's series before and after A's
winner row existed; in the database, `child_user_mismatch=0` and `cross_user_groups=0`.

### The index expression, and the migration's blast radius

`date_trunc('minute', "ExceptionDate" AT TIME ZONE 'UTC')` is immutable, which Postgres requires
of an index expression (`date_trunc` on a `timestamptz` alone is not). Measured: the index is
created, `Down` drops it, and `+07`/`Z` spellings of the same minute group together. Only two
foreign keys point at `Events` — `EventTasks` (CASCADE) and the self FK (NO ACTION) — and there
are no grandchildren. The three `migrationBuilder.Sql` calls are constant literals, no
interpolation. Per-table counts changed only for `Events`, `EventTasks` and
`__EFMigrationsHistory`.

### Parent review LOW 7, 10 and 16 are closed as the parent review defined them

LOW 7: both outbox queries now share `GoogleCalendarOutbox.MaxRetries`; no literal `5` is left;
4 new tests, including the row exactly at the limit. LOW 10: duplicates cleaned, partial unique
index, and "on 23505, re-read the existing child" — all three present. LOW 16: the notifications
passage and the expander comment are rewritten, and the two translation keys have no references
left. Parent LOW 15 stays half-closed (see finding 10).

### Layering, packages, secrets

Application's new code depends only on Domain interfaces; Infrastructure already called
Application's static helpers on base. The new test package comes from nuget.org with a Microsoft
author signature, has no known vulnerabilities, and is not in the Web output or `Web.deps.json`.
No secret was added to a tracked file, and `EnableSensitiveDataLogging` appears nowhere.

## Round 1 findings

### 1 [LOW] The migration keeps a different copy than the one the server has been writing to

*Introduced, by reading.* The ranking in `…AddOneEventPerSeriesDayIndex.cs:41-45` ends with
`"CreatedAt" DESC`, so it keeps the newest copy, while `EventRepository.GetOccurrenceChildAsync`
(`:40`) reads with `OrderBy(e => e.CreatedAt)` — the oldest. Since PR #25, ticks have therefore
gone to a copy the migration deletes. Ticked tasks are not in the ranking at all, and they go
with the row (`ON DELETE CASCADE`). **Fix:** count ticked tasks in the ranking and break ties by
the oldest.

### 2 [LOW] The deleted copies leave outbox rows behind, and those still push to Google

*Introduced.* `GoogleCalendarOutboxes.EventId` has no foreign key to `Events`. Seeded and
measured on a clone: after the migration, `outbox EventId=…a1 Action=Insert orphan=t`. By reading
`GoogleCalendarSyncWorker.cs:76-95`, the worker pushes such an Insert from its payload and simply
skips the local link, so Google gets an event with no row here. **Fix:** delete the losers' outbox
rows in the same migration.

### 3 [LOW] Nothing guards the index name against drift between the migration and the const

*Introduced.* The name is a literal at `…Index.cs:53` and `:62` (justified — a migration must not
change when code does) and a const at `ApplicationDbContext.cs:15`, which
`EventRepository.cs:65` matches the violation by. If the two ever differ, every race becomes a
500 again and no test fails. **Fix:** assert the migration's SQL contains the const.

### 4 [LOW] Every expected conflict is logged at Error with a full stack trace

*Introduced.* `EventRepository.cs:52-72`. Measured: 2 entries per refusal, about 8.4 KB; 130
entries for the 65 refusals in the live run. No values leak (`'?'`, redacted DETAIL). A 100-request
flood produced only 2 refusals. **Fix (optional):** `INSERT … ON CONFLICT DO NOTHING`.

### 5 [LOW] Two different "slot taken" checks in one handler, and an inaccurate comment

*Introduced.* `UpdateEventCommand.cs:134-135` asks the database; `:392-394` re-implements
`OccurrenceMaterializer.FindDay` in memory, minus the self-exclusion. The comment says the holder
is "an edited one", but a local-only day the loop has not reached yet also matches. **Fix:** use
`FindDay` in both places and correct the comment.

### 6 [LOW] An empty `else if` branch holding only a comment

*Introduced.* `GoogleCalendarService.cs:261-268` reads like a missing statement, and its comment
claims a `GoogleEventId` check that `FindDay` does not make. **Fix:** invert to `== null`.

### 7 [LOW] The new failure handling has no automated test

*Introduced (and parent MEDIUM 5).* `TryAddOccurrenceDayAsync`'s 23505 catch and detach, the index,
the dedupe SQL and the sync branch are all verified only by the live runs in this report. The unit
tests mock `TryAddOccurrenceDayAsync`, and EF InMemory cannot raise a constraint violation.

### INFO

- **8** Roadmap 5.3 still said "four copies" of the expander (git history says three), and 5.6c's
  "still open, all LOW" list left out LOW 12, LOW 13 and the half-open MEDIUM 5.
- **9** `Microsoft.EntityFrameworkCore.InMemory` 10.0.5 against EF Core 10.0.10.
- **10** `"Insert"` stays a literal beside the new const (parent LOW 15; 13 other sites).
- **11** Minute truncation exists three ways: `RecurrenceExceptions.TruncateToMinute` (internal),
  inline in `EventRepository.cs:31-35` (which uses `SpecifyKind` where the helper uses
  `ToUniversalTime`), and `date_trunc` in SQL. Latent: callers pass UTC today.
- **12** Writers other than the materializer can still hit the index uncaught — the check-then-update
  in `UpdateEventCommand.cs:134-141`, and two Google exceptions for the same master and minute in
  one sync feed (`localEvents` is not refreshed after an add). Both are a 500 (and a failed sync
  for that user) where base made a silent duplicate; `UpdateEventCommand` is not transactional, so
  such a 500 leaves a half-applied edit. By reading, not reproduced.
- **13** The backend applies pending migrations at startup (`Program.cs:21-26` →
  `ApplicationDbContextInitialiser`), so this migration's delete runs without an operator step and
  cannot be undone. Pre-existing mechanism, worth knowing before the first start on this branch.

## Lenses run by the consolidating pass

The bugs, contracts and tests reviewers were killed by a session limit. These checks stood in:

| Check | Result |
| --- | --- |
| Every writer of `ExceptionDate` / `ParentEventId` enumerated (`git grep`), each assessed against the index | 5 sites; 2 guarded here, 3 covered by finding 12 |
| `dotnet ef migrations has-pending-model-changes` | no model drift, so EF will not try to recreate the raw index |
| Migration forward and back on a clone, with seeded state-carrying duplicates | correct in both orderings; `Down` drops the index |
| 5 negative controls (one per fix) | all caught by a test |
| Test counts, branch vs base | 144 (round 2) / 141 (round 1) / 132 (base) |
| Live concurrency, branch vs base build | table above |

Not done, and the honest gap: a mutation run over the new logic beyond those 5 controls, and a
contracts pass over the Flutter side's matching of a child to its series occurrence.

## Out-of-scope notes

- 4 orphan outbox rows already exist in the dump, unrelated to this branch.
- The Docker template database holds one user with a real Google refresh token and the real
  client secret is in `appsettings.Development.json`, so any test server started against a clone
  could push to that user's live calendar. Both test servers in this review were checked: the
  worker started and processed nothing.
- No rate limiting anywhere on `/events/*` (pre-existing).

# Conclusion

The branch does what it claims, at the right layer: the invariant "one event per day of a series"
is enforced by the database, not by hoping two requests never interleave, and the application code
is adjusted to live with that invariant rather than to work around it.

- **The fix is at the bottom layer.** A unique index is the only place a check-then-insert race can
  actually be settled; the repository turns the violation into an ordinary "someone else got there
  first", which the materializer already knew how to handle.
- **The before state was measured, not assumed.** The same script against a build of `main` produced
  11–12 copies of one day, which is what the finding claimed.
- **The writers were brought in line, not just the materializer.** Three other paths that set a
  day's slot were adjusted in the same pass, which is what kept the new constraint from turning
  ordinary edits into 500s.
- **The cleanup in round 2 came from reading the read path**, not from the test suite: nothing
  failed, yet the migration was deleting the copy the server actually uses.

After 2 rounds: 12 findings (7 LOW, 5 INFO). Closed: 7 (1, 2, 3, 5, 6, 8, 9). Open by choice: 4
(log noise), 7 (no integration test for the DB paths), 12 (uncaught index violations in three
writers). Still open and pre-existing: 10, 11, 13. **No HIGH or MEDIUM. Does not block merge.**

Process notes: the negative controls ran per fix rather than once at the end, so each new test is
known to fail without its fix. Coverage is thinner than the parent review — three of five lenses
did not report — and findings 7 and 12 are where the next look should start.

## Commands run to verify

### Round 1

```
git show b765db8 --stat ; git diff 78e7d8f b765db8
git grep -n 'ParentEventId\s*=\|ExceptionDate = ' -- server/src      # every writer of a day's slot
dotnet test tests/Application.UnitTests -o /tmp/servertest           # 141 pass (base: 132)
dotnet build HabitTracker.slnx                                       # 0 errors, no new warnings
cd apps && flutter analyze && flutter test                           # no issues; 183 pass
python scratchpad/negative_controls_safety.py                        # 5 mutations, each caught
CREATE DATABASE "habit-tracker-safety" TEMPLATE "habit-tracker"      # 5433, throwaway clone
dotnet ef database update --connection "...habit-tracker-safety..."  # index created, 2 dups removed
dotnet ef database update AddEventReminders --connection "..."       # Down: index dropped
dotnet <out>/Web.dll (:5099 branch, :5098 base build of main)
python scratchpad/live_race_check.py                                 # branch: all PASS
python scratchpad/live_race_check_before.py                          # base: 15 FAIL (11-12 copies)
docker logs habit_tracker_postgres | grep -c 'UX_Events_...'         # 65 refused inserts
grep -c 'fail:' webcheck-safety.log                                  # 130 = 65 x 2 EF entries
DROP DATABASE "habit-tracker-safety" / "habit-tracker-before"
```

### Round 2

```
dotnet test tests/Application.UnitTests -o /tmp/servertest2          # 144 pass
dotnet ef migrations has-pending-model-changes                       # no model drift
CREATE DATABASE "rv-final" TEMPLATE "habit-tracker" ; psql -f seed_dupes.sql
dotnet ef database update --connection "...rv-final..."              # ranking + outbox checks above
DROP DATABASE "rv-final" (and the reviewers' rv-* databases)
```
