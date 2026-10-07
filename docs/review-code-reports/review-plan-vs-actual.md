# Code review: `feat/plan-vs-actual`

Base: `a1fbea1` (tip of `feat/streak-at-risk`) · Reviewed by: Claude Code

| Round | Commit | Date | Outcome |
| --- | --- | --- | --- |
| 1 | `cdee12e` feat(analytics): show booked time against the time it actually took | 2026-09-12 | 0 HIGH, 1 MEDIUM, 1 LOW, 2 INFO — **MEDIUM 1 blocks merge** |
| 2 | `0aab01a` fix(analytics): count every finished session in the totals, not just habit ones | 2026-09-13 | The MEDIUM closed and verified on the real database, 2 INFO closed, 1 LOW half-closed. 2 new: 1 LOW, 1 INFO. 1 round-1 claim **corrected** (build warnings). **Nothing blocking.** |
| 3 | uncommitted working tree (fixes for round 2) | 2026-09-13 | Both new findings closed: the category view now carries its own remainder row, and the misleading test name is gone. No new findings. **Nothing blocking.** |
| 4 | `26bc628` fix(analytics): give the category view its own remainder row (round 3, now committed) | 2026-09-13 | Round 3 re-verified independently, both closures hold, both negative controls reproduce, 0 re-opened. 2 new INFO, both stale comments. **Nothing blocking.** |
| 5 | uncommitted working tree (fixes for round 4) | 2026-09-13 | Both INFO closed: the remainder guard checks all three fields (with a test), and the card's class doc matches its own tests. No new findings. **Nothing blocking.** |
| 6 | `96f3990` fix(analytics): guard every field of the remainder row, not just its count (round 5, now committed) | 2026-09-13 | Round 5 re-verified independently, both closures hold, the negative control reproduces, 0 re-opened. 1 new INFO (a doc clause). **Nothing blocking.** |
| 7 | uncommitted working tree (fix for round 6) | 2026-09-13 | The INFO closed: the class doc states when the views do not add up. No new findings. **Nothing blocking — the branch has converged.** |

> **The base is not `main`.** This branch is stacked on the unmerged `feat/streak-at-risk`:
> `git merge-base HEAD feat/streak-at-risk` is `a1fbea1`, which is that branch's tip. A
> three-dot diff against `main` pulls in 4 unrelated commits and 2 582 lines of
> streak-at-risk work, all of it already reviewed in `review-streak-at-risk.md` (rounds 1-5).
> Everything below is measured on `a1fbea1...HEAD`: `cdee12e` (the feature, round 1),
> `0aab01a` (round 1's fixes, round 2), `26bc628` (round 2's fixes, rounds 3-4) and
> `96f3990` (round 4's fixes, rounds 5-6). `46ab5a5` — which addresses that report's round-5
> findings 19 and 20 — sits on the streak branch, not this one, and belongs to that review.

---

# Round 7 — uncommitted working tree (fix for round 6)

One clause, as round 6 proposed.

## Status of round 6 findings

| # | Finding | Status |
| --- | --- | --- |
| 9 | [INFO] The class doc claims an invariant the guard deliberately breaks | ✅ **Closed** |
| 2 | [LOW] The category query is unconditional | ⚠️ Still half-closed, on round 3's reasoning |

### Finding 9 — closed

`plan_vs_actual_card.dart:18-22` now states the exception rather than the rule alone:

> Each view carries a row for the sessions its own grouping cannot show, so both add up to the
> headline above them — unless the groupings and the totals disagree, in which case that row is
> dropped rather than shown with negative durations (`_remainder`), and the view
> under-accounts until the next refresh.

Round 6's observation about the shape of that state is the part worth having in writing: the
visible symptom is not only a missing row but a bar reporting **more** booked time than the
headline above it. Someone reading a "the numbers don't add up" report will now find the
reason in the first comment they open, and the pointer to where the decision lives.

`flutter analyze` clean. No test changed: the behaviour this describes is already pinned by
`no row when the counts agree but the minutes do not`, and a comment is not testable.

## Round 7 verification

| Item | Round 6 | Round 7 |
| --- | --- | --- |
| `flutter analyze` | `No issues found!` | `No issues found!` |
| `flutter test` | 257 pass / 0 fail | 257 pass / 0 fail — unchanged, comment-only edit |
| `dotnet test` | not re-run | not re-run — no server file changed since round 2 |
| Findings re-opened | — | **0** |

## Round 7 notes

- This closes every finding that can be closed without a product decision. The remaining item,
  finding 2, is whether the category grouping is worth keeping at all — no account in the dev
  database has a categorised session — and that belongs with the person who decides what this
  app is for, not in a review round.
- Seven rounds is more than this feature warranted, and the reason is visible in the trail:
  rounds 4-7 each found one comment that had stopped matching the code a previous round
  changed. The code converged at round 3; the prose took four more.

---
# Round 6 — review `96f3990`, independent verification of round 5

Round 5 was written against an uncommitted tree; that tree is now `96f3990`
(`fix(analytics): guard every field of the remainder row, not just its count`) and
`git status` is clean. Client-only again — no server file has changed since round 2's live SQL
check.

A quiet round. Both round-4 findings are closed, the negative control reproduces, and the one
regression risk the change actually carried is clean. One INFO, in text written this round.

## Verifying round 5's claims

| Round 5 claimed | I verified with | Result |
| --- | --- | --- |
| Finding 7 closed — all three fields guarded | `plan_vs_actual.dart:95-110`; `if (sessions <= 0 \|\| planned < 0 \|\| actual < 0) return null;`, and the sums are computed once before the check rather than twice after | ✔ |
| …the inconsistent case no longer renders | re-ran round 4's own case (`byHabit` 6/620/600 against totals 8/600/570) | ✔ `row present=false` — was `-30 min of -20 min` |
| Negative control: narrowing to `sessions <= 0` fails 1 test | applied that exact mutation, ran `test/features/home/` | ✔ **exactly 1** — `no row when the counts agree but the minutes do not`, and nothing else |
| Finding 8 closed — class doc rewritten | `plan_vs_actual_card.dart:18-21` | ✔ the "several categories" clause is gone — but see finding **9** |
| `grep` finds no stale claim outside the report | `grep -rn "several categories\|at most one habit" apps/lib docs` | ✔ 11 hits, **all 11 inside this report**; nothing in `apps/lib`, nothing elsewhere in `docs/` |
| `fold<int>` everywhere | `plan_vs_actual.dart:85,98,99` | ✔ all three explicitly typed |
| `flutter test` → 257 pass | `flutter test` | ✔ `00:20 +257: All tests passed!` |
| `flutter analyze` → clean | `flutter analyze` | ✔ `No issues found! (ran in 4.7s)` |

### The regression this change could have caused, and did not

Widening the guard to the minute fields put it on top of the zero-`TargetDuration` case that
round 1 verified — a remainder of real sessions that were never booked any time. `planned` is
legitimately `0` there, and a guard written `planned <= 0` would have silently deleted that
row. It is written `< 0`:

```
PROBE zero-target remainder: sessions=2 planned=0 actual=0 (row present=true)
```

The row survives and still renders "No time was booked for these" via `ratio == null`, which
is the behaviour round 1 signed off. The asymmetry between `sessions <= 0` and `planned < 0`
in one condition looks like a typo and is the opposite — worth knowing before someone
"tidies" it.

### Round 5's own correction is the right kind

Round 5 records that its first version of the guard failed to compile (`fold` inferring `num`),
that it ran the negative control anyway, and that it reported the compile error as the control
being caught. That is worth keeping in the file: a control you do not read the output of proves
nothing, and it is the same failure as a vacuously passing test with the sign flipped. I re-ran
the control from the committed tree, so the "1 test fails" above is measured on code that
compiles.

## New findings

### 9 [INFO] The replacement class doc claims an invariant the new guard deliberately breaks

Finding 8 was a stale clause in `PlanVsActualCard`'s doc. The replacement
(`plan_vs_actual_card.dart:18-21`) reads:

> Categories follow, collapsed by default: the same sessions, grouped more coarsely, and
> worth a tap once anything is categorised. **Each view carries a row for the sessions its own
> grouping cannot show, so both add up to the headline above them.**

The bolded half is what finding 7's fix made conditional. When the groupings and the totals
disagree, `_remainder` returns null — no row is carried, and the view does not add up.
Measured on round 4's case:

```
PROBE inconsistent: row present=false | headline says 8 sessions, bars account for 6
PROBE rendered: "You booked 10h and spent 9h 30m across 8 sessions."
PROBE rendered: "Reading"  /  "10h of 10h 20m"  /  "20 min under, across 6 sessions"
```

Note the shape of it: the single bar reports **more** booked time than the headline total
(10h 20m against 10h) and fewer sessions (6 against 8). So the visible symptom is not only a
missing remainder — it is a row that overshoots the total above it.

This is the trade round 5 made on purpose, and I agree with it: the alternative renders
negative durations, and the state is transient, so suppressing the row is the least-bad
option for something that a refresh fixes. But it does mean the failure mode reverted to the
silent-undercount class that findings 1 and 5 were about, and the comment now asserts the
invariant that no longer always holds — in the file whose doc was just corrected for exactly
that kind of over-claim.

Impact: documentation only, and narrow. It matters because this comment is the one a person
debugging a real "the numbers don't add up" report would read first, and it would tell them
the code guarantees something it does not.

**Fix**: one clause.

> …so both add up to the headline above them — unless the groupings and the totals disagree,
> in which case the row is dropped rather than shown negative (see `_remainder`).

## Round 6 verification

| Item | Round 5 | Round 6 |
| --- | --- | --- |
| `flutter test` | 257 pass / 0 fail | **257 pass / 0 fail** — reproduced |
| `flutter analyze` | `No issues found!` | `No issues found!` |
| `dotnet test` | not re-run | not re-run — **0 server files** changed since round 2's live check |
| Inconsistent case renders | claimed no row | **no row** — reproduced on round 4's exact input |
| Zero-target remainder still renders | not measured | **yes** — `planned=0` passes a `< 0` guard |
| Negative control: guard narrowed to the count | 1 fail | **1 fail** — reproduced from the committed tree |
| Stale claims outside this report (`grep`) | claimed 0 | **0** — all 11 hits are report text |
| Round 5 findings re-opened | — | **0** |
| `git status --porcelain` after the control | empty | empty (mutation reverted) |

## Round 6 notes

- Six rounds in, every finding that changed behaviour is closed and measured: the totals
  (round 1's MEDIUM), the category remainder (5), and the guard (7). What is left is one
  comment clause. The branch has converged.
- The one open item is finding 2 — the category query runs unconditionally — held
  half-closed since round 3 on the reasoning that whether categories are part of this product
  is a product call, not a review item. Still the right place for it.
- Rounds 3-6 were all client-only. The two grouping queries and the totals query have not
  changed since I ran them against real Postgres in round 2, so that evidence still stands.

---

# Round 5 — uncommitted working tree (now committed as `96f3990`)

Round 4's two findings, fixed on top of `26bc628`. Both were comments that no longer matched
the code beside them; one of them was hiding a real render.

## Status of round 4 findings

| # | Finding | Status |
| --- | --- | --- |
| 7 | [INFO] The remainder guard checks only the session count | ✅ **Closed** — all three fields, with a test and a negative control |
| 8 | [INFO] The card's class doc still says "only once there are several categories" | ✅ **Closed** — rewritten to match the gate and the tests |
| 2 | [LOW] The category query is unconditional | ⚠️ Still half-closed, on round 3's reasoning |

### Finding 7 — closed: the guard covers what its comment claims

`_remainder` now computes all three numbers before deciding:

```dart
if (sessions <= 0 || planned < 0 || actual < 0) return null;
```

Round 4's reachability analysis is right, and it is the part worth keeping: the groupings and
the totals are three separate queries with no snapshot between them, so a session finished or
deleted mid-load can leave the count positive while the minutes go negative. That rendered as
`-30 min of -20 min` beneath a caption saying no time was booked.

| Round 4's case: `byHabit` 6 sessions / 620 planned, totals 8 / 600 | Before | After |
| --- | --- | --- |
| `unlinkedSessions` | 2 | 2 — the count still looks fine |
| `unlinked` | a row with −20 planned, −30 actual | **null** |

Pinned by `no row when the counts agree but the minutes do not`, with the reason in the test
body. Negative control: narrowing the guard back to `sessions <= 0` fails that test and
nothing else.

Not fixed, and deliberately: the three queries still have no snapshot between them. A
read-only transaction for a dashboard card costs more than a transient row that disappears on
the next refresh — round 4's own judgement, which I agree with. The other half of that seam,
a mid-load completion labelled "Not linked to a habit" with positive numbers, is unguardable
from the client and equally transient.

### Finding 8 — closed

The class doc's last clause is replaced, and it now also states the invariant the card
actually holds:

> Categories follow, collapsed by default: the same sessions, grouped more coarsely, and
> worth a tap once anything is categorised. Each view carries a row for the sessions its own
> grouping cannot show, so both add up to the headline above them.

Round 4's process note is worth acting on rather than just recording: three times on this
branch a claim survived in a second place after being fixed in the first. Checked by grep
this time — `grep -rn "several categories\|at most one habit" apps/lib docs` returns nothing
outside this report.

## A round-5 mistake, for the record

My first version of the guard read the two sums into locals without a type argument, so
`fold` inferred `num` and the file stopped compiling. I then ran the negative control and
reported "CAUGHT (1 failed)" — which was the compile error failing the test, not the guard
catching anything. Fixed with `fold<int>`, and the control re-run: no compile error, 1 test
fails. A negative control whose output you do not read is worth nothing, which is the
convention's own point about vacuous passes, in reverse.

## Round 5 verification

| Item | Round 4 | Round 5 |
| --- | --- | --- |
| `flutter test` | 256 pass / 0 fail | **257 pass / 0 fail** (+1) |
| `flutter analyze` | `No issues found!` | `No issues found!` |
| `dotnet test` | not re-run | not re-run — no server file changed since round 2's live check |
| Remainder with negative minutes | renders `-30 min of -20 min` | **no row** |
| Negative control: guard narrowed to the count | — | **1 test fails** (re-run after the compile fix) |
| Stale claims elsewhere (`grep`) | 3 occurrences across the branch | **0 outside the report** |
| Round 4 findings re-opened | — | **0** |

---

# Round 4 — review `26bc628`, independent verification of round 3

Round 3 was written against an uncommitted tree; that tree is now `26bc628`
(`fix(analytics): give the category view its own remainder row`) and `git status` is clean.
Client-only: `git diff --name-only 0aab01a..HEAD | grep -c '^server/'` → `0`, so the SQL
checked live in round 2 has not changed.

Every round-3 claim was re-run here, including both negative controls.

## Verifying round 3's claims

| Round 3 claimed | I verified with | Result |
| --- | --- | --- |
| Finding 5 closed — the category view accounts for the headline | re-ran **round 2's own probe fixture** (10 sessions, 6 on habits, only 3 categorised) through the card | ✔ see table below |
| Both remainders are one helper | `plan_vs_actual.dart:68-101` — `unlinked => _remainder(byHabit)`, `uncategorised => _remainder(byCategory)` | ✔ one code path, two call sites |
| The remainder row is inside the expanded view | `plan_vs_actual_card.dart:265-274` — inside `if (_open)` | ✔ not shown while collapsed |
| Negative control: both remainders from `byHabit` → 2 tests fail | pointed `uncategorised` at `byHabit`, ran `test/features/home/` | ✔ **exactly 2**, and usefully one per layer: `sessions with no category get the same remainder row as habitless ones` (model) and `the category view adds up to the same headline as the habit rows` (card) |
| Negative control: remainder row dropped → 1 test fails | removed the `_ItemRow` from `_CategoryBreakdown` | ✔ **exactly 1** — `the category view adds up to the same headline as the habit rows` |
| Finding 6 closed — test renamed | `plan_vs_actual_card_test.dart:69` is now `the category view is behind a tap` | ✔ — but the same claim survives elsewhere, finding **8** |
| `flutter test` → 256 pass | `flutter test` | ✔ `00:20 +256: All tests passed!` |
| `flutter analyze` → clean | `flutter analyze` | ✔ `No issues found! (ran in 4.5s)` |
| i18n for the new label | `home_plan_actual_uncategorised` | ✔ en `No category` / vi `Chưa có nhóm` |

### Finding 5 — closed, measured on the fixture that exposed it

The same input round 2 used, so the two rounds are directly comparable:

| View | Round 2 (`0aab01a`) | Round 4 (`26bc628`) |
| --- | --- | --- |
| Habit rows + remainder | 10 of 10 sessions | 10 of 10 |
| Category rows + remainder | **3 of 10**, silently | **10 of 10** |

Rendered, with "By category" tapped:

```
PROBE rendered: "You booked 10h and spent 8h 20m across 10 sessions."
PROBE rendered: "Reading"               / "5h of 6h"      / "1h under, across 6 sessions"
PROBE rendered: "Not linked to a habit" / "3h 20m of 4h"  / "40 min under, across 4 sessions"
PROBE rendered: "Study"                 / "2h 30m of 3h"  / "30 min under, across 3 sessions"
PROBE rendered: "No category"           / "5h 50m of 7h"  / "1h 10m under, across 7 sessions"
```

Both views now add to the headline exactly: 6 + 4 and 3 + 7 sessions, 5h + 3h 20m and
2h 30m + 5h 50m, against 10 sessions and 8h 20m of 10h. A session with neither a habit nor a
category appears in both remainders, which is correct — they are two independent groupings of
the same sessions, and neither view double-counts within itself.

The collapse gate is still `report.byCategory.isNotEmpty`, which is the right condition to
keep: with nothing categorised at all the view would be a single "No category" row restating
the headline, and it stays hidden.

## New findings

### 7 [INFO] The remainder's null guard checks only the session count, though its comment claims more

`plan_vs_actual.dart:86-101`:

```dart
/// What [rows] leave unaccounted, as a row of its own. Null when they account for
/// everything — or for more than everything, which would mean the server disagreed with
/// itself and is better shown as nothing than as a negative bar.
PlanVsActualItem? _remainder(List<PlanVsActualItem> rows) {
  final sessions = _missingSessions(rows);
  if (sessions <= 0) return null;

  return PlanVsActualItem(
    …
    plannedMinutes: totalPlannedMinutes - rows.fold(0, (sum, i) => sum + i.plannedMinutes),
    actualMinutes: totalActualMinutes - rows.fold(0, (sum, i) => sum + i.actualMinutes),
  );
}
```

Three fields are subtracted; one is guarded. A response whose session counts are consistent
but whose minutes are not slips straight through. Measured — `byHabit` reporting 6 sessions
and 620 planned minutes against totals of 8 sessions and 600:

```
PROBE remainder sessions=2 planned=-20 actual=-30 ratio=null diff=-10
PROBE neg rendered: "Not linked to a habit"
PROBE neg rendered: "-30 min of -20 min"
PROBE neg rendered: "No time was booked for these"
```

Negative durations in the pair text, and a caption that says no time was booked when the
arithmetic says the opposite. The bar itself is safe — `ratio` is null because
`plannedMinutes <= 0`, so nothing is drawn — which is why only the text is wrong.

Reachability is narrow but real, and it is not the rounding path: round 2 established that
every duration is a whole number of minutes (`TimeSpanConverter.toJson` emits `HH:MM:00`,
0 of 82 rows sub-minute), so `ROUND` cannot make the two sides disagree. What can is that the
handler takes **three separate round trips with no snapshot between them**
(`GetPlanVsActualQuery.cs:95-97` — three sequential awaits, no transaction). A write landing
between the first query and the third makes the groupings and the totals describe different
states:

- a session **completed** mid-load lands in the totals but not in `byHabit`, so it shows up as
  "Not linked to a habit" when it is in fact linked — the label lies, the numbers stay positive;
- a session **deleted or un-completed** mid-load can leave the minute remainder negative while
  the count stays positive, which is the render above.

Both are transient — the next pull-to-refresh is consistent — so INFO rather than higher. But
the comment asserts the guard covers "the server disagreed with itself", and it covers one
third of that. Either widen it (`if (sessions <= 0 || planned < 0 || actual < 0) return null;`,
or clamp each field at zero) or narrow the comment to say it guards the count only. Widening
is two lines and makes the comment true.

Not worth wrapping the three queries in a transaction for this: a read-only snapshot for a
dashboard card costs more than a wrong row that disappears on refresh.

### 8 [INFO] The card's own doc comment still carries the claim finding 6 removed from the test name

Round 2's finding 6 was that a test name asserted the category view appears "only with
several categories" after the gate had become `isNotEmpty`. Round 3 renamed the test.
`PlanVsActualCard`'s class doc (`plan_vs_actual_card.dart:18-20`) says the same thing:

> Habits lead, because that is the unit people plan in. Categories follow, collapsed by
> default: the same sessions, grouped more coarsely, and **useful only once there are
> several categories**.

The test directly below the renamed one is `one category is still offered, behind the same
tap` (`:89`), whose comment explains that hiding it below two categories was why the view had
never been seen against real data. So the file's own tests contradict its class doc.

Trivial to fix — drop the last clause, or replace it with "and worth a tap once anything is
categorised" — but worth logging because it is the third time in this branch that a claim
survived in a second location after being fixed in the first (round 1's finding 1 premise
lived in three places; round 2's finding 6 in two). The pattern is consistent enough to be
worth a habit: when a gate or an invariant changes, grep the phrase, not just the line.

## Round 4 verification

| Item | Round 3 | Round 4 |
| --- | --- | --- |
| `flutter test` | 256 pass / 0 fail | **256 pass / 0 fail** — reproduced |
| `flutter analyze` | `No issues found!` | `No issues found!` |
| `dotnet test` | not re-run | not re-run — **0 server files** changed since round 2's live check |
| Category rows + remainder vs headline | claimed exact | **exact**, on round 2's own fixture |
| Negative control: remainders both from `byHabit` | 2 fail | **2 fail** — reproduced, one per layer |
| Negative control: remainder row dropped | 1 fail | **1 fail** — reproduced |
| Remainder with negative minutes | not measured | **renders** `-30 min of -20 min` — finding 7 |
| Round 3 findings re-opened | — | **0** |
| `git status --porcelain` after controls | empty | empty (both mutations reverted) |

## Round 4 notes

- Round 3's fix is the right shape, and better than what round 2 proposed: I suggested mirror
  getters, the commit factored the subtraction into one `_remainder` so a third grouping gets
  it for free and the two rows cannot drift apart. The negative controls are also well
  chosen — the `byHabit`/`byCategory` swap is the mutation that a careless refactor would
  actually make, and it fails in both layers.
- Both findings are cosmetic and in the same class: a comment that no longer matches the code
  beside it. Neither blocks.
- Finding 2 (the category query runs unconditionally) stays half-closed on round 3's
  reasoning, which I agree with — whether categories are part of how this app is used is a
  product call, and it is now recorded in roadmap 2.1 rather than carried as a review item.

---

# Round 3 — uncommitted working tree (now committed as `26bc628`)

Round 2's two findings, fixed on top of `0aab01a`. Finding 5 was the same defect as round 1's
MEDIUM, on the half of the card I had not touched — so the fix is the one round 2 proposed,
with the duplication removed rather than written twice.

## Status of round 2 findings

| # | Finding | Status |
| --- | --- | --- |
| 5 | [LOW] The category view accounts for a fraction of the headline | ✅ **Closed** — `uncategorised` remainder row, mirroring `unlinked` |
| 6 | [INFO] A test name asserts the opposite of the test beside it | ✅ **Closed** — renamed |
| 2 | [LOW] The category query is unconditional | ⚠️ Still half-closed — see below |

### Finding 5 — closed, and the asymmetry that caused it removed

The two remainders are now one helper on the model. Each grouping's row is whatever that
grouping leaves unaccounted, so neither can drift from the totals it is derived from:

```dart
PlanVsActualItem? get unlinked => _remainder(byHabit);
PlanVsActualItem? get uncategorised => _remainder(byCategory);
```

| View, with 4 sessions and one category covering 1 | Round 2 | Round 3 |
| --- | --- | --- |
| Habit rows + remainder | 4 of 4 sessions | 4 of 4 |
| Category rows + remainder | **1 of 4**, silently | **4 of 4** — "Study" plus "No category" (3 sessions, 1h 39m) |

`_remainder` returns null when a grouping accounts for everything **or more** than the
totals: that can only happen if the server disagrees with itself, and a negative bar is worse
than no row. Round 2 did not ask for that case; it is one line and it has its own test.

Measured: the card test taps "By category" and finds both rows, and the remainder's pair
reads `1h 39m of 2h` against the headline's `1h 59m of 2h 30m`.

Negative controls, each reverted immediately:

| Mutation | Result |
| --- | --- |
| remainder row dropped from the category view | 1 test fails |
| both remainders computed from `byHabit` | 2 tests fail |
| a negative remainder rendered instead of hidden | 6 tests fail |

### Finding 6 — closed

`the category view is behind a tap, and only with several categories` → `the category view is
behind a tap`. The test below it already proves the second half is no longer true.

### Finding 2 — still half-closed, deliberately

The category query still runs on every load. It is one indexed aggregate per visit to Home,
and the view it feeds is now correct when there is data for it; dropping the grouping instead
is a product decision — whether categories are part of how this app is used — not a fix.
Recorded in roadmap 2.1 rather than carried as a review item.

## Round 3 verification

| Item | Round 2 | Round 3 |
| --- | --- | --- |
| `flutter test` | 251 pass / 0 fail | **256 pass / 0 fail** (+5) |
| `flutter analyze` | `No issues found!` | `No issues found!` |
| `dotnet test` | 154 pass / 0 fail | not re-run — no server file changed in this round |
| Category rows + remainder vs headline | 3 of 10 sessions | **exact** |
| Negative controls | 8 (round 1 commit) | + 3, all caught |
| Round 2 findings re-opened | — | **0** |

## Round 3 notes

- The shape of this review is worth keeping: round 1 found the habit half, round 2 found that
  the fix had not been applied to the category half, and both were the same sentence in two
  places. The model now has one helper, so a third grouping would get it for free.
- Nothing in rounds 2 or 3 touched the server. The SQL has not changed since the live check in
  round 2.

---

# Round 2 — review `0aab01a`

`fix(analytics): count every finished session in the totals, not just habit ones`, on top of
`cdee12e`. Re-measured here; nothing carried over from round 1 on trust.

## Status of round 1 findings

| # | Finding | Status |
| --- | --- | --- |
| 1 | [MEDIUM] A finished session with no habit is counted nowhere, so the card shows the empty state | ✅ **Closed** — third un-joined query for the totals; verified against the real database |
| 2 | [LOW] The category query runs on every load and returns nothing for any user | ⚠️ **Half-closed** — the `length > 1` gate is gone so the view is now reachable, but the query is still unconditional. See finding **5**, which the change exposed |
| 3 | [INFO] Third consumer of the hardcoded UTC+7 day boundary | ✅ **Closed** — recorded in roadmap 5.1's inventory |
| 4 | [INFO] The card test imports its fixture from another test file | ✅ **Closed** — `apps/test/features/home/plan_vs_actual_fixture.dart` |

### Finding 1 — closed: the totals are their own query, and the habitless user now sees their data

`GetPlanVsActualTotalsAsync` (`EventRepository.cs:88-111`) is the same aggregate with **no
join at all**, and the handler uses it instead of summing `ByHabit`
(`GetPlanVsActualQuery.cs:97,103-105`). The client derives the missing slice by subtraction
and renders it as its own row (`plan_vs_actual.dart:72-90`, `plan_vs_actual_card.dart:91-98`)
under `home_plan_actual_unlinked` — "Not linked to a habit" / "Không thuộc thói quen nào".

Verified by calling all three repository methods against the real database, over the window
the handler actually builds:

```
PROBE 48a67a1e-…39784: byHabit rows=0 sessions=0 | byCategory rows=0 sessions=0 |
                        TOTALS sessions=14 planned=795 actual=715 | unlinked=14 | isEmpty=False
PROBE u1:               byHabit rows=0 sessions=0 | byCategory rows=0 sessions=0 |
                        TOTALS sessions=0 planned=0 actual=0   | unlinked=0  | isEmpty=True
```

| Same user, same window | Round 1 (`cdee12e`) | Round 2 (`0aab01a`) |
| --- | --- | --- |
| `TotalSessions` | 0 | **14** |
| `TotalActualMinutes` | 0 | **715** |
| `isEmpty` → card | `true` → "Finish a focus session and the comparison shows up here." | **`false`** → headline + one "Not linked to a habit" row covering all 14 |

(Round 1 measured 15 sessions / 790 minutes for this user and round 2 measures 14 / 715: the
date rolled to 2026-09-13 between the two reviews, so the rolling 14-day window dropped a
day. Same user, same defect, same fix — only the window moved.)

Covered by tests on both sides: `TotalsCountEverySession_NotASumOfEitherGrouping`,
`ReportsSessionsWithNoHabit_InsteadOfNothingAtAll` on the handler, and `sessions with no
habit get their own row, not an empty state` plus `no row when every session belongs to a
habit` on the card — the second being the negative control for the first. The stale premise
was corrected everywhere it appeared: the DTO summary (`GetPlanVsActualQuery.cs:33-38`), the
roadmap's "Limits worth knowing", and the test that used to pin the old behaviour.

### Deriving the row by subtraction is safe, because durations are whole minutes by construction

Worth recording, because it is the one thing about this fix that could have been wrong.
`unlinked*` is `total − Σ(habit rows)`, and each side is `ROUND(SUM(…)/60.0)` computed
separately in SQL — per group on one side, over the whole window on the other. Rounding each
group and then summing is not the same as rounding the sum, so in principle the difference
could drift, or even go negative while the session count was positive.

It cannot, because nothing writes a sub-minute duration. `TimeSpanConverter.toJson`
(`event_model.dart:23-28`) emits `HH:MM:00`, and the client models both fields as
`int` minutes. Measured over every finished session in the database:

```
PROBE targetNotWholeMin=0 actualNotWholeMin=0 of 82
PROBE u1  habitRowsPlanned=3270 totalPlanned=3270 -> unlinkedPlanned=0
          habitRowsActual=2066  totalActual=2066  -> unlinkedActual=0
```

Exact, not approximately exact. The session count is a `COUNT(*)` and never rounded, and the
null guard is on that count (`unlinkedSessions <= 0 ? null`), which is the right field to
guard on. The invariant is implicit rather than enforced, so it is worth knowing it is what
holds this up.

## New findings

### 5 [LOW] The category view accounts for a fraction of the headline, and says nothing about the rest

Finding 1 was that the totals ignored sessions the habit grouping cannot see. The category
grouping cannot see a different set — events with no `CategoryId` — and got no equivalent
row. Now that the totals count every session, the category rows are guaranteed to under-account
for any user who has even one uncategorised session.

`_ReportBody` builds the unlinked row for habits and hands `_CategoryBreakdown` the raw list
(`plan_vs_actual_card.dart:91-102`):

```dart
if (report.unlinked case final unlinked?)
  _ItemRow(item: unlinked, label: translations.translate('home_plan_actual_unlinked')),
if (report.byCategory.isNotEmpty) ...[
  _CategoryBreakdown(items: report.byCategory),
```

Measured — 10 finished sessions, 6 on habits and 4 on plain events, of which only 3 carry a
category:

```
PROBE totals=10 sessions, 500 min actual
PROBE habit view accounts for    = 10 sessions  (rows + unlinked)
PROBE category view accounts for = 3 sessions
```

and what the card renders once "By category" is tapped:

```
PROBE rendered: "You booked 10h and spent 8h 20m across 10 sessions."
PROBE rendered: "Reading"               / "5h of 6h"     / "1h under, across 6 sessions"
PROBE rendered: "Not linked to a habit" / "3h 20m of 4h" / "40 min under, across 4 sessions"
PROBE rendered: "Study"                 / "2h 30m of 3h" / "30 min under, across 3 sessions"
```

The habit rows plus the unlinked row add up to the headline exactly — 6 + 4 = 10 sessions,
5h + 3h 20m = 8h 20m. The category view under the same headline shows one row for 3 sessions
and 2h 30m, accounting for 30% of it, with nothing indicating the other 70% exists.

Impact: lower than finding 1 — it is one tap down, the numbers shown are each correct, and
no user in the dev database has a categorised session at all (`byCategory rows=0`), so
nobody has hit it yet. But it is the same defect in the same card, and round 2 made it
easier to reach: dropping the `length > 1` gate to `isNotEmpty` means a single category now
opens the view, and a single category is exactly the case most likely to cover a small
fraction of the window. The entity remark and the roadmap both still present "uncategorised
events are absent rather than bundled" as a settled decision, which it was when the totals
came from the habit grouping and disagreed with everything anyway.

**Fix**: symmetric with the one already written, and the client already has the numbers —
add the mirror getters and pass the row into `_CategoryBreakdown`:

```dart
int get uncategorisedSessions =>
    totalSessions - byCategory.fold(0, (sum, i) => sum + i.sessions);
// …PlannedMinutes, …ActualMinutes, and an `uncategorised` item like `unlinked`
```

with a `home_plan_actual_uncategorised` string ("No category" / "Chưa có nhóm"). If the
decision is instead to leave the category view partial, then it needs to say so — the label
on the toggle, or a line under the rows — because a breakdown that silently covers 30% of
the number above it is the failure finding 1 was about. Either way the test to add is a
category grouping that does not account for every session, which is what is missing now.

### 6 [INFO] A test name now asserts the opposite of the test beside it

`plan_vs_actual_card_test.dart:69`:

```dart
testWidgets('the category view is behind a tap, and only with several categories', …
```

The "only with several categories" half stopped being true in this commit — the gate is now
`report.byCategory.isNotEmpty` — and the very next test (`:90`) is
`one category is still offered, behind the same tap`, which proves it. The body of the first
test only asserts that the view is collapsed by default and that two categories both render,
so it is not wrong, just misnamed. Rename to `the category view is behind a tap` and the pair
reads correctly.

## A round-1 claim corrected

Round 1's verification table says `dotnet build` → "0 warnings, 0 errors". The errors are
right, the warnings are not: the build emits **6 NU1603 warnings**, all of them
`Infrastructure depends on Google.Apis.Calendar.v3 (>= 1.68.0.3411) but … 1.68.0.3430 was
resolved instead`. They are pre-existing and nothing to do with this branch — it touches no
`.csproj` (`git diff --name-only a1fbea1...HEAD | grep -c csproj` → `0`) — but I had only
read the tail of the output and should not have reported a warning count I had not looked at.

## Round 2 verification

| Item | Round 1 | Round 2 |
| --- | --- | --- |
| `dotnet build` | reported "0 warnings" — wrong, see above | **0 errors, 6 pre-existing NU1603 warnings** |
| `dotnet test` | 153 pass / 0 fail | **154 pass / 0 fail** (+1) |
| `flutter analyze` | `No issues found!` | `No issues found!` |
| `flutter test` | 246 pass / 0 fail | **251 pass / 0 fail** (+5) |
| Totals for the habitless user, real DB | 0 sessions, `isEmpty=true` | **14 sessions, 715 min, `isEmpty=false`** |
| Habit rows + unlinked vs headline | n/a | **exact** (10/10 sessions, 8h 20m/8h 20m) |
| Category rows vs headline | n/a | **3 of 10 sessions** — finding 5 |
| Sub-minute durations in the database | not measured | **0 of 82** — the subtraction is exact |
| Round 1 findings re-opened | — | **0** |
| `git status --porcelain` after probes | empty | empty (both probe files deleted) |

## Round 2 notes

- The fix went further than round 1 asked. I suggested making the totals honest; the commit
  also gave the unaccounted sessions a visible row, which is what makes the headline and the
  bars agree rather than merely making the headline correct. The `unlinked` derivation on the
  client — rather than a fourth server field — is the better call: it cannot disagree with
  the totals it is derived from.
- There are now three round trips per card load (habit, category, totals). Acceptable: each
  is one indexed aggregate, the provider is `autoDispose` and does not watch `eventsProvider`,
  so it is three queries per visit to Home, not per rebuild. Worth remembering if a fourth
  grouping ever arrives — that is the point to reach for `GROUPING SETS` instead.
- Finding 5 is the only thing standing, and it is not blocking.

---

# Round 1 — review `cdee12e`

Kept as the record. See round 2 above for the current status of each finding.

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

---

# Conclusion

The branch does what roadmap 2.1 asked and puts it where it belongs: two aggregates in
Postgres, a handler that owns the window, and a card that reads the result. Nothing is
computed in C# that SQL can group, and the client derives only what it can derive from
numbers it already has.

Design decisions that hold up:

- **Only finished sessions take part**, so both sides of the comparison describe the same
  sessions. "You did 4 of the 9 you booked" is the activity card's question, and keeping the
  two apart is what makes either readable.
- **The window is the activity card's window**, reused rather than redefined, so two cards on
  one screen cannot disagree about "last 14 days".
- **The totals are their own query.** Neither grouping sees every session, so any sum of them
  is wrong in one direction or the other.
- **Each grouping carries its own remainder row**, derived on the client from the totals, so a
  view either adds up to the headline above it or says what it is missing.

After 7 rounds: 9 findings, 8 closed, 1 half-closed by choice (2 — the category query is
unconditional; whether the grouping is worth keeping at all is a product decision, recorded
in roadmap 2.1). **No HIGH. The MEDIUM is closed. Does not block merge.**

The MEDIUM is the one to remember. The feature was measured live, 13 checks passed, and it
was still broken for the only account in the database with data in the window — because every
check used data the probe had just created, all of it habit-linked. The review found it by
asking what the *existing* rows look like. Round 2 then found that the fix had been applied to
the habit half and not the category half, which was the same sentence written in two places;
round 3 made it one helper.

Rounds 4 and 5 found no behaviour left to fix in the feature itself — only comments that had
stopped matching the code beside them, one of which was hiding a real render (a remainder row
with negative minutes, reachable because the three queries have no snapshot between them).
That class of finding appeared four times on this branch, always a claim left standing in a
second location after being fixed in the first, and it is now checked by grep rather than by
reading.

Process note: each round's fix came with negative controls (8, then 3, then 1), and two rounds
corrected their own earlier claims — round 2 a "0 warnings" that had not been looked at, round
5 a negative control that was measuring a compile error rather than the guard it was aimed at.
Both corrections are in the rounds themselves, which is the convention working as intended.

## Commands run to verify

### Round 1

```
git merge-base HEAD feat/streak-at-risk                       # a1fbea1 - the real base
git diff --stat a1fbea1...HEAD                                # exactly one commit
dotnet build ; dotnet test -o /tmp/pvatest                    # 0 errors; 153 pass
cd apps && flutter analyze && flutter test                    # clean; 246 pass
psql (5432, read-only) per-user finished sessions             # 82 total, 17 habitless
psql ... in-window per user                                   # 15 of 15 habitless - finding 1
widget probe: the card fed what the server returns            # empty state - finding 1
psql ... events with a category and a session                 # 0 - finding 2
git status --porcelain                                        # empty (probes deleted)
```

### Round 2

```
psql (5432, read-only) habitless sessions, per user and in-window   # re-measured: 15/15, 790 min
dotnet build                                                  # 0 errors, 6 pre-existing NU1603
dotnet test -o /tmp/pvatest2 ; flutter test                   # 154 pass ; 251 pass
CREATE DATABASE "pva-check2" TEMPLATE "habit-tracker"         # 5433, throwaway
dotnet /tmp/pvaweb2/Web.dll (:5099) ; live_pva_check.py       # 16/16, totals 5/195/169
psql ... sub-minute ActualDuration rows                       # 0 of 82
probe: habit rows + unlinked vs headline                      # exact; category view 3 of 10
DROP DATABASE "pva-check2"                                    # dropped after the run
```

### Round 3

```
flutter test test/features/home/                              # 83 pass
flutter analyze ; flutter test                                # clean ; 256 pass
python negative controls (3 mutations)                        # 1, 2 and 6 tests fail; restored
git status --porcelain                                        # no stray probe files
```

### Round 4

As recorded in that round's own write-up:

```
flutter test ; flutter analyze                                # 256 pass ; clean
probe: remainder with inconsistent minutes                    # renders -30 min of -20 min
negative controls re-run (2 of round 3's)                     # 2 fail, 1 fail - reproduced
git diff --name-only | grep -c '^server/'                     # 0 - dotnet test not re-run
git status --porcelain                                        # empty
```

### Round 5

```
flutter test test/features/home/domain/plan_vs_actual_test.dart   # 12 pass (after fold<int>)
sed guard -> 'sessions <= 0' && flutter test <that file>          # 1 fails, no compile error
flutter analyze ; flutter test                                    # clean ; 257 pass
grep -rn "several categories|at most one habit" apps/lib docs     # 0 outside the report
git status --porcelain                                            # mutation reverted
```

### Round 6

As recorded in that round's own write-up:

```
flutter test ; flutter analyze                                # 257 pass ; clean
probe: inconsistent groupings vs totals                       # no row; bar overshoots headline
probe: planned=0 remainder                                    # still renders, as intended
negative control re-run (round 5's)                            # 1 fail - reproduced
grep -rn <the corrected claims> apps/lib docs                  # 11 hits, all report text
git status --porcelain                                        # empty
```

### Round 7

```
flutter analyze                                               # No issues found (12.7s)
```
