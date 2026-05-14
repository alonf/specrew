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
        git -C $RepoPath add . 2>&1 | Out-Null
        git -C $RepoPath commit --quiet -m $Message 2>&1 | Out-Null
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

'@ | Set-Content -LiteralPath (Join-Path $scratchRoot '.squad\decisions.md') -Encoding UTF8

    Invoke-GitCommit -RepoPath $scratchRoot -Message 'fixture scaffold' -When '2026-05-14T01:00:30Z'

    Add-Content -LiteralPath (Join-Path $fixtureIteration 'state.md') -Value "`n- planning boundary reached" -Encoding UTF8
    Invoke-GitCommit -RepoPath $scratchRoot -Message 'Feature 016 substantive-interaction-model iteration 001 planning boundary' -When '2026-05-14T01:01:00Z'
    
    $planningCommitHash = (git -C $scratchRoot rev-parse HEAD)

    @"

## 2026-05-14T01:00:00Z — Authorization: planning

- **Decision ID**: authorization-feature-016-iter-001-planning
- **Type**: authorization
- **Boundary**: planning
- **Approving Human**: Fixture Human
- **Recorded At**: 2026-05-14T01:00:00Z
- **Commit Reference**: $planningCommitHash
- **Authorization Text**:
  > Continue to the planning boundary.
"@ | Add-Content -LiteralPath (Join-Path $scratchRoot '.squad\decisions.md') -Encoding UTF8

    Add-Content -LiteralPath (Join-Path $fixtureIteration 'state.md') -Value "`n- implementation boundary reached" -Encoding UTF8
    Invoke-GitCommit -RepoPath $scratchRoot -Message 'Feature 016 substantive-interaction-model iteration 001: implement' -When '2026-05-14T01:02:00Z'
    
    $implementationCommitHash = (git -C $scratchRoot rev-parse HEAD)

    $failOutput = @(
        pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorScript -ProjectPath $scratchRoot -IterationPath $fixtureIteration 2>&1
    )
    if ($LASTEXITCODE -eq 0) {
        Write-Fail 'Expected bundled-boundary-advance failure when no implementation authorization exists.'
        $failOutput | ForEach-Object { Write-Host $_ }
        exit 1
    }

    $failJoined = ($failOutput | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
    if ($failJoined -notmatch 'bundled-boundary-advance') {
        Write-Fail "Expected bundled-boundary-advance finding in failing fixture.`n$failJoined"
        exit 1
    }

    $implementationCommitHash = (git -C $scratchRoot rev-parse HEAD)

    @"

## 2026-05-14T01:01:30Z — Authorization: implementation

- **Decision ID**: authorization-feature-016-iter-001-implementation
- **Type**: authorization
- **Boundary**: implementation
- **Approving Human**: Fixture Human
- **Recorded At**: 2026-05-14T01:01:30Z
- **Commit Reference**: $implementationCommitHash
- **Authorization Text**:
  > Advance only to the implementation boundary, then stop again.
"@ | Add-Content -LiteralPath (Join-Path $scratchRoot '.squad\decisions.md') -Encoding UTF8

    $passOutput = @(
        pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorScript -ProjectPath $scratchRoot -IterationPath $fixtureIteration 2>&1
    )
    if ($LASTEXITCODE -ne 0) {
        Write-Fail 'Did not expect bundled-boundary-advance failure after adding the implementation authorization with populated Commit Reference.'
        $passOutput | ForEach-Object { Write-Host $_ }
        exit 1
    }

    $passJoined = ($passOutput | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
    if ($passJoined -match 'bundled-boundary-advance') {
        Write-Fail "Did not expect bundled-boundary-advance finding after adding authorization with populated Commit Reference.`n$passJoined"
        exit 1
    }

    Add-Content -LiteralPath (Join-Path $fixtureIteration 'state.md') -Value "`n- review boundary reached" -Encoding UTF8
    Invoke-GitCommit -RepoPath $scratchRoot -Message 'Feature 016 substantive-interaction-model iteration 001 review boundary' -When '2026-05-14T01:03:00Z'

    $reviewBoundaryCommitHash = (git -C $scratchRoot rev-parse HEAD)

    @"

## 2026-05-14T01:02:30Z — Authorization: review-boundary

- **Decision ID**: authorization-feature-016-iter-001-review-boundary
- **Type**: authorization
- **Boundary**: review-boundary
- **Approving Human**: Fixture Human
- **Recorded At**: 2026-05-14T01:02:30Z
- **Commit Reference**: $reviewBoundaryCommitHash
- **Authorization Text**:
  > Open the review boundary.
"@ | Add-Content -LiteralPath (Join-Path $scratchRoot '.squad\decisions.md') -Encoding UTF8

    $soloAuthPassOutput = @(
        pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorScript -ProjectPath $scratchRoot -IterationPath $fixtureIteration 2>&1
    )
    if ($LASTEXITCODE -ne 0) {
        Write-Fail 'Did not expect bundled-boundary-advance failure after adding solo review-boundary authorization.'
        $soloAuthPassOutput | ForEach-Object { Write-Host $_ }
        exit 1
    }

    Add-Content -LiteralPath (Join-Path $fixtureIteration 'state.md') -Value "`n- retro boundary reached" -Encoding UTF8
    Invoke-GitCommit -RepoPath $scratchRoot -Message 'Feature 016 substantive-interaction-model iteration 001 retrospective boundary' -When '2026-05-14T01:04:00Z'

    $missingAuthFailOutput = @(
        pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorScript -ProjectPath $scratchRoot -IterationPath $fixtureIteration 2>&1
    )
    if ($LASTEXITCODE -eq 0) {
        Write-Fail 'Expected bundled-boundary-advance failure for retro boundary commit with missing Commit Reference authorization.'
        $missingAuthFailOutput | ForEach-Object { Write-Host $_ }
        exit 1
    }

    $missingAuthFailJoined = ($missingAuthFailOutput | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
    if ($missingAuthFailJoined -notmatch 'bundled-boundary-advance') {
        Write-Fail "Expected bundled-boundary-advance finding for retro boundary without matching Commit Reference authorization.`n$missingAuthFailJoined"
        exit 1
    }
}
finally {
    if (Test-Path -LiteralPath $scratchRoot) {
        Remove-Item -LiteralPath $scratchRoot -Recurse -Force
    }
}

Write-Pass 'Feature 016 boundary discipline validation: negative (missing auth), positive (populated Commit Reference), positive (solo review auth), negative (missing retro auth)'
exit 0
