# Post-bootstrap output helpers for specrew-init.ps1 (extracted via Proposal 108 Slice 8)
#
# Depends on: scripts/init/_utilities.ps1 (Get-SpecrewExecutionLayout)
#
# Functions:
#   - Write-PostBootstrapGuidance  130-line bootstrap-success splash (greeting, usage flow, next steps,
#                                  slash-command surface, team extension instructions, PATH guidance)
#   - Write-BootstrapSummary       final action-table summary (single-line outcomes per step)
#
# Host-coupling notes (Phase D / Slice 9+ follow-up):
# Write-PostBootstrapGuidance currently has Squad-only strings (".squad/team.md", "Run squad to start.").
# These stay Squad-specific because the post-bootstrap message is Copilot-host-default. When non-Copilot
# Crew runtimes ship (Slice 9 / Proposal 024 Slice 3), this function gains a host-aware variant or is
# split into per-host messages dispatched via the registry.

Set-StrictMode -Version Latest

function Write-PostBootstrapGuidance {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    $baselineRoles = 'Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator'
    $teamPath = Join-Path $ProjectPath '.squad\team.md'
    # Use the execution layout's scripts dir (one level below RootPath), NOT $PSScriptRoot.
    # After Slice 8, $PSScriptRoot here is scripts/init/, but the PATH guidance must point to
    # scripts/ (where specrew.ps1 lives). Resolve from the layout to stay location-independent.
    $executionLayout = Get-SpecrewExecutionLayout
    $isModuleContext = ($executionLayout.Mode -eq 'module')
    $specrewScriptsPath = Join-Path $executionLayout.RootPath 'scripts'

    Write-Host ''
    Write-Host '         ╱─────────────────╲' -ForegroundColor Cyan
    Write-Host '        ╱  ●━━●━━●          ╲' -ForegroundColor Cyan
    Write-Host '       │       ╲             │' -ForegroundColor Cyan
    Write-Host '       │   ●━━●━━●           │' -ForegroundColor Blue
    Write-Host '       │        ╲            │' -ForegroundColor Blue
    Write-Host '        ╲  ●━━●━━●          ╱' -ForegroundColor Blue
    Write-Host '         ╲─────────────────╱' -ForegroundColor Blue
    Write-Host ''
    Write-Host '         S  P  E  C  R  E  W' -ForegroundColor White
    Write-Host '    ─── GOVERNED AGENTIC SDLC ───' -ForegroundColor DarkGray
    Write-Host ''
    Write-Host '         Bootstrap Complete' -ForegroundColor Green
    Write-Host ''
    Write-Host ("Baseline Specrew crew installed: {0}." -f $baselineRoles) -ForegroundColor White
    Write-Host ''
    Write-Host '=== Usage Flow ===' -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'Baseline crew → specrew start → Squad drives specify → clarify for new specs (or recorded skip on resumed clarified work) → plan → tasks → implement → review → retro' -ForegroundColor Yellow
    Write-Host ''
    Write-Host '=== Next Steps ===' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '1. Start spec authoring (Spec Kit workflows):' -ForegroundColor Yellow
    Write-Host '   - Run specrew start from the project root (optionally add a short feature request)' -ForegroundColor White
    Write-Host '   - Specrew launches the selected host CLI (default: Copilot; `--host claude` or `--host codex` available since v0.26.0) from the project directory in the current terminal by default, stays out of autopilot until intake is grounded, and supports --new-window or --prompt-approvals when you want them' -ForegroundColor White
    Write-Host '   - Specrew will launch or hand off to the Squad agent with lifecycle context' -ForegroundColor White
    Write-Host '   - Squad should drive specify -> clarify -> plan -> tasks -> implement (skip clarify only for resumed clarified work with a recorded rationale)' -ForegroundColor White
    Write-Host ''
    Write-Host '2. Resuming work later:' -ForegroundColor Yellow
    Write-Host '   - Every later session also starts with specrew start from the project root' -ForegroundColor White
    Write-Host '   - specrew start regenerates the runtime handoff before launch' -ForegroundColor White
    Write-Host '   - Do not run the host CLI directly (e.g., `copilot ...` / `claude ...` / `codex ...`); going around `specrew start` skips the bootstrap refresh and leaves the launch contract stale' -ForegroundColor White
    Write-Host ''
    Write-Host '3. Run the iteration lifecycle:' -ForegroundColor Yellow
    Write-Host '   - Materialize iteration artifacts under specs/<feature>/iterations/<NNN>/' -ForegroundColor White
    Write-Host '   - Keep plan.md, state.md, drift-log.md, review.md, and retro.md current by phase' -ForegroundColor White
    Write-Host '   - Run validate-governance.ps1 before phase transitions' -ForegroundColor White
    Write-Host ''
    Write-Host 'Slash-command surface provisioned:' -ForegroundColor Green
    Write-Host '   - /specrew-where, /specrew-status, /specrew-update, /specrew-team, /specrew-review, /specrew-help, /specrew-version' -ForegroundColor White
    Write-Host '   - Deployed to .claude/skills/, .github/skills/, and .agents/skills/ with identical SKILL.md content' -ForegroundColor White
    Write-Host '   - If host-native /specrew- discovery is unavailable, use /specrew-help as the catalog fallback' -ForegroundColor White
    Write-Host ''
    Write-Host '4. (Optional) Add domain-specific team members:' -ForegroundColor Yellow
    Write-Host '   Add extra Squad members after bootstrap with Security Analyst, UX Designer,' -ForegroundColor White
    Write-Host '   DBA, or other specialists using Specrew team management commands:' -ForegroundColor White
    Write-Host ''

    if ($isModuleContext) {
        Write-Host '  specrew team add <member-name> --role <role> --charter "<charter-text>"' -ForegroundColor White
        Write-Host '  specrew start' -ForegroundColor White
        Write-Host '  specrew team list' -ForegroundColor White
        Write-Host '  specrew team update <member-name> --charter "<new-charter>"' -ForegroundColor White
        Write-Host '  specrew team remove <member-name>' -ForegroundColor White
    } else {
        Write-Host '  pwsh -File <specrew-repo>\scripts\specrew.ps1 team add <member-name> --role <role> --charter "<charter-text>"' -ForegroundColor White
        Write-Host '  pwsh -File <specrew-repo>\scripts\specrew.ps1 start' -ForegroundColor White
        Write-Host '  pwsh -File <specrew-repo>\scripts\specrew.ps1 team list' -ForegroundColor White
        Write-Host '  pwsh -File <specrew-repo>\scripts\specrew.ps1 team update <member-name> --charter "<new-charter>"' -ForegroundColor White
        Write-Host '  pwsh -File <specrew-repo>\scripts\specrew.ps1 team remove <member-name>' -ForegroundColor White
    }

    Write-Host ''
    Write-Host '   Keep the Specrew-managed baseline block intact in .squad/team.md.' -ForegroundColor Yellow
    Write-Host ''

    if (-not $isModuleContext) {
        Write-Host 'Replace <specrew-repo> with the actual path where you cloned Specrew.' -ForegroundColor Yellow
        Write-Host ''
        Write-Host '=== Optional: Add Specrew to PATH for Convenience ===' -ForegroundColor Cyan
        Write-Host ''
        Write-Host 'To use the short form (e.g., "specrew team list") instead of full paths,' -ForegroundColor White
        Write-Host 'you can add the scripts directory to your PATH.' -ForegroundColor White
        Write-Host ''

        if ($IsWindows) {
            Write-Host 'OPTION 1: Current Session Only (Windows)' -ForegroundColor Yellow
            Write-Host 'Run this command in your current PowerShell session:' -ForegroundColor White
            Write-Host ''
            Write-Host ('  $env:PATH = "$env:PATH;{0}"' -f $specrewScriptsPath) -ForegroundColor Green
            Write-Host ''
            Write-Host '(This only affects the current shell and is lost when you close it.)' -ForegroundColor DarkGray
            Write-Host ''
            Write-Host 'OPTION 2: Persistent (All Future Sessions, Windows)' -ForegroundColor Yellow
            Write-Host 'To make this permanent for your user account, run:' -ForegroundColor White
            Write-Host ''
            Write-Host ('  $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")') -ForegroundColor Green
            Write-Host ('  $pathEntries = $currentPath -split "";""') -ForegroundColor Green
            Write-Host ('  if ($pathEntries -notcontains ""{0}"") {{' -f $specrewScriptsPath) -ForegroundColor Green
            Write-Host ('      [Environment]::SetEnvironmentVariable("PATH", "$currentPath;{0}", "User")' -f $specrewScriptsPath) -ForegroundColor Green
            Write-Host ('      Write-Host "Added Specrew scripts to user PATH. Restart your shell to apply." -ForegroundColor Green') -ForegroundColor Green
            Write-Host ('  }') -ForegroundColor Green
            Write-Host ''
            Write-Host '(This adds the path to your user-level environment and persists across sessions.' -ForegroundColor DarkGray
            Write-Host ' Restart your shell after running this command.)' -ForegroundColor DarkGray
        } elseif ($IsLinux -or $IsMacOS) {
            $shellProfile = if ($IsMacOS) { '~/.zshrc or ~/.bash_profile' } else { '~/.bashrc or ~/.profile' }
            Write-Host 'Adding Specrew to PATH (Linux/macOS)' -ForegroundColor Yellow
            Write-Host ('Add this line to your shell profile ({0}):' -f $shellProfile) -ForegroundColor White
            Write-Host ''
            Write-Host ('  export PATH="$PATH:{0}"' -f $specrewScriptsPath) -ForegroundColor Green
            Write-Host ''
            Write-Host 'Then reload your shell:' -ForegroundColor White
            Write-Host ''
            Write-Host ('  source {0}' -f $shellProfile) -ForegroundColor Green
            Write-Host ''
            Write-Host 'Or restart your terminal.' -ForegroundColor DarkGray
        }

        Write-Host ''
    }

    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'Documentation:' -ForegroundColor White
    Write-Host '  - Getting Started: docs/getting-started.md' -ForegroundColor DarkGray
    Write-Host '  - User Guide: docs/user-guide.md' -ForegroundColor DarkGray
    Write-Host ''
}

function Write-BootstrapSummary {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions,

        [Parameter(Mandatory = $true)]
        [bool]$DryRunMode,

        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [bool]$ShowGuidance
    )

    Write-Host ''
    Write-Host 'Bootstrap summary' -ForegroundColor Green
    $Actions | Format-Table -AutoSize

    if ($DryRunMode) {
        Write-Host 'Dry run complete. No files were changed.' -ForegroundColor Yellow
        return
    }

    Write-Host ("Bootstrap completed for {0}." -f $ProjectPath) -ForegroundColor Green
    if ($ShowGuidance) {
        Write-PostBootstrapGuidance -ProjectPath $ProjectPath
    }
}

