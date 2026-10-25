<#
.SYNOPSIS
  Shared parse-failure vocabulary for Specrew's CONSTRAINED YAML records (FR-026, iteration 002, T017).

.DESCRIPTION
  PowerShell 7 has no native YAML parser and Specrew deliberately avoids powershell-yaml, so several
  records use a constrained YAML subset with a co-designed emitter and matched reader
  (product-domain.yml, implementation-rules.yml). Each reader answers "did this document match my
  constructs"; NEITHER used to answer "then what IS it", so a document in another representation read as
  an empty record and the field backstops - a robustness net for a MISSING schema - became the primary
  error surface.

  Field case: the WinUI walk's product-domain.yml, written by the product-domain lens itself, contained
  JSON. The refusal named missing depth and missing confirmation for a record whose depth and
  confirmation were present, correct and human-confirmed, and invited the reader to conclude the human's
  answer had been lost. The agent resolved it only by opening the schema.

  These two helpers are the ONE place that vocabulary lives, so the two readers cannot drift apart the
  way the message and its trigger did (the right shape existed in one lens and never fired, because it
  keyed on a $null the other reader never returned).
#>

Set-StrictMode -Version Latest

function Get-SpecrewConstrainedYamlRepresentation {
    # Name what the document ACTUALLY is, so the refusal stops describing a symptom. Deliberately shallow:
    # it reports only what the first non-space character can prove, and says plainly when it cannot tell.
    [CmdletBinding()]
    [OutputType([string])]
    param([AllowNull()][AllowEmptyString()][string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return 'empty' }
    $trimmed = $Text.TrimStart()
    if ($trimmed.StartsWith('{') -or $trimmed.StartsWith('[')) { return 'JSON' }
    if ($trimmed.StartsWith('<')) { return 'XML or HTML' }
    return 'not the constrained YAML this record uses'
}

function Get-SpecrewConstrainedYamlParseFailureMessage {
    # The refusal: what failed, the instance (the representation found), that the recorded answers are
    # intact - the sentence whose absence sent the walk to the schema - and one reachable action.
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)][string]$FileName,
        [AllowNull()][AllowEmptyString()][string]$Text,
        [Parameter(Mandatory = $true)][string]$SchemaName
    )
    $representation = Get-SpecrewConstrainedYamlRepresentation -Text $Text
    $because = if ($representation -eq 'empty') {
        'the file is empty'
    }
    elseif ($representation -eq 'not the constrained YAML this record uses') {
        'no line in it matches the constrained YAML this record uses'
    }
    else {
        ("no line in it matches the constrained YAML this record uses (the content reads as {0})" -f $representation)
    }
    return ("{0} could not be parsed: {1}. The answers inside are not lost and nothing was mis-confirmed; only the file's format is wrong. Re-write it as the YAML {2} describes, keeping every recorded value, then continue." -f $FileName, $because, $SchemaName)
}
