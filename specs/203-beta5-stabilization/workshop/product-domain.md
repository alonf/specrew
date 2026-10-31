# Product Domain: 203 Beta5 Stabilization

**Depth**: Standard. A later feature in a known product, but it changes the approval-authority path,
spans three hosts, and its scope was the main decision. Not Deep: no new product or user segment.
**Confirmation**: human-confirmed (lens-question), typed "confirm" on Claude, 2026-10-30, receipt
`6f4065f86f53f5fd0329c0037c6932ff0e94b0566f2002d5e3a8912ad7d4d19c`.
**Context scope**: feature_standalone.

## Who

- The maintainer, the human in the dogfood walks. `known`
- Beta users on Claude Code, Copilot CLI and Codex; number and host mix unknown. `assumed`
- The harmed human: a typed approval that is lost (re-typing, blocked work), or an approval recorded
  that was never given. `known`

## What hurts

All `known`, observed on the 202 walks.

1. Approvals are lost, misreported, or outnumber the decisions they stand for: B4F-112, B4F-116,
   B4F-117, B4F-140, B4F-151; B4F-061 measured six typed authorizations for one boundary.
2. Stops block when no decision is needed: B4F-121, B5F-012, B5F-004, B5F-011.
3. CI hides failures until merge or publish: B5F-013, B5F-015, B4F-079, B4F-119, B4F-158.

Current workaround: the maintainer re-types approvals, answers the `use it` interim check, uses
partial sign-off and runs protection windows with `!`; CI gaps are fixed by follow-up pull requests
after the release dry run.

## Maintainer direction: the review budget

Per-round review approvals go. The plan states a review budget in rounds plus a reviewer host order,
and approving `before-implement` approves it. Within the budget the cycle runs without asking: a clean
result ends the review; a fix-needed result means fix, then the next round. The human is stopped only
when:

- (a) the budget is spent; the top-up is `approved for allowance reset`, which also starts the next
  round;
- (b) the crew wants to dispute or defer a finding;
- (c) a finding needs the human's judgment, such as a scope change;
- (d) the next reviewer host is outside the plan's approved order.

The per-round approval guarded against runaway cycles and tokens; the budget and the fix decision now
do that job. Token usage is captured for display only: the usage slot in
`scripts/internal/continuous-co-review/review-progress-projection.ps1` is filled by no reviewer adapter
today. `known`

### What the budget model removes

| Item | Result |
| --- | --- |
| B4F-115 planned checkpoint stops for approval already given | Removed |
| B4F-121 stop check asks for a round approval while a round runs | Removed as a stop; takes B5F-012 with it |
| B4F-116 / B4F-150 round approval reported "not recorded" | Mostly removed; the `approved for review...` prefix residue remains |
| B4F-117 typed reply blamed on a picker | Shrinks; the latest-turn-only capture survives on the budget capture |
| B4F-140 / B4F-137 re-typed approval folded into an older unspent one | Survives on the top-up |
| B4F-061 six authorizations per boundary | Target: the sign-off verdict plus one per top-up |
| B4F-126 / B4F-152 pause offers a stop it cannot complete | Removed with the pause |
| B4F-054 fixes re-arm the review | Survives, reduced: decides whether a test-only fix needs a round |
| B4F-058 sign-off records invalidate coverage | Survives on the budget-spent acceptance path |

These are `assumed` until built and walked.

## Constraints

- The typed reply stays the only way to approve. `known`
- Fixes hold on all three validated hosts; Copilot also runs the Claude hooks. `known`
- Release is beta-stable on the PowerShell Gallery: prerelease, human validation, stable. `known`
- No commit between an approval and the step that consumes it. `known`
- Schedule and target date. `unknown`

## Success measures

`assumed` until the live walk measures them.

- (a) Every typed approval is recorded the first time it is typed.
- (b) No approval is recorded that the human did not type.
- (c) No false "not recorded" reports.
- (d) A review stops the human only for budget spent, a dispute or deferral, a judgment call, or a
  reviewer host outside the approved order.
- (e) Every test the publish census can fail on also runs in a PR lane.
- (f) On the three-host walk, a review costs at most the sign-off verdict plus one approval per top-up
  (baseline: six per boundary).

## MVP: feature 203

- **A. Review budget model.** Absorbs B4F-115, B4F-121, B4F-061, B4F-126, B4F-152, B5F-012 and the
  residues of B4F-116/150, B4F-117, B4F-140/137, B4F-058, B4F-054. Token capture, display only.
- **B. Approval capture correctness.** B4F-112 (a verdict after a compaction is not captured), B4F-151
  (an unreadable approval form refuses silently), and the capture residues from A.
- **C. Stops that carry no decision.** B5F-004 (audit the remaining stop reasons), B5F-011 (every
  waiting turn ends with what to type).
- **D. Lifecycle.** B5F-014 (a merged feature's claim is never released; on branch
  `docs/beta5-b5f-014`, PR #3715).
- **Rider: CI.** B5F-013, B5F-015, B4F-079, B4F-119, B4F-158, B4F-142.

## Non-goals

- Init and bootstrap, B5F-006 to B5F-010: candidate feature 204.
- B5F-001, B5F-002, B5F-003, B5F-005.
- B4F-125, dropped by the maintainer.
- The remaining beta4 items marked beta5 (dashboards, host tiers, Ctrl+O and others).

## Alternative rejected

Keep per-round approvals, merge the phrases (B4F-061 option 2) and fix the capture bugs one by one.
Cheaper, but it keeps one authorization per round and treats the classes symptom by symptom.

## Rollout

A beta-stable prerelease validated by a live walk on Claude, Copilot and Codex measuring (a) to (f),
then stable. `assumed`

## Follow-up research

- Whether the Copilot reviewer reports token usage, and how the Codex file delivery carries it.
  `research-needed`, not load-bearing.
