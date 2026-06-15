$ErrorActionPreference = 'Stop'

# F-174 iteration 010 (Invoke-ProviderProcess rewrite guard). The launch primitive was changed from
# `Start-Process -ArgumentList` to ProcessStartInfo.ArgumentList with ASYNCHRONOUS stdout/stderr reads
# (started before WaitForExit) to avoid a full-pipe deadlock. EVERY provider's stdout flows through this
# primitive - the bootstrap provider's ~54KB SessionStart payload, the refocus digests. A deadlock or a
# buffer-boundary truncation in the new async-read path would present EXACTLY as the "environmental" timeout
# we have been dismissing on the subprocess-heavy suites - so this is a CLEAN-ROOM check: drive the REAL
# dispatcher (which calls the REAL Invoke-ProviderProcess) against a stub that emits >100KB to stdout, and
# assert (a) NO truncation - the end canary past the 100KB mark survives - and (b) NO deadlock - it returns
# fast, far under the provider timeout. The dispatcher passes a Stop-event single-fragment payload through
# verbatim (Write-InjectionOutput default/non-PostToolUse = Write-Output), so its stdout == the captured
# provider stdout.

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

$dispatcher = (Resolve-Path "$PSScriptRoot/../../scripts/internal/specrew-hook-dispatcher.ps1").Path
$proj = Join-Path ([System.IO.Path]::GetTempPath()) ("lgout-" + [guid]::NewGuid().ToString('N'))
$scriptsDir = Join-Path $proj '.specify/extensions/specrew-speckit/scripts'
New-Item -ItemType Directory -Path (Join-Path $proj '.specrew/runtime') -Force | Out-Null
New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
try {
    $catalog = @{
        schema_version = '1'
        providers      = @(@{ id = 'bigstub'; kind = 'inject'; events = @('Stop'); order = 30; budget_share = 1.0; command = 'big-stub.ps1' })
    } | ConvertTo-Json -Depth 6
    Set-Content -LiteralPath (Join-Path $proj '.specify/extensions/specrew-speckit/refocus-scopes.json') -Value $catalog -Encoding UTF8

    # Stub: emit CANARY-START, a NON-ASCII canary (Hebrew RTL + a supplementary-plane emoji, built from code
    # points so the stub file's own encoding can't confound it), ~120KB of filler (well past any single pipe
    # buffer ~4-64KB), then CANARY-END as the LAST bytes. If the async reader truncates at a buffer boundary,
    # CANARY-END is the first thing lost; if StandardOutputEncoding=UTF8 is wrong, the non-ASCII canary corrupts.
    # The stub declares UTF-8 output, mirroring the real providers' SPECREW-UTF8-OUTPUT contract (the child half
    # of the UTF-8 round-trip; the dispatcher reads UTF-8 via StandardOutputEncoding). Without BOTH halves a
    # non-ASCII byte is mangled to '?' - this test pins the dispatcher's read half against a conformant provider.
    $stub = @'
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { $null = $_ }  # best-effort (mirrors the providers' fail-open encoding declaration)
$big = 'X' * 120000
$heb = [string][char]0x05E9 + [char]0x05DC + [char]0x05D5 + [char]0x05DD  # Hebrew "shalom" (RTL)
$emoji = [System.Char]::ConvertFromUtf32(0x1F680)                        # rocket (surrogate pair)
[Console]::Out.Write("CANARY-START`nNONASCII[" + $heb + $emoji + "]`n" + $big + "`nCANARY-END")
exit 0
'@
    Set-Content -LiteralPath (Join-Path $scriptsDir 'big-stub.ps1') -Value $stub -Encoding UTF8

    $event = @{ session_id = 'big1'; source = 'stop' } | ConvertTo-Json -Compress
    $eventFile = Join-Path $proj 'event.json'; Set-Content -LiteralPath $eventFile -Value $event -Encoding UTF8 -NoNewline
    $outFile = Join-Path $proj 'd.out'; $errFile = Join-Path $proj 'd.err'

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    # Default provider timeout is 20s; a deadlock would push elapsed toward that ceiling + a Kill.
    $p = Start-Process -FilePath 'pwsh' `
        -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $dispatcher, '-Event', 'Stop', '-HostKind', 'claude') `
        -WorkingDirectory $proj -NoNewWindow -PassThru -Wait `
        -RedirectStandardInput $eventFile -RedirectStandardOutput $outFile -RedirectStandardError $errFile
    $sw.Stop()

    Assert-True ($p.ExitCode -eq 0) 'dispatcher exits 0 on a large-stdout provider'
    $captured = (Get-Content -LiteralPath $outFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue) ?? ''
    Assert-True ($captured.Contains('CANARY-START')) 'large-stdout: the START of the payload is captured'
    Assert-True ($captured.Contains('CANARY-END')) 'large-stdout: NO TRUNCATION - the END canary past the 100KB mark survived the async read'
    Assert-True ($captured.Length -ge 120000) ("large-stdout: full payload length preserved (got {0} bytes)" -f $captured.Length)
    # UTF-8 round-trip (Prop-145 P3 / RTL scar tissue): the non-ASCII canary survives the ProcessStartInfo
    # StandardOutputEncoding=UTF8 read. Reconstruct the expected runes from code points (test-file-encoding-proof).
    $expectHeb = [string][char]0x05E9 + [char]0x05DC + [char]0x05D5 + [char]0x05DD
    $expectEmoji = [System.Char]::ConvertFromUtf32(0x1F680)
    Assert-True ($captured.Contains($expectHeb)) 'utf8: Hebrew (non-ASCII / RTL) round-trips through StandardOutputEncoding=UTF8 intact'
    Assert-True ($captured.Contains($expectEmoji)) 'utf8: a supplementary-plane emoji (surrogate pair) round-trips intact'
    # NO DEADLOCK: a clean async-read completes in ~the process-launch cost; a deadlocked pipe waits out the
    # full 20s provider timeout + Kill. 15s cleanly separates the two even under moderate load.
    Assert-True ($sw.Elapsed.TotalSeconds -lt 15) ("large-stdout: returned fast - no pipe deadlock ({0:N1}s, well under the 20s timeout)" -f $sw.Elapsed.TotalSeconds)

    Write-Host "`n=== DispatcherLargeStdout.Tests.ps1: all assertions passed ===" -ForegroundColor Green
}
finally { Remove-Item -LiteralPath $proj -Recurse -Force -ErrorAction SilentlyContinue }
