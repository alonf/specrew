[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red }

function Invoke-TestScript {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList
    )

    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgumentList 2>&1)
    return @{
        Output   = @($output | ForEach-Object { [string]$_ })
        ExitCode = $LASTEXITCODE
    }
}

function Invoke-InteractiveStart {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string[]]$Inputs
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = 'pwsh'
    $null = $startInfo.ArgumentList.Add('-NoProfile')
    $null = $startInfo.ArgumentList.Add('-ExecutionPolicy')
    $null = $startInfo.ArgumentList.Add('Bypass')
    $null = $startInfo.ArgumentList.Add('-File')
    $null = $startInfo.ArgumentList.Add($ScriptPath)
    $null = $startInfo.ArgumentList.Add('-ProjectPath')
    $null = $startInfo.ArgumentList.Add($ProjectRoot)
    $null = $startInfo.ArgumentList.Add('-NoLaunch')
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    $process = [System.Diagnostics.Process]::Start($startInfo)
    foreach ($inputValue in $Inputs) {
        Start-Sleep -Milliseconds 150
        $process.StandardInput.WriteLine($inputValue)
    }
    $process.StandardInput.Close()
    $process.WaitForExit()

    return @{
        ExitCode = $process.ExitCode
        Output   = $process.StandardOutput.ReadToEnd() + $process.StandardError.ReadToEnd()
    }
}

function New-MinimalProject {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $null = New-Item -ItemType Directory -Path $ProjectRoot -Force
    $null = & git -C $ProjectRoot init --quiet 2>&1
    $null = & git -C $ProjectRoot config user.email 'test@specrew.local' 2>&1
    $null = & git -C $ProjectRoot config user.name 'Test User' 2>&1

    foreach ($relativeDirectory in @('.specrew', '.specify', '.squad', '.github\agents', 'specs\022-hotfix-schema-tests\iterations\001')) {
        $null = New-Item -ItemType Directory -Path (Join-Path $ProjectRoot $relativeDirectory) -Force
    }

    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specrew\config.yml'), "project_name: sample`nspecrew_version: `"0.0.0`"`nbootstrap_date: `"2026-01-01`"`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specify\feature.json'), "{`n  `"feature_directory`": `"specs/022-hotfix-schema-tests`"`n}", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\team.md'), "# Team`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\config.json'), "{}`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\decisions.md'), "# Decisions`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.github\agents\squad.agent.md'), "# Squad Agent`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot 'specs\022-hotfix-schema-tests\spec.md'), "# Spec`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot 'README.md'), "# Test Repo`n", [System.Text.UTF8Encoding]::new($false))

    $null = & git -C $ProjectRoot add -A 2>&1
    $null = & git -C $ProjectRoot commit -m 'Seed project' --quiet 2>&1
    $null = & git -C $ProjectRoot branch -M main 2>&1
    $null = & git -C $ProjectRoot checkout -b 022-hotfix-schema-tests 2>&1
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$syncScript = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1'
$startScript = Join-Path $repoRoot 'scripts\specrew-start.ps1'

$scratchRoot = Join-Path $repoRoot '.scratch\start-recovery-flow'
if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $scratchRoot -Force

function New-StaleProject {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    New-MinimalProject -ProjectRoot $ProjectRoot
    $syncResult = Invoke-TestScript -ScriptPath $syncScript -ArgumentList @('-ProjectPath', $ProjectRoot, '-BoundaryType', 'plan', '-FeatureRef', '022-hotfix-schema-tests', '-IterationNumber', '001')
    if ($syncResult.ExitCode -ne 0) {
        throw ("Failed to seed plan boundary state:`n{0}" -f ($syncResult.Output -join [Environment]::NewLine))
    }

    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\decisions.md'), "# Decisions`n", [System.Text.UTF8Encoding]::new($false))
}

# Interactive stale-state flow with invalid input visibility
$interactiveProject = Join-Path $scratchRoot 'interactive'
New-StaleProject -ProjectRoot $interactiveProject
$interactiveResult = Invoke-InteractiveStart -ScriptPath $startScript -ProjectRoot $interactiveProject -Inputs @('z', 'A')
if ($interactiveResult.ExitCode -ne 0) {
    Write-Fail ("Interactive recovery flow should not dead-end:`n{0}" -f $interactiveResult.Output)
    exit 1
}

foreach ($pattern in @('Stale state detected', 'A\) re-anchor to the correct feature', 'B\) create a new feature', 'C\) exit and manually fix state', 'WARN: Invalid recovery choice', 'Prepared Specrew start context')) {
    if ($interactiveResult.Output -notmatch $pattern) {
        Write-Fail "Interactive recovery flow is missing expected output: $pattern"
        exit 1
    }
}

$interactiveContext = Get-Content -LiteralPath (Join-Path $interactiveProject '.specrew\start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12
if ($interactiveContext.recovery_session.entry_mode -ne 'detected-stale-state' -or $interactiveContext.recovery_session.selected_choice -ne 'A' -or $interactiveContext.recovery_session.bypass_gate -or $interactiveContext.recovery_session.approval_mode_changed) {
    Write-Fail 'Interactive recovery did not persist the expected recovery_session contract.'
    exit 1
}

$interactivePrompt = Get-Content -LiteralPath (Join-Path $interactiveProject '.specrew\last-start-prompt.md') -Raw -Encoding UTF8
if ($interactivePrompt -notmatch '## Recovery Mode' -or $interactivePrompt -notmatch 'Recovery choice A selected') {
    Write-Fail 'Interactive recovery prompt did not persist recovery guidance.'
    exit 1
}

Write-Pass 'Interactive stale-state recovery accepts invalid then valid input and persists recovery diagnostics'

# Explicit --recover bypass
$recoverProject = Join-Path $scratchRoot 'recover-flag'
New-StaleProject -ProjectRoot $recoverProject
$recoverResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $recoverProject, '-NoLaunch', '-Recover')
if ($recoverResult.ExitCode -ne 0) {
    Write-Fail ("--recover should bypass the stale-state gate:`n{0}" -f ($recoverResult.Output -join [Environment]::NewLine))
    exit 1
}

$recoverContext = Get-Content -LiteralPath (Join-Path $recoverProject '.specrew\start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12
if ($recoverContext.recovery_session.entry_mode -ne 'explicit-recover-flag' -or -not $recoverContext.recovery_session.bypass_gate -or $recoverContext.recovery_session.approval_mode_changed) {
    Write-Fail '--recover did not persist the expected bypass recovery contract.'
    exit 1
}

if (($recoverResult.Output -join [Environment]::NewLine) -notmatch 'Prepared Specrew start context') {
    Write-Fail '--recover did not continue through start artifact preparation.'
    exit 1
}

Write-Pass '--recover bypasses stale-state blocking without changing approval behavior'
exit 0
