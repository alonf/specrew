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
                ($tail -match '\b(?:do\s*not|don''t|dont|never|no\s+longer|cancel|withdraw|revoke|rescind|retract|hold\s+off|stand\s+down|stop|abort|scratch\s+that|never\s+mind|nevermind|actually\s+(?:stop|no|not)|disregard|ignore\s+that)\b')
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
        # An UNSPENT capture of the same utterance is the same act - do not re-mint. A different
        # utterance, or a spent slot, is superseded by the newer human act: both are human, so replacing
        # one with the other fabricates nothing. History goes to the journal either way.
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
    try {
        [IO.Directory]::CreateDirectory($root) | Out-Null
        ($fact | ConvertTo-Json -Compress -Depth 8) | Add-Content -LiteralPath (Join-Path $root 'captures.jsonl') -Encoding UTF8
    }
    catch { $null = $_ }
    # An UNSPENT capture is what a withdrawal removes; a spent one is history and stays.
    if ($null -ne $withdrawn -and [string]::IsNullOrWhiteSpace([string]$withdrawn.spent_at)) {
        try { [IO.File]::Delete($path) } catch { return $null }
    }
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
    if ($tail -match '\b(?:do\s*not|don''t|dont|never|no\s+longer|cancel|withdraw|revoke|rescind|retract|hold\s+off|stand\s+down|stop|abort|scratch\s+that|never\s+mind|nevermind|actually\s+(?:stop|no|not)|disregard|ignore\s+that)\b') { return $r }
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
