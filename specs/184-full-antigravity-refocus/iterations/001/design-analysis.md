# Design Analysis: Full Antigravity Refocus (Iteration 001)

**Feature**: 184-full-antigravity-refocus
**Date**: 2026-06-17
**Boundary**: design-analysis (pre-plan)
**Spec**: file:///C:/Dev/183-stability-quality-bundle/specs/184-full-antigravity-refocus/spec.md
**Builds on**:
file:///C:/Dev/183-stability-quality-bundle/specs/184-full-antigravity-refocus/workshop/

## Problem Framing

F-184 completes the Antigravity work intentionally left bounded in F-183. The
feature has three load-bearing implementation questions:

- Edge 1: Antigravity must not warn about its own same-worktree marker.
- Edge 2: Antigravity must use the same per-session refocus state/anchor model
  as other hosts, keyed by the real `conversationId`.
- B3: Antigravity must deliver boundary-cross refocus through `PreInvocation`
  `injectSteps`, exactly once, and only on real boundary crossings.

The design decision is how to finish those without turning F-184 into a broad
host-platform rewrite or claiming parity before real `agy` evidence exists.

## Alternatives

### Option A - Complete Bounded Antigravity Refocus In One Iteration

Use the existing refocus architecture and extend only the Antigravity
manifest/adapter/state/helper slice. Discovery runs first and produces
PASS/FAIL rows for the split guard before implementation proceeds.

**Effort**: 26 story_points, with a temporary F-184 capacity override from the
baseline 20 SP cap.

**Pros**:

- Completes the known F-183 carry-forward scope now.
- Keeps the full parity claim evidence-gated.
- Preserves existing host behavior by treating Antigravity differences as an
  adapter boundary.

**Cons**:

- Over the nominal 20 SP iteration cap.
- Depends on manual real-host `agy` validation.
- Discovery can still force a split/defer if a falsifiable trigger fails.

### Option B - Split B3 Into A Follow-Up

Fix Edge 1 and Edge 2 now, but leave B3-on-`PreInvocation` as a later feature.

**Effort**: 16 story_points.

**Pros**:

- Fits the nominal cap.
- Reduces real-host uncertainty inside this iteration.

**Cons**:

- Violates the user's explicit completeness goal.
- Keeps Antigravity short of full refocus again.
- Forces another return to a known missing requirement.

### Option C - General Host-Model Refactor

Refactor the shared host model so every host expresses B2/B3, injection,
handover, health, and state behavior through a richer shared contract.

**Effort**: 35+ story_points.

**Pros**:

- Strong long-term model if multiple hosts need the same change.

**Cons**:

- Trips the F-184 split guard.
- Risks changing non-Antigravity behavior.
- Repeats F-183's scope-expansion failure mode.

## Decision

Proceed with **Option A** under the user's 2026-06-17 instruction to implement
the complete F-184 scope before the next human gate. The iteration is
human-authorized over the 20 SP cap for completeness, but the split guard is
not bypassed. The first implementation task is a discovery spike with
falsifiable PASS/FAIL triggers:

| Trigger | PASS condition | FAIL action |
| --- | --- | --- |
| Fresh boundary cursor | `PreInvocation` can see or derive the pre-turn boundary cursor needed for B3. | Stop for human split/defer verdict. |
| Exactly-once B3 | Existing dedupe/breaker logic can make `PreInvocation` inject B3 once for a real crossing and not on ordinary turns. | Stop for human split/defer verdict. |
| Bounded host model | Implementation stays in Antigravity manifest/adapter/state/helper changes without altering non-Antigravity contracts. | Stop for human split/defer verdict. |

## Component Map

```text
agy hook runtime
  |
  v
AntigravityEventAdapter
  - normalize conversationId, event, transcript path, workspace paths
  - shape PreInvocation and Stop output
  |
  v
SpecrewHookDispatcher
  |
  +--> SessionStateAccessor
  |      owns refocus-state-<session>.json, anchor, cursor, dedupe, breaker
  |
  +--> ClassificationEngine
  |      decides lifecycle boundary/refocus classification
  |
  +--> B3RefocusDecision
  |      uses existing Test-B3ShouldInject/dedupe/breaker behavior
  |
  +--> ConcurrencyMarkerClassifier
         small helper if needed: own marker vs competing marker

deploy-refocus-hooks.ps1
  |
  v
.agents/hooks.json
  - preserve user hooks
  - install/remove only Specrew-owned Antigravity hook definition
```

## Binding Design Rules

- `conversationId` is the Antigravity per-session identity.
- No code path may return or persist global `unknown` when Antigravity provides
  a real `conversationId`.
- `SessionStateAccessor` owns state. Antigravity code normalizes input and
  delegates state read/write.
- `PreInvocation` is the selected B2/B3 carrier. `PostToolUse` is not an
  injection carrier for this feature.
- Hook failures fail open with bounded warnings and recovery guidance.
- Docs reach host-level content depth, but status labels remain evidence-gated.
- The release topology is stacked: F-184 completes F-183 and releases together
  with it after beta validation.

## Key Flows

### B3 Boundary Crossing

```text
agy PreInvocation
  -> AntigravityEventAdapter extracts conversationId
  -> SessionStateAccessor loads refocus-state-<session>.json
  -> ClassificationEngine compares boundary cursor
  -> B3RefocusDecision checks dedupe/breaker
  -> Dispatcher emits Antigravity injectSteps exactly once
  -> SessionStateAccessor records decision/evidence
```

### Ordinary Turn

```text
agy PreInvocation
  -> state load succeeds
  -> boundary cursor unchanged
  -> B3RefocusDecision returns no injection
  -> no dedupe/breaker false advance
```

### Stop Handover Regression Guard

```text
agy Stop
  -> dispatcher uses existing handover provider
  -> output remains Antigravity decision JSON
  -> rolling handover stays host-agnostic
```

## Capacity Model

| Slice | Requirements | Effort |
| --- | --- | ---: |
| Discovery spike and split-guard evidence | FR-003, FR-010, SC-009 | 3 |
| Per-session identity and state/anchor | FR-001, FR-002, FR-005, SC-001, SC-002 | 4 |
| B3 on `PreInvocation` | FR-003, FR-006, FR-010, SC-003, SC-007, SC-009 | 5 |
| Self-marker concurrency classifier | FR-004, SC-004 | 3 |
| Hook config preservation and F-183 regression guards | FR-005, FR-007, SC-005, SC-006 | 3 |
| Documentation and release-status wording | FR-008, FR-009, TG-006, SC-008, SC-010 | 2 |
| Automated validation, mirror/FileList readiness | TG-001, TG-002, TG-003, SC-001..SC-010 | 3 |
| Real-host evidence and review artifacts | TG-004, TG-005, SC-002, SC-003, SC-005, SC-009 | 3 |
| **Total** |  | **26** |

Capacity status: **26/26 story_points** under a temporary F-184 capacity
override from the baseline 20 SP cap. The 6 SP expansion is explicitly accepted
by the human's 2026-06-17 completeness instruction. No scope is deferred. The
discovery split guard remains binding, and retro/closeout must restore the
baseline cap.

## Co-Design Record

**Human-agreed**: yes. The user approved the specify packet, then gave an
explicit implementation-through-completion instruction on 2026-06-17:
"You are clear to implement all... Next stop gate ... AFTER the complete
implementation."

This design-analysis consumes the already-confirmed workshop decisions rather
than re-deciding them.

## Plan Obligations

- The task table must sequence discovery first.
- The discovery task must produce explicit PASS/FAIL split-guard rows.
- Plan and tasks must show the temporary 26 SP capacity override from the
  baseline 20 SP cap rather than hiding the expansion.
- Review must use Proposal 145 discipline and fix findings before presenting
  the next human gate.
