# Archive

These documents describe what the project was planned to be. They are **not** a
description of the code as it stands, and several parts were never built or were built
differently. They are kept because the audit and the roadmap cite them, and because the
original intent is sometimes the missing context for why something looks the way it does.

| Document | What it was | What to know now |
| --- | --- | --- |
| `project-plan.md` | The original architecture blueprint: tech stack, entities, API surface | Sections that were never built are annotated in place (e.g. `isar`/`hive` offline storage — there is still no local database). See audit finding 10 in `../review-code-reports/review-main-codebase-audit.md` |
| `implementation-plan.md` | The phase-by-phase build order for backend and frontend | All phases it lists are long done; the current backlog is `../feature-roadmap.md` |
| `calendar-enhancement.md` | The plan to rebuild the calendar UI to match a Shadcn-style calendar | Largely carried out in the calendar feature; the command-centre panel it describes was removed when the Home screen arrived (PR #25) |

For how things actually work today, read `CLAUDE.md` in the repository root and the
current documents in `../`.
