Set-StrictMode -Version Latest

function Get-SpecrewWorkshopAuthorityReceiptPath {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string] $ProjectRoot)

    return Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/runtime/workshop-authority.jsonl'
}

function Get-SpecrewWorkshopResponseAuthority {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $Phase,
        [Parameter(Mandatory)][string] $Response
    )

    $normalized = ($Response -replace '\s+', ' ').Trim().ToLowerInvariant()
    $delegated = $normalized -match '^(?:please\s+)?(?:you decide|decide for me|choose for me|use your (?:best )?judg(?:e)?ment)(?:\b.*)?$'
    $skipped = $normalized -match '^(?:skip(?:\s+(?:it|this|this lens|this question|the lens))?|not applicable|n/?a|move on without(?:\b.*)?)(?:[.!])?$'

    if ($Phase -eq 'agenda') {
        if ($delegated -or $skipped) {
            return [pscustomobject]@{ confirmation = 'invalid'; confirmation_scope = 'lens-selection' }
        }
        return [pscustomobject]@{ confirmation = 'human-confirmed'; confirmation_scope = 'lens-selection' }
    }
    if ($delegated) {
        return [pscustomobject]@{ confirmation = 'human-delegated'; confirmation_scope = 'explicit-delegation' }
    }
    if ($skipped) {
        return [pscustomobject]@{ confirmation = 'human-skipped'; confirmation_scope = 'explicit-skip' }
    }
    return [pscustomobject]@{ confirmation = 'human-confirmed'; confirmation_scope = 'lens-question' }
}

function Get-SpecrewWorkshopAuthorityHash {
    param([AllowEmptyString()][string] $Text)
    $bytes = [Text.Encoding]::UTF8.GetBytes([string]$Text)
    return ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))).ToLowerInvariant()
}

function Get-SpecrewWorkshopRefusalContractText {
    [CmdletBinding()]
    param()

    return @(
        'If the named action does not clear this refusal on the next attempt, stop and tell the human that the workshop controller plumbing is broken; do not retry again.'
        'Never write lens-applicability.json or any governed controller state by hand to clear a refusal.'
    ) -join ' '
}

function ConvertTo-SpecrewWorkshopAgendaBinding {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][Collections.IDictionary]$Agenda,
        [Parameter(Mandatory)][Collections.IDictionary]$Skipped
    )

    $selectedRecords = [Collections.Generic.List[object]]::new()
    foreach ($entry in $Agenda.GetEnumerator()) {
        $value = $entry.Value
        $selectedRecords.Add([ordered]@{
            lens = [string]$entry.Key
            depth = [string]$value.depth
            decision = ([string]$value.decision).Trim()
        }) | Out-Null
    }
    $skippedRecords = [Collections.Generic.List[object]]::new()
    foreach ($entry in $Skipped.GetEnumerator()) {
        $skippedRecords.Add([ordered]@{
            lens = [string]$entry.Key
            reason = ([string]$entry.Value).Trim()
        }) | Out-Null
    }
    return [ordered]@{
        schema_version = '1.0'
        selected = $selectedRecords.ToArray()
        skipped = $skippedRecords.ToArray()
    }
}

function Get-SpecrewWorkshopAgendaDigest {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Binding)

    $json = $Binding | ConvertTo-Json -Depth 8 -Compress
    return Get-SpecrewWorkshopAuthorityHash -Text $json
}

function Get-SpecrewWorkshopAgendaChangedLenses {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$ExpectedBinding,
        [Parameter(Mandatory)]$ActualBinding
    )

    $expected = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
    $actual = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
    $position = 0
    foreach ($entry in @($ExpectedBinding.selected)) {
        $expected[[string]$entry.lens] = ('selected|{0}|{1}|{2}' -f $position, [string]$entry.depth, ([string]$entry.decision).Trim())
        $position++
    }
    $position = 0
    foreach ($entry in @($ExpectedBinding.skipped)) {
        $expected[[string]$entry.lens] = ('skipped|{0}|{1}' -f $position, ([string]$entry.reason).Trim())
        $position++
    }
    $position = 0
    foreach ($entry in @($ActualBinding.selected)) {
        $actual[[string]$entry.lens] = ('selected|{0}|{1}|{2}' -f $position, [string]$entry.depth, ([string]$entry.decision).Trim())
        $position++
    }
    $position = 0
    foreach ($entry in @($ActualBinding.skipped)) {
        $actual[[string]$entry.lens] = ('skipped|{0}|{1}' -f $position, ([string]$entry.reason).Trim())
        $position++
    }

    $all = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($lens in $expected.Keys) { [void]$all.Add($lens) }
    foreach ($lens in $actual.Keys) { [void]$all.Add($lens) }
    return @($all | Where-Object {
            -not $expected.ContainsKey($_) -or -not $actual.ContainsKey($_) -or $expected[$_] -cne $actual[$_]
        } | Sort-Object)
}

function Test-SpecrewWorkshopAgendaVisibleInText {
    [CmdletBinding()]
    param(
        [AllowNull()][string]$Text,
        [AllowNull()][string]$CanonicalAgendaText
    )

    if ([string]::IsNullOrWhiteSpace($Text) -or [string]::IsNullOrWhiteSpace($CanonicalAgendaText)) { return $false }
    # ConversationCaptureAccessor intentionally collapses host transcript whitespace. The binding is the
    # structured agenda digest; this visibility check only proves that the complete canonical content appeared
    # in the assistant turn, independent of CRLF/LF and accessor whitespace normalization.
    $normalize = {
        param([string]$Value)
        return (($Value -replace '\s+', ' ').Trim())
    }
    $visible = & $normalize $Text
    $agenda = & $normalize $CanonicalAgendaText
    return ($visible.IndexOf($agenda, [StringComparison]::Ordinal) -ge 0)
}

function ConvertTo-SpecrewWorkshopSourceEvent {
    param([AllowNull()][string]$SourceEvent)
    $key = ([string]$SourceEvent).Trim().ToLowerInvariant() -replace '[-_]', ''
    switch ($key) {
        'userpromptsubmit' { return 'UserPromptSubmit' }
        'userpromptsubmitted' { return 'UserPromptSubmit' }
        'preinvocation' { return 'PreInvocation' }
        default { return $null }
    }
}

function Test-SpecrewWorkshopHumanResponseText {
    [CmdletBinding()]
    param([AllowNull()][string] $Text)

    if ([string]::IsNullOrWhiteSpace($Text)) { return $false }
    $trimmed = $Text.Trim()

    # Host stop-block output can be re-submitted by the host as a userPromptSubmitted event. It is still hook
    # machinery, not a typed human answer. Codex gives that machinery an explicit envelope; Copilot 1.0.79
    # replays the plain Specrew directive itself. Authority is fail-closed on both shapes.
    if ($trimmed -match '(?is)^\s*<(?:hook_prompt\b|task-notification\b|turn_aborted\b|system-reminder\b|environment_context\b)[\s\S]*</(?:hook_prompt|task-notification|turn_aborted|system-reminder|environment_context)>\s*$') { return $false }
    if ($trimmed -match '(?is)^\s*(?:Specrew:|Specrew\s+review\s+[-—]|\[specrew-|AWAITING YOUR VERDICT:|BOUNDARY NOT READY FOR A VERDICT:|Campaign review authority\b)') { return $false }
    return $true
}

function Test-SpecrewWorkshopResponseIsHookOutput {
    # SPECREW-AUTHORITY-CONSUMER: workshop-hook-output-identity
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$Response
    )
    $path = Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/runtime/hook-output-authority.jsonl'
    if (Test-Path -LiteralPath ($path + '.unhealthy') -PathType Leaf) { return $true }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $false }
    $hash = Get-SpecrewWorkshopAuthorityHash -Text $Response.Trim()
    foreach ($line in [IO.File]::ReadLines($path, [Text.Encoding]::UTF8)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try { $record = $line | ConvertFrom-Json -Depth 5 -ErrorAction Stop }
        catch { throw 'workshop-hook-output-authority-journal-invalid' }
        if ([string]$record.schema_version -cne '1.0' -or [string]::IsNullOrWhiteSpace([string]$record.output_hash)) {
            throw 'workshop-hook-output-authority-record-invalid'
        }
        if ([string]$record.output_hash -ceq $hash) { return $true }
    }
    return $false
}

function Write-SpecrewWorkshopAuthorityReceipt {
    # SPECREW-AUTHORITY-CONTROL: workshop-agenda-question-identity
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $ProjectRoot,
        [Parameter(Mandatory)][string] $Response,
        [AllowNull()][string] $HostKind,
        [AllowNull()][string] $SourceEvent
    )

    $canonicalSourceEvent = ConvertTo-SpecrewWorkshopSourceEvent -SourceEvent $SourceEvent
    if ($null -eq $canonicalSourceEvent) { return $null }
    $root = [IO.Path]::GetFullPath($ProjectRoot)
    if (-not (Test-SpecrewWorkshopHumanResponseText -Text $Response)) { return $null }
    if (Test-SpecrewWorkshopResponseIsHookOutput -ProjectRoot $root -Response $Response) { return $null }
    $questionPath = Join-Path $root '.specrew/handover/workshop-question.json'
    if (-not (Test-Path -LiteralPath $questionPath -PathType Leaf)) { return $null }

    try {
        $questionItem = Get-Item -LiteralPath $questionPath -ErrorAction Stop
        if ($questionItem.Length -le 0 -or $questionItem.Length -gt 65536) { return $null }
        $question = Get-Content -LiteralPath $questionPath -Raw -Encoding UTF8 -ErrorAction Stop |
            ConvertFrom-Json -Depth 10 -ErrorAction Stop
        if ([string]$question.schema -cne 'v3' -or [string]$question.status -cne 'workshop-active') { return $null }
        $featureRef = [string]$question.feature_ref
        $phase = [string]$question.phase
        $lens = [string]$question.lens
        $questionHash = [string]$question.message_hash
        $agendaDigest = ''
        $agendaBinding = $null
        if ($featureRef -cnotmatch '^[0-9]{3}-[a-z0-9][a-z0-9-]{0,63}$' -or
            $phase -cnotin @('product-domain', 'agenda', 'lens') -or
            [string]::IsNullOrWhiteSpace($questionHash)) { return $null }
        if ($phase -eq 'lens' -and $lens -cnotmatch '^[a-z][a-z0-9-]{1,63}$') { return $null }
        if ($phase -eq 'agenda') {
            $digestProperty = $question.PSObject.Properties['agenda_digest']
            $bindingProperty = $question.PSObject.Properties['agenda_binding']
            if (-not $digestProperty -or [string]$digestProperty.Value -cnotmatch '^[a-f0-9]{64}$' -or
                -not $bindingProperty -or $null -eq $bindingProperty.Value) { return $null }
            $agendaDigest = [string]$digestProperty.Value
            $agendaBinding = $bindingProperty.Value
            if ((Get-SpecrewWorkshopAgendaDigest -Binding $agendaBinding) -cne $agendaDigest) { return $null }
        }
        $controllerPath = Join-Path (Join-Path (Join-Path $root 'specs') $featureRef) 'lens-applicability.json'
        if (-not (Test-Path -LiteralPath $controllerPath -PathType Leaf)) { return $null }
        $controller = Get-Content -LiteralPath $controllerPath -Raw -Encoding UTF8 -ErrorAction Stop |
            ConvertFrom-Json -Depth 20 -ErrorAction Stop
        if ([string]$controller.human_turn_contract -cne 'typed-turns-v1' -or
            [string]$controller.agenda_contract -cne 'complete-coverage-v1') { return $null }
        if ($phase -in @('product-domain', 'agenda') -and [string]$controller.agenda_status -cne 'pending-confirmation') { return $null }
        $featureRoot = Join-Path (Join-Path $root 'specs') $featureRef
        $hasProductMarkdown = Test-Path -LiteralPath (Join-Path $featureRoot 'workshop/product-domain.md') -PathType Leaf
        $hasProductStructured = Test-Path -LiteralPath (Join-Path $featureRoot 'workshop/product-domain.yml') -PathType Leaf
        if ($phase -eq 'product-domain' -and $hasProductMarkdown -and $hasProductStructured) { return $null }
        if ($phase -eq 'agenda' -and (-not $hasProductMarkdown -or -not $hasProductStructured)) { return $null }
        if ($phase -eq 'lens') {
            if ([string]$controller.agenda_status -cne 'confirmed' -or @($controller.selected) -cnotcontains $lens) { return $null }
            $recordProperty = if ($controller.PSObject.Properties['workshop']) { $controller.workshop.PSObject.Properties[$lens] } else { $null }
            if ($recordProperty -and $recordProperty.Value.PSObject.Properties['moved_on'] -and [bool]$recordProperty.Value.moved_on) { return $null }
        }

        $authority = Get-SpecrewWorkshopResponseAuthority -Phase $phase -Response $Response
        $responseHash = Get-SpecrewWorkshopAuthorityHash -Text $Response
        $receiptId = Get-SpecrewWorkshopAuthorityHash -Text ($featureRef + '|' + $phase + '|' + $lens + '|' + $questionHash + '|' + $agendaDigest + '|' + $responseHash)
        $record = [ordered]@{
            schema_version      = '1'
            receipt_id         = $receiptId
            feature_ref        = $featureRef
            iteration_number   = [string]$question.iteration_number
            phase              = $phase
            lens               = $lens
            question_hash      = $questionHash
            response_hash      = $responseHash
            confirmation       = [string]$authority.confirmation
            confirmation_scope = [string]$authority.confirmation_scope
            source_event       = $canonicalSourceEvent
            host_kind          = [string]$HostKind
            recorded_at        = [DateTimeOffset]::UtcNow.ToString('o')
        }
        if ($phase -eq 'agenda') {
            $record['agenda_digest'] = $agendaDigest
            $record['agenda_binding'] = $agendaBinding
        }

        $path = Get-SpecrewWorkshopAuthorityReceiptPath -ProjectRoot $root
        $dir = Split-Path -Parent $path
        if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        $line = ($record | ConvertTo-Json -Depth 5 -Compress) + [Environment]::NewLine
        $lockPath = $path + '.lock'
        $lockStream = $null
        try {
            $deadline = [DateTimeOffset]::UtcNow.AddSeconds(2)
            do {
                try { $lockStream = [IO.File]::Open($lockPath, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None) }
                catch { if ([DateTimeOffset]::UtcNow -ge $deadline) { throw }; Start-Sleep -Milliseconds 25 }
            } until ($null -ne $lockStream)
            [IO.File]::AppendAllText($path, $line, [Text.UTF8Encoding]::new($false))
        }
        finally {
            if ($null -ne $lockStream) { $lockStream.Dispose() }
            Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue
        }
        return [pscustomobject]$record
    }
    catch { return $null }
}

function Get-SpecrewWorkshopAuthorityReceipt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $ProjectRoot,
        [Parameter(Mandatory)][string] $FeatureRef,
        [Parameter(Mandatory)][ValidateSet('product-domain', 'agenda', 'lens')][string] $Phase,
        [AllowNull()][string] $Lens,
        [AllowNull()][string] $ReceiptId
    )

    $path = Get-SpecrewWorkshopAuthorityReceiptPath -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    try {
        $latest = $null
        foreach ($line in [IO.File]::ReadLines($path, [Text.Encoding]::UTF8)) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            if ([Text.Encoding]::UTF8.GetByteCount($line) -gt 65536) { throw 'workshop-authority-record-size-invalid' }
            try { $record = [string]$line | ConvertFrom-Json -Depth 8 -ErrorAction Stop }
            catch { throw 'workshop-authority-record-json-invalid' }
            if ([string]$record.schema_version -cne '1' -or [string]$record.feature_ref -cne $FeatureRef -or
                [string]$record.phase -cne $Phase) { continue }
            if (-not [string]::IsNullOrWhiteSpace($Lens) -and [string]$record.lens -cne $Lens) { continue }
            if (-not [string]::IsNullOrWhiteSpace($ReceiptId) -and [string]$record.receipt_id -cne $ReceiptId) { continue }
            $latest = $record
        }
        return $latest
    }
    catch { throw ('workshop-authority-store-invalid:' + $_.Exception.Message) }
}

function Test-SpecrewWorkshopAuthorityReceipt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $ProjectRoot,
        [Parameter(Mandatory)][string] $FeatureRef,
        [Parameter(Mandatory)][ValidateSet('product-domain', 'agenda', 'lens')][string] $Phase,
        [AllowNull()][string] $Lens,
        [Parameter(Mandatory)][string] $ReceiptId,
        [Parameter(Mandatory)][string] $Confirmation,
        [Parameter(Mandatory)][string] $ConfirmationScope,
        [AllowNull()][string] $AgendaDigest
    )

    $record = Get-SpecrewWorkshopAuthorityReceipt -ProjectRoot $ProjectRoot -FeatureRef $FeatureRef -Phase $Phase -Lens $Lens
    if ($null -eq $record) { return $false }
    $digestMatches = [string]::IsNullOrWhiteSpace($AgendaDigest) -or
        ($record.PSObject.Properties['agenda_digest'] -and [string]$record.agenda_digest -ceq $AgendaDigest)
    return ([string]$record.receipt_id -ceq $ReceiptId -and [string]$record.confirmation -ceq $Confirmation -and
        [string]$record.confirmation_scope -ceq $ConfirmationScope -and [string]$record.confirmation -cne 'invalid' -and $digestMatches)
}
