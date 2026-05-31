---
proposal: 150
title: Agent-Support Hardening Bundle (Boundary Discipline + Tool Manifest + Structured Updaters + Safety Defaults)
status: candidate
phase: phase-2
estimated-sp: 25-30
priority-tier: 1
discussion: surfaced 2026-05-31 by Codex cross-review of F-054 v0.30.0-beta1 validation walkthrough — eight systemic "Specrew makes agent mistakes too easy" issues observed in a single fresh-greenfield trial against `--host claude`
---

# Agent-Support Hardening Bundle (Boundary Discipline + Tool Manifest + Structured Updaters + Safety Defaults)

## Why

A single fresh-greenfield trial of `specrew start --host claude` against v0.30.0-beta1 (`C:/Temp/SpecrewTrials/v30`, feature: "A 3d game of life") produced **eight distinct failure modes** in one session. None of the eight were primarily Claude's fault — every one of them was Specrew offering an interface that made the agent mistake easy, default, or unavoidable.

**Headline:** the F-054 surfaces (`/speckit.checklist` at before-plan, `/speckit.analyze` at before-implement) never appeared in the lifecycle handoff. Initial framing was "F-054 didn't provision surfaces to non-Copilot skill catalogs." Codex cross-review reframed it: the *deeper* cause is that the coordinator prompt lists the entire canonical lifecycle sequence as a single chain ([`squad-templates/coordinator/specrew-governance.md:7`](../extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md)) and the agent chains right past every boundary stop without ever surfacing what should appear at each gate. Surface provisioning is necessary but not sufficient; **boundary discipline at the prompt layer** is the load-bearing fix.

This proposal bundles all eight observed issues into one focused agent-support-hardening feature, in Codex's recommended priority order.

### Empirical evidence (single trial, 2026-05-31)

| # | Observed issue | Specrew interface that enabled it | File reference |
| --- | --- | --- | --- |
| 1 | Claude received `--dangerously-skip-permissions` without explicit opt-in | `--allow-all` is the DEFAULT (not opt-in) for tool-call approval | [`scripts/specrew-start.ps1:305`](../scripts/specrew-start.ps1) help-text + [`hosts/claude/handlers.ps1:95`](../hosts/claude/handlers.ps1) translation |
| 2 | Launch UX printed `"Copilot approval mode: ..."` when host was Claude | Host-specific UX text bound to Copilot regardless of `--host` | [`scripts/specrew-start.ps1:4143`](../scripts/specrew-start.ps1) |
| 3 | Agent chained specify → clarify → plan → tasks → before-implement in one turn without stopping for `/speckit.checklist` / `/speckit.analyze` | Coordinator prompt lists the whole canonical sequence; no "next allowed step only" directive | [`squad-templates/coordinator/specrew-governance.md:7`](../extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md) |
| 4 | Agent guessed `-FeatureRef` when the script wanted `-FeaturePath`; two wasted invocations | No machine-readable manifest of valid parameters per Specrew script | (no manifest exists today) |
| 5 | Agent did 5+ rounds of hand-editing the hardening-gate Markdown table to satisfy enum validators | Scaffold writes `tbd` placeholders; updates are Markdown-table surgery, not structured input | [`scripts/run-hardening-gate.ps1:157`](../extensions/specrew-speckit/scripts/run-hardening-gate.ps1) `Get-HardeningConcernDefinitions` |
| 6 | Agent invoked `pwsh` scripts through Bash → `Select-Object: command not found`, `iconv -f UTF-16LE` confusion, ~4 wasted tool calls before switching to PowerShell tool | No per-host coordinator rule warning Claude that PowerShell syntax requires the PowerShell tool on Windows | [`hosts/claude/coordinator-rules.psd1:1`](../hosts/claude/coordinator-rules.psd1) (no Windows rule exists) |
| 7 | Iteration plan assigned Implementer tasks to `copilot` even though host was Claude | Routing reads `role-assignments.yml` defaults without reconciling against active runtime | (no host-aware routing logic exists) |
| 8 | No automated regression catches any of the seven above | No per-host integration tests assert observable startup posture | (no tests of this shape exist) |

Each row is one observed failure in one trial. They are not isolated bugs; they share a single root: **Specrew's interface invites the mistake**.

## What

Eight items grouped into three tiers per Codex's recommended priority order.

### Tier 1 — Safety + boundary discipline (must-ship; load-bearing)

#### Item 1 — Flip the `--allow-all` default

Change tool-approval policy:

- Claude and Codex default to **prompt-approvals** (interactive approval on tool calls)
- `--allow-all` becomes opt-in (explicit flag required to bypass)
- Copilot's existing default is retained ONLY if its empirical safety story is meaningfully different; otherwise flip it too

**Why first:** an agent running with skipped permissions can do real damage to a user's machine (file deletion, git destruction, network actions) BEFORE the lifecycle even reaches its first boundary stop. This is the only item where the cost of doing nothing is non-reversible.

**Files touched:** [`scripts/specrew-start.ps1`](../scripts/specrew-start.ps1) default logic (lines 305, 321, 3572-3573, 4035-4041, 4159-4160), [`hosts/claude/handlers.ps1:95`](../hosts/claude/handlers.ps1), per-host handlers for codex / antigravity / cursor.

#### Item 3 — "Next authorized action only" prompt block

Generate, at the TOP of `.specrew/last-start-prompt.md`, a block computed from `.specrew/start-context.json`:

```text
NEXT AUTHORIZED ACTION ONLY:
  pending_next_boundary: specify
  allowed_command: /speckit.specify
  stop_after: specify
  do_not_run: clarify, plan, tasks, before-implement, implement
```

Keep the existing canonical lifecycle list (it is still needed for *understanding* the lifecycle) but make the immediate, ONLY-allowed command unmissable. The agent reads the block first and cannot chain further.

**Why this fixes the F-054 surface gap directly:** when `pending_next_boundary` is `before-plan`, the allowed action becomes "surface `/speckit.checklist`, then stop for human verdict." The agent emits the surface naturally because the boundary IS the next allowed action.

**Files touched:** [`squad-templates/coordinator/specrew-governance.md`](../extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md), [`scripts/specrew-start.ps1`](../scripts/specrew-start.ps1) prompt-emission section, `start-context.json` schema (add `pending_next_boundary` + `allowed_command` derivation).

#### Item 4 — Generate `.specrew/agent-command-manifest.json`

Machine-readable manifest written at `specrew init` time (refreshed at `specrew start`):

```json
{
  "scripts": {
    "resolve-quality-profile": {
      "path": ".specify/extensions/specrew-speckit/scripts/resolve-quality-profile.ps1",
      "parameters": {
        "ProjectPath":  { "type": "string", "required": false },
        "FeaturePath":  { "type": "string", "required": false },
        "SpecPath":     { "type": "string", "required": false },
        "OutputFormat": { "type": "enum", "values": ["object","json"] }
      },
      "preferred_invocation_per_phase": { "before-plan": "-ProjectPath . -FeaturePath specs/<feature>/" }
    },
    "run-hardening-gate":      { "...": "..." },
    "scaffold-iteration-artifacts": { "...": "..." }
  }
}
```

The coordinator prompt instructs every agent: *"Read `.specrew/agent-command-manifest.json` before invoking any Specrew script; do not guess parameter names."* Eliminates the `-FeatureRef` vs `-FeaturePath` class of failure entirely.

**Files touched:** new script `scripts/build-agent-command-manifest.ps1`, `specrew init` flow integration, `specrew start` refresh, coordinator-prompt instruction.

#### Item 5 — Structured hardening-gate updater

Replace Markdown-table surgery with structured input:

```powershell
pwsh -File run-hardening-gate.ps1 `
  -ConcernUpdatesJson '{
    "security-surface": {
      "status": "addressed",
      "evidenceBasis": "planning-time-analysis",
      "runtimeEvidenceStatus": "not-needed",
      "expectedControls": "No network/storage/input...",
      "rationale": "Self-contained client-side renderer..."
    }
  }'
```

OR a `set-hardening-concern.ps1` per-concern wrapper. The updater **validates enum values against the schema before writing**, so the validator's "must use Evidence Basis X" / "must use Runtime Evidence Status Y" errors become inline rejections at write time rather than 5+ rounds of trial-and-error post-write.

**Files touched:** [`extensions/specrew-speckit/scripts/run-hardening-gate.ps1`](../extensions/specrew-speckit/scripts/run-hardening-gate.ps1) (extend with structured-input mode), new helper `Set-HardeningConcern` function, enum-schema centralization for re-use by validator.

### Tier 2 — Host-aware UX cleanup

#### Item 2 — Host-neutral launch UX text

Replace `"Copilot approval mode: ..."` with `"{Host} tool approval mode: ..."` or simply `"Tool approval mode: ..."`. Apply same fix to the new-window success messages and any other Copilot-bound copy.

**Files touched:** [`scripts/specrew-start.ps1:4143`](../scripts/specrew-start.ps1) and adjacent host-bound Write-Info calls.

#### Item 6 — Windows shell guidance in Claude coordinator-rules

Inject an `Append` rule into [`hosts/claude/coordinator-rules.psd1`](../hosts/claude/coordinator-rules.psd1):

```text
On Windows, PowerShell syntax must run in the PowerShell tool, not Bash.
Commands containing Get-ChildItem, Select-Object, Get-Command, Where-Object,
or any .ps1 invocation must NOT be sent to bash.
Discover script syntax with `Get-Command -Syntax <path>` before inventing parameters.
```

Apply analogous rules to Codex / Cursor / Antigravity coordinator-rules where the host's tool-selection adapter has known sharp edges.

**Files touched:** [`hosts/claude/coordinator-rules.psd1`](../hosts/claude/coordinator-rules.psd1) (add Append rule), other per-host coordinator-rule files.

#### Item 7 — Host-aware Implementer routing

When `--host claude`, iteration plans should NOT auto-assign Implementer tasks to `copilot` unless a real Copilot runtime is configured AND intended. Either:

- Normalize the `Agent` column in `iterations/<NNN>/plan.md` to the active host on plan render
- OR record "planned role" separately from "actual runtime" so the deviation is visible without ambiguity

**Files touched:** plan-rendering logic (likely in `scripts/specrew.ps1` or scaffold scripts), role-assignments.yml resolver, possibly schema addition to iteration plan table.

### Tier 3 — Regression coverage

#### Item 8 — Regression tests anchored to this exact trial

Add integration tests that assert:

- `specrew start --host claude` does NOT print `Copilot approval mode`
- Claude does NOT receive `--dangerously-skip-permissions` unless `--allow-all` is explicit
- Generated `.specrew/last-start-prompt.md` contains a `NEXT AUTHORIZED ACTION ONLY:` block matching `pending_next_boundary`
- `.specrew/agent-command-manifest.json` exposes `-FeaturePath` (not invented `-FeatureRef`) for every script with that parameter
- `run-hardening-gate.ps1 -ConcernUpdatesJson <file>` accepts structured input AND passes validator on first run
- Per-host integration test: fresh greenfield → specrew init → specrew start → verify boundary handoff surfaces `/speckit.checklist` at before-plan + `/speckit.analyze` at before-implement (closes the F-054 empirical gap for ALL hosts, not just Copilot)

**Files touched:** new test files under `tests/integration/`, possibly a per-host test harness pattern.

## How

### Iteration structure

| Iter | Items | Effort | Goal |
| ---- | ----- | ------ | ---- |
| 001 | Items 1, 2, 6 (safety defaults + host-neutral UX + Windows rule) | ~5-7 SP | Stop the bleeding: no more `--dangerously-skip-permissions` by default, no more "Copilot approval mode" surfacing for other hosts, no more Bash-on-PowerShell traps in Claude |
| 002 | Items 3, 4 (one-boundary prompt + agent command manifest) | ~10-13 SP | Boundary discipline at the prompt layer + machine-readable command interface |
| 003 | Items 5, 7, 8 (structured hardening updater + host-aware routing + regression tests) | ~10-13 SP | Eliminate Markdown surgery + close host-routing mismatch + lock in all the above with tests |

Each iteration stays under the 20 SP cap (per `[[project-20sp-iteration-cap-intentional-2026-05-29]]`). Total ~25-33 SP.

### Composition with existing proposals

- **[Proposal 145](145-structured-multi-phase-reviewer.md)** (Structured Multi-Phase Reviewer): Item 8 (regression tests) anchors Phase 2 (Functional Correctness) sub-rules. Specifically: per-host runtime walkthrough becomes a standard Phase-2 verification for any cross-host feature.
- **[Proposal 065](065-launch-mode-boundary-enforcement.md)** (Launch-Mode Boundary Enforcement, shipped F-039): Item 3 is the natural-language equivalent at the prompt layer. 065 enforces boundaries via tool-call intercept; this proposal enforces at the prompt-input layer (defense in depth).
- **[Proposal 069](069-multi-host-launch-path.md)** (Multi-Host Launch Path, shipped F-040): Item 7 (host-aware routing) extends 069's per-host flag mapping to per-host agent assignment.
- **[Proposal 088](088-markdown-lint-pre-boundary-auto-fix-discipline.md)** (Markdown Lint Pre-Boundary, shipped F-033): Item 5 (structured hardening updater) is the same pattern applied to hardening-gate edits — replace post-write validation with at-write validation.
- **[Proposal 028](028-lifecycle-hardening-bundle.md)** (Lifecycle Hardening Bundle, candidate): Item 4 (command manifest) feeds 028's auto-INDEX generation discipline — both are about machine-readable canonical sources of truth.

### Sequencing within feature roadmap

- **F-054 beta2** (in flight) should ship the minimum surface provisioning fix only (defense-in-depth at the catalog layer). Stays scoped, ships v0.30.0 stable.
- **This proposal (148)** becomes the next major feature after F-054 stable promotes — likely F-055 or F-056 depending on F-051 sequencing.
- **F-051** (Multi-Session Foundation) continues in parallel; Items 1-6 in this proposal are orthogonal to multi-session scope.

## Risks

- **Default flip user-impact (Item 1):** Users with established muscle memory of "tool calls just happen" will notice the prompt cadence change. Mitigation: announce in release notes prominently; offer one-line `--allow-all` opt-in for power-users.
- **Coordinator prompt regression (Item 3):** A poorly-crafted "next allowed step" block could make the agent over-cautious and refuse legitimate intra-phase work. Mitigation: the block lists `do_not_run` boundaries explicitly; intra-phase tool calls are not restricted.
- **Agent command manifest staleness (Item 4):** If scripts change signatures, the manifest must regenerate. Mitigation: regenerate at `specrew start` (cheap operation); add validator rule that flags manifest drift.
- **Test-harness fragility for per-host integration tests (Item 8):** Headless invocation of Claude / Codex / Cursor / Antigravity CLIs in CI is non-trivial. Mitigation: start with assertion against generated `.specrew/last-start-prompt.md` content (file-shape test, no host launch required); add real-launch tests only where the CLI runs headlessly.

## Open questions

1. Should Copilot's `--allow-all` default also flip to opt-in, or is Copilot's safety story (interactive Copilot CLI vs autonomous host) different enough to retain it? Recommend research at Iter-001 clarify boundary.
2. Should `.specrew/agent-command-manifest.json` be checked-in or runtime-generated? Checked-in catches schema drift in PRs but adds churn. Recommend runtime-generated at `specrew init` / `specrew start` with a validator rule.
3. Should the "next authorized action only" block live in `.specrew/last-start-prompt.md` (re-rendered every start) or in a separate `.specrew/next-action.md` file the prompt links to (decouples prompt + state)? Recommend embedded for v1, separate file for v2.
