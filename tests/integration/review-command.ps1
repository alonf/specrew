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

function Invoke-TestScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList
    )

    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgumentList 2>&1)
    return @{
        Output   = @($output | ForEach-Object { [string]$_ })
        ExitCode = $LASTEXITCODE
    }
}

function Assert-Contains {
    param(
        [string]$Content,
        [string]$Pattern,
        [string]$FailureMessage
    )

    if ($Content -notmatch $Pattern) {
        Write-Fail $FailureMessage
        return $false
    }

    return $true
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$entryScript = Join-Path $repoRoot 'scripts\specrew.ps1'
$reviewScript = Join-Path $repoRoot 'scripts\specrew-review.ps1'

foreach ($requiredPath in @($entryScript, $reviewScript)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        Write-Fail "Missing required file: $requiredPath"
        exit 1
    }
}

$scratchRoot = Join-Path $repoRoot '.scratch\review-command'
$projectRoot = Join-Path $scratchRoot 'project'
$iterationDirectory = Join-Path $projectRoot 'specs\001-sample\iterations\001'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$null = New-Item -ItemType Directory -Path $iterationDirectory -Force
$null = New-Item -ItemType Directory -Path (Join-Path $projectRoot '.specrew') -Force

[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specrew\config.yml'), "project_name: sample`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $iterationDirectory 'review.md'), @'
# Review: Iteration 001

**Schema**: v1
**Reviewed**: 2026-05-06
**Overall Verdict**: accepted

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T-001 | FR-001 | pass | Good |
| T-002 | FR-002 | pass | Good |
| T-003 | FR-003 | blocked | Needs follow-up |
'@, [System.Text.UTF8Encoding]::new($false))

[System.IO.File]::WriteAllText((Join-Path $iterationDirectory 'reviewer-index.md'), @'
# Reviewer Index: Iteration 001

**Schema**: v1
**Reviewed**: 2026-05-06
**Overall Verdict**: accepted

## Summary

- Header: feature=001-sample | iteration=001 | branch=main | commit_range=abc123..def456
- Verdict: accepted
- Requirements: covered=FR-001, FR-002, FR-003 | not_covered=(none)
- Code Surface: files=4 | hotspots=1 | test_to_code=1:3
- Dependencies: changed=1 | new_to_project=1 | vulnerability=unscanned
- Coverage: kind=qualitative | signal=not_executed
- Operational Signals: escalations=1 | routing_fallbacks=0
- Drift: 1/1 resolved
- Reviewer Index: specs\001-sample\iterations\001\reviewer-index.md
- Implementation Briefing: (unavailable)
- Local Open Hints: specs\001-sample\iterations\001\reviewer-index.md

## Replay Digest

`SPECREW_REVIEW schema=v1 iter=001 feature=001-sample verdict=accepted tasks=2/3 reqs=3 files=4 new_deps=1 vuln=unscanned cov=not_executed escalations=1 drift=1/1 index=specs\001-sample\iterations\001\reviewer-index.md`
'@, [System.Text.UTF8Encoding]::new($false))

foreach ($artifactName in @('code-map.md', 'dependency-report.md', 'coverage-evidence.md', 'drift-log.md')) {
    [System.IO.File]::WriteAllText((Join-Path $iterationDirectory $artifactName), "$artifactName`n", [System.Text.UTF8Encoding]::new($false))
}

Write-Host "Test 1: help advertises reviewer replay"
$helpResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @('review', '--help')
if ($helpResult.ExitCode -ne 0) {
    Write-Fail 'specrew review --help failed'
    exit 1
}

$helpOutput = $helpResult.Output -join "`n"
foreach ($pattern in @('specrew review', '--project-path', '--iteration', '--quiet', '--json', '--open')) {
    if (-not (Assert-Contains -Content $helpOutput -Pattern $pattern -FailureMessage ("Help output is missing '{0}'." -f $pattern))) {
        exit 1
    }
}
Write-Pass 'Help output includes review options'

Write-Host "`nTest 2: human-readable review replay summarizes the latest reviewer packet"
$summaryResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @('review', '--project-path', $projectRoot)
if ($summaryResult.ExitCode -ne 0) {
    Write-Fail 'specrew review summary mode failed'
    exit 1
}

$summaryOutput = $summaryResult.Output -join "`n"
foreach ($pattern in @('SPECREW REVIEWER SUMMARY', 'Header:\s+feature=001-sample\s+\|\s+iteration=001', 'Operational Signals:\s+escalations=1\s+\|\s+routing_fallbacks=0', 'SPECREW_REVIEW schema=v1 iter=001 feature=001-sample verdict=accepted tasks=2/3 reqs=3 files=4 new_deps=1 vuln=unscanned cov=not_executed escalations=1 drift=1/1 index=specs\\001-sample\\iterations\\001\\reviewer-index\.md')) {
    if (-not (Assert-Contains -Content $summaryOutput -Pattern $pattern -FailureMessage ("Summary output is missing '{0}'." -f $pattern))) {
        exit 1
    }
}
Write-Pass 'Summary mode replays the persisted closeout packet'

Write-Host "`nTest 3: quiet mode emits only the digest line"
$quietResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @('review', '--project-path', $projectRoot, '--quiet')
if ($quietResult.ExitCode -ne 0) {
    Write-Fail 'specrew review --quiet failed'
    exit 1
}

$quietOutput = ($quietResult.Output -join "`n").Trim()
if (-not (Assert-Contains -Content $quietOutput -Pattern '^SPECREW_REVIEW schema=v1 iter=001 feature=001-sample verdict=accepted tasks=2/3 reqs=3 files=4 new_deps=1 vuln=unscanned cov=not_executed escalations=1 drift=1/1 index=specs\\001-sample\\iterations\\001\\reviewer-index\.md$' -FailureMessage 'Quiet mode did not emit the expected digest line.')) {
    exit 1
}
Write-Pass 'Quiet mode emits the machine-parseable digest'

Write-Host "`nTest 4: json mode emits structured summary data"
$jsonResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @('review', '--project-path', $projectRoot, '--json')
if ($jsonResult.ExitCode -ne 0) {
    Write-Fail 'specrew review --json failed'
    exit 1
}

$jsonOutput = $jsonResult.Output -join "`n"
foreach ($pattern in @('"feature":\s*"001-sample"', '"iteration":\s*"001"', '"digest":\s*"SPECREW_REVIEW schema=v1 iter=001 feature=001-sample verdict=accepted tasks=2/3 reqs=3 files=4 new_deps=1 vuln=unscanned cov=not_executed escalations=1 drift=1/1 index=specs\\\\001-sample\\\\iterations\\\\001\\\\reviewer-index.md"', '"summary_lines":\s*\[', '"reviewer_index":\s*"specs\\\\001-sample\\\\iterations\\\\001\\\\reviewer-index.md"')) {
    if (-not (Assert-Contains -Content $jsonOutput -Pattern $pattern -FailureMessage ("JSON output is missing '{0}'." -f $pattern))) {
        exit 1
    }
}
Write-Pass 'JSON mode emits structured reviewer summary data'

Write-Host "`nTest 5: reviewer replay surfaces lockout-chain cap state when present"
$capFixturePath = Join-Path $repoRoot 'tests\integration\fixtures\lockout-chain-cap\project'
if (-not (Test-Path -LiteralPath $capFixturePath -PathType Container)) {
    Write-Fail "Missing lockout-chain-cap fixture: $capFixturePath"
    exit 1
}

# Check cap visibility in iteration state.md (FR-011: visibility in handoff surfaces)
$capStateFile = Join-Path $capFixturePath 'specs\008-sample\iterations\001\state.md'
if (-not (Test-Path -LiteralPath $capStateFile -PathType Leaf)) {
    Write-Fail "Missing state.md in lockout-chain-cap fixture: $capStateFile"
    exit 1
}

$capStateContent = Get-Content -LiteralPath $capStateFile -Raw -Encoding utf8
foreach ($pattern in @('Cap Active.*true', 'Lockout Chain Length.*3', 'Next Owner Path')) {
    if (-not (Assert-Contains -Content $capStateContent -Pattern $pattern -FailureMessage ("Cap state.md is missing '{0}'." -f $pattern))) {
        Write-Host "Full state.md content:" -ForegroundColor Yellow
        Write-Host $capStateContent
        exit 1
    }
}
Write-Pass 'Reviewer regression state block includes lockout-chain cap status and next-owner path'

exit 0
