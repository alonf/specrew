#!/usr/bin/env pwsh
<#
.SYNOPSIS
  The governed LENS CHECKPOINT writer (FR-027, iteration 002, T018).

.DESCRIPTION
  F-1, measured on the WinUI walk: the human confirms a lens, the agent writes the artifacts, and the
  controller stays on the same phase because NOTHING runs the transition. `moved_on` was written by the
  agent hand-editing lens-applicability.json per skill instruction. Later, outside work plus an open topic
  triggers a re-ask of a lens the human already answered - and to a newcomer that reads as "the system lost
  my answer". Roughly nine of those per full workshop.

  Inert-control family: the state exists, a writer exists for the AGENDA (confirm-workshop-agenda.ps1), and
  nothing connected them at the moment a LENS is confirmed. This is that missing writer, and it is the only
  supported way `moved_on` becomes true.

  B-6 rides with it, scoped as the maintainer ruled: the lens's ALREADY-EXISTING validator runs HERE, at the
  checkpoint, with the human still in the room and the context still loaded - instead of at the specify
  boundary, lenses later, in reverse order of creation. No new validators are written; the boundary gate
  keeps its own calls as defense in depth.

  Refusals route through the workshop refusal contract: they name what is missing, keep the human's answers,
  and give one action - never machinery vocabulary, never blaming Specrew.
#>
# PositionalBinding = $false: EVERY parameter must be named.
#
# Measured in the field (ConsoleFractal, 2026-08-30): a six-element `-Agenda` array was absorbed across the
# positional parameters and one of its strings landed in `-Confirmation`. The ValidateSet caught it loudly,
# which is correct - but the message named `Confirmation`, and the cause was `Agenda`. Accurate about what
# it checked, wrong about what went wrong; the same family as the binding refusal above. With positional
# binding refused, a mis-shaped call fails as "a positional parameter cannot be found" instead of
# reappearing as a different parameter's validation error.
[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Mandatory)][string] $ProjectRoot,
    [Parameter(Mandatory)][string] $FeatureRef,
    [Parameter(Mandatory)][string] $Lens,
    [Parameter(Mandatory)][string] $Decision,
    [Parameter(Mandatory)][string] $Depth,
    [Parameter(Mandatory)][string[]] $Agenda,
    [AllowNull()][string] $Diagram,
    [AllowNull()][string] $BindingsJson,
    [ValidateSet('human-confirmed', 'human-skipped', 'human-delegated')][string] $Confirmation = 'human-confirmed',
    [switch] $PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$here = $PSScriptRoot
foreach ($dependency in @('workshop-authority-store.ps1', 'shared-governance.ps1')) {
    $path = Join-Path $here $dependency
    if (Test-Path -LiteralPath $path -PathType Leaf) { . $path }
}

function Write-SpecrewLensAtomicUtf8NoBom {
    param([Parameter(Mandatory)][string] $Path, [Parameter(Mandatory)][string] $Content)
    $directory = Split-Path -Parent $Path
    if ($directory -and -not (Test-Path -LiteralPath $directory -PathType Container)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    $temp = "$Path.tmp"
    [System.IO.File]::WriteAllText($temp, $Content, [System.Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temp -Destination $Path -Force
}

function New-SpecrewLensCheckpointRefusal {
    # Same contract as the agenda writer's refusals: a summary the human can act on, one action, and the
    # standing reassurance that their answers are safe. No machinery nouns.
    param([Parameter(Mandatory)][string] $Summary, [Parameter(Mandatory)][string] $Action)
    $contract = if (Get-Command -Name 'Get-SpecrewWorkshopRefusalContractText' -ErrorAction SilentlyContinue) {
        Get-SpecrewWorkshopRefusalContractText -AnswerState 'preserved'
    }
    else {
        'Your answers so far are safe and unchanged.'
    }
    return ("{0} {1} {2}" -f $Summary, $Action, $contract)
}

$resolvedProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
$featurePath = Join-Path (Join-Path $resolvedProjectRoot 'specs') (Split-Path -Leaf $FeatureRef)
$controllerPath = Join-Path $featurePath 'lens-applicability.json'
$lensRecordPath = Join-Path (Join-Path $featurePath 'workshop') ($Lens + '.md')

if (-not (Test-Path -LiteralPath $controllerPath -PathType Leaf)) {
    throw (New-SpecrewLensCheckpointRefusal `
            -Summary ("This feature has no recorded workshop plan yet, so the '{0}' discussion cannot be closed." -f $Lens) `
            -Action 'Start the workshop for this feature and confirm its agenda first, then close this lens again.')
}

$controller = $null
try { $controller = Get-Content -LiteralPath $controllerPath -Raw -Encoding UTF8 | ConvertFrom-Json }
catch {
    throw (New-SpecrewLensCheckpointRefusal `
            -Summary ("The recorded workshop plan for this feature could not be read, so the '{0}' discussion cannot be closed." -f $Lens) `
            -Action 'Ask for the workshop plan to be repaired, then close this lens again.')
}

# THE INTAKE LENS IS NOT AN AGENDA TOPIC, and treating it as one deadlocked every greenfield workshop.
#
# `product-domain` runs BEFORE the agenda and is what produces it, so it is never in `selected` - the
# agenda catalog excludes it by construction. This writer required membership in `selected` and a
# CONFIRMED agenda, so the first lens of every new feature could not be closed: closing it demanded a
# confirmed agenda, and confirming the agenda demanded the product-domain records this step persists.
# Two refusals that are each correct in isolation and jointly a trap - the pause-recovery shape again.
$isIntakeLens = Test-SpecrewWorkshopIntakeLens -Lens $Lens

# SPECREW-AUTHORITY-CONSUMER: the finite transition contract. A TECHNICAL lens closes only from a
# confirmed agenda; the INTAKE lens closes from the pre-agenda state, which is how the controller reaches
# `pending-product-projection`.
$transitionOperation = if ($isIntakeLens) { 'confirm-intake-lens' } else { 'confirm-lens' }
$transition = Resolve-SpecrewWorkshopStateTransition -Controller $controller -Operation $transitionOperation
if (-not [bool]$transition.allowed) {
    # A REFUSAL MUST LEAVE A LEGAL NEXT MOVE (method rule 12, applied to writers rather than checks). The
    # intake and technical cases fail for opposite reasons, so one shared sentence cannot name a move that
    # is actually available from where the reader is.
    $transitionAction = if ($isIntakeLens) {
        "This topic runs before the agenda, so there is no agenda to confirm first. Ask for the workshop plan to be repaired, then close this topic again."
    }
    else {
        "Confirm the workshop agenda first (or ask for the plan to be repaired), then close this topic again."
    }
    throw (New-SpecrewLensCheckpointRefusal `
            -Summary ("The workshop plan is not in a state where the '{0}' discussion can be closed." -f $Lens) `
            -Action $transitionAction)
}

if (-not $isIntakeLens) {
    $selected = @()
    if ($controller.PSObject.Properties['selected'] -and $null -ne $controller.selected) { $selected = @($controller.selected | ForEach-Object { [string]$_ }) }
    if ($selected -notcontains $Lens) {
        # Naming the agreed topics is what keeps this refusal actionable; with an empty agenda it would
        # otherwise say "close one of: " and name nothing, which is a refusal with no legal move in it.
        $agreedList = if ($selected.Count -gt 0) { ($selected -join ', ') } else { '(none yet - the agenda has not been confirmed)' }
        throw (New-SpecrewLensCheckpointRefusal `
                -Summary ("'{0}' is not one of the topics this workshop agreed to cover." -f $Lens) `
                -Action ("Close one of the agreed topics instead: {0}." -f $agreedList))
    }
}

# The typed-turn receipt: the human's own reply, minted by the prompt-submit hook. No receipt, no close -
# a lens cannot be closed on the agent's say-so.
# THE PHASE MUST MATCH THE ONE THE TURN WAS MINTED UNDER. Intake answers are recorded with
# `phase: 'product-domain'` - measured in the field: HelloWinUIReactive's store holds 12 of them - while
# this lookup asked for `phase: 'lens'`. Fixing only the membership check above would have moved the
# deadlock one line down and reported "no typed reply from you is on record" for a reply that was.
# A fact that fails two contracts reports one (DRIFT-199-I002-020).
$receiptPhase = if ($isIntakeLens) { $Lens } else { 'lens' }
$receipt = Get-SpecrewWorkshopAuthorityReceipt -ProjectRoot $resolvedProjectRoot -FeatureRef $FeatureRef -Phase $receiptPhase -Lens $Lens
if ($null -eq $receipt) {
    throw (New-SpecrewLensCheckpointRefusal `
            -Summary ("No typed reply from you is on record for the '{0}' question, so the topic was not closed." -f $Lens) `
            -Action ('Reply to the open question (or type "skip" to skip the topic), and the checkpoint will run on that reply.'))
}
$receiptConfirmation = [string]$receipt.confirmation
# FR-027 review finding `workshop-receipt-contract`: the scope written here is the scope the RECEIPT
# carries, never one this script derives. A local table is a second opinion about what the human typed,
# and Test-SpecrewWorkshopAuthorityReceipt compares the record's scope against the receipt's - so a
# derived scope that disagrees makes the entry unreadable at the next workshop-state read, which is the
# precise failure this whole checkpoint exists to prevent.
$receiptScope = [string]$receipt.confirmation_scope
if ($receiptConfirmation -cne $Confirmation) {
    throw (New-SpecrewLensCheckpointRefusal `
            -Summary ("Your recorded reply for '{0}' does not match the way this topic is being closed." -f $Lens) `
            -Action 'Close the topic the way you answered it, or reply again to the open question.')
}
if ([string]::IsNullOrWhiteSpace($receiptScope)) {
    throw (New-SpecrewLensCheckpointRefusal `
            -Summary ("Your recorded reply for '{0}' is missing the detail the checkpoint needs to close the topic safely, so nothing was changed." -f $Lens) `
            -Action 'Reply to the open question once more, and the checkpoint will run on that reply.')
}

if (-not (Test-Path -LiteralPath $lensRecordPath -PathType Leaf)) {
    throw (New-SpecrewLensCheckpointRefusal `
            -Summary ("The '{0}' discussion has no written record yet, so it cannot be closed." -f $Lens) `
            -Action ("Write the discussion record at workshop/{0}.md, then close this topic again." -f $Lens))
}
$recordText = Get-Content -LiteralPath $lensRecordPath -Raw -Encoding UTF8
if ([string]::IsNullOrWhiteSpace($recordText)) {
    throw (New-SpecrewLensCheckpointRefusal `
            -Summary ("The '{0}' discussion record is empty, so the topic cannot be closed." -f $Lens) `
            -Action ("Write what was decided into workshop/{0}.md, then close this topic again." -f $Lens))
}

# B-6: the lens's OWN validator, at ITS checkpoint. Only the two lenses that have one; no new validators.
#
# The resolution below is deliberately explicit, and it REFUSES rather than skipping when it cannot find the
# validator it knows should exist. A silent skip here would be the inert-control shape this whole batch is
# about: a check that is called, cannot load, and reports nothing - green because it never ran.
function Resolve-SpecrewLensScriptPath {
    param([Parameter(Mandatory)][string] $FileName, [Parameter(Mandatory)][string] $StartDirectory, [AllowNull()][string] $ProjectRootPath)
    $candidates = New-Object System.Collections.Generic.List[string]
    $walk = $StartDirectory
    while (-not [string]::IsNullOrWhiteSpace($walk)) {
        $candidates.Add((Join-Path $walk (Join-Path 'scripts' (Join-Path 'internal' $FileName)))) | Out-Null
        $parent = Split-Path -Parent $walk
        if ($parent -eq $walk) { break }
        $walk = $parent
    }
    if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_MODULE_PATH)) {
        $candidates.Add((Join-Path $env:SPECREW_MODULE_PATH (Join-Path 'scripts' (Join-Path 'internal' $FileName)))) | Out-Null
    }
    if (-not [string]::IsNullOrWhiteSpace($ProjectRootPath)) {
        $candidates.Add((Join-Path $ProjectRootPath (Join-Path 'scripts' (Join-Path 'internal' $FileName)))) | Out-Null
    }
    try {
        $module = Get-Module -ListAvailable Specrew -ErrorAction SilentlyContinue | Sort-Object Version -Descending | Select-Object -First 1
        if ($null -ne $module) { $candidates.Add((Join-Path $module.ModuleBase (Join-Path 'scripts' (Join-Path 'internal' $FileName)))) | Out-Null }
    }
    catch { $null = $_ }
    foreach ($candidate in $candidates) {
        if (-not [string]::IsNullOrWhiteSpace($candidate) -and (Test-Path -LiteralPath $candidate -PathType Leaf)) { return $candidate }
    }
    return $null
}

$lensValidators = @{
    'product-domain'      = @{ Script = 'product-domain-lens.ps1'; Function = 'Test-SpecrewProductDomainRecord' }
    'code-implementation' = @{ Script = 'code-implementation-lens.ps1'; Function = 'Test-SpecrewImplementationRulesManifest' }
}
$lensValidatorErrors = @()
if ($lensValidators.ContainsKey($Lens)) {
    $spec = $lensValidators[$Lens]
    if (-not (Get-Command -Name ([string]$spec.Function) -ErrorAction SilentlyContinue)) {
        $scriptPath = Resolve-SpecrewLensScriptPath -FileName ([string]$spec.Script) -StartDirectory $here -ProjectRootPath $resolvedProjectRoot
        if ($null -ne $scriptPath) { . $scriptPath }
    }
    if (-not (Get-Command -Name ([string]$spec.Function) -ErrorAction SilentlyContinue)) {
        throw (New-SpecrewLensCheckpointRefusal `
                -Summary ("The '{0}' record cannot be checked here because this installation's checker for it could not be loaded, and closing the topic without checking it would hide a problem until much later." -f $Lens) `
                -Action 'Ask for the installation to be repaired or updated, then close this topic again.')
    }
    if ($Lens -ceq 'product-domain') {
        $recordPath = Get-SpecrewProductDomainRecordPath -FeatureDir $featurePath
        $schemaPath = if (Get-Command -Name 'Get-SpecrewProductDomainSchemaPath' -ErrorAction SilentlyContinue) { Get-SpecrewProductDomainSchemaPath -FeatureDir $featurePath } else { $null }
        $lensValidatorErrors = @(Test-SpecrewProductDomainRecord -Path $recordPath -SchemaPath $schemaPath)
    }
    else {
        $manifestPath = Get-SpecrewCodeManifestPath -FeatureDir $featurePath
        $lensValidatorErrors = @(Test-SpecrewImplementationRulesManifest -Path $manifestPath -SchemaPath $null -CatalogPath $null -OverlayPath $null)
    }
}
if ($lensValidatorErrors.Count -gt 0) {
    throw (New-SpecrewLensCheckpointRefusal `
            -Summary ("The '{0}' record did not pass its own checks, so the topic stays open: {1}" -f $Lens, ($lensValidatorErrors -join ' ')) `
            -Action 'Fix the record, then close this topic again.')
}

$entry = [ordered]@{
    agenda             = @($Agenda)
    decision           = $Decision
    depth              = $Depth
    moved_on           = $true
    confirmation       = $Confirmation
    confirmation_scope = $receiptScope
}
if (-not [string]::IsNullOrWhiteSpace($Diagram)) { $entry['diagram'] = $Diagram }
if (-not [string]::IsNullOrWhiteSpace($BindingsJson)) {
    try { $entry['bindings'] = ($BindingsJson | ConvertFrom-Json) }
    catch {
        throw (New-SpecrewLensCheckpointRefusal `
                -Summary ("The cross-topic names recorded for '{0}' could not be read." -f $Lens) `
                -Action 'Record them as a simple name-to-value list, then close this topic again.')
    }
}
# `human_turn_receipt` is the name ProjectMetadataAccessor reads. It was written as `turn_receipt`, so
# every entry this checkpoint wrote was invisible to the reader and the next state read returned
# `workshop-completed-human-turn-receipt-invalid`.
if ($receipt.PSObject.Properties['receipt_id']) { $entry['human_turn_receipt'] = [string]$receipt.receipt_id }

$workshop = if ($controller.PSObject.Properties['workshop'] -and $null -ne $controller.workshop) { $controller.workshop } else { [pscustomobject]@{} }
$workshopMap = [ordered]@{}
foreach ($property in @($workshop.PSObject.Properties)) { $workshopMap[[string]$property.Name] = $property.Value }
$workshopMap[$Lens] = $entry

$updated = [ordered]@{}
foreach ($property in @($controller.PSObject.Properties)) {
    if ([string]$property.Name -ceq 'workshop') { continue }
    $updated[[string]$property.Name] = $property.Value
}
$updated['workshop'] = $workshopMap

Write-SpecrewLensAtomicUtf8NoBom -Path $controllerPath -Content (($updated | ConvertTo-Json -Depth 12) + [Environment]::NewLine)

# The handover refresh the skill's step 7(c) used to ask the agent to remember.
$handoverProvider = Join-Path $here 'specrew-handover-provider.ps1'
if (Test-Path -LiteralPath $handoverProvider -PathType Leaf) {
    try { & pwsh -NoProfile -File $handoverProvider --project-root $resolvedProjectRoot --source workshop 2>&1 | Out-Null }
    catch { $null = $_ }
}

if ($PassThru) {
    [pscustomobject]@{
        lens               = $Lens
        moved_on           = $true
        confirmation       = $Confirmation
        confirmation_scope = $receiptScope
        controller_path    = $controllerPath
        validated          = ($Lens -cin @('product-domain', 'code-implementation'))
    }
}
