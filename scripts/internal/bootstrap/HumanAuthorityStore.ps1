$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# W73: the conditional-clause rule lives in the capture accessor, which loads ahead of this module in
# every production path. Tests and tools that load this module alone still get it, because a recognizer
# missing its deferral guard would mint conditional approvals - the failure this fix exists to end.
if (-not (Get-Command Test-SpecrewConditionalDeferralClause -ErrorAction SilentlyContinue)) {
    $specrewCaptureAccessor = Join-Path $PSScriptRoot 'ConversationCaptureAccessor.ps1'
    if (Test-Path -LiteralPath $specrewCaptureAccessor -PathType Leaf) { . $specrewCaptureAccessor }
}
function Get-SpecrewReviewSignoffOverrideRoot {
    param([Parameter(Mandatory)][string]$ProjectRoot)
    return Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/review/signoff-gate'
}

function Get-SpecrewHumanAuthorityHash {
    param([AllowEmptyString()][string]$Text)
    return ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes([string]$Text)))).ToLowerInvariant()
}

function ConvertTo-SpecrewHumanAuthoritySourceEvent {
    param([AllowNull()][string]$SourceEvent)
    $key = ([string]$SourceEvent).Trim().ToLowerInvariant() -replace '[-_]', ''
    switch ($key) {
        'userpromptsubmit' { return 'UserPromptSubmit' }
        'userpromptsubmitted' { return 'UserPromptSubmit' }
        'preinvocation' { return 'PreInvocation' }
        default { return $null }
    }
}

function Write-SpecrewReviewSignoffOverrideRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$TargetTreeId,
        [Parameter(Mandatory)][string]$CampaignId,
        [AllowNull()][string]$RunId,
        [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o'))
    )
    if ($TargetTreeId -cnotmatch '^[a-f0-9]{40,64}$') { throw 'review-signoff-override-request-tree-invalid' }
    if ($CampaignId -cnotmatch '^cmp-[a-z0-9][a-z0-9-]{1,190}$') { throw 'review-signoff-override-request-campaign-invalid' }
    $requestId = 'override-' + (Get-SpecrewHumanAuthorityHash -Text ($TargetTreeId + '|' + $CampaignId)).Substring(0, 24)
    $request = [pscustomobject][ordered]@{
        schema_version = '1.0'
        request_id = $requestId
        target_tree_id = $TargetTreeId
        campaign_id = $CampaignId
        run_id = [string]$RunId
        required_phrase = 'approved for partial review signoff - <why accepting partial coverage is safe>'
        created_at = $NowUtc
    }
    $root = Get-SpecrewReviewSignoffOverrideRoot -ProjectRoot $ProjectRoot
    [IO.Directory]::CreateDirectory($root) | Out-Null
    $path = Join-Path $root 'pending-override.json'
    $json = $request | ConvertTo-Json -Depth 8
    if (Get-Command Write-SpecrewFileAtomic -ErrorAction SilentlyContinue) { Write-SpecrewFileAtomic -Path $path -Content $json }
    else { [IO.File]::WriteAllText($path, $json, [Text.UTF8Encoding]::new($false)) }
    return $request
}

function Read-SpecrewReviewSignoffOverrideRequest {
    param([Parameter(Mandatory)][string]$ProjectRoot)
    $path = Join-Path (Get-SpecrewReviewSignoffOverrideRoot -ProjectRoot $ProjectRoot) 'pending-override.json'
    if (-not [IO.File]::Exists($path)) { return $null }
    $item = Get-Item -LiteralPath $path -ErrorAction Stop
    if ($item.Length -le 0 -or $item.Length -gt 65536) { throw 'review-signoff-override-request-size-invalid' }
    try { $request = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop }
    catch { throw 'review-signoff-override-request-json-invalid' }
    foreach ($name in @('schema_version', 'request_id', 'target_tree_id', 'campaign_id', 'required_phrase', 'created_at')) {
        $property = $request.PSObject.Properties[$name]
        if (-not $property -or [string]::IsNullOrWhiteSpace([string]$property.Value)) { throw "review-signoff-override-request-field-missing:$name" }
    }
    if ([string]$request.schema_version -cne '1.0') { throw 'review-signoff-override-request-schema-invalid' }
    if ([string]$request.target_tree_id -cnotmatch '^[a-f0-9]{40,64}$' -or
        [string]$request.campaign_id -cnotmatch '^cmp-[a-z0-9][a-z0-9-]{1,190}$') {
        throw 'review-signoff-override-request-identity-invalid'
    }
    $expectedRequestId = 'override-' + (Get-SpecrewHumanAuthorityHash -Text ([string]$request.target_tree_id + '|' + [string]$request.campaign_id)).Substring(0, 24)
    if ([string]$request.request_id -cne $expectedRequestId -or
        [string]$request.required_phrase -cne 'approved for partial review signoff - <why accepting partial coverage is safe>') {
        throw 'review-signoff-override-request-binding-invalid'
    }
    $createdAt = [DateTimeOffset]::MinValue
    if (-not [DateTimeOffset]::TryParse([string]$request.created_at, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind, [ref]$createdAt)) {
        throw 'review-signoff-override-request-time-invalid'
    }
    return $request
}

function Write-SpecrewReviewSignoffOverrideAuthorization {
    # SPECREW-AUTHORITY-CONTROL: partial-review-signoff
    <# Capture only from a genuine prompt-entry event and only while a tree-bound request exists. #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$Response,
        [AllowNull()][string]$HostKind,
        [AllowNull()][string]$SourceEvent,
        # 203 T004 (FR-021): the typed act's identity; a later sign-off for the same request supersedes, never conflicts.
        [AllowNull()][string]$TurnIdentity,
        [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o'))
    )
    $event = ConvertTo-SpecrewHumanAuthoritySourceEvent -SourceEvent $SourceEvent
    if ($null -eq $event) { return $null }
    $trimmed = $Response.Trim()
    if ($trimmed -match '(?is)^\s*<(?:hook_prompt\b|task-notification\b|turn_aborted\b|system-reminder\b|environment_context\b)') { return $null }
    $match = [regex]::Match($trimmed, '(?is)^approved\s+for\s+partial\s+review\s+signoff\s*[-:]\s*(?<rationale>.+?)\s*$')
    if (-not $match.Success) { return $null }
    # Feature 203 T013 (maintainer ruling 2026-11-12; PRED-BETA4-022's class): THE REASON IS THE PHRASE'S OWN LINE, on every
    # host. DRIFT-199-I002-034 below left bounding it as a contract change; a pasted transcript that starts with the phrase,
    # on a host that cannot mark pastes, had every line after the dash read as the reason and was recorded. A message that
    # goes on past the phrase's line records nothing, and the human is told to send the one line again.
    if (Test-SpecrewAuthorityMessageContinues -Text $trimmed) {
        [Console]::Error.WriteLine("[specrew-authority] YOUR APPROVAL WAS NOT RECORDED. The phrase matched, but your message goes on past the phrase's line, and the reason must be on that same line. Nothing is wrong with your decision and nothing else has changed. Send the approval again as the WHOLE message, on one line: 'approved for partial review signoff - <why accepting it is safe>'.")
        try {
            $dropJournal = Join-Path $ProjectRoot '.specrew/runtime/authority-capture-drops.jsonl'
            $dropDir = Split-Path -Parent $dropJournal
            if ($dropDir -and -not (Test-Path -LiteralPath $dropDir)) { New-Item -ItemType Directory -Path $dropDir -Force | Out-Null }
            (([pscustomobject][ordered]@{ event = 'authority-phrase-matched-but-rejected'; phrase = 'review-signoff-partial-override'; reason = 'rationale-not-one-line'
                        line_count = (Get-SpecrewAuthorityMessageLineCount -Text $trimmed); recorded_at = $NowUtc
                        # Feature 203 T012 (FR-041): the refusal names the typed turn it refused.
                        turn_identity = [string]$TurnIdentity; turn_identity_source = $(if ([string]::IsNullOrWhiteSpace($TurnIdentity)) { '' } else { 'refused-message' }) }) | ConvertTo-Json -Compress) | Add-Content -LiteralPath $dropJournal -Encoding UTF8
        }
        catch { $null = $_ }
        return $null
    }
    # ONCE THE PHRASE HAS MATCHED, A REJECTION MUST SPEAK. (DRIFT-199-I002-034.)
    #
    # This is where a maintainer's valid approval was discarded in silence: the rationale group is read
    # with `(?is)` and no `m`, so it is EVERYTHING from the dash to the end of the message rather than the
    # sentence attached to the phrase. An approval followed by two further instruction paragraphs measured
    # 2193 characters, exceeded the cap, and `return $null` said nothing. The gate then refused with
    # `latest-result-not-current` - true, and about something else entirely - so the human retyped a phrase
    # that had never been wrong, twice.
    #
    # A phrase that did NOT match stays silent: that is ordinary conversation and announcing it would make
    # every message a diagnostic. A phrase that DID match and was then rejected is a human trying to
    # authorize something, and their attempt must never vanish. The message says what to do, not only what
    # happened - the standard that found this defect applies to its replacement.
    #
    # Bounding the rationale to its own paragraph is the better fix and is a change to what COUNTS as a
    # rationale, i.e. a contract change; it is beta4's, by the same rule that declined to widen the
    # binding-name pattern mid-batch (DRIFT-199-I002-029).
    $rationale = $match.Groups['rationale'].Value.Trim()
    if ($rationale.Length -lt 10 -or $rationale.Length -gt 2000) {
        $why = if ($rationale.Length -gt 2000) {
            ("the reason attached to it is too long ({0} characters; the limit is 2000). Note that everything after the dash counts, including anything you wrote further down the same message" -f $rationale.Length)
        }
        else {
            ("the reason attached to it is too short ({0} characters; at least 10 are needed)" -f $rationale.Length)
        }
        $line = ("[specrew-authority] YOUR APPROVAL WAS NOT RECORDED. The phrase matched, but {0}. Nothing is wrong with your decision and nothing else has changed. Send the approval again as the WHOLE message, with a short reason and nothing after it: 'approved for partial review signoff - <why accepting it is safe>'." -f $why)
        [Console]::Error.WriteLine($line)
        try {
            $dropJournal = Join-Path $ProjectRoot '.specrew/runtime/authority-capture-drops.jsonl'
            $dropDir = Split-Path -Parent $dropJournal
            if ($dropDir -and -not (Test-Path -LiteralPath $dropDir)) { New-Item -ItemType Directory -Path $dropDir -Force | Out-Null }
            (([pscustomobject][ordered]@{ event = 'authority-phrase-matched-but-rejected'; phrase = 'review-signoff-partial-override'; reason = $(if ($rationale.Length -gt 2000) { 'rationale-too-long' } else { 'rationale-too-short' }); rationale_length = $rationale.Length; recorded_at = $NowUtc
                        # Feature 203 T012 (FR-041): the refusal names the typed turn it refused.
                        turn_identity = [string]$TurnIdentity; turn_identity_source = $(if ([string]::IsNullOrWhiteSpace($TurnIdentity)) { '' } else { 'refused-message' }) }) | ConvertTo-Json -Compress) | Add-Content -LiteralPath $dropJournal -Encoding UTF8
        }
        catch { $null = $_ }
        return $null
    }
    $request = Read-SpecrewReviewSignoffOverrideRequest -ProjectRoot $ProjectRoot
    if ($null -eq $request) {
        # The phrase matched and there is nothing outstanding to authorize. Silence here would read to the
        # human exactly like the over-length drop did: an approval that vanished.
        [Console]::Error.WriteLine("[specrew-authority] YOUR APPROVAL WAS NOT RECORDED. The phrase matched, but no partial-coverage approval is currently outstanding for this project, so there was nothing for it to authorize. Nothing is wrong with your decision. Run the review command once to see whether it still refuses - if it does, it will name the approval it wants, and sending the phrase again straight afterwards will be recorded against it.")
        return $null
    }

    $fact = [pscustomobject][ordered]@{
        schema_version = '1.0'
        fact_type = 'review-signoff-partial-override'
        request_id = [string]$request.request_id
        target_tree_id = [string]$request.target_tree_id
        campaign_id = [string]$request.campaign_id
        run_id = [string]$request.run_id
        authority_kind = 'human'
        authorized_by = 'unattributed-human'
        verdict_text = $trimmed
        rationale = $rationale
        response_hash = Get-SpecrewHumanAuthorityHash -Text $trimmed
        evidence_source = 'hook-captured-user-prompt'
        source_event = $event
        host_kind = [string]$HostKind
        observed_at = $NowUtc
        turn_identity = [string]$TurnIdentity
    }
    $root = Get-SpecrewReviewSignoffOverrideRoot -ProjectRoot $ProjectRoot
    $factsRoot = Join-Path $root 'override-authorizations'
    [IO.Directory]::CreateDirectory($factsRoot) | Out-Null
    $path = Join-Path $factsRoot (([string]$request.request_id) + '.json')
    $json = $fact | ConvertTo-Json -Depth 8
    if ([IO.File]::Exists($path)) {
        try { $existing = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop }
        catch { throw 'review-signoff-override-authorization-json-invalid' }
        # 203 T004 (FR-021): a later typed sign-off for the same request is the human's newer reason. It replaces the
        # record, with the fact naming what it retired journalled first; the conflict below is for a writer with no
        # turn identity to tell the two apart.
        $succession = Resolve-SpecrewTypedActSupersession -Existing $existing -TurnIdentity $TurnIdentity -NowUtc $NowUtc `
            -JournalPath (Join-Path $root 'supersessions.jsonl') -FactType 'review-signoff-partial-override'
        if ($succession -cin @('same-act', 'keep-newer')) { return $existing }
        if ($succession -ceq 'refused') { return $null }
        if ($succession -ceq 'superseded') {
            if (Get-Command Write-SpecrewFileAtomic -ErrorAction SilentlyContinue) { Write-SpecrewFileAtomic -Path $path -Content $json }
            else { [IO.File]::WriteAllText($path, $json, [Text.UTF8Encoding]::new($false)) }
            return $fact
        }
        $sameAuthority =
            [string]$existing.schema_version -ceq [string]$fact.schema_version -and
            [string]$existing.fact_type -ceq [string]$fact.fact_type -and
            [string]$existing.request_id -ceq [string]$fact.request_id -and
            [string]$existing.target_tree_id -ceq [string]$fact.target_tree_id -and
            [string]$existing.campaign_id -ceq [string]$fact.campaign_id -and
            [string]$existing.authority_kind -ceq 'human' -and
            [string]$existing.verdict_text -ceq [string]$fact.verdict_text -and
            [string]$existing.rationale -ceq [string]$fact.rationale -and
            [string]$existing.response_hash -ceq [string]$fact.response_hash -and
            [string]$existing.evidence_source -ceq [string]$fact.evidence_source -and
            [string]$existing.source_event -ceq [string]$fact.source_event
        if (-not $sameAuthority) {
            throw 'review-signoff-override-authorization-conflict'
        }
        return $existing
    }
    else {
        $stream = [IO.File]::Open($path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::Read)
        try {
            $bytes = [Text.UTF8Encoding]::new($false).GetBytes($json)
            $stream.Write($bytes, 0, $bytes.Length)
            $stream.Flush($true)
        }
        finally { $stream.Dispose() }
    }
    return $fact
}

function Get-SpecrewReviewSignoffOverrideAuthorization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$ExpectedTargetTreeId,
        [Parameter(Mandatory)][string]$ExpectedCampaignId
    )
    $request = Read-SpecrewReviewSignoffOverrideRequest -ProjectRoot $ProjectRoot
    if ($null -eq $request -or [string]$request.target_tree_id -cne $ExpectedTargetTreeId -or [string]$request.campaign_id -cne $ExpectedCampaignId) { return $null }
    $path = Join-Path (Join-Path (Get-SpecrewReviewSignoffOverrideRoot -ProjectRoot $ProjectRoot) 'override-authorizations') (([string]$request.request_id) + '.json')
    if (-not [IO.File]::Exists($path)) { return $null }
    $item = Get-Item -LiteralPath $path -ErrorAction Stop
    if ($item.Length -le 0 -or $item.Length -gt 65536) { throw 'review-signoff-override-authorization-size-invalid' }
    try { $fact = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop }
    catch { throw 'review-signoff-override-authorization-json-invalid' }
    foreach ($name in @('schema_version', 'fact_type', 'request_id', 'target_tree_id', 'campaign_id', 'authority_kind', 'authorized_by', 'verdict_text', 'rationale', 'response_hash', 'evidence_source', 'source_event', 'observed_at')) {
        $property = $fact.PSObject.Properties[$name]
        if (-not $property -or [string]::IsNullOrWhiteSpace([string]$property.Value)) { throw "review-signoff-override-authorization-field-missing:$name" }
    }
    if ([string]$fact.schema_version -cne '1.0' -or [string]$fact.fact_type -cne 'review-signoff-partial-override' -or
        [string]$fact.request_id -cne [string]$request.request_id -or [string]$fact.target_tree_id -cne $ExpectedTargetTreeId -or
        [string]$fact.campaign_id -cne $ExpectedCampaignId -or [string]$fact.authority_kind -cne 'human' -or
        [string]$fact.evidence_source -cne 'hook-captured-user-prompt' -or
        [string]$fact.source_event -cnotin @('UserPromptSubmit', 'PreInvocation')) { return $null }
    $storedRationale = [string]$fact.rationale
    $storedVerdict = [string]$fact.verdict_text
    $storedMatch = [regex]::Match($storedVerdict, '(?is)^approved\s+for\s+partial\s+review\s+signoff\s*[-:]\s*(?<rationale>.+?)\s*$')
    if (-not $storedMatch.Success -or $storedMatch.Groups['rationale'].Value.Trim() -cne $storedRationale -or
        [string]$fact.response_hash -cne (Get-SpecrewHumanAuthorityHash -Text $storedVerdict) -or
        $storedRationale.Length -lt 10 -or $storedRationale.Length -gt 2000) {
        throw 'review-signoff-override-authorization-content-invalid'
    }
    $observedAt = [DateTimeOffset]::MinValue
    if (-not [DateTimeOffset]::TryParse([string]$fact.observed_at, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind, [ref]$observedAt)) {
        throw 'review-signoff-override-authorization-time-invalid'
    }
    # Feature 203 T013 (B5F-066): used only when the human typed it.
    if (-not (Test-SpecrewAuthorizationRecordSender -ProjectRoot $ProjectRoot -Record $fact -Purpose 'partial sign-off')) { return $null }
    return $fact
}

# ===================================================================================================
# W44 (2026-08-22, maintainer ruling): ROUND APPROVAL IS A TYPED PHRASE, LIKE EVERY OTHER AUTHORITY.
#
# The human's role in this system is authorization, not operation. Boundary verdicts, partial signoff
# and workshop repair are all typed phrases captured from the conversation, with the agent operating
# the machinery afterwards. Round approval alone demanded the human execute a CLI command - the W36
# split, now ruled wrong: telling a human in a conversation to go run `specrew review --live
# --approve-round` is inconsistent with the system's own model, and it failed as UX the first day
# (the bash-PATH seam).
#
# So: the human types `approved for review round`; the hook captures it here, from the human's own
# prompt entry, exactly as the partial-signoff override above is captured; and the agent then runs the
# command carrying that captured phrase as its authority. An agent invoking --approve-round with no
# captured phrase is refused. A human invoking it from their own terminal - outside any agent session -
# is still self-evidently authorized: the invocation IS the approving act, performed by the human.
# ===================================================================================================

function Get-SpecrewAuthorityApprovalLine {
    # W56 / round-15 finding (DRIFT-199-I001-125): THE APPROVAL LIVES ON ITS OWN LINE.
    #
    # Every authority recognizer used to collapse all whitespace BEFORE deciding, so a paragraph
    # break became an ordinary space and a real approval followed by an instruction block read as
    # arbitrary prose after the phrase - refused, forcing the human to type a second bare message.
    # Measured live: the maintainer's approval, refused, with the round it authorized never run.
    #
    # This returns the approval's own line, whitespace-normalized: everything before the first line
    # break. Within it, the closed tail, the deferral scan and the interrogative test apply exactly
    # as before - a same-line condition ("..., once the tests pass") still defers, which is round
    # 14's guarantee. What follows a line break is an instruction BLOCK and is not scanned, the same
    # doctrine the boundary-verdict recognizer already applies across a sentence break.
    [OutputType([string])]
    param([Parameter()][AllowNull()][AllowEmptyString()][string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return '' }
    $firstLine = ([regex]::Split($Text, '\r\n|\n|\r', 2))[0]
    return (($firstLine -replace '\s+', ' ').Trim())
}

function Test-SpecrewAuthorityMessageContinues {
    # A VERDICT IS ONE LINE (PRED-BETA4-022, the sharpest authority-corruption case in the beta4 record):
    # the phrase, plus at most the documented same-line instruction form. W56 made every recognizer decide
    # on the phrase's own line so an instruction BLOCK below it would not refuse the approval - and that
    # is exactly how a 136-line Copilot transcript from ANOTHER project, pasted into a reviewer session
    # with the human's typed phrase still at its top, was minted here as a live review-round approval,
    # twice, under two encodings. The first line matched; the other 135 were never looked at. A message
    # that continues past its first line into non-empty content is not a verdict, whatever its first
    # line says; it is refused, and the refusal is disclosed so the human retypes ONE line.
    [OutputType([bool])]
    param([Parameter()][AllowNull()][AllowEmptyString()][string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $false }
    # The INSTANCE Split takes a count; the static three-argument form reads a RegexOptions there and
    # splits everything, which made "the rest" mean line two alone (found by W56's own blank-line case).
    $parts = [regex]::new('\r\n|\n|\r').Split($Text.Trim(), 2)
    if ($parts.Count -lt 2) { return $false }
    return (-not [string]::IsNullOrWhiteSpace([string]$parts[1]))
}

function Get-SpecrewAuthorityMessageLineCount {
    [OutputType([int])]
    param([Parameter()][AllowNull()][AllowEmptyString()][string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return 0 }
    return @([regex]::Split($Text.Trim(), '\r\n|\n|\r')).Count
}

# Feature 202 iteration 002, T018 (FR-029, DA-3; B4F-125): THE FORM A TYPED APPROVAL MAY TAKE.
#
# The one-line rule (PRED-BETA4-022) exists because a pasted transcript with the phrase at its top was once recorded as an
# approval, and on a host that cannot tell a paste from typing it is the only safe rule. It also refused the maintainer's
# own `approved for allowance reset`, typed on its own line below a paste of their own notes (B4F-125 a). Claude marks a
# paste in the message itself, so there the rule is exact: nothing inside a paste counts, and a phrase leading its own
# line outside every paste is an approval, whatever typed text surrounds it. A paste is marked only by an opening and a
# closing tag carrying the same ID, so a closing tag quoted inside a paste never ends it, and an opening tag that is never
# closed makes everything after it pasted. On every host, a message carrying more than one verdict option is a quoted
# menu - the crew's own options, copied back - and never an approval.
$script:SpecrewMachineryEnvelopeLinePattern = '(?im)^\s*</?(?:hook_prompt|task-notification|turn_aborted|system-reminder|environment_context|command-name|local-command|bash-stdout)\b'
$script:SpecrewVerdictOptionLinePattern = '^(?:approv(?:e|ed)\s+for\b|changes\s+needed\s*:|discuss\s+prompt\b|stop\s+the\s+review\s+here\b|abandon\s+this\s+review\s+campaign\b|continue\s+without\s+coverage\b|hold\s+implementation\s+here\b|withdraw\s+the\s+approval\b)'

# THE OBSERVED PASTE-SIZE BOUNDARY (T018). Claude tags a paste only above a size, so untagged text is typing only while it
# is small. Measured on this project's Claude transcripts (2026-10-18): the smallest of 26 tagged pastes was 675 characters
# over 9 lines, and no untagged multi-line human message appears at all. Untagged text past either limit cannot be told
# from an untagged paste, so the one-line rule decides it - which is what keeps a large pasted transcript with the phrase
# at its top refused on Claude as well (PRED-BETA4-022).
$script:SpecrewTypedTextMaxLines = 8

# Feature 203 T013 (B5F-064): the wrapper Claude Code puts around another session's message when it delivers it as a prompt
# (tests/fixtures/hook-payloads/claude/peer-message). The same text rule is in Claude's host binding and the dispatcher's
# defaults, so the prompt hook gives such a prompt origin host-injected.
$script:SpecrewPeerMessagePattern = '(?s)^\s*(?:Another Claude session sent a message:\s*)?<cross-session-message\b'
$script:SpecrewTypedTextMaxChars = 674

function Test-SpecrewHostMarksPastes {
    # The hosts whose recorded payloads mark a paste in the message (Claude's `<pasted_content id="N">`). Every other
    # host keeps "the phrase alone" until a recorded payload shows how it marks one.
    [OutputType([bool])]
    param([AllowNull()][string]$HostKind)
    return ((([string]$HostKind).Trim().ToLowerInvariant()) -ceq 'claude')
}

function Remove-SpecrewPairedPastes {
    # The human's own text: every paste removed. A paste runs from `<pasted_content id="N">` to the first
    # `</pasted_content id="N">` with the SAME ID after it; an opening tag never closed runs to the end of the message.
    [OutputType([string])]
    param([AllowNull()][AllowEmptyString()][string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return '' }
    $rest = $Text
    $kept = New-Object System.Text.StringBuilder
    while ($true) {
        $open = [regex]::Match($rest, '<pasted_content\s+id="(?<id>[^"]+)"\s*>')
        if (-not $open.Success) { [void]$kept.Append($rest); break }
        [void]$kept.Append($rest.Substring(0, $open.Index))
        $closeTag = '</pasted_content id="' + $open.Groups['id'].Value + '">'
        $close = $rest.IndexOf($closeTag, $open.Index + $open.Length, [StringComparison]::Ordinal)
        if ($close -lt 0) { break }
        [void]$kept.Append([Environment]::NewLine)
        $rest = $rest.Substring($close + $closeTag.Length)
    }
    return $kept.ToString()
}

function Resolve-SpecrewApprovalForm {
    # What the recognizers decide on. { Text; Reason; Options }: Reason 'quoted-menu' when the human's own text carries
    # more than one verdict option and one of them is a typed authority phrase (Text unchanged, so nothing mints); on a
    # host that marks pastes, Text is the one authority line outside every paste, or the text with its pastes removed.
    # Reason 'machinery-envelope' when the human's own text is wrapped in a host envelope, and 'qualified' when the typed
    # text beside the one authority line carries a condition or a reversal (Text is then left multi-line, so it refuses).
    # Anywhere else Text is the message unchanged, and the one-line rule decides.
    [OutputType([pscustomobject])]
    param([AllowNull()][AllowEmptyString()][string]$Text, [AllowNull()][string]$HostKind)
    $result = [pscustomobject]@{ Text = [string]$Text; Reason = ''; Options = @() }
    if ([string]::IsNullOrWhiteSpace($Text)) { return $result }
    $marks = Test-SpecrewHostMarksPastes -HostKind $HostKind
    $outside = if ($marks) { Remove-SpecrewPairedPastes -Text $Text } else { [string]$Text }
    # Co-review round 5 (iteration 002): text the host or the machinery wrapped in one of its envelopes is never reduced to
    # the authority line inside it. Every writer refuses an envelope at the start of the message; reduced, the envelope was
    # gone before any writer saw it, and '<hook_prompt>' around 'approved for review round' recorded a human approval.
    # Co-review round 6: looked for in the human's own text, outside every paste. A pasted log that quoted a
    # '<system-reminder>' line hid the approval typed below it, and no refusal said so.
    if ($outside -match $script:SpecrewMachineryEnvelopeLinePattern) { $result.Reason = 'machinery-envelope'; return $result }
    $lines = @([regex]::Split($outside, '\r\n|\n|\r') | ForEach-Object { (($_ -replace '\s+', ' ').Trim()) } | Where-Object { $_ })
    $shapeOf = { param([string]$Line) if (Get-Command Get-SpecrewTypedAuthorityShape -ErrorAction SilentlyContinue) { Get-SpecrewTypedAuthorityShape -Text $Line } else { $null } }
    # Co-review round 6: an option is an option whatever it is wrapped in. A menu copied with its bullets, quote marks,
    # numbers or inline code had one counted option, so it was not a quoted menu and its approval line was recorded.
    $options = @($lines | ForEach-Object { ConvertTo-SpecrewVerdictOptionText -Line $_ } | Where-Object { $_ -match $script:SpecrewVerdictOptionLinePattern } | Select-Object -Unique)
    $authorityLines = @($lines | Where-Object { $null -ne (& $shapeOf $_) })
    if ($options.Count -ge 2 -and $authorityLines.Count -ge 1) {
        $result.Reason = 'quoted-menu'; $result.Options = $options
        return $result
    }
    # Co-review round 6: THE OTHER TYPED LINES CAN QUALIFY THE APPROVAL. Reduced to its line, 'approved for review round'
    # above 'provided the security checks pass' reached the writer with nothing after it, so the condition every writer
    # refuses on the same line was never seen and the round was spendable at once. When the typed text beside the line
    # carries a condition or a reversal, the message is not reduced, and the one-line rule refuses it by name.
    # Co-review round 8: on every host. Looked for only where the host marks pastes, the condition reached the partial
    # sign-off writer unrefused on Codex and Copilot, and that writer reads every line after its dash as the reason.
    $others = @($lines | Where-Object { $null -eq (& $shapeOf $_) })
    $qualified = ($authorityLines.Count -eq 1 -and $others.Count -gt 0 -and (Test-SpecrewAuthorityContextQualifies -Text ($others -join ' ')))
    # Feature 203 T013 (maintainer ruling 2026-11-12; PRED-BETA4-022's class): a partial sign-off is the human's whole typed text,
    # on every host. Its reason is the phrase's own line, so any other typed line beside it - text typed on after it, or a
    # paste Copilot and Codex cannot mark - is never reduced away: the message is refused by name and the human retypes it.
    if (-not $qualified -and $authorityLines.Count -eq 1 -and $others.Count -gt 0) {
        $authorityShape = & $shapeOf ([string]$authorityLines[0])
        if ($null -ne $authorityShape -and [string]$authorityShape.Kind -ceq 'partial-review-signoff') { $qualified = $true }
    }
    if ($marks) {
        $typedSized = ($lines.Count -le $script:SpecrewTypedTextMaxLines -and $outside.Trim().Length -le $script:SpecrewTypedTextMaxChars)
        if ($typedSized -and $authorityLines.Count -eq 1 -and -not $qualified) { $result.Text = [string]$authorityLines[0] }
        elseif ($typedSized -and $qualified) { $result.Text = $outside.Trim(); $result.Reason = 'qualified' }
        elseif ($outside -cne [string]$Text) { $result.Text = $outside.Trim() }
    }
    elseif ($qualified) { $result.Reason = 'qualified' }
    return $result
}

function ConvertTo-SpecrewVerdictOptionText {
    # One line as an option reads: lower-cased, its list, quote and number markers and its inline emphasis or code marks
    # removed, as the turn's meaning lines are read.
    [OutputType([string])]
    param([AllowNull()][AllowEmptyString()][string]$Line)
    $text = ([string]$Line).Trim().ToLowerInvariant()
    $previous = $null
    while ($text -cne $previous) {
        $previous = $text
        $text = ($text -replace '^(?:[-*+>]\s+|>|\d+[.)]\s+|[`*_~"''“”]+)', '').TrimStart()
    }
    return $text
}

# A condition or reversal in the typed text beside an approval line: the clauses the writers refuse after the phrase on its
# own line (Test-SpecrewConditionalDeferralClause, and the reversals the round writer names).
$script:SpecrewAuthorityContextReversalPattern = '\b(?:do\s*not|don''t|dont|never|not\s+yet|no\s+longer|cancel|withdraw|revoke|rescind|retract|hold\s+off|stand\s+down|stop|abort|wait|scratch\s+that|never\s+mind|nevermind|actually\s+(?:stop|no|not)|disregard|ignore\s+that|only)\b'

function Test-SpecrewAuthorityContextQualifies {
    [OutputType([bool])]
    param([AllowNull()][AllowEmptyString()][string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $false }
    $lower = $Text.ToLowerInvariant()
    if (Test-SpecrewConditionalDeferralClause -Text $lower) { return $true }
    return [bool]($lower -match $script:SpecrewAuthorityContextReversalPattern)
}

function Get-SpecrewAuthorityMultiLineRefusal {
    # THE SWEEP BEHIND THE DISCLOSURE. Runs the minting recognizers that carry the one-line rule and
    # names the first that refused THIS text for continuing past its line - so the drop writer below
    # and the prompt-entry disclosure read one answer, in one place, and a recognizer added later
    # joins the table here rather than growing its own copy (the W66 lesson, again).
    #
    # The WITHDRAWAL is deliberately absent: it REMOVES authority, and its recognizer's own doctrine
    # is that a false negative runs a review the human said to stop. The one-line rule bounds what
    # MINTS; refusing a multi-line withdrawal would fail open.
    #
    # T018 (FR-029, DA-3): decided on the approval form - a quoted menu is refused as one, on every host, and on a host
    # that marks pastes the one-line rule applies to the human's own text, outside every paste.
    [OutputType([pscustomobject])]
    param([Parameter()][AllowNull()][AllowEmptyString()][string]$Text, [AllowNull()][string]$HostKind)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    $form = Resolve-SpecrewApprovalForm -Text $Text -HostKind $HostKind
    if ([string]$form.Reason -ceq 'quoted-menu') {
        $menuShape = $null
        foreach ($option in @($form.Options)) { if (Get-Command Get-SpecrewTypedAuthorityShape -ErrorAction SilentlyContinue) { $menuShape = Get-SpecrewTypedAuthorityShape -Text $option }; if ($null -ne $menuShape) { break } }
        return [pscustomobject]@{
            Kind      = if ($null -ne $menuShape) { [string]$menuShape.Kind } else { 'approval' }
            FirstLine = (Get-SpecrewAuthorityApprovalLine -Text $Text)
            LineCount = (Get-SpecrewAuthorityMessageLineCount -Text $Text)
            Retype    = if ($null -ne $menuShape) { [string]$menuShape.Retype } else { [string]@($form.Options)[0] }
            Reason    = 'quoted-menu'
            Options   = @($form.Options)
            HostKind  = [string]$HostKind
        }
    }
    $Text = [string]$form.Text
    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    $table = @(
        @{ Kind = 'review-round-approval'; Fn = 'Test-SpecrewReviewRoundApprovalPhrase'; Retype = 'approved for review round' }
        @{ Kind = 'pause-decision'; Fn = 'Test-SpecrewPauseDecisionPhrase'; Retype = 'stop the review here (or: abandon this review campaign)' }
        @{ Kind = 'allowance-reset'; Fn = 'Test-SpecrewAllowanceResetPhrase'; Retype = 'approved for allowance reset' }
        @{ Kind = 'coverage-deferral'; Fn = 'Test-SpecrewCoverageDeferralPhrase'; Retype = 'continue without coverage until the review phase' }
    )
    foreach ($row in $table) {
        if (-not (Get-Command ([string]$row.Fn) -ErrorAction SilentlyContinue)) { continue }
        $r = $null
        try { $r = & ([string]$row.Fn) -Text $Text } catch { $r = $null }
        if ($null -eq $r -or [bool]$r.Matched) { continue }
        if (-not $r.PSObject.Properties['Reason'] -or [string]$r.Reason -cne 'multi-line-refused') { continue }
        return [pscustomobject]@{
            Kind      = [string]$row.Kind
            FirstLine = (Get-SpecrewAuthorityApprovalLine -Text $Text)
            LineCount = (Get-SpecrewAuthorityMessageLineCount -Text $Text)
            Retype    = [string]$row.Retype
            Reason    = 'multi-line'
            Options   = @()
            HostKind  = [string]$HostKind
        }
    }
    # T018 (FR-029): on a host that marks no pastes the phrase must stand alone, wherever it sits in the message. A phrase
    # on a later line - typed below a paste the host cannot mark, as in B4F-125 - is refused with that reason, not
    # passed over in silence because the first line was something else. Co-review round 6: the same on a host that marks
    # pastes when the typed text beside the phrase qualifies it, so a condition typed above the phrase is refused by name too.
    if (((-not (Test-SpecrewHostMarksPastes -HostKind $HostKind)) -or [string]$form.Reason -ceq 'qualified') -and (Get-SpecrewAuthorityMessageLineCount -Text $Text) -gt 1 -and
        (Get-Command Get-SpecrewTypedAuthorityShape -ErrorAction SilentlyContinue)) {
        foreach ($line in @([regex]::Split($Text, '\r\n|\n|\r') | ForEach-Object { (($_ -replace '\s+', ' ').Trim()) } | Where-Object { $_ })) {
            $lineShape = Get-SpecrewTypedAuthorityShape -Text $line
            if ($null -eq $lineShape -or [string]$lineShape.Kind -ceq 'approval-withdrawal') { continue }
            return [pscustomobject]@{
                Kind      = [string]$lineShape.Kind
                FirstLine = $line
                LineCount = (Get-SpecrewAuthorityMessageLineCount -Text $Text)
                Retype    = [string]$lineShape.Retype
                Reason    = 'multi-line'
                Options   = @()
                HostKind  = [string]$HostKind
            }
        }
    }
    return $null
}

function Get-SpecrewAuthorityMultiLineDisclosure {
    # The sentence the human reads. It names what was refused, why, and the ONE move that clears it,
    # in the words the docs use - the refusal standard (B4F-009 family, B4F-064), not a code word.
    [OutputType([string])]
    param([Parameter(Mandatory)][pscustomobject]$Refusal)
    $reason = if ($Refusal.PSObject.Properties['Reason']) { [string]$Refusal.Reason } else { 'multi-line' }
    if ($reason -ceq 'quoted-menu') {
        $quoted = (@($Refusal.Options) | Select-Object -First 3 | ForEach-Object { "'" + $(if ($_.Length -gt 60) { $_.Substring(0, 57) + '...' } else { $_ }) + "'" }) -join ', '
        return ("Specrew: your reply was received but NOT recorded as a {0}. It carries more than one verdict option ({1}), so it reads as a quoted menu, not a choice. Nothing you wrote is lost and no authority was changed. To record your choice, send it on its own line: '{2}'." -f $Refusal.Kind, $quoted, $Refusal.Retype)
    }
    $shown = [string]$Refusal.FirstLine
    if ($shown.Length -gt 80) { $shown = $shown.Substring(0, 77) + '...' }
    $refusalHost = if ($Refusal.PSObject.Properties['HostKind']) { [string]$Refusal.HostKind } else { '' }
    if (-not [string]::IsNullOrWhiteSpace($refusalHost) -and -not (Test-SpecrewHostMarksPastes -HostKind $refusalHost)) {
        return ("Specrew: your reply was received but NOT recorded as a {0}. Its first line is '{1}', but the message continues for {2} more line(s), and on this host Specrew cannot tell a paste from typing, so a verdict is ONE line - the phrase alone, or the phrase with a same-line instruction after a dash. Nothing you wrote is lost and no authority was changed. To record it, send a message that is exactly one line: '{3}' or '{3} - <your instructions>'." -f $Refusal.Kind, $shown, ([int]$Refusal.LineCount - 1), $Refusal.Retype)
    }
    return ("Specrew: your reply was received but NOT recorded as a {0}. Its first line is '{1}', but the message continues for {2} more line(s), and a verdict is ONE line - the phrase alone, or the phrase with a same-line instruction after a dash. A pasted transcript or a block of notes under the phrase is not a verdict. Nothing you wrote is lost and no authority was changed. To record it, send a message that is exactly one line: '{3}' or '{3} - <your instructions>'." -f $Refusal.Kind, $shown, ([int]$Refusal.LineCount - 1), $Refusal.Retype)
}

function Write-SpecrewAuthorityMultiLineDrop {
    # The disclosure half of the one-line rule: a refusal nobody can see is B4F-043's silence again.
    # Same journal and event the partial-signoff override uses for "the phrase matched and was then
    # rejected" (DRIFT-199-I002-034), because that is exactly what this is; plus the stderr line for
    # hosts that surface it. Returns the disclosure sentence so the prompt-entry provider can put it
    # in the turn, where the human actually reads. Fail-open: never breaks the end of a turn.
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][pscustomobject]$Refusal,
        [AllowNull()][string]$HostKind,
        [AllowNull()][string]$SourceEvent,
        # Feature 203 T012 (FR-041): the typed turn whose message was refused.
        [AllowNull()][AllowEmptyString()][string]$TurnIdentity = '',
        [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o'))
    )
    $message = Get-SpecrewAuthorityMultiLineDisclosure -Refusal $Refusal
    try {
        $dropJournal = Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/runtime/authority-capture-drops.jsonl'
        $dropDir = Split-Path -Parent $dropJournal
        if ($dropDir -and -not (Test-Path -LiteralPath $dropDir)) { New-Item -ItemType Directory -Path $dropDir -Force | Out-Null }
        $shown = [string]$Refusal.FirstLine
        if ($shown.Length -gt 80) { $shown = $shown.Substring(0, 77) + '...' }
        (([pscustomobject][ordered]@{
                event = 'authority-phrase-matched-but-rejected'; phrase = [string]$Refusal.Kind
                reason = $(if ($Refusal.PSObject.Properties['Reason'] -and -not [string]::IsNullOrWhiteSpace([string]$Refusal.Reason)) { [string]$Refusal.Reason } else { 'multi-line' })
                first_line = $shown; line_count = [int]$Refusal.LineCount
                host_kind = [string]$HostKind; source_event = [string]$SourceEvent; recorded_at = $NowUtc
                turn_identity = [string]$TurnIdentity; turn_identity_source = $(if ([string]::IsNullOrWhiteSpace($TurnIdentity)) { '' } else { 'refused-message' })
                fix = ("send exactly one line: '{0}' or '{0} - <your instructions>'" -f [string]$Refusal.Retype)
            }) | ConvertTo-Json -Compress) | Add-Content -LiteralPath $dropJournal -Encoding UTF8
        [Console]::Error.WriteLine(("[specrew-authority] YOUR {0} WAS NOT RECORDED. {1}" -f ([string]$Refusal.Kind).ToUpperInvariant().Replace('-', ' '), $message))
    }
    catch { $null = $_ }
    return $message
}

function Get-SpecrewReviewRoundApprovalRoot {
    # Feature 203 T008: the per-round approval is gone; the folder keeps the question-UI observation (W54) beside it.
    param([Parameter(Mandatory)][string]$ProjectRoot)
    return Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/review/round-approval'
}

function Get-SpecrewQuestionUiObservationPath {
    # W54: lives BESIDE the round-approval store because it is that family's diagnostic - never
    # authority. The directory is already review runtime evidence (untracked by ruling).
    param([Parameter(Mandatory)][string]$ProjectRoot)
    return Join-Path (Get-SpecrewReviewRoundApprovalRoot -ProjectRoot $ProjectRoot) 'question-ui-observation.json'
}

function Write-SpecrewQuestionUiPhraseObservation {
    # W54 (maintainer ruling, 2026-08-24): an authority phrase that arrived through a question-UI
    # tool is visible in the transcript only as a tool result, and capture rightly refuses it by
    # typed-turns doctrine - but silently, so the agent re-asks through the same tool and the human
    # answers the same question again (measured: three asks for one decision on the KeyContextAI
    # walk). This records the OBSERVATION so the refusal downstream can name the actual cause and
    # remedy. It is a diagnostic fact: nothing reads it as approval, and a genuine typed capture
    # clears it.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][ValidateSet('review-round-approval', 'allowance-reset', 'coverage-deferral')][string]$PhraseKind,
        [AllowNull()][string]$HostKind,
        [AllowNull()][string]$SourceEvent,
        [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o'))
    )
    $path = Get-SpecrewQuestionUiObservationPath -ProjectRoot $ProjectRoot
    $dir = Split-Path -Parent $path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $fact = [pscustomobject][ordered]@{
        schema_version = '1.0'; fact_type = 'question-ui-phrase-observation'
        phrase_kind = $PhraseKind; host_kind = [string]$HostKind; source_event = [string]$SourceEvent
        observed_at = $NowUtc
    }
    $json = $fact | ConvertTo-Json -Depth 4
    try {
        if (Get-Command Write-SpecrewFileAtomic -ErrorAction SilentlyContinue) { Write-SpecrewFileAtomic -Path $path -Content $json }
        else { [IO.File]::WriteAllText($path, $json, [Text.UTF8Encoding]::new($false)) }
    }
    catch { return $null }
    return $fact
}

function Get-SpecrewQuestionUiPhraseObservation {
    # The standing observation, or $null. Shape-validated the way every store reader here is; an
    # unreadable file is treated as absent, and absent just means the refusal names no picker cause.
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ProjectRoot)
    $path = Get-SpecrewQuestionUiObservationPath -ProjectRoot $ProjectRoot
    if (-not [IO.File]::Exists($path)) { return $null }
    $fact = $null
    try { $fact = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 4 -ErrorAction Stop } catch { return $null }
    foreach ($name in @('fact_type', 'phrase_kind', 'observed_at')) {
        $property = $fact.PSObject.Properties[$name]
        if (-not $property -or [string]::IsNullOrWhiteSpace([string]$property.Value)) { return $null }
    }
    if ([string]$fact.fact_type -cne 'question-ui-phrase-observation') { return $null }
    return $fact
}

function Clear-SpecrewQuestionUiPhraseObservation {
    # Called by the authority writers on a successful mint: once the human typed the phrase in the
    # chat, the picker diagnosis is history, not standing state.
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ProjectRoot)
    $path = Get-SpecrewQuestionUiObservationPath -ProjectRoot $ProjectRoot
    try { if ([IO.File]::Exists($path)) { [IO.File]::Delete($path) } } catch { $null = $_ }
}

function Get-SpecrewAgentSessionSignalNames {
    # The env signals that mean "this process is running inside an agent session". MIRRORS the per-host
    # sets in HandoverStore's Get-SpecrewRuntimeHostFromEnv - a parity test pins the two together, so a
    # host added there without being added here fails a guard instead of silently bypassing this check.
    # Credential-only vars are excluded for the same reason they are excluded there.
    return @(
        'CODEX_SESSION_ID', 'OPENAI_CODEX_CLI',
        'CLAUDECODE', 'CLAUDE_CODE_SESSION_ID', 'CLAUDE_PROJECT_DIR',
        'COPILOT_AGENT_SESSION_ID', 'COPILOT_CLI', 'COPILOT_CLI_BINARY_VERSION',
        'CURSOR_AGENT', 'CURSOR_TRACE_ID',
        'ANTIGRAVITY_SESSION_ID'
    )
}

function Test-SpecrewInsideAgentSession {
    # $true when any live host session variable is present. This is a GOVERNANCE discriminator, not a
    # security boundary: it tells an honestly-behaving invocation which authority rules apply. The
    # !-prefix case - the human running the command inside a session - shares this environment; it is
    # handled by the capture recognizing the human's own typed invocation as the approving act.
    [OutputType([bool])]
    param()
    foreach ($name in (Get-SpecrewAgentSessionSignalNames)) {
        if (-not [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name))) { return $true }
    }
    return $false
}

function Test-SpecrewReviewRoundApprovalPhrase {
    # Conservative, in the verdict-token tradition: only a CLEAR approving act matches, and anything
    # ambiguous falls through to "not an approval" so the caller asks rather than invents.
    #
    # Two shapes qualify:
    #   1. The typed phrase: "approved for review round" (leading-anchored; "a"/"one"/"another"/"a
    #      fresh" allowed; instructions may FOLLOW a delimiter). Interrogatives and deferrals are not
    #      approvals.
    #   2. The human's own invocation: a message that IS the approve-round command ("! specrew review
    #      --live --approve-round"). A human typing the command with the flag is performing the act the
    #      flag names - this is what keeps the !-prefix path working from inside a session. It must be
    #      essentially the whole message: a QUESTION about the command, or prose around it, is not it.
    [OutputType([pscustomobject])]
    param([AllowNull()][AllowEmptyString()][string]$Text)

    $r = [pscustomobject]@{ Matched = $false; Kind = $null; Phrase = $null; Reason = $null }
    if ([string]::IsNullOrWhiteSpace($Text)) { return $r }
    $trimmed = $Text.Trim()
    # Machinery envelopes are not human turns, whatever they contain.
    if ($trimmed -match '(?is)^\s*<(?:hook_prompt\b|task-notification\b|turn_aborted\b|system-reminder\b|environment_context\b|command-name\b|local-command\b|bash-stdout\b)') { return $r }

    # W56 decided on the approval's OWN LINE so that "approved for review round?" is still deliberation
    # while a question in a FOLLOWING block is a follow-up. PRED-BETA4-022 narrows what a following block
    # may be: nothing. A verdict is one line; a message that continues is refused, by reason, below.
    $lower = (Get-SpecrewAuthorityApprovalLine -Text $trimmed).ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($lower)) { return $r }
    if ($lower.EndsWith('?')) { return $r }

    # Shape 1: the typed phrase, leading-anchored so mentions and teaching ("reply with approved for
    # review round") never match.
    $anchor = [regex]::Match($lower, '^\s*(?:(?:yes|confirmed)\s*[,;:\-]\s*)?(?:(?:i|we)\s+)?approv(?:e|ed)\s+(?:for\s+)?(?:a\s+|one\s+|another\s+|a\s+fresh\s+)?review\s+round\b')
    if ($anchor.Success) {
        if (Test-SpecrewAuthorityMessageContinues -Text $trimmed) { $r.Reason = 'multi-line-refused'; return $r }
        $tail = $lower.Substring($anchor.Length)
        # Closed tail: nothing, or a delimiter followed by instructions. Arbitrary prose directly after
        # the phrase ("...review round seems premature") is not the phrase.
        if ([string]::IsNullOrWhiteSpace($tail) -or $tail -match '^\s*[-,.;:]') {
            # A deferral or negation anywhere in the TAIL still defers. Round-14 finding
            # (DRIFT-199-I001-123): the first cut split the tail on the delimiter and inspected
            # element ZERO - empty by construction for a delimited tail - so "approved for review
            # round, once the tests pass" minted immediately and could spend a round before the
            # stated condition held. This is SPEND authority: the conservative floor scans the whole
            # tail, and a false negative costs the human one plain retype, never a spent round.
            $negated = ($lower -match '^\s*(?:do\s*not|do\s+not|never|not\s+yet|hold\s+off|wait|stop)\b') -or
                ($tail -match '\b(?:do\s*not|don''t|dont|never|not\s+yet|no\s+longer|cancel|withdraw|revoke|rescind|retract|hold\s+off|stand\s+down|stop|abort|scratch\s+that|never\s+mind|nevermind|actually\s+(?:stop|no|not)|disregard|ignore\s+that)\b')
            if (-not (Test-SpecrewConditionalDeferralClause -Text $tail) -and -not $negated) {
                $r.Matched = $true; $r.Kind = 'typed-phrase'; $r.Phrase = $trimmed
                return $r
            }
        }
        return $r
    }

    # Shape 2: the human's own invocation. Single-line, the whole message, carrying the flag.
    if ($trimmed -notmatch '[\r\n]' -and
        $lower -match '^!?\s*(?:pwsh\s+[^|;&]*)?specrew(?:\.ps1)?\s+review\b[^|;&]*--approve-round\b[^|;&]*$') {
        $r.Matched = $true; $r.Kind = 'self-invocation'; $r.Phrase = $trimmed
        return $r
    }
    return $r
}

function Test-SpecrewTypedActReplacesRecord {
    # B4F-137 (202 iteration 002): AN APPROVAL THE HUMAN TYPES IS NEVER FOLDED INTO AN OLDER TURN-END RECORD.
    #
    # The writers below return an unspent record with the same text as "the same act", so a duplicate never mints twice.
    # But a record the turn-end path recovered from the transcript is not this typed message: with message identity
    # (T017) the turn-end path never re-offers a message the message hook recorded, so a typed approval reaching a writer
    # that already holds a turn-end record is a NEWER act. Returning the old record kept its provenance - an approval
    # left from an earlier double record, observed 43 hours old, then authorized the step the human had just typed. The
    # typed act replaces it, so the stored approval carries the evidence of the act that authorizes it.
    [OutputType([bool])]
    param([AllowNull()]$Existing, [AllowNull()]$Fact)
    if ($null -eq $Existing -or $null -eq $Fact) { return $false }
    # A record that has already become a grant keeps it: its minted_ref is how ownership is joined (W61), and an
    # undelivered attempt keeps the entitlement it carries.
    if ($Existing.PSObject.Properties['minted_ref'] -and -not [string]::IsNullOrWhiteSpace([string]$Existing.minted_ref)) { return $false }
    $existingSource = if ($Existing.PSObject.Properties['evidence_source']) { [string]$Existing.evidence_source } else { '' }
    return ([string]$Fact.evidence_source -ceq 'hook-captured-user-prompt' -and $existingSource -cne 'hook-captured-user-prompt')
}

function Resolve-SpecrewTypedActSupersession {
    # 203 T004 (FR-021; tasks.md: "the same rule covers the top-up, the coverage deferral and the partial sign-off"): A
    # NEWER TYPED ACT SUPERSEDES; IT NEVER FOLDS. The round approval's rule, for a writer that holds one record of its
    # kind. Given the held record and the new act's turn identity:
    #   legacy     - nothing to compare (no record, no identity, or the record is spent): the writer's own rule applies;
    #   same-act   - the same message re-offered: return the held record;
    #   keep-newer - an older message reaching the writer late (a recovery path): return the held record;
    #   superseded - a different, later message: the fact naming what it retires is journalled; write the new record;
    #   refused    - the fact could not be journalled, so the held record must not vanish unexplained: write nothing.
    [OutputType([string])]
    param(
        [AllowNull()]$Existing,
        [AllowNull()][AllowEmptyString()][string]$TurnIdentity,
        [Parameter(Mandatory)][string]$NowUtc,
        [Parameter(Mandatory)][string]$JournalPath,
        [Parameter(Mandatory)][string]$FactType
    )
    if ($null -eq $Existing -or [string]::IsNullOrWhiteSpace($TurnIdentity)) { return 'legacy' }
    $existingTurn = if ($Existing.PSObject.Properties['turn_identity']) { [string]$Existing.turn_identity } else { '' }
    $existingAt = if ($Existing.PSObject.Properties['observed_at']) { ConvertTo-SpecrewAuthorityInstant -Value $Existing.observed_at } else { $null }
    $newAt = ConvertTo-SpecrewAuthorityInstant -Value $NowUtc
    $olderThanHeld = ($existingTurn -cne $TurnIdentity -and $null -ne $existingAt -and $null -ne $newAt -and $newAt -lt $existingAt)
    # Co-review round 9 (finding 2): THE ORDER HOLDS WHATEVER THE HELD RECORD'S STATE. Checked only for an unspent record,
    # an older message recovered after the newer one was spent replaced it as a fresh, unspent approval.
    if ($Existing.PSObject.Properties['spent_at'] -and -not [string]::IsNullOrWhiteSpace([string]$Existing.spent_at)) {
        if ($olderThanHeld) { return 'keep-newer' }
        return 'legacy'
    }
    if ($existingTurn -ceq $TurnIdentity) { return 'same-act' }
    if ($olderThanHeld) { return 'keep-newer' }
    $fact = [pscustomobject][ordered]@{
        schema_version = '1.0'; fact_type = ($FactType + '-superseded'); authority_kind = 'human'
        # The instant, rendered round-trip: a [string] cast of a parsed date drops its offset (W60).
        superseded_observed_at = if ($null -ne $existingAt) { ([DateTimeOffset]$existingAt).ToUniversalTime().ToString('o') } else { '' }
        superseded_turn_identity = $existingTurn
        superseded_by_observed_at = $NowUtc
        superseded_by_turn_identity = [string]$TurnIdentity
        observed_at = $NowUtc
    }
    try {
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($JournalPath)) | Out-Null
        Add-Content -LiteralPath $JournalPath -Value ($fact | ConvertTo-Json -Compress -Depth 8) -Encoding UTF8 -ErrorAction Stop
    }
    catch { return 'refused' }
    return 'superseded'
}

function Get-SpecrewAuthorityFlagPhraseMap {
    # W76 (maintainer finding, 2026-08-27): ONE TABLE PAIRING EACH AUTHORITY FLAG WITH THE PHRASE THAT
    # ACTUALLY AUTHORIZES IT - read by the advisories that print them AND by the audit that checks them.
    #
    # This exists because the audit could not see a surface it was written to police. W44 swept
    # `--approve-round`; W49 extended the sweep to `--pause-choice`; the exhaustion advisory naming
    # `--remediate allowance-reset` was written afterwards and nobody added it to the sweep's hand-kept
    # list. **So the standing check PASSED while the surface violated the rule that check enforces**,
    # and it reached a human: a downstream agent read the advisory and relayed the flag, correctly,
    # because that is what Specrew told it to say.
    #
    # A LIST THE AUDITOR KEEPS CAN ONLY CATCH WHAT ITS AUTHOR REMEMBERED. The audit now derives its
    # flags from the surfaces themselves and resolves each against this table; a flag with no entry is
    # a decision someone must make, not a gap that passes quietly. Adding a flag here is the one step
    # that makes both the advisory and its audit correct at once - the enumerated-versus-derived lesson
    # from the self-leak firewall, arriving in the surface sweep.
    #
    # A flag is IN THIS TABLE when running it carries a human's typed authority. Flags that carry no
    # authority - `--live`, `--run-id`, `--ack-reason`, `--host` - are listed as exempt below, with the
    # reason, so "not authority-bearing" is also a recorded decision rather than an omission.
    [OutputType([hashtable])]
    param()
    return @{
        '--pause-choice'              = 'stop the review here'
        '--remediate allowance-reset' = 'approved for allowance reset'
    }
}

function Get-SpecrewNonAuthorityFlagExemptions {
    # Flags that appear in reader-facing text and carry NO human authority, each with the reason it is
    # exempt. Kept beside the authority table so the audit can tell "not authority" from "forgotten",
    # which is the distinction the sweep could not previously make.
    [OutputType([hashtable])]
    param()
    return @{
        '--live'            = 'selects the live engine; authorizes nothing'
        '--run-id'          = 'names an existing run; authorizes nothing'
        '--ack-reason'      = 'carries the human''s stated reason, and is refused without the typed phrase that authorizes the act'
        '--host'            = 'selects the reviewer harness; authorizes nothing'
        '--project-path'    = 'locates the project; authorizes nothing'
        '--json'            = 'output shape; authorizes nothing'
        '--remediate'       = 'the bare flag names a remediation FAMILY; each authority-bearing member is listed in the authority table by its full form'
        '--feature'         = 'selects which feature to act on; authorizes nothing'
        '--iteration'       = 'selects which iteration to act on; authorizes nothing'
        '--quiet'           = 'suppresses output; authorizes nothing'
        '--open'            = 'opens a rendered artifact for reading; authorizes nothing'
        '--baseline-ref'    = 'names a comparison point; authorizes nothing'
        '--checkpoint-id'   = 'names an existing checkpoint; authorizes nothing'
        '--reconcile-run'   = 'repairs bookkeeping for a run that already happened; grants no new round'
        '--reconcile'       = 'repairs bookkeeping; grants nothing'
        '--timeout-seconds' = 'bounds how long a reviewer may run; authorizes nothing'
        '--scope'           = 'narrows what is examined; authorizes nothing'
        '--list-hosts'      = 'prints the reviewer catalogue; authorizes nothing'
        '--ack-degraded'    = 'acknowledges a degraded runtime so the reason is recorded; it does not authorize a review, and the typed phrase is still required to run one'
        '--flag'            = 'appears only as prose about flags in general, never as a command to run'
        '--dispute'         = 'the crew raises a review stop for the human to decide; it decides and authorizes nothing itself'
        '--reason'          = 'carries the crew''s reason for a dispute, shown to the human at the stop; authorizes nothing'
        '--propose-defer'   = 'the crew raises a review stop proposing a deferral; only the human''s typed defer line moves the finding'
        '--to'              = 'names where a proposed deferral would go; authorizes nothing'
        '--ask'             = 'the crew raises a review stop asking the human a question; authorizes nothing'
        '--authorization-ref' = 'LABELS where an approval came from; it records provenance and explicitly does not stand in for one. Its own advisory says so, and the gate says command-line identity fields are not authority.'
    }
}

function Get-SpecrewTypedTurnIdentity {
    # W69 (maintainer ruling, 2026-08-26): THE TURN IS THE ACT; THE PHRASE IS ONLY ITS CONTENT.
    #
    # typed-turns-v1 is not changed by this, it is COMPLETED. Its stated rule is that only a real human
    # turn mints authority; the unstated half - never needed until the Stop backstop began re-offering
    # turns - is that each turn mints AT MOST ONCE, EVER. Content was always a proxy for identity, and
    # the backstop is exactly where the proxy fails: the same turn arrives again at the end of every
    # assistant turn, identical in every byte, and nothing about the phrase can tell that apart from a
    # human typing it a second time.
    #
    # Identity is POSITION + CONTENT + ARRIVAL, hashed to one stable id per host. Position and arrival
    # come from the turn as the host delivered it; a genuine retype lands at a different position with
    # a different arrival and is therefore a different act, which is the property that keeps the rule
    # from wedging anyone.
    #
    # Feature 202 iteration 002, T017 (FR-027, DA-2; B4F-127): ONE MESSAGE, ONE KEY. When the host gives the
    # message its own ID - Claude's `prompt_id`, which its transcript entry carries as `promptId`, and Codex's
    # `turn_id` - that ID IS the identity, and the path that saw the message is not part of it. W71 accepted "at
    # most two mints per utterance" because the hosts shared no per-turn id; Claude and Codex do, so the message
    # hook and every later turn end now compute the same key, and the exhausted-turn check below admits only the
    # first. Position and arrival stay as the identity for a host that sends no message ID.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Response,
        [AllowEmptyString()][AllowNull()][string]$HostKind,
        [AllowEmptyString()][AllowNull()][string]$SourceEvent,
        [AllowEmptyString()][AllowNull()][string]$TurnPosition,
        [AllowEmptyString()][AllowNull()][string]$TurnArrival,
        [AllowEmptyString()][AllowNull()][string]$MessageId
    )
    if ([string]::IsNullOrWhiteSpace($Response)) { return '' }
    if (-not [string]::IsNullOrWhiteSpace($MessageId)) {
        return (Get-SpecrewHumanAuthorityHash -Text (@('message-id', [string]$HostKind, ([string]$MessageId).Trim()) -join '|'))
    }
    $parts = @(
        [string]$HostKind
        [string]$SourceEvent
        [string]$TurnPosition
        [string]$TurnArrival
        (Get-SpecrewHumanAuthorityHash -Text ([string]$Response))
    ) -join '|'
    return (Get-SpecrewHumanAuthorityHash -Text $parts)
}

function Get-SpecrewExhaustedTurnLedgerPath {
    param([Parameter(Mandatory)][string]$ProjectRoot)
    return (Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/authority/exhausted-turns.jsonl')
}

function Test-SpecrewTypedTurnExhausted {
    # Has this turn already minted? Append-only ledger, read as a set.
    #
    # FAILS CLOSED on an unreadable ledger, and that direction is deliberate: the cost of a false
    # "exhausted" is that the human types the phrase again, while the cost of a false "fresh" is a
    # forged authority. This is the same call made for the withdrawal journal in W68, for the same
    # reason.
    #
    # W70 / round-27 finding: A TORN LINE IS NOT A LINE TO SKIP. The reader used to `continue` past
    # anything it could not parse, so an interrupted append - the exact failure the two-phase write
    # below exists to survive - produced the false-fresh answer this ledger exists to prevent. A record
    # it cannot read is a turn it cannot rule out.
    #
    # W71 (maintainer ruling, 2026-08-26): SAME CHANNEL ONLY. THE SECOND CHANNEL IS OBSERVED, NOT
    # BLOCKED.
    #
    # W70 tried to make one utterance exhaust BOTH channels by matching content + host. Round 28
    # returned two findings against it that contradict each other - one that it suppressed a genuinely
    # later retype forever (a WEDGE, with no recovery, exactly when the backstop is needed), one that
    # it still let a double mint through when the ledger write failed. The ruling names what that
    # contradiction actually is: **not two defects, but the guess failing to be an identity, stated
    # twice.** These hosts share no per-turn id; prompt-entry has an event clock, Stop has a transcript
    # index. Everything built on top of that was a heuristic wearing an identity's clothes.
    #
    # THE RESIDUAL, WITH ITS SIZE STATED, because the size is what makes it acceptable: same-channel
    # exhaustion means each channel mints AT MOST ONCE per utterance, so a dual-event host yields AT
    # MOST TWO mints from one typed act. Bounded. The pre-W69 hole was unlimited. And it is a
    # SPEND-ACCOUNTING cost rather than a forgery - the human did approve a round; the machinery may
    # grant a second one.
    #
    # The double mint is RECORDED as an observation by the router, so beta4 gets field data on how
    # often two channels carry one utterance rather than speculation. Visibility was the right answer
    # to the exhaustion gap and to the picker gap; it is the right answer here.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][AllowEmptyString()][string]$TurnId,
        [AllowEmptyString()][AllowNull()][string]$ContentHash,
        [AllowEmptyString()][AllowNull()][string]$HostKind,
        [AllowEmptyString()][AllowNull()][string]$SourceEvent
    )
    if ([string]::IsNullOrWhiteSpace($TurnId)) { return $false }
    $path = Get-SpecrewExhaustedTurnLedgerPath -ProjectRoot $ProjectRoot
    if (-not [IO.File]::Exists($path)) { return $false }
    try {
        foreach ($line in [IO.File]::ReadAllLines($path)) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $entry = $null
            try { $entry = $line | ConvertFrom-Json -Depth 6 -ErrorAction Stop } catch { $entry = $null }
            # W75 / round-31 finding: A TORN LINE IS SKIPPED, AND RECORDED. NOT "every turn is exhausted".
            #
            # THE DISTINCTION I MISSED IN W70 AND REPEATED IN W72, and it is the sharpest form of the
            # wedge-versus-spend trade in this project:
            #
            #   Failing closed on "should this ACT be authorized" is SAFETY.
            #   Failing closed on "can this PROJECT ever be authorized again" is an OUTAGE.
            #
            # Returning $true here answered the second question. One interrupted append and the project
            # accepted no further approval, pause, reset or withdrawal - permanently, with retyping
            # powerless and the refusal contract forbidding a hand-edit of the store. The trigger is a
            # Ctrl+C at the wrong moment.
            #
            # An unreadable line's turn_id is unknowable, so it can neither confirm nor deny exhaustion
            # of the turn being asked about. The bounded cost of skipping it is one possible re-mint of
            # whatever it recorded; the cost of the alternative is an ungovernable project.
            if ($null -eq $entry -or -not $entry.PSObject.Properties['turn_id']) {
                if (Get-Command Write-SpecrewAuthorityLedgerDamageObservation -ErrorAction SilentlyContinue) {
                    Write-SpecrewAuthorityLedgerDamageObservation -ProjectRoot $ProjectRoot -Journal 'exhausted-turns.jsonl' | Out-Null
                }
                continue
            }
            if ([string]$entry.turn_id -ceq [string]$TurnId) { return $true }
        }
    }
    catch { return $true }
    return $false
}

function Get-SpecrewCrossChannelMint {
    # Did ANOTHER channel already mint this content on this host? Returns the earlier ledger entry, or
    # $null. This ANSWERS A QUESTION; it does not gate anything - W71 removed the gate because the
    # match is not an identity. It exists so the router can record what it saw.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][AllowEmptyString()][string]$ContentHash,
        [AllowEmptyString()][AllowNull()][string]$HostKind,
        [AllowEmptyString()][AllowNull()][string]$SourceEvent
    )
    if ([string]::IsNullOrWhiteSpace($ContentHash)) { return $null }
    $path = Get-SpecrewExhaustedTurnLedgerPath -ProjectRoot $ProjectRoot
    if (-not [IO.File]::Exists($path)) { return $null }
    $thisChannel = if ((([string]$SourceEvent).Trim().ToLowerInvariant()) -in @('stop', 'stop-transcript')) { 'stop' } else { 'prompt-entry' }
    try {
        foreach ($line in [IO.File]::ReadAllLines($path)) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $entry = $null
            try { $entry = $line | ConvertFrom-Json -Depth 6 -ErrorAction Stop } catch { continue }
            if ($null -eq $entry -or -not $entry.PSObject.Properties['content_hash']) { continue }
            if ([string]$entry.fact_type -cne 'typed-turn-exhausted') { continue }
            if ([string]$entry.content_hash -cne [string]$ContentHash) { continue }
            if (-not $entry.PSObject.Properties['minted'] -or [string]::IsNullOrWhiteSpace([string]$entry.minted)) { continue }
            $entryHost = if ($entry.PSObject.Properties['host_kind']) { [string]$entry.host_kind } else { '' }
            if ($entryHost -cne [string]$HostKind) { continue }
            $entrySource = if ($entry.PSObject.Properties['source_event']) { [string]$entry.source_event } else { '' }
            $entryChannel = if (($entrySource.Trim().ToLowerInvariant()) -in @('stop', 'stop-transcript')) { 'stop' } else { 'prompt-entry' }
            if ($entryChannel -ceq $thisChannel) { continue }
            return $entry
        }
    }
    catch { return $null }
    return $null
}

function Write-SpecrewCrossChannelMintObservation {
    # A DIAGNOSTIC FACT, never authority - the same standing as the W54 picker observation. It records
    # that one typed utterance was minted by both channels, which is the bounded residual W71 accepts,
    # so its real-world rate can be measured instead of argued about.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][AllowEmptyString()][string]$TurnId,
        [Parameter(Mandatory)][AllowEmptyString()][string]$ContentHash,
        [AllowEmptyString()][AllowNull()][string]$HostKind,
        [AllowEmptyString()][AllowNull()][string]$SourceEvent,
        [AllowEmptyString()][AllowNull()][string]$PriorTurnId,
        [AllowEmptyString()][AllowNull()][string]$PriorSourceEvent,
        [AllowEmptyString()][AllowNull()][string]$MintedWriters,
        [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o'))
    )
    $path = Get-SpecrewExhaustedTurnLedgerPath -ProjectRoot $ProjectRoot
    try {
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path)) | Out-Null
        $entry = [pscustomobject][ordered]@{
            schema_version = '1.0'; fact_type = 'cross-channel-double-mint'; authority_kind = 'none'
            turn_id = [string]$TurnId; content_hash = [string]$ContentHash
            host_kind = [string]$HostKind; source_event = [string]$SourceEvent
            prior_turn_id = [string]$PriorTurnId; prior_source_event = [string]$PriorSourceEvent
            minted = [string]$MintedWriters; observed_at = $NowUtc
        }
        Add-Content -LiteralPath $path -Value ($entry | ConvertTo-Json -Compress -Depth 6) -Encoding UTF8 -ErrorAction Stop
        return $true
    }
    catch { return $false }
}

function Write-SpecrewAuthorityLedgerDamageObservation {
    # W75 / round-31 finding: a DIAGNOSTIC fact, never authority - the same standing as the W54 picker
    # observation and the W71 double-mint one. It records that a journal lost a record, so that
    # skipping the torn line does not trade an outage for an invisible hole.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Journal,
        [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o'))
    )
    $path = Get-SpecrewExhaustedTurnLedgerPath -ProjectRoot $ProjectRoot
    try {
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path)) | Out-Null
        # Once per journal, not once per read: this is consulted on every turn, and a damaged file
        # would otherwise append forever.
        if ([IO.File]::Exists($path)) {
            foreach ($existing in [IO.File]::ReadAllLines($path)) {
                if ([string]$existing -match 'authority-ledger-damaged' -and [string]$existing -match [regex]::Escape($Journal)) { return $true }
            }
        }
        $entry = [pscustomobject][ordered]@{
            schema_version = '1.0'; fact_type = 'authority-ledger-damaged'; authority_kind = 'none'
            journal = [string]$Journal; observed_at = $NowUtc
            detail = 'A record in this journal could not be read - almost always an append interrupted mid-write. It is skipped rather than treated as every future act, because refusing everything would leave a project that can never be authorized again.'
        }
        Add-Content -LiteralPath $path -Value ($entry | ConvertTo-Json -Compress -Depth 6) -Encoding UTF8 -ErrorAction Stop
        return $true
    }
    catch { return $false }
}

function Get-SpecrewTypedAuthorityShape {
    # Feature 202 iteration 002, T017 (FR-027): which typed authority, if any, this text IS - the minting
    # recognizers, matched as their writers would match them. Used only to REPORT a message a host's single
    # recording path did not record; it never mints.
    #
    # Co-review round 1 (iteration 002): EVERY act the router's writers mint is shaped here, and the retype is the act
    # the human typed - a missed `abandon this review campaign` is never answered with `stop the review here`, whose
    # consequence is different. A withdrawal is shaped too, because it is the one act whose loss fails OPEN.
    [OutputType([pscustomobject])]
    param([Parameter()][AllowNull()][AllowEmptyString()][string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    $trimmed = $Text.Trim()
    if (Get-Command Test-SpecrewApprovalWithdrawalPhrase -ErrorAction SilentlyContinue) {
        $w = $null
        try { $w = Test-SpecrewApprovalWithdrawalPhrase -Text $Text } catch { $w = $null }
        if ($null -ne $w -and [bool]$w.Matched) { return [pscustomobject]@{ Kind = 'approval-withdrawal'; Retype = 'withdraw the approval'; Choice = '' } }
    }
    $table = @(
        @{ Kind = 'review-round-approval'; Fn = 'Test-SpecrewReviewRoundApprovalPhrase'; Retype = 'approved for review round' }
        @{ Kind = 'pause-decision'; Fn = 'Test-SpecrewPauseDecisionPhrase'; Retype = '' }
        @{ Kind = 'allowance-reset'; Fn = 'Test-SpecrewAllowanceResetPhrase'; Retype = 'approved for allowance reset' }
        @{ Kind = 'coverage-deferral'; Fn = 'Test-SpecrewCoverageDeferralPhrase'; Retype = 'continue without coverage until the review phase' }
    )
    foreach ($row in $table) {
        if (-not (Get-Command ([string]$row.Fn) -ErrorAction SilentlyContinue)) { continue }
        $r = $null
        try { $r = & ([string]$row.Fn) -Text $Text } catch { $r = $null }
        if ($null -eq $r -or -not [bool]$r.Matched) { continue }
        $choice = if ($r.PSObject.Properties['Choice']) { [string]$r.Choice } else { '' }
        $retype = [string]$row.Retype
        if ([string]$row.Kind -ceq 'pause-decision') {
            $retype = if ($choice -ceq 'abandon') { 'abandon this review campaign' } else { 'stop the review here' }
        }
        return [pscustomobject]@{ Kind = [string]$row.Kind; Retype = $retype; Choice = $choice }
    }
    # The two writers with no separate recognizer, matched as their writers match them.
    # Feature 203 T013 (maintainer ruling 2026-11-12): the reason is the phrase's own line, so the shape is one line. A message
    # that goes on past it is no partial sign-off; the one-line rule refuses it by name (Get-SpecrewAuthorityMultiLineRefusal).
    if ($trimmed -match '(?i)^approved\s+for\s+partial\s+review\s+signoff\s*[-:]\s*\S[^\r\n]*$') {
        return [pscustomobject]@{ Kind = 'partial-review-signoff'; Retype = 'approved for partial review signoff - <your reason>'; Choice = '' }
    }
    if ($trimmed -ceq 'approved for workshop repair') {
        return [pscustomobject]@{ Kind = 'workshop-repair'; Retype = 'approved for workshop repair'; Choice = '' }
    }
    return $null
}

# Feature 203 T003 (FR-014 to FR-023; DA-1 option B, DA-2, DA-3): ONE CLASSIFIER, ONE ACT PER TYPED TURN.
#
# Today a typed turn is read by the prompt router, the turn end, the transcript backstop and the writer CLIs, each with
# its own reading rules, and the spread is the root of B4F-112, B4F-116/150, B4F-117 and B4F-137/140. Resolve-SpecrewTypedAct
# is the one reading: a turn record and the pending state in, exactly one act or none with a reason out. It is pure: it
# reads no store and writes none. T004 rewires the paths to it and removes their own rules; until then nothing calls it.
#
# The reasons a turn records nothing, and whether the human must be told (FR-026; data-model.md):
#   not-an-act           the text is no act and nothing waits for a reply                     not reported
#   not-human            host-injected text or a compaction summary (FR-015, FR-019; R4)       not reported
#   not-standalone       quoted, in backticks, inside a paste, or a quoted menu (FR-015)       not reported
#   not-standalone       the human's own text carries the phrase but goes on, or qualifies it  reported: retype one line
#   origin-unconfirmed   the dispatcher could not tell who wrote it                            reported
#   no-identity          the host gave the turn no identity (FR-015)                           reported
#   already-recorded     this identity has an act already (FR-015, FR-022)                     not reported
#   form-unreadable      the form or verdict reader failed or is missing                       reported
#   no-pending-crossing  an act with nothing waiting for it                                    reported
#   boundary-mismatch    a verdict naming another boundary than the waiting one (FR-020)       reported
#   stage-evidence-absent the waiting crossing's stage owes its artifacts                       reported
#   missing-destination  `defer finding <id>` without `to <destination>` (FR-011)              reported
#
# Kinds: the four FR-018 names, plus the acts today's router writes that FR-018 does not name, routed here so T004's
# rewiring loses none of them: partial-signoff, workshop-repair and coverage-deferral. T008 removed the per-round
# approval and its withdrawal (FR-010); their phrases are still recognised, so 'approved for review round' is never read
# as a verdict for the 'review' boundary (B4F-116/150, DRIFT-006), and record nothing:
#   retired-act          the per-round approval, or its withdrawal, which no longer exist           reported
#
# Deliberately NOT here (T003 notes): a re-typed approval dropped while an older one is unspent (02:44 and 14:45 local,
# 2026-11-02; DRIFT-019, DRIFT-023) is supersession, T004 (FR-021); the human-facing notice for it is T006.

function Get-SpecrewTypedActIdentity {
    # One key per typed message, from the turn record alone (FR-016, DA-2). The host's message id, or the binding's
    # declared stand-in (Copilot), together with the text. The text is part of the key because Claude reuses a
    # message id: a message queued while a turn runs reaches the prompt hook with that RUNNING turn's prompt_id
    # (measured on Claude Code 2.1.314, 2026-11-02, a scratch-folder probe). Keyed on the id alone, the queued
    # approval was the previous turn, already recorded, and it was dropped without a word (DRIFT-006, DRIFT-012).
    [OutputType([pscustomobject])]
    param([Parameter()][AllowNull()]$Turn)
    $none = [pscustomobject]@{ Identity = ''; Kind = 'none' }
    if ($null -eq $Turn) { return $none }
    $prop = { param($name) if ($Turn.PSObject.Properties[$name]) { [string]$Turn.$name } else { '' } }
    $messageId = (& $prop 'message_id').Trim()
    $text = (& $prop 'text').Trim()
    # Co-review round 9: the text in the one form both recording paths read (ConvertTo-SpecrewTypedActText); a message that
    # is nothing but a wrapper keeps its own text, so it still has a key.
    $cleaned = (ConvertTo-SpecrewTypedActText -Text $text).Trim()
    if (-not [string]::IsNullOrWhiteSpace($cleaned)) { $text = $cleaned }
    if ([string]::IsNullOrWhiteSpace($messageId) -or [string]::IsNullOrWhiteSpace($text)) { return $none }
    $hostKind = (& $prop 'host').Trim().ToLowerInvariant()
    # Feature 203 T004 (option 1): Cursor and Antigravity send no id; their substitute is the prompt event's position key.
    $kind = switch -CaseSensitive ((& $prop 'message_identity').Trim()) { 'stand-in' { 'stand-in' } 'position-key' { 'position-key' } default { 'host-message-id' } }
    # Co-review round 8 (T004): the id and the text are not one key per message either. Two messages with the same text
    # can reach the hook under one running prompt_id (the human retypes the approval while the turn ends), so a reader
    # that has told them apart by the host's own record of each one (Read-SpecrewCitedTypedTurn) hands the key it
    # resolved as act_identity, and the prompt hook keys a second such message by its own prompt event (occurrence).
    $resolved = (& $prop 'act_identity').Trim()
    if (-not [string]::IsNullOrWhiteSpace($resolved)) { return [pscustomobject]@{ Identity = $resolved; Kind = $kind } }
    $parts = @('typed-act', $hostKind, $messageId, (Get-SpecrewHumanAuthorityHash -Text $text))
    $occurrence = (& $prop 'occurrence').Trim()
    if (-not [string]::IsNullOrWhiteSpace($occurrence)) { $parts += $occurrence }
    $identity = Get-SpecrewHumanAuthorityHash -Text ($parts -join '|')
    return [pscustomobject]@{ Identity = $identity; Kind = $kind }
}

function Get-SpecrewStopAnswerShape {
    # The review-stop lines of FR-011 that no older recognizer reads. One line, the phrase alone. $null when none.
    [OutputType([pscustomobject])]
    param([AllowNull()][AllowEmptyString()][string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    $line = ($Text.Trim() -replace '\s+', ' ')
    if ($line -match '(?i)^defer\s+finding\s+(?<id>\S+)\s+to\s+(?<to>\S.*?)\s*\.?$') { return [pscustomobject]@{ Answer = 'defer'; Finding = $Matches['id']; Argument = $Matches['to'] } }
    if ($line -match '(?i)^defer\s+finding\s+(?<id>\S+)\s*\.?$') { return [pscustomobject]@{ Answer = 'defer'; Finding = $Matches['id']; Argument = '' } }
    if ($line -match '(?i)^drop\s+finding\s+(?<id>\S+)\s*\.?$') { return [pscustomobject]@{ Answer = 'drop'; Finding = $Matches['id']; Argument = '' } }
    if ($line -match '(?i)^fix\s+finding\s+(?<id>\S+)\s*\.?$') { return [pscustomobject]@{ Answer = 'fix'; Finding = $Matches['id']; Argument = '' } }
    if ($line -match '(?i)^allow\s+reviewer\s+(?<host>[a-z][a-z0-9-]*)\s*\.?$') { return [pscustomobject]@{ Answer = 'allow-reviewer'; Finding = ''; Argument = $Matches['host'].ToLowerInvariant() } }
    return $null
}

function Resolve-SpecrewTypedAct {
    # Turn: host, message_id, message_identity ('declared' | 'stand-in' | 'position-key' | 'none'), origin ('typed-user' | 'host-injected'
    # | 'unknown'), text, and is_compact_summary when a transcript reader built it. Pending: Crossing { From; To;
    # StageEvidenceAbsent }, Pause { Kind ('a-budget-spent' | 'b-dispute-or-defer' | 'c-judgment' |
    # 'd-host-outside-order'); Id }, WorkshopQuestion { Id }, each $null when nothing waits. RecordedIdentities: the
    # identities that already have an act. Returns { Kind; Reason; Report; TurnIdentity; IdentityKind; Target; Answer;
    # Argument; Shape }.
    [OutputType([pscustomobject])]
    param(
        [Parameter()][AllowNull()]$Turn,
        [Parameter()][AllowNull()]$Pending,
        [Parameter()][AllowNull()][string[]]$RecordedIdentities = @()
    )
    $act = [pscustomobject]@{ Kind = 'none'; Reason = 'not-an-act'; Report = $false; TurnIdentity = ''; IdentityKind = 'none'; Target = ''; Answer = ''; Argument = ''; Shape = '' }
    $none = { param([string]$Reason, [bool]$Report) $act.Kind = 'none'; $act.Reason = $Reason; $act.Report = $Report; return $act }
    if ($null -eq $Turn) { return (& $none 'not-an-act' $false) }
    $prop = { param($Object, $name) if ($null -ne $Object -and $Object.PSObject.Properties[$name]) { $Object.$name } else { $null } }
    $text = [string](& $prop $Turn 'text')
    $hostKind = ([string](& $prop $Turn 'host')).Trim().ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($text)) { return (& $none 'not-an-act' $false) }
    $crossing = & $prop $Pending 'Crossing'
    $pause = & $prop $Pending 'Pause'
    $question = & $prop $Pending 'WorkshopQuestion'

    # What act, if any, the human's own standalone text is. A reader that throws is a form that cannot be read.
    $form = $null; $shape = $null; $verdict = $null; $stop = $null
    try {
        $form = Resolve-SpecrewApprovalForm -Text $text -HostKind $hostKind
        $own = [string]$form.Text
        if ([string]::IsNullOrWhiteSpace([string]$form.Reason) -and -not [string]::IsNullOrWhiteSpace($own)) {
            $shape = Get-SpecrewTypedAuthorityShape -Text $own
            if ($null -eq $shape -and -not (Test-SpecrewAuthorityMessageContinues -Text $own)) { $stop = Get-SpecrewStopAnswerShape -Text $own }
            if ($null -eq $shape -and $null -eq $stop) {
                if (-not (Get-Command Test-SpecrewHumanVerdictToken -ErrorAction SilentlyContinue)) { throw 'the boundary verdict reader is not loaded' }
                # DA-3: the phrase starts the message. The verdict reader alone took 'I approved for tasks yesterday' as an
                # approval of the waiting crossing, as the prompt-entry verdict path still does until T004.
                $token = Test-SpecrewHumanVerdictToken -Text $own
                if ([bool]$token.IsApproval -and $own.TrimStart() -match '^(?i)approv(?:e|ed)\b') { $verdict = $token }
            }
        }
    }
    catch {
        $act.Shape = 'unreadable'
        return (& $none 'form-unreadable' $true)
    }
    $isAct = ($null -ne $shape -or $null -ne $stop -or $null -ne $verdict)
    $act.Shape = if ($null -ne $shape) { [string]$shape.Kind } elseif ($null -ne $stop) { 'stop-answer' } elseif ($null -ne $verdict) { 'boundary-verdict' } else { '' }

    # Who wrote it (FR-015, FR-019). Never reported: the human did not type it, so telling them it was "not recorded"
    # would be false (measure c). A compaction summary quotes the human's earlier approvals (R4, Claude 2.1.312).
    $compact = & $prop $Turn 'is_compact_summary'
    if ($compact -eq $true -or [string]$compact -match '(?i)^\s*true\s*$') { return (& $none 'not-human' $false) }
    $origin = ([string](& $prop $Turn 'origin')).Trim()
    # Feature 203 T013 (maintainer ruling 2026-11-12; B5F-064, B5F-066): THE TRANSCRIPT RECORD DECIDES WHO TYPED IT, where
    # there is one. Claude records a typed message as turnOrigin human with promptSource typed or queued; a peer message is
    # peer, a scheduled prompt scheduled, a task notification task_notification, and "!" command output human with no
    # promptSource. A scheduled prompt is raw text with no wrapper, so no text rule can see it. A turn whose record carries
    # these fields is the human's only when they say so; a record without them (an older host) leaves the text rules to
    # decide, as before.
    $recordSender = Get-SpecrewTranscriptRecordSender -TurnOrigin ([string](& $prop $Turn 'record_turn_origin')) -PromptSource ([string](& $prop $Turn 'record_prompt_source')) `
        -IsMeta (& $prop $Turn 'record_is_meta') -OriginKind ([string](& $prop $Turn 'record_origin_kind')) `
        -RecordKind ([string](& $prop $Turn 'record_kind')) -HumanTurn (& $prop $Turn 'record_human_turn') -CommandMode ([string](& $prop $Turn 'record_command_mode'))
    if ([bool]$recordSender.fields_present) {
        if ([bool]$recordSender.accepted) { $origin = 'typed-user' }
        else { return (& $none 'not-human' $false) }
    }
    # Feature 203 T013 (B5F-064): another Claude session's message, in the wrapper the host puts around it, is never the
    # human's turn, whatever origin the prompt hook could give it (the hook runs before the host writes the record).
    if ($text -match $script:SpecrewPeerMessagePattern) { return (& $none 'not-human' $false) }
    if ($origin -ceq 'host-injected') { return (& $none 'not-human' $false) }
    if ($origin -cne 'typed-user') { return (& $none $(if ($isAct) { 'origin-unconfirmed' } else { 'not-an-act' }) $isAct) }

    $identity = Get-SpecrewTypedActIdentity -Turn $Turn
    $act.TurnIdentity = [string]$identity.Identity; $act.IdentityKind = [string]$identity.Kind
    if ([string]::IsNullOrWhiteSpace($act.TurnIdentity)) { return (& $none $(if ($isAct) { 'no-identity' } else { 'not-an-act' }) $isAct) }
    if (@($RecordedIdentities) -contains $act.TurnIdentity) { return (& $none 'already-recorded' $false) }

    if (-not $isAct) {
        # The form named a reason, or reduced the message to nothing: the phrase is not the human's own standalone line.
        $refusal = $null
        try { $refusal = Get-SpecrewAuthorityMultiLineRefusal -Text $text -HostKind $hostKind } catch { $refusal = $null }
        if ($null -ne $refusal) { $act.Shape = [string]$refusal.Kind; return (& $none 'not-standalone' $true) }
        $unwrapped = @([regex]::Split((Remove-SpecrewPairedPastes -Text $text), '\r\n|\n|\r') + @([regex]::Split($text, '\r\n|\n|\r')) |
                ForEach-Object { ConvertTo-SpecrewVerdictOptionText -Line (($_ -replace '[`"''“”]', ' ') -replace '\s+', ' ').Trim() } | Where-Object { $_ })
        foreach ($line in $unwrapped) {
            if ($null -ne (Get-SpecrewTypedAuthorityShape -Text $line) -or $line -match $script:SpecrewVerdictOptionLinePattern) { return (& $none 'not-standalone' $false) }
        }
        # Any other typed reply answers what waits for one: a judgment call at a review stop, then a workshop question.
        if ($null -ne $pause -and [string](& $prop $pause 'Kind') -ceq 'c-judgment') {
            $act.Kind = 'stop-answer'; $act.Reason = ''; $act.Answer = 'judgment'; $act.Target = [string](& $prop $pause 'Id')
            return $act
        }
        if ($null -ne $question) {
            $act.Kind = 'workshop-reply'; $act.Reason = ''; $act.Target = [string](& $prop $question 'Id')
            return $act
        }
        return (& $none 'not-an-act' $false)
    }

    $route = { param([string]$Kind, [string]$Target, [string]$Answer, [string]$Argument)
        $act.Kind = $Kind; $act.Reason = ''; $act.Report = $false; $act.Target = $Target; $act.Answer = $Answer; $act.Argument = $Argument
        return $act }
    $pauseId = [string](& $prop $pause 'Id')
    if ($null -ne $shape) {
        switch ([string]$shape.Kind) {
            # Feature 203 T008 (FR-010; DRIFT-052): the per-round approval is removed, and with it the withdrawal of one.
            # Both phrases are still recognised, so `approved for review round` is never read as the `review` boundary
            # verdict (B4F-116/150), but they record nothing, and the human is told why (retired-act).
            'approval-withdrawal' { return (& $none 'retired-act' $true) }
            'review-round-approval' { return (& $none 'retired-act' $true) }
            'partial-review-signoff' { return (& $route 'partial-signoff' '' '' '') }
            'workshop-repair' { return (& $route 'workshop-repair' '' '' '') }
            'coverage-deferral' { return (& $route 'coverage-deferral' '' '' '') }
            'allowance-reset' {
                # Feature 203 T004 (DRIFT-027): until T007's budget pause exists, today's reset is captured with no pause
                # waiting and checked by the review CLI when it is spent; the pending state says so (PreBudgetReviewActs).
                $preBudget = (& $prop $Pending 'PreBudgetReviewActs') -eq $true
                if (($null -eq $pause -or [string](& $prop $pause 'Kind') -cne 'a-budget-spent') -and -not $preBudget) { return (& $none 'no-pending-crossing' $true) }
                return (& $route 'top-up' $pauseId '' '')
            }
            'pause-decision' {
                # Feature 203 T008 step (iii) (FR-011; maintainer ruling 2026-11-09): abandoning a review campaign is retired, the
                # way the per-round approval is: still recognised, so it is never read as anything else, and it records nothing.
                # The human is told it changed nothing and that `stop the review here` is what to type instead.
                if ([string]$shape.Choice -ceq 'abandon') { return (& $none 'retired-act' $true) }
                # Feature 203 T004 (DRIFT-027): today's pause decision is recorded even with no pause waiting, bound to none,
                # and the review CLI refuses it for a run it does not answer; T008's stop answers replace it.
                if ($null -eq $pause -and (& $prop $Pending 'PreBudgetReviewActs') -eq $true) { return (& $route 'stop-answer' '' $(if ([string]$shape.Choice -ceq 'abandon') { 'abandon' } else { 'stop-review' }) '') }
                if ($null -eq $pause) { return (& $none 'no-pending-crossing' $true) }
                return (& $route 'stop-answer' $pauseId $(if ([string]$shape.Choice -ceq 'abandon') { 'abandon' } else { 'stop-review' }) '')
            }
        }
        return (& $none 'not-an-act' $false)
    }
    if ($null -ne $stop) {
        if ($null -eq $pause) { return (& $none 'no-pending-crossing' $true) }
        if ([string]$stop.Answer -ceq 'defer' -and [string]::IsNullOrWhiteSpace([string]$stop.Argument)) { return (& $none 'missing-destination' $true) }
        $routed = & $route 'stop-answer' $pauseId ([string]$stop.Answer) ([string]$stop.Argument)
        if (-not [string]::IsNullOrWhiteSpace([string]$stop.Finding)) { $routed.Target = ('{0}#{1}' -f $pauseId, [string]$stop.Finding) }
        return $routed
    }
    # A boundary verdict pairs with the durable pending crossing, never with a marker (FR-019).
    if ($null -eq $crossing) { return (& $none 'no-pending-crossing' $true) }
    $canon = { param([string]$b) $v = $b.Trim().ToLowerInvariant(); if (Get-Command Normalize-SpecrewCanonicalBoundaryType -ErrorAction SilentlyContinue) { try { $v = [string](Normalize-SpecrewCanonicalBoundaryType -Boundary $v) } catch { $null = $_ } }; $v }
    $from = & $canon ([string](& $prop $crossing 'From'))
    $to = & $canon ([string](& $prop $crossing 'To'))
    $named = @(@($verdict.NamedBoundaries) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | ForEach-Object { & $canon ([string]$_) })
    # Feature 203 T005 (FR-020): a verdict approves the boundary it goes TO; naming the "from" end is the approval already given.
    if ($named.Count -gt 0 -and @($named | Where-Object { $_ -ceq $to }).Count -eq 0) { return (& $none 'boundary-mismatch' $true) }
    $absent = & $prop $crossing 'StageEvidenceAbsent'
    if ($absent -eq $true) { return (& $none 'stage-evidence-absent' $true) }
    return (& $route 'boundary-verdict' ('{0}->{1}' -f $from, $to) '' '')
}

# Feature 203 T004 (FR-022): THE CITED TURN IS RE-READ, NEVER TAKEN ON THE CALLER'S WORD.
#
# A writer used to take a captured evidence label from whoever called it, so an agent that cited the maintainer's real
# `confirm` turn got a verdict recorded (spec US2 scenario 5). Now a citation is a turn identity: the host's id for the
# message (Claude's promptId, Codex's turn_id, Copilot's stand-in) or the act identity Resolve-SpecrewTypedAct returned.
# The turn is read back from the host's record and classified again, and only the act the classifier derives is written.
# The host's record is the transcript; for a prompt the host delivers with no transcript (or before the transcript holds
# it), it is the reservation the prompt hook made for that message when the host handed it over, which carries the
# message's content hash and the dispatcher's origin. A caller-supplied text that no reservation vouches for is no record.
#
# Reasons a citation yields no turn, added to the classifier's (data-model.md):
#   no-citation              no turn identity was given
#   no-host-record           neither a transcript nor a prompt to check against the hook's reservation
#   turn-not-in-host-record  the host's record holds no turn with that identity
#   ambiguous-citation       a message id that names more than one message (Claude reuses a running turn's promptId for a
#                            queued message); the act identity names one

function Get-SpecrewTypedActRecordedIdentities {
    # The act identities that already have an act: the boundary ledger's turn identities, and the typed-act entries of the
    # turn ledger that minted something. The prompt hook's reservation of a message (nothing minted yet) is not an act:
    # the router classifies the message after reserving it.
    [OutputType([string[]])]
    param([Parameter(Mandatory)][string]$ProjectRoot)
    $ids = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $path = Get-SpecrewExhaustedTurnLedgerPath -ProjectRoot $ProjectRoot
    if ([IO.File]::Exists($path)) {
        foreach ($line in [IO.File]::ReadAllLines($path)) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $entry = $null
            try { $entry = $line | ConvertFrom-Json -Depth 6 -ErrorAction Stop } catch { continue }
            if ($null -ne $entry -and $entry.PSObject.Properties['identity'] -and [string]$entry.identity -ceq 'typed-act' -and $entry.PSObject.Properties['turn_id'] -and
                $entry.PSObject.Properties['minted'] -and -not [string]::IsNullOrWhiteSpace([string]$entry.minted)) {
                [void]$ids.Add([string]$entry.turn_id)
            }
        }
    }
    $contextPath = Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/start-context.json'
    if ([IO.File]::Exists($contextPath)) {
        $context = $null
        try { $context = [IO.File]::ReadAllText($contextPath) | ConvertFrom-Json -Depth 20 -ErrorAction Stop } catch { $context = $null }
        $enforcement = if ($null -ne $context -and $context.PSObject.Properties['boundary_enforcement']) { $context.boundary_enforcement } else { $null }
        if ($null -ne $enforcement -and $enforcement.PSObject.Properties['verdict_history']) {
            foreach ($entry in @($enforcement.verdict_history)) {
                if ($null -ne $entry -and $entry.PSObject.Properties['turn_identity'] -and -not [string]::IsNullOrWhiteSpace([string]$entry.turn_identity)) {
                    [void]$ids.Add([string]$entry.turn_identity)
                }
            }
        }
    }
    return [string[]]@($ids)
}

function Test-SpecrewMessageKeyRecorded {
    # Feature 203 T004 (the update from 202): is this message recorded under the 202 key, the host's message id alone?
    # Only with the same content hash: Claude gives a message queued while a turn runs that turn's prompt_id, so the 202
    # key alone names both, and the queued one (whose text differs) is not the one recorded. Fails closed on an unreadable
    # ledger, as the exhausted-turn check does.
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [AllowNull()][AllowEmptyString()][string]$MessageKey,
        [AllowNull()][AllowEmptyString()][string]$ContentHash
    )
    if ([string]::IsNullOrWhiteSpace($MessageKey) -or [string]::IsNullOrWhiteSpace($ContentHash)) { return $false }
    $path = Get-SpecrewExhaustedTurnLedgerPath -ProjectRoot $ProjectRoot
    if (-not [IO.File]::Exists($path)) { return $false }
    try {
        foreach ($line in [IO.File]::ReadAllLines($path)) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $entry = $null
            try { $entry = $line | ConvertFrom-Json -Depth 6 -ErrorAction Stop } catch { continue }
            if ($null -ne $entry -and $entry.PSObject.Properties['turn_id'] -and [string]$entry.turn_id -ceq $MessageKey -and
                $entry.PSObject.Properties['content_hash'] -and [string]$entry.content_hash -ceq $ContentHash) { return $true }
        }
    }
    catch { return $true }
    return $false
}

function Request-SpecrewPromptRepeatClaim {
    # Feature 203 T004 (FR-016; option 1, 2026-11-04): is this prompt event the first for its message, on a host whose
    # binding declares the position key (Cursor, Antigravity)? That key carries the time the hook ran, so one message
    # whose prompt hook fires twice would be two keys and two acts. "One prompt event per message" is an unverified
    # assumption on those hosts (T001 probed neither, and Cursor can also run Claude Code hooks, the shape that doubled
    # every Copilot hook), so a second event with the same session and the same text within the window is the same
    # message. Returns $true for the first event (record it), $false for a repeat (record nothing).
    #
    # The ledger cannot answer it: two hooks fired for one message start together, and the second asks before the first
    # has reserved anything (Copilot's two channels ran 727 ms apart, less than a hook's start-up). So the claim is a
    # file per (session, text), read and rewritten under an exclusive handle: the hooks queue on it, and each reads
    # the time the previous one claimed. A claim older than the window is a human typing the line again.
    #
    # FAILS OPEN, to "first": a false repeat drops the human's message without a word, while a false first leaves the
    # position key's own once-per-key checks in force.
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [AllowNull()][AllowEmptyString()][string]$SessionId,
        [AllowNull()][AllowEmptyString()][string]$Text,
        [Parameter(Mandatory)][string]$NowUtc,
        [int]$WindowSeconds = 5
    )
    if ([string]::IsNullOrWhiteSpace($Text)) { return $true }
    $fs = $null
    try {
        $now = [DateTimeOffset]::Parse($NowUtc, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal)
        $key = Get-SpecrewHumanAuthorityHash -Text (@('prompt-claim', ([string]$SessionId).Trim(), (Get-SpecrewHumanAuthorityHash -Text $Text.Trim())) -join '|')
        $dir = Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/runtime/prompt-claims'
        [IO.Directory]::CreateDirectory($dir) | Out-Null
        $path = Join-Path $dir ($key + '.json')
        $deadline = [DateTime]::UtcNow.AddSeconds(3)
        while ($null -eq $fs) {
            try { $fs = [IO.File]::Open($path, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None) }
            catch [IO.IOException] {
                if ([DateTime]::UtcNow -gt $deadline) { return $true }
                Start-Sleep -Milliseconds 25
            }
        }
        $previous = $null
        if ($fs.Length -gt 0) {
            $buffer = [byte[]]::new([int]$fs.Length)
            [void]$fs.Read($buffer, 0, $buffer.Length)
            # Epoch milliseconds, not an ISO string: ConvertFrom-Json turns an ISO time into a local DateTime, whose
            # string form drops the offset and read back as UTC was hours away, so no second event was ever a repeat.
            try {
                $claimed = [Text.Encoding]::UTF8.GetString($buffer) | ConvertFrom-Json -ErrorAction Stop
                $previous = [DateTimeOffset]::FromUnixTimeMilliseconds([int64]$claimed.claimed_epoch_ms)
            }
            catch { $previous = $null }
        }
        if ($null -ne $previous -and [Math]::Abs(($now - $previous).TotalSeconds) -le $WindowSeconds) { return $false }
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes(([pscustomobject]@{ claimed_epoch_ms = $now.ToUnixTimeMilliseconds(); session_id = [string]$SessionId } | ConvertTo-Json -Compress))
        $fs.SetLength(0); $fs.Position = 0
        $fs.Write($bytes, 0, $bytes.Length)
        return $true
    }
    catch { return $true }
    finally { if ($null -ne $fs) { $fs.Dispose() } }
}

function Get-SpecrewTypedActPendingState {
    # What waits for a reply, in the classifier's shape, read from the stores: the waiting crossing, and the review pause
    # the navigator published (unanswered, scoped to the active feature). No workshop question: a workshop reply is the
    # prompt hook's receipt, never a recovery path's act. PreBudgetReviewActs: today's review acts (the round approval,
    # the allowance reset, the pause decision) are captured with nothing waiting and checked when the review CLI spends
    # them; T007 and T008 replace them with the budget pause and the stop answers, and this flag goes with them.
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][string]$ProjectRoot)
    $pause = $null
    try {
        $published = Get-SpecrewPendingPauseIdentity -ProjectRoot $ProjectRoot
        # Feature 203 T008 step (iii): the stop's own kind; a pause written before step (iii) has none and reads as before.
        if ($null -ne $published -and -not [string]::IsNullOrWhiteSpace([string]$published.run_id)) {
            $kind = if (-not [string]::IsNullOrWhiteSpace([string]$published.stop_kind)) { [string]$published.stop_kind } else { 'b-dispute-or-defer' }
            $pause = [pscustomobject]@{ Kind = $kind; Id = [string]$published.run_id }
        }
    }
    catch { $pause = $null }
    $crossing = $null
    if (Get-Command Get-SpecrewPendingVerdictState -ErrorAction SilentlyContinue) {
        $pv = $null
        try { $pv = Get-SpecrewPendingVerdictState -ProjectRoot $ProjectRoot } catch { $pv = $null }
        if ($null -ne $pv -and [bool]$pv.HasPendingVerdict -and -not [string]::IsNullOrWhiteSpace([string]$pv.PendingToBoundary)) {
            # Checked and absent only: an unverifiable read is not a refusal, as at the capture.
            $absent = ([bool]$pv.StageEvidenceAbsent -and -not [bool]$pv.StageEvidenceUnverifiable)
            $crossing = [pscustomobject]@{ From = [string]$pv.PendingFromBoundary; To = [string]$pv.PendingToBoundary; StageEvidenceAbsent = $absent }
        }
    }
    return [pscustomobject]@{ Crossing = $crossing; Pause = $pause; WorkshopQuestion = $null; PreBudgetReviewActs = $true }
}

function Get-SpecrewTypedActWriterName {
    # The one writer that records an act of this kind; '' when no writer records it yet (a workshop reply is the prompt
    # hook's receipt; the stop answers other than stop-review and abandon are T008's).
    [OutputType([string])]
    param([Parameter(Mandatory)]$Act)
    switch ([string]$Act.Kind) {
        'top-up' { return 'Write-SpecrewAllowanceResetAuthorization' }
        'coverage-deferral' { return 'Write-SpecrewCoverageDeferralAuthorization' }
        'partial-signoff' { return 'Write-SpecrewReviewSignoffOverrideAuthorization' }
        'workshop-repair' { return 'Write-SpecrewWorkshopRepairAuthorization' }
        'stop-answer' {
            if ([string]$Act.Answer -ceq 'stop-review') { return 'Write-SpecrewPauseDecisionAuthorization' }
            # Feature 203 T008 step (iii) (FR-011): the other stop lines, captured bound to the open stop for the next launch.
            if ([string]$Act.Answer -cin @('defer', 'drop', 'fix', 'allow-reviewer', 'judgment')) { return 'Write-SpecrewStopAnswerAuthorization' }
        }
    }
    return ''
}

function Invoke-SpecrewTypedActSink {
    # Records a derived act (not a boundary verdict) through the one writer for its kind, with the human's own text, and
    # returns what that writer returned ($null when it recorded nothing). Throws when the writer throws, so the caller can
    # tell a failure from an act no writer takes.
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)]$Act,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Text,
        [AllowNull()][AllowEmptyString()][string]$HostKind,
        [AllowNull()][AllowEmptyString()][string]$SourceEvent,
        [AllowNull()][AllowEmptyString()][string]$NowUtc
    )
    $writerName = Get-SpecrewTypedActWriterName -Act $Act
    if ([string]::IsNullOrWhiteSpace($writerName)) { return $null }
    $writer = Get-Command $writerName -ErrorAction SilentlyContinue
    if ($null -eq $writer) { throw "the writer for '$([string]$Act.Kind)' is not loaded" }
    $splat = @{ ProjectRoot = $ProjectRoot; Response = $Text; HostKind = $HostKind; SourceEvent = $SourceEvent }
    if ($writer.Parameters.ContainsKey('NowUtc') -and -not [string]::IsNullOrWhiteSpace($NowUtc)) { $splat['NowUtc'] = $NowUtc }
    if ($writer.Parameters.ContainsKey('TurnIdentity') -and -not [string]::IsNullOrWhiteSpace([string]$Act.TurnIdentity)) { $splat['TurnIdentity'] = [string]$Act.TurnIdentity }
    # A writer that records what the classifier derived (the stop lines: answer, finding, argument) takes the act itself.
    if ($writer.Parameters.ContainsKey('Act')) { $splat['Act'] = $Act }
    return (& $writer @splat)
}

function Test-SpecrewPromptEventKeyTaken {
    # Co-review round 8 (T004): has a prompt event already reserved this key? On a host that fires one prompt event per
    # message (Claude, measured by T001), such a row is ANOTHER message with the same id and text (a reply retyped while the
    # turn ends, which Claude hands the running turn's prompt_id), never this one again. A turn end's row is not one.
    [OutputType([bool])]
    param([Parameter(Mandatory)][string]$ProjectRoot, [AllowNull()][AllowEmptyString()][string]$TurnId)
    if ([string]::IsNullOrWhiteSpace($TurnId)) { return $false }
    $path = Get-SpecrewExhaustedTurnLedgerPath -ProjectRoot $ProjectRoot
    if (-not [IO.File]::Exists($path)) { return $false }
    foreach ($line in [IO.File]::ReadAllLines($path)) {
        if ([string]::IsNullOrWhiteSpace($line) -or -not $line.Contains($TurnId)) { continue }
        $row = $null
        try { $row = $line | ConvertFrom-Json -Depth 6 -ErrorAction Stop } catch { continue }
        if ($null -eq $row -or -not $row.PSObject.Properties['turn_id'] -or [string]$row.turn_id -cne $TurnId) { continue }
        $event = if ($row.PSObject.Properties['source_event']) { ([string]$row.source_event).Trim().ToLowerInvariant() } else { '' }
        if ($event -notin @('', 'stop', 'stop-transcript', 'agentstop')) { return $true }
    }
    return $false
}

function Resolve-SpecrewTranscriptEntryActIdentity {
    # Co-review round 8 (T004): each transcript entry's act identity, set on its turn as act_identity, from the host's own
    # record of that message. Entries: { Turn (record_uuid, text); Base (the id-and-text key); Session }, oldest first.
    #   1 bound   - the hook's output for this prompt event sits under the entry's own record: the key the hook recorded;
    #   2 pending - the hook has reserved a message with this text whose output is under no record yet (it is still being
    #               written): that reservation. Each one stands for one entry, newest first. Only rows after the newest row
    #               that IS under a record can be pending, so an older message's row never stands in for a newer one;
    #   3 history - a row under the id-and-text key from before the hook printed its prompt event: that key;
    #   4 missed  - the hook did not record it: the key of its own record ('record:<uuid>'), which no other message has.
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$Entries,
        [Parameter(Mandatory)][hashtable]$ParentOf,
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.HashSet[string]]$Records,
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$HookEvents
    )
    if ($Entries.Count -eq 0) { return }
    # Which prompt events sit under which record: an attachment's parent may be another attachment of the same message.
    $boundTo = @{}
    $boundEvents = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($hookEvent in $HookEvents) {
        $node = [string]$hookEvent.Parent
        for ($step = 0; $step -lt 32 -and -not [string]::IsNullOrWhiteSpace($node) -and -not $Records.Contains($node) -and $ParentOf.ContainsKey($node); $step++) { $node = [string]$ParentOf[$node] }
        if ([string]::IsNullOrWhiteSpace($node) -or -not $Records.Contains($node)) { continue }
        if (-not $boundTo.ContainsKey($node)) { $boundTo[$node] = [System.Collections.Generic.List[string]]::new() }
        $boundTo[$node].Add([string]$hookEvent.PromptEvent) | Out-Null
        [void]$boundEvents.Add([string]$hookEvent.PromptEvent)
    }
    $rows = [System.Collections.Generic.List[object]]::new()
    $path = Get-SpecrewExhaustedTurnLedgerPath -ProjectRoot $ProjectRoot
    if ([IO.File]::Exists($path)) {
        $index = 0
        foreach ($line in [IO.File]::ReadAllLines($path)) {
            $index++
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $row = $null
            try { $row = $line | ConvertFrom-Json -Depth 6 -ErrorAction Stop } catch { continue }
            if ($null -eq $row -or -not $row.PSObject.Properties['turn_id']) { continue }
            $get = { param($n) if ($row.PSObject.Properties[$n]) { [string]$row.$n } else { '' } }
            $rows.Add([pscustomobject]@{ Index = $index; TurnId = [string]$row.turn_id; PromptEvent = (& $get 'prompt_event'); ContentHash = (& $get 'content_hash')
                    Session = (& $get 'session_id'); Event = (& $get 'source_event').Trim().ToLowerInvariant() }) | Out-Null
        }
    }
    $byEvent = @{}
    foreach ($row in $rows) { if (-not [string]::IsNullOrWhiteSpace($row.PromptEvent) -and -not $byEvent.ContainsKey($row.PromptEvent)) { $byEvent[$row.PromptEvent] = $row } }
    $lastBound = 0
    foreach ($row in $rows) { if (-not [string]::IsNullOrWhiteSpace($row.PromptEvent) -and $boundEvents.Contains($row.PromptEvent) -and $row.Index -gt $lastBound) { $lastBound = $row.Index } }
    $pending = [System.Collections.Generic.List[object]]::new()
    $pendingSeen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($row in $rows) {
        if ([string]::IsNullOrWhiteSpace($row.PromptEvent) -or $boundEvents.Contains($row.PromptEvent) -or $row.Index -le $lastBound) { continue }
        if ($row.Event -in @('', 'stop', 'stop-transcript', 'agentstop')) { continue }
        if ($pendingSeen.Add($row.PromptEvent)) { $pending.Add($row) | Out-Null }
    }
    $history = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($row in $rows) { if ([string]::IsNullOrWhiteSpace($row.PromptEvent)) { [void]$history.Add($row.TurnId) } }
    for ($i = $Entries.Count - 1; $i -ge 0; $i--) {
        $entry = $Entries[$i]
        $turn = $entry.Turn
        $uuid = [string]$turn.record_uuid
        $resolved = ''
        if (-not [string]::IsNullOrWhiteSpace($uuid) -and $boundTo.ContainsKey($uuid)) {
            foreach ($promptEvent in $boundTo[$uuid]) { if ($byEvent.ContainsKey($promptEvent)) { $resolved = [string]$byEvent[$promptEvent].TurnId; break } }
        }
        elseif ($pending.Count -gt 0) {
            $text = ([string]$turn.text).Trim()
            $hashes = @((Get-SpecrewHumanAuthorityHash -Text $text))
            try {
                $form = Resolve-SpecrewApprovalForm -Text $text -HostKind ([string]$turn.host)
                if ($null -ne $form -and -not [string]::IsNullOrWhiteSpace([string]$form.Text)) { $hashes += Get-SpecrewHumanAuthorityHash -Text ([string]$form.Text).Trim() }
            }
            catch { $null = $_ }
            for ($p = $pending.Count - 1; $p -ge 0; $p--) {
                $row = $pending[$p]
                if ($hashes -cnotcontains $row.ContentHash) { continue }
                if (-not [string]::IsNullOrWhiteSpace($row.Session) -and -not [string]::IsNullOrWhiteSpace([string]$entry.Session) -and $row.Session -cne [string]$entry.Session) { continue }
                $resolved = $row.TurnId
                $pending.RemoveAt($p)
                break
            }
        }
        if ([string]::IsNullOrWhiteSpace($resolved) -and $history.Contains([string]$entry.Base)) { $resolved = [string]$entry.Base }
        if ([string]::IsNullOrWhiteSpace($resolved)) {
            $resolved = if ([string]::IsNullOrWhiteSpace($uuid)) { [string]$entry.Base }
            else {
                $own = [pscustomobject]@{ host = $turn.host; message_id = $turn.message_id; text = $turn.text; occurrence = ('record:' + $uuid) }
                [string](Get-SpecrewTypedActIdentity -Turn $own).Identity
            }
        }
        $turn | Add-Member -NotePropertyName act_identity -NotePropertyValue $resolved -Force
    }
}

function Read-SpecrewCitedTypedTurn {
    # The cited turn from the host's record, in the classifier's turn shape. Returns { Turn; Reason } with Turn $null when
    # the record holds no such turn.
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [AllowNull()][AllowEmptyString()][string]$HostKind,
        [AllowNull()][AllowEmptyString()][string]$TurnIdentity,
        [AllowNull()][AllowEmptyString()][string]$TranscriptPath,
        # The prompt as the host handed it to the hook, checked against the hook's own reservation of that message.
        [AllowNull()][AllowEmptyString()][string]$PromptText,
        [AllowNull()][AllowEmptyString()][string]$MessageIdentity,
        [int]$MaxLines = 4000
    )
    $hostKey = ([string]$HostKind).Trim().ToLowerInvariant()
    $cited = ([string]$TurnIdentity).Trim()
    if ([string]::IsNullOrWhiteSpace($cited)) { return [pscustomobject]@{ Turn = $null; Reason = 'no-citation' } }
    $identityKind = if (([string]$MessageIdentity).Trim() -cin @('stand-in', 'position-key')) { ([string]$MessageIdentity).Trim() } else { 'declared' }
    $hadRecord = $false

    if (-not [string]::IsNullOrWhiteSpace($TranscriptPath) -and [IO.File]::Exists($TranscriptPath)) {
        $hadRecord = $true
        $prop = { param($o, $n) if ($null -ne $o -and $o.PSObject.Properties[$n]) { $o.$n } else { $null } }
        $entries = [System.Collections.Generic.List[object]]::new()
        # Co-review round 8 (T004): THE HOST'S OWN RECORD TELLS TWO MESSAGES APART, never a time window. Claude can hand two
        # messages with the same text to the prompt hook under one running prompt_id, so neither the id nor the text says
        # which message a ledger row is. What does: Claude stores the hook's output for each message as an attachment
        # under that message's own record (the user entry, or the queued_command attachment of a message absorbed into a
        # running turn; measured on this project's transcript, Claude Code 2.1.31x: all 132 prompt-hook outputs). The hook
        # prints its prompt event's id there and keeps it on its reservation (Register-SpecrewExhaustedTurn -PromptEvent),
        # so each entry resolves, by its own uuid, to the key the hook recorded it under.
        $parentOf = @{}
        $records = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        $hookEvents = [System.Collections.Generic.List[object]]::new()
        $codexTurnId = ''
        foreach ($line in @(Get-SpecrewTranscriptTailLines -Path $TranscriptPath -MaxLines $MaxLines)) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $o = $null
            try { $o = $line | ConvertFrom-Json -Depth 40 -ErrorAction Stop } catch { continue }
            if ($null -eq $o) { continue }
            $entryType = [string](& $prop $o 'type')
            if ($entryType -ceq 'turn_context') { $codexTurnId = [string](& $prop (& $prop $o 'payload') 'turn_id'); continue }
            $uuid = [string](& $prop $o 'uuid')
            if ($entryType -ceq 'attachment') {
                $attachment = & $prop $o 'attachment'
                $attachmentType = [string](& $prop $attachment 'type')
                if ($attachmentType -ceq 'queued_command') {
                    if (-not [string]::IsNullOrWhiteSpace($uuid)) { [void]$records.Add($uuid) }
                    # B5F-070 (maintainer ruling 2026-11-13): a message typed while the crew is working has no user record; its
                    # turn is this attachment, its act identity resolved through the hook output under it.
                    $queuedText = [string](& $prop $attachment 'prompt')
                    if (-not [string]::IsNullOrWhiteSpace($uuid) -and -not [string]::IsNullOrWhiteSpace($queuedText) -and -not ($hostKey -cin @('codex'))) {
                        $queuedOrigin = & $prop $attachment 'origin'
                        $queuedSender = Get-SpecrewTranscriptRecordSender -RecordKind 'queued_command' -OriginKind ([string](& $prop $queuedOrigin 'kind')) `
                            -HumanTurn (& $prop $attachment 'humanTurn') -CommandMode ([string](& $prop $attachment 'commandMode'))
                        $queuedAt = & $prop $attachment 'timestamp'
                        $queuedTurn = [pscustomobject]@{ host = 'claude'; message_id = ('queued:' + $uuid); message_identity = $identityKind
                            origin = $(if ([bool]$queuedSender.accepted) { 'typed-user' } else { 'host-injected' }); text = $queuedText; record_uuid = $uuid
                            observed_at = $(if ($queuedAt -is [datetime]) { $queuedAt.ToUniversalTime().ToString('o') } else { [string]$queuedAt })
                            record_kind = 'queued_command'; record_origin_kind = [string](& $prop $queuedOrigin 'kind'); record_human_turn = (& $prop $attachment 'humanTurn')
                            record_command_mode = [string](& $prop $attachment 'commandMode'); record_turn_origin = ''; record_prompt_source = ''; record_is_meta = $null }
                        $queuedAsCited = [string](Get-SpecrewTypedActIdentity -Turn ([pscustomobject]@{ host = $hostKey; message_id = ('queued:' + $uuid); text = $queuedText })).Identity
                        $entries.Add([pscustomobject]@{ Turn = $queuedTurn; Base = [string](Get-SpecrewTypedActIdentity -Turn $queuedTurn).Identity; AsCited = $queuedAsCited; Session = [string](& $prop $o 'sessionId') }) | Out-Null
                    }
                }
                elseif (-not [string]::IsNullOrWhiteSpace($uuid)) { $parentOf[$uuid] = [string](& $prop $o 'parentUuid') }
                if ($attachmentType -ceq 'hook_additional_context' -and [string](& $prop $attachment 'hookEvent') -ceq 'UserPromptSubmit') {
                    $content = (@(& $prop $attachment 'content') | ForEach-Object { [string]$_ }) -join "`n"
                    foreach ($m in [regex]::Matches($content, 'specrew-prompt-event:\s*([0-9a-f]{32})')) {
                        $hookEvents.Add([pscustomobject]@{ Parent = [string](& $prop $o 'parentUuid'); PromptEvent = $m.Groups[1].Value }) | Out-Null
                    }
                }
                continue
            }
            if ($entryType -ceq 'user' -and -not [string]::IsNullOrWhiteSpace($uuid)) { [void]$records.Add($uuid) }
            $rp = Get-SpecrewConversationTurnRolePartsFromObject -Object $o
            if ($null -eq $rp -or [string]$rp.role -cne 'user') { continue }
            $formatted = Format-SpecrewConversationTurnText -Turn $rp -Raw
            if ($null -eq $formatted) { continue }
            $messageId = [string](& $prop $o 'promptId')
            if ([string]::IsNullOrWhiteSpace($messageId) -and $entryType -ceq 'response_item') { $messageId = $codexTurnId }
            if ([string]::IsNullOrWhiteSpace($messageId)) { continue }
            # Co-review round 11 (finding 1): THE ENTRY'S HOST IS THE RECORD'S, NOT THE CALLER'S. The host is part of the act
            # identity, and the reader labelled each entry with the host it was told, so one Claude approval cited again as
            # codex (or with no host) had a second identity, and once spent it was recorded again. The entry's own shape
            # names its host (a Codex rollout's response_item, a Claude entry's promptId); an entry whose shape is the other
            # of those two hosts than the caller names is not this caller's message. A caller naming neither (no host, or the
            # handover's 'host' when nothing named one) reads every entry under its own host.
            $entryHost = if ($entryType -ceq 'response_item') { 'codex' } else { 'claude' }
            if ($hostKey -cin @('claude', 'codex') -and $hostKey -cne $entryHost) { continue }
            # Who wrote it, from the entry itself: Claude records origin.kind ('human', 'task-notification', ...) and marks
            # a sub-agent's entries isSidechain; the role/parts reader marks metadata and host envelopes as machinery.
            $origin = 'typed-user'
            if ([string]$rp.verdict_evidence -cne 'human') { $origin = 'host-injected' }
            $side = & $prop $o 'isSidechain'
            if ($side -eq $true -or [string]$side -match '(?i)^\s*true\s*$') { $origin = 'host-injected' }
            $entryOrigin = & $prop $o 'origin'
            if ($null -ne $entryOrigin -and $null -ne (& $prop $entryOrigin 'kind') -and [string](& $prop $entryOrigin 'kind') -cne 'human') { $origin = 'host-injected' }
            # When the human typed it, as the host recorded it: the act is ordered by this, never by when a recovery ran.
            $entryTime = & $prop $o 'timestamp'
            $observedAt = if ($entryTime -is [datetime]) { $entryTime.ToUniversalTime().ToString('o') } elseif ($null -ne $entryTime) { [string]$entryTime } else { '' }
            $turn = [pscustomobject]@{ host = $entryHost; message_id = $messageId; message_identity = $identityKind; origin = $origin; text = [string]$formatted.text; record_uuid = $uuid; observed_at = $observedAt }
            if (Test-SpecrewConversationMetaFlag -Object $o) { $turn | Add-Member -NotePropertyName is_compact_summary -NotePropertyValue $true }
            # Feature 203 T013 (maintainer ruling 2026-11-12): the record's own word on who wrote it, for the classifier's
            # positive rule (turnOrigin human with promptSource typed or queued). Absent on older hosts.
            # Every field Get-SpecrewTranscriptRecordSender reads, each where the record has it (an older host has some or none).
            $recordOriginKind = [string](& $prop $entryOrigin 'kind')
            $recordMeta = & $prop $o 'isMeta'
            $turn | Add-Member -NotePropertyName record_turn_origin -NotePropertyValue ([string](& $prop $o 'turnOrigin'))
            $turn | Add-Member -NotePropertyName record_prompt_source -NotePropertyValue ([string](& $prop $o 'promptSource'))
            $turn | Add-Member -NotePropertyName record_origin_kind -NotePropertyValue $recordOriginKind
            $turn | Add-Member -NotePropertyName record_is_meta -NotePropertyValue $recordMeta
            if ($recordOriginKind -ceq 'peer') {
                $turn | Add-Member -NotePropertyName record_peer_name -NotePropertyValue ([string](& $prop $entryOrigin 'name'))
                $turn | Add-Member -NotePropertyName record_peer_address -NotePropertyValue ([string](& $prop $entryOrigin 'from'))
            }
            # The id-and-text key a caller with no host label computed, so its citation still finds the entry; the turn and
            # its identity keep the entry's own host.
            $asCited = [string](Get-SpecrewTypedActIdentity -Turn ([pscustomobject]@{ host = $hostKey; message_id = $messageId; text = [string]$formatted.text })).Identity
            $entries.Add([pscustomobject]@{ Turn = $turn; Base = [string](Get-SpecrewTypedActIdentity -Turn $turn).Identity; AsCited = $asCited; Session = [string](& $prop $o 'sessionId') }) | Out-Null
        }
        Resolve-SpecrewTranscriptEntryActIdentity -ProjectRoot $ProjectRoot -Entries $entries -ParentOf $parentOf -Records $records -HookEvents $hookEvents
        # The citation names an entry by the act identity it resolved to, or by its record ('entry:<uuid>'). A message id,
        # or the id-and-text key from before the record resolved it, still names the newest entry it fits; a message id
        # fitting entries with different texts is ambiguous.
        $exact = @($entries | Where-Object { [string]$_.Turn.act_identity -ceq $cited -or ('entry:' + [string]$_.Turn.record_uuid) -ceq $cited })
        if ($exact.Count -ge 1) { return [pscustomobject]@{ Turn = $exact[$exact.Count - 1].Turn; Reason = '' } }
        $byKey = @($entries | Where-Object { [string]$_.Base -ceq $cited -or [string]$_.AsCited -ceq $cited })
        if ($byKey.Count -ge 1) { return [pscustomobject]@{ Turn = $byKey[$byKey.Count - 1].Turn; Reason = '' } }
        $byId = @($entries | Where-Object { [string]$_.Turn.message_id -ceq $cited })
        $distinct = @($byId | ForEach-Object { $_.Base } | Sort-Object -Unique)  # specrew-dedup-not-a-path: act identities are lowercase SHA-256 hex
        if ($distinct.Count -gt 1) { return [pscustomobject]@{ Turn = $null; Reason = 'ambiguous-citation' } }
        if ($byId.Count -ge 1) { return [pscustomobject]@{ Turn = $byId[$byId.Count - 1].Turn; Reason = '' } }
    }

    if (-not [string]::IsNullOrWhiteSpace($PromptText)) {
        $hadRecord = $true
        # Co-review round 9: the text in the form the prompt router keyed it (ConvertTo-SpecrewTypedActText, trimmed).
        $cleanedPrompt = (ConvertTo-SpecrewTypedActText -Text $PromptText).Trim()
        if (-not [string]::IsNullOrWhiteSpace($cleanedPrompt)) { $PromptText = $cleanedPrompt }
        # The reservation the prompt hook wrote for this message (Invoke-SpecrewTypedAuthorityCapture), under the key and
        # content hash it computes: the message id's key, and the hash of the approval form's text, trimmed.
        $formText = [string]$PromptText
        try {
            $form = Resolve-SpecrewApprovalForm -Text $PromptText -HostKind $hostKey
            if ($null -ne $form -and -not [string]::IsNullOrWhiteSpace([string]$form.Text)) { $formText = [string]$form.Text }
        }
        catch { $formText = [string]$PromptText }
        # The router keys a message with an id by its act identity; one reserved before 203 by the 202 key.
        # Co-review round 8: or the router's own key for this prompt event, cited as it is (a second message with the same
        # text under the same prompt id is keyed by its prompt event).
        $reservationKeys = @(
            $cited
            [string](Get-SpecrewTypedActIdentity -Turn ([pscustomobject]@{ host = $hostKey; message_id = $cited; text = [string]$PromptText })).Identity
            [string](Get-SpecrewTypedTurnIdentity -Response $formText -HostKind $hostKey -MessageId $cited)
        )
        $contentHash = Get-SpecrewHumanAuthorityHash -Text $formText.Trim()
        $path = Get-SpecrewExhaustedTurnLedgerPath -ProjectRoot $ProjectRoot
        $reservation = $null
        $reservationAt = ''
        if ([IO.File]::Exists($path)) {
            foreach ($line in [IO.File]::ReadAllLines($path)) {
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                $entry = $null
                try { $entry = $line | ConvertFrom-Json -Depth 6 -ErrorAction Stop } catch { continue }
                if ($null -eq $entry -or -not $entry.PSObject.Properties['turn_id'] -or $reservationKeys -cnotcontains [string]$entry.turn_id) { continue }
                if (-not $entry.PSObject.Properties['content_hash'] -or [string]$entry.content_hash -cne $contentHash) { continue }
                $event = if ($entry.PSObject.Properties['source_event']) { ([string]$entry.source_event).Trim().ToLowerInvariant() } else { '' }
                if ($event -in @('', 'stop', 'stop-transcript', 'agentstop')) { continue }
                $reservation = $entry
                # The time as written: ConvertFrom-Json would hand it back as a local [datetime].
                $atMatch = [regex]::Match($line, '"observed_at"\s*:\s*"([^"]+)"')
                $reservationAt = if ($atMatch.Success) { $atMatch.Groups[1].Value } else { '' }
                break
            }
        }
        if ($null -ne $reservation) {
            $origin = if ($reservation.PSObject.Properties['turn_origin'] -and -not [string]::IsNullOrWhiteSpace([string]$reservation.turn_origin)) { [string]$reservation.turn_origin } else { 'unknown' }
            # The key the router recorded it under, unless that is the 202 key (history), which is no act identity.
            $actIdentity = if ([string]$reservation.turn_id -ceq $reservationKeys[2]) { '' } else { [string]$reservation.turn_id }
            $turn = [pscustomobject]@{ host = $hostKey; message_id = $cited; message_identity = $identityKind; origin = $origin; text = [string]$PromptText; act_identity = $actIdentity; observed_at = $reservationAt }
            return [pscustomobject]@{ Turn = $turn; Reason = '' }
        }
    }
    return [pscustomobject]@{ Turn = $null; Reason = $(if ($hadRecord) { 'turn-not-in-host-record' } else { 'no-host-record' }) }
}

function Resolve-SpecrewCitedTypedAct {
    # The act a cited turn IS: re-read from the host's record and classified against what waits now. Pure apart from
    # reading the stores. Text is the human's own line (outside any paste the host marks), for the act's writer; a
    # boundary verdict also carries VerdictText, the verdict line the ledger records. Neither is stored by this.
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [AllowNull()][AllowEmptyString()][string]$HostKind,
        [AllowNull()][AllowEmptyString()][string]$TurnIdentity,
        [AllowNull()][AllowEmptyString()][string]$TranscriptPath,
        [AllowNull()][AllowEmptyString()][string]$PromptText,
        [AllowNull()][AllowEmptyString()][string]$MessageIdentity,
        [AllowNull()]$Pending
    )
    $read = Read-SpecrewCitedTypedTurn -ProjectRoot $ProjectRoot -HostKind $HostKind -TurnIdentity $TurnIdentity -TranscriptPath $TranscriptPath -PromptText $PromptText -MessageIdentity $MessageIdentity
    if ($null -eq $read.Turn) {
        $act = [pscustomobject]@{ Kind = 'none'; Reason = [string]$read.Reason; Report = $false; TurnIdentity = ''; IdentityKind = 'none'; Target = ''; Answer = ''; Argument = ''; Shape = '' }
        $act | Add-Member -NotePropertyName VerdictText -NotePropertyValue ''
        $act | Add-Member -NotePropertyName Text -NotePropertyValue ''
        return $act
    }
    if ($null -eq $Pending) { $Pending = Get-SpecrewTypedActPendingState -ProjectRoot $ProjectRoot }
    $act = Resolve-SpecrewTypedAct -Turn $read.Turn -Pending $Pending -RecordedIdentities (Get-SpecrewTypedActRecordedIdentities -ProjectRoot $ProjectRoot)
    $own = [string]$read.Turn.text
    try {
        $form = Resolve-SpecrewApprovalForm -Text $own -HostKind ([string]$read.Turn.host)
        if ($null -ne $form -and -not [string]::IsNullOrWhiteSpace([string]$form.Text)) { $own = [string]$form.Text }
    }
    catch { $own = [string]$read.Turn.text }
    $verdictText = ''
    if ([string]$act.Kind -ceq 'boundary-verdict') {
        $to = ([string]$act.Target -split '->', 2)[-1]
        $verdictText = Get-SpecrewCapturedVerdictText -HumanText $own -ToBoundary $to
    }
    $act | Add-Member -NotePropertyName VerdictText -NotePropertyValue $verdictText -Force
    $act | Add-Member -NotePropertyName Text -NotePropertyValue $(if ([string]$act.Kind -ceq 'none') { '' } else { $own }) -Force
    return $act
}

function Write-SpecrewTypedAct {
    # Feature 203 T004 (FR-022): THE ONLY WRITER FOR THE RECOVERY PATHS. Re-reads the cited turn, re-derives its act through
    # the classifier, and writes only that act, only if it is unrecorded. Returns { Act; Written }. A boundary verdict is
    # recorded through Add-SpecrewBoundaryAuthorization, which re-derives the same citation itself before it writes.
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [AllowNull()][AllowEmptyString()][string]$HostKind,
        [AllowNull()][AllowEmptyString()][string]$TurnIdentity,
        [AllowNull()][AllowEmptyString()][string]$TranscriptPath,
        [AllowNull()][AllowEmptyString()][string]$PromptText,
        [AllowNull()][AllowEmptyString()][string]$MessageIdentity,
        [AllowNull()][AllowEmptyString()][string]$SourceEvent,
        [AllowNull()][AllowEmptyString()][string]$SessionId,
        # A turn end citing a transcript entry passes the entry's position and arrival, so a message recorded before the
        # message-id key existed (Test-SpecrewLegacyTurnRecorded) is not recorded again on an upgraded project.
        [AllowNull()][AllowEmptyString()][string]$LegacyTurnPosition,
        [AllowNull()][AllowEmptyString()][string]$LegacyTurnArrival,
        # The turn end's verdict capture owns a boundary verdict at the same turn end (paired with the packet marker
        # until T005 pairs it with the pending crossing), so the backstop leaves one to it.
        [switch]$ExceptBoundaryVerdict,
        [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o'))
    )
    if ([string]::IsNullOrWhiteSpace($SourceEvent)) { $SourceEvent = if (-not [string]::IsNullOrWhiteSpace($TranscriptPath)) { 'stop-transcript' } else { 'UserPromptSubmit' } }
    $act = Resolve-SpecrewCitedTypedAct -ProjectRoot $ProjectRoot -HostKind $HostKind -TurnIdentity $TurnIdentity -TranscriptPath $TranscriptPath -PromptText $PromptText -MessageIdentity $MessageIdentity
    $result = [pscustomobject]@{ Act = $act; Written = $false }
    if ([string]$act.Kind -ceq 'none') { return $result }
    if ($ExceptBoundaryVerdict -and [string]$act.Kind -ceq 'boundary-verdict') { return $result }
    # The same message under the keys recorded before the act identity: the prompt hook's reservation under the 202
    # message-id key, matched with its content hash (Claude gives a queued message the running turn's promptId, so the id
    # alone would take the queued approval for the turn already recorded), and the pre-202 position key. Not for a boundary
    # verdict: the router reserves every message it sees but records no verdict (the verdict capture does, keyed on the
    # ledger's turn identity), so its reservation says nothing about one.
    $hostKey = ([string]$HostKind).Trim().ToLowerInvariant()
    $read = Read-SpecrewCitedTypedTurn -ProjectRoot $ProjectRoot -HostKind $HostKind -TurnIdentity $TurnIdentity -TranscriptPath $TranscriptPath -PromptText $PromptText -MessageIdentity $MessageIdentity
    $contentHash = Get-SpecrewHumanAuthorityHash -Text ([string]$act.Text).Trim()
    $legacyKey = if ($null -ne $read.Turn) { Get-SpecrewTypedTurnIdentity -Response ([string]$act.Text) -HostKind $hostKey -MessageId ([string]$read.Turn.message_id) } else { '' }
    $alreadyRecorded = $false
    if ([string]$act.Kind -cne 'boundary-verdict') {
        # The prompt hook saw this message: it reserved it under the act identity (or, before 203, under the 202 key).
        # The turn end recovers only a message the hook missed (FR-014).
        $alreadyRecorded = (Test-SpecrewTypedTurnExhausted -ProjectRoot $ProjectRoot -TurnId ([string]$act.TurnIdentity)) -or
            (Test-SpecrewMessageKeyRecorded -ProjectRoot $ProjectRoot -MessageKey $legacyKey -ContentHash $contentHash)
    }
    if (-not $alreadyRecorded -and -not [string]::IsNullOrWhiteSpace($LegacyTurnPosition) -and [string]$act.Kind -cne 'boundary-verdict') {
        $positionKey = Get-SpecrewTypedTurnIdentity -Response ([string]$act.Text) -HostKind $HostKind -SourceEvent $SourceEvent -TurnPosition $LegacyTurnPosition -TurnArrival $LegacyTurnArrival
        $alreadyRecorded = $true
        try { $alreadyRecorded = [bool](Test-SpecrewLegacyTurnRecorded -ProjectRoot $ProjectRoot -LegacyTurnId $positionKey -ContentHash $contentHash -HostKind $HostKind -SinceUtc $LegacyTurnArrival -ExpectedWriter (Get-SpecrewTypedActWriterName -Act $act)) }
        catch { $alreadyRecorded = $true }
    }
    if ($alreadyRecorded) { $act.Kind = 'none'; $act.Reason = 'already-recorded'; $act.Report = $false; return $result }
    switch ([string]$act.Kind) {
        'boundary-verdict' {
            if (-not (Get-Command Add-SpecrewBoundaryAuthorization -ErrorAction SilentlyContinue)) { $act.Kind = 'none'; $act.Reason = 'form-unreadable'; $act.Report = $true; return $result }
            $pv = Get-SpecrewPendingVerdictState -ProjectRoot $ProjectRoot
            # F-198 FR-005: an authorization behind the working crossing is a reconciliation, recorded as retroactive.
            $kind = if ((Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$pv.PendingToBoundary)) -ne (Normalize-SpecrewCanonicalBoundaryType -Boundary ([string]$pv.WorkingBoundary))) { 'retroactive' } else { 'standard' }
            $evidence = if (-not [string]::IsNullOrWhiteSpace($TranscriptPath) -and [IO.File]::Exists($TranscriptPath)) { 'hook-captured-from-transcript' } else { 'hook-captured-user-prompt' }
            $null = Add-SpecrewBoundaryAuthorization -ProjectRoot $ProjectRoot -CurrentBoundary ([string]$pv.PendingFromBoundary) -AuthorizedBoundary ([string]$pv.PendingToBoundary) `
                -AuthorizingHuman 'unattributed' -VerdictText ([string]$act.VerdictText) -EvidenceSource $evidence -Kind $kind `
                -TurnIdentity $TurnIdentity -TranscriptPath $TranscriptPath -PromptText $PromptText -HostKind $HostKind -MessageIdentity $MessageIdentity
            if (Get-Command Sync-SpecrewPendingVerdictArtifactAfterAuthorization -ErrorAction SilentlyContinue) {
                try { Sync-SpecrewPendingVerdictArtifactAfterAuthorization -ProjectRoot $ProjectRoot -NowUtc $NowUtc } catch { $null = $_ }
            }
            $result.Written = $true
        }
        default {
            # Co-review round 8 (T004): RESERVE BEFORE MINTING, as the router does (W70). The turn used to be registered after
            # the writer, its result discarded, so a ledger that could not be appended left a spendable approval with no
            # record that its turn had minted, and once that approval was spent the next turn end recovered the same entry
            # into a fresh one. No reservation, no mint.
            $reserved = $false
            try {
                # Feature 203 T012 (FR-024): the classifier minted this act only after the transcript showed the human typed it
                # (origin typed-user, Resolve-SpecrewCitedTypedAct), so the row says so, and the authority audit can tell it from
                # a row nothing confirmed.
                $reserved = [bool](Register-SpecrewExhaustedTurn -ProjectRoot $ProjectRoot -TurnId ([string]$act.TurnIdentity) -HostKind $HostKind -SourceEvent $SourceEvent `
                        -MintedWriters '' -ContentHash $contentHash -SessionId $SessionId -Identity 'typed-act' -TurnOrigin 'typed-user' -TranscriptPath $TranscriptPath -NowUtc $NowUtc)
            }
            catch { $reserved = $false }
            if (-not $reserved) { $act.Kind = 'none'; $act.Reason = 'not-reserved'; $act.Report = $true; return $result }
            # Co-review round 8: the act is dated by when the human typed it, as the host recorded it, so supersession
            # orders recovered acts by that and not by when this recovery ran.
            $actAt = $NowUtc
            $typedAt = if ($null -ne $read.Turn -and $read.Turn.PSObject.Properties['observed_at']) { ConvertTo-SpecrewAuthorityInstant -Value $read.Turn.observed_at } else { $null }
            if ($null -ne $typedAt) { $actAt = ([DateTimeOffset]$typedAt).ToUniversalTime().ToString('o') }
            $written = $null
            try { $written = Invoke-SpecrewTypedActSink -ProjectRoot $ProjectRoot -Act $act -Text ([string]$act.Text) -HostKind $HostKind -SourceEvent $SourceEvent -NowUtc $actAt }
            catch {
                # Reserved and not saved: said at the human's next message, as the router says it (received is not saved).
                $shape = Get-SpecrewTypedAuthorityShape -Text ([string]$act.Text)
                if ($null -ne $shape) { $null = Write-SpecrewAuthorityNotRecordedReport -ProjectRoot $ProjectRoot -Shape $shape -EntryKey ([string]$act.TurnIdentity) -HostKind $HostKind -SessionId $SessionId -Reason 'not-saved' -NowUtc $NowUtc }
                $act.Kind = 'none'; $act.Reason = 'not-saved'; $act.Report = $true
                return $result
            }
            $result.Written = ($null -ne $written)
            # Co-review round 10 (finding 1): AN ACT NO WRITER TAKES IS SAID, NEVER DROPPED. The partial sign-off and the
            # workshop repair are recorded only as the human sends them (their writers take a prompt event alone), so one the
            # prompt hook missed was derived here, reserved, and recorded by nothing, without a word; the reservation then
            # made every later attempt already-recorded. Reserved and not recorded is reported, and said at the human's next
            # message with the phrase to type again, as a message the hook never received is.
            if (-not $result.Written) {
                $shape = Get-SpecrewTypedAuthorityShape -Text ([string]$act.Text)
                if ($null -ne $shape) { $null = Write-SpecrewAuthorityNotRecordedReport -ProjectRoot $ProjectRoot -Shape $shape -EntryKey ([string]$act.TurnIdentity) -HostKind $HostKind -SessionId $SessionId -Reason 'not-taken' -NowUtc $NowUtc }
                $act.Reason = 'not-taken'; $act.Report = $true
            }
        }
    }
    if ($result.Written) {
        $null = Register-SpecrewExhaustedTurn -ProjectRoot $ProjectRoot -TurnId ([string]$act.TurnIdentity) -HostKind $HostKind -SourceEvent $SourceEvent `
            -MintedWriters ([string]$act.Kind) -ContentHash $contentHash -SessionId $SessionId -Identity 'typed-act' -TurnOrigin 'typed-user' -TranscriptPath $TranscriptPath -NowUtc $NowUtc
    }
    return $result
}

function Test-SpecrewPromptChannelSawContent {
    # Did the message hook (any channel that is not the turn end) see EVERY message in this session with this
    # content? The reservation is written before any writer runs, for every message the hook receives, so it is
    # proof the hook saw a message whether or not anything minted.
    #
    # Co-review round 1 (iteration 002): one same-text reservation is NOT proof for THIS message. Approval A
    # recorded and spent, the same phrase typed again as B 30 seconds later, B missed - a "recent identical text"
    # test let A vouch for B and B vanished without a trace. So the answer is a COUNT within the session: the
    # transcript holds ExpectedCount human messages with this text, and the hook must have reserved at least that
    # many distinct turns in the same session, from the earliest of those messages on (SinceUtc - the transcript
    # is read as a window, so a message older than the window is neither counted nor allowed to vouch). A
    # reservation from another session never counts.
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][AllowEmptyString()][string]$ContentHash,
        [AllowEmptyString()][AllowNull()][string]$HostKind,
        [AllowEmptyString()][AllowNull()][string]$SinceUtc,
        [AllowEmptyString()][AllowNull()][string]$SessionId,
        [int]$ExpectedCount = 1,
        # Co-review round 2 (iteration 002): the arrival of every counted message, oldest first; the LAST is the one asked
        # about. When given, each message must be paired with a reservation of its own, made within 15 seconds of its
        # arrival (measured: Copilot's hook records 4-6 s before the transcript entry, Claude's about 4 s after). A
        # reservation from a message outside the transcript window is near THAT message's arrival, not this one's, so
        # it can no longer stand in for it - which the count from the earliest message allowed.
        [AllowNull()][string[]]$MessageTimesUtc
    )
    if ([string]::IsNullOrWhiteSpace($ContentHash)) { return $false }
    if ($ExpectedCount -lt 1) { $ExpectedCount = 1 }
    # 202 iteration 002, after review sign-off: every time here is read as an instant (ConvertTo-SpecrewAuthorityInstant),
    # never through a [string] cast. A ledger row's observed_at comes back from ConvertFrom-Json as a [datetime]; its
    # string drops the fraction and, for a `+00:00` row, prints local time, so a UTC re-parse shifted it by the zone.
    $messageTimes = @(@($MessageTimesUtc) | ForEach-Object { ConvertTo-SpecrewAuthorityInstant -Value $_ } | Where-Object { $null -ne $_ })
    $path = Get-SpecrewExhaustedTurnLedgerPath -ProjectRoot $ProjectRoot
    if (-not [IO.File]::Exists($path)) { return $false }
    $since = [DateTimeOffset]::MinValue
    $sinceInstant = ConvertTo-SpecrewAuthorityInstant -Value $SinceUtc
    if ($null -ne $sinceInstant) { $since = $sinceInstant.AddSeconds(-60) }
    $session = ([string]$SessionId).Trim()
    $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $candidates = [System.Collections.Generic.List[object]]::new()
    try {
        foreach ($line in [IO.File]::ReadAllLines($path)) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $entry = $null
            try { $entry = $line | ConvertFrom-Json -Depth 6 -ErrorAction Stop } catch { continue }
            if ($null -eq $entry -or -not $entry.PSObject.Properties['content_hash']) { continue }
            if ([string]$entry.content_hash -cne [string]$ContentHash) { continue }
            if ([string]$entry.host_kind -cne [string]$HostKind) { continue }
            if ((([string]$entry.source_event).Trim().ToLowerInvariant()) -in @('stop', 'stop-transcript', 'agentstop')) { continue }
            $entrySession = if ($entry.PSObject.Properties['session_id']) { ([string]$entry.session_id).Trim() } else { '' }
            if (-not [string]::IsNullOrWhiteSpace($session) -and -not [string]::IsNullOrWhiteSpace($entrySession) -and $entrySession -cne $session) { continue }
            if ($messageTimes.Count -gt 0) {
                $when = if ($entry.PSObject.Properties['observed_at']) { ConvertTo-SpecrewAuthorityInstant -Value $entry.observed_at } else { $null }
                if ($null -ne $when -and $seen.Add([string]$entry.turn_id)) { $candidates.Add([pscustomobject]@{ At = $when; Used = $false }) | Out-Null }
                continue
            }
            $at = if ($entry.PSObject.Properties['observed_at']) { ConvertTo-SpecrewAuthorityInstant -Value $entry.observed_at } else { $null }
            if ($null -ne $at -and $at -lt $since) { continue }
            [void]$seen.Add([string]$entry.turn_id)
            if ($seen.Count -ge $ExpectedCount) { return $true }
        }
    }
    catch { return $false }
    if ($messageTimes.Count -eq 0) { return $false }
    # Oldest message first, each takes the nearest unused reservation within 15 seconds; the answer is the last one's.
    $matchedLast = $false
    for ($m = 0; $m -lt $messageTimes.Count; $m++) {
        $best = $null; $bestGap = [double]::MaxValue
        foreach ($c in $candidates) {
            if ($c.Used) { continue }
            $gap = [math]::Abs(($c.At - $messageTimes[$m]).TotalSeconds)
            if ($gap -le 15 -and $gap -lt $bestGap) { $best = $c; $bestGap = $gap }
        }
        if ($null -ne $best) { $best.Used = $true }
        if ($m -eq $messageTimes.Count - 1) { $matchedLast = ($null -ne $best) }
    }
    return $matchedLast
}

function Test-SpecrewLegacyTurnRecorded {
    # Co-review round 1 (iteration 002): THE KEY CHANGED, THE HISTORY DID NOT. A message recorded before the
    # message-ID key existed is in the ledger under the old key - the turn end's position key, or the message
    # hook's arrival key. After an update, the next turn end computes the NEW key for that same message, finds
    # nothing, and would record a spent approval again: B4F-127, one last time, on every upgraded project. So the
    # turn end also asks whether the OLD record of this message exists. Entries written under the new key carry
    # `identity`, and are never read here; this answers only for history.
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [AllowEmptyString()][AllowNull()][string]$LegacyTurnId,
        [AllowEmptyString()][AllowNull()][string]$ContentHash,
        [AllowEmptyString()][AllowNull()][string]$HostKind,
        [AllowEmptyString()][AllowNull()][string]$SinceUtc,
        # The writer that records this message's phrase (Write-SpecrewAllowanceResetAuthorization, ...). Empty
        # when the text is no recognized phrase.
        [AllowEmptyString()][AllowNull()][string]$ExpectedWriter
    )
    $path = Get-SpecrewExhaustedTurnLedgerPath -ProjectRoot $ProjectRoot
    if (-not [IO.File]::Exists($path)) { return $false }
    # Times read as instants, never through a [string] cast - see Test-SpecrewPromptChannelSawContent.
    $since = $null
    $sinceInstant = ConvertTo-SpecrewAuthorityInstant -Value $SinceUtc
    if ($null -ne $sinceInstant) { $since = $sinceInstant.AddSeconds(-60) }
    try {
        $lines = [IO.File]::ReadAllLines($path)
        # Co-review round 4 (iteration 002): what each old turn RECORDED, read from its second ledger line.
        $mintedByTurn = @{}
        foreach ($line in $lines) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $entry = $null
            try { $entry = $line | ConvertFrom-Json -Depth 6 -ErrorAction Stop } catch { continue }
            if ($null -eq $entry -or -not $entry.PSObject.Properties['turn_id'] -or -not $entry.PSObject.Properties['minted']) { continue }
            foreach ($w in ([string]$entry.minted -split ',')) { if (-not [string]::IsNullOrWhiteSpace($w)) { $mintedByTurn[([string]$entry.turn_id + '|' + $w.Trim())] = $true } }
        }
        foreach ($line in $lines) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $entry = $null
            try { $entry = $line | ConvertFrom-Json -Depth 6 -ErrorAction Stop } catch { continue }
            if ($null -eq $entry -or -not $entry.PSObject.Properties['turn_id']) { continue }
            if ($entry.PSObject.Properties['identity'] -and -not [string]::IsNullOrWhiteSpace([string]$entry.identity)) { continue }
            if (-not [string]::IsNullOrWhiteSpace($LegacyTurnId) -and [string]$entry.turn_id -ceq [string]$LegacyTurnId) { return $true }
            # The old keys cannot always be recomputed (the message hook's used its own clock), so the same text on
            # the same host, recorded by either path from just before this message arrived on, is this message.
            # Co-review round 2 (iteration 002): the old message hook hashed the UNTRIMMED text, so a typed approval with a
            # trailing space has no hash this path can compute. Its record is still the message hook's reservation made
            # within 15 seconds of this message's arrival (see Test-SpecrewPromptChannelSawContent for the measurement),
            # so that matches on time alone.
            # Co-review round 4: time alone is not this message. The old message hook reserved EVERY message, so an
            # ordinary reply, or an approval, typed seconds before a withdrawal the message hook then missed, matched it,
            # and the withdrawal was never recorded. A record on time alone is this message only when that old turn
            # recorded the same kind of act this message asks for.
            if ($null -ne $since -and -not [string]::IsNullOrWhiteSpace($ExpectedWriter) -and
                $mintedByTurn.ContainsKey([string]$entry.turn_id + '|' + $ExpectedWriter) -and [string]$entry.host_kind -ceq [string]$HostKind -and
                (([string]$entry.source_event).Trim().ToLowerInvariant()) -notin @('stop', 'stop-transcript', 'agentstop')) {
                $near = if ($entry.PSObject.Properties['observed_at']) { ConvertTo-SpecrewAuthorityInstant -Value $entry.observed_at } else { $null }
                if ($null -ne $near -and [math]::Abs(($near - $since.AddSeconds(60)).TotalSeconds) -le 15) { return $true }
            }
            # With no arrival to compare, any old record of the same text counts: this check fails closed.
            if ([string]::IsNullOrWhiteSpace($ContentHash)) { continue }
            if (-not $entry.PSObject.Properties['content_hash'] -or [string]$entry.content_hash -cne [string]$ContentHash) { continue }
            if ([string]$entry.host_kind -cne [string]$HostKind) { continue }
            $at = if ($entry.PSObject.Properties['observed_at']) { ConvertTo-SpecrewAuthorityInstant -Value $entry.observed_at } else { $null }
            if ($null -ne $at -and ($null -eq $since -or $at -ge $since)) { return $true }
            if ($null -eq $since) { return $true }
        }
    }
    catch { return $true }
    return $false
}

function Get-SpecrewAuthorityNotRecordedJournalPath {
    param([Parameter(Mandatory)][string]$ProjectRoot)
    return (Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/runtime/authority-capture-drops.jsonl')
}

function Write-SpecrewAuthorityNotRecordedReport {
    # Feature 202 iteration 002, T017 (FR-027, DA-2 condition 2): on a host whose message hook is the only
    # recording path, a typed approval that hook did not record is REPORTED, never dropped without a trace. One
    # row per message (keyed by the transcript entry), in the journal the one-line refusals already use, plus a
    # stderr line; the human reads it at the next message (Get-SpecrewAuthorityNotRecordedDisclosure).
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][pscustomobject]$Shape,
        [Parameter(Mandatory)][string]$EntryKey,
        [AllowNull()][string]$HostKind,
        [AllowNull()][string]$SessionId,
        # Co-review round 2 (iteration 002): 'not-saved' when the message hook received the act but its writer could not
        # store it; the default when the message never reached the hook.
        [string]$Reason = 'message-hook-did-not-record',
        # Feature 203 T006: what the human typed, when it is not the phrase to type again (`defer finding F1` is retyped with
        # its destination). Empty means the retype phrase is what they typed.
        [AllowEmptyString()][string]$Typed = '',
        [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o'))
    )
    $journal = Get-SpecrewAuthorityNotRecordedJournalPath -ProjectRoot $ProjectRoot
    $shapeChoice = if ($Shape.PSObject.Properties['Choice']) { [string]$Shape.Choice } else { '' }
    try {
        if ([IO.File]::Exists($journal)) {
            foreach ($line in [IO.File]::ReadAllLines($journal)) {
                if ($line -notmatch 'authority-phrase-not-recorded') { continue }
                $row = $null
                try { $row = $line | ConvertFrom-Json -ErrorAction Stop } catch { continue }
                if ([string]$row.event -ceq 'authority-phrase-not-recorded' -and [string]$row.entry_key -ceq $EntryKey) { return $false }
            }
        }
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($journal)) | Out-Null
        (([pscustomobject][ordered]@{
                event = 'authority-phrase-not-recorded'; phrase = [string]$Shape.Kind; reason = $Reason
                retype = [string]$Shape.Retype; typed = [string]$Typed; choice = $shapeChoice; entry_key = $EntryKey; host_kind = [string]$HostKind
                session_id = [string]$SessionId; recorded_at = $NowUtc
            }) | ConvertTo-Json -Compress) | Add-Content -LiteralPath $journal -Encoding UTF8 -ErrorAction Stop
        if ($Reason -ceq 'retired-act' -and $shapeChoice -ceq 'abandon') {
            [Console]::Error.WriteLine("[specrew-authority] 'abandon this review campaign' CHANGED NOTHING: abandoning a review campaign was retired. To end the review, type: 'stop the review here'.")
        }
        elseif ($Reason -ceq 'retired-act') {
            [Console]::Error.WriteLine(("[specrew-authority] '{0}' CHANGED NOTHING: review rounds no longer need an approval of their own; the review budget approved with the implementation pays for them." -f [string]$Shape.Retype))
        }
        else {
            [Console]::Error.WriteLine(("[specrew-authority] YOUR {0} WAS NOT RECORDED: the message reached the conversation but not Specrew. Type it again, alone: '{1}'." -f ([string]$Shape.Kind).ToUpperInvariant().Replace('-', ' '), [string]$Shape.Retype))
        }
        return $true
    }
    catch { return $false }
}

function Test-SpecrewNotRecordedReportSettled {
    # Feature 203 T006 (FR-026: the report checks the store when it speaks). A message another path recorded after its report
    # was written (the turn end recovering what the prompt hook could not, a host firing twice) is not reported: the line
    # would tell the human an approval they hold was lost. A typed act: its turn has a writer's mark in the turn ledger. A
    # boundary verdict: the crossing it was for no longer waits. Fails open to speaking: a line said in error costs a retype,
    # a line withheld in error costs an approval the human believes they gave.
    [OutputType([bool])]
    param([Parameter(Mandatory)][string]$ProjectRoot, [Parameter(Mandatory)]$Row)
    try {
        if ([string]$Row.phrase -ceq 'boundary-verdict') {
            if (-not (Get-Command Get-SpecrewPendingVerdictState -ErrorAction SilentlyContinue)) { return $false }
            $pending = Get-SpecrewPendingVerdictState -ProjectRoot $ProjectRoot
            $target = ([string]$Row.retype -replace '^(?i)\s*approved\s+for\s+', '').Trim()
            return (-not [bool]$pending.HasPendingVerdict -or [string]$pending.PendingToMarkerBoundary -cne $target)
        }
        $ledger = Get-SpecrewExhaustedTurnLedgerPath -ProjectRoot $ProjectRoot
        if (-not [IO.File]::Exists($ledger)) { return $false }
        $key = [string]$Row.entry_key
        foreach ($line in [IO.File]::ReadAllLines($ledger)) {
            if (-not $line.Contains($key)) { continue }
            $entry = $null
            try { $entry = $line | ConvertFrom-Json -ErrorAction Stop } catch { continue }
            if ([string]$entry.turn_id -ceq $key -and $entry.PSObject.Properties['minted'] -and -not [string]::IsNullOrWhiteSpace([string]$entry.minted)) { return $true }
        }
    }
    catch { return $false }
    return $false
}

function Get-SpecrewAuthorityNotRecordedDisclosure {
    # The one visible line for a not-recorded approval, said once, at the human's next message on that host.
    # Co-review round 1 (iteration 002): in THE SESSION THAT MISSED IT. Another session on the same project never
    # hears about it and never marks it said, so the session the human typed into still gets its line.
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [AllowNull()][string]$HostKind,
        [AllowNull()][string]$SessionId,
        [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o'))
    )
    $session = ([string]$SessionId).Trim()
    $journal = Get-SpecrewAuthorityNotRecordedJournalPath -ProjectRoot $ProjectRoot
    if (-not [IO.File]::Exists($journal)) { return $null }
    try {
        $pending = [ordered]@{}
        $reports = @{}
        foreach ($line in [IO.File]::ReadAllLines($journal)) {
            if ($line -notmatch 'authority-phrase-not-recorded') { continue }
            $row = $null
            try { $row = $line | ConvertFrom-Json -ErrorAction Stop } catch { continue }
            if ([string]$row.host_kind -cne [string]$HostKind) { continue }
            $rowSession = if ($row.PSObject.Properties['session_id']) { ([string]$row.session_id).Trim() } else { '' }
            if (-not [string]::IsNullOrWhiteSpace($rowSession) -and $rowSession -cne $session) { continue }
            $key = [string]$row.entry_key
            if ([string]$row.event -ceq 'authority-phrase-not-recorded') { $pending[$key] = $row; $reports[$key] = $row }
            elseif ([string]$row.event -ceq 'authority-phrase-not-recorded-settled') { $pending.Remove($key) }
            elseif ([string]$row.event -ceq 'authority-phrase-not-recorded-disclosed') { $pending.Remove($key) }
            # Co-review round 2 (iteration 002): the dispatcher withheld the output that carried the line, so it was never
            # shown; it is pending again and the next message says it.
            elseif ([string]$row.event -ceq 'authority-phrase-not-recorded-undelivered' -and $reports.ContainsKey($key)) { $pending[$key] = $reports[$key] }
        }
        if ($pending.Count -eq 0) { return $null }
        $lines = foreach ($key in @($pending.Keys)) {
            $row = $pending[$key]
            if (Test-SpecrewNotRecordedReportSettled -ProjectRoot $ProjectRoot -Row $row) {
                (([pscustomobject][ordered]@{ event = 'authority-phrase-not-recorded-settled'; entry_key = $key; host_kind = [string]$HostKind; session_id = $session; recorded_at = $NowUtc }) | ConvertTo-Json -Compress) |
                    Add-Content -LiteralPath $journal -Encoding UTF8 -ErrorAction Stop
                continue
            }
            (([pscustomobject][ordered]@{ event = 'authority-phrase-not-recorded-disclosed'; entry_key = $key; host_kind = [string]$HostKind; session_id = $session; recorded_at = $NowUtc }) | ConvertTo-Json -Compress) |
                Add-Content -LiteralPath $journal -Encoding UTF8 -ErrorAction Stop
            $reason = if ($row.PSObject.Properties['reason']) { [string]$row.reason } else { '' }
            $typed = if ($row.PSObject.Properties['typed'] -and -not [string]::IsNullOrWhiteSpace([string]$row.typed)) { [string]$row.typed } else { [string]$row.retype }
            # Feature 203 T006 (FR-026): each reason in its own words - what Specrew looked for, and what it took the message for.
            $readsAs = if ([string]$row.phrase -ceq 'allowance-reset') { 'a reset of a spent review allowance, and no review is paused waiting for one' } else { 'an answer to a review stop, and no review stop is waiting for one' }
            if ($reason -ceq 'form-unreadable') {
                ("Specrew: your '{0}' was received but not recorded - Specrew could not read the message to tell what it approves, so it approved nothing. Nothing you wrote is lost. To record it, type it again on its own: '{0}'." -f $typed)
            }
            elseif ($reason -ceq 'no-pending-crossing') {
                ("Specrew: your '{0}' was received but not recorded - it reads as {1} now, so it changed nothing. Nothing you wrote is lost. Send it again when Specrew asks for it." -f $typed, $readsAs)
            }
            elseif ($reason -ceq 'retired-act' -and $typed -match '(?i)\babandon\b') {
                ("Specrew: your '{0}' changed nothing - abandoning a review campaign was retired, so nothing was recorded. Nothing you wrote is lost. To end the review, type, as a normal chat message: 'stop the review here'." -f $typed)
            }
            elseif ($reason -ceq 'retired-act') {
                ("Specrew: your '{0}' changed nothing - review rounds no longer need an approval of their own, because the review budget approved with the implementation pays for them, so there is no round approval to give or withdraw. Nothing you wrote is lost." -f $typed)
            }
            elseif ($reason -ceq 'missing-destination') {
                ("Specrew: your '{0}' was received but not recorded - deferring a finding needs a destination, so it changed nothing. Nothing you wrote is lost. To defer it, type: '{1}'." -f $typed, [string]$row.retype)
            }
            elseif ($reason -ceq 'no-writer') {
                ("Specrew: your '{0}' was received but not recorded - this version of Specrew cannot record that answer yet, so it changed nothing. Nothing you wrote is lost. Tell the crew in your own words what you want done, and they will carry it out." -f $typed)
            }
            elseif ($reason -ceq 'no-identity') {
                ("Specrew: your '{0}' was received but not recorded - Specrew could not tell which message it came from, so it approved nothing. Nothing you wrote is lost. To record it, type it again on its own: '{0}'." -f $typed)
            }
            elseif ($reason -ceq 'not-saved') {
                ("Specrew: your earlier '{0}' was received but could not be saved, so it approved nothing. Nothing you wrote is lost. To record it, type it again on its own: '{0}'." -f [string]$row.retype)
            }
            elseif ($row.PSObject.Properties['reason'] -and [string]$row.reason -ceq 'not-taken') {
                ("Specrew: your earlier '{0}' was not recorded - it is recorded only as you send it, and Specrew did not receive it then, so it approved nothing. Nothing you wrote is lost. To record it, type it again on its own: '{0}'." -f [string]$row.retype)
            }
            elseif ($row.PSObject.Properties['reason'] -and [string]$row.reason -ceq 'origin-unconfirmed') {
                ("Specrew: your '{0}' was received but not recorded - Specrew could not confirm it was typed in this conversation, so it approved nothing. Nothing you wrote is lost. To record it, type it again on its own: '{0}'." -f [string]$row.retype)
            }
            else {
                ("Specrew: your earlier '{0}' was not recorded - it reached the conversation, but Specrew did not receive it, so it approved nothing. Nothing you wrote is lost. To record it, type it again on its own: '{0}'." -f [string]$row.retype)
            }
        }
        return (@($lines) -join "`n")
    }
    catch { return $null }
}

function Get-SpecrewTranscriptRecordSender {
    # Feature 203 T013 (B5F-066; maintainer rulings 2026-11-12): WHO SENT A MESSAGE, from its transcript record's own fields.
    # Pure. The rule, field by field: isMeta not true; origin.kind human where present; turnOrigin human where present;
    # promptSource typed or queued, or sdk only when origin.kind is human (a human in the VS Code extension or the desktop
    # app; a program has no origin.kind). Any other combination is refused. A record with none of the fields (an older
    # host) is 'unverified': the text rules decided when it was captured.
    # These fields are not a documented host contract (B5F-068); every shape is pinned with its Claude version in
    # tests/fixtures/hook-payloads/claude/transcript-origins/record-shapes.json.
    [OutputType([pscustomobject])]
    param(
        [AllowNull()][AllowEmptyString()][string]$TurnOrigin,
        [AllowNull()][AllowEmptyString()][string]$PromptSource,
        [AllowNull()]$IsMeta,
        [AllowNull()][AllowEmptyString()][string]$OriginKind,
        [AllowNull()][AllowEmptyString()][string]$PeerName,
        [AllowNull()][AllowEmptyString()][string]$PeerAddress,
        # B5F-070 (maintainer ruling 2026-11-13): a message typed while the crew is working is a queued_command attachment,
        # not a user record. It is the human's only when origin.kind is human, humanTurn is true and commandMode is prompt.
        [AllowNull()][AllowEmptyString()][string]$RecordKind,
        [AllowNull()]$HumanTurn,
        [AllowNull()][AllowEmptyString()][string]$CommandMode
    )
    $to = ([string]$TurnOrigin).Trim(); $ps = ([string]$PromptSource).Trim(); $ok = ([string]$OriginKind).Trim()
    if (([string]$RecordKind).Trim() -ceq 'queued_command') {
        $humanTurn = ($HumanTurn -eq $true) -or ([string]$HumanTurn -match '(?i)^\s*true\s*$')
        $queuedHuman = ($ok -ceq 'human') -and $humanTurn -and (([string]$CommandMode).Trim() -ceq 'prompt')
        $queuedSender = if ($queuedHuman) { 'human' } elseif ($ok -ceq 'peer') { 'peer' } elseif ($ok -ceq 'task-notification') { 'task-notification' } else { 'other' }
        $queued = [pscustomobject][ordered]@{ sender = $queuedSender; accepted = [bool]$queuedHuman; fields_present = $true; peer_name = ''; peer_address = '' }
        if ($queuedSender -ceq 'peer') { $queued.peer_name = ([string]$PeerName).Trim(); $queued.peer_address = ([string]$PeerAddress).Trim() }
        return $queued
    }
    $meta = ($IsMeta -eq $true) -or ([string]$IsMeta -match '(?i)^\s*true\s*$')
    $result = [pscustomobject][ordered]@{ sender = 'unverified'; accepted = $true; fields_present = $false; peer_name = ''; peer_address = '' }
    if ([string]::IsNullOrWhiteSpace($to) -and [string]::IsNullOrWhiteSpace($ps) -and [string]::IsNullOrWhiteSpace($ok) -and -not $meta) { return $result }
    $result.fields_present = $true
    $human = (-not $meta) -and ([string]::IsNullOrWhiteSpace($ok) -or $ok -ceq 'human') -and ([string]::IsNullOrWhiteSpace($to) -or $to -ceq 'human') -and
        ((@('typed', 'queued') -ccontains $ps) -or ($ps -ceq 'sdk' -and $ok -ceq 'human'))
    $result.accepted = [bool]$human
    $result.sender = if ($human) { 'human' }
    elseif ($to -ceq 'peer' -or $ok -ceq 'peer') { 'peer' }
    elseif ($to -ceq 'scheduled') { 'scheduled' }
    elseif ($to -ceq 'task_notification' -or $ok -ceq 'task-notification') { 'task-notification' }
    elseif ($to -ceq 'human' -and [string]::IsNullOrWhiteSpace($ps)) { 'self-command' }
    else { 'other' }
    if ($result.sender -ceq 'peer') { $result.peer_name = ([string]$PeerName).Trim(); $result.peer_address = ([string]$PeerAddress).Trim() }
    return $result
}

function Get-SpecrewAuthorizationSenderRefusal {
    # The sentence the human reads when an authorization is not used because of who sent it (maintainer ruling 2026-11-12:
    # it says what to do next).
    [OutputType([string])]
    param([Parameter(Mandatory)][string]$Sender, [AllowNull()][AllowEmptyString()][string]$Purpose, [AllowNull()][AllowEmptyString()][string]$PeerName)
    $what = if ([string]::IsNullOrWhiteSpace($Purpose)) { 'approval' } else { $Purpose.Trim() }
    if ($Sender -ceq 'not-found') {
        return ("Specrew: this {0} was not used, because Specrew could not find the message it came from in your Claude conversation, so it cannot confirm you typed it. Nothing else changed. Type the line again yourself in the terminal session where the crew is working." -f $what)
    }
    $from = switch -CaseSensitive ($Sender) {
        'peer' { if ([string]::IsNullOrWhiteSpace($PeerName)) { 'another Claude session' } else { "another Claude session ('$PeerName')" } }
        'scheduled' { 'a scheduled prompt the session wrote for itself' }
        'task-notification' { 'a background task notification' }
        'self-command' { 'command output the session produced' }
        default { 'a message Specrew cannot confirm you typed' }
    }
    return ("Specrew: this {0} was not used: it came from {1}, not from you typing it. Nothing else changed. To approve, type the line yourself in the terminal session; if you typed it in a Claude app, update Claude Code and type it again there." -f $what, $from)
}

function Resolve-SpecrewAuthorizationSender {
    # Feature 203 T013 (B5F-066; maintainer rulings 2026-11-12): THE CHECK WHEN AN AUTHORIZATION IS USED. The prompt hook runs
    # before the host writes the message's transcript record, so who sent it is read here, from the record the turn's ledger
    # row points at (Register-SpecrewExhaustedTurn -TranscriptPath -MessageId). Returns { accepted; sender; peer_name;
    # peer_address; reason; message }. The sender is stored against the turn (.specrew/authority/turn-senders.jsonl) for the
    # audit and for a later delegated grant; text the session wrote for itself is refused at every level.
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [AllowNull()][AllowEmptyString()][string]$TurnIdentity,
        [AllowNull()][AllowEmptyString()][string]$Purpose,
        [AllowNull()][AllowEmptyString()][string]$HostKind = 'claude',
        [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o')),
        # Iteration review round A finding 3: the authority audit reads the sender and stores nothing (it is read only).
        [switch]$NoRecord
    )
    $result = [pscustomobject][ordered]@{ accepted = $false; sender = 'not-found'; peer_name = ''; peer_address = ''; reason = 'turn-not-found'; message = ''; record_uuid = '' }
    $root = [IO.Path]::GetFullPath($ProjectRoot)
    $turn = $null
    $anyRow = $null
    if (-not [string]::IsNullOrWhiteSpace($TurnIdentity)) {
        $row = $null
        $ledger = Get-SpecrewExhaustedTurnLedgerPath -ProjectRoot $root
        if ([IO.File]::Exists($ledger)) {
            foreach ($line in [IO.File]::ReadAllLines($ledger)) {
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                $entry = $null
                try { $entry = $line | ConvertFrom-Json -Depth 6 -ErrorAction Stop } catch { continue }
                if ($null -eq $entry -or -not $entry.PSObject.Properties['turn_id'] -or [string]$entry.turn_id -cne $TurnIdentity.Trim()) { continue }
                $anyRow = $entry
                if ($entry.PSObject.Properties['transcript_path'] -and -not [string]::IsNullOrWhiteSpace([string]$entry.transcript_path)) { $row = $entry }
            }
        }
        if ($null -ne $row -and [IO.File]::Exists([string]$row.transcript_path)) {
            try {
                $read = Read-SpecrewCitedTypedTurn -ProjectRoot $root -HostKind $HostKind -TurnIdentity $TurnIdentity.Trim() -TranscriptPath ([string]$row.transcript_path) -MaxLines 1000000
                if ($null -ne $read -and $null -ne $read.Turn) { $turn = $read.Turn }
                if ($null -eq $turn -and $row.PSObject.Properties['message_id'] -and -not [string]::IsNullOrWhiteSpace([string]$row.message_id)) {
                    $read = Read-SpecrewCitedTypedTurn -ProjectRoot $root -HostKind $HostKind -TurnIdentity ([string]$row.message_id) -TranscriptPath ([string]$row.transcript_path) -MaxLines 1000000
                    if ($null -ne $read -and $null -ne $read.Turn) { $turn = $read.Turn }
                }
            }
            catch { $turn = $null }
        }
    }
    $rowHost = if ($null -ne $anyRow -and $anyRow.PSObject.Properties['host_kind']) { ([string]$anyRow.host_kind).Trim().ToLowerInvariant() } else { '' }
    $result | Add-Member -NotePropertyName host_kind -NotePropertyValue $(if ($rowHost) { $rowHost } else { ([string]$HostKind).Trim().ToLowerInvariant() })
    $result | Add-Member -NotePropertyName turn -NotePropertyValue $turn
    $noPathHost = ($null -eq $turn -and $null -ne $anyRow -and $null -eq $row -and -not [string]::IsNullOrWhiteSpace($rowHost) -and $rowHost -cne 'claude')
    if ($noPathHost) {
        # Maintainer ruling 2026-11-12: a host whose hook input carries no transcript path (Copilot) cannot be checked; the
        # approval is unverified, as on Codex, where the record carries no sender fields. The text rules decided at capture.
        $result.accepted = $true; $result.sender = 'unverified'; $result.reason = 'host-has-no-transcript'
    }
    elseif ($null -eq $turn) {
        $result.message = Get-SpecrewAuthorizationSenderRefusal -Sender 'not-found' -Purpose $Purpose
    }
    else {
        $prop = { param($n) if ($turn.PSObject.Properties[$n]) { $turn.$n } else { $null } }
        $s = Get-SpecrewTranscriptRecordSender -TurnOrigin ([string](& $prop 'record_turn_origin')) -PromptSource ([string](& $prop 'record_prompt_source')) `
            -IsMeta (& $prop 'record_is_meta') -OriginKind ([string](& $prop 'record_origin_kind')) -PeerName ([string](& $prop 'record_peer_name')) -PeerAddress ([string](& $prop 'record_peer_address')) `
            -RecordKind ([string](& $prop 'record_kind')) -HumanTurn (& $prop 'record_human_turn') -CommandMode ([string](& $prop 'record_command_mode'))
        $result.accepted = [bool]$s.accepted; $result.sender = [string]$s.sender; $result.peer_name = [string]$s.peer_name; $result.peer_address = [string]$s.peer_address
        $result.record_uuid = [string](& $prop 'record_uuid')
        $result.reason = if ($s.accepted) { $(if ($s.fields_present) { 'typed-by-human' } else { 'fields-absent-text-rules' }) } else { 'not-typed-by-human' }
        if (-not $s.accepted) { $result.message = Get-SpecrewAuthorizationSenderRefusal -Sender $result.sender -Purpose $Purpose -PeerName $result.peer_name }
    }
    if ($NoRecord) { return $result }
    try {
        $dir = Join-Path $root '.specrew/authority'
        [IO.Directory]::CreateDirectory($dir) | Out-Null
        $row = [pscustomobject][ordered]@{ turn_identity = [string]$TurnIdentity; sender = $result.sender; accepted = $result.accepted; reason = $result.reason
            peer_name = $result.peer_name; peer_address = $result.peer_address; record_uuid = $result.record_uuid; purpose = [string]$Purpose; host_kind = [string]$result.host_kind; checked_at = $NowUtc }
        Add-Content -LiteralPath (Join-Path $dir 'turn-senders.jsonl') -Value ($row | ConvertTo-Json -Compress) -Encoding UTF8 -ErrorAction Stop
        if ($result.sender -ceq 'unverified') {
            # The unprotected path (maintainer ruling 2026-11-12): journaled, and shown on the status health line.
            $runtime = Join-Path $root '.specrew/runtime'
            [IO.Directory]::CreateDirectory($runtime) | Out-Null
            Add-Content -LiteralPath (Join-Path $runtime 'authorization-sender-unverified.jsonl') -Value ($row | ConvertTo-Json -Compress) -Encoding UTF8 -ErrorAction Stop
        }
    }
    catch { $null = $_ }
    return $result
}

function Test-SpecrewAuthorizationRecordSender {
    # Feature 203 T013 (B5F-066; maintainer ruling 2026-11-12): the check every store reader runs before it hands an
    # authorization to the place that uses it, so no place can skip it and a new reader gets it by calling this. $true when
    # the record's turn was typed by the human (or its record carries none of the sender fields, journaled); $false
    # otherwise, after telling the human what to do next.
    [OutputType([bool])]
    param([Parameter(Mandatory)][string]$ProjectRoot, [AllowNull()]$Record, [AllowNull()][AllowEmptyString()][string]$Purpose)
    if ($null -eq $Record) { return $false }
    $turnIdentity = if ($Record -is [System.Collections.IDictionary]) { [string]$Record['turn_identity'] } elseif ($Record.PSObject.Properties['turn_identity']) { [string]$Record.turn_identity } else { '' }
    $hostKind = if ($Record -is [System.Collections.IDictionary]) { [string]$Record['host_kind'] } elseif ($Record.PSObject.Properties['host_kind']) { [string]$Record.host_kind } else { '' }
    if ([string]::IsNullOrWhiteSpace($hostKind)) { $hostKind = 'claude' }
    $sender = Resolve-SpecrewAuthorizationSender -ProjectRoot $ProjectRoot -TurnIdentity $turnIdentity -Purpose $Purpose -HostKind $hostKind
    if ([bool]$sender.accepted -and $null -ne $sender.turn) {
        # Maintainer ruling 2026-11-12: the record is bound to what its turn said. Its kind must be that turn's act, and its
        # text must be what the turn said (the phrase, or the phrase with the same-line instruction the turn carried).
        $binding = Test-SpecrewAuthorizationRecordMatchesTurn -Record $Record -Turn $sender.turn
        if (-not $binding) {
            $what = if ([string]::IsNullOrWhiteSpace($Purpose)) { 'approval' } else { $Purpose }
            try { [Console]::Error.WriteLine(("Specrew: this {0} was not used: the message it cites does not say it. Nothing else changed. To approve, type the line yourself in the terminal session." -f $what)) } catch { $null = $_ }
            return $false
        }
    }
    if (-not [bool]$sender.accepted) {
        try { [Console]::Error.WriteLine([string]$sender.message) } catch { $null = $_ }
    }
    return [bool]$sender.accepted
}

function Test-SpecrewAuthorizationRecordMatchesTurn {
    # Feature 203 T013 (maintainer ruling 2026-11-12): does the record say what the turn it cites said? $true when the
    # record's kind is the turn's act and its text is the turn's own line (whitespace normalized; the turn may carry a
    # same-line instruction after the phrase). A judgment answer keeps no text (FR-023), so only its kind is checked.
    [OutputType([bool])]
    param([AllowNull()]$Record, [AllowNull()]$Turn)
    if ($null -eq $Record -or $null -eq $Turn) { return $false }
    $get = { param($o, $n) if ($o -is [System.Collections.IDictionary]) { $o[$n] } elseif ($null -ne $o -and $o.PSObject.Properties[$n]) { $o.$n } else { $null } }
    $norm = { param($t) (([string]$t) -replace '\s+', ' ').Trim().ToLowerInvariant() }
    $turnText = [string](& $get $Turn 'text')
    $own = $turnText
    try { $form = Resolve-SpecrewApprovalForm -Text $turnText -HostKind ([string](& $get $Turn 'host')); if (-not [string]::IsNullOrWhiteSpace([string]$form.Text)) { $own = [string]$form.Text } } catch { $own = $turnText }
    # The turn's act, from its own line.
    $turnKind = ''
    $shape = $null
    try { $shape = Get-SpecrewTypedAuthorityShape -Text $own } catch { $shape = $null }
    if ($null -ne $shape) { $turnKind = [string]$shape.Kind }
    elseif ($null -ne (Get-SpecrewStopAnswerShape -Text $own)) { $turnKind = 'stop-answer' }
    elseif ((Get-Command Test-SpecrewHumanVerdictToken -ErrorAction SilentlyContinue) -and [bool](Test-SpecrewHumanVerdictToken -Text $own).IsApproval) { $turnKind = 'boundary-verdict' }
    # The record's kind.
    $factType = [string](& $get $Record 'fact_type')
    $recordKinds = switch -CaseSensitive ($factType) {
        'allowance-reset-approval' { @('allowance-reset') }
        'review-pause-decision' { @('pause-decision') }
        'review-stop-answer' { @('stop-answer', 'pause-decision') }
        'review-signoff-partial-override' { @('partial-review-signoff') }
        'coverage-deferral' { @('coverage-deferral') }
        'workshop-repair' { @('workshop-repair') }
        default {
            if (-not [string]::IsNullOrWhiteSpace([string](& $get $Record 'to_boundary'))) { @('boundary-verdict') }
            elseif (-not [string]::IsNullOrWhiteSpace([string](& $get $Record 'proposal_id'))) { @('workshop-repair') }
            else { @() }
        }
    }
    # A workshop record keeps the reply's hash, not its text (a workshop reply is any text, so it has no act kind to match).
    $recordHash = ([string](& $get $Record 'response_hash')).Trim().ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace([string](& $get $Record 'verdict_text')) -and -not [string]::IsNullOrWhiteSpace($recordHash) -and
        ($factType -ceq '' -or $factType -ceq 'workshop-repair')) {
        if (@($recordKinds).Count -gt 0 -and @($recordKinds) -cnotcontains $turnKind) { return $false }
        $sha = { param([string]$t) ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($t)))).ToLowerInvariant() }
        foreach ($candidate in @($turnText, $turnText.Trim(), $own, $own.Trim())) { if ((& $sha $candidate) -ceq $recordHash) { return $true } }
        return $false
    }
    $answer = [string](& $get $Record 'answer')
    if ($factType -ceq 'review-stop-answer' -and $answer -ceq 'judgment') { return $true }
    if (@($recordKinds).Count -gt 0 -and @($recordKinds) -cnotcontains $turnKind) { return $false }
    $recordText = & $norm (& $get $Record 'verdict_text')
    if ([string]::IsNullOrWhiteSpace($recordText)) { return $false }
    foreach ($said in @((& $norm $own), (& $norm $turnText))) {
        if ($said -ceq $recordText) { return $true }
        if ($said.StartsWith($recordText + ' ') -or $said.StartsWith($recordText + '-')) { return $true }
    }
    return $false
}

function Register-SpecrewExhaustedTurn {
    # Record that this turn has minted. Append-only: the ledger is history, and history that can be
    # rewritten is not a control.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][AllowEmptyString()][string]$TurnId,
        [AllowEmptyString()][AllowNull()][string]$HostKind,
        [AllowEmptyString()][AllowNull()][string]$SourceEvent,
        [AllowEmptyString()][AllowNull()][string]$MintedWriters,
        [AllowEmptyString()][AllowNull()][string]$ContentHash,
        # Co-review round 1 (iteration 002): which session reserved it, and `message-id` when the key is the host's
        # message ID, so the turn end can tell history (no identity) from a record made under the current key.
        [AllowEmptyString()][AllowNull()][string]$SessionId,
        [AllowEmptyString()][AllowNull()][string]$Identity,
        # Feature 203 T004 (FR-022): the dispatcher's origin for a prompt (typed-user | host-injected | unknown), so the
        # reservation is the host's record of that message for Read-SpecrewCitedTypedTurn. Empty from the turn end.
        [AllowEmptyString()][AllowNull()][string]$TurnOrigin,
        # Co-review round 8 (T004): the id the prompt hook gave this prompt event and printed in its output, which Claude
        # records under the message's own transcript record. It is how the turn end finds which message this row is.
        [AllowEmptyString()][AllowNull()][string]$PromptEvent,
        # Feature 203 T013 (B5F-066; maintainer ruling 2026-11-12): where the message's transcript record will be. The prompt
        # hook runs before the host writes it, so the check of who sent the message runs when an authorization is used
        # (Resolve-SpecrewAuthorizationSender), and finds the record by these.
        [AllowEmptyString()][AllowNull()][string]$TranscriptPath,
        [AllowEmptyString()][AllowNull()][string]$MessageId,
        [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o'))
    )
    if ([string]::IsNullOrWhiteSpace($TurnId)) { return $false }
    $path = Get-SpecrewExhaustedTurnLedgerPath -ProjectRoot $ProjectRoot
    try {
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path)) | Out-Null
        $entry = [pscustomobject][ordered]@{
            schema_version = '1.0'; fact_type = 'typed-turn-exhausted'; turn_id = [string]$TurnId
            content_hash = [string]$ContentHash
            host_kind = [string]$HostKind; source_event = [string]$SourceEvent
            minted = [string]$MintedWriters; session_id = [string]$SessionId; identity = [string]$Identity; observed_at = $NowUtc
        }
        if (-not [string]::IsNullOrWhiteSpace($TurnOrigin)) { $entry | Add-Member -NotePropertyName turn_origin -NotePropertyValue ([string]$TurnOrigin).Trim() }
        if (-not [string]::IsNullOrWhiteSpace($PromptEvent)) { $entry | Add-Member -NotePropertyName prompt_event -NotePropertyValue ([string]$PromptEvent).Trim() }
        if (-not [string]::IsNullOrWhiteSpace($TranscriptPath)) { $entry | Add-Member -NotePropertyName transcript_path -NotePropertyValue ([string]$TranscriptPath).Trim() }
        if (-not [string]::IsNullOrWhiteSpace($MessageId)) { $entry | Add-Member -NotePropertyName message_id -NotePropertyValue ([string]$MessageId).Trim() }
        # -ErrorAction Stop, and it is load-bearing. Add-Content raises a NON-TERMINATING error, so a
        # plain try/catch around it never fires: the append failed, the catch was skipped, and this
        # returned $true. A reservation that reports success it did not achieve is precisely the
        # failure the reservation exists to prevent, and it was found by the case that locks the ledger.
        $line = ($entry | ConvertTo-Json -Compress -Depth 6)
        # Feature 203 T004 (measured 2026-11-04, tests/unit/position-key-identity.Tests.ps1): TWO HOOKS AT ONCE QUEUE, THEY
        # DO NOT FAIL. One message reaching two hook registrations together (Copilot's shape, and Cursor's if it also runs
        # the Claude Code hooks) appended to this ledger in the same instant; the second append or read-back met a sharing
        # violation, this returned $false, and that message recorded nothing without a word. A sharing violation is
        # retried for up to three seconds; any other failure still refuses, as before.
        $deadline = [DateTime]::UtcNow.AddSeconds(3)
        while ($true) {
            try { Add-Content -LiteralPath $path -Value $line -Encoding UTF8 -ErrorAction Stop; break }
            catch {
                if (-not ($_.Exception -is [IO.IOException]) -or [DateTime]::UtcNow -gt $deadline) { throw }
                Start-Sleep -Milliseconds 25
            }
        }
        # And READ IT BACK, because "the write did not throw" is not "the record is there" - the same
        # postcondition rule the round-approval and allowance-reset consumptions were corrected to.
        $written = $null
        while ($null -eq $written) {
            try { $written = [IO.File]::ReadAllLines($path) }
            catch [IO.IOException] {
                if ([DateTime]::UtcNow -gt $deadline.AddSeconds(2)) { throw }
                Start-Sleep -Milliseconds 25
            }
        }
        $confirmed = $false
        foreach ($writtenLine in $written) {
            if ([string]$writtenLine -ceq [string]$line) { $confirmed = $true; break }
        }
        return $confirmed
    }
    catch { return $false }
}

function ConvertTo-SpecrewAuthorityInstant {
    # W60 / round-19 walk (DRIFT-199-I001-129): AN INSTANT IS NOT A RENDERED STRING.
    #
    # Found by the round-18 double-spend block refusing the maintainer's own fresh approval. Both
    # timestamps come back from ConvertFrom-Json as [DateTime] objects, and PowerShell's [string]
    # cast renders a Kind=Utc value as a bare UTC clock while rendering a value parsed from a
    # `+00:00` offset in LOCAL time. Re-parsing both then assumed local, so the two instants were
    # compared in DIFFERENT FRAMES - skewed by the machine's offset, which on this machine turned
    # "the round ran 24 minutes BEFORE you approved" into "after". A units mismatch, in the
    # authority layer, reachable only outside UTC.
    #
    # Everything that compares stored times goes through this: objects keep their own instant, and
    # only genuine strings are parsed - offset-bearing or Z-suffixed round-trip exactly, and a
    # naive string is read as UTC rather than silently as local, because the store writes UTC.
    [OutputType([object])]
    [CmdletBinding()]
    param([AllowNull()][object]$Value)
    if ($null -eq $Value) { return $null }
    if ($Value -is [DateTimeOffset]) { return $Value }
    if ($Value -is [DateTime]) {
        $dt = [DateTime]$Value
        if ($dt.Kind -eq [DateTimeKind]::Unspecified) { $dt = [DateTime]::SpecifyKind($dt, [DateTimeKind]::Utc) }
        return [DateTimeOffset]::new($dt)
    }
    $text = ([string]$Value).Trim()
    if ([string]::IsNullOrWhiteSpace($text)) { return $null }
    $parsed = [DateTimeOffset]::MinValue
    if ([DateTimeOffset]::TryParse($text, [Globalization.CultureInfo]::InvariantCulture,
            ([Globalization.DateTimeStyles]::RoundtripKind -bor [Globalization.DateTimeStyles]::AssumeUniversal), [ref]$parsed)) {
        return $parsed
    }
    return $null
}

function Get-SpecrewPauseDecisionRoot {
    param([Parameter(Mandatory)][string]$ProjectRoot)
    return Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/review/pause-decision'
}

function Get-SpecrewPendingPauseIdentity {
    # W63 / round-21 finding (DRIFT-199-I001-132): which pause is waiting for an answer right now.
    # Read from the store's own published fact (campaigns/<id>/runs/<run>/pending-pause.json) so a
    # captured decision can be BOUND to the round it answers. Returns $null when nothing is pending -
    # which is itself the answer: a decision typed against no pause authorizes no pause.
    #
    # W70 / round-27 finding: SCOPED TO THE CAMPAIGN BEING ANSWERED. W68 excluded ANSWERED pauses,
    # which fixed the reported wedge and left the other half standing: with two campaigns each holding
    # an unanswered pause, the human answering the active feature was bound to whichever campaign
    # paused most recently, the CLI rejected it for the run actually waiting, and retyping repeated the
    # binding. I called scoping secondary hardening at the time; it was the same wedge through the door
    # left open. Fail-open on SCOPE ALONE - a caller with no campaign to name keeps the project-wide
    # behaviour, because refusing them would wedge every caller that cannot supply one.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [AllowEmptyString()][AllowNull()][string]$CampaignId
    )
    $campaignsRoot = Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/review/authority/campaigns'
    if (-not (Test-Path -LiteralPath $campaignsRoot -PathType Container)) { return $null }
    # W71 / round-28 finding: SELF-SCOPE, because the production writer has no campaign to pass.
    #
    # W70 added -CampaignId and the test exercised the helper with it. The writer calls this with
    # ProjectRoot alone, so the fix never reached the path that uses it - the tenth instance of a test
    # proving the thing added rather than the path that reaches it. Rather than plumb a campaign
    # through a router that has no idea what one is, the helper resolves the active feature itself and
    # prefers campaigns belonging to it. Explicit -CampaignId still wins.
    #
    # Fail-open on SCOPE ALONE: if no feature resolves, every campaign stays eligible, which is the
    # pre-W70 behaviour minus answered pauses.
    if ([string]::IsNullOrWhiteSpace($CampaignId) -and (Get-Command Resolve-SpecrewBranchFeatureRef -ErrorAction SilentlyContinue)) {
        $activeFeature = ''
        try { $activeFeature = [string](Resolve-SpecrewBranchFeatureRef -ProjectRoot $ProjectRoot) } catch { $activeFeature = '' }
        if (-not [string]::IsNullOrWhiteSpace($activeFeature)) { $script:SpecrewPauseScopeFeature = $activeFeature }
        else { $script:SpecrewPauseScopeFeature = '' }
    }
    else { $script:SpecrewPauseScopeFeature = '' }
    $newest = $null
    $newestAt = [DateTimeOffset]::MinValue
    try {
        foreach ($pauseFile in @(Get-ChildItem -LiteralPath $campaignsRoot -Filter 'pending-pause.json' -File -Recurse -ErrorAction SilentlyContinue)) {
            $pause = $null
            try { $pause = Get-Content -LiteralPath $pauseFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12 -ErrorAction Stop } catch { continue }
            if ($null -eq $pause -or -not $pause.PSObject.Properties['run_id']) { continue }
            # W68 / round-25 finding (DRIFT-199-I001-141): AN ANSWERED PAUSE IS HISTORY.
            #
            # This took the newest pause in the whole project without excluding ones that already carry
            # a sibling decision - which the canonical Get-ReviewCampaignPendingPause reader DOES
            # exclude. Two readers of one question, for the fourth time in this feature. With an older
            # unanswered campaign and a newer answered one, a typed `stop the review here` bound to the
            # closed run, the CLI rejected it for the run actually waiting, and retyping repeated the
            # same wrong binding - the human answering forever while nothing moved.
            #
            # Scoped by DIRECTORY rather than by re-reading the store, because this is the bootstrap
            # module and it must not take a dependency on the review-authority reader to answer a
            # question about a file sitting next to the one it already opened.
            if ([IO.File]::Exists([IO.Path]::Combine($pauseFile.DirectoryName, 'pause-decision.json'))) { continue }
            # Feature 203 T008 step (iii): a stop the engine reads as closed is not waiting either - (a) after an allowance
            # reset, (d) after a reviewer was allowed (Get-ReviewCampaignOpenStop, read here from the files beside it).
            if ($pause.PSObject.Properties['stop_kind'] -and (Test-SpecrewStopClosedBySibling -Pause $pause -RunDirectory $pauseFile.DirectoryName)) { continue }
            $pauseCampaign = if ($pause.PSObject.Properties['campaign_id']) { [string]$pause.campaign_id } else { '' }
            if (-not [string]::IsNullOrWhiteSpace($CampaignId)) {
                if ($pauseCampaign -cne [string]$CampaignId) { continue }
            }
            elseif (-not [string]::IsNullOrWhiteSpace($script:SpecrewPauseScopeFeature)) {
                if ($pauseCampaign -notmatch [regex]::Escape([string]$script:SpecrewPauseScopeFeature)) { continue }
            }
            $observed = $null
            if ($pause.PSObject.Properties['observed_at']) { $observed = ConvertTo-SpecrewAuthorityInstant -Value $pause.observed_at }
            if ($null -eq $observed) { $observed = [DateTimeOffset]::MinValue }
            if ($null -eq $newest -or $observed -gt $newestAt) { $newest = $pause; $newestAt = $observed }
        }
    }
    catch { return $null }
    if ($null -eq $newest) { return $null }
    return [pscustomobject]@{
        campaign_id = $(if ($newest.PSObject.Properties['campaign_id']) { [string]$newest.campaign_id } else { '' })
        run_id = [string]$newest.run_id
        target_digest = $(if ($newest.PSObject.Properties['target_digest']) { [string]$newest.target_digest } else { '' })
        stop_kind = $(if ($newest.PSObject.Properties['stop_kind']) { [string]$newest.stop_kind } else { '' })
    }
}

function Test-SpecrewStopClosedBySibling {
    # Feature 203 T008 step (iii): whether the campaign closed this stop without a pause decision - stop (a) by an allowance
    # reset recorded after it, stop (d) by a reviewer allowed after it. The bootstrap module reads the campaign's files
    # directly rather than loading the review engine for one question (the same rule as the answered check above).
    [OutputType([bool])]
    param([Parameter(Mandatory)]$Pause, [Parameter(Mandatory)][string]$RunDirectory)
    $kind = [string]$Pause.stop_kind
    $folder = switch ($kind) { 'a-budget-spent' { 'budget-resets' } 'd-host-outside-order' { 'allowed-reviewers' } default { '' } }
    if ([string]::IsNullOrWhiteSpace($folder)) { return $false }
    $pausedAt = if ($Pause.PSObject.Properties['observed_at']) { ConvertTo-SpecrewAuthorityInstant -Value $Pause.observed_at } else { $null }
    if ($null -eq $pausedAt) { return $false }
    $campaignDirectory = [IO.Path]::GetDirectoryName([IO.Path]::GetDirectoryName($RunDirectory))
    $siblings = [IO.Path]::Combine($campaignDirectory, $folder)
    if (-not [IO.Directory]::Exists($siblings)) { return $false }
    foreach ($file in [IO.Directory]::EnumerateFiles($siblings, '*.json')) {
        try {
            $fact = Get-Content -LiteralPath $file -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop
            $at = if ($fact.PSObject.Properties['observed_at']) { ConvertTo-SpecrewAuthorityInstant -Value $fact.observed_at } else { $null }
            if ($null -ne $at -and $at -gt $pausedAt) { return $true }
        }
        catch { continue }
    }
    return $false
}

function Get-SpecrewStopAnswerRoot {
    param([Parameter(Mandatory)][string]$ProjectRoot)
    return Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/review/stop-answer'
}

function Write-SpecrewStopAnswerAuthorization {
    # SPECREW-AUTHORITY-CONTROL: stop-answer
    # Feature 203 T008 step (iii) (FR-006, FR-011; DRIFT-052 item 5): the human's typed stop line - `allow reviewer <host>`,
    # `defer finding <id> to <destination>`, `drop finding <id>`, `fix finding <id>`, or free text at a judgment stop -
    # captured from the typed turn and bound to the stop that was open when they typed it. The next review launch lands it
    # as the campaign's own fact (Invoke-ReviewCampaignStopAnswerLanding) and spends it. A line typed with no stop open
    # binds to nothing and records nothing.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$Response,
        [AllowNull()][string]$HostKind,
        [AllowNull()][string]$SourceEvent,
        [AllowNull()]$Act,
        [AllowNull()][string]$TurnIdentity,
        [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o'))
    )
    $event = ConvertTo-SpecrewHumanAuthoritySourceEvent -SourceEvent $SourceEvent
    $evidenceSource = 'hook-captured-user-prompt'
    if ($null -eq $event) {
        if (([string]$SourceEvent).Trim().ToLowerInvariant() -in @('stop', 'stop-transcript')) { $event = 'Stop'; $evidenceSource = 'hook-captured-from-transcript' }
        else { return $null }
    }
    $pending = Get-SpecrewPendingPauseIdentity -ProjectRoot $ProjectRoot
    if ($null -eq $pending -or [string]::IsNullOrWhiteSpace([string]$pending.run_id) -or [string]::IsNullOrWhiteSpace([string]$pending.stop_kind)) { return $null }
    $text = ([string]$Response).Trim()
    $answer = ''; $finding = ''; $argument = ''
    $shape = Get-SpecrewStopAnswerShape -Text $text
    if ($null -ne $shape) { $answer = [string]$shape.Answer; $finding = [string]$shape.Finding; $argument = [string]$shape.Argument }
    elseif ($null -ne $Act -and [string]$Act.Answer -ceq 'judgment' -and [string]$pending.stop_kind -ceq 'c-judgment') { $answer = 'judgment' }
    if ([string]::IsNullOrWhiteSpace($answer)) { return $null }
    if ($answer -ceq 'defer' -and [string]::IsNullOrWhiteSpace($argument)) { return $null }
    $hash = Get-SpecrewHumanAuthorityHash -Text $text
    $fact = [pscustomobject][ordered]@{
        schema_version = '1.0'; fact_type = 'review-stop-answer'; authority_kind = 'human'; authorized_by = 'unattributed-human'
        answer = $answer; finding = $finding; argument = $argument; verdict_text = $text; response_hash = $hash
        evidence_source = $evidenceSource; source_event = $event; host_kind = [string]$HostKind; turn_identity = [string]$TurnIdentity
        campaign_id = [string]$pending.campaign_id; run_id = [string]$pending.run_id; stop_kind = [string]$pending.stop_kind
        observed_at = $NowUtc; spent_at = $null; authorization_ref = $null
    }
    $directory = Join-Path (Get-SpecrewStopAnswerRoot -ProjectRoot $ProjectRoot) ([string]$pending.run_id)
    [IO.Directory]::CreateDirectory($directory) | Out-Null
    $path = Join-Path $directory ('{0}-{1}.json' -f $answer, $hash.Substring(0, 16))
    # Iteration review round A finding 2 (second defect): the record already stored for this text is returned only when it is
    # this same turn's, unspent (a retried capture of one message). Another turn's record - one refused because a scheduled
    # prompt sent it, one already spent, or another message - is not this line: this turn's line is recorded beside it.
    $readExisting = { param($p) try { Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop } catch { $null } }
    $isThisTurns = { param($e) $null -ne $e -and [string]$e.turn_identity -ceq [string]$TurnIdentity -and [string]::IsNullOrWhiteSpace([string]$e.spent_at) }
    if ([IO.File]::Exists($path)) {
        $existing = & $readExisting $path
        if (& $isThisTurns $existing) { return $existing }
        $turnTag = (Get-SpecrewHumanAuthorityHash -Text $(if ([string]::IsNullOrWhiteSpace($TurnIdentity)) { $NowUtc } else { [string]$TurnIdentity })).Substring(0, 12)
        $path = Join-Path $directory ('{0}-{1}-{2}.json' -f $answer, $hash.Substring(0, 16), $turnTag)
        if ([IO.File]::Exists($path)) {
            $existing = & $readExisting $path
            if (& $isThisTurns $existing) { return $existing }
        }
    }
    $json = $fact | ConvertTo-Json -Depth 8
    if (Get-Command Write-SpecrewFileAtomic -ErrorAction SilentlyContinue) { Write-SpecrewFileAtomic -Path $path -Content $json }
    else { [IO.File]::WriteAllText($path, $json, [Text.UTF8Encoding]::new($false)) }
    try { ($fact | ConvertTo-Json -Compress -Depth 8) | Add-Content -LiteralPath (Join-Path (Get-SpecrewStopAnswerRoot -ProjectRoot $ProjectRoot) 'captures.jsonl') -Encoding UTF8 } catch { $null = $_ }
    return $fact
}

function Get-SpecrewStopAnswerAuthorizations {
    # The unspent typed stop lines bound to one stop, oldest first, each with its path. A record whose text does not hash to
    # its recorded hash, or that is not the human's, is not authority and is skipped.
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ProjectRoot, [Parameter(Mandatory)][string]$RunId)
    $directory = Join-Path (Get-SpecrewStopAnswerRoot -ProjectRoot $ProjectRoot) $RunId
    if (-not [IO.Directory]::Exists($directory)) { return @() }
    $answers = foreach ($file in [IO.Directory]::EnumerateFiles($directory, '*.json')) {
        $fact = $null
        try { $fact = Get-Content -LiteralPath $file -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop } catch { continue }
        if ($null -eq $fact -or [string]$fact.fact_type -cne 'review-stop-answer' -or [string]$fact.authority_kind -cne 'human') { continue }
        if ([string]$fact.response_hash -cne (Get-SpecrewHumanAuthorityHash -Text ([string]$fact.verdict_text))) { continue }
        if ([string]$fact.run_id -cne $RunId) { continue }
        if (-not [string]::IsNullOrWhiteSpace([string]$fact.spent_at)) { continue }
        # Feature 203 T013 (B5F-066): used only when the human typed it.
        if (-not (Test-SpecrewAuthorizationRecordSender -ProjectRoot $ProjectRoot -Record $fact -Purpose 'stop answer')) { continue }
        $fact | Add-Member -NotePropertyName path -NotePropertyValue $file -Force
        $fact
    }
    return @($answers | Sort-Object -Property { ConvertTo-SpecrewAuthorityInstant -Value $_.observed_at })
}

function Complete-SpecrewStopAnswerAuthorization {
    # One typed line, one landing: stamped spent with the fact it became, and read back.
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$AuthorizationRef, [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o')))
    $fact = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop
    $fact.PSObject.Properties.Remove('path')
    $fact | Add-Member -NotePropertyName spent_at -NotePropertyValue $NowUtc -Force
    $fact | Add-Member -NotePropertyName authorization_ref -NotePropertyValue $AuthorizationRef -Force
    $json = $fact | ConvertTo-Json -Depth 8
    if (Get-Command Write-SpecrewFileAtomic -ErrorAction SilentlyContinue) { Write-SpecrewFileAtomic -Path $Path -Content $json }
    else { [IO.File]::WriteAllText($Path, $json, [Text.UTF8Encoding]::new($false)) }
    $verified = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop
    return (-not [string]::IsNullOrWhiteSpace([string]$verified.spent_at))
}

function Test-SpecrewPauseDecisionPhrase {
    # W62 / round-20 finding (DRIFT-199-I001-131): EVERY PAUSE CHOICE CARRIES THE HUMAN.
    #
    # Choices 2 and 3 were exempt from the captured-approval gate because they spend no round - but
    # stopping here passes `AuthorizedBy='human'` into the landing, writes an identity-bound human
    # disposition, and can COMPLETE SIGN-OFF. So an agent invoking `--pause-choice 2` manufactured
    # the human authorization for the most consequential act in the lifecycle: the W44 hole, one
    # door down, on the door that matters most. These are the two typed decisions the W49 menu
    # already shows the human; now they are authority, captured like every other.
    #
    # Same conservative shape as the round-approval recognizer: the decision lives on its own line,
    # a closed tail admits instructions but not prose, and questions, deferrals, reversals, mentions
    # and machinery envelopes are not acts.
    [OutputType([pscustomobject])]
    param([AllowNull()][AllowEmptyString()][string]$Text)

    $r = [pscustomobject]@{ Matched = $false; Choice = $null; Phrase = $null }
    if ([string]::IsNullOrWhiteSpace($Text)) { return $r }
    $trimmed = $Text.Trim()
    if ($trimmed -match '(?is)^\s*<(?:hook_prompt\b|task-notification\b|turn_aborted\b|system-reminder\b|environment_context\b|command-name\b|local-command\b|bash-stdout\b)') { return $r }
    $lower = (Get-SpecrewAuthorityApprovalLine -Text $trimmed).ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($lower) -or $lower.EndsWith('?')) { return $r }

    $shapes = @(
        @{ Choice = 'stop-here'; Pattern = '^\s*(?:(?:yes|confirmed)\s*[,;:\-]\s*)?(?:(?:i|we)\s+)?(?:want\s+to\s+|would\s+like\s+to\s+)?stop\s+(?:the\s+)?review\s+here\b' }
        @{ Choice = 'abandon'; Pattern = '^\s*(?:(?:yes|confirmed)\s*[,;:\-]\s*)?(?:(?:i|we)\s+)?(?:want\s+to\s+|would\s+like\s+to\s+)?abandon\s+(?:this\s+)?review\s+campaign\b' }
    )
    foreach ($shape in $shapes) {
        $anchor = [regex]::Match($lower, [string]$shape.Pattern)
        if (-not $anchor.Success) { continue }
        if (Test-SpecrewAuthorityMessageContinues -Text $trimmed) { $r | Add-Member -NotePropertyName 'Reason' -NotePropertyValue 'multi-line-refused' -Force; return $r }
        $tail = $lower.Substring($anchor.Length)
        if (-not ([string]::IsNullOrWhiteSpace($tail) -or $tail -match '^\s*[-,.;:]')) { return $r }
        if (Test-SpecrewConditionalDeferralClause -Text $tail) { return $r }
        if ($lower -match '^\s*(?:do\s*not|never|not\s+yet|hold\s+off|wait)\b') { return $r }
        if ($tail -match "\b(?:do\s*not|don''t|dont|never|not\s+yet|no\s+longer|cancel|withdraw|revoke|rescind|retract|hold\s+off|stand\s+down|abort|scratch\s+that|never\s+mind|nevermind|actually\s+(?:stop|no|not)|disregard|ignore\s+that)\b") { return $r }
        $r.Matched = $true; $r.Choice = [string]$shape.Choice; $r.Phrase = $trimmed
        return $r
    }
    return $r
}

function Write-SpecrewPauseDecisionAuthorization {
    # SPECREW-AUTHORITY-CONTROL: pause-decision
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$Response,
        [AllowNull()][string]$HostKind,
        [AllowNull()][string]$SourceEvent,
        # Feature 203 T012 (FR-024, FR-041): the typed turn of the `stop the review here` line. The typed-act sink passes it to
        # every writer that declares it.
        [AllowNull()][AllowEmptyString()][string]$TurnIdentity = '',
        [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o'))
    )
    $event = ConvertTo-SpecrewHumanAuthoritySourceEvent -SourceEvent $SourceEvent
    $evidenceSource = 'hook-captured-user-prompt'
    if ($null -eq $event) {
        if (([string]$SourceEvent).Trim().ToLowerInvariant() -in @('stop', 'stop-transcript')) { $event = 'Stop'; $evidenceSource = 'hook-captured-from-transcript' }
        else { return $null }
    }
    $recognized = Test-SpecrewPauseDecisionPhrase -Text $Response
    if (-not [bool]$recognized.Matched) { return $null }
    # Round-21 finding (DRIFT-199-I001-132): A DECISION ANSWERS ONE PAUSE.
    #
    # The first cut recorded only the choice, so a phrase typed in an unrelated conversation - or
    # against a campaign closed weeks ago - became a standing project-wide capability an agent could
    # apply to whatever pause happened to be current. The capture now binds to the pause that was
    # PENDING when the human typed, and a decision bound to nothing answers nothing.
    $pending = Get-SpecrewPendingPauseIdentity -ProjectRoot $ProjectRoot
    $root = Get-SpecrewPauseDecisionRoot -ProjectRoot $ProjectRoot
    [IO.Directory]::CreateDirectory($root) | Out-Null
    $path = Join-Path $root (([string]$recognized.Choice) + '.json')
    $fact = [pscustomobject][ordered]@{
        schema_version = '1.0'; fact_type = 'review-pause-decision'; authority_kind = 'human'
        authorized_by = 'unattributed-human'; choice = [string]$recognized.Choice
        verdict_text = [string]$recognized.Phrase
        response_hash = Get-SpecrewHumanAuthorityHash -Text ([string]$recognized.Phrase)
        evidence_source = $evidenceSource; source_event = $event; host_kind = [string]$HostKind
        campaign_id = $(if ($null -ne $pending) { [string]$pending.campaign_id } else { '' })
        run_id = $(if ($null -ne $pending) { [string]$pending.run_id } else { '' })
        target_digest = $(if ($null -ne $pending) { [string]$pending.target_digest } else { '' })
        turn_identity = $(if ([string]::IsNullOrWhiteSpace($TurnIdentity)) { '' } else { $TurnIdentity.Trim() })
        observed_at = $NowUtc; spent_at = $null; authorization_ref = $null
    }
    if ([IO.File]::Exists($path)) {
        $existing = $null
        try { $existing = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop } catch { $existing = $null }
        # Same act = same phrase AND same pause. Round-21: without the second half, a phrase typed
        # once while nothing was pending was returned forever - so the human re-typing it against a
        # REAL pause got their old unbound record back and the decision could never bind.
        if ($null -ne $existing -and $existing.PSObject.Properties['spent_at'] -and
            [string]::IsNullOrWhiteSpace([string]$existing.spent_at) -and
            [string]$existing.response_hash -ceq [string]$fact.response_hash -and
            [string]$(if ($existing.PSObject.Properties['run_id']) { $existing.run_id } else { '' }) -ceq [string]$fact.run_id -and
            -not (Test-SpecrewTypedActReplacesRecord -Existing $existing -Fact $fact)) { return $existing }
    }
    $json = $fact | ConvertTo-Json -Depth 8
    if (Get-Command Write-SpecrewFileAtomic -ErrorAction SilentlyContinue) { Write-SpecrewFileAtomic -Path $path -Content $json }
    else { [IO.File]::WriteAllText($path, $json, [Text.UTF8Encoding]::new($false)) }
    try { ($fact | ConvertTo-Json -Compress -Depth 8) | Add-Content -LiteralPath (Join-Path $root 'captures.jsonl') -Encoding UTF8 } catch { $null = $_ }
    return $fact
}

function Get-SpecrewPauseDecisionAuthorization {
    # The unspent captured decision for ONE choice, or $null. A decision for stopping here never
    # authorizes abandoning the campaign: they are different acts with different consequences.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][ValidateSet('stop-here', 'abandon')][string]$Choice,
        # Round-21 (DRIFT-199-I001-132): the run this decision must answer. A decision bound to a
        # different round - or to no pause at all - is not authority for THIS one. Omitted only by
        # readers that are reporting rather than authorizing.
        [AllowNull()][string]$RunId
    )
    $path = Join-Path (Get-SpecrewPauseDecisionRoot -ProjectRoot $ProjectRoot) ($Choice + '.json')
    if (-not [IO.File]::Exists($path)) { return $null }
    $item = Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
    if ($null -eq $item -or $item.Length -le 0 -or $item.Length -gt 65536) { return $null }
    $fact = $null
    try { $fact = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop } catch { return $null }
    foreach ($name in @('schema_version', 'fact_type', 'authority_kind', 'choice', 'verdict_text', 'response_hash', 'observed_at')) {
        $property = $fact.PSObject.Properties[$name]
        if (-not $property -or [string]::IsNullOrWhiteSpace([string]$property.Value)) { return $null }
    }
    if ([string]$fact.fact_type -cne 'review-pause-decision' -or [string]$fact.authority_kind -cne 'human') { return $null }
    if ([string]$fact.choice -cne $Choice) { return $null }
    if ([string]$fact.response_hash -cne (Get-SpecrewHumanAuthorityHash -Text ([string]$fact.verdict_text))) { return $null }
    $recognized = Test-SpecrewPauseDecisionPhrase -Text ([string]$fact.verdict_text)
    if (-not [bool]$recognized.Matched -or [string]$recognized.Choice -cne $Choice) { return $null }
    if ($fact.PSObject.Properties['spent_at'] -and -not [string]::IsNullOrWhiteSpace([string]$fact.spent_at)) { return $null }
    if (-not [string]::IsNullOrWhiteSpace($RunId)) {
        $boundRun = if ($fact.PSObject.Properties['run_id']) { [string]$fact.run_id } else { '' }
        # Unbound (typed when no pause was pending) or bound elsewhere: not authority for this round.
        if ([string]::IsNullOrWhiteSpace($boundRun) -or $boundRun -cne $RunId) { return $null }
    }
    # Feature 203 T013 (B5F-066): used only when the human typed it.
    if (-not (Test-SpecrewAuthorizationRecordSender -ProjectRoot $ProjectRoot -Record $fact -Purpose 'decision to stop the review')) { return $null }
    return $fact
}

function Complete-SpecrewPauseDecisionAuthorization {
    # One decision, one landing - stamped spent with the reference it became, read back like every
    # other consumption in this store.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][ValidateSet('stop-here', 'abandon')][string]$Choice,
        [Parameter(Mandatory)][string]$AuthorizationRef,
        [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o'))
    )
    $path = Join-Path (Get-SpecrewPauseDecisionRoot -ProjectRoot $ProjectRoot) ($Choice + '.json')
    if (-not [IO.File]::Exists($path)) { return [pscustomobject]@{ consumed = $false; fact = $null; reason = 'no-pending-decision' } }
    $fact = $null
    try { $fact = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop }
    catch { return [pscustomobject]@{ consumed = $false; fact = $null; reason = 'pending-decision-unreadable' } }
    if ($null -eq $fact) { return [pscustomobject]@{ consumed = $false; fact = $null; reason = 'pending-decision-empty' } }
    $fact | Add-Member -NotePropertyName 'spent_at' -NotePropertyValue $NowUtc -Force
    $fact | Add-Member -NotePropertyName 'authorization_ref' -NotePropertyValue ([string]$AuthorizationRef) -Force
    $json = $fact | ConvertTo-Json -Depth 8
    try {
        if (Get-Command Write-SpecrewFileAtomic -ErrorAction SilentlyContinue) { Write-SpecrewFileAtomic -Path $path -Content $json }
        else { [IO.File]::WriteAllText($path, $json, [Text.UTF8Encoding]::new($false)) }
    }
    catch { return [pscustomobject]@{ consumed = $false; fact = $null; reason = ('write-failed:' + $_.Exception.Message) } }
    $verified = $null
    try { $verified = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop }
    catch { return [pscustomobject]@{ consumed = $false; fact = $null; reason = 'readback-failed' } }
    if ($null -eq $verified -or [string]::IsNullOrWhiteSpace([string]$verified.spent_at)) {
        return [pscustomobject]@{ consumed = $false; fact = $null; reason = 'stamp-not-durable' }
    }
    return [pscustomobject]@{ consumed = $true; fact = $verified; reason = 'consumed' }
}

function Test-SpecrewApprovalWithdrawalPhrase {
    # W57 / round-16 finding (DRIFT-199-I001-126): the CLI's undelivered-round refusal tells the
    # human they may "withdraw the approval (say so, and nothing further runs)" - and nothing
    # implemented it, so the next invocation loaded the same unspent capture and invoked another
    # reviewer. A promise made in a refusal is a contract; this is the recognizer that keeps it.
    #
    # Same conservative shape as every recognizer here - leading-anchored, so a mention or a
    # question is not an act - but the floor cuts the OTHER way for a withdrawal: it REMOVES
    # authority, so a false positive costs a retype while a false negative runs a review the human
    # said to stop. Hence the deliberately generous verb set and no closed-tail requirement.
    [OutputType([pscustomobject])]
    param([AllowNull()][AllowEmptyString()][string]$Text)
    $r = [pscustomobject]@{ Matched = $false; Phrase = $null }
    if ([string]::IsNullOrWhiteSpace($Text)) { return $r }
    $trimmed = $Text.Trim()
    if ($trimmed -match '(?is)^\s*<(?:hook_prompt\b|task-notification\b|turn_aborted\b|system-reminder\b|environment_context\b|command-name\b|local-command\b|bash-stdout\b)') { return $r }
    $lower = (Get-SpecrewAuthorityApprovalLine -Text $trimmed).ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($lower) -or $lower.EndsWith('?')) { return $r }
    if ($lower -notmatch '^\s*(?:(?:i|we)\s+)?(?:want\s+to\s+|would\s+like\s+to\s+)?(?:withdraw|revoke|rescind|retract|cancel)\b') { return $r }
    if ($lower -notmatch '\b(approval|approve[d]?|round|authorization|authorisation)\b') { return $r }
    # PRED-BETA4-022's one-line rule is NOT applied here, on purpose: it bounds what MINTS. A withdrawal
    # removes authority, and this recognizer's floor cuts the other way - a false negative runs a review
    # the human said to stop - so a withdrawal typed above a block of notes still withdraws.
    $r.Matched = $true; $r.Phrase = $trimmed
    return $r
}

# ===================================================================================================
# W50 (2026-08-23, maintainer ruling): THE ALLOWANCE METERS ATTEMPTS; THE HUMAN AUTHORIZES DELIVERIES.
#
# A captured `approved for review round` is an ENTITLEMENT to one DELIVERED review, and it survives
# system failure:
#   - failure BEFORE invocation (crash, unresolvable feature, no slot): nothing is consumed - not the
#     capture, not a slot.
#   - INVOKED but NOT DELIVERED (infrastructure failure; a partial that examined nothing due to a
#     harness fault): the token cost is recorded as spent-without-delivery - the cost is real and must
#     stay visible - but the entitlement stands, and the system gets ONE bounded automatic retry
#     (different host or more time, its choice, recorded) before it may ask the human anything.
#   - DELIVERED (complete; or a partial the human explicitly accepts): the entitlement is consumed.
#     Only here.
#
# The bound matters: unlimited retry on "failure" is a token-burn hole. One automatic retry, then a
# plain-language ask naming what failed, what it cost, and what is requested - never a re-approval of
# the same decision.
# ===================================================================================================

# ===================================================================================================
# ALLOWANCE RESET IS AN AUTHORITY ACT (W50 rider): it replenishes spend authority, so a bare agent
# invocation is the W44 gap one door down. Same capture pattern: the human types
# `approved for allowance reset`; the hooks capture it; the agent runs the command carrying it.
# A human at their own terminal stays self-evident.
# ===================================================================================================

function Get-SpecrewAllowanceResetRoot {
    param([Parameter(Mandatory)][string]$ProjectRoot)
    return Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/review/allowance-reset'
}

function Test-SpecrewAllowanceResetPhrase {
    [OutputType([pscustomobject])]
    param([AllowNull()][AllowEmptyString()][string]$Text)
    $r = [pscustomobject]@{ Matched = $false; Phrase = $null }
    if ([string]::IsNullOrWhiteSpace($Text)) { return $r }
    $trimmed = $Text.Trim()
    if ($trimmed -match '(?is)^\s*<(?:hook_prompt\b|task-notification\b|turn_aborted\b|system-reminder\b|environment_context\b|command-name\b|local-command\b|bash-stdout\b)') { return $r }
    # W56 (DRIFT-199-I001-125): the approval's own line - the reviewer named this sibling site by
    # line number, and rule 6 requires the same treatment in every copy of the rule.
    $lower = (Get-SpecrewAuthorityApprovalLine -Text $trimmed).ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($lower)) { return $r }
    if ($lower.EndsWith('?')) { return $r }
    $anchor = [regex]::Match($lower, '^\s*(?:(?:yes|confirmed)\s*[,;:\-]\s*)?(?:(?:i|we)\s+)?approv(?:e|ed)\s+(?:for\s+)?(?:an\s+|the\s+)?allowance\s+reset\b')
    if (-not $anchor.Success) { return $r }
    if (Test-SpecrewAuthorityMessageContinues -Text $trimmed) { $r | Add-Member -NotePropertyName 'Reason' -NotePropertyValue 'multi-line-refused' -Force; return $r }
    $tail = $lower.Substring($anchor.Length)
    if (-not ([string]::IsNullOrWhiteSpace($tail) -or $tail -match '^\s*[-,.;:]')) { return $r }
    # Round-14 finding (DRIFT-199-I001-123): the whole TAIL, not element zero of a delimiter split -
    # which is empty by construction - or "approved for allowance reset, after we verify the
    # failures" replenishes spend authority before the stated condition holds.
    if (Test-SpecrewConditionalDeferralClause -Text $tail) { return $r }
    if ($lower -match '^\s*(?:do\s*not|never|not\s+yet|hold\s+off|wait|stop)\b') { return $r }
    # Round-16 (DRIFT-199-I001-126): a reversal AFTER the anchor is the same refusal as one before it.
    if ($tail -match '\b(?:do\s*not|don''t|dont|never|not\s+yet|no\s+longer|cancel|withdraw|revoke|rescind|retract|hold\s+off|stand\s+down|stop|abort|scratch\s+that|never\s+mind|nevermind|actually\s+(?:stop|no|not)|disregard|ignore\s+that)\b') { return $r }
    $r.Matched = $true; $r.Phrase = $trimmed
    return $r
}

# Co-review round 12 (T004, finding 2): the round slot's rule, for the reset's slot. The capture and the consumption each
# read pending-allowance-reset.json, decide, and write it back; unserialized, a consumption that read reset A wrote its
# spent A over a newer B the prompt hook had just saved, and B's turn was already reserved, so nothing restored it.
$script:SpecrewAllowanceResetSlotLockDepth = 0

function Invoke-SpecrewAllowanceResetSlotLocked {
    # Runs Body holding the reset slot's lock file open exclusively; throws 'allowance-reset-slot-busy' when it cannot take it.
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][scriptblock]$Body,
        [int]$TimeoutSeconds = 15
    )
    if ($script:SpecrewAllowanceResetSlotLockDepth -gt 0) { return (& $Body) }
    $root = Get-SpecrewAllowanceResetRoot -ProjectRoot $ProjectRoot
    [IO.Directory]::CreateDirectory($root) | Out-Null
    $lockPath = Join-Path $root 'pending-allowance-reset.lock'
    $stream = $null
    $deadline = [DateTimeOffset]::UtcNow.AddSeconds($TimeoutSeconds)
    do {
        try { $stream = [IO.File]::Open($lockPath, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None) }
        catch {
            if ([DateTimeOffset]::UtcNow -ge $deadline) { throw 'allowance-reset-slot-busy' }
            Start-Sleep -Milliseconds 25
        }
    } until ($null -ne $stream)
    $script:SpecrewAllowanceResetSlotLockDepth++
    try { return (& $Body) }
    finally {
        $script:SpecrewAllowanceResetSlotLockDepth--
        $stream.Dispose()
    }
}

function Resolve-SpecrewActiveReviewCampaignId {
    # Feature 203 T012 (FR-041): the review campaign of the active iteration (start-context session_state), through the
    # review engine's one derivation (Get-ReviewCampaignIdForIteration), loaded the way the budget snapshot loads it when
    # the caller has not. '' when the session names no feature or iteration, or no engine can be loaded.
    [OutputType([string])]
    param([Parameter(Mandatory)][string]$ProjectRoot)
    try {
        $contextPath = Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/start-context.json'
        if (-not (Test-Path -LiteralPath $contextPath -PathType Leaf)) { return '' }
        $context = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 16 -ErrorAction Stop
        $session = if ($context.PSObject.Properties['session_state']) { $context.session_state } else { $null }
        if ($null -eq $session) { return '' }
        $feature = if ($session.PSObject.Properties['feature_ref']) { [string]$session.feature_ref } else { '' }
        $iteration = if ($session.PSObject.Properties['iteration_number']) { ([string]$session.iteration_number).Trim() } else { '' }
        if ([string]::IsNullOrWhiteSpace($feature) -or $iteration -notmatch '^\d+$') { return '' }
        if (-not (Get-Command Get-ReviewCampaignIdForIteration -ErrorAction SilentlyContinue) -and (Get-Command Get-SpecrewReviewEngineLoadPath -ErrorAction SilentlyContinue)) {
            $engine = Get-SpecrewReviewEngineLoadPath -ProjectRoot $ProjectRoot
            if (-not [string]::IsNullOrWhiteSpace([string]$engine)) { . $engine }
        }
        if (-not (Get-Command Get-ReviewCampaignIdForIteration -ErrorAction SilentlyContinue)) { return '' }
        return [string](Get-ReviewCampaignIdForIteration -FeatureId (Split-Path -Leaf $feature.Trim()) -IterationNumber ('{0:000}' -f [int]$iteration))
    }
    catch { return '' }
}

function Write-SpecrewAllowanceResetAuthorization {
    # SPECREW-AUTHORITY-CONTROL: allowance-reset
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$Response,
        [AllowNull()][string]$HostKind,
        [AllowNull()][string]$SourceEvent,
        # 203 T004 (FR-021): the typed act's identity; a different message supersedes an unspent reset, never folds.
        [AllowNull()][string]$TurnIdentity,
        [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o'))
    )
    # Co-review round 12: under the reset slot's lock (a busy slot throws, and the router reports the reset as not recorded).
    if ($script:SpecrewAllowanceResetSlotLockDepth -lt 1) {
        $bound = $PSBoundParameters
        return (Invoke-SpecrewAllowanceResetSlotLocked -ProjectRoot $ProjectRoot -Body { Write-SpecrewAllowanceResetAuthorization @bound })
    }
    $event = ConvertTo-SpecrewHumanAuthoritySourceEvent -SourceEvent $SourceEvent
    $evidenceSource = 'hook-captured-user-prompt'
    if ($null -eq $event) {
        if (([string]$SourceEvent).Trim().ToLowerInvariant() -in @('stop', 'stop-transcript')) { $event = 'Stop'; $evidenceSource = 'hook-captured-from-transcript' }
        else { return $null }
    }
    $recognized = Test-SpecrewAllowanceResetPhrase -Text $Response
    if (-not [bool]$recognized.Matched) { return $null }
    $root = Get-SpecrewAllowanceResetRoot -ProjectRoot $ProjectRoot
    [IO.Directory]::CreateDirectory($root) | Out-Null
    $path = Join-Path $root 'pending-allowance-reset.json'
    $fact = [pscustomobject][ordered]@{
        schema_version = '1.0'; fact_type = 'allowance-reset-approval'; authority_kind = 'human'
        authorized_by = 'unattributed-human'; verdict_text = [string]$recognized.Phrase
        response_hash = Get-SpecrewHumanAuthorityHash -Text ([string]$recognized.Phrase)
        evidence_source = $evidenceSource; source_event = $event; host_kind = [string]$HostKind
        observed_at = $NowUtc; spent_at = $null; turn_identity = [string]$TurnIdentity
        # Feature 203 T012 (FR-041): the review campaign whose budget the reset tops up.
        campaign_id = (Resolve-SpecrewActiveReviewCampaignId -ProjectRoot $ProjectRoot)
    }
    if ([IO.File]::Exists($path)) {
        $existing = $null
        try { $existing = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop } catch { $existing = $null }
        # 203 T004 (FR-021): with the act's identity, the same message is the same act and a later one supersedes.
        $succession = Resolve-SpecrewTypedActSupersession -Existing $existing -TurnIdentity $TurnIdentity -NowUtc $NowUtc `
            -JournalPath (Join-Path $root 'supersessions.jsonl') -FactType 'allowance-reset-approval'
        if ($succession -cin @('same-act', 'keep-newer')) { Clear-SpecrewQuestionUiPhraseObservation -ProjectRoot $ProjectRoot; return $existing }
        if ($succession -ceq 'refused') { return $null }
        if ($succession -ceq 'legacy' -and $null -ne $existing -and $existing.PSObject.Properties['spent_at'] -and
            [string]::IsNullOrWhiteSpace([string]$existing.spent_at) -and
            [string]$existing.response_hash -ceq [string]$fact.response_hash -and
            -not (Test-SpecrewTypedActReplacesRecord -Existing $existing -Fact $fact)) {
            Clear-SpecrewQuestionUiPhraseObservation -ProjectRoot $ProjectRoot
            return $existing
        }
    }
    $json = $fact | ConvertTo-Json -Depth 8
    if (Get-Command Write-SpecrewFileAtomic -ErrorAction SilentlyContinue) { Write-SpecrewFileAtomic -Path $path -Content $json }
    else { [IO.File]::WriteAllText($path, $json, [Text.UTF8Encoding]::new($false)) }
    # W54: the human typed it in the chat, so any standing picker diagnosis is now history.
    Clear-SpecrewQuestionUiPhraseObservation -ProjectRoot $ProjectRoot
    return $fact
}

function Get-SpecrewAllowanceResetAuthorization {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ProjectRoot)
    $path = Join-Path (Get-SpecrewAllowanceResetRoot -ProjectRoot $ProjectRoot) 'pending-allowance-reset.json'
    if (-not [IO.File]::Exists($path)) { return $null }
    $fact = $null
    try { $fact = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop } catch { return $null }
    foreach ($name in @('schema_version', 'fact_type', 'authority_kind', 'verdict_text', 'response_hash', 'observed_at')) {
        $property = $fact.PSObject.Properties[$name]
        if (-not $property -or [string]::IsNullOrWhiteSpace([string]$property.Value)) { return $null }
    }
    if ([string]$fact.fact_type -cne 'allowance-reset-approval' -or [string]$fact.authority_kind -cne 'human') { return $null }
    if ([string]$fact.response_hash -cne (Get-SpecrewHumanAuthorityHash -Text ([string]$fact.verdict_text))) { return $null }
    if (-not [bool](Test-SpecrewAllowanceResetPhrase -Text ([string]$fact.verdict_text)).Matched) { return $null }
    $spent = $fact.PSObject.Properties['spent_at']
    if ($spent -and -not [string]::IsNullOrWhiteSpace([string]$spent.Value)) { return $null }
    # Feature 203 T013 (B5F-066): used only when the human typed it.
    if (-not (Test-SpecrewAuthorizationRecordSender -ProjectRoot $ProjectRoot -Record $fact -Purpose 'allowance reset')) { return $null }
    return $fact
}

function Test-SpecrewAllowanceResetSameCapture {
    # Whether the held reset record is the capture the caller read: the same turn when both carry one, else the same text
    # observed at the same instant.
    [OutputType([bool])]
    param([AllowNull()]$Held, [AllowNull()]$Approval)
    if ($null -eq $Held -or $null -eq $Approval) { return $false }
    $heldTurn = if ($Held.PSObject.Properties['turn_identity']) { [string]$Held.turn_identity } else { '' }
    $approvalTurn = if ($Approval.PSObject.Properties['turn_identity']) { [string]$Approval.turn_identity } else { '' }
    if (-not [string]::IsNullOrWhiteSpace($heldTurn) -and -not [string]::IsNullOrWhiteSpace($approvalTurn)) { return ($heldTurn -ceq $approvalTurn) }
    $heldAt = if ($Held.PSObject.Properties['observed_at']) { ConvertTo-SpecrewAuthorityInstant -Value $Held.observed_at } else { $null }
    $approvalAt = if ($Approval.PSObject.Properties['observed_at']) { ConvertTo-SpecrewAuthorityInstant -Value $Approval.observed_at } else { $null }
    if ($null -eq $heldAt -or $null -eq $approvalAt) { return $false }
    return ([string]$Held.response_hash -ceq [string]$Approval.response_hash -and ([DateTimeOffset]$heldAt).UtcDateTime -eq ([DateTimeOffset]$approvalAt).UtcDateTime)
}

function Complete-SpecrewAllowanceResetAuthorization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$Reference,
        # Co-review round 12 (finding 2): the capture the reset was applied from. When the slot now holds a different, newer
        # act, that act is left waiting, and the reset is bound to the capture it used instead.
        [AllowNull()]$Approval,
        [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o'))
    )
    if ($script:SpecrewAllowanceResetSlotLockDepth -lt 1) {
        $bound = $PSBoundParameters
        try { return (Invoke-SpecrewAllowanceResetSlotLocked -ProjectRoot $ProjectRoot -Body { Complete-SpecrewAllowanceResetAuthorization @bound }) }
        catch { if ([string]$_.Exception.Message -ceq 'allowance-reset-slot-busy') { return [pscustomobject]@{ consumed = $false; fact = $null; reason = 'pending-capture-busy' } }; throw }
    }
    # W66 / round-24 finding (DRIFT-199-I001-138): SAY WHAT HAPPENED, AND VERIFY IT.
    #
    # The caller swallowed every error here, discarded the result, printed success and exited 0 - so a
    # transient failure writing the stamp left the human's `approved for allowance reset` unspent even
    # though the reset itself had landed, and a later agent invocation could replenish the allowance
    # again from that same one approval. Every exit now returns { consumed; fact; reason }, and
    # consumed=$true only when the stamp reads back durably: the identical rule the round-approval
    # consumption was corrected to in round 16, arrived at here eight rounds later because the two
    # paths were fixed one at a time instead of as one class.
    $path = Join-Path (Get-SpecrewAllowanceResetRoot -ProjectRoot $ProjectRoot) 'pending-allowance-reset.json'
    if (-not [IO.File]::Exists($path)) { return [pscustomobject]@{ consumed = $false; fact = $null; reason = 'no-pending-capture' } }
    $fact = $null
    try { $fact = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop }
    catch { return [pscustomobject]@{ consumed = $false; fact = $null; reason = 'pending-capture-unreadable' } }
    if ($null -eq $fact) { return [pscustomobject]@{ consumed = $false; fact = $null; reason = 'pending-capture-empty' } }
    if ($null -ne $Approval -and -not (Test-SpecrewAllowanceResetSameCapture -Held $fact -Approval $Approval)) {
        # A newer act took the slot after the reset read its capture. It stays waiting; the binding says which capture this
        # reset paid for, so the landed-reset guard does not take the newer act as already paid.
        $approvalAt = ConvertTo-SpecrewAuthorityInstant -Value $Approval.observed_at
        $binding = [pscustomobject][ordered]@{
            schema_version = '1.0'; fact_type = 'allowance-reset-binding'; reset_reference = [string]$Reference
            approval_turn_identity = if ($Approval.PSObject.Properties['turn_identity']) { [string]$Approval.turn_identity } else { '' }
            approval_observed_at = if ($null -ne $approvalAt) { ([DateTimeOffset]$approvalAt).ToUniversalTime().ToString('o') } else { [string]$Approval.observed_at }
            observed_at = $NowUtc
        }
        try { Add-Content -LiteralPath (Join-Path (Get-SpecrewAllowanceResetRoot -ProjectRoot $ProjectRoot) 'reset-bindings.jsonl') -Value ($binding | ConvertTo-Json -Compress -Depth 6) -Encoding UTF8 -ErrorAction Stop }
        catch { return [pscustomobject]@{ consumed = $false; fact = $null; reason = ('binding-write-failed:' + $_.Exception.Message) } }
        return [pscustomobject]@{ consumed = $true; fact = $Approval; reason = 'superseded-by-newer' }
    }
    $fact | Add-Member -NotePropertyName 'spent_at' -NotePropertyValue $NowUtc -Force
    $fact | Add-Member -NotePropertyName 'reset_reference' -NotePropertyValue ([string]$Reference) -Force
    $json = $fact | ConvertTo-Json -Depth 8
    try {
        if (Get-Command Write-SpecrewFileAtomic -ErrorAction SilentlyContinue) { Write-SpecrewFileAtomic -Path $path -Content $json }
        else { [IO.File]::WriteAllText($path, $json, [Text.UTF8Encoding]::new($false)) }
    }
    catch { return [pscustomobject]@{ consumed = $false; fact = $null; reason = ('write-failed:' + $_.Exception.Message) } }
    $verified = $null
    try { $verified = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop }
    catch { return [pscustomobject]@{ consumed = $false; fact = $null; reason = 'readback-failed' } }
    if ($null -eq $verified -or -not $verified.PSObject.Properties['spent_at'] -or
        [string]::IsNullOrWhiteSpace([string]$verified.spent_at) -or
        [string]$verified.reset_reference -cne [string]$Reference) {
        return [pscustomobject]@{ consumed = $false; fact = $null; reason = 'stamp-not-durable' }
    }
    return [pscustomobject]@{ consumed = $true; fact = $verified; reason = 'consumed' }
}

function Get-SpecrewLandedResetForAllowanceCapture {
    # THE DERIVED GUARD, mirroring W61's join: "has this approval already been spent?" is answered
    # from the facts the store published, never from a marker that can itself fail to be written. A
    # budget reset recorded at or after this capture was observed IS this capture's reset - nothing
    # else could have authorized it - so a lost stamp can no longer replenish the allowance twice.
    #
    # Returns the landed reset fact, or $null. A re-typed phrase is a NEW capture with a later
    # observed_at, so this leaves the human's recovery path open: refusing that was the round-19
    # wedge, and repeating it here would be the same mistake one door down. An unreadable store also
    # answers $null - a fabricated block locks a human out of a reset they own, which is worse.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][AllowEmptyString()][string]$CampaignId,
        # As stored: the capture's own [datetime] keeps its instant; a string is parsed (round 9, after DRIFT-004).
        [Parameter(Mandatory)][AllowNull()][AllowEmptyString()][object]$CaptureObservedAt
    )
    if ([string]::IsNullOrWhiteSpace($CampaignId) -or $null -eq $CaptureObservedAt -or [string]::IsNullOrWhiteSpace([string]$CaptureObservedAt)) { return $null }
    $root = Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) ('.specrew/review/authority/campaigns/' + $CampaignId + '/budget-resets')
    if (-not [IO.Directory]::Exists($root)) { return $null }
    $capturedAt = $null
    try { $capturedAt = ConvertTo-SpecrewAuthorityInstant -Value $CaptureObservedAt } catch { return $null }
    if ($null -eq $capturedAt) { return $null }
    # Co-review round 12 (finding 2): a reset bound to a capture observed before this one paid for that capture, not this.
    $paidForEarlier = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $bindingsPath = Join-Path (Get-SpecrewAllowanceResetRoot -ProjectRoot $ProjectRoot) 'reset-bindings.jsonl'
    if ([IO.File]::Exists($bindingsPath)) {
        foreach ($line in @(Get-Content -LiteralPath $bindingsPath -Encoding UTF8 -ErrorAction SilentlyContinue)) {
            if ([string]::IsNullOrWhiteSpace([string]$line)) { continue }
            $binding = $null
            try { $binding = $line | ConvertFrom-Json -Depth 6 -ErrorAction Stop } catch { continue }
            $boundAt = $null
            try { $boundAt = ConvertTo-SpecrewAuthorityInstant -Value $binding.approval_observed_at } catch { $boundAt = $null }
            if ($null -ne $boundAt -and $boundAt -lt $capturedAt) { [void]$paidForEarlier.Add([string]$binding.reset_reference) }
        }
    }
    $landed = $null
    $landedAt = $null
    try {
        foreach ($file in [IO.Directory]::EnumerateFiles($root, '*.json')) {
            $reset = $null
            try { $reset = Get-Content -LiteralPath $file -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop } catch { continue }
            if ($null -eq $reset -or -not $reset.PSObject.Properties['observed_at']) { continue }
            if ($reset.PSObject.Properties['reset_id'] -and $paidForEarlier.Contains([string]$reset.reset_id)) { continue }
            $resetAt = $null
            try { $resetAt = ConvertTo-SpecrewAuthorityInstant -Value $reset.observed_at } catch { continue }
            if ($null -eq $resetAt -or $resetAt -lt $capturedAt) { continue }
            if ($null -eq $landedAt -or $resetAt -lt $landedAt) { $landed = $reset; $landedAt = $resetAt }
        }
    }
    catch { return $null }
    return $landed
}
