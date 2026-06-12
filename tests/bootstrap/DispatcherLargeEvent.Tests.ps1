$ErrorActionPreference = 'Stop'

# F-174 iteration 010 (Prop-145 round-4, HIGH). FALSIFICATION floor for "large hook input prevents the handover
# provider from starting": codex's Stop event carries a last_assistant_message that can be 10s of KB. Passed as
# --event-json it exceeds the Windows command-line length limit, ProcessStartInfo refuses to launch, and the
# handover (so the conversation capture) silently never runs.
#
# Two fixes, pinned against the REAL dispatcher:
#   2b (cross-platform) - the dispatcher does NOT pass --event-json to the 'handover' provider (only the bounded
#        clean args), so its argv is small regardless of event size. This is about which args the dispatcher
#        BUILDS, independent of any OS argv ceiling -> always asserted.
#   2a (Windows-only)   - a per-provider LAUNCH failure (a non-handover provider that DOES get the 60KB
#        --event-json) is contained (skip that provider) instead of aborting the whole event. The TRIGGER (the
#        ~32767-char Windows command-line ceiling) is OS-specific: POSIX ARG_MAX is far larger, so a 60KB argv
#        launches fine there and the "did not launch" premise does not hold. Guarded to $IsWindows.

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

$dispatcher = (Resolve-Path "$PSScriptRoot/../../scripts/internal/specrew-hook-dispatcher.ps1").Path

# Build a temp project (.specrew + a stub catalog) and run the REAL dispatcher with $EventObj on stdin.
# $Providers is an array of @{ id; order; command; body } - each body is written as a stub script. Returns the
# project root (inspect the stubs' side-effect files + d.err).
function Invoke-DispatcherScenario {
    param([object[]]$Providers, $EventObj)
    $proj = Join-Path ([System.IO.Path]::GetTempPath()) ("lgevt-" + [guid]::NewGuid().ToString('N'))
    $scriptsDir = Join-Path $proj '.specify/extensions/specrew-speckit/scripts'
    New-Item -ItemType Directory -Path (Join-Path $proj '.specrew/runtime') -Force | Out-Null
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    $catalog = @{ schema_version = '1'; providers = @($Providers | ForEach-Object { @{ id = $_.id; kind = 'inject'; events = @('Stop'); order = $_.order; budget_share = 1.0; command = $_.command } }) } | ConvertTo-Json -Depth 6
    Set-Content -LiteralPath (Join-Path $proj '.specify/extensions/specrew-speckit/refocus-scopes.json') -Value $catalog -Encoding UTF8
    foreach ($p in $Providers) { Set-Content -LiteralPath (Join-Path $scriptsDir $p.command) -Value $p.body -Encoding UTF8 }
    $eventFile = Join-Path $proj 'event.json'; Set-Content -LiteralPath $eventFile -Value ($EventObj | ConvertTo-Json -Compress) -Encoding UTF8 -NoNewline
    $outFile = Join-Path $proj 'd.out'; $errFile = Join-Path $proj 'd.err'
    $pr = Start-Process -FilePath 'pwsh' `
        -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $dispatcher, '-Event', 'Stop', '-HostKind', 'claude') `
        -WorkingDirectory $proj -NoNewWindow -PassThru -Wait `
        -RedirectStandardInput $eventFile -RedirectStandardOutput $outFile -RedirectStandardError $errFile
    return [pscustomobject]@{ Proj = $proj; ExitCode = $pr.ExitCode; Stderr = ((Get-Content -LiteralPath $errFile -Raw -ErrorAction SilentlyContinue) ?? '') }
}

# Stub that records the argv it received (the 'handover' provider).
$recordArgs = @'
ConvertTo-Json -InputObject (@($args)) -Compress | Set-Content -LiteralPath (Join-Path (Get-Location).Path 'handover-args.json') -Encoding UTF8
exit 0
'@

# --- 2b (ALWAYS): the handover provider is built WITHOUT --event-json, with the clean args. ---
$s1 = Invoke-DispatcherScenario -Providers @(@{ id = 'handover'; order = 30; command = 'handover-stub.ps1'; body = $recordArgs }) `
    -EventObj @{ session_id = 'n'; source = 'stop'; transcript_path = 'C:\t\sess.jsonl' }
try {
    Assert-True ($s1.ExitCode -eq 0) 'dispatcher exits 0'
    $argsPath = Join-Path $s1.Proj 'handover-args.json'
    Assert-True (Test-Path -LiteralPath $argsPath) 'the handover provider launched'
    $captured = @(Get-Content -LiteralPath $argsPath -Raw | ConvertFrom-Json)
    Assert-True (-not ($captured -contains '--event-json')) '2b: the handover provider receives NO --event-json (so a large event cannot block its launch)'
    Assert-True ($captured -contains '--transcript-path') '2b: the handover provider still gets --transcript-path (capture route intact)'
    $si = [array]::IndexOf($captured, '--source-event')
    Assert-True ($si -ge 0 -and $captured[$si + 1] -eq 'Stop') '2b: the handover provider still gets --source-event Stop'
}
finally { Remove-Item -LiteralPath $s1.Proj -Recurse -Force -ErrorAction SilentlyContinue }

# --- 2a (WINDOWS-ONLY): a non-handover provider that gets the 60KB --event-json fails to launch but is CONTAINED;
#     the later handover provider still runs. The trigger is the Windows command-line ceiling. ---
if ($IsWindows) {
    $bigEvent = @{ session_id = 'big'; source = 'stop'; transcript_path = 'C:\t\sess.jsonl'; last_assistant_message = ('A' * 60000) }
    Assert-True (($bigEvent | ConvertTo-Json -Compress).Length -gt 40000) 'the test event genuinely exceeds the Windows command-line ceiling'
    $s2 = Invoke-DispatcherScenario -Providers @(
        @{ id = 'bigstub'; order = 10; command = 'bigstub.ps1'; body = 'Set-Content -LiteralPath (Join-Path (Get-Location).Path "bigstub-ran.txt") -Value "ran" -Encoding UTF8; exit 0' }
        @{ id = 'handover'; order = 30; command = 'handover-stub.ps1'; body = $recordArgs }
    ) -EventObj $bigEvent
    try {
        Assert-True ($s2.ExitCode -eq 0) '2a: dispatcher exits 0 even with a 60KB event (fail-open)'
        Assert-True (-not (Test-Path -LiteralPath (Join-Path $s2.Proj 'bigstub-ran.txt'))) '2a: the oversized-arg provider did NOT launch (too-long command line)'
        Assert-True ($s2.Stderr -match 'failed to launch') '2a: the launch failure is surfaced as a single informative WARN'
        Assert-True (([regex]::Matches($s2.Stderr, 'failed to launch')).Count -eq 1) '2a: exactly ONE WARN for the launch failure (no double-WARN)'
        Assert-True (Test-Path -LiteralPath (Join-Path $s2.Proj 'handover-args.json')) '2a: the LATER handover provider still launched after the bigstub failure (containment, not abort)'
    }
    finally { Remove-Item -LiteralPath $s2.Proj -Recurse -Force -ErrorAction SilentlyContinue }
}
else {
    Write-Host 'SKIP: 2a launch-failure-containment scenario (relies on the Windows command-line ceiling; POSIX ARG_MAX is far larger)' -ForegroundColor Yellow
}

Write-Host "`n=== DispatcherLargeEvent.Tests.ps1: all assertions passed ===" -ForegroundColor Green
