$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

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
        [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o'))
    )
    $event = ConvertTo-SpecrewHumanAuthoritySourceEvent -SourceEvent $SourceEvent
    if ($null -eq $event) { return $null }
    $trimmed = $Response.Trim()
    if ($trimmed -match '(?is)^\s*<(?:hook_prompt\b|task-notification\b|turn_aborted\b|system-reminder\b|environment_context\b)') { return $null }
    $match = [regex]::Match($trimmed, '(?is)^approved\s+for\s+partial\s+review\s+signoff\s*[-:]\s*(?<rationale>.+?)\s*$')
    if (-not $match.Success) { return $null }
    $rationale = $match.Groups['rationale'].Value.Trim()
    if ($rationale.Length -lt 10 -or $rationale.Length -gt 2000) { return $null }
    $request = Read-SpecrewReviewSignoffOverrideRequest -ProjectRoot $ProjectRoot
    if ($null -eq $request) { return $null }

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
    }
    $root = Get-SpecrewReviewSignoffOverrideRoot -ProjectRoot $ProjectRoot
    $factsRoot = Join-Path $root 'override-authorizations'
    [IO.Directory]::CreateDirectory($factsRoot) | Out-Null
    $path = Join-Path $factsRoot (([string]$request.request_id) + '.json')
    $json = $fact | ConvertTo-Json -Depth 8
    if ([IO.File]::Exists($path)) {
        try { $existing = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop }
        catch { throw 'review-signoff-override-authorization-json-invalid' }
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
    # W50: a partial the human explicitly accepts IS a delivered review, and delivery is the only
    # point that consumes the round entitlement. The acceptance is this override; consume here.
    if (Get-Command Complete-SpecrewReviewRoundApprovalAuthorization -ErrorAction SilentlyContinue) {
        try { Complete-SpecrewReviewRoundApprovalAuthorization -ProjectRoot $ProjectRoot -AuthorizationRef ('partial-accepted:' + [string]$request.request_id) | Out-Null } catch { $null = $_ }
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

function Get-SpecrewReviewRoundApprovalRoot {
    param([Parameter(Mandatory)][string]$ProjectRoot)
    return Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/review/round-approval'
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

    $r = [pscustomobject]@{ Matched = $false; Kind = $null; Phrase = $null }
    if ([string]::IsNullOrWhiteSpace($Text)) { return $r }
    $trimmed = $Text.Trim()
    # Machinery envelopes are not human turns, whatever they contain.
    if ($trimmed -match '(?is)^\s*<(?:hook_prompt\b|task-notification\b|turn_aborted\b|system-reminder\b|environment_context\b|command-name\b|local-command\b|bash-stdout\b)') { return $r }
    if ($trimmed.EndsWith('?')) { return $r }

    $lower = ($trimmed -replace '\s+', ' ').ToLowerInvariant()

    # Shape 1: the typed phrase, leading-anchored so mentions and teaching ("reply with approved for
    # review round") never match.
    $anchor = [regex]::Match($lower, '^\s*(?:(?:yes|confirmed)\s*[,;:\-]\s*)?(?:(?:i|we)\s+)?approv(?:e|ed)\s+(?:for\s+)?(?:a\s+|one\s+|another\s+|a\s+fresh\s+)?review\s+round\b')
    if ($anchor.Success) {
        $tail = $lower.Substring($anchor.Length)
        # Closed tail: nothing, or a delimiter followed by instructions. Arbitrary prose directly after
        # the phrase ("...review round seems premature") is not the phrase.
        if ([string]::IsNullOrWhiteSpace($tail) -or $tail -match '^\s*[-,.;:]') {
            # A deferral or negation around the clause still defers.
            $clause = ([regex]::Split($tail, '[,.;:]|\s-\s', 2))[0]
            $negated = $lower -match '^\s*(?:do\s*not|do\s+not|never|not\s+yet|hold\s+off|wait|stop)\b'
            if ($clause -notmatch '\b(later|after|once|when|unless|if)\b' -and -not $negated) {
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

function Write-SpecrewReviewRoundApprovalAuthorization {
    # SPECREW-AUTHORITY-CONTROL: review-round-approval
    <# Capture only from a genuine human utterance: a prompt-entry event's own text, or a verified human
       transcript turn relayed by the Stop backstop. Never from agent output. #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$Response,
        [AllowNull()][string]$HostKind,
        [AllowNull()][string]$SourceEvent,
        [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o'))
    )
    $event = ConvertTo-SpecrewHumanAuthoritySourceEvent -SourceEvent $SourceEvent
    $evidenceSource = 'hook-captured-user-prompt'
    if ($null -eq $event) {
        # The Stop backstop relays the most recent VERIFIED human transcript turn, for hosts where the
        # prompt-entry event does not deliver the prompt text (observed on claude: verdict capture lands
        # at Stop). The caller vouches for the turn's origin; every recognizer guard still applies.
        if (([string]$SourceEvent).Trim().ToLowerInvariant() -in @('stop', 'stop-transcript')) {
            $event = 'Stop'
            $evidenceSource = 'hook-captured-from-transcript'
        }
        else { return $null }
    }
    $recognized = Test-SpecrewReviewRoundApprovalPhrase -Text $Response
    if (-not [bool]$recognized.Matched) { return $null }

    $root = Get-SpecrewReviewRoundApprovalRoot -ProjectRoot $ProjectRoot
    [IO.Directory]::CreateDirectory($root) | Out-Null
    $path = Join-Path $root 'pending-round-approval.json'

    $fact = [pscustomobject][ordered]@{
        schema_version = '1.0'
        fact_type = 'review-round-approval'
        authority_kind = 'human'
        authorized_by = 'unattributed-human'
        approval_kind = [string]$recognized.Kind
        verdict_text = [string]$recognized.Phrase
        response_hash = Get-SpecrewHumanAuthorityHash -Text ([string]$recognized.Phrase)
        evidence_source = $evidenceSource
        source_event = $event
        host_kind = [string]$HostKind
        observed_at = $NowUtc
        spent_at = $null
        authorization_ref = $null
    }

    if ([IO.File]::Exists($path)) {
        $existing = $null
        try { $existing = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop }
        catch { $existing = $null }
        # An UNSPENT capture of the same utterance is the same act - do not re-mint. A different
        # utterance, or a spent slot, is superseded by the newer human act: both are human, so replacing
        # one with the other fabricates nothing. History goes to the journal either way.
        if ($null -ne $existing -and $existing.PSObject.Properties['spent_at'] -and
            [string]::IsNullOrWhiteSpace([string]$existing.spent_at) -and
            [string]$existing.response_hash -ceq [string]$fact.response_hash) {
            return $existing
        }
    }

    $json = $fact | ConvertTo-Json -Depth 8
    if (Get-Command Write-SpecrewFileAtomic -ErrorAction SilentlyContinue) { Write-SpecrewFileAtomic -Path $path -Content $json }
    else { [IO.File]::WriteAllText($path, $json, [Text.UTF8Encoding]::new($false)) }
    try {
        ($fact | ConvertTo-Json -Compress -Depth 8) | Add-Content -LiteralPath (Join-Path $root 'captures.jsonl') -Encoding UTF8
    }
    catch { $null = $_ }
    return $fact
}

function Get-SpecrewReviewRoundApprovalAuthorization {
    # The unspent captured approval, or $null. Shape-validated: a hand-authored file that does not carry
    # the full fact is treated as absent, and absent refuses - which is this control's fail direction.
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ProjectRoot)
    $path = Join-Path (Get-SpecrewReviewRoundApprovalRoot -ProjectRoot $ProjectRoot) 'pending-round-approval.json'
    if (-not [IO.File]::Exists($path)) { return $null }
    $item = Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
    if ($null -eq $item -or $item.Length -le 0 -or $item.Length -gt 65536) { return $null }
    $fact = $null
    try { $fact = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop }
    catch { return $null }
    foreach ($name in @('schema_version', 'fact_type', 'authority_kind', 'verdict_text', 'response_hash', 'evidence_source', 'source_event', 'observed_at')) {
        $property = $fact.PSObject.Properties[$name]
        if (-not $property -or [string]::IsNullOrWhiteSpace([string]$property.Value)) { return $null }
    }
    if ([string]$fact.fact_type -cne 'review-round-approval' -or [string]$fact.authority_kind -cne 'human') { return $null }
    if ([string]$fact.response_hash -cne (Get-SpecrewHumanAuthorityHash -Text ([string]$fact.verdict_text))) { return $null }
    # The stored text must still BE an approval by the live recognizer - a phrase file whose content
    # would not capture today does not authorize today.
    if (-not [bool](Test-SpecrewReviewRoundApprovalPhrase -Text ([string]$fact.verdict_text)).Matched) { return $null }
    $spent = $fact.PSObject.Properties['spent_at']
    if ($spent -and -not [string]::IsNullOrWhiteSpace([string]$spent.Value)) { return $null }
    return $fact
}

function Complete-SpecrewReviewRoundApprovalAuthorization {
    # One approval, one round: the mint that consumed the phrase stamps it spent, carrying the
    # authorization reference it became, so the record reads end to end - who approved (the phrase),
    # what it became (the ref), when it was spent.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$AuthorizationRef,
        [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o'))
    )
    $path = Join-Path (Get-SpecrewReviewRoundApprovalRoot -ProjectRoot $ProjectRoot) 'pending-round-approval.json'
    if (-not [IO.File]::Exists($path)) { return $null }
    $fact = $null
    try { $fact = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop }
    catch { return $null }
    if ($null -eq $fact) { return $null }
    $fact | Add-Member -NotePropertyName 'spent_at' -NotePropertyValue $NowUtc -Force
    $fact | Add-Member -NotePropertyName 'authorization_ref' -NotePropertyValue ([string]$AuthorizationRef) -Force
    $json = $fact | ConvertTo-Json -Depth 8
    if (Get-Command Write-SpecrewFileAtomic -ErrorAction SilentlyContinue) { Write-SpecrewFileAtomic -Path $path -Content $json }
    else { [IO.File]::WriteAllText($path, $json, [Text.UTF8Encoding]::new($false)) }
    return $fact
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

function Resolve-SpecrewRoundEntitlementOutcome {
    # Classifies one campaign invocation against the entitlement rule. The never-reached set is
    # FR-014's own discriminator, reused verbatim so the entitlement and the round counter cannot
    # drift apart: a run whose runtime_outcome is preflight-failed, claim-contended or launch-failed
    # never reached a reviewer.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter()][AllowNull()]$CampaignRun)

    $r = [pscustomobject]@{ outcome = 'not-invoked'; reason = 'no-run-object'; run_id = $null; completion = $null }
    if ($null -eq $CampaignRun) { return $r }
    $status = ''
    $statusProp = $CampaignRun.PSObject.Properties['status']
    if ($null -ne $statusProp) { $status = [string]$statusProp.Value }
    $invoked = $false
    $invokedProp = $CampaignRun.PSObject.Properties['invoked']
    if ($null -ne $invokedProp) { $invoked = [bool]$invokedProp.Value }
    $result = $null
    $resultProp = $CampaignRun.PSObject.Properties['result']
    if ($null -ne $resultProp) { $result = $resultProp.Value }
    $runIdProp = $CampaignRun.PSObject.Properties['run_id']
    if ($null -ne $runIdProp) { $r.run_id = [string]$runIdProp.Value }

    if (-not $invoked -or $status -cin @('not-started', 'suppressed')) {
        $r.outcome = 'not-invoked'
        $r.reason = if ([string]::IsNullOrWhiteSpace($status)) { 'not-invoked' } else { $status }
        return $r
    }
    if ($null -eq $result) {
        $r.outcome = 'undelivered'
        $r.reason = 'invoked-no-result'
        return $r
    }
    $runtimeOutcome = ''
    $roProp = $result.PSObject.Properties['runtime_outcome']
    if ($null -ne $roProp) { $runtimeOutcome = [string]$roProp.Value }
    if ($runtimeOutcome -cin @('preflight-failed', 'claim-contended', 'launch-failed')) {
        # Never reached a reviewer: this is failure-before-invocation in the rule's terms, whatever
        # the invocation plumbing says - no reviewer saw the files, no round was spent (FR-014).
        $r.outcome = 'not-invoked'
        $r.reason = $runtimeOutcome
        return $r
    }
    $completion = ''
    $cProp = $result.PSObject.Properties['completion']
    if ($null -ne $cProp) { $completion = [string]$cProp.Value }
    $r.completion = $completion
    if ($completion -ceq 'complete') {
        $r.outcome = 'delivered'
        $r.reason = 'complete'
        return $r
    }
    # Partial or incomplete: the review product was not delivered. A partial the human explicitly
    # accepts is consumed at the ACCEPTANCE (the partial-signoff override writer completes the
    # entitlement), never here.
    $r.outcome = 'undelivered'
    $r.reason = if ([string]::IsNullOrWhiteSpace($completion)) { 'no-completion-recorded' } else { "completion-$completion" }
    return $r
}

function Write-SpecrewRoundDeliveryJournal {
    # Spent-without-delivery is a REAL cost and must stay visible: every undelivered invoked attempt,
    # and every automatic retry choice, is journaled where the captures live.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$EventKind,
        [AllowNull()][string]$RunId,
        [AllowNull()][string]$Detail,
        [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o'))
    )
    try {
        $root = Get-SpecrewReviewRoundApprovalRoot -ProjectRoot $ProjectRoot
        [IO.Directory]::CreateDirectory($root) | Out-Null
        ([pscustomobject]@{ event = $EventKind; run_id = [string]$RunId; detail = [string]$Detail; recorded_at = $NowUtc } |
            ConvertTo-Json -Compress) | Add-Content -LiteralPath (Join-Path $root 'delivery-journal.jsonl') -Encoding UTF8
    }
    catch { $null = $_ }
}

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
    if ($trimmed.EndsWith('?')) { return $r }
    $lower = ($trimmed -replace '\s+', ' ').ToLowerInvariant()
    $anchor = [regex]::Match($lower, '^\s*(?:(?:yes|confirmed)\s*[,;:\-]\s*)?(?:(?:i|we)\s+)?approv(?:e|ed)\s+(?:for\s+)?(?:an\s+|the\s+)?allowance\s+reset\b')
    if (-not $anchor.Success) { return $r }
    $tail = $lower.Substring($anchor.Length)
    if (-not ([string]::IsNullOrWhiteSpace($tail) -or $tail -match '^\s*[-,.;:]')) { return $r }
    $clause = ([regex]::Split($tail, '[,.;:]|\s-\s', 2))[0]
    if ($clause -match '\b(later|after|once|when|unless|if)\b') { return $r }
    if ($lower -match '^\s*(?:do\s*not|never|not\s+yet|hold\s+off|wait|stop)\b') { return $r }
    $r.Matched = $true; $r.Phrase = $trimmed
    return $r
}

function Write-SpecrewAllowanceResetAuthorization {
    # SPECREW-AUTHORITY-CONTROL: allowance-reset
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$Response,
        [AllowNull()][string]$HostKind,
        [AllowNull()][string]$SourceEvent,
        [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o'))
    )
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
        observed_at = $NowUtc; spent_at = $null
    }
    if ([IO.File]::Exists($path)) {
        $existing = $null
        try { $existing = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop } catch { $existing = $null }
        if ($null -ne $existing -and $existing.PSObject.Properties['spent_at'] -and
            [string]::IsNullOrWhiteSpace([string]$existing.spent_at) -and
            [string]$existing.response_hash -ceq [string]$fact.response_hash) { return $existing }
    }
    $json = $fact | ConvertTo-Json -Depth 8
    if (Get-Command Write-SpecrewFileAtomic -ErrorAction SilentlyContinue) { Write-SpecrewFileAtomic -Path $path -Content $json }
    else { [IO.File]::WriteAllText($path, $json, [Text.UTF8Encoding]::new($false)) }
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
    return $fact
}

function Complete-SpecrewAllowanceResetAuthorization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$Reference,
        [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o'))
    )
    $path = Join-Path (Get-SpecrewAllowanceResetRoot -ProjectRoot $ProjectRoot) 'pending-allowance-reset.json'
    if (-not [IO.File]::Exists($path)) { return $null }
    $fact = $null
    try { $fact = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop } catch { return $null }
    if ($null -eq $fact) { return $null }
    $fact | Add-Member -NotePropertyName 'spent_at' -NotePropertyValue $NowUtc -Force
    $fact | Add-Member -NotePropertyName 'reset_reference' -NotePropertyValue ([string]$Reference) -Force
    $json = $fact | ConvertTo-Json -Depth 8
    if (Get-Command Write-SpecrewFileAtomic -ErrorAction SilentlyContinue) { Write-SpecrewFileAtomic -Path $path -Content $json }
    else { [IO.File]::WriteAllText($path, $json, [Text.UTF8Encoding]::new($false)) }
    return $fact
}
