# Iteration 003 Closeout Validation (Phase A — Always-On Gate Re-Architecture)

**Feature**: 197-continuous-co-review
**Iteration**: 003
**Validated**: 2026-06-20
**Task**: T064

## Test evidence (runtime, not file-presence)

- **Full `tests/continuous-co-review` suite: 173 passed, 0 failed** (run per-file in fresh
  `pwsh` processes with a short-path-free `$env:TEMP`, the local Pester 3.4 workaround).
- **HOLE A (gitignored-source blindness) BLOCKS**: `reviewed-state-digest.Tests.ps1` proves a
  gitignored-source change flips the content-addressed tree-id; `review-signoff-evidence-gate.Tests.ps1`
  proves the gate returns `stale-co-review-evidence` on that drift. The F1 adversarial regression
  proves source named like a secret (`credentials.ts`) stays in the identity and its drift flips it.
- **HOLE B (unanchored operator baseline) BLOCKS**: the gate returns `coverage-gap` when a pass
  does not chain to the merge-base anchor; `producer-gate-loop.Tests.ps1` proves a signoff run
  auto-anchors to the merge-base, records `reviewed_tree_id`, the gate ALLOWS the matching state
  and BLOCKS on drift.
- **SC-023 zero-spawn**: `gate-review-dispatcher.Tests.ps1` + `gate-dispatch-run.Tests.ps1` prove
  unregistered stages (plan/tasks/spec/design-lens) and casual yields run NO reviewer and write no
  evidence; a registered implement checkpoint runs the orchestrator.
- **Spawn robustness (NFR-001)**: `reviewer-spawn-timeout.Tests.ps1` proves a stalled large-stdin
  child is timed out (not hung) and its process tree killed (no orphan).
- **Fail-closed**: the gate blocks on digest failure, anchor-unresolvable, empty-tree, malformed,
  and git errors; no fail-open path (confirmed by the adversarial re-review and tests).

## Protected-surface evidence (SC-006)

- `tests/continuous-co-review/governance/protected-surface-guard.Tests.ps1`: **1/1 pass**.
- The iteration's actual changed files (`git diff --name-only a8647528..HEAD`) touch only
  `scripts/internal/continuous-co-review/`, the 197-owned `scripts/specrew-review.ps1`,
  `specs/197-continuous-co-review/`, and `tests/`. **No F-184 protected surface is edited.**
  (A naive `main...HEAD` diff shows F-184 files only because the local `main` ref is stale; the
  session-base diff is authoritative.)
- The gate's WIRING into `Invoke-SpecrewBoundaryStateSync` remains deferred until the F-185
  host-neutral gate-enforcement branch merges, by design.

## Traceability (task -> requirement)

| Task | Requirement | Evidence |
| ---- | ----------- | -------- |
| T058 | FR-027 | reviewed_ref/rebaseline; resolver + rebaseline tests |
| T065 | FR-025, SEC-002 | content-addressed digest; 9/9 incl. F1 regression |
| T066 | FR-025, FR-027 | reviewed_tree_id + git-lineage/anchor resolver; 6/6 |
| T067 | FR-025, SC-019, SC-020 | re-architected gate; 9/9 (HOLE A/B block) |
| T068 | FR-025, FR-027, INT-004 | producer auto-anchor + digest; producer-gate-loop |
| T069 | FR-025, NFR-001 | retire dead full-diff; diff-provider 6/6 |
| T059/T060 | FR-032, SC-023, FR-024 | dispatcher + registry + wiring; 6/6 + 2/2 |
| T062 | FR-028, FR-029, NFR-005, SEC-004 | one-time auth + escalation; 3/3 + 3/3 |
| T063 | NFR-001, INT-004 | spawn-timeout/orphan regression; 2/2 |

## Carried (advisory, not blocking signoff)

- F3/F4 (adversarial re-review): override + run-record trust boundary -> bound to the deferred
  F-185 wiring (authenticate + persist; binding comment in the gate).
- The maintainer-run real-host validation (SC-012-class) and the live Stop-hook trigger remain
  Iteration 004 (Phase B).

## Outcome

Phase A is implementation-complete and adversarially validated: the sound content-addressed +
anchored gate, the producer that feeds it, and the gate-keyed dispatcher are all green, with both
original false-allows (HOLE A/B) and the adversarial F1 false-allow closed in running code, and no
F-184 protected-surface edits. Ready for the Proposal 145 review.
