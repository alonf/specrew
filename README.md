<p align="center">
  <img src="docs/assets/specrew-icon.png" alt="Specrew" height="130" align="middle" />
  &nbsp;&nbsp;
  <img src="docs/assets/specrew-wordmark-light.svg#gh-light-mode-only" alt="Specrew — Governed Agentic SDLC" height="110" align="middle" />
  <img src="docs/assets/specrew-wordmark-dark.svg#gh-dark-mode-only" alt="Specrew — Governed Agentic SDLC" height="110" align="middle" />
</p>

# Specrew

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.25.0-blue.svg)](.specrew/config.yml)
[![Status: Alpha](https://img.shields.io/badge/status-alpha-orange.svg)](#status)

Specrew is a **methodology** for AI-assisted software delivery — a governance layer that runs on top of [GitHub Spec Kit](https://github.com/github/spec-kit) and [Squad CLI](https://www.npmjs.com/package/@bradygaster/squad-cli) and enforces the SDLC discipline that those tools alone don't enforce.

It is **not** a multi-agent framework, **not** an autopilot tool, and **not** another code generator. It is the layer that keeps the human in the loop at every decision boundary while letting agents do the work between boundaries.

## Why Specrew exists

Modern AI-assisted code tools optimize for **throughput** — finish more in less time. That works until the AI quietly decides things the human would have decided differently:

- Picks a database without asking
- Resolves an ambiguous requirement by guessing
- Skips a clarifying question to save a turn
- Crosses a planning-to-implementation boundary without authorization
- Ships work that "looks correct" but isn't traceable to a spec

Specrew was built after observing these failures empirically and concluding that **the gap is not in the agent's capability; it is in the discipline around the agent.** The same agent that auto-resolves a scope decision under one tool will surface it as a question under another. The difference is the methodology layer.

Specrew encodes that methodology as four guarantees:

1. **Boundary discipline.** The lifecycle has explicit approval boundaries (`specify`, `clarify`, `plan`, `tasks`, `before-implement`, `review-signoff`, `retro`, `iteration-closeout`, `feature-closeout`). One human authorization advances at most one boundary. No agent prose can simulate authorization. Enforcement is moving from prose to code (see [Proposal 065](proposals/065-launch-mode-boundary-enforcement.md), in flight as Feature 039).
2. **Substantive interaction.** Every boundary handoff is reviewable in the console with the essence of "what I just did / why I stopped / what I need from you" visible without opening files. Status pings are not enough.
3. **Audit-trail durability.** Every verdict, decision, drift event, and bypass lives in `.squad/decisions.md` with timestamps, commit hashes, and recognized verdict shapes. Sessions can be reconstructed after the fact; methodology lives in artifacts, not in agent memory.
4. **Methodology survives the host.** As of v0.27.0 Specrew runs on **GitHub Copilot CLI (default), Claude Code, Codex CLI, or Antigravity (`agy`)** via `specrew start --host <kind>` or the interactive numbered menu when `--host` is omitted — VS Code Chat remains a roadmap item ([Proposal 071](proposals/071-vscode-copilot-chat-host.md)). Per-host flag translation keeps `--remote` / `--allow-all` / `--autopilot` uniform at the Specrew surface; canonical Crew identity lives at `.specrew/team/agents/<role>.md` and translates to each host's native subagent format on every `specrew start`. The skill-level enforcement gates are host-agnostic by design — switching hosts must not weaken the methodology.

## What Specrew is not

| If you want… | …use this instead |
|---|---|
| A multi-agent code library (orchestrate agents in Python) | [CrewAI](https://www.crewai.com/), [AutoGen](https://github.com/microsoft/autogen), [LangGraph](https://www.langchain.com/langgraph) |
| Autopilot coding (let the agent run; check the output) | [Devin](https://devin.ai/), [OpenInterpreter](https://www.openinterpreter.com/), [Aider](https://aider.chat/) |
| The spec-driven command surface alone (`/speckit.specify`, `/speckit.plan`, …) | [Spec Kit](https://github.com/github/spec-kit) directly |
| The multi-agent runtime alone (specialist teams, agent charters) | [Squad CLI](https://www.npmjs.com/package/@bradygaster/squad-cli) directly |
| A code generator | None of these — Specrew is governance over agent-driven work, not a code generator |

Specrew composes Spec Kit + Squad into a **methodology layer with enforced discipline**. It is the smallest layer that keeps the human in control when agents are doing the typing.

## How it differs in one paragraph

Vanilla Spec Kit ships the slash-command surface but has no orchestration or boundary enforcement. Vanilla Squad runs multi-agent teams but doesn't drive a spec-driven lifecycle. Autopilot tools and multi-agent libraries optimize for throughput by letting the agent decide. Specrew goes the other direction: **the spec is authoritative, drift is a first-class event, every boundary requires explicit human authorization, and the audit trail is durable.** Different design point. Same agents.

## Status

- **Active development line**: 0.27.0
- **Latest stable baseline**: 0.26.0 (F-040 Multi-Host Launch Path)
- **Pending PR-to-main**: v0.27.0 bundle — F-043 Multi-Host Onboarding + F-044 Per-Host Architecture Refactor (5 iterations including Antigravity host graduation, canonical `.specrew/team/` source-of-truth, interactive host menu)
- **Alpha software**, validated through dogfooding in this repository
- **Built for a single developer today.** Multi-developer reconciliation is a roadmap item ([Proposal 010](proposals/010-multi-developer-reconciliation.md)).
- Release truth lives in [CHANGELOG.md](CHANGELOG.md), [docs/versioning.md](docs/versioning.md), and the `v0.NN.0` tags.

## What's working today

- `specrew init` bootstraps Spec Kit, Squad, and Specrew governance into a fresh or existing repo
- `specrew start` launches the canonical lifecycle session with handoff artifacts refreshed
- `specrew where` renders the velocity dashboard from canonical artifacts
- The full lifecycle: `specify → clarify → plan → tasks → implement → review-signoff → retro → iteration-closeout → feature-closeout` — with gate-respecting boundary stops by default ([Proposal 066](proposals/066-gate-respecting-default.md), shipped)
- Session-state durability across reboots, worktree switches, and boundary events
- Slash-command catalog deployed to `.claude/skills/`, `.github/skills/`, and `.agents/skills/` ([Feature 024](specs/024-slash-command-multi-host-correctness/spec.md))
- Validator memoization, parallelization, closed-iteration index, repetition detector — the v0.24.3 process-optimization bundle keeps the discipline cheap to enforce
- Reviewer-regression routing, session-loaded file change detection, drift-log integrity
- Pre-boundary markdown-lint auto-fix gate prevents lint round-trips at every boundary commit
- PR-review-integration soft warning surfaces missing `pr-review-resolution.md` when host has automated review available

## What's coming (roadmap highlights)

- **F-039** [Launch-Mode Boundary Enforcement](proposals/065-launch-mode-boundary-enforcement.md) — mechanical refusal of agent boundary chaining (shipped v0.25.0)
- **F-040** [Multi-Host Launch Path](proposals/069-multi-host-launch-path.md) — `specrew start --host claude|codex|copilot` (shipped v0.26.0)
- **F-043** [Multi-Host Onboarding + Selection Flow](proposals/104-multi-host-onboarding-and-selection-flow.md) — `specrew host list/use/status` CLI surface + host-history persistence + interactive numbered menu (shipped v0.27.0)
- **F-044** [Per-Host Architecture Refactor](specs/044-per-host-architecture-refactor/spec.md) — Open-Closed host extension (registry + 4 host packages); 5th contract function `Install-<Kind>CrewRuntime`; canonical `.specrew/team/agents/<role>.md` source-of-truth; Antigravity host graduated to supported (shipped v0.27.0)
- **F-041** [Cost-Aware Model Routing](proposals/068-cost-aware-model-routing.md) — discovery skill + lean cost-profile + Junior→cheap-model auto-routing (next; addresses 2026-05-30 Copilot pricing pivot)
- **F-042** [Token Economy MVP](proposals/070-token-economy-mvp.md) — cost.yml + dashboard COST section so per-iteration spend is measurable
- **F-043** [Multi-Host Onboarding + Selection Flow](proposals/104-multi-host-onboarding-and-selection-flow.md) — first-run host probe + `host-history.yml` + `specrew host` command
- **Substantive Intake Questioning** ([Proposal 063](proposals/063-substantive-intake-questioning.md)) — persona-driven adaptive intake at specify + clarify boundaries
- **Friction Dial** ([Proposal 100](proposals/100-friction-dial.md)) — strict/default/autonomous modes for expert developers
- **Host-Native Hook Deployment** ([Proposal 105](proposals/105-host-native-hook-deployment.md)) — Claude Code PreToolUse hooks elevate F-039 from cooperative to runtime enforcement
- **Installed-File SDLC Audit** ([Proposal 099](proposals/099-installed-file-sdlc-instruction-audit.md)) — close the dogfooding deficit between maintainer paste-prompts and installed methodology files

See [proposals/INDEX.md](proposals/INDEX.md) for the full proposal catalog (Shipped / Draft / Candidate).

## Quickstart

Five minutes from zero to a running lifecycle session:

```powershell
Install-Module Specrew -Scope CurrentUser -SkipPublisherCheck
mkdir C:\Dev\calculator && cd C:\Dev\calculator && git init
specrew init
specrew start "Build a web based calculator with only the + - * / MR MC M+ M- operations"
```

See [docs/getting-started.md](docs/getting-started.md) for the full quickstart, install variants, and known limitations. See [docs/user-guide.md](docs/user-guide.md) for day-to-day usage.

## Platform support

| Platform | Status |
|---|---|
| Windows 11 (primary) | ✅ Fully validated |
| WSL Ubuntu | ✅ Manually validated end-to-end |
| Linux native (Ubuntu) | ✅ Path handling cross-platform; CI matrix configured |
| macOS | 🔧 Path handling cross-platform; CI matrix configured; no in-house validation yet |

## Key documents

- [docs/getting-started.md](docs/getting-started.md) — bootstrap + minimal flow
- [docs/user-guide.md](docs/user-guide.md) — day-to-day lifecycle usage
- [docs/dashboard-guide.md](docs/dashboard-guide.md) — dashboard sections, flags, closeout snapshots
- [docs/versioning.md](docs/versioning.md) — release-numbering policy and tag/changelog rules
- [CHANGELOG.md](CHANGELOG.md) — retroactive feature-release history
- [proposals/INDEX.md](proposals/INDEX.md) — full proposal catalog (candidates, drafts, shipped)
- [docs/roadmap-maintenance.md](docs/roadmap-maintenance.md) — `.specrew/roadmap.yml` maintenance

## Contributing

Specrew is alpha. Reading, issues, and discussion are welcome now. External pull requests are intentionally deferred until the operating model and review boundaries stabilize. The dogfooding loop on this repository is the validation surface for every methodology change.

## License

Specrew is released under the MIT License. See [LICENSE](LICENSE) for the repository license and [NOTICE.md](NOTICE.md) for upstream attribution covering derived Squad and Spec Kit materials.
