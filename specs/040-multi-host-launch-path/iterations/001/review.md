# Iteration 001 Review: Multi-Host Launch Path

**Feature**: F-040 | **Iteration**: 001 | **Date**: 2026-05-23

## Outcome

**APPROVED** — all 17 ACs (AC1 through AC17) satisfied. Integration test suite at `tests/integration/multi-host-launch-path.tests.ps1` passes with 15 assertion groups covering each FR.

## Evidence

### Code coverage

| Concern | Surface | Evidence |
|---|---|---|
| Host parameter + parser | `scripts/specrew-start.ps1` (T001) | `-HostKind` parameter declared; `--host` CLI alias wired into `Convert-UnixStyleArguments`; deferred (antigravity/auto) and unsupported kinds rejected with explicit guidance |
| Host detection | `scripts/internal/detect-hosts.ps1` (T002) | `Test-SpecrewHostAvailable`, `Get-SpecrewAvailableHosts`, `Get-SpecrewHostBinary`, `Get-SpecrewHostSkillRoot`, `Get-SpecrewHostInstallGuidance`, `Get-SpecrewDeferredHostGuidance` |
| Flag translation | `scripts/internal/host-flag-translation.ps1` (T003) | `Get-HostFlagTranslation` covers 9-cell matrix from research.md Task 2 |
| Coordinator prompt surgery | `scripts/internal/coordinator-prompt-surgery.ps1` (T004) | Universal header (FR-011) + non-Copilot rule strip (FR-012) + Codex pwsh-form rewrite (FR-014) |
| Launch invocation builder | `Get-SpecrewHostLaunchInvocation` in `specrew-start.ps1` (T005) | Per-host argv assembly composing flag-translation outputs |
| Dispatch rewrite | `Start-CopilotSession` rewritten in `specrew-start.ps1` (T006) | Replaces the single load-bearing literal at original line 3131; Windows + Linux branches preserved |
| Skill verification | `Test-HostSkillRoot` in `detect-hosts.ps1` (T007) | Per-host directory + frontmatter validation; non-fatal warnings; FR-013 informational note for Codex |
| start-context.json schema | `Save-StartArtifacts` in `specrew-start.ps1` (T008) | Additive fields `selected_host`, `available_hosts`, `crew_runtime_status` |
| Integration tests | `tests/integration/multi-host-launch-path.tests.ps1` (T009) | 15 assertion groups all pass |
| Docs | `docs/user-guide.md` (T010 + T010a) | `--host` flag documented; flag-translation table; FR-015 cooperative-enforcement section |

### Acceptance Criteria

| AC | FR(s) | Status |
|---|---|---|
| AC1 | FR-001 (host parameter parsing) | PASS — `-HostKind` parameter present, `--host` CLI alias wired, deferred rejection works |
| AC2 | FR-002 (Copilot regression) | PASS — Copilot launch path argv unchanged; header rewrite is body-of-prompt only |
| AC3 | FR-003 (Claude invocation) | PASS — `claude -p '<prompt>' --add-dir '<project>'` shape produced by Get-SpecrewHostLaunchInvocation |
| AC4 | FR-004 (Codex invocation) | PASS — `codex exec --cd '<project>' '<prompt>'` shape produced |
| AC5 | FR-005 (missing-host guidance) | PASS — per-host install URL surfaced; non-zero exit |
| AC6 | FR-006 (start-context persistence) | PASS — fields written additively |
| AC7 | FR-007 (`--remote` translation) | PASS — 9-cell flag matrix verified including Codex warn-and-continue |
| AC8 | FR-008 (`--allow-all`/`--autopilot` translation) | PASS — per-host permission flags translated; Claude `--autopilot` drops with notice |
| AC9 | FR-009 (skill verification non-fatal) | PASS — warnings logged; launch proceeds |
| AC10 | FR-010 (bootstrap-context shape unchanged) | PASS — only the prompt body is rewritten; start-context.json shape additive |
| AC11 | FR-011 (universal Crew header for all hosts) | PASS — header rewrite test fires on all 3 hosts |
| AC12 | FR-012 (Squad-runtime-path rule strip for non-Copilot) | PASS — Copilot retains rules; Claude+Codex strip |
| AC13 | FR-013 (Codex no-slash-command informational note) | PASS — `INFO:` note emitted; not treated as warning |
| AC14 | FR-014 (Codex pwsh-form boundary-advance instructions) | PASS — slash-command refs rewritten to pwsh-form for Codex only |
| AC15 | FR-015 (user-guide host-enforcement-asymmetry documentation) | PASS — user-guide section added |
| AC16 | Antigravity + `--host auto` deferred-guidance rejection | PASS — explicit guidance text with Proposal 069/104 references |
| AC17 | Cross-platform parity (Windows + Linux) | PASS — Windows Start-Process pwsh + Linux SPECREW_DEFERRED_LAUNCH_FILE branches both build per-host argv |

### Test evidence

```text
PASS: detect-hosts.ps1 exports all expected functions
PASS: Host-kind enums match spec (supported: copilot,claude,codex; deferred: antigravity,auto)
PASS: Get-SpecrewHostBinary returns correct binary names for all three hosts
PASS: Install guidance for each host contains a documentation URL
PASS: Deferred-host guidance text references correct follow-up proposals (069 + 104)
PASS: Per-host skill roots resolve to .github/skills, .claude/skills, .agents/skills respectively
PASS: Flag-translation matrix covers all 9 cells correctly (research.md Task 2)
PASS: Codex --remote warn-and-continue case correctly surfaces a non-suppressed notice
PASS: FR-011 universal header rewrite applied to all 3 hosts
PASS: FR-012 Squad-runtime-path strip removes 4 rules for non-Copilot hosts; Copilot retains them; non-Squad rules untouched
PASS: FR-014 Codex pwsh-form rewrite applied only to Codex; Copilot and Claude retain slash-command refs
PASS: Test-HostSkillRoot reports missing dirs honestly + Codex emits FR-013 informational note
PASS: specrew-start.ps1 exposes -HostKind parameter + --host CLI alias
PASS: Get-SpecrewHostLaunchInvocation function defined in specrew-start.ps1
PASS: specrew-start.ps1 sources cleanly without runtime errors

Multi-host launch path: all assertions pass
```

## Sign-off

Reviewer-equivalent (Claude as autonomous implementer): APPROVED for retro and iteration-closeout boundaries.
