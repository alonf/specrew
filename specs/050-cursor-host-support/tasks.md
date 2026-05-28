# Tasks: Cursor Host Package

**Feature**: `050-cursor-host-support`
**Date**: 2026-05-28
**Plan**: [plan.md](./plan.md) · **Spec**: [spec.md](./spec.md)
**Pre-allocated ModuleVersion**: `0.29.0` (do not change — Parallel-Work Charter)

Every task maps to ≥1 FR/SC. Every FR/SC has ≥1 task (see Traceability matrix at end).

## Iteration 001 — Core package + skill target

| Task | Description | Maps to | Files |
| --- | --- | --- | --- |
| T001 | Author `hosts/cursor/host.psd1` manifest: all required fields + `MenuPriority=1.5`, `Binary=cursor-agent`, `SkillRoot=.cursor/rules`, `HasUserSlashCommandSurface=$false`, `AgentDir=.cursor/rules/`, `InstructionsFile=AGENTS.md`, `Status=supported`, `InstallUrl/InstallGuidance` | FR-001, FR-009, FR-010, FR-011, SC-006 | `hosts/cursor/host.psd1` |
| T002 | Implement `New-CursorLaunchInvocation` (`--print --workspace <proj> "<prompt>"`; `--force --trust` only under `-AllowAll`/`-UseAutopilot`) + unit test | FR-002, FR-009, FR-011, SC-001 | `hosts/cursor/handlers.ps1`, `tests/hosts/cursor.tests.ps1` |
| T003 | Implement `ConvertTo-CursorFlag` (allow-all→`--force --trust`; autonomous→`--force`; readonly→`--mode plan`; unknown→Notice+SuppressWarning) + unit test | FR-002 | `hosts/cursor/handlers.ps1`, `tests/hosts/cursor.tests.ps1` |
| T004 | Implement `Test-CursorRuntimeInstalled` (probe `cursor-agent` on PATH; never throws) + unit test | FR-002 | `hosts/cursor/handlers.ps1`, `tests/hosts/cursor.tests.ps1` |
| T005 | Implement `Get-CursorSignals` (return confirmed Cursor env-var names; document any uncertainty) + unit test | FR-002 | `hosts/cursor/handlers.ps1`, `tests/hosts/cursor.tests.ps1` |
| T006 | Implement `Install-CursorCrewRuntime` (translate `.specrew/team/agents/*.md` → `.cursor/rules/<role>.mdc`; `-DryRun`; idempotent) + unit test | FR-002, FR-010 | `hosts/cursor/handlers.ps1`, `tests/hosts/cursor.tests.ps1` |
| T007 | Author `hosts/cursor/coordinator-rules.psd1` (declare `Rules = @()` if no Cursor-specific surgery) | FR-001 | `hosts/cursor/coordinator-rules.psd1` |
| T008 | Add `cursor` entry → `.cursor/rules` to `Get-ActiveSkillRoots` (4-entry list) | FR-003 | `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` |
| T009 | Add the 3 `hosts/cursor/*` paths to `Specrew.psd1` `FileList` (Mac-install lesson + validator rule) | FR-001 | `Specrew.psd1` |
| T010 | Verify registry auto-discovery: `Get-RegisteredHostKinds` includes `cursor`, `Test-HostManifestValid` passes, structural firewall test still green | FR-004, SC-006 | (verification; `tests/hosts/cursor.tests.ps1`) |

## Iteration 002 — Test coverage

| Task | Description | Maps to | Files |
| --- | --- | --- | --- |
| T011 | Harden `tests/hosts/cursor.tests.ps1`: all 5 functions covered with BOTH mock and real-`cursor-agent` fixtures (real-binary cases skip-guarded when absent) | FR-005, SC-004 | `tests/hosts/cursor.tests.ps1` |
| T012 | Author `tests/integration/host-cursor-launch.tests.ps1` end-to-end smoke (skipped on CI without binary) | FR-006, SC-005 | `tests/integration/host-cursor-launch.tests.ps1` |
| T013 | Update `tests/integration/multi-host-detection.tests.ps1` to include `cursor` in the probe matrix | FR-007 | `tests/integration/multi-host-detection.tests.ps1` |

## Iteration 003 — Documentation + manual smoke

| Task | Description | Maps to | Files |
| --- | --- | --- | --- |
| T014 | Add "Cursor Quickstart" + caveats (no slash palette; AGENTS.md-driven) to `docs/getting-started.md` | FR-008, SC-007 | `docs/getting-started.md` |
| T015 | Add Cursor interaction-model section to `docs/user-guide.md` (rules-context vs slash commands; `--allow-all`→`--force --trust` semantics) | FR-008, SC-007 | `docs/user-guide.md` |
| T016 | Manual end-to-end smoke: `specrew start --host cursor "<feature>"` on this machine; capture evidence | SC-001, SC-002, SC-003, SC-005 | (evidence in iteration review) |

## Cross-cutting / governance tasks

| Task | Description | Maps to |
| --- | --- | --- |
| T017 | Confirm Parallel-Work Charter compliance at each boundary: ModuleVersion stays `0.29.0`; no `.specify/extensions/specrew-speckit/**` edits; no `specrew update`; append-only on shared files | (governance) |
| T018 | Cross-reviewer (different model session) at review-signoff | (governance, Charter Item 8) |

## Traceability matrix (FR/SC → task)

| Requirement | Tasks |
| --- | --- |
| FR-001 | T001, T007, T009 |
| FR-002 | T002, T003, T004, T005, T006 |
| FR-003 | T008 |
| FR-004 | T010 |
| FR-005 | T011 |
| FR-006 | T012 |
| FR-007 | T013 |
| FR-008 | T014, T015 |
| FR-009 | T001, T002 |
| FR-010 | T001, T006 |
| FR-011 | T001, T002 |
| SC-001 | T002, T016 |
| SC-002 | T016 |
| SC-003 | T016 |
| SC-004 | T011 |
| SC-005 | T012, T016 |
| SC-006 | T001, T010 |
| SC-007 | T014, T015 |

All 11 FRs and all 7 SCs are covered. All 18 tasks trace to ≥1 FR/SC (T017/T018 are governance tasks tied to the Parallel-Work Charter, not feature FRs).
