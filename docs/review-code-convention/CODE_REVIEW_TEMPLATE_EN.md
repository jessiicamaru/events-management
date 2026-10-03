# Code review template

Use this file as the skeleton every time you review a branch/PR. This structure is
distilled from 4 real reviews (`review-074-rich-text-tables.md`,
`review-email-notification-wiring.md`, `review-fix-rich-text-length-limits.md`,
`review-hire-date-reenroll-override.md`) — keep the same spirit and format, just
swap in the content for the branch under review.

Review file name: `review-<short-branch-name>.md`

---

## 0. General principles (apply throughout, not a section to fill in)

- **Multi-round, never rewritten from scratch.** Every time there's a new commit /
  new change on the branch → add a new "Round N" at the **top** of the file, never
  delete older rounds. Old rounds stay as historical record.
- **Don't trust a previous report, verify it again.** If a prior round was written
  by a different session/person, the next round must re-run every check itself —
  never take the prior write-up at face value as evidence.
- **Measure for real, don't infer.** Prefer: running commands, building fixtures,
  calling functions/RPCs directly, measuring real performance — over reading code
  and asserting. Paste real input/output into the review.
- **Nail down the real base.** If `main`/`develop` is way out of date (huge diff,
  not the branch's actual scope), state explicitly what base is actually used for
  the diff (usually `HEAD~1`, or the true parent commit) — as a blockquote line
  right under the top table.
- **State clearly what was NOT fixed and why.** A finding can be closed as
  "acceptable, not fixing" — as long as the reasoning and trade-off are written
  down. Don't leave the status implicit.
- **Give credit when the commit does better than your own suggestion.** If the
  author chose a different (and better) direction than what you proposed in a
  previous round, say clearly why it's better.
- **Distinguish this branch's bugs from pre-existing / out-of-scope issues.**
  Always confirm by re-running against the base/prior commit — don't guess.
- **Severity**: `HIGH` / `MEDIUM` / `LOW` / `INFO`, used consistently. HIGH/MEDIUM
  should block merge; LOW/INFO are noted but non-blocking.
- Write in plain, technical, no-fluff prose (matching the tone of the 4 sample
  files) — direct, no padding adjectives, no cheerleading.

---

## 1. Title + overview table (top of file, always kept up to date)

```markdown
# Code review: `<branch-name>`

Base: `<commit-hash>` (<description, e.g. HEAD~1 / Merged PR NNN>) · Reviewed by: Claude Code

| Round | Commit | Date | Outcome |
| --- | --- | --- | --- |
| 1 | `<hash>` <short commit description> | YYYY-MM-DD | <summary: finding counts by severity> |
| 2 | `<hash>` <description> | YYYY-MM-DD | <summary: closed/open status, new findings> |
```

> (if needed) Note about the base actually used for the diff, if main/develop has
> drifted too far.

- Every new round adds one row to this table — never edit an existing row.
- Keep the "Outcome" column terse: counts by severity, what closed, what's still
  open, whether there are new findings.

---

## 2. Structure of each "Round" (newest always at the TOP, right below the overview table)

```markdown
# Round N — review `<commit-hash>`  (or "independent verification of round N-1", "uncommitted working tree")

## Status of round N-1 findings

| # | Finding | Status |
| --- | --- | --- |
| 1 | <short description> | ✅ **Closed** — <brief verification method> |
| 2 | <short description> | ⚠️ **Still open** / **Half-closed** — <reason> |

### Finding 1 — why closed / not closed, in detail

<Explain how it was fixed, quote the relevant code (path:line), then MEASURE FOR
REAL with an input/output table or the commands you ran. When comparing behavior
before/after, use a two-column "Before | After" table.>

## New findings

### N<k> [<Severity>] <short title describing the actual consequence>

<Describe the issue, quote code (path:line), then show measured evidence (command,
input/output, log). State the concrete impact — who is affected, when it happens.
Give a specific fix proposal (small diff if applicable). Note any mitigating
factor if one exists.>

## Round N verification

| Item | Round N-1 | Round N |
| --- | --- | --- |
| Relevant test suite | <x pass/y fail> | <x pass/y fail> |
| `tsc --noEmit` / typecheck | <n errors, pre-existing or not> | ... |
| ESLint (changed files) | clean/not | ... |
| <domain-specific item: perf, security, migration...> | ... | ... |
```

- If this round is an **independent verification** (no new code, just re-checking
  the previous round's claims — e.g. written by a different session/person): use
  a "Round X claimed | I verified with | Result" table instead of the usual status
  table, to make clear this is a double-check.

```markdown
| Round X claimed | I verified with | Result |
| --- | --- | --- |
| <claim 1> | <command / method> | ✔ / ✘ |
```

---

## 3. Round 1 content (the first round, most detailed — kept as the record)

```markdown
# Round 1 — review `<commit-hash>`

Kept as the record. See the latest round's table for current status of each finding.

## Scope

<N> files, +<added> / −<removed>:

| File | Change |
| --- | --- |
| `path/to/file.ts` | +X/−Y — <short description of what changed> |

## Parts verified as correct

### <Name of design decision / mechanism 1>

<Explanation + measured evidence (real input/output, not inference). State clearly
why this choice is correct, compare with alternatives if relevant.>

### <Mechanism 2>
...

## Round 1 findings

### 1 [<Severity>] <title>

<path:line> — <code excerpt>. <Explain the mechanism of the bug>. Reproduced:

```
<input>
<actual output>
```

Impact: <who is affected, when>.

**Fix**: <specific proposal, small diff if applicable>.

### 2 [<Severity>] ...

## Round 1 verification

| Item | Result |
| --- | --- |
| Relevant test suite (<n files>) | <x pass / y fail> |
| `tsc --noEmit` | <result, note if pre-existing> |
| ESLint (changed files) | clean/not |
| <domain-specific check> | ... |

## Out-of-scope notes

<Issues visible but NOT caused by this branch — list clearly, with evidence (e.g.
re-run against base to confirm), so they aren't wrongly attributed to this branch.>
```

---

## 4. Conclusion (updated every round, always at the end of the "review by round" section, before "Commands run")

```markdown
# Conclusion

<1 paragraph: does the branch do what it claims, at the right layer?>

<List the important design decisions that hold up under scrutiny — 2-4 bullets,
each with one sentence on why it's correct.>

<If multiple rounds: summarize how the author handled findings across rounds — how
many closed, whether they did better than the suggested fix anywhere, whether they
surfaced consequences the review hadn't identified.>

After <N> rounds: <total> findings, <n> closed, <n> still open (list briefly, with
reason if intentionally left open). **<Still/No longer> any <highest severity>.
<Blocks/Does not block> merge.**

<If applicable: notable process observations — e.g. commit messages stating the
actual root cause, new tests locking the exact spot that just broke rather than
just the spot that was fixed, negative controls used...>

## Commands run to verify

### Round 1

\```
<command 1>                                                  # short result / why run
<command 2>                                                  # ...
\```

### Round 2
\```
...
\```
```

---

## 5. Checklist when starting a review on a new branch

1. Determine the real base (`git merge-base`, or check whether `main`/`develop`
   has drifted abnormally).
2. `git log --oneline`, `git show --numstat` to get the scope (files, +/−).
3. Read the diff by logical area (domain/pure, server actions/mutating, UI,
   migration, tests) — not sequentially file by file.
4. For each important mechanism/design decision: build your own input, run it for
   real (existing unit test, REPL, small script, or calling the function/RPC
   directly on a test DB/transaction rollback), compare the output — don't just
   read the code and trust it.
5. Run the full check: relevant test suite, typecheck, lint. Classify failures:
   caused by this branch or pre-existing (confirm by re-running against the base).
6. For each finding: severity, code citation (path:line), measured evidence,
   impact, concrete fix proposal.
7. Write a "Checked and sound" section for parts thoroughly verified and found
   clean — don't just list findings, also record what's done right so the review
   is balanced.
8. Write a Priority table at the end of round 1 (severity, category, estimated
   fix cost) if there are more than 1-2 findings.
9. When the branch gets a new commit in response to the review: do NOT trust the
   commit message — verify each finding by reproducing the exact case that was
   originally reported as broken.
10. Use negative controls when possible: deliberately break the thing that was
    just fixed (or the new test) to confirm it actually catches the bug — a
    vacuous pass is a common risk, especially with mocks or `for...of` over an
    array that could be empty.
11. Update the overview table at the top of the file, add the new "Round N"
    section at the top, update the "Conclusion" at the end.
