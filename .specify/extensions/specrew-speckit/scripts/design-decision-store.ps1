# THE DESIGN-DECISION RECORD - the artifact a co-decided design choice lands in, and the rules that make it
# checkable.
#
# WHY THIS EXISTS. At the design-analysis stop the methodology requires a real choice from the human:
# design-workshop.md's co-design rule says in as many words *do NOT hand down finished options*. The
# machinery offered nowhere to put the answer. `approved for plan with Option 2` is defined nowhere; the
# boundary approval anchor admits an option only as a LEADING prefix and caps it at 1-2, so a three-option
# decision cannot be expressed at all and the trailing form falls inside the boundary name. So crews wrote
# the choice into design-analysis.md as prose - the one place nothing validates - and the gate could not see
# that a decision had been made, by whom, or between what (B4F-045).
#
# ITS OWN PHRASE FAMILY, SEPARATE BY CONSTRUCTION. A design decision is not a boundary verdict: it settles
# what to build, not permission to proceed, and conflating them would let one typed sentence do both. The
# separation is structural rather than conventional - the decision phrase begins with a word the approval
# anchor cannot match, so no string can ever be read as both. Test-SpecrewDesignDecisionPhrase and the
# boundary anchor are asserted disjoint in BOTH directions by the suite, because a separation that holds
# only in the direction someone happened to test is not a separation.
#
# WHAT THE RULES ENFORCE, and each one is the co-design rule made checkable:
#   - at least TWO options, because a choice between one thing is a hand-down wearing a choice's clothes;
#   - the chosen option must be one of the options RECORDED, so a decision cannot name something the human
#     was never shown;
#   - a rationale, because the value of the record is why, not which.

$script:SpecrewDesignDecisionSchemaVersion = '1.0'
$script:SpecrewDesignDecisionConfirmation = 'human-decided'
$script:SpecrewDesignDecisionScope = 'design-decision'

function Get-SpecrewDesignDecisionPath {
    [OutputType([string])]
    param([Parameter(Mandatory)][string] $ProjectRoot, [Parameter(Mandatory)][string] $FeatureRef)
    return (Join-Path (Join-Path (Join-Path $ProjectRoot 'specs') (Split-Path -Leaf $FeatureRef)) 'design-decisions.json')
}

function Test-SpecrewDesignDecisionPhrase {
    # THE PHRASE FAMILY. It opens with `design decision`, which the boundary anchor - built around the verb
    # `approv(e|ed|es)` - cannot match under any input. That is the entire collision-avoidance mechanism, and
    # it is deliberately a property of the grammar rather than a rule someone has to remember.
    [OutputType([bool])]
    param([AllowNull()][AllowEmptyString()][string] $Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $false }
    return ($Text -imatch '^\s*design\s+decision\b')
}

function Test-SpecrewDesignDecisionRecord {
    # THE GATE'S VIEW. Returns a result object rather than a bare boolean so a refusal can name which rule
    # failed - the standard this batch keeps rediscovering: a check that reports only "invalid" makes the
    # reader guess, and they guess wrong.
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][AllowNull()]$Record)

    function New-Result { param([bool]$Valid, [string]$Reason) [pscustomobject]@{ valid = $Valid; reason = $Reason } }

    if ($null -eq $Record -or $Record -is [System.Array] -or $Record -is [string] -or $Record -is [ValueType]) {
        return (New-Result -Valid $false -Reason 'design-decision-record-invalid')
    }
    foreach ($required in @('question', 'chosen', 'rationale', 'confirmation', 'confirmation_scope', 'human_turn')) {
        $property = $Record.PSObject.Properties[$required]
        if (-not $property -or $property.Value -isnot [string] -or [string]::IsNullOrWhiteSpace([string]$property.Value)) {
            return (New-Result -Valid $false -Reason ("design-decision-{0}-missing" -f ($required -replace '_', '-')))
        }
    }
    # `recorded_at` is checked for PRESENCE, not for being a [string], and the difference is not pedantry:
    # ConvertFrom-Json silently converts an ISO-8601 timestamp into a [datetime], so a record this very
    # script had just written failed its own read-back with `recorded-at-missing`. The writer's verify step
    # caught it before anything shipped, which is the argument for having a verify step - but a type check
    # that a correct round-trip cannot survive is the check being wrong, not the data.
    $recordedAtProperty = $Record.PSObject.Properties['recorded_at']
    if (-not $recordedAtProperty -or $null -eq $recordedAtProperty.Value -or
        [string]::IsNullOrWhiteSpace([string]$recordedAtProperty.Value)) {
        return (New-Result -Valid $false -Reason 'design-decision-recorded-at-missing')
    }
    if ([string]$Record.confirmation -cne $script:SpecrewDesignDecisionConfirmation) {
        return (New-Result -Valid $false -Reason 'design-decision-confirmation-invalid')
    }
    if ([string]$Record.confirmation_scope -cne $script:SpecrewDesignDecisionScope) {
        return (New-Result -Valid $false -Reason 'design-decision-scope-invalid')
    }
    # The human's own typed sentence, kept verbatim, and it must belong to THIS family. A record carrying a
    # boundary approval in this field would be a design decision minted from permission to proceed.
    if (-not (Test-SpecrewDesignDecisionPhrase -Text ([string]$Record.human_turn))) {
        return (New-Result -Valid $false -Reason 'design-decision-human-turn-not-this-family')
    }

    $optionsProperty = $Record.PSObject.Properties['options']
    if (-not $optionsProperty -or $optionsProperty.Value -isnot [System.Array]) {
        return (New-Result -Valid $false -Reason 'design-decision-options-invalid')
    }
    $options = @($optionsProperty.Value)
    # TWO IS THE MINIMUM, and this is the co-design rule enforced rather than restated. One option presented
    # and "chosen" is exactly the handing-down the skill forbids; nothing downstream could tell it apart from
    # a real decision once it was prose.
    if ($options.Count -lt 2) {
        return (New-Result -Valid $false -Reason 'design-decision-needs-at-least-two-options')
    }
    $ids = New-Object System.Collections.Generic.List[string]
    foreach ($option in $options) {
        if ($option -is [string] -or $option -is [ValueType] -or $null -eq $option) {
            return (New-Result -Valid $false -Reason 'design-decision-option-shape-invalid')
        }
        $idProperty = $option.PSObject.Properties['id']
        $summaryProperty = $option.PSObject.Properties['summary']
        if (-not $idProperty -or [string]::IsNullOrWhiteSpace([string]$idProperty.Value) -or
            -not $summaryProperty -or [string]::IsNullOrWhiteSpace([string]$summaryProperty.Value)) {
            return (New-Result -Valid $false -Reason 'design-decision-option-shape-invalid')
        }
        $id = ([string]$idProperty.Value).Trim()
        if ($ids.Contains($id)) { return (New-Result -Valid $false -Reason 'design-decision-option-ids-not-unique') }
        $ids.Add($id) | Out-Null
    }
    # THE CHOICE MUST BE ONE OF THE OPTIONS RECORDED. Without this the record could name a choice the human
    # was never shown, which is the same defect as handing options down, arriving one step later.
    if (-not $ids.Contains(([string]$Record.chosen).Trim())) {
        return (New-Result -Valid $false -Reason 'design-decision-chosen-not-among-options')
    }
    return (New-Result -Valid $true -Reason 'design-decision-valid')
}

function Read-SpecrewDesignDecisions {
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][string] $ProjectRoot, [Parameter(Mandatory)][string] $FeatureRef)

    $path = Get-SpecrewDesignDecisionPath -ProjectRoot $ProjectRoot -FeatureRef $FeatureRef
    $result = [pscustomobject]@{ present = $false; path = $path; valid = $true; reason = 'design-decisions-absent'; decisions = [ordered]@{} }
    try {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $result }
        $result.present = $true
        $document = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 20 -ErrorAction Stop
        if ($null -eq $document -or $document -is [System.Array]) {
            $result.valid = $false; $result.reason = 'design-decisions-root-invalid'; return $result
        }
        if ([string]$document.schema_version -cne $script:SpecrewDesignDecisionSchemaVersion) {
            $result.valid = $false; $result.reason = 'design-decisions-schema-invalid'; return $result
        }
        $decisionsProperty = $document.PSObject.Properties['decisions']
        if (-not $decisionsProperty -or $null -eq $decisionsProperty.Value -or $decisionsProperty.Value -is [System.Array]) {
            $result.valid = $false; $result.reason = 'design-decisions-map-invalid'; return $result
        }
        foreach ($entry in $decisionsProperty.Value.PSObject.Properties) {
            $validation = Test-SpecrewDesignDecisionRecord -Record $entry.Value
            if (-not $validation.valid) {
                $result.valid = $false
                $result.reason = ("{0}:{1}" -f [string]$entry.Name, [string]$validation.reason)
                return $result
            }
            $result.decisions[[string]$entry.Name] = $entry.Value
        }
        $result.reason = 'design-decisions-valid'
        return $result
    }
    catch {
        $result.valid = $false; $result.reason = 'design-decisions-unreadable'; return $result
    }
}
