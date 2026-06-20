# Design Analysis - Feature 197-continuous-co-review / Iteration 003

**Feature**: 197-continuous-co-review
**Iteration**: 003
**Date**: 2026-06-20
**Spec**: file:///C:/Dev/197-continuous-co-review/specs/197-continuous-co-review/spec.md

## Problem Framing

Iterations 001/002 shipped the rung-2b co-review spine (contracts, adapters, prompt
composer, gate evaluator, blackboard) plus a manual `specrew review --live` command
and a signoff-time discipline instruction. But always-on was never enforced: the
only wiring is boundary-discipline text the agent may skip, with no deterministic
gate. The maintainer ruled (2026-06-20) that co-review MUST be always on - mandatory
at every implement checkpoint, like a pair-programming navigator that checks each
increment as the driver writes it, not just once at review-signoff.

Two facts ground the design. First, the deterministic boundary-advance chokepoint is
`Invoke-SpecrewBoundaryStateSync` in `scripts/internal/sync-boundary-state.ps1`,
which already hosts throw-to-refuse gates (markdownlint, working-tree,
iteration-state-truth) and is NOT on the F-184 protected list. Second, there is no
per-task implement boundary in the canonical state machine - `implement` and
`review` both alias to `review-signoff` - so a per-task checkpoint must be created.
The only agent-unforgeable per-stop trigger is the host Stop hook, which IS protected
(F-184) and whose per-host block-and-feedback capability is unproven.

## Key Design Decision Points

1. How to fire co-review at every implement checkpoint without firing on every casual
   turn-yield and without per-host conditionals.
2. Where deterministic enforcement lives (non-protected boundary-sync) versus the live
   per-stop trigger (protected Stop hook).
3. How to keep the trigger host-neutral across all five harnesses through the existing
   hook abstraction, with a backstop when a hook fire is missed.
4. How to filter stops so only registered gates run a reviewer (the dispatcher and
   gate-keyed registry).
5. How to slice the work so the high-risk protected/cross-host parts do not block the
   deterministic floor.

## Alternatives

### Option A: Simplest - Instruction-only enforcement (status quo)

**Approach**: Keep relying on the review-signoff refocus discipline that tells the
agent to run `specrew review --live`, with a doc-presence test.

**Trade-offs**:

- (+) Zero new runtime code.
- (-) Not deterministic - depends on the agent obeying instructions, which is exactly
  the reliability gap the maintainer rejected. No guarantee the reviewer ever runs.

**Recommended for**: Nothing; this is the rejected status quo.

### Option B: Recommended - Layered, split into Phase A (this iteration) and Phase B

**Approach**: Build the deterministic, 197-owned floor and dispatcher first (Phase A =
Iteration 003), then add the live protected Stop-hook trigger across harnesses
(Phase B = Iteration 004). Phase A: a per-task checkpoint with an incremental
baseline; a 197-owned gate-review dispatcher that a single host-hook call invokes and
that consults a gate-keyed registry (one registrant: code review at implement); the
existing navigator runtime reused on the incremental diff; and a deterministic gate
floor in `sync-boundary-state.ps1` that refuses review-signoff unless every increment
carries passing or escalated evidence. Phase B then wires the Stop hook through the
host abstraction with a block-and-feedback handshake and proves it on all five hosts.

**Architectural pattern**: Layered enforcement (deterministic floor + event trigger)
with a gate-keyed dispatch seam.

**Effort estimate**: Phase A ~10 points; Phase B ~6-8 points.

**Reversibility cost**: Low for Phase A (no protected files; fixture-testable).

**Trade-offs**:

- (+) Phase A delivers an un-bypassable guarantee (no signoff without reviewed
  increments) entirely in 197-owned, non-protected code.
- (+) The dispatcher/registry kills the "fire on every stop" anti-pattern and makes
  future per-gate reviewers a registry entry, not a hook change.
- (+) Isolates the riskiest assumption (per-host Stop-hook block capability) into
  Phase B on a green base.
- (-) The live navigator-on-your-shoulder experience lands in Phase B; Phase A's
  feedback point is review-signoff.

**Recommended for**: Iteration 003 (Phase A) and Iteration 004 (Phase B).

### Option C: By-the-book - Single all-in-one iteration (floor + live hook + cross-host)

**Approach**: Implement the gate floor, dispatcher, live Stop hook, per-host
block-feedback, and five-host verification in one iteration.

**Trade-offs**:

- (+) Full live experience sooner.
- (-) Couples low-risk 197-owned code to the riskiest protected/cross-host work;
  likely needs the 20-SP cap raised; a per-host hook limitation would stall the whole
  slice including the deterministic floor.

**Recommended for**: Rejected; the split delivers the floor's value before betting on
per-host hook behavior.

## Applicable Lenses

- **architecture-core**: Option B keeps the deterministic floor (non-protected
  boundary-sync) separate from the protected event trigger, and routes the trigger
  through one dispatch seam rather than coupling review to host internals.
- **component-design**: the dispatcher, gate-keyed registry, gate-floor function, and
  checkpoint/baseline helper are distinct feature-local responsibilities that reuse
  the iteration 001/002 spine unchanged.
- **integration-api**: the Stop hook delivers one host-neutral call; the registry maps
  gate to reviewer; the navigator runtime and contracts are reused as-is.
- **security-compliance**: the navigator stays read-only by contract with the mutation
  guard; one-time per-project authorization satisfies cost control without per-run
  prompts.
- **observability-resilience**: each checkpoint review writes durable evidence under
  `.specrew/review/inline/<run-id>/`; the gate floor reconstructs pass/block from that
  evidence; the dispatcher records no-op decisions for casual/unregistered stops.
- **devops-operations**: Phase A adds no protected-surface edits and no new service;
  Phase B's hook wiring is the authorized F-184 coordination.

## Co-Design Record

**Decomposition vocabulary**: layered enforcement + gate-keyed dispatch seam.

**Human-agreed**: yes - cadence (per implement checkpoint), Option A dispatcher
ownership (197-owned, not a general hook-platform subscription), all five harnesses
carry the Stop hook with the gate floor as a universal backstop, the A/B split, and
deferral of the manual real-host validation until after both A and B were all
confirmed in conversation on 2026-06-20.

### Agreed loop (with the gate-review dispatcher)

```text
DRIVER (implementer, any harness) completes task TNNN, then YIELDS the turn
  -> host fires native Stop event
  -> [F-184] HOST HOOK ABSTRACTION (registry + handlers + dispatcher, 5 harnesses)
  -> ONE host-neutral call
  -> [NEW] GATE-REVIEW DISPATCHER
       real checkpoint? -- no --> no-op (casual yield)
       which gate? -- consult registry --
         implement   -> CODE reviewer  -> run        (today)
         design-lens -> (future)        -> no-op
         plan/tasks  -> (future)        -> no-op
  -> [SPINE] CO-REVIEW RUNTIME: spawn fresh-context navigator (claude -p / codex exec)
       normalize -> blackboard -> gate verdict -> .specrew/review/inline/<run-id>/
  -> pass | block (<=2 rounds) -> driver fixes | escalate -> human
BACKSTOP: gate floor in sync-boundary-state.ps1 refuses review-signoff unless every
increment carries passing/escalated evidence
```

### Layered enforcement

```text
PRIMARY (Phase B / iter 004)  Stop-hook navigator: every increment, live, all 5 hosts
   |  if a Stop fire is missed/crashed/degraded
   v
BACKSTOP (Phase A / iter 003) gate floor in Invoke-SpecrewBoundaryStateSync
   (sync-boundary-state.ps1, NOT F-184-protected) -- refuses signoff without
   passing/escalated evidence for every increment
```

## Crew Recommendation

**Recommended: Option B, Iteration 003 = Phase A.**

Phase A delivers the deterministic guarantee and the dispatcher machinery entirely in
197-owned, non-protected code, fixture-testable without any hook, so the un-bypassable
"no signoff without reviewed increments" floor ships first. Phase B (Iteration 004)
then adds the live per-stop Stop-hook navigator across all five harnesses under the
authorized F-184 coordination, where the per-host block-and-feedback capability is the
explicit risk to prove. The maintainer's manual real-host validation runs after both
phases, because Phase A has no live hook to exercise.

## Human Decision

- **Decision verdict**: pending plan-boundary approval (this artifact + plan.md)
- **Chosen option**: Option B, split as Iteration 003 (Phase A) / Iteration 004
  (Phase B)
- **Reason**: The maintainer confirmed always-on per-checkpoint co-review, the
  Option A 197-owned dispatcher scope line, all five harnesses carrying the Stop hook
  with the gate floor as a universal backstop, the A/B split, and that the manual
  real-host validation runs after both A and B.
- **Modifications**: F-184 coordination is authorized for the Phase B Stop-hook trigger
  only; the Phase A floor and dispatcher touch no protected files. FR-008's no-hook
  constraint is relaxed narrowly for the Stop hook (never PostToolUse/per-edit).
- **Approval evidence commit**: pending - the spec amendment and these artifacts are
  held uncommitted in the working tree until the maintainer authorizes a commit.
