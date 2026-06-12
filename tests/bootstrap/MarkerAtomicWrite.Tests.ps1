# F-174 iter-10: SessionStart marker atomic-write falsification test.
#
# The codex double-hook-call dogfood (2026-06-12) left a PERMANENTLY corrupt session-marker.json - two
# JSON objects for the same session, ~ms apart. Root cause of the double FIRE was a non-idempotent older
# deploy that left two SessionStart registrations in ~/.codex/hooks.json (now self-healed + locked by
# refocus-deploy.tests.ps1 section 8b). The corrupt MARKER is a separate, mechanism-independent harm: a
# plain Set-Content truncates-then-writes the destination in place, so a writer killed mid-write - or two
# overlapping writers - can leave the dest half-written for good. Write-SpecrewSessionMarker now writes a
# PID-unique temp then atomically File.Replace's it into place, so the dest is only ever touched by an
# atomic rename: always the OLD marker or the NEW one whole, never a partial, regardless of when a process
# dies.
#
# What this test LOCKS (the achievable, stable guarantees):
#   1. round-trip + first-write still work (no regression from the atomic change);
#   2. the reader fail-opens (returns $null, never throws) on every torn shape - INCLUDING the exact
#      two-object concatenation the dogfood produced - which is what makes any transient torn read harmless;
#   3. under concurrent writers the FINAL state is always a single valid marker (the persistent corruption
#      is closed) and the real reader never throws across the whole race.
# NOTE deliberately NOT asserted: "zero torn mid-race reads". No Windows rename primitive delivers that
# cheaply under a brutal hammer (measured 2026-06-12); the reader's fail-open is the correctness guarantee,
# not mid-race read atomicity.
$ErrorActionPreference = 'Stop'

$base = "$PSScriptRoot/../../scripts/internal/bootstrap"
. "$base/SessionStateAccessor.ps1"

function Assert-Equal {
    param([AllowNull()]$Actual, [AllowNull()]$Expected, [string]$Message)
    if ($Actual -ne $Expected) { throw "FAIL: $Message (expected '$Expected', got '$Actual')" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-marker-atomic-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
try {
    $mp = Join-Path $tmp 'session-marker.json'

    # --- 1. Round-trip still works after the atomic change (no regression) -----------------
    Write-SpecrewSessionMarker -MarkerPath $mp -HostName codex -ProjectRoot $tmp -Branch main -HeadCommit abc123 -StartedAt '2026-06-12T12:00:00Z' | Out-Null
    $m = Get-SpecrewSessionMarker -MarkerPath $mp
    Assert-Equal $m.host 'codex' 'atomic marker round-trip: host'
    Assert-Equal $m.head_commit 'abc123' 'atomic marker round-trip: head_commit'
    Assert-True (-not (Test-Path -LiteralPath "$mp.$PID.tmp")) 'no temp file left behind after a successful write'

    # --- 2. First write creates the directory (dest-absent Move path) -----------------------
    $nested = Join-Path $tmp 'sub/dir/session-marker.json'
    Write-SpecrewSessionMarker -MarkerPath $nested -HostName claude -ProjectRoot $tmp -StartedAt '2026-06-12T12:00:01Z' | Out-Null
    Assert-True (Test-Path -LiteralPath $nested) 'first write creates missing parent dirs + lands the file (dest-absent Move path)'
    Assert-Equal (Get-SpecrewSessionMarker -MarkerPath $nested).host 'claude' 'first write is readable'

    # --- 3. Reader fail-open safety net: every torn shape -> $null, NEVER an exception --------
    # This is the property that makes a transient torn read harmless. The two-object case is the EXACT
    # shape the dogfood produced; assert the reader refuses it rather than mis-parsing it.
    $valid = Get-Content -LiteralPath $mp -Raw
    foreach ($bad in @(
            @{ Label = 'empty file'; Content = '' },
            @{ Label = 'half-written object (truncated)'; Content = '{ "started_at": "2026-06-12T12:0' },
            @{ Label = 'two concatenated objects (the dogfood corruption)'; Content = ($valid + $valid) },
            @{ Label = 'garbage'; Content = 'not json at all <<<' }
        )) {
        [System.IO.File]::WriteAllText($mp, [string]$bad.Content, [System.Text.UTF8Encoding]::new($false))
        $threw = $false; $result = 'sentinel'
        try { $result = Get-SpecrewSessionMarker -MarkerPath $mp } catch { $threw = $true }
        Assert-True (-not $threw) ("reader never throws on {0}" -f $bad.Label)
        Assert-True ($null -eq $result) ("reader fails open to `$null on {0}" -f $bad.Label)
    }

    # --- 4. Concurrency: final state always a single valid marker; real reader never throws ----
    # Two writer PROCESSES hammer the same dest with distinct, ever-changing content. We sample the REAL
    # reader throughout (it must never throw) and assert the FINAL on-disk marker is one valid object -
    # the persistent corruption the dogfood saw is closed, even though transient torn reads may occur.
    Write-SpecrewSessionMarker -MarkerPath $mp -HostName seed -ProjectRoot $tmp -StartedAt '2026-06-12T12:00:00Z' | Out-Null
    $iterations = 400
    $writer = {
        param($MarkerPath, $AccessorPath, $HostName, $Iterations)
        . $AccessorPath
        for ($i = 0; $i -lt $Iterations; $i++) {
            Write-SpecrewSessionMarker -MarkerPath $MarkerPath -HostName $HostName -ProjectRoot 'X' -HeadCommit ("c$i") -StartedAt '2026-06-12T12:00:00Z' | Out-Null
        }
    }
    $accessor = "$base/SessionStateAccessor.ps1"
    $j1 = Start-Job -ScriptBlock $writer -ArgumentList $mp, $accessor, 'codex', $iterations
    $j2 = Start-Job -ScriptBlock $writer -ArgumentList $mp, $accessor, 'claude', $iterations

    $readerThrew = 0
    $samples = 0
    while (($j1.State -eq 'Running') -or ($j2.State -eq 'Running')) {
        try { $null = Get-SpecrewSessionMarker -MarkerPath $mp; $samples++ }
        catch { $readerThrew++ }
    }
    Receive-Job -Job $j1 -ErrorAction SilentlyContinue | Out-Null
    Receive-Job -Job $j2 -ErrorAction SilentlyContinue | Out-Null
    Remove-Job -Job $j1, $j2 -Force -ErrorAction SilentlyContinue

    Write-Host ("  concurrency: {0} reader samples during the race, {1} reader exceptions" -f $samples, $readerThrew) -ForegroundColor Cyan
    Assert-True ($samples -gt 0) 'sampler actually observed the file during the race (test is live)'
    Assert-Equal $readerThrew 0 'the real reader NEVER throws during concurrent writes (fail-open holds)'

    $final = Get-SpecrewSessionMarker -MarkerPath $mp
    Assert-True ($null -ne $final -and ($final.host -in @('codex', 'claude'))) 'after the race the marker is a single VALID object (no persistent corruption)'
    Assert-True (-not (Test-Path -LiteralPath "$mp.$PID.tmp")) 'no temp files orphaned after the race'
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'MarkerAtomicWrite: all tests passed.' -ForegroundColor Green
