# Review: Iteration 001

**Schema**: v1
**Reviewed**: 2026-05-24 (retroactive backfill of 2026-05-24 implementation)
**Overall Verdict**: accepted

**Feature**: F-043 Multi-Host Onboarding + Selection Flow

## Outcome Summary

**APPROVED with deferred scope** — 9 of 13 FRs shipped and verified; 4 FRs (Category A coordinator-content migration) deferred to a follow-up slice with explicit rationale in [`scope.md`](./scope.md).

Verification evidence: integration tests pass against the host-selection chain; manual exercise via `specrew host list/use/status` confirms CLI surface works end-to-end against all 3 supported runtime hosts (Copilot, Claude, Codex).

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | (intake) | pass | Spec + plan boundary artifacts committed at `487c653f`. |
| T002 | FR-001, FR-003 | pass | host-history schema + draft helpers (`d9868035`); JSON instead of YAML per Drift #1. |
| T003 | FR-005, FR-006, FR-007 | pass | `specrew host` CLI surface (`39b4e48d`); all 3 subcommands work end-to-end. |
| T004 | FR-004 | pass | `Update-SpecrewHostHistory` persists on every selection. |
| T005 | FR-002, FR-012, FR-013 | pass | Host-selection priority chain wired in `specrew-start.ps1` (`755c87f1`); A-1 bug introduced and fixed in F-044 iter-002 cross-feature (Drift #4). |

## Gap Ledger

- No in-scope requirement (FR/SC) gaps: all 9 in-scope FRs (FR-001..007, FR-012, FR-013) verified: fixed-now. FR-008/009/010/011 were explicit out-of-scope scope cuts at spec time, not iteration gaps — documented in [`scope.md`](./scope.md) and queued as a follow-up small-fix slice; not Gap-Ledger-tracked.

## Acceptance criteria

| AC source | FR | Verification | Status |
|---|---|---|---|
| AC1 | FR-001 (host-history schema) | `host-history.json` written on first start; schema_version + last_selected_host + hosts map present | PASS |
| AC2 | FR-002 (selection priority chain) | Verified: `--host` flag wins; in absence, history wins; in absence of both, first-run probe fires; non-TTY non-zero exit honored | PASS |
| AC3 | FR-003 (first-run probe) | `Invoke-SpecrewFirstRunHostProbe` enumerates `Get-SpecrewSupportedHostKinds`; deferred hosts excluded | PASS |
| AC4 | FR-004 (history update on every selection) | `Update-SpecrewHostHistory` called from `Save-StartArtifacts`; `last_used_at` + `first_used_at` populated | PASS |
| AC5 | FR-005 (`specrew host list`) | Output shows hosts + on-PATH availability + currently-selected marker; deferred hosts listed with their reason | PASS |
| AC6 | FR-006 (`specrew host use`) | Validates kind via registry; persists to `host-history.json`; does NOT launch | PASS |
| AC7 | FR-007 (`specrew host status`) | Per-host crew-runtime install state shown via `Get-SpecrewHostRuntimeInventory` | PASS |
| AC8 | FR-008 (Category A → `.specrew/coordinator/`) | n/a — deferred | DEFERRED |
| AC9 | FR-009 (brownfield migration) | n/a — deferred | DEFERRED |
| AC10 | FR-010 (Category B stays host-native) | Design honored: no `.squad/decisions.md`, `.squad/team.md`, etc. moved | PASS |
| AC11 | FR-011 (validators read `.specrew/coordinator/`) | n/a — deferred (validators still read `.squad/coordinator/` until FR-008/009 ship) | DEFERRED |
| AC12 | FR-012 (`host_resolution` in start-context.json) | Field present with values: `flag`, `last-selected`, `auto-single-available`, `first-run-prompt`, `non-interactive-no-default`, `no-launch-default`, `legacy-default`, `fallback-copilot` | PASS |
| AC13 | FR-013 (non-TTY guidance) | Non-zero exit + actionable message verified by manual run | PASS |

## Form-vs-meaning verification

- **Form**: `host-history.json` schema fields match the spec verbatim (modulo `.yml` → `.json` serialization).
- **Meaning**: `specrew host use claude` followed by `specrew start` (no flag) launches Claude, not Copilot — empirically confirmed during integration testing on the `multi-host-integration-refactor` branch.

## Known issues at close

1. **Bundled fix from F-044 iter-002**: The host-gate's `non-interactive-no-default` and `no-hosts-available` branches exited unconditionally with `exit 1`, breaking the `-NoLaunch` artifact-write contract. Three pre-existing integration tests (`specrew-start-baseline-tracking`, `-auto-continue-preservation`, `-change-detector`) regressed as a result. The fix (a `-NoLaunch` carve-out that falls back to `selectedHost='copilot'` with `host_resolution='no-launch-default'`) landed in commit `dcc4beb7` (F-044 iter-002) — same branch, different feature iteration.
2. **Spec drift**: `host-history.yml` shipped as `host-history.json` (no `powershell-yaml` dependency). Will be noted in CHANGELOG when this branch merges. See [`drift-log.md`](./drift-log.md).
3. **Test gap**: `tests/integration/multi-host-onboarding.tests.ps1` (planned T010 in `../../tasks.md`) was not implemented. F-043 behavior is regression-covered by `multi-host-launch-path.tests.ps1` + the three `specrew-start-*` tests but lacks F-043-specific assertions. Queued for the follow-up slice that handles FR-008/009/011.

## Sign-off

Approved for feature-closeout under the explicit scope-cut + bundled-with-F-044 framing. PR description will surface the deferred FRs and the cross-feature bundle so a reader can navigate to F-044's iteration artifacts for the architectural substrate this feature builds on.
