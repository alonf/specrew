---
proposal: 105
title: Host-Native Hook Deployment for Runtime Boundary Enforcement
status: candidate
phase: phase-2
estimated-sp: 12-18
discussion: ad-hoc 2026-05-23 multi-host research session; surfaced explicitly during F-040 plan-boundary review when the cooperative-vs-runtime enforcement gap was identified
---

# Host-Native Hook Deployment for Runtime Boundary Enforcement

## Why

F-039 (Launch-Mode Boundary Enforcement) shipped as v0.25.0 with what its name suggests is "runtime" enforcement, but the actual mechanism is **cooperative**: the boundary-authorization gate fires only when the agent invokes Specrew's canonical sync path. The canonical path is a slash command on Copilot/Claude (`/speckit.specrew-speckit.sync-plan`) or a direct PowerShell invocation on Codex (`pwsh -File ...`). If a rogue or sloppy agent writes directly to `.specrew/start-context.json` boundary_enforcement section, **no gate fires** — the host runtime doesn't intercept that write.

This was an acceptable trade-off when Specrew ran only on Copilot CLI (which has no hook surface), but the 2026-05-23 multi-host research wave found:

- **Claude Code has rich lifecycle hooks** (`PreToolUse`, `PostToolUse`, `SubagentStart`, `Stop`, `TaskCreated`, `TaskCompleted`, more) — configured in `.claude/settings.json`. `PreToolUse` can intercept **any** tool call, including file writes, before the host runtime executes them.
- **Antigravity CLI has hooks** (JSON-configured lifecycle interceptors per 2026-05-23 research).
- **Codex CLI's hook surface is unclear** at research time but the subagent system suggests lifecycle hooks may exist.
- **Copilot CLI has no hook surface**.

On hosts that support hooks, F-039 enforcement can be elevated from "guardrail" (cooperative — depends on agent invoking canonical path) to "wall" (runtime — host refuses the call before the agent gets a chance to bypass). This is a real defense-in-depth upgrade with concrete scenarios it would catch:

1. **Rogue agent writes directly to boundary state files** (any host with hooks)
2. **Compromised subagent attempts to bypass approval** (Claude Code with `SubagentStart` hook)
3. **Stale session state restored without re-authorization** (PreToolUse intercepts the resume)
4. **F-040 multi-host scenarios where Codex agent has no slash-command discoverability and might skip the canonical path** (hook would force the check anyway)

Without this proposal, F-040's multi-host launch on Codex inherits F-039's cooperative limitations with no compensating layer. The user gets cost-reduction benefits but pays a strictness cost.

## What

Per-host hook configurations deployed by `specrew init` / `specrew update` that wire host-native lifecycle interceptors to Specrew's existing F-039 authorization helpers. The hooks call into the same `Test-SpecrewBoundaryAuthorization` / `Parse-SpecrewBoundaryAuthorization` helpers F-039 already ships; the hooks are merely the runtime-layer trigger that ensures those helpers are called.

### Pillar 1: Hook config templates per host (~4-5 SP)

Per-host hook configurations as templates that Specrew deploys.

**Claude Code** — `.claude/settings.json` with hook entries:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "filter": { "files": [".specrew/start-context.json", ".specrew/last-validator-summary.json"] },
        "command": "pwsh -File .specify/extensions/specrew-speckit/scripts/hooks/pretool-boundary-state-write.ps1"
      }
    ],
    "SubagentStart": [
      {
        "command": "pwsh -File .specify/extensions/specrew-speckit/scripts/hooks/subagent-start-roster-check.ps1"
      }
    ],
    "Stop": [
      {
        "command": "pwsh -File .specify/extensions/specrew-speckit/scripts/hooks/stop-session-persist.ps1"
      }
    ]
  }
}
```

**Antigravity** — JSON hook config at `.agents/hooks.json` (per 2026-05-23 research, structurally similar to Claude).

**Codex** — TBD; ship template once Codex's hook surface is documented. Proposal 105's MVP can ship without Codex coverage and add it as a follow-up small-fix slice.

**Copilot** — no hook surface; explicitly out-of-scope. Cooperative enforcement remains the only mechanism on Copilot.

### Pillar 2: Hook handler scripts (~4-5 SP)

PowerShell scripts at `scripts/hooks/*.ps1` that:

- Read the host's hook-context (typically a JSON blob describing the intercepted tool call)
- Call into `shared-governance.ps1` authorization helpers (`Test-SpecrewBoundaryAuthorization`, etc.)
- Return exit code 0 (allow) or 2 (deny per Claude Code's hook convention) with structured rejection reason
- Log the interception to `.squad/decisions.md` for audit trail

Specific handlers:

| Handler | Purpose |
|---|---|
| `pretool-boundary-state-write.ps1` | Validate authorization before any write to `.specrew/start-context.json` boundary_enforcement section |
| `subagent-start-roster-check.ps1` | Validate subagent identity matches expected roster from `.specrew/coordinator/team.md` |
| `stop-session-persist.ps1` | Persist last-session state for resume |
| `posttool-decisions-append.ps1` | Auto-append decision-ledger entries for tool calls that match patterns |

### Pillar 3: Hook deployment integrated into init/update (~2-3 SP)

`specrew init` and `specrew update` gain a `Deploy-SpecrewHostHooks -Host <kind>` step:

- For Copilot: no-op (no hook surface)
- For Claude Code: write `.claude/settings.json` hook configuration; merge with existing settings non-destructively
- For Antigravity: write `.agents/hooks.json`
- For Codex: no-op until Codex hook surface documented

Deployment respects `.specrew/host-history.yml` (Proposal 104) — only deploys hooks for hosts the project has selected via `--host`.

### Pillar 4: Friction-dial integration (~2-3 SP)

Hook deployment is opt-in per friction mode (Proposal 100):

| Friction mode | Hook deployment |
|---|---|
| `strict` | Hooks deployed; runtime enforcement active |
| `default` | Hooks deployed; runtime enforcement active (same as strict — most users want the safer default) |
| `autonomous` | Hooks **NOT** deployed; cooperative enforcement only (matches autonomous mode's existing posture of trusting the agent) |

This respects the same principle as Proposal 066's `--autonomous` flag: explicit opt-out for unattended runs that trade strictness for throughput.

## How

| Step | File | Effort |
|---|---|---|
| `.claude/settings.json` hook template + merge logic | `templates/claude/settings.json` (new) + `scripts/internal/deploy-host-hooks.ps1` (new) | 2 SP |
| `pretool-boundary-state-write.ps1` handler | `scripts/hooks/pretool-boundary-state-write.ps1` (new) | 1.5 SP |
| `subagent-start-roster-check.ps1` handler | `scripts/hooks/subagent-start-roster-check.ps1` (new) | 1 SP |
| `stop-session-persist.ps1` handler | `scripts/hooks/stop-session-persist.ps1` (new) | 1 SP |
| `posttool-decisions-append.ps1` handler | `scripts/hooks/posttool-decisions-append.ps1` (new) | 1 SP |
| Antigravity `.agents/hooks.json` template + deployment | `templates/agents/hooks.json` (new) | 1.5 SP |
| `Deploy-SpecrewHostHooks` integration in init + update | `scripts/specrew-init.ps1`, `scripts/specrew-update.ps1` | 2 SP |
| Friction-dial gating | depends on Proposal 100 shipping first; conditional logic in `Deploy-SpecrewHostHooks` | 2 SP |
| Integration tests per host | `tests/integration/host-hook-deployment.tests.ps1` (new) | 2-3 SP |
| Docs (user-guide host-enforcement section) | `docs/user-guide.md` | 1 SP |

Total: ~14-16 SP.

## Acceptance criteria

| AC | Statement |
|---|---|
| AC1 | After `specrew init` on a project with `--host claude` history, `.claude/settings.json` contains hook entries calling Specrew's PreToolUse handler |
| AC2 | A `PreToolUse` hook on Claude Code fires when an agent attempts to write `.specrew/start-context.json` without valid boundary authorization and the write is REJECTED |
| AC3 | A `PreToolUse` hook on Claude Code allows the same write when valid authorization is present |
| AC4 | `SubagentStart` hook validates that subagent identity matches a name in `.specrew/coordinator/team.md`; unknown subagents are rejected |
| AC5 | Hook handlers log every interception to `.squad/decisions.md` with timestamp, hook type, tool call summary, and decision (allow/deny) |
| AC6 | Friction mode `autonomous` does NOT deploy hooks; cooperative enforcement is the only layer on that mode |
| AC7 | `specrew update` non-destructively merges hook entries into existing `.claude/settings.json` (preserves any user-added entries) |
| AC8 | Antigravity hook deployment ships in v1 if Antigravity hook surface is documented at implementation time; otherwise deferred to follow-up |
| AC9 | Codex hook deployment is no-op in v1 (documented limitation); follow-up slice adds it when Codex hook surface is documented |
| AC10 | Hooks compose with F-039 — they don't replace the slash-command-side gate, they add a runtime-layer in front of it |

## Out of scope

- **Copilot CLI hook deployment** — Copilot has no hook surface; cooperative enforcement remains the only mechanism. If Copilot adds hooks in the future, fold into a small-fix slice
- **Codex hook deployment** — defer until Codex's hook surface is documented; the proposal architecture accommodates Codex addition as a follow-up
- **Hook-based MCP server lifecycle management** — separate concern; out-of-scope
- **Hook-based cost-attribution** — Proposal 070 (Token Economy MVP) owns; could compose later
- **Hooks for non-boundary scenarios** (e.g., test failures, lint failures) — narrow scope to boundary enforcement in v1; broader hook usage is follow-up

## Composition

| Proposal | Relationship |
|---|---|
| **065 (Launch-Mode Boundary Enforcement)** — shipped | Prerequisite. This proposal layers runtime enforcement ON TOP of F-039's authorization helpers. Without 065's `Test-SpecrewBoundaryAuthorization`, this proposal has nothing to gate. |
| **069 (Multi-Host Launch Path)** | Direct dependency. 069 ships the per-host launch surface; this proposal adds host-native runtime enforcement on the hosts 069 launches. |
| **104 (Multi-Host Onboarding + Selection Flow)** | Composes via `.specrew/host-history.yml` — hook deployment only fires for hosts the project has used via `--host`. |
| **100 (Friction Dial)** | Pillar 4 of this proposal gates hook deployment on friction mode. Hook deployment is the default behavior in strict + default modes; opt-out in autonomous mode. |
| **024 (Multi-Host Runtime Abstraction)** | This proposal is a near-term concrete step toward Slice 3 of 024 (host-native runtime depth). When 024 ships full per-host abstraction, this proposal's hook deployment is one of the surfaces 024 generates. |
| **038 (Adaptive Boundary Discipline)** | Future composition: when 038 ships boundary-class classifications (mechanical-execution vs human-judgment-required), hooks can fire selectively per class. |

## Risks

- **Hook misconfiguration breaks user workflows** — Mitigation: hooks call exit-code-2-with-reason on rejection rather than crashing; integration tests validate happy-path + rejection paths
- **Host runtime evolution breaks hook contracts** — Claude Code's hook API is recent; format may shift. Mitigation: pin hook config to specific schema; version-detect at deploy time
- **Hook-induced slowdowns** — Each tool call invokes PowerShell startup overhead. Mitigation: handlers stay lean (< 100ms target); leverage F-035's parallel execution pattern where applicable
- **Codex/Antigravity hook surfaces shift before v1 ships** — Mitigation: ship Claude-only v1 if needed; other hosts as follow-up slices
- **Friction-dial integration depends on Proposal 100 shipping** — Mitigation: this proposal can ship before Proposal 100 with hooks always-on (default behavior); Proposal 100 integration becomes a small-fix follow-up when 100 ships

## Empirical motivation

The 2026-05-22 F-039 implementation session surfaced this gap during the Crew autonomous-advance incident retro. F-039's mechanical gate did fire correctly when the agent invoked the canonical sync path, but the underlying threat model ("agent writes directly to state files") was never closed because no host-runtime interception layer exists. F-040's plan-boundary review (2026-05-23) explicitly identified the gap when the user asked "how we enforce our gate validation, without the proper hook?" — making the case for this proposal concrete.

## Cross-references

- file:///C:/Dev/Specrew/proposals/065-launch-mode-boundary-enforcement.md (foundation)
- file:///C:/Dev/Specrew/proposals/069-multi-host-launch-path.md (composes; per-host launch)
- file:///C:/Dev/Specrew/proposals/104-multi-host-onboarding-and-selection-flow.md (composes; host history)
- file:///C:/Dev/Specrew/proposals/100-friction-dial.md (composes; deployment gating)
- file:///C:/Dev/Specrew/proposals/024-multi-host-runtime-abstraction.md (architectural endgame)
- file:///C:/Dev/Specrew/specs/039-launch-mode-boundary-enforcement/spec.md (current F-039 enforcement)
- file:///C:/Dev/Specrew/specs/040-multi-host-launch-path/research.md (Task 5 capability comparison)
- file:///C:/Dev/Specrew/proposals/INDEX.md
