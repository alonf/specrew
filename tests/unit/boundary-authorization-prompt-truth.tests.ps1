[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { Write-Fail $Message }
}

function Invoke-HandoffValidator {
    param(
        [string]$ValidatorPath,
        [string]$ProjectRoot,
        [string]$FixturePath
    )

    $text = Get-Content -LiteralPath $FixturePath -Raw -Encoding UTF8
    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ValidatorPath -ProjectRoot $ProjectRoot -ResponseText $text -BoundaryName plan -ResponseScope boundary-handoff 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Text     = ($output -join "`n")
    }
}

function New-ApprovedStatusWorkspace {
    param(
        [string]$Root,
        [bool]$WithVerdictEvidence
    )

    if (Test-Path -LiteralPath $Root) { Remove-Item -LiteralPath $Root -Recurse -Force }
    New-Item -ItemType Directory -Path $Root -Force | Out-Null
    git -C $Root init --quiet
    pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot 'scripts\specrew-init.ps1') -ProjectPath $Root -Force -NoAgents | Out-Null

    $featurePath = Join-Path $Root 'specs\001-test'
    New-Item -ItemType Directory -Path $featurePath -Force | Out-Null
    "# Feature Specification: Test`n`n**Status**: Approved`n" | Set-Content -LiteralPath (Join-Path $featurePath 'spec.md') -Encoding UTF8

    $verdictHistory = @()
    if ($WithVerdictEvidence) {
        $verdictHistory = @([ordered]@{
                from_boundary     = 'clarify'
                to_boundary       = 'plan'
                verdict_text      = 'approved for plan'
                authorizing_human = 'Fixture Human'
                recorded_at       = '2026-06-01T00:00:00Z'
                auth_commit_hash  = 'abcdef1'
            })
    }

    $policyClasses = [ordered]@{}
    foreach ($boundary in @('specify', 'clarify', 'plan', 'tasks', 'before-implement', 'review-signoff', 'retro', 'iteration-closeout', 'feature-closeout')) {
        $policyClasses[$boundary] = 'human-judgment-required'
    }

    $context = [ordered]@{
        schema               = 'v2'
        session_state        = [ordered]@{
            active           = $true
            boundary_type    = 'clarify'
            feature_ref      = '001-test'
            feature_path     = $featurePath
            iteration_number = '001'
            task_id          = $null
            auth_commit_hash = $null
            recorded_at      = '2026-06-01T00:00:00Z'
        }
        boundary_enforcement = [ordered]@{
            enabled                  = $true
            last_authorized_boundary = 'clarify'
            pending_next_boundary    = $null
            verdict_history          = $verdictHistory
            bypass_history           = @()
            policy_classes           = $policyClasses
        }
    }

    ($context | ConvertTo-Json -Depth 12) | Set-Content -LiteralPath (Join-Path $Root '.specrew\start-context.json') -Encoding UTF8
}

function Assert-PowerShellParses {
    param([string]$Path)

    $tokens = $null
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors) | Out-Null
    $message = if ($parseErrors.Count -gt 0) { $parseErrors[0].Message } else { '' }
    Assert-True ($parseErrors.Count -eq 0) "$Path parse errors: $message"
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$startScriptPath = Join-Path $repoRoot 'scripts\specrew-start.ps1'
$sharedGovernancePath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1'
$sharedGovernanceMirrorPath = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\shared-governance.ps1'
$validatorPath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'
$validatorMirrorPath = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\validate-governance.ps1'
$handoffValidatorPath = Join-Path $repoRoot 'extensions\specrew-speckit\validators\handoff-governance-validator.ps1'
$handoffValidatorMirrorPath = Join-Path $repoRoot '.specify\extensions\specrew-speckit\validators\handoff-governance-validator.ps1'
$fixtureRoot = Join-Path $repoRoot 'tests\unit\fixtures\139-boundary-authorization-prompt-truth\handoffs'
$scratchRoot = Join-Path $repoRoot '.scratch\boundary-authorization-prompt-truth-unit'

Assert-True ((Get-Content -LiteralPath $sharedGovernancePath -Raw -Encoding UTF8) -eq (Get-Content -LiteralPath $sharedGovernanceMirrorPath -Raw -Encoding UTF8)) 'shared-governance mirror drifted.'
Assert-True ((Get-Content -LiteralPath $validatorPath -Raw -Encoding UTF8) -eq (Get-Content -LiteralPath $validatorMirrorPath -Raw -Encoding UTF8)) 'validate-governance mirror drifted.'
Assert-True ((Get-Content -LiteralPath $handoffValidatorPath -Raw -Encoding UTF8) -eq (Get-Content -LiteralPath $handoffValidatorMirrorPath -Raw -Encoding UTF8)) 'handoff validator mirror drifted.'
Write-Pass 'Mirrored governance files remain identical'

Assert-PowerShellParses -Path $startScriptPath
Assert-PowerShellParses -Path $sharedGovernancePath
Assert-PowerShellParses -Path $validatorPath
Write-Pass 'Edited PowerShell files parse'

$startScript = Get-Content -LiteralPath $startScriptPath -Raw -Encoding UTF8
Assert-True ($startScript -notmatch 'is the only gate that HARD-BLOCKS') 'Start prompt still contains beta2 four-gate hard-block wording.'
Assert-True ($startScript -notmatch 'continue automatically through `speckit\.specrew-speckit\.before-plan`, `speckit\.plan`, `speckit\.tasks`') 'Start prompt still contains beta2 auto-chain wording.'
foreach ($required in @(
        'boundary_enforcement.policy_classes',
        '.specrew/config.yml',
        'clarify -> plan',
        '## What I Just Did',
        '## Why I Stopped',
        '## What Needs Your Review',
        '## What Happens Next',
        '## Discussion Prompts',
        '## What I Need From You',
        'file:///',
        'You can answer any prompt that should change direction, or approve with the defaults.',
        'approve as-is, approve with instructions, send back, or discuss prompt #N',
        'free-form discussion or feedback is not approval'
    )) {
    Assert-True ($startScript.Contains($required)) "Start prompt is missing required contract text: $required"
}
Assert-True ($startScript -notmatch 'append this exact fenced block') 'Start prompt still requires legacy handoff-block duplication as the primary stop contract.'
Write-Pass 'Generated prompt contract text covers policy truth and the six-section packet'

if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $scratchRoot '.specrew') -Force | Out-Null
@'
schema: "v1"
boundary_enforcement:
  policy_classes:
    specify: "human-judgment-required"
    clarify: "human-judgment-required"
    plan: "human-judgment-required"
    tasks: "human-judgment-required"
    before-implement: "human-judgment-required"
    review-signoff: "human-judgment-required"
    retro: "human-judgment-required"
    iteration-closeout: "human-judgment-required"
    feature-closeout: "human-judgment-required"
'@ | Set-Content -LiteralPath (Join-Path $scratchRoot '.specrew\config.yml') -Encoding UTF8
. $sharedGovernancePath
$policyMap = Get-SpecrewBoundaryPolicyClassMap -ProjectRoot $scratchRoot
foreach ($boundary in (Get-SpecrewCanonicalBoundaryTypes)) {
    Assert-True ($policyMap[$boundary] -eq 'human-judgment-required') "Policy snapshot did not resolve $boundary from .specrew/config.yml."
}
$state = New-SpecrewBoundaryEnforcementState -CurrentBoundary clarify -ProjectRoot $scratchRoot
Assert-True ($null -ne $state['policy_classes'] -and $state['policy_classes']['plan'] -eq 'human-judgment-required') 'Boundary enforcement state did not include policy_classes snapshot.'
Write-Pass 'Boundary policy snapshot resolves from .specrew/config.yml'

foreach ($case in @(
        @{ Name = 'missing-why-stopped.md'; Pattern = 'validation-fail\.incomplete-human-reentry-packet' },
        @{ Name = 'approve-only-without-discussion.md'; Pattern = 'validation-fail\.non-contextual-discussion-prompts' },
        @{ Name = 'context-free-discussion-prompt.md'; Pattern = 'validation-fail\.non-contextual-discussion-prompts' }
    )) {
    foreach ($scriptPath in @($handoffValidatorPath, $handoffValidatorMirrorPath)) {
        $result = Invoke-HandoffValidator -ValidatorPath $scriptPath -ProjectRoot $repoRoot -FixturePath (Join-Path $fixtureRoot $case.Name)
        Assert-True ($result.ExitCode -eq 1) "Fixture $($case.Name) unexpectedly passed with $scriptPath."
        Assert-True ($result.Text -match $case.Pattern) "Fixture $($case.Name) did not emit $($case.Pattern). Output: $($result.Text)"
    }
}
Write-Pass 'Non-compliant human re-entry packet fixtures fail'

$validatorText = Get-Content -LiteralPath $validatorPath -Raw -Encoding UTF8
Assert-True ($validatorText -match 'function Test-ApprovedFeatureStatusVerdictEvidence') 'Validator missing Status: Approved verdict-evidence check.'
Assert-True ($validatorText -match 'approved-status-without-verdict') 'Validator missing approved-status-without-verdict finding.'

$badApprovedRoot = Join-Path $scratchRoot 'approved-without-verdict'
New-ApprovedStatusWorkspace -Root $badApprovedRoot -WithVerdictEvidence:$false
$badApprovedOutput = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorPath -ProjectPath $badApprovedRoot 2>&1)
Assert-True ($LASTEXITCODE -eq 1) 'Status: Approved without verdict evidence should fail validation.'
Assert-True (($badApprovedOutput -join "`n") -match 'approved-status-without-verdict') 'Status: Approved failure did not emit approved-status-without-verdict.'

$goodApprovedRoot = Join-Path $scratchRoot 'approved-with-verdict'
New-ApprovedStatusWorkspace -Root $goodApprovedRoot -WithVerdictEvidence:$true
$goodApprovedOutput = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorPath -ProjectPath $goodApprovedRoot 2>&1)
Assert-True ($LASTEXITCODE -eq 0) "Status: Approved with verdict evidence should pass validation. Output: $($goodApprovedOutput -join "`n")"
Assert-True (($goodApprovedOutput -join "`n") -notmatch 'approved-status-without-verdict') 'Status: Approved with verdict evidence emitted unexpected contradiction finding.'
Write-Pass 'Status: Approved contradiction check flags missing verdicts and accepts matching evidence'

if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force }
Write-Host ''
Write-Host 'Boundary authorization prompt truth unit assertions: all pass'
exit 0
