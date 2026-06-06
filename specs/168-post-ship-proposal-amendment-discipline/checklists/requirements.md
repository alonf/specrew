# Requirements Quality Checklist: Post-Ship Proposal Amendment Discipline

**Feature**: file:///C:/Dev/Specrew-post-ship-amendment-discipline/specs/168-post-ship-proposal-amendment-discipline/spec.md
**Created**: 2026-06-06
**Purpose**: Validate that the specify-phase requirements from Proposal 167 are complete enough to enter clarification without fabricating planning decisions or implementation scope.

## Content Quality

- [x] User value and regression risk are clear: shipped proposals must remain historical baselines, and new behavior must be tracked as explicit deltas.
- [x] Requirements are testable and independently reviewable.
- [x] Success criteria are measurable and tied to documentation, validator, reviewer, index/status, and test evidence.
- [x] Scope exclusions are explicit, including no bulk rewrite of historical shipped proposals and no reimplementation of unrelated shipped behavior.
- [x] The spec preserves Proposal 167's warning-level default while marking enforcement severity as a clarification candidate.

## Requirement Completeness

- [x] Functional requirements cover proposal mutability classes, amendment schema, allowed direct edits, delta-based planning, review signoff, closeout evidence, validator warnings, status surfacing, and tests.
- [x] Acceptance scenarios cover shipped/superseded proposal edits, candidate/draft proposal edits, allowed typo/link/errata fixes, valid amendment entries, malformed entries, reviewer checks, and unimplemented amendment surfacing.
- [x] Edge cases cover malformed status, active proposal handling, malformed amendment records, non-semantic rewrites, validator-rule amendments, and prospective-only migration scope.
- [x] Key entities are defined for mutability classes, amendments, normative sections, validator findings, review evidence, and amendment backlog entries.
- [x] Requirements have owner roles and delivery windows.

## Governance Readiness

- [x] The spec remains in `Draft` status and does not claim human approval.
- [x] Human oversight points include the specify boundary and all downstream human-judgment boundaries.
- [x] Drift signals identify mismatches across Proposal 167, spec, docs, validator, reviewer guidance, index/status output, tests, and review evidence.
- [x] Delta-only implementation discipline is explicit and release-blocking for planning and review.

## Clarification Candidates

- [ ] QC-001: Confirm whether shipped/superseded normative edits outside `Post-Ship Amendments` stay as soft warnings for this iteration or become hard validation failures.
- [ ] QC-002: Confirm whether `Post-Ship Amendments` may appear on `active` proposals or whether active proposals should use the normal active-feature amendment mechanism.
- [ ] QC-003: Confirm whether implemented amendments remain only in the original proposal and status/index output, or are also copied into a generated amendment index.
