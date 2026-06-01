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

function Invoke-HandoffValidatorText {
    param(
        [string]$ValidatorPath,
        [string]$ProjectRoot,
        [string]$Text
    )

    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ValidatorPath -ProjectRoot $ProjectRoot -ResponseText $Text -BoundaryName plan -ResponseScope boundary-handoff 2>&1)
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
$repoRootUri = ($repoRoot -replace '\\', '/')
$startScriptPath = Join-Path $repoRoot 'scripts\specrew-start.ps1'
$syncBoundaryScriptPath = Join-Path $repoRoot 'scripts\internal\sync-boundary-state.ps1'
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
Assert-PowerShellParses -Path $syncBoundaryScriptPath
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
        'Core Specrew defines the response contract and allowed response shapes',
        'The selected host package renders the interaction behavior below',
        'free-form discussion or feedback is not approval',
        'Every artifact, file, or directory reference in every packet section MUST use',
        'visible bare ``file:///`` URLs',
        'Do not use markdown-link syntax for boundary packets',
        'The packet text recorded as boundary evidence MUST be the exact human-visible packet',
        'not bare repository paths such as'
    )) {
    Assert-True ($startScript.Contains($required)) "Start prompt is missing required contract text: $required"
}
Assert-True ($startScript -notmatch 'append this exact fenced block') 'Start prompt still requires legacy handoff-block duplication as the primary stop contract.'
Assert-True ($startScript -notmatch 'clickable markdown links using `file:///` URLs') 'Start prompt still tells agents to use markdown links for artifacts.'
Assert-True ($startScript -notmatch 'wrap the reference in markdown-link syntax') 'Start prompt still instructs markdown-link artifact references.'
Assert-True ($startScript -notmatch 'On Copilot CLI / Codex CLI / Antigravity') 'Start prompt core Rule 53 still mentions host-specific CLI behavior.'
Assert-True ($startScript -notmatch 'Squad handles the rest of the lifecycle automatically') 'Start prompt core Rule 53 still claims Squad lifecycle execution.'
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

$packetWithBareReferences = @'
## What I just did

I completed T001, T002, and T003 for FR-001, the packet-wide clickable reference rule. The affected artifacts include specs/139-boundary-authorization-prompt-truth/iterations/001/retro.md and .specrew/start-context.json, which are intentionally bare here.

## Why I stopped

I stopped at the plan boundary because .squad/decisions.md must record explicit approval evidence before the next lifecycle step.

## What needs your review

Review README.md and specs/139-boundary-authorization-prompt-truth/iterations/001/drift-log.md before approving.

## What happens next

If approved, I will update tests/unit/boundary-authorization-prompt-truth.tests.ps1 and then stop again at the next human boundary.

## Discussion prompts

Because this packet includes artifact references across several sections, should the default be to block every bare repository path? I recommend blocking all authored packet references unless they are inside a command or code block; otherwise the next handoff can regress.

## What I need from you

Review .specrew/handoff-evidence.json and approve or send back the plan boundary.
'@

$packetWithExemptReferences = @'
## What I just did

I completed T001, T002, and T003 for FR-001, the packet-wide clickable reference rule. I verified file:///__REPO_ROOT_URI__/specs/139-boundary-authorization-prompt-truth/iterations/001/retro.md, file:///__REPO_ROOT_URI__/.specrew/start-context.json, and file:///__REPO_ROOT_URI__/tests/unit/boundary-authorization-prompt-truth.tests.ps1 for the current boundary evidence.

## Why I stopped

I stopped at the plan boundary because the next lifecycle step requires a human verdict before I proceed.

## What needs your review

Review file:///__REPO_ROOT_URI__/specs/139-boundary-authorization-prompt-truth/iterations/001/drift-log.md before approving.

## What happens next

If approved, I will keep the validator evidence path active and stop again at the next human boundary.

## Discussion prompts

Because this packet includes command examples, should explicit code blocks remain exempt from clickable-reference enforcement? I recommend yes; otherwise valid commands become noisy and less copyable.

## What I need from you

Review file:///__REPO_ROOT_URI__/.specrew/handoff-evidence.json and approve or send back the plan boundary.

```powershell
Get-Content specs/139-boundary-authorization-prompt-truth/iterations/001/retro.md
Get-Content .specrew/start-context.json
Get-Content .squad/decisions.md
Get-Content README.md
pwsh -File tests/unit/boundary-authorization-prompt-truth.tests.ps1
```
'@.Replace('__REPO_ROOT_URI__', $repoRootUri)

$packetWithBarePrimaryReviewTargets = @'
## What I just did

I closed the iteration and recorded the closeout evidence for the boundary packet repair.

## Why I stopped

I stopped at the iteration-closeout boundary because explicit approval is required before feature-closeout.

## What needs your review

Review specs/139-boundary-authorization-prompt-truth/iterations/001/dashboard.md, specs/139-boundary-authorization-prompt-truth/iterations/001/quality/hardening-gate.md, specs/139-boundary-authorization-prompt-truth/iterations/001/drift-log.md, and specs/139-boundary-authorization-prompt-truth/iterations/001/quality/quality-evidence.md before approving.

## What happens next

If approved, I will proceed to feature-closeout.

## Discussion prompts

Because the primary review section contains artifact references, should the validator block bare repository paths there? I recommend yes; otherwise D-004 is not enforced across the packet body.

## What I need from you

Review file:///__REPO_ROOT_URI__/specs/139-boundary-authorization-prompt-truth/iterations/001/dashboard.md and approve or send back the iteration-closeout boundary.
'@.Replace('__REPO_ROOT_URI__', $repoRootUri)

$packetWithBarePrimaryReviewTargetsAndCompliantLegacy = @'
## What I just did

I closed Feature 139 feature-closeout and recorded the closeout evidence for the boundary packet repair.

## Why I stopped

I stopped at the feature-closeout boundary because release-closeout needs explicit approval before stable promotion.

## What needs your review

Review specs/139-boundary-authorization-prompt-truth/closeout-dashboard.md, specs/139-boundary-authorization-prompt-truth/iterations/001/dashboard.md, specs/139-boundary-authorization-prompt-truth/iterations/001/drift-log.md, specs/139-boundary-authorization-prompt-truth/iterations/001/quality/quality-evidence.md, and specs/139-boundary-authorization-prompt-truth/smoke/beta3-smoke-evidence.md before approving.

## What happens next

If approved, I will proceed to release-closeout and keep stable promotion blocked until beta replay passes.

## Discussion prompts

Because the primary packet body contains artifact references while the legacy block is compliant, should the validator fail the whole packet? I recommend yes; otherwise a compliant legacy block can hide a non-clickable primary packet.

## What I need from you

Review file:///__REPO_ROOT_URI__/specs/139-boundary-authorization-prompt-truth/closeout-dashboard.md and approve or send back the feature-closeout boundary.

=== SPECREW HANDOFF ===
STOPPED AT: feature-closeout
STATUS: Feature 139 closeout pending release approval
WHY STOPPED: release-closeout requires human approval
AGENT NEXT ACTION:
  - Use file:///__REPO_ROOT_URI__/specs/139-boundary-authorization-prompt-truth/smoke/beta3-smoke-evidence.md for release-closeout evidence
HUMAN ACTION NEEDED:
  - Review file:///__REPO_ROOT_URI__/specs/139-boundary-authorization-prompt-truth/closeout-dashboard.md
RESUME WITH: approve release-closeout
=== END SPECREW HANDOFF ===
'@.Replace('__REPO_ROOT_URI__', $repoRootUri)

$packetWithMarkdownPrimaryReviewTargetsAndCompliantLegacy = @'
## What I just did

I closed Feature 139 feature-closeout and recorded the closeout evidence for the boundary packet repair.

## Why I stopped

I stopped at the feature-closeout boundary because release-closeout needs explicit approval before stable promotion.

## What needs your review

Review [closeout-dashboard.md](file:///__REPO_ROOT_URI__/specs/139-boundary-authorization-prompt-truth/closeout-dashboard.md), [dashboard.md](file:///__REPO_ROOT_URI__/specs/139-boundary-authorization-prompt-truth/iterations/001/dashboard.md), [drift-log.md](file:///__REPO_ROOT_URI__/specs/139-boundary-authorization-prompt-truth/iterations/001/drift-log.md), [quality-evidence.md](file:///__REPO_ROOT_URI__/specs/139-boundary-authorization-prompt-truth/iterations/001/quality/quality-evidence.md), and [beta3-smoke-evidence.md](file:///__REPO_ROOT_URI__/specs/139-boundary-authorization-prompt-truth/smoke/beta3-smoke-evidence.md) before approving.

## What happens next

If approved, I will proceed to release-closeout and keep stable promotion blocked until beta replay passes.

## Discussion prompts

Because markdown file links hide the visible file URI in terminal hosts, should boundary validation reject them even when the legacy block uses bare file URIs? I recommend yes; otherwise the stored packet can validate while the visible primary packet is not directly clickable.

## What I need from you

Review file:///__REPO_ROOT_URI__/specs/139-boundary-authorization-prompt-truth/closeout-dashboard.md and approve or send back the feature-closeout boundary.

=== SPECREW HANDOFF ===
STOPPED AT: feature-closeout
STATUS: Feature 139 closeout pending release approval
WHY STOPPED: release-closeout requires human approval
AGENT NEXT ACTION:
  - Use file:///__REPO_ROOT_URI__/specs/139-boundary-authorization-prompt-truth/smoke/beta3-smoke-evidence.md for release-closeout evidence
HUMAN ACTION NEEDED:
  - Review file:///__REPO_ROOT_URI__/specs/139-boundary-authorization-prompt-truth/closeout-dashboard.md
RESUME WITH: approve release-closeout
=== END SPECREW HANDOFF ===
'@.Replace('__REPO_ROOT_URI__', $repoRootUri)

foreach ($scriptPath in @($handoffValidatorPath, $handoffValidatorMirrorPath)) {
    $bareResult = Invoke-HandoffValidatorText -ValidatorPath $scriptPath -ProjectRoot $repoRoot -Text $packetWithBareReferences
    Assert-True ($bareResult.ExitCode -eq 1) "Packet-wide bare artifact references unexpectedly passed with $scriptPath."
    Assert-True ($bareResult.Text -match 'validation-fail\.bare-path-in-boundary-handoff') "Packet-wide bare artifact references did not emit the hard-fail rule. Output: $($bareResult.Text)"
    foreach ($expectedPath in @('specs/139-boundary-authorization-prompt-truth/iterations/001/retro.md', '.specrew/start-context.json', '.squad/decisions.md', 'README.md', 'tests/unit/boundary-authorization-prompt-truth.tests.ps1')) {
        Assert-True ($bareResult.Text -match [regex]::Escape($expectedPath)) "Bare path '$expectedPath' was not reported. Output: $($bareResult.Text)"
    }

    $primaryReviewResult = Invoke-HandoffValidatorText -ValidatorPath $scriptPath -ProjectRoot $repoRoot -Text $packetWithBarePrimaryReviewTargets
    Assert-True ($primaryReviewResult.ExitCode -eq 1) "Bare primary review targets unexpectedly passed with $scriptPath."
    Assert-True ($primaryReviewResult.Text -match 'validation-fail\.bare-path-in-boundary-handoff') "Bare primary review targets did not emit the hard-fail rule. Output: $($primaryReviewResult.Text)"
    foreach ($expectedPath in @(
            'specs/139-boundary-authorization-prompt-truth/iterations/001/dashboard.md',
            'specs/139-boundary-authorization-prompt-truth/iterations/001/quality/hardening-gate.md',
            'specs/139-boundary-authorization-prompt-truth/iterations/001/drift-log.md',
            'specs/139-boundary-authorization-prompt-truth/iterations/001/quality/quality-evidence.md'
        )) {
        Assert-True ($primaryReviewResult.Text -match [regex]::Escape($expectedPath)) "Bare primary review target '$expectedPath' was not reported. Output: $($primaryReviewResult.Text)"
    }

    $primaryWithLegacyResult = Invoke-HandoffValidatorText -ValidatorPath $scriptPath -ProjectRoot $repoRoot -Text $packetWithBarePrimaryReviewTargetsAndCompliantLegacy
    Assert-True ($primaryWithLegacyResult.ExitCode -eq 1) "Bare primary review targets with compliant legacy block unexpectedly passed with $scriptPath."
    Assert-True ($primaryWithLegacyResult.Text -match 'validation-fail\.bare-path-in-boundary-handoff') "Bare primary targets with compliant legacy block did not emit the hard-fail rule. Output: $($primaryWithLegacyResult.Text)"

    $markdownPrimaryResult = Invoke-HandoffValidatorText -ValidatorPath $scriptPath -ProjectRoot $repoRoot -Text $packetWithMarkdownPrimaryReviewTargetsAndCompliantLegacy
    Assert-True ($markdownPrimaryResult.ExitCode -eq 1) "Markdown primary review targets with compliant legacy block unexpectedly passed with $scriptPath."
    Assert-True ($markdownPrimaryResult.Text -match 'validation-fail\.markdown-file-url-in-boundary-handoff') "Markdown primary targets with compliant legacy block did not emit the markdown-link hard-fail rule. Output: $($markdownPrimaryResult.Text)"

    $exemptResult = Invoke-HandoffValidatorText -ValidatorPath $scriptPath -ProjectRoot $repoRoot -Text $packetWithExemptReferences
    Assert-True ($exemptResult.ExitCode -eq 0) "Code-block-exempt packet unexpectedly failed with $scriptPath. Output: $($exemptResult.Text)"
    Assert-True ($exemptResult.Text -notmatch 'bare-path-in-boundary-handoff') "Code-block-exempt packet emitted a bare-path finding. Output: $($exemptResult.Text)"
}
Write-Pass 'Packet-wide bare artifact references fail outside exempt command/code contexts'

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

$badEvidenceRoot = Join-Path $scratchRoot 'bad-handoff-evidence'
New-ApprovedStatusWorkspace -Root $badEvidenceRoot -WithVerdictEvidence:$true
New-Item -ItemType Directory -Path (Join-Path $badEvidenceRoot 'specs\001-test\iterations\001') -Force | Out-Null
'# Iteration State: 001' | Set-Content -LiteralPath (Join-Path $badEvidenceRoot 'specs\001-test\iterations\001\state.md') -Encoding UTF8
$badEvidence = [ordered]@{
    schema = 'v1'
    boundary_events = @([ordered]@{
            commit = 'badc0de'
            boundary = 'retro'
            response_text = $packetWithBareReferences
            handoff_present = $true
            recorded_at = '2026-06-01T00:00:00Z'
        })
}
($badEvidence | ConvertTo-Json -Depth 8) | Set-Content -LiteralPath (Join-Path $badEvidenceRoot '.specrew\handoff-evidence.json') -Encoding UTF8
$badEvidenceOutput = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorPath -ProjectPath $badEvidenceRoot 2>&1)
Assert-True ($LASTEXITCODE -eq 1) 'validate-governance should fail when stored boundary packet evidence contains bare artifact paths.'
Assert-True (($badEvidenceOutput -join "`n") -match 'handoff-evidence-packet-invalid') 'Stored boundary packet evidence failure did not identify handoff-evidence-packet-invalid.'
Assert-True (($badEvidenceOutput -join "`n") -match 'validation-fail\.bare-path-in-boundary-handoff') 'Stored boundary packet evidence failure did not surface the bare-path validator finding.'

$badMarkdownEvidenceRoot = Join-Path $scratchRoot 'bad-markdown-handoff-evidence'
New-ApprovedStatusWorkspace -Root $badMarkdownEvidenceRoot -WithVerdictEvidence:$true
New-Item -ItemType Directory -Path (Join-Path $badMarkdownEvidenceRoot 'specs\001-test\iterations\001') -Force | Out-Null
'# Iteration State: 001' | Set-Content -LiteralPath (Join-Path $badMarkdownEvidenceRoot 'specs\001-test\iterations\001\state.md') -Encoding UTF8
$badMarkdownEvidence = [ordered]@{
    schema = 'v1'
    boundary_events = @([ordered]@{
            commit = 'badc0df'
            boundary = 'feature-closeout'
            response_text = $packetWithMarkdownPrimaryReviewTargetsAndCompliantLegacy
            handoff_present = $true
            recorded_at = '2026-06-01T00:00:00Z'
        })
}
($badMarkdownEvidence | ConvertTo-Json -Depth 8) | Set-Content -LiteralPath (Join-Path $badMarkdownEvidenceRoot '.specrew\handoff-evidence.json') -Encoding UTF8
$badMarkdownEvidenceOutput = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $validatorPath -ProjectPath $badMarkdownEvidenceRoot 2>&1)
Assert-True ($LASTEXITCODE -eq 1) 'validate-governance should fail when stored boundary packet evidence contains markdown file links in the primary packet.'
Assert-True (($badMarkdownEvidenceOutput -join "`n") -match 'handoff-evidence-packet-invalid') 'Stored markdown packet evidence failure did not identify handoff-evidence-packet-invalid.'
Assert-True (($badMarkdownEvidenceOutput -join "`n") -match 'validation-fail\.markdown-file-url-in-boundary-handoff') 'Stored markdown packet evidence failure did not surface the markdown-link validator finding.'
Write-Pass 'Stored boundary packet evidence is validated against actual emitted packet text'

$syncRejectRoot = Join-Path $scratchRoot 'sync-rejects-invalid-visible-packet'
New-ApprovedStatusWorkspace -Root $syncRejectRoot -WithVerdictEvidence:$true
$previousModulePath = $env:SPECREW_MODULE_PATH
try {
    $env:SPECREW_MODULE_PATH = $repoRoot
    $syncOutput = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1') -ProjectPath $syncRejectRoot -BoundaryType plan -FeatureRef 001-test -AuthCommitHash abcdef1 -HandoffText $packetWithMarkdownPrimaryReviewTargetsAndCompliantLegacy 2>&1)
    Assert-True ($LASTEXITCODE -ne 0) 'sync-boundary-state should reject invalid visible packet text before advancing the boundary.'
    $syncOutputText = $syncOutput -join "`n"
    Assert-True ($syncOutputText -match 'boundary-handoff-validation-gate') "Sync rejection did not identify the pre-advance handoff validation gate. Output: $syncOutputText"
    Assert-True ($syncOutputText -match 'validation-fail\.markdown-file-url-in-boundary-handoff') "Sync rejection did not surface the markdown-link validator finding. Output: $syncOutputText"
    $syncContext = Get-Content -LiteralPath (Join-Path $syncRejectRoot '.specrew\start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-True ($syncContext.session_state.boundary_type -eq 'clarify') 'Invalid packet sync advanced the session boundary despite validation failure.'
}
finally {
    $env:SPECREW_MODULE_PATH = $previousModulePath
}
Write-Pass 'Boundary sync rejects invalid visible packet text before state advancement'

if (Test-Path -LiteralPath $scratchRoot) { Remove-Item -LiteralPath $scratchRoot -Recurse -Force }
Write-Host ''
Write-Host 'Boundary authorization prompt truth unit assertions: all pass'
exit 0
