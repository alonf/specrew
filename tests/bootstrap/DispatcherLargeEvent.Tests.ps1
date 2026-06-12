$ErrorActionPreference = 'Stop'

# F-174 iteration 010 (Prop-145 round-4, HIGH). FALSIFICATION floor for "large hook input prevents the handover
# provider from starting": codex's Stop event carries a last_assistant_message that can be 10s of KB. Passed as
# --event-json it exceeds the Windows command-line length limit, ProcessStartInfo refuses to launch, and the
# handover (so the conversation capture) silently never runs. Two fixes, both pinned here against the REAL
# dispatcher with a 60KB event:
#   2b - the dispatcher does NOT pass --event-json to the 'handover' provider (only the bounded clean args), so it
#        launches regardless of event size.
#   2a - a per-provider LAUNCH failure (a non-handover provider that DOES get the 60KB --event-json) is contained
#        (WARN + skip that provider), NOT propagated to abort the whole event - so later providers still run.

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

$dispatcher = (Resolve-Path "$PSScriptRoot/../../scripts/internal/specrew-hook-dispatcher.ps1").Path
$proj = Join-Path ([System.IO.Path]::GetTempPath()) ("lgevt-" + [guid]::NewGuid().ToString('N'))
$scriptsDir = Join-Path $proj '.specify/extensions/specrew-speckit/scripts'
New-Item -ItemType Directory -Path (Join-Path $proj '.specrew/runtime') -Force | Out-Null
New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
try {
    # bigstub (order 10, id != handover -> GETS --event-json -> 60KB blows the cmdline -> Start() throws).
    # handover (order 30, id == handover -> NO --event-json -> launches; records its args).
    $catalog = @{
        schema_version = '1'
        providers      = @(
            @{ id = 'bigstub'; kind = 'inject'; events = @('Stop'); order = 10; budget_share = 1.0; command = 'bigstub.ps1' }
            @{ id = 'handover'; kind = 'inject'; events = @('Stop'); order = 30; budget_share = 1.0; command = 'handover-stub.ps1' }
        )
    } | ConvertTo-Json -Depth 6
    Set-Content -LiteralPath (Join-Path $proj '.specify/extensions/specrew-speckit/refocus-scopes.json') -Value $catalog -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $scriptsDir 'bigstub.ps1') -Value 'Set-Content -LiteralPath (Join-Path (Get-Location).Path "bigstub-ran.txt") -Value "ran" -Encoding UTF8; exit 0' -Encoding UTF8
    $hstub = @'
ConvertTo-Json -InputObject (@($args)) -Compress | Set-Content -LiteralPath (Join-Path (Get-Location).Path 'handover-args.json') -Encoding UTF8
exit 0
'@
    Set-Content -LiteralPath (Join-Path $scriptsDir 'handover-stub.ps1') -Value $hstub -Encoding UTF8

    # 60KB last_assistant_message (well over the ~32767 Windows command-line ceiling) + a transcript_path.
    $event = @{ session_id = 'big'; source = 'stop'; transcript_path = 'C:\t\sess.jsonl'; last_assistant_message = ('A' * 60000) } | ConvertTo-Json -Compress
    Assert-True ($event.Length -gt 40000) 'the test event genuinely exceeds the Windows command-line ceiling'
    $eventFile = Join-Path $proj 'event.json'; Set-Content -LiteralPath $eventFile -Value $event -Encoding UTF8 -NoNewline
    $outFile = Join-Path $proj 'd.out'; $errFile = Join-Path $proj 'd.err'

    $p = Start-Process -FilePath 'pwsh' `
        -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $dispatcher, '-Event', 'Stop', '-HostKind', 'claude') `
        -WorkingDirectory $proj -NoNewWindow -PassThru -Wait `
        -RedirectStandardInput $eventFile -RedirectStandardOutput $outFile -RedirectStandardError $errFile

    Assert-True ($p.ExitCode -eq 0) 'dispatcher exits 0 even with a 60KB event (fail-open)'

    # 2a: bigstub got the 60KB --event-json and FAILED to launch, but that did NOT abort the event...
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $proj 'bigstub-ran.txt'))) '2a: the oversized-arg provider did NOT launch (too-long command line)'
    $stderr = (Get-Content -LiteralPath $errFile -Raw -ErrorAction SilentlyContinue) ?? ''
    Assert-True ($stderr -match 'failed to launch') '2a: the launch failure is surfaced as a WARN (not silent)'

    # ...the LATER handover provider still ran (containment), and got the bounded clean args, no --event-json.
    $argsPath = Join-Path $proj 'handover-args.json'
    Assert-True (Test-Path -LiteralPath $argsPath) '2a+2b: the handover provider STILL launched after the bigstub failure (containment), with a small argv'
    $captured = @(Get-Content -LiteralPath $argsPath -Raw | ConvertFrom-Json)
    Assert-True (-not ($captured -contains '--event-json')) '2b: the handover provider received NO --event-json (so a 60KB event cannot block its launch)'
    Assert-True ($captured -contains '--transcript-path') '2b: the handover provider still got --transcript-path (the capture route is intact)'
    $si = [array]::IndexOf($captured, '--source-event')
    Assert-True ($si -ge 0 -and $captured[$si + 1] -eq 'Stop') '2b: the handover provider still got --source-event Stop'

    Write-Host "`n=== DispatcherLargeEvent.Tests.ps1: all assertions passed ===" -ForegroundColor Green
}
finally { Remove-Item -LiteralPath $proj -Recurse -Force -ErrorAction SilentlyContinue }
