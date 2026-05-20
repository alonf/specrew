<p align="center">
  <img src="assets/specrew-icon.png" alt="Specrew" height="100" align="middle" />
  &nbsp;&nbsp;
  <img src="assets/specrew-wordmark-light.svg#gh-light-mode-only" alt="Specrew — Governed Agentic SDLC" height="84" align="middle" />
  <img src="assets/specrew-wordmark-dark.svg#gh-dark-mode-only" alt="Specrew — Governed Agentic SDLC" height="84" align="middle" />
</p>

# Specrew Getting Started

Practical quickstart for running Specrew in a new repo (greenfield) and adding it to an existing repo (brownfield).

## Prerequisites

- PowerShell 7.x (`pwsh`)
- Git
- `uv` (used to install Spec Kit if missing)
- `npm` (used to install Squad if missing)

**Platform Support**: Specrew is validated on Windows 11. Cross-platform hardening
for Linux and macOS is in progress (path handling hardened; CI validation configured).
See README.md for current platform validation status.

## Key Capabilities (v0.21.0)

- **Session-State Durability**: Squad accurately resumes work after system reboots,
  detecting stale state and multi-worktree status.
- **In-Flight Progress Tracking**: Task progress, completed tasks, and active
  boundaries persist through all lifecycle events.
- **Slash-Command Surface**: First-class `/specrew.*` commands for key workflows.
  `/specrew.help` shows the full catalog; `/specrew.status` is an alias for `/specrew.where`.
- **Full Workflow Governance**: Spec Kit integration, Squad orchestration, and
  Specrew version stability across Phase 2 feature delivery.

## Before You Begin: Install Specrew

Specrew ships as a PowerShell module. Pick whichever install path fits your environment:

### Option A — PowerShell Gallery (recommended)

```powershell
Install-Module Specrew -Scope CurrentUser -SkipPublisherCheck
```

The `-SkipPublisherCheck` flag is required for now because the module is
signed with a self-signed certificate. It will be removed once a CA-issued
certificate is in place.

Once installed, the `specrew`, `specrew-init`, `specrew-start`, `specrew-update`,
`specrew-where`, `specrew-team`, `specrew-review`, and `specrew-version` aliases (plus their
PowerShell-canonical `Verb-Noun` forms — `Invoke-Specrew`, `Initialize-Specrew`,
`Start-Specrew`, `Update-Specrew`, `Show-SpecrewStatus`, `Invoke-SpecrewTeam`,
`Show-SpecrewReview`, `Show-SpecrewVersion`) are available in any PowerShell session.

**Prerelease channel** — early adopters who want to validate the next version
before it goes stable can opt into the prerelease channel:

```powershell
Install-Module Specrew -AllowPrerelease -Scope CurrentUser -SkipPublisherCheck
```

### Option B — Local clone (development workflow)

If you're contributing to Specrew or want to track the bleeding edge, clone the
repo and import the module manifest:

```powershell
git clone https://github.com/alonf/specrew.git C:\Dev\Specrew
Import-Module C:\Dev\Specrew\Specrew.psd1
```

The module-import path exposes the same `specrew` / `specrew-init` / `specrew-start` / `specrew-version` /
`specrew-where` / `specrew-team` / `specrew-review` / `specrew-update` aliases as the PSGallery install, so the rest of this guide works identically.

### Option C — Direct script invocation (fallback for non-module scenarios)

If you can't or don't want to load the module, every command is also reachable via
direct script invocation against the cloned repository:

```powershell
pwsh -File C:\Dev\Specrew\scripts\specrew.ps1 <command>
```

This is the lowest-friction fallback if your environment blocks module imports.

## Bootstrap Help

Once the module is loaded (Option A or B), view the bootstrap help:

```powershell
specrew init --help
```

If you're on Option C (direct-script), the equivalent is:

```powershell
pwsh -File C:\Dev\Specrew\scripts\specrew-init.ps1 -Help
```

## Greenfield Quickstart (recommended)

### Prerequisites for Full Greenfield Flow

The complete greenfield bootstrap-to-iteration flow requires:

- **Spec Kit CLI access via `uv`**: Specrew installs or repairs the official GitHub-hosted Spec Kit release when needed. The tested baseline is **Spec Kit 0.8.4**.
- **Squad CLI** (installed via `npm`): Must be available
- **Copilot CLI**: Required as Specrew's host runtime for Squad handoff and optional delegated-agent routing
- **UTF-8 environment support**: Some Windows PowerShell environments may encounter Unicode encoding issues (detailed in Known Limitations below)

### Greenfield Bootstrap Steps

1. Create a fresh repo and enter it.

```powershell
mkdir my-specrew-project
Set-Location my-specrew-project
git init
```

1. Run bootstrap.

```powershell
specrew init -ProjectPath .
```

For a fresh git-only repo, `-Force` is **not** required. Add `-Force` only when you want non-interactive default selections or when the repo already contains files beyond `.git`.

> Direct-script equivalent (Option C, no module): `pwsh -File C:\Dev\Specrew\scripts\specrew-init.ps1 -ProjectPath .`

1. Verify bootstrap succeeded (essential before proceeding).

The bootstrap script succeeds when:

- ✅ Dependency validation passes (versions of Spec Kit and Squad are acceptable)
- ✅ Specrew preflight confirms `specify init` can fetch a real template asset
- ✅ `.specrew/` governance artifacts are created
- ✅ `.specify/extensions/specrew-speckit/` extension is deployed

⚠️ **Note**: Bootstrap can fail before these artifacts are created if:

- Spec Kit CLI fails (e.g., asset dependency blocker, encoding issue)
- Squad CLI fails
- An error occurs during initialization

Check for these artifacts:

```powershell
# Governance layer (always created if dependency validation passes)
Test-Path '.specrew/config.yml'
Test-Path '.specrew/constitution.md'

# CLI initialization layer (created only if CLIs succeeded)
Test-Path '.specify/'
Test-Path '.squad/'
```

If `.specify/` is missing: Spec Kit initialization did not complete. Specrew now fails before mutating the project when its preflight still cannot make `specify init` healthy. See Known Limitations below.

### Baseline crew and post-bootstrap extension

Successful bootstrap installs a deterministic Specrew baseline crew in `.squad\team.md`:

- Spec Steward
- Planner
- Implementer
- Reviewer
- Retro Facilitator

Specrew manages those five baseline roles so re-running bootstrap can keep governance intact. If you need extra domain-specific members (for example Security, UX, DBA, or SRE support), add them **after** bootstrap using Specrew's command-driven team management interface:

```powershell
# Add a new domain-specific member
specrew team add security-analyst `
  --role "Security Analyst" `
  --charter "Review code for security vulnerabilities, ensure secure coding practices, validate authentication/authorization logic."

# List all team members (baseline + domain-specific)
specrew team list

# Update an existing member's charter
specrew team update security-analyst `
  --charter "Updated charter text..."

# Remove a domain-specific member
specrew team remove security-analyst
```

> Direct-script equivalents (Option C, no module): replace `specrew` with
> `pwsh -File C:\Dev\Specrew\scripts\specrew.ps1` — same arguments otherwise.

### Optional: Adding Specrew to PATH (only needed for Option C)

If you're using Option C (direct-script invocation) and want the short `specrew`
command without `pwsh -File`, add the scripts directory to your PATH. With the
module (Option A or B), this is unnecessary — the aliases resolve in any
PowerShell session that has the module imported.

**Current Session Only** (temporary, lost when shell closes):

```powershell
$env:PATH = "$env:PATH;C:\Dev\Specrew\scripts"
```

**Persistent** (all future sessions):

```powershell
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$pathEntries = $currentPath -split ";"
if ($pathEntries -notcontains "C:\Dev\Specrew\scripts") {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;C:\Dev\Specrew\scripts", "User")
    Write-Host "Added Specrew scripts to user PATH. Restart your shell to apply." -ForegroundColor Green
}
```

After adding to PATH persistently, restart your PowerShell session, then use the short form:

```powershell
specrew start "Build a REST API for user management"
specrew team list
specrew team add my-specialist --role "Role" --charter "Charter text"
```

The `add` command atomically creates all required Squad artifacts: (1) a new row in `.squad\team.md`, (2) `.squad\agents\<member>\charter.md`, and (3) `.squad\agents\<member>\history.md`. The `update` and `remove` commands modify or delete these artifacts consistently. Baseline roles are protected and cannot be removed through these commands.

When Copilot CLI is available, Specrew treats it as the mandatory host runtime rather than an optional delegated choice. Optional delegated agent families such as Claude and Codex are explicit opt-in during bootstrap via `-Agents`; bootstrap no longer asks interactive consent questions for them. By default, Specrew's baseline delegated preferences treat Implementer as Copilot-first, Planner and Reviewer as Claude-first, and Spec Steward as Codex-first (with fallback to Claude when Codex is unavailable) so review and problem-solving work can use delegated agents when they are enabled.

1. (Only if `.specify/` exists) Start your first feature run.

If the bootstrap created `.specify/` successfully, the canonical next step is:

```powershell
specrew start
```

Optionally, you can provide a short plain-language request up front:

```powershell
specrew start "Build a REST API for user management"
```

> Direct-script equivalent (Option C, no module): `pwsh -File C:\Dev\Specrew\scripts\specrew.ps1 start [optional-request]`

`specrew start` should launch or hand off to Squad and have Squad drive the full Spec Kit lifecycle for you:

- `speckit.specify`
- `speckit.clarify` for every newly generated spec before planning, or a recorded skip rationale only when resuming an already-clarified feature
- post-clarify team shaping and team presentation before implementation
- explicit human go-ahead before `speckit.implement`
- `specrew start` reuses the current terminal by default; pass `--new-window` only when you explicitly want Copilot opened in a separate shell
- `speckit.plan`
- `speckit.tasks`
- `speckit.implement`
- developer-facing implementation briefing plus no-gap review before closure

### Checking status after startup

Once a repo has feature and iteration artifacts, use the dashboard to answer
"where are we right now?":

```powershell
specrew where --no-color
specrew status --compact
```

> Direct-script equivalent (Option C, no module): replace `specrew` with
> `pwsh -NoProfile -File C:\Dev\Specrew\scripts\specrew.ps1` — same arguments.

For a sample output and section-by-section guide, see `docs/dashboard-guide.md`.

Add `.specrew\roadmap.yml` when you want roadmap progress and remaining-effort
projection to appear in the dashboard.

The human developer should mainly answer only the unresolved questions Squad cannot safely answer from repo context or existing artifacts. If you start without a request, Squad should inspect current work, continue any in-progress feature, or ask the next intake question and wait for your answer before invoking `speckit.specify`. In a new brownfield repo, Squad should first mine existing code, manifests, docs, and recent git history to seed the starting spec and propose concrete specialist additions when the current team lacks obvious stack/domain expertise. Review and closure now also operate under a **no-gap policy**: if Specrew finds a known gap across spec, implementation, tests, docs, or observability, it should fix it in the current iteration or explicitly defer it with your approval and recorded evidence before claiming the run is complete.

Specrew launches Copilot from the target project directory, reuses the current terminal by default, and auto-loads a compact bootstrap message via `-i` that points Copilot at `.specrew\last-start-prompt.md` and `.specrew\start-context.json`. Specrew defaults to **gate-respecting mode**: Squad stops at every lifecycle approval boundary (specify, clarify, plan, tasks, implement, review, retro) and waits for your explicit verdict before advancing. Tool calls between gates run without per-call prompts by default (`--allow-all`); pass `--prompt-approvals` to keep each tool call interactive. Copilot may still ask you to trust the project directory on first launch.

Two flags control independent concerns:

- `--allow-all` (default) vs `--prompt-approvals` — controls **tool-call approval**. Whether each Copilot tool invocation prompts you before running.
- `--autonomous` (opt-in) — controls **lifecycle-gate advancement**. When passed, Squad advances through approval gates without explicit verdict. Use only for unattended runs such as overnight execution where you have already authorized the entire lifecycle.

```powershell
# Default (gate-respecting): Squad stops at every approval boundary
specrew start "build a feature"

# Tool calls are still interactive
specrew start "build a feature" --prompt-approvals

# Unattended overnight run: Squad advances without explicit gate verdicts
specrew start "build a feature" --autonomous
```

### Resuming work later

Every later session also begins with `specrew start` — on the same machine or on a different one.

`specrew start` regenerates these transient runtime handoff files before launch:

- `.specrew/last-start-prompt.md`
- `.specrew/start-context.json`
- `.specrew/start-summary.md`

Those files do not travel with git. After you pull the tracked project state onto another machine, run `specrew start` there and Specrew will rebuild the local handoff files from the repository's tracked iteration state before launch.

Do not run `copilot` directly: it skips the runtime handoff refresh, so the launch contract is not regenerated for the new session.

If you are already inside a live session that was launched by `specrew start`, do not run it again in that same conversation. "Resuming" means starting a later session in a new terminal.

### Session-loaded file change detection

When you restart Copilot/Squad, `specrew start` automatically detects whether you've committed changes to **session-loaded files** (agent charters, Copilot instructions, or Spec Kit extension templates). If changes are detected, the auto-continue behavior pauses and prompts you to confirm or provide additional directives before the lifecycle resumes.

**Session-loaded paths checked**:

- `.github/agents/*`
- `.github/copilot-instructions.md`
- `extensions/specrew-speckit/squad-templates/coordinator/*`
- `.specify/extensions/specrew-speckit/squad-templates/coordinator/*`
- `.squad/agents/*/charter.md`

**Pause-and-confirm workflow**:

1. You commit changes to one or more session-loaded files (e.g., updating `.github/agents/squad.agent.md` to refine reviewer behavior).
2. You restart Copilot/Squad and run `specrew start`.
3. The regenerated `.specrew/last-start-prompt.md` includes a **PAUSE-AND-CONFIRM** message listing the changed files.
4. You can review the changes and provide directives (e.g., "Focus on reviewer escalation testing") before typing `CONFIRM` or a directive to continue.

**Example pause-and-confirm message**:

```
⚠️ Session-loaded files changed:
- .github/agents/squad.agent.md
- .squad/agents/reviewer/charter.md

Please review the changes above and provide any additional context needed.
Type CONFIRM or a directive to continue.
```

**Routine resumes (no changes)**: When no session-loaded files have changed, `specrew start` auto-continues immediately per the documented baseline behavior.

**Optional parameter for custom directives**: Power users can prepend a custom directive using the `-PostRestartDirective` parameter:

```powershell
specrew start -PostRestartDirective "Validate reviewer escalation contract before continuing."
```

The custom directive is prepended to the handoff prompt, followed by any pause-and-confirm or auto-continue logic.

**Baseline tracking**: `specrew start` records a baseline commit hash in `.specrew/last-start-prompt.md` YAML frontmatter (`baseline_commit_hash: <40-char SHA>`). The detector compares this baseline against HEAD to identify committed changes. **Uncommitted work-in-progress modifications do not trigger the pause**—only committed changes are detected.

**Practical examples**:

- **Scenario 1: Updating agent charters mid-iteration**
  1. You're implementing feature 011 and realize the reviewer's charter needs adjustment.
  2. You update `.squad/agents/reviewer/charter.md` and commit.
  3. You restart Copilot and run `specrew start`.
  4. Result: Pause-and-confirm message appears, showing `.squad/agents/reviewer/charter.md` changed. You can add directives like "Focus on charter alignment during review" before continuing.

- **Scenario 2: Routine resume with no changes**
  1. You close your terminal at the end of the day.
  2. The next day, you reopen the terminal and run `specrew start`.
  3. Result: Auto-continue behavior proceeds immediately because no session-loaded files changed overnight.

- **Scenario 3: Using `-PostRestartDirective` for explicit scope**
  1. You're resuming after a break and want to ensure the team focuses on a specific area.
  2. You run: `specrew start -PostRestartDirective "Continue iteration 002 closeout tasks only."`
  3. Result: Your directive is prepended to the handoff prompt, followed by auto-continue or pause-and-confirm logic.

Iteration artifact helpers still exist for direct/manual use:

```powershell
pwsh -File .\.specify\extensions\specrew-speckit\scripts\scaffold-iteration-plan.ps1 `
  -SpecPath .\specs\001-your-feature\spec.md `
  -IterationNumber 001

pwsh -File .\.specify\extensions\specrew-speckit\scripts\scaffold-iteration-artifacts.ps1 `
  -SpecDirectory .\specs\001-your-feature `
  -IterationNumber 001
```

Then continue the lifecycle with:

```powershell
pwsh -File .\.specify\extensions\specrew-speckit\scripts\scaffold-review-artifact.ps1 `
  -IterationDirectory .\specs\001-your-feature\iterations\001

pwsh -File .\.specify\extensions\specrew-speckit\scripts\scaffold-retro-artifact.ps1 `
  -IterationDirectory .\specs\001-your-feature\iterations\001
```

## Brownfield Quickstart (existing repo)

Current practical flow is additive and review-first.

1. Try a dry run to preview actions.

```powershell
specrew init -ProjectPath . -DryRun
```

If the directory is populated (has files beyond `.git` and hasn't been initialized with Specrew), add `-Force`:

```powershell
specrew init -ProjectPath . -DryRun -Force
```

1. Apply bootstrap with `-Force` on populated repos.

```powershell
specrew init -ProjectPath . -Force
```

1. Review merged/added files.

- `.specrew/*` governance files
- `.squad/team.md` baseline role merge
- `.squad/ceremonies.md` Specrew ceremony entries
- `.copilot/skills/specrew-*` skills
- Any custom members you maintain outside the Specrew-managed baseline block in `.squad/team.md`

1. After resolving any conflicts or making adjustments, re-run with `-Force` to complete the merge.

```powershell
specrew init -ProjectPath . -Force
```

Notes:

- Brownfield conflict handling is still a focus area for Iteration 2 (`FR-020`).
- Keep existing project governance under version control before first bootstrap run.
- `-Force` is optional for fresh git-only repos and skips interactive prompts when you want default selections automatically.
- For populated repos (contain files beyond `.git`), `-Force` is required for both the dry-run preview and the actual bootstrap apply step.

## Common Flags

- `-ProjectPath <path>`: target repo
- `-DryRun`: preview only
- `-Force`: non-interactive defaults
- `-Agents claude|codex|claude,codex|all`: enable optional delegated agents for review-heavy and problem-solving-heavy routing while Copilot remains the mandatory host runtime
- `-NoAgents`: disable optional delegated agents only; Copilot host runtime stays enabled
- `-SpecKitExtensionOnly`: deploy Spec Kit extension slice only

## Troubleshooting

### Verifying Spec Kit Installation

Current Spec Kit releases expose the version surface through `specify version`.
If you want to verify the CLI manually before re-running Specrew bootstrap, use:

```powershell
specify version
```

### Known Limitations

#### Dependency Validation vs. Bootstrap Completion

The `specrew-init.ps1` script performs two distinct steps:

1. **Dependency validation** (always runs): Detects whether Spec Kit and Squad versions are compatible (>= 0.8.4 and >= 0.9.1 respectively). This step always succeeds if the CLIs are installed and operational.
1. **Bootstrap initialization** (depends on CLI success): Preflights `specify init` in a disposable directory, repairs the common release-asset blocker when possible, then initializes `.specify/`, `.squad/`, and `.specrew/`.

Specrew bootstrap success means:

- ✅ Dependency validation passed (versions are acceptable)
- ✅ `.specrew/` governance artifacts are created
- ✅ `.specify/extensions/specrew-speckit/` extension is deployed

Specrew bootstrap is incomplete if `.specify/` is missing—the Spec Kit CLI did not complete successfully.

#### Blocker: Spec Kit CLI Release-Asset Mismatch

**Current Status**: Some `uv` environments can pick up a `specify-cli` build that reports a healthy version but fails `specify init` with:

```text
No matching release asset found for copilot
```

Specrew now preflights `specify init` before touching your project. If it sees this exact blocker and `uv` is available, it automatically repairs Spec Kit to the official GitHub release source and retries. If that repair still fails, bootstrap stops early with the exact repair command.

**Impact if repair cannot complete**: Without `.specify/`, you cannot run the downstream iteration scaffolding helpers (plan, artifacts, review, retro), so the complete greenfield bootstrap-to-iteration flow cannot finish.

**How to resolve this**:

1. Re-run Specrew bootstrap with `uv` available. Specrew should attempt the repair automatically:

```powershell
specrew init -ProjectPath . -Force
```

1. If Specrew reports that automatic repair failed, run the same official install manually:

```powershell
uv tool install --force specify-cli --from git+https://github.com/github/spec-kit.git@v0.8.4
```

1. Verify the repaired CLI:

```powershell
specify version
specrew init -ProjectPath . -Force
```

1. If the official GitHub release still cannot initialize, check the [Spec Kit repository](https://github.com/github/spec-kit) for release notes or open issues before retrying.

#### Environment-Specific Blocker: Spec Kit CLI Encoding (Windows Only)

In some Windows PowerShell environments, the Spec Kit CLI fails with a Unicode encoding error (`UnicodeEncodeError: 'charmap' codec can't encode characters`) when rendering its banner. This is a Spec Kit CLI issue, not a Specrew bootstrap issue, **but it blocks the entire greenfield-to-iteration flow** because `.specify/` will not be created.

**Impact**: Without `.specify/`, you cannot run the downstream iteration scaffolding helpers (plan, artifacts, review, retro), so the complete greenfield bootstrap-to-iteration flow cannot finish.

**How to resolve this**:

1. Try running in a different terminal:
   - Windows Terminal (has better UTF-8 support)
   - VS Code integrated terminal
   - PowerShell 7.4+ in a UTF-8 environment

2. If the issue persists, manually initialize `.specify/` from the terminal with UTF-8 support:

```powershell
specify init --here --ai copilot --script ps --ignore-agent-tools --force
```

1. After manually initializing `.specify/`, re-run bootstrap to complete the rest:

```powershell
specrew init -ProjectPath . -Force
```

1. Once `.specify/` exists, you can proceed with the iteration scaffolding steps (plan, artifacts, review, retro).

#### Other Limitations

- Squad team configuration (`.squad/`) requires `npm` and the Squad CLI. If Squad CLI is unavailable, `.squad/` will not be created, but `.specrew/` and `.specify/` can still be initialized.
- Downstream iteration artifact scaffolding requires `.specify/` to exist (see Greenfield Quickstart step 4 above).

## Next Step

Continue with [user-guide.md](user-guide.md) for the full iteration lifecycle (planning, execution, review/demo, retro, drift handling).
