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

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        Write-Fail $Message
        exit 1
    }
}

function Invoke-ValidatorScript {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$ResponseText
    )

    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptPath -ProjectPath $ProjectPath -ResponseText $ResponseText -BoundaryName implementation -ResponseScope boundary-handoff 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Text     = ($output -join "`n")
    }
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$fixtureRoot = Join-Path $repoRoot 'tests\unit\fixtures\016-substantive-interaction-model'
$scratchRoot = Join-Path $repoRoot '.scratch\validate-governance-interaction-model'
$extensionSharedGovernancePath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1'
$specifySharedGovernancePath = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\shared-governance.ps1'
$validatorScripts = @(
    @{ Name = 'extension'; ScriptPath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1' },
    @{ Name = 'specify'; ScriptPath = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\validate-governance.ps1' }
)
$repoRootUri = ($repoRoot -replace '\\', '/')
. $extensionSharedGovernancePath

function New-TestWorkspace {
    param([Parameter(Mandatory = $true)][string]$WorkspaceName)

    $destination = Join-Path $scratchRoot $WorkspaceName
    if (Test-Path -LiteralPath $destination) {
        Remove-Item -LiteralPath $destination -Recurse -Force
    }

    $null = New-Item -ItemType Directory -Path $destination -Force
    foreach ($directory in @('.squad', 'specs\016-substantive-interaction-model\iterations\002')) {
        $null = New-Item -ItemType Directory -Path (Join-Path $destination $directory) -Force
    }

    '# Decisions Ledger' | Set-Content -LiteralPath (Join-Path $destination '.squad\decisions.md') -Encoding UTF8
    '# Iteration State: 002' | Set-Content -LiteralPath (Join-Path $destination 'specs\016-substantive-interaction-model\iterations\002\state.md') -Encoding UTF8
    return $destination
}

function Get-FixtureText {
    param([Parameter(Mandatory = $true)][string]$Name)

    $raw = Get-Content -LiteralPath (Join-Path $fixtureRoot "navigation\$Name.md") -Raw -Encoding UTF8
    return $raw.Replace('__REPO_ROOT__', $repoRoot).Replace('__REPO_ROOT_URI__', $repoRootUri)
}

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

try {
    New-Item -ItemType Directory -Path $scratchRoot -Force | Out-Null

    #
    # Scenario Group: Authorization fidelity
    #
    $canonicalTimestamp = ConvertTo-InteractionModelUtcSeconds -Timestamp '2026-05-14T14:00:30.789+02:00'
    Assert-True -Condition ($canonicalTimestamp -eq '2026-05-14T12:00:30Z') -Message 'Authorization fidelity scenario did not normalize to canonical UTC seconds precision.'

    $authWorkspace = New-TestWorkspace -WorkspaceName 'auth-sync'
    Add-InteractionModelAuthorizationEntry -ProjectRoot $authWorkspace -FeatureNumber 16 -IterationNumber 2 -Boundary implementation -Type authorization -ApprovingHuman 'Fixture Human' -AuthorizationText 'Advance only to implementation.' -CommitReference pending -RecordedAt '2026-05-14T14:00:30Z' | Out-Null
    Sync-InteractionModelAuthorizationCommitReference -ProjectRoot $authWorkspace -DecisionId 'authorization-feature-016-iter-002-implementation' -CommitHash 'abcdef1234567890' -UseShortHash | Out-Null
    Set-InteractionModelAuthorizationMetadata -ProjectRoot $authWorkspace -DecisionId 'authorization-feature-016-iter-002-implementation' -RecordedAt '2026-05-14T14:00:30.999+00:00' | Out-Null
    $authLedgerText = Get-Content -LiteralPath (Join-Path $authWorkspace '.squad\decisions.md') -Raw -Encoding UTF8
    Assert-True -Condition ($authLedgerText -match 'Commit Reference\*\*: abcdef1') -Message 'Authorization fidelity scenario did not synchronize to the expected short hash.'
    Assert-True -Condition ($authLedgerText -match 'Recorded At\*\*: 2026-05-14T14:00:30Z') -Message 'Authorization fidelity scenario did not recanonicalize Recorded At.'

    #
    # Scenario Group: Post-commit verification evidence
    #
    $scanText = @"
Review file:///$repoRootUri/README.md for the implementation boundary.
Reference file:///$repoRootUri/missing.md only if the scan is broken.
"@
    $scanResult = Invoke-InteractionModelStaleReferenceScan -ProjectRoot $repoRoot -Text $scanText
    Assert-True -Condition ($scanResult.Status -eq 'needs-fix') -Message 'Post-commit verification scenario should flag a stale file:/// reference.'
    Assert-True -Condition ($scanResult.MissingReferences.Count -eq 1) -Message 'Post-commit verification scenario should report exactly one missing reference.'

    #
    # Scenario Group: Navigation graduation
    #
    $sharedExtension = Get-Content -LiteralPath $extensionSharedGovernancePath -Raw -Encoding UTF8
    $sharedSpecify = Get-Content -LiteralPath $specifySharedGovernancePath -Raw -Encoding UTF8
    $validatorExtension = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1') -Raw -Encoding UTF8
    $validatorSpecify = Get-Content -LiteralPath (Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\validate-governance.ps1') -Raw -Encoding UTF8
    Assert-True -Condition ($sharedExtension -eq $sharedSpecify) -Message 'Mirrored shared-governance scripts drifted.'
    Assert-True -Condition ($validatorExtension -eq $validatorSpecify) -Message 'Mirrored validate-governance scripts drifted.'

    foreach ($case in $validatorScripts) {
        $violatingResult = Invoke-ValidatorScript -ScriptPath $case.ScriptPath -ProjectPath $repoRoot -ResponseText (Get-FixtureText -Name 'violating-boundary-handoff')
        Assert-True -Condition ($violatingResult.ExitCode -eq 1) -Message "Navigation graduation violating fixture did not fail for $($case.Name)."
        Assert-True -Condition ($violatingResult.Text -match 'validation-fail\.bare-path-in-boundary-handoff') -Message "Navigation graduation violating fixture did not emit the hard-fail rule for $($case.Name)."

        foreach ($fixtureName in @('compliant-boundary-handoff', 'exempt-boundary-handoff')) {
            $result = Invoke-ValidatorScript -ScriptPath $case.ScriptPath -ProjectPath $repoRoot -ResponseText (Get-FixtureText -Name $fixtureName)
            Assert-True -Condition ($result.ExitCode -eq 0) -Message "Navigation graduation fixture '$fixtureName' unexpectedly failed for $($case.Name)."
            Assert-True -Condition ($result.Text -notmatch 'bare-path-in-boundary-handoff') -Message "Navigation graduation fixture '$fixtureName' emitted an unexpected bare-path finding for $($case.Name)."
        }
    }

    #
    # Scenario Group: Docs/template truth
    #
    $quickstartText = Get-Content -LiteralPath (Join-Path $repoRoot 'specs\016-substantive-interaction-model\quickstart.md') -Raw -Encoding UTF8
    $readmeText = Get-Content -LiteralPath (Join-Path $repoRoot 'README.md') -Raw -Encoding UTF8
    $laneText = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions\specrew-speckit\governance\validation-lane.md') -Raw -Encoding UTF8
    Assert-True -Condition ($quickstartText -match 'Iteration 2 Command Matrix') -Message 'Docs/template truth scenario is missing the Iteration 2 command matrix.'
    Assert-True -Condition ($readmeText -match 'Post-Commit Verification Protocol') -Message 'Docs/template truth scenario is missing the README post-commit verification protocol.'
    Assert-True -Condition ($laneText -match 'exact committed tree') -Message 'Docs/template truth scenario is missing exact-tree wording in the validation lane.'
}
finally {
    if (Test-Path -LiteralPath $scratchRoot) {
        Remove-Item -LiteralPath $scratchRoot -Recurse -Force
    }
}

Write-Pass 'Feature 016 Iteration 002 unit coverage: authorization fidelity, post-commit verification evidence, navigation graduation, and docs/template truth'
exit 0
