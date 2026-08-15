$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# T010 / FR-015, FR-016 / SC-009 - THE CONSUMER LANGUAGE LAYER.
#
# The acceptance bar names the failure directly: a consumer completes their first feature without
# hitting "a sentence they cannot understand". Three instances were measured in this feature, and they
# are one defect in different clothes - a surface that is TRUE and still unusable:
#
#   - the stale block named a run and a snapshot, every word accurate, and omitted the one fact that
#     made it dismissible; the reader investigated and found nothing
#   - its only remediation was addressed to a role the reader might not hold, so the block could never
#     be cleared and re-fired at every stop - and a block correctly declined every time teaches people
#     to stop reading blocks, which is how the one that matters gets missed
#   - a bare `T006` or `FR-013` is the same failure at sentence scale: an identifier the reader must go
#     and look up before the sentence means anything
#
# These helpers are deliberately PURE text functions with no lifecycle knowledge, so packet templates,
# stop messages, skill instructions and the banner can all consult the same rules.

function Format-SpecrewIdGloss {
    # An identifier never travels alone. REFUSING a missing description is the point: a helper that
    # silently passed the id through would let every caller emit exactly the defect it exists to
    # prevent, and the failure would surface as a confusing sentence rather than a broken build.
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Id,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Title
    )
    if ([string]::IsNullOrWhiteSpace($Id)) { throw 'specrew-id-gloss-requires-an-id' }
    if ([string]::IsNullOrWhiteSpace($Title)) {
        throw ("specrew-id-gloss-requires-a-description: '{0}' must be written with a short description a reader can act on, e.g. '{0} (what it does)'" -f $Id.Trim())
    }
    return ('{0} ({1})' -f $Id.Trim(), $Title.Trim())
}

# The identifier shapes this project actually uses in consumer-facing prose. Deliberately NARROW: a
# detector that also flagged version strings, commit hashes or ordinary words would be switched off
# within a week, and a switched-off detector guards nothing.
$script:SpecrewConsumerIdPattern = '\b(?<id>(?:T\d{3}|(?:FR|SC|NFR|US)-\d{3}))\b'

function Get-SpecrewUnglossedId {
    # Returns the identifiers that appear WITHOUT a description. Only the FIRST use must be glossed:
    # requiring every occurrence would push authors toward dropping the id entirely, and the reader
    # would lose the handle they need to search the records.
    [OutputType([string[]])]
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) { return @() }
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $unglossed = [Collections.Generic.List[string]]::new()
    foreach ($match in [regex]::Matches($Text, $script:SpecrewConsumerIdPattern)) {
        $id = [string]$match.Groups['id'].Value
        if (-not $seen.Add($id)) { continue }   # specrew-dedup-not-a-path
        # A gloss is a parenthesised description immediately after the id. An EMPTY pair of brackets is
        # not a description - it is the same bare id with decoration.
        $rest = $Text.Substring($match.Index + $match.Length)
        if ($rest -match '^\s*\((?<body>[^)]*)\)' -and -not [string]::IsNullOrWhiteSpace($Matches['body'])) { continue }
        $unglossed.Add($id) | Out-Null
    }
    return @($unglossed)
}

# Machinery vocabulary that must never reach a consumer surface. LIFECYCLE STAGE NAMES and approval
# phrases are deliberately ABSENT: they are the words the human is asked to USE, and banning them would
# make the approval instruction unspeakable.
$script:SpecrewBannedConsumerNouns = @(
    'crossing', 'mint', 'marker', 'digest', 'boundary sync', 'verdict capture',
    'controller truth', 'workshop controller', 'controller plumbing', 'governed controller state',
    'lens-applicability.json', 'ratchet', 'claim-ordered', 'terminalize'
)

function Get-SpecrewBannedConsumerNoun {
    # Case-insensitive on purpose: a capitalised "Digest" is the same word to a reader.
    #
    # INFLECTIONS MATTER, and this was found by running the detector over its own release notes. The
    # first version matched `\bmint\b`, which reports CLEAN on "a fresh authorization was minted" - the
    # exact sentence the ban exists to catch. A detector that passes the inflected form of a banned word
    # is worse than none, because it certifies the text as checked.
    #
    # Suffixes are bounded deliberately (s / ed / ing / e / es). A looser rule would start matching
    # unrelated words and get the detector switched off, which guards nothing.
    [OutputType([string[]])]
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) { return @() }
    $found = [Collections.Generic.List[string]]::new()
    foreach ($noun in $script:SpecrewBannedConsumerNouns) {
        $pattern = '\b' + [regex]::Escape($noun) + '(?:e?s|ed|ing)?\b'
        if ([regex]::IsMatch($Text, $pattern, 'IgnoreCase')) { $found.Add($noun) | Out-Null }
    }
    return @($found)
}

function Get-SpecrewUnprovenFaultAttribution {
    # A refusal may state what the agent could not complete. It may not diagnose Specrew as broken or
    # at fault in the message shown to the human: the emitting agent does not have enough evidence to
    # distinguish its own missed step from inconsistent project records or a product defect. Diagnosis
    # belongs in the drift record, where evidence can support it.
    [OutputType([string[]])]
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) { return @() }
    $patterns = @(
        '\bSpecrew\b.{0,100}\b(?:broken|buggy|at fault|has (?:a )?problem|failed)\b',
        '\b(?:broken|bug|fault|problem|failure)\b.{0,100}\b(?:in|with)\s+Specrew\b'
    )
    $found = [Collections.Generic.List[string]]::new()
    foreach ($pattern in $patterns) {
        foreach ($match in [regex]::Matches($Text, $pattern, 'IgnoreCase')) {
            $found.Add($match.Value) | Out-Null
        }
    }
    return @($found)
}
