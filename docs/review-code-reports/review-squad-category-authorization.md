# Code review: `fix/squad-category-authorization`

Base: `407e705` (`main`, merge of PR #28) · Reviewed by: Claude Code

| Round | Commit | Date | Outcome |
| --- | --- | --- | --- |
| 1 | `99d7145` fix(security): stop signed-in users reading and changing other people's categories | 2026-09-13 | 0 HIGH, 1 MEDIUM (pre-existing), 1 LOW, 1 INFO — the fix itself is correct; the MEDIUM is a second path to the same data |
| 2 | uncommitted working tree (fixes for round 1) | 2026-09-13 | All 3 closed — the MEDIUM on both its write and read side, verified live including revocation; the LOW with a scope check; the INFO by routing five commands through `SquadAccess`. One out-of-scope note closed too. No new findings. **Nothing blocking.** |
| 3 | `5675ead` fix(security): close the second door to categories (round 2, committed) | 2026-09-13 | Round 2's closures hold on 29 live checks and 11 mutations. 4 new: 1 MEDIUM (pre-existing — the SignalR hub checks no membership), 2 LOW (the keep-exemption leaks through "all occurrences"; 3 surviving mutations), 1 INFO — **MEDIUM blocks merge** |
| 4 | uncommitted working tree (fixes for round 3) | 2026-09-13 | All 4 closed; N1 verified live on the reviewer's own probe, every survivor now caught, the hub covered by 7 tests. No new findings. **Nothing blocking.** |

> `main` = `origin/main` = `git merge-base HEAD main` = `407e705`, and `git log main..HEAD` is
> exactly one commit. The three-dot diff is the branch's real scope: 20 files, +597 / −64,
> server and docs only.

---

# Round 4 — uncommitted working tree (fixes for round 3)

## Status of round 3 findings

| # | Finding | Status |
| --- | --- | --- |
| N3 | [MEDIUM — pre-existing] The SignalR hub checks no squad membership | ✅ **Closed** — every hub method requires approved membership; 7 tests |
| N1 | [LOW — introduced in round 2] Keeping a day's category spreads it onto the series | ✅ **Closed** — measured against the row that is overwritten; verified live |
| N2 | [LOW] Three mutations survived the suite | ✅ **Closed** — each now caught; the fourth (SQL) documented as untestable without Postgres |
| N4 | [INFO] The client shows a raw exception on the new 403 | ⚠️ Open by choice — see below |

### N3 — closed: the hub is a squad boundary now

`SocialHub` had `[Authorize]` and nothing more. `JoinSquadGroup(squadId)` added any caller to
`Squad_{squadId}`, and `SendMessage`, `SendPoke` and `SendReaction` saved and broadcast into any squad.
So a signed-in user holding a squad id could read that squad's live chat and post into it. The REST
chat-history endpoint already checked membership; the hub, which carries the same messages, did not.

Every hub method now starts with `RequireMembershipAsync`: the caller must be an approved member
(`SquadAccess.CanRead`), otherwise `HubException`. Nothing is saved and nothing is broadcast. Pokes and
reactions also require the *target* to be an approved member, since the message names them to the
whole squad. "No such squad", an unparseable id and "not yours" all get the same message. The group
name is built from the parsed Guid (`SocialHub.GroupName`), so one squad cannot become two groups by
letter case.

Measured with the real hub class and mocked `HubCallerContext`, `IGroupManager` and `IHubCallerClients`
(`SquadAuthorizationSurfaceTests`): an outsider and a pending member cannot join; an outsider cannot
post; a poke or reaction with a non-member on either end is refused. **Not verified over a live
WebSocket connection** — there is no SignalR client in the probe tooling. The Flutter client only
joins and posts to squads the user is in, so members see no change.

### N1 — closed: "keeping" is measured against the row that is overwritten

`UpdateEventCommand` compared `request.CategoryId` with the category of the event being edited. For a
split-off day edited with "all occurrences" or "this and future", that is the wrong row: the edit
writes the category onto the **series**, and `FollowSeriesAsync` then writes it onto every local-only
day. `CategoryBeingReplacedAsync` now returns the parent series' category in that case.

Verified live by re-running round 3's own probe against a fresh clone:

| Removed member, keeping a squad category that one day still has | Round 3 (`5675ead`) | Round 4 |
| --- | --- | --- |
| edit that day with "all occurrences" | 200 | **404** |
| the series' category afterwards | the squad's | **unchanged** |
| a local-only day's category afterwards | the squad's | **unchanged** |
| "this and future" keeping it | 200, 2 new series rows on the squad's category | **404, 0** |
| the probe's other checks | 29 / 29 | **29 / 29** |

The exemption itself is kept and still tested: an edit of just that day keeps what the day has.

### N2 — closed: the survivors are caught

| Round 3's surviving mutation | Round 4 |
| --- | --- |
| M2: the category check skipped for split-off days | **caught** (2 tests) |
| M3: `Events.CreateEvent` null → 403 mapping removed | **caught** (3 tests) |
| M11: `Habits.CreateHabit` null → 403 mapping removed | **caught** (3 tests) |
| M1: the plan-vs-actual SQL visibility filter removed | still survives — raw SQL has no automated test in this project (parent reviews' MEDIUM 5). Covered by the live probes only |

The endpoint tests call the real endpoint methods with a mocked `ISender`, so they also pin the happy
path (201 with the id) and the category endpoints' 403s.

### N4 — open by choice

On a 403, `create_event_sheet.dart` shows its existing destructive toast with the raw exception text
(`failed_to_create_event: DioException … 403`), under a title using the known-missing `'error'` key
(parent review `review-home-page.md` LOW 11). It does not crash. In normal use the picker offers only
categories the user may use, so this appears only for a member removed while the sheet is open. A
friendly message belongs with the pre-existing toast-key cleanup, not in a security PR.

## Round 4 verification

| Item | Round 3 | Round 4 |
| --- | --- | --- |
| `dotnet build` | 0 errors | 0 errors |
| `dotnet test` | 182 pass | **196 pass / 0 fail** (+14) |
| Negative controls | 11 mutations, 3 survived | **6 more** — N1, the hub's two checks, and the three survivors — all caught, none a build error |
| Live, round 3's probe | 29 / 29, with N1 leaking | **29 / 29, N1 refused** |
| Server log during the run | — | 0 `fail:` lines |
| `flutter test` | not run | not run — no client file changed |

---

# Round 3 — review `5675ead`, independent verification of round 2

A single reviewer was run for this round and **was cut off by a session limit before writing it up**.
Its probe and mutation logs survived and are the evidence below. The consolidating pass read them,
checked the parts that mattered against the code, and added the one finding the reviewer had not
reached: the hub.

## Verifying round 2's claims

| Round 2 claimed | Verified with | Result |
| --- | --- | --- |
| Event and habit writes refuse a category the caller may not use | live: outsider creates an event on a squad category, on a member's personal category, on a nonexistent id; creates a habit on a personal category | ✔ 403 each; the 403 is not a cookie redirect (no `Location` header) |
| An update onto a foreign category is refused, row unchanged | live: outsider moves own event onto a member's category / a nonexistent one | ✔ 404, `CategoryId` unchanged |
| A leader cannot replace a squad category with a personal one | live | ✔ 404, the squad category still exists |
| Revocation revokes | live: member uses the squad category, completes a session, leaves; leader renames | ✔ listed while a member; hidden after; rename not visible; totals unchanged; `GET ?squadId` → 403 |
| A removed member can still edit their own old event | live | ✔ 200 |
| The unit tests catch each rule | 11 mutations over a `git archive` copy | ✔ 7 caught — ✘ **4 survived** (N2) |
| `dotnet test` → 182 | reviewer's run | ✔ 182 pass |

## New findings

### N3 [MEDIUM — pre-existing] The SignalR hub checks no squad membership

`SocialHub.cs` (at `5675ead`): `JoinSquadGroup` calls `Groups.AddToGroupAsync(Context.ConnectionId,
$"Squad_{squadId}")` with the client's string and no check. `SendMessage`, `SendPoke` and
`SendReaction` save a `SquadChatMessage` and broadcast to `Squad_{squadId}` for any caller. By reading:
any signed-in user who knows a squad id can receive its live chat and post into it as themselves.
`GetChatHistoryQuery` already checks `GetMembershipAsync`, so the REST read path was closed and the
real-time path was not. Found while documenting this branch's rule, not by the reviewer. **Fix:**
require approved membership in every hub method, and an approved target for pokes and reactions.

### N1 [LOW — introduced in round 2] Keeping a day's category spreads it onto the whole series

Measured live by the reviewer: a member removed from a squad, whose split-off day still carried the
squad's category, edited that day with "all occurrences" and re-sent the category → **200**. The
series and a local-only day then carried the squad's category ("rows of this member on SC: 4"), and a
"this and future" edit created two new series rows with it. `CanAssignAsync` compared against the
day's category, but the edit writes onto the series. Impact is bounded — the caller's own rows, and
the read-side filter hides the name — but it breaks round 2's own invariant that a category cannot be
newly attached. **Fix:** measure "keeping" against the row being overwritten.

### N2 [LOW] Three authorization paths had no test that fails without them

| Mutation | Result at `5675ead` |
| --- | --- |
| M1: plan-vs-actual SQL visibility filter removed | 182 pass |
| M2: `UpdateEventCommand` category check skipped for split-off days | 182 pass |
| M3: `Events.CreateEvent` null → 403 mapping removed | 182 pass |
| M11: `Habits.CreateHabit` null → 403 mapping removed | 182 pass |

M3 and M11 mean a handler could refuse and the endpoint would still answer 201. **Fix:** endpoint-level
tests, and a test that edits a split-off day. M1 needs a real Postgres.

### N4 [INFO] The client's reaction to the new 403 is a raw exception toast

By reading `create_event_sheet.dart:398-406`. No crash; see round 4.

## Round 3 verification

| Item | Result |
| --- | --- |
| `dotnet test` | 182 pass / 0 fail |
| Live probe (throwaway clone `rv3`, Google tokens nulled) | 29 / 29 as expected, with N1 recorded as observed behaviour |
| Mutations (copy of the tree, not the repo) | 11 run, 7 caught, 4 survived, 0 build errors |
| Cleanup | the reviewer was cut off before cleanup; the consolidating pass dropped `rv3` and confirmed no server on :5105 |

---

# Round 2 — uncommitted working tree (fixes for round 1)

Round 1's three findings, fixed on top of `99d7145`. Round 1 said finding 1 "does not argue
for holding the branch — it argues against calling 5.5 done", and offered two options: mark
5.5 🟡, or close the second path in the same PR. This round takes the second, because the
first would have shipped a security fix whose own title was still true.

## Status of round 1 findings

| # | Finding | Status |
| --- | --- | --- |
| 1 | [MEDIUM — pre-existing] Categories reachable through events and habits | ✅ **Closed** — both halves: writes validate `CategoryId`, and the one read-back query filters by visibility in SQL. Live 10/10 including revocation |
| 2 | [LOW] A replacement is checked for readability, not scope | ✅ **Closed** — `EventCategoryAccess.CanReplaceAsync` requires the same scope |
| 3 | [INFO] Five squad commands inline the check `SquadAccess.CanManage` centralises | ✅ **Closed** — all five call it |
| — | Out-of-scope note: `GetCategories` returns `Task<IResult>` | ✅ **Closed** — typed `Results<Ok<…>, ForbidHttpResult, UnauthorizedHttpResult>` |

### Finding 1 — closed on both sides

Round 1 was specific that the write side alone would not close the revocation case, so both
were done.

**Writes.** `EventCategoryAccess.CanAssignAsync(categoryId, currentCategoryId, userId, …)` is
called by all four commands that store a category: `CreateEvent` and `CreateHabit` (refusal →
null → **403**), `UpdateEvent` and `UpdateHabit` (refusal → false → **404**). `UpdateEvent`
writes `request.CategoryId` in three places (the day, the whole series, a new series); it is
checked once, at the top of `Handle`, so no path can skip it.

One decision round 1 did not have to make: **keeping the category a row already has is always
allowed.** A member who leaves a squad still owns their old events, and the client re-sends the
event's category on every edit — refusing that would have locked them out of their own data. What
they lose is *seeing* the category, which is the read side's job. Pinned by
`KeepingTheCategoryARowAlreadyHas_IsAllowed_EvenWhenItIsNoLongerVisible`, and its negative control
fails.

**Read-back.** `GetPlanVsActualByCategoryAsync` now joins only categories the caller may still see:

```sql
AND (
    (c."SquadId" IS NULL AND c."UserId" = {userId})
    OR EXISTS (SELECT 1 FROM "SquadMembers" m
               WHERE m."SquadId" = c."SquadId" AND m."UserId" = {userId} AND m."IsApproved")
)
```

Filtered sessions are not lost: they fall into the client's existing "No category" remainder row
(`review-plan-vs-actual.md` finding 5), because the totals query does not join categories. Round 1
confirmed this was the only server query that reads a category name back through an event; I
re-checked by grep (`"EventCategories"` in `Infrastructure/Repositories`) and it still is.

Measured live on a throwaway clone, two accounts:

| Case | Before (round 1's probes) | After |
| --- | --- | --- |
| create an event on the victim's category | accepted and persisted | **403** |
| create a habit on the victim's category | accepted and persisted | **403** |
| move an own event onto the victim's category | — | **404**, `CategoryId` unchanged |
| a pre-fix row pointing at the victim's category: does the name come back? | yes, through the card | **no** — only the caller's own category is listed; the session still counts in the totals |
| approved member uses the squad's category | — | 201, and it is shown |
| same member removed; leader renames the category | old and new names still shown | **neither shown** |
| the removed member edits their own old event | — | **200** — not locked out |

The pre-fix row was written directly in SQL, which is the honest way to test "rows written before
the fix": the API can no longer create one.

### Finding 2 — closed

`CanReplaceAsync(deleted, replacement, …)` requires the same scope — the same squad, or the same
owner's personal categories — and readability on top. Round 1's snippet, as proposed, including
refusing personal → squad; round 1 called loosening that half a product decision, and nothing
here asks for it.

| Leader deletes a squad category, replacement is… | Round 1 | Round 2 |
| --- | --- | --- |
| the leader's own personal category | allowed, every member's rows moved | **refused, nothing moved or deleted** |
| a category of another squad the leader also leads | allowed | **refused** |
| another category of the same squad | allowed | allowed |

The handler-level test checks the whole outcome, not just the rule: `ReassignCategoryAsync` and
`DeleteAsync` are never called.

### Finding 3 — closed

`ApproveMember`, `ChangeLeader`, `DeleteSquad`, `RejectMember` and `UpdateSquadSettings` all read
`!SquadAccess.CanManage(callerMembership)`. The replaced expression was identical in behaviour, and
the 182 tests pass unchanged on those commands.

## A test-suite note

Adding the write-side check broke three existing habit tests, correctly: they passed a random
`CategoryId` and expected it to be saved, which is the exact thing that is now refused. They were
not rewritten to expect refusal — their subject is "the fields get saved" — so the successful one
now names a category the caller owns, and the two that refuse earlier (not found, not owner) get
plain mocks, since they return before a category is looked at. Refusal is covered in
`CategoryAssignmentTests`. My first pass pasted the owned-category setup into all three, which did
not compile in the two refusal tests; caught by the build, fixed before any test ran.

## Round 2 verification

| Item | Round 1 | Round 2 |
| --- | --- | --- |
| `dotnet build` | 0 errors | **0 errors** |
| `dotnet test` | 169 pass / 0 fail | **182 pass / 0 fail** (+13, `CategoryAssignmentTests`) |
| Negative controls | 6, all caught | **+5**, all caught, each confirmed to compile |
| Live, round 2's cases | not measured | **10 / 10** on a throwaway clone |
| Live, round 1's probe re-run on this build | 13 / 13 | **13 / 13** — no regression |
| Server log during the live runs | — | 0 `fail:` lines |
| Other server queries joining category names | 1 (plan-vs-actual) | 1, now filtered |
| `flutter test` | not run | not run — no client file changed; approved members get the same responses |

---

# Round 1 — review `99d7145`

## Scope

| File | Change |
| --- | --- |
| `server/src/Application/Common/SquadAccess.cs` | +44 — new. `CanRead` / `CanContribute` / `CanManage` from a membership row |
| `server/src/Application/Common/EventCategoryAccess.cs` | +53 — new. Rights from the stored category row: squad → membership, personal → owner |
| `…/EventCategories/Queries/GetEventCategoriesQuery.cs` | membership check before returning a squad's categories; null → 403 |
| `…/EventCategories/Commands/CreateEventCategoryCommand.cs` | `CallerUserId`; membership check for a squad category |
| `…/EventCategories/Commands/UpdateEventCategoryCommand.cs` | the `&&` check replaced by `EventCategoryAccess.CanManageAsync`; request squad id dropped |
| `…/EventCategories/Commands/DeleteEventCategoryCommand.cs` | same, plus the replacement must be readable by the caller |
| `server/src/Web/Endpoints/V1/EventCategoriesEndpoint.cs` | stamps `CallerUserId`, forces `UserId` null for a squad create, stops forwarding body/query squad ids |
| `server/src/Domain/Entities/SquadMember.cs` + 7 squad commands + `SquadRepository.cs` | `LeaderRole` / `MemberRole` replace 11 string literals |
| `tests/…/EventCategoryAuthorizationTests.cs` | +286 — 15 authorization tests |
| `CLAUDE.md`, `docs/feature-roadmap.md` | the rule written down; roadmap 5.5 marked 🟢 done |

## Parts verified as correct

### Rights are decided from the stored row, and the old bypass is gone

`EventCategoryAccess.IsEntitledAsync` (`EventCategoryAccess.cs:35-51`) reads `category.SquadId`
from the row: a squad category is decided by the caller's membership of *that* squad, a
personal one by `category.UserId == userId`. The request can no longer say which kind of
category it is — `UpdateEventCategoryRequest.SquadId` is still accepted for client
compatibility but never forwarded (`EventCategoriesEndpoint.cs:65-73`), and delete takes no
squad id at all. The null-equals-null hole (`category.UserId != request.UserId &&
category.SquadId != request.SquadId`) cannot recur because neither side of it exists any more.

### Membership means approved membership, in one place

`SquadAccess.CanRead` is `membership != null && membership.IsApproved`, and `CanManage` adds the
leader role on top of it rather than replacing it — so a *pending* request with the leader role
(not a state the app creates, but a state a row can be in) still gets nothing.
`APendingJoinRequestIsNotMembership` covers it.

### The status codes do not become an existence oracle

GET and POST return 403 when the caller is not an approved member — and a squad that does not
exist yields a null membership and the same 403, so the answer does not distinguish "no such
squad" from "not yours". PUT and DELETE return 404 both for a missing category and for one the
caller may not manage. Consistent within each verb pair, and neither leaks existence.

### Create cannot be pointed at someone else

The endpoint stamps `CallerUserId` from the token and sets `UserId = SquadId == null ? userId :
null` (`EventCategoriesEndpoint.cs:48-52`); the handler also refuses a personal create whose
`UserId` differs from the caller (`CreateEventCategoryCommand.cs:65-70`). Belt and braces, and
the second half means the handler is safe even if a future endpoint forgets the first.

### The role-literal change is behaviour-identical

Every hunk in the seven squad commands, `SquadRepository.cs` and `SquadMember.cs` is a
`"Leader"`/`"Member"` literal swapped for `SquadMember.LeaderRole`/`MemberRole` plus a `using`;
no condition changed shape. `grep -rn '"Leader"\|"Member"' server/src --include=*.cs` now returns
only the two constant definitions.

## Round 1 findings

### 1 [MEDIUM — pre-existing] Categories are still reachable through events and habits, whose `CategoryId` is never checked

The branch closes all four category endpoints. But a category's id is also written by four
other commands, and none of them checks it:

```
CreateEventCommand.cs:69     CategoryId = request.CategoryId,
UpdateEventCommand.cs:311    existingEvent.CategoryId = request.CategoryId;   (and :257, :432)
CreateHabitCommand.cs:34     CategoryId = request.CategoryId,
UpdateHabitCommand.cs:39     habit.CategoryId = request.CategoryId;
```

`CreateEventCommandHandler` and `CreateHabitCommandHandler` do not even take an
`IEventCategoryRepository` or `ISquadRepository`, so they cannot. Measured with the handlers
themselves (temporary mock-only probe, since deleted):

```
PROBE CreateEvent by 'attacker' with victim's CategoryId -> id=created savedCategoryId==victim's=True savedUserId=attacker
PROBE CreateHabit by 'attacker' with victim's CategoryId -> savedCategoryId==victim's=True
```

And there is a read-back path. `GetPlanVsActualByCategoryAsync`
(`EventRepository.cs:64-84`) filters on the *event's* owner only and joins the category
unconditionally:

```sql
JOIN "EventCategories" c ON c."Id" = e."CategoryId"
WHERE e."UserId" = {userId} …
SELECT c."Name" AS "GroupName" …
```

So the boundary this branch builds can be walked around:

- **A removed squad member keeps it with no effort.** Their existing events already point at the
  squad's categories. After removal, `GET /event-categories?squadId=…` correctly answers 403 —
  and `GET /analytics/plan-vs-actual` keeps returning those categories' names, including any
  rename the leader makes afterwards. Revocation does not revoke.
- **Anyone who knows a category id** can attach a finished event to it and read its name back the
  same way. GUIDs are not guessable, but this branch's own table records that until now every
  squad's category ids were listable by any signed-in caller, so "known" is not a hypothetical.
- **It chains.** `ReassignCategoryAsync` moves every event and habit with the old id regardless
  of owner (`EventCategoryRepository.cs:63-72`). If the victim later deletes that category with a
  replacement, the attacker's own event is moved too — and events return their `categoryId` to
  their owner, so the attacker learns the replacement's id, and its name through the card.

Scope of the leak is the category name (and presence of the row), not events or habits. Writes
are limited to attaching one's own rows to someone else's category.

Why it belongs in this review despite predating it: it is the remaining path to exactly the data
the branch is titled as protecting; it breaks the rule this commit adds to `CLAUDE.md` — *"Decide
a caller's rights from the stored row, never from an id the request carries"*; and
`feature-roadmap.md` now marks 5.5 🟢 **done**.

**Recommendation**: this does not argue for holding the branch — everything in it is a strict
improvement and should merge. It argues against calling 5.5 done. Either change the roadmap
entry to 🟡 with this path listed as the remaining half, or fix it in the same PR:

- in the four event/habit commands, when `CategoryId` is set, load the category and require
  `EventCategoryAccess.CanReadAsync` for the caller (reject, not silently null it — a client
  sending a bad id is a bug worth surfacing);
- give the category grouping in `GetPlanVsActualByCategoryAsync` the same condition in SQL — a
  personal category owned by the caller, or a squad category of a squad the caller is an
  approved member of — so rows written before the fix, and rows of removed members, stop
  leaking without a data migration.

The second bullet is the one that closes the revocation case; the first alone would not.

### 2 [LOW — introduced here] A replacement is checked for readability, not scope, so a leader can move the squad's rows onto a private category

The new replacement check (`DeleteEventCategoryCommand.cs:120-131`) asks whether the caller may
*read* the replacement. For a squad category, a leader can read their own personal categories,
so this is allowed:

```
PROBE leader deletes SQUAD category with replacement = own PERSONAL category -> allowed=True reassigned squad->personal=True
```

`ReassignCategoryAsync` then moves **every member's** events and habits in that category onto
the leader's personal one. Afterwards those members' rows point at a category that
`GET /event-categories` will never list for them, whose name they still see through the
plan-vs-actual card (finding 1's read path), and the leader's private category now carries
other people's data.

The test suite states the intended rule and does not enforce it:
`ALeaderMayReplaceWithAnotherCategoryOfTheSameSquad` covers squad → same squad; nothing covers
squad → personal or squad → another squad, which are both accepted today.

**Fix**: require the replacement to share the deleted category's scope, in addition to the read
check —

```csharp
var sameScope = category.SquadId.HasValue
    ? replacement.SquadId == category.SquadId
    : replacement.SquadId == null && replacement.UserId == category.UserId;
```

— plus two refusal tests (squad → leader's personal, squad → a different squad the leader also
leads). Moving a *personal* category's rows into a squad category the owner belongs to is a
product decision rather than a leak, and the snippet above refuses it too; loosen that half
deliberately if it is wanted.

### 3 [INFO] Five squad commands still inline the check `SquadAccess.CanManage` now centralises

`CLAUDE.md` gains *"Squad permissions go through `Application/Common/SquadAccess`"*, and this
commit edits the exact lines where five squad commands test for a leader —
`ApproveMember`, `ChangeLeader`, `DeleteSquad`, `RejectMember`, `UpdateSquadSettings`:

```csharp
if (callerMembership == null || callerMembership.Role != SquadMember.LeaderRole || !callerMembership.IsApproved)
```

That is `!SquadAccess.CanManage(callerMembership)` written out. Identical behaviour today, so
not a bug; but "one place, because the rule was written inline at every call site and was
wrong at several" (`SquadAccess.cs` remarks) is the argument for routing these through it too,
and the commit was already on those lines.

## Round 1 verification

| Item | Result |
| --- | --- |
| `dotnet build` | 0 errors (no `.csproj` in the diff; the NU1603 package warnings noted in the plan-vs-actual review are unrelated) |
| `dotnet test` | **169 pass / 0 fail** — matches the commit message (154 → 169) |
| Role literals left in `server/src` | **0** outside the two constant definitions |
| Squad-command hunks | literal → constant only, no condition changed |
| Event/habit create accepting another user's `CategoryId` | **accepted and persisted** — finding 1 |
| Category read-back through plan-vs-actual | SQL filters `e."UserId"` only, joins `c` unconditionally — finding 1 |
| Leader delete with personal replacement | **allowed, reassigns squad → personal** — finding 2 |
| `git status --porcelain` after probes | empty (probe file deleted) |

Not reproduced here: the commit's live 13/13 run against a running server. Everything above is
handler-level with mocks plus reading the SQL; findings 1 and 2 would each take two throwaway
accounts to confirm live, which I did not do against the shared dev database.

## Out-of-scope notes

- `GetCategories` still returns `Task<IResult>` rather than a `Results<…>` union, which
  `CLAUDE.md`'s endpoint convention asks for; the signature predates this branch.
- Plan-vs-actual's category grouping is where finding 1 surfaces, but the unconditional join is
  not a mistake in that feature on its own terms — it was written when categories had no
  enforced boundary to respect.

---

# Conclusion

The branch closes a real, measured hole — any signed-in user could read, rename and delete other
people's categories, personal ones included — and after round 2 it closes the second door to the
same data as well: attaching one's own rows to someone else's category, and reading its name back
through plan-vs-actual.

Design decisions that hold up:

- **Rights come from the stored row, never from an id in the request.** That rule is what the
  original bug broke, and it is written down in `CLAUDE.md` where the next endpoint author will
  find it.
- **One place for what membership allows** (`SquadAccess`), with approval checked as well as role,
  so a pending request is never membership.
- **Keeping an existing category is not a new grant.** It is what lets revocation work on the read
  side without locking a removed member out of their own events.
- **403 for the list and create verbs, 404 for update and delete**, so no response confirms that
  someone else's category exists.

After 4 rounds: 7 findings, 6 closed, 1 INFO open by choice (the client's raw-exception toast,
which belongs with the pre-existing toast-key cleanup). **No HIGH, no MEDIUM open. Does not block
merge.**

Rounds 3 and 4 added two things worth keeping. The hub finding came from writing the rule down: once
`CLAUDE.md` said "squad permissions go through `SquadAccess`", the question "does everything that
touches a squad?" had an obvious grep, and the real-time path failed it. And N1 is the case round 2's
own exemption created — found by a reviewer that tried to abuse the exemption rather than confirm it.

Round 1's finding 1 is the one worth remembering. The first commit fixed exactly what the roadmap
entry described, verified it live, and marked 5.5 done — while the same data stayed reachable by a
path the entry never mentioned. The review found it by asking where else a category id is written,
not by re-testing the endpoints that had been fixed.

## Commands run to verify

### Round 1

As recorded in that round's own write-up:

```
dotnet build ; dotnet test -o <dir>                           # 0 errors ; 169 pass
grep -rn '"Leader"\|"Member"' server/src --include=*.cs       # only the two constants
probe (mocks): CreateEvent/CreateHabit with a victim's CategoryId   # accepted - finding 1
read GetPlanVsActualByCategoryAsync SQL                       # no visibility filter - finding 1
probe (mocks): leader delete with a personal replacement      # allowed - finding 2
git status --porcelain                                        # empty (probe deleted)
```

### Round 2

```
grep -n "CategoryId = request.CategoryId" <event and habit commands>   # 6 writes, 4 commands
grep -rn '"EventCategories"' server/src/Infrastructure --include=*.cs  # 1 read-back query
psql \d "SquadMembers"                                        # SquadId, UserId, IsApproved
dotnet build tests/Application.UnitTests                      # 7 CS7036 - every construction site
dotnet test -o /tmp/authzr2t5                                 # 182 pass
python negative_controls_authz_r2.py                          # 5 mutations: 5,1,3,1,1 fail; none a build error
CREATE DATABASE "authz-check2" TEMPLATE "habit-tracker"       # 5433, Google tokens nulled
dotnet /tmp/authzweb3/Web.dll (:5099)
python authz_probe_r2.py                                      # 10/10, incl. a pre-fix row and revocation
python authz_probe.py                                         # round 1's 13/13 - no regression
grep -c "fail:" /tmp/authzweb3.log                            # 0
DROP DATABASE "authz-check2"
```

### Round 3

From the interrupted reviewer's surviving logs (`scratchpad/rv3/`):

```
dotnet test -o rv3/out                                        # 182 pass
python probe.py        (server on :5105, clone rv3)          # 29/29 as expected; N1 observed
python mutate.py       (git archive copy)                     # 11 mutations: 7 caught, 4 survived
```

### Round 4

```
dotnet test tests/Application.UnitTests -o /tmp/r3test         # 196 pass
python negative_controls_r3.py                                # 6 mutations, all caught, no build errors
CREATE DATABASE "rv3" TEMPLATE "habit-tracker" ; null tokens
dotnet /tmp/r3web/Web.dll (:5105) ; python rv3/probe.py       # 29/29; N1 edits now 404, 0 rows spread
grep -c "fail:" /tmp/r3web.log                                # 0
DROP DATABASE "rv3"
```
