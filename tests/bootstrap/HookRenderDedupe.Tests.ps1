# F-174 iter-10: the HOOK double-render dedupe via an ATOMIC single-winner CLAIM. codex fires SessionStart
# twice per launch near-SIMULTANEOUSLY (worktree dogfood 2026-06-13: two fires ~microseconds apart, same
# session id + source) - so the dedupe MUST elect one winner under genuine CONCURRENCY, which the earlier
# recency/record-after-render scheme could not (both fires checked before either recorded -> both rendered).
# These tests therefore RACE concurrent claimants (Start-Job) and assert EXACTLY ONE wins - the test a
# sequential two-call test could never have caught (it trivially passes the broken scheme). Real codex remains
# the decisive acceptance; this locks the mechanism.
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../../scripts/internal/bootstrap/LauncherIntegration.ps1"
$provider = (Resolve-Path "$PSScriptRoot/../../scripts/internal/specrew-bootstrap-provider.ps1").Path
$accessor = (Resolve-Path "$PSScriptRoot/../../scripts/internal/bootstrap/LauncherIntegration.ps1").Path

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}
function Assert-Equal {
    param($Actual, $Expected, [string]$Message)
    if ($Actual -ne $Expected) { throw "FAIL: $Message (expected '$Expected', got '$Actual')" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

$tmp  = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-hookrender-" + [guid]::NewGuid().ToString('N'))
$tmp2 = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-hookrender2-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $tmp  '.specrew/runtime') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $tmp2 '.specrew/runtime') -Force | Out-Null
try {
    # ---------------- UNIT: the claim election ----------------
    Assert-True (Request-SpecrewHookRenderClaim -ProjectRoot $tmp -DedupeKey 'A' -Source 'startup' -RecordedAt '2026-06-13T12:00:00Z') 'U1: first claim of (A,startup) WINS -> render'
    Assert-True (-not (Request-SpecrewHookRenderClaim -ProjectRoot $tmp -DedupeKey 'A' -Source 'startup' -RecordedAt '2026-06-13T12:00:01Z')) 'U2: second claim of the SAME (A,startup) LOSES -> silent'
    Assert-True (Request-SpecrewHookRenderClaim -ProjectRoot $tmp -DedupeKey 'B' -Source 'startup' -RecordedAt '2026-06-13T12:00:02Z') 'U3: DIFFERENT session (B) wins its own claim -> render'
    Assert-True (Request-SpecrewHookRenderClaim -ProjectRoot $tmp -DedupeKey 'A' -Source 'clear' -RecordedAt '2026-06-13T12:00:03Z') 'U4: same session A under DIFFERENT source (/clear) wins its own claim -> render'

    # ---------------- CONCURRENCY: the decisive property ----------------
    # N processes race the SAME (session,source) claim simultaneously -> the atomic CreateNew must elect
    # EXACTLY ONE winner. This is the test that would have caught the original (recency) bug: under real
    # near-simultaneous fires it produced N winners, not one.
    $claimJob = {
        param($AccessorPath, $ProjectRoot, $Key, $Src)
        . $AccessorPath
        Request-SpecrewHookRenderClaim -ProjectRoot $ProjectRoot -DedupeKey $Key -Source $Src -RecordedAt '2026-06-13T12:00:00Z'
    }
    $N = 8
    $jobs = 1..$N | ForEach-Object { Start-Job -ScriptBlock $claimJob -ArgumentList $accessor, $tmp2, 'race-session', 'startup' }
    $null = $jobs | Wait-Job
    $results = @($jobs | Receive-Job)
    $jobs | Remove-Job -Force
    $winners = @($results | Where-Object { $_ -eq $true }).Count
    Write-Host ("  concurrency: $N racers, $winners winner(s)") -ForegroundColor Cyan
    Assert-Equal $winners 1 "C1: EXACTLY ONE of $N concurrent claimants wins the race (atomic CreateNew, no check-then-act gap)"

    # ---------------- INTEGRATION: two CONCURRENT provider fires (the real codex double-fire) ----------------
    $provJob = {
        param($Provider, $Evt, $Root)
        (& pwsh -NoProfile -File $Provider --event-json $Evt --host-kind codex --project-root $Root 2>&1 | Out-String)
    }
    $evt = '{"source":"startup","session_id":"concurrent-dup"}'
    $p1 = Start-Job -ScriptBlock $provJob -ArgumentList $provider, $evt, $tmp
    $p2 = Start-Job -ScriptBlock $provJob -ArgumentList $provider, $evt, $tmp
    $null = $p1, $p2 | Wait-Job
    $outs = @(($p1 | Receive-Job), ($p2 | Receive-Job))
    $p1, $p2 | Remove-Job -Force
    $renderCount = @($outs | Where-Object { $_ -match 'VISIBLE PROSE' }).Count          # 'VISIBLE PROSE' is render-specific (not in the PROVIDER_FAILED WARN)
    $failCount   = @($outs | Where-Object { $_ -match 'PROVIDER_FAILED' }).Count
    Write-Host ("  concurrent provider fires: $renderCount render(s), $failCount fail(s)") -ForegroundColor Cyan
    Assert-Equal $failCount 0 'I1a: neither concurrent fire PROVIDER_FAILED'
    Assert-Equal $renderCount 1 'I1b: two CONCURRENT provider fires (same session+source) -> EXACTLY ONE renders (the real codex double-fire is deduped)'
    # The journal still records BOTH fires (Invoke ran in each) - the forensic fire-count is intact; only the RENDER was deduped.
    $rows = @(Get-Content -LiteralPath (Join-Path $tmp '.specrew/runtime/bootstrap-journal.jsonl') | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json })
    $dup = @($rows | Where-Object { $_.dedupe_key -eq 'concurrent-dup' })
    Assert-Equal $dup.Count 2 "I1c: BOTH fires journaled (forensic count intact) - $($dup.Count) rows for concurrent-dup"

    # I2: a DIFFERENT source after the startup pair still renders (claims its own key) -> /clear re-bootstrap safe.
    $clear = & pwsh -NoProfile -File $provider --event-json '{"source":"clear","session_id":"concurrent-dup"}' --host-kind codex --project-root $tmp 2>&1 | Out-String
    Assert-True ($clear -match 'VISIBLE PROSE') 'I2: same session under source=clear RE-RENDERS (its own claim; /clear is never suppressed)'

    # I3: no usable host session id gets a per-launch fallback token. Two concurrent missing-id fires therefore
    # use distinct keys, BOTH render, and no global no-session/unknown state is written.
    $nsJob = {
        param($Provider, $Root)
        (& pwsh -NoProfile -File $Provider --event-json '{"source":"startup"}' --host-kind codex --project-root $Root 2>&1 | Out-String)
    }
    $n1 = Start-Job -ScriptBlock $nsJob -ArgumentList $provider, $tmp2
    $n2 = Start-Job -ScriptBlock $nsJob -ArgumentList $provider, $tmp2
    $null = $n1, $n2 | Wait-Job
    $nsOuts = @(($n1 | Receive-Job), ($n2 | Receive-Job))
    $n1, $n2 | Remove-Job -Force
    $nsRenders = @($nsOuts | Where-Object { $_ -match 'VISIBLE PROSE' }).Count
    Assert-Equal $nsRenders 2 'I3a: two concurrent missing-id fires BOTH render (per-launch fallback keys, never shared suppression)'
    $nsRows = @(Get-Content -LiteralPath (Join-Path $tmp2 '.specrew/runtime/bootstrap-journal.jsonl') | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json })
    $nsKeys = @($nsRows | ForEach-Object { [string]$_.dedupe_key })
    Assert-True (($nsKeys | Where-Object { $_ -match '^launch-[a-f0-9]{32}$' }).Count -eq 2) 'I3b: missing-id journal rows use per-launch fallback tokens'
    Assert-True (-not ($nsKeys -contains 'no-session') -and -not ($nsKeys -contains 'unknown')) 'I3c: missing-id journal rows avoid no-session/unknown buckets'
}
finally {
    Get-Job -ErrorAction SilentlyContinue | Remove-Job -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tmp  -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tmp2 -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'HookRenderDedupe: all tests passed.' -ForegroundColor Green
