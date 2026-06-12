$ErrorActionPreference = 'Stop'

$base = "$PSScriptRoot/../../scripts/internal/bootstrap"
. "$base/HostEventAdapter.ps1"
. "$base/SessionStateAccessor.ps1"
. "$base/ProjectMetadataAccessor.ps1"
. "$base/HandoverStore.ps1"
. "$base/ClassificationEngine.ps1"
. "$base/ValidationEngine.ps1"
. "$base/DirectiveEngine.ps1"
. "$base/SessionBootstrapManager.ps1"

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

$evt = '{"session_id":"sess-1","source":"startup","hook_event_name":"SessionStart"}'
$root = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-t007-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $root 'specs/feat-x') -Force | Out-Null
# Prop-145 round-6 (HIGH): git-init the fixture so it is its OWN repo root. The temp dir lives under a HOME
# that is itself a git worktree, so without this `git status --untracked-files=all` (inside Get-SpecrewSessionDelta)
# would scan the WHOLE parent tree - the unbounded hang the reviewer hit. As its own repo root the scan is
# bounded to this tiny fixture, AND Test-SpecrewIsGitRepoRoot's positive branch (gate passes) is exercised.
& git -C $root init -q 2>$null | Out-Null
& git -C $root -c user.email='t@t' -c user.name='t' commit -q --allow-empty -m init 2>$null | Out-Null
try {
    # No anchor -> full bootstrap, render-first directive, dedupe key from session id.
    $r1 = Invoke-SpecrewSessionBootstrap -RawEvent $evt -HostName claude -ProjectRoot $root -StatePath (Join-Path $root 'absent.json')
    Assert-Equal $r1.mode 'full' 'no anchor resolves full bootstrap'
    Assert-True $r1.directive.render_first 'directive is render-first'
    Assert-Equal $r1.directive.dedupe_key 'sess-1' 'dedupe key derived from session id'

    # Non-portable anchor -> cleared-anchor with reason in the record + findings.
    $s2 = New-StateFile -Path (Join-Path $root 's2.json') -FeatureRef 'feat-x' -FeaturePath 'D:/other/worktree/specs/feat-x'
    $r2 = Invoke-SpecrewSessionBootstrap -RawEvent $evt -HostName claude -ProjectRoot $root -StatePath $s2
    Assert-Equal $r2.mode 'cleared-anchor' 'non-portable anchor resolves cleared-anchor'
    Assert-Equal $r2.record.anchor_cleared 'non-portable' 'record carries the clear reason'
    Assert-True ($r2.directive.validation_findings.Count -ge 1) 'directive carries validation findings'

    # Valid anchor (present, portable, not a git repo) -> welcome-back.
    $s3 = New-StateFile -Path (Join-Path $root 's3.json') -FeatureRef 'feat-x' -FeaturePath (Join-Path $root 'specs/feat-x')
    $r3 = Invoke-SpecrewSessionBootstrap -RawEvent $evt -HostName claude -ProjectRoot $root -StatePath $s3 -BaseBranch 'main'
    Assert-Equal $r3.mode 'welcome-back' 'valid anchor resolves welcome-back'

    # Journal record is appended when a journal path is supplied.
    $jp = Join-Path $root 'journal/records.jsonl'
    Invoke-SpecrewSessionBootstrap -RawEvent $evt -HostName claude -ProjectRoot $root -StatePath (Join-Path $root 'absent.json') -JournalPath $jp | Out-Null
    Assert-True (Test-Path -LiteralPath $jp) 'journal record file written'
    Assert-True ((Get-Content -LiteralPath $jp -Raw) -match '"mode":"full"') 'journal record captures the mode'
}
finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'SessionBootstrapManager: all tests passed.' -ForegroundColor Green
