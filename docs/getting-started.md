<p align="center">
  <img src="assets/specrew-icon.png" alt="Specrew" height="100" align="middle" />
  &nbsp;&nbsp;
  <img src="assets/specrew-wordmark-light.svg#gh-light-mode-only" alt="Specrew — Governed Agentic SDLC" height="84" align="middle" />
  <img src="assets/specrew-wordmark-dark.svg#gh-dark-mode-only" alt="Specrew — Governed Agentic SDLC" height="84" align="middle" />
</p>

# Specrew Getting Started

## Minimal Flow — Try Specrew in 5 minutes

Four commands. A new directory, a one-line feature description, and Specrew runs the full spec-driven lifecycle end-to-end. Read the [README](../README.md) first if you want the philosophy; this page just gets you running.

### 1. Check dependencies

```powershell
pwsh --version          # PowerShell 7.x or later
git --version
uv --version            # required for Spec Kit install/repair
npm --version           # required for Squad install
gh --version            # required for PR-creation surfaces (optional but recommended)
```

If any are missing:

- **PowerShell 7**: [https://aka.ms/powershell](https://aka.ms/powershell)
- **Git**: [https://git-scm.com/downloads](https://git-scm.com/downloads)
- **uv**: `powershell -c "irm https://astral.sh/uv/install.ps1 | iex"` (Windows) or `curl -LsSf https://astral.sh/uv/install.sh | sh` (macOS/Linux)
- **Node.js + npm**: [https://nodejs.org/](https://nodejs.org/) (LTS)
- **GitHub CLI**: [https://cli.github.com/](https://cli.github.com/) — used for the PR-creation lifecycle gates

#### Pick at least one host CLI

Specrew needs one of the supported **agent host CLIs** to actually run a lifecycle session. As of v0.26.0 there are three supported hosts — install at least one. You select which one at launch time via `specrew start --host <kind>` (default: `copilot`).

| Host | `--host` value | CLI binary | Install URL | Notes |
|---|---|---|---|---|
| **GitHub Copilot** *(default)* | `copilot` | `copilot` | [docs.github.com/en/copilot/how-tos/copilot-cli](https://docs.github.com/en/copilot/how-tos/copilot-cli) | Most-tested host; default if `--host` is omitted |
| **Claude Code** | `claude` | `claude` | [docs.anthropic.com/en/docs/claude-code/installation](https://docs.anthropic.com/en/docs/claude-code/installation) | Headless `claude -p` invocation; rich subagent + hook surface (see [Proposal 105](../proposals/105-host-native-hook-deployment.md) for the hook-deployment follow-up) |
| **Codex CLI** | `codex` | `codex` | [developers.openai.com/codex/cli](https://developers.openai.com/codex/cli) | `codex exec --cd` invocation; no user-defined slash commands so the Crew uses pwsh-form boundary-advance instructions instead |

Reserved-but-deferred kinds: `antigravity` (follow-up slice once `agy` working-directory + session-ID issues clear), `auto` (reserved for [Proposal 104](../proposals/104-multi-host-onboarding-and-selection-flow.md) first-run probe). Specrew rejects these with explicit "deferred" guidance rather than silently falling back.

### 2. Install Specrew from PowerShell Gallery

```powershell
Install-Module Specrew -Scope CurrentUser -SkipPublisherCheck
```

The `-SkipPublisherCheck` flag is required because the module is currently signed with a self-signed certificate. A CA-signed release is planned.

Verify:

```powershell
specrew --version
```

### 3. Bootstrap a project

```powershell
mkdir C:\Dev\calculator
cd C:\Dev\calculator
git init
specrew init
```

`specrew init` installs Spec Kit (via `uv`) and Squad (via `npm`) if missing, scaffolds the `.specrew/`, `.specify/`, and `.squad/` directories, configures the multi-agent team baseline, deploys the slash-command surface to `.claude/skills/`, `.github/skills/`, and `.agents/skills/`, and seeds the governance + roadmap configuration. The bootstrap is non-destructive and idempotent — safe to re-run.

### 4. Start the first feature

Pick the host at launch time via `--host`. The default (no flag) is `copilot`:

```powershell
# Default: GitHub Copilot host
specrew start "Build a web based calculator with only the + - * / MR MC M+ M- operations"

# Or with Claude Code
specrew start --host claude "Build a web based calculator with only the + - * / MR MC M+ M- operations"

# Or with Codex CLI
specrew start --host codex "Build a web based calculator with only the + - * / MR MC M+ M- operations"
```

That single command:

1. Refreshes the runtime handoff artifacts (`.specrew/last-start-prompt.md`, `.specrew/start-context.json`, `.specrew/start-summary.md`)
2. Validates the selected host is installed on PATH (otherwise exits with the install URL for that host — see step 1's host table)
3. Launches the selected host CLI in the current terminal with Specrew's bootstrap context. Per-host flag translation makes `--remote` / `--allow-all` / `--autopilot` uniform regardless of host (see [docs/user-guide.md "Multi-Host Launch"](user-guide.md#multi-host-launch-v0260) for the full flag-translation matrix)
4. Hands the Crew the feature description and tells it to drive the canonical lifecycle: `specify → clarify → plan → tasks → before-implement → implement → review-signoff → retro → iteration-closeout → feature-closeout`
5. Stops at every approval boundary and waits for your explicit verdict before advancing (gate-respecting mode is the default since Proposal 066)

When the Crew surfaces a clarify question, answer it. When it surfaces a planning artifact, review it. When it asks for an implementation verdict, type one of the recognized verdict shapes (e.g. `approved for implementation-boundary entry`). The lifecycle then continues to the next boundary.

> **Switching hosts on the same project** is supported: end the session and restart `specrew start --host <other>`. Mid-session switching requires you to end and restart — by design. (Concurrent multi-host execution is Scenario B of [Proposal 024](../proposals/024-multi-host-runtime-abstraction.md), not in F-040's scope.)

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
│   └── start-summary.md
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
- **Dashboard**: `specrew where` shows the velocity dashboard; full reference in [docs/dashboard-guide.md](dashboard-guide.md)
- **Versioning**: [docs/versioning.md](versioning.md)
- **CHANGELOG**: [CHANGELOG.md](../CHANGELOG.md)

---

## Advanced Install Options

The PowerShell Gallery path above is the recommended install. The variants below exist for specific scenarios.

### Prerelease channel — early adopters

For validating the next version before it goes stable:

```powershell
Install-Module Specrew -AllowPrerelease -Scope CurrentUser -SkipPublisherCheck
```

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

When `specrew start` runs without a feature description in an existing project, the Crew runs brownfield discovery first and asks targeted intake questions before invoking `/speckit.specify`.

---

## Known Limitations

- **Multi-host runtime**: Copilot CLI, Claude Code, and Codex CLI are all supported as of v0.26.0 via `specrew start --host <kind>` (see [docs/user-guide.md](user-guide.md) for the full per-host flag-translation matrix). Antigravity, `--host auto`, and VS Code Chat are roadmap items per [Proposal 069](../proposals/069-multi-host-launch-path.md), [Proposal 104](../proposals/104-multi-host-onboarding-and-selection-flow.md), [Proposal 071](../proposals/071-vscode-copilot-chat-host.md).
- **Multi-developer coordination**: single-developer workflow only. [Proposal 010](../proposals/010-multi-developer-reconciliation.md) covers the eventual model.
- **Brownfield cartography**: discovery covers the obvious surfaces (manifests, configs, docs) but JIT codebase cartography for arbitrary inherited repos is a future item ([Proposal 025](../proposals/025-jit-codebase-cartography.md)).
- **Module signing**: the `-SkipPublisherCheck` flag is required on `Install-Module` until a CA-signed release lands. See [Proposal 072](../proposals/072-psgallery-unsigned-default.md) for the decision context.
- **Windows path encoding**: some PowerShell environments encounter UTF-8 issues on Windows. Set `$env:PSDefaultParameterValues['*:Encoding'] = 'utf8'` if you see mojibake in artifacts.
- **External pull requests**: not yet part of the alpha operating model. Reading, issues, and discussion are welcome; PRs are intentionally deferred until the operating model stabilizes.

## Platform Support Status

| Platform | Status |
|---|---|
| Windows 11 (primary) | ✅ Fully validated |
| WSL Ubuntu | ✅ Manually validated end-to-end (specrew init + specrew start launch the host CLI; Copilot+Squad validated through F-019; Claude/Codex hosts added in v0.26.0 and parser-tested) |
| Linux native (Ubuntu) | ✅ Path handling cross-platform; CI matrix configured |
| macOS | 🔧 Path handling cross-platform; CI matrix configured; no in-house validation runs yet |

Detailed cross-platform evidence lives in `specs/019-specrew-distribution-module/test-evidence/us5-cross-platform.md`.
