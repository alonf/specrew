$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../../scripts/internal/bootstrap/SessionStateAccessor.ps1"

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

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-t002-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
    # Anchor read from a well-formed state file.
    $statePath = Join-Path $tmp 'start-context.json'
    @{ session_state = @{ active = $true; feature_ref = '174-x'; feature_path = (Join-Path $tmp 'specs/174-x'); boundary_type = 'plan'; iteration_number = '001'; auth_commit_hash = 'abc'; recorded_at = '2026-06-08' } } |
        ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $statePath -Encoding UTF8
    $a = Get-SpecrewSessionAnchor -StatePath $statePath
    Assert-Equal $a.feature_ref '174-x' 'anchor feature_ref read'
    Assert-Equal $a.boundary 'plan' 'anchor boundary read'
    Assert-True $a.active 'anchor active flag read'

    # Missing file fails open (null).
    Assert-True ($null -eq (Get-SpecrewSessionAnchor -StatePath (Join-Path $tmp 'nope.json'))) 'missing state file returns null'

    # Corrupt JSON fails open (null).
    Set-Content -LiteralPath (Join-Path $tmp 'bad.json') -Value 'not json' -Encoding UTF8
    Assert-True ($null -eq (Get-SpecrewSessionAnchor -StatePath (Join-Path $tmp 'bad.json'))) 'corrupt state returns null'

    # State file without a session_state key returns null.
    '{"other":1}' | Set-Content -LiteralPath (Join-Path $tmp 'nostate.json') -Encoding UTF8
    Assert-True ($null -eq (Get-SpecrewSessionAnchor -StatePath (Join-Path $tmp 'nostate.json'))) 'state without session_state returns null'

    # Marker write + roundtrip.
    $markerPath = Join-Path $tmp 'runtime/marker.json'
    $m = Write-SpecrewSessionMarker -MarkerPath $markerPath -HostName claude -ProjectRoot $tmp -Branch 'b' -HeadCommit 'c' -StartedAt '2026-06-08T00:00:00Z'
    Assert-Equal $m.host 'claude' 'marker host set'
    Assert-True (Test-Path -LiteralPath $markerPath) 'marker file written (dir auto-created)'
    $back = (Get-Content -LiteralPath $markerPath -Raw | ConvertFrom-Json)
    Assert-Equal $back.head_commit 'c' 'marker head_commit roundtrips'

    # Portability.
    $portable = [pscustomobject]@{ feature_path = (Join-Path $tmp 'specs/174-x') }
    Assert-True (Test-SpecrewAnchorPortable -Anchor $portable -ProjectRoot $tmp) 'under-root path is portable'
    # Cross-platform foreign absolute path: a Windows other-drive path on Windows; a foreign POSIX root path
    # elsewhere. (A 'D:/...' string is NOT IsPathRooted on Linux, so it would wrongly read as portable there.)
    $foreignFp = if ($IsWindows) { 'D:/other/worktree/specs/171-x' } else { '/other/worktree/specs/171-x' }
    $foreign = [pscustomobject]@{ feature_path = $foreignFp }
    Assert-True (-not (Test-SpecrewAnchorPortable -Anchor $foreign -ProjectRoot $tmp)) 'foreign absolute path is non-portable'
    $noPath = [pscustomobject]@{ feature_path = $null }
    Assert-True (Test-SpecrewAnchorPortable -Anchor $noPath -ProjectRoot $tmp) 'no recorded path -> portable (resolve project-local)'
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'SessionStateAccessor: all tests passed.' -ForegroundColor Green
