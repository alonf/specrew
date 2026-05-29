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

- This artifact was scaffolded from plan.md for the Review/Demo ceremony.
- Replace default verdicts in the Task Verdicts table with the actual per-task review outcome (valid values: pass | 
eeds-work | locked) before closing the review phase.
- Set Overall Verdict (in the metadata above) to ccepted only when every task is pass and every Gap Ledger entry is ixed-now (or deferred with an approval ref in .squad/decisions.md). Otherwise 
eeds-rework or locked.
- Use the no-gap policy: known gaps must be fixed now or explicitly deferred with approval and recorded evidence before closure.
- If per-task drift checks did not run during execution, invoke specrew-drift-check in batch and update drift-log.md before accepting the iteration.