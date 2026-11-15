# Feature 203 T002 follow-up (DRIFT-016): every generated hook command, for every host, stays well under the
# Windows command-line limit. A host that starts its hook through cmd.exe cuts a command at 8,191 characters; the
# pin check made Claude's encoded command about 12,600 characters, pwsh got a truncated -EncodedCommand ("not properly
# encoded") and every Claude hook failed. The commands before the pin were already within about 100 characters of the
# limit, because the baked host binding rode inside the encoded text.
#
# The limit asserted here is half of cmd.exe's, so a later addition has room before it breaks anything. The cmd.exe
# runs below prove the real path: the short commands decode and run, and an over-length one fails the way the live
# hooks did, so this file would have caught it.
#
# Mutation that turns this file red: put the baked binding or the live-engine pin check back inline in an encoded
# command (deploy-refocus-hooks.ps1, Get-SpecrewHookCommand).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$deploy = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1'
$cmdExeLimit = 8191
$limit = [int][math]::Floor($cmdExeLimit / 2)

$work = Join-Path ([IO.Path]::GetTempPath()) ('hook-length-' + [guid]::NewGuid().ToString('N').Substring(0, 8))

# Iteration review round D, maintainer's batch (DRIFT-072 open item): THIS SUITE CHANGES NOTHING IN THE CHECKOUT IT RUNS IN.
# Run from this checkout with no working directory, the antigravity launcher started this project's own hook dispatcher
# (session start, 02:23:38 local on 2026-11-14), which rewrote iterations/001/state.md and tasks-progress.yml. Every command
# runs in its scratch project, and the checkout's changed and untracked files are the same, byte for byte, at the end.
function Get-CheckoutEntryHash {
    # What a listed path holds, without following it: '-' when absent, a link by its target text (a tracked link can point
    # at another machine, round E's preflight), a file by its content hash, and a file that cannot be read as unreadable
    # with the reason. Never throws: one unreadable entry must not stop the check.
    param([string]$Path)
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if ($null -eq $item) { return '-' }
    if (-not [string]::IsNullOrEmpty([string]$item.LinkTarget)) { return 'link:' + [string]$item.LinkTarget }
    if ($item.PSIsContainer) { return 'dir' }
    try { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash }
    catch { return 'unreadable:' + $_.Exception.GetType().Name + ':' + [string]$_.Exception.Message }
}
function Get-CheckoutState {
    param([string]$Root)
    $lines = @(& git -C $Root status --porcelain --untracked-files=all 2>$null)
    return @($lines | ForEach-Object {
            $rel = ([string]$_).Substring(3).Trim('"')
            '{0} {1}' -f ([string]$_), (Get-CheckoutEntryHash -Path (Join-Path $Root $rel))
        } | Sort-Object)
}
function Get-CheckoutChanges {
    # An empty snapshot is an empty list, never null: a clean checkout has nothing changed or untracked, and PowerShell
    # hands a function's empty output back as null, which Compare-Object refuses.
    param([AllowEmptyCollection()][object[]]$Before = @(), [AllowEmptyCollection()][object[]]$After = @())
    return @(Compare-Object -ReferenceObject @($Before) -DifferenceObject @($After) | ForEach-Object { '{0} {1}' -f $_.SideIndicator, $_.InputObject })
}
$checkoutBefore = @(Get-CheckoutState -Root $repoRoot)

# Guard (sweep of 671b2dfc, lane f203-i001-suites red): the check runs on a clean checkout, where the snapshot is empty.
$cleanCheckout = Join-Path ([IO.Path]::GetTempPath()) ('hook-length-clean-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
try {
    New-Item -ItemType Directory -Path $cleanCheckout -Force | Out-Null
    & git -C $cleanCheckout init -q 2>$null
    Set-Content -LiteralPath (Join-Path $cleanCheckout 'a.txt') -Value 'a' -Encoding UTF8
    & git -C $cleanCheckout -c user.email=t@t -c user.name=t add -A 2>$null
    & git -C $cleanCheckout -c user.email=t@t -c user.name=t commit -q -m clean 2>$null
    $cleanChanges = @(); $cleanError = ''
    try { $cleanChanges = @(Get-CheckoutChanges -Before @(Get-CheckoutState -Root $cleanCheckout) -After @(Get-CheckoutState -Root $cleanCheckout)) }
    catch { $cleanError = [string]$_.Exception.Message }
    Assert-True ($cleanError -eq '' -and $cleanChanges.Count -eq 0) ("the checkout check runs on a clean checkout and finds no change ({0})" -f $(if ($cleanError) { $cleanError } else { $cleanChanges.Count }))
    $cleanState = @()
    Set-Content -LiteralPath (Join-Path $cleanCheckout 'a.txt') -Value 'b' -Encoding UTF8
    $dirtyChanges = @(); $dirtyError = ''
    try { $dirtyChanges = @(Get-CheckoutChanges -Before $cleanState -After @(Get-CheckoutState -Root $cleanCheckout)) }
    catch { $dirtyError = [string]$_.Exception.Message }
    Assert-True ($dirtyError -eq '' -and $dirtyChanges.Count -eq 1 -and $dirtyChanges[0] -match 'a\.txt') ("and reports a file changed after a clean start, by name ({0})" -f $(if ($dirtyError) { $dirtyError } else { $dirtyChanges -join '; ' }))
}
finally { Remove-Item -LiteralPath $cleanCheckout -Recurse -Force -ErrorAction SilentlyContinue }

# Guard (iteration review round E, run-20261115-011232703-6c6475f7: its preflight's lane f203-i001-suites red). The
# review's frozen copy has the support folders deleted in the index and restored in the working tree only, so the status
# lists about 1,500 entries, among them a tracked symbolic link whose target is on another machine. The snapshot threw on
# that link. The check must complete over such a status, record a link by its target without following it, and record an
# entry it cannot read as unreadable instead of throwing.
$layoutCheckout = Join-Path ([IO.Path]::GetTempPath()) ('hook-length-layout-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
try {
    New-Item -ItemType Directory -Path (Join-Path $layoutCheckout 'support') -Force | Out-Null
    & git -C $layoutCheckout init -q 2>$null
    foreach ($i in 1..1100) { [IO.File]::WriteAllText((Join-Path $layoutCheckout ('support/f{0:d4}.txt' -f $i)), "entry $i") }
    & git -C $layoutCheckout -c user.email=t@t -c user.name=t add -A 2>$null
    & git -C $layoutCheckout -c user.email=t@t -c user.name=t commit -q -m layout 2>$null
    # The preflight's layout: deleted in the index, present in the working tree.
    & git -C $layoutCheckout rm -r -q --cached -- support 2>$null
    $missingTarget = Join-Path $layoutCheckout 'elsewhere/not-on-this-machine.json'
    $linkPath = Join-Path $layoutCheckout 'dangling.json'
    $linkMade = $true
    try { New-Item -ItemType SymbolicLink -Path $linkPath -Target $missingTarget -ErrorAction Stop | Out-Null }
    catch { $linkMade = $false; Write-Fail ("a symbolic link can be created for this case ({0})" -f $_.Exception.Message) }
    $listed = @(& git -C $layoutCheckout status --porcelain --untracked-files=all 2>$null).Count
    $layoutState = @(); $layoutError = ''
    $watch = [Diagnostics.Stopwatch]::StartNew()
    try { $layoutState = @(Get-CheckoutState -Root $layoutCheckout) }
    catch { $layoutError = [string]$_.Exception.Message }
    $watch.Stop()
    Assert-True ($layoutError -eq '' -and $listed -gt 1000 -and $layoutState.Count -eq $listed -and $watch.Elapsed.TotalSeconds -lt 60) ("the checkout check completes over a status of {0} entries with a dangling link, in {1:n1} s ({2})" -f $listed, $watch.Elapsed.TotalSeconds, $(if ($layoutError) { $layoutError } else { "$($layoutState.Count) recorded" }))
    if ($linkMade) {
        $linkEntry = @($layoutState | Where-Object { $_ -match 'dangling\.json' })
        Assert-True ($linkEntry.Count -eq 1 -and $linkEntry[0] -match 'link:' -and $linkEntry[0] -match 'not-on-this-machine\.json') ("a link is recorded by its target, not followed ({0})" -f ($linkEntry -join ''))
        $relinkError = ''; $relinkChanges = @()
        try {
            Remove-Item -LiteralPath $linkPath -Force
            New-Item -ItemType SymbolicLink -Path $linkPath -Target (Join-Path $layoutCheckout 'elsewhere/another.json') -ErrorAction Stop | Out-Null
            $relinkChanges = @(Get-CheckoutChanges -Before $layoutState -After @(Get-CheckoutState -Root $layoutCheckout))
        }
        catch { $relinkError = [string]$_.Exception.Message }
        Assert-True ($relinkError -eq '' -and $relinkChanges.Count -eq 2 -and @($relinkChanges | Where-Object { $_ -match 'dangling\.json' }).Count -eq 2) ("a link pointed elsewhere is reported, by name ({0})" -f $(if ($relinkError) { $relinkError } else { $relinkChanges -join '; ' }))
    }
    if ($IsWindows) {
        # A listed file another process holds open with no sharing cannot be read: recorded as unreadable, not thrown on.
        $held = Join-Path $layoutCheckout 'support/f0001.txt'
        $lock = [IO.File]::Open($held, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        $heldState = @(); $heldError = ''
        try { $heldState = @(Get-CheckoutState -Root $layoutCheckout) }
        catch { $heldError = [string]$_.Exception.Message }
        finally { $lock.Dispose() }
        $heldEntry = @($heldState | Where-Object { $_ -match '^\?\? support/f0001\.txt ' })
        Assert-True ($heldError -eq '' -and $heldEntry.Count -eq 1 -and $heldEntry[0] -match 'unreadable:') ("a listed entry that cannot be read is recorded as unreadable ({0})" -f $(if ($heldError) { $heldError } else { $heldEntry -join '' }))
    }
}
finally { Remove-Item -LiteralPath $layoutCheckout -Recurse -Force -ErrorAction SilentlyContinue }

function Get-CommandStrings {
    # Every command a host would run, from any hook settings shape: { command }, { bash, powershell }, nested groups.
    param($Node)
    if ($null -eq $Node) { return }
    if ($Node -is [System.Collections.IList]) { foreach ($item in $Node) { Get-CommandStrings -Node $item }; return }
    if ($Node -is [pscustomobject]) {
        foreach ($property in $Node.PSObject.Properties) {
            if ($property.Name -in @('command', 'bash', 'powershell') -and $property.Value -is [string]) { $property.Value }
            else { Get-CommandStrings -Node $property.Value }
        }
    }
}

function Invoke-ThroughCmd {
    # The command exactly as a host that uses cmd.exe would start it.
    # WorkingDirectory: the scratch project the command belongs to. Without it the command runs in this checkout and its
    # launcher finds this project's own dispatcher (DRIFT-072).
    param([string]$Command, [hashtable]$Environment, [string]$WorkingDirectory)
    $saved = @{}
    foreach ($key in $Environment.Keys) { $saved[$key] = [Environment]::GetEnvironmentVariable($key); [Environment]::SetEnvironmentVariable($key, $Environment[$key]) }
    try {
        $psi = [Diagnostics.ProcessStartInfo]::new('cmd.exe')
        $psi.Arguments = '/d /s /c "' + $Command + '"'
        if (-not [string]::IsNullOrWhiteSpace($WorkingDirectory)) { $psi.WorkingDirectory = $WorkingDirectory }
        $psi.UseShellExecute = $false; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.RedirectStandardInput = $true
        $p = [Diagnostics.Process]::Start($psi)
        $p.StandardInput.Close()
        $out = $p.StandardOutput.ReadToEndAsync(); $err = $p.StandardError.ReadToEndAsync()
        if (-not $p.WaitForExit(120000)) { $p.Kill(); throw 'cmd.exe run timed out' }
        $ranIn = if ([string]::IsNullOrWhiteSpace($psi.WorkingDirectory)) { (Get-Location).ProviderPath } else { $psi.WorkingDirectory }
        return [pscustomobject]@{ Exit = $p.ExitCode; Text = ($out.Result + "`n" + $err.Result); RanIn = [IO.Path]::GetFullPath($ranIn) }
    }
    finally { foreach ($key in $saved.Keys) { [Environment]::SetEnvironmentVariable($key, $saved[$key]) } }
}

try {
    $hosts = @(Get-ChildItem -Path (Join-Path $repoRoot 'hosts') -Directory | Where-Object {
            $manifestPath = Join-Path $_.FullName 'host.psd1'
            (Test-Path -LiteralPath $manifestPath) -and $null -ne (Import-PowerShellDataFile -LiteralPath $manifestPath).RefocusHookBindings
        } | ForEach-Object { $_.Name })
    Assert-True ($hosts.Count -ge 5) ("every host with hook bindings is measured ({0})" -f ($hosts -join ', '))

    $claudeStop = $null; $encodedLauncher = $null; $claudeProject = $null; $antigravityProject = $null
    foreach ($hostKind in $hosts) {
        # Each host deploys into its own project and home, so every command found is that host's.
        $project = Join-Path $work ($hostKind + '-project'); $fakeHome = Join-Path $work ($hostKind + '-home')
        New-Item -ItemType Directory -Path (Join-Path $project '.specrew'), $fakeHome -Force | Out-Null
        $out = & pwsh -NoProfile -File $deploy -ProjectPath $project -HostKind $hostKind -UserHomeOverride $fakeHome 2>&1
        Assert-True ($LASTEXITCODE -eq 0) ("{0}: deploy runs clean" -f $hostKind)
        $files = @(Get-ChildItem -Path $project, $fakeHome -Recurse -File -Force -Include *.json | Where-Object { $_.FullName -notmatch '[\\/]\.specrew[\\/]' })
        $commands = @(foreach ($file in $files) {
                $settings = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
                Get-CommandStrings -Node $settings | Where-Object { $_ -match 'specrew-hook|EncodedCommand' } | ForEach-Object { [pscustomobject]@{ File = $file.Name; Command = $_ } }
            })
        $own = $commands
        Assert-True ($own.Count -gt 0) ("{0}: its hook commands were found ({1})" -f $hostKind, $own.Count)
        $longest = ($own | ForEach-Object { $_.Command.Length } | Measure-Object -Maximum).Maximum
        Assert-True ($longest -le $limit) ("{0}: longest hook command is {1} characters, within {2} (half of cmd.exe's {3})" -f $hostKind, $longest, $limit, $cmdExeLimit)
        if ($hostKind -eq 'claude') { $claudeProject = $project; $claudeStop = (Get-Content -LiteralPath (Join-Path $project '.claude/settings.local.json') -Raw | ConvertFrom-Json).hooks.Stop[0].hooks[0].command }
        if ($hostKind -eq 'antigravity') { $antigravityProject = $project; $antigravityHome = $fakeHome; $encodedLauncher = @($own | Where-Object { $_.Command -match 'EncodedCommand' } | Select-Object -First 1)[0].Command }
    }

    # The real path: through cmd.exe, Claude's Stop command decodes and runs its generated launcher. This scratch
    # project has no dispatcher, so the launcher's own "not found" refusal is the proof that pwsh ran it.
    $r = Invoke-ThroughCmd -Command $claudeStop -Environment @{ CLAUDE_PROJECT_DIR = $claudeProject; SPECREW_MODULE_PATH = $null } -WorkingDirectory $claudeProject
    Assert-True ($r.Text -notmatch 'not properly encoded' -and $r.Text -match 'could not find its hook dispatcher') ("claude: the Stop command runs through cmd.exe and reaches its launcher (exit {0})" -f $r.Exit)
    Assert-True ($r.RanIn.StartsWith([IO.Path]::GetFullPath($work), [StringComparison]::OrdinalIgnoreCase)) ("claude: the Stop command ran in its scratch project, not in this checkout ({0})" -f $r.RanIn)
    $r = Invoke-ThroughCmd -Command $encodedLauncher -Environment @{ USERPROFILE = $antigravityHome; HOME = $antigravityHome; SPECREW_MODULE_PATH = $null } -WorkingDirectory $antigravityProject
    Assert-True ($r.Text -notmatch 'not properly encoded' -and $r.Exit -eq 0) ("antigravity: the encoded launcher command runs through cmd.exe (exit {0})" -f $r.Exit)
    Assert-True ($r.RanIn.StartsWith([IO.Path]::GetFullPath($work), [StringComparison]::OrdinalIgnoreCase)) ("antigravity: the encoded launcher command ran in its scratch project, not in this checkout ({0})" -f $r.RanIn)

    # Control: an encoded command over the limit fails through cmd.exe, as the live hooks did. The padding is ordinary
    # text: a long run of one repeated character is refused at process start on some machines, before cmd.exe runs.
    $words = ((Get-Content -LiteralPath $deploy -Raw) -replace '[^A-Za-z ]', ' ' -replace '\s+', ' ')
    $padded = "'" + $words.Substring(0, 4800) + "' | Out-Null"
    $tooLong = 'pwsh -NoProfile -EncodedCommand ' + [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($padded))
    $r = Invoke-ThroughCmd -Command $tooLong -Environment @{}
    Assert-True ($tooLong.Length -gt $cmdExeLimit -and $r.Exit -ne 0) ("control: a {0}-character encoded command fails through cmd.exe (exit {1})" -f $tooLong.Length, $r.Exit)
}
finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
$checkoutChanges = @(Get-CheckoutChanges -Before $checkoutBefore -After @(Get-CheckoutState -Root $repoRoot))
Assert-True ($checkoutChanges.Count -eq 0) ("nothing changed in the checkout this suite ran in ({0})" -f ($checkoutChanges -join '; '))

if ($script:failCount -gt 0) { Write-Host "$script:failCount failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'All hook command length checks passed.' -ForegroundColor Green
exit 0
