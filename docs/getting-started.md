<p align="center">
  <img src="assets/specrew-icon.png" alt="Specrew" height="100" align="middle" />
  &nbsp;&nbsp;
  <img src="assets/specrew-wordmark-light.svg#gh-light-mode-only" alt="Specrew — Governed Agentic SDLC" height="84" align="middle" />
  <img src="assets/specrew-wordmark-dark.svg#gh-dark-mode-only" alt="Specrew — Governed Agentic SDLC" height="84" align="middle" />
</p>

# Specrew Getting Started

## Minimal Flow — Try Specrew in 5 minutes

Four commands. A new directory, a one-line feature description, and Specrew runs the full spec-driven lifecycle end-to-end. Read the [README](../README.md) first if you want the philosophy; this page just gets you running.

### 1. Install Specrew

Start here. The dependency details are below the install commands, but the happy path is intentionally short.

#### macOS / Linux — native shell (recommended)

```sh
curl -fsSL https://raw.githubusercontent.com/alonf/specrew/main/install.sh | sh
```

`install.sh` is the user-facing entrypoint. It auto-installs PowerShell Core as an internal dependency if it is missing (Ubuntu/Debian via the Microsoft apt repository; macOS via Homebrew — `brew` runs as you, never `sudo`), installs Specrew from the PowerShell Gallery, and installs the native `specrew` command wrappers onto your `PATH`. You never type `pwsh` or `Install-Module`. Append `-s -- --prerelease` to install a beta. On an unsupported platform it fails closed with a manual-install link (it never reports a half-finished install as success).

#### Windows — PowerShell Gallery

```powershell
Install-Module Specrew -Scope CurrentUser -SkipPublisherCheck
```

`-SkipPublisherCheck` tells PowerShellGet to skip the Authenticode publisher check. Specrew modules ship **unsigned** (the OSS PowerShell Gallery norm) since v0.24.1, so the flag keeps the install from failing or prompting on machines that enforce that check. Use it only for the official Specrew Gallery package or a source you trust — see [Proposal 072](../proposals/072-psgallery-unsigned-default.md) for the decision context. CA-signed releases for corporate/enterprise consumers are tracked as future work.

> **macOS/Linux module fallback (only if you skip `install.sh`):** `Install-Module` exists only inside PowerShell — run `pwsh` first, then `Install-Module Specrew -Scope CurrentUser -SkipPublisherCheck`. Running it in zsh/bash prints `command not found: Install-Module`. The PowerShell Gallery prompt defaults to **`N`** (pressing Enter *declines* the install) — answer **`A` / Yes to All** or pass `-Force`. After the module is installed, run `specrew install-shell-wrappers` to get the native `specrew` command without `pwsh`.

Verify:

```powershell
specrew --version
```

### 2. Dependencies Specrew uses

You do not need to memorize this list before installing. Use it when an install/bootstrap step reports a missing tool or when you are preparing a machine manually.

```powershell
specrew --version
git --version
pwsh --version          # Windows: required shell/runtime; macOS/Linux: auto-installed by install.sh when missing
uv --version            # used for Spec Kit install/repair
npm --version           # used for Squad install when Copilot/Squad surfaces are needed
gh --version            # optional but recommended for PR-creation surfaces
```

Required or commonly used dependencies:

- **Git**: [https://git-scm.com/downloads](https://git-scm.com/downloads)
- **PowerShell 7**: [https://aka.ms/powershell](https://aka.ms/powershell). On macOS/Linux, the native `install.sh` path auto-installs it as an internal dependency when missing. On Windows, run Specrew from PowerShell 7+.
- **uv**: `powershell -c "irm https://astral.sh/uv/install.ps1 | iex"` (Windows) or `curl -LsSf https://astral.sh/uv/install.sh | sh` (macOS/Linux)
- **Node.js + npm**: [https://nodejs.org/](https://nodejs.org/) (Node 24+). On macOS with `nvm`, a `brew`-installed Node can be *shadowed* by an older `nvm` default — verify `node -v` **inside `pwsh`** (the runtime Specrew uses), not only in your login shell. See [troubleshooting](troubleshooting.md#macos-node-version-shadowed-by-nvm).
- **GitHub CLI**: [https://cli.github.com/](https://cli.github.com/) — used for the PR-creation lifecycle gates

#### Pick at least one host CLI

Specrew also needs one supported **agent host CLI** to run a lifecycle session. Install at least one. You select which one simply by **launching it** in the project (the SessionStart hook drives that host), or explicitly via `specrew start --host <kind>`. Two defaults matter for the `specrew start` path:

- **`--host` flag default (non-interactive / CI / automation)**: `copilot` — most-tested host, predictable for headless runs
- **Interactive menu default (TTY, multiple installed hosts)**: highest-priority installed host in the order **Claude → Cursor → Codex → Copilot → Antigravity**. The interactive menu shows installed hosts in priority order; `[default 1]` selects the highest-priority one

When `--host` is omitted in interactive mode, Specrew shows a numbered menu of installed hosts (plus an "(not installed)" group with install URLs).

| Host | `--host` value | CLI binary | Install URL | Notes |
|---|---|---|---|---|
| **GitHub Copilot** *(`--host` flag default)* | `copilot` | `copilot` | [docs.github.com/en/copilot/how-tos/copilot-cli](https://docs.github.com/en/copilot/how-tos/copilot-cli) | Most-tested host; the `--host` flag falls back to `copilot` in non-interactive contexts. Interactive menu priority: 4 of 5 |
| **Claude Code** | `claude` | `claude` | [docs.anthropic.com/en/docs/claude-code/installation](https://docs.anthropic.com/en/docs/claude-code/installation) | Headless `claude -p` invocation; rich subagent + hook surface (see [Proposal 105](../proposals/105-host-native-hook-deployment.md) for the hook-deployment follow-up) |
| **Cursor** | `cursor` | `cursor-agent` | [cursor.com/cli](https://cursor.com/cli) | Interactive `cursor-agent "<prompt>" --workspace <path>` invocation; `--force` maps from `--allow-all`. No user-defined slash commands (like Codex) — skills + Crew charters deploy as `.cursor/rules/*.mdc` context; coordinator prompt via `AGENTS.md`. Menu priority 2 of 5 (between Claude and Codex). Added in F-050 |
| **Codex CLI** | `codex` | `codex` | [developers.openai.com/codex/cli](https://developers.openai.com/codex/cli) | `codex exec --cd` invocation; no user-defined slash commands so the Crew uses pwsh-form boundary-advance instructions instead |
| **Antigravity** | `antigravity` | `agy` | [antigravity.google](https://antigravity.google/) | Native entry point is `agy` in the project; `specrew start --host antigravity` launches `agy -i <prompt> --add-dir <path>`. `agy -c` or `agy --conversation <id>` resumes a prior Antigravity conversation. `--dangerously-skip-permissions` maps from `--allow-all`. |

Reserved-but-deferred kind: `auto` (reserved for [Proposal 104](../proposals/104-multi-host-onboarding-and-selection-flow.md) first-run probe — partially implemented via the F-043 first-run menu but `auto` literal still rejected). Specrew rejects this with explicit "deferred" guidance rather than silently falling back.

### Updating Specrew later

For an existing PowerShell Gallery install, use the normal module update path first:

```powershell
Update-Module Specrew
Import-Module Specrew -Force
specrew --version
```

If PowerShellGet cannot update the installed copy in place, reinstall from the trusted Gallery source:

```powershell
Install-Module Specrew -Scope CurrentUser -Force -SkipPublisherCheck
Import-Module Specrew -Force
specrew --version
```

`-Force` here belongs to PowerShellGet: it intentionally overwrites or reinstalls the module package. It does not bypass Specrew lifecycle gates and it does not make brownfield project conflicts safe to ignore. `-SkipPublisherCheck` bypasses publisher validation, so use it only for the official PowerShell Gallery Specrew package or a package source you already trust. Do not copy this flag into unrelated module installs as a default habit.

After updating the tool, refresh each existing Specrew project so its deployed hooks, skills, and templates match the new version. From inside the project, run **`specrew update`** — the canonical project re-sync that brings the project to the version of Specrew you now have installed (run `specrew update --info` first to see the version status). Re-running **`specrew init`** also redeploys managed project files and is the heavier equivalent; both are idempotent. Do this when the release notes mention runtime, extension, template, or skill-catalog changes, or when `specrew start` reports missing runtime surfaces. For `specrew init`, add `-Force` only when you intentionally want to refresh managed surfaces even if the project is not empty.

If the wrong version still loads, project assets look incomplete, or a resumed session points at the wrong feature, use the recovery guide in [troubleshooting.md](troubleshooting.md) before editing generated files by hand.

### 3. Bootstrap a project

```powershell
mkdir C:\Dev\calculator
cd C:\Dev\calculator
git init
specrew init
```

`specrew init` installs Spec Kit (via `uv`) and Squad (via `npm`) if missing, scaffolds the `.specrew/`, `.specify/`, and `.squad/` directories, configures the multi-agent team baseline, deploys the slash-command surface to `.claude/skills/`, `.github/skills/`, and `.agents/skills/`, **deploys the Specrew session hooks**, and seeds the governance + roadmap configuration. The bootstrap is non-destructive and idempotent — safe to re-run.

Because init deploys the hooks, on a **hook-capable host** (Claude, Codex, Copilot, Cursor, and Antigravity where project `.agents/hooks.json` fires) you just **launch your host** afterwards (`claude` / `codex` / `copilot` / `cursor`, or `agy` when Antigravity hooks fire) — the SessionStart or equivalent hook bootstraps you automatically, so you do **not** need `specrew start`. Antigravity support is bounded to `PreInvocation` bootstrap injection and `Stop` handover decisions; if those hooks do not fire in your environment, recover with `specrew start --host antigravity`.

### 4. Start the first feature

After `specrew init`, there are two equivalent ways to begin — **the SessionStart hook is the primary path, and `specrew start` is optional**:

- **Just open your host in the project** (`claude`, `codex`, `copilot`, `cursor`, or `agy` when Antigravity hooks fire). A **SessionStart or equivalent hook** bootstraps the session — it writes the governed launch contract, renders your orientation banner, and drives the `specify → plan → implement → review → retro` lifecycle. No `specrew start` needed when the hook fires.
- **Or run `specrew start`** (optional) to **pick / switch the host** (`--host <kind>`), to **start from a script** with the feature prompt in one command, or to recover on **Antigravity** when its bounded project hooks do not fire. The non-interactive default (no flag, no TTY) is `copilot`; the interactive-menu default is the highest-priority installed host (Claude → Cursor → Codex → Copilot → Antigravity):

```powershell
# Default: GitHub Copilot host
specrew start "Build a web based calculator with only the + - * / MR MC M+ M- operations"

# Or with Claude Code
specrew start --host claude "Build a web based calculator with only the + - * / MR MC M+ M- operations"

# Or with Cursor (cursor-agent)
specrew start --host cursor "Build a web based calculator with only the + - * / MR MC M+ M- operations"

# Or with Codex CLI
specrew start --host codex "Build a web based calculator with only the + - * / MR MC M+ M- operations"

# Or with Antigravity (agy)
specrew start --host antigravity "Build a web based calculator with only the + - * / MR MC M+ M- operations"
```

> **Cursor Quickstart.** Cursor's host is the standalone **`cursor-agent`** CLI (install: [cursor.com/cli](https://cursor.com/cli); verify `cursor-agent --version`, authenticate `cursor-agent login`). `specrew start --host cursor "<feature>"` launches `cursor-agent` interactively in your project workspace with Specrew's coordinator prompt (delivered via `AGENTS.md`) and begins the lifecycle. **Caveat — no slash palette:** unlike Claude/Copilot, Cursor has no user-typed `/speckit.*` slash commands; the lifecycle is driven entirely by the `AGENTS.md` coordinator prompt plus auto-attached `.cursor/rules/*.mdc` context (Speckit skills + Crew charters deploy there as rules, not as a command palette). If `cursor-agent` is not on PATH, Specrew exits with an install link rather than launching. Use `--allow-all` to auto-approve tool calls (maps to `cursor-agent --force`).

> **Antigravity Quickstart.** Antigravity's host binary is **`agy`** (verify with `agy --version`). After `specrew init`, run `agy` from the project root and type your request or `continue`; the project `.agents/hooks.json` slice injects the Specrew bootstrap when that Antigravity build fires `PreInvocation`, and `Stop` records the handover decision. Native resume is `agy -c` for the latest conversation or `agy --conversation <id>` for a specific one. `specrew start --host antigravity "<feature>"` remains the explicit host-selection path and the fallback when those project hooks do not fire. Use `--allow-all` through Specrew, or `agy --dangerously-skip-permissions` when launching Antigravity directly, to auto-approve tool permission prompts between lifecycle boundaries.

That single command:

1. Refreshes the runtime handoff artifacts (`.specrew/last-start-prompt.md`, `.specrew/start-context.json`, `.specrew/start-summary.md`)
2. Validates the selected host is installed on PATH (otherwise exits with the install URL for that host — see step 1's host table)
3. Launches the selected host CLI in the current terminal with Specrew's bootstrap context. Per-host flag translation makes `--remote` / `--allow-all` / `--autopilot` uniform regardless of host (see [docs/user-guide.md "Multi-Host Launch"](user-guide.md#multi-host-launch-v0260) for the full flag-translation matrix)
4. Hands the Crew the feature description and tells it to drive the canonical lifecycle: `specify → clarify → plan → tasks → before-implement → implement → review-signoff → retro → iteration-closeout → feature-closeout`
5. Stops at every approval boundary and waits for your explicit verdict before advancing (gate-respecting mode is the default since Proposal 066)

When the Crew surfaces a clarify question, answer it. When it surfaces a planning artifact, review it. When it asks for an implementation verdict, type one of the recognized verdict shapes (e.g. `approved for implementation-boundary entry`). The lifecycle then continues to the next boundary.

> **Hook-driven bootstrap.** A **SessionStart hook** bootstraps and **drives** the session when you launch a
> host inside a Specrew project — it writes the governed launch contract (`.specrew/last-start-prompt.md`,
> with the user-profile/expertise adaptation + the coordinator framing), renders your orientation banner and a
> Resume / New / Pick-feature menu as prose before any picker, and follows the governed lifecycle. So after
> `specrew init` you do **not** need to run `specrew start` first. This works on **Claude, Codex, Copilot, Cursor, and
> Antigravity when `.agents/hooks.json` fires**. Antigravity is bounded to `PreInvocation` bootstrap injection and `Stop`
> handover decisions, so `specrew start --host antigravity` remains the fallback when those hooks do not fire. (Full
> cross-host story: [docs/user-guide.md "Session Continuity"](user-guide.md#session-continuity--auto-bootstrap-rolling-handover-host-switching).)
>
> **`specrew start` remains available — and does what only it can:** host selection / switching (`--host`),
> a one-command scripted start with a feature prompt, uniform `--remote` / `--allow-all` / `--autopilot` flag
> translation, and the Antigravity hook-failure fallback. Both paths share the SAME contract generator
> (`Get-StartPrompt`), so there is no drift between them; when a launcher and a hook both fire in one startup,
> a dedupe handshake guarantees exactly one bootstrap.
>
> A companion **Stop hook** (the per-host end-of-turn event) refreshes one always-latest, local
> Proposal-130 rolling handover on every material turn — deployed across the four hooked hosts and
> crash-safe (it reflects the last completed turn even on a hard-kill). The **agent authors the handover
> body** (the hook is transcript-blind and only keeps the floor fresh); when the agent renders a re-entry /
> boundary packet it persists that packet as the handover, so the next session inherits exactly what you
> last saw. If a session ends without authoring one, the next launch shows a **hollow-handover warning**
> instead of a rich resume it does not actually have — you are the backstop, not a fabricated summary.
>
> **Two ways to start — the hook is the primary path:**
>
> - **Direct launch** (`claude` / `codex` / `copilot` / `cursor-agent`, or `agy` when Antigravity hooks fire, in the project) — the SessionStart or equivalent hook
>   bootstraps and **drives**: it writes the governed contract and the agent renders its orientation on the
>   **first reply**, not the splash screen (a host hook cannot paint the host's UI). Just **ask** — "What
>   should I do now?" — or **state intent** — "Create a feature for …". The hook hands the agent the same
>   contract `specrew start` writes, via the same generator (no drift).
> - **`specrew start`** (optional) — host selection / switching (`--host`), a one-command scripted start,
>   uniform `--remote` / `--allow-all` / `--autopilot` flag translation, and the fallback path on
>   **Antigravity** when project hooks do not fire. When both a launcher and a hook fire in one startup, a dedupe handshake yields
>   exactly one bootstrap.

**The Design Workshop.** For substantive features, the Crew also facilitates a **Design Workshop** — first at intake (it hands you a lens agenda, opens with the **product & problem domain** lens to ground users / pain / MVP / constraints, then works the technical lenses that apply) and again at the design-analysis stop before planning (to co-design the architecture with you: component map, responsibilities, flows, and trade-off options). For any code-writing feature it also runs the **code & implementation** lens, which captures implementation-craft rules (language version, patterns, per-stack conventions, dependency choices) into a per-feature `implementation-rules.yml` manifest, which the lens's implement-time guidance skill then uses to guide the coding agent while it writes code. It is a conversation, not a questionnaire — you see every diagram and agenda in-band, and every decision is recorded as a durable artifact. The full methodology is in [docs/methodology/design-workshop-methodology.md](methodology/design-workshop-methodology.md).

> **Switching hosts on the same project** is supported: end the session, then **launch the other host directly** in the project (`claude` / `codex` / `copilot` / `cursor-agent` / `agy`) and type `continue` — its SessionStart or equivalent hook reads the rolling handover and resumes the same feature at the same spot. `specrew start --host <other>` stays available as the optional explicit driver, and it is the fallback on **Antigravity** if its bounded project hooks do not fire. Mid-session switching still means end-and-restart — by design. (Concurrent multi-host execution is Scenario B of [Proposal 024](../proposals/024-multi-host-runtime-abstraction.md), not in F-040's scope.)

### 5. Close the iteration (and the feature)

The lifecycle does not end at `implement`. Two more boundaries finish the work:

- **`iteration-closeout`** — after the Crew passes review-signoff and writes `retro.md`, you approve the iteration close. Boundary-sync generates `specs/<feature>/iterations/<NNN>/dashboard.md` (per-iteration snapshot: variance, drift count, FR scoreboard) and appends the iteration to `.specrew/closed-iterations.yml`. Verdict shape: `approved for iteration-closeout`.
- **`feature-closeout`** — after the final iteration of a feature is closed, you approve the feature close. Boundary-sync generates `specs/<feature>/closeout-dashboard.md` (cross-iteration FR scoreboard + velocity + delivery summary) and marks the feature complete. Verdict shape: `approved for feature-closeout`.

**Why this matters**: these two boundaries are what mark the work durably "done". Until you authorize them, the feature is **in flight** — `specrew where` will list it as active, and starting a new `specrew start "<other feature>"` will resume the in-flight feature instead of starting fresh. The artifacts produced at closeout (dashboard.md per iteration + closeout-dashboard.md per feature) are also the canonical input that future iterations and features read for velocity calibration. Skipping closeout silently degrades both your project's state-tracking and Specrew's own estimation accuracy.

> If you only want to take a break (not finish), close your terminal — Specrew preserves session state (and a rolling handover in `.specrew/handover/session-handover.md`). On a hook host, just **relaunch your host** in the project — the SessionStart or equivalent hook auto-resumes at the same boundary from that handover; you do not route resume through `specrew start` (it stays optional, and is the recovery path on Antigravity if hooks do not fire). Closeout is the explicit "this is done" gate, not the "I'm pausing" gate.

That is the full minimal flow. Everything else on this page is optional — covered in the sections below.

---

## What just happened

After you run the four commands above, the project tree contains:

```text
calculator/
├── .specrew/              # Specrew governance config + session state
│   ├── config.yml         # version, NFR thresholds, governance dials
│   ├── constitution.md    # project's authority text
│   ├── roadmap.yml        # phase/feature index
│   ├── last-start-prompt.md
│   ├── start-context.json
│   ├── start-summary.md
│   ├── handover/          # rolling cross-host session handover (gitignored)
│   └── runtime/           # hook journals + session markers (gitignored)
├── .specify/              # Spec Kit installation (managed)
├── .squad/                # Squad team + casting + identity
├── .claude/skills/        # /specrew-* slash command catalog (Claude Code)
├── .github/skills/        # /specrew-* slash command catalog (Copilot CLI)
├── .agents/skills/        # /specrew-* slash command catalog (host-neutral)
└── specs/                 # populated as Squad runs /speckit.specify
```

As Squad runs the lifecycle, it adds `specs/001-web-calculator/spec.md`, `plan.md`, `tasks.md`, and per-iteration artifacts under `iterations/001/`. You can inspect them between boundaries.

## Where to go next

- **Day-to-day usage**: [docs/user-guide.md](user-guide.md)
- **Design Workshop**: how the lens-driven design conversation works at intake and before planning — [docs/methodology/design-workshop-methodology.md](methodology/design-workshop-methodology.md)
- **Recovery paths**: [docs/troubleshooting.md](troubleshooting.md)
- **Dashboard**: `specrew where` shows the velocity dashboard; full reference in [docs/dashboard-guide.md](dashboard-guide.md)
- **Versioning**: [docs/versioning.md](versioning.md)
- **CHANGELOG**: [CHANGELOG.md](../CHANGELOG.md)

---

## Advanced Install Options

The PowerShell Gallery path above is the recommended install. The variants below exist for specific scenarios.

### Prerelease channel — early adopters

Every Specrew release ships first as a `-beta1` prerelease to PSGallery (then `-beta2`, … if validation fails), then promotes to stable only after manual install validation passes. If you want to help validate the next version (or just track the bleeding edge), install the prerelease.

#### Side-by-side gotcha

PowerShellGet installs prerelease versions **side-by-side** with whatever stable version is already on disk. It does NOT replace or remove the stable. After:

```powershell
Install-Module Specrew -AllowPrerelease -Scope CurrentUser -SkipPublisherCheck
```

you have BOTH versions installed:

```powershell
Get-Module Specrew -ListAvailable | Select-Object Name, Version, PrivateData
# Name     Version       PrivateData
# ----     -------       -----------
# Specrew  0.27.4        @{PSData=@{...}}                                ← stable
# Specrew  0.27.4.0      @{PSData=@{Prerelease='beta1'; ...}}            ← prerelease
```

**Plain `Import-Module Specrew` (or autoload) picks the highest stable**, NOT the highest version overall. So if both are installed, `specrew --version` reports the stable version even when you intended to test the beta. This is by design in PowerShell module resolution.

Three patterns cover the cases you actually need:

#### Pattern A: Test the beta cleanly (no stable on disk)

Uninstall any installed version first, then install only the prerelease. This guarantees `Import-Module Specrew` loads the beta:

```powershell
# 1. Remove everything (both stable + any prior prereleases)
Get-Module Specrew | Remove-Module
Uninstall-Module Specrew -AllVersions -Force

# 2. Install the latest prerelease (only)
Install-Module Specrew -AllowPrerelease -Scope CurrentUser -SkipPublisherCheck -Force

# 3. Verify
Import-Module Specrew -Force
specrew --version             # Should report the -beta1 version
Get-Module Specrew -ListAvailable | Select-Object Name, Version, @{N='Prerelease';E={$_.PrivateData.PSData.Prerelease}}
```

To pin a specific beta (not just "latest prerelease"):

```powershell
Install-Module Specrew -RequiredVersion '0.27.4-beta1' -AllowPrerelease -Scope CurrentUser -SkipPublisherCheck -Force
```

Note the prerelease syntax: the current convention tags releases as `v<X.Y.Z>-beta1` (no dot), and the installable version string matches — `0.35.0-beta1`, not `0.35.0-beta.1`. Use `Find-Module Specrew -AllowPrerelease -AllVersions` to see exact installable strings.

#### Pattern B: Beta alongside stable (compare or fall back)

If you want to keep stable installed AND test the beta in parallel — e.g. to compare behavior or roll back fast:

```powershell
# Add the beta side-by-side (stable stays)
Install-Module Specrew -AllowPrerelease -Scope CurrentUser -SkipPublisherCheck -Force

# Auto-load picks stable by default — force the beta explicitly:
Remove-Module Specrew -ErrorAction SilentlyContinue
Import-Module Specrew -RequiredVersion '0.27.4-beta1' -Force

specrew --version             # Now reports -beta1
```

To switch back to stable mid-session:

```powershell
Remove-Module Specrew
Import-Module Specrew -Force   # Auto-loads highest stable
```

This pattern is useful for short test runs. For day-to-day work, Pattern A (single-version) is cleaner because every `pwsh` session and every script does the right thing without `-RequiredVersion` ceremony.

#### Pattern C: Move from beta back to stable

After the beta promotes to a stable release (or you decide to drop back), uninstall every prerelease and install only the stable:

```powershell
# 1. Drop loaded module
Get-Module Specrew | Remove-Module

# 2. Remove ALL installed versions (stable + prereleases)
Uninstall-Module Specrew -AllVersions -Force

# 3. Install only the new stable
Install-Module Specrew -Scope CurrentUser -SkipPublisherCheck -Force

# 4. Verify
Import-Module Specrew -Force
specrew --version             # Should report the new stable (no -beta suffix)
Get-Module Specrew -ListAvailable
```

The `-AllVersions` flag on `Uninstall-Module` is what does the work — without it, only the highest stable is removed and prereleases linger. Linger-prereleases are harmless on disk but confuse later updates.

#### Single-version invariant (recommended for most users)

The cleanest day-to-day setup is **exactly one installed version of Specrew at a time** — either stable OR prerelease, never both. Whenever you change channels:

```powershell
Uninstall-Module Specrew -AllVersions -Force
Install-Module Specrew [-AllowPrerelease] -Scope CurrentUser -SkipPublisherCheck -Force
```

Two flags govern the channel:

| Goal | Command |
|---|---|
| Latest stable | `Install-Module Specrew -Force` |
| Latest prerelease | `Install-Module Specrew -AllowPrerelease -Force` |
| Specific stable version | `Install-Module Specrew -RequiredVersion '0.27.3' -Force` |
| Specific prerelease | `Install-Module Specrew -RequiredVersion '0.27.4-beta1' -AllowPrerelease -Force` |

(Add `-Scope CurrentUser -SkipPublisherCheck` to all of these unless you have a reason to deviate.)

### Local clone, direct import — Specrew contributors

If you're hacking on Specrew itself:

```powershell
git clone https://github.com/alonf/specrew.git C:\Dev\Specrew
Import-Module C:\Dev\Specrew\Specrew.psd1
```

This exposes the same aliases as the PSGallery install but only when you import the manifest by path. Good for the bleeding edge; awkward for "any session, any directory" use.

### Install from clone — installed-equivalent from local source

When you want `Import-Module Specrew` to resolve without a path AND `Get-Module Specrew -ListAvailable` to list it, but you're working from a clone rather than PSGallery:

```powershell
# From inside the cloned repo
$version = (Import-PowerShellDataFile .\Specrew.psd1).ModuleVersion
$userModulePath = ($env:PSModulePath -split [System.IO.Path]::PathSeparator |
    Where-Object { $_ -like "*$HOME*Modules*" } | Select-Object -First 1)
$dest = Join-Path $userModulePath "Specrew\$version"

if (Test-Path $dest) { Remove-Item -Path $dest -Recurse -Force }
New-Item -ItemType Directory -Path $dest -Force | Out-Null
Copy-Item -Path .\Specrew.psd1, .\Specrew.psm1, .\scripts, .\extensions, .\templates `
    -Destination $dest -Recurse -Force

Get-Module Specrew -ListAvailable
Import-Module Specrew
```

For continuous syncing (clone changes immediately reflected as installed-module changes), use a symbolic link instead of copy. Requires Windows Developer Mode enabled, or running PowerShell as administrator:

```powershell
New-Item -ItemType SymbolicLink -Path $dest -Target $PWD.Path -Force
```

**Tradeoffs vs PSGallery**: Copy/symlink does not exercise the FileList machinery that `Install-Module` runs. To catch FileList regressions (missing internal helpers in the shipped package), validate via the PSGallery prerelease channel.

### Direct script invocation — non-module fallback

If your environment blocks module imports:

```powershell
pwsh -File C:\Dev\Specrew\scripts\specrew.ps1 <command>
```

Same arguments, different invocation. Loses the alias surface (`specrew`, `specrew-init`, etc.) but works everywhere PowerShell runs.

---

## Brownfield — adding Specrew to an existing project

`specrew init` is non-destructive. Running it inside an existing repo:

1. Detects existing files and merges configuration rather than overwriting
2. Walks the codebase for stack/domain signals (manifests, configs, docs)
3. Seeds `.specrew/constitution.md` with discovered constraints
4. Adds the multi-agent team baseline without disrupting any existing Squad setup
5. Defers the first `/speckit.specify` invocation until you type a concrete feature request — the Crew can run discovery first but cannot make scope decisions on its own (per Proposal 063, in flight as F-040)

```powershell
cd C:\Dev\existing-project
specrew init
specrew start
```

Use `specrew init -Force` only when you have decided to redeploy managed Specrew surfaces in that existing project. It does not bypass brownfield conflict checks; conflicts must still be resolved or intentionally preserved by the self-hosting ownership rules.

When `specrew start` runs without a feature description in an existing project, the Crew runs brownfield discovery first and asks targeted intake questions before invoking `/speckit.specify`.

---

## Known Limitations

- **Multi-host runtime**: Copilot CLI, Claude Code, Cursor (`cursor-agent`), Codex CLI, and Antigravity (`agy`) are all supported via direct host launch after `specrew init`, `specrew start --host <kind>`, or the interactive menu when `--host` is omitted (see [docs/user-guide.md](user-guide.md) for the full per-host flag-translation matrix). `--host auto` and VS Code Chat are roadmap items per [Proposal 104](../proposals/104-multi-host-onboarding-and-selection-flow.md) and [Proposal 071](../proposals/071-vscode-copilot-chat-host.md).
- **Antigravity host caveats**: Antigravity has bounded project hook support through `.agents/hooks.json`: `PreInvocation` bootstrap injection and `Stop` handover decisions. This slice has been manually validated on Windows with Antigravity CLI 1.0.8 using direct `agy` launch plus exit/re-enter resume, but it is still not a blanket parity claim for every Antigravity build or channel. If hooks do not fire or no orientation appears, recover with `specrew start --host antigravity` and keep the durable artifacts as the source of truth.
- **Per-host coordinator overlay** (v0.27.0): Copilot users get a `.squad/coordinator-overlay.md` file materialized at init. Claude / Cursor / Codex / Antigravity users get the same coordination behavior via the bootstrap prompt and host-native instruction files, but no overlay file is created (less discoverable). Functionally equivalent today; a future iteration may unify this.
- **Multi-developer coordination**: single-developer workflow only. [Proposal 010](../proposals/010-multi-developer-reconciliation.md) covers the eventual model.
- **Brownfield cartography**: discovery covers the obvious surfaces (manifests, configs, docs) but JIT codebase cartography for arbitrary inherited repos is a future item ([Proposal 025](../proposals/025-jit-codebase-cartography.md)).
- **Module signing**: Specrew modules ship **unsigned** since v0.24.1 (the OSS PowerShell Gallery norm), so `Install-Module` uses `-SkipPublisherCheck` to skip the Authenticode publisher check. CA-signed releases for corporate/enterprise consumers are tracked as future work. See [Proposal 072](../proposals/072-psgallery-unsigned-default.md) for the decision context.
- **Windows path encoding**: some PowerShell environments encounter UTF-8 issues on Windows. Set `$env:PSDefaultParameterValues['*:Encoding'] = 'utf8'` if you see mojibake in artifacts.
- **External pull requests**: not yet part of the alpha operating model. Reading, issues, and discussion are welcome; PRs are intentionally deferred until the operating model stabilizes.

## Platform Support Status

| Platform | Status |
|---|---|
| Windows 11 (primary) | ✅ Fully validated |
| WSL Ubuntu | ✅ Manually validated end-to-end (specrew init + specrew start launch the host CLI; Copilot+Squad validated through F-019; Claude/Codex hosts added in v0.26.0 and parser-tested; Antigravity host added in v0.27.0) |
| Windows native Antigravity | ✅ Manually validated with `agy` 1.0.8 direct launch, graceful exit, and resume through `agy -c` / conversation handoff |
| Linux native (Ubuntu) | ✅ Path handling cross-platform; CI matrix configured |
| macOS | 🔧 Path handling cross-platform; CI matrix configured; no in-house validation runs yet |

Detailed cross-platform evidence lives in `specs/019-specrew-distribution-module/test-evidence/us5-cross-platform.md`.
