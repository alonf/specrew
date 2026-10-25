#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Records a co-decided design choice as a declared artifact the gate can validate. Fix 2 item (f).

.DESCRIPTION
  THE GAP THIS FILLS. At the design-analysis stop the human chooses between options the crew co-built with
  them. Until now there was nowhere to put that answer: `approved for plan with Option 2` is defined
  nowhere, the boundary approval anchor admits an option only as a leading prefix and caps it at 1-2, and so
  the choice was written into design-analysis.md as prose - the one artifact nothing validates. The gate
  could not see that a decision had been made, between what, or on whose say-so (B4F-045).

  ITS OWN PHRASE FAMILY. The human's typed sentence opens with `design decision`, which the boundary anchor
  cannot match under any input because that anchor is built around the verb `approve`. A design decision
  settles WHAT to build; a boundary verdict grants permission to PROCEED. One sentence must never be able to
  do both, and the separation is a property of the two grammars rather than a rule anyone has to remember.

  WHAT IT REFUSES, and each refusal is the co-design rule made enforceable rather than restated:
    - fewer than two options - a choice between one thing is a hand-down wearing a choice's clothes;
    - a chosen option that is not among those recorded - naming something the human was never shown;
    - a human turn from the wrong phrase family - a decision minted out of permission to proceed.

.EXAMPLE
  pwsh -File record-design-decision.ps1 -FeatureRef 001-mdlink-checker -Key decomposition-style `
      -Question 'How is the checker decomposed?' `
      -OptionId '1','2','3' `
      -OptionSummary 'one script, three functions','a module per concern','a pipeline of filters' `
      -Chosen 2 -Rationale 'the concerns are tested separately and the team already works this way' `
      -HumanTurn 'design decision: option 2 - I want the concerns testable on their own'
#>
[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Mandatory)][string] $FeatureRef,

    # A stable slug for the decision, so a later lens can cite it and a repeat can be detected.
    [Parameter(Mandatory)][string] $Key,

    [Parameter(Mandatory)][string] $Question,

    # The options AS PRESENTED. Parallel arrays, same length - the ids the human saw and what each one said.
    [Parameter(Mandatory)][string[]] $OptionId,
    [Parameter(Mandatory)][string[]] $OptionSummary,

    [Parameter(Mandatory)][string] $Chosen,
    [Parameter(Mandatory)][string] $Rationale,

    # The human's own typed sentence, verbatim. Not a summary of it: the record's authority is that a person
    # typed this, and a paraphrase is the agent's word for the human's.
    [Parameter(Mandatory)][string] $HumanTurn,

    [AllowNull()][string] $ProjectRoot,
    [switch] $AsJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$storePath = Join-Path $PSScriptRoot 'design-decision-store.ps1'
if (-not (Test-Path -LiteralPath $storePath -PathType Leaf)) {
    throw "The design-decision store is missing next to this script: '$storePath'."
}
. $storePath

$root = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { (Get-Location).Path } else { $ProjectRoot }
$root = [System.IO.Path]::GetFullPath($root)

if ($OptionId.Count -ne $OptionSummary.Count) {
    throw "Each option needs both an id and a summary: -OptionId has $($OptionId.Count) entries and -OptionSummary has $($OptionSummary.Count)."
}
if (-not (Test-SpecrewDesignDecisionPhrase -Text $HumanTurn)) {
    throw ("The human's reply is not a design decision. A design decision starts with 'design decision' - for example: " +
        "`"design decision: option 2 - the concerns are testable on their own`". An 'approved for <boundary>' reply is a " +
        'boundary verdict and authorizes proceeding, not a choice between designs; the two are recorded separately on purpose.')
}
if ($Key -cnotmatch '^[a-z][a-z0-9-]{1,63}$') {
    throw "The decision key must be a short lowercase slug (letters, digits and hyphens), for example 'decomposition-style'. Got '$Key'."
}

$options = @()
for ($i = 0; $i -lt $OptionId.Count; $i++) {
    $options += [pscustomobject]@{ id = ([string]$OptionId[$i]).Trim(); summary = ([string]$OptionSummary[$i]).Trim() }
}

$record = [pscustomobject][ordered]@{
    question           = $Question.Trim()
    options            = @($options)
    chosen             = $Chosen.Trim()
    rationale          = $Rationale.Trim()
    confirmation       = 'crew-declared-human-reply'
    confirmation_scope = 'design-decision'
    human_turn         = $HumanTurn.Trim()
    recorded_at        = [DateTimeOffset]::UtcNow.ToString('o')
}

# VALIDATED BEFORE IT IS WRITTEN, with the same function the gate uses. A writer that validates by its own
# lights and a reader that validates by different ones is how a controller ends up well-formed to whoever
# produced it and invalid to everything downstream - the exact shape of the workshop defect this batch spent
# its largest single effort on.
$validation = Test-SpecrewDesignDecisionRecord -Record $record
if (-not $validation.valid) {
    $guidance = switch ([string]$validation.reason) {
        'design-decision-needs-at-least-two-options' {
            'A design decision records a choice, so it needs at least two options as they were presented. If there was only ever one way to do it, that is a constraint to write down, not a decision to record.'
        }
        'design-decision-chosen-not-among-options' {
            ("The chosen option '{0}' is not one of the options recorded ({1}). Record the options the human actually saw, then the one they picked." -f $record.chosen, (($options | ForEach-Object { $_.id }) -join ', '))
        }
        'design-decision-option-ids-not-unique' { 'Two options share an id, so the choice would be ambiguous.' }
        default { 'The decision could not be recorded in a form the gate can read.' }
    }
    throw ("This design decision was not recorded, and nothing else has changed. {0}" -f $guidance)
}

$path = Get-SpecrewDesignDecisionPath -ProjectRoot $root -FeatureRef $FeatureRef
$featureDir = Split-Path -Parent $path
if (-not (Test-Path -LiteralPath $featureDir -PathType Container)) {
    throw ("This feature has no directory yet, so there is nowhere to record the decision: '{0}'. Create the governed feature first." -f $featureDir)
}

$document = [ordered]@{ schema_version = '1.0'; feature_ref = (Split-Path -Leaf $FeatureRef); decisions = [ordered]@{} }
if (Test-Path -LiteralPath $path -PathType Leaf) {
    $existing = Read-SpecrewDesignDecisions -ProjectRoot $root -FeatureRef $FeatureRef
    if (-not $existing.valid) {
        throw ("The recorded design decisions for this feature could not be read, so nothing was changed. Ask for them to be repaired, then record this decision again. ({0})" -f $existing.reason)
    }
    foreach ($entry in $existing.decisions.GetEnumerator()) { $document.decisions[$entry.Key] = $entry.Value }
}
$replaced = $document.decisions.Contains($Key)
$document.decisions[$Key] = $record

$temp = $path + '.tmp-' + [guid]::NewGuid().ToString('N')
try {
    [System.IO.File]::WriteAllText($temp, ($document | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::Move($temp, $path, $true)
}
finally {
    if (Test-Path -LiteralPath $temp -PathType Leaf) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue }
}

# Read back through the gate's own reader before reporting success. The write is the point of this script;
# reporting it on the strength of no exception is what makes a silent failure possible.
$verify = Read-SpecrewDesignDecisions -ProjectRoot $root -FeatureRef $FeatureRef
if (-not $verify.valid -or -not $verify.decisions.Contains($Key)) {
    throw ("The decision was written but could not be read back as valid, so treat it as not recorded. ({0})" -f $verify.reason)
}

if ($AsJson) {
    [pscustomobject][ordered]@{
        path = $path; key = $Key; chosen = $record.chosen; replaced = $replaced
        options = @($options | ForEach-Object { $_.id }); valid = $true
    } | ConvertTo-Json -Depth 6
    return
}

Write-Output ("Recorded the '{0}' design decision for {1}: option {2} of {3}, with the reason you gave. The gate reads it from {4}." -f
    $Key, (Split-Path -Leaf $FeatureRef), $record.chosen, (($options | ForEach-Object { $_.id }) -join '/'), $path)
