[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass {
    param([string]$Message)
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

function Invoke-GitCommit {
    param(
        [string]$RepoPath,
        [string]$Message,
        [string]$When
    )

    $env:GIT_AUTHOR_DATE = $When
    $env:GIT_COMMITTER_DATE = $When
    try {
        git -C $RepoPath add . | Out-Null
        git -C $RepoPath commit --quiet -m $Message | Out-Null
    }
    finally {
        Remove-Item Env:\GIT_AUTHOR_DATE -ErrorAction SilentlyContinue
        Remove-Item Env:\GIT_COMMITTER_DATE -ErrorAction SilentlyContinue
    }
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$validatorScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'
$scratchRoot = Join-Path $repoRoot 'tests\integration\scratch\feature016-boundary-discipline-fixture'
$fixtureFeatureRoot = Join-Path $scratchRoot 'specs\016-substantive-interaction-model'
$fixtureIteration = Join-Path $fixtureFeatureRoot 'iterations\001'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

try {
    New-Item -ItemType Directory -Path $scratchRoot -Force | Out-Null
    foreach ($directory in @('.github', '.specrew', '.squad', 'specs')) {
        New-Item -ItemType Directory -Path (Join-Path $scratchRoot $directory) -Force | Out-Null
    }

    Copy-Item -LiteralPath (Join-Path $repoRoot '.github\copilot-instructions.md') -Destination (Join-Path $scratchRoot '.github\copilot-instructions.md')
    Copy-Item -LiteralPath (Join-Path $repoRoot '.specrew\config.yml') -Destination (Join-Path $scratchRoot '.specrew\config.yml')
    Copy-Item -LiteralPath (Join-Path $repoRoot '.specrew\iteration-config.yml') -Destination (Join-Path $scratchRoot '.specrew\iteration-config.yml')
    Copy-Item -LiteralPath (Join-Path $repoRoot '.squad\team.md') -Destination (Join-Path $scratchRoot '.squad\team.md')
    Copy-Item -LiteralPath (Join-Path $repoRoot 'specs\016-substantive-interaction-model') -Destination $fixtureFeatureRoot -Recurse

    git -C $scratchRoot init --quiet | Out-Null
    git -C $scratchRoot config user.name 'Copilot Test' | Out-Null
    git -C $scratchRoot config user.email 'copilot-test@example.com' | Out-Null

    @'
# Decisions Ledger

## 2026-05-14T01:00:00Z — Authorization: planning

- **Decision ID**: authorization-feature-016-iter-001-planning
- **Type**: authorization
- **Boundary**: planning
- **Approving Human**: Fixture Human
- **Recorded At**: 2026-05-14T01:00:00Z
- **Commit Reference**: pending
- **Authorization Text**:
  > Continue to the planning boundary.
'@ | Set-Content -LiteralPath (Join-Path $scratchRoot '.squad\decisions.md') -Encoding UTF8

    Invoke-GitCommit -RepoPath $scratchRoot -Message 'fixture scaffold' -When '2026-05-14T01:00:30Z'

    Add-Content -LiteralPath (Join-Path $fixtureIteration 'state.md') -Value "`n- planning boundary reached" -Encoding UTF8
    Invoke-GitCommit -RepoPath $scratchRoot -Message 'Feature 016 substantive-interaction-model iteration 001 planning boundary' -When '2026-05-14T01:01:00Z'

    Add-Content -LiteralPath (Join-Path $fixtureIteration 'state.md') -Value "`n- implementation boundary reached" -Encoding UTF8
    Invoke-GitCommit -RepoPath $scratchRoot -Message 'Feature 016 substantive-interaction-model iteration 001: implement' -When '2026-05-14T01:02:00Z'

    $failOutput = @(
        pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorScript -ProjectPath $scratchRoot -IterationPath $fixtureIteration 2>&1
    )
    if ($LASTEXITCODE -eq 0) {
        Write-Fail 'Expected bundled-boundary-advance failure when no intervening authorization exists.'
        $failOutput | ForEach-Object { Write-Host $_ }
        exit 1
    }

    $failJoined = ($failOutput | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
    if ($failJoined -notmatch 'bundled-boundary-advance') {
        Write-Fail "Expected bundled-boundary-advance finding in failing fixture.`n$failJoined"
        exit 1
    }

    @'

## 2026-05-14T01:01:30Z — Authorization: implementation

- **Decision ID**: authorization-feature-016-iter-001-implementation
- **Type**: authorization
- **Boundary**: implementation
- **Approving Human**: Fixture Human
- **Recorded At**: 2026-05-14T01:01:30Z
- **Commit Reference**: pending
- **Authorization Text**:
  > Advance only to the implementation boundary, then stop again.
'@ | Add-Content -LiteralPath (Join-Path $scratchRoot '.squad\decisions.md') -Encoding UTF8

    $passOutput = @(
        pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorScript -ProjectPath $scratchRoot -IterationPath $fixtureIteration 2>&1
    )
    if ($LASTEXITCODE -ne 0) {
        Write-Fail 'Did not expect bundled-boundary-advance failure after adding the intervening authorization.'
        $passOutput | ForEach-Object { Write-Host $_ }
        exit 1
    }

    $passJoined = ($passOutput | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
    if ($passJoined -match 'bundled-boundary-advance') {
        Write-Fail "Did not expect bundled-boundary-advance finding after repair.`n$passJoined"
        exit 1
    }
}
finally {
    if (Test-Path -LiteralPath $scratchRoot) {
        Remove-Item -LiteralPath $scratchRoot -Recurse -Force
    }
}

Write-Pass 'Feature 016 boundary discipline validation fails on bundled advances and clears after intervening authorization is recorded'
exit 0
