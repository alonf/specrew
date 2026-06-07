# Feature 171 T010: merge-aware hook deployment tests (FR-014; SC-006, SC-009).
# Drives the REAL deploy script against scratch settings files: creation, user-entry
# preservation (incl. mixed groups), idempotence, removal, opt-out memory, and the
# dormant-PreToolUse invariant.
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Failures = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:Failures++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$deployScript = Join-Path $repoRoot 'scripts\internal\deploy-refocus-hooks.ps1'
$scratchRoot = Join-Path $repoRoot '.scratch\refocus-deploy'
$projectRoot = Join-Path $scratchRoot 'project'
$settingsPath = Join-Path $projectRoot '.claude\settings.local.json'

function New-ScratchProject {
    if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force }
    New-Item -ItemType Directory -Path (Join-Path $projectRoot '.specrew') -Force | Out-Null
}

function Invoke-Deploy {
    param([string[]]$DeployArgs = @())
    return @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $deployScript -ProjectPath $projectRoot @DeployArgs 2>&1 | ForEach-Object { [string]$_ })
}

# --- 1. Fresh project: settings created with our entries, PreToolUse absent -------
New-ScratchProject
$out = Invoke-Deploy
Assert-True (Test-Path -LiteralPath $settingsPath -PathType Leaf) 'settings.local.json created when absent'
$settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
Assert-True ($null -ne $settings.hooks.SessionStart) 'SessionStart registered'
Assert-True ($null -ne $settings.hooks.PostToolUse -and [string]$settings.hooks.PostToolUse[0].matcher -eq 'Bash') 'PostToolUse registered with the Bash matcher (P4 narrowing)'
Assert-True (-not $settings.hooks.PSObject.Properties['PreToolUse']) 'PreToolUse NOT registered (dormant F-165 seat)'
Assert-True (([string]$settings.hooks.SessionStart[0].hooks[0].command).Contains('specrew-hook-dispatcher.ps1')) 'command points at the dispatcher'

# --- 2. Idempotence: re-deploy is byte-identical ------------------------------------
$before = Get-Content -LiteralPath $settingsPath -Raw
$null = Invoke-Deploy
$after = Get-Content -LiteralPath $settingsPath -Raw
Assert-True ($before -eq $after) 're-deploy is byte-idempotent'

# --- 3. User entries preserved exactly (pure user group + mixed group) ---------------
New-ScratchProject
New-Item -ItemType Directory -Path (Split-Path -Parent $settingsPath) -Force | Out-Null
$userSettings = [pscustomobject]@{
    permissions = [pscustomobject]@{ allow = @('Bash(npm test:*)') }
    hooks       = [pscustomobject]@{
        SessionStart = @(
            [pscustomobject]@{ hooks = @([pscustomobject]@{ type = 'command'; command = 'echo user-session-hook' }) }
        )
        Stop         = @(
            [pscustomobject]@{ hooks = @(
                    [pscustomobject]@{ type = 'command'; command = 'echo user-stop-hook' },
                    [pscustomobject]@{ type = 'command'; command = 'pwsh -File old/specrew-hook-dispatcher.ps1 -Event Stop' }
                )
            }
        )
    }
}
[System.IO.File]::WriteAllText($settingsPath, ($userSettings | ConvertTo-Json -Depth 16), [System.Text.UTF8Encoding]::new($false))
$null = Invoke-Deploy
$settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
Assert-True ([string]$settings.permissions.allow[0] -eq 'Bash(npm test:*)') 'non-hook user settings preserved'
$ssCommands = @($settings.hooks.SessionStart | ForEach-Object { @($_.hooks) } | ForEach-Object { [string]$_.command })
Assert-True ($ssCommands -contains 'echo user-session-hook') 'user SessionStart hook preserved'
Assert-True (@($ssCommands | Where-Object { $_.Contains('specrew-hook-dispatcher.ps1') }).Count -eq 1) 'our SessionStart entry added exactly once'
$stopCommands = @($settings.hooks.Stop | ForEach-Object { @($_.hooks) } | ForEach-Object { [string]$_.command })
Assert-True (($stopCommands -contains 'echo user-stop-hook') -and -not ($stopCommands -like '*specrew-hook-dispatcher*')) 'mixed group: user hook kept, stale Specrew hook removed from an event we do not register'

# --- 4. Stale-entry refresh: our old command replaced, not duplicated ----------------
$null = Invoke-Deploy
$settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
$ssCommands = @($settings.hooks.SessionStart | ForEach-Object { @($_.hooks) } | ForEach-Object { [string]$_.command })
Assert-True (@($ssCommands | Where-Object { $_.Contains('specrew-hook-dispatcher.ps1') }).Count -eq 1) 'repeat deploy never duplicates our entries'

# --- 5. Remove: only ours stripped; opt-out recorded ----------------------------------
$out = Invoke-Deploy -DeployArgs @('-Remove')
$settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
$ssCommands = @(if ($settings.hooks.PSObject.Properties['SessionStart']) { @($settings.hooks.SessionStart | ForEach-Object { @($_.hooks) } | ForEach-Object { [string]$_.command }) } else { @() })
Assert-True (($ssCommands -contains 'echo user-session-hook') -and -not ($ssCommands -like '*specrew-hook-dispatcher*')) '-Remove strips only Specrew entries'
$optOutMarker = Join-Path $projectRoot '.specrew\runtime\refocus-hooks-optout'
Assert-True (Test-Path -LiteralPath $optOutMarker -PathType Leaf) 'opt-out marker recorded'

# --- 6. Opt-out respected; -Force re-enables explicitly --------------------------------
$out = Invoke-Deploy
Assert-True (($out -join ' ').Contains('skipped: opt-out recorded')) 'plain deploy respects the recorded opt-out (no silent re-enable)'
$settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
$ssCommands = @(if ($settings.hooks.PSObject.Properties['SessionStart']) { @($settings.hooks.SessionStart | ForEach-Object { @($_.hooks) } | ForEach-Object { [string]$_.command }) } else { @() })
Assert-True (-not ($ssCommands -like '*specrew-hook-dispatcher*')) 'opt-out: our entries stay absent'
$out = Invoke-Deploy -DeployArgs @('-Force')
$settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
$ssCommands = @($settings.hooks.SessionStart | ForEach-Object { @($_.hooks) } | ForEach-Object { [string]$_.command })
Assert-True (@($ssCommands | Where-Object { $_.Contains('specrew-hook-dispatcher.ps1') }).Count -eq 1) '-Force re-enables explicitly'
Assert-True (-not (Test-Path -LiteralPath $optOutMarker -PathType Leaf)) '-Force clears the opt-out marker'

# --- 7. Unparsable settings: refuse, never clobber --------------------------------------
New-ScratchProject
New-Item -ItemType Directory -Path (Split-Path -Parent $settingsPath) -Force | Out-Null
[System.IO.File]::WriteAllText($settingsPath, '{user content, not json', [System.Text.UTF8Encoding]::new($false))
$out = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $deployScript -ProjectPath $projectRoot 2>&1 | ForEach-Object { [string]$_ })
Assert-True ($LASTEXITCODE -ne 0) 'unparsable settings: deploy refuses'
Assert-True ((Get-Content -LiteralPath $settingsPath -Raw) -eq '{user content, not json') 'unparsable settings: file untouched'

# --- summary ------------------------------------------------------------------------------
if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force }
if ($script:Failures -gt 0) {
    Write-Host "refocus-deploy tests: $script:Failures failure(s)" -ForegroundColor Red
    exit 1
}
Write-Host 'refocus-deploy tests: all passed' -ForegroundColor Green
exit 0
