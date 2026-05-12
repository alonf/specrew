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

function Assert-Condition {
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

function Get-MarkdownSectionTable {
    param(
        [AllowEmptyString()]
        [Parameter(Mandatory = $true)]
        [string[]]$Lines,

        [Parameter(Mandatory = $true)]
        [string]$Heading
    )

    $headingPattern = '^#{2,3}\s+' + [regex]::Escape($Heading) + '\b'
    $startIndex = -1

    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match $headingPattern) {
            $startIndex = $index
            break
        }
    }

    if ($startIndex -lt 0) {
        return @()
    }

    $tableLines = New-Object System.Collections.Generic.List[string]
    for ($index = $startIndex + 1; $index -lt $Lines.Count; $index++) {
        $currentLine = $Lines[$index]
        if ($currentLine -match '^#{2,3}\s+') {
            break
        }

        if ($currentLine.Trim().StartsWith('|')) {
            $null = $tableLines.Add($currentLine)
        }
    }

    if ($tableLines.Count -lt 2) {
        return @()
    }

    $headers = ($tableLines[0].Trim('|') -split '\|') | ForEach-Object { $_.Trim() }
    $rows = New-Object System.Collections.Generic.List[object]

    for ($rowIndex = 1; $rowIndex -lt $tableLines.Count; $rowIndex++) {
        $cells = ($tableLines[$rowIndex].Trim('|') -split '\|') | ForEach-Object { $_.Trim() }
        $isSeparator = $true

        foreach ($cell in $cells) {
            if ($cell -notmatch '^:?-{3,}:?$') {
                $isSeparator = $false
                break
            }
        }

        if ($isSeparator) {
            continue
        }

        $row = [ordered]@{}
        for ($cellIndex = 0; $cellIndex -lt $headers.Count; $cellIndex++) {
            $value = if ($cellIndex -lt $cells.Count) { $cells[$cellIndex] } else { '' }
            $row[$headers[$cellIndex]] = $value
        }

        $rows.Add([pscustomobject]$row)
    }

    return $rows.ToArray()
}

function Normalize-MarkdownCell {
    param([AllowNull()][string]$Value)

    if ($null -eq $Value) {
        return ''
    }

    return $Value.Trim().Trim('`')
}

function Assert-RequiredGatesCovered {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PlanPath,

        [Parameter(Mandatory = $true)]
        [string]$EvidencePath,

        [Parameter(Mandatory = $true)]
        [string]$FailurePrefix
    )

    $planLines = @(Get-Content -LiteralPath $PlanPath -Encoding UTF8)
    $evidenceLines = @(Get-Content -LiteralPath $EvidencePath -Encoding UTF8)
    $requiredGateRows = @(Get-MarkdownSectionTable -Lines $planLines -Heading 'Required Quality Gates')
    $evidenceRows = @(Get-MarkdownSectionTable -Lines $evidenceLines -Heading 'Gate Matrix')

    if ($requiredGateRows.Count -eq 0) {
        Write-Fail "$FailurePrefix plan fixture is missing the Required Quality Gates table."
        return $false
    }

    if ($evidenceRows.Count -eq 0) {
        Write-Fail "$FailurePrefix evidence fixture is missing the Gate Matrix table."
        return $false
    }

    $allChecksPassed = $true
    foreach ($requiredGate in $requiredGateRows) {
        $requiredGateId = Normalize-MarkdownCell ([string]$requiredGate.'Required Quality Gate')
        $match = @(
            $evidenceRows |
                Where-Object { (Normalize-MarkdownCell ([string]$_.Gate)) -eq $requiredGateId } |
                Select-Object -First 1
        )

        if ($match.Count -eq 0) {
            Write-Fail ("{0} evidence matrix is missing required gate '{1}'." -f $FailurePrefix, $requiredGateId)
            $allChecksPassed = $false
            continue
        }

        $evidenceSource = Normalize-MarkdownCell ([string]$match[0].'Evidence Source')
        if ([string]::IsNullOrWhiteSpace($evidenceSource)) {
            Write-Fail ("{0} evidence matrix gate '{1}' is missing an Evidence Source entry." -f $FailurePrefix, $requiredGateId)
            $allChecksPassed = $false
        }
    }

    return $allChecksPassed
}

function Assert-GateMissing {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PlanPath,

        [Parameter(Mandatory = $true)]
        [string]$EvidencePath,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedGateId
    )

    $planLines = @(Get-Content -LiteralPath $PlanPath -Encoding UTF8)
    $evidenceLines = @(Get-Content -LiteralPath $EvidencePath -Encoding UTF8)
    $requiredGateRows = @(Get-MarkdownSectionTable -Lines $planLines -Heading 'Required Quality Gates')
    $evidenceRows = @(Get-MarkdownSectionTable -Lines $evidenceLines -Heading 'Gate Matrix')

    $requiredGateIds = @($requiredGateRows | ForEach-Object { Normalize-MarkdownCell ([string]$_.'Required Quality Gate') })
    if ($requiredGateIds -notcontains $ExpectedGateId) {
        Write-Fail "Missing-evidence fixture does not declare required gate '$ExpectedGateId' in the plan."
        return $false
    }

    $observedGateIds = @($evidenceRows | ForEach-Object { Normalize-MarkdownCell ([string]$_.Gate) })
    if ($observedGateIds -contains $ExpectedGateId) {
        Write-Fail "Missing-evidence fixture unexpectedly includes gate '$ExpectedGateId' in quality-evidence.md."
        return $false
    }

    return $true
}

function New-TestWorkspace {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScratchRoot,

        [Parameter(Mandatory = $true)]
        [string]$FixtureProjectPath,

        [Parameter(Mandatory = $true)]
        [string]$WorkspaceName
    )

    $workspaceRoot = Join-Path $ScratchRoot $WorkspaceName
    if (Test-Path -LiteralPath $workspaceRoot) {
        Remove-Item -LiteralPath $workspaceRoot -Recurse -Force
    }

    $null = New-Item -ItemType Directory -Path $workspaceRoot -Force
    Copy-Item -Path (Join-Path $FixtureProjectPath '*') -Destination $workspaceRoot -Recurse -Force
    return $workspaceRoot
}

function Invoke-Validator {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ValidatorScriptPath,

        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [string]$IterationPath
    )

    $output = @(
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $ValidatorScriptPath -ProjectPath $ProjectPath -IterationPath $IterationPath 2>&1
    )

    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = @($output)
        Text     = ($output -join "`n")
    }
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$validatorScriptPath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'
$sharedGovernancePath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1'
$fixtureRoot = Join-Path $repoRoot 'tests\integration\fixtures\quality-evidence-governance'
$scratchRoot = Join-Path $repoRoot '.scratch\quality-evidence-governance'

foreach ($requiredPath in @($validatorScriptPath, $sharedGovernancePath, $fixtureRoot)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        Write-Fail "Missing quality-evidence governance dependency: $requiredPath"
        exit 1
    }
}

. $sharedGovernancePath

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$completeFixtureProject = Join-Path $fixtureRoot 'complete-evidence\project'
$missingFixtureProject = Join-Path $fixtureRoot 'missing-evidence\project'
$hardeningApprovedFixtureProject = Join-Path $fixtureRoot 'hardening-gate-approved\project'
$hardeningBlockedFixtureProject = Join-Path $fixtureRoot 'hardening-gate-blocked\project'
$completeWorkspace = New-TestWorkspace -ScratchRoot $scratchRoot -FixtureProjectPath $completeFixtureProject -WorkspaceName 'complete-evidence'
$missingWorkspace = New-TestWorkspace -ScratchRoot $scratchRoot -FixtureProjectPath $missingFixtureProject -WorkspaceName 'missing-evidence'
$hardeningApprovedWorkspace = New-TestWorkspace -ScratchRoot $scratchRoot -FixtureProjectPath $hardeningApprovedFixtureProject -WorkspaceName 'hardening-gate-approved'
$hardeningBlockedWorkspace = New-TestWorkspace -ScratchRoot $scratchRoot -FixtureProjectPath $hardeningBlockedFixtureProject -WorkspaceName 'hardening-gate-blocked'
$implicitHardeningWorkspace = New-TestWorkspace -ScratchRoot $scratchRoot -FixtureProjectPath $hardeningApprovedFixtureProject -WorkspaceName 'hardening-gate-implicit'

$completeIterationPath = Join-Path $completeWorkspace 'specs\005-quality-evidence\iterations\001'
$missingIterationPath = Join-Path $missingWorkspace 'specs\005-quality-evidence\iterations\001'
$completePlanPath = Join-Path $completeIterationPath 'plan.md'
$completeEvidencePath = Join-Path $completeIterationPath 'quality\quality-evidence.md'
$missingPlanPath = Join-Path $missingIterationPath 'plan.md'
$missingEvidencePath = Join-Path $missingIterationPath 'quality\quality-evidence.md'
$hardeningApprovedIterationPath = Join-Path $hardeningApprovedWorkspace 'specs\005-quality-evidence\iterations\001'
$hardeningBlockedIterationPath = Join-Path $hardeningBlockedWorkspace 'specs\005-quality-evidence\iterations\001'
$implicitHardeningIterationPath = Join-Path $implicitHardeningWorkspace 'specs\005-quality-evidence\iterations\001'
$hardeningApprovedGatePath = Join-Path $hardeningApprovedIterationPath 'quality\hardening-gate.md'
$hardeningBlockedGatePath = Join-Path $hardeningBlockedIterationPath 'quality\hardening-gate.md'
$implicitHardeningPlanPath = Join-Path $implicitHardeningIterationPath 'plan.md'
$implicitHardeningGatePath = Join-Path $implicitHardeningIterationPath 'quality\hardening-gate.md'

$implicitPlanContent = Get-Content -LiteralPath $implicitHardeningPlanPath -Raw -Encoding UTF8
$implicitPlanReplacement = @'
## Iteration Acceptance Criteria

1. The repair preserves one `hardening-gate.md` artifact across lifecycle phases.
2. Pre-implementation readiness requires planning-time analysis, expected controls, rationale, and explicit non-applicable reasoning rather than runtime-only proof.
3. Runtime-only concerns remain visibly open or pending until later runtime evidence is recorded before closure.

## Notes

- This iteration relies on `specs/005-quality-evidence/iterations/001/quality/hardening-gate.md` as the lifecycle-visible hardening artifact.
- Runtime evidence remains pending post-implementation for applicable concerns.
'@
$implicitPlanContent = [regex]::Replace(
    $implicitPlanContent,
    '(?s)\r?\n## Phase 2 Hardening and Specialist Review Planning.*?(?=\r?\n## Tasks)',
    "`r`n$implicitPlanReplacement`r`n"
)
[System.IO.File]::WriteAllText($implicitHardeningPlanPath, $implicitPlanContent, [System.Text.UTF8Encoding]::new($false))

$allChecksPassed = $true

if (Assert-RequiredGatesCovered -PlanPath $completePlanPath -EvidencePath $completeEvidencePath -FailurePrefix 'Complete-evidence fixture') {
    Write-Pass 'Complete-evidence fixture records every declared Phase 1 quality gate in quality-evidence.md.'
}
else {
    $allChecksPassed = $false
}

if (Assert-GateMissing -PlanPath $missingPlanPath -EvidencePath $missingEvidencePath -ExpectedGateId 'quality-lens-review') {
    Write-Pass 'Missing-evidence fixture intentionally omits the quality-lens-review gate from quality-evidence.md.'
}
else {
    $allChecksPassed = $false
}

$approvedHardeningState = Get-HardeningGateState -Path $hardeningApprovedGatePath -ProjectRoot $hardeningApprovedWorkspace
$approvedOperationalConcern = @($approvedHardeningState.ConcernRows | Where-Object { [string]$_.Concern -eq 'operational-resilience-concerns' })[0]
if (-not (Assert-Condition -Condition (
            [string]$approvedOperationalConcern.Status -eq 'deferred-with-approval' -and
            [string]$approvedOperationalConcern.EvidenceBasis -eq 'planning-time-analysis' -and
            [string]$approvedOperationalConcern.RuntimeEvidenceStatus -eq 'pending-post-implementation' -and
            -not (Test-IsNullish ([string]$approvedOperationalConcern.ExpectedControls))
        ) -FailureMessage 'Approved hardening fixture must keep planning-time analysis, expected controls, and pending runtime evidence visible for the deferred operational concern.')) {
    $allChecksPassed = $false
}
else {
    Write-Pass 'Approved hardening fixture keeps planning-time analysis and pending runtime evidence visible for the deferred operational concern.'
}

$blockedHardeningState = Get-HardeningGateState -Path $hardeningBlockedGatePath -ProjectRoot $hardeningBlockedWorkspace
$blockedOperationalConcern = @($blockedHardeningState.ConcernRows | Where-Object { [string]$_.Concern -eq 'operational-resilience-concerns' })[0]
if (-not (Assert-Condition -Condition (
            [string]$blockedOperationalConcern.Status -eq 'tbd' -and
            (Test-IsNullish ([string]$blockedOperationalConcern.EvidenceBasis))
        ) -FailureMessage 'Blocked hardening fixture must leave the unresolved operational concern without planning-time analysis.')) {
    $allChecksPassed = $false
}
else {
    Write-Pass 'Blocked hardening fixture keeps the unresolved operational concern missing planning-time analysis.'
}

$completeValidation = Invoke-Validator -ValidatorScriptPath $validatorScriptPath -ProjectPath $completeWorkspace -IterationPath $completeIterationPath
if ($completeValidation.ExitCode -ne 0) {
    Write-Fail 'validate-governance should accept the complete-evidence fixture.'
    foreach ($line in $completeValidation.Output) {
        Write-Host $line
    }
    $allChecksPassed = $false
}
else {
    Write-Pass 'validate-governance accepts the complete-evidence fixture.'
}

$missingValidation = Invoke-Validator -ValidatorScriptPath $validatorScriptPath -ProjectPath $missingWorkspace -IterationPath $missingIterationPath
if ($missingValidation.ExitCode -eq 0) {
    Write-Fail 'validate-governance should fail closed when quality-evidence.md omits a declared required gate.'
    $allChecksPassed = $false
}
elseif ($missingValidation.Text -notmatch 'quality-evidence|missing evidence|quality-lens-review|required gate') {
    Write-Fail 'validate-governance failed the missing-evidence fixture, but the failure did not mention the missing quality evidence gate.'
    foreach ($line in $missingValidation.Output) {
        Write-Host $line
    }
    $allChecksPassed = $false
}
else {
    Write-Pass 'validate-governance rejects the missing-evidence fixture with a quality-evidence-specific failure.'
}

$hardeningApprovedValidation = Invoke-Validator -ValidatorScriptPath $validatorScriptPath -ProjectPath $hardeningApprovedWorkspace -IterationPath $hardeningApprovedIterationPath
if ($hardeningApprovedValidation.ExitCode -ne 0) {
    Write-Fail 'validate-governance should accept the hardening-gate-approved fixture when the deferment carries explicit human approval evidence.'
    foreach ($line in $hardeningApprovedValidation.Output) {
        Write-Host $line
    }
    $allChecksPassed = $false
}
else {
    Write-Pass 'validate-governance accepts the hardening-gate-approved fixture once human-approved defer evidence is present.'
}

$hardeningBlockedValidation = Invoke-Validator -ValidatorScriptPath $validatorScriptPath -ProjectPath $hardeningBlockedWorkspace -IterationPath $hardeningBlockedIterationPath
if ($hardeningBlockedValidation.ExitCode -eq 0) {
    Write-Fail 'validate-governance should fail when an executing iteration still has a blocked hardening gate.'
    $allChecksPassed = $false
}
elseif ($hardeningBlockedValidation.Text -notmatch 'hardening-gate|blocks implementation|operational-resilience-concerns') {
    Write-Fail 'validate-governance failed the blocked hardening fixture, but the failure did not mention the blocking hardening concern.'
    foreach ($line in $hardeningBlockedValidation.Output) {
        Write-Host $line
    }
    $allChecksPassed = $false
}
elseif ($hardeningBlockedValidation.Text -notmatch 'planning-time analysis|Expected Controls') {
    Write-Fail 'validate-governance failed the blocked hardening fixture, but the failure did not mention the missing planning-time analysis boundary.'
    foreach ($line in $hardeningBlockedValidation.Output) {
        Write-Host $line
    }
    $allChecksPassed = $false
}
else {
    Write-Pass 'validate-governance rejects the blocked hardening fixture with a hardening-gate-specific failure.'
}

$implicitHardeningValidation = Invoke-Validator -ValidatorScriptPath $validatorScriptPath -ProjectPath $implicitHardeningWorkspace -IterationPath $implicitHardeningIterationPath
if ($implicitHardeningValidation.ExitCode -ne 0) {
    Write-Fail 'validate-governance should accept an iteration-local hardening gate even when the legacy Phase 2 metadata section is absent.'
    foreach ($line in $implicitHardeningValidation.Output) {
        Write-Host $line
    }
    $allChecksPassed = $false
}
else {
    Write-Pass 'validate-governance accepts the implicit iteration-local hardening-gate plan shape.'
}

$implicitCorruptedGate = (Get-Content -LiteralPath $implicitHardeningGatePath -Raw -Encoding UTF8) -replace '\*\*Gate ID\*\*: `pre-implementation-hardening`', '**Gate ID**: `broken-hardening-gate`'
[System.IO.File]::WriteAllText($implicitHardeningGatePath, $implicitCorruptedGate, [System.Text.UTF8Encoding]::new($false))

$implicitCorruptedValidation = Invoke-Validator -ValidatorScriptPath $validatorScriptPath -ProjectPath $implicitHardeningWorkspace -IterationPath $implicitHardeningIterationPath
if ($implicitCorruptedValidation.ExitCode -eq 0) {
    Write-Fail 'validate-governance should fail when an implicit iteration-local hardening gate drifts out of contract.'
    $allChecksPassed = $false
}
elseif ($implicitCorruptedValidation.Text -notmatch 'Gate ID|hardening-gate') {
    Write-Fail 'validate-governance failed the implicit hardening-gate regression, but the failure did not mention the drifted hardening metadata.'
    foreach ($line in $implicitCorruptedValidation.Output) {
        Write-Host $line
    }
    $allChecksPassed = $false
}
else {
    Write-Pass 'validate-governance rejects a drifted implicit iteration-local hardening gate.'
}

if (-not $allChecksPassed) {
    exit 1
}

Write-Pass 'Quality evidence governance regressions passed.'
