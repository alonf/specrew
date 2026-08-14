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
