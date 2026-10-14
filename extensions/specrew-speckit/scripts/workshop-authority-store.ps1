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

function Get-SpecrewWorkshopRepairProposalPath {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ProjectRoot)

    return Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/handover/workshop-controller-repair-proposal.json'
}

function Get-SpecrewWorkshopRepairAuthorityPath {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ProjectRoot)

    return Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/runtime/workshop-controller-repair-authority.jsonl'
}

function Get-SpecrewWorkshopFileSha256 {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    return ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([IO.File]::ReadAllBytes($Path)))).ToLowerInvariant()
}

function Get-SpecrewWorkshopIntakeLenses {
    # THE INTAKE LENSES: the ones that run BEFORE the agenda exists, and therefore can never appear in
    # `selected` - `selected` is the agenda's output, and these are its input.
    #
    # This set was previously implied in three places that could not disagree out loud: the agenda catalog
    # filtered `product-domain` out of the selectable lenses; the transition table had a
    # `pending-product-projection` state class for exactly one workshop key named `product-domain`; and the
    # receipt store's phase ValidateSet carried `product-domain` as a first-class phase beside `lens`. The
    # lens WRITER knew none of it, and refused the first lens of every workshop as "not one of the topics
    # this workshop agreed to cover" - which was true, and was never going to stop being true.
    # The rule, one layer up: never enumerate a set by hand in several places when one
    # definition can be read by all of them.
    [OutputType([string[]])]
    param()
    # NOT `return , @(...)`: the comma operator wraps the array in another array, so a `-ccontains` on the
    # result compares against a nested array and is always false. Callers wrap with @() themselves.
    return @('product-domain')
}

function Test-SpecrewWorkshopIntakeLens {
    [OutputType([bool])]
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Lens)
    return (@(Get-SpecrewWorkshopIntakeLenses) -ccontains $Lens)
}

function Resolve-SpecrewWorkshopStateTransition {
    # This is the finite pre-agenda transition contract shared by the writer, reader, and governed repair path.
    # Keep the state population closed and test every state x operation cell; a new state or operation must extend
    # that table before it can become reachable in production.
    [CmdletBinding()]
    param(
        [AllowNull()][object]$Controller,
        [Parameter(Mandatory)]
        [ValidateSet('initialize', 'read', 'render-agenda', 'confirm-agenda', 'confirm-lens', 'confirm-intake-lens', 'request-repair', 'apply-repair')]
        [string]$Operation
    )

    $stateClass = 'missing'
    if ($null -ne $Controller) {
        $agendaStatus = if ($Controller.PSObject.Properties['agenda_status']) { [string]$Controller.agenda_status } else { '' }
        if ($agendaStatus -eq 'pending-confirmation') {
            $selectedCount = if ($Controller.PSObject.Properties['selected']) { @($Controller.selected).Count } else { -1 }
            $workshopKeys = @()
            if ($Controller.PSObject.Properties['workshop'] -and $null -ne $Controller.workshop) {
                $workshopKeys = @($Controller.workshop.PSObject.Properties | ForEach-Object { [string]$_.Name })
            }
            else { $workshopKeys = @('__invalid__') }
            $technicalKeys = @($workshopKeys | Where-Object { $_ -cne 'product-domain' })
            $agendaCount = if ($Controller.PSObject.Properties['agenda'] -and $null -ne $Controller.agenda) { @($Controller.agenda.PSObject.Properties).Count } else { -1 }
            $skippedCount = if ($Controller.PSObject.Properties['skipped'] -and $null -ne $Controller.skipped) { @($Controller.skipped.PSObject.Properties).Count } else { -1 }
            $confirmation = if ($Controller.PSObject.Properties['agenda_confirmation']) { [string]$Controller.agenda_confirmation } else { '' }
            $confirmationScope = if ($Controller.PSObject.Properties['agenda_confirmation_scope']) { [string]$Controller.agenda_confirmation_scope } else { '' }
            $receipt = if ($Controller.PSObject.Properties['agenda_turn_receipt']) { [string]$Controller.agenda_turn_receipt } else { '' }
            $canonicalPending = ($selectedCount -eq 0 -and $technicalKeys.Count -eq 0 -and $agendaCount -eq 0 -and
                $skippedCount -eq 0 -and $confirmation -eq 'pending' -and $confirmationScope -eq 'lens-selection' -and $receipt -eq 'pending')
            if ($selectedCount -lt 0 -or $agendaCount -lt 0 -or $skippedCount -lt 0 -or $workshopKeys -contains '__invalid__') { $stateClass = 'invalid' }
            elseif ($canonicalPending -and $workshopKeys.Count -eq 0) { $stateClass = 'pending-empty' }
            elseif ($canonicalPending -and $workshopKeys.Count -eq 1 -and $workshopKeys[0] -ceq 'product-domain') { $stateClass = 'pending-product-projection' }
            else { $stateClass = 'pending-inconsistent' }
        }
        elseif ($agendaStatus -eq 'confirmed') {
            $selectedCount = if ($Controller.PSObject.Properties['selected']) { @($Controller.selected).Count } else { 0 }
            $agendaCount = if ($Controller.PSObject.Properties['agenda'] -and $null -ne $Controller.agenda) { @($Controller.agenda.PSObject.Properties).Count } else { 0 }
            $confirmation = if ($Controller.PSObject.Properties['agenda_confirmation']) { [string]$Controller.agenda_confirmation } else { '' }
            $stateClass = if ($selectedCount -gt 0 -and $agendaCount -eq $selectedCount -and $confirmation -eq 'human-confirmed') {
                'confirmed-complete'
            }
            else { 'confirmed-incomplete' }
        }
        else { $stateClass = 'invalid' }
    }

    $allowed = switch ($Operation) {
        'initialize' { $stateClass -eq 'missing' }
        'read' { $stateClass -in @('pending-empty', 'pending-product-projection', 'confirmed-complete') }
        'render-agenda' { $stateClass -in @('pending-empty', 'pending-product-projection') }
        'confirm-agenda' { $stateClass -in @('pending-empty', 'pending-product-projection') }
        # FR-027 (iteration 002, T018): a LENS closes only from a confirmed, complete agenda - the workshop
        # is running and the topic list is settled. Adding the operation to this closed table is what makes
        # the governed lens writer reachable at all; the table's own test pins every cell.
        'confirm-lens' { $stateClass -eq 'confirmed-complete' }
        # THE INTAKE LENS CLOSES BEFORE THE AGENDA EXISTS, because it is what produces the agenda. Closing
        # it from `pending-empty` is precisely how the controller reaches `pending-product-projection`, a
        # state class this table already had and nothing could legally produce. Without this cell the
        # workshop deadlocks at its first lens on EVERY greenfield feature: `confirm-lens` demanded a
        # confirmed agenda, and confirming the agenda demanded the product-domain records that only this
        # step persists. Two locally correct refusals, jointly a trap.
        # `confirmed-complete` IS IN THIS SET, AND SINCE 2026-09-09 NOTHING CAN ACT ON IT. Read this before
        # deleting it as dead.
        #
        # It was added for a stranded project: C:\Temp\ConsoleFractal, 2026-08-30 - agenda confirmed, six
        # technical lenses selected, `workshop` EMPTY, the intake lens never recorded. The recovery it enabled
        # was field-proved against that original specimen on 2026-09-01, on four checks, and none of the four
        # asked the reader what the recovery LEFT BEHIND. Measured 2026-09-09: it writes `product-domain` into
        # the map of a controller whose `selected` does not contain it, which the accessor reads as
        # `workshop-record-not-selected` - invalid, every lens stopped. That is the same state the router-skill
        # project was found in after a crew "restored" the cleared entry (B4F-035). The sanctioned recovery and
        # the corrupting repair were one operation.
        #
        # The stranded state also turned out to be INDISTINGUISHABLE from a healthy post-agenda one: confirming
        # an agenda clears the map by design, so `records on disk` and `receipt minted` are true of both. What
        # actually un-deadlocks the stranded projects is the reader tolerating the intake key, not this write.
        #
        # SO THE CELL STAYS AND confirm-workshop-lens.ps1 REFUSES DOWNSTREAM OF IT - deliberately, because that
        # is where the good message lives. Removing the cell would make this table produce the refusal instead,
        # and its text names the governed repair, which refuses every confirmed agenda and would clear nothing
        # (the remedy-wrong-for-state family, B4F-030). A permission nothing can use, with a refusal that tells
        # the reader the truth, beats a refusal that sends them somewhere that cannot help.
        'confirm-intake-lens' { $stateClass -in @('pending-empty', 'pending-product-projection', 'confirmed-complete') }
        'request-repair' { $stateClass -eq 'pending-inconsistent' }
        'apply-repair' { $stateClass -eq 'pending-inconsistent' }
    }
    return [pscustomobject]@{
        state_class = $stateClass
        operation   = $Operation
        allowed     = [bool]$allowed
        reason      = if ($allowed) { 'allowed' } else { 'workshop-transition-not-allowed' }
    }
}

function Get-SpecrewWorkshopRepairAuthorization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$ProposalId
    )

    $path = Get-SpecrewWorkshopRepairAuthorityPath -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    $latest = $null
    foreach ($line in [IO.File]::ReadLines($path, [Text.Encoding]::UTF8)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try { $record = $line | ConvertFrom-Json -Depth 6 -ErrorAction Stop }
        catch { throw 'workshop-repair-authority-store-invalid' }
        if ([string]$record.schema_version -cne '1' -or [string]$record.proposal_id -cne $ProposalId) { continue }
        if ([string]$record.authorization -cne 'human-approved') { throw 'workshop-repair-authority-record-invalid' }
        $latest = $record
    }
    return $latest
}

function Write-SpecrewWorkshopRepairAuthorization {
    # A repair is destructive to controller projections even though durable workshop files remain. It is therefore
    # authorized only by an exact typed human reply bound to the immutable proposal and current controller bytes.
    # SPECREW-AUTHORITY-CONTROL: workshop-repair-human-authorization
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$Response,
        [AllowNull()][string]$HostKind,
        [AllowNull()][string]$SourceEvent
    )

    if ($Response.Trim() -cne 'approved for workshop repair') { return $null }
    $canonicalSourceEvent = ConvertTo-SpecrewWorkshopSourceEvent -SourceEvent $SourceEvent
    if ($null -eq $canonicalSourceEvent -or -not (Test-SpecrewWorkshopHumanResponseText -Text $Response)) { return $null }
    $root = [IO.Path]::GetFullPath($ProjectRoot)
    if (Test-SpecrewWorkshopResponseIsHookOutput -ProjectRoot $root -Response $Response) { return $null }
    $proposalPath = Get-SpecrewWorkshopRepairProposalPath -ProjectRoot $root
    if (-not (Test-Path -LiteralPath $proposalPath -PathType Leaf)) { return $null }

    try {
        $proposal = Get-Content -LiteralPath $proposalPath -Raw -Encoding UTF8 -ErrorAction Stop |
            ConvertFrom-Json -Depth 8 -ErrorAction Stop
        if ([string]$proposal.schema_version -cne '1.0' -or [string]$proposal.feature_ref -cnotmatch '^[0-9]{3}-[a-z0-9][a-z0-9-]{0,63}$' -or
            [string]$proposal.proposal_id -cnotmatch '^[a-f0-9]{64}$' -or [string]$proposal.controller_sha256 -cnotmatch '^[a-f0-9]{64}$') { return $null }
        $controllerPath = Join-Path (Join-Path (Join-Path $root 'specs') ([string]$proposal.feature_ref)) 'lens-applicability.json'
        if (-not (Test-Path -LiteralPath $controllerPath -PathType Leaf) -or
            (Get-SpecrewWorkshopFileSha256 -Path $controllerPath) -cne [string]$proposal.controller_sha256) { return $null }
        $existing = Get-SpecrewWorkshopRepairAuthorization -ProjectRoot $root -ProposalId ([string]$proposal.proposal_id)
        if ($null -ne $existing) { return $existing }

        $record = [ordered]@{
            schema_version   = '1'
            proposal_id      = [string]$proposal.proposal_id
            feature_ref      = [string]$proposal.feature_ref
            controller_sha256 = [string]$proposal.controller_sha256
            authorization    = 'human-approved'
            response_hash    = Get-SpecrewWorkshopAuthorityHash -Text $Response.Trim()
            source_event     = $canonicalSourceEvent
            host_kind        = [string]$HostKind
            recorded_at      = [DateTimeOffset]::UtcNow.ToString('o')
        }
        $path = Get-SpecrewWorkshopRepairAuthorityPath -ProjectRoot $root
        $dir = Split-Path -Parent $path
        if (-not (Test-Path -LiteralPath $dir -PathType Container)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $lockPath = $path + '.lock'
        $lockStream = $null
        try {
            $deadline = [DateTimeOffset]::UtcNow.AddSeconds(2)
            do {
                try { $lockStream = [IO.File]::Open($lockPath, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None) }
                catch { if ([DateTimeOffset]::UtcNow -ge $deadline) { throw }; Start-Sleep -Milliseconds 25 }
            } until ($null -ne $lockStream)
            [IO.File]::AppendAllText($path, (($record | ConvertTo-Json -Depth 5 -Compress) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
        }
        finally {
            if ($null -ne $lockStream) { $lockStream.Dispose() }
            Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue
        }
        return [pscustomobject]$record
    }
    catch { return $null }
}

function Get-SpecrewWorkshopRefusalContractText {
    [CmdletBinding()]
    param(
        [ValidateSet('preserved', 'none')][string]$AnswerState = 'preserved'
    )

    $answerStatus = if ($AnswerState -eq 'preserved') {
        'Tell the human calmly what you were doing, that their answers are safe and nothing has been lost, and what you could not complete without assigning blame.'
    }
    else {
        'Tell the human calmly what you were doing, that no answer was recorded yet, and what you could not complete without assigning blame.'
    }
    return @(
        'Try the action above once. If it does not resolve the situation, do not retry and do not edit this project''s workshop records by hand.'
        $answerStatus
        'Give one concrete next action you can take and ask the human for approval before taking it.'
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
    # Feature 202 T003 (FR-003..FR-005): a reply is refused as authority only when it matches recorded hook output -
    # in the journal or in an outage-buffer file the dispatcher wrote while the journal was unavailable. The buffer is
    # read first, before this prompt decision. A legacy `.unhealthy` marker no longer refuses every reply (that was
    # the B4F-108 latch); the dispatcher clears it on its next good append. A store that cannot be READ right now
    # fails closed for this decision only.
    # T004 (FR-010): which of the three answers this was is kept for the caller, so a refusal can name its
    # actual cause - 'match' (the text is recorded hook output) or 'unavailable' (a store could not be read).
    $script:SpecrewWorkshopLastHookOutputCheck = 'none'
    $script:SpecrewWorkshopLastHookOutputSkipped = 0
    $runtimeDir = Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/runtime'
    $path = Join-Path $runtimeDir 'hook-output-authority.jsonl'
    $bufferDir = Join-Path $runtimeDir 'hook-output-buffer'
    $sources = @(if (Test-Path -LiteralPath $bufferDir -PathType Container) { Get-ChildItem -LiteralPath $bufferDir -File -Filter '*.jsonl' | ForEach-Object FullName })
    # A journal set aside by an approved recovery (T004, FR-009) still counts: its hashes are recorded hook output.
    $sources += @(Get-ChildItem -LiteralPath $runtimeDir -File -Filter 'hook-output-authority.set-aside-*.jsonl' -ErrorAction SilentlyContinue | ForEach-Object FullName)
    if (Test-Path -LiteralPath $path -PathType Leaf) { $sources += $path }
    if ($sources.Count -eq 0) { return $false }
    $hash = Get-SpecrewWorkshopAuthorityHash -Text $Response.Trim()
    foreach ($source in $sources) {
        try {
            $stream = [IO.File]::Open($source, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete)
            try {
                $reader = [IO.StreamReader]::new($stream, [Text.UTF8Encoding]::new($false))
                try { $content = $reader.ReadToEnd() } finally { $reader.Dispose() }
            }
            finally { $stream.Dispose() }
        }
        catch [IO.FileNotFoundException], [IO.DirectoryNotFoundException] { continue }  # a buffer file flushed between listing and reading
        catch { $script:SpecrewWorkshopLastHookOutputCheck = 'unavailable'; return $true }
        foreach ($line in @($content -split "`r?`n")) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            # Co-review round 1 (202): a malformed line used to THROW here, which escaped the receipt writer's outcome
            # handling and left the turn silent - and, since the line never goes away, refused every later reply: the
            # permanent latch FR-003 forbids. A line that cannot be parsed carries no hash, so it can authenticate
            # nothing; it is skipped and counted, and the decision rests on the records that can be read.
            try { $record = $line | ConvertFrom-Json -Depth 5 -ErrorAction Stop }
            catch { $script:SpecrewWorkshopLastHookOutputSkipped++; continue }
            # Co-review round 3: valid JSON is not yet a record. {} or an array or a bare value has no fields, and reading
            # one under StrictMode threw past the guard above - the same permanent refusal. The shape is checked first.
            if ($record -isnot [pscustomobject] -or -not $record.PSObject.Properties['schema_version'] -or -not $record.PSObject.Properties['output_hash'] -or
                [string]$record.schema_version -cne '1.0' -or [string]::IsNullOrWhiteSpace([string]$record.output_hash)) {
                $script:SpecrewWorkshopLastHookOutputSkipped++; continue
            }
            if ([string]$record.output_hash -ceq $hash) { $script:SpecrewWorkshopLastHookOutputCheck = 'match'; return $true }
        }
    }
    return $false
}

# Feature 202 T004 (FR-007, FR-010): every exit of the receipt writer leaves a typed outcome. Callers keep the
# receipt-or-$null contract; the outcome says WHY there is no receipt, so the same turn can say so.
$script:SpecrewWorkshopLastHookOutputCheck = 'none'
$script:SpecrewWorkshopLastHookOutputSkipped = 0
$script:SpecrewWorkshopLastReceiptOutcome = $null

function Set-SpecrewWorkshopReceiptOutcome {
    # status: recorded | not-applicable | refused | degraded. Only 'recorded' means the reply was used as the
    # answer (consumed). Every outcome other than not-applicable is journaled - hashes, never the reply text.
    param(
        [AllowNull()][string]$ProjectRoot,
        [Parameter(Mandatory)][ValidateSet('recorded', 'not-applicable', 'refused', 'degraded')][string]$Status,
        [Parameter(Mandatory)][string]$Reason,
        [AllowNull()][string]$FeatureRef,
        [AllowNull()][string]$Phase,
        [AllowNull()][string]$Response
    )
    $outcome = [pscustomobject]@{
        status      = $Status
        reason      = $Reason
        feature_ref = $FeatureRef
        phase       = $Phase
        consumed    = ($Status -eq 'recorded')
        recorded_at = [DateTimeOffset]::UtcNow.ToString('o')
    }
    $script:SpecrewWorkshopLastReceiptOutcome = $outcome
    if ($Status -ne 'not-applicable' -and -not [string]::IsNullOrWhiteSpace($ProjectRoot)) {
        try {
            $journal = Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/runtime/workshop-receipt-outcomes.jsonl'
            [IO.Directory]::CreateDirectory((Split-Path -Parent $journal)) | Out-Null
            $row = [ordered]@{
                schema_version = '1.0'; status = $Status; reason = $Reason; feature_ref = $FeatureRef; phase = $Phase
                consumed = $outcome.consumed; recorded_at = $outcome.recorded_at
                response_hash = if ([string]::IsNullOrWhiteSpace($Response)) { $null } else { Get-SpecrewWorkshopAuthorityHash -Text $Response }
            }
            [IO.File]::AppendAllText($journal, (($row | ConvertTo-Json -Compress) + "`n"), [Text.UTF8Encoding]::new($false))
        }
        catch { $null = $_ }  # the outcome journal is evidence; the in-turn disclosure does not depend on it
    }
    return $outcome
}

function Get-SpecrewWorkshopLastReceiptOutcome { return $script:SpecrewWorkshopLastReceiptOutcome }

function Get-SpecrewWorkshopLatestRefusal {
    # The newest refused/degraded outcome for one feature and phase, from the outcome journal; $null when none.
    param([Parameter(Mandatory)][string]$ProjectRoot, [Parameter(Mandatory)][string]$FeatureRef, [Parameter(Mandatory)][string]$Phase)
    $journal = Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/runtime/workshop-receipt-outcomes.jsonl'
    if (-not (Test-Path -LiteralPath $journal -PathType Leaf)) { return $null }
    $latest = $null
    foreach ($line in [IO.File]::ReadAllLines($journal, [Text.Encoding]::UTF8)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try { $row = $line | ConvertFrom-Json -ErrorAction Stop } catch { continue }
        if ($row -isnot [pscustomobject] -or -not $row.PSObject.Properties['feature_ref'] -or -not $row.PSObject.Properties['phase'] -or -not $row.PSObject.Properties['status']) { continue }  # co-review round 3: shape first
        if ([string]$row.feature_ref -ceq $FeatureRef -and [string]$row.phase -ceq $Phase -and [string]$row.status -in @('refused', 'degraded')) { $latest = $row }
    }
    return $latest
}

function Get-SpecrewWorkshopRefusalCauseText {
    # One sentence naming the actual cause, in project terms (FR-010; no internal nouns, never a channel the
    # human did not use).
    param([Parameter(Mandatory)][string]$Reason)
    switch ($Reason) {
        'matches-hook-output'              { return 'it repeats text Specrew itself showed, not an answer typed by you' }
        'not-typed-by-human'               { return 'it was added by the assistant''s host, not typed by you' }
        'record-check-unavailable'         { return 'Specrew could not read its own records to check the reply this turn' }
        'product-answers-already-recorded' { return 'the product-domain answers for this feature are already recorded' }
        'product-answers-missing'          { return 'the product-domain answers are not recorded yet, so there is no agenda to confirm' }
        'agenda-not-shown'                 { return 'the agenda it would confirm was not shown in the message before it' }
        'agenda-changed'                   { return 'the agenda changed after it was shown' }
        'agenda-already-confirmed'         { return 'the agenda is already confirmed' }
        'lens-not-on-agenda'               { return 'the question it answers is for a lens that is not on the confirmed agenda' }
        'lens-already-closed'              { return 'that lens is already closed' }
        'question-record-invalid'          { return 'the open question is not recorded in a form Specrew can bind an answer to' }
        'question-record-unreadable'       { return 'the open question could not be read' }
        'workshop-records-missing'         { return 'the feature''s workshop records are missing' }
        'workshop-records-incompatible'    { return 'the feature''s workshop records were written by an incompatible version' }
        'reply-write-failed'               { return 'Specrew could not write the record of the reply' }
        default                            { return 'Specrew could not match it to the open workshop question' }
    }
}

function Get-SpecrewWorkshopReceiptOutcomeDisclosure {
    # FR-007: a refused or degraded reply is said in the SAME turn, with whether it was used. Recovery wording never
    # implies loss when nothing is lost (rule feature-202.rule.recovery-wording-no-implied-loss). $null for an
    # outcome that needs no disclosure (recorded, or not a workshop reply at all).
    param([AllowNull()]$Outcome)
    if ($null -eq $Outcome -or [string]$Outcome.status -notin @('refused', 'degraded')) { return $null }
    $cause = Get-SpecrewWorkshopRefusalCauseText -Reason ([string]$Outcome.reason)
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add(("Specrew: your last reply was not used as your workshop answer, because {0}. The question is still open, and your earlier answers are unchanged." -f $cause)) | Out-Null
    switch ([string]$Outcome.reason) {
        'matches-hook-output'      { $lines.Add('Tell the human this in your reply, and ask them to type their answer in their own words if they meant it as one.') | Out-Null }
        'not-typed-by-human'       { $lines.Add('Tell the human this in your reply, and wait for their typed answer.') | Out-Null }
        'record-check-unavailable' { $lines.Add('Tell the human this in your reply. Nothing is deleted; they can send the same answer again next turn.') | Out-Null }
        'reply-write-failed'       { $lines.Add('Tell the human this in your reply. Nothing is deleted; they can send the same answer again next turn.') | Out-Null }
        default                    { $lines.Add('Tell the human this in your reply, in these words, before anything else.') | Out-Null }
    }
    return ($lines -join "`n")
}

# Feature 202 T004 (FR-009): when self-recovery has not happened - reply recording still degraded this long after it
# began - ask the human ONE decision, in the reference wording, and act only on their typed yes.
$script:SpecrewReplyRecordingRecoveryAfterMinutes = 10
$script:SpecrewReplyRecordingRecoveryQuestion = "Specrew couldn't record your reply safely. May I clear the stuck error so it can record again? Nothing is deleted."

function Get-SpecrewReplyRecordingDegradedSince {
    # The first-seen time of the open degraded episode (T003 health journal), or $null when not degraded.
    param([Parameter(Mandatory)][string]$ProjectRoot)
    $healthPath = Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/runtime/hook-output-health.jsonl'
    if (-not (Test-Path -LiteralPath $healthPath -PathType Leaf)) { return $null }
    try {
        $stream = [IO.File]::Open($healthPath, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
        try { $reader = [IO.StreamReader]::new($stream); $lines = @($reader.ReadToEnd() -split "`r?`n" | Where-Object { $_.Trim() }); $reader.Dispose() } finally { $stream.Dispose() }
        if ($lines.Count -eq 0) { return $null }
        $last = $lines[$lines.Count - 1] | ConvertFrom-Json -ErrorAction Stop
        if ([string]$last.state -ne 'degraded') { return $null }
        return [DateTimeOffset]::Parse([string]$last.first_seen, [Globalization.CultureInfo]::InvariantCulture)
    }
    catch { return $null }
}

function Get-SpecrewReplyRecordingRecoveryRequest {
    # The open recovery question for the CURRENT degraded episode, or $null. A request left from an episode that has
    # since recovered on its own - or from an earlier episode - is stale (co-review round 1): it is removed, so a later
    # unrelated "yes" can never be read as approval of a question that no longer stands.
    param([Parameter(Mandatory)][string]$ProjectRoot)
    $requestPath = Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/runtime/reply-recording-recovery-request.json'
    if (-not (Test-Path -LiteralPath $requestPath -PathType Leaf)) { return $null }
    $since = Get-SpecrewReplyRecordingDegradedSince -ProjectRoot $ProjectRoot
    $request = $null
    try { $request = [IO.File]::ReadAllText($requestPath, [Text.Encoding]::UTF8) | ConvertFrom-Json -ErrorAction Stop } catch { $request = $null }
    # ConvertFrom-Json turns an ISO timestamp into a DateTime, so the episode is compared as an instant, not as text.
    $requestSince = $null
    if ($null -ne $request -and $null -ne $request.degraded_since) {
        try {
            $requestSince = if ($request.degraded_since -is [datetime]) { [DateTimeOffset]$request.degraded_since }
            else { [DateTimeOffset]::Parse([string]$request.degraded_since, [Globalization.CultureInfo]::InvariantCulture) }
        }
        catch { $requestSince = $null }
    }
    $current = $null -ne $since -and $null -ne $requestSince -and
        $requestSince.UtcTicks -eq $since.UtcTicks -and
        [string]$request.question_hash -ceq (Get-SpecrewWorkshopAuthorityHash -Text $script:SpecrewReplyRecordingRecoveryQuestion)
    if (-not $current) {
        Remove-Item -LiteralPath $requestPath -Force -ErrorAction SilentlyContinue
        return $null
    }
    return [pscustomobject]@{ Path = $requestPath; Request = $request; DegradedSince = $since }
}

function Get-SpecrewReplyRecordingRecoveryAsk {
    # Returns the in-turn text that asks the recovery question when degraded past the threshold, and records that
    # the question is open (so the next typed yes is bound to it). $null when no ask is due.
    #
    # Co-review round 2: the request records the session it was asked in. The question is delivered to that one
    # session's turn, so only that session's typed yes can answer it - another session working in the same project
    # never saw it, and its "yes" belongs to whatever IT was asked.
    param([Parameter(Mandatory)][string]$ProjectRoot, [Parameter(Mandatory)][string]$NowUtc, [AllowNull()][string]$SessionId)
    $since = Get-SpecrewReplyRecordingDegradedSince -ProjectRoot $ProjectRoot
    if ($null -eq $since) { $null = Get-SpecrewReplyRecordingRecoveryRequest -ProjectRoot $ProjectRoot; return $null }
    $now = [DateTimeOffset]::Parse($NowUtc, [Globalization.CultureInfo]::InvariantCulture)
    if (($now - $since).TotalMinutes -lt $script:SpecrewReplyRecordingRecoveryAfterMinutes) { return $null }
    if ($null -ne (Get-SpecrewReplyRecordingRecoveryRequest -ProjectRoot $ProjectRoot)) { return $null }  # one decision per episode
    $requestPath = Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/runtime/reply-recording-recovery-request.json'
    try {
        [IO.Directory]::CreateDirectory((Split-Path -Parent $requestPath)) | Out-Null
        $request = [ordered]@{ schema_version = '1.0'; asked_at = $NowUtc; asked_session = [string]$SessionId; degraded_since = $since.ToString('o'); question_hash = Get-SpecrewWorkshopAuthorityHash -Text $script:SpecrewReplyRecordingRecoveryQuestion }
        [IO.File]::WriteAllText($requestPath, ($request | ConvertTo-Json -Compress), [Text.UTF8Encoding]::new($false))
    }
    catch { return $null }
    return ("Specrew: reply recording has not recovered on its own since {0}. Ask the human exactly this, as its own question, and wait for their typed answer: {1}" -f $since.ToString('o'), $script:SpecrewReplyRecordingRecoveryQuestion)
}

function Test-SpecrewReplyRecordingRecoveryApproval {
    # A short typed reply that approves and does not, anywhere in it, decline or hold off (co-review round 1: "okay,
    # do not clear it" and "yes, but leave the error alone" used to approve). Anything unclear is not approval; the
    # question stays open and the human can answer it plainly.
    param([AllowNull()][string]$Response)
    $trimmed = ([string]$Response).Trim()
    if ($trimmed.Length -eq 0 -or $trimmed.Length -gt 200 -or $trimmed.EndsWith('?')) { return $false }
    if ($trimmed -notmatch '(?i)^(?:yes|y|approved?|ok|okay|go ahead|do it|please do|sure)\b') { return $false }
    if ($trimmed -match "(?i)\b(?:no|not|never|don'?t|doesn'?t|won'?t|shouldn'?t|leave|keep|stop|wait|hold|cancel|later|but|instead)\b|n't\b") { return $false }
    return $true
}

function Invoke-SpecrewReplyRecordingRecoveryIfApproved {
    # When the recovery question is open and the human's TYPED reply approves it: record the approving reply FIRST
    # (FR-009 - no action without its receipt), then set the stuck record aside (moved, never deleted - its hashes
    # stay readable as recorded hook output), and record what happened. Returns the in-turn text, or $null when not
    # applicable.
    param([Parameter(Mandatory)][string]$ProjectRoot, [AllowNull()][string]$Response, [Parameter(Mandatory)][string]$NowUtc, [AllowNull()][string]$TurnOrigin, [AllowNull()][string]$SessionId)
    $root = [IO.Path]::GetFullPath($ProjectRoot)
    $runtime = Join-Path $root '.specrew/runtime'
    $open = Get-SpecrewReplyRecordingRecoveryRequest -ProjectRoot $root
    if ($null -eq $open) { return $null }
    if (-not [string]::IsNullOrWhiteSpace($TurnOrigin) -and $TurnOrigin -cne 'typed-user') { return $null }  # FR-006
    # Co-review round 2: only the session that was asked can answer. A request from a caller with no session id
    # (a direct call) binds nothing and keeps the text checks alone.
    $askedSession = if ($open.Request.PSObject.Properties['asked_session']) { [string]$open.Request.asked_session } else { '' }
    if (-not [string]::IsNullOrWhiteSpace($askedSession) -and [string]$SessionId -cne $askedSession) { return $null }
    if (-not (Test-SpecrewWorkshopHumanResponseText -Text $Response)) { return $null }
    if (-not (Test-SpecrewReplyRecordingRecoveryApproval -Response $Response)) { return $null }
    if (Test-SpecrewWorkshopResponseIsHookOutput -ProjectRoot $root -Response $Response) { return $null }

    $receiptPath = Join-Path $runtime 'reply-recording-recovery.jsonl'
    $responseHash = Get-SpecrewWorkshopAuthorityHash -Text $Response
    $questionHash = Get-SpecrewWorkshopAuthorityHash -Text $script:SpecrewReplyRecordingRecoveryQuestion
    try {
        $approval = [ordered]@{
            schema_version = '1.0'; approved_at = $NowUtc; response_hash = $responseHash; question_hash = $questionHash
            degraded_since = $open.DegradedSince.ToString('o'); action = 'set-aside-stuck-record'; result = 'approved'
        }
        [IO.File]::AppendAllText($receiptPath, (($approval | ConvertTo-Json -Compress) + "`n"), [Text.UTF8Encoding]::new($false))
    }
    catch {
        return 'Specrew: your approval could not be recorded this turn, so nothing was changed. Nothing is deleted. Tell the human, and that the same question is still open for their typed answer next turn.'
    }

    $stamp = ([DateTimeOffset]::Parse($NowUtc, [Globalization.CultureInfo]::InvariantCulture)).ToString('yyyyMMddTHHmmssZ')
    $journal = Join-Path $runtime 'hook-output-authority.jsonl'
    $legacy = $journal + '.unhealthy'
    $actions = New-Object System.Collections.Generic.List[string]
    $result = 'recovered'
    try {
        if (Test-Path -LiteralPath $journal -PathType Leaf) {
            $setAside = Join-Path $runtime ('hook-output-authority.set-aside-{0}.jsonl' -f $stamp)
            Move-Item -LiteralPath $journal -Destination $setAside -ErrorAction Stop
            $actions.Add(('record set aside as {0}' -f (Split-Path -Leaf $setAside))) | Out-Null
        }
        if (Test-Path -LiteralPath $legacy -PathType Leaf) {
            Move-Item -LiteralPath $legacy -Destination (Join-Path $runtime ('hook-output-authority.unhealthy.set-aside-{0}.txt' -f $stamp)) -ErrorAction Stop
            $actions.Add('older stuck error set aside') | Out-Null
        }
    }
    catch { $result = 'still-stuck'; $actions.Add(('could not set the record aside: {0}' -f $_.Exception.Message)) | Out-Null }
    try {
        $done = [ordered]@{
            schema_version = '1.0'; recorded_at = $NowUtc; response_hash = $responseHash; question_hash = $questionHash
            action = 'set-aside-stuck-record'; result = $result; details = @($actions)
        }
        [IO.File]::AppendAllText($receiptPath, (($done | ConvertTo-Json -Compress) + "`n"), [Text.UTF8Encoding]::new($false))
    }
    catch { $null = $_ }  # the approval is already recorded; this line only adds what the action did
    if ($result -eq 'recovered') {
        Remove-Item -LiteralPath $open.Path -Force -ErrorAction SilentlyContinue
        return 'Specrew: your approval was recorded and the stuck record was set aside, not deleted. Specrew starts a fresh record at its next write, and replies are checked against both. Tell the human it is done.'
    }
    return 'Specrew: your approval was recorded, but the stuck record could not be set aside yet because another process still holds it. Nothing is deleted. Tell the human, and that Specrew will try again when they next reply.'
}

function Get-SpecrewReplyRecordingDegradedDisclosure {
    # FR-007 (co-review round 1): while reply recording is degraded, the turn the human typed into says so and
    # whether their reply was used. $null when recording is healthy.
    param([Parameter(Mandatory)][string]$ProjectRoot, [AllowNull()]$Outcome)
    if ($null -eq (Get-SpecrewReplyRecordingDegradedSince -ProjectRoot $ProjectRoot)) { return $null }
    $used = if ($null -ne $Outcome -and [string]$Outcome.status -eq 'recorded') { 'your reply was used as your workshop answer' }
    elseif ($null -ne $Outcome -and [string]$Outcome.status -in @('refused', 'degraded')) { 'your reply was not used as your workshop answer' }
    else { 'your reply was handled normally' }
    return ("Specrew: replies are being recorded in a fallback record until the main one is free again; {0}, and nothing is lost. Mention this to the human in one sentence." -f $used)
}

function Write-SpecrewWorkshopAuthorityReceipt {
    # SPECREW-AUTHORITY-CONTROL: workshop-agenda-question-identity
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $ProjectRoot,
        [Parameter(Mandatory)][string] $Response,
        [AllowNull()][string] $HostKind,
        [AllowNull()][string] $SourceEvent,
        # Feature 202 (FR-006): the dispatcher's origin for this prompt. Only typed-user can produce a receipt; empty
        # means a direct caller with no turn record, where the text checks below are the whole decision.
        [AllowNull()][string] $TurnOrigin
    )

    $script:SpecrewWorkshopLastReceiptOutcome = $null
    $canonicalSourceEvent = ConvertTo-SpecrewWorkshopSourceEvent -SourceEvent $SourceEvent
    if ($null -eq $canonicalSourceEvent) { $null = Set-SpecrewWorkshopReceiptOutcome -Status 'not-applicable' -Reason 'not-a-prompt-event'; return $null }
    $root = [IO.Path]::GetFullPath($ProjectRoot)
    if (-not (Test-SpecrewWorkshopHumanResponseText -Text $Response)) { $null = Set-SpecrewWorkshopReceiptOutcome -Status 'not-applicable' -Reason 'host-or-specrew-text'; return $null }
    $questionPath = Join-Path $root '.specrew/handover/workshop-question.json'
    if (-not (Test-Path -LiteralPath $questionPath -PathType Leaf)) { $null = Set-SpecrewWorkshopReceiptOutcome -Status 'not-applicable' -Reason 'no-open-workshop-question'; return $null }

    # The question context is read first, so every refusal below can be journaled against its feature and phase.
    $featureRef = $null; $phase = $null
    try {
        $questionItem = Get-Item -LiteralPath $questionPath -ErrorAction Stop
        if ($questionItem.Length -le 0 -or $questionItem.Length -gt 65536) { $null = Set-SpecrewWorkshopReceiptOutcome -ProjectRoot $root -Status 'refused' -Reason 'question-record-unreadable' -Response $Response; return $null }
        $question = Get-Content -LiteralPath $questionPath -Raw -Encoding UTF8 -ErrorAction Stop |
            ConvertFrom-Json -Depth 10 -ErrorAction Stop
        if ([string]$question.status -cne 'workshop-active') { $null = Set-SpecrewWorkshopReceiptOutcome -Status 'not-applicable' -Reason 'workshop-not-active'; return $null }
        $featureRef = [string]$question.feature_ref
        $phase = [string]$question.phase
        if ([string]$question.schema -cne 'v3') { $null = Set-SpecrewWorkshopReceiptOutcome -ProjectRoot $root -Status 'refused' -Reason 'question-record-invalid' -FeatureRef $featureRef -Phase $phase -Response $Response; return $null }
    }
    catch { $null = Set-SpecrewWorkshopReceiptOutcome -ProjectRoot $root -Status 'refused' -Reason 'question-record-unreadable' -Response $Response; return $null }

    # FR-006 (co-review round 1): the origin the host's declared rules gave this prompt is enforced here, not only
    # passed along. A host-injected prompt (a task notification, a replayed stop reason, a dismissed question) or
    # one of unknown origin is never the human's answer, whatever its text looks like.
    #
    # Co-review round 2 (FR-010): 'unknown' is not proof the host added the reply. The dispatcher gives a typed prompt
    # that origin when its record check could not read the hook-output records, so the actual cause is that check -
    # degraded for this turn, said as such - and the human is not told their typed reply came from the host.
    if (-not [string]::IsNullOrWhiteSpace($TurnOrigin) -and $TurnOrigin -cne 'typed-user') {
        if ($TurnOrigin -ceq 'unknown') {
            $null = Set-SpecrewWorkshopReceiptOutcome -ProjectRoot $root -Status 'degraded' -Reason 'record-check-unavailable' -FeatureRef $featureRef -Phase $phase -Response $Response
        }
        else {
            $null = Set-SpecrewWorkshopReceiptOutcome -ProjectRoot $root -Status 'refused' -Reason 'not-typed-by-human' -FeatureRef $featureRef -Phase $phase -Response $Response
        }
        return $null
    }

    # Recorded hook output is never authority (FR-005). A check that could not read its records fails closed for
    # this turn only, and says so as its own cause rather than as a replay (FR-010).
    if (Test-SpecrewWorkshopResponseIsHookOutput -ProjectRoot $root -Response $Response) {
        $hookReason = if ($script:SpecrewWorkshopLastHookOutputCheck -eq 'unavailable') { 'record-check-unavailable' } else { 'matches-hook-output' }
        $hookStatus = if ($hookReason -eq 'record-check-unavailable') { 'degraded' } else { 'refused' }
        $null = Set-SpecrewWorkshopReceiptOutcome -ProjectRoot $root -Status $hookStatus -Reason $hookReason -FeatureRef $featureRef -Phase $phase -Response $Response
        return $null
    }

    try {
        $lens = [string]$question.lens
        $questionHash = [string]$question.message_hash
        $agendaDigest = ''
        $agendaBinding = $null
        if ($featureRef -cnotmatch '^[0-9]{3}-[a-z0-9][a-z0-9-]{0,63}$' -or
            $phase -cnotin @('product-domain', 'agenda', 'lens') -or
            [string]::IsNullOrWhiteSpace($questionHash)) { $null = Set-SpecrewWorkshopReceiptOutcome -ProjectRoot $root -Status 'refused' -Reason 'question-record-invalid' -FeatureRef $featureRef -Phase $phase -Response $Response; return $null }
        if ($phase -eq 'lens' -and $lens -cnotmatch '^[a-z][a-z0-9-]{1,63}$') { $null = Set-SpecrewWorkshopReceiptOutcome -ProjectRoot $root -Status 'refused' -Reason 'question-record-invalid' -FeatureRef $featureRef -Phase $phase -Response $Response; return $null }
        if ($phase -eq 'agenda') {
            $digestProperty = $question.PSObject.Properties['agenda_digest']
            $bindingProperty = $question.PSObject.Properties['agenda_binding']
            if (-not $digestProperty -or [string]$digestProperty.Value -cnotmatch '^[a-f0-9]{64}$' -or
                -not $bindingProperty -or $null -eq $bindingProperty.Value) { $null = Set-SpecrewWorkshopReceiptOutcome -ProjectRoot $root -Status 'refused' -Reason 'agenda-not-shown' -FeatureRef $featureRef -Phase $phase -Response $Response; return $null }
            $agendaDigest = [string]$digestProperty.Value
            $agendaBinding = $bindingProperty.Value
            if ((Get-SpecrewWorkshopAgendaDigest -Binding $agendaBinding) -cne $agendaDigest) { $null = Set-SpecrewWorkshopReceiptOutcome -ProjectRoot $root -Status 'refused' -Reason 'agenda-changed' -FeatureRef $featureRef -Phase $phase -Response $Response; return $null }
        }
        $controllerPath = Join-Path (Join-Path (Join-Path $root 'specs') $featureRef) 'lens-applicability.json'
        if (-not (Test-Path -LiteralPath $controllerPath -PathType Leaf)) { $null = Set-SpecrewWorkshopReceiptOutcome -ProjectRoot $root -Status 'refused' -Reason 'workshop-records-missing' -FeatureRef $featureRef -Phase $phase -Response $Response; return $null }
        $controller = Get-Content -LiteralPath $controllerPath -Raw -Encoding UTF8 -ErrorAction Stop |
            ConvertFrom-Json -Depth 20 -ErrorAction Stop
        if ([string]$controller.human_turn_contract -cne 'typed-turns-v1' -or
            [string]$controller.agenda_contract -cne 'complete-coverage-v1') { $null = Set-SpecrewWorkshopReceiptOutcome -ProjectRoot $root -Status 'refused' -Reason 'workshop-records-incompatible' -FeatureRef $featureRef -Phase $phase -Response $Response; return $null }
        if ($phase -in @('product-domain', 'agenda') -and [string]$controller.agenda_status -cne 'pending-confirmation') { $null = Set-SpecrewWorkshopReceiptOutcome -ProjectRoot $root -Status 'refused' -Reason 'agenda-already-confirmed' -FeatureRef $featureRef -Phase $phase -Response $Response; return $null }
        $featureRoot = Join-Path (Join-Path $root 'specs') $featureRef
        $hasProductMarkdown = Test-Path -LiteralPath (Join-Path $featureRoot 'workshop/product-domain.md') -PathType Leaf
        $hasProductStructured = Test-Path -LiteralPath (Join-Path $featureRoot 'workshop/product-domain.yml') -PathType Leaf
        # The product-records refusal (T004 acceptance): disclosed with its cause, not silent.
        if ($phase -eq 'product-domain' -and $hasProductMarkdown -and $hasProductStructured) { $null = Set-SpecrewWorkshopReceiptOutcome -ProjectRoot $root -Status 'refused' -Reason 'product-answers-already-recorded' -FeatureRef $featureRef -Phase $phase -Response $Response; return $null }
        if ($phase -eq 'agenda' -and (-not $hasProductMarkdown -or -not $hasProductStructured)) { $null = Set-SpecrewWorkshopReceiptOutcome -ProjectRoot $root -Status 'refused' -Reason 'product-answers-missing' -FeatureRef $featureRef -Phase $phase -Response $Response; return $null }
        if ($phase -eq 'lens') {
            if ([string]$controller.agenda_status -cne 'confirmed' -or @($controller.selected) -cnotcontains $lens) { $null = Set-SpecrewWorkshopReceiptOutcome -ProjectRoot $root -Status 'refused' -Reason 'lens-not-on-agenda' -FeatureRef $featureRef -Phase $phase -Response $Response; return $null }
            $recordProperty = if ($controller.PSObject.Properties['workshop']) { $controller.workshop.PSObject.Properties[$lens] } else { $null }
            if ($recordProperty -and $recordProperty.Value.PSObject.Properties['moved_on'] -and [bool]$recordProperty.Value.moved_on) { $null = Set-SpecrewWorkshopReceiptOutcome -ProjectRoot $root -Status 'refused' -Reason 'lens-already-closed' -FeatureRef $featureRef -Phase $phase -Response $Response; return $null }
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
        $null = Set-SpecrewWorkshopReceiptOutcome -ProjectRoot $root -Status 'recorded' -Reason 'recorded' -FeatureRef $featureRef -Phase $phase -Response $Response
        return [pscustomobject]$record
    }
    catch {
        $null = Set-SpecrewWorkshopReceiptOutcome -ProjectRoot $root -Status 'degraded' -Reason 'reply-write-failed' -FeatureRef $featureRef -Phase $phase -Response $Response
        return $null
    }
}

function Get-SpecrewWorkshopReceiptDisclosure {
    # PRED-BETA4-053: a typed confirmation the receipt writer CANNOT bind is said, in the turn, with the remedy.
    # Measured on the walk project (e9334af1): the canonical agenda block had been rendered only as a tool
    # result, the assistant turn before the confirm did not contain it, the Stop hook therefore bound no
    # agenda digest into workshop-question.json, and Write-SpecrewWorkshopAuthorityReceipt returned $null at
    # prompt entry - silently, one of its twelve exits. The coordinator learned of it when the persist threw.
    # The verdict path got this disclosure in beta4 (PRED-026); this is the workshop path's. Narrow by
    # construction: agenda phase only (the one with a visibility proof to read), a confirmation-shaped reply,
    # and the question active without a digest. Lens questions carry no visibility proof; not covered here.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $ProjectRoot,
        [AllowNull()][string] $Response
    )
    try {
        if (-not (Test-SpecrewWorkshopHumanResponseText -Text $Response)) { return $null }
        $root = [IO.Path]::GetFullPath($ProjectRoot)
        if (Test-SpecrewWorkshopResponseIsHookOutput -ProjectRoot $root -Response $Response) { return $null }
        $questionPath = Join-Path $root '.specrew/handover/workshop-question.json'
        if (-not (Test-Path -LiteralPath $questionPath -PathType Leaf)) { return $null }
        $question = Get-Content -LiteralPath $questionPath -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -Depth 10 -ErrorAction Stop
        if ([string]$question.schema -cne 'v3' -or [string]$question.status -cne 'workshop-active' -or [string]$question.phase -cne 'agenda') { return $null }
        $digestProperty = $question.PSObject.Properties['agenda_digest']
        if ($digestProperty -and [string]$digestProperty.Value -cmatch '^[a-f0-9]{64}$') { return $null }   # visible and bound: the receipt handles it
        # A question is not a confirmation, whatever the classifier would bind (it binds any non-skip reply on
        # the agenda); the disclosure names a confirmation, so it fires only for a reply that reads as one.
        if (($Response -replace '\s+', ' ').Trim().EndsWith('?')) { return $null }
        $authority = Get-SpecrewWorkshopResponseAuthority -Phase 'agenda' -Response $Response
        if ([string]$authority.confirmation -cne 'human-confirmed') { return $null }
        $line = "Specrew: your agenda confirmation was received but NOT bound - the canonical agenda block was not in the assistant's previous message (a tool result is not a message), so nothing was recorded. Render the block in your message, then ask again."
        try {
            $journal = Join-Path $root '.specrew/runtime/handover-journal.jsonl'
            $dir = Split-Path -Parent $journal
            if (-not (Test-Path -LiteralPath $dir -PathType Container)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            $row = [ordered]@{
                event = 'workshop-confirmation-not-bound-disclosed'; recorded_at = [DateTimeOffset]::UtcNow.ToString('o')
                feature_ref = [string]$question.feature_ref; phase = 'agenda'; reason = 'agenda-block-not-in-assistant-message'
                response_hash = (Get-SpecrewWorkshopAuthorityHash -Text $Response)
            }
            [IO.File]::AppendAllText($journal, (($row | ConvertTo-Json -Compress -Depth 5) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
        }
        catch { $null = $_ }
        return $line
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
