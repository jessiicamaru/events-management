# Documentation

Start here. Each entry says what the document is for and whether it still describes the code.

## Current

| Document | What it is | Read it when |
| --- | --- | --- |
| [`feature-roadmap.md`](feature-roadmap.md) | The backlog: features and technical debt, each with enough grounding to pick up, plus a suggested order | Deciding what to build next |
| [`google-calendar-sync-architecture.md`](google-calendar-sync-architecture.md) | The outbox, the webhook and how events map to Google's | Before touching anything under `GoogleCalendar*` |
| [`stale-while-revalidate-sync.md`](stale-while-revalidate-sync.md) | Why reading events returns local rows first and refreshes behind the scenes | Before changing `GetEventsQuery` or the events provider |
| [`notifications-and-reminders.md`](notifications-and-reminders.md) | Local notifications: the planner, the Android permission matrix, how to test on an emulator | Working on reminders or the streak nudge |
| [`workflow.md`](workflow.md) | The branch-to-merge routine: definition of done, review rounds, PRs | Starting or finishing a piece of work |

## Code reviews

| Folder | What it is |
| --- | --- |
| [`review-code-convention/`](review-code-convention/) | The template every review follows: rounds, severities, measure-don't-infer, negative controls |
| [`review-code-reports/`](review-code-reports/) | One report per branch or audit, newest round at the top of each file. `review-main-codebase-audit.md` is the whole-codebase audit; the rest are per branch |

The reports are worth reading before starting in an area: they list what is known to be
wrong and deliberately not fixed yet, with the reasoning.

## Archive

[`archive/`](archive/) holds the original planning documents. They describe what was
intended in the beginning, not what exists now, and are kept because the reviews and the
roadmap refer back to them. See [`archive/README.md`](archive/README.md).

## Also worth knowing

- **`CLAUDE.md`** in the repository root is the working brief for the codebase: layout,
  commands, the architecture of both apps, and the conventions that are easy to break.
  It is the most current description of how the system fits together.
- **`local-dev/`** (gitignored) holds throwaway SQL for seeding demo data locally.
