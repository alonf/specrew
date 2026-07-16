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

function Invoke-Git {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Repository,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $output = @(& git -C $Repository @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed in $Repository`: $($output -join "`n")"
    }
    return @($output)
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$entryScript = Join-Path $repoRoot 'scripts\specrew.ps1'
$reviewScript = Join-Path $repoRoot 'scripts\specrew-review.ps1'
$sharedGovernancePath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1'
$manifestPath = Join-Path $repoRoot 'Specrew.psd1'

foreach ($requiredPath in @($entryScript, $reviewScript, $sharedGovernancePath, $manifestPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        Write-Fail "Missing required file: $requiredPath"
        exit 1
    }
}

$manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
$currentSpecrewVersion = [string]$manifest.ModuleVersion

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
foreach ($pattern in @('specrew review', '--project-path', '--iteration', '--quiet', '--json', '--open', '--effort')) {
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
$reviewerIndexJsonPattern = '"reviewer_index":\s*"specs(?:\\\\|/)001-sample(?:\\\\|/)iterations(?:\\\\|/)001(?:\\\\|/)reviewer-index.md"'
foreach ($pattern in @('"feature":\s*"001-sample"', '"iteration":\s*"001"', '"digest":\s*"SPECREW_REVIEW schema=v1 iter=001 feature=001-sample verdict=accepted tasks=2/3 reqs=3 files=4 new_deps=1 vuln=unscanned cov=not_executed escalations=1 drift=1/1 index=specs\\\\001-sample\\\\iterations\\\\001\\\\reviewer-index.md"', '"summary_lines":\s*\[', $reviewerIndexJsonPattern)) {
    if (-not (Assert-Contains -Content $jsonOutput -Pattern $pattern -FailureMessage ("JSON output is missing '{0}'." -f $pattern))) {
        exit 1
    }
}
Write-Pass 'JSON mode emits structured reviewer summary data'

Write-Host "`nTest 5: live review REFUSES an unregistered host loudly (honour-or-surface, never substitute)"
# REWRITTEN 2026-07-08 (co-review finding, run 20260708T115526673): the old Test 5 drove the LEGACY
# pre-worktree-cutover fixture pipeline and asserted its deleted artifact set (review-request.json /
# spawn-invocation.json / gate_state). Under the CURRENT engine + T093 honour-or-surface + the
# D-197-I010-002 loud-fail doctrine, an explicit --host that is not installed+authorized+cataloged
# must fail with a stated reason and write NO gate evidence - never silently substitute a harness.
$liveProjectRoot = Join-Path $scratchRoot 'live-project'
$liveSourcePath = Join-Path $liveProjectRoot 'src\sample.ps1'
$null = New-Item -ItemType Directory -Path (Split-Path -Parent $liveSourcePath) -Force
$null = New-Item -ItemType Directory -Path (Join-Path $liveProjectRoot '.specrew') -Force
[System.IO.File]::WriteAllText((Join-Path $liveProjectRoot '.specrew\config.yml'), "project_name: live-review`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($liveSourcePath, "function Get-Sample { 'before' }`n", [System.Text.UTF8Encoding]::new($false))
Invoke-Git -Repository $liveProjectRoot -Arguments @('init', '--initial-branch=main') | Out-Null
Invoke-Git -Repository $liveProjectRoot -Arguments @('config', 'user.email', 'specrew-test@example.invalid') | Out-Null
Invoke-Git -Repository $liveProjectRoot -Arguments @('config', 'user.name', 'Specrew Test') | Out-Null
Invoke-Git -Repository $liveProjectRoot -Arguments @('add', '.') | Out-Null
Invoke-Git -Repository $liveProjectRoot -Arguments @('commit', '-m', 'baseline') | Out-Null
Add-Content -LiteralPath $liveSourcePath -Value "function Get-SampleAfter { 'after' }" -Encoding UTF8

$liveRunId = 'test-live-unregistered-host'
$liveResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @(
    'review', '--project-path', $liveProjectRoot,
    '--live',
    '--host', 'fixture',
    '--code-writer-host', 'claude',
    '--run-id', $liveRunId
)
if ($liveResult.ExitCode -eq 0) {
    Write-Fail 'specrew review --live with an unregistered --host must exit non-zero (loud refusal)'
    Write-Host ($liveResult.Output -join "`n") -ForegroundColor Yellow
    exit 1
}
$liveOutput = $liveResult.Output -join "`n"
if (-not (Assert-Contains -Content $liveOutput -Pattern 'requested-host-not-available' -FailureMessage 'the refusal must state requested-host-not-available (honour-or-surface)')) {
    exit 1
}
if (-not (Assert-Contains -Content $liveOutput -Pattern 'DID NOT RUN' -FailureMessage 'the refusal must state the co-review did not run')) {
    exit 1
}
if (Test-Path -LiteralPath (Join-Path $liveProjectRoot ".specrew\review\inline\$liveRunId\review-run.json") -PathType Leaf) {
    Write-Fail 'an unregistered-host refusal must not write promoted gate evidence'
    exit 1
}
# D-197-I010-006 / F-198 FR-022 budget-drift regression: with NO --timeout-seconds, the --live door
# must resolve the SAME config/catalog/floor chain as the auto path. An unknown host reaches the
# intentional 600-second terminal floor (300 was superseded as too short); the refused run still
# writes its status envelope.
$liveStatusPath = Join-Path $liveProjectRoot ".specrew\review\pending\$liveRunId\status.json"
if (Test-Path -LiteralPath $liveStatusPath -PathType Leaf) {
    $liveStatus = Get-Content -LiteralPath $liveStatusPath -Raw | ConvertFrom-Json
    if ([int]$liveStatus.timeout_seconds -ne 600) {
        Write-Fail ("default --live budget must use the shared 600s terminal floor, got '{0}'" -f $liveStatus.timeout_seconds)
        exit 1
    }
    Write-Pass 'Default --live budget resolves through the shared chain to the 600s terminal floor'
}
else {
    Write-Fail "expected the refused run's status envelope at $liveStatusPath (needed for the default-budget assertion)"
    exit 1
}
Write-Pass 'Live review refuses an unregistered host loudly and writes no gate evidence'

Write-Host "`nTest 6: --ack-degraded with a flag-shaped run-id fails with precise usage (downstream field bug 2026-07-09)"
# Capture stderr too (2>&1): the guard is a parse-time THROW, which the plain helper's stdout
# capture misses. Assert wrap-proof tokens: 'run-id' + 'Usage' distinguish the precise guard from
# the generic unknown-argument error (which has neither).
$ackOut = @(& pwsh -NoProfile -File $entryScript review --project-path $liveProjectRoot --ack-degraded --ack-reason 'some rationale' 2>&1)
$ackExit = $LASTEXITCODE
if ($ackExit -eq 0) {
    Write-Fail '--ack-degraded without a run-id must exit non-zero'
    exit 1
}
$ackText = ($ackOut | ForEach-Object { [string]$_ }) -join "`n"
if (-not (Assert-Contains -Content $ackText -Pattern 'run-id' -FailureMessage 'the guard names the missing run-id (through the PUBLIC front door - the whitelist must admit the flag first)')) {
    exit 1
}
if (-not (Assert-Contains -Content $ackText -Pattern 'Usage' -FailureMessage 'the guard shows actionable usage (not a generic unknown-argument error)')) {
    exit 1
}
Write-Pass '--ack-degraded flag-shaped run-id is rejected with actionable usage'

Write-Host "`nTest 7: reviewer replay surfaces lockout-chain cap state when present"
$capFixturePath = Join-Path $repoRoot 'tests\integration\fixtures\lockout-chain-cap\project'
if (-not (Test-Path -LiteralPath $capFixturePath -PathType Container)) {
    Write-Fail "Missing lockout-chain-cap fixture: $capFixturePath"
    exit 1
}

$capProjectRoot = Join-Path $scratchRoot 'lockout-chain-cap-project'
Copy-Item -LiteralPath $capFixturePath -Destination $capProjectRoot -Recurse -Force
[System.IO.File]::WriteAllText((Join-Path $capProjectRoot '.specrew\config.yml'), ("project_name: cap-fixture`nspecrew_version: `"{0}`"`nbootstrap_date: `"2026-01-01`"`n" -f $currentSpecrewVersion), [System.Text.UTF8Encoding]::new($false))
$capIterationDirectory = Join-Path $capProjectRoot 'specs\008-sample\iterations\001'

. $sharedGovernancePath
$capPlanLines = Get-Content -LiteralPath (Join-Path $capIterationDirectory 'plan.md') -Encoding UTF8
$capStateLines = Get-Content -LiteralPath (Join-Path $capIterationDirectory 'state.md') -Encoding UTF8
$completedTaskCount = Get-DeclaredCompletedTaskCount -PlanLines $capPlanLines -StateLines $capStateLines
if ($completedTaskCount -ne 0) {
    Write-Fail "Expected Get-DeclaredCompletedTaskCount to treat the cap fixture plan table as status-less and return 0, got $completedTaskCount"
    exit 1
}

# Scaffold reviewer artifacts for the cap fixture to generate reviewer-index.md with cap state
$scaffoldScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\scaffold-reviewer-artifacts.ps1'
if (-not (Test-Path -LiteralPath $scaffoldScript -PathType Leaf)) {
    Write-Fail "Missing scaffold script: $scaffoldScript"
    exit 1
}

$scaffoldResult = Invoke-TestScript -ScriptPath $scaffoldScript -ArgumentList @('-IterationDirectory', $capIterationDirectory, '-DryRun:$false')
if ($scaffoldResult.ExitCode -ne 0) {
    Write-Fail "Failed to scaffold cap fixture reviewer artifacts"
    Write-Host "Scaffold output:" -ForegroundColor Yellow
    $scaffoldResult.Output | ForEach-Object { Write-Host $_ }
    exit 1
}

# Verify scaffolded reviewer-index.md contains cap state fields
$capReviewerIndexPath = Join-Path $capIterationDirectory 'reviewer-index.md'
if (-not (Test-Path -LiteralPath $capReviewerIndexPath -PathType Leaf)) {
    Write-Fail "Scaffolding did not create reviewer-index.md: $capReviewerIndexPath"
    exit 1
}

$capIndexContent = Get-Content -LiteralPath $capReviewerIndexPath -Raw -Encoding utf8
foreach ($pattern in @('Lockout Cap:\s+active', 'chain=\d+/\d+', 'Next Owner:')) {
    if (-not (Assert-Contains -Content $capIndexContent -Pattern $pattern -FailureMessage ("Scaffolded reviewer-index.md is missing cap field '{0}'." -f $pattern))) {
        Write-Host "Full reviewer-index.md content:" -ForegroundColor Yellow
        Write-Host $capIndexContent
        exit 1
    }
}

# Verify specrew review shows cap state
$capReviewResult = Invoke-TestScript -ScriptPath $entryScript -ArgumentList @('review', '--project-path', $capProjectRoot)
if ($capReviewResult.ExitCode -ne 0) {
    Write-Fail 'specrew review on cap fixture failed'
    Write-Host "Review output:" -ForegroundColor Yellow
    $capReviewResult.Output | ForEach-Object { Write-Host $_ }
    exit 1
}

$capReviewOutput = $capReviewResult.Output -join "`n"
foreach ($pattern in @('Lockout Cap:\s+active', 'Next Owner:')) {
    if (-not (Assert-Contains -Content $capReviewOutput -Pattern $pattern -FailureMessage ("specrew review output is missing cap field '{0}'." -f $pattern))) {
        exit 1
    }
}

Write-Pass 'Reviewer replay surfaces lockout-chain cap status and next-owner path via scaffolded artifacts'

exit 0
