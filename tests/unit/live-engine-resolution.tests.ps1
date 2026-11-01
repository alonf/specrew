# Feature 203 T002 (DA-8): the live-engine pin. With no pin configured, engine resolution is exactly today's (the
# project tree's scripts/internal). With a valid pin, engine code loads from the pin and never from the project
# tree. With a configured pin that is missing or corrupt, the hooks refuse in plain words and load NOTHING - no
# silent fall back to the project tree or an installed module.
#
# Mutation that turns this file red: make the handover or navigator provider ignore the pin record, or fall back
# to the project tree when the pin is unusable.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$scriptsDir = Join-Path $repoRoot 'extensions\specrew-speckit\scripts'
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

. (Join-Path $scriptsDir 'live-engine-resolution.ps1')

$work = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-pin-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $work | Out-Null
$markerFile = Join-Path $work 'loaded-from.txt'

function Write-EngineStubs {
    # Engine stubs that record which copy was loaded. HandoverStore's Update-SpecrewRollingHandover is the call the
    # handover provider makes; worktree-navigator's function is the one the navigator provider calls.
    param([string]$Root, [string]$Label)
    $boot = Join-Path $Root 'scripts/internal/bootstrap'
    $ccr = Join-Path $Root 'scripts/internal/continuous-co-review'
    $ext = Join-Path $Root 'extensions/specrew-speckit/scripts'
    $deployed = Join-Path $Root '.specify/extensions/specrew-speckit/scripts'
    foreach ($d in @($boot, $ccr, $ext, $deployed)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    Set-Content -LiteralPath (Join-Path $deployed 'specrew-hook-dispatcher.ps1') -Value '# stub'
    $markerLine = "Add-Content -LiteralPath `$env:SPECREW_TEST_MARKER -Value '$Label'"
    Set-Content -LiteralPath (Join-Path $boot 'HandoverStore.ps1') -Value @($markerLine, 'function Update-SpecrewRollingHandover { return $null }')
    foreach ($f in 'ClassificationEngine', 'ProjectMetadataAccessor', 'ConversationCaptureAccessor', 'HumanAuthorityStore') {
        Set-Content -LiteralPath (Join-Path $boot "$f.ps1") -Value '# stub'
    }
    Set-Content -LiteralPath (Join-Path $ccr 'worktree-navigator.ps1') -Value @($markerLine, 'function Invoke-ContinuousCoReviewWorktreeNavigator { return $null }')
    Set-Content -LiteralPath (Join-Path $ext 'shared-governance.ps1') -Value '# stub'
}

function New-StubProject {
    param([string]$Name)
    $root = Join-Path $work $Name
    New-Item -ItemType Directory -Path (Join-Path $root '.specrew/runtime') -Force | Out-Null
    Write-EngineStubs -Root $root -Label 'project-tree'
    return $root
}

function Invoke-Git { param([string[]]$GitArgs) & git @GitArgs 2>&1 | Out-Null; if ($LASTEXITCODE -ne 0) { throw "git $($GitArgs -join ' ') failed" } }

# A real pin: a repository with the engine stubs committed, checked out detached as a worktree elsewhere.
$pinSource = Join-Path $work 'pin-source'
New-Item -ItemType Directory -Path $pinSource | Out-Null
Write-EngineStubs -Root $pinSource -Label 'pin'
Invoke-Git @('-C', $pinSource, 'init', '-q')
Invoke-Git @('-C', $pinSource, 'add', '-A')
Invoke-Git @('-C', $pinSource, '-c', 'user.email=t@example.invalid', '-c', 'user.name=t', 'commit', '-q', '-m', 'engine')
$pinCommit = (& git -C $pinSource rev-parse HEAD).Trim()
$pinPath = Join-Path $work 'live-engine'
Invoke-Git @('-C', $pinSource, 'worktree', 'add', '-q', '--detach', $pinPath, $pinCommit)

function Set-PinRecord {
    param([string]$ProjectRoot, [string]$Path, [string]$Commit)
    $record = [ordered]@{ schema_version = '1'; path = $Path; commit = $Commit }
    Set-Content -LiteralPath (Get-SpecrewLiveEngineRecordPath -ProjectRoot $ProjectRoot) -Value ($record | ConvertTo-Json) -Encoding UTF8
}

function Invoke-Provider {
    param([string]$ProjectRoot, [string]$Script, [string[]]$ProviderArgs)
    if (Test-Path -LiteralPath $markerFile) { Remove-Item -LiteralPath $markerFile -Force }
    $env:SPECREW_TEST_MARKER = $markerFile
    Push-Location $ProjectRoot
    try { $out = (& pwsh -NoProfile -File (Join-Path $scriptsDir $Script) @ProviderArgs 2>$null) -join "`n" }
    finally { Pop-Location; Remove-Item Env:SPECREW_TEST_MARKER -ErrorAction SilentlyContinue }
    $loaded = if (Test-Path -LiteralPath $markerFile) { (Get-Content -LiteralPath $markerFile) -join ',' } else { '' }
    return [pscustomobject]@{ Output = [string]$out; Loaded = [string]$loaded }
}

try {
    # --- Get-SpecrewLiveEnginePin ---
    $p = New-StubProject 'unit'
    $r = Get-SpecrewLiveEnginePin -ProjectRoot $p
    Assert-True (-not $r.Configured) 'no record: not configured'

    Set-Content -LiteralPath (Get-SpecrewLiveEngineRecordPath -ProjectRoot $p) -Value '{ not json'
    $r = Get-SpecrewLiveEnginePin -ProjectRoot $p
    Assert-True ($r.Configured -and -not $r.Valid -and $r.Reason -eq 'record-unreadable') 'unreadable record: configured, refused (record-unreadable)'

    Set-PinRecord -ProjectRoot $p -Path (Join-Path $work 'absent') -Commit $pinCommit
    $r = Get-SpecrewLiveEnginePin -ProjectRoot $p
    Assert-True ($r.Configured -and -not $r.Valid -and $r.Reason -eq 'pin-missing') 'absent pin path: refused (pin-missing)'

    Set-PinRecord -ProjectRoot $p -Path $pinSource -Commit $pinCommit
    $r = Get-SpecrewLiveEnginePin -ProjectRoot $p
    Assert-True ($r.Configured -and -not $r.Valid -and $r.Reason -eq 'pin-not-a-checkout') 'a main repository (attached HEAD) is not a pin: refused (pin-not-a-checkout)'

    Set-PinRecord -ProjectRoot $p -Path $pinPath -Commit ('0' * 40)
    $r = Get-SpecrewLiveEnginePin -ProjectRoot $p
    Assert-True ($r.Configured -and -not $r.Valid -and $r.Reason -eq 'pin-commit-mismatch') 'pin at another commit: refused (pin-commit-mismatch)'

    Set-PinRecord -ProjectRoot $p -Path $pinPath -Commit $pinCommit
    $r = Get-SpecrewLiveEnginePin -ProjectRoot $p
    Assert-True ($r.Configured -and $r.Valid -and $r.Root -eq $pinPath) 'valid pin: configured, valid, root is the pin'

    $msg = Get-SpecrewLiveEngineRefusalMessage -Pin ([pscustomobject]@{ Reason = 'pin-missing'; Root = 'C:\x'; Commit = $pinCommit; Detail = $null })
    Assert-True ($msg -match 'recorded nothing' -and $msg -match 'earlier approvals and answers are unchanged' -and $msg -match 'Should it do that\?') 'refusal message: nothing recorded, approvals unchanged, one action, asks first'
    Assert-True ($msg -notmatch 'pin-missing') 'refusal message carries no internal reason code'

    # --- handover provider wiring ---
    $h = New-StubProject 'handover'
    $res = Invoke-Provider -ProjectRoot $h -Script 'specrew-handover-provider.ps1' -ProviderArgs @('--project-root', $h, '--source', 'stop')
    Assert-True ($res.Loaded -eq 'project-tree') ("no pin configured: today's resolution, project tree loaded (got '{0}')" -f $res.Loaded)

    Set-PinRecord -ProjectRoot $h -Path $pinPath -Commit $pinCommit
    $res = Invoke-Provider -ProjectRoot $h -Script 'specrew-handover-provider.ps1' -ProviderArgs @('--project-root', $h, '--source', 'stop')
    Assert-True ($res.Loaded -eq 'pin') ("valid pin: handover engine loaded from the pin only (got '{0}')" -f $res.Loaded)

    Set-PinRecord -ProjectRoot $h -Path (Join-Path $work 'absent') -Commit $pinCommit
    $res = Invoke-Provider -ProjectRoot $h -Script 'specrew-handover-provider.ps1' -ProviderArgs @('--project-root', $h, '--source', 'stop')
    Assert-True ([string]::IsNullOrEmpty($res.Loaded)) ("missing pin: handover loads no engine at all (got '{0}')" -f $res.Loaded)
    Assert-True ($res.Output -match 'could not load its reviewed engine') 'missing pin: handover says so in plain words'

    # --- navigator provider wiring ---
    $n = New-StubProject 'navigator'
    Set-PinRecord -ProjectRoot $n -Path $pinPath -Commit ('0' * 40)
    $res = Invoke-Provider -ProjectRoot $n -Script 'specrew-co-review-navigator-provider.ps1' -ProviderArgs @('--source-event', 'stop')
    Assert-True ([string]::IsNullOrEmpty($res.Loaded)) ("corrupt pin: navigator loads no engine (got '{0}')" -f $res.Loaded)
    Assert-True ($res.Output.StartsWith('<<<SPECREW-STOP-BLOCK>>>') -and $res.Output -match 'could not load its reviewed engine') 'corrupt pin: navigator stops visibly with the plain-words refusal'

    Set-PinRecord -ProjectRoot $n -Path $pinPath -Commit $pinCommit
    $res = Invoke-Provider -ProjectRoot $n -Script 'specrew-co-review-navigator-provider.ps1' -ProviderArgs @('--source-event', 'stop')
    Assert-True ($res.Loaded -eq 'pin') ("valid pin: navigator engine loaded from the pin only (got '{0}')" -f $res.Loaded)

    # --- the dispatcher: a pin record plus a helper that fails or is missing refuses (round 1, finding 4) ---
    # The dispatcher's own Get-DispatcherLiveEngine, run beside a helper stand-in; "no pin" would silently fall back.
    $dispatcherPath = Join-Path $scriptsDir 'specrew-hook-dispatcher.ps1'
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($dispatcherPath, [ref]$null, [ref]$null)
    $functionText = @($ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -in @('Get-DispatcherLiveEngine', 'Write-DispatcherWarn') }, $false) | ForEach-Object { $_.Extent.Text }) -join "`n"
    $harnessText = "param([string]`$ProjectRoot)`n`$script:Banner = '[test]'`n$functionText`n`$r = Get-DispatcherLiveEngine -ProjectRoot `$ProjectRoot`nif (`$null -eq `$r) { 'none' } elseif ([bool]`$r.Refused) { 'refused' } else { 'resolved' }"
    $broken = Join-Path $work 'helper-throws'; $absent = Join-Path $work 'helper-absent'
    New-Item -ItemType Directory -Path $broken, $absent | Out-Null
    Set-Content -LiteralPath (Join-Path $broken 'live-engine-resolution.ps1') -Value "throw 'helper broken'"
    foreach ($dir in @($broken, $absent)) { Set-Content -LiteralPath (Join-Path $dir 'harness.ps1') -Value $harnessText }
    $d = New-StubProject 'dispatcher'
    $outcome = { param([string]$Dir) ((& pwsh -NoProfile -File (Join-Path $Dir 'harness.ps1') -ProjectRoot $d 2>$null) | Select-Object -Last 1) }
    Assert-True ((& $outcome $broken) -eq 'none') 'dispatcher, no record, helper fails: no pin (today''s resolution)'
    Set-PinRecord -ProjectRoot $d -Path $pinPath -Commit $pinCommit
    Assert-True ((& $outcome $broken) -eq 'refused') 'dispatcher, pin record, helper fails: refuses'
    Assert-True ((& $outcome $absent) -eq 'refused') 'dispatcher, pin record, helper missing: refuses'

    # --- the pin script: Create and Advance refuse a pin with local changes (round 1, finding 3) ---
    $pinScript = Join-Path $repoRoot 'scripts/internal/live-engine-pin.ps1'
    $pinProject = Join-Path $work 'pin-project'
    New-Item -ItemType Directory -Path $pinProject | Out-Null
    Invoke-Git @('-C', $pinProject, 'init', '-q')
    Set-Content -LiteralPath (Join-Path $pinProject 'engine.txt') -Value 'one'
    Invoke-Git @('-C', $pinProject, 'add', '-A')
    Invoke-Git @('-C', $pinProject, '-c', 'user.email=t@example.invalid', '-c', 'user.name=t', 'commit', '-q', '-m', 'one')
    $commitOne = (& git -C $pinProject rev-parse HEAD).Trim()
    Set-Content -LiteralPath (Join-Path $pinProject 'engine.txt') -Value 'two'
    Invoke-Git @('-C', $pinProject, '-c', 'user.email=t@example.invalid', '-c', 'user.name=t', 'commit', '-q', '-am', 'two')
    $commitTwo = (& git -C $pinProject rev-parse HEAD).Trim()
    New-Item -ItemType Directory -Path (Join-Path $pinProject '.specrew/runtime') -Force | Out-Null
    $scriptPin = Join-Path $work 'script-pin'
    $invokePin = { param([string[]]$PinArgs) $out = (& pwsh -NoProfile -File $pinScript -ProjectRoot $pinProject @PinArgs 2>&1) -join "`n"; [pscustomobject]@{ Exit = $LASTEXITCODE; Output = $out } }
    $r = & $invokePin @('-Action', 'Create', '-Commit', $commitOne, '-PinPath', $scriptPin)
    Assert-True ($r.Exit -eq 0) ("pin script: Create pins a clean checkout (exit {0})" -f $r.Exit)
    $r = & $invokePin @('-Action', 'Create', '-Commit', $commitOne, '-PinPath', (Join-Path $work 'second-pin'))
    Assert-True ($r.Exit -ne 0 -and $r.Output -match 'already configured') 'pin script: Create refuses while a pin is configured'
    $r = & $invokePin @('-Action', 'Advance', '-Commit', $commitTwo)
    Assert-True ($r.Exit -eq 0 -and (& git -C $scriptPin rev-parse HEAD).Trim() -eq $commitTwo) 'pin script: Advance moves a clean pin'
    Set-Content -LiteralPath (Join-Path $scriptPin 'engine.txt') -Value 'edited inside the pin'
    $r = & $invokePin @('-Action', 'Advance', '-Commit', $commitOne)
    Assert-True ($r.Exit -ne 0 -and $r.Output -match 'local changes') 'pin script: Advance refuses a pin with an edited file'
    Assert-True ((& git -C $scriptPin rev-parse HEAD).Trim() -eq $commitTwo) 'pin script: a refused Advance leaves the pin where it was'
    Invoke-Git @('-C', $scriptPin, 'checkout', '--', 'engine.txt')
    Set-Content -LiteralPath (Join-Path $scriptPin 'stray.ps1') -Value '# untracked'
    $r = & $invokePin @('-Action', 'Advance', '-Commit', $commitOne)
    Assert-True ($r.Exit -ne 0 -and $r.Output -match 'local changes') 'pin script: Advance refuses a pin with an untracked file'
    Remove-Item -LiteralPath (Join-Path $scriptPin 'stray.ps1') -Force
    Invoke-Git @('-C', $pinProject, 'worktree', 'remove', '--force', $scriptPin)
    $r = & $invokePin @('-Action', 'Advance', '-Commit', $commitOne)
    # pwsh wraps a long error across lines, so the two parts are matched separately.
    Assert-True ($r.Exit -ne 0 -and $r.Output -match 'cannot be advanced' -and $r.Output -match 'pin-missing') 'pin script: Advance on a missing pin says so plainly'

    # --- the pin script: Remove clears a record whose folder is not a worktree (round 2, finding 3) ---
    $plainFolder = Join-Path $work 'plain-folder'
    New-Item -ItemType Directory -Path $plainFolder | Out-Null
    Set-PinRecord -ProjectRoot $pinProject -Path $plainFolder -Commit $commitOne
    $r = & $invokePin @('-Action', 'Remove')
    Assert-True ($r.Exit -eq 0 -and -not (Test-Path -LiteralPath (Get-SpecrewLiveEngineRecordPath -ProjectRoot $pinProject))) ("pin script: Remove deletes the record when the folder is not a worktree (exit {0})" -f $r.Exit)
    Assert-True ((Test-Path -LiteralPath $plainFolder) -and $r.Output -match 'left in place') 'pin script: that folder is left on disk, and the output says so'

    # --- the pin script: a Create that fails its checks removes the checkout again (round 2, finding 2) ---
    # A post-checkout hook leaves an untracked file in the new checkout, so the clean check fails after the add.
    $hookFile = Join-Path $pinProject '.git/hooks/post-checkout'
    Set-Content -LiteralPath $hookFile -Value "#!/bin/sh`necho stray > untracked.txt" -NoNewline
    $failedPin = Join-Path $work 'failed-pin'
    $r = & $invokePin @('-Action', 'Create', '-Commit', $commitOne, '-PinPath', $failedPin)
    $listed = (& git -C $pinProject worktree list --porcelain) -join "`n"
    Assert-True ($r.Exit -ne 0 -and $r.Output -match 'local changes') 'pin script: Create refuses a checkout that is not clean'
    Assert-True (-not (Test-Path -LiteralPath $failedPin) -and $listed -notmatch [regex]::Escape(($failedPin -replace '\\', '/'))) 'pin script: the refused checkout is removed, folder and worktree entry'
    Assert-True (-not (Test-Path -LiteralPath (Get-SpecrewLiveEngineRecordPath -ProjectRoot $pinProject))) 'pin script: a refused Create writes no record'
    Remove-Item -LiteralPath $hookFile -Force
    $r = & $invokePin @('-Action', 'Create', '-Commit', $commitOne, '-PinPath', $failedPin)
    Assert-True ($r.Exit -eq 0) ("pin script: a retry after the refusal is not blocked by a leftover folder (exit {0})" -f $r.Exit)
    $null = & $invokePin @('-Action', 'Remove')

    # --- ProjectMetadataAccessor: a pin record plus a missing helper loads no store (round 2, finding 4) ---
    # The accessor alone, with no live-engine-resolution.ps1 three levels above it, reading a project whose own
    # .specify store would write the marker if it were loaded.
    $accessorHome = Join-Path $work 'accessor-only/scripts/internal/bootstrap'
    New-Item -ItemType Directory -Path $accessorHome -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot 'scripts/internal/bootstrap/ProjectMetadataAccessor.ps1') -Destination $accessorHome
    $a = Join-Path $work 'accessor-project'
    $storeDir = Join-Path $a '.specify/extensions/specrew-speckit/scripts'
    New-Item -ItemType Directory -Path $storeDir, (Join-Path $a '.specrew/runtime'), (Join-Path $a 'specs/001-pin-probe') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $storeDir 'workshop-authority-store.ps1') -Value @("Add-Content -LiteralPath `$env:SPECREW_TEST_MARKER -Value 'project-store'", 'function Test-SpecrewWorkshopAuthorityReceipt { return $true }')
    Set-Content -LiteralPath (Join-Path $a 'specs/001-pin-probe/lens-applicability.json') -Value (@{ workshop_intake = $true; confirmation_required = $true; agenda_status = 'pending-confirmation'; selected = @(); workshop = @{}; human_turn_contract = 'typed-turns-v1' } | ConvertTo-Json)
    $accessorReason = {
        if (Test-Path -LiteralPath $markerFile) { Remove-Item -LiteralPath $markerFile -Force }
        $env:SPECREW_TEST_MARKER = $markerFile
        try { $reason = (& pwsh -NoProfile -Command ". '$accessorHome/ProjectMetadataAccessor.ps1'; (Get-SpecrewWorkshopLifecycleState -ProjectRoot '$a' -FeatureRef '001-pin-probe').reason" 2>$null) | Select-Object -Last 1 }
        finally { Remove-Item Env:SPECREW_TEST_MARKER -ErrorAction SilentlyContinue }
        [pscustomobject]@{ Reason = [string]$reason; Loaded = (Test-Path -LiteralPath $markerFile) }
    }
    $res = & $accessorReason
    Assert-True ($res.Loaded) ("accessor, no record: the project's store loads as today (reason '{0}')" -f $res.Reason)
    Set-PinRecord -ProjectRoot $a -Path $pinPath -Commit $pinCommit
    $res = & $accessorReason
    Assert-True (-not $res.Loaded -and $res.Reason -eq 'workshop-human-turn-helper-missing') ("accessor, pin record, helper missing: no store loads (reason '{0}')" -f $res.Reason)
}
finally {
    try { & git -C $pinSource worktree remove --force $pinPath 2>&1 | Out-Null } catch { $null = $_ }
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}

if ($script:failCount -gt 0) { Write-Host "$script:failCount failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'All live-engine resolution checks passed.' -ForegroundColor Green
exit 0
