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

# Timestamps are read through the one helper beside this file - see timestamp-read.ps1 for the three sites
# that were each wrong in their own way about a value ConvertFrom-Json had coerced.
$script:SpecrewDesignDecisionTimestampReadPath = Join-Path $PSScriptRoot 'timestamp-read.ps1'
if (-not (Get-Command ConvertTo-SpecrewUtcTimestamp -ErrorAction SilentlyContinue) -and
    (Test-Path -LiteralPath $script:SpecrewDesignDecisionTimestampReadPath -PathType Leaf)) {
    . $script:SpecrewDesignDecisionTimestampReadPath
}

# THE CONFIRMATION VALUE NAMES WHAT IT ACTUALLY IS, AND IT IS NOT `human-confirmed`.
#
# No hook captures a receipt for a design decision yet. What this record carries is the CREW'S DECLARATION
# of what the human typed - the agent's word for the human's - and calling that `human-confirmed` would
# claim an authority no artifact supports. This batch has already measured what that claim costs: five
# `human-confirmed` receipts were minted for a workshop question that had never been asked, and the record
# could not tell them from real ones because both validated identically.
#
# So the value is `crew-declared-human-reply`, which a reader can weigh correctly without being told.
# BETA5 closes the gap: `design decision - option N` becomes a reserved phrase in the handover store, the
# hook mints a receipt for it like any other typed turn, and this record cites that receipt - at which
# point the value can honestly become a confirmation.
$script:SpecrewDesignDecisionConfirmation = 'crew-declared-human-reply'
$script:SpecrewDesignDecisionScope = 'design-decision'

function Get-SpecrewDesignDecisionPath {
    [OutputType([string])]
    param([Parameter(Mandatory)][string] $ProjectRoot, [Parameter(Mandatory)][string] $FeatureRef)
    return (Join-Path (Join-Path (Join-Path $ProjectRoot 'specs') (Split-Path -Leaf $FeatureRef)) 'design-decisions.json')
}

function Find-SpecrewNewestTypedTurn {
    # Feature 203 T004 (FR-014, FR-022; maintainer's decision 2026-11-04, option 1): A WRITER CLI CITES THE NEWEST TYPED
    # TURN ITSELF. The agent never sees the host's message id, so it cannot be asked for one, and its word for what the
    # human typed is not the human's word. The prompt hook reserves every typed message in the exhausted-turn ledger
    # before anything else (its act identity, the hash of its trimmed text, the dispatcher's origin), so the newest
    # reservation from a prompt event IS the human's newest message. The text the CLI was given counts only when its
    # hash is that message's; the turn end's own lines are not prompt events and are never read here.
    # Returns { Found; Matches; TurnIdentity; HostKind; Origin; ObservedAt; Reason }.
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string] $ProjectRoot,
        [AllowNull()][AllowEmptyString()][string] $Text
    )
    $result = [pscustomobject]@{ Found = $false; Matches = $false; TurnIdentity = ''; HostKind = ''; Origin = ''; ObservedAt = $null; Reason = 'no-typed-turn' }
    $path = Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/authority/exhausted-turns.jsonl'
    if (-not [IO.File]::Exists($path)) { return $result }
    $lines = $null
    try { $lines = [IO.File]::ReadAllLines($path) } catch { $result.Reason = 'host-record-unreadable'; return $result }
    $newest = $null; $newestAt = $null
    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $entry = $null
        # A line it cannot read may be the newest message, so the newest cannot be known: it fails closed.
        try { $entry = $line | ConvertFrom-Json -Depth 6 -ErrorAction Stop } catch { $result.Reason = 'host-record-unreadable'; return $result }
        if ($null -eq $entry -or -not $entry.PSObject.Properties['turn_id'] -or [string]::IsNullOrWhiteSpace([string]$entry.turn_id)) { continue }
        if ($entry.PSObject.Properties['fact_type'] -and [string]$entry.fact_type -cne 'typed-turn-exhausted') { continue }
        $event = if ($entry.PSObject.Properties['source_event']) { ([string]$entry.source_event).Trim().ToLowerInvariant() } else { '' }
        if ($event -in @('', 'stop', 'stop-transcript', 'agentstop')) { continue }
        # The time as the line holds it: ConvertFrom-Json turns an ISO time into a local DateTime, whose string form
        # drops the offset.
        $at = $null
        $m = [regex]::Match($line, '"observed_at"\s*:\s*"([^"]+)"')
        $parsed = [DateTimeOffset]::MinValue
        if ($m.Success -and [DateTimeOffset]::TryParse($m.Groups[1].Value, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal, [ref]$parsed)) { $at = $parsed }
        if ($null -eq $at) { continue }
        if ($null -eq $newestAt -or $at -gt $newestAt) { $newest = $entry; $newestAt = $at }
    }
    if ($null -eq $newest) { return $result }
    $result.Found = $true
    $result.TurnIdentity = [string]$newest.turn_id
    $result.HostKind = if ($newest.PSObject.Properties['host_kind']) { [string]$newest.host_kind } else { '' }
    $result.Origin = if ($newest.PSObject.Properties['turn_origin']) { [string]$newest.turn_origin } else { '' }
    $result.ObservedAt = $newestAt
    $hash = ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(([string]$Text).Trim())))).ToLowerInvariant()
    $result.Matches = ($newest.PSObject.Properties['content_hash'] -and [string]$newest.content_hash -ceq $hash)
    $result.Reason = if (-not $result.Matches) { 'newest-turn-differs' } elseif ($result.Origin -cne 'typed-user') { 'not-typed-by-human' } else { '' }
    return $result
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

# Co-review round 9 (T004): words that make a sentence naming an option something other than choosing it: a negation, a
# condition, or still deciding. Read anywhere in the sentence, so a reason that uses one refuses too; the human's sentence
# can be the decision alone ('design decision: option 2'), and the reason goes in the record's rationale.
$script:SpecrewDesignDecisionUndecidedPattern = '(?i)\b(?:not|no|never|neither|nor|undecided|maybe|perhaps|possibly|unsure|if|unless|whether|provided|assuming|depends|depending|tentatively|let\s+me\s+think|think\s+about)\b|n[''\u2019]t\b'

function Get-SpecrewDesignDecisionReading {
    # Co-review round 8 (T004): THE OPTION THE HUMAN'S OWN SENTENCE NAMES, read from it: `design decision: option 2`,
    # `design decision: 2`, `design decision - option B because ...`. The record's `chosen` must be this, so a valid turn
    # citation can never carry a choice the human did not make.
    # Co-review round 9: AND ONLY WHEN THE SENTENCE CHOOSES IT. `option 2?`, `option 2 is not acceptable` and `option 2 - not
    # decided` named option 2 and were recorded as choosing it. The option must be followed by the end of the sentence or a
    # separator before the reason, and the sentence may not ask, negate, set a condition or deliberate.
    # Co-review round 10: THE AFFIRMATIVE FORM, NOT A LIST OF WORDS IT MAY NOT CONTAIN. `option 2 - rejected` and `option 2 -
    # I reject this option` passed the round-9 list, and no list names every way to refuse. A sentence decides only as the
    # option alone, or the option and then a reason introduced as one (`because`, `since`, `as`, `so`); any other text after
    # the option is not read as assent. The list still applies to that reason, so it cannot ask, negate or condition.
    # Returns { Choice; Reason }: Reason '' (Choice is the option), 'names-no-option', or 'not-a-decision'.
    [OutputType([pscustomobject])]
    param([AllowNull()][AllowEmptyString()][string] $Text)
    $reading = [pscustomobject]@{ Choice = ''; Reason = 'names-no-option' }
    if ([string]::IsNullOrWhiteSpace($Text)) { return $reading }
    $m = [regex]::Match($Text, '^\s*design\s+decision\b\s*[:\-\u2013\u2014]?\s*(?:option\s+)?(?<id>[^\s,;:.!?\-\u2013\u2014]+)(?<after>.*)$', 'IgnoreCase, Singleline')
    if (-not $m.Success) { return $reading }
    $after = $m.Groups['after'].Value
    if ($Text.Contains('?') -or $Text -match $script:SpecrewDesignDecisionUndecidedPattern -or
        $after -notmatch '(?i)^\s*(?:[.!]?\s*$|[,;:\-\u2013\u2014]?\s*(?:because|since|as|so)\s+\S)') {
        $reading.Reason = 'not-a-decision'
        return $reading
    }
    $reading.Choice = $m.Groups['id'].Value.Trim()
    $reading.Reason = ''
    return $reading
}

function Get-SpecrewDesignDecisionChoice {
    # The option the sentence chooses (Get-SpecrewDesignDecisionReading); '' when it chooses none.
    [OutputType([string])]
    param([AllowNull()][AllowEmptyString()][string] $Text)
    return [string](Get-SpecrewDesignDecisionReading -Text $Text).Choice
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
    # `recorded_at` is checked as a READABLE TIMESTAMP, not as a [string], and the difference is not
    # pedantry: ConvertFrom-Json silently converts an ISO-8601 timestamp into a [datetime], so a record this
    # very script had just written failed its own read-back with `recorded-at-missing`. The writer's verify
    # step caught it before anything shipped, which is the argument for having a verify step - but a type
    # check that a correct round-trip cannot survive is the check being wrong, not the data. It was the first
    # of three such sites in one batch; all three now read through ConvertTo-SpecrewUtcTimestamp, which
    # accepts whatever shape survived JSON and answers the only question that matters: when.
    $recordedAtProperty = $Record.PSObject.Properties['recorded_at']
    if (-not $recordedAtProperty -or $null -eq $recordedAtProperty.Value -or
        [string]::IsNullOrWhiteSpace([string]$recordedAtProperty.Value)) {
        return (New-Result -Valid $false -Reason 'design-decision-recorded-at-missing')
    }
    if ((Get-Command ConvertTo-SpecrewUtcTimestamp -ErrorAction SilentlyContinue) -and
        $null -eq (ConvertTo-SpecrewUtcTimestamp -Value $recordedAtProperty.Value)) {
        return (New-Result -Valid $false -Reason 'design-decision-recorded-at-unreadable')
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
    # Co-review round 8 (T004): AND IT MUST BE THE OPTION THE HUMAN'S SENTENCE NAMES. The choice used to be a separate
    # parameter, so a real reply choosing option 2 could carry a record of option 1. A sentence that names no option
    # recorded is no decision between them.
    # Co-review round 9: a sentence that asks, negates, conditions or deliberates chooses nothing, whatever it names.
    $reading = Get-SpecrewDesignDecisionReading -Text ([string]$Record.human_turn)
    if ([string]$reading.Reason -ceq 'not-a-decision') {
        return (New-Result -Valid $false -Reason 'design-decision-human-turn-not-a-decision')
    }
    $named = [string]$reading.Choice
    $namedId = @($ids | Where-Object { [string]::Equals($_, $named, [StringComparison]::OrdinalIgnoreCase) })
    if ($namedId.Count -ne 1) {
        return (New-Result -Valid $false -Reason 'design-decision-human-turn-names-no-option')
    }
    if ([string]$namedId[0] -cne ([string]$Record.chosen).Trim()) {
        return (New-Result -Valid $false -Reason 'design-decision-chosen-not-the-human-choice')
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
