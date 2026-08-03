# Iteration Plan: 011

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 18.5/20 story_points
**Started**: 2026-08-03
**Completed**:
**Planning Baseline**: `d7f27f6a`

> **This plan measured 21.5/20 — over cap by 1.5, which `overcommit_threshold: 1.0` forbids.**
> T091 (3.0 SP) was deferred at plan time to bring it to 18.5/20 with 1.5 SP of slack. That
> deferral is the planner's selection under `defer_strategy: manual`, it is **reversible at the
> plan verdict**, and its requirement impact is stated in `## Capacity` rather than buried: FR-068
> ships partially delivered and SC-025's second clause is unmet.
>
> The validator's own suggestion was to defer **T088 (5.0 SP)**, ranked `[unmapped; priority
> unavailable]` — i.e. chosen by size because it could not resolve FR-066's priority. That cut was
> not taken: T088 is the core FR-066 integrity fix, and deferring it would leave the iteration
> without the defect it exists to close.

## Human Authorization

Approved for plan 2026-08-03, with three carried instructions. Iteration 011 is **phase 2** of a
two-phase iteration decided in advance: phase 1 amended the spec (FR-019 scope amendment plus
FR-066/FR-067/FR-068, with SC-022..SC-025), and this phase plans and implements against it.

Carried instructions, binding on this iteration:

1. **Checkpoint identity derives from the lifecycle state machine** — the boundary/stage being
   certified — **NOT caller-supplied free text.** Minting checkpoint names would reopen the spin
   hazard through the naming door, bounded only by the campaign total. This constrains FR-019's
   implementation wherever it lands.
2. **FR-068's reproduction harness is its own plan line with its own estimate.** Confirmed. It is
   T086 below, and it precedes every FR-068 correction.
3. **Honest per-task numbers; if the total exceeds 20 SP, propose the split by severity with
   authorization-integrity (FR-066, FR-068) first, and the tag after both. The estimate decides,
   not optimism.**

The standing Beta2 bug-bash grant (Iterations 009–013, approved 2026-07-26) covers autonomous fix,
deterministic test, and independent-review correction cycles. It does not authorize a merge, tag,
publication, or paid-provider action outside an existing grant.

## The estimate decided, and it says three iterations — not two

Instruction 3 anticipated an overflow. The overflow is larger than a two-way split absorbs.

Two surveys measured the actual implementation surfaces before any number was written. **The full
consumer-severe set is ~52 SP against a cap of 20**, distributed very unevenly:

| Slice | Estimate | Fits one iteration? |
| --- | --- | --- |
| **Authorization-integrity — FR-066 + FR-068** (this iteration) | **21.5** | marginally over; deferral candidate named |
| **FR-019** round-ceiling re-keying | ~19 + certification | no — at or over cap on its own |
| **FR-067** finality convergence | ~14 + certification | yes, with headroom |

So the split the instruction asked for — 011 = authorization-integrity, 012 = everything else —
would put iteration 012 at ~33 SP. **That is the same shape as Iteration 009**, which planned 24.5
against a cap of 20 and delivered ~70. The estimate's job is to say so before the fact rather than
after, so it is said here.

**This moves the beta2 tag** if the tag continues to gate on the whole consumer-severe set. A
decision on that belongs to the maintainer and is put at the plan boundary, not assumed here. The
alternative worth weighing: **tag after authorization-integrity alone.** FR-066 and FR-068 are
integrity defects — a verdict demanded against an empty increment risks a false human
authorization, which is the severest failure the governance model has. F10 (round-ceiling tax) and
F17 (non-convergent finality) are severe cost and UX defects but not integrity defects, and the
narrowed claim already ships with limitation 1 named and standing.

### Why FR-019 is nearly a full iteration by itself

The survey found the surface is not what the requirement's simplicity implies:

- **There are two independent allowance systems, plus a third dormant one.** System A (the legacy
  round ceiling) is not per-campaign — it is a **repo-global singleton keyed on changed-path
  overlap** (`.specrew/runtime/co-review-round-state.json`, one file, keyed by
  `Test-ContinuousCoReviewPathLineageOverlap`). System B is the campaign grant/slot allowance keyed
  by `campaign_id`. System C, in the inline gate evaluator, is *already* checkpoint-scoped with its
  own separate default. Re-keying System A converges it on System C; leaving both is two ceilings
  with different keys.
- **A checkpoint-identity minting rule does not exist.** Today `checkpoint_id = "nav-$RunId"` —
  per-run, not per-boundary. Instruction 1 requires it derive from the lifecycle state machine, so
  this is net-new design, not a refactor.
- **The authority contracts are closed-shape with `schema_version` pinned to `1.0`.** Adding
  `checkpoint_id` to `GrantFact` needs the field list, the validator, a schema-version decision,
  and a migration — every existing on-disk fact fails closed-shape validation otherwise.
- **The campaign-level total does not exist.** `granted_slots` is computed but nothing caps it. The
  spend-guard backstop the maintainer endorsed at specify is net-new logic, not a config change.
- **~3,738 lines / 151 `It` blocks are in the blast radius**, and they are behaviour-locking:
  titles like *"clears blocking + lineage but PRESERVES the spent rounds"* and *"REPLENISHES the
  round allowance to 0"* need renegotiating, not extending.
- **One good surprise**: `resolved-against-disk` already preserves the spent count
  (`worktree-review-orchestrator.ps1:253`, a deliberate DRIFT-198-I003-005 fix). The "verified
  closure retires findings without replenishing" semantic exists — it only lacks a checkpoint key.

An open question that must be settled before FR-019 is scheduled, not during: the repo runs in
**campaign** mode, and `scripts/specrew-review.ps1:803` rejects every remediation except
`override-block` in that mode. `allowance-reset` and `resolved-against-disk` — the two paths FR-019
changes — are therefore **unreachable in the live mode today**. Either the story includes lifting
that gate, or the new behaviour ships unreachable.

### Why FR-067 is the one most likely to be under-estimated

Its blocking decision is a single line (`review-signoff-evidence-gate.ps1:409`), which reads cheap.
It is not, for two reasons the survey surfaced:

- **A configurable severity threshold requires unifying two incompatible vocabularies first.**
  `review-authority-core.ps1` enforces `blocking|major|minor|note`; `worktree-reviewer.ps1` emits
  `blocking|advisory|nit`; the only rank map lives in a third file. Five thresholds are hard-coded
  in five places.
- **The self-referential half cannot take the obvious shortcut.** Widening the digest strip list is
  blocked by the explicit warning at `reviewed-state-digest.ps1:61-63` that *anything excluded from
  the identity is a false-allow vector.* FR-045's carry-forward allowlist
  (`review-signoff-evidence-gate.ps1:281`) covers exactly the six generated review artifacts and
  denies `state`/`plan`/`tasks` — the documented cause of the reopen loop.

Neither is in this iteration. Both are recorded here so the next plan starts from measurement.

## Objective

Close the two **authorization-integrity** defects from the consumer manual test: a verdict demanded
for a stage that has produced no evidence, and a first boundary whose packet is the event that
creates the state it reports. Both risk a human authorization recorded against nothing.

## Scope Summary

**In scope**: FR-066 (first-boundary arrival sync precedes the first packet), FR-068 (a verdict
demand requires its stage's evidence; conflicting hook signals resolve deterministically), and
their criteria SC-023 and SC-025.

**Explicitly NOT in this iteration**: FR-019 and FR-067, with their criteria SC-022 and SC-024.
Deferred on the estimate above, not on preference.

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T086 | FR-068 reproduction harness — reproduce BOTH halves of the 2026-07-25T17:40:45Z shape | FR-068 | Authorization integrity | 2.5 | Implementer | tests/integration/dispatcher-stop-block.tests.ps1 | planned | | | Own plan line per instruction 2. Must reproduce the demand-without-evidence AND the emit/do-not-emit marker conflict in one delivered message, before any correction. The spec's reproduction-first mandate is binding: the transcript is an observation elsewhere, not a reproduction here |
| T087 | FR-066 RED fixtures — first-boundary arrival, proven RED before any fix | FR-066 | Authorization integrity | 2.0 | Implementer | tests/integration/pending-verdict-stop-artifact.tests.ps1, tests/integration/pending-verdict-surface.tests.ps1 | planned | | | Must include the un-bootstrapped project path that makes `Set-SpecrewPendingBoundaryCrossingScope` throw, since that is the live hole |
| T088 | FR-066 — give `IsFirstBoundary` a consumer; the sync's degraded catch becomes a first-class suppressed state | FR-066 | Authorization integrity | 5.0 | Implementer | scripts/internal/sync-boundary-state.ps1, extensions/specrew-speckit/scripts/shared-governance.ps1 | planned | | | `IsFirstBoundary` is computed at `shared-governance.ps1:1192` and **no consumer branches on it**. The `catch` at `sync-boundary-state.ps1:1660` degrades to warn-and-continue, producing no record and no artifact — that silent degrade is the defect |
| T089 | FR-066 — the conformance provider honors the unsynced state: no approval options, no marker, names what is missing | FR-066 | Authorization integrity | 2.5 | Implementer | extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1 | planned | | | Today the `else` branch at `:1088-1090` emits a boundary stop naming a boundary with **no marker text**, because the pending crossing was null — the Antigravity "headers but no marker" shape |
| T090 | FR-068 — artifact-gated verdict demand: a new seam between the conformance provider and stage evidence | FR-068 | Authorization integrity | 4.0 | Implementer | extensions/specrew-speckit/scripts/shared-governance.ps1, extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1 | planned | | | `Get-SpecrewPendingVerdictState` probes no artifact at all, and the block warrant at `:1024` is purely cursor/marker/intent with no evidence term. The suppression shape to reuse exists (`render_boundary_packet` / `render_verdict_marker`), but the two subsystems do not currently talk |
| T091 | FR-068 — deterministic stop-block composition: stated precedence, conflict detection, losing signal preserved | FR-068 | Authorization integrity | 0.0 | Implementer | scripts/internal/specrew-hook-dispatcher.ps1, extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1 | deferred | | | **DEFERRED at plan time to bring the iteration under cap — carries 3.0 SP into the FR-019/FR-067 slice.** Reversible at the plan verdict; see `## Capacity`. Composition today is concatenation with `----- AND ALSO -----` at `:1197-1202`; no precedence, no conflict detection, and the `:1209` fall-through discards the merged reason with no record. Only two providers can ever conflict (conformance 40, navigator 50), which caps the work. Dispatcher is a byte-identical twin: every edit is a two-file edit |
| T092 | Integrated verification and capped certification | FR-066, FR-068 | Release confidence | 2.5 | Reviewer | tests/**, specs/198-beta2-hardening/iterations/011/** | planned | | | Round cap 3. Correction allowance is inside this task rather than assumed free |

**Total planned: 18.5 SP against a capacity of 20, with 1.5 SP of SLACK.**

Before the deferral it was 21.5 — over cap by 1.5, which `overcommit_threshold: 1.0` forbids. T091
was deferred to bring it under; the reasoning is below and the maintainer can reverse it.

## Capacity

`capacity_per_iteration: 20`, `overcommit_threshold: 1.0` — **no overcommit is permitted**, so the
measured 21.5 could not stand. `defer_strategy: manual`, so nothing is dropped silently.

**Deferred: T091 (3.0 SP)** — the composition half of FR-068 — bringing the plan to **18.5/20 with
1.5 SP of slack**, which preserves the absorption Iteration 010 proved valuable and Iteration 009
never had. It carries its 3.0 SP into the FR-019/FR-067 slice.

Ranked lowest-priority-first, as the method requires, the reasoning is:

- T091 is the **lower-integrity half** of FR-068. A contradictory pair of directives is confusing
  and forces the agent to violate one live instruction — real, and recorded — but the human is not
  thereby led to authorize nothing. **T090 is the half that risks a false authorization**, and it
  stays.
- Its blast radius is the smallest measured: two providers, a six-line composition point, and an
  existing two-provider merge test to extend.
- **Requirement impact, stated plainly**: deferring T091 means **FR-068 is partially delivered and
  SC-025's second clause is unmet** at this iteration's close. That must be recorded as such — not
  as a pass — and it is exactly the shape that held Iteration 009 open. If the maintainer prefers
  not to repeat that, the alternative is to keep T091 and defer T087's fixtures into T088/T089,
  which is worse: it removes the RED-first proof that Iteration 010 demonstrated is the difference
  between a fixture that catches a defect and one that decorates it.

**Recommendation: defer T091 to the FR-019/FR-067 slice**, where the dispatcher is untouched by
other work and the composition change can carry its own certification.

## Tag basis RE-CUT, 2026-08-03 — beta2 gates on authorization-integrity only

Maintainer verdict on the estimate above. Rather than move the tag by two iterations, the tag's
basis was re-cut:

- **beta2 gates on FR-066 and FR-068's evidence half.** Tag after Iteration 011.
- **F10 (FR-019) and F17 (FR-067) move to beta3**, entering
  file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/beta2-release-claim.md as named
  limitations 8 and 9, in the same posture limitation 1 takes.
- **Iterations 012 and 013 of the five-iteration plan are formally re-homed to beta3.** The release
  gate and the maintainer's manual test follow Iteration 011.
- **T091 stays deferred**, and the verdict authorized a scoped specify touch naming the beta3
  hook-machinery cluster as SC-025's composition vehicle — so FR-068 closes honestly here rather
  than holding Iteration 011 open against an unmet clause (the DRIFT-198-I009-044 wall).

The causation claim behind that last point is written into SC-025 and is **checkable at this
iteration's certification**: T090's stage-evidence gating removes the observed conflict at its
origin, because the 2026-07-25 emit/do-not-emit pair only formed when a premature demand
co-rendered with a campaign block. If certification finds a conflict that stage-evidence gating does
NOT remove, that finding reopens the clause rather than being waved through.

## Beta3 scope, recorded now so it is planned rather than rediscovered

Per the maintainer's instruction that FR-019's precondition be named now rather than found later:

| Item | Why it is here |
| --- | --- |
| **PRECONDITION — campaign mode rejects all remediations except `override-block`** (`scripts/specrew-review.ps1:803`) | FR-019 changes `allowance-reset` and `resolved-against-disk`; both are unreachable in the shipped mode. **This must be settled before FR-019 is scheduled, not during** — either the story lifts the gate, or the new behaviour ships unreachable. |
| **DRIFT-198-I010-012 — the halt message teaches a command that throws** | Found while writing limitation 8. Compounds F10 and belongs with it: the ceiling is mis-scoped AND its documented escape is nailed shut. Puts FR-018 in violation on the shipped default. |
| **FR-019 implementation** (~19 SP + certification) | Checkpoint-identity minting from the lifecycle state machine is net-new design; closed-shape contract migration; campaign-total enforcement is net-new. |
| **FR-067 implementation** (~14 SP + certification) | Prerequisite: unify the two severity vocabularies. The digest strip list is not available as a shortcut. |
| **T091 — deterministic stop-block composition** (3.0 SP, deferred from here) | Joins the hook-machinery cluster named in SC-025. |
| **Containment consolidation** (delivers DRIFT-198-I009-041 / -I010-004) | One primitive covering resolution AND enumeration, link-state oracle fixtures, structural rule, mutation gate. |
| **Proposal 206 — governance-schema vocabulary completeness** | Seven instances, including DRIFT-198-I010-008 (boundary cursor). |
| **Repo-wide `state.md` audit** | Maintainer-assigned to beta3 backlog. This feature's nine iterations were measured; other features on other branches were not. |
| **DRIFT-198-I010-010 — the `Status` projection fix** | See the slack assessment below. |

## Does DRIFT-198-I010-010 fit the 1.5 SP slack? — assessed, and NO

The maintainer's instruction was explicit: *"rides 011's 1.5 SP slack **only if it genuinely
fits**."* Assessed honestly, it does not.

The fix is three parts: carry `Status` through `Get-TaskProgressPlanRows`, seed a newly-minted
ledger from it, and prove it RED-first. The projection change is nearly free. The seeding is not —
it has to interact correctly with the existing preserve-live-state logic
(`task-progress.ps1:657-662`, which deliberately protects `in-progress`, `blocked`, `needs-rework`
and `deferred` from being downgraded), and it must decide how three disagreeing status vocabularies
map. The RED-first fixture needs a project whose plan records `done` tasks and no ledger.

**Estimate: 1.5 SP — exactly the available slack, leaving zero absorption.** That is the Iteration
009 condition restated: entering an iteration at cap with nothing to absorb the first surprise.
Iteration 010 proved the alternative works, and the maintainer's own words on that headroom were
*"that headroom is exactly what 009 never had."*

**Recommendation: it does not fit; it goes to beta3 with the `state.md` audit** it is the root cause
of. The immediate risk is already mitigated — Iteration 011's `tasks-progress.yml` was authored at
plan time, which removes the condition the defect requires, and Iteration 010's record is restored.

## Method — carried forward, binding

Unchanged from Iteration 010, which delivered on estimate under them:

1. **Test first, and prove the test can fail.** T086 and T087 precede every correction. A fixture
   that passes before the fix is not evidence.
2. **Reproduce before correcting.** Binding for FR-068 by spec text: the 2026-07-25 transcript is
   an observation elsewhere, not a reproduction here.
3. **Push per focused commit, and check the previous push's CI before starting the next cycle.**
   Every workflow individually, not one of them.
4. **Evidence before hypothesis, and verify the evidence tool.** No piping a diagnostic run through
   `Select-String`/`Select-Object -First` and then trusting the exit code.
5. **Scoped validator during work, full validator before commit.**
6. **Never edit the tree while a registry or review run is in flight.**
7. **Both trees, every time.** The hook dispatcher is byte-identical across `scripts/internal/` and
   `extensions/specrew-speckit/scripts/`; provider parity is a recurring defect class in this
   feature.

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Configured value; unchanged. |
| Iteration Bounding | scope | Matches `iteration-config.yml`, which offers only `scope` or `time`. **NOT the real bound** — the real bound is the 3-round review cap. See DRIFT-198-I010-001. |
| Time Limit (hours) | n/a | Bounded by review rounds, not time. |
| Overcommit Threshold | 1.0 | No overcommit allowed — hence the named deferral candidate. |
| Defer Strategy | manual | No approved requirement slice is silently dropped. |
| Calibration Enabled | true | Retro records engineering and verification variance. |

### Phase baseline, for retro comparison

| Phase | Planned SP |
| --- | --- |
| Discovery / reproduction (T086, T087) | 4.5 |
| Implementation (T088, T089, T090) | 11.5 |
| Verification + certification (T092) | 2.5 |
| *(deferred: T091)* | *3.0, carried out* |

Iteration 010's calibration is the reference: base work landed on estimate, and the 3-round cap
plus the termination rule held the correction cycle to **one** round rather than Iteration 009's
eight. The correction allowance stays inside T092.

## Release-Claim Impact

This iteration removes **no** limitation from
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/beta2-release-claim.md. Limitation
1 (containment: resolution yes, enumeration no) stands and is closed by the beta3 consolidation.

What it changes is the tag's basis: if the maintainer rules that the tag gates on
authorization-integrity rather than the whole consumer-severe set, then FR-019's round-ceiling tax
and FR-067's non-convergent finality become **named, documented limitations** in the claim rather
than silent defects — the same honest posture limitation 1 already takes.

## Traceability Summary

- Requirement scope: FR-066, FR-068. Criteria: SC-023, SC-025.
- Every task traces to at least one; both requirements have at least one covering task.
- **`tasks.md` backfill — SCHEDULED at this iteration's tasks boundary** (maintainer instruction,
  2026-08-03). `tasks.md` carries no Iteration 009, 010 or 011 sections, so its bidirectional check
  has not covered T072 onward (DRIFT-198-I010-007). All three sections and their bidirectional
  checks land when the tasks boundary is authored, rather than 011 joining the same gap.

## Notes

- **The scaffolder could not produce this plan.** `scaffold-iteration-plan.ps1` fails on every
  requirement carrying provenance parentheses; it can see 8 of this spec's 70 FR definitions
  (DRIFT-198-I010-011). This plan is hand-authored against Iteration 010's validator-checked
  structure. No scaffolder output was faked.
- **Iteration bounding says `scope`; the real bound is the 3-round review cap.** The structured
  field cannot express it (DRIFT-198-I010-001, in the beta3 vocabulary work).
