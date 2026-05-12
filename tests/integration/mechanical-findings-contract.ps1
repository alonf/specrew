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
        [Parameter(Mandatory = $true)]
        [bool]$Condition,

        [Parameter(Mandatory = $true)]
        [string]$FailureMessage
    )

    if (-not $Condition) {
        Write-Fail $FailureMessage
        return $false
    }

    return $true
}

function Read-JsonFixture {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 32
}

function Test-FixtureAgainstSchema {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$SchemaPath
    )

    try {
        $null = Test-Json -Path $Path -SchemaFile $SchemaPath -WarningAction SilentlyContinue
        return $true
    }
    catch {
        return $false
    }
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$fixtureRoot = Join-Path $repoRoot 'tests\integration\fixtures\mechanical-findings-contract'
$schemaPath = Join-Path $repoRoot 'specs\005-stack-aware-quality-bar\contracts\mechanical-findings.schema.json'
$baselineFixturePath = Join-Path $fixtureRoot 'valid-mechanical-findings.json'
$demotedFixturePath = Join-Path $fixtureRoot 'demoted-mechanical-findings.json'
$invalidDemotionFixturePath = Join-Path $fixtureRoot 'demoted-mechanical-findings-missing-disposition.json'

$allChecksPassed = $true

foreach ($requiredPath in @($fixtureRoot, $schemaPath, $baselineFixturePath, $demotedFixturePath, $invalidDemotionFixturePath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        Write-Fail "Missing mechanical findings contract dependency: $requiredPath"
        $allChecksPassed = $false
    }
}

if (-not $allChecksPassed) {
    exit 1
}

if (-not (Assert-True -Condition (Test-FixtureAgainstSchema -Path $baselineFixturePath -SchemaPath $schemaPath) -FailureMessage 'Baseline mechanical findings fixture does not satisfy the v1 schema contract.')) {
    $allChecksPassed = $false
}

if (-not (Assert-True -Condition (Test-FixtureAgainstSchema -Path $demotedFixturePath -SchemaPath $schemaPath) -FailureMessage 'Demoted mechanical findings fixture does not satisfy the v1 schema contract.')) {
    $allChecksPassed = $false
}

if (-not (Assert-True -Condition (-not (Test-FixtureAgainstSchema -Path $invalidDemotionFixturePath -SchemaPath $schemaPath)) -FailureMessage 'Schema contract should reject demoted findings that omit dispositionRef.')) {
    $allChecksPassed = $false
}

$baselinePayload = Read-JsonFixture -Path $baselineFixturePath
$demotedPayload = Read-JsonFixture -Path $demotedFixturePath

if (-not (Assert-True -Condition ($baselinePayload.schemaVersion -eq 'v1') -FailureMessage 'Baseline fixture did not persist schemaVersion=v1.')) {
    $allChecksPassed = $false
}

if (-not (Assert-True -Condition ($baselinePayload.generator.name -eq 'specrew-mechanical-contract-fixture') -FailureMessage 'Baseline fixture did not include the expected generator name.')) {
    $allChecksPassed = $false
}

$expectedRuleIds = @(
    'dead-field.websocket-payload-unused'
    'anti-pattern.fire-and-forget-broadcast'
    'test-integrity.smoke-only-handshake'
)

$baselineRuleIds = @($baselinePayload.findings | ForEach-Object { [string]$_.ruleId })
foreach ($expectedRuleId in $expectedRuleIds) {
    if (-not (Assert-True -Condition ($baselineRuleIds -contains $expectedRuleId) -FailureMessage ("Baseline fixture did not keep the Phase 1 rule '{0}' visible." -f $expectedRuleId))) {
        $allChecksPassed = $false
    }
}

$gateRequirementMap = @{
    'dead-field'    = 'FR-027'
    'anti-pattern'  = 'FR-028'
    'test-integrity'= 'FR-029'
}

foreach ($finding in $baselinePayload.findings) {
    if (-not (Assert-True -Condition (-not [System.IO.Path]::IsPathRooted([string]$finding.source.path)) -FailureMessage ("Finding '{0}' should use a repo-relative source path." -f $finding.findingId))) {
        $allChecksPassed = $false
    }

    if (-not (Assert-True -Condition ([string]::IsNullOrWhiteSpace([string]$finding.remediation) -eq $false) -FailureMessage ("Finding '{0}' should include remediation guidance." -f $finding.findingId))) {
        $allChecksPassed = $false
    }

    if (-not (Assert-True -Condition ($finding.requirementRefs -contains 'FR-030') -FailureMessage ("Finding '{0}' should trace machine-readable output to FR-030." -f $finding.findingId))) {
        $allChecksPassed = $false
    }

    $requiredTrace = $gateRequirementMap[[string]$finding.gateId]
    if ($requiredTrace) {
        if (-not (Assert-True -Condition ($finding.requirementRefs -contains $requiredTrace) -FailureMessage ("Finding '{0}' did not keep the expected gate trace '{1}'." -f $finding.findingId, $requiredTrace))) {
            $allChecksPassed = $false
        }
    }
}

if (-not (Assert-True -Condition (@($baselinePayload.findings).Count -eq @($demotedPayload.findings).Count) -FailureMessage 'Demotion fixture should keep the full findings set visible instead of removing noisy rules.')) {
    $allChecksPassed = $false
}

$demotedFinding = @($demotedPayload.findings | Where-Object { $_.ruleId -eq 'anti-pattern.fire-and-forget-broadcast' })[0]
if (-not (Assert-True -Condition ($null -ne $demotedFinding) -FailureMessage 'Demotion fixture did not keep the anti-pattern finding visible.')) {
    $allChecksPassed = $false
}
else {
    if (-not (Assert-True -Condition ($demotedFinding.demoted -eq $true) -FailureMessage 'Demoted anti-pattern finding should set demoted=true.')) {
        $allChecksPassed = $false
    }

    if (-not (Assert-True -Condition ([string]::IsNullOrWhiteSpace([string]$demotedFinding.dispositionRef) -eq $false) -FailureMessage 'Demoted anti-pattern finding should include a dispositionRef.')) {
        $allChecksPassed = $false
    }

    if (-not (Assert-True -Condition ($demotedFinding.requirementRefs -contains 'FR-030a') -FailureMessage 'Demoted anti-pattern finding should trace the reviewed demotion workflow via FR-030a.')) {
        $allChecksPassed = $false
    }
}

if (-not $allChecksPassed) {
    exit 1
}

Write-Pass 'Mechanical findings contract fixtures keep the Phase 1 rule set schema-compliant and make demoted rules remain visible with disposition references'
exit 0
