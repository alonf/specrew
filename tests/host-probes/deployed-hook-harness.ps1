# Shared harness: deploy Specrew's real hooks into a temp project and run a deployed hook command exactly as a host
# would, with a payload's raw bytes on stdin. Probe providers record whether anything ran.
#
# Dot-sourced by tests/unit/host-binding-match.tests.ps1 (recorded payloads) and
# tests/host-probes/host-payload-capture-probe.ps1 (payloads the probe has just captured from the real hosts).
# The caller sets $repoRoot before dot-sourcing.
Set-StrictMode -Version Latest

$script:HarnessDeployer = Join-Path $repoRoot 'scripts\internal\deploy-refocus-hooks.ps1'
$script:HarnessDispatcherSource = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\specrew-hook-dispatcher.ps1'

$script:HarnessProbeBody = @'
# Probe provider: records the arguments the dispatcher hands a provider, then stays silent.
$out = Join-Path (Get-Location).Path '.probe'
[IO.Directory]::CreateDirectory($out) | Out-Null
$name = '{0}-{1}.json' -f (Split-Path -Leaf $PSCommandPath), [guid]::NewGuid().ToString('N')
[IO.File]::WriteAllText((Join-Path $out $name), (ConvertTo-Json -InputObject @($args | ForEach-Object { [string]$_ }) -Compress), [Text.UTF8Encoding]::new($false))
exit 0
'@

function New-TurnRecordProject {
    param([string]$HostKind)
    $base = [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) ('trc-{0}-{1}' -f $HostKind, [guid]::NewGuid().ToString('N').Substring(0, 8))))
    $proj = Join-Path $base 'proj'
    $userHome = Join-Path $base 'home'
    $scripts = Join-Path $proj '.specify\extensions\specrew-speckit\scripts'
    New-Item -ItemType Directory -Force -Path (Join-Path $proj '.specrew\runtime'), $scripts, $userHome | Out-Null
    Copy-Item -LiteralPath $script:HarnessDispatcherSource -Destination (Join-Path $scripts 'specrew-hook-dispatcher.ps1')
    # The probes take the shipped providers' file names, so the dispatcher's provider-keyed argument rules apply.
    foreach ($leaf in 'specrew-handover-provider.ps1', 'specrew-bootstrap-provider.ps1') {
        [IO.File]::WriteAllText((Join-Path $scripts $leaf), $script:HarnessProbeBody, [Text.UTF8Encoding]::new($false))
    }
    $catalog = [ordered]@{
        schema_version = '1'
        providers      = @(
            [ordered]@{ id = 'bootstrap'; kind = 'inject'; events = @('SessionStart', 'PreInvocation'); order = 20; budget_share = 0.5; command = 'specrew-bootstrap-provider.ps1' },
            [ordered]@{ id = 'handover'; kind = 'inject'; events = @('UserPromptSubmit', 'PreInvocation', 'Stop', 'agentStop'); order = 30; budget_share = 0.5; command = 'specrew-handover-provider.ps1' }
        )
    }
    [IO.File]::WriteAllText((Join-Path $proj '.specify\extensions\specrew-speckit\refocus-scopes.json'), ($catalog | ConvertTo-Json -Depth 6), [Text.UTF8Encoding]::new($false))
    $deployLog = Join-Path $base 'deploy.log'
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $script:HarnessDeployer -ProjectPath $proj -HostKind $HostKind -UserHomeOverride $userHome *> $deployLog
    if ($LASTEXITCODE -ne 0) { throw ("deployer failed for {0}: {1}" -f $HostKind, (Get-Content -LiteralPath $deployLog -Raw)) }
    return [pscustomobject]@{ Base = $base; Project = $proj; Home = $userHome; HostKind = $HostKind }
}

function Get-DeployedHookCommand {
    param($Fixture, [string]$NativeEvent)
    switch ($Fixture.HostKind) {
        'claude' {
            $cfg = Get-Content -LiteralPath (Join-Path $Fixture.Project '.claude\settings.local.json') -Raw | ConvertFrom-Json
            return [string]$cfg.hooks.$NativeEvent[0].hooks[0].command
        }
        'codex' {
            $cfg = Get-Content -LiteralPath (Join-Path $Fixture.Home '.codex\hooks.json') -Raw | ConvertFrom-Json
            return [string]$cfg.hooks.$NativeEvent[0].hooks[0].command
        }
        'copilot' {
            $cfg = Get-Content -LiteralPath (Join-Path $Fixture.Home '.copilot\hooks\specrew-refocus.json') -Raw | ConvertFrom-Json
            return [string]$cfg.hooks.$NativeEvent[0].powershell
        }
    }
    throw "no deployed command reader for $($Fixture.HostKind)"
}

function Split-CommandLine {
    param([string]$CommandLine)
    $tokens = [System.Collections.Generic.List[string]]::new()
    foreach ($m in [regex]::Matches($CommandLine, '"((?:[^"\\]|\\.)*)"|(\S+)')) {
        if ($m.Groups[1].Success) { $tokens.Add($m.Groups[1].Value.Replace('\"', '"')) } else { $tokens.Add($m.Groups[2].Value) }
    }
    return $tokens.ToArray()
}

function Invoke-DeployedHook {
    # Runs the deployed command exactly as the host would: stdin carries the payload's raw bytes, and every
    # project-root variable any host manifest names is pinned to the temp project, so a payload can never
    # resolve to a real (governed) project from this process's environment.
    param($Fixture, [string]$NativeEvent, [byte[]]$StdinBytes)
    Get-ChildItem -LiteralPath (Join-Path $Fixture.Project '.probe') -ErrorAction SilentlyContinue | Remove-Item -Force
    $argv = Split-CommandLine -CommandLine (Get-DeployedHookCommand -Fixture $Fixture -NativeEvent $NativeEvent)
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $argv[0]
    foreach ($a in $argv[1..($argv.Count - 1)]) { $psi.ArgumentList.Add($a) }
    $psi.WorkingDirectory = $Fixture.Project
    $psi.UseShellExecute = $false
    # Hosts spawn hooks with a hidden console, so the hook's console input code page is the OEM one (measured
    # ibm437 on every validated host, research.md T001). Without a console .NET falls back to UTF-8 and the
    # decoding defect is invisible, so the harness spawns the same way the hosts do.
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    foreach ($var in 'CLAUDE_PROJECT_DIR', 'CURSOR_PROJECT_DIR', 'COPILOT_PROJECT_DIR') { $psi.Environment[$var] = $Fixture.Project }
    $psi.Environment.Remove('SPECREW_REFOCUS_DISABLE') | Out-Null
    $psi.Environment.Remove('SPECREW_DISABLE_EVENTS') | Out-Null
    $proc = [System.Diagnostics.Process]::Start($psi)
    $outTask = $proc.StandardOutput.ReadToEndAsync()
    $errTask = $proc.StandardError.ReadToEndAsync()
    $proc.StandardInput.BaseStream.Write($StdinBytes, 0, $StdinBytes.Length)
    $proc.StandardInput.Close()
    if (-not $proc.WaitForExit(90000)) { $proc.Kill($true); throw "deployed hook timed out ($($Fixture.HostKind) $NativeEvent)" }
    $null = $outTask.Result; $stderr = $errTask.Result
    $calls = @{}
    foreach ($f in @(Get-ChildItem -LiteralPath (Join-Path $Fixture.Project '.probe') -Filter *.json -ErrorAction SilentlyContinue)) {
        $leaf = $f.Name -replace '-[0-9a-f]{32}\.json$', ''
        $calls[$leaf] = @([IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8) | ConvertFrom-Json)
    }
    return [pscustomobject]@{ ExitCode = $proc.ExitCode; Calls = $calls; StdErr = $stderr }
}

function Clear-HarnessRuntime { param($Fixture) foreach ($d in '.probe', '.specrew\runtime\hook-health') { Get-ChildItem -LiteralPath (Join-Path $Fixture.Project $d) -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue } }
function Get-HarnessHealthFiles { param($Fixture) @(Get-ChildItem -LiteralPath (Join-Path $Fixture.Project '.specrew\runtime\hook-health') -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '^unrecognized-payload-' }) }
function Get-HarnessUnrecognizedLogs { param($Fixture) @(Get-ChildItem -LiteralPath (Join-Path $Fixture.Project '.specrew\runtime\hook-health') -File -Filter 'unrecognized-payload-*' -ErrorAction SilentlyContinue) }
function Get-HarnessRuntimeSnapshot {
    # Every file under the project's .specrew/runtime, with its length: a hook that stood down changes none of them.
    param($Fixture)
    $runtime = Join-Path $Fixture.Project '.specrew\runtime'
    return @(@(Get-ChildItem -LiteralPath $runtime -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object { '{0}|{1}' -f [IO.Path]::GetRelativePath($runtime, $_.FullName), $_.Length }) + '(runtime)' | Sort-Object)
}
