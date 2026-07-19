[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

function Invoke-TestScript {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList
    )

    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgumentList 2>&1)
    return @{
        Output = @($output | ForEach-Object { [string]$_ })
        ExitCode = $LASTEXITCODE
    }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$env:SPECREW_MODULE_PATH = $repoRoot
$syncScript = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1'
$scratchRoot = Join-Path $repoRoot '.scratch\pending-verdict-stop-artifact'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

function New-TestProject {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [AllowNull()][string]$LastAuthorizedBoundary
    )

    $projectRoot = Join-Path $scratchRoot $Name
    foreach ($relativeDirectory in @('.specrew', '.specify', '.squad', '.github\agents', 'specs\001-test-feature')) {
        $null = New-Item -ItemType Directory -Path (Join-Path $projectRoot $relativeDirectory) -Force
    }

    [System.IO.File]::WriteAllText((Join-Path $projectRoot '.specrew\config.yml'), "project_name: sample`nspecrew_version: `"0.0.0`"`nbootstrap_date: `"2026-01-01`"`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $projectRoot '.specify\feature.json'), "{`n  `"feature_directory`": `"specs/001-test-feature`"`n}", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $projectRoot '.squad\team.md'), "# Team`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $projectRoot '.squad\config.json'), "{}`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $projectRoot '.squad\decisions.md'), "# Decisions`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $projectRoot '.github\agents\squad.agent.md'), "# Squad Agent`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $projectRoot 'specs\001-test-feature\spec.md'), "# Spec`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $projectRoot 'README.md'), "# Test Repo`n", [System.Text.UTF8Encoding]::new($false))

    $context = [ordered]@{
        schema = 'v2'
        feature_path = Join-Path $projectRoot 'specs\001-test-feature'
        generated_at_utc = '2026-06-22T00:00:00Z'
        session_state = [ordered]@{
            active = $true
            boundary_type = $null
            feature_ref = '001-test-feature'
            feature_path = Join-Path $projectRoot 'specs\001-test-feature'
            iteration_number = '001'
            task_id = $null
            auth_commit_hash = $null
            recorded_at = '2026-06-22T00:00:00Z'
        }
        boundary_enforcement = [ordered]@{
            enabled = $true
            last_authorized_boundary = if ([string]::IsNullOrWhiteSpace($LastAuthorizedBoundary)) { $null } else { $LastAuthorizedBoundary }
            pending_next_boundary = $null
            verdict_history = @()
            bypass_history = @()
        }
    }
    [System.IO.File]::WriteAllText((Join-Path $projectRoot '.specrew\start-context.json'), ($context | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))

    $null = & git -C $projectRoot init --quiet 2>&1
    $null = & git -C $projectRoot config user.email 'test@specrew.local' 2>&1
    $null = & git -C $projectRoot config user.name 'Test User' 2>&1
    $null = & git -C $projectRoot add -A 2>&1
    $null = & git -C $projectRoot commit -m 'Seed repository' --quiet 2>&1
    $null = & git -C $projectRoot branch -M main 2>&1
    $null = & git -C $projectRoot checkout -b 001-test-feature 2>&1

    return $projectRoot
}

function Invoke-BoundarySync {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$BoundaryType
    )

    $result = Invoke-TestScript -ScriptPath $syncScript -ArgumentList @(
        '-ProjectPath', $ProjectRoot,
        '-BoundaryType', $BoundaryType,
        '-FeatureRef', '001-test-feature',
        '-IterationNumber', '001',
        '-AuthCommitHash', 'HEAD'
    )

    if ($result.ExitCode -ne 0) {
        Fail ("Boundary sync '{0}' failed:`n{1}" -f $BoundaryType, ($result.Output -join [Environment]::NewLine))
    }

    return ($result.Output -join [Environment]::NewLine)
}

function Assert-ArtifactContains {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$ExpectedBoundary,
        [Parameter(Mandatory = $true)][string]$ExpectedApproval,
        [Parameter(Mandatory = $true)][string]$ExpectedMarker,
        [AllowNull()][string]$ForbiddenText,
        [AllowNull()][string]$SyncOutput
    )

    $artifactPath = Join-Path $ProjectRoot '.specrew\runtime\pending-verdict-stop.md'
    if (-not (Test-Path -LiteralPath $artifactPath -PathType Leaf)) {
        Fail "Expected pending-verdict stop artifact missing: $artifactPath"
    }

    $content = Get-Content -LiteralPath $artifactPath -Raw -Encoding UTF8
    $context = Get-Content -LiteralPath (Join-Path $ProjectRoot '.specrew\start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $scope = $context.boundary_enforcement.pending_crossing
    if ($null -eq $scope -or [string]$scope.crossing_id -notmatch '^crossing-[0-9a-f]{64}$') {
        Fail 'Pending-verdict artifact was written without a stable scoped crossing identity.'
    }
    $expectedCommit = (& git -C $ProjectRoot rev-parse HEAD).Trim()
    $expectedTree = (& git -C $ProjectRoot rev-parse 'HEAD^{tree}').Trim()
    if ([string]$scope.boundary_commit_hash -ne $expectedCommit -or [string]$scope.artifact_state_id -ne $expectedTree) {
        Fail ("Pending crossing did not bind the actual current boundary commit/tree. Expected {0}/{1}; found {2}/{3}." -f $expectedCommit, $expectedTree, $scope.boundary_commit_hash, $scope.artifact_state_id)
    }
    foreach ($expected in @(
        "Boundary to ask for: $ExpectedBoundary",
        "Human approval phrase: $ExpectedApproval",
        "Approval choice: $ExpectedApproval",
        'Numeric labels are non-authoritative; reply with the full human approval phrase.',
        $ExpectedMarker
    )) {
        if ($content -notmatch [regex]::Escape($expected)) {
            Fail ("Pending-verdict artifact did not contain expected text '{0}'. Content:`n{1}" -f $expected, $content)
        }
        if (-not [string]::IsNullOrWhiteSpace($SyncOutput) -and $SyncOutput -notmatch [regex]::Escape($expected)) {
            Fail ("Boundary sync output did not surface expected text '{0}'. Output:`n{1}" -f $expected, $SyncOutput)
        }
    }

    foreach ($expectedScopedLine in @(
        "Crossing ID: $($scope.crossing_id)",
        "Boundary commit hash: $($scope.boundary_commit_hash)",
        "Artifact state: git-tree $($scope.artifact_state_id)"
    )) {
        if ($content -notmatch [regex]::Escape($expectedScopedLine)) {
            Fail ("Pending-verdict artifact did not contain scoped identity '{0}'. Content:`n{1}" -f $expectedScopedLine, $content)
        }
    }
    foreach ($expectedScopedValue in @($scope.crossing_id, $scope.boundary_commit_hash, $scope.artifact_state_id)) {
        if (-not [string]::IsNullOrWhiteSpace($SyncOutput) -and $SyncOutput -notmatch [regex]::Escape([string]$expectedScopedValue)) {
            Fail ("Boundary sync output did not expose scoped identity '{0}'. Output:`n{1}" -f $expectedScopedValue, $SyncOutput)
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($ForbiddenText) -and $content -match [regex]::Escape($ForbiddenText)) {
        Fail ("Pending-verdict artifact contained forbidden text '{0}'. Content:`n{1}" -f $ForbiddenText, $content)
    }
}

try {
    $firstProject = New-TestProject -Name 'first-boundary' -LastAuthorizedBoundary $null
    $firstOutput = Invoke-BoundarySync -ProjectRoot $firstProject -BoundaryType 'specify'
    Assert-ArtifactContains `
        -ProjectRoot $firstProject `
        -ExpectedBoundary 'intake -> specify' `
        -ExpectedApproval 'approved for specify' `
        -ExpectedMarker '<!-- SPECREW-VERDICT-BOUNDARY: intake -> specify -->' `
        -ForbiddenText 'approved for clarify' `
        -SyncOutput $firstOutput
    Write-Pass 'sync-specify writes and surfaces the first-boundary pending verdict stop artifact'

    $overAdvanceProject = New-TestProject -Name 'over-advance' -LastAuthorizedBoundary $null
    $overAdvanceOutput = Invoke-BoundarySync -ProjectRoot $overAdvanceProject -BoundaryType 'clarify'
    Assert-ArtifactContains `
        -ProjectRoot $overAdvanceProject `
        -ExpectedBoundary 'intake -> specify' `
        -ExpectedApproval 'approved for specify' `
        -ExpectedMarker '<!-- SPECREW-VERDICT-BOUNDARY: intake -> specify -->' `
        -ForbiddenText 'approved for clarify' `
        -SyncOutput $overAdvanceOutput
    Write-Pass 'multi-boundary over-advance still surfaces the first unpaid crossing, not the working cursor'

    $clarifyProject = New-TestProject -Name 'clarify-boundary' -LastAuthorizedBoundary 'specify'
    $clarifyOutput = Invoke-BoundarySync -ProjectRoot $clarifyProject -BoundaryType 'clarify'
    Assert-ArtifactContains `
        -ProjectRoot $clarifyProject `
        -ExpectedBoundary 'specify -> clarify' `
        -ExpectedApproval 'approved for clarify' `
        -ExpectedMarker '<!-- SPECREW-VERDICT-BOUNDARY: specify -> clarify -->' `
        -ForbiddenText 'approved for specify' `
        -SyncOutput $clarifyOutput
    Write-Pass 'sync-clarify after specify authorization surfaces specify -> clarify'

    $completedTasksProject = New-TestProject -Name 'completed-tasks-opens-next-crossing' -LastAuthorizedBoundary 'tasks'
    $stalePath = Join-Path $completedTasksProject '.specrew\runtime\pending-verdict-stop.md'
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $stalePath) -Force
    [System.IO.File]::WriteAllText($stalePath, "stale`n", [System.Text.UTF8Encoding]::new($false))
    $tasksOutput = Invoke-BoundarySync -ProjectRoot $completedTasksProject -BoundaryType 'tasks'
    Assert-ArtifactContains `
        -ProjectRoot $completedTasksProject `
        -ExpectedBoundary 'tasks -> before-implement' `
        -ExpectedApproval 'approved for before-implement' `
        -ExpectedMarker '<!-- SPECREW-VERDICT-BOUNDARY: tasks -> before-implement -->' `
        -ForbiddenText 'approved for tasks' `
        -SyncOutput $tasksOutput
    $firstRender = Get-Content -LiteralPath $stalePath -Raw -Encoding UTF8
    . (Join-Path $repoRoot 'scripts\internal\sync-boundary-state.ps1')
    $repeatSession = (Get-Content -LiteralPath (Join-Path $completedTasksProject '.specrew\start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json).session_state
    $null = Sync-SpecrewPendingVerdictStopArtifact -ProjectRoot $completedTasksProject -SessionState $repeatSession
    $repeatRender = Get-Content -LiteralPath $stalePath -Raw -Encoding UTF8
    if ($repeatRender -cne $firstRender) {
        $renderDiff = Compare-Object -ReferenceObject @($firstRender -split "`r?`n") -DifferenceObject @($repeatRender -split "`r?`n") | Out-String
        Fail "Repeated sync of the same completed boundary changed the exact pending-crossing packet. Diff:`n$renderDiff"
    }
    Assert-ArtifactContains `
        -ProjectRoot $completedTasksProject `
        -ExpectedBoundary 'tasks -> before-implement' `
        -ExpectedApproval 'approved for before-implement' `
        -ExpectedMarker '<!-- SPECREW-VERDICT-BOUNDARY: tasks -> before-implement -->' `
        -ForbiddenText 'approved for tasks' `
        -SyncOutput $null
    Write-Pass 'authorized tasks sync opens one stable tasks -> before-implement crossing at the exact current commit/tree'

    $bareNumericVerdict = Parse-SpecrewBoundaryVerdict -VerdictText '1'
    if ([bool]$bareNumericVerdict.Authorized) {
        Fail 'Bare-number verdict unexpectedly authorized the scoped crossing.'
    }
    Write-Pass 'bare-number reply remains non-authoritative'

    $closeoutProject = New-TestProject -Name 'closeout-current-not-stale-parent' -LastAuthorizedBoundary 'iteration-closeout'
    $staleParent = (& git -C $closeoutProject rev-parse HEAD).Trim()
    [System.IO.File]::AppendAllText((Join-Path $closeoutProject 'README.md'), "`nActual closeout artifact.`n", [System.Text.UTF8Encoding]::new($false))
    $null = & git -C $closeoutProject add README.md 2>&1
    $null = & git -C $closeoutProject commit -m 'Actual closeout boundary' --quiet 2>&1
    $actualCloseout = (& git -C $closeoutProject rev-parse HEAD).Trim()
    $beforeRejectedSync = Get-Content -LiteralPath (Join-Path $closeoutProject '.specrew\start-context.json') -Raw -Encoding UTF8
    $staleResult = Invoke-TestScript -ScriptPath $syncScript -ArgumentList @(
        '-ProjectPath', $closeoutProject,
        '-BoundaryType', 'iteration-closeout',
        '-FeatureRef', '001-test-feature',
        '-IterationNumber', '001',
        '-AuthCommitHash', $staleParent
    )
    $staleOutput = ($staleResult.Output -join [Environment]::NewLine)
    $stalePlain = (($staleOutput -replace "`e\[[0-9;?]*[ -/]*[@-~]", '') -replace '\s+', ' ').Trim()
    $hasCurrentExplanation =
        ($stalePlain -match 'is stale; the actual current boundary commit is') -and
        ($stalePlain -match [regex]::Escape("HEAD '$actualCloseout'"))
    if ($staleResult.ExitCode -eq 0 -or -not $hasCurrentExplanation) {
        Fail ("Stale pre-closeout parent was not refused with the current-commit explanation. Output:`n{0}" -f ($staleResult.Output -join [Environment]::NewLine))
    }
    $afterRejectedSync = Get-Content -LiteralPath (Join-Path $closeoutProject '.specrew\start-context.json') -Raw -Encoding UTF8
    if ($afterRejectedSync -cne $beforeRejectedSync) {
        Fail 'Rejected stale-parent sync mutated the authorization context.'
    }
    $closeoutOutput = Invoke-BoundarySync -ProjectRoot $closeoutProject -BoundaryType 'iteration-closeout'
    Assert-ArtifactContains `
        -ProjectRoot $closeoutProject `
        -ExpectedBoundary 'iteration-closeout -> plan' `
        -ExpectedApproval 'approved for plan' `
        -ExpectedMarker '<!-- SPECREW-VERDICT-BOUNDARY: iteration-closeout -> plan -->' `
        -ForbiddenText $staleParent `
        -SyncOutput $closeoutOutput
    $closeoutScope = (Get-Content -LiteralPath (Join-Path $closeoutProject '.specrew\start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json).boundary_enforcement.pending_crossing
    if ([string]$closeoutScope.boundary_commit_hash -ne $actualCloseout) {
        Fail 'Closeout crossing did not bind the actual closeout commit after the stale parent was refused.'
    }
    Write-Pass 'stale pre-closeout parent is refused and the actual closeout commit/tree renders the next crossing'

    Write-Host "`n=== pending-verdict-stop-artifact.tests.ps1: all assertions passed ===" -ForegroundColor Green
    exit 0
}
finally {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force -ErrorAction SilentlyContinue
}
