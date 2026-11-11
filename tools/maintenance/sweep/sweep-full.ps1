# Feature 203 sweep driver (crew maintenance tooling; not packaged in Specrew.psd1). Committed 2026-11-09 from the session
# scratchpad, where it was written for the maintainer's DRIFT-045 item 2 and DRIFT-050 rule: every suite and lane it starts
# gets ONE redirected home (SPECREW_USER_HOME_OVERRIDE, set once here and inherited by every child process), and the real
# home's hook files are copied before and compared after. Reports, home snapshots and checkouts are written under the temp
# folder (specrew-sweeps), never into the repository. Launch from PowerShell, not Git Bash (GNU tar on PATH breaks a suite).
#
# Maintainer rulings 2026-11-11 (DRIFT-055 and the index.lock trace):
#   - the sweep runs every suite the sign-off lanes name at the swept revision, with the list given (-SkipSignoffSuites
#     for a targeted check, which then cannot close a task);
#   - each suite is timed on the wall clock and on a clock that stops while the machine sleeps; one that spanned standby
#     is marked "spanned standby, rerun", never pass or fail, and a sweep with one cannot close a task. Windows' standby
#     log for the sweep's window is printed as supporting evidence;
#   - while the sweep runs it holds a keep-awake request with Windows (system required; the display may sleep), released
#     in the finally block below, on error and on cancel too. Self-test: sweep-driver.tests.ps1.
# Usage: pwsh -File tools/maintenance/sweep/sweep-full.ps1 -Rev <commit> [-List <file in this folder or a path>] [-SkipLanes] [-SkipSignoffSuites]
param([string]$Repo = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path, [Parameter(Mandatory)][string]$Rev, [string]$List = 't008iii-list.txt', [switch]$SkipLanes,
    [switch]$SkipSignoffSuites, [int]$SuiteTimeoutSeconds = 900, [int]$Throttle = 6, [string]$Tag = '', [double]$StandbyThresholdSeconds = 20,
    # Self-test only: hold the keep-awake request this long, then return without sweeping (sweep-driver.tests.ps1, case 6).
    [int]$SelfTestHoldSeconds = 0)
$ErrorActionPreference = 'Stop'
$tools = Split-Path -Parent $PSCommandPath
. (Join-Path $tools 'sweep-support.ps1')

$keepAwake = Enter-SweepKeepAwake -Reason ("Specrew sweep of {0}{1}" -f $Rev, $Tag)
try {
    if ($SelfTestHoldSeconds -gt 0) { Start-Sleep -Seconds $SelfTestHoldSeconds; return }
    $resolved = ([string](& git -C $Repo rev-parse --verify --quiet ("{0}^{{commit}}" -f $Rev) 2>$null)).Trim()
    if ([string]::IsNullOrWhiteSpace($resolved)) { throw "No commit '$Rev' in $Repo; nothing was swept." }
    $sweepStarted = Get-Date
    $awakeStarted = Get-SweepAwakeSeconds

    # Outputs go outside the repository, so a sweep never dirties the tree it is checking.
    $scratch = Join-Path ([IO.Path]::GetTempPath()) 'specrew-sweeps'
    New-Item -ItemType Directory -Force -Path $scratch | Out-Null
    $listPath = if (Test-Path -LiteralPath $List) { (Resolve-Path -LiteralPath $List).Path } else { Join-Path $tools $List }
    function Assert-NotSessionTree([string]$Path) { $p = [IO.Path]::GetFullPath($Path).TrimEnd('\') + '\'; $s = [IO.Path]::GetFullPath($Repo).TrimEnd('\') + '\'; if ($s.StartsWith($p, [StringComparison]::OrdinalIgnoreCase)) { throw "refusing to remove ${Path}: it is the session's worktree or a parent of it (B5F-035)" } }
    $homeHookFiles = @(
        "$env:USERPROFILE\.claude\settings.json", "$env:USERPROFILE\.claude\settings.local.json",
        "$env:USERPROFILE\.codex\hooks.json", "$env:USERPROFILE\.codex\config.toml",
        "$env:USERPROFILE\.copilot\config.json", "$env:USERPROFILE\.copilot\hooks\specrew-refocus.json", "$env:USERPROFILE\.cursor\hooks.json", "$env:USERPROFILE\.gemini\settings.json")
    function Get-HomeSnapshot {
        foreach ($f in $homeHookFiles) {
            if (Test-Path -LiteralPath $f) { [pscustomobject]@{ File = $f; Hash = (Get-FileHash -LiteralPath $f).Hash; Written = (Get-Item -LiteralPath $f).LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss') } }
            else { [pscustomobject]@{ File = $f; Hash = 'absent'; Written = '' } }
        }
    }
    function Get-HomeChanges($From, $To) {
        foreach ($t in $To) {
            $f = $From | Where-Object File -eq $t.File
            if ($null -eq $f -or $f.Hash -ne $t.Hash) { '  {0} (written {1} local)' -f $t.File, $(if ($t.Written) { $t.Written } else { 'removed' }) }
        }
    }

    # The suites to run: the list given, then every suite the sign-off lanes name at this revision (DRIFT-055).
    $suiteList = @(Get-SweepSuiteList -ListPath $listPath -Repo $Repo -Rev $Rev -SkipSignoffSuites:$SkipSignoffSuites)
    $givenCount = @(Get-Content -LiteralPath $listPath | Where-Object { $_.Trim() }).Count
    $combinedList = Join-Path $scratch ("list-{0}{1}.txt" -f $Rev, $Tag)
    Set-Content -LiteralPath $combinedList -Value $suiteList -Encoding UTF8

    # B5F-032: every suite and lane this sweep starts gets one redirected home, set once here. The deployer honours it
    # (GetFolderPath ignores USERPROFILE); the real-home check below stays, and now checks the runner as well.
    $fakeHome = Join-Path ([IO.Path]::GetTempPath()) ('sweep-home-' + $Rev)
    if (Test-Path -LiteralPath $fakeHome) { Remove-Item -LiteralPath $fakeHome -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $fakeHome | Out-Null
    $env:SPECREW_USER_HOME_OVERRIDE = $fakeHome

    $before = @(Get-HomeSnapshot)
    # Changes made between the previous sweep and this one are reported too, not only changes during this sweep.
    $lastAfterPath = Join-Path $scratch 'home-last-after.json'
    $hadPrevious = Test-Path -LiteralPath $lastAfterPath
    $sincePrevious = @(if ($hadPrevious) { Get-HomeChanges (Get-Content -LiteralPath $lastAfterPath -Raw | ConvertFrom-Json) $before })
    $keep = Join-Path $scratch "home-before-$Rev"; New-Item -ItemType Directory -Force -Path $keep | Out-Null
    foreach ($f in $homeHookFiles) { if (Test-Path -LiteralPath $f) { Copy-Item -LiteralPath $f -Destination (Join-Path $keep (($f -replace '[:\\]', '_'))) -Force } }

    $neighbourPath = Join-Path $scratch "neighbour-$Rev$Tag.txt"
    & pwsh -NoProfile -File (Join-Path $tools 'sweep-list.ps1') -Repo $Repo -Rev $Rev -ListFile $combinedList -SuiteTimeoutSeconds $SuiteTimeoutSeconds -Throttle $Throttle -StandbyThresholdSeconds $StandbyThresholdSeconds *> $neighbourPath

    $co = Join-Path ([IO.Path]::GetTempPath()) ('lanes-' + $Rev)
    $lanes = @(if (-not $SkipLanes) { 'iteration-001-governance-203', 'f203-i001-suites', 'f203-i001-t008-suites', 'f203-i001-validator-scope', 'f203-i001-carried', 'f199-class-guards-a', 'f199-class-guards-b' })
    $out = @("lanes: " + ($lanes -join ', '))
    $lanesStandby = ''
    if ($lanes.Count -gt 0) {
        if (Test-Path $co) { Assert-NotSessionTree $co; & git -C $Repo worktree remove --force $co 2>&1 | Out-Null }
        & git -C $Repo worktree add -q --detach $co $Rev
        try {
            $lanesWall0 = Get-Date; $lanesAwake0 = Get-SweepAwakeSeconds
            $out += @(& (Join-Path $tools 'run-lane.ps1') -Dir $co -LaneIds $lanes 2>&1 | ForEach-Object { [string]$_ })
            $lanesWall = ((Get-Date) - $lanesWall0).TotalSeconds; $lanesAwake = (Get-SweepAwakeSeconds) - $lanesAwake0
            $lanesStandby = Get-SweepStandbyVerdict -WallSeconds $lanesWall -AwakeSeconds $lanesAwake -ThresholdSeconds $StandbyThresholdSeconds
            $out += ('lanes: wall {0} s, awake {1} s{2}' -f [int]$lanesWall, [int]$lanesAwake, $(if ($lanesStandby) { ' ' + $lanesStandby } else { '' }))
        }
        finally { Assert-NotSessionTree $co; & git -C $Repo worktree remove --force $co 2>&1 | Out-Null }
    }
    $after = @(Get-HomeSnapshot)
    $during = @(Get-HomeChanges $before $after)
    $after | ConvertTo-Json | Set-Content -LiteralPath $lastAfterPath -Encoding UTF8
    $out += $(if ($hadPrevious) { 'real home hook files changed since the previous sweep, before this one started: {0}' -f $sincePrevious.Count } else { 'real home hook files changed since the previous sweep: no previous sweep recorded' })
    $out += $sincePrevious
    $out += 'real home hook files changed during this sweep: {0}' -f $during.Count
    $out += $during
    $out += 'files the suites wrote to the redirected home: {0}' -f @(Get-ChildItem -LiteralPath $fakeHome -Recurse -File -ErrorAction SilentlyContinue).Count
    $out += @(Get-ChildItem -LiteralPath $fakeHome -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 12 | ForEach-Object { '  ' + $_.FullName.Substring($fakeHome.Length) })

    # Whether this sweep can close a task: every suite counted (none spanned standby), the lanes did not span standby, and
    # the sign-off-lane suites were included.
    $neighbour = @(if (Test-Path -LiteralPath $neighbourPath) { Get-Content -LiteralPath $neighbourPath })
    $suitesValid = @($neighbour | Where-Object { $_ -like '--- valid to close a task: yes*' }).Count -eq 1
    $wallTotal = ((Get-Date) - $sweepStarted).TotalSeconds; $awakeTotal = (Get-SweepAwakeSeconds) - $awakeStarted
    $out += ('sweep: wall {0} s, awake {1} s; keep-awake: {2}' -f [int]$wallTotal, [int]$awakeTotal, [string]$keepAwake.Detail)
    $standbyEvents = @(Get-SweepStandbyEvents -From $sweepStarted -To (Get-Date))
    $out += ('Windows standby log during the sweep (supporting evidence): {0} event(s)' -f $standbyEvents.Count)
    $out += $standbyEvents
    $out += $(if ($SkipSignoffSuites) { 'sign-off-lane suites: skipped (-SkipSignoffSuites)' } else { 'sign-off-lane suites: included ({0} suites run; {1} from the list given)' -f $suiteList.Count, $givenCount })
    $reasons = @()
    if (-not $suitesValid) { $reasons += 'a suite spanned standby, or the suite run reported no result' }
    if ($lanesStandby) { $reasons += 'the lanes spanned standby' }
    if ($SkipSignoffSuites) { $reasons += 'the sign-off-lane suites were skipped' }
    $out += $(if ($reasons.Count -eq 0) { 'valid to close a task: yes, if every suite and lane passed' } else { 'valid to close a task: no (' + ($reasons -join '; ') + ')' })
    $out | Set-Content -LiteralPath (Join-Path $scratch "sweep-$Rev$Tag.txt") -Encoding UTF8
    '--- neighbours'; $neighbour | Select-Object -Last 4
    '--- lanes'; $out
}
finally { Exit-SweepKeepAwake -Request $keepAwake }
