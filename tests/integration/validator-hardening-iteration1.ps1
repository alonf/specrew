[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

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
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )

    if (-not $Condition) {
        Write-Fail $FailureMessage
        return $false
    }

    return $true
}

function Assert-Match {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )

    if ($Text -notmatch $Pattern) {
        Write-Fail ("{0}`nObserved output:`n{1}" -f $FailureMessage, $Text)
        return $false
    }

    return $true
}

function Assert-NotMatch {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )

    if ($Text -match $Pattern) {
        Write-Fail ("{0}`nObserved output:`n{1}" -f $FailureMessage, $Text)
        return $false
    }

    return $true
}

function New-Workspace {
    param([Parameter(Mandatory = $true)][string]$WorkspaceName)

    $workspaceRoot = Join-Path $scratchRoot $WorkspaceName
    if (Test-Path -LiteralPath $workspaceRoot) {
        Remove-Item -LiteralPath $workspaceRoot -Recurse -Force
    }

    $null = New-Item -ItemType Directory -Path $workspaceRoot -Force

    foreach ($item in @('.specrew', '.squad', '.github')) {
        $source = Join-Path $repoRoot $item
        if (Test-Path -LiteralPath $source) {
            Copy-Item -LiteralPath $source -Destination $workspaceRoot -Recurse -Force
        }
    }

    $contractsSource = Join-Path $repoRoot 'specs\013-validator-hardening\contracts'
    $contractsDestination = Join-Path $workspaceRoot 'specs\013-validator-hardening\contracts'
    $contractsParent = Split-Path -Parent $contractsDestination
    if (-not (Test-Path -LiteralPath $contractsParent)) {
        $null = New-Item -ItemType Directory -Path $contractsParent -Force
    }
    Copy-Item -LiteralPath $contractsSource -Destination $contractsParent -Recurse -Force

    return $workspaceRoot
}

function Set-ContentUtf8 {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        $null = New-Item -ItemType Directory -Path $parent -Force
    }

    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Get-FeaturePlanTemplate {
    param([Parameter(Mandatory = $true)][string]$FeatureId)

    $planContent = Get-Content -LiteralPath $feature013PlanPath -Raw -Encoding UTF8
    if ($FeatureId -ne '013-validator-hardening') {
        $planContent = $planContent -replace '013-validator-hardening', $FeatureId
    }

    return $planContent
}

function Get-FeatureSpecTemplate {
    param([Parameter(Mandatory = $true)][string]$FeatureId)

    $specContent = Get-Content -LiteralPath $feature013SpecPath -Raw -Encoding UTF8
    if ($FeatureId -ne '013-validator-hardening') {
        $specContent = $specContent -replace '013-validator-hardening', $FeatureId
    }

    return $specContent
}

function Get-GateFixtureContent {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$FeatureId
    )

    $content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $content = $content.Replace('__FEATURE_REF__', "specs/$FeatureId/spec.md")
    $content = $content.Replace('__ITERATION_REF__', "specs/$FeatureId/iterations/001")
    return $content
}

function New-FixtureIteration {
    param(
        [Parameter(Mandatory = $true)][string]$WorkspaceName,
        [Parameter(Mandatory = $true)][string]$FeatureId,
        [Parameter(Mandatory = $true)][string]$StateFixturePath,
        [Parameter(Mandatory = $true)][string]$GateFixturePath,
        [switch]$SkipState,
        [switch]$MalformedConfig
    )

    $workspaceRoot = New-Workspace -WorkspaceName $WorkspaceName
    $featureRoot = Join-Path $workspaceRoot ("specs\{0}" -f $FeatureId)
    $iterationRoot = Join-Path $featureRoot 'iterations\001'
    $qualityRoot = Join-Path $iterationRoot 'quality'

    Set-ContentUtf8 -Path (Join-Path $featureRoot 'spec.md') -Content (Get-FeatureSpecTemplate -FeatureId $FeatureId)
    Set-ContentUtf8 -Path (Join-Path $iterationRoot 'plan.md') -Content (Get-FeaturePlanTemplate -FeatureId $FeatureId)
    if (-not $SkipState) {
        Set-ContentUtf8 -Path (Join-Path $iterationRoot 'state.md') -Content (Get-Content -LiteralPath $StateFixturePath -Raw -Encoding UTF8)
    }
    Set-ContentUtf8 -Path (Join-Path $qualityRoot 'hardening-gate.md') -Content (Get-GateFixtureContent -Path $GateFixturePath -FeatureId $FeatureId)

    if ($MalformedConfig) {
        Set-ContentUtf8 -Path (Join-Path $workspaceRoot '.specrew\iteration-config.yml') -Content "reviewer:`n  strongest_available: ["
    }

    return [pscustomobject]@{
        WorkspaceRoot  = $workspaceRoot
        IterationRoot  = $iterationRoot
        RelativeState  = ("specs/{0}/iterations/001/state.md" -f $FeatureId)
        RelativeGate   = ("specs/{0}/iterations/001/quality/hardening-gate.md" -f $FeatureId)
    }
}

function Invoke-Validator {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$IterationPath
    )

    $output = @(
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorScriptPath -ProjectPath $ProjectPath -IterationPath $IterationPath 2>&1
    )

    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = @($output)
        Text     = ($output -join "`n")
    }
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$validatorScriptPath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'
$fixtureRoot = Join-Path $repoRoot 'tests\integration\fixtures\013-validator-hardening'
$scratchRoot = Join-Path $repoRoot '.scratch\validator-hardening-iteration1'
$feature013PlanPath = Join-Path $repoRoot 'specs\013-validator-hardening\iterations\001\plan.md'
$feature013SpecPath = Join-Path $repoRoot 'specs\013-validator-hardening\spec.md'

foreach ($requiredPath in @($validatorScriptPath, $fixtureRoot, $feature013PlanPath, $feature013SpecPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        Write-Fail "Missing validator-hardening iteration 001 dependency: $requiredPath"
        exit 1
    }
}

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$allChecksPassed = $true
$canonicalStateFixture = Join-Path $fixtureRoot 'state-canonical\pending-values.md'
$legacyStateFixture = Join-Path $fixtureRoot 'state-noncanonical\grandfathered-legacy-state.md'
$gateReadyFixture = Join-Path $fixtureRoot 'hardening-gate-canonical\ready-with-extra-row.md'

$scenarios = @(
    @{
        Name              = 'canonical-pass'
        FeatureId         = '013-validator-hardening'
        StateFixturePath  = $canonicalStateFixture
        GateFixturePath   = $gateReadyFixture
        ExpectPass        = $true
        SuccessMessage    = 'Canonical state metadata with extra narrative and a post-canonical concern row passes.'
    },
    @{
        Name              = 'state-noncanonical-label'
        FeatureId         = '013-validator-hardening'
        StateFixturePath  = (Join-Path $fixtureRoot 'state-noncanonical\noncanonical-iteration-status.md')
        GateFixturePath   = $gateReadyFixture
        ExpectPass        = $false
        RequiredPatterns  = @('category=canonical-schema', 'non-canonical label for ''Iteration Status''', 'remediation_hint=Replace it with the canonical metadata line ''\*\*Iteration Status\*\*:''')
        RelativeArtifact  = 'specs/013-validator-hardening/iterations/001/state.md'
        SuccessMessage    = 'Non-canonical Iteration Status label fails with a structured canonical-schema issue.'
    },
    @{
        Name              = 'state-missing-field'
        FeatureId         = '013-validator-hardening'
        StateFixturePath  = (Join-Path $fixtureRoot 'state-noncanonical\missing-current-phase.md')
        GateFixturePath   = $gateReadyFixture
        ExpectPass        = $false
        RequiredPatterns  = @('category=canonical-schema', 'missing canonical field ''Current Phase''', 'file_path=specs/013-validator-hardening/iterations/001/state.md')
        RelativeArtifact  = 'specs/013-validator-hardening/iterations/001/state.md'
        SuccessMessage    = 'Missing Current Phase fails with a structured canonical-schema issue.'
    },
    @{
        Name              = 'grandfathered-legacy-pass'
        FeatureId         = '012-grandfathered-fixture'
        StateFixturePath  = $legacyStateFixture
        GateFixturePath   = $gateReadyFixture
        ExpectPass        = $true
        SuccessMessage    = 'Grandfathered legacy iteration state metadata remains accepted.'
    },
    @{
        Name              = 'missing-canonical-concern'
        FeatureId         = '013-validator-hardening'
        StateFixturePath  = $canonicalStateFixture
        GateFixturePath   = (Join-Path $fixtureRoot 'hardening-gate-noncanonical\missing-error-handling-row.md')
        ExpectPass        = $false
        RequiredPatterns  = @('category=concern-order', 'exactly one canonical concern row for ''error-handling-expectations''', 'file_path=specs/013-validator-hardening/iterations/001/quality/hardening-gate.md')
        RelativeArtifact  = 'specs/013-validator-hardening/iterations/001/quality/hardening-gate.md'
        SuccessMessage    = 'Missing canonical hardening-gate concern fails with a structured concern-order issue.'
    },
    @{
        Name              = 'reordered-canonical-concerns'
        FeatureId         = '013-validator-hardening'
        StateFixturePath  = $canonicalStateFixture
        GateFixturePath   = (Join-Path $fixtureRoot 'hardening-gate-noncanonical\reordered-first-two-rows.md')
        ExpectPass        = $false
        RequiredPatterns  = @('category=concern-order', 'row 1 must be canonical concern ''security-surface'' but found ''error-handling-expectations''', 'file_path=specs/013-validator-hardening/iterations/001/quality/hardening-gate.md')
        RelativeArtifact  = 'specs/013-validator-hardening/iterations/001/quality/hardening-gate.md'
        SuccessMessage    = 'Reordered canonical concerns fail with a structured concern-order issue.'
    },
    @{
        Name              = 'missing-state-file'
        FeatureId         = '013-validator-hardening'
        StateFixturePath  = $canonicalStateFixture
        GateFixturePath   = $gateReadyFixture
        SkipState         = $true
        ExpectPass        = $false
        RequiredPatterns  = @('category=missing-artifact', 'Missing required artifact: state.md', 'file_path=specs/013-validator-hardening/iterations/001/state.md')
        RelativeArtifact  = 'specs/013-validator-hardening/iterations/001/state.md'
        SuccessMessage    = 'Missing state.md fails with a structured missing-artifact issue.'
    },
    @{
        Name              = 'bad-project-path'
        FeatureId         = '013-validator-hardening'
        StateFixturePath  = $canonicalStateFixture
        GateFixturePath   = $gateReadyFixture
        BadProjectPath    = $true
        ExpectPass        = $false
        RequiredPatterns  = @('category=unexpected-validator-error', 'remediation_hint=Repair the validator inputs or configuration and rerun validate-governance.ps1.')
        SuccessMessage    = 'Unexpected validator input is surfaced as structured FAIL output rather than a raw exception.'
    }
)

foreach ($scenario in $scenarios) {
    $fixtureParams = @{
        WorkspaceName   = [string]$scenario.Name
        FeatureId       = [string]$scenario.FeatureId
        StateFixturePath = [string]$scenario.StateFixturePath
        GateFixturePath = [string]$scenario.GateFixturePath
    }
    if ($scenario.ContainsKey('SkipState')) {
        $fixtureParams.SkipState = [bool]$scenario.SkipState
    }
    $fixture = New-FixtureIteration @fixtureParams
    $projectPath = if ($scenario.ContainsKey('BadProjectPath') -and [bool]$scenario.BadProjectPath) {
        Join-Path $fixture.WorkspaceRoot 'missing-project-root'
    }
    else {
        $fixture.WorkspaceRoot
    }
    $result = Invoke-Validator -ProjectPath $projectPath -IterationPath $fixture.IterationRoot

    if ($scenario.ExpectPass) {
        if (-not (Assert-True -Condition ($result.ExitCode -eq 0) -FailureMessage ("{0} should pass validate-governance.ps1." -f $scenario.Name))) {
            $allChecksPassed = $false
            continue
        }

        if (-not (Assert-Match -Text $result.Text -Pattern 'PASS .*iterations\\001' -FailureMessage ("{0} should emit a PASS line." -f $scenario.Name))) {
            $allChecksPassed = $false
            continue
        }

        Write-Pass $scenario.SuccessMessage
        continue
    }

    if (-not (Assert-True -Condition ($result.ExitCode -ne 0) -FailureMessage ("{0} should fail validate-governance.ps1." -f $scenario.Name))) {
        $allChecksPassed = $false
        continue
    }

    foreach ($pattern in $scenario.RequiredPatterns) {
        if (-not (Assert-Match -Text $result.Text -Pattern $pattern -FailureMessage ("{0} output is missing expected structured pattern '{1}'." -f $scenario.Name, $pattern))) {
            $allChecksPassed = $false
        }
    }

    if (-not (Assert-NotMatch -Text $result.Text -Pattern 'CategoryInfo:|FullyQualifiedErrorId|at .*validate-governance\.ps1' -FailureMessage ("{0} should not leak raw PowerShell exception formatting." -f $scenario.Name))) {
        $allChecksPassed = $false
    }

    Write-Pass $scenario.SuccessMessage
}

if (-not $allChecksPassed) {
    exit 1
}

Write-Pass 'Validator hardening Iteration 001 fixtures exercise canonical-schema, concern-order, grandfathering, missing-file, and unexpected-input paths through validate-governance.ps1'
exit 0
