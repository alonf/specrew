---
proposal: 124
title: Multi-Host Catalog Expansion — Tier 1 CLIs (Aider + Amp + OpenCode + Cursor)
status: candidate
phase: phase-2
estimated-sp: 8-12
priority-tier: 2
discussion: triaged 2026-05-24 from 11 candidate hosts to viable Tier-1 set; gated on multi-host-integration-refactor merging (DONE) + Antigravity follow-up closing (DONE 2026-05-25); ready to draft now
---

# Multi-Host Catalog Expansion — Tier 1 CLIs

## Why

> **2026-05-28 amendment — Cursor extracted to standalone Proposal 114.** Cursor host work has been promoted to standalone implementation under Proposal 114 to serve as the parallel-development workflow pilot (running concurrently with Feature 049). Until 114 ships and 124's scope is re-evaluated, this bundle proposal SHOULD be treated as covering Aider + Amp + OpenCode only; the Cursor row below is retained as historical record. After 114 ships, the maintainer may amend 124 to formally remove the Cursor row (reducing the bundle to ~6-9 SP) OR retain Cursor coverage for cross-validation against 114's empirical answers. See Proposal 114 status history for the standalone extraction rationale.

F-040 (Multi-Host Launch Path) shipped Claude + Codex + Copilot launch dispatch. F-043 + F-044 (Per-Host Architecture Refactor) added Antigravity and refactored to a registry-driven adapter pattern where each host is `hosts/<kind>/` with manifest + handlers + coordinator-rules. **Adding a new host now costs ~half a day once the CLI's behavior is verified** — no core script edits, registry auto-discovers.

This proposal claims the obvious 4-host expansion that came out of the 2026-05-24 11-host triage. All four pass the "mature CLI that fits the adapter contract" bar empirically (subject to verification at implementation time):

| Host | Status | Reason for inclusion |
|---|---|---|
| **Aider** | Tier 1 | Python CLI, very mature. `aider --message`, working-dir, conversation history. Lowest-risk add — proves the expansion pattern. |
| **Amp** (Sourcegraph) | Tier 1 | `amp` CLI with prompt mode. Recent but stable. Active investment from Sourcegraph. |
| **OpenCode** (SST) | Tier 1 | Terminal-native AI coding agent. Active development. |
| **Cursor CLI** (`cursor-agent`) | Tier 1 | Newer; surface may shift but Cursor is committed. |

Tier 2 hosts (Jules, Devin, Grok) require empirical CLI verification before commitment. Tier 3 hosts (Cline, Kiro, Junie, DeepSeek/DeepCode) don't fit the host model at all — IDE-embedded or model-layer; out of scope per memory `[[multi-host-expansion-triage-2026-05-24]]`.

## What

Three slices. All add to `hosts/<kind>/` per the adapter contract documented at file:///C:/Dev/Specrew/docs/how-to/add-a-new-host.md.

### Slice 1: Aider (~2 SP) — lowest-risk, proves the pattern

Aider is the most mature CLI in the queue. Use as the calibration host for the rest of the proposal.

- `hosts/aider/host.psd1` — manifest (Kind=aider, DisplayName='Aider', Status='supported', Binary='aider', SkillRoot='.aider/skills', AgentDir='.aider/agents')
- `hosts/aider/handlers.ps1` — 5 contract functions (NewLaunchInvocation using `aider --message`, ConvertToFlag mapping --allow-all → --auto-commits, TestRuntimeInstalled checking `aider --version`, GetSignals, InstallCrewRuntime deploying SKILL.md files to .aider/skills)
- `hosts/aider/coordinator-rules.psd1` — `@{ Rules = @() }` initially
- Add 3 files to `Specrew.psd1` FileList
- Integration test: `tests/integration/multi-host-aider.tests.ps1`

### Slice 2: Amp + OpenCode + Cursor (~4-6 SP) — parallelizable

Each follows the same pattern as Slice 1. Can run in parallel once Slice 1 proves the workflow:

- `hosts/amp/` — `amp` binary, Sourcegraph CLI conventions
- `hosts/opencode/` — `opencode` binary, SST CLI conventions
- `hosts/cursor/` — `cursor-agent` binary, Cursor's terminal CLI

Each gets its own manifest + handlers + coordinator-rules + integration test. Mechanical work; differs only in:

- Binary name
- Prompt-mode flag (each CLI's `-p` or `--message` equivalent)
- Skill-deployment format (most use `.<host>/skills/SKILL.md` per the established convention from F-044)
- ConvertToFlag mappings (which native flag maps to `--allow-all`)

### Slice 3: User-guide + docs updates (~1-2 SP)

- Update `docs/user-guide.md` Multi-Host Launch section: extend host capability matrix with the 4 new entries
- Update `docs/getting-started.md`: mention the expanded host catalog
- Update README badge: "Hosts: Claude Code · Codex CLI · Copilot CLI · Antigravity · Aider · Amp · OpenCode · Cursor" (8 hosts)
- CHANGELOG entry under `### Added`

## How

Per the established host-adapter contract. Per-host effort is ~half a day mechanical once CLI is verified. Total ~8-12 SP across the 3 slices.

| Step | File | Effort |
|---|---|---|
| Slice 1 Aider host | `hosts/aider/*`, `Specrew.psd1`, tests | 2 SP |
| Slice 2 Amp | `hosts/amp/*`, `Specrew.psd1`, tests | 1.5 SP |
| Slice 2 OpenCode | `hosts/opencode/*`, `Specrew.psd1`, tests | 1.5 SP |
| Slice 2 Cursor | `hosts/cursor/*`, `Specrew.psd1`, tests | 1.5 SP |
| Slice 3 docs + README + CHANGELOG | docs/user-guide.md, docs/getting-started.md, README.md, CHANGELOG.md | 1-2 SP |
| ValidateSet updates (until Phase D ships) | per memory: 3 ValidateSet locations | 0.5 SP |

## Acceptance criteria

- **AC1**: `specrew start --host aider` launches Aider with auto-loaded bootstrap prompt
- **AC2**: `specrew start --host amp` launches Amp with auto-loaded bootstrap prompt
- **AC3**: `specrew start --host opencode` launches OpenCode similarly
- **AC4**: `specrew start --host cursor` launches Cursor CLI similarly
- **AC5**: Each host's `InstallCrewRuntime` deploys SKILL.md files to `.<host>/skills/` per the established convention
- **AC6**: Multi-host lifecycle smoke test passes for all 4 new hosts (the test suite extended in F-044)
- **AC7**: Each host's manifest correctly declares `HasUserSlashCommandSurface` — informs Test-HostSkillRoot's Codex-style "informational note vs warning" branching
- **AC8**: ValidateSet locations updated (until Phase D eliminates them)
- **AC9**: README + user-guide + CHANGELOG accurately reflect the expanded host catalog

## Out of scope

- **Tier 2 hosts (Jules, Devin, Grok)** — require empirical CLI verification first; defer to follow-up slice
- **Tier 3 hosts (Cline, Kiro, Junie, DeepSeek/DeepCode)** — IDE-embedded or model-layer; don't fit the host-adapter model
- **Remote-by-default hosts (Devin)** — needs contract extension to support remote-launch semantics; separate proposal
- **Phase D ValidateSet elimination** — orthogonal infrastructure work; this proposal updates the existing ValidateSets only
- **Host-specific MCP server integration** — separate concern; out

## Composition

- **Proposal 024 (Multi-Host Runtime Abstraction CORE)** — endgame for the adapter pattern; this proposal adds more concrete hosts on the existing path
- **Proposal 058 (Plugin-Based Distribution)** — future host packaging per host = plugin; this proposal's hosts could ship as plugins post-058
- **Proposal 069 (Multi-Host Launch Path, shipped as F-040)** — current dispatcher; this proposal extends the catalog
- **Proposal 104 (Multi-Host Onboarding)** — selection UX; new hosts auto-appear in selection menu
- **Proposal 105 (Host-Native Hook Deployment, draft)** — applies to Aider / Amp / OpenCode / Cursor if their CLIs support hook surfaces; verify at implementation time
- **Proposal 108 (Per-Host Crew Runtime Install)** — established skill-deployment pattern; new hosts follow

## Risks

- **CLI surface churn for newer hosts** (Cursor, OpenCode) — Mitigation: ship Slice 2 hosts as `Status='preview'` rather than `Status='supported'` until empirical stability; promote per-host as evidence accumulates
- **Aider's Python runtime requirement** — Aider needs Python + Aider's own install; documented prerequisite. Mitigation: TestRuntimeInstalled in handlers.ps1 surfaces missing runtime clearly
- **Skill-deployment format ambiguity** — some new hosts may not have a documented skill convention. Mitigation: follow F-044 default (`.<host>/skills/SKILL.md`) and adjust per host as we learn
- **Flag-mapping completeness** — each host has its own `--allow-all` equivalent; mapping may miss edge cases. Mitigation: per-host integration tests cover the flag translation
- **Same-day CLI rename risk** for newer hosts — Mitigation: pin recommended CLI version in user-guide; document expected behavior at the time of host addition

## Empirical motivation

2026-05-24 user question: "how hard is it to add these 11 hosts?" produced the triage memory. F-044 closing 2026-05-25 (PR #844 merge, multi-host-integration-refactor) removed the original blocker. Antigravity follow-up closed in the same session. The adapter contract is stable enough to scale to 4 more hosts without churn.

## Cross-references

- file:///C:/Dev/Specrew/docs/how-to/add-a-new-host.md (the contract this proposal follows)
- file:///C:/Dev/Specrew/hosts/_registry.ps1 (auto-discovery; no edits needed)
- file:///C:/Dev/Specrew/proposals/024-multi-host-runtime-abstraction.md
- file:///C:/Dev/Specrew/proposals/069-multi-host-launch-path.md
- file:///C:/Dev/Specrew/proposals/104-multi-host-onboarding-and-selection-flow.md
- file:///C:/Dev/Specrew/proposals/105-host-native-hook-deployment.md
- file:///C:/Dev/Specrew/proposals/108-per-host-crew-runtime-install.md
- Memory: [[multi-host-expansion-triage-2026-05-24]]

## Status history

- 2026-05-24: triage of 11 candidate hosts into Tier 1 / Tier 2 / Tier 3; queued for proposal after gating conditions cleared.
- 2026-05-25: gating cleared (multi-host-integration-refactor merged + Antigravity follow-up closed).
- 2026-05-26: candidate proposal drafted as part of memory→proposal sweep. Scoped to Tier 1 only; Tier 2 deferred pending empirical CLI verification; Tier 3 explicitly excluded with reasons.
