$ErrorActionPreference = 'Stop'

# F-174 iteration 010 (T002 fix F4b). DELIVERY floor for the reviewer finding: "no test proves the dispatcher
# hands the transcript_path to the handover provider". The dispatcher extracts transcript_path from the INTACT
# stdin event and re-passes it as a CLEAN --transcript-path arg to the provider. The launch primitive
# (Invoke-ProviderProcess) uses ProcessStartInfo.ArgumentList, which escapes each arg correctly - so a
# transcript_path CONTAINING A SPACE (the common `C:\Users\First Last\...` home) survives byte-for-byte; the
# old `Start-Process -ArgumentList` SPLIT it. This runs the REAL dispatcher against a temp project with a STUB
# provider that records every arg it received, and asserts the spaced path + the companion clean args
# (--source-event, --host-kind) all arrive intact. The dispatcher calls `exit`, so it MUST run as a child
# process (here launched via Start-Process - the TEST harness's choice; it passes the dispatcher only
# space-free args, so the harness's own launch is unaffected by the bug this test pins).

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

$dispatcher = (Resolve-Path "$PSScriptRoot/../../scripts/internal/specrew-hook-dispatcher.ps1").Path
$proj = Join-Path ([System.IO.Path]::GetTempPath()) ("f4b-" + [guid]::NewGuid().ToString('N'))
$scriptsDir = Join-Path $proj '.specify/extensions/specrew-speckit/scripts'
New-Item -ItemType Directory -Path (Join-Path $proj '.specrew/runtime') -Force | Out-Null
New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
try {
    # Minimal catalog: ONE stub inject provider on Stop (the real dispatcher resolves it under the deployed tree).
    $catalog = @{
        schema_version = '1'
        providers      = @(@{ id = 'stub'; kind = 'inject'; events = @('Stop'); order = 30; budget_share = 1.0; command = 'stub-capture.ps1' })
    } | ConvertTo-Json -Depth 6
    Set-Content -LiteralPath (Join-Path $proj '.specify/extensions/specrew-speckit/refocus-scopes.json') -Value $catalog -Encoding UTF8

    # Stub provider: record every arg it received to <projectRoot>/stub-args.json (cwd == the dispatcher's
    # -WorkingDirectory == projectRoot), emit nothing, exit 0.
    $stub = @'
$dest = Join-Path (Get-Location).Path 'stub-args.json'
ConvertTo-Json -InputObject (@($args)) -Compress | Set-Content -LiteralPath $dest -Encoding UTF8
exit 0
'@
    Set-Content -LiteralPath (Join-Path $scriptsDir 'stub-capture.ps1') -Value $stub -Encoding UTF8

    # The event the host hands the Stop hook on stdin - transcript_path CONTAINS SPACES (the hard case).
    $spaced = 'C:\Users\some user\.claude\projects\my proj\sess 1.jsonl'
    $event = @{ session_id = 'abc123'; source = 'stop'; transcript_path = $spaced } | ConvertTo-Json -Compress
    $eventFile = Join-Path $proj 'event.json'
    Set-Content -LiteralPath $eventFile -Value $event -Encoding UTF8 -NoNewline

    $outFile = Join-Path $proj 'd.out'; $errFile = Join-Path $proj 'd.err'
    $p = Start-Process -FilePath 'pwsh' `
        -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $dispatcher, '-Event', 'Stop', '-HostKind', 'claude') `
        -WorkingDirectory $proj -NoNewWindow -PassThru -Wait `
        -RedirectStandardInput $eventFile -RedirectStandardOutput $outFile -RedirectStandardError $errFile
    Assert-True ($p.ExitCode -eq 0) 'dispatcher exits 0 (fail-open doctrine holds)'

    $argsPath = Join-Path $proj 'stub-args.json'
    Assert-True (Test-Path -LiteralPath $argsPath) 'the stub provider was actually invoked (args captured)'
    $captured = @(Get-Content -LiteralPath $argsPath -Raw | ConvertFrom-Json)

    $ti = [array]::IndexOf($captured, '--transcript-path')
    Assert-True ($ti -ge 0) 'F4b: the dispatcher passed --transcript-path as a CLEAN arg'
    Assert-True ($captured[$ti + 1] -eq $spaced) 'F4b: the SPACED transcript_path survived ProcessStartInfo.ArgumentList delivery byte-for-byte'

    $si = [array]::IndexOf($captured, '--source-event')
    Assert-True ($si -ge 0 -and $captured[$si + 1] -eq 'Stop') 'F4b: the neutral --source-event Stop is delivered (clean arg)'
    $hi = [array]::IndexOf($captured, '--host-kind')
    Assert-True ($hi -ge 0 -and $captured[$hi + 1] -eq 'claude') 'F4b: --host-kind claude is delivered'

    Write-Host "`n=== DispatcherTranscriptDelivery.Tests.ps1: all assertions passed ===" -ForegroundColor Green
}
finally { Remove-Item -LiteralPath $proj -Recurse -Force -ErrorAction SilentlyContinue }
