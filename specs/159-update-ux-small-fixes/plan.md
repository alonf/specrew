# Implementation Plan: Specrew Update Downgrade Guard and Compatibility Message Cleanup

**Feature**: 159-update-ux-small-fixes  
**Spec**: ./spec.md  
**Branch**: 159-update-ux-small-fixes  
**Date**: 2026-06-05  
**Status**: Plan ready for human review  
**Iteration**: 001  

## Summary

This slice implements Proposal 159 Tier 1 only. It adds a pre-mutation downgrade guard to
`specrew update` so an older running Specrew module cannot rewrite a newer-baseline project,
and it removes stale `0.24.0` current-baseline wording from active generated governance and
routine version/update UX.

No self-update or child-process re-dispatch is included. No Proposal 160 resolver/sidecar
surface and no Feature 141 design-lens intake surface is intentionally changed.

## Technical Context

| Area | Decision |
| --- | --- |
| Runtime | PowerShell scripts and markdown/generated governance templates |
| Primary script | `scripts/specrew-update.ps1` |
| Version helpers | `scripts/internal/version-check.ps1` and existing semantic-version parsing helpers |
| Active UX surfaces | `scripts/specrew-version.ps1`, `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`, `extensions/specrew-speckit/squad-templates/skills/specrew-version/SKILL.md` |
| Primary tests | `tests/integration/update-command.ps1`, `tests/integration/slash-command-compatibility.tests.ps1`, plus targeted unit/integration additions if needed |
| Dependencies | No new package or module dependencies |

## Requirement Mapping

| Requirement | Planned Approach | Evidence Target |
| --- | --- | --- |
| FR-001 | Read running source/module version and project `specrew_version` before mutating update actions. | Update-command regression test exercises stale/equal/newer setup. |
| FR-002 | Add guard before deploy scripts, template refresh, dependency installs, and config write for any mutating scope. | Stale-module test snapshots protected files before/after and asserts non-zero exit. |
| FR-003 | Emit actionable refusal mentioning `Update-Module Specrew` and `SPECREW_MODULE_PATH`. | Output assertion in stale-module test. |
| FR-004 | Preserve equal/newer behavior by letting the existing update path continue unchanged after the guard passes. | Existing update-command tests plus explicit equal/newer cases. |
| FR-005 | Keep `--info` read-only and skip downgrade refusal mutation path. | Existing info-mode mutation test stays green. |
| FR-006 | Reword active generated/routine `0.24.0` compatibility-baseline messaging. | Compatibility-surface tests assert no active current-baseline `0.24.0` claim. |
| FR-007 | Preserve historical `0.24.0` records. | Changed-file review avoids closed specs/proposals/changelog history. |
| FR-008 | Add regression coverage for downgrade refusal, no-mutation, equal/newer, and active-message cleanup. | Test commands in review evidence. |
| FR-009 | Avoid Feature 141 and Proposal 160 surfaces. | Changed-file collision review and Proposal 145 gap ledger. |

## Architecture

`specrew update` already resolves:

- target project path
- project config map
- running extension/source version
- requested update scopes
- deployment scripts and template refresh entry points

The planned change adds one explicit decision point after argument/config/version resolution and
before any mutating action. For mutating invocations, the guard compares:

- running source Specrew version: `$sourceSpecrewVersion`
- target project baseline: `.specrew/config.yml` `specrew_version`

If project baseline is absent, existing behavior continues. If it is unparsable, the command
fails clearly before mutation. If parsed baseline is greater than the running source version,
the command refuses with a non-zero exit and remediation text.

The guard is intentionally central, not embedded inside each deployment operation, so the
failure path is simple and protected files cannot be partially changed.

## Protected Mutation Boundary

The stale-module guard must run before these operations:

- `.specify/extensions/**` refresh
- `.squad/**` runtime deployment
- host skill/rule deployment via managed runtime refresh
- template refresh
- Spec Kit / Squad dependency installation from `--spec-kit`, `--squad`, or `--all`
- `.specrew/config.yml` write

This means stale running Specrew refuses all mutating scopes, including `--spec-kit` and
`--squad`, because those flows still run from old Specrew command logic against a newer project.

## Compatibility Messaging Cleanup

Active current-baseline wording should be removed or reworded from:

- `scripts/specrew-version.ps1` help/report copy
- `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`
- `extensions/specrew-speckit/squad-templates/skills/specrew-version/SKILL.md`
- tests that assert `0.24.0` as an active current baseline

Historical references stay intact in proposals, closed specs, changelog entries, migration
contracts, and release records.

## Testing Strategy

| Test Area | Planned Command |
| --- | --- |
| Update command regression | `pwsh -File tests/integration/update-command.ps1` |
| Slash/version compatibility messaging | `pwsh -File tests/integration/slash-command-compatibility.tests.ps1` |
| Targeted grep/static check | `rg -n "0\\.24\\.0|pre-v0\\.24\\.0|minimum compatibility is Specrew" scripts extensions tests` with expected active allowlist |
| Governance validation | `pwsh -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .` |

If implementation changes a helper that can be unit-tested without full bootstrap cost, add a
targeted unit test or library seam. Otherwise extend the existing update-command integration
test because it already bootstraps a project and verifies mutation behavior.

## Phase 1 Quality Planning

**Resolved profile**: `quality-profile.custom-composition.v1`  
**Resolution mode**: bounded custom composition  
**Lens refs**: `security-baseline@v1.0.0`, `robustness-baseline@v1.0.0`, `test-integrity@v1.0.0`

| Risk Dimension | Status | Planning Response |
| --- | --- | --- |
| Code quality | required | Keep the guard small, central, and helper-backed if needed. Avoid scattered checks. |
| Design quality and separation of concerns | required | Separate version comparison/refusal semantics from deployment operations. |
| Verification confidence | required | Snapshot protected files before stale refusal and prove byte-for-byte no mutation. |
| Maintainability | required | Reuse existing version parsing/helpers and update the existing regression suites. |
| Security | required | Treat stale-module downgrade as a project integrity/supply-chain safety failure. |
| Robustness | required | Fail closed for older or unparsable project baseline before mutation. |

### Required Quality Gates

| Gate | Category | Evidence Source |
| --- | --- | --- |
| dead-field | mechanical | `specs/159-update-ux-small-fixes/iterations/001/quality/mechanical-findings.json` |
| anti-pattern | mechanical | `specs/159-update-ux-small-fixes/iterations/001/quality/mechanical-findings.json` |
| test-integrity | mechanical | `specs/159-update-ux-small-fixes/iterations/001/quality/mechanical-findings.json` |
| stack-tooling-evidence | tooling | `specs/159-update-ux-small-fixes/iterations/001/quality/quality-evidence.md` |
| quality-lens-review | manual-evidence | `specs/159-update-ux-small-fixes/iterations/001/quality/quality-evidence.md` |

## Phase 2 Hardening Planning

The before-implement hardening gate must explicitly cover:

- stale-module refusal before mutation
- fail-closed behavior for unparsable project baseline
- remediation text accuracy
- no-mutation proof for protected assets
- test integrity of downgrade and equal/newer cases
- active/historical `0.24.0` distinction
- collision review against Feature 141 and Proposal 160 surfaces

No human-approved hardening deferrals are planned at this boundary.

## Proposal 145 Review Plan

At review-signoff, the reviewer must produce evidence for:

- Phase 1 branch hygiene: HEAD pushed, worktree state classified, cited evidence committed.
- Phase 2 functional correctness: stale refusal, no mutation, equal/newer pass-through.
- Phase 3 non-functional review: project integrity, failure semantics, no hidden network/dependency change.
- Phase 4 code quality: small central guard, clear helper naming, no broad catch-and-ignore.
- Phase 5 test integrity: negative path asserts exit code, output, and file snapshots; equal/newer no-regression.
- Phase 6 system safety/collision: no Feature 141/Proposal 160 changes.
- Claim ledger: every review claim maps to changed files, test commands, or explicit no-change evidence.

## Data and State

No persisted application data is introduced. The feature reads and preserves project state:

- `.specrew/config.yml`
- `.specify/extensions/specrew-speckit/**`
- `.squad/**`
- generated host skill/runtime assets

The only intended persistent changes after implementation are source/test/template files in the
Specrew repository, plus later generated artifacts produced by lifecycle review.

## Risks

| Risk | Mitigation |
| --- | --- |
| Guard runs too late and allows partial mutation | Place the guard before any mutating operation and prove no-mutation with snapshots. |
| `--spec-kit` / `--squad` behavior unexpectedly changes | Plan explicitly scopes stale refusal to all mutating scopes; equal/newer tests protect normal behavior. |
| `0.24.0` cleanup rewrites history | Limit changes to active generated/routine UX; use changed-file review to keep history untouched. |
| Parallel work collision | Avoid `.github/agents/squad.agent.md` unless needed for active-message cleanup, and avoid Proposal 160 path-resolver files entirely. |

## Planned Iteration

Iteration 001 is sized at 5 story points with a 1 story point buffer:

| Work Item | Estimate |
| --- | --- |
| Downgrade guard implementation | 2 SP |
| Refusal/no-mutation/equal-newer tests | 2 SP |
| Active `0.24.0` messaging cleanup and tests | 1 SP |
| Buffer | 1 SP |

Tasks will be decomposed in `tasks.md` after human approval of this plan boundary.
