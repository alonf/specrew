# F-174 iter-10: the HOOK double-render dedupe (codex re-fires SessionStart twice per launch from ONE
# registration -> the bootstrap directive renders twice). Locks the (session, source)-keyed, record-at-end,
# fail-open contract: the SECOND fire of a session is suppressed, but a different source (/clear re-bootstrap),
# a fresh session, and the 'no-session' sentinel (self-host repo / Stop events) ALWAYS render. The mechanism
# is the only thing a deterministic test can prove; whether real codex fire TIMING + matching SOURCE actually
# trips it is the iter-10 re-deploy dogfood's job (sequential subprocess calls here trivially satisfy timing).
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../../scripts/internal/bootstrap/LauncherIntegration.ps1"
$provider = (Resolve-Path "$PSScriptRoot/../../scripts/internal/specrew-bootstrap-provider.ps1").Path

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

$tmp  = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-hookrender-" + [guid]::NewGuid().ToString('N'))
$tmp2 = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-hookrender2-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $tmp  '.specrew') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $tmp2 '.specrew') -Force | Out-Null
try {
    # ---------------- UNIT: the dedupe predicate ----------------
    # Suppression requires POSITIVE proof of a matching prior render; everything else renders.
    Write-SpecrewHookRenderMarker -ProjectRoot $tmp -DedupeKey 'A' -Source 'startup' -RecordedAt '2026-06-13T12:00:00Z' | Out-Null
    Assert-True (Test-SpecrewHookRenderRecent -ProjectRoot $tmp -DedupeKey 'A' -Source 'startup' -NowUtc '2026-06-13T12:00:10Z') 'U1: same session+source within window -> dedupe (silent)'
    Assert-True (-not (Test-SpecrewHookRenderRecent -ProjectRoot $tmp -DedupeKey 'B' -Source 'startup' -NowUtc '2026-06-13T12:00:10Z')) 'U2: DIFFERENT session -> render'
    Assert-True (-not (Test-SpecrewHookRenderRecent -ProjectRoot $tmp -DedupeKey 'A' -Source 'clear'   -NowUtc '2026-06-13T12:00:10Z')) 'U3: same session, DIFFERENT source (/clear re-bootstrap) -> render'
    Assert-True (-not (Test-SpecrewHookRenderRecent -ProjectRoot $tmp -DedupeKey 'A' -Source 'startup' -NowUtc '2026-06-13T12:05:00Z')) 'U4: same session+source but STALE (beyond window) -> render'
    Assert-True (-not (Test-SpecrewHookRenderRecent -ProjectRoot $tmp2 -DedupeKey 'A' -Source 'startup' -NowUtc '2026-06-13T12:00:10Z')) 'U5: NO marker -> render'

    # Fail-open on a corrupt marker: garbage text (parse throws) AND a two-object file (the session-marker
    # corruption shape) BOTH return $false (render) - a torn marker can only cause a benign duplicate, never
    # a suppressed directive.
    $mp = Get-SpecrewHookRenderMarkerPath -ProjectRoot $tmp
    Set-Content -LiteralPath $mp -Value 'not json at all {{{' -Encoding UTF8
    Assert-True (-not (Test-SpecrewHookRenderRecent -ProjectRoot $tmp -DedupeKey 'A' -Source 'startup' -NowUtc '2026-06-13T12:00:10Z')) 'U6a: garbage marker -> fail-open render'
    Set-Content -LiteralPath $mp -Value "{`"dedupe_key`":`"A`",`"source`":`"startup`",`"recorded_at`":`"2026-06-13T12:00:00Z`"}`n{`"dedupe_key`":`"A`",`"source`":`"startup`",`"recorded_at`":`"2026-06-13T12:00:00Z`"}" -Encoding UTF8
    Assert-True (-not (Test-SpecrewHookRenderRecent -ProjectRoot $tmp -DedupeKey 'A' -Source 'startup' -NowUtc '2026-06-13T12:00:10Z')) 'U6b: two-object (torn) marker -> fail-open render'

    # ---------------- INTEGRATION: the provider, end to end ----------------
    # I1/I2: the SAME session fires startup TWICE -> the FIRST renders, the SECOND is suppressed (the codex
    # double-render, gone). Sequential subprocess calls guarantee fire-1's marker is on disk before fire-2.
    $first  = & pwsh -NoProfile -File $provider --event-json '{"source":"startup","session_id":"s-dup"}' --host-kind codex --project-root $tmp2
    Assert-True ((($first -join "`n")) -match '\[specrew-bootstrap\]') 'I1: first fire RENDERS the bootstrap directive'
    $second = & pwsh -NoProfile -File $provider --event-json '{"source":"startup","session_id":"s-dup"}' --host-kind codex --project-root $tmp2
    Assert-True ([string]::IsNullOrWhiteSpace((($second -join '')).Trim())) 'I2: identical SECOND fire is SILENT (double-render suppressed)'

    # I3: the journal still recorded BOTH fires (forensic fire-count intact; only the RENDER was suppressed),
    # and each row carries the new source field = 'startup' (the dogfood-observability hook).
    $rows = @(Get-Content -LiteralPath (Join-Path $tmp2 '.specrew/runtime/bootstrap-journal.jsonl') | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json })
    $dup = @($rows | Where-Object { $_.dedupe_key -eq 's-dup' })
    Assert-True ($dup.Count -eq 2) "I3: BOTH fires journaled (forensic count intact) - found $($dup.Count) rows for s-dup"
    Assert-True (@($dup | Where-Object { $_.source -eq 'startup' }).Count -eq 2) 'I3: each journaled fire carries source=startup (dogfood observability)'

    # I4: same session, DIFFERENT source (a /clear re-bootstrap) STILL renders - the lone harmful failure mode
    # (suppressing a wanted re-bootstrap) is structurally prevented by source-in-key.
    $clear = & pwsh -NoProfile -File $provider --event-json '{"source":"clear","session_id":"s-dup"}' --host-kind codex --project-root $tmp2
    Assert-True ((($clear -join "`n")) -match '\[specrew-bootstrap\]') 'I4: same session under source=clear RE-RENDERS (/clear re-bootstrap is never suppressed)'

    # I5: the 'no-session' sentinel (no session_id - the self-host repo where codex sends none, or any Stop
    # event) is NEVER deduped: two identical fires on a fresh root BOTH render. This is the fail-safe that
    # keeps a missing directive impossible when there is no stable key.
    $ns1 = & pwsh -NoProfile -File $provider --event-json '{"source":"startup"}' --host-kind codex --project-root $tmp
    $ns2 = & pwsh -NoProfile -File $provider --event-json '{"source":"startup"}' --host-kind codex --project-root $tmp
    Assert-True ((($ns1 -join "`n")) -match '\[specrew-bootstrap\]') 'I5a: no-session fire #1 renders'
    Assert-True ((($ns2 -join "`n")) -match '\[specrew-bootstrap\]') 'I5b: no-session fire #2 ALSO renders (no-session is never deduped)'
}
finally {
    Remove-Item -LiteralPath $tmp  -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tmp2 -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'HookRenderDedupe: all tests passed.' -ForegroundColor Green
