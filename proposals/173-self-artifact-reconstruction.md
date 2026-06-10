---
proposal: 173
title: Self-Artifact Reconstruction and Provenance Backfill
status: candidate
phase: phase-2
estimated-sp: 5-8
priority-tier: 2
type: documentation-governance-backfill
discussion: surfaced 2026-06-08 after comparing downstream Specrew projects with Specrew's own self-bootstrap history; downstream projects now get iteration-local reviewer artifacts and global architecture/current-state artifacts, while Specrew's earliest features predate those conventions
composes-with:
  - 030  # Form-vs-meaning verification
  - 046  # Auto-render dashboard at closeout
  - 075  # Update artifact backfill discipline
  - 145  # Structured reviewer evidence discipline
  - 167  # Post-ship proposal amendment discipline
audience: maintainers, reviewers, future contributors
---

# Self-Artifact Reconstruction and Provenance Backfill

## Why

New downstream projects created under current Specrew conventions receive a
richer artifact surface than Specrew itself had during its self-bootstrap
period. Iterations now commonly carry review artifacts such as `code-map.md`,
`coverage-evidence.md`, `reviewer-index.md`, `review-diagrams.md`, and
`dependency-report.md`. Features also increasingly carry global or feature-level
architecture artifacts outside a single iteration, such as
`current-architecture.md` or design-analysis outputs.

Specrew did not start life with those rules. Early Specrew features were built
before Specrew could enforce or scaffold its own artifact discipline. The result
is an asymmetric repository: downstream projects look more governed than the
project that defines the governance.

The gap is real, but the fix must not rewrite history. Reconstructed artifacts
can help maintainers understand the current system and important legacy feature
surfaces. They cannot become retroactive proof that an old lifecycle gate
stopped, a human approved, or a reviewer inspected evidence at the time.

## What

Create a governed reconstruction pass for Specrew's own missing artifact
surface, explicitly labeled as reconstruction from repository analysis.

The pass should produce useful current-state documentation and selected
legacy-feature maps while preserving historical truth:

1. Generate one or more repo-level current-state architecture artifacts for
   Specrew itself, covering the runtime architecture, lifecycle artifact model,
   command surfaces, host integrations, release/versioning surfaces, and
   governance validators.
2. Create a reconstruction provenance ledger that records when each artifact was
   generated, which repository evidence was analyzed, and which claims are
   current-state deductions rather than original lifecycle evidence.
3. Inventory legacy features and iterations that predate specific artifact
   conventions, classifying each missing artifact as `not-required-at-the-time`,
   `reconstructable-current-map`, or `do-not-reconstruct-historical-evidence`.
4. Reconstruct only useful architecture/code-map style artifacts for selected
   high-value legacy features. These artifacts must be clearly labeled as
   reconstructed snapshots.
5. Forbid synthetic historical lifecycle artifacts: no retroactive
   `approved`/`accepted` verdicts, no fake review packets, no fabricated retro
   decisions, and no claim that reconstructed files prove a historical gate.

## Acceptance Criteria

- **AC1**: The reconstruction feature creates at least one repo-level
  current-state architecture artifact for Specrew with explicit provenance.
- **AC2**: Every reconstructed artifact includes a standard notice saying it was
  generated after the fact from repository analysis and is not historical gate
  evidence.
- **AC3**: A reconstruction ledger lists generated artifacts, source evidence,
  generation date, and confidence/limitation notes.
- **AC4**: Legacy feature/iteration inventory distinguishes missing-because-
  pre-convention from missing-but-required under current rules.
- **AC5**: The process explicitly rejects backfilling old approval, review,
  retro, or verdict artifacts as if they existed at the time.
- **AC6**: Reviewers get a short rule for treating reconstructed artifacts:
  useful for system understanding, invalid as proof of historical authorization.
- **AC7**: The implementation leaves existing historical artifacts intact unless
  the change is a clearly labeled errata/provenance annotation.

## Out Of Scope

- Running a full design workshop retroactively for old Specrew features.
- Reopening historical feature-closeout decisions.
- Re-scoring old reviews or changing old iteration verdicts.
- Filling every missing artifact in every legacy iteration.
- Treating reconstructed artifacts as evidence for release, beta, or prior gate
  compliance.
- Replacing future normal Specrew artifact generation with reconstruction.

## Implementation Notes

Prefer a small, explicit artifact schema over a broad automated rewrite. A first
slice can be mostly documentation:

- a repo-level architecture snapshot
- a reconstruction ledger
- a legacy-artifact inventory
- one or two high-value feature examples

Good candidate source evidence includes `Specrew.psd1`, command scripts under
`scripts/`, extension scripts under `extensions/specrew-speckit/`, host
manifests under `hosts/`, current specs under `specs/`, and release truth from
`CHANGELOG.md`.

The standard reconstructed-artifact notice should be machine-searchable, for
example:

```text
Reconstruction Notice: This artifact was generated after the fact from repository
analysis. It is useful for current-state understanding and maintenance. It is
not evidence that the original lifecycle gate produced or reviewed this artifact.
```

The proposal should compose with Proposal 075 rather than duplicate it: 075 is
the general update/backfill discipline for missing artifacts; this proposal is
the self-hosted Specrew-specific reconstruction pass and provenance policy.

## Effort

Estimated 5-8 SP:

| Work item | Estimate |
| --- | --- |
| Proposal/spec and artifact policy | 1 SP |
| Repo-level current architecture snapshot | 1.5-2 SP |
| Reconstruction ledger and legacy inventory | 1.5-2 SP |
| Selected feature code-map/current-map examples | 1-2 SP |
| Review rules, lint, and validation | 1 SP |

## Status History

- 2026-06-08: Created from maintainer question about whether Specrew should
  reconstruct its own missing early artifacts by analyzing the current solution.
