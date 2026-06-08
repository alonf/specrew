$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../../scripts/internal/bootstrap/HandoverStore.ps1"

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

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-t008-" + [guid]::NewGuid().ToString('N'))
$hd = Join-Path $tmp 'handover'
try {
    # Write a Proposal 130-shaped SessionEnd handover.
    $sections = @{ 'Recommended next-immediate-step' = 'Resume iteration 002 task T009.' }
    $p = Write-SpecrewHandover -HandoverDir $hd -Source clear -FromHost claude -RecordedAt '2026-06-08T12:00:00Z' `
        -FromCommit abc123 -ActiveFeature '174-x' -ActiveBoundary review-signoff -Sections $sections
    Assert-True (Test-Path -LiteralPath $p) 'handover file written'
    Assert-True ($p -match 'session-end-clear-from-claude\.md$') 'path follows Proposal 130 SessionEnd convention'
    $raw = Get-Content -LiteralPath $p -Raw
    Assert-True ($raw -match 'schema: v1') 'frontmatter carries schema v1'
    Assert-True ($raw -match 'Resume iteration 002 task T009') 'provided section content is written'
    Assert-True ($raw -match '\(no relevant content\)') 'missing sections get the 130 placeholder'
    Assert-True ($raw -match "## Why I'm stopping") 'all six 130 sections are emitted'
    $idx = Join-Path $hd 'index.yml'
    Assert-True (Test-Path -LiteralPath $idx) 'index.yml created'
    Assert-True ((Get-Content -LiteralPath $idx -Raw) -match 'session-end-clear-from-claude') 'index references the handover'

    # Round-trip read, fresh (1h later, 24h window).
    $h = Get-SpecrewHandover -HandoverDir $hd -NowUtc '2026-06-08T13:00:00Z' -FreshnessHours 24
    Assert-Equal $h.schema 'v1' 'read schema v1'
    Assert-Equal $h.source 'clear' 'read source'
    Assert-Equal $h.active_feature '174-x' 'read active_feature'
    Assert-Equal $h.active_boundary 'review-signoff' 'read active_boundary'
    Assert-True $h.fresh 'recent handover is fresh'

    # Stale read (48h later).
    $h2 = Get-SpecrewHandover -HandoverDir $hd -NowUtc '2026-06-10T13:00:00Z' -FreshnessHours 24
    Assert-True (-not $h2.fresh) 'old handover is not fresh'

    # Missing dir fails open.
    Assert-True ($null -eq (Get-SpecrewHandover -HandoverDir (Join-Path $tmp 'none') -NowUtc '2026-06-08T13:00:00Z')) 'missing handover dir returns null'
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'HandoverStore: all tests passed.' -ForegroundColor Green
