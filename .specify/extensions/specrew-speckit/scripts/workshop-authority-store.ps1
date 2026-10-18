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

function Test-SpecrewWorkshopReviewerPick {
    # Co-review round 6 (iteration 002; FR-031, DA-4): a reply that only names the reviewer - a reviewer host or the default,
    # with nothing but the words of a choice around it ("Use codex as the reviewer.", "copilot", "Confirm the default
    # reviewer.", "The reviewer is claude."). It is the one confirmed reply that may follow a wide delegation without taking
    # the lens back. Anything more is an answer to the lens.
    # Co-review round 7 (iteration 002): bound to the question it answers. 'Use the default.' to 'Use SQLite or the default
    # in-memory store?' is a craft answer, and was passed over as a reviewer pick. A reply that does not itself say
    # "reviewer" or "review" is a reviewer pick only when the open question asks about the reviewer.
    [OutputType([bool])]
    param([AllowNull()][AllowEmptyString()][string] $Response, [AllowNull()][AllowEmptyString()][string] $Question)
    $normalized = (($Response -replace '\s+', ' ').Trim().ToLowerInvariant()) -replace '[.!]+$', ''
    if ([string]::IsNullOrWhiteSpace($normalized)) { return $false }
    $aboutReview = '\breview(?:er|ers|s|ing)?\b'
    if ($normalized -notmatch $aboutReview -and ([string]$Question).ToLowerInvariant() -notmatch $aboutReview) { return $false }
    $reviewer = '(?:the\s+)?(?:default|codex|copilot|claude|cursor|gemini|antigravity|agy)(?:\s+(?:reviewer|host|one))?'
    $choice = '(?:(?:yes|ok(?:ay)?|sure|confirm(?:ed)?)[\s,:;-]+)?(?:(?:i\s+)?(?:use|keep|pick|choose|want|go\s+with)\s+|let''?s\s+(?:use|go\s+with)\s+)?'
    $role = '(?:\s+(?:as|for)\s+(?:the\s+)?review(?:er|s)?)?(?:\s+(?:is\s+fine|please))?'
    if ($normalized -match ('^' + $choice + $reviewer + $role + '$')) { return $true }
    return [bool]($normalized -match ('^(?:the\s+)?reviewer(?:\s+is|\s+should\s+be|:)\s+' + $reviewer + '(?:\s+please)?$'))
}

function Test-SpecrewWorkshopWideDelegation {
    # Feature 202 iteration 002, T020 (FR-031, DA-4; B4F-130): the exact wide forms of a delegation. "you decide the
    # remaining lenses" and "you decide all remaining lenses" cover every lens left on the agenda. "the rest" is NOT one:
    # it can mean the rest of this lens. Only a reply that is already a delegation is asked.
    # Co-review round 5 (iteration 002): the wide form is the WHOLE reply - the delegation and the remaining lenses, and
    # nothing else. 'you decide this lens, not all remaining lenses' mentions the phrase to limit the delegation, and a
    # match anywhere in the reply recorded it for every open lens.
    param([AllowNull()][string] $Response)
    $normalized = ([string]$Response -replace '\s+', ' ').Trim().ToLowerInvariant()
    return ($normalized -match '^(?:please\s+)?(?:you decide|decide for me|choose for me|use your (?:best )?judg(?:e)?ment)(?:\s+(?:on|for))?\s+(?:the|all(?:\s+the)?)\s+remaining\s+lenses(?:\s+please)?\s*[.!]?$')
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

    # Co-review rounds 3 and 4 (202 iteration 002, FR-027): a non-match is an explicit `return $null` below - a stale or
    # malformed proposal, a moved controller. Anything that THROWS from here on (an unreadable proposal, an existing
    # record that cannot be read, a save that fails) is a failure, not a non-match: it propagates, so the authority
    # router reports the approval as received but not saved instead of dropping it silently.
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
$script:SpecrewWorkshopLastDelegation = $null

# Feature 202 T022 (FR-033, DA-5; R5-5): THE RECEIPT OUTCOME LIVES IN THE SESSION'S OWN FOLDER.
#
# It used to be appended to one journal shared by every session in the project, and both readers - the dispatcher's
# same-turn disclosure and the Stop's latest-refusal check - filtered it after the fact. A refusal in one session could
# then show in another (R5-5). Now each session keeps its own record beside its turn records, under the same per-session
# folder the turn-end store resolves, and the readers read only that. Hashes, never the reply text.
function Get-SpecrewWorkshopReceiptOutcomePath {
    param([Parameter(Mandatory)][string]$ProjectRoot, [AllowNull()][string]$HostKind, [AllowNull()][string]$SessionId)
    $runtimeRoot = Join-Path ([IO.Path]::GetFullPath($ProjectRoot)) '.specrew/runtime'
    # The same arithmetic as Get-SpecrewTurnEndOwnerHash (turn-end-store.ps1), so the record sits in the session's own
    # folder; a session-less host keeps one record at the runtime root, as its turn records do.
    $owner = ''
    if (-not [string]::IsNullOrWhiteSpace($SessionId)) {
        $safeHost = if ([string]::IsNullOrWhiteSpace($HostKind)) { 'unknown' } else { (($HostKind -replace '[^a-zA-Z0-9-]+', '-').Trim('-').ToLowerInvariant()) }
        $safeSession = (($SessionId -replace '[^a-zA-Z0-9-]+', '-').Trim('-'))
        if (-not [string]::IsNullOrWhiteSpace($safeSession)) {
            $bytes = [Text.Encoding]::UTF8.GetBytes(('{0}|{1}' -f $safeHost, $safeSession))
            $owner = -join ([Security.Cryptography.SHA256]::Create().ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') })
        }
    }
    $stateRoot = if ([string]::IsNullOrWhiteSpace($owner)) { $runtimeRoot } else { Join-Path (Join-Path $runtimeRoot 'conformance-sessions') $owner }
    return (Join-Path $stateRoot 'workshop-receipt-outcome.json')
}

function Read-SpecrewWorkshopReceiptOutcomeRecord {
    # The session's record, or $null when absent or unreadable. Shape: { schema_version; last; refusals{feature|phase} }.
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    try {
        $record = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -Depth 8 -ErrorAction Stop
        if ($record -isnot [pscustomobject] -or -not $record.PSObject.Properties['schema_version'] -or [string]$record.schema_version -cne '1.0') { return $null }
        return $record
    }
    catch { return $null }
}

function Set-SpecrewWorkshopReceiptOutcome {
    # status: recorded | not-applicable | refused | degraded. Only 'recorded' means the reply was used as the
    # answer (consumed). Every outcome other than not-applicable is recorded in the session's own folder.
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
        $temp = $null
        try {
            $path = Get-SpecrewWorkshopReceiptOutcomePath -ProjectRoot $ProjectRoot -HostKind ([string]$script:SpecrewWorkshopReceiptHostKind) -SessionId ([string]$script:SpecrewWorkshopReceiptSessionId)
            [IO.Directory]::CreateDirectory((Split-Path -Parent $path)) | Out-Null
            $row = [ordered]@{
                status = $Status; reason = $Reason; feature_ref = $FeatureRef; phase = $Phase
                consumed = $outcome.consumed; recorded_at = $outcome.recorded_at
                response_hash = if ([string]::IsNullOrWhiteSpace($Response)) { $null } else { Get-SpecrewWorkshopAuthorityHash -Text $Response }
                session_id = if ([string]::IsNullOrWhiteSpace([string]$script:SpecrewWorkshopReceiptSessionId)) { $null } else { [string]$script:SpecrewWorkshopReceiptSessionId }
            }
            # The latest outcome (the same-turn disclosure reads it) and, per feature and phase, the latest refusal (the
            # Stop's check reads it), so a later used reply does not hide why an earlier one was refused.
            $refusals = [ordered]@{}
            $existing = Read-SpecrewWorkshopReceiptOutcomeRecord -Path $path
            if ($null -ne $existing -and $existing.PSObject.Properties['refusals'] -and $existing.refusals -is [pscustomobject]) {
                foreach ($p in $existing.refusals.PSObject.Properties) { $refusals[$p.Name] = $p.Value }
            }
            if ($Status -in @('refused', 'degraded')) { $refusals[('{0}|{1}' -f $FeatureRef, $Phase)] = $row }
            $record = [ordered]@{ schema_version = '1.0'; last = $row; refusals = $refusals }
            $temp = $path + '.tmp-' + [guid]::NewGuid().ToString('N')
            [IO.File]::WriteAllText($temp, ($record | ConvertTo-Json -Depth 8 -Compress), [Text.UTF8Encoding]::new($false))
            [IO.File]::Move($temp, $path, $true)
        }
        catch { $null = $_ }  # the outcome record is evidence; the in-turn disclosure does not depend on it
        finally { if ($null -ne $temp -and (Test-Path -LiteralPath $temp -PathType Leaf)) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue } }
    }
    return $outcome
}

function Get-SpecrewWorkshopLastReceiptOutcome { return $script:SpecrewWorkshopLastReceiptOutcome }

function Get-SpecrewWorkshopLatestRefusal {
    # The newest refused/degraded outcome for one feature and phase IN THIS SESSION; $null when none (T022, R5-5).
    param([Parameter(Mandatory)][string]$ProjectRoot, [Parameter(Mandatory)][string]$FeatureRef, [Parameter(Mandatory)][string]$Phase,
        [AllowNull()][string]$HostKind, [AllowNull()][string]$SessionId)
    $record = Read-SpecrewWorkshopReceiptOutcomeRecord -Path (Get-SpecrewWorkshopReceiptOutcomePath -ProjectRoot $ProjectRoot -HostKind $HostKind -SessionId $SessionId)
    if ($null -eq $record -or -not $record.PSObject.Properties['refusals'] -or $record.refusals -isnot [pscustomobject]) { return $null }
    $row = $record.refusals.PSObject.Properties[('{0}|{1}' -f $FeatureRef, $Phase)]
    if ($null -eq $row -or $row.Value -isnot [pscustomobject] -or -not $row.Value.PSObject.Properties['status'] -or -not $row.Value.PSObject.Properties['reason']) { return $null }  # co-review round 3: shape first
    if ([string]$row.Value.status -notin @('refused', 'degraded')) { return $null }
    return $row.Value
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
$script:SpecrewWorkshopReceiptSessionId = $null
$script:SpecrewWorkshopReceiptHostKind = $null
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
    $openRequest = Get-SpecrewReplyRecordingRecoveryRequest -ProjectRoot $ProjectRoot
    # Co-review round 5 (202): the human already said no in this episode; no session asks it again until it ends.
    if ($null -ne $openRequest -and (Test-SpecrewReplyRecordingRecoveryDeclined -Request $openRequest.Request)) { return $null }
    if ($null -ne $openRequest) {
        # One decision per episode - in the session that holds it. Co-review round 4 (202, FR-009): a question asked in
        # a session that then ended could be answered by no one (only the asked session's yes counts), and it kept every
        # other session from being asked. Once it has stood unanswered for the recovery threshold, the next session is
        # asked again and the question becomes that session's, so a late yes from the old one no longer answers it. Two
        # live sessions therefore take it over at most once per threshold, never back and forth on every prompt.
        $askedSession = if ($openRequest.Request.PSObject.Properties['asked_session']) { [string]$openRequest.Request.asked_session } else { '' }
        if ([string]::IsNullOrWhiteSpace($SessionId) -or [string]::IsNullOrWhiteSpace($askedSession) -or $askedSession -ceq [string]$SessionId) { return $null }
        $askedAt = $null
        try {
            $rawAsked = $openRequest.Request.asked_at
            $askedAt = if ($rawAsked -is [datetime]) { [DateTimeOffset]$rawAsked } else { [DateTimeOffset]::Parse([string]$rawAsked, [Globalization.CultureInfo]::InvariantCulture) }
        }
        catch { $askedAt = $null }
        if ($null -ne $askedAt -and ($now - $askedAt).TotalMinutes -lt $script:SpecrewReplyRecordingRecoveryAfterMinutes) { return $null }
    }
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
    # Co-review round 5 (202): a yes with a condition ("yes, after I finish the other session", "yes, if the next append
    # fails") is not yet a yes - the record was set aside before the condition held. The words are the shared hedge set
    # (Get-SpecrewConditionalConjunctionPattern, which this store does not load), plus the times people defer to.
    $conditional = if (Get-Command Get-SpecrewConditionalConjunctionPattern -ErrorAction SilentlyContinue) { Get-SpecrewConditionalConjunctionPattern }
    else { '(?:later|after|once|when|unless|if|provided|providing|assuming|contingent|subject\s+to|as\s+long\s+as|so\s+long\s+as|pending)' }
    if ($trimmed -match ('(?i)\b' + $conditional + '\b') -or $trimmed -match '(?i)\b(?:until|whenever|tomorrow|tonight)\b') { return $false }
    return $true
}

function Test-SpecrewReplyRecordingRecoveryDecline {
    # Co-review round 5 (202): a typed reply that plainly declines the recovery question. Only a LEADING refusal counts,
    # so a reply about something else is never taken as this decision; anything unclear leaves the question open.
    param([AllowNull()][string]$Response)
    $trimmed = ([string]$Response).Trim()
    if ($trimmed.Length -eq 0 -or $trimmed.Length -gt 200 -or $trimmed.EndsWith('?')) { return $false }
    return [bool]($trimmed -match "(?i)^(?:no|n|nope|don'?t|do not|leave it|not now|keep it)\b")
}

function Test-SpecrewReplyRecordingRecoveryDeclined {
    # Whether the open request already carries the human's decline: one decision per episode, so it approves nothing
    # and is not asked again until the episode ends.
    param([AllowNull()]$Request)
    return ($null -ne $Request -and $null -ne $Request.PSObject.Properties['declined_at'] -and -not [string]::IsNullOrWhiteSpace([string]$Request.declined_at))
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
    if (Test-SpecrewReplyRecordingRecoveryDeclined -Request $open.Request) { return $null }
    if (-not (Test-SpecrewWorkshopHumanResponseText -Text $Response)) { return $null }
    if (Test-SpecrewWorkshopResponseIsHookOutput -ProjectRoot $root -Response $Response) { return $null }

    $receiptPath = Join-Path $runtime 'reply-recording-recovery.jsonl'
    $responseHash = Get-SpecrewWorkshopAuthorityHash -Text $Response
    $questionHash = Get-SpecrewWorkshopAuthorityHash -Text $script:SpecrewReplyRecordingRecoveryQuestion
    # Co-review round 5 (202): a plain "no" is the human's decision on this question, not silence. It is recorded, the
    # request is closed for the episode (so a later, unrelated "yes" cannot approve it), and the turn says so - which
    # also keeps the "no" from being taken as a workshop answer.
    if (Test-SpecrewReplyRecordingRecoveryDecline -Response $Response) {
        try {
            $decline = [ordered]@{
                schema_version = '1.0'; recorded_at = $NowUtc; response_hash = $responseHash; question_hash = $questionHash
                degraded_since = $open.DegradedSince.ToString('o'); action = 'set-aside-stuck-record'; result = 'declined'
            }
            [IO.File]::AppendAllText($receiptPath, (($decline | ConvertTo-Json -Compress) + "`n"), [Text.UTF8Encoding]::new($false))
            # The field is added to the request's own text, so its episode stamp stays byte-for-byte what was asked.
            $raw = [IO.File]::ReadAllText($open.Path, [Text.Encoding]::UTF8).TrimEnd()
            if (-not $raw.EndsWith('}')) { throw 'the open request is not a JSON object' }
            $closed = $raw.Substring(0, $raw.Length - 1) + ',"declined_at":' + ($NowUtc | ConvertTo-Json) + '}'
            [IO.File]::WriteAllText($open.Path, $closed, [Text.UTF8Encoding]::new($false))
        }
        catch {
            return 'Specrew: your answer could not be recorded this turn, so nothing was changed. Nothing is deleted. Tell the human, and that the same question is still open for their typed answer next turn.'
        }
        return 'Specrew: your answer was recorded: the stuck record is left as it is, and nothing was changed. You will not be asked again while this lasts. Tell the human in one sentence.'
    }
    if (-not (Test-SpecrewReplyRecordingRecoveryApproval -Response $Response)) { return $null }
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

function Get-SpecrewReplyUsedText {
    # Whether the human's reply was used, from its receipt outcome - the clause every recording disclosure carries.
    param([AllowNull()]$Outcome)
    if ($null -ne $Outcome -and [string]$Outcome.status -eq 'recorded') { return 'your reply was used as your workshop answer' }
    if ($null -ne $Outcome -and [string]$Outcome.status -in @('refused', 'degraded')) { return 'your reply was not used as your workshop answer' }
    return 'your reply was handled normally'
}

function Get-SpecrewReplyRecordingDegradedDisclosure {
    # FR-007 (co-review round 1): while reply recording is degraded, the turn the human typed into says so and
    # whether their reply was used. $null when recording is healthy.
    param([Parameter(Mandatory)][string]$ProjectRoot, [AllowNull()]$Outcome)
    if ($null -eq (Get-SpecrewReplyRecordingDegradedSince -ProjectRoot $ProjectRoot)) { return $null }
    return ("Specrew: replies are being recorded in a fallback record until the main one is free again; {0}, and nothing is lost. Mention this to the human in one sentence." -f (Get-SpecrewReplyUsedText -Outcome $Outcome))
}

function Get-SpecrewReplyRecordingWithheldDisclosure {
    # Co-review round 3 (202, FR-005 + FR-007): when this turn's output could be neither journaled nor buffered, FR-005
    # withholds it - and the turn must still say so. This sentence is the only text then shown. It is unrecorded, so it
    # starts with 'Specrew:', which Test-SpecrewWorkshopHumanResponseText never accepts as a typed reply.
    param([AllowNull()]$Outcome)
    return ("Specrew: this turn's Specrew guidance could not be recorded safely, so it was held back; {0}, and nothing is lost. Mention this to the human in one sentence." -f (Get-SpecrewReplyUsedText -Outcome $Outcome))
}

function Get-SpecrewWorkshopTurnReceiptOutcome {
    # Co-review round 3 (202): the receipt outcome journaled at or after -Since (one hook fire), or $null. The dispatcher
    # composes its disclosure AFTER the provider that used or refused the reply has exited, so it reads the outcome from
    # the journal that provider wrote, not from memory.
    #
    # Co-review round 5 (202, FR-007): the journal is shared by every session in the project, so a time bound alone picked
    # up another session's outcome and told this human their reply was used. A row counts only when it answers THIS
    # reply (its hash) and, when both sides know it, was typed in THIS session. No reply, no outcome.
    #
    # Feature 202 T022 (FR-033, DA-5): the outcome is read from THIS session's own record, so another session's outcome
    # is never in reach; the hash and time checks stay, so a stale outcome of this session is not this turn's either.
    param([Parameter(Mandatory)][string]$ProjectRoot, [Parameter(Mandatory)][DateTimeOffset]$Since, [AllowNull()][string]$Response, [AllowNull()][string]$SessionId,
        [AllowNull()][string]$HostKind)
    if ([string]::IsNullOrWhiteSpace($Response)) { return $null }
    $responseHash = Get-SpecrewWorkshopAuthorityHash -Text $Response
    try {
        $record = Read-SpecrewWorkshopReceiptOutcomeRecord -Path (Get-SpecrewWorkshopReceiptOutcomePath -ProjectRoot $ProjectRoot -HostKind $HostKind -SessionId $SessionId)
        if ($null -eq $record -or -not $record.PSObject.Properties['last']) { return $null }
        $row = $record.last
        if ($row -isnot [pscustomobject] -or -not $row.PSObject.Properties['status'] -or -not $row.PSObject.Properties['recorded_at']) { return $null }
        $at = $null
        try { $at = [DateTimeOffset]$row.recorded_at } catch { $at = $null }
        if ($null -eq $at -or $at -lt $Since) { return $null }
        if (-not $row.PSObject.Properties['response_hash'] -or [string]$row.response_hash -cne $responseHash) { return $null }
        return $row
    }
    catch { return $null }
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
        [AllowNull()][string] $TurnOrigin,
        # Co-review round 5 (202): the session the reply was typed in; T022 records its outcome in that session's own folder.
        [AllowNull()][string] $SessionId,
        # T020 (FR-031, DA-2): the host's ID for this message, so every receipt one message produces is bound to it.
        [AllowNull()][string] $MessageId
    )

    $script:SpecrewWorkshopLastReceiptOutcome = $null
    $script:SpecrewWorkshopLastDelegation = $null
    $script:SpecrewWorkshopReceiptSessionId = $SessionId
    $script:SpecrewWorkshopReceiptHostKind = $HostKind
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
        # T020 (FR-031, DA-4; B4F-130): which lenses this reply answers. Normally the open one. A delegation in one of
        # the exact wide forms answers every lens still open on the confirmed agenda, the open one first; lenses added
        # to the agenda later are not covered. The walk recorded one lens for "you decide the remaining lenses", and
        # every later lens asked again.
        $coveredLenses = @($lens)
        $pendingLenses = @()
        $wideDelegation = $false
        if ($phase -eq 'lens' -and [string]$authority.confirmation -ceq 'human-delegated') {
            $openOnAgenda = @(@($controller.selected) | ForEach-Object { [string]$_ } | Where-Object {
                    $closedProperty = if ($controller.PSObject.Properties['workshop']) { $controller.workshop.PSObject.Properties[$_] } else { $null }
                    -not ($closedProperty -and $closedProperty.Value.PSObject.Properties['moved_on'] -and [bool]$closedProperty.Value.moved_on)
                })
            if (Test-SpecrewWorkshopWideDelegation -Response $Response) {
                $wideDelegation = $true
                $coveredLenses = @(@($lens) + @($openOnAgenda | Where-Object { $_ -cne $lens }))
            }
            else { $pendingLenses = @($openOnAgenda | Where-Object { $_ -cne $lens }) }
        }
        $records = New-Object System.Collections.Generic.List[object]
        foreach ($coveredLens in $coveredLenses) {
            $record = [ordered]@{
                schema_version      = '1'
                receipt_id         = Get-SpecrewWorkshopAuthorityHash -Text ($featureRef + '|' + $phase + '|' + $coveredLens + '|' + $questionHash + '|' + $agendaDigest + '|' + $responseHash)
                feature_ref        = $featureRef
                iteration_number   = [string]$question.iteration_number
                phase              = $phase
                lens               = $coveredLens
                question_hash      = $questionHash
                response_hash      = $responseHash
                confirmation       = [string]$authority.confirmation
                confirmation_scope = [string]$authority.confirmation_scope
                source_event       = $canonicalSourceEvent
                host_kind          = [string]$HostKind
                recorded_at        = [DateTimeOffset]::UtcNow.ToString('o')
            }
            if (-not [string]::IsNullOrWhiteSpace($MessageId)) { $record['message_id'] = [string]$MessageId }
            if ($wideDelegation) { $record['delegation_breadth'] = 'remaining-lenses' }
            if ($phase -eq 'lens' -and [string]$authority.confirmation -ceq 'human-confirmed' -and (Test-SpecrewWorkshopReviewerPick -Response $Response -Question $(if ($question.PSObject.Properties['question']) { [string]$question.question } else { '' }))) { $record['answer_kind'] = 'reviewer-pick' }
            if ($phase -eq 'agenda') {
                $record['agenda_digest'] = $agendaDigest
                $record['agenda_binding'] = $agendaBinding
            }
            $records.Add($record) | Out-Null
        }
        $record = $records[0]
        $receiptId = [string]$record.receipt_id
        if ([string]$authority.confirmation -ceq 'human-delegated') {
            $script:SpecrewWorkshopLastDelegation = [pscustomobject]@{ Wide = $wideDelegation; Covered = @($coveredLenses); Pending = @($pendingLenses) }
        }

        $path = Get-SpecrewWorkshopAuthorityReceiptPath -ProjectRoot $root
        $dir = Split-Path -Parent $path
        if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        $lockPath = $path + '.lock'
        $lockStream = $null
        try {
            $deadline = [DateTimeOffset]::UtcNow.AddSeconds(2)
            do {
                try { $lockStream = [IO.File]::Open($lockPath, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None) }
                catch { if ([DateTimeOffset]::UtcNow -ge $deadline) { throw }; Start-Sleep -Milliseconds 25 }
            } until ($null -ne $lockStream)
            # Feature 202 iteration 002, T016 (FR-028; B4F-129): a receipt ID the store already holds is the same reply
            # offered again - by a second host's hooks reading the same session, or a second path - so it is never
            # written twice. The record already there is the answer; the reply was recorded, once.
            # Co-review round 5 (iteration 002): THE SAME REPLY, NOT THE SAME WORDS. The ID hashes the answer text, so
            # 'skip', 'you decide', 'skip' to one question kept only the first skip, and the delegation between them stayed
            # the newest act. A held record is this reply only when it carries the same message ID or, where the host gives
            # none, when it is still the newest record for its lens and the same answer to the same question; otherwise this is a
            # new act, and its ID is made its own.
            $existingLines = if ([IO.File]::Exists($path)) { [IO.File]::ReadAllLines($path) } else { @() }
            $existingRecords = New-Object System.Collections.Generic.List[object]
            foreach ($existingLine in $existingLines) {
                if ([string]::IsNullOrWhiteSpace($existingLine)) { continue }
                $existingRecord = $null
                try { $existingRecord = $existingLine | ConvertFrom-Json -ErrorAction Stop } catch { $existingRecord = $null }
                if ($null -ne $existingRecord -and $existingRecord.PSObject.Properties['receipt_id']) { $existingRecords.Add($existingRecord) | Out-Null }
            }
            $toWrite = New-Object System.Text.StringBuilder
            $openExisting = $null
            foreach ($candidate in $records) {
                $baseId = [string]$candidate.receipt_id
                $held = $null
                if (-not [string]::IsNullOrWhiteSpace($MessageId)) {
                    # The host names the message: the same message, with the same answer, for the same lens is the same reply.
                    foreach ($existingRecord in $existingRecords) {
                        if ([string]$existingRecord.lens -ceq [string]$candidate.lens -and [string]$existingRecord.phase -ceq [string]$candidate.phase -and
                            [string]$existingRecord.feature_ref -ceq [string]$candidate.feature_ref -and
                            $existingRecord.PSObject.Properties['message_id'] -and [string]$existingRecord.message_id -ceq [string]$MessageId -and
                            [string]$existingRecord.response_hash -ceq [string]$candidate.response_hash) { $held = $existingRecord }
                    }
                }
                else {
                    # No message ID: the same reply is the same answer to the same question, still the newest for its lens.
                    $lensNewest = $null
                    foreach ($existingRecord in $existingRecords) {
                        if ([string]$existingRecord.lens -ceq [string]$candidate.lens -and [string]$existingRecord.phase -ceq [string]$candidate.phase -and
                            [string]$existingRecord.feature_ref -ceq [string]$candidate.feature_ref) { $lensNewest = $existingRecord }
                    }
                    if ($null -ne $lensNewest -and [string]$lensNewest.response_hash -ceq [string]$candidate.response_hash -and
                        [string]$lensNewest.question_hash -ceq [string]$candidate.question_hash -and [string]$lensNewest.confirmation -ceq [string]$candidate.confirmation) { $held = $lensNewest }
                }
                if ($null -ne $held) { if ($baseId -ceq $receiptId) { $openExisting = $held }; continue }
                # A new act. Its ID is the answer's own unless an earlier act already holds it.
                if (@($existingRecords | Where-Object { [string]$_.receipt_id -ceq $baseId }).Count -gt 0) {
                    $actKey = if (-not [string]::IsNullOrWhiteSpace($MessageId)) { [string]$MessageId } else { [string]$candidate.recorded_at }
                    $candidate['receipt_id'] = Get-SpecrewWorkshopAuthorityHash -Text ($baseId + '|' + $actKey)
                    if ($baseId -ceq $receiptId) { $receiptId = [string]$candidate.receipt_id }
                }
                [void]$toWrite.Append((($candidate | ConvertTo-Json -Depth 5 -Compress) + [Environment]::NewLine))
            }
            if ($toWrite.Length -gt 0) { [IO.File]::AppendAllText($path, $toWrite.ToString(), [Text.UTF8Encoding]::new($false)) }
            if ($null -ne $openExisting) {
                $null = Set-SpecrewWorkshopReceiptOutcome -ProjectRoot $root -Status 'recorded' -Reason 'recorded' -FeatureRef $featureRef -Phase $phase -Response $Response
                return $openExisting
            }
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

function Get-SpecrewWorkshopDelegationLine {
    # T020 (FR-031, DA-4): what this turn's delegation covered, for the crew to say in one line. Wide: the lenses it
    # covers. Narrow, with other lenses still open: that it covers only this one, and the phrase that covers the rest
    # (the narrow case is loud too). $null otherwise.
    $delegation = $script:SpecrewWorkshopLastDelegation
    if ($null -eq $delegation) { return $null }
    $join = {
        param([string[]]$Names)
        if ($Names.Count -le 1) { return ($Names -join '') }
        return ((($Names | Select-Object -First ($Names.Count - 1)) -join ', ') + ' and ' + $Names[$Names.Count - 1])
    }
    if ([bool]$delegation.Wide) {
        return ("Specrew: this reply delegates the remaining lenses: {0}. Each one is recorded as delegated, so do not ask about them again; name them to the human in one line." -f (& $join @($delegation.Covered)))
    }
    if (@($delegation.Pending).Count -gt 0) {
        return ("Specrew: this delegation covers only {0}; {1} still open. Tell the human in one line that typing 'you decide the remaining lenses' delegates those too." -f (& $join @($delegation.Covered)), ((& $join @($delegation.Pending)) + $(if (@($delegation.Pending).Count -eq 1) { ' is' } else { ' are' })))
    }
    return $null
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
        [AllowNull()][string] $ReceiptId,
        # T020: the newest receipt with this confirmation, for a lens that holds more than one kind.
        [AllowNull()][string] $Confirmation
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
            if (-not [string]::IsNullOrWhiteSpace($Confirmation) -and [string]$record.confirmation -cne $Confirmation) { continue }
            $latest = $record
        }
        return $latest
    }
    catch { throw ('workshop-authority-store-invalid:' + $_.Exception.Message) }
}

function Get-SpecrewWorkshopLensClosingReceipt {
    # T020 (FR-031, DA-4): THE RECEIPT A LENS CLOSES ON. Normally its newest receipt: a newer answer replaces an older
    # one, so an older reply cannot be replayed. One mix is allowed: a lens covered by a WIDE delegation ("you decide the
    # remaining lenses", given in advance) whose reviewer pick the human then confirmed closes as delegated, on that
    # delegation receipt - the walk's Claude case, where the confirmed reviewer answer was newest and the close asked
    # "confirm or you decide this lens" again. Only a reviewer pick may stand after it; a later answer, skip or delegation is the
    # newest act and wins, and a narrow "you decide" followed by an answer is a changed mind, so the answer wins. Used by
    # the lens checkpoint and by every reader that checks a closed lens.
    param(
        [Parameter(Mandatory)][string] $ProjectRoot,
        [Parameter(Mandatory)][string] $FeatureRef,
        [Parameter(Mandatory)][ValidateSet('product-domain', 'agenda', 'lens')][string] $Phase,
        [AllowNull()][string] $Lens,
        [AllowNull()][string] $Confirmation
    )
    $latest = Get-SpecrewWorkshopAuthorityReceipt -ProjectRoot $ProjectRoot -FeatureRef $FeatureRef -Phase $Phase -Lens $Lens
    if ($null -eq $latest -or [string]$latest.confirmation -ceq [string]$Confirmation) { return $latest }
    if ($Phase -cne 'lens' -or [string]$Confirmation -cne 'human-delegated' -or [string]$latest.confirmation -cne 'human-confirmed') { return $latest }
    $path = Get-SpecrewWorkshopAuthorityReceiptPath -ProjectRoot $ProjectRoot
    $forLens = New-Object System.Collections.Generic.List[object]
    foreach ($line in [IO.File]::ReadLines($path, [Text.Encoding]::UTF8)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $record = [string]$line | ConvertFrom-Json -Depth 8 -ErrorAction Stop
        if ([string]$record.schema_version -cne '1' -or [string]$record.feature_ref -cne $FeatureRef -or [string]$record.phase -cne $Phase) { continue }
        if (-not [string]::IsNullOrWhiteSpace($Lens) -and [string]$record.lens -cne $Lens) { continue }
        $forLens.Add($record) | Out-Null
    }
    # Co-review round 6 (iteration 002): only a REVIEWER PICK stands after the delegation. Every confirmed reply was passed
    # over, so 'Do not decide this lens for me; I choose a local queue' still let the lens close as delegated, on the older
    # receipt and a decision the agent wrote. A reply that answers the lens itself is the newest act and wins.
    for ($i = $forLens.Count - 1; $i -ge 0; $i--) {
        $c = [string]$forLens[$i].confirmation
        if ($c -ceq 'human-confirmed' -and $forLens[$i].PSObject.Properties['answer_kind'] -and [string]$forLens[$i].answer_kind -ceq 'reviewer-pick') { continue }
        if ($c -ceq 'human-delegated' -and $forLens[$i].PSObject.Properties['delegation_breadth'] -and [string]$forLens[$i].delegation_breadth -ceq 'remaining-lenses') { return $forLens[$i] }
        break
    }
    return $latest
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

    $record = Get-SpecrewWorkshopLensClosingReceipt -ProjectRoot $ProjectRoot -FeatureRef $FeatureRef -Phase $Phase -Lens $Lens -Confirmation $Confirmation
    if ($null -eq $record) { return $false }
    $digestMatches = [string]::IsNullOrWhiteSpace($AgendaDigest) -or
        ($record.PSObject.Properties['agenda_digest'] -and [string]$record.agenda_digest -ceq $AgendaDigest)
    return ([string]$record.receipt_id -ceq $ReceiptId -and [string]$record.confirmation -ceq $Confirmation -and
        [string]$record.confirmation_scope -ceq $ConfirmationScope -and [string]$record.confirmation -cne 'invalid' -and $digestMatches)
}
