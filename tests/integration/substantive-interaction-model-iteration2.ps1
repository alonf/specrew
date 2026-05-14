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
        [Parameter(Mandatory = $true)][string]$RepoPath,
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $true)][string]$When
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

function Invoke-Validator {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [string]$IterationPath,
        [string]$ResponseText,
        [string]$BoundaryName,
        [string]$ResponseScope
    )

    $args = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $ScriptPath, '-ProjectPath', $ProjectPath)
    if (-not [string]::IsNullOrWhiteSpace($IterationPath)) {
        $args += @('-IterationPath', $IterationPath)
    }
    if (-not [string]::IsNullOrWhiteSpace($ResponseText)) {
        $args += @('-ResponseText', $ResponseText)
    }
    if (-not [string]::IsNullOrWhiteSpace($BoundaryName)) {
        $args += @('-BoundaryName', $BoundaryName)
    }
    if (-not [string]::IsNullOrWhiteSpace($ResponseScope)) {
        $args += @('-ResponseScope', $ResponseScope)
    }

    $output = @(& pwsh @args 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = @($output)
        Text     = ($output -join "`n")
    }
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$validatorScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'
$sharedGovernancePath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1'
$fixtureRoot = Join-Path $repoRoot 'tests\integration\fixtures\016-substantive-interaction-model'
$scratchRoot = Join-Path $repoRoot 'tests\integration\scratch\feature016-iteration2-fixture'
$repoRootUri = ($repoRoot -replace '\\', '/')
. $sharedGovernancePath

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

try {
    #
    # Scenario Group: Docs/template truth
    #
    $docsExpectations = @(
        @{ Path = Join-Path $repoRoot 'README.md'; Pattern = 'Feature 016 Interaction Model' },
        @{ Path = Join-Path $repoRoot 'README.md'; Pattern = 'Post-Commit Verification Protocol' },
        @{ Path = Join-Path $repoRoot 'extensions\specrew-speckit\governance\validation-lane.md'; Pattern = 'substantive-interaction-model-iteration2\.ps1' },
        @{ Path = Join-Path $repoRoot 'extensions\specrew-speckit\governance\validation-lane.md'; Pattern = 'stale-reference scan' },
        @{ Path = Join-Path $repoRoot 'specs\001-specrew-product\contracts\coordinator-handoff-template.md'; Pattern = 'Feature 016 Boundary Worked Examples' },
        @{ Path = Join-Path $repoRoot 'extensions\specrew-speckit\checklists\coordinator-handoff-governance.md'; Pattern = 'Post-commit verification truth' },
        @{ Path = Join-Path $repoRoot 'specs\016-substantive-interaction-model\quickstart.md'; Pattern = 'Iteration 2 Command Matrix' }
    )

    foreach ($expectation in $docsExpectations) {
        $content = Get-Content -LiteralPath $expectation.Path -Raw -Encoding UTF8
        if ($content -notmatch $expectation.Pattern) {
            Write-Fail "Docs/template truth scenario missing expected pattern '$($expectation.Pattern)' in '$($expectation.Path)'."
            exit 1
        }
    }

    #
    # Scenario Group: Navigation graduation
    #
    foreach ($fixtureName in @('violating-boundary-handoff', 'compliant-boundary-handoff', 'exempt-boundary-handoff')) {
        $rawFixture = Get-Content -LiteralPath (Join-Path $fixtureRoot "navigation\$fixtureName.md") -Raw -Encoding UTF8
        $fixtureText = $rawFixture.Replace('__REPO_ROOT__', $repoRoot).Replace('__REPO_ROOT_URI__', $repoRootUri)
        $result = Invoke-Validator -ScriptPath $validatorScript -ProjectPath $repoRoot -ResponseText $fixtureText -BoundaryName 'implementation' -ResponseScope 'boundary-handoff'

        switch ($fixtureName) {
            'violating-boundary-handoff' {
                if ($result.ExitCode -eq 0 -or $result.Text -notmatch 'validation-fail\.bare-path-in-boundary-handoff') {
                    Write-Fail "Expected hard-fail bare-path finding for navigation violating fixture.`n$($result.Text)"
                    exit 1
                }
            }
            default {
                if ($result.ExitCode -ne 0) {
                    Write-Fail "Did not expect failure for navigation fixture '$fixtureName'.`n$($result.Text)"
                    exit 1
                }

                if ($result.Text -match 'bare-path-in-boundary-handoff') {
                    Write-Fail "Did not expect bare-path finding for navigation fixture '$fixtureName'.`n$($result.Text)"
                    exit 1
                }
            }
        }
    }

    #
    # Scenario Group: Authorization fidelity + post-commit verification evidence
    #
    New-Item -ItemType Directory -Path $scratchRoot -Force | Out-Null
    foreach ($directory in @('.github', '.specrew', '.squad', 'specs')) {
        New-Item -ItemType Directory -Path (Join-Path $scratchRoot $directory) -Force | Out-Null
    }

    Copy-Item -LiteralPath (Join-Path $repoRoot '.github\copilot-instructions.md') -Destination (Join-Path $scratchRoot '.github\copilot-instructions.md')
    Copy-Item -LiteralPath (Join-Path $repoRoot '.specrew\config.yml') -Destination (Join-Path $scratchRoot '.specrew\config.yml')
    Copy-Item -LiteralPath (Join-Path $repoRoot '.specrew\iteration-config.yml') -Destination (Join-Path $scratchRoot '.specrew\iteration-config.yml')
    Copy-Item -LiteralPath (Join-Path $repoRoot '.squad\team.md') -Destination (Join-Path $scratchRoot '.squad\team.md')
    Copy-Item -LiteralPath (Join-Path $repoRoot 'specs\016-substantive-interaction-model') -Destination (Join-Path $scratchRoot 'specs\016-substantive-interaction-model') -Recurse

    git -C $scratchRoot init --quiet | Out-Null
    git -C $scratchRoot config user.name 'Copilot Test' | Out-Null
    git -C $scratchRoot config user.email 'copilot-test@example.com' | Out-Null

    @'
# Decisions Ledger

'@ | Set-Content -LiteralPath (Join-Path $scratchRoot '.squad\decisions.md') -Encoding UTF8

    Invoke-GitCommit -RepoPath $scratchRoot -Message 'fixture scaffold' -When '2026-05-14T14:00:00Z'

    $fixtureIteration = Join-Path $scratchRoot 'specs\016-substantive-interaction-model\iterations\002'
    $statePath = Join-Path $fixtureIteration 'state.md'
    $stateContent = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8
    $stateContent = $stateContent -replace '\*\*Current Phase\*\*:.*', '**Current Phase**: implementing'
    $stateContent = $stateContent -replace '\*\*Iteration Status\*\*:.*', '**Iteration Status**: executing'
    Set-Content -LiteralPath $statePath -Value $stateContent -Encoding UTF8

    Add-Content -LiteralPath $statePath -Value "`n- implementation boundary evidence staged" -Encoding UTF8
    Invoke-GitCommit -RepoPath $scratchRoot -Message 'Feature 016 substantive-interaction-model iteration 002: implementation T001-T013' -When '2026-05-14T14:01:00Z'

    $implementationCommitHash = (git -C $scratchRoot rev-parse HEAD).Trim()
    $authorizationText = Get-Content -LiteralPath (Join-Path $fixtureRoot 'authorization-fidelity\authorization-text.txt') -Raw -Encoding UTF8
    Add-InteractionModelAuthorizationEntry -ProjectRoot $scratchRoot -FeatureNumber 16 -IterationNumber 2 -Boundary 'implementation' -Type 'authorization' -ApprovingHuman 'Fixture Human' -AuthorizationText $authorizationText -CommitReference 'pending' -RecordedAt '2026-05-14T14:00:30.789Z' | Out-Null

    $pendingResult = Invoke-Validator -ScriptPath $validatorScript -ProjectPath $scratchRoot -IterationPath $fixtureIteration
    if ($pendingResult.ExitCode -eq 0 -or $pendingResult.Text -notmatch 'non-canonical Recorded At|bundled-boundary-advance') {
        Write-Fail "Expected pending or timestamp failure before post-commit synchronization.`n$($pendingResult.Text)"
        exit 1
    }

    Set-InteractionModelAuthorizationMetadata -ProjectRoot $scratchRoot -DecisionId 'authorization-feature-016-iter-002-implementation' -RecordedAt '2026-05-14T14:00:30.789Z' | Out-Null
    Sync-InteractionModelAuthorizationCommitReference -ProjectRoot $scratchRoot -DecisionId 'authorization-feature-016-iter-002-implementation' -CommitHash $implementationCommitHash | Out-Null

    $fullHashResult = Invoke-Validator -ScriptPath $validatorScript -ProjectPath $scratchRoot -IterationPath $fixtureIteration
    if ($fullHashResult.ExitCode -ne 0) {
        Write-Fail "Did not expect validator failure after full-hash synchronization.`n$($fullHashResult.Text)"
        exit 1
    }

    Sync-InteractionModelAuthorizationCommitReference -ProjectRoot $scratchRoot -DecisionId 'authorization-feature-016-iter-002-implementation' -CommitHash $implementationCommitHash -UseShortHash | Out-Null
    $shortHashResult = Invoke-Validator -ScriptPath $validatorScript -ProjectPath $scratchRoot -IterationPath $fixtureIteration
    if ($shortHashResult.ExitCode -ne 0) {
        Write-Fail "Did not expect validator failure after short-hash synchronization.`n$($shortHashResult.Text)"
        exit 1
    }

    $scanText = @"
Review file:///$($scratchRoot -replace '\\', '/')/specs/016-substantive-interaction-model/iterations/002/plan.md before the review-boundary.
Reference file:///$($scratchRoot -replace '\\', '/')/specs/016-substantive-interaction-model/iterations/002/missing.md if the stale scan is broken.
"@
    $scanResult = Invoke-InteractionModelStaleReferenceScan -ProjectRoot $scratchRoot -Text $scanText
    if ($scanResult.Status -ne 'needs-fix' -or $scanResult.MissingReferences.Count -ne 1) {
        Write-Fail 'Expected stale-reference scan to flag exactly one missing file:/// target.'
        exit 1
    }

    $cleanScanText = "Review file:///$($scratchRoot -replace '\\', '/')/specs/016-substantive-interaction-model/iterations/002/plan.md before the review-boundary."
    $cleanScanResult = Invoke-InteractionModelStaleReferenceScan -ProjectRoot $scratchRoot -Text $cleanScanText
    if ($cleanScanResult.Status -ne 'clean') {
        Write-Fail 'Expected stale-reference scan to stay clean for valid file:/// targets.'
        exit 1
    }
}
finally {
    if (Test-Path -LiteralPath $scratchRoot) {
        Remove-Item -LiteralPath $scratchRoot -Recurse -Force
    }
}

Write-Pass 'Feature 016 Iteration 002 integration replay: docs/template truth, navigation graduation, authorization fidelity, and post-commit verification evidence'
exit 0
