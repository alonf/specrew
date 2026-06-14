<p align="center">
  <img src="docs/assets/specrew-icon.png" alt="Specrew" height="130" align="middle" />
  &nbsp;&nbsp;
  <img src="docs/assets/specrew-wordmark-light.svg#gh-light-mode-only" alt="Specrew — Governed Agentic SDLC" height="110" align="middle" />
  <img src="docs/assets/specrew-wordmark-dark.svg#gh-dark-mode-only" alt="Specrew — Governed Agentic SDLC" height="110" align="middle" />
</p>

# Specrew

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.37.0-blue.svg)](.specrew/config.yml)
[![Status: Alpha](https://img.shields.io/badge/status-alpha-orange.svg)](#status)
[![Platforms](https://img.shields.io/badge/platforms-Windows%20%7C%20macOS%20%7C%20Linux-blue.svg)](#prerequisites)

**Governed agentic SDLC. Agents type — you decide.** Specrew is a methodology layer over [GitHub Spec Kit](https://github.com/github/spec-kit) that keeps the human in the loop at every decision boundary while letting AI agents do the work between boundaries. Runs on Windows, macOS, and Linux via PowerShell 7+. Works with GitHub Copilot, Claude Code, Cursor, OpenAI Codex CLI, and Google Antigravity.

## ⚡ Try it now (5 min)

### macOS / Linux — native shell (zsh/bash)

```sh
curl -fsSL https://raw.githubusercontent.com/alonf/specrew/main/install.sh | sh
mkdir hello-specrew && cd hello-specrew && git init
specrew init
claude   # launch your AI host (or codex / copilot / cursor) — then just say: Build a tip calculator with a web UI
```

For Mac and Linux, `install.sh` does it all: it auto-installs PowerShell Core as an internal dependency if it is missing (Ubuntu/Debian via the Microsoft apt repository; macOS via Homebrew), installs Specrew from the PowerShell Gallery, and puts the native `specrew` command on your `PATH`. To validate a beta instead of the stable release, append `-s -- --prerelease` to the `curl … | sh` line.

> **Validating an unreleased prerelease?** The `main` URL above serves the *released* `install.sh`. When you're beta-testing a feature branch or tag that isn't merged yet, fetch the script from that ref instead — e.g. `curl -fsSL https://raw.githubusercontent.com/alonf/specrew/<branch-or-tag>/install.sh | sh -s -- --prerelease`.

### Windows — PowerShell 7+

```powershell
Install-Module Specrew -Scope CurrentUser -SkipPublisherCheck
mkdir hello-specrew; cd hello-specrew; git init
specrew init
claude   # launch your AI host (or codex / copilot / cursor) — then just say: Build a tip calculator with a web UI
```

That's it. Specrew now drives you through the spec-driven lifecycle: you'll co-author a spec with the AI, sign off on a plan, and end with working code traceable to every decision.

> **`specrew init` is a one-time setup — then just launch your host.** You run `specrew init` **once per project** to deploy Specrew's session hooks; you never need to run it again in that project. From then on, every session you simply run your host CLI (`claude` / `codex` / `copilot` / `cursor`) inside the project and Specrew bootstraps you automatically — `specrew start` is **optional**. Your **first message** — "What should I do now?" or "Create a feature for …" — gets a Specrew orientation banner as the agent's first reply, and Specrew drives the governed lifecycle from there. When you stop, a rolling handover file is written, so your next launch **auto-resumes where you left off** — same host or a different one. Specrew works on **Claude, Codex, Copilot, and Cursor**; **Antigravity** has no hook surface, so there you start with `specrew start` ([see below](#starting-on-antigravity)). You can still use `specrew start` anywhere to pick or switch hosts (`--host`) or start from a script.

### Prerequisites

git and one AI host CLI — [GitHub Copilot](https://docs.github.com/en/copilot/how-tos/copilot-cli), [Claude Code](https://docs.anthropic.com/en/docs/claude-code/installation), [Cursor](https://cursor.com/), [Codex CLI](https://developers.openai.com/codex/cli), or [Antigravity](https://antigravity.google/). PowerShell 7+ is the runtime: on **macOS/Linux it is an internal dependency that `install.sh` auto-installs for you** (you never invoke `pwsh` directly); on **Windows** you run Specrew from PowerShell 7+.

**Installing PowerShell 7+ manually** (only needed if you bypass `install.sh`):

- **Windows:** preinstalled on Windows 11; on Windows 10, `winget install Microsoft.PowerShell` or [microsoft.com/powershell](https://github.com/PowerShell/PowerShell/releases)
- **macOS:** `brew install --cask powershell` (then run `pwsh` to enter)
- **Linux:** [official install guide](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-linux) (Ubuntu, Debian, Fedora, Arch all supported)

> **macOS/Linux fallback — module install instead of `install.sh`:** run `Install-Module Specrew -Scope CurrentUser -SkipPublisherCheck` **from inside `pwsh`**, not zsh/bash (`Install-Module` does not exist in your login shell — running it there prints `command not found`). The PowerShell Gallery prompt defaults to **`N`**, so pressing Enter *declines* the install — choose **`A` / Yes to All** (or add `-Force`). The native `install.sh` path above avoids both pitfalls.

See [docs/getting-started.md](docs/getting-started.md) for full install steps, dependency notes (uv, npm, Node, Spec Kit), and brownfield-project bootstrap.

## What just happened

Specrew gated the agent at every decision boundary: `specify` → `clarify` → `plan` → `tasks` → `implement` → `review-signoff` → `iteration-closeout`. At each boundary, the agent stopped and asked you to authorize before advancing. The artifacts on disk (`.specrew/`, `specs/<feature>/`) form a complete, host-independent audit trail. When you stopped, a Stop hook wrote a rolling handover to `.specrew/handover/session-handover.md`; when you launch again — same host or a different one — the SessionStart hook reads that handover and a re-computed resume reconciliation, so work **auto-resumes where it stopped** with no `specrew start` required. The methodology lives in files, not in the agent's memory.

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
4. **Methodology survives the host.** Specrew runs on **GitHub Copilot CLI, Claude Code, Cursor (`cursor-agent`), Codex CLI, or Antigravity (`agy`)** — on a hook-capable host you just launch the CLI directly and Specrew bootstraps you; `specrew start --host <kind>` (or the interactive menu) is the explicit way to pick or switch a host, and the way in on hookless Antigravity. VS Code Chat remains a roadmap item ([Proposal 071](proposals/071-vscode-copilot-chat-host.md)). Per-host flag translation keeps `--remote` / `--allow-all` / `--autopilot` uniform at the Specrew surface; canonical Crew identity lives at `.specrew/team/agents/<role>.md` and translates to each host's native subagent format on launch. The skill-level enforcement gates are host-agnostic by design — switching hosts must not weaken the methodology.

## Post-Commit Verification Protocol

Boundary handoffs are only trustworthy when the cited evidence is tied to the
committed tree, not to transient working-copy state. After a boundary commit, the
Crew must:

1. replace any `.squad/decisions.md` authorization `Commit Reference: pending`
   value with the real boundary commit hash
2. keep `Recorded At` values in canonical UTC seconds precision
3. run a stale-reference scan against every cited `file:///` review target
4. rerun the governed validation lane on the exact committed tree before claiming
   boundary readiness
5. state any remaining verification gap or defer explicitly in the handoff

This protocol is part of the substantive-interaction contract: a boundary stop
must tell the human what changed, why the agent stopped, what evidence to inspect,
and whether that evidence still resolves after commit.

## Switch your AI host mid-feature — without losing your place

This is what governance buys you that raw CLI usage cannot.

Every AI coding host has a context window. When that window fills — or you simply close the terminal — the agent's memory of "what we just decided, why we stopped here, what the gates are, which iteration is open" is gone. Picking back up means rebuilding context in prose, paying the token cost of recap, and trusting the agent to faithfully reconstruct decisions it never explicitly recorded.

Specrew sidesteps this by treating the **artifact on disk** as the source of truth, not the agent's memory. The spec, plan, tasks, iteration plan, decisions ledger, drift log, current boundary state, and the host-agnostic **rolling handover** (`.specrew/handover/session-handover.md`) all live in files inside your project. Stop in one host, launch a different host, type **`continue`** — its SessionStart hook reads that handover and resumes from where the last host stopped.

A real workflow this makes possible (on a hook-capable host you just launch the CLI — no `specrew start`):

```text
Monday  — claude    "specify a tip calculator"
                       → spec.md committed, handover written, /speckit.clarify queued
Tuesday — codex     "continue"   (SessionStart reads the handover — resumes at clarify)
                       → clarifications.md committed, /speckit.plan queued
Wednesday — copilot "continue"   (resumes at plan)
                       → plan.md committed, /speckit.tasks queued
Thursday — claude   "continue"   (resumes at iteration scaffold)
                       → iter-001/plan.md, ready for /speckit.implement
Friday   — specrew start --host antigravity   (Antigravity is hookless — use specrew start to recover)
                       → tests + code committed, /speckit.review-signoff queued
```

On each launch, the new host:

- Resolves to the same canonical Crew at `.specrew/team/agents/<role>.md` (translated to host-native format on the fly)
- Reads the same boundary state from `.specrew/state.yml` plus the rolling handover, and auto-resumes at the next gate
- Picks up the same decisions ledger, drift log, and audit trail
- Honors the same enforcement gates (no boundary auto-advance, no scope creep, no host-specific shortcuts)

One thing to know: if you switch to a non-Claude host mid-feature, the new session may ask you to re-confirm your last approval before it advances. Your work and your place still follow you — you just say the word once more.

The methodology is what makes this practical. Without governed boundaries + durable artifacts, switching host mid-feature means context loss and silent decision divergence between sessions. With them, the host is interchangeable — you can chase the cheapest model, the strongest reasoner, or the host that's loaded on the machine you happen to be at, and the project doesn't care.

## Starting on Antigravity

Antigravity (Google's `agy` CLI) is a fully supported host, with one difference: it has **no session-hook surface**, so the automatic "just launch and go" bootstrap doesn't apply there. On Antigravity you open each session with `specrew start`, which hands the host the same orientation banner and drives the same governed lifecycle:

```powershell
specrew start --host antigravity
# …or open with a request:
specrew start --host antigravity "Build a tip calculator with a web UI"
```

Everything downstream is identical to the other hosts — the same decision boundaries, the same decisions ledger, the same rolling handover on disk. Because that handover is just a file, you can still hand a feature **between** Antigravity and a hook-capable host: stop in one, pick it up in the other.

## Hands-off mode (auto-approve)

By default your host asks permission before it edits a file or runs a command. If you'd rather let the agent work uninterrupted **between** decision boundaries, every host has an "auto-approve" flag that skips those per-action prompts. Specrew gives you one uniform flag, `--allow-all`, and translates it to whatever your host calls it:

| Host | Pass to `specrew start` | The host's own flag (if you launch it directly) |
|---|---|---|
| Copilot | `--allow-all` | `--allow-all` |
| Claude | `--allow-all` | `--dangerously-skip-permissions` |
| Cursor | `--allow-all` | `--force` |
| Codex | `--allow-all` | `--full-auto` |
| Antigravity | `--allow-all` | `--dangerously-skip-permissions` |

```powershell
specrew start --host claude --allow-all "Build a tip calculator with a web UI"
```

Auto-approve only changes how the agent does the work in between — **it does not skip Specrew's decision boundaries.** Even in full auto-approve, the lifecycle still stops at every gate (`specify`, `plan`, `tasks`, `review-signoff`, …) and waits for your verdict. It speeds up the typing; you still make the decisions.

## Updating Specrew

Specrew has two layers, and you update them independently:

- **The tool** — the `specrew` command itself. Update it like any PowerShell module:

  ```powershell
  Update-Module Specrew
  ```

  On macOS/Linux, re-run the `install.sh` one-liner from the quick-start to pull the latest release.

- **A project's Specrew files** — the hooks, skills, and templates `specrew init` deployed into a project. From inside the project, run:

  ```powershell
  specrew update
  ```

  This re-syncs the project to the version of Specrew you currently have installed.

A good habit: update the tool **first** (`Update-Module Specrew`), then run `specrew update` inside each project so its hooks and skills match the tool. See [docs/getting-started.md](docs/getting-started.md) for the full update notes.

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

- **Latest stable baseline**: 0.35.0 — stable promotion of the 0.33.0–0.35.0 line (Specrew Refocus, Product & Problem Domain lens, Code & Implementation lens) after beta-before-stable validation; see [CHANGELOG.md](CHANGELOG.md) for release details
- **Active development line**: none in flight — `0.35.0` is the current stable; the next feature opens the next prerelease line
- **Alpha software**, exercised end-to-end in this repository
- **Built for a single developer today.** Multi-developer reconciliation is a roadmap item ([Proposal 010](proposals/010-multi-developer-reconciliation.md)); a leaner spec-first concurrent model is queued as [Proposal 115](proposals/115-spec-first-concurrent-development-workflow.md).
- Release truth lives in [CHANGELOG.md](CHANGELOG.md), [docs/versioning.md](docs/versioning.md), and the `v0.NN.0` tags.

## What's working today

- `specrew init` bootstraps Spec Kit + Specrew governance (and installs Squad CLI when Copilot is the chosen host) into a fresh or existing repo, and **deploys the Specrew hooks** so a hook-capable host self-bootstraps on launch
- **Hook-driven session bootstrap + auto-resume** — on a hook-capable host (Claude, Codex, Copilot, Cursor) you just launch the CLI; the SessionStart hook renders the orientation banner + governed launch contract + any resume context, and a Stop hook keeps a crash-safe rolling handover (`.specrew/handover/session-handover.md`, atomic write + `.old` backup, gitignored) so the next session resumes where it stopped. `specrew start` is now an optional explicit driver / re-anchor (and the recovery path for hookless Antigravity)
- `specrew where` renders the velocity dashboard from canonical artifacts
- The full lifecycle: `specify → clarify → plan → tasks → implement → review-signoff → retro → iteration-closeout → feature-closeout` — with gate-respecting boundary stops by default ([Proposal 066](proposals/066-gate-respecting-default.md), shipped). The last two boundaries (iteration-closeout, feature-closeout) are not decoration: they produce the per-iteration `dashboard.md` + per-feature `closeout-dashboard.md` artifacts, mark the work durably "done", and gate the next iteration / next feature from starting. Skipping them leaves the project in an in-flight state — see [docs/user-guide.md "Closing iterations + features"](docs/user-guide.md#closing-iterations--features) for what these boundaries produce and the verdict shapes that advance them.
- The **Design Workshop** — a facilitated, lens-driven design conversation at specify-intake and again at the design-analysis stop before planning: nine design lenses (architecture, components, NFRs, UI/UX, data, security, integration, DevOps, observability), co-designed component maps and flows, in-band diagrams, and durable workshop artifacts. The full methodology lives in [docs/methodology/design-workshop-methodology.md](docs/methodology/design-workshop-methodology.md)
- Session-state durability across reboots, worktree switches, and boundary events
- A per-user **Crew Interaction Profile** (`/specrew-user-profile`) — four decision-area settings (Product Strategy, UX/UI Design, Software Architecture, AI Delivery Planning) that tune how much Specrew asks, explains, recommends, and auto-decides. It resolves per current user from the loader/path rule (`$env:USERPROFILE\.specrew\user-profile.yml` on Windows, `~/.specrew/user-profile.yml` on Unix), is surfaced as soft session guidance everywhere and hard-applied only in `/speckit.specify`, and lets teammates run different local profiles in the same repo with no shared-repository changes. See [docs/user-guide.md "Crew Interaction Profile"](docs/user-guide.md#crew-interaction-profile).
- Slash-command catalog deployed to `.claude/skills/`, `.github/skills/`, and `.agents/skills/` ([Feature 024](specs/024-slash-command-multi-host-correctness/spec.md))
- Validator memoization, parallelization, closed-iteration index, repetition detector — the v0.24.3 process-optimization bundle keeps the discipline cheap to enforce
- Reviewer-regression routing, session-loaded file change detection, drift-log integrity
- Pre-boundary markdown-lint auto-fix gate keeps every boundary commit lint-clean
- **Refocus drift recovery** (`/specrew-refocus`) + automatic discipline injection: boundary syncs deliver the incoming stage's rules on every host; post-compaction and session-start hooks re-ground context on hook-capable hosts (Claude, Codex, Copilot, Cursor) — with a per-session circuit breaker and three kill-switch levels
- PR-review-integration soft warning surfaces missing `pr-review-resolution.md` when host has automated review available

## Lifecycle-adjacent Spec Kit commands

Specrew surfaces these lifecycle-adjacent Spec Kit commands at specific lifecycle points. They are additive aids — they complement the governed lifecycle and do not replace governance.

| Command | Lifecycle point | When to use | Status |
|---|---|---|---|
| `/speckit.checklist` | before-plan | Requirements-quality aid that catches vague, incomplete, inconsistent, or missing requirements before planning. Recommended for substantive work; optional for low-risk slices. | Surfaced |
| `/speckit.analyze` | before-implement (after a complete `tasks.md`) | Additive cross-artifact consistency review across `spec.md`, `plan.md`, and `tasks.md`. Complements governance validation; does not replace it. | Surfaced |
| `/speckit.taskstoissues` | — | Known but **deferred** for Feature 054; not part of the default lifecycle in this slice. | Deferred |

## What's coming (roadmap highlights)

- **F-039** [Launch-Mode Boundary Enforcement](proposals/065-launch-mode-boundary-enforcement.md) — mechanical refusal of agent boundary chaining (shipped v0.25.0)
- **F-040** [Multi-Host Launch Path](proposals/069-multi-host-launch-path.md) — `specrew start --host claude|codex|copilot` (shipped v0.26.0)
- **F-043** [Multi-Host Onboarding + Selection Flow](proposals/104-multi-host-onboarding-and-selection-flow.md) — `specrew host list/use/status` CLI surface + host-history persistence + interactive numbered menu (shipped v0.27.0)
- **F-044** [Per-Host Architecture Refactor](specs/044-per-host-architecture-refactor/spec.md) — Open-Closed host extension (registry + 4 host packages); 5th contract function `Install-<Kind>CrewRuntime`; canonical `.specrew/team/agents/<role>.md` source-of-truth; Antigravity host graduated to supported (shipped v0.27.0)
- **F-041** [Cost-Aware Model Routing](proposals/068-cost-aware-model-routing.md) — discovery skill + lean cost-profile + Junior→cheap-model auto-routing (next; addresses the Copilot pricing pivot)
- **F-042** [Token Economy MVP](proposals/070-token-economy-mvp.md) — cost.yml + dashboard COST section so per-iteration spend is measurable
- **Substantive Intake Questioning** ([Proposal 063](proposals/063-substantive-intake-questioning.md)) — persona-driven adaptive intake at specify + clarify boundaries
- **Iteration-Level Lifecycle Enforcement** ([Proposal 117](proposals/117-iteration-level-lifecycle-enforcement.md)) — populate state.md / review.md / retro.md per iteration (closes the empty-iteration-dir gap)
- **Host Autopilot Quality Profiles** ([Proposal 118](proposals/118-host-autopilot-quality-profiles.md)) — surface per-host quality-defaults at selection time + per-feature overrides
- **Friction Dial** ([Proposal 100](proposals/100-friction-dial.md)) — strict/default/autonomous modes for expert developers
- **Host-Native Hook Deployment** ([Proposal 105](proposals/105-host-native-hook-deployment.md)) — Claude Code PreToolUse hooks elevate F-039 from cooperative to runtime enforcement
- **Installed-File SDLC Audit** ([Proposal 099](proposals/099-installed-file-sdlc-instruction-audit.md)) — close the gap between maintainer paste-prompts and the methodology files that actually ship to your project

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
- [docs/methodology/design-workshop-methodology.md](docs/methodology/design-workshop-methodology.md) — the Design Workshop: the lens-driven design conversation at intake + the design-analysis stop
- [docs/troubleshooting.md](docs/troubleshooting.md) — recovery paths for install drift, update failures, stale session state, and Shape-5 evidence mistakes
- [docs/dashboard-guide.md](docs/dashboard-guide.md) — dashboard sections, flags, closeout snapshots
- [docs/versioning.md](docs/versioning.md) — release-numbering policy and tag/changelog rules
- [CHANGELOG.md](CHANGELOG.md) — retroactive feature-release history
- [proposals/INDEX.md](proposals/INDEX.md) — full proposal catalog (candidates, drafts, shipped)
- [docs/roadmap-maintenance.md](docs/roadmap-maintenance.md) — `.specrew/roadmap.yml` maintenance

## Contributing

Specrew is alpha. Reading, issues, and discussion are welcome now. External pull requests are intentionally deferred until the operating model and review boundaries stabilize. Specrew builds itself with its own methodology in this repository, and that loop is where every methodology change is proven out.

## License

Specrew is released under the MIT License. See [LICENSE](LICENSE) for the repository license and [NOTICE.md](NOTICE.md) for upstream attribution covering derived Squad and Spec Kit materials.
