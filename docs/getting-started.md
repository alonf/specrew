# Specrew Getting Started

Practical quickstart for running Specrew in a new repo (greenfield) and adding it to an existing repo (brownfield).

## Prerequisites

- PowerShell (`pwsh`)
- Git
- `uv` (used to install Spec Kit if missing)
- `npm` (used to install Squad if missing)

## Before You Begin: Getting the Specrew Bootstrap Script

Specrew currently works as a **local repository clone**. This means you need to clone the Specrew repository to your machine to access the bootstrap script.

### Clone Specrew (one-time setup)

```powershell
# Clone Specrew to a location on your machine (e.g., C:\Dev\Specrew)
git clone https://github.com/alonf/specrew.git C:\Dev\Specrew
Set-Location C:\Dev\Specrew
```

The Specrew repository includes the `scripts/specrew-init.ps1` bootstrap script. This script is what you'll use to initialize your project.

### Future: Packaged Installation

In future versions, Specrew will be available as an npm or pip package, eliminating the need for a separate clone. For now, cloning is the supported approach.

## Bootstrap Script Help

Once you have cloned Specrew, you can view the bootstrap script help:

```powershell
pwsh -File C:\Dev\Specrew\scripts\specrew-init.ps1 -Help
```

Replace `C:\Dev\Specrew` with the path where you cloned Specrew.

## Greenfield Quickstart (recommended)

### Prerequisites for Full Greenfield Flow

The complete greenfield bootstrap-to-iteration flow requires:

- **Spec Kit CLI access via `uv`**: Specrew installs or repairs the official GitHub-hosted Spec Kit release when needed. The tested baseline is **Spec Kit 0.8.4**.
- **Squad CLI** (installed via `npm`): Must be available
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
pwsh -File C:\Dev\Specrew\scripts\specrew-init.ps1 -ProjectPath .
```

For a fresh git-only repo, `-Force` is **not** required. Add `-Force` only when you want non-interactive default selections or when the repo already contains files beyond `.git`.

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
pwsh -File C:\Dev\Specrew\scripts\specrew.ps1 team add security-analyst `
  --role "Security Analyst" `
  --charter "Review code for security vulnerabilities, ensure secure coding practices, validate authentication/authorization logic."

# List all team members (baseline + domain-specific)
pwsh -File C:\Dev\Specrew\scripts\specrew.ps1 team list

# Update an existing member's charter
pwsh -File C:\Dev\Specrew\scripts\specrew.ps1 team update security-analyst `
  --charter "Updated charter text..."

# Remove a domain-specific member
pwsh -File C:\Dev\Specrew\scripts\specrew.ps1 team remove security-analyst
```

Replace `C:\Dev\Specrew` with the actual path where you cloned the Specrew repository.

### Optional: Adding Specrew to PATH

For convenience, you can add the Specrew scripts directory to your PATH to use short commands like `specrew team list` instead of typing the full path each time.

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

1. (Only if `.specify/` exists) Start your first feature run.

If the bootstrap created `.specify/` successfully, the canonical next step is:

```powershell
pwsh -File C:\Dev\Specrew\scripts\specrew.ps1 start
```

Optionally, you can provide a short plain-language request up front:

```powershell
pwsh -File C:\Dev\Specrew\scripts\specrew.ps1 start "Build a REST API for user management"
```

`specrew start` should launch or hand off to Squad and have Squad drive the full Spec Kit lifecycle for you:

- `speckit.specify`
- `speckit.clarify` when needed
- `speckit.plan`
- `speckit.tasks`
- `speckit.implement`

The human developer should mainly answer only the unresolved questions Squad cannot safely answer from repo context or existing artifacts. If you start without a request, Squad should inspect current work, continue any in-progress feature, or ask whether you want a fix or a new feature.

To reduce Copilot CLI blocking on tool prompts, Specrew launches Copilot from the target project directory and defaults to `--allow-all`. Copilot may still ask you to trust the project directory on first launch. If you prefer Copilot's interactive approval prompts, use:

```powershell
pwsh -File C:\Dev\Specrew\scripts\specrew.ps1 start --prompt-approvals
```

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
pwsh -File C:\Dev\Specrew\scripts\specrew-init.ps1 -ProjectPath . -DryRun
```

If the directory is populated (has files beyond `.git` and hasn't been initialized with Specrew), add `-Force`:

```powershell
pwsh -File C:\Dev\Specrew\scripts\specrew-init.ps1 -ProjectPath . -DryRun -Force
```

1. Apply bootstrap with `-Force` on populated repos.

```powershell
pwsh -File C:\Dev\Specrew\scripts\specrew-init.ps1 -ProjectPath . -Force
```

1. Review merged/added files.

- `.specrew/*` governance files
- `.squad/team.md` baseline role merge
- `.squad/ceremonies.md` Specrew ceremony entries
- `.copilot/skills/specrew-*` skills
- Any custom members you maintain outside the Specrew-managed baseline block in `.squad/team.md`

1. After resolving any conflicts or making adjustments, re-run with `-Force` to complete the merge.

```powershell
pwsh -File C:\Dev\Specrew\scripts\specrew-init.ps1 -ProjectPath . -Force
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
- `-Agents copilot|all|copilot,claude|copilot,codex`
- `-NoAgents`: disable all agents
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
pwsh -File C:\Dev\Specrew\scripts\specrew-init.ps1 -ProjectPath . -Force
```

1. If Specrew reports that automatic repair failed, run the same official install manually:

```powershell
uv tool install --force specify-cli --from git+https://github.com/github/spec-kit.git@v0.8.4
```

1. Verify the repaired CLI:

```powershell
specify version
pwsh -File C:\Dev\Specrew\scripts\specrew-init.ps1 -ProjectPath . -Force
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

3. After manually initializing `.specify/`, re-run bootstrap to complete the rest:

```powershell
pwsh -File C:\Dev\Specrew\scripts\specrew-init.ps1 -ProjectPath . -Force
```

4. Once `.specify/` exists, you can proceed with the iteration scaffolding steps (plan, artifacts, review, retro).

#### Other Limitations

- Squad team configuration (`.squad/`) requires `npm` and the Squad CLI. If Squad CLI is unavailable, `.squad/` will not be created, but `.specrew/` and `.specify/` can still be initialized.
- Downstream iteration artifact scaffolding requires `.specify/` to exist (see Greenfield Quickstart step 4 above).

## Next Step

Continue with [user-guide.md](user-guide.md) for the full iteration lifecycle (planning, execution, review/demo, retro, drift handling).
