---
proposal: 169
title: Retire Top-Level Evaluation Surface
status: shipped
phase: phase-2
estimated-sp: 1-2
priority-tier: 3
type: repo-hygiene
discussion: surfaced 2026-06-06 after maintainer questioned whether the top-level evaluation directory was obsolete
composes-with:
  - 001  # Specrew Product
  - 009  # Project Path Resolution
  - 108  # specrew-init Refactor + Per-Host Crew-Runtime Abstraction
audience: maintainers, contributors
---

# Retire Top-Level Evaluation Surface

## Why

The top-level `evaluation/` directory looked like an old public product surface,
but inspection showed mixed value:

- `evaluation/report.md` was a stale generated artifact.
- `evaluation/README.md` described deferred outcome scoring that never became a
  maintained public workflow.
- `evaluation/scorers/process-scorer.ps1` still had live value because CI
  integration tests use it to validate lifecycle artifact and phase adherence.

Keeping all three under `evaluation/` made the repository harder to read: a user
could reasonably infer that Specrew still ships an evaluation harness, while the
actual maintained behavior is only a deterministic process-quality regression
helper.

## What

Retire `evaluation/` as a top-level public surface while preserving the useful
process-quality scorer as test support.

Implementation shape:

1. Move the process-quality scorer to `tests/support/process-quality-scorer.ps1`.
2. Keep the two existing integration tests as the supported entry points:
   `tests/integration/process-quality-scorer.ps1` and
   `tests/integration/process-quality-report.ps1`.
3. Move default generated report output away from `evaluation/report.md` to
   scratch/test-result space.
4. Delete stale `evaluation/README.md` and `evaluation/report.md`.
5. Update docs, CI-adjacent guidance, portability checks, and path-regression
   scans so no active surface points at `evaluation/`.
6. Preserve historical specs and retros as history; do not rewrite old shipped
   evidence just because the implementation moved.

## Acceptance Criteria

- **AC1**: No tracked top-level `evaluation/` directory remains after cleanup.
- **AC2**: `tests/integration/process-quality-scorer.ps1` still passes.
- **AC3**: `tests/integration/process-quality-report.ps1` still passes and writes
  its generated report outside the deleted top-level surface.
- **AC4**: The multi-host lifecycle smoke test parses the moved scorer and
  preserves the Linux-safe forward-slash path assertion.
- **AC5**: User-facing docs no longer advertise `evaluation/` as a current
  public workflow.
- **AC6**: Maintainer-facing proposal/index surfaces record why the useful code
  was moved rather than deleted.

## Out Of Scope

- Designing the deferred outcome-quality scorer.
- Reworking historical shipped artifacts that mention `evaluation/`.
- Changing CI job names or the process-quality test semantics.
- Creating a new product-facing evaluation command.

## Implementation Notes

This proposal is intentionally a small cleanup slice. The important decision is
classification: the scorer is test infrastructure, not product runtime or a
public evaluation harness. The stale generated report and README can be deleted,
but the scorer remains valuable because it catches lifecycle artifact regressions
in deterministic CI.

## Effort

Estimated 1-2 SP:

| Work item | Estimate |
| --- | --- |
| Move scorer and update test callers | 0.5 SP |
| Delete stale top-level evaluation files | 0.25 SP |
| Update docs, path scans, and portability smoke checks | 0.5 SP |
| Add proposal/index audit trail and run focused tests | 0.25-0.75 SP |

## Status History

- 2026-06-06: Created after maintainer review of the top-level `evaluation/`
  directory. Implemented as a focused cleanup preserving the live scorer under
  `tests/support/` and deleting the stale top-level surface.
