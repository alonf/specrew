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
    # DRIFT-199-I002-011's rule, one layer up: never enumerate a set by hand in several places when one
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
        # `confirmed-complete` IS IN THIS SET BECAUSE OF A STRANDED PROJECT, not for symmetry.
        # Measured on C:\Temp\ConsoleFractal, 2026-08-30: agenda confirmed, six technical lenses selected,
        # and `workshop` EMPTY - the intake lens never recorded. That state is reachable because
        # confirm-workshop-agenda requires the product-domain RECORDS on disk and not the controller entry,
        # so a workshop can pass the agenda with the intake lens still unclosed. From there both operations
        # refused: `confirm-intake-lens` because the state was no longer pending, `confirm-lens` because
        # product-domain is not in `selected` and never can be. The pending-only fix unblocked NEW
        # workshops and left every already-advanced project exactly as stuck - shipping it would have
        # stranded the projects it was written to save.
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
