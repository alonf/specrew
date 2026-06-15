$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../../scripts/internal/bootstrap/SessionStateAccessor.ps1"
. "$PSScriptRoot/../../scripts/internal/bootstrap/ProjectMetadataAccessor.ps1"
. "$PSScriptRoot/../../scripts/internal/bootstrap/ValidationEngine.ps1"

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
function New-StateFile {
    param([string]$Path, [string]$FeatureRef, [string]$FeaturePath, [bool]$Active = $true)
    @{ session_state = @{ active = $Active; feature_ref = $FeatureRef; feature_path = $FeaturePath; boundary_type = 'plan'; iteration_number = '001'; auth_commit_hash = 'x'; recorded_at = 't' } } |
        ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Path -Encoding UTF8
    return $Path
}

$root = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-t005-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $root 'specs/feat-x') -Force | Out-Null
try {
    # Valid: present, portable, not a git repo so merged fails safe to false.
    $s1 = New-StateFile -Path (Join-Path $root 's1.json') -FeatureRef 'feat-x' -FeaturePath (Join-Path $root 'specs/feat-x')
    $v1 = Test-SpecrewAnchorValidity -StatePath $s1 -ProjectRoot $root -BaseBranch 'main'
    Assert-True $v1.valid 'present, portable, unmerged anchor is valid'

    # No anchor -> invalid, no clear reason.
    $v2 = Test-SpecrewAnchorValidity -StatePath (Join-Path $root 'none.json') -ProjectRoot $root
    Assert-True (-not $v2.valid) 'missing state file is invalid'
    Assert-True ($null -eq $v2.cleared_reason) 'missing state has no clear reason'

    # Inactive anchor -> invalid.
    $s3 = New-StateFile -Path (Join-Path $root 's3.json') -FeatureRef 'feat-x' -FeaturePath (Join-Path $root 'specs/feat-x') -Active $false
    Assert-True (-not (Test-SpecrewAnchorValidity -StatePath $s3 -ProjectRoot $root).valid) 'inactive anchor is invalid'

    # Non-portable absolute path -> cleared 'non-portable'.
    # Cross-platform foreign absolute path (Windows other-drive; POSIX foreign root) - see SessionStateAccessor.Tests.
    $foreignFp = if ($IsWindows) { 'D:/other/worktree/specs/feat-x' } else { '/other/worktree/specs/feat-x' }
    $s4 = New-StateFile -Path (Join-Path $root 's4.json') -FeatureRef 'feat-x' -FeaturePath $foreignFp
    $v4 = Test-SpecrewAnchorValidity -StatePath $s4 -ProjectRoot $root
    Assert-Equal $v4.cleared_reason 'non-portable' 'foreign absolute path cleared as non-portable'

    # Feature absent locally -> cleared 'missing'.
    $s5 = New-StateFile -Path (Join-Path $root 's5.json') -FeatureRef 'ghost' -FeaturePath (Join-Path $root 'specs/ghost')
    $v5 = Test-SpecrewAnchorValidity -StatePath $s5 -ProjectRoot $root
    Assert-Equal $v5.cleared_reason 'missing' 'absent feature cleared as missing'

    # Merged feature (real git fixture) -> cleared 'merged'.
    $g = Join-Path $root 'gitrepo'
    New-Item -ItemType Directory -Path (Join-Path $g 'specs/feat-merged') -Force | Out-Null
    git -C $g init -q -b main 2>$null
    git -C $g config user.email 't@t'; git -C $g config user.name 't'
    git -C $g commit --allow-empty -q -m base
    git -C $g checkout -q -b feat-merged
    git -C $g commit --allow-empty -q -m work
    git -C $g checkout -q main
    git -C $g merge -q --no-ff feat-merged -m merge 2>$null
    $sm = New-StateFile -Path (Join-Path $g 'sm.json') -FeatureRef 'feat-merged' -FeaturePath (Join-Path $g 'specs/feat-merged')
    $vm = Test-SpecrewAnchorValidity -StatePath $sm -ProjectRoot $g -BaseBranch 'main'
    Assert-Equal $vm.cleared_reason 'merged' 'merged feature cleared as merged'
}
finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'ValidationEngine: all tests passed.' -ForegroundColor Green
