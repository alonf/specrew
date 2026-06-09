$ErrorActionPreference = 'Stop'

# F-174 iteration 005 (T033). The CI-blocking failure-mode-A PLUMBING floor + the non-blocking
# failure-mode-B detection. Carry #2: A tests the PLUMBING round-trip (persisted bytes == surfaced
# bytes), NEVER an agent-display claim - so it does not secretly depend on the B authoring behavior.

$base = "$PSScriptRoot/../../scripts/internal/bootstrap"
. "$base/HostEventAdapter.ps1"
. "$base/SessionStateAccessor.ps1"
. "$base/ProjectMetadataAccessor.ps1"
. "$base/HandoverStore.ps1"
. "$base/ClassificationEngine.ps1"
. "$base/ValidationEngine.ps1"
. "$base/DirectiveEngine.ps1"
. "$base/SessionBootstrapManager.ps1"
$provider = (Resolve-Path "$PSScriptRoot/../../scripts/internal/specrew-handover-provider.ps1").Path

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

$k1 = 'What I just did (last 3-5 turns or last boundary work)'
$k5 = 'Recommended next-immediate-step'
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-t033-" + [guid]::NewGuid().ToString('N'))
$hd = Join-Path $tmp 'handover'
try {
    # ===== Failure-mode A - CI-blocking PLUMBING floor =====

    # A1: the agent authors a rich body; it reads back rich; the detector says NOT placeholder.
    Write-SpecrewHandoverContext -HandoverDir $hd -FromHost claude -RecordedAt '2026-06-09T10:00:00Z' `
        -ActiveFeature feat -ActiveBoundary plan -Sections @{ $k1 = 'Implemented the floor/body split.'; $k5 = 'Run the tests.' } | Out-Null
    $h = Get-SpecrewRollingHandover -HandoverDir $hd -NowUtc '2026-06-09T10:05:00Z'
    Assert-Equal $h.sections[$k5] 'Run the tests.' 'A1: the agent-authored section reads back verbatim'
    Assert-True (-not (Test-SpecrewHandoverBodyPlaceholder -Sections $h.sections).placeholder) 'A1: an authored body is not a placeholder'

    # A2: render==persist (carry #2). The bytes on disk carry the authored content == what the read-back
    # surfaces. This is a PLUMBING assertion (file <-> read-back), not a claim about what the agent shows.
    $persisted = Get-Content -LiteralPath (Get-SpecrewRollingHandoverPath -HandoverDir $hd) -Raw
    Assert-True ($persisted -match [regex]::Escape($h.sections[$k5])) 'A2: persisted bytes == the surfaced section (render==persist plumbing)'

    # A3: a hook Stop on the SAME boundary PRESERVES the agent body (never clobbers).
    Write-SpecrewRollingHandover -HandoverDir $hd -Source Stop -FromHost claude -RecordedAt '2026-06-09T10:10:00Z' -ActiveFeature feat -ActiveBoundary plan | Out-Null
    $h3 = Get-SpecrewRollingHandover -HandoverDir $hd -NowUtc '2026-06-09T10:11:00Z'
    Assert-Equal $h3.sections[$k5] 'Run the tests.' 'A3: a same-boundary hook Stop preserves the agent body'
    Assert-True (-not (Test-SpecrewHandoverBodyPlaceholder -Sections $h3.sections).placeholder) 'A3: the preserved body is still not a placeholder'

    # A4: a hook Stop on a MOVED boundary resets the now-stale body to a placeholder.
    Write-SpecrewRollingHandover -HandoverDir $hd -Source Stop -FromHost claude -RecordedAt '2026-06-09T10:20:00Z' -ActiveFeature feat -ActiveBoundary tasks | Out-Null
    $h4 = Get-SpecrewRollingHandover -HandoverDir $hd -NowUtc '2026-06-09T10:21:00Z'
    Assert-Equal $h4.active_boundary 'tasks' 'A4: the floor refreshed to the new boundary'
    Assert-True (Test-SpecrewHandoverBodyPlaceholder -Sections $h4.sections).placeholder 'A4: a boundary-move resets the body to a placeholder'

    # A5: bootstrap SURFACING plumbing - the manager carries the PERSISTED authored body in the directive.
    $root = Join-Path $tmp 'proj'
    New-Item -ItemType Directory -Path (Join-Path $root 'specs/feat') -Force | Out-Null
    Write-SpecrewHandoverContext -HandoverDir (Join-Path $root '.specrew/handover') -FromHost claude -RecordedAt '2026-06-09T11:00:00Z' `
        -ActiveFeature feat -ActiveBoundary plan -Sections @{ $k5 = 'Resume at plan.' } | Out-Null
    $evt = '{"session_id":"s","source":"startup","hook_event_name":"SessionStart"}'
    $r = Invoke-SpecrewSessionBootstrap -RawEvent $evt -HostName claude -ProjectRoot $root -StatePath (Join-Path $root 'absent.json') -NowUtc '2026-06-09T11:05:00Z' -BaseBranch main
    Assert-Equal $r.mode 'welcome-back' 'A5: a valid authored handover resolves welcome-back'
    Assert-True ($null -ne $r.directive.handover -and $r.directive.handover.present) 'A5: the directive carries the handover'
    Assert-True (-not $r.directive.handover.placeholder) 'A5: the directive handover is not placeholder (authored)'
    Assert-Equal $r.directive.handover.sections[$k5] 'Resume at plan.' 'A5: the directive carries the PERSISTED authored body (surfacing plumbing)'

    # A6: a PLACEHOLDER handover is flagged placeholder in the directive (so the provider can warn).
    $root2 = Join-Path $tmp 'proj2'
    New-Item -ItemType Directory -Path (Join-Path $root2 'specs/feat') -Force | Out-Null
    Write-SpecrewRollingHandover -HandoverDir (Join-Path $root2 '.specrew/handover') -Source Stop -FromHost claude -RecordedAt '2026-06-09T11:00:00Z' -ActiveFeature feat -ActiveBoundary plan | Out-Null
    $r2 = Invoke-SpecrewSessionBootstrap -RawEvent $evt -HostName claude -ProjectRoot $root2 -StatePath (Join-Path $root2 'absent.json') -NowUtc '2026-06-09T11:05:00Z' -BaseBranch main
    Assert-True ($null -ne $r2.directive.handover -and $r2.directive.handover.placeholder) 'A6: a placeholder handover is flagged placeholder in the directive'

    # A7/A8: the bootstrap PROVIDER actually RENDERS the surfacing (the user-facing prose). The real
    # clock drives freshness here, so the handover is written with the real current UTC.
    $bootProv = (Resolve-Path "$PSScriptRoot/../../scripts/internal/specrew-bootstrap-provider.ps1").Path
    $nowReal = (Get-Date).ToUniversalTime().ToString('o')
    $pr = Join-Path $tmp 'provrender'
    New-Item -ItemType Directory -Path (Join-Path $pr 'specs/feat') -Force | Out-Null
    Write-SpecrewHandoverContext -HandoverDir (Join-Path $pr '.specrew/handover') -FromHost claude -RecordedAt $nowReal -ActiveFeature feat -ActiveBoundary plan -Sections @{ $k5 = 'PROVRENDER-NEXT-STEP' } | Out-Null
    $t7 = (& pwsh -NoProfile -File $bootProv --event-json '{"source":"startup","session_id":"pr"}' --project-root $pr) -join "`n"
    Assert-True ($t7 -match 'PROVRENDER-NEXT-STEP') 'A7: the provider RENDERS the agent-authored body content on resume'
    Assert-True ($t7 -match 'Handover protocol') 'A7: the provider renders the author-before-stop protocol instruction'

    $ph = Join-Path $tmp 'provholl'
    New-Item -ItemType Directory -Path (Join-Path $ph 'specs/feat') -Force | Out-Null
    Write-SpecrewRollingHandover -HandoverDir (Join-Path $ph '.specrew/handover') -Source Stop -FromHost claude -RecordedAt $nowReal -ActiveFeature feat -ActiveBoundary plan | Out-Null
    $t8 = (& pwsh -NoProfile -File $bootProv --event-json '{"source":"startup","session_id":"ph"}' --project-root $ph) -join "`n"
    Assert-True ($t8 -match 'HOLLOW HANDOVER') 'A8: the provider renders the PROMINENT hollow-handover warning for a placeholder body'

    # ===== Failure-mode B - NON-BLOCKING detection =====

    # B1: the pure detector distinguishes authored / marker-only / null.
    Assert-True (-not (Test-SpecrewHandoverBodyPlaceholder -Sections @{ $k5 = 'real content' }).placeholder) 'B1: authored content -> not placeholder'
    Assert-True (Test-SpecrewHandoverBodyPlaceholder -Sections @{ $k5 = (Get-SpecrewHandoverPlaceholderMarker -Boundary plan) }).placeholder 'B1: a marker-only body -> placeholder'
    Assert-True (Test-SpecrewHandoverBodyPlaceholder -Sections $null).placeholder 'B1: a null body -> placeholder'

    # B2: the Stop provider records a same-session hollow detection on a material Stop with no authored body.
    $pj = Join-Path $tmp 'pj'
    New-Item -ItemType Directory -Path (Join-Path $pj '.specrew/handover') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $pj '.gitignore') -Value ".specrew/`n" -Encoding UTF8
    git -C $pj init -q -b main 2>$null; git -C $pj config user.email t@t 2>$null; git -C $pj config user.name t 2>$null
    git -C $pj add -A 2>$null; git -C $pj commit -q -m init 2>$null
    (@{ session_state = @{ feature_ref = 'feat'; boundary_type = 'plan'; host = 'claude' } } | ConvertTo-Json -Depth 5) |
        Set-Content -LiteralPath (Join-Path $pj '.specrew/start-context.json') -Encoding UTF8
    & pwsh -NoProfile -File $provider --event-json '{"hook_event_name":"Stop"}' --project-root $pj 2>$null | Out-Null
    $jpath = Join-Path $pj '.specrew/runtime/handover-journal.jsonl'
    Assert-True (Test-Path -LiteralPath $jpath) 'B2: a hollow detection journal is written on a hollow Stop'
    Assert-True ((Get-Content -LiteralPath $jpath -Raw) -match 'hollow-handover-at-stop') 'B2: the journal records the hollow-handover-at-stop event'
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'AgentAuthoredHandover: all tests passed.' -ForegroundColor Green
