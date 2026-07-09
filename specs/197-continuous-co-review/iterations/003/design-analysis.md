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

## Design Revision (2026-06-20) — Sound Evidence Model (supersedes the diff-from-baseline gate)

### Why this revision

The first Phase-A gate keyed signoff freshness on a `diff_hash` recomputed from an
operator-chosen baseline to the working tree. Two fresh-context Proposal 145 co-reviews
(the feature dogfooding itself) found this model has two false-allows that no localized
patch closes:

- **HOLE A — gitignored-source blindness**: `git diff <baseline>` walks tracked files
  only, and `git status --untracked-files=all` omits ignored files, so reviewable
  gitignored source signs off un-reviewed.
- **HOLE B — unanchored operator baseline**: the gate proves only that the tree matches
  the diff from an operator-chosen `--baseline-ref`; nothing verifies that baseline was
  itself reviewed, so a tip-only review skips the middle. The "baseline advances only on
  a pass" invariant is vacuous because no production caller threads `-RebaselineToLastPass`.

Re-architected within Iteration 003 (D-197-I003-005) per maintainer decisions: gitignored
SOURCE is in review scope with `.env`/secrets/ambient excluded; the trusted anchor is the
merge-base with `main`; enforcement is producer auto-anchor PLUS gate chain-verification,
with a human-authorized recorded partial-coverage override.

### The sound model — four parts

**1. Content-addressed reviewed-state identity (closes HOLE A, NEW-1-untracked, NEW-2,
NEW-5, NEW-6).** A run records a digest of the EXACT worktree content it reviewed, not a
diff. The digest is built from a temporary git index so the real index/HEAD are never
touched: seed a temp `GIT_INDEX_FILE` from HEAD, `git add -A` (all tracked changes +
untracked non-ignored), then `git add -f` the gitignored-SOURCE paths after removing the
secret/ambient set, then `git write-tree` -> a tree-id over tracked + untracked +
included-gitignored content. Freshness = current worktree tree-id == a passing run's
recorded tree-id. This structurally removes the diff-recompute, the untracked blind spot
(it is in the tree), the empty-diff trust (the empty tree has a distinct well-known id),
and the porcelain path-parsing. (VALIDATED empirically 2026-06-20 in an isolated repo: `write-tree` over a temp index is
deterministic same-checkout; `add -f` includes gitignored source; the secret stays out by
not adding it; a tracked OR gitignored-source change flips the tree-id (HOLE A closed); a
change to an excluded secret does not affect the digest; the empty tree has the well-known
id `4b825dc642cb6eb9a060e54bf8d69288fbee4904` for the no-content guard. Cross-platform
determinism is a non-issue because the gate recomputes on the SAME checkout that produced
the evidence, so the manifest-of-hashes fallback is not needed.)

**2. Secret/ambient exclusion (SEC-002 + maintainer "leave .env out").** When building the
temp index, exclude a conservative, extensible secret/ambient denylist: `.env*`, `*.key`,
`*.pem`, `*secret*`, `*credential*`, token stores, `node_modules/`, `dist/`, `build/`,
`.venv/`, and the existing Specrew runtime trees (`.git/`, `.specrew/`, `.squad/`,
`.specify/`, `.scratch/`). Excluded content is in neither the reviewer bundle nor the
digest. Tradeoff (accepted): the denylist is best-effort, so a secret in an undeclared
location could enter the bundle; the maintainer chose include-by-default-minus-denylist
over an opt-in allowlist.

**3. Lineage chain anchored to merge-base with `main` (closes HOLE B + NEW-1 scope).** No
`scope` string (it was never populated). Identity is git lineage: a passing run is a chain
candidate iff its `reviewed_ref` is an ancestor of HEAD (`git merge-base --is-ancestor`).
The TRUSTED ANCHOR is `git merge-base(HEAD, main)` — "co-review must cover everything the
feature added on top of shipped main". The gate verifies the selected pass's chain reaches
the anchor with no gap (each link's baseline is the prior pass's reviewed point, back to
the anchor), and BLOCKS on a gap. `reviewed_ref`/`baseline_ref` already exist on the
record, so there is no never-null field to forget.

**4. Producer auto-anchoring + recorded override (makes the invariant TRUE).** The live
command and the always-on path stop accepting an arbitrary `--baseline-ref` for
signoff-bearing runs; the baseline is forced to the last-pass (chaining to the anchor).
Exploratory reviews with a custom baseline are allowed but recorded as non-signoff and do
not count. A human-authorized, RECORDED partial-coverage override ("partial coverage
accepted by <human> with rationale") exists for edge cases — auditable, never silent.

All git failures (status, write-tree, merge-base, rev-parse) fail CLOSED (block as
infrastructure-unsafe), and path enumeration uses `-z`/NUL parsing.

### Reviewer context vs gate identity

- The REVIEWER is fed more context (the change under review plus gitignored-source
  context), minus secrets — per the maintainer's HOLE-A decision.
- The GATE keys on the absolute content-addressed tree-id of the reviewed state (not a
  diff), anchored to merge-base with main.

### Components touched (all 197-owned; wiring into boundary-sync stays deferred post-185)

- `review-run-index-writer.ps1`: record `reviewed_tree_id` + `reviewed_ref`;
  lineage-filtered + anchor-verified last-passing resolver.
- `checkpoint-diff-provider.ps1` / a new reviewed-state-digest helper: the temp-index
  tree-id incl. gitignored-source minus secrets.
- `review-signoff-evidence-gate.ps1`: tree-id-equality freshness + chain-to-anchor
  verification + fail-closed + recorded override.
- `checkpoint-review-orchestrator.ps1` + `scripts/specrew-review.ps1`: producer
  auto-anchor; record the digest.
- `gate-review-dispatcher.ps1` + registry (T059/T060): unchanged in concept.

### Capacity

Re-plan sized to the maintainer-raised **25 SP** cap (iteration extended rather than split).

### Residual risks

- History rewrite (rebase/squash) breaks ancestry -> spurious BLOCK (fail-closed,
  recoverable by re-running co-review). Acceptable.
- Secret denylist is best-effort (maintainer-accepted).
- write-tree determinism VALIDATED (same-checkout, 2026-06-20); cross-platform is a
  non-issue because the gate recomputes on the producing checkout. Manifest fallback not
  needed.

### Design-revision decision

- **Verdict**: pending maintainer design approval (this revision) before the re-plan.
- **Maintainer decisions captured**: gitignored-source-in / secrets-out (A);
  merge-base-with-main anchor + auto-anchor + gate chain-verify + recorded override (B);
  25 SP cap; re-architecture stays in Iteration 003.
