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
Assert-True ($null -ne $settings.hooks.Stop) 'Stop registered (F-174 iter-4: rolling handover)'
Assert-True (([string]$settings.hooks.Stop[0].hooks[0].command).Contains('-Event Stop')) 'Stop command dispatches -Event Stop'
Assert-True (-not $settings.hooks.PSObject.Properties['SessionEnd']) 'SessionEnd NOT registered (iter-4 replaced it with the universal Stop)'
Assert-True ($null -ne $settings.hooks.PostToolUse) 'PostToolUse registered (F-174 iter-9.1: mid-workshop rolling-handover refresh)'
Assert-True (([string]$settings.hooks.PostToolUse[0].hooks[0].command).Contains('-Event PostToolUse')) 'PostToolUse command dispatches -Event PostToolUse'
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
        PostToolUse  = @(
            [pscustomobject]@{ hooks = @(
                    [pscustomobject]@{ type = 'command'; command = 'echo user-ptu-hook' },
                    [pscustomobject]@{ type = 'command'; command = 'pwsh -File old/specrew-hook-dispatcher.ps1 -Event PostToolUse' }
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
$ptuCommands = @($settings.hooks.PostToolUse | ForEach-Object { @($_.hooks) } | ForEach-Object { [string]$_.command })
Assert-True (($ptuCommands -contains 'echo user-ptu-hook') -and -not ($ptuCommands -like '*old/specrew-hook-dispatcher*') -and (@($ptuCommands | Where-Object { $_.Contains('specrew-hook-dispatcher.ps1') }).Count -eq 1)) 'mixed group: user hook kept, stale Specrew hook refreshed to exactly one current entry (PostToolUse now registered, F-174 iter-9.1)'

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

# --- 8. T014: codex binding (~/.codex/hooks.json; top-level event keys; full triad) --------
New-ScratchProject
$fakeHome = Join-Path $scratchRoot 'home'
New-Item -ItemType Directory -Path (Join-Path $fakeHome '.codex') -Force | Out-Null
$codexPath = Join-Path $fakeHome '.codex\hooks.json'
$userCodex = '{"PreToolUse":[{"matcher":"^(Write)$","hooks":[{"type":"command","command":"python3 user_scanner.py"}]}]}'
[System.IO.File]::WriteAllText($codexPath, $userCodex, [System.Text.UTF8Encoding]::new($false))
$out = Invoke-Deploy -DeployArgs @('-HostKind', 'codex', '-UserHomeOverride', $fakeHome)
$codex = Get-Content -LiteralPath $codexPath -Raw | ConvertFrom-Json
Assert-True ($null -ne $codex.hooks.PSObject.Properties['SessionStart'] -and $null -ne $codex.hooks.PSObject.Properties['UserPromptSubmit']) 'codex: SessionStart + UserPromptSubmit registered (full triad; events nested under top-level hooks)'
Assert-True (([string]$codex.hooks.SessionStart[0].hooks[0].command).Contains('-HostKind codex')) 'codex: command carries -HostKind codex'
Assert-True (([string]$codex.PreToolUse[0].hooks[0].command) -eq 'python3 user_scanner.py') 'codex: user PreToolUse entry untouched'
$before = Get-Content -LiteralPath $codexPath -Raw
$null = Invoke-Deploy -DeployArgs @('-HostKind', 'codex', '-UserHomeOverride', $fakeHome)
Assert-True ((Get-Content -LiteralPath $codexPath -Raw) -eq $before) 'codex: re-deploy byte-idempotent'
$null = Invoke-Deploy -DeployArgs @('-HostKind', 'codex', '-UserHomeOverride', $fakeHome, '-Remove')
$codex = Get-Content -LiteralPath $codexPath -Raw | ConvertFrom-Json
Assert-True ((-not $codex.hooks.PSObject.Properties['SessionStart']) -and $null -ne $codex.PSObject.Properties['PreToolUse']) 'codex: -Remove strips only ours'
Assert-True (Test-Path -LiteralPath (Join-Path $projectRoot '.specrew\runtime\refocus-hooks-optout-codex')) 'codex: per-host opt-out recorded'

# --- 9. T014: copilot binding (hooks-dir model; wholly-owned file; B2 only) ------------------
$out = Invoke-Deploy -DeployArgs @('-HostKind', 'copilot', '-UserHomeOverride', $fakeHome)
$copilotPath = Join-Path $fakeHome '.copilot\hooks\specrew-refocus.json'
Assert-True (Test-Path -LiteralPath $copilotPath -PathType Leaf) 'copilot: owned hooks-dir file created'
$copilot = Get-Content -LiteralPath $copilotPath -Raw | ConvertFrom-Json
Assert-True ([int]$copilot.version -eq 1) 'copilot: version 1 declared'
Assert-True ($null -ne $copilot.hooks.sessionStart -and -not $copilot.hooks.PSObject.Properties['userPromptSubmitted']) 'copilot: sessionStart only (B2; B3 via channel 1)'
$entry = $copilot.hooks.sessionStart[0]
Assert-True (([string]$entry.bash).Contains('-HostKind copilot') -and ([string]$entry.powershell).Contains('-HostKind copilot')) 'copilot: bash + powershell pair both present'
$null = Invoke-Deploy -DeployArgs @('-HostKind', 'copilot', '-UserHomeOverride', $fakeHome, '-Remove')
Assert-True (-not (Test-Path -LiteralPath $copilotPath)) 'copilot: -Remove deletes the owned file'

# --- 10. T014: cursor binding (~/.cursor/hooks.json; bare command entries; B2 only) ----------
New-Item -ItemType Directory -Path (Join-Path $fakeHome '.cursor') -Force | Out-Null
$cursorPath = Join-Path $fakeHome '.cursor\hooks.json'
$userCursor = '{"version":1,"hooks":{"afterFileEdit":[{"command":"hooks/audit.sh"}]}}'
[System.IO.File]::WriteAllText($cursorPath, $userCursor, [System.Text.UTF8Encoding]::new($false))
$out = Invoke-Deploy -DeployArgs @('-HostKind', 'cursor', '-UserHomeOverride', $fakeHome)
$cursor = Get-Content -LiteralPath $cursorPath -Raw | ConvertFrom-Json
Assert-True ($null -ne $cursor.hooks.sessionStart -and (([string]$cursor.hooks.sessionStart[0].command).Contains('-HostKind cursor'))) 'cursor: sessionStart command entry registered'
Assert-True (([string]$cursor.hooks.afterFileEdit[0].command) -eq 'hooks/audit.sh') 'cursor: user afterFileEdit entry untouched'
Assert-True (-not $cursor.hooks.PSObject.Properties['postToolUse']) 'cursor: no postToolUse (latency-rejected; B3 via channel 1)'
$before = Get-Content -LiteralPath $cursorPath -Raw
$null = Invoke-Deploy -DeployArgs @('-HostKind', 'cursor', '-UserHomeOverride', $fakeHome)
Assert-True ((Get-Content -LiteralPath $cursorPath -Raw) -eq $before) 'cursor: re-deploy byte-idempotent'

# --- 11. T017: catalog managed-with-overlay merge (FR-014/FR-018) ----------------------------
. (Join-Path $repoRoot 'scripts\internal\refocus-deploy-integration.ps1')
$canonicalCatalog = Join-Path $repoRoot 'extensions\specrew-speckit\refocus-scopes.json'
$projectCatalogDir = Join-Path $projectRoot '.specify\extensions\specrew-speckit'
$projectCatalog = Join-Path $projectCatalogDir 'refocus-scopes.json'

New-ScratchProject
New-Item -ItemType Directory -Path $projectCatalogDir -Force | Out-Null
$userCatalog = Get-Content -LiteralPath $canonicalCatalog -Raw | ConvertFrom-Json
$userCatalog.triggers.b1.enabled = $false
$userCatalog.PSObject.Properties['providers'].Value = @($userCatalog.providers) + @([pscustomobject]@{ id = 'user-audit'; kind = 'inject'; events = @('SessionStart'); order = 20; budget_share = 0.2; command = 'user-audit.ps1' })
[System.IO.File]::WriteAllText($projectCatalog, ($userCatalog | ConvertTo-Json -Depth 16), [System.Text.UTF8Encoding]::new($false))

$overlay = Get-RefocusCatalogOverlay -ProjectPath $projectRoot
Assert-True ($overlay.Present -and -not $overlay.Aborted) 'overlay: captured from a parsable user catalog'
Assert-True ($overlay.TriggerEnabled['b1'] -eq $false -and $overlay.TriggerEnabled['b2'] -eq $true) 'overlay: per-trigger enabled flags captured'
Assert-True (@($overlay.UserProviders).Count -eq 1 -and [string]$overlay.UserProviders[0].id -eq 'user-audit') 'overlay: user provider row captured (canonical refocus row excluded)'

Copy-Item -LiteralPath $canonicalCatalog -Destination $projectCatalog -Force   # simulate the wholesale canonical refresh
$applied = Set-RefocusCatalogOverlay -ProjectPath $projectRoot -Overlay $overlay
Assert-True ($applied -eq $true) 'overlay: re-apply reports a change after canonical refresh'
$merged = Get-Content -LiteralPath $projectCatalog -Raw | ConvertFrom-Json
Assert-True ([bool]$merged.triggers.b1.enabled -eq $false) 'overlay: user b1 disable survives the update (never silently flips a disable)'
Assert-True ([bool]$merged.triggers.b2.enabled -eq $true -and [bool]$merged.triggers.b3.enabled -eq $true) 'overlay: untouched triggers stay canonical'
$mergedIds = @($merged.providers | ForEach-Object { [string]$_.id })
Assert-True (($mergedIds -contains 'refocus') -and ($mergedIds -contains 'user-audit')) 'overlay: canonical provider kept + user provider row restored'

# --- 11b. T017 (PR #2152): overlay does NOT duplicate a user provider that became canonical ----
# Simulate a freshly-deployed catalog that now ships a provider id which an older user catalog
# had added by hand. Re-applying the captured overlay must NOT append a second copy.
$dupCatalog = Get-Content -LiteralPath $canonicalCatalog -Raw | ConvertFrom-Json
$dupCatalog.PSObject.Properties['providers'].Value = @($dupCatalog.providers) + @([pscustomobject]@{ id = 'now-canonical'; kind = 'inject'; events = @('SessionStart'); order = 30; budget_share = 0.1; command = 'now-canonical.ps1' })
[System.IO.File]::WriteAllText($projectCatalog, ($dupCatalog | ConvertTo-Json -Depth 16), [System.Text.UTF8Encoding]::new($false))
$dupOverlay = [pscustomobject]@{ Present = $true; Aborted = $false; TriggerEnabled = @{}; UserProviders = @([pscustomobject]@{ id = 'now-canonical'; kind = 'inject'; events = @('SessionStart'); order = 30; budget_share = 0.1; command = 'now-canonical.ps1' }) }
$dupApplied = Set-RefocusCatalogOverlay -ProjectPath $projectRoot -Overlay $dupOverlay
$dupMerged = Get-Content -LiteralPath $projectCatalog -Raw | ConvertFrom-Json
$dupCount = @($dupMerged.providers | Where-Object { [string]$_.id -eq 'now-canonical' }).Count
Assert-True ($dupApplied -eq $false -and $dupCount -eq 1) 'overlay: a user provider whose id is now canonical is NOT duplicated (dup-ID guard)'

# --- 12. T017: pristine catalog -> overlay is a no-op (byte-untouched) ------------------------
Copy-Item -LiteralPath $canonicalCatalog -Destination $projectCatalog -Force
$pristineOverlay = Get-RefocusCatalogOverlay -ProjectPath $projectRoot
$bytesBefore = Get-Content -LiteralPath $projectCatalog -Raw
$applied = Set-RefocusCatalogOverlay -ProjectPath $projectRoot -Overlay $pristineOverlay
Assert-True ($applied -eq $false) 'overlay: pristine catalog -> no change reported'
Assert-True ((Get-Content -LiteralPath $projectCatalog -Raw) -eq $bytesBefore) 'overlay: pristine catalog left byte-untouched'

# --- 13. T017: unparsable catalog fails SAFE in both directions --------------------------------
[System.IO.File]::WriteAllText($projectCatalog, '{corrupt catalog, not json', [System.Text.UTF8Encoding]::new($false))
$corruptOverlay = Get-RefocusCatalogOverlay -ProjectPath $projectRoot
Assert-True ($corruptOverlay.Aborted -eq $true) 'overlay: unparsable catalog -> capture aborts'
Copy-Item -LiteralPath $canonicalCatalog -Destination $projectCatalog -Force
$bytesBefore = Get-Content -LiteralPath $projectCatalog -Raw
Assert-True ((Set-RefocusCatalogOverlay -ProjectPath $projectRoot -Overlay $corruptOverlay) -eq $false) 'overlay: aborted capture is never merged'
Assert-True ((Get-Content -LiteralPath $projectCatalog -Raw) -eq $bytesBefore) 'overlay: freshly-deployed canonical file untouched after aborted capture'
[System.IO.File]::WriteAllText($projectCatalog, '{corrupt catalog, not json', [System.Text.UTF8Encoding]::new($false))
Assert-True ((Set-RefocusCatalogOverlay -ProjectPath $projectRoot -Overlay $overlay) -eq $false) 'overlay: never merges INTO an unparsable target'
Assert-True ((Get-Content -LiteralPath $projectCatalog -Raw) -eq '{corrupt catalog, not json') 'overlay: unparsable target untouched'

# --- 14. T017: Invoke-RefocusHookDeployment wiring (host detection, fail-open) ------------------
New-ScratchProject
New-Item -ItemType Directory -Path (Join-Path $projectRoot '.claude') -Force | Out-Null
$stubDeploy = Join-Path $scratchRoot 'stub-deploy.ps1'
[System.IO.File]::WriteAllText($stubDeploy, "param([string]`$ProjectPath, [string]`$HostKind = 'claude')`n""stub-deploy `$HostKind""`n", [System.Text.UTF8Encoding]::new($false))
$hookActions = @(Invoke-RefocusHookDeployment -ProjectPath $projectRoot -DeployScriptPath $stubDeploy)
$claudeAction = @($hookActions | Where-Object { $_.HostKind -eq 'claude' })
Assert-True ($claudeAction.Count -eq 1 -and $claudeAction[0].Action -eq 'refocus-hooks' -and ([string]$claudeAction[0].Detail).Contains('stub-deploy claude')) 'hook deployment: .claude dir detected -> claude deploy invoked + action recorded'
Assert-True (@($hookActions | Where-Object { $_.Action -notin @('refocus-hooks', 'refocus-hooks-failed') }).Count -eq 0) 'hook deployment: every action carries a known action kind'

$throwingDeploy = Join-Path $scratchRoot 'stub-deploy-throws.ps1'
[System.IO.File]::WriteAllText($throwingDeploy, "param([string]`$ProjectPath, [string]`$HostKind = 'claude')`nthrow 'boom'`n", [System.Text.UTF8Encoding]::new($false))
$failActions = @(Invoke-RefocusHookDeployment -ProjectPath $projectRoot -DeployScriptPath $throwingDeploy)
$claudeFail = @($failActions | Where-Object { $_.HostKind -eq 'claude' })
Assert-True ($claudeFail.Count -eq 1 -and $claudeFail[0].Action -eq 'refocus-hooks-failed' -and ([string]$claudeFail[0].Detail).Contains('boom')) 'hook deployment: deploy failure recorded, never thrown (fail open)'
Assert-True (@(Invoke-RefocusHookDeployment -ProjectPath $projectRoot -DeployScriptPath (Join-Path $scratchRoot 'missing.ps1')).Count -eq 0) 'hook deployment: missing deploy script -> no actions, no error'

# --- 14b. T017 (PR #2152): -UserHomeOverride passthrough (hermetic-test seam) -------------------
$homeStub = Join-Path $scratchRoot 'stub-deploy-home.ps1'
[System.IO.File]::WriteAllText($homeStub, "param([string]`$ProjectPath, [string]`$HostKind = 'claude', [string]`$UserHomeOverride)`n""home=[`$UserHomeOverride]""`n", [System.Text.UTF8Encoding]::new($false))
$noOverride = @(Invoke-RefocusHookDeployment -ProjectPath $projectRoot -DeployScriptPath $homeStub)
$claudeNoOverride = @($noOverride | Where-Object { $_.HostKind -eq 'claude' })
Assert-True ($claudeNoOverride.Count -eq 1 -and ([string]$claudeNoOverride[0].Detail).Contains('home=[]')) 'hook deployment: no -UserHomeOverride -> deploy script gets none (production default)'
$withOverride = @(Invoke-RefocusHookDeployment -ProjectPath $projectRoot -DeployScriptPath $homeStub -UserHomeOverride 'C:\fake\home')
$claudeWithOverride = @($withOverride | Where-Object { $_.HostKind -eq 'claude' })
Assert-True ($claudeWithOverride.Count -eq 1 -and ([string]$claudeWithOverride[0].Detail).Contains('home=[C:\fake\home]')) 'hook deployment: -UserHomeOverride passed through to the deploy script (hermetic seam)'

# --- 15. T017: init/update wiring content + parse integrity --------------------------------------
$updateScript = Join-Path $repoRoot 'scripts\specrew-update.ps1'
$initScript = Join-Path $repoRoot 'scripts\specrew-init.ps1'
$updateRaw = Get-Content -LiteralPath $updateScript -Raw
$initRaw = Get-Content -LiteralPath $initScript -Raw
Assert-True ($updateRaw.Contains('refocus-deploy-integration.ps1') -and $updateRaw.Contains('Invoke-RefocusHookDeployment')) 'update: dot-sources the integration + deploys hooks'
$idxGet = $updateRaw.IndexOf('Get-RefocusCatalogOverlay')
$idxRefresh = $updateRaw.IndexOf('-RefreshExisting')
$idxSet = $updateRaw.IndexOf('Set-RefocusCatalogOverlay')
Assert-True ($idxGet -ge 0 -and $idxSet -ge 0 -and $idxGet -lt $idxRefresh -and $idxRefresh -lt $idxSet) 'update: overlay captured BEFORE the canonical refresh and re-applied AFTER'
Assert-True ($initRaw.Contains('refocus-deploy-integration.ps1') -and $initRaw.Contains('Invoke-RefocusHookDeployment')) 'init: dot-sources the integration + deploys hooks'
$idxSquadRuntime = $initRaw.IndexOf("Write-Step 'Deploying Squad runtime'")
$idxRefocusHooks = $initRaw.IndexOf("Write-Step 'Deploying refocus hooks'")
Assert-True ($idxSquadRuntime -ge 0 -and $idxRefocusHooks -gt $idxSquadRuntime) 'init: refocus hooks deploy AFTER the Squad-runtime/skill-surface step (greenfield .claude detection; review-caught anchor defect)'
# PR #2152: the SAME ordering fix in the update path — hook deploy must follow the squad-runtime
# refresh that provisions .claude (else a workspace gaining .claude this update skips Claude).
$idxUpdSquad = $updateRaw.IndexOf('& $deploySquadRuntimeScript')
$idxUpdHook = $updateRaw.IndexOf('Invoke-RefocusHookDeployment')
Assert-True ($idxUpdSquad -ge 0 -and $idxUpdHook -gt $idxUpdSquad) 'update: refocus hooks deploy AFTER the Squad-runtime refresh (.claude provisioned first; PR #2152 ordering fix)'
foreach ($wired in @($updateScript, $initScript, (Join-Path $repoRoot 'scripts\internal\refocus-deploy-integration.ps1'))) {
    $parseErrors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($wired, [ref]$null, [ref]$parseErrors)
    Assert-True (@($parseErrors).Count -eq 0) ("parses clean: {0}" -f (Split-Path -Leaf $wired))
}

# --- summary ------------------------------------------------------------------------------
if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force }
if ($script:Failures -gt 0) {
    Write-Host "refocus-deploy tests: $script:Failures failure(s)" -ForegroundColor Red
    exit 1
}
Write-Host 'refocus-deploy tests: all passed' -ForegroundColor Green
exit 0
