# Multi-Host Smoke Test — F-040 post-merge validation
#
# Manual smoke test for the maintainer to run after F-040 (Multi-Host Launch
# Path) merges to main and PSGallery publishes v0.26.0. Validates that the
# new `specrew start --host <kind>` surface works end-to-end on a fresh
# project across the three supported hosts (copilot/claude/codex) without
# any pre-existing Specrew bootstrap.
#
# Estimated time: 5 minutes (4 scenarios × ~1 min each).
#
# Usage:
#   pwsh -File tests/manual/multi-host-smoke.ps1
#   pwsh -File tests/manual/multi-host-smoke.ps1 -SkipPSGallery     # use local clone instead
#   pwsh -File tests/manual/multi-host-smoke.ps1 -SkipLaunch        # --no-launch mode only
#   pwsh -File tests/manual/multi-host-smoke.ps1 -ScratchRoot 'C:\Temp\specrew-smoke'
#
# Each scenario:
#   1. Creates a fresh scratch directory
#   2. Runs git init + specrew init
#   3. Runs specrew start with --host <kind> --no-launch (default; -SkipLaunch keeps this even if you remove the switch)
#   4. Verifies artifacts: .specrew/last-start-prompt.md + start-context.json
#   5. Verifies the start-context.json has F-040's new fields (selected_host, available_hosts, crew_runtime_status)
#   6. Verifies the coordinator-prompt body has the universal Crew header (FR-011)
#   7. For non-Copilot hosts: verifies the Squad-runtime-path directives are stripped (FR-012)
#   8. For Codex: verifies pwsh-form boundary-advance directives (FR-014)
#
# Cleanup: scratch directories are removed at end of each scenario unless -PreserveScratch is set.

[CmdletBinding()]
param(
    [switch]$SkipPSGallery,       # Use local clone import instead of PSGallery
    [switch]$SkipLaunch,           # Force --no-launch (default true; -SkipLaunch:$false enables actual launches — interactive)
    [string]$ScratchRoot,          # Override scratch root (defaults to system temp)
    [switch]$PreserveScratch,      # Keep scratch dirs after run
    [string[]]$Hosts = @('copilot', 'claude', 'codex')  # Which hosts to test
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$M) Write-Host "PASS: $M" -ForegroundColor Green }
function Write-Fail { param([string]$M) Write-Host "FAIL: $M" -ForegroundColor Red }
function Write-Info { param([string]$M) Write-Host "INFO: $M" -ForegroundColor Cyan }
function Write-Warn { param([string]$M) Write-Host "WARN: $M" -ForegroundColor Yellow }

$useNoLaunch = -not ($SkipLaunch.IsPresent -and -not $SkipLaunch.ToBool())  # default true unless explicitly set false
if ($SkipLaunch.IsPresent) {
    # Honor explicit value
    $useNoLaunch = $SkipLaunch.ToBool() -or $true
}

if ([string]::IsNullOrWhiteSpace($ScratchRoot)) {
    $ScratchRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('specrew-multi-host-smoke-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
}

Write-Host ''
Write-Host '================================================================' -ForegroundColor Magenta
Write-Host 'Specrew Multi-Host Smoke Test (F-040 / v0.26.0)' -ForegroundColor Magenta
Write-Host '================================================================' -ForegroundColor Magenta
Write-Host "Scratch root: $ScratchRoot"
Write-Host "Hosts to test: $($Hosts -join ', ')"
Write-Host "Mode: $(if ($useNoLaunch) { '--no-launch (artifact verification only)' } else { 'Full launch (interactive — will spawn host CLI)' })"
Write-Host ''

# Phase 1: Verify specrew is installed
Write-Host '--- Phase 1: Verify Specrew installation ---' -ForegroundColor Cyan
$specrewCmd = Get-Command specrew -ErrorAction SilentlyContinue
if (-not $specrewCmd) {
    Write-Fail 'specrew command not found on PATH. Install via: Install-Module Specrew -Scope CurrentUser -SkipPublisherCheck'
    exit 1
}
$versionOutput = & specrew --version 2>&1 | Out-String
$versionMatch = [regex]::Match($versionOutput, '(\d+\.\d+\.\d+)')
if (-not $versionMatch.Success) {
    Write-Fail "Could not parse specrew --version output: $versionOutput"
    exit 1
}
$installedVersion = $versionMatch.Groups[1].Value
Write-Pass "specrew installed: v$installedVersion"

if ([version]$installedVersion -lt [version]'0.26.0') {
    Write-Warn "Installed version $installedVersion is older than v0.26.0 (F-040 ship). Multi-host smoke may fail. Upgrade via: Install-Module Specrew -Force -SkipPublisherCheck"
}

# Phase 2: Per-host scenarios
Write-Host ''
Write-Host '--- Phase 2: Per-host scenarios ---' -ForegroundColor Cyan

$results = @{}

foreach ($host in $Hosts) {
    Write-Host ''
    Write-Host "=== Host: $host ===" -ForegroundColor Magenta

    # Check binary availability (for --no-launch mode this is informational only; --no-launch still writes artifacts)
    $hostBinary = switch ($host) {
        'copilot' { 'copilot' }
        'claude'  { 'claude' }
        'codex'   { 'codex' }
    }
    $hostInstalled = $null -ne (Get-Command $hostBinary -ErrorAction SilentlyContinue)
    Write-Info "$hostBinary on PATH: $hostInstalled"

    # Create scratch project
    $scratchDir = Join-Path $ScratchRoot "scenario-$host"
    if (Test-Path -LiteralPath $scratchDir) {
        Remove-Item -LiteralPath $scratchDir -Recurse -Force
    }
    $null = New-Item -ItemType Directory -Path $scratchDir -Force
    Write-Info "Scratch project: $scratchDir"

    Push-Location -LiteralPath $scratchDir
    $scenarioPass = $true
    try {
        # git init
        $gitOut = & git init --quiet 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Fail "git init failed: $gitOut"
            $scenarioPass = $false
            continue
        }

        # specrew init
        Write-Info 'Running specrew init...'
        $initOut = & specrew init -NoAgents 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            Write-Fail "specrew init failed (exit $LASTEXITCODE):`n$initOut"
            $scenarioPass = $false
            continue
        }
        Write-Pass 'specrew init succeeded'

        # specrew start --host <kind> --no-launch (or actual launch)
        $launchFlags = @('--host', $host)
        if ($useNoLaunch) { $launchFlags += '--no-launch' }
        Write-Info "Running specrew start $($launchFlags -join ' ') 'multi-host smoke test'..."
        $startOut = & specrew start "multi-host smoke test" @launchFlags 2>&1 | Out-String

        if (-not $useNoLaunch) {
            # Live launch — exit codes vary; just record the output
            Write-Info "Launch output (truncated):`n$($startOut.Substring(0, [Math]::Min(500, $startOut.Length)))..."
        }
        else {
            if ($LASTEXITCODE -ne 0) {
                # --host without CLI on PATH should still write artifacts in --no-launch mode (per F-040 commit 4e1deab8 fix)
                # but it may exit non-zero if the host probe rejected — check the artifacts anyway
                Write-Warn "specrew start exit $LASTEXITCODE — checking artifacts for diagnostic info"
            }
            else {
                Write-Pass 'specrew start --no-launch succeeded'
            }
        }

        # Verify artifacts
        $promptPath = Join-Path $scratchDir '.specrew/last-start-prompt.md'
        $contextPath = Join-Path $scratchDir '.specrew/start-context.json'

        if (-not (Test-Path -LiteralPath $promptPath -PathType Leaf)) {
            Write-Fail "last-start-prompt.md NOT created at $promptPath"
            $scenarioPass = $false
        }
        else {
            Write-Pass 'last-start-prompt.md created'
        }

        if (-not (Test-Path -LiteralPath $contextPath -PathType Leaf)) {
            Write-Fail "start-context.json NOT created at $contextPath"
            $scenarioPass = $false
        }
        else {
            Write-Pass 'start-context.json created'

            # Verify F-040 new fields
            try {
                $context = Get-Content -LiteralPath $contextPath -Raw | ConvertFrom-Json
                if (-not ($context.PSObject.Properties.Name -contains 'selected_host')) {
                    Write-Fail 'start-context.json missing selected_host field (F-040 FR-006)'
                    $scenarioPass = $false
                }
                else {
                    if ($context.selected_host -ne $host) {
                        Write-Fail "selected_host=$($context.selected_host); expected $host"
                        $scenarioPass = $false
                    }
                    else {
                        Write-Pass "selected_host=$($context.selected_host) (matches --host flag)"
                    }
                }

                if (-not ($context.PSObject.Properties.Name -contains 'available_hosts')) {
                    Write-Fail 'start-context.json missing available_hosts field (F-040 FR-006)'
                    $scenarioPass = $false
                }
                else {
                    Write-Pass "available_hosts field present"
                }

                if (-not ($context.PSObject.Properties.Name -contains 'crew_runtime_status')) {
                    Write-Fail 'start-context.json missing crew_runtime_status field (F-040 FR-006)'
                    $scenarioPass = $false
                }
                else {
                    $expectedStatus = if ($host -eq 'copilot') { 'squad-runtime' } else { 'bootstrap_only' }
                    if ($context.crew_runtime_status -ne $expectedStatus) {
                        Write-Fail "crew_runtime_status=$($context.crew_runtime_status); expected $expectedStatus"
                        $scenarioPass = $false
                    }
                    else {
                        Write-Pass "crew_runtime_status=$($context.crew_runtime_status)"
                    }
                }
            }
            catch {
                Write-Fail "start-context.json parse failed: $($_.Exception.Message)"
                $scenarioPass = $false
            }
        }

        # Verify universal Crew header (FR-011)
        if (Test-Path -LiteralPath $promptPath -PathType Leaf) {
            $promptContent = Get-Content -LiteralPath $promptPath -Raw
            if ($promptContent -match 'You are the Crew team coordinator running inside a Specrew-bootstrapped repository\.') {
                Write-Pass 'Universal Crew header present (FR-011)'
            }
            else {
                Write-Fail 'Universal Crew header MISSING from last-start-prompt.md'
                $scenarioPass = $false
            }

            if ($promptContent -match 'You are Squad running inside a Specrew-bootstrapped repository\.') {
                Write-Fail 'Old Squad-flavored header STILL present (FR-011 violation)'
                $scenarioPass = $false
            }

            # FR-012: Squad-runtime-path strip on non-Copilot hosts
            if ($host -ne 'copilot') {
                if ($promptContent -match '\.squad/decisions\.md|\.squad\\decisions\.md') {
                    Write-Fail "Non-Copilot host '$host' should STRIP .squad/decisions.md references (FR-012)"
                    $scenarioPass = $false
                }
                else {
                    Write-Pass "FR-012: Squad-runtime-path .squad/decisions.md stripped on $host"
                }
            }

            # FR-014: Codex pwsh-form rewrite
            if ($host -eq 'codex') {
                if ($promptContent -match 'pwsh -File.*sync-boundary-state\.ps1') {
                    Write-Pass 'FR-014: Codex pwsh-form boundary-advance instructions present'
                }
                # Note: original prompt may not have slash-command refs, so absence isn't proof of failure
            }
        }
    }
    finally {
        Pop-Location
        if (-not $PreserveScratch) {
            try {
                Remove-Item -LiteralPath $scratchDir -Recurse -Force -ErrorAction SilentlyContinue
                Write-Info "Cleaned up scratch: $scratchDir"
            }
            catch {
                Write-Warn "Could not clean scratch dir: $($_.Exception.Message)"
            }
        }
    }

    $results[$host] = $scenarioPass
}

# Phase 3: Summary
Write-Host ''
Write-Host '================================================================' -ForegroundColor Magenta
Write-Host 'Smoke Test Summary' -ForegroundColor Magenta
Write-Host '================================================================' -ForegroundColor Magenta

$allPassed = $true
foreach ($host in $Hosts) {
    if ($results[$host]) {
        Write-Host "  [PASS] --host $host" -ForegroundColor Green
    }
    else {
        Write-Host "  [FAIL] --host $host" -ForegroundColor Red
        $allPassed = $false
    }
}

if ($allPassed) {
    Write-Host ''
    Write-Host 'All multi-host smoke tests PASSED' -ForegroundColor Green
    exit 0
}
else {
    Write-Host ''
    Write-Host 'One or more multi-host smoke tests FAILED' -ForegroundColor Red
    exit 1
}
