---
proposal: 069
title: Multi-Host Launch Path + Per-Host Flag Pass-Through (Claude Code + Codex)
status: draft
phase: phase-2
estimated-sp: 9-10
discussion: ad-hoc 2026-05-20 session; expanded 2026-05-21 to include --remote flag pass-through
release-urgency: immediate
---

# Multi-Host Launch Path

## Why

User is already paying for Claude Code ($200/mo) and Codex CLI ($20/mo) independently of Copilot. Today, `specrew start` only launches Copilot CLI. Routing some or all sessions to Claude Code (or Codex) shifts cost from the Copilot meter to a budget the user is already paying — net savings can be substantial, especially with the 10-day Copilot pricing pivot.

Full Multi-Host Runtime Abstraction (Proposal 024, 65 SP) is the architectural endgame. This proposal ships the **MVP slice**: a launch-path branch that lets `specrew start --host claude` (or `--host codex`) start the appropriate CLI with Specrew's bootstrap context, instead of `copilot`. No deep abstraction; just routing.

Composes with Proposal 068 (model catalog) — once both ship, Squad knows which models are available on each host and can route tasks accordingly.

## What

Three pillars:

### Pillar 1: Host detection (~1 SP)

`scripts/specrew-start.ps1` gains host detection logic that runs on every start:

- Check for `claude` binary on PATH (Claude Code CLI)
- Check for `codex` binary on PATH (Codex CLI)
- Check for `copilot` (or `gh copilot`) binary on PATH
- Record detected hosts in `.specrew/start-context.json` (new field: `available_hosts`)

The detection is informational; no behavior change without explicit `--host` flag.

### Pillar 2: `--host` parameter on `specrew start` (~3-4 SP)

`specrew start` gains a `-Host` parameter (with `--host` CLI alias):

- `--host copilot` (default, current behavior)
- `--host claude` — launches Claude Code CLI instead
- `--host codex` — launches Codex CLI instead
- `--host auto` — picks the first available based on a preference order in `.specrew/config.yml`

For each host, the launch command is host-specific:

```text
copilot:  copilot --agent Squad --add-dir <project> -i <bootstrap-prompt> [--allow-all] [--autopilot]
claude:   claude --working-directory <project> [other flags TBD per Claude Code CLI semantics]
codex:    codex --workdir <project> [other flags TBD per Codex CLI semantics]
```

The bootstrap context (`last-start-prompt.md` + `start-context.json`) is the same; only the host-CLI invocation differs. The host adapts to Specrew's contract, not the other way around.

If the requested host isn't installed, Specrew prints actionable guidance ("Claude Code CLI not found on PATH; install per <https://docs.anthropic.com/en/docs/claude-code/installation>") and exits without launching.

### Pillar 3: Per-host slash-command + skill validation (~1-2 SP)

F-024 deploys skills to `.claude/skills/`, `.github/skills/`, `.agents/skills/`. This proposal verifies the deployed skills are discoverable on the actual host being launched:

- `--host claude` smoke: after init, confirm `.claude/skills/specrew-where/SKILL.md` is present and frontmatter parses; warn if missing
- `--host copilot` smoke: confirm `.github/skills/specrew-where/SKILL.md` is present
- `--host codex` smoke: deferred per F-024's discoverability-claim limitation; deploy to `.agents/skills/` and log "future-proof path; no current Codex discoverability guarantee"

### Pillar 4: `--remote` flag pass-through with per-host translation (~2-3 SP)

Added 2026-05-21 per user direction. Both Copilot CLI and Claude Code support remote-control modes that stream the session for steering from mobile/web/IDE clients, but with different flag names:

| Host | Remote-control flag | Notes |
|---|---|---|
| Copilot CLI | `--remote` | Generally available 2026-05-18 — stream to GitHub Mobile / github.com / VS Code; steer, approve, respond remotely. See <https://docs.github.com/en/copilot/concepts/agents/copilot-cli/about-remote-control> |
| Claude Code | `--remote-control` (or `--rc`) | Stream to claude.ai / Claude app. See <https://code.claude.com/docs/en/remote-control> |
| Codex CLI | (none verified) | Defer — no current remote-control surface verified at proposal-draft time |

`specrew start` gains a single `-Remote` (or `--remote`) switch parameter that translates to the host-appropriate flag:

- `--host copilot --remote` → `copilot --remote ...`
- `--host claude --remote` → `claude --remote-control ...`
- `--host codex --remote` → warn-and-continue (Codex doesn't support remote-control today); session launches without remote control rather than fail
- No `--host` flag specified: defaults route through Pillar 2's host-detection logic; `--remote` translation follows the selected host

The flag is the **first instance** of a per-host flag pass-through framework. The translation table for `--remote → --remote / --remote-control` lives in a small helper (e.g., `Get-HostRemoteFlag` in `shared-governance.ps1` or `scripts/internal/host-flag-translation.ps1`) so future per-host flags (e.g., `--prompt-approvals`, `--allow-all` are already host-specific) can compose into the same pattern.

#### Acceptance for Pillar 4

| AC | Statement |
|---|---|
| AC9 | `specrew start --host copilot --remote` invokes `copilot --remote ...` with Specrew's bootstrap context |
| AC10 | `specrew start --host claude --remote` invokes `claude --remote-control ...` (translated flag form) with Specrew's bootstrap context |
| AC11 | `specrew start --host codex --remote` emits an actionable warning and continues without remote control (Codex CLI doesn't expose a remote-control flag today) |
| AC12 | The Codex behavior in AC11 is a deliberate warn-and-continue, NOT a hard fail; users opting into `--remote` on Codex get the session anyway, just without remote-control wiring |

### Pillar 5 (deferred to follow-up): True host abstraction

The full Proposal 024 Multi-Host Runtime CORE introduces a host-neutral protocol where Squad doesn't know which host it's running on. That's 60+ SP of work. **This proposal explicitly defers that** — Squad still talks to one host at a time per session; the user picks the host at launch.

## How

| Step | File | Effort |
|---|---|---|
| Add `-Host` parameter + `--host` CLI parser case | `scripts/specrew-start.ps1` | 1 SP |
| Implement host detection helper | `scripts/internal/detect-hosts.ps1` (new) or inline | 1 SP |
| Implement per-host launch invocation builders | `scripts/specrew-start.ps1` (extend existing copilot-launch logic) | 2 SP |
| Add `available_hosts` + `selected_host` fields to start-context.json schema | `scripts/specrew-start.ps1` | 0.5 SP |
| Add `host_preference_order` field to `.specrew/config.yml` (default: `[copilot, claude, codex]`) | `scripts/specrew-init.ps1` + downstream config | 0.5 SP |
| Per-host smoke verification (skill presence) | `scripts/specrew-start.ps1` | 1 SP |
| `-Remote` switch + per-host flag translation helper | `scripts/specrew-start.ps1` + `scripts/internal/host-flag-translation.ps1` (new) | 1.5 SP |
| Codex `--remote` warn-and-continue path | `scripts/specrew-start.ps1` | 0.5 SP |
| Update help text + docs (including `--remote` per-host semantics) | `scripts/specrew-start.ps1` help block + user-guide + getting-started | 0.5 SP |
| Integration tests (host selection + flag translation) | `tests/integration/start-command-host-selection.ps1` (new) | 1 SP |

Total: ~9-10 SP

## Acceptance criteria

| AC | Statement |
|---|---|
| AC1 | `specrew start --host claude` launches Claude Code CLI (when installed) with Specrew's bootstrap context, not Copilot CLI |
| AC2 | `specrew start --host codex` launches Codex CLI (when installed); deploys skills to `.agents/skills/` only (no current Codex discoverability claim) |
| AC3 | `specrew start --host copilot` (or no `--host` flag) preserves current behavior |
| AC4 | If requested host is not installed, Specrew exits with actionable guidance, not a confusing failure |
| AC5 | `.specrew/start-context.json` records both `available_hosts` (array) and `selected_host` (string) — auditable post-launch |
| AC6 | `--host auto` picks the first available host per `host_preference_order` |
| AC7 | Existing single-host (Copilot) tests continue to pass without modification |
| AC8 | Host-specific skill smoke verification logs warnings when expected skill files are missing on the selected host |

## Out of scope

- **Host-neutral protocol abstraction** (Proposal 024 — 60+ SP). This proposal hard-codes the per-host launch commands; the deep abstraction comes later.
- **Mid-session host switching** — can't change host mid-session in v1. User must end the session and restart with a different `--host`.
- **Multi-host parallel execution** — only one host runs per session.
- **Codex discoverability guarantee** — `.agents/skills/` is deployed but no Codex CLI discoverability is claimed (consistent with F-024).
- **Codex remote control** — Codex CLI doesn't expose a remote-control surface today; `--remote --host codex` warns and continues without remote wiring (AC11). When Codex ships a remote surface, that gets folded into Pillar 4's translation table as a follow-up small-fix.
- **Cost reporting per host** — that's Proposal 070 (Token Economy MVP).
- **Per-role host routing** — e.g., "use Claude for review, Copilot for implementation" — needs Proposal 024's protocol abstraction.
- **Other per-host flag pass-through** — `--allow-all`, `--autopilot`, etc. are already host-specific but handled inline today. Pillar 4 establishes the pattern via the translation helper; future flags can compose in via small-fix slices when needed.

## Composition

| Proposal | Relationship |
|---|---|
| **024 (Multi-Host Runtime CORE)** | Architectural endgame; this proposal is its tactical MVP. When 024 ships, this proposal's host-CLI invocations get refactored into 024's protocol. |
| **068 (Cost-Aware Model Routing)** | Catalog (in 068) covers per-host models; routing (in 068) makes assumptions about which host is active. 069 + 068 together = "pick host, pick model within host, route tasks." |
| **070 (Token Economy MVP)** | Cost tracking needs to know which host is active to compute cost. Both proposals add host-awareness to artifacts. |
| **F-024 (in flight)** | Deploys skills to `.claude/`, `.github/`, `.agents/`. Without F-024, this proposal's per-host skill verification (Pillar 3) has no skills to verify. F-024 is a prerequisite. |
| **067 (Small-Fix Slice)** | This proposal's ship cycle uses the 067 contract: code + tests + CHANGELOG + proposal-entry + INDEX update at ship time. |

## Cross-references

- Memory: `[[project-copilot-cost-baseline-and-strategy-2026-05-16]]` — cost baseline
- file:///C:/Dev/Specrew/proposals/024-multi-host-runtime-abstraction.md
- file:///C:/Dev/Specrew/proposals/068-cost-aware-model-routing.md
- file:///C:/Dev/Specrew/proposals/070-token-economy-mvp.md
- file:///C:/Dev/Specrew/proposals/INDEX.md
