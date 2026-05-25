# Feature Specification: Per-Host Architecture Refactor

**Feature Branch**: `multi-host-integration-refactor` (bundled with F-043 — see closeout dashboard)
**Created**: 2026-05-24 (retroactive — work shipped 2026-05-23 → 2026-05-24)
**Status**: Implemented (closing via this PR)
**Input**: User direction (2026-05-24, conversational): "We have to have the ability to Specrew start --host different hosts on the same project. So either start should init each host, or init creates the teams for all. ... we need to be host agnostic in most of the code... in the future, adding a host for Cursor, windsurf or grok code should not open existing files."
**Source proposal**: file:///C:/Dev/Specrew/proposals/108-specrew-init-refactor-and-crew-runtime-abstraction.md (Proposal 108 — drafted 2026-05-24; shipped retroactively as F-044)
**Composes with**: F-040 Multi-Host Launch Path (host registry + 4 contract functions), F-043 Multi-Host Onboarding (host-history + selection chain), Proposal 024 Multi-Host Runtime Abstraction (this feature IS Slice 3's substrate), Proposal 058 Plugin-Based Multi-Host Distribution

## Why

Two empirical observations converged on the same refactor at 2026-05-24:

**Observation A**: `scripts/specrew-init.ps1` had grown to 2,428 lines with 45 internal-only functions mixing preflight, template deployment, Spec-Kit install, Squad bootstrap, agent detection, governance scaffolding, and post-bootstrap output. Every CI failure in the prior three weeks traced to this file's tangled responsibilities. The host-coupling firewall test was forced to allow-list the entire file.

**Observation B**: The host-package refactor (F-040 + earlier 2026-05-24 work) stopped short of the Crew-runtime layer. `specrew start --host claude` launched Claude but with no team of agents — Squad's 5-agent baseline (Spec Steward / Planner / Implementer / Reviewer / Retro Facilitator) remained hardcoded as Copilot-only. The user-observed gap: "I tried it with Claude and I didn't see a team of agents as we have with Squad."

These two concerns are not independent — specrew-init.ps1 is where Squad bootstrap lives. Splitting the monolith correctly required designing the per-host Crew-runtime-install abstraction at the same time.

## User scenarios

### Story 1 — `specrew start --host claude` deploys a 5-agent team (P0)

A user with Claude Code on PATH runs `specrew start --host claude` against a Specrew-bootstrapped project. After launch, `.claude/agents/` contains 5 subagent files (one per Crew role) with valid YAML frontmatter. Claude's Task tool can invoke each as `subagent_type: '<role>'`. The team is functionally equivalent to Squad's 5-agent baseline, just rendered in Claude's native subagent format.

### Story 2 — `specrew start --host codex` and `--host antigravity` get their own teams (P0)

Same as Story 1 but for Codex (TOML format under `.codex/agents/`) and Antigravity (Markdown + YAML under `.agents/agents/`). All four supported hosts now have a Crew-runtime install path.

### Story 3 — Switching hosts on the same project keeps teams in sync (P1)

User runs `specrew start --host copilot` then later `specrew start --host claude` on the same project. Both host-native trees stay synchronized with the canonical team source at `.specrew/team/agents/<role>.md`. If the user edits the canonical charter, the next `specrew start` for any host re-translates that change. Adding a custom specialist (e.g., `security-analyst.md`) at the canonical location flows to all four hosts on subsequent launches.

### Story 4 — Adding a new host (e.g., Cursor) doesn't touch existing code (P0)

A contributor creates `hosts/cursor/` with `host.psd1`, `handlers.ps1` exporting 5 contract functions, and `coordinator-rules.psd1`. They add the 3 files to `Specrew.psd1` FileList. No edits to any other file. The registry discovers Cursor automatically. `specrew start --host cursor`, `specrew host list`, `specrew host use cursor`, `specrew where` all work.

### Story 5 — `scripts/specrew-init.ps1` becomes a thin orchestrator (P1)

`specrew-init.ps1` shrinks from 2,428 lines to ~250-300 lines (thin orchestrator). The extracted concerns live under `scripts/init/` as 9 focused files of <300 lines each. Every previously-internal function remains accessible via dot-source. CI surface for init-related regressions narrows.

### Story 6 — Spec-Kit `specrew start` without prior `init` still gets a usable team (P2)

User runs `specrew start --host claude` on a greenfield project where they never ran `specrew init`. The canonical `.specrew/team/agents/` directory is auto-seeded from the shipped baseline charters before the per-host translation fires. The user gets a working 5-agent team without needing to know they should have run `init` first.

## Functional requirements

| FR | Requirement |
|---|---|
| FR-001 | A canonical team source-of-truth MUST exist at `.specrew/team/agents/<role>.md` (one Markdown file per agent role; flat structure). The shipped baseline 5 (spec-steward, planner, implementer, reviewer, retro-facilitator) MUST be seeded here on `specrew init` AND on first `specrew start` for greenfield projects. |
| FR-002 | Every supported host (`Status: 'supported'` in its manifest) MUST declare an `AgentDir` field pointing to its host-native subagent directory. The validator (`Test-HostManifestValid`) MUST enforce this. |
| FR-003 | A 5th contract function `Install-<PascalKind>CrewRuntime -ProjectPath <p> [-DryRun]` MUST be exported by every supported host's `handlers.ps1`. The function reads canonical charters via `Get-SpecrewCanonicalCharterContent` and writes host-native subagent files to the manifest-declared `AgentDir`. |
| FR-004 | The contract registry (`hosts/_registry.ps1`) MUST expose `InstallCrewRuntime` as a contract slot in `$script:HostContractFunctionMap` and dispatch via `Invoke-HostHandler -ContractFunction InstallCrewRuntime`. |
| FR-005 | A central dispatcher `Invoke-CrewBootstrap -ProjectPath <p> -HostKind <k>` MUST translate the canonical team to the host's native location on every `specrew start`. The dispatcher is idempotent + cheap (~50ms target). |
| FR-006 | `Invoke-CrewBootstrap` MUST auto-seed `.specrew/team/agents/` if missing, so greenfield projects without prior `init` still get a working team. |
| FR-007 | Host-native files generated by `Install-<Kind>CrewRuntime` MUST carry a "Specrew-managed" marker — either inline (`# Specrew-managed`, `-- Specrew-managed`, or `<!-- Specrew-managed -->` per host's native syntax) OR a sidecar marker file `<path>.specrew-managed` when the host format cannot tolerate inline comments (e.g., Squad's `charter.md` consumed as charter body). |
| FR-008 | User edits to host-native files (= file exists, lacks the Specrew-managed marker, AND sidecar missing) MUST NOT be clobbered by re-deploy. Install handlers MUST emit a "preserved" notice + skip. |
| FR-009 | `scripts/specrew-init.ps1` MUST be split into a thin orchestrator (~250-300 lines) + 9 focused files under `scripts/init/`: `_utilities`, `preflight`, `template-deploy`, `spec-kit-deploy`, `dependency-install`, `agent-detection`, `squad-deploy`, `crew-bootstrap`, `post-bootstrap-output`. Each <300 lines. Bit-identical behavior for the existing Copilot-default path. |
| FR-010 | Path resolution in the split files MUST use a marker-file walk on `Specrew.psd1` (not fragile N-level `Split-Path -Parent` chains). Same lesson as F-019 Slice 5 / Slice 8. |
| FR-011 | Adding a new host MUST require only: `mkdir hosts/<kind>/`, write 3 files (manifest + handlers + coordinator-rules), add the 3 to `Specrew.psd1` FileList. Zero edits to existing files. A structural firewall test (`tests/integration/host-coupling-firewall.tests.ps1`) MUST enforce this. |
| FR-012 | Documentation (`hosts/_contract.md`, `docs/architecture/host-package-architecture.md`, `docs/how-to/add-a-new-host.md`, `docs/user-guide.md`) MUST be updated to reflect the 5-function contract + canonical team source-of-truth + per-host translation flow. |
| FR-013 | A dedicated integration test `tests/integration/crew-bootstrap-contract.tests.ps1` MUST verify: 5 baseline charters seed canonically; every host's Install function deploys to its manifest-declared AgentDir; sentinel-preservation works on user-edited files; sentinel re-write works on still-managed files. |

## Acceptance criteria

| AC | FR(s) | Verification |
|---|---|---|
| AC1 | FR-001 | `Initialize-SpecrewTeamCanonical` writes 5 charters to `.specrew/team/agents/` on init AND first start. Idempotent: re-run preserves existing files. |
| AC2 | FR-002 | `Test-HostManifestValid` rejects a `Status='supported'` manifest without `AgentDir`. Test 16 in `host-registry.tests.ps1` covers this. |
| AC3 | FR-003 | Every host's `Install-<Kind>CrewRuntime` exists and conforms to signature. Test 15 in `host-registry.tests.ps1` covers existence. |
| AC4 | FR-004 | `Resolve-HostHandler -ContractFunction InstallCrewRuntime` returns the right per-host function. Test 14 covers this. |
| AC5 | FR-005 | `Invoke-CrewBootstrap` invoked by `specrew start` translates 5 charters per host in <500ms. E2E test covers all 4 hosts. |
| AC6 | FR-006 | `specrew start --host claude` on a project without `.specrew/team/agents/` still produces a working 5-agent team under `.claude/agents/`. |
| AC7 | FR-007 + FR-008 | Re-deploy preserves user-edited host-native files (test 8 in `crew-bootstrap-contract.tests.ps1`) and still re-writes Specrew-managed files (test 9). |
| AC8 | FR-009 | `scripts/specrew-init.ps1` post-refactor is <800 lines (target ~250-300 for the orchestrator surface). `scripts/init/` contains the 9 focused files. |
| AC9 | FR-010 | Path resolution in `crew-bootstrap.ps1` + `agent-detection.ps1` survives a hypothetical relocation (marker-walk to `Specrew.psd1`). |
| AC10 | FR-011 | Host-coupling firewall test passes with the existing 4 hosts; no hardcoded enum violations in production `.ps1` files outside `hosts/` + allow-list. |
| AC11 | FR-012 | 4 doc files updated; `hosts/_contract.md` rewrite reflects 5-function contract; user-guide describes canonical team flow. |
| AC12 | FR-013 | `tests/integration/crew-bootstrap-contract.tests.ps1` exists with 9 assertions; all PASS. |

## Architecture references

- Source proposal: file:///C:/Dev/Specrew/proposals/108-specrew-init-refactor-and-crew-runtime-abstraction.md
- Host contract: [`hosts/_contract.md`](../../hosts/_contract.md)
- Host-package architecture (Mermaid diagram): [`docs/architecture/host-package-architecture.md`](../../docs/architecture/host-package-architecture.md)
- Slice 9 implementation review: [`docs/design/proposal-108-slice-9-review.md`](../../docs/design/proposal-108-slice-9-review.md)
- How-to add a new host: [`docs/how-to/add-a-new-host.md`](../../docs/how-to/add-a-new-host.md)

## Out-of-scope (deferred to future work)

- **Coordinator-overlay translation per host**: F-044 ships the team-charter substrate but NOT the per-host translation of the 45 coordinator directives (Proposal 024 Category D). The Copilot coordinator overlay at `.github/agents/squad.agent.md` exists; Claude/Codex/Antigravity overlays are not yet host-translated. Tracked for follow-up Proposal 024 work.
- **Ceremonies migration**: ceremonies.md still lives at `.squad/ceremonies.md` (Copilot-only). Hosting equivalent for Claude/Codex/Antigravity deferred.
- **`specrew team` CLI rewiring**: The team-customization CLI (`specrew team add/list/update/remove`) currently writes to `.squad/team.md`. Rewiring it to write canonical `.specrew/team/agents/<role>.md` deferred to a follow-up small-fix slice.
- **Antigravity smoke test**: Antigravity remains "medium-confidence" — its subagent format is inferred from Gemini CLI documentation but not yet smoke-tested against an actual `agy` binary (Gemini deadline 2026-06-18).
