[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 141 Iteration 3 — FR-013 / SC-009: fresh-greenfield baseline-commit handling.
#
# Prove-first outcome (maintainer C+nudge decision 2026-06-03): the baseline already resolves
# correctly once a commit exists (the Feature-029 contract), and the zero-commit case is an
# intentional fail-safe. So this slice preserves the fail-safe (no stamp, NO auto-commit) and
# adds a greenfield guidance nudge at `specrew start`.
#
# This suite is self-contained and runnable GREEN LOCALLY (it dot-sources the repo functions the
# boundary sync uses and invokes the repo `specrew-start.ps1` directly). A co-located SC-009 also
# lives in tests/integration/baseline-hygiene.tests.ps1 for when CI reaches it; this file is the
# primary, locally-verifiable enforcement of the committed FR-013 behavior.

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }
function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { Write-Fail $Message } Write-Pass $Message }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$startScript = Join-Path $repoRoot 'scripts\specrew-start.ps1'
$internalScript = Join-Path $repoRoot 'scripts\internal\sync-boundary-state.ps1'
foreach ($p in @($startScript, $internalScript)) {
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { Write-Fail "Missing required script: $p" }
}
. $internalScript  # Get-SpecrewCurrentHeadCommitHash + Update-BaselineCommitHashInFrontmatter (repo)

function New-GreenfieldFixture {
    param([Parameter(Mandatory = $true)][string]$Root, [switch]$SkipInitialCommit)

    if (Test-Path -LiteralPath $Root) { Remove-Item -LiteralPath $Root -Recurse -Force }
    $null = New-Item -ItemType Directory -Path $Root -Force
    $null = & git -C $Root init --quiet 2>&1
    $null = & git -C $Root config user.email 'greenfield@example.test' 2>&1
    $null = & git -C $Root config user.name 'Greenfield Dev' 2>&1

    foreach ($d in @('.specrew', '.specify', '.squad', '.squad\agents\planner', '.github\agents', 'specs\141-fr013\iterations\001')) {
        $null = New-Item -ItemType Directory -Path (Join-Path $Root $d) -Force
    }
    $u = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText((Join-Path $Root '.specrew\config.yml'), "project_name: sample`nspecrew_version: `"0.0.0`"`nbootstrap_date: `"2026-01-01`"`n", $u)
    [System.IO.File]::WriteAllText((Join-Path $Root '.specify\feature.json'), "{`n  `"feature_directory`": `"specs/141-fr013`"`n}", $u)
    [System.IO.File]::WriteAllText((Join-Path $Root '.squad\team.md'), "# Team`n", $u)
    [System.IO.File]::WriteAllText((Join-Path $Root '.squad\config.json'), "{}`n", $u)
    [System.IO.File]::WriteAllText((Join-Path $Root '.squad\decisions.md'), "# Decisions`n", $u)
    [System.IO.File]::WriteAllText((Join-Path $Root '.github\agents\squad.agent.md'), "# Squad Agent`n", $u)
    [System.IO.File]::WriteAllText((Join-Path $Root '.squad\agents\planner\charter.md'), "# Planner Charter`n", $u)
    [System.IO.File]::WriteAllText((Join-Path $Root 'specs\141-fr013\spec.md'), "# Spec`n", $u)
    [System.IO.File]::WriteAllText((Join-Path $Root 'README.md'), "# Repo`n", $u)

    if (-not $SkipInitialCommit) {
        $null = & git -C $Root add -A 2>&1
        $null = & git -C $Root commit -m 'Seed' --quiet 2>&1
    }
}

$fixture = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-141-fr013-{0}" -f ([System.Guid]::NewGuid().ToString('N')))
try {
    New-GreenfieldFixture -Root $fixture -SkipInitialCommit
    $promptPath = Join-Path $fixture '.specrew\last-start-prompt.md'

    # SC-009 (1): zero-commit greenfield -> start emits guidance, does NOT stamp a baseline, no corruption.
    $startOut = (pwsh -NoProfile -ExecutionPolicy Bypass -File $startScript -ProjectPath $fixture -NoLaunch *>&1 | Out-String)
    Assert-True ($startOut -match 'No baseline commit yet' -and $startOut -match 'initial commit') "SC-009: zero-commit greenfield start emits the baseline guidance nudge"
    Assert-True (Test-Path -LiteralPath $promptPath) "SC-009: specrew start writes a prompt in the zero-commit greenfield"
    $zeroPrompt = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8
    Assert-True ($zeroPrompt -notmatch 'baseline_commit_hash:') "SC-009: zero-commit greenfield does NOT stamp baseline_commit_hash (Feature-029 fail-safe preserved, no auto-commit)"
    $null = & git -C $fixture rev-parse --verify HEAD 2>&1
    Assert-True ($LASTEXITCODE -ne 0) "SC-009: start did NOT create a commit on the user's behalf (still zero-commit)"

    # SC-009 (2): after the first real commit -> the boundary baseline-refresh path resolves the
    # baseline to a real HEAD and keeps it consistent (Get-SpecrewCurrentHeadCommitHash +
    # Update-BaselineCommitHashInFrontmatter are exactly what sync-boundary-state.ps1:1209-1210 calls).
    $null = & git -C $fixture add -A 2>&1
    $null = & git -C $fixture commit -m 'Initial commit (establishes baseline)' --quiet 2>&1
    $head = (& git -C $fixture rev-parse HEAD).ToString().Trim()
    $resolved = Get-SpecrewCurrentHeadCommitHash -ProjectRoot $fixture
    Assert-True ($resolved -eq $head) "SC-009: Get-SpecrewCurrentHeadCommitHash resolves to the real HEAD once a commit exists"
    Update-BaselineCommitHashInFrontmatter -PromptPath $promptPath -NewBaselineHash $resolved
    $stamped = ([regex]::Match((Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8), 'baseline_commit_hash:\s*([0-9a-f]{40})')).Groups[1].Value
    Assert-True ($stamped -eq $head) "SC-009: after the first commit, baseline_commit_hash resolves to the real HEAD and is consistent across the start packet and boundary-state HEAD"
}
finally {
    Remove-Item -LiteralPath $fixture -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
Write-Host 'All Feature-141 Iteration-3 greenfield baseline (FR-013 / SC-009) tests passed.' -ForegroundColor Green
exit 0
