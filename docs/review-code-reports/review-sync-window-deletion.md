# Code review: `fix/sync-window-deletion`

Base: `c3cc04e` (`main`, merge of PR #31) · Reviewed by: Claude Code

| Round | Commit | Date | Outcome |
| --- | --- | --- | --- |
| 1 | `6ceee03` fix(sync): stop incoming sync deleting synced events outside its window | 2026-09-13 | The fix works: history and events past the window survive, every page is read; the author's 8/13, 10/10 and 222 all reproduced. 1 MEDIUM, 3 LOW, INFO notes — all introduced by the branch's new lookup, none a data-loss regression. **MEDIUM blocks merge** |
| 2 | uncommitted working tree (fixes for round 1) | 2026-09-13 | 🟡 **In progress** — see the tracker below |

> `git log main..HEAD` is one commit. Scope: 8 files, server and docs only, no migration.

---

# Round 2 — fixes for round 1 (in progress)

## Fix tracker

| # | Finding | Status |
| --- | --- | --- |
| R1 | [MEDIUM] An event moved on Google keeps its old time locally, and is looked up on every sync | 🟡 Code changed — what the lookup finds joins the list, so steps 2–5 apply it; test pending |
| R2 | [LOW] A network error during a lookup aborts the whole sync | 🟡 Code changed — transport errors and timeouts count as "unknown", keep the event, and stop further lookups for that sync; test pending |
| R3 | [LOW] Days of a series cancelled on Google survive outside the window as stand-alone events | 🟡 Code changed — deleting a series deletes its days first, whatever their date; test pending |
| R4 | [LOW] Eight surviving mutants: the fake ignores the list's query, no tentative / transport-error / edge-UNTIL tests, default-window test vacuous | ⚪ Not started |
| R5 | [LOW/INFO] Wrong "client's form" comment; the client's real `UNTIL=20260820 165959Z` is not parsed | ⚪ Not started |
| R6 | [INFO] Repeated page token loops for ever; floating `UNTIL` read as UTC | 🟡 Page-token guard added; floating UNTIL pending |
| R7 | [INFO] Two doc sentences contradicted by R1 and R2 | ⚪ Not started |

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
