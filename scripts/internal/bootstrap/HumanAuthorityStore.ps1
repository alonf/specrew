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
        # Round-16 (DRIFT-199-I001-126): the same postcondition as the CLI's delivered branch - a
        # consumption that did not land is surfaced, never swallowed, or one approval can deliver
        # twice. The override itself still stands; what is reported is the unmarked approval.
        $partialConsumption = $null
        try { $partialConsumption = Complete-SpecrewReviewRoundApprovalAuthorization -ProjectRoot $ProjectRoot -AuthorizationRef ('partial-accepted:' + [string]$request.request_id) }
        catch { $partialConsumption = [pscustomobject]@{ consumed = $false; reason = ('threw:' + $_.Exception.Message) } }
        if ($null -eq $partialConsumption -or -not [bool]$partialConsumption.consumed) {
            $partialReason = if ($null -ne $partialConsumption) { [string]$partialConsumption.reason } else { 'no-result' }
            [Console]::Error.WriteLine('[specrew-authority] WARN ROUND_APPROVAL_NOT_CONSUMED partial-accepted:' + $partialReason)
        }
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

function Get-SpecrewReviewRoundApprovalRoot {
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

    $r = [pscustomobject]@{ Matched = $false; Kind = $null; Phrase = $null }
    if ([string]::IsNullOrWhiteSpace($Text)) { return $r }
    $trimmed = $Text.Trim()
    # Machinery envelopes are not human turns, whatever they contain.
    if ($trimmed -match '(?is)^\s*<(?:hook_prompt\b|task-notification\b|turn_aborted\b|system-reminder\b|environment_context\b|command-name\b|local-command\b|bash-stdout\b)') { return $r }

    # W56: decide on the approval's OWN LINE. The interrogative test binds to that line, so
    # "approved for review round?" is still deliberation while a question in a FOLLOWING
    # instruction block is an ordinary follow-up.
    $lower = (Get-SpecrewAuthorityApprovalLine -Text $trimmed).ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($lower)) { return $r }
    if ($lower.EndsWith('?')) { return $r }

    # Shape 1: the typed phrase, leading-anchored so mentions and teaching ("reply with approved for
    # review round") never match.
    $anchor = [regex]::Match($lower, '^\s*(?:(?:yes|confirmed)\s*[,;:\-]\s*)?(?:(?:i|we)\s+)?approv(?:e|ed)\s+(?:for\s+)?(?:a\s+|one\s+|another\s+|a\s+fresh\s+)?review\s+round\b')
    if ($anchor.Success) {
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
            if ($tail -notmatch '\b(later|after|once|when|unless|if)\b' -and -not $negated) {
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
        # Round-19 (DRIFT-199-I001-130): present from birth, so ownership has a STABLE SHAPE to
        # join on. A reader that has to test whether the field exists is one StrictMode throw away
        # from treating "no round yet" as an error.
        minted_ref = ''
        minted_at = ''
    }

    if ([IO.File]::Exists($path)) {
        $existing = $null
        try { $existing = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop }
        catch { $existing = $null }
        # An UNSPENT capture of the same utterance is the same act - do not re-mint.
        #
        # W69 (2026-08-26) REPLACES what this comment used to claim. It said a spent slot "is superseded
        # by the newer human act ... replacing one with the other fabricates nothing". That premise is
        # inverted whenever the Stop backstop re-offers a turn: THERE IS NO NEWER HUMAN ACT. Replacing a
        # spent record with a re-offer of its own source fabricates a human act that did not happen a
        # second time - the forged-disposition class, reached by machinery rather than by an agent,
        # which is why it outranks the hole it mirrors: the evidence looks correct.
        #
        # The condition below is unchanged and is still not sufficient on its own - `spent_at` empty is
        # a PRECONDITION of this return, so a spent slot falls through to a fresh write. What stops that
        # now is upstream: the router refuses a turn that has already minted, BEFORE any writer is
        # called, so this branch is never reached by a re-offer.
        if ($null -ne $existing -and $existing.PSObject.Properties['spent_at'] -and
            [string]::IsNullOrWhiteSpace([string]$existing.spent_at) -and
            [string]$existing.response_hash -ceq [string]$fact.response_hash) {
            Clear-SpecrewQuestionUiPhraseObservation -ProjectRoot $ProjectRoot
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
    # W54: the human typed it in the chat, so any standing picker diagnosis is now history.
    Clear-SpecrewQuestionUiPhraseObservation -ProjectRoot $ProjectRoot
    return $fact
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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Response,
        [AllowEmptyString()][AllowNull()][string]$HostKind,
        [AllowEmptyString()][AllowNull()][string]$SourceEvent,
        [AllowEmptyString()][AllowNull()][string]$TurnPosition,
        [AllowEmptyString()][AllowNull()][string]$TurnArrival
    )
    if ([string]::IsNullOrWhiteSpace($Response)) { return '' }
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
    $isStopOffer = (([string]$SourceEvent).Trim().ToLowerInvariant() -in @('stop', 'stop-transcript'))
    try {
        foreach ($line in [IO.File]::ReadAllLines($path)) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $entry = $null
            try { $entry = $line | ConvertFrom-Json -Depth 6 -ErrorAction Stop } catch { return $true }
            if ($null -eq $entry -or -not $entry.PSObject.Properties['turn_id']) { return $true }
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
            minted = [string]$MintedWriters; observed_at = $NowUtc
        }
        # -ErrorAction Stop, and it is load-bearing. Add-Content raises a NON-TERMINATING error, so a
        # plain try/catch around it never fires: the append failed, the catch was skipped, and this
        # returned $true. A reservation that reports success it did not achieve is precisely the
        # failure the reservation exists to prevent, and it was found by the case that locks the ledger.
        $line = ($entry | ConvertTo-Json -Compress -Depth 6)
        Add-Content -LiteralPath $path -Value $line -Encoding UTF8 -ErrorAction Stop
        # And READ IT BACK, because "the write did not throw" is not "the record is there" - the same
        # postcondition rule the round-approval and allowance-reset consumptions were corrected to.
        $confirmed = $false
        foreach ($written in [IO.File]::ReadAllLines($path)) {
            if ([string]$written -ceq [string]$line) { $confirmed = $true; break }
        }
        return $confirmed
    }
    catch { return $false }
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
    # W68 / round-25 finding (DRIFT-199-I001-141): A WITHDRAWAL THAT COULD NOT DELETE STILL REVOKES.
    #
    # Write-SpecrewApprovalWithdrawal journals the human's act and THEN deletes this file. The journal
    # is written first precisely so the record survives a failed delete - but nothing read it, so a
    # delete that lost a race left the approval sitting here, spendable, after the human had explicitly
    # taken it back. The maintainer ruled this class the most severe the system has, one round before
    # it was found here, in the router introduced to fix the round-24 version of the same shape: the
    # capture was wired and the CONSUMPTION of the writer's result was not.
    #
    # Revocation is decided HERE, at the reader, because that is the only place that cannot be skipped
    # by a failed write somewhere else.
    # The stamp the withdrawal writes onto this very fact, honoured directly - the revocation path that
    # needs no second file to have survived (W71 / round-28).
    if ($fact.PSObject.Properties['withdrawn_at'] -and -not [string]::IsNullOrWhiteSpace([string]$fact.withdrawn_at)) { return $null }
    if (-not (Test-SpecrewApprovalIsWithdrawn -ProjectRoot $ProjectRoot -Fact $fact)) { return $fact }
    return $null
}

function Test-SpecrewApprovalIsWithdrawn {
    # Did the human take THIS approval back? A withdrawal journalled at or after the approval was
    # observed revokes it.
    #
    # TIME, NOT A JOIN, AND DELIBERATELY. The journal's `withdrew_observed_at` names the approval it
    # revoked, but it stores whatever `[string]` rendered from a JSON-parsed date, so it does not
    # round-trip to the same text on every host - matching on it would fail open exactly where this
    # control must not. The time rule fails CLOSED and stays RECOVERABLE, which is the pair that
    # matters: an approval typed AFTER the withdrawal has a later instant and is untouched, so a human
    # who changes their mind is never wedged (the round-19 lesson, kept).
    #
    # Unreadable journal answers "withdrawn". This is the one reader in this file that fails closed on
    # corruption rather than open: everywhere else a false refusal costs a retype, but here a false
    # ACCEPT spends authority the human revoked.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][AllowNull()]$Fact
    )
    if ($null -eq $Fact) { return $false }
    # BOTH journals: the one beside the approval, and the independent one under the authority root
    # that exists so an unwritable round-approval directory cannot erase a revocation (W71/round-28).
    $journals = @(
        (Join-Path (Get-SpecrewReviewRoundApprovalRoot -ProjectRoot $ProjectRoot) 'captures.jsonl')
        (Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/authority/withdrawals.jsonl')
    ) | Where-Object { [IO.File]::Exists($_) }
    if (@($journals).Count -eq 0) { return $false }
    $approvedAt = $null
    if ($Fact.PSObject.Properties['observed_at']) { $approvedAt = ConvertTo-SpecrewAuthorityInstant -Value $Fact.observed_at }
    if ($null -eq $approvedAt) { return $true }
    try {
        foreach ($line in @($journals | ForEach-Object { [IO.File]::ReadAllLines($_) })) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $entry = $null
            try { $entry = $line | ConvertFrom-Json -Depth 8 -ErrorAction Stop } catch { continue }
            if ($null -eq $entry -or -not $entry.PSObject.Properties['fact_type']) { continue }
            if ([string]$entry.fact_type -cne 'review-round-approval-withdrawn') { continue }
            if (-not $entry.PSObject.Properties['observed_at']) { continue }
            $withdrawnAt = ConvertTo-SpecrewAuthorityInstant -Value $entry.observed_at
            if ($null -eq $withdrawnAt) { continue }
            if ($withdrawnAt -ge $approvedAt) { return $true }
        }
    }
    catch { return $true }
    return $false
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
    }
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
        $tail = $lower.Substring($anchor.Length)
        if (-not ([string]::IsNullOrWhiteSpace($tail) -or $tail -match '^\s*[-,.;:]')) { return $r }
        if ($tail -match '\b(later|after|once|when|unless|if)\b') { return $r }
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
            [string]$(if ($existing.PSObject.Properties['run_id']) { $existing.run_id } else { '' }) -ceq [string]$fact.run_id) { return $existing }
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

function Set-SpecrewReviewRoundApprovalMintedRef {
    # W61 / round-19 finding (DRIFT-199-I001-130): OWNERSHIP IS RECORDED, NOT INFERRED.
    #
    # The capture now carries the authorization reference minted FROM it, so "has this approval
    # already bought a round?" is a join through published facts rather than a guess from
    # timestamps. Stamping the mint does NOT spend the capture - an undelivered attempt keeps the
    # entitlement, which is the W50 rule - it only records which grant this act became.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$AuthorizationRef,
        [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o'))
    )
    $path = Join-Path (Get-SpecrewReviewRoundApprovalRoot -ProjectRoot $ProjectRoot) 'pending-round-approval.json'
    if (-not [IO.File]::Exists($path)) { return [pscustomobject]@{ stamped = $false; reason = 'no-pending-capture' } }
    $fact = $null
    try { $fact = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop }
    catch { return [pscustomobject]@{ stamped = $false; reason = 'pending-capture-unreadable' } }
    if ($null -eq $fact) { return [pscustomobject]@{ stamped = $false; reason = 'pending-capture-empty' } }
    $fact | Add-Member -NotePropertyName 'minted_ref' -NotePropertyValue ([string]$AuthorizationRef) -Force
    $fact | Add-Member -NotePropertyName 'minted_at' -NotePropertyValue $NowUtc -Force
    $json = $fact | ConvertTo-Json -Depth 8
    try {
        if (Get-Command Write-SpecrewFileAtomic -ErrorAction SilentlyContinue) { Write-SpecrewFileAtomic -Path $path -Content $json }
        else { [IO.File]::WriteAllText($path, $json, [Text.UTF8Encoding]::new($false)) }
    }
    catch { return [pscustomobject]@{ stamped = $false; reason = ('write-failed:' + $_.Exception.Message) } }
    $verified = $null
    try { $verified = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop }
    catch { return [pscustomobject]@{ stamped = $false; reason = 'readback-failed' } }
    if ($null -eq $verified -or [string]$verified.minted_ref -cne [string]$AuthorizationRef) {
        return [pscustomobject]@{ stamped = $false; reason = 'mint-ref-not-durable' }
    }
    return [pscustomobject]@{ stamped = $true; fact = $verified; reason = 'stamped' }
}

function Get-SpecrewDeliveredRoundForMintedRef {
    # W61 / round-19 findings (DRIFT-199-I001-130): THE JOIN, replacing the time inference.
    #
    # "Did this approval already buy a delivered round?" is answered by following the facts the
    # store published: capture.minted_ref -> grants/*.json (authorization_ref) -> grant_id ->
    # reservations/<grant_id>/**/generation-*.json (run_id) -> runs/<run_id>/result.json. Asking
    # instead "did ANY completed run start after this capture?" attributed an unrelated round to a
    # pending approval and refused it - the round-19 major - and made the printed recovery
    # unreachable, because a re-typed phrase kept the old timestamp - the round-19 blocking wedge.
    #
    # Returns the delivered run result, or $null. An unreadable store answers $null: a fabricated
    # block locks a human out of a round they own, which is the worse failure.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][AllowEmptyString()][string]$CampaignId,
        [Parameter(Mandatory)][AllowEmptyString()][string]$AuthorizationRef
    )
    if ([string]::IsNullOrWhiteSpace($AuthorizationRef) -or [string]::IsNullOrWhiteSpace($CampaignId)) { return $null }
    $campaignRoot = Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) (".specrew/review/authority/campaigns/" + $CampaignId)
    if (-not (Test-Path -LiteralPath $campaignRoot -PathType Container)) { return $null }
    try {
        $grantIds = [Collections.Generic.List[string]]::new()
        foreach ($grantFile in @(Get-ChildItem -LiteralPath (Join-Path $campaignRoot 'grants') -Filter '*.json' -File -ErrorAction SilentlyContinue)) {
            $grant = $null
            try { $grant = Get-Content -LiteralPath $grantFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop } catch { continue }
            if ($null -eq $grant -or -not $grant.PSObject.Properties['authorization_ref']) { continue }
            if ([string]$grant.authorization_ref -cne $AuthorizationRef) { continue }
            if ($grant.PSObject.Properties['grant_id'] -and -not [string]::IsNullOrWhiteSpace([string]$grant.grant_id)) {
                $grantIds.Add([string]$grant.grant_id) | Out-Null
            }
        }
        if ($grantIds.Count -eq 0) { return $null }
        foreach ($grantId in $grantIds) {
            $reservationRoot = Join-Path (Join-Path $campaignRoot 'reservations') $grantId
            if (-not (Test-Path -LiteralPath $reservationRoot -PathType Container)) { continue }
            foreach ($generation in @(Get-ChildItem -LiteralPath $reservationRoot -Filter '*.json' -File -Recurse -ErrorAction SilentlyContinue)) {
                $reservation = $null
                try { $reservation = Get-Content -LiteralPath $generation.FullName -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop } catch { continue }
                if ($null -eq $reservation -or -not $reservation.PSObject.Properties['run_id']) { continue }
                $runId = [string]$reservation.run_id
                if ([string]::IsNullOrWhiteSpace($runId)) { continue }
                $resultPath = Join-Path (Join-Path (Join-Path $campaignRoot 'runs') $runId) 'result.json'
                if (-not [IO.File]::Exists($resultPath)) { continue }
                $result = $null
                try { $result = Get-Content -LiteralPath $resultPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 20 -ErrorAction Stop } catch { continue }
                if ($null -eq $result -or -not $result.PSObject.Properties['runtime_outcome']) { continue }
                # DELIVERED only: an attempt that never reached a reviewer spends nothing (W50).
                if ([string]$result.runtime_outcome -ceq 'completed') { return $result }
            }
        }
    }
    catch { return $null }
    return $null
}

function Get-SpecrewDeliveredRoundForCapture {
    # W59 / round-18 finding (DRIFT-199-I001-128): DERIVE THE BLOCK FROM EVIDENCE THAT ALREADY
    # EXISTS, not from a marker written at the moment of failure.
    #
    # Round 17 blocked the double spend with a marker file - and that write fails for exactly the
    # reason the consumption write failed (unwritable directory, full disk), so once storage
    # recovered nothing stopped the next mint. Third consecutive round finding the fix one layer
    # short of enforcement. The store already holds the answer: a DELIVERED run that started after
    # the capture was observed IS the round that capture paid for, published before any of this
    # could fail. If such a run exists while the capture is still unspent, the entitlement is
    # already used, whatever the stamp says.
    #
    # Returns the delivered run, or $null. UNPARSEABLE TIMES ANSWER NULL: absent evidence is not
    # evidence, and this must never fabricate a block that locks a human out of a round they own.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowNull()][object]$CaptureObservedAt,
        [AllowNull()][object[]]$RunResults
    )
    if ($null -eq $CaptureObservedAt -or $null -eq $RunResults) { return $null }
    $observed = ConvertTo-SpecrewAuthorityInstant -Value $CaptureObservedAt
    if ($null -eq $observed) { return $null }
    foreach ($run in @($RunResults)) {
        if ($null -eq $run) { continue }
        $outcomeProperty = $run.PSObject.Properties['runtime_outcome']
        if (-not $outcomeProperty -or [string]$outcomeProperty.Value -cne 'completed') { continue }
        $startedProperty = $run.PSObject.Properties['started_at']
        if (-not $startedProperty) { continue }
        $started = ConvertTo-SpecrewAuthorityInstant -Value $startedProperty.Value
        if ($null -eq $started) { continue }
        if ($started -gt $observed) { return $run }
    }
    return $null
}

function Get-SpecrewUnconsumedDeliveryPath {
    param([Parameter(Mandatory)][string]$ProjectRoot)
    return Join-Path (Get-SpecrewReviewRoundApprovalRoot -ProjectRoot $ProjectRoot) 'delivered-unconsumed.json'
}

function Write-SpecrewUnconsumedDeliveryFact {
    # W58 / round-17 finding (DRIFT-199-I001-127): A WARNING IS NOT A CONTROL.
    #
    # Round 16 made a failed consumption stamp VISIBLE; round 17 observed that visibility does not
    # stop it - the capture stayed unspent, so the next invocation minted a fresh round-numbered
    # grant and started a SECOND paid review from one human approval. The delivered-but-unconsumed
    # state is therefore durable, and the mint gate fails closed on it: a round that was delivered
    # and could not be marked paid blocks further spending until a human resolves it.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [AllowNull()][string]$RunId,
        [Parameter(Mandatory)][string]$AuthorizationRef,
        [Parameter(Mandatory)][string]$Reason,
        [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o'))
    )
    $path = Get-SpecrewUnconsumedDeliveryPath -ProjectRoot $ProjectRoot
    $fact = [pscustomobject][ordered]@{
        schema_version = '1.0'; fact_type = 'review-round-delivered-unconsumed'
        run_id = [string]$RunId; authorization_ref = [string]$AuthorizationRef
        reason = [string]$Reason; observed_at = $NowUtc
    }
    try {
        [IO.Directory]::CreateDirectory((Split-Path -Parent $path)) | Out-Null
        $json = $fact | ConvertTo-Json -Depth 6
        if (Get-Command Write-SpecrewFileAtomic -ErrorAction SilentlyContinue) { Write-SpecrewFileAtomic -Path $path -Content $json }
        else { [IO.File]::WriteAllText($path, $json, [Text.UTF8Encoding]::new($false)) }
    }
    catch { return $null }
    return $fact
}

function Get-SpecrewUnconsumedDeliveryFact {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ProjectRoot)
    $path = Get-SpecrewUnconsumedDeliveryPath -ProjectRoot $ProjectRoot
    if (-not [IO.File]::Exists($path)) { return $null }
    $fact = $null
    try { $fact = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 6 -ErrorAction Stop } catch { return $null }
    foreach ($name in @('fact_type', 'authorization_ref', 'reason', 'observed_at')) {
        $property = $fact.PSObject.Properties[$name]
        if (-not $property -or [string]::IsNullOrWhiteSpace([string]$property.Value)) { return $null }
    }
    if ([string]$fact.fact_type -cne 'review-round-delivered-unconsumed') { return $null }
    return $fact
}

function Clear-SpecrewUnconsumedDeliveryFact {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ProjectRoot)
    $path = Get-SpecrewUnconsumedDeliveryPath -ProjectRoot $ProjectRoot
    try { if ([IO.File]::Exists($path)) { [IO.File]::Delete($path) } } catch { $null = $_ }
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
    $r.Matched = $true; $r.Phrase = $trimmed
    return $r
}

function Write-SpecrewApprovalWithdrawal {
    # SPECREW-AUTHORITY-CONTROL: approval-withdrawal
    # Removes the pending capture and records WHY it is gone, so the ledger shows a withdrawal
    # rather than an approval that silently vanished. Journals before deleting: the record of the
    # human's act must survive even if the delete then fails.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$Response,
        [AllowNull()][string]$HostKind,
        [AllowNull()][string]$SourceEvent,
        [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o'))
    )
    $recognized = Test-SpecrewApprovalWithdrawalPhrase -Text $Response
    if (-not [bool]$recognized.Matched) { return $null }
    $root = Get-SpecrewReviewRoundApprovalRoot -ProjectRoot $ProjectRoot
    $path = Join-Path $root 'pending-round-approval.json'
    $withdrawn = $null
    if ([IO.File]::Exists($path)) {
        try { $withdrawn = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop } catch { $withdrawn = $null }
    }
    $fact = [pscustomobject][ordered]@{
        schema_version = '1.0'; fact_type = 'review-round-approval-withdrawn'; authority_kind = 'human'
        authorized_by = 'unattributed-human'; verdict_text = [string]$recognized.Phrase
        response_hash = Get-SpecrewHumanAuthorityHash -Text ([string]$recognized.Phrase)
        withdrew_observed_at = $(if ($null -ne $withdrawn -and $withdrawn.PSObject.Properties['observed_at']) { [string]$withdrawn.observed_at } else { '' })
        host_kind = [string]$HostKind; source_event = [string]$SourceEvent; observed_at = $NowUtc
    }
    # W71 / round-28 finding, reported BLOCKING: THREE INDEPENDENT WAYS TO REVOKE, because one
    # unwritable file must not hand the human's authority back.
    #
    # W68 made the reader consult the journal, which closed "the delete failed". Round 28 found the
    # pair: if the journal append ALSO fails there is nothing to consult, and the revoked approval
    # reads as usable again. So the withdrawal now (1) stamps the pending fact itself, which the reader
    # honours directly, (2) journals, and (3) deletes. Any one of the three landing is a revocation.
    # They are attempted in that order because the stamp is the one the reader reads without needing a
    # second file to survive.
    $revoked = $false
    if ($null -ne $withdrawn -and [string]::IsNullOrWhiteSpace([string]$withdrawn.spent_at)) {
        try {
            $withdrawn | Add-Member -NotePropertyName 'withdrawn_at' -NotePropertyValue $NowUtc -Force
            $stampJson = $withdrawn | ConvertTo-Json -Depth 8
            if (Get-Command Write-SpecrewFileAtomic -ErrorAction SilentlyContinue) { Write-SpecrewFileAtomic -Path $path -Content $stampJson }
            else { [IO.File]::WriteAllText($path, $stampJson, [Text.UTF8Encoding]::new($false)) }
            $verify = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop
            if ($null -ne $verify -and $verify.PSObject.Properties['withdrawn_at'] -and
                -not [string]::IsNullOrWhiteSpace([string]$verify.withdrawn_at)) { $revoked = $true }
        }
        catch { $revoked = $false }
    }
    try {
        [IO.Directory]::CreateDirectory($root) | Out-Null
        Add-Content -LiteralPath (Join-Path $root 'captures.jsonl') -Value ($fact | ConvertTo-Json -Compress -Depth 8) -Encoding UTF8 -ErrorAction Stop
        $revoked = $true
    }
    catch { $null = $_ }
    # A FOURTH PATH, IN A DIFFERENT DIRECTORY. The three above all live under the round-approval root,
    # so "that directory is unwritable" defeats all of them at once - which is precisely the round-28
    # scenario, and why three paths in one place is really one path wearing three hats. The authority
    # root is independent storage; if BOTH are unwritable the project has no working store at all.
    try {
        $independent = Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/authority/withdrawals.jsonl'
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($independent)) | Out-Null
        Add-Content -LiteralPath $independent -Value ($fact | ConvertTo-Json -Compress -Depth 8) -Encoding UTF8 -ErrorAction Stop
        $revoked = $true
    }
    catch { $null = $_ }
    # An UNSPENT capture is what a withdrawal removes; a spent one is history and stays.
    if ($null -ne $withdrawn -and [string]::IsNullOrWhiteSpace([string]$withdrawn.spent_at)) {
        try { [IO.File]::Delete($path); $revoked = $true } catch { $null = $_ }
    }
    if (-not $revoked) { return $null }
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
    # W57: EVERY exit returns the same shape. The old early returns handed back $null, which the
    # caller could not tell from success - the discard that let a delivered round leave its approval
    # unspent (round-16 finding). "There was nothing to consume" is itself a reportable outcome.
    if (-not [IO.File]::Exists($path)) { return [pscustomobject]@{ consumed = $false; fact = $null; reason = 'no-pending-capture' } }
    $fact = $null
    try { $fact = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop }
    catch { return [pscustomobject]@{ consumed = $false; fact = $null; reason = 'pending-capture-unreadable' } }
    if ($null -eq $fact) { return [pscustomobject]@{ consumed = $false; fact = $null; reason = 'pending-capture-empty' } }
    $fact | Add-Member -NotePropertyName 'spent_at' -NotePropertyValue $NowUtc -Force
    $fact | Add-Member -NotePropertyName 'authorization_ref' -NotePropertyValue ([string]$AuthorizationRef) -Force
    $json = $fact | ConvertTo-Json -Depth 8
    # W57 / round-16 finding (DRIFT-199-I001-126): VERIFY THE POSTCONDITION, AND SAY SO.
    #
    # The caller swallowed every error here and never checked the outcome, so a transient write
    # failure left spent_at unset after a DELIVERED review - and the next invocation derived a fresh
    # grant from the same capture, two delivered reviews from one approval. This now returns
    # { consumed; fact; reason }: consumed=$true ONLY when the stamp is durably readable back, which
    # is the same read-back rule the block counter and the cap fact already follow.
    $reason = 'consumed'
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
        [string]$verified.authorization_ref -cne [string]$AuthorizationRef) {
        return [pscustomobject]@{ consumed = $false; fact = $null; reason = 'stamp-not-durable' }
    }
    return [pscustomobject]@{ consumed = $true; fact = $verified; reason = $reason }
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
    # W56 (DRIFT-199-I001-125): the approval's own line - the reviewer named this sibling site by
    # line number, and rule 6 requires the same treatment in every copy of the rule.
    $lower = (Get-SpecrewAuthorityApprovalLine -Text $trimmed).ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($lower)) { return $r }
    if ($lower.EndsWith('?')) { return $r }
    $anchor = [regex]::Match($lower, '^\s*(?:(?:yes|confirmed)\s*[,;:\-]\s*)?(?:(?:i|we)\s+)?approv(?:e|ed)\s+(?:for\s+)?(?:an\s+|the\s+)?allowance\s+reset\b')
    if (-not $anchor.Success) { return $r }
    $tail = $lower.Substring($anchor.Length)
    if (-not ([string]::IsNullOrWhiteSpace($tail) -or $tail -match '^\s*[-,.;:]')) { return $r }
    # Round-14 finding (DRIFT-199-I001-123): the whole TAIL, not element zero of a delimiter split -
    # which is empty by construction - or "approved for allowance reset, after we verify the
    # failures" replenishes spend authority before the stated condition holds.
    if ($tail -match '\b(later|after|once|when|unless|if)\b') { return $r }
    if ($lower -match '^\s*(?:do\s*not|never|not\s+yet|hold\s+off|wait|stop)\b') { return $r }
    # Round-16 (DRIFT-199-I001-126): a reversal AFTER the anchor is the same refusal as one before it.
    if ($tail -match '\b(?:do\s*not|don''t|dont|never|not\s+yet|no\s+longer|cancel|withdraw|revoke|rescind|retract|hold\s+off|stand\s+down|stop|abort|scratch\s+that|never\s+mind|nevermind|actually\s+(?:stop|no|not)|disregard|ignore\s+that)\b') { return $r }
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
            [string]$existing.response_hash -ceq [string]$fact.response_hash) {
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
    return $fact
}

function Complete-SpecrewAllowanceResetAuthorization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$Reference,
        [string]$NowUtc = ([DateTimeOffset]::UtcNow.ToString('o'))
    )
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
        [Parameter(Mandatory)][AllowEmptyString()][string]$CaptureObservedAt
    )
    if ([string]::IsNullOrWhiteSpace($CampaignId) -or [string]::IsNullOrWhiteSpace($CaptureObservedAt)) { return $null }
    $root = Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) ('.specrew/review/authority/campaigns/' + $CampaignId + '/budget-resets')
    if (-not [IO.Directory]::Exists($root)) { return $null }
    $capturedAt = $null
    try { $capturedAt = ConvertTo-SpecrewAuthorityInstant -Value $CaptureObservedAt } catch { return $null }
    if ($null -eq $capturedAt) { return $null }
    $landed = $null
    $landedAt = $null
    try {
        foreach ($file in [IO.Directory]::EnumerateFiles($root, '*.json')) {
            $reset = $null
            try { $reset = Get-Content -LiteralPath $file -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 -ErrorAction Stop } catch { continue }
            if ($null -eq $reset -or -not $reset.PSObject.Properties['observed_at']) { continue }
            $resetAt = $null
            try { $resetAt = ConvertTo-SpecrewAuthorityInstant -Value $reset.observed_at } catch { continue }
            if ($null -eq $resetAt -or $resetAt -lt $capturedAt) { continue }
            if ($null -eq $landedAt -or $resetAt -lt $landedAt) { $landed = $reset; $landedAt = $resetAt }
        }
    }
    catch { return $null }
    return $landed
}
