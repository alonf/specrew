$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Trace: T004 / FR-010.
#
# WIRING DRIFT, diagnosed live on 2026-08-10. `specrew hooks status` answered ONE question on an
# event-map host: "is the dispatcher mentioned anywhere in this file?" A settings file written by an
# older Specrew - registering SessionStart and Stop, before the manifest grew UserPromptSubmit and
# PostToolUse - answered YES, so status reported `installed` while two registered events were not
# wired at all.
#
# That is the exact condition a status surface exists to catch, and it matters more here than
# elsewhere: verdict capture rides UserPromptSubmit, so a drifted config silently downgrades capture
# to the Stop path alone with nothing reporting it. The consumer sees a green status and a lost
# verdict.
#
# Two halves, and both are asserted because either alone is a false comfort:
#   STATUS must FLAG the drift and NAME the events that are missing.
#   DEPLOY must RECONCILE it - add the missing events without disturbing the user's own hooks.

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'scripts/internal/specrew-hook-health.ps1')

$failures = 0
function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Fail { param([string]$m) $script:failures++; Write-Host "FAIL: $m" -ForegroundColor Red }

$scratch = Join-Path ([IO.Path]::GetTempPath()) ("hooks-reconcile-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch -Force | Out-Null
try {
    $project = Join-Path $scratch 'project'
    $userHome = Join-Path $scratch 'home'
    New-Item -ItemType Directory -Path (Join-Path $project '.claude') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $project '.specrew') -Force | Out-Null
    New-Item -ItemType Directory -Path $userHome -Force | Out-Null

    # A config written by an older Specrew: the dispatcher IS wired, but only for two of the four events
    # the manifest now registers. The user's OWN hook sits on UserPromptSubmit - which is what makes the
    # check structural rather than a search for the event NAME: a name search would see "UserPromptSubmit"
    # in this file and call it wired while Specrew is absent from it.
    # NOTE: built by concatenation, never with -f. The command carries `${CLAUDE_PROJECT_DIR}`, whose
    # braces the format operator parses as a placeholder and then fails on.
    function New-DispatcherCommand {
        param([string]$EventName)
        return ('pwsh -NoProfile -File "${CLAUDE_PROJECT_DIR}/.specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1" -Event ' + $EventName)
    }
    $settingsPath = Join-Path $project '.claude\settings.local.json'
    $stale = [ordered]@{
        hooks = [ordered]@{
            SessionStart     = @(@{ hooks = @(@{ type = 'command'; command = (New-DispatcherCommand -EventName 'SessionStart') }) })
            Stop             = @(@{ hooks = @(@{ type = 'command'; command = (New-DispatcherCommand -EventName 'Stop') }) })
            UserPromptSubmit = @(@{ hooks = @(@{ type = 'command'; command = 'pwsh -NoProfile -File ./tools/my-own-linter.ps1' }) })
        }
    }
    [IO.File]::WriteAllText($settingsPath, ($stale | ConvertTo-Json -Depth 16), [Text.UTF8Encoding]::new($false))

    # -- STATUS flags the drift, and names it -------------------------------------------------------
    $row = @(Get-SpecrewHooksStatus -ProjectPath $project -UserHomeOverride $userHome) | Where-Object { $_.Host -eq 'claude' } | Select-Object -First 1
    if ($null -eq $row) { Fail 'no claude row returned by Get-SpecrewHooksStatus' }
    else {
        if ($row.State -ne 'stale') { Fail "drifted config reported '$($row.State)', expected 'stale' (detail: $($row.Detail))" }
        else { Write-Pass 'status: a config missing newly registered events reports STALE, not installed' }

        foreach ($expected in @('UserPromptSubmit', 'PostToolUse')) {
            if ([string]$row.Detail -notmatch [regex]::Escape($expected)) { Fail "status detail does not NAME the missing event '$expected': $($row.Detail)" }
        }
        if ([string]$row.Detail -match 'SessionStart' -or [string]$row.Detail -match '\bStop\b') {
            Fail "status detail names an event that IS wired: $($row.Detail)"
        }
        if ($script:failures -eq 0) { Write-Pass 'status: the missing events are NAMED, and the wired ones are not' }
    }

    # -- DEPLOY reconciles ---------------------------------------------------------------------------
    $userHookBefore = 'my-own-linter.ps1'
    & pwsh -NoProfile -NonInteractive -File (Join-Path $repoRoot 'scripts/internal/deploy-refocus-hooks.ps1') `
        -ProjectPath $project -HostKind claude -UserHomeOverride $userHome *> $null
    if ($LASTEXITCODE -ne 0) { Fail "deploy-refocus-hooks.ps1 exited $LASTEXITCODE" }

    $after = @(Get-SpecrewHooksStatus -ProjectPath $project -UserHomeOverride $userHome) | Where-Object { $_.Host -eq 'claude' } | Select-Object -First 1
    if ($null -eq $after -or $after.State -ne 'installed') {
        Fail "after deploy the state is '$(if ($null -eq $after) { 'missing row' } else { $after.State })', expected 'installed' (detail: $($after.Detail))"
    }
    else { Write-Pass 'deploy: reconciles a settings file missing a newly registered event' }

    $reconciled = Get-Content -LiteralPath $settingsPath -Raw -Encoding UTF8
    foreach ($eventName in @('SessionStart', 'UserPromptSubmit', 'Stop', 'PostToolUse')) {
        $missing = @(Get-SpecrewHookMissingEventRegistrations -ParsedConfig ($reconciled | ConvertFrom-Json) -Bindings (Get-SpecrewHookHealthBindings -HostKind claude))
        if ($missing -contains $eventName) { Fail "event '$eventName' still has no Specrew entry after deploy" }
    }
    Write-Pass 'deploy: every registered event carries a Specrew entry afterwards'

    # The user's own hook is not collateral. A reconciliation that repairs wiring by discarding user
    # content would be a worse defect than the drift it fixes.
    if (-not $reconciled.Contains($userHookBefore)) { Fail "deploy discarded the user's own UserPromptSubmit hook" }
    else { Write-Pass "deploy: the user's own hook on a reconciled event survives" }

    # -- A fully-wired config is NOT reported as drifted (the paired sibling) -------------------------
    if ($null -ne $after -and $after.State -eq 'installed' -and [string]$after.Detail -match 'no Specrew entry') {
        Fail 'a fully wired config still carries a drift detail'
    }
    else { Write-Pass 'status: a fully wired config reports installed with no drift note' }
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}

if ($failures -gt 0) {
    Write-Host "`n=== hooks-reconcile.Tests.ps1: $failures failure(s) ===" -ForegroundColor Red
    exit 1
}
Write-Host "`n=== hooks-reconcile.Tests.ps1: all assertions passed ===" -ForegroundColor Green
exit 0
