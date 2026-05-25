---
proposal: 104
title: Multi-Host Onboarding + Selection Flow (Init Timing, Host Detection, State Location)
status: shipped
shipped-as: feature-043
shipped-in-version: 0.27.0
phase: phase-2
estimated-sp: 8-12
actual-sp: 11
spec: specs/043-multi-host-onboarding/spec.md
discussion: ad-hoc 2026-05-23 multi-host research session
---

# Multi-Host Onboarding + Selection Flow

## Why

Six concrete architectural questions arose in the 2026-05-23 multi-host research session:

1. At `specrew init` time, do we initialise Copilot / Claude / Codex / Antigravity AND their team-agent surfaces? Or lazy at first `--host` use?
2. If `specrew start` is invoked without `--host`, should the default be "last selected"?
3. If no last-host is recorded AND `--host` is omitted, should Specrew probe the machine, present available hosts, and ask the user to pick?
4. Should the user be able to move between hosts on the same project? Eventually develop concurrently across hosts?
5. Squad keeps state files under `.squad/` (e.g., `decisions.md`). Do we (a) replicate the same pattern on each host's native filesystem convention, or (b) migrate all of it to `.specrew/` so coupling is reduced and migration between hosts is easier?
6. Before choosing an abstraction-layer scope, audit every place Specrew currently calls Squad and decide what must come from the underlying agent team vs from Specrew.

Proposals 069 (Multi-Host Launch Path), 068 (Cost-Aware Model Routing), 070 (Token Economy MVP), and 024 (Multi-Host Runtime Abstraction) cover **launch dispatch**, **routing logic**, **cost attribution**, and the **architectural endgame** respectively. None of them owns the **onboarding + selection UX** as a first-class surface. This proposal slots into that gap and binds the answers to the 6 questions into one coherent flow.

The 2026-05-23 internal Specrew↔Squad coupling audit (full results inline in Proposal 024 as the "Abstraction Surface Inventory" section) is the empirical ground truth this proposal builds on.

## What

### Decision matrix (one row per question)

| # | Question | Decision (v1) | Why |
|---|---|---|---|
| 1 | Init: eager or lazy? | **Lazy.** `specrew init` deploys host-agnostic skill catalogs (`.claude/skills/`, `.github/skills/`, `.agents/skills/` — already covered by F-024 / Proposal 064) but does NOT install Copilot / Claude / Codex / Antigravity CLIs. Host-specific install + Crew-runtime install + per-host state scaffolding happens on first `specrew start --host <kind>` use. | Eager init forces the user to authenticate every host before they pick one. Lazy keeps init fast and host-agnostic; cost of "first use of host X is slower" is paid once per host. |
| 2 | Default = last selected? | **Yes.** `.specrew/host-history.yml` (new) persists `last_selected_host`; `specrew start` with no `--host` uses it. | Matches user mental model — "I'm on this project; I was using Claude here last." |
| 3 | First-run detection + offer? | **Yes.** If `last_selected_host` is unknown AND `--host` is unspecified, Specrew probes PATH for `copilot`, `claude`, `codex`, `agy`; prints the found set; prompts the user to pick. If only one is found, auto-select with a notice. If none, print actionable install guidance. | "Just works" first-run UX. Avoids hardcoding a default that may be wrong for the user's environment. |
| 4 | Movement + concurrent? | **Movement: yes** — `--host <other>` on any `specrew start` flips host; project state persists. **Concurrent: explicit out-of-scope for v1** — single active host per session. Concurrent multi-host = Scenario B of Proposal 024 (~150-200 SP separate effort). | Movement is mechanical given Proposal 069; concurrent needs lockfile + decisions-ledger reconciliation + a UI that doesn't exist yet. |
| 5 | State location — `.squad/` or `.specrew/`? | **Hybrid migration.** **Category A** (Specrew-owned templates currently under `.squad/`: coordinator instructions, charters, ceremonies, directives) migrates to `.specrew/coordinator/` (host-portable). **Category B** (per-host runtime state: `identity/now.md`, `decisions.md`, `team.md`, `config.json`) stays at the host's native convention — `.squad/` for Copilot+Squad, `.claude/` for Claude Code, `.codex/` for Codex, `.agents/` for Antigravity. Specrew adapters read/write per-host paths through a single set of resolver helpers. | Migrating Category B would break the host's own discoverability. Migrating Category A reduces coupling without breaking any host. See [[024]] Categories A-D analysis for the full taxonomy. |
| 6 | Abstraction-layer scope | **Four-slice ladder** (each slice ships independently): **Slice 0** = Proposal 069 (single-line dispatch on launch invocation). **Slice 1** = this proposal — onboarding/selection flow + `.specrew/host-history.yml` + Category A relocation. **Slice 2** = Coordinator-prompt directive surgery (rules 12, 35, 37, 42-44 + `speckit.*` references → per-host variants). **Slice 3** = Full Proposal 024 (host-neutral protocol + adapter layer + concurrent execution). | Each slice is independently shippable. The first three slices unblock multi-host *use*; Slice 3 is the architectural endgame for *team adoption*. |

### Composition surface

`specrew init` (no changes from Proposal 064 baseline):

- Deploys host-agnostic skill catalogs to all known host-skill directories
- Writes Category A coordinator templates to `.specrew/coordinator/` (new — currently in `.squad/`)
- Does NOT touch Crew-runtime CLIs

`specrew start` (this proposal's new logic):

1. If `--host <kind>` specified: use it. Persist as `last_selected_host`.
2. Else if `.specrew/host-history.yml` has `last_selected_host`: use it.
3. Else: probe PATH for known hosts (`copilot`, `claude`, `codex`, `agy`); print available; prompt user.
4. Once host is selected:
   - Probe whether the host's Crew-runtime is installed for this project (per-host inventory: `.squad/agents/`, `.claude/agents/`, `.codex/agents/`, `.agents/agents/`)
   - If missing: run per-host Crew bootstrap (Slice 1 ships Copilot+Squad only; other hosts add as their slice ships)
   - Hand off to Proposal 069's launch-invocation dispatcher

`specrew host` (new command, ~1 SP):

- `specrew host list` — show available + currently-selected
- `specrew host use <kind>` — set `last_selected_host` without launching
- `specrew host status` — show which hosts have Crew-runtimes installed for this project

### `.specrew/host-history.yml` schema

```yaml
host_history:
  schema_version: 1
  last_selected_host: claude
  hosts:
    copilot:
      first_used_at: 2026-04-22T00:00:00Z
      last_used_at: 2026-05-22T18:30:00Z
      crew_runtime_installed: true
      crew_runtime_path: .squad/
    claude:
      first_used_at: 2026-05-23T08:00:00Z
      last_used_at: 2026-05-23T14:15:00Z
      crew_runtime_installed: true
      crew_runtime_path: .claude/agents/
    codex:
      first_used_at: null
      last_used_at: null
      crew_runtime_installed: false
      crew_runtime_path: null
    antigravity:
      first_used_at: null
      last_used_at: null
      crew_runtime_installed: false
      crew_runtime_path: null
```

## How

| Step | File | Effort |
|---|---|---|
| `host-history.yml` schema + read/write helpers | `scripts/internal/host-history.ps1` (new) | 1 SP |
| `specrew start` host-selection logic (last → probe → prompt) | `scripts/specrew-start.ps1` (extends existing host detection) | 2 SP |
| Category A → `.specrew/coordinator/` migration (one-time, idempotent) | `scripts/specrew-init.ps1` + new resolver helpers | 2 SP |
| Per-host Crew-runtime inventory probes | `scripts/internal/host-runtime-inventory.ps1` (new) | 1 SP |
| `specrew host` command dispatcher | `scripts/specrew-host.ps1` (new) + `scripts/specrew.ps1` route | 1 SP |
| First-run interactive prompt (only when stdin is TTY; else error with guidance) | `scripts/specrew-start.ps1` | 1 SP |
| Migration handling for existing projects (`.squad/` Category A files → `.specrew/coordinator/`) | `scripts/specrew-update.ps1` | 1.5 SP |
| Tests + doc updates | tests + getting-started + user-guide | 1 SP |

Total: ~10 SP

## Acceptance criteria

| AC | Statement |
|---|---|
| AC1 | `specrew init` does NOT prompt for host selection and does NOT install any host CLI |
| AC2 | First `specrew start` with no `--host` and no prior host in `host-history.yml` probes PATH and prompts the user to pick from found hosts |
| AC3 | Second `specrew start` with no `--host` uses the host selected at first run (no re-prompt) |
| AC4 | `specrew start --host <other>` flips the selected host; both old and new host appear in `host-history.yml` with `last_used_at` timestamps |
| AC5 | `specrew host list` shows available hosts on PATH + which is currently selected |
| AC6 | Category A files (coordinator-governance.md, charters, ceremonies, directives, skill templates) are at `.specrew/coordinator/` after `specrew init` on a greenfield project |
| AC7 | `specrew update` on a project with existing `.squad/coordinator-governance.md` migrates content to `.specrew/coordinator/specrew-governance.md` non-destructively (leaves a deprecation breadcrumb at the old location for one update cycle) |
| AC8 | Non-interactive runs (stdin not a TTY) with no `--host` and no `last_selected_host` exit with actionable guidance, not a hang |
| AC9 | Host history is auditable post-launch via `.specrew/start-context.json`'s `host_resolution` field — records both how the host was resolved (flag / last-selected / first-run-prompt) and which alternatives were available at probe time |
| AC10 | `specrew host status` distinguishes "host CLI installed" from "host Crew-runtime installed for this project" — both must be true to launch on that host |

## Out of scope

- **Concurrent multi-host execution** — Scenario B of Proposal 024; not in this proposal.
- **Per-host Crew-runtime install for non-Copilot hosts** — Slice 1 ships Copilot+Squad install only. Claude Code Crew install ships with Slice 2 (Proposal 024 alongside Category D directive surgery); Codex + Antigravity Crew install ships per their respective slices.
- **Mid-session host switch** — once `specrew start` has launched on a host, switching requires ending the session and restarting. Same constraint as Proposal 069.
- **Migration of Category B state** (`.squad/decisions.md`, `.squad/identity/now.md`, etc.) — these stay at host-native paths per Decision Matrix row 5. The `Get-SpecrewDecisionsLedgerPath -Host` style helpers from Proposal 024 are the abstraction surface; this proposal does NOT prematurely relocate state files.
- **Concurrent host detection for fingerprinting** — probing is shallow (PATH presence only). Deep capability probing (which models each host supports, which slash-commands work) is Proposal 068's catalog scope.

## Composition

| Proposal | Relationship |
|---|---|
| **069 (Multi-Host Launch Path)** | Direct prerequisite. 069 ships the per-host launch dispatch; this proposal layers selection UX + persistence + Category A relocation on top. Slice 0 = 069; Slice 1 = this proposal. |
| **024 (Multi-Host Runtime Abstraction)** | Architectural parent. This proposal's Category A relocation + per-host inventory helpers are the on-disk foundations 024's helper API formalizes. The 4-slice ladder (this proposal's row 6) makes 024 a graduated path rather than a single 65 SP cliff. |
| **068 (Cost-Aware Model Routing)** | Catalog (in 068) needs to know which host(s) are active; this proposal's `host-history.yml` + probe results feed the catalog refresh. |
| **070 (Token Economy MVP)** | Cost.yml's `host:` field comes from this proposal's host-resolution logic. |
| **064 (Slash-Command Multi-Host Correctness)** | Already deploys skill catalogs to all 3 host-skill conventions (`.claude/`, `.github/`, `.agents/`). This proposal extends the same multi-host pattern to Crew-runtime state. |
| **058 (Plugin-Based Multi-Host Distribution)** | When 058 ships, per-host packaging composes with this proposal's per-host Crew-runtime install. |
| **067 (Small-Fix Slice)** | This proposal ships under 067's contract (proposal entry + CHANGELOG + INDEX update at ship time + tests). |

## Risks

- **`.specrew/coordinator/` migration breaks downstream projects** — Mitigation: leave breadcrumb file at old `.squad/` location for one update cycle (covered by AC7); ship behind `specrew update --dry-run` preview.
- **First-run prompt UX gets in the way of automation** — Mitigation: AC8 says non-TTY runs error with guidance rather than hang. Automation can pass `--host` explicitly.
- **Per-host Crew-runtime install grows unbounded** — Mitigation: only Copilot+Squad install ships in Slice 1; other hosts opt-in per their respective slices.
- **State drift if user manually edits `host-history.yml`** — Mitigation: schema versioning + tolerant read (Proposal 059 pattern) + clear "regenerate via `specrew host status --reset`" recovery path.

## Cross-references

- file:///C:/Dev/Specrew/proposals/069-multi-host-launch-path.md
- file:///C:/Dev/Specrew/proposals/024-multi-host-runtime-abstraction.md
- file:///C:/Dev/Specrew/proposals/068-cost-aware-model-routing.md
- file:///C:/Dev/Specrew/proposals/070-token-economy-mvp.md
- file:///C:/Dev/Specrew/proposals/058-plugin-based-multi-host-distribution.md
- file:///C:/Dev/Specrew/proposals/064-slash-command-multi-host-correctness.md
- file:///C:/Dev/Specrew/proposals/INDEX.md
- Memory: `[[project-design-session-2026-05-22]]` — adjacent design-session context for the multi-host research wave
