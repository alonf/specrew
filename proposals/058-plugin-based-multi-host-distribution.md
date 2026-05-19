---
proposal: 058
title: Plugin-Based Multi-Host Distribution (Per-Host Plugin Packaging)
status: candidate
phase: phase-3
estimated-sp: 28
discussion: tbd
---

# Plugin-Based Multi-Host Distribution

## Why

Specrew today distributes via PowerShell Gallery (`Install-Module Specrew`). The full bootstrap UX requires the user to:

1. Open a terminal (outside their AI agent session)
2. Start `pwsh`
3. Install Spec Kit (Python), Squad (npm), Specrew (PSGallery) — three ecosystems
4. Navigate to a project directory
5. Run `specrew init`
6. Run `specrew start` — which launches their AI agent session
7. Switch focus back into the agent
8. Start working

Eight steps, three context switches, three runtime ecosystems. Real adoption friction.

Meanwhile, every major AI agent host (Claude Code, GitHub Copilot CLI, Codex CLI) has a plugin or extension mechanism that's literally designed for the kind of work Specrew does — registering commands, agents, hooks, skills, and MCP servers with the host. Specrew's capabilities map cleanly to plugin extension points.

This proposal packages Specrew as a per-host plugin so the bootstrap UX collapses to:

1. Open the agent host
2. `/plugin install specrew`
3. [first run prompts for missing dependencies — user confirms]
4. Navigate to a project
5. `/specrew.init` (slash command, in-host)
6. Start working

Six steps, ONE context (the agent host throughout). User never leaves the agent session.

The polyglot stack (Spec Kit Python + Squad npm + Specrew PowerShell) becomes invisible — handled by the plugin's first-run dependency detection. The polyglot architecture converts from an adoption liability into an architectural strength (each tool keeps its best-fit ecosystem; the plugin abstraction unifies the user-facing experience).

## What

### Architecture

Per-host plugin packages register Specrew's host-facing capabilities with each agent host's plugin/extension system. The plugin DOES NOT replace PSGallery distribution — it COMPLEMENTS it. Clean layering:

```text
Per-host plugin (installed in the agent host)
       ↓ registers
   Slash commands + agents + hooks + skills + MCP servers
       ↓ which invoke
   PSGallery-distributed Specrew module (project bootstrap + templates)
       ↓ which produces
   Project-level .specrew/, .specify/, .squad/, specs/ artifacts
```

### Specrew capabilities → plugin extension points

| Specrew capability | Plugin extension point |
|---|---|
| `/speckit.*` + `/specrew.*` slash commands | Plugin **commands** |
| Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator agents | Plugin **agents** |
| Validator hooks at lifecycle boundaries | Plugin **hooks** |
| Specrew governance skills (Squad-native skill definitions) | Plugin **skills** |
| Vendor adapters (per Proposal 057): GitHub Projects, Linear, Jira | Plugin **MCP servers** |
| Closeout artifact templates, ceremony prompts | Plugin **resources** |

Every capability maps to a standard extension point. This isn't coincidence — plugin systems were designed for the "extend the agent with structured behavior" pattern.

### Plugin systems per host

| Host | Plugin/extension mechanism | Confidence |
|---|---|---|
| **Claude Code** | Full Plugins system: commands, agents, hooks, skills, MCP servers, output styles, status lines. Marketplace exists. `/plugin install <name>`. | High |
| **GitHub Copilot CLI** | `/plugin` command exists per user observation 2026-05-19; specifics need verification at planning time. | Medium |
| **Codex CLI** | Extension story exists (MCP servers at minimum); plugin specifics need verification. | Lower |

The plugin format and registration API differ per host. Proposal 058 produces three per-host packages from a single canonical capability set.

### Pattern A: Plugins for host integration; PSGallery for project bootstrap (recommended)

```text
Claude Code:    claude plugin install specrew    → registers commands/agents/hooks/skills
                                                    Then: specrew init bootstraps project
Copilot CLI:    copilot plugin install specrew   → same
Codex CLI:      codex plugin install specrew     → same
```

Clean separation:
- **Plugin = host integration** (registers Specrew's slash commands, agents, hooks, skills with the host)
- **PSGallery module = portable project templates + shell entrypoint** (used by `specrew init` to scaffold project files)

This composes with F-019's existing PSGallery distribution rather than replacing it. PSGallery becomes the canonical project-bootstrap layer; plugins become the per-host agent-integration layer.

### Pattern B: Plugin bundles everything (rejected for v1)

Alternative considered: plugin install does the whole thing including auto-running `specrew init` on first directory use. More streamlined UX but blurs concerns. Per-host plugin must carry the entire Specrew toolchain.

Rejected because:
- Each host's plugin must include all PSGallery module content (bloat; replication)
- Updates require coordinated per-host plugin republishes
- Doesn't compose with F-019's existing distribution model

### Dependency installation handling

Specrew depends on three tools across three ecosystems:

| Tool | Ecosystem | Install today |
|---|---|---|
| Spec Kit | Python | `pip install speckit` |
| Squad | npm | `npm install -g squad` |
| Specrew | PowerShell Gallery | `Install-Module Specrew` |

Plugin marketplaces generally can't auto-resolve transitive dependencies across these ecosystems. Two viable patterns:

**Pattern A (recommended)**: detect-and-prompt at first use.

```text
Specrew plugin installed!

Checking dependencies...
  • Spec Kit: not found.            Install via pip? [Y/n]
  • Squad: not found.                Install via npm? [Y/n]
  • Specrew module: not found.       Install via Install-Module? [Y/n]

All set! Run /specrew.init in any project to get started.
```

- Plugin first-run script checks each dependency
- Prompts user to install missing ones (no silent install; user confirms each)
- Plugin executes the appropriate installer (`pip` / `npm` / `Install-Module`) per ecosystem

**Pattern B**: declare dependencies in plugin manifest if host supports it.

- Some hosts may support cross-ecosystem dependency declarations
- Marketplace handles install order
- Less control but cleaner if available

Recommend Pattern A as the universal fallback; Pattern B as opportunistic when the host supports it.

### `/specrew.init` and `/specrew.start` reintroduced as slash commands

[Proposal 032 (Slash-Command Surface, shipped as F-021)](file:///C:/Dev/Specrew/proposals/032-specrew-slash-commands.md) deliberately EXCLUDED `/specrew.init` and `/specrew.start` from its v1 catalog. Reasoning at the time:

- `/specrew.init` was circular — slash commands require a Specrew-bootstrapped project, but init bootstraps the project
- `/specrew.start` was circular — you're already in an agent session if you can invoke slash commands

**Plugin distribution changes this calculus**. Plugins are HOST-LEVEL (installed in Claude Code / Copilot CLI / Codex CLI itself), not project-level. So:

- `/specrew.init` slash command is available BEFORE any project bootstrap. User opens a directory, runs `/specrew.init` → bootstraps the project. **Coherent.**
- `/specrew.start` reframes from "launch session" to "load Specrew context for current project". Useful if the user opened a new project AFTER the agent session started. **Coherent with reframing.**

Proposal 058 adds both commands to the plugin's command catalog. The exclusion from F-021's v1 catalog was correct for the shell-install model; plugin distribution changes the assumptions.

### Updated v1 plugin command catalog

Per-host plugin ships these slash commands:

| Slash command | Source | Description |
|---|---|---|
| `/specrew.init` | NEW (plugin-enabled) | Bootstrap a project from inside the agent |
| `/specrew.start` | NEW (plugin-enabled) | Load Specrew context for current project |
| `/specrew.where` | F-021 (shipped) | Render velocity dashboard |
| `/specrew.status` | F-021 (alias) | Alias for `/specrew.where` |
| `/specrew.update` | F-021 (shipped) | Update Specrew templates and config |
| `/specrew.team` | F-021 (shipped) | Manage Squad team roster |
| `/specrew.review` | F-021 (shipped) | Trigger or inspect Specrew review session |
| `/specrew.help` | F-021 (shipped) | Show full Specrew slash-command catalog |
| `/specrew.version` | Proposal 050 (queued) | Show installed Specrew version |
| `/specrew.config` | Proposal 047 (queued) | View / edit governance profile |

Plus the `/speckit.*` commands (Spec Kit's slash command surface) — these continue to come from Spec Kit's own distribution; the plugin just ensures they coexist cleanly with `/specrew.*`.

### "Without leaving Copilot" UX comparison

Today's user experience (shell-install model):

```text
1. Open terminal (outside Copilot)
2. pwsh
3. Install-Module Specrew
4. Install Spec Kit, Squad separately
5. cd my-project
6. specrew init
7. specrew start              ← this launches Copilot
8. Now in Copilot, do work
```

Eight steps, three context switches between terminal and Copilot.

Plugin-install model (post-Proposal 058):

```text
1. Open agent host (Copilot CLI / Claude Code / Codex CLI)
2. /plugin install specrew
3. [first-run prompts: install Spec Kit? Squad? — user confirms]
4. cd my-project (or open project)
5. /specrew.init
6. Do work
```

Six steps, ONE context (the agent host throughout). User never leaves the session.

**Massive adoption-friendly UX improvement** — converts "I saw Specrew, looked complicated, didn't try" into "I tried it in 30 seconds".

## Effort

~28 SP across two iterations.

### Iteration 1 (~14 SP) — Claude Code plugin (primary first target)

- Claude Code plugin package format definition + manifest schema (~2 SP)
- Map Specrew capabilities to Claude Code extension points: commands, agents, hooks, skills (~4 SP)
- Plugin first-run dependency detection + install prompts (Pattern A) (~3 SP)
- `/specrew.init` and `/specrew.start` slash-command implementations + their host-level semantics (~2 SP)
- Update story: `claude plugin update specrew` + version-check coupling per Proposal 049 refinements (~1 SP)
- Marketplace listing strategy + author docs (~1 SP)
- Tests + documentation (~1 SP)

### Iteration 2 (~14 SP) — Copilot CLI plugin + Codex CLI plugin

- Copilot CLI plugin format definition + manifest schema (~3 SP)
- Map capabilities to Copilot CLI extension points (~3 SP)
- Codex CLI plugin format definition + manifest schema (~3 SP)
- Map capabilities to Codex CLI extension points (degraded gracefully if Codex lacks features like hooks) (~3 SP)
- Per-host install verification + cross-host parity tests (~1 SP)
- Documentation: per-host install + usage + troubleshooting (~1 SP)

## Phase placement

**Phase 3 (alongside Multi-Host Runtime Abstraction CORE).** Partner proposal to [Proposal 024](file:///C:/Dev/Specrew/proposals/024-multi-host-runtime-abstraction.md):

- **Proposal 024** is the RUNTIME side — how Specrew executes on different hosts (canonical state + per-host projections)
- **Proposal 058** is the DELIVERY side — how Specrew gets INSTALLED on different hosts (per-host plugin packages)

Both proposals are needed for genuine multi-host capability. Ship together as a combined Phase 3 feature.

**Alternative**: ship a Copilot-only subset (Iteration 1's Copilot-CLI plugin) in Phase 2 pre-public-flip. This delivers the in-agent UX improvement immediately for the current primary host without waiting for full multi-host runtime work. Then ship the Claude Code + Codex CLI plugins (Iteration 2) in Phase 3 alongside Proposal 024. Worth resolving at the post-F-022 consolidation pass.

**Priority tier**: Tier 3 (Scale — reach more users). Substantial adoption potential because each agent host's user base becomes addressable.

## Composition with existing queue

| Proposal | Composition |
|---|---|
| **F-019 / Proposal 031 (PSGallery Distribution, shipped)** | Plugin COMPLEMENTS PSGallery — doesn't replace. Module = project bootstrap; plugin = agent-host integration. Clean layering. |
| **Proposal 024 (Multi-Host Runtime Abstraction CORE)** | PARTNER proposal — 024 is runtime, 058 is delivery. Both needed for multi-host. Recommended bundle as a combined Phase 3 feature. |
| **F-021 / Proposal 032 (Slash-Command Surface, shipped)** | F-021's slash commands become plugin commands. F-021 work reusable. F-021 deliberately excluded `/specrew.init` and `/specrew.start`; 058 reintroduces them under plugin model. |
| **Proposal 050 (Version Surface Discoverability)** | `/specrew.version` is one of the plugin's commands; composes naturally. |
| **Proposal 047 (Project Governance Profile)** | `/specrew.config` plugin command surfaces the governance profile; composes naturally. |
| **Proposal 052 (Specrew Profile System)** | Profiles are Specrew-specific extension points; plugins are host-specific delivery mechanisms. Compose without overlap. |
| **Proposal 057 (Roadmap Spine + Adapters)** | Vendor adapters (GitHub Projects, Linear, Jira) can ship as separate small plugins OR bundled into the main plugin. Decided per-adapter. |
| **Proposal 049 (Version-Check Source Unification, partly fixed)** | Plugin version + module version coupling check at runtime; composes with version-check refinements. |
| **F-021 retro Lesson 7 — Restart after Specrew update** | Plugin update story should handle "Specrew was updated since session started" warning automatically. |

## Open questions

1. **Plugin install + PSGallery install ordering** — does the plugin install also pull the PSGallery module automatically, or are they fully independent? Recommend: plugin's first-run dependency check handles PSGallery install via Pattern A.
2. **Per-project `specrew init` flow** — auto-trigger on first directory, or require explicit `/specrew.init` invocation? Recommend: explicit invocation; auto-triggering risks accidental bootstrap of unintended directories.
3. **Squad / Spec Kit bundling** — should the plugin bundle them, or rely on Pattern A's detect-and-install? Recommend: rely on detect-and-install. Bundling is bloat + update-coordination burden.
4. **Per-host update story** — `claude plugin update specrew` cascades to which dependencies? Recommend: plugin update updates the plugin itself only; user is prompted if dependency versions are stale (similar to first-run check).
5. **Marketplace gating** — Claude Code marketplace may require verification; vendor plugins may need approval. Mitigation strategy?
6. **Plugin version + module version divergence** — if the plugin is v1.2 but the user's PSGallery module is v0.21.0, what's the behavior? Recommend: plugin's first-run check warns; user can choose to continue (with degraded capability) or upgrade.
7. **Per-host capability differences** — if Codex lacks hooks, what's the degraded experience? Recommend: graceful degradation — Specrew warns when invoking an unsupported capability; rest works normally.
8. **Plugin install as primary vs advanced path** — should the plugin install be the recommended path going forward, with PSGallery-only install as advanced/scripted fallback? Recommend: yes, plugin install primary for the public-flip era.
9. **Plugin discovery** — open-source plugin published to each host's marketplace, OR install-from-URL/repo? Recommend: marketplace primary; URL/repo fallback supported.
10. **Update story for plugin itself** — does the plugin self-update, or rely on host's plugin-update mechanism? Recommend: rely on host's plugin-update — don't reinvent.

## Risks

- **Per-host plugin format drift**: maintaining 3 different plugin formats means triple the keep-up-with-vendor work. Mitigation: per-host plugin as a separate sub-feature; can defer Codex if budget exhausted. Profile-based authoring (per Proposal 052) lets community contribute per-host adapters.
- **Marketplace gating**: vendor plugin marketplaces may require verification, signing, or approval. Some plugins may need to wait for marketplace authorization. Mitigation: maintain install-from-URL/repo as fallback; document the per-host marketplace process.
- **Confusion vs PSGallery distribution**: users may not understand which install path to use. Mitigation: documentation; recommend plugin install as primary, PSGallery as advanced/scripted fallback.
- **Plugin update vs Specrew update divergence**: if plugin pins one version + PSGallery module is another, behavior diverges. Mitigation: plugin version + module version coupling check at runtime (composes with Proposal 049).
- **Per-host capability gaps**: not all hosts support all extension points (Codex may lack hooks; Copilot CLI may lack certain skill types). Mitigation: graceful degradation — Specrew warns when invoking an unsupported capability; documentation lists per-host support matrix.
- **Authentication for marketplace publishing**: each marketplace requires its own credentials / publishing process. Mitigation: CI/CD automation per host; per-marketplace secret management (composes with Proposal 045 CI Watchdog).
- **Plugin authoring duplication**: writing three similar plugins risks divergence. Mitigation: single canonical capability set in Specrew; per-host plugin generators produce the packages from one source.

## Cross-references

- **[Proposal 024 (Multi-Host Runtime Abstraction CORE)](file:///C:/Dev/Specrew/proposals/024-multi-host-runtime-abstraction.md)** — partner proposal; ship together
- **[Proposal 031 / F-019 (Specrew Distribution Module)](file:///C:/Dev/Specrew/proposals/031-specrew-distribution-module.md)** — current PSGallery distribution; complement
- **[Proposal 032 / F-021 (Slash-Command Surface)](file:///C:/Dev/Specrew/proposals/032-specrew-slash-commands.md)** — slash commands reused; init/start exclusion reverted under plugin model
- **[Proposal 047 (Project Governance Profile)](file:///C:/Dev/Specrew/proposals/047-project-governance-profile.md)** — `/specrew.config` command surface
- **[Proposal 049 (Version-Check Source Unification)](file:///C:/Dev/Specrew/proposals/049-version-check-source-unification.md)** — plugin + module version coupling
- **[Proposal 050 (Version Surface Discoverability)](file:///C:/Dev/Specrew/proposals/050-version-surface-discoverability.md)** — `/specrew.version` command
- **[Proposal 052 (Specrew Profile System)](file:///C:/Dev/Specrew/proposals/052-specrew-profile-system.md)** — profiles vs plugins distinct concerns
- **[Proposal 055 (Always-In-Flow + Bug-Fix Lifecycle)](file:///C:/Dev/Specrew/proposals/055-always-in-flow-bug-fix-lifecycle.md)** — slice types as plugin extensibility
- **[Proposal 057 (Roadmap Spine + Adapters)](file:///C:/Dev/Specrew/proposals/057-roadmap-spine-input-adapter-pattern.md)** — vendor adapters distributable as separate plugins
- **Memory: [Plugin-based distribution candidate (2026-05-19)](file:///C:/Users/alon.HOME/.claude/projects/C--Dev-Specrew/memory/project_plugin_based_distribution_proposal_candidate_2026_05_19.md)** — original capture

## Status history

- 2026-05-19: candidate captured after user observation of Copilot CLI's `/plugin` command. Cross-host plugin packaging recognized as the right abstraction for Specrew's polyglot stack (Python + npm + PowerShell). Initial capture in memory.
- 2026-05-19: drafted as full proposal during the post-F-022 consolidation pass. Composition with proposals 024, 031, 032, 047, 049, 050, 052, 055, 057 made explicit. Phase 3 placement alongside Proposal 024 (Multi-Host CORE) as partner proposal.
