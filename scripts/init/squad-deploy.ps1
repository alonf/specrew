# Squad-deploy helpers for specrew-init.ps1 (extracted via Proposal 108 Slice 7)
#
# Depends on: scripts/init/_utilities.ps1 (Invoke-NativeCommand*, Add-Action, Write-MissingUtf8File,
# Ensure-DirectoryExists); scripts/init/template-deploy.ps1 (Copy-TemplateTree).
#
# Functions:
#   - Test-SquadInitSupportsNonInteractive  probe "squad init --non-interactive"
#   - Get-SquadInitPlan                     pick "squad init" arg list per CLI capability
#   - Initialize-SquadFallbackScaffold      write the .squad/ 5-agent skeleton when Squad CLI is missing
#
# TRANSITION NOTE (Proposal 108 Slice 9 follow-up):
# This entire file is Squad-only — every function deploys to .squad/ paths and invokes the Squad CLI.
# When Slice 9 introduces the 5th contract function (Install-<Kind>CrewRuntime) on each host package,
# Initialize-SquadFallbackScaffold becomes the body of Install-CopilotCrewRuntime in
# hosts/copilot/handlers.ps1. Test-SquadInitSupportsNonInteractive + Get-SquadInitPlan become
# Copilot-specific helpers within that host package. After Slice 9, this file shrinks to a
# 3-function delegating shim or disappears entirely.

Set-StrictMode -Version Latest

function Test-SquadInitSupportsNonInteractive {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProbeRoot
    )

    $probeDirectory = Join-Path $ProbeRoot ('.specrew-squad-probe-{0}' -f [guid]::NewGuid().ToString('N'))

    New-Item -Path $probeDirectory -ItemType Directory -Force | Out-Null
    try {
        try {
            $probeResult = Invoke-NativeCommandForOutput -FilePath 'squad' -ArgumentList @('init', '--non-interactive') -WorkingDirectory $probeDirectory
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

