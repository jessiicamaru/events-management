# Code review: `fix/sync-window-deletion`

Base: `c3cc04e` (`main`, merge of PR #31) · Reviewed by: Claude Code

| Round | Commit | Date | Outcome |
| --- | --- | --- | --- |
| 1 | `6ceee03` fix(sync): stop incoming sync deleting synced events outside its window | 2026-09-13 | The fix works: history and events past the window survive, every page is read; the author's 8/13, 10/10 and 222 all reproduced. 1 MEDIUM, 3 LOW, INFO notes — all introduced by the branch's new lookup, none a data-loss regression. **MEDIUM blocks merge** |
| 2 | `c421e0d` fix(sync): apply what the lookup finds, survive network errors, take a series' days with it · `0ce29cc` test(sync): fail fast on endless paging | 2026-09-13 | All 7 closed. 22 negative controls in a worktree: 21 caught, 1 equivalent (N6, measured). `dotnet test` 232 passed. No new findings. **Nothing blocking.** |

> `git log main..HEAD` is three commits after round 2. Scope: server and docs only, no migration.

---

# Round 2 — `c421e0d` and `0ce29cc`, fixes for round 1

## Status of round 1 findings

| # | Finding | Status |
| --- | --- | --- |
| R1 | [MEDIUM] An event moved on Google keeps its old time locally, and is looked up on every sync | ✅ **Closed** — what the lookup finds joins the list, so steps 2–5 apply it |
| R2 | [LOW] A network error during a lookup aborts the whole sync | ✅ **Closed** — transport errors and timeouts keep the event, and stop further lookups |
| R3 | [LOW] Days of a series cancelled on Google survive outside the window | ✅ **Closed** — a series takes its days with it, local-only days included |
| R4 | [LOW] Eight surviving mutants | ✅ **Closed** — seven now caught; N6 is equivalent, measured |
| R5 | [LOW/INFO] Wrong "client's form" comment; the dialog's UNTIL not parsed | ✅ **Closed** — comment corrected, format parsed |
| R6 | [INFO] Repeated page token; floating UNTIL | ✅ **Closed** — guard added; a non-UTC UNTIL gets a day's grace |
| R7 | [INFO] Two doc sentences | ✅ **Closed** — rewritten |

Progress log:

- `c421e0d` — all seven addressed in code, tests and docs. `dotnet test`: 231 passed.
- 22 negative controls in a detached worktree, restoring files byte for byte: 21 caught, N6 survived.
  R6b was caught only because the test run hung for 240 s.
- `0ce29cc` — the fake now fails a listing after 10 calls, so R6b fails in 2 s. A test pins how a
  listed cancelled day is removed, and N6 still passes against it: an equivalent mutant.
  `dotnet test`: **232 passed**.

### R1 — closed: what the lookup finds is applied

`IsGoneFromGoogleAsync` became `LookUpAsync`, which returns one of three outcomes: **Gone**
(cancelled, 404, 410), **Found** (with the event) or **Unknown**. A found event is added to the list,
so the same code that applies a listed event updates the local copy. An event moved out of the
window takes its new time, and from the next sync on it is no longer a candidate.

Test `AnEventMovedOutOfTheWindowOnGoogle_IsKept_AtItsNewTime`: the lookup answers with a start 20 days
past the window; the stored start and title follow, and a second sync looks nothing up. Control R1
(the found event not added) fails it.

### R2 — closed: an unanswered lookup keeps the event and the sync goes on

`LookUpAsync` also catches `HttpRequestException`, and `TaskCanceledException` when the sync's own
token was not cancelled. The outcome is Unknown: the event is kept, and **the remaining candidates are
kept without asking**, since the same failure would repeat for each — probe PR2 measured 2.8 s of
retries for a single 503.

Tests: `ANetworkErrorWhileChecking_KeepsTheEvent_AndTheSyncCarriesOn` (a listed rename is still
applied), `AGoogleErrorWhileChecking_…` (the same for a 500), `AfterALookupFails_TheRestAreKeptWithoutAsking`
(two unreachable candidates, one lookup). Controls R2a and R2b fail them.

A cancelled sync still ends the sync, as it should.

### R3 — closed: a series takes its days with it

When step 1 deletes a series, it first deletes every row with that `ParentEventId`, whatever its date,
and then the series. Children go first because the parent link is set to null rather than cascaded:
removing the series first would turn its tracked days into one-off events. Already-deleted ids are
skipped, so a day is neither deleted twice nor looked up after its series went.

This also removes **local-only days** of the series, which the reviewer noted were orphaned before the
branch. They belong to a series Google says no longer exists, which is how step 4 already treats a
local-only day of a cancelled date.

Test `ASeriesCancelledOnGoogle_TakesItsDaysWithIt_WhateverTheirDate`: a series listed as cancelled, an
edited day 50 days before the window and a local-only day 40 days before; all three are gone and
nothing is looked up. Control R3 fails it.

### R4 — closed: the eight survivors

| Mutant | Now | Test that fails |
| --- | --- | --- |
| N3 default look-back 3650 days | caught | `TheDefaultWindow_KeepsLastMonthsHistory` asserts no lookups and the `timeMin` sent |
| N10 default look-ahead 0 | caught | same test, `timeMax` |
| N4 no `timeMin` | caught | `TheListAsksForTheWindow_WithDeletedEvents_AndSeriesUnexpanded` — the fake records the query |
| N5 `ShowDeleted = false` | caught | same test |
| N7 lookup catches every exception | superseded | the code now catches transport errors deliberately; R2a checks the boundary |
| N9 anything not "confirmed" counts as gone | caught | `ATentativeEvent_IsKept` |
| N11 a UTC `UNTIL` also gets +1 day | caught | `AUtcUntil_GetsNoGrace` |
| N6 a listed cancelled instance deleted in step 1 | **equivalent** | see below |

**N6 is an equivalent mutant, measured.** A day of a series that Google lists as cancelled is left by
step 1 to step 4, which deletes the local day and adds its date to the series' exception list. The
mutant deletes the day in step 1 instead; step 4 then finds no local day but still records the date.
`ADayCancelledOnGoogle_IsRemoved_AndItsDateExcludedFromTheSeries` checks both outcomes and passes on
the mutant as on the code (log below). No test can tell the two apart, and the code keeps the
original condition.

### R5 and R6 — closed

- `UNTIL=20260820 165959Z`, the form `custom_recurrence_dialog.dart` writes, is now one of the parsed
  formats. The test comment that called the RFC form "the client's" now says "no RRULE: prefix", and
  the dialog's form has its own case.
- An `UNTIL` not ending in `Z` — a date, or a floating local time — gets a day's grace, the widest a
  time zone can shift it. A wrong grace costs one lookup; a missing one could hide a deletion.
- `ListWindowAsync` stops when Google returns the token it was asked with.
  `ARepeatedPageToken_EndsTheListing` covers it, and the fake fails any listing over 10 calls, so the
  control fails in 2 s instead of hanging.

### R7 — closed

`google-calendar-sync-architecture.md` §4 now lists what a lookup can answer (gone, still there,
error), the short-circuit after a failure, and that a series takes its days with it. §5 says a moved
event is looked up once and then carries its new time.

## Still open, by choice

- **Not verified against a real Google account.** Every Google answer in the tests is a fake that
  follows the documented API. How Google actually filters a recurring series by time, and what it
  returns for a reverted edited day (R6, INFO), are unverified. Checking needs a throwaway account
  and a refresh token.
- **All-day events west of UTC** (R6, INFO): a purged all-day event can be missed for one sync. No
  data is lost, and no user of this app is west of UTC.
- **The client writes a non-RFC `UNTIL`** (R5, pre-existing, out of scope): what Google does with
  `UNTIL=20260820 165959Z` is unverified.

## Round 2 verification

| Check | Result |
| --- | --- |
| `dotnet test` | **232 passed**, 0 failed (`main`: 196) |
| New tests | 36 (filtered run: 36 passed): 20 in `GoogleCalendarSyncRemovalTests`, 16 cases in `GoogleSyncWindowTests` |
| Negative controls | 22 run in a detached worktree: 21 caught, 1 equivalent (N6) |
| Build | 0 errors; the known NU1603 warnings only |
| Real Google | not run |

---

---

# Round 1 — review `6ceee03`

The reviewer worked in a detached worktree at `6ceee03`, built into temporary folders, and removed
the worktree afterwards. Logs, the review-only probe tests (`ReviewProbesTests.cs`, which print what the
code does rather than assert) and the mutation scripts are kept in the session scratchpad under
`rv58/`.

## Scope

`SyncEventsAsync` lists one window of Google's calendar — 7 days back to 14 ahead by default, or the
range the calendar is browsing — and used to delete **every** synced local event missing from that
list, reading only the first page. The branch:

- reads every page (`ListWindowAsync`);
- deletes an event missing from the list only if `GoogleSyncWindow.CouldBeListed` and an
  `Events: get` answers cancelled, 404 or 410;
- makes `GetCalendarServiceAsync` `protected virtual`, so tests run the real method against a fake
  Google HTTP layer;
- adds 26 tests and updates `CLAUDE.md` and three documents.

## Author's claims, verified

| Claim | How checked | Result |
| --- | --- | --- |
| 8 of 13 removal tests fail on the pre-fix logic | Mutant P0b: the old removal condition and first page only. P0a: the old condition with pagination kept | ✔ P0b: 8 failed. P0a: 7 failed (all but page two) |
| 10/10 negative controls caught | Re-ran `mutate58.py` against the worktree | ✔ M1–M10 all caught |
| 222 tests pass | `dotnet test -o <tmp>` | ✔ 222 passed, 0 failed; a filtered run shows the 26 new ones |
| `dotnet build` clean | `dotnet build --no-incremental -o <tmp>` | ✔ 0 errors; warnings NU1603 and one CS8602 in an unchanged file |
| Docs match the code | Diff read line by line against code and probes | ✔ except the two sentences in R7 |
| "The client's form" test comment | `dart run` of the dialog's formatting expression | ✘ see R5 |

## Parts verified as correct

- Window bounds match Google's documented filter: end > `timeMin`, start < `timeMax`, both exclusive.
- `startTime=…Z` from the query string binds as `DateTimeKind.Utc` (probe PR9, through
  `RequestDelegateFactory`), so the window and the stored times compare correctly.
- Deleting a row the loop has already deleted is harmless: `DeleteAsync` finds nothing.
- The roadmap's claim that `GetEventsForUserAsync(userId, start, end)` returns every split-off day
  whatever its date (`EventRepository.cs:236`), so it could not have been the fix.

## Round 1 findings

### R1 — [MEDIUM — introduced] An event moved on Google keeps its old time locally

`IsGoneFromGoogleAsync` fetched the event and kept only its status. When the user moves tomorrow's
meeting to next month on Google, the window's list no longer has it, the local copy's old time is
still inside the window, the lookup answers "confirmed", and the local copy is kept **at tomorrow's
time**. It stays on the calendar, and its reminder fires, until some sync covers next month. Every
sync repeats the lookup. Before the branch the event was deleted, with its tasks, and re-created later.

Evidence: probe PR7 — `storedStart=2026-09-03T00:00:00Z (Google's Get answered start=2026-09-01T00:00:00Z)`.

Suggested fix: apply the fetched event the way steps 3–5 apply a listed one.

### R2 — [LOW — introduced] A network error during a lookup aborts the whole sync

Only `GoogleApiException` was caught. An `HttpRequestException` or an HttpClient timeout
(`TaskCanceledException`) reached the outer catch: `SyncEventsAsync` returned false and skipped every
upsert, while `GetEventsQuery` ignores the result and still marks the range fresh for a minute. That
contradicts the test name `…_AndTheSyncCarriesOn` and the architecture document.

Evidence: probe PR1 — `result=False listedTitle=listed` (a rename Google listed was not applied).
PR2 — a 503 is retried three times, 2.8 s for one candidate; 50 candidates answering 403 made 50 GETs.

Suggested fix: catch transport errors too, and stop looking up after the first failure.

### R3 — [LOW — introduced] Days of a series cancelled on Google survive as stand-alone events

The parent link has no cascade (EF's default `ClientSetNull`). When a series listed as cancelled is
deleted, its Google-linked days inside the window are looked up and deleted, but a day **outside**
the window gets `ParentEventId = null` and stays as a one-off event. Before the branch it was deleted
in the same sync. By reading, not measured: local-only days, which have no Google id, were already
orphaned the same way.

Evidence: probe PR4 — `master=False inWindowChild=False outWindowChild=True outParent=null`.

Suggested fix: when a series is deleted, delete its days whatever their date.

### R4 — [LOW] Test gaps: eight mutants survive

Run by `mutate_rv.py` (log `03-mutants.log`); N7 first failed to build and was corrected before
counting.

| Mutant | Survived because |
| --- | --- |
| N3 default look-back 3650 days | the default-window test never asserts that no lookup happened, and the fake says "exists" for unknown ids |
| N10 default look-ahead 0 | same |
| N4 `timeMin` / `timeMax` removed from the list request | the fake ignores the query string |
| N5 `ShowDeleted = false` | same; on real Google, cancelled days of a series would never reach step 4 |
| N6 a listed cancelled *instance* deleted in step 1 | rule predates the branch and is untested |
| N7 lookup catches every exception | no transport-error test (R2) |
| N9 anything not "confirmed" counts as gone | no tentative-status test |
| N11 a date-time `UNTIL` also gets +1 day | no test near the window edge |

Caught: N1 (410 not gone), N2 (unreadable UNTIL treated as ended), N8 (COUNT treated as ended).

### R5 — [LOW/INFO] The test comment names the wrong client format

`GoogleSyncWindowTests.cs:48` calls `FREQ=DAILY;INTERVAL=1;UNTIL=20260820T235959Z` "the client's form".
Running the dialog's formatting expression gives `RRULE:…;UNTIL=20260820 165959Z` — a space, not `T`.
`CouldBeListed` cannot parse it and treats the series as never-ending, which is safe (one extra
lookup). Out of scope and pre-existing: the client sends this non-RFC UNTIL to Google; what Google
does with it is unverified.

### R6 — [INFO]

- **Floating UNTIL** (no `Z`) is read as UTC, which underestimates a series' end west of UTC. Google
  emits `Z`, so this is unlikely.
- **A repeated `nextPageToken`** would loop for ever: probe PR10 made 29,185 list calls in 3 s, and the
  real callers pass `CancellationToken.None`. Google does not repeat tokens.
- **All-day events** are stored at UTC midnight while Google filters them in the calendar's time zone
  (by reading): in UTC+7 only extra lookups; west of UTC a purged event can be missed for one sync.
- **A reverted edited day** that the lookup still returns is kept (PR5); before the branch it was
  deleted. Needs a real Google account to know which is right.
- `ge.Recurrence.First()` can be an EXDATE line (pre-existing); `CouldBeListed` then says "could be
  listed", which is safe.

### R7 — [INFO] Two doc sentences

- `google-calendar-sync-architecture.md:156` "Any other answer, including an error, keeps the event"
  — kept, but the sync aborted on transport errors (R2).
- `:179` "Normally there are none" (lookups) — a moved event was looked up on every sync (R1).

## Process note

The author's `mutate58.py` edits files in the checkout, and its restore rewrote CRLF as LF: content
identical (`git diff --ignore-cr-at-eol` empty), but the files showed as modified on a CRLF worktree.
Mutation runs should happen in a worktree and restore bytes.


---

## Commands run to verify

Round 2 (author):

```bash
# full suite, into a temp folder because a backend may be running from src/Web
dotnet test tests/Application.UnitTests -o "$TEMP/rv58-after"
# -> Passed!  - Failed: 0, Passed: 232, Total: 232

# negative controls, in a worktree at c421e0d; each file restored byte for byte
git worktree add --detach <scratchpad>/wt58 HEAD
python <scratchpad>/mutate58r2.py
# M1  no window check                       CAUGHT (6 tests)
# M2  candidates deleted without lookup     CAUGHT (5)
# M3  first page only                       CAUGHT (2)
# M5  window start inclusive                CAUGHT (2)
# M6  UNTIL ignored                         CAUGHT (6)
# M8  series length ignored                 CAUGHT (2)
# M9  cancelled on lookup kept              CAUGHT (1)
# M10 window end inclusive                  CAUGHT (1)
# R1  found event not applied               CAUGHT AnEventMovedOutOfTheWindowOnGoogle_IsKept_AtItsNewTime
# R2a transport errors not caught           CAUGHT ANetworkErrorWhileChecking_…, AfterALookupFails_…
# R2b lookups continue after a failure      CAUGHT AfterALookupFails_TheRestAreKeptWithoutAsking
# R3  series days not deleted               CAUGHT ASeriesCancelledOnGoogle_TakesItsDaysWithIt_WhateverTheirDate
# R5  dialog UNTIL format not parsed        CAUGHT ASeriesThatBeganEarlier_DependsOnWhenItEnds
# R6a non-UTC UNTIL gets no grace           CAUGHT ADateOnlyUntil_…, ASeriesThatBeganEarlier_…
# R6b repeated page token not detected      CAUGHT (hang: test run exceeded 240 s)  -> made fail-fast, below
# N3  default look-back 3650 days           CAUGHT TheDefaultWindow_KeepsLastMonthsHistory
# N10 default look-ahead 0                  CAUGHT TheDefaultWindow_KeepsLastMonthsHistory
# N4  no timeMin                            CAUGHT TheDefaultWindow_…, TheListAsksForTheWindow_…
# N5  ShowDeleted false                     CAUGHT TheListAsksForTheWindow_…
# N6  listed cancelled instance in step 1   SURVIVED
# N9  not-confirmed counts as gone          CAUGHT ATentativeEvent_IsKept
# N11 UTC UNTIL gets +1 day                 CAUGHT AUtcUntil_GetsNoGrace
# No control failed to build.

# R6b again, with the fake failing any listing over 10 calls
# -> Failed: 1, Passed: 18 — ARepeatedPageToken_EndsTheListing, in 2 s

# N6 against a test written for it
dotnet test … --filter "FullyQualifiedName~ADayCancelledOnGoogle"
# baseline -> Passed: 1 ;  N6 -> Passed: 1   (equivalent)

git worktree remove --force <scratchpad>/wt58
```

Round 1 (reviewer): logs `01`–`06` in the session scratchpad under `rv58/` — the pre-fix comparison
(P0a/P0b), the author's controls re-run, `mutate_rv.py` (N1–N11), the review-only probes PR1–PR10, and
`dart run` of the dialog's UNTIL expression.

Before the branch (author): the 13 removal tests on `main`'s removal logic with only the test seam
added — **8 failed, 5 passed**.
