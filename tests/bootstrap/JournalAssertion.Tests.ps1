$ErrorActionPreference = 'Stop'

$base = "$PSScriptRoot/../../scripts/internal/bootstrap"
foreach ($c in 'HostEventAdapter', 'SessionStateAccessor', 'ProjectMetadataAccessor', 'HandoverStore', 'ClassificationEngine', 'ValidationEngine', 'DirectiveEngine', 'SessionBootstrapManager', 'HookJournalAccessor') {
    . "$base/$c.ps1"
}

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

$root = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-t018-" + [guid]::NewGuid().ToString('N'))
$j = Join-Path $root 'bootstrap-journal.jsonl'
$now = '2026-06-08T12:05:00Z'
try {
    # full - no anchor, no handover.
    $tmpF = Join-Path $root 'full'; New-Item -ItemType Directory -Path (Join-Path $tmpF '.specrew') -Force | Out-Null
    Invoke-SpecrewSessionBootstrap -RawEvent '{"source":"startup","session_id":"f"}' -HostName claude -ProjectRoot $tmpF -JournalPath $j -NowUtc $now | Out-Null

    # welcome-back - fresh handover + the feature present locally.
    $tmpW = Join-Path $root 'wb'; New-Item -ItemType Directory -Path (Join-Path $tmpW 'specs/myfeat') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $tmpW '.specrew') -Force | Out-Null
    Write-SpecrewHandover -HandoverDir (Join-Path $tmpW '.specrew/handover') -Source clear -FromHost claude -RecordedAt '2026-06-08T12:00:00Z' -ActiveFeature myfeat -ActiveBoundary review-signoff | Out-Null
    Invoke-SpecrewSessionBootstrap -RawEvent '{"source":"startup","session_id":"w"}' -HostName claude -ProjectRoot $tmpW -JournalPath $j -NowUtc $now | Out-Null

    # cleared-anchor - a non-portable (absolute, out-of-tree) anchor, no handover.
    $tmpC = Join-Path $root 'cl'; New-Item -ItemType Directory -Path (Join-Path $tmpC '.specrew') -Force | Out-Null
    (@{ session_state = @{ feature_ref = 'x'; feature_path = 'C:/nonexistent/specs/x'; boundary_type = 'plan'; active = $true } } | ConvertTo-Json -Depth 5) |
        Set-Content -LiteralPath (Join-Path $tmpC '.specrew/start-context.json') -Encoding UTF8
    Invoke-SpecrewSessionBootstrap -RawEvent '{"source":"startup","session_id":"c"}' -HostName claude -ProjectRoot $tmpC -JournalPath $j -NowUtc $now | Out-Null

    $records = Get-SpecrewBootstrapJournal -JournalPath $j
    Assert-Equal $records.Count 3 'three journal records appended (one per bootstrap)'
    $modes = @($records | ForEach-Object { $_.mode })
    Assert-True ($modes -contains 'full') 'full mode recorded'
    Assert-True ($modes -contains 'welcome-back') 'welcome-back mode recorded'
    Assert-True ($modes -contains 'cleared-anchor') 'cleared-anchor mode recorded'
    Assert-Equal (@($modes | Select-Object -Unique).Count) 3 'all three modes are DISTINGUISHABLE in the journal (SC-007)'
    foreach ($r in $records) {
        Assert-True (($null -ne $r.mode) -and ($null -ne $r.dedupe_key) -and ($null -ne $r.PSObject.Properties['concurrent_session'])) "record carries mode + dedupe_key + concurrent_session ($($r.mode))"
    }
}
finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'JournalAssertion: all tests passed.' -ForegroundColor Green
