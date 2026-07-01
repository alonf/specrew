# Review: Iteration 003 (Always-On Co-Review — Phase A, Sound Gate Re-Architecture)

**Feature**: 197-continuous-co-review
**Iteration**: 003
**Reviewed**: 2026-06-20
**Boundary**: review-signoff -> retro
**Overall Verdict**: Accepted (recommended; awaiting maintainer review-signoff verdict)

## Scope reviewed

The complete Phase A always-on co-review slice, including the mid-iteration gate
RE-ARCHITECTURE: T058 (incremental baseline), T065-T069 (content-addressed digest,
lineage/anchor resolver, re-architected gate, producer auto-anchor, diff-hash retirement),
T059/T060 (gate-review dispatcher + wiring), T062 (one-time auth + escalation), T063
(spawn-orphan regression), T064 (closeout validation). 24.00/25 SP.

## The arc (the dogfood loop worked — repeatedly)

1. The first Phase-A gate keyed signoff on a `diff_hash` recomputed from an operator-chosen
   baseline. The feature's OWN fresh-context co-reviews found it unsound: HOLE A (gitignored
   source invisible) and HOLE B (operator baseline never verified as reviewed).
2. Re-architected (maintainer-directed, within Iteration 003) to a **content-addressed
   reviewed-state tree-id** (includes tracked + untracked + gitignored source) **anchored to
   the merge-base with the trunk**, with producer auto-anchoring and a recorded override.
3. An adversarial re-review of the re-architected gate found a BLOCKING false-allow (F1: the
   denylist over-matched source named like a secret) — fixed.
4. A comprehensive 3-dimension Proposal 145 review found a second BLOCKING false-allow (the
   digest IDENTITY strip still excluded real source: `bin/**`, `*.key`/`*.token`/`*.pem`) plus
   a secret-handling finding (F-SEC-1) and governance gaps (B1/B2/B3, A1) — all addressed.
5. The confirming re-review (correctness + conformance) returned APPROVE on both.

This is exactly the shift-left value Proposal 197 exists to deliver: continuous co-review
caught its own gate model unsound — twice — before it could ship.

## Runtime evidence

- **Full `tests/continuous-co-review` suite: 176 passed, 0 failed.**
- **HOLE A blocks**: gitignored-source drift flips the tree-id and the gate returns
  `stale-co-review-evidence`; tracked source named like a secret / under `bin/` stays in the
  identity and its drift blocks (the F1 + correctness false-allow regressions).
- **HOLE B blocks**: a pass not chaining to the merge-base anchor returns `coverage-gap`; the
  multi-hop chain ALLOW + mid-gap are tested; the producer auto-anchors signoff runs.
- **Producer->gate loop** proven end to end (auto-anchor -> tree-id recorded -> allow ->
  drift blocks).
- **SC-023 zero-spawn**: unregistered stages (plan/tasks/spec/design-lens) and casual yields
  run no reviewer and write no evidence; a registered implement checkpoint runs the orchestrator.
- **Spawn robustness (NFR-001)**: a stalled large-stdin child is timed out and its process
  tree killed (no orphan).
- **Fail-closed** on every git/digest/anchor/lineage failure; no fail-open path.
- **SC-006**: protected-surface guard passes; the iteration's committed changes
  (`a8647528..HEAD`) touch only `scripts/internal/continuous-co-review/`, the 197-owned
  `scripts/specrew-review.ps1`, `specs/197-continuous-co-review/`, and `tests/` — **no F-184
  protected-surface edit**.

## Proposal 145 review (3 dimensions, all APPROVE after fixes)

- **Correctness**: false-allows closed (HOLE A, HOLE B, F1, the identity-strip); chain-walk
  sound; no new false-allow. APPROVE.
- **Conformance/traceability**: B1 (FR-025 reworded to the tree-id/anchor model), B2
  (SC-019/SC-020 honestly scoped to decision-logic with a recorded deferral authorization),
  B3 (task statuses + capacity reconciled), A1 (multi-hop tests). APPROVE.
- **Security**: spawn argv-safety, read-only posture, provider authorization, mutation guard
  all pass. F-SEC-1 (secret in the reviewer bundle/diff) was RELAXED by the maintainer's
  trust-boundary decision — the reviewer is a trusted in-boundary component that must read
  repo context and run tests with inherited env + repo access; recorded in the SEC-002
  amendment + Governance Alignment.

## Deferred (recorded, authorized)

- **Gate enforcement WIRING** into `Invoke-SpecrewBoundaryStateSync`: decision logic is
  delivered; the wired advancement block is deferred to coordinate with F-185 (authorized).
  SC-019/SC-020 are satisfied at the decision-logic level.
- **Phase B (Iteration 004)**: the live Stop-hook navigator across five harnesses (incl. the
  reviewer-runs-in-repo-for-tests execution model) and SC-022.
- **F3/F4 override + run-record trust**: binding obligations on the F-185 wiring PR
  (authenticate + persist the override; SEC-009 invalidation test for forged records).
- **SC-012 maintainer real-host validation**: after Phase B.

## Process notes (honest)

- A review sub-agent polluted the repo early (a stray commit + a local git-config change that
  mis-authored 16 commits as "probe"); detected, the stray commit reset, the config restored,
  and the 16 commits re-authored to the maintainer (history rewrite run by the maintainer).
  Lesson recorded for future review fan-outs.
- The multi-agent design/review workflow repeatedly hit stream-idle timeouts on heavy single
  agents; single `reviewer` Agents and inline empirical validation proved reliable and carried
  the design + review work.

## Claim-ledger honesty

- Proven by runtime evidence: the full suite (176/0), every HOLE-A/B/F1/identity false-allow
  blocking in running code, SC-023, the spawn regression, the producer->gate loop, the
  protected-surface diff.
- NOT claimed: wired advancement enforcement (deferred, decision-logic only); hard secret
  sandboxing (relaxed by trust-boundary decision); the live Stop-hook (Phase B).

## Recommended verdict

**Accept Iteration 003 for review-signoff -> retro.** Phase A delivers the sound,
adversarially-validated content-addressed + anchored gate, the producer, and the gate-keyed
dispatcher in 197-owned non-protected code, with both original false-allows and the
review-found false-allows closed in running code, all governance findings resolved, and the
deferrals explicitly authorized. Verdict names this exact boundary: **review-signoff -> retro**.
