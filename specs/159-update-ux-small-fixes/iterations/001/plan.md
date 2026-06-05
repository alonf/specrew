# Iteration Plan: 001

**Schema**: v1  
**Spec**: [../../spec.md](../../spec.md)  
**Status**: planning  
**Capacity**: 6/20 story_points  
**Started**: 2026-06-06  
**Completed**:

## Scope Summary

Iteration 001 implements Proposal 159 Tier 1 only: `specrew update` refuses to mutate a newer-baseline project when run from an older Specrew module/source tree, and active generated/routine UX stops presenting `0.24.0` as a current minimum compatibility baseline.

No Tier 2 self-update, no Proposal 160 resolver/sidecar files, no Feature 141 design-lens intake work, no release publishing, and no stable tag work are in scope.

## Requirements in Scope

| Requirement | Summary | Stories |
| --- | --- | --- |
| FR-001 | Read running Specrew version and target project `specrew_version` before mutating update actions. | US1, US2 |
| FR-002 | Refuse all mutating update scopes when running Specrew is older than the project baseline, before protected-surface mutation. | US1 |
| FR-003 | Refusal output names remediation via `Update-Module Specrew` and `SPECREW_MODULE_PATH`. | US1 |
| FR-004 | Equal/newer running module behavior remains unchanged. | US2 |
| FR-005 | `specrew update --info` remains read-only. | US2 |
| FR-006 | Active generated governance, active skill templates, and routine version/update UX do not present `0.24.0` as current baseline. | US3 |
| FR-007 | Historical `0.24.0` release records remain intact. | US3 |
| FR-008 | Tests cover downgrade refusal, no-mutation proof, equal/newer no-regression, and active-message cleanup. | US1, US2, US3 |
| FR-009 | Feature 141 and Proposal 160 surfaces remain out of scope unless an unavoidable shared active-governance line is explicitly justified. | US1, US3 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T001 | Add stale-module preflight decision in `scripts/specrew-update.ps1` before any mutating action; skip refusal for `--info`; fail closed for older running module or unparsable present baseline; continue absent/equal/newer behavior. | FR-001, FR-002, FR-004, FR-005, SC-001, SC-003 | US1, US2 | 1.5 | Implementer | `scripts/specrew-update.ps1` | planned | codex | | |
| T002 | Add actionable refusal output and non-zero exit semantics naming running/project versions plus `Update-Module Specrew` and `SPECREW_MODULE_PATH` remediation. | FR-002, FR-003, SC-001, SC-002 | US1 | 0.5 | Implementer | `scripts/specrew-update.ps1` | planned | codex | | |
| T003 | Extend update-command regression coverage with deterministic protected-surface snapshots/hashes and equal/newer no-regression cases. | FR-001, FR-002, FR-004, FR-005, FR-008, SC-001, SC-003 | US1, US2 | 1.5 | Reviewer | `tests/integration/update-command.ps1` | planned | codex | | |
| T004 | Clean active `0.24.0` compatibility-baseline wording in canonical active sources first; generated active surfaces are allowed only if parity/tests require them and only for stale wording. | FR-006, FR-007, FR-009, SC-004, SC-006 | US3 | 1 | Spec Steward | `scripts/specrew-version.ps1`, `scripts/internal/version-check.ps1`, `extensions/specrew-speckit/squad-templates/**`, `.github/agents/squad.agent.md` | planned | codex | | |
| T005 | Update compatibility-message tests and active-message scan coverage with `Select-String` fallback when `rg` is unavailable. | FR-006, FR-008, SC-004 | US3 | 1 | Reviewer | `tests/integration/slash-command-compatibility.tests.ps1`, `tests/**` | planned | codex | | |
| T006 | Produce Proposal 145 review-signoff evidence: branch hygiene, functional/NFR/code/test/scope review, Feature 141 and Proposal 160 collision check, claim ledger, and gap ledger. | FR-008, FR-009, TG-005, SC-005, SC-006 | US1, US2, US3 | 0.5 | Reviewer | `specs/159-update-ux-small-fixes/iterations/001/**` | planned | codex | | |

## Before-Implement Controls

### Protected-Surface Snapshot Set

T003 must hash or otherwise deterministically snapshot this exact protected set before and after stale-module refusal:

- `.specrew/config.yml`
- `.specify/extensions/**`
- `.squad/**`
- `.claude/skills/**`
- `.github/skills/**`
- `.agents/skills/**`
- `.cursor/rules/**` when present
- `.github/agents/**` generated runtime/agent surfaces when touched by update logic
- `.codex/agents/**` generated runtime/agent surfaces when present and touched by update logic
- generated template/runtime assets under `.github/workflows/**`, `.github/prompts/**`, `.specify/templates/**`, and any other path returned by the update command's template refresh mapping

The test must compare the before/after snapshot, not just `git status`.

### Generated Active Surface Rule

T004 must prefer canonical source/template changes. Generated active surfaces such as `.github/agents/squad.agent.md` may be touched later only when parity or tests require it; the change must record the reason and must be limited to stale `0.24.0` compatibility wording. Do not carry unrelated six-section packet or broad governance drift into Feature 159.

### Collision Check

Before implementation approval and again at review-signoff, run a changed-file collision check against:

- Feature 141 design-lens intake/runtime surfaces
- Proposal 160 resolver and managed-skill sidecar surfaces
- Existing stashes from this branch

The existing stashes must remain unapplied and outside Feature 159.

Before-implement check on 2026-06-06 found only `.specify/feature.json` overlap with Feature 141 and no Proposal 160 overlap in current Feature 159 changed files. Feature 141 already changes `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`; T004 may touch that file only for unavoidable stale `0.24.0` active-governance wording, with the reason recorded and the diff limited to that wording.

## Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Planned Status |
| --- | --- | --- | --- |
| `dead-field` | mechanical | `quality/mechanical-findings.json` | planned |
| `anti-pattern` | mechanical | `quality/mechanical-findings.json` | planned |
| `test-integrity` | mechanical | `quality/mechanical-findings.json` | planned |
| `stack-tooling-evidence` | tooling | `quality/quality-evidence.md` | planned |
| `quality-lens-review` | manual-evidence | `quality/quality-evidence.md` and `quality/lenses/**` | planned |

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Planned Effort | 6 | Approved 5 SP implementation scope plus 1 SP review/rework buffer. |
| Iteration Bounding | scope | `scope` keeps requirements fixed. |
| Overcommit Threshold | 1.0 | Warn if planned task effort exceeds 20 story_points. |
| Defer Strategy | manual | No deferrals planned. |

## Concurrency Rationale

- `T001` and `T002` are serial because both touch `scripts/specrew-update.ps1`.
- `T003` depends on `T001/T002`.
- `T004` can run independently from `T001/T002` if confined to canonical active UX surfaces.
- `T005` depends on `T004`.
- `T006` depends on all implementation/test tasks.
- No same-specialty parallel expansion is proposed; the slice is small and touches shared command/governance surfaces.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| --- | --- | --- |
| Planning | complete | Spec, plan, tasks, and before-implement artifacts. |
| Implementation | 3 | T001, T002, T004. |
| Review/Test | 2.5 | T003, T005, T006. |
| Rework | 0.5 | Included in the 1 SP buffer. |

## Traceability Summary

Every FR/SC in scope is covered by at least one task. Every task maps to at least one FR/SC. The after-tasks traceability check passed on 2026-06-06.

## Notes

- Existing stashes are preserved and must not be applied or folded into this branch.
- No implementation code has been written at this boundary.
