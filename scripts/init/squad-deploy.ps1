# Squad-deploy helpers for specrew-init.ps1 (extracted via Proposal 108 Slice 7)
#
# Depends on: scripts/init/_utilities.ps1 (Invoke-NativeCommand*, Add-Action, Write-MissingUtf8File,
# Ensure-DirectoryExists); scripts/init/template-deploy.ps1 (Copy-TemplateTree).
#
# Functions:
#   - Test-SquadInitSupportsNonInteractive  probe "squad init --non-interactive"
#   - Get-SquadInitPlan                     pick "squad init" arg list per CLI capability
#   - Invoke-SquadInitInProject             run "squad init" confined to the project folder (B4F-122)
#   - Initialize-SquadFallbackScaffold      write the .squad/ 5-agent skeleton when Squad CLI is missing
#
# POST-SLICE-9 SCOPE NOTE:
# Slice 9 introduced Install-CopilotCrewRuntime in hosts/copilot/handlers.ps1 with a narrow
# scope: translate canonical .specrew/team/agents/<role>.md → .squad/agents/<role>/charter.md.
# Initialize-SquadFallbackScaffold in this file STAYS as the source-of-truth for the broader
# .squad/ skeleton (config.json, team.md, decisions.md, ceremonies.md) — that scaffold lives
# OUTSIDE Install-CopilotCrewRuntime's per-charter scope and is still invoked from specrew-init.ps1.
# Test-SquadInitSupportsNonInteractive + Get-SquadInitPlan probe the Squad CLI itself and remain
# init-time concerns, not per-launch concerns.

Set-StrictMode -Version Latest

function Test-SquadInitSupportsNonInteractive {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProbeRoot,

        [ValidateRange(1, 7200)]
        [int]$TimeoutSeconds = 30,

        [string]$SquadCommand = 'squad'
    )

    $probeDirectory = Join-Path $ProbeRoot ('.specrew-squad-probe-{0}' -f [guid]::NewGuid().ToString('N'))

    New-Item -Path $probeDirectory -ItemType Directory -Force | Out-Null
    try {
        try {
            # B4F-122: the probe folder sits inside the install root, which may itself be inside a repository; fence Git
            # discovery at the install root so the probe's squad.agent.md lands in the probe folder and is removed with it.
            $probeResult = Invoke-NativeCommandWithClosedInput -FilePath $SquadCommand -ArgumentList @('init', '--non-interactive') -WorkingDirectory $probeDirectory -TimeoutSeconds $TimeoutSeconds -GitCeilingDirectory $ProbeRoot
        }
        catch [System.TimeoutException] {
            # A timed-out capability probe is an operational failure, not evidence that the option is unsupported.
            # Preserve the fatal signal so init cannot silently continue through the compatibility scaffold.
            throw
        }
        catch {
            return $false
        }

        if ($probeResult.ExitCode -ne 0) {
            return $false
        }

        return (Test-Path -LiteralPath (Join-Path $probeDirectory '.squad'))
    }
    finally {
        if (Test-Path -LiteralPath $probeDirectory) {
            Remove-Item -LiteralPath $probeDirectory -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-SquadInitPlan {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProbeRoot
    )

    $supportsNonInteractive = Test-SquadInitSupportsNonInteractive -ProbeRoot $ProbeRoot

    $arguments = @('init')
    if ($supportsNonInteractive) {
        $arguments += '--non-interactive'
    }

    return [pscustomobject]@{
        SupportsNonInteractive = $supportsNonInteractive
        ArgumentList           = $arguments
    }
}

function Invoke-SquadInitInProject {
    # B4F-122: `squad init` writes .github/agents/squad.agent.md at the Git top-level it discovers, which for a folder
    # inside another repository's work tree is that repository's root. Fencing Git discovery at the project's parent keeps
    # every write inside the project folder; a project that is its own repository still finds its own .git.
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList,

        [ValidateRange(1, 7200)]
        [int]$TimeoutSeconds = 120,

        [string]$SquadCommand = 'squad'
    )

    $resolvedProject = [System.IO.Path]::GetFullPath($ProjectPath)
    $ceiling = Split-Path -Parent $resolvedProject.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    return Invoke-NativeCommandWithClosedInput -FilePath $SquadCommand -ArgumentList $ArgumentList -WorkingDirectory $resolvedProject -TimeoutSeconds $TimeoutSeconds -GitCeilingDirectory $ceiling
}

function Initialize-SquadFallbackScaffold {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [switch]$PreviewOnly
    )

    $baselineAgentDirectories = @('spec-steward', 'planner', 'implementer', 'reviewer', 'retro-facilitator')
    $directories = @(
        (Join-Path $ProjectPath '.squad'),
        (Join-Path $ProjectPath '.squad\agents'),
        (Join-Path $ProjectPath '.squad\identity'),
        (Join-Path $ProjectPath '.squad\templates')
    ) + @(
        foreach ($agentDirectory in $baselineAgentDirectories) {
            Join-Path $ProjectPath ('.squad\agents\{0}' -f $agentDirectory)
        }
    )

    foreach ($directory in $directories) {
        Ensure-DirectoryExists -Path $directory -PreviewOnly:$PreviewOnly
    }

    $files = @(
        @{
            Path    = Join-Path $ProjectPath '.squad\.first-run'
            Content = ''
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\config.json'
            Content = @'
{
  "version": 1
}
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\team.md'
            Content = @'
# Squad Team
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\ceremonies.md'
            Content = @'
# Ceremonies
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\decisions.md'
            Content = @'
# Decisions
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\routing.md'
            Content = @'
# Routing
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\identity\now.md'
            Content = @'
---
---

# What We''re Focused On
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\identity\wisdom.md'
            Content = @'
# Team Wisdom
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\agents\spec-steward\charter.md'
            Content = @'
# Spec Steward
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\agents\spec-steward\history.md'
            Content = @'
# Spec Steward History
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\agents\planner\charter.md'
            Content = @'
# Planner
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\agents\planner\history.md'
            Content = @'
# Planner History
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\agents\implementer\charter.md'
            Content = @'
# Implementer
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\agents\implementer\history.md'
            Content = @'
# Implementer History
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\agents\reviewer\charter.md'
            Content = @'
# Reviewer
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\agents\reviewer\history.md'
            Content = @'
# Reviewer History
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\agents\retro-facilitator\charter.md'
            Content = @'
# Retro Facilitator
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\agents\retro-facilitator\history.md'
            Content = @'
# Retro Facilitator History
'@
        }
    )

    foreach ($file in $files) {
        Write-MissingUtf8File -Path $file.Path -Content $file.Content -PreviewOnly:$PreviewOnly
    }
}

