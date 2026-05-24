# Specrew v0.26.0 — Multi-Host Launch Path

**Released**: 2026-05-23 (target — pending PR #805 merge)

## TL;DR

Specrew now runs on three hosts instead of one. Pick at launch time with `--host`:

```powershell
specrew start --host copilot "<task>"   # default; pre-v0.26.0 behavior
specrew start --host claude  "<task>"   # NEW: launches Claude Code with Specrew's bootstrap
specrew start --host codex   "<task>"   # NEW: launches Codex CLI with Specrew's bootstrap
```

Per-host flag translation keeps the Specrew surface uniform: `--remote`, `--allow-all`, `--autopilot` all "just work" across hosts — Specrew translates each to the host-native flag name.

This is the **tactical MVP slice** of multi-host runtime abstraction. Cost-aware model routing (F-041) and per-iteration token economy (F-042) build on this in the next two minor releases. Together they multiply effective budget by alternating across hosts.

## Why this ships now

The 2026-05-30 Copilot pricing pivot is 7 days away. v0.26.0 unlocks the workflow shift: instead of all work hitting Copilot's premium-request quota, you can alternate to Claude Code (your $200/mo Claude Max subscription) or Codex CLI for a portion of the work. Manual alternation works today; automatic Junior→cheap-model routing arrives with v0.27.0 (F-041).

## What's new

### `specrew start --host <kind>`

The headline feature. Three supported kinds:

| `--host` | CLI binary | Bootstrap surface |
|---|---|---|
| `copilot` (default) | `copilot` | `copilot --agent Squad --add-dir <project> -i <prompt>` |
| `claude` | `claude` | `claude -p <prompt> --add-dir <project>` |
| `codex` | `codex` | `codex exec --cd <project> <prompt>` |

Reserved-but-deferred kinds:

- `antigravity` — rejected with explicit guidance (separate follow-up slice once `agy` working-directory + session-ID issues resolve upstream)
- `auto` — rejected with explicit guidance (reserved for F-043 / Proposal 104 first-run probe)

### Per-host flag translation

User-facing flags stay uniform; Specrew translates per host:

| Specrew flag | Copilot | Claude | Codex |
|---|---|---|---|
| `--remote` | `--remote` | `--remote-control` | warn-and-continue (no remote surface) |
| `--allow-all` | `--allow-all` | `--dangerously-skip-permissions` | `--full-auto` |
| `--autopilot` | `--autopilot` | drop with notice (no Claude equivalent) | `--full-auto` (folds into `--allow-all`) |

### Universal Crew-coordinator header

The coordinator prompt's opening line is now **the same across all hosts**, aligning with the project's terminology (the Crew = team role; Squad = npm runtime product):

```text
You are the Crew team coordinator running inside a Specrew-bootstrapped repository.
```

This replaces the pre-v0.26.0 line `"You are Squad running inside a Specrew-bootstrapped repository."` for ALL hosts including Copilot. Behavioral impact is minimal (Squad agents continue to function as before); terminology is cleaner. See migration guide below for details.

### Squad-runtime-path directive strip for non-Copilot hosts

When the selected host is Claude or Codex, Specrew strips directives that reference `.squad/decisions.md`, `.squad/config.json`, `agentModelOverrides`, and `sync-squad-model-overrides.ps1` — those paths don't exist when running on Claude/Codex. Copilot+Squad runs retain these directives unchanged.

### Codex-specific pwsh-form boundary-advance instructions

Codex has no user-defined slash-command surface. Specrew rewrites coordinator-prompt slash-command references (e.g., `/speckit.specrew-speckit.sync-plan`) as direct PowerShell invocations (`pwsh -File ... sync-boundary-state.ps1 -BoundaryType plan`) when the selected host is Codex. The agent can discover Specrew's canonical authorization path without slash commands.

### Per-host skill verification

Specrew already deploys slash-command skills to `.github/skills/`, `.claude/skills/`, `.agents/skills/` per F-021. v0.26.0 adds a per-host verification: when you launch `--host claude`, Specrew checks `.claude/skills/` for the expected SKILL.md files and logs a warning if any are missing. Non-fatal — launch proceeds.

### `.specrew/start-context.json` schema additions

New additive fields (schema v2 unchanged):

- `selected_host` — `"copilot"` / `"claude"` / `"codex"` reflecting the active `--host` kind
- `available_hosts` — map of host kind → bool (PATH probe result)
- `crew_runtime_status` — `"squad-runtime"` (Copilot+Squad) or `"bootstrap_only"` (non-Copilot, no per-host Crew runtime deployed yet — Proposal 024 Slice 3 territory)

Pre-v0.26.0 readers don't need to know about these — they're tolerated as missing optional fields per the Proposal 059 read-tolerance pattern.

### Cooperative-enforcement transparency

F-039's boundary enforcement remains cooperative across all hosts (gate fires when the agent invokes Specrew's canonical sync path). v0.26.0 explicitly documents this in `docs/user-guide.md` and references [Proposal 105](../proposals/105-host-native-hook-deployment.md) as the runtime-upgrade path (deploys Claude Code's PreToolUse hooks to convert cooperative gates into runtime gates).

**Recommendation for strict-mode users**: prefer Copilot or Claude over Codex until Proposal 105 ships, because Copilot/Claude's slash-command surfaces make Specrew's canonical authorization path more discoverable.

## Migration guide

### For maintainer + most users: zero migration needed

Existing projects continue to work without changes. Running `specrew start` (no `--host` flag) preserves pre-v0.26.0 behavior (launches Copilot CLI with Squad agent).

### One behavior change worth noting

The coordinator-prompt opening line changes for ALL hosts (including Copilot):

```diff
- You are Squad running inside a Specrew-bootstrapped repository.
+ You are the Crew team coordinator running inside a Specrew-bootstrapped repository.
```

Squad agents continue to function as before — "Crew" is the team-role name; "Squad" is still the npm runtime product. The change aligns the prompt with the INDEX.md 2026-05-21 terminology note. If you've customized your coordinator prompt, the customization is preserved through normal `specrew update` flows.

### CI scripts: pass `--host copilot` explicitly

If you have CI automation that runs `specrew start --no-launch` in non-TTY environments, the future F-043 first-run probe (Proposal 104) will exit with explicit guidance instead of defaulting silently. To future-proof your CI now:

```diff
- specrew start --no-launch "<task>"
+ specrew start --host copilot --no-launch "<task>"
```

This is forward-compatibility insurance only; no behavior change in v0.26.0.

### Downstream projects using Claude or Codex

If you want to use a non-Copilot host on an existing Specrew project:

1. Install the host CLI (see [docs/getting-started.md](getting-started.md) for install URLs)
2. Run `specrew start --host claude` (or `--host codex`) — Specrew will launch the host with the existing Specrew bootstrap context

Note: the per-host Crew runtime is NOT yet deployed for non-Copilot hosts in v0.26.0. The host receives Specrew's bootstrap prompt but has no `.claude/agents/*.md` or `.codex/agents/*.toml` subagent files. This is `crew_runtime_status: bootstrap_only` — Proposal 024 Slice 3 fills that gap in a later release.

## Smoke test

A maintainer-runnable smoke-test script ships with v0.26.0:

```powershell
pwsh -File tests/manual/multi-host-smoke.ps1
```

Iterates through `--host copilot`, `--host claude`, `--host codex` in a fresh scratch project; verifies the F-040 contract end-to-end. Takes ~5 minutes.

## What's next (post-v0.26.0)

- **v0.27.0** — F-041 / Proposal 068 Cost-Aware Model Routing. Junior tasks auto-route to cheap-tier models; Senior/Reviewer/Spec-Steward stay on strong-tier. Empirical cost reduction.
- **v0.28.0** — F-042 / Proposal 070 Token Economy MVP. Per-iteration `cost.yml` + dashboard COST section + `specrew cost` CLI surface. Measures whether F-041's routing actually saves money.
- **v0.29.0** — F-043 / Proposal 104 Multi-Host Onboarding. First-run host probe + `host-history.yml` + `specrew host` command. UX layer for external testers.
- **TBD small-fix slice** — Antigravity host follow-up (4th host added once `agy --print` working-directory + session-ID issues resolve upstream).
- **TBD feature** — Proposal 105 Host-Native Hook Deployment. Elevate F-039 enforcement from cooperative to runtime on hook-supporting hosts (Claude Code).

## Acknowledgments

This release is the first slice of multi-host runtime abstraction (the 4-slice ladder from Proposal 024). It builds on:

- F-021 (Slash-Command Multi-Host Correctness) — already deploys skills to all three host-skill directories
- F-039 (Launch-Mode Boundary Enforcement) — F-040 honors the boundary-authorization helpers
- F-019 (Specrew Distribution Module) — PSGallery publishing carries v0.26.0 to users

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
