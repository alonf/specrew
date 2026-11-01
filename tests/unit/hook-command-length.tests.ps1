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
    param([string]$Command, [hashtable]$Environment)
    $saved = @{}
    foreach ($key in $Environment.Keys) { $saved[$key] = [Environment]::GetEnvironmentVariable($key); [Environment]::SetEnvironmentVariable($key, $Environment[$key]) }
    try {
        $psi = [Diagnostics.ProcessStartInfo]::new('cmd.exe')
        $psi.Arguments = '/d /s /c "' + $Command + '"'
        $psi.UseShellExecute = $false; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.RedirectStandardInput = $true
        $p = [Diagnostics.Process]::Start($psi)
        $p.StandardInput.Close()
        $out = $p.StandardOutput.ReadToEndAsync(); $err = $p.StandardError.ReadToEndAsync()
        if (-not $p.WaitForExit(120000)) { $p.Kill(); throw 'cmd.exe run timed out' }
        return [pscustomobject]@{ Exit = $p.ExitCode; Text = ($out.Result + "`n" + $err.Result) }
    }
    finally { foreach ($key in $saved.Keys) { [Environment]::SetEnvironmentVariable($key, $saved[$key]) } }
}

try {
    $hosts = @(Get-ChildItem -Path (Join-Path $repoRoot 'hosts') -Directory | Where-Object {
            $manifestPath = Join-Path $_.FullName 'host.psd1'
            (Test-Path -LiteralPath $manifestPath) -and $null -ne (Import-PowerShellDataFile -LiteralPath $manifestPath).RefocusHookBindings
        } | ForEach-Object { $_.Name })
    Assert-True ($hosts.Count -ge 5) ("every host with hook bindings is measured ({0})" -f ($hosts -join ', '))

    $claudeStop = $null; $encodedLauncher = $null
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
        if ($hostKind -eq 'antigravity') { $antigravityHome = $fakeHome; $encodedLauncher = @($own | Where-Object { $_.Command -match 'EncodedCommand' } | Select-Object -First 1)[0].Command }
    }

    # The real path: through cmd.exe, Claude's Stop command decodes and runs its generated launcher. This scratch
    # project has no dispatcher, so the launcher's own "not found" refusal is the proof that pwsh ran it.
    $r = Invoke-ThroughCmd -Command $claudeStop -Environment @{ CLAUDE_PROJECT_DIR = $claudeProject; SPECREW_MODULE_PATH = $null }
    Assert-True ($r.Text -notmatch 'not properly encoded' -and $r.Text -match 'Specrew dispatcher not found') ("claude: the Stop command runs through cmd.exe and reaches its launcher (exit {0})" -f $r.Exit)
    $r = Invoke-ThroughCmd -Command $encodedLauncher -Environment @{ USERPROFILE = $antigravityHome; HOME = $antigravityHome; SPECREW_MODULE_PATH = $null }
    Assert-True ($r.Text -notmatch 'not properly encoded' -and $r.Exit -eq 0) ("antigravity: the encoded launcher command runs through cmd.exe (exit {0})" -f $r.Exit)

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

if ($script:failCount -gt 0) { Write-Host "$script:failCount failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'All hook command length checks passed.' -ForegroundColor Green
exit 0
