# Implementation Plan: Post-Ship Proposal Amendment Discipline

**Branch**: `168-post-ship-proposal-amendment-discipline`
**Date**: 2026-06-06
**Spec**: file:///C:/Dev/Specrew-post-ship-amendment-discipline/specs/168-post-ship-proposal-amendment-discipline/spec.md
**Source Proposal**: file:///C:/Dev/Specrew-post-ship-amendment-discipline/proposals/167-post-ship-proposal-amendment-discipline.md
**Input**: Clarified Feature 168 spec plus human-approved clarify-to-plan instructions.

## Summary

Feature 168 adds post-ship proposal amendment discipline without rewriting or reimplementing shipped proposal behavior. The implementation will document proposal mutability classes, add a structured `Post-Ship Amendments` template, add warning-first validation for shipped and superseded proposal normative edits outside the amendment section, update reviewer guidance for delta-based implementation review, and surface accepted but unimplemented amendments in proposal index/status surfaces.

The implementation is deliberately narrow and fixture-driven. Tests must use synthetic proposal fixtures for shipped/superseded edit detection instead of modifying real shipped proposal bodies. The plan treats the legacy handoff-block validator warning for commit `100bfc83` as out-of-scope validator drift and does not expand this feature to repair it.

## Clarified Decisions

| Question | Human Decision | Planning Effect |
| --- | --- | --- |
| QC-001 | Warning first, not hard failure yet. | Validator findings for shipped/superseded normative edits are warnings in this slice. |
| QC-002 | Active proposals use active-feature amendment flow. | `Post-Ship Amendments` is for shipped and superseded proposals, not active proposals. |
| QC-003 | Implemented amendments remain in the original proposal and are surfaced by index/status. | No generated amendment index is introduced in this slice. |

## State Hygiene

Pre-plan dirty state is recorded at file:///C:/Dev/Specrew-post-ship-amendment-discipline/specs/168-post-ship-proposal-amendment-discipline/state-reconciliation.md and committed as `bf2521f3`.

Plan and later task commits must use path-limited staging. The following paths remain out-of-scope dirty drift unless a future explicit human decision says otherwise:

- file:///C:/Dev/Specrew-post-ship-amendment-discipline/.codex/
- file:///C:/Dev/Specrew-post-ship-amendment-discipline/.github/agents/squad.agent.md
- file:///C:/Dev/Specrew-post-ship-amendment-discipline/.squad/casting/registry.json
- file:///C:/Dev/Specrew-post-ship-amendment-discipline/.squad/config.json
- file:///C:/Dev/Specrew-post-ship-amendment-discipline/specs/140-unix-native-install/iterations/003/tasks-progress.yml
- file:///C:/Dev/Specrew-post-ship-amendment-discipline/.cursor/
- file:///C:/Dev/Specrew-post-ship-amendment-discipline/.specrew/version-check-cache.json

## Delta From Shipped Behavior

This feature is not implementing from a shipped proposal amendment, but it directly governs how future shipped proposal amendments are implemented. Therefore FR-006 and FR-015 are release-blocking planning constraints.

| Release-Blocking Constraint | Plan Requirement | Review Evidence Required |
| --- | --- | --- |
| FR-006 | Any future task that references a shipped proposal amendment must state amendment id or superseding proposal, delta from shipped behavior, preserve list, and tests required. | Reviewer must verify the delivered work against the delta, not against the whole shipped proposal body. |
| FR-015 | Feature 168 implementation must not rewrite historical shipped proposal bodies, bulk-migrate existing proposals, or reimplement shipped behavior from prior proposal work. | Review must inspect the git diff and confirm real shipped proposal bodies were not rewritten and prior shipped behavior was not reimplemented. |

Implementation tasks must carry these constraints into task descriptions, test expectations, and review evidence.

## Context Load

| Source | Loaded Context | Planning Effect |
| --- | --- | --- |
| Proposal 167 | Implemented proposals are historical records; new behavior requires delta records; validator should warn. | Add mutability policy, amendment schema, warning-first validator, review checklist, and status surfacing. |
| Clarified spec | Warning-first enforcement, active proposals excluded from post-ship amendment flow, no generated amendment index. | Keep implementation small and avoid new index-generation subsystem. |
| Proposal discipline docs | Existing proposal format, status handling, INDEX maintenance, and reviewer validation rules. | Update existing proposal discipline rather than creating a parallel methodology document. |
| Review instructions | Proposal-touching review already loads proposal discipline and checks lifecycle evidence. | Add delta-based amendment review checks to existing reviewer path. |
| Quality profile resolver | Bounded custom Phase 1 profile with security, robustness, test-integrity, maintainability, and code-quality gates. | Require focused tests, validation evidence, and explicit non-applicable reasoning for retry/concurrency concerns. |
| State reconciliation | Dirty host/runtime files exist before planning. | Use path-limited staging and exclude unrelated dirty drift from plan/task commits. |

## Technical Context

**Language/Version**: PowerShell 7.x, Markdown, JSON/YAML repository state
**Primary Dependencies**: Git, markdownlint, Specrew governance validator, existing proposal docs and reviewer docs
**Storage**: File-based proposal and governance artifacts under `proposals/`, `docs/methodology/`, `extensions/`, `.specify/extensions/`, `tests/`, and `specs/`
**Testing**: Focused PowerShell unit/integration tests, synthetic proposal fixtures, markdownlint, governance validation
**Target Platform**: Specrew repository governance workflows on Windows and cross-host downstream use
**Constraints**: Warning-first validation, fixture-driven tests, no real shipped proposal body rewrites, no generated amendment index, no fix for the legacy handoff-block warning in this feature

## Phase 1 Quality Planning

**Phase Scope**: `phase-1-first-slice`
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`
**Selected Composition**: Bounded custom composition

### Stack Surfaces in Scope

| Stack Surface | Path Globs | Recognized Stack | Matched Signals |
| --- | --- | --- | --- |
| `proposal-methodology-docs` | `docs/methodology/proposal-discipline.md`, `docs/methodology/review-instructions.md` | Markdown governance docs | Existing proposal and review discipline |
| `proposal-fixtures` | `tests/**/fixtures/**/proposals/*.md` or equivalent synthetic fixture paths | Markdown fixtures | Fixture-driven validator coverage |
| `governance-validator` | `extensions/specrew-speckit/scripts/validate-governance.ps1`, `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` | PowerShell validator | Existing validation surface |
| `proposal-status-surfaces` | `proposals/INDEX.md`, `scripts/specrew-where.ps1`, status rendering docs if applicable | Markdown/PowerShell status output | Existing proposal/status surfaces |
| `reviewer-guidance` | `docs/methodology/review-instructions.md`, reviewer artifact templates if needed | Markdown review discipline | Existing review signoff path |

### Risk Dimensions

| Risk Dimension | Status | Rationale |
| --- | --- | --- |
| `code-quality` | required | Validator and status-surface changes must be narrow, deterministic, and reviewable. |
| `design-quality-and-separation-of-concerns` | required | Amendment parsing, diff classification, docs, and status rendering must not become tangled. |
| `verification-confidence` | required | Synthetic fixtures must prove unsafe edits, allowed edits, malformed records, and status surfacing. |
| `maintainability` | required | Proposal discipline should remain understandable to maintainers without a generated index subsystem. |
| `security` | required | Governance validation is authorization-adjacent; warnings must not fabricate implementation ownership or approval. |
| `robustness` | required | Malformed front matter and malformed amendment records need clear findings rather than silent success. |
| `concurrency-correctness` | not-applicable | This feature does not introduce shared-state concurrency behavior. |
| `retry-idempotency-and-recovery` | not-applicable | There is no retry workflow; idempotency concern is limited to deterministic validation output. |

### Quality Tool Bundle

| Area | Selection |
| --- | --- |
| Bundle ID | `phase1-custom-quality-bundle` |
| Mechanical Checks | dead-field, anti-pattern, test-integrity |
| Ecosystem Tools | markdownlint, focused PowerShell tests, governance validator |
| Manual Evidence | plan quality sections, review gap ledger, code-map and coverage evidence at review |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source |
| --- | --- | --- |
| `dead-field` | mechanical | `specs/168-post-ship-proposal-amendment-discipline/iterations/001/quality/mechanical-findings.json` |
| `anti-pattern` | mechanical | `specs/168-post-ship-proposal-amendment-discipline/iterations/001/quality/mechanical-findings.json` |
| `test-integrity` | mechanical | `specs/168-post-ship-proposal-amendment-discipline/iterations/001/quality/mechanical-findings.json` |
| `stack-tooling-evidence` | tooling | `specs/168-post-ship-proposal-amendment-discipline/iterations/001/quality/quality-evidence.md` |
| `quality-lens-review` | manual evidence | `specs/168-post-ship-proposal-amendment-discipline/iterations/001/quality/quality-evidence.md` |

### Phase 2 Hardening Planning

Phase 2 hardening gate planning remains required before implementation. The before-implement package must include:

- Security surface analysis for proposal parsing and validator warnings.
- Error-handling expectations for malformed front matter and malformed amendment records.
- Explicit non-applicable rationale for retry/idempotency beyond deterministic output.
- Test-integrity targets for positive and negative fixture coverage.

## Expected Implementation Surfaces

| Surface | Planned Change | Scope Control |
| --- | --- | --- |
| `docs/methodology/proposal-discipline.md` | Add mutability classes, amendment template, allowed direct edits, and active-proposal rule. | Documentation-only policy update; no historical proposal rewrite. |
| `docs/methodology/review-instructions.md` | Add proposal-review checks for amendment id, preserve list, tests required, and no unrelated shipped-scope reimplementation. | Review guidance only; no broad review-method rewrite. |
| `extensions/specrew-speckit/scripts/validate-governance.ps1` and mirror | Add warning-first shipped/superseded normative edit detection and malformed amendment finding. | Lightweight structural detection; no full semantic diffing. |
| `tests/unit/` or `tests/integration/` | Add focused tests and synthetic proposal fixtures. | Use fixtures, not real shipped proposal body rewrites. |
| `proposals/INDEX.md` or existing status renderer | Surface accepted-unimplemented post-ship amendments where proposal status is shown. | Human-maintained status surfacing only; no generated amendment index. |

If implementation discovery finds an existing narrower proposal-status renderer, tasks should target that renderer instead of adding a new one.

## Implementation Strategy

1. Update proposal discipline documentation with the six mutability classes and structured amendment template.
2. Add review guidance requiring delta-based review evidence for shipped-proposal amendment work.
3. Implement a small proposal front matter and amendment-section reader, preferably inside the existing validator path or a local helper used only by the validator.
4. Add warning-first validator findings for shipped/superseded normative section edits outside `Post-Ship Amendments`.
5. Add a separate malformed-amendment finding for missing required fields or invalid statuses.
6. Add index/status surfacing for `accepted-unimplemented` and `active` post-ship amendments without introducing a generated amendment index.
7. Add fixture-driven tests for unsafe edits, allowed edits, malformed records, active proposal exclusion, and status surfacing.
8. Preserve mirror parity where this repository convention requires both `extensions/` and `.specify/extensions/` copies.

## FR Traceability Matrix

| Requirement | Implementation Surface | Planned Tests / Evidence |
| --- | --- | --- |
| FR-001 | Proposal discipline docs | Markdown review and doc lint |
| FR-002 | Proposal discipline docs and amendment parser | Template assertion includes all required fields |
| FR-003 | Proposal discipline docs and validator status enum | Fixture with invalid status emits malformed-amendment finding |
| FR-004 | Proposal discipline docs and validator warning | Shipped body-edit fixture emits warning; allowed correction fixture does not |
| FR-005 | Proposal discipline docs and review guidance | Reviewer guidance includes new/superseding proposal default for behavior changes |
| FR-006 | Plan, task text, and review evidence requirements | Tasks must include delta-from-shipped-behavior checks; review gap ledger verifies |
| FR-007 | Review instructions and reviewer artifact expectations | Reviewer checklist/guidance test or textual assertion |
| FR-008 | Review instructions and review artifact template if needed | Review evidence must cite amendment id and preserve list |
| FR-009 | Closeout evidence requirements | Tasks include closeout amendment disposition evidence |
| FR-010 | Governance validator | Shipped/superseded normative edit fixture emits warning |
| FR-011 | Governance validator | Allowed correction, candidate, draft, and valid amendment fixtures do not warn |
| FR-012 | Governance validator | Malformed amendment fixture emits separate finding |
| FR-013 | Proposal index/status surface | Fixture/status test shows `A1 accepted-unimplemented` |
| FR-014 | Test suite | Focused unit/integration tests named in task plan |
| FR-015 | Plan, tasks, implementation review | Git diff review confirms no real shipped proposal body rewrite or reimplementation |
| TG-005 | Plan and tasks | Every implementation task includes delta-only scope note where relevant |
| TG-006 | Review artifact | Gap ledger marks documented, implemented, enforced, observable, and tested |
| TG-007 | Review artifact | Any shipped proposal touch records allowed reason and preservation evidence |

## Test Plan

| Test Area | Positive Coverage | Negative Coverage |
| --- | --- | --- |
| Mutability classes | Docs list candidate, draft, active, shipped, superseded, withdrawn. | Missing status or unknown status produces a clear validator status finding. |
| Amendment schema | Valid shipped proposal amendment with all fields parses cleanly. | Missing field or invalid amendment status emits malformed-amendment finding. |
| Unsafe shipped edits | Shipped/superseded normative body edit outside amendments emits warning. | Candidate/draft body edits do not emit shipped-edit warning. |
| Allowed corrections | Typo/link/errata/supersession-only fixtures do not warn. | Behavior-changing body edit does warn. |
| Active proposal rule | Active proposal fixture follows active-feature amendment handling and does not use post-ship warning path. | Active proposal using post-ship amendment section is not treated as shipped/superseded amendment enforcement. |
| Review guidance | Reviewer guidance requires amendment id, preserve list, tests required, and no unrelated reimplementation. | Review guidance lacking delta-based check fails textual assertion if a test is added. |
| Status surfacing | Proposal status/index output shows `A1 accepted-unimplemented`. | Implemented, rejected, or superseded-only amendments do not appear as unimplemented backlog. |
| Delta-only guardrail | Review confirms real shipped proposal bodies were untouched or only allowed corrections. | Any unrelated shipped proposal body rewrite blocks review. |

Expected commands during implementation and review:

```powershell
npx markdownlint-cli docs/methodology/proposal-discipline.md docs/methodology/review-instructions.md
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\unit\post-ship-proposal-amendment-discipline.tests.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\validate-governance-changed-only.tests.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\.specify\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

Exact test file names may be adjusted during tasking if the existing test suite has a narrower home for the validator and status assertions.

## Review Output Requirements

Review must include a gap ledger for post-ship amendment discipline:

| Dimension | Required Review Question |
| --- | --- |
| Documented | Do docs explain mutability classes, amendment schema, active-proposal rule, and allowed direct edits? |
| Implemented | Does validator/status/reviewer behavior implement only the approved delta? |
| Enforced | Does validation warn for unsafe shipped/superseded edits and separate malformed amendments? |
| Observable | Are unimplemented amendments visible in index/status output and review evidence? |
| Tested | Do synthetic fixtures cover positive, negative, malformed, and no-false-positive paths? |

Review must reject the implementation if the git diff rewrites historical shipped proposal bodies, bulk-migrates existing proposals, reimplements shipped behavior, or hides any known gap without explicit human-approved deferral.

## Project Structure

### Planning Artifacts

```text
specs/168-post-ship-proposal-amendment-discipline/
├── spec.md
├── plan.md
├── data-model.md
├── quickstart.md
├── review-diagrams.md
├── state-reconciliation.md
└── contracts/
    └── post-ship-proposal-amendment-discipline.md
```

### Expected Implementation Surfaces

```text
docs/methodology/
├── proposal-discipline.md
└── review-instructions.md

extensions/specrew-speckit/scripts/
└── validate-governance.ps1

.specify/extensions/specrew-speckit/scripts/
└── validate-governance.ps1

tests/
├── unit/
└── integration/
```

## Complexity Tracking

No constitutional violations are planned. Complexity is controlled by warning-first enforcement, synthetic fixtures, reuse of existing docs/validator/status surfaces, and explicit exclusion of generated amendment-index work.

## Out of Scope

- Rewriting historical shipped proposal bodies.
- Bulk-migrating existing proposals into the new amendment format.
- Reimplementing shipped behavior from prior proposals.
- Hard-failing shipped/superseded normative edits in this slice.
- Allowing `Post-Ship Amendments` on active proposals.
- Creating a generated amendment index.
- Full semantic diffing of proposal meaning.
- Fixing the legacy handoff-block validator warning for commit `100bfc83`.
