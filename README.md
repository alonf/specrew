<p align="center">
  <img src="docs/assets/specrew-icon.png" alt="Specrew" height="130" align="middle" />
  &nbsp;&nbsp;
  <img src="docs/assets/specrew-wordmark-light.svg#gh-light-mode-only" alt="Specrew — Governed Agentic SDLC" height="110" align="middle" />
  <img src="docs/assets/specrew-wordmark-dark.svg#gh-dark-mode-only" alt="Specrew — Governed Agentic SDLC" height="110" align="middle" />
</p>

# Specrew

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.28.0-blue.svg)](.specrew/config.yml)
[![Status: Alpha](https://img.shields.io/badge/status-alpha-orange.svg)](#status)

**Governed agentic SDLC. Agents type — you decide.** Specrew is a methodology layer over [GitHub Spec Kit](https://github.com/github/spec-kit) that keeps the human in the loop at every decision boundary while letting AI agents do the work between boundaries. Works with GitHub Copilot, Claude Code, OpenAI Codex CLI, and Google Antigravity.

## ⚡ Try it now (5 min)

```powershell
Install-Module Specrew -Scope CurrentUser -SkipPublisherCheck
mkdir C:\Dev\hello-specrew; cd C:\Dev\hello-specrew; git init
specrew init
specrew start "Build a tip calculator with a web UI"
```

That's it. Specrew now drives you through the spec-driven lifecycle: you'll co-author a spec with the AI, sign off on a plan, and end with working code traceable to every decision.

**Prerequisites** (one-time): PowerShell 7+, git, and one AI host CLI — [GitHub Copilot](https://docs.github.com/en/copilot/how-tos/copilot-cli), [Claude Code](https://docs.anthropic.com/en/docs/claude-code/installation), [Codex CLI](https://developers.openai.com/codex/cli), or [Antigravity](https://antigravity.google/). On macOS / Linux, replace the `mkdir`/`cd` line with the platform equivalent. See [docs/getting-started.md](docs/getting-started.md) for full install steps, dependency notes (uv, npm), and brownfield-project bootstrap.

## What just happened

Specrew gated the agent at every decision boundary: `specify` → `clarify` → `plan` → `tasks` → `implement` → `review-signoff` → `iteration-closeout`. At each boundary, the agent stopped and asked you to authorize before advancing. The artifacts on disk (`.specrew/`, `specs/<feature>/`) form a complete, host-independent audit trail. You can resume the same feature tomorrow from a different AI host — the methodology lives in files, not in the agent's memory.

## Why Specrew exists

Modern AI-assisted code tools optimize for **throughput** — finish more in less time. That works until the AI quietly decides things the human would have decided differently:

- Picks a database without asking
- Resolves an ambiguous requirement by guessing
- Skips a clarifying question to save a turn
- Crosses a planning-to-implementation boundary without authorization
- Ships work that "looks correct" but isn't traceable to a spec

Specrew was built after observing these failures empirically and concluding that **the gap is not in the agent's capability; it is in the discipline around the agent.** The same agent that auto-resolves a scope decision under one tool will surface it as a question under another. The difference is the methodology layer.

Specrew encodes that methodology as four guarantees:

1. **Boundary discipline.** The lifecycle has explicit approval boundaries (`specify`, `clarify`, `plan`, `tasks`, `before-implement`, `review-signoff`, `retro`, `iteration-closeout`, `feature-closeout`). One human authorization advances at most one boundary. No agent prose can simulate authorization. Enforcement is moving from prose to code (see [Proposal 065](proposals/065-launch-mode-boundary-enforcement.md), shipped as Feature 039).
2. **Substantive interaction.** Every boundary handoff is reviewable in the console with the essence of "what I just did / why I stopped / what I need from you" visible without opening files. Status pings are not enough.
3. **Audit-trail durability.** Every verdict, decision, drift event, and bypass lives in `.squad/decisions.md` (Copilot host) or the host-native decisions ledger with timestamps, commit hashes, and recognized verdict shapes. Sessions can be reconstructed after the fact; methodology lives in artifacts, not in agent memory.
4. **Methodology survives the host.** As of v0.27.0 Specrew runs on **GitHub Copilot CLI (default), Claude Code, Codex CLI, or Antigravity (`agy`)** via `specrew start --host <kind>` or the interactive numbered menu when `--host` is omitted — VS Code Chat remains a roadmap item ([Proposal 071](proposals/071-vscode-copilot-chat-host.md)). Per-host flag translation keeps `--remote` / `--allow-all` / `--autopilot` uniform at the Specrew surface; canonical Crew identity lives at `.specrew/team/agents/<role>.md` and translates to each host's native subagent format on every `specrew start`. The skill-level enforcement gates are host-agnostic by design — switching hosts must not weaken the methodology.

## Switch your AI host mid-feature — without losing your place

This is what governance buys you that raw CLI usage cannot.

Every AI coding host has a context window. When that window fills — or you simply close the terminal — the agent's memory of "what we just decided, why we stopped here, what the gates are, which iteration is open" is gone. Picking back up means rebuilding context in prose, paying the token cost of recap, and trusting the agent to faithfully reconstruct decisions it never explicitly recorded.

Specrew sidesteps this by treating the **artifact on disk** as the source of truth, not the agent's memory. The spec, plan, tasks, iteration plan, decisions ledger, drift log, and current boundary state all live in files inside your project. Any host — Copilot, Claude, Codex, Antigravity — can be started against the same project, read the same artifacts, and continue from the exact same boundary.

A real workflow this makes possible:

```text
Monday  — specrew start --host copilot     "specify a tip calculator"
                                              → spec.md committed, /speckit.clarify queued
Tuesday — specrew start --host claude       (no prompt — resumes at clarify)
                                              → clarifications.md committed, /speckit.plan queued
Wednesday — specrew start --host codex      (no prompt — resumes at plan)
                                              → plan.md committed, /speckit.tasks queued
Thursday — specrew start --host antigravity (no prompt — resumes at iteration scaffold)
                                              → iter-001/plan.md, ready for /speckit.implement
```

Each `specrew start` on a different host:

- Resolves to the same canonical Crew at `.specrew/team/agents/<role>.md` (translated to host-native format on the fly)
- Reads the same boundary state from `.specrew/state.yml` and resumes at the next gate
- Picks up the same decisions ledger, drift log, and audit trail
- Honors the same enforcement gates (no boundary auto-advance, no scope creep, no host-specific shortcuts)

The methodology is what makes this practical. Without governed boundaries + durable artifacts, switching host mid-feature means context loss and silent decision divergence between sessions. With them, the host is interchangeable — you can chase the cheapest model, the strongest reasoner, or the host that's loaded on the machine you happen to be at, and the project doesn't care.

## What Specrew is not

| If you want… | …use this instead |
|---|---|
| A multi-agent code library (orchestrate agents in code) | [CrewAI](https://www.crewai.com/), [AutoGen](https://github.com/microsoft/autogen), [LangGraph](https://www.langchain.com/langgraph), [Microsoft Agent Framework](https://learn.microsoft.com/en-us/agent-framework/) |
| Autopilot coding (let the agent run; check the output) | [GitHub Copilot Coding Agent](https://docs.github.com/copilot/concepts/agents/coding-agent/about-coding-agent), [OpenAI Codex (cloud app)](https://openai.com/index/introducing-the-codex-app/), [Claude Code autonomous mode](https://www.anthropic.com/news/enabling-claude-code-to-work-more-autonomously) |
| The spec-driven command surface alone (`/speckit.specify`, `/speckit.plan`, …) | [Spec Kit](https://github.com/github/spec-kit) directly |
| A code-agent team runtime on its own (specialist agents, agent charters) — without spec-driven governance | [Squad CLI](https://www.npmjs.com/package/@bradygaster/squad-cli) directly (Copilot host only), or each host's native subagent system (`.claude/agents/`, etc.) |
| A code generator | None of these — Specrew is governance over agent-driven work, not a code generator |

Specrew composes Spec Kit + your host's native code-agent teams into a **methodology layer with enforced discipline**. It is the smallest layer that keeps the human in control when agents are doing the typing.

## How it differs in one paragraph

Vanilla Spec Kit ships the slash-command surface but has no orchestration or boundary enforcement. Vanilla code-agent-team runners (Squad CLI, host-native subagent systems) run multi-agent teams but don't drive a spec-driven lifecycle. Autopilot tools and multi-agent libraries optimize for throughput by letting the agent decide. Specrew goes the other direction: **the spec is authoritative, drift is a first-class event, every boundary requires explicit human authorization, and the audit trail is durable.** Different design point. Same agents.

## Status

- **Active development line**: 0.27.3
- **Latest stable baseline**: 0.27.3 (F-047 trust-hardening bug-bash bundle)
- **Alpha software**, validated through dogfooding in this repository
- **Built for a single developer today.** Multi-developer reconciliation is a roadmap item ([Proposal 010](proposals/010-multi-developer-reconciliation.md)); a leaner spec-first concurrent model is queued as [Proposal 115](proposals/115-spec-first-concurrent-development-workflow.md).
- Release truth lives in [CHANGELOG.md](CHANGELOG.md), [docs/versioning.md](docs/versioning.md), and the `v0.NN.0` tags.

## What's working today

- `specrew init` bootstraps Spec Kit + Specrew governance (and installs Squad CLI when Copilot is the chosen host) into a fresh or existing repo
- `specrew start` launches the canonical lifecycle session with handoff artifacts refreshed
- `specrew where` renders the velocity dashboard from canonical artifacts
- The full lifecycle: `specify → clarify → plan → tasks → implement → review-signoff → retro → iteration-closeout → feature-closeout` — with gate-respecting boundary stops by default ([Proposal 066](proposals/066-gate-respecting-default.md), shipped). The last two boundaries (iteration-closeout, feature-closeout) are not decoration: they produce the per-iteration `dashboard.md` + per-feature `closeout-dashboard.md` artifacts, mark the work durably "done", and gate the next iteration / next feature from starting. Skipping them leaves the project in an in-flight state — see [docs/user-guide.md "Closing iterations + features"](docs/user-guide.md#closing-iterations--features) for what these boundaries produce and the verdict shapes that advance them.
- Session-state durability across reboots, worktree switches, and boundary events
- A per-user **Crew Interaction Profile** (`/specrew-user-profile`) — four decision-area settings (Product Strategy, UX/UI Design, Software Architecture, AI Delivery Planning) that tune how much Specrew asks, explains, recommends, and auto-decides. It resolves per current user from the loader/path rule (`$env:USERPROFILE\.specrew\user-profile.yml` on Windows, `~/.specrew/user-profile.yml` on Unix), is surfaced as soft session guidance everywhere and hard-applied only in `/speckit.specify`, and lets teammates run different local profiles in the same repo with no shared-repository changes. See [docs/user-guide.md "Crew Interaction Profile"](docs/user-guide.md#crew-interaction-profile).
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
- **Substantive Intake Questioning** ([Proposal 063](proposals/063-substantive-intake-questioning.md)) — persona-driven adaptive intake at specify + clarify boundaries
- **Iteration-Level Lifecycle Enforcement** ([Proposal 117](proposals/117-iteration-level-lifecycle-enforcement.md)) — populate state.md / review.md / retro.md per iteration (closes the empty-iteration-dir gap surfaced by 2026-05-25 dice re-audit)
- **Host Autopilot Quality Profiles** ([Proposal 118](proposals/118-host-autopilot-quality-profiles.md)) — surface per-host quality-defaults at selection time + per-feature overrides
- **Friction Dial** ([Proposal 100](proposals/100-friction-dial.md)) — strict/default/autonomous modes for expert developers
- **Host-Native Hook Deployment** ([Proposal 105](proposals/105-host-native-hook-deployment.md)) — Claude Code PreToolUse hooks elevate F-039 from cooperative to runtime enforcement
- **Installed-File SDLC Audit** ([Proposal 099](proposals/099-installed-file-sdlc-instruction-audit.md)) — close the dogfooding deficit between maintainer paste-prompts and installed methodology files

See [proposals/INDEX.md](proposals/INDEX.md) for the full proposal catalog (Shipped / Draft / Candidate).

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
- [docs/troubleshooting.md](docs/troubleshooting.md) — recovery paths for install drift, update failures, stale session state, and Shape-5 evidence mistakes
- [docs/dashboard-guide.md](docs/dashboard-guide.md) — dashboard sections, flags, closeout snapshots
- [docs/versioning.md](docs/versioning.md) — release-numbering policy and tag/changelog rules
- [CHANGELOG.md](CHANGELOG.md) — retroactive feature-release history
- [proposals/INDEX.md](proposals/INDEX.md) — full proposal catalog (candidates, drafts, shipped)
- [docs/roadmap-maintenance.md](docs/roadmap-maintenance.md) — `.specrew/roadmap.yml` maintenance

## Contributing

Specrew is alpha. Reading, issues, and discussion are welcome now. External pull requests are intentionally deferred until the operating model and review boundaries stabilize. The dogfooding loop on this repository is the validation surface for every methodology change.

## License

Specrew is released under the MIT License. See [LICENSE](LICENSE) for the repository license and [NOTICE.md](NOTICE.md) for upstream attribution covering derived Squad and Spec Kit materials.
