# Contribution workflow

How a change goes from an idea to `main` in this repository.

## 1. Start from an up-to-date `main`

```bash
git checkout main
git pull
git checkout -b <type>/<short-name>      # e.g. feat/plan-vs-actual, fix/squad-category-authorization
```

`git fetch` updates your view of every remote branch without changing your working tree;
`git pull` brings the current branch up to date.

One branch does one thing. A branch that grows a second concern should be split, or the second
concern recorded in `docs/feature-roadmap.md` for later.

## 2. Pick the work

Take the item from `docs/feature-roadmap.md`. Each entry carries enough context to start without
re-deriving it, and the "Suggested order" section says what comes next.

## 3. Definition of done

A change is done when all of these hold, and the evidence is in the PR:

- **Tests are part of the change.** New handlers, repositories and widgets get tests in the same
  step; changed code gets its tests updated in the same step.
- **The checks pass:** `dotnet build`, `dotnet test`, `flutter analyze`, `flutter test`. If an
  annotated Riverpod provider or a freezed model changed, run
  `dart run build_runner build --delete-conflicting-outputs` too — CI fails on stale generated code
  even when everything else passes.
- **It has been run for real.** Try the UI change on a device or emulator. Exercise a server change
  against a running backend. Run the E2E suite (`integration_test/`) for frontend work.
- **Tests fail without the fix.** Break the fix on purpose (a *negative control*) and confirm a test
  goes red. A test that passes both before and after proves nothing.

## 4. Review

Every branch is reviewed in rounds, following `docs/review-code-convention/CODE_REVIEW_TEMPLATE_EN.md`.
The report goes in `docs/review-code-reports/review-<branch>.md`. Each round verifies the previous
round's claims itself instead of trusting them, fixes are committed, and the next round reviews those
fixes. A branch is ready when a round finds nothing blocking.

## 5. Pull request and merge

- Push the branch and open a PR against `main` (the `gh-pr-create` skill fills in the template, the
  labels and the evidence).
- CI must be green. If a conflict appears, resolve it on the branch; if it cannot be resolved safely,
  say so in the PR rather than forcing it.
- After the merge:
  ```bash
  git checkout main
  git pull
  ```
- A branch stacked on an unmerged one is rebased onto `main` once its parent has merged, and its
  checks are run again before it is pushed.

## 6. Keep the documentation true

When behaviour changes, update the documents that describe it in the same branch: `CLAUDE.md` for
conventions and architecture, `docs/feature-roadmap.md` for status, and the relevant design document
in `docs/`. `docs/README.md` indexes them and says which ones are current.
