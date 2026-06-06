# Tasks: Specrew Update Downgrade Guard and Compatibility Message Cleanup

**Feature**: 159-update-ux-small-fixes  
**Spec**: ./spec.md  
**Plan**: ./plan.md  
**Date**: 2026-06-06  
**Status**: Ready for before-implement approval  

Effort unit: story points. Iteration cap: 20 SP. This feature is a single small-fix
iteration with 5 planned SP and 1 SP buffer. No implementation code is written by this
tasks boundary.

## Human Instructions Carried Into Tasks

- The stale-module no-mutation test MUST use a deterministic before/after snapshot or hash of
  protected surfaces, not only `git status`.
- Protected surfaces for stale refusal are `.specrew/config.yml`, `.specify/extensions/**`,
  `.squad/**`, host skill roots, and generated runtime assets.
- The `0.24.0` cleanup MUST prefer canonical source/template changes first. Generated active
  surfaces such as `.github/agents/squad.agent.md` may be edited only if parity or tests require
  it, and then only for stale compatibility wording.
- Active-message scan tests MUST work without `rg`; use a PowerShell `Select-String` fallback
  when `rg` is unavailable.
- Proposal 160 resolver files and Feature 141 design-lens intake files stay out of scope unless a
  task explicitly identifies an unavoidable shared active-governance line and records why.

## Iteration 001 - Tier 1 Guard + Active Message Cleanup (6/20 SP)

| ID | Task | FR / SC | Story | SP | Owner | Dependencies | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T001 | Add the stale-module preflight decision to `scripts/specrew-update.ps1`: after parsing project/config/version/scope and before any mutating operation, compare the running Specrew version to project `.specrew/config.yml` `specrew_version`; skip refusal for `--info`; fail closed for an older running module or unparsable present baseline; continue existing behavior for absent baseline, equal baseline, or newer running module. | FR-001, FR-002, FR-004, FR-005, SC-001, SC-003 | US1, US2 | 1.5 | Implementer | — | planned |
| T002 | Add actionable refusal output and failure semantics: stale refusal exits non-zero, names installed/running version and project baseline, and tells the user to run `Update-Module Specrew` or set `SPECREW_MODULE_PATH` to a matching dev tree before retrying. | FR-002, FR-003, SC-001, SC-002 | US1 | 0.5 | Implementer | T001 | planned |
| T003 | Extend update-command regression coverage with deterministic protected-surface snapshots/hashes: prove stale refusal leaves `.specrew/config.yml`, `.specify/extensions/**`, `.squad/**`, host skill roots, and generated runtime assets unchanged; also prove equal and newer running-module scenarios preserve existing update behavior. | FR-001, FR-002, FR-004, FR-005, FR-008, SC-001, SC-003 | US1, US2 | 1.5 | Reviewer | T001, T002 | planned |
| T004 | Clean active `0.24.0` compatibility-baseline wording in canonical active sources first: `scripts/specrew-version.ps1`, `scripts/internal/version-check.ps1` only if needed for current user-facing output, `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`, and `extensions/specrew-speckit/squad-templates/skills/specrew-version/SKILL.md`; preserve historical records. Generated active surfaces such as `.github/agents/squad.agent.md` are allowed only if parity/tests require them and only for this stale wording. | FR-006, FR-007, FR-009, SC-004, SC-006 | US3 | 1 | Spec Steward | — | planned |
| T005 | Update compatibility-message tests and active-message scan coverage: revise tests that currently assert `0.24.0` as an active current baseline, verify routine `specrew version` help/report and generated active templates no longer present old-baseline noise, and implement a `Select-String` fallback when `rg` is unavailable. | FR-006, FR-008, SC-004 | US3 | 1 | Reviewer | T004 | planned |
| T006 | Record review-signoff evidence using Proposal 145 discipline: branch hygiene, functional correctness, NFR/project-integrity review, code quality, test integrity, collision/scope review against Feature 141 and Proposal 160, claim-to-evidence ledger, and explicit gap ledger. | FR-008, FR-009, TG-005, SC-005, SC-006 | US1, US2, US3 | 0.5 | Reviewer | T001-T005 | planned |

**Planned SP**: 6/20 SP, matching the approved 5 SP implementation scope plus 1 SP review/rework buffer.

## Execution Notes

- T001/T002 should be implemented in one focused pass over `scripts/specrew-update.ps1`.
- T003 should extend `tests/integration/update-command.ps1` unless implementation exposes a smaller helper that deserves a unit test.
- T004 must avoid closed specs/proposals/changelog history.
- T005 must not assume `rg` exists; use `Get-Command rg -ErrorAction SilentlyContinue` and otherwise run `Get-ChildItem` plus `Select-String` over active paths.
- T006 review should classify every material requirement as implemented, enforced, observable, and documented.

## Traceability Matrix

| Requirement / Success Criterion | Covered by |
| --- | --- |
| FR-001 | T001, T003 |
| FR-002 | T001, T002, T003 |
| FR-003 | T002, T003 |
| FR-004 | T001, T003 |
| FR-005 | T001, T003 |
| FR-006 | T004, T005 |
| FR-007 | T004 |
| FR-008 | T003, T005, T006 |
| FR-009 | T004, T006 |
| TG-001 | T006 |
| TG-002 | T006 |
| TG-003 | T006 |
| TG-004 | T006 |
| TG-005 | T006 |
| SC-001 | T001, T002, T003 |
| SC-002 | T002, T003 |
| SC-003 | T001, T003 |
| SC-004 | T004, T005 |
| SC-005 | T006 |
| SC-006 | T004, T006 |

## After-Tasks Traceability Check

**Checked**: 2026-06-06  
**Verdict**: PASS  
**Coverage**: 15/15 FR/SC references covered by 6 tasks.  
**Findings**: No orphan tasks, invalid FR/SC references, uncovered FR/SC references, or missing task owner/effort/story metadata.

## Out of Scope

- Proposal 159 Tier 2 self-update / child-process re-dispatch.
- Proposal 160 resolver and managed-skill sidecar files.
- Feature 141 design-lens intake/runtime work.
- Release promotion, beta publish, or stable tag operations.
