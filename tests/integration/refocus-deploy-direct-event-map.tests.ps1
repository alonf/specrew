# Feature 200 iteration 002 T012 (FR-009): the generic manifest-driven `direct-event-map` hook ConfigShape.
# Devin's .devin/hooks.v1.json stores the lifecycle event map at the JSON ROOT (no `hooks` wrapper). This drives
# the REAL deploy script against a scratch project and proves:
#   - deploy registers the three declared events (SessionStart/UserPromptSubmit/Stop) at the FILE ROOT
#   - the command carries DEVIN_PROJECT_DIR project resolution and the -Event Stop dispatch (decision-block Stop)
#   - merge preserves a pre-existing non-Specrew hook entry AND an unrelated top-level property
#   - re-deploy is byte-idempotent; -Remove strips only ours and records the per-host opt-out
#   - the shape is selected purely by the manifest ConfigShape value (no host-name branch in shared code)
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

# The host kind under test is read from the manifest folder name, never hardcoded here — the test stays as
# host-neutral as the seam it exercises. Pick the (single) experimental host whose manifest declares the
# direct-event-map ConfigShape so the test discovers Devin without naming it.
. (Join-Path $repoRoot 'hosts\_registry.ps1')
$directKinds = @()
foreach ($kind in @(Get-RegisteredHostKinds)) {
    $manifest = Get-HostManifest -Kind $kind
    if ($manifest.ContainsKey('RefocusHookBindings') -and
        [string]$manifest.RefocusHookBindings.ConfigShape -eq 'direct-event-map') {
        $directKinds += $kind
    }
}
Assert-True ($directKinds.Count -ge 1) ("a host manifest declares ConfigShape=direct-event-map ({0})" -f ($directKinds -join ', '))
$hostKind = @($directKinds | Select-Object -First 1)[0]
$dirManifest = Get-HostManifest -Kind $hostKind
$configFileRel = [string]$dirManifest.RefocusHookBindings.SettingsFile        # e.g. .devin/hooks.v1.json
$projectEnvVar = @($dirManifest.RefocusHookBindings.ProjectRootEnvironmentVariables)[0]
$optOutRel = [string]$dirManifest.RefocusHookBindings.OptOutMarkerFile
$declaredEvents = @($dirManifest.RefocusHookBindings.Registrations | ForEach-Object { [string]$_.Event })

$scratchRoot = Join-Path $repoRoot '.scratch\refocus-deploy-direct'
$projectRoot = Join-Path $scratchRoot 'project'
$fakeHome = Join-Path $scratchRoot 'home'
$configPath = Join-Path $projectRoot ($configFileRel -replace '/', '\')
$optOutMarker = Join-Path $projectRoot ($optOutRel -replace '/', '\')

function New-ScratchProject {
    if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force }
    New-Item -ItemType Directory -Path (Join-Path $projectRoot '.specrew') -Force | Out-Null
    New-Item -ItemType Directory -Path $fakeHome -Force | Out-Null
}

function Invoke-Deploy {
    param([string[]]$DeployArgs = @())
    return @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $deployScript -ProjectPath $projectRoot -HostKind $hostKind -UserHomeOverride $fakeHome @DeployArgs 2>&1 | ForEach-Object { [string]$_ })
}

function Get-RootProp { param($Object, [string]$Name) return $Object.PSObject.Properties[$Name] }

# --- 1. Manifest contract: declares the three events + DEVIN_PROJECT_DIR + root-level config -----------------
Assert-True ($projectEnvVar -eq 'DEVIN_PROJECT_DIR') ("manifest resolves the project through {0}" -f $projectEnvVar)
Assert-True (($declaredEvents -contains 'SessionStart') -and ($declaredEvents -contains 'UserPromptSubmit') -and ($declaredEvents -contains 'Stop')) 'manifest declares SessionStart + UserPromptSubmit + Stop'
$stopReg = @($dirManifest.RefocusHookBindings.Registrations | Where-Object { [string]$_.Event -eq 'Stop' })[0]
Assert-True ([string]$dirManifest.RefocusHookBindings.DispatcherRuntime.StopBlockShape -eq 'decision-block') 'manifest declares the decision-block Stop response'

# --- 2. Fresh project: events written at the JSON ROOT (no `hooks` wrapper) -----------------------------------
New-ScratchProject
$out = Invoke-Deploy
Assert-True ($LASTEXITCODE -eq 0) 'fresh deploy exits 0'
Assert-True (Test-Path -LiteralPath $configPath -PathType Leaf) 'direct-event-map config file created when absent'
$cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
Assert-True (-not (Get-RootProp -Object $cfg -Name 'hooks')) 'no `hooks` wrapper — event keys live at the JSON root'
Assert-True ($null -ne (Get-RootProp -Object $cfg -Name 'SessionStart')) 'SessionStart registered at root'
Assert-True ($null -ne (Get-RootProp -Object $cfg -Name 'UserPromptSubmit')) 'UserPromptSubmit registered at root'
Assert-True ($null -ne (Get-RootProp -Object $cfg -Name 'Stop')) 'Stop registered at root'
Assert-True (-not (Get-RootProp -Object $cfg -Name 'version')) 'no root `version` scalar injected (would break the array-only remove pass / idempotence)'
$ssCmd = [string]$cfg.SessionStart[0].hooks[0].command
$stopCmd = [string]$cfg.Stop[0].hooks[0].command
Assert-True ($ssCmd.Contains('specrew-hook-launch.ps1')) 'SessionStart command routes through the per-machine launcher'
Assert-True ($ssCmd.Contains(('-HostKind {0}' -f $hostKind))) ('command carries -HostKind {0}' -f $hostKind)
Assert-True ($stopCmd.Contains('-Event Stop')) 'Stop command dispatches -Event Stop'
# DEVIN_PROJECT_DIR is consumed by the per-machine launcher (manifest-enumerated ProjectRootEnvironmentVariables).
$launcherText = Get-Content -LiteralPath (Join-Path $fakeHome '.specrew\specrew-hook-launch.ps1') -Raw
Assert-True ($launcherText.Contains($projectEnvVar)) ('per-machine launcher resolves the project via {0}' -f $projectEnvVar)

# --- 3. Idempotence: re-deploy is byte-identical --------------------------------------------------------------
$before = Get-Content -LiteralPath $configPath -Raw
$null = Invoke-Deploy
$after = Get-Content -LiteralPath $configPath -Raw
Assert-True ($before -eq $after) 're-deploy is byte-idempotent'

# --- 4. Merge preserves a pre-existing NON-Specrew event entry AND an unrelated top-level property ------------
New-ScratchProject
New-Item -ItemType Directory -Path (Split-Path -Parent $configPath) -Force | Out-Null
$userConfig = [pscustomobject]@{
    schemaNote   = 'user-owned top-level string'                                       # unrelated scalar root prop
    SessionStart = @([pscustomobject]@{ hooks = @([pscustomobject]@{ type = 'command'; command = 'echo user-devin-session-hook' }) })
}
[System.IO.File]::WriteAllText($configPath, ($userConfig | ConvertTo-Json -Depth 16), [System.Text.UTF8Encoding]::new($false))
$null = Invoke-Deploy
$cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
Assert-True ([string]$cfg.schemaNote -eq 'user-owned top-level string') 'unrelated top-level property preserved exactly (not wrapped into an array)'
$ssCommands = @($cfg.SessionStart | ForEach-Object { @($_.hooks) } | ForEach-Object { [string]$_.command })
Assert-True ($ssCommands -contains 'echo user-devin-session-hook') 'pre-existing non-Specrew SessionStart entry preserved'
Assert-True (@($ssCommands | Where-Object { $_.Contains('specrew-hook-launch.ps1') }).Count -eq 1) 'our SessionStart entry added exactly once alongside the user entry'

# --- 5. Stale-entry refresh: our old entry replaced, not duplicated -------------------------------------------
$null = Invoke-Deploy
$cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$ssCommands = @($cfg.SessionStart | ForEach-Object { @($_.hooks) } | ForEach-Object { [string]$_.command })
Assert-True (@($ssCommands | Where-Object { $_.Contains('specrew-hook-launch.ps1') }).Count -eq 1) 'repeat deploy never duplicates our entries'
Assert-True ($ssCommands -contains 'echo user-devin-session-hook') 'user entry still preserved after repeat deploy'

# --- 6. -Remove: only ours stripped; user entry + unrelated prop survive; opt-out recorded --------------------
$null = Invoke-Deploy -DeployArgs @('-Remove')
$cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
Assert-True ([string]$cfg.schemaNote -eq 'user-owned top-level string') '-Remove leaves the unrelated top-level property untouched'
$ssCommands = @(if (Get-RootProp -Object $cfg -Name 'SessionStart') { @($cfg.SessionStart | ForEach-Object { @($_.hooks) } | ForEach-Object { [string]$_.command }) } else { @() })
Assert-True (($ssCommands -contains 'echo user-devin-session-hook') -and -not ($ssCommands -like '*specrew-hook-launch.ps1*')) '-Remove strips only Specrew entries; user SessionStart entry kept'
Assert-True (-not (Get-RootProp -Object $cfg -Name 'Stop')) '-Remove drops the wholly-Specrew Stop event key'
Assert-True (Test-Path -LiteralPath $optOutMarker -PathType Leaf) 'per-host opt-out marker recorded'

# --- 7. Opt-out respected; -Force re-enables explicitly -------------------------------------------------------
$out = Invoke-Deploy
Assert-True (($out -join ' ').Contains('skipped: opt-out recorded')) 'plain deploy respects the recorded opt-out (no silent re-enable)'
$out = Invoke-Deploy -DeployArgs @('-Force')
$cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$ssCommands = @($cfg.SessionStart | ForEach-Object { @($_.hooks) } | ForEach-Object { [string]$_.command })
Assert-True (@($ssCommands | Where-Object { $_.Contains('specrew-hook-launch.ps1') }).Count -eq 1) '-Force re-enables explicitly'
Assert-True (-not (Test-Path -LiteralPath $optOutMarker -PathType Leaf)) '-Force clears the opt-out marker'

# --- 8. Unparsable config: refuse, never clobber -------------------------------------------------------------
New-ScratchProject
New-Item -ItemType Directory -Path (Split-Path -Parent $configPath) -Force | Out-Null
[System.IO.File]::WriteAllText($configPath, '{user content, not json', [System.Text.UTF8Encoding]::new($false))
$out = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $deployScript -ProjectPath $projectRoot -HostKind $hostKind -UserHomeOverride $fakeHome 2>&1 | ForEach-Object { [string]$_ })
Assert-True ($LASTEXITCODE -ne 0) 'unparsable config: deploy refuses'
Assert-True ((Get-Content -LiteralPath $configPath -Raw) -eq '{user content, not json') 'unparsable config: file untouched'

# --- 9. Shared-core purity: deploy script names no direct-event-map host literal ------------------------------
# The shape is selected by the manifest ConfigShape value, never by a host-name conditional in shared code.
$deploySrc = Get-Content -LiteralPath $deployScript -Raw
Assert-True ($deploySrc.Contains("hookConfigShape -eq 'direct-event-map'")) 'deployer selects the shape by the manifest ConfigShape value'
Assert-True (-not ($deploySrc.ToLowerInvariant().Contains($hostKind.ToLowerInvariant()))) ('deployer contains no `{0}` host literal (host-neutral seam)' -f $hostKind)

# --- summary --------------------------------------------------------------------------------------------------
if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force }
if ($script:Failures -gt 0) {
    Write-Host "refocus-deploy-direct-event-map tests: $script:Failures failure(s)" -ForegroundColor Red
    exit 1
}
Write-Host 'refocus-deploy-direct-event-map tests: all passed' -ForegroundColor Green
exit 0
