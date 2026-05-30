# Review: Iteration 002

**Schema**: v1
**Reviewed**: 2026-05-29
**Overall Verdict**: accepted

> **Provenance (Shape-5 guard):** verdicts backed by tests COMMITTED at `d53f6a4e`,
> run green (real-binary fixtures executed — cursor-agent on PATH). Implementer-coordinator
> self-review; authoritative review-signoff is the independent Reviewer session + human verdict — PENDING.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T011 | FR-005 | pass | Real-`cursor-agent` version-probe fixture added (skip-guarded); executed green on this machine. |
| T012 | FR-006 | pass | `host-cursor-launch.tests.ps1` smoke proves `--host cursor` flows through Get-SpecrewHostLaunchInvocation to the interactive launch argv; real-binary case green. |
| T013 | FR-007 | pass | Explicit cursor detection-matrix + launch-shape assertions in `host-detection-ux.tests.ps1`; green. |

<!--
  Gap Ledger schema (validator-enforced):
    EVERY non-empty line MUST be a bullet entry classified with one of two tokens:
      - "fixed-now"  — the gap was repaired during this iteration
      - "deferred"   — the gap is parked with explicit human approval (the approval
                       reference must be recorded in .squad/decisions.md)
    Free-form intro prose between the heading and the bullets is REJECTED by the
    validator (it scans every non-empty line for a classification token).

  When there are no gaps, write ONE line:
    - "No requirement (FR/SC) gaps: all in-scope requirements verified: fixed-now."
-->

## Gap Ledger

- No requirement (FR/SC) gaps: all in-scope requirements verified: fixed-now.

## Notes

- Iteration 002 is test-only (no production code changed); all 3 tasks (T011-T013) are pass.
- Gap ledger: no requirement gaps. No-gap policy satisfied.
- Drift: 0 events this iteration (contract reconciliation was completed in iter-001).
- **Real-binary fixture provenance**: the `cursor-agent`-dependent assertions in `host-cursor.tests.ps1` (version-probe) and `host-cursor-launch.tests.ps1` (real-path resolution) are **skip-guarded** — they execute only when `cursor-agent` is on PATH. They ran GREEN in the implementing session (cursor-agent v2026.05.28 present) but are NOT guaranteed to be independently reproduced where the binary is absent (CI runners or a reviewer session lacking Cursor), where they cleanly SKIP. The deterministic, binary-independent assertions (interactive argv shape, --force gating, detection-matrix membership) run everywhere.
