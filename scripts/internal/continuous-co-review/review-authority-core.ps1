$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# F-198 / T042-T044: dependency-free PURE review authority core. This file intentionally performs
# no filesystem, Git, process, environment, or clock I/O. Callers pass immutable facts and observed
# timestamps in; adapters execute the returned decisions.

$script:ReviewAuthorityMaxInvocationTimeoutSeconds = 7200
$script:ReviewAuthorityMaxTerminationGraceSeconds = 10
$script:ReviewAuthorityOrchestrationOverheadAllowanceSeconds = 120
$script:ReviewAuthorityCandidateLimits = [ordered]@{
    max_candidate_bytes = 262144
    max_summary_characters = 4000
    max_findings = 100
    max_local_id_characters = 64
    max_title_characters = 200
    max_description_characters = 4000
    max_location_characters = 1000
}
# A terminal duration includes the invocation timeout, termination grace, and bounded controller
# overhead. Keep this value derived here so changing any contributing ceiling changes the schema
# bound in the same edit; measured duration evidence is validated as observed and is never clamped.
$script:ReviewAuthorityMaxDurationMilliseconds = [long](
    $script:ReviewAuthorityMaxInvocationTimeoutSeconds +
    $script:ReviewAuthorityMaxTerminationGraceSeconds +
    $script:ReviewAuthorityOrchestrationOverheadAllowanceSeconds
) * 1000L

function Get-ReviewAuthorityTimingLimits {
    return [pscustomobject][ordered]@{
        max_invocation_timeout_seconds = $script:ReviewAuthorityMaxInvocationTimeoutSeconds
        max_termination_grace_seconds = $script:ReviewAuthorityMaxTerminationGraceSeconds
        orchestration_overhead_allowance_seconds = $script:ReviewAuthorityOrchestrationOverheadAllowanceSeconds
        max_duration_ms = $script:ReviewAuthorityMaxDurationMilliseconds
    }
}

function Get-ReviewAuthorityCandidateLimits {
    return [pscustomobject][ordered]@{
        max_candidate_bytes = $script:ReviewAuthorityCandidateLimits.max_candidate_bytes
        max_summary_characters = $script:ReviewAuthorityCandidateLimits.max_summary_characters
        max_findings = $script:ReviewAuthorityCandidateLimits.max_findings
        max_local_id_characters = $script:ReviewAuthorityCandidateLimits.max_local_id_characters
        max_title_characters = $script:ReviewAuthorityCandidateLimits.max_title_characters
        max_description_characters = $script:ReviewAuthorityCandidateLimits.max_description_characters
        max_location_characters = $script:ReviewAuthorityCandidateLimits.max_location_characters
    }
}

function Get-ReviewAuthorityPropertyNames {
    param([AllowNull()]$Object)
    if ($null -eq $Object) { return @() }
    if ($Object -is [System.Collections.IDictionary]) { return @($Object.Keys) }
    return @($Object.PSObject.Properties.Name)
}

function Get-ReviewAuthorityProperty {
    param([AllowNull()]$Object, [Parameter(Mandatory)][string]$Name)
    if ($null -eq $Object) { return $null }
    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) {
            $value = $Object[$Name]
            if ($value -is [System.Collections.IEnumerable] -and $value -isnot [string] -and $value -isnot [System.Collections.IDictionary]) { Write-Output -NoEnumerate $value; return }
            return $value
        }
        return $null
    }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    if ($property.Value -is [System.Collections.IEnumerable] -and $property.Value -isnot [string] -and $property.Value -isnot [System.Collections.IDictionary]) { Write-Output -NoEnumerate $property.Value; return }
    return $property.Value
}

function ConvertTo-ReviewAuthorityTimestamp {
    <#
    Authority ordering is by instant, never by the spelling of an ISO-8601 value. `Z` and
    `+00:00` describe the same zone but do not sort the same as strings. An absent or malformed
    authority timestamp is corruption, not an invitation to choose a permissive default.
    #>
    [CmdletBinding()]
    param(
        [AllowNull()]$Value,
        [string]$FieldName = 'timestamp'
    )

    # ConvertFrom-Json materializes ISO values as DateTime on current PowerShell releases. Accept
    # those typed values directly; their original JSON spelling has already passed the closed fact
    # reader, and converting them back through the current culture would destroy the ISO shape.
    if ($Value -is [DateTimeOffset]) { return ([DateTimeOffset]$Value).ToUniversalTime() }
    if ($Value -is [DateTime]) {
        $dateTime = [DateTime]$Value
        if ($dateTime.Kind -eq [DateTimeKind]::Unspecified) { throw "review-authority-timestamp-invalid:$FieldName" }
        return ([DateTimeOffset]$dateTime).ToUniversalTime()
    }

    $text = [string]$Value
    $parsed = [DateTimeOffset]::MinValue
    # Validate the shape before parsing so culture-permissive inputs such as local dates can
    # never become authority. TryParse (rather than its string[] TryParseExact overload) is used
    # deliberately: PowerShell 7.5 binds that by-ref overload inconsistently on Windows.
    if ([string]::IsNullOrWhiteSpace($text) -or
        $text -cnotmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,7})?(?:Z|[+-]\d{2}:\d{2})$' -or
        -not [DateTimeOffset]::TryParse(
            $text,
            [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::RoundtripKind,
            [ref]$parsed)) {
        throw "review-authority-timestamp-invalid:$FieldName"
    }
    return $parsed.ToUniversalTime()
}

function Test-ReviewAuthorityIdentifier {
    param(
        [AllowNull()]$Value,
        [Parameter(Mandatory)][ValidateSet('campaign', 'run', 'grant', 'reservation', 'finding', 'lineage', 'disposition')][string]$Kind
    )
    if ($Value -isnot [string]) { return $false }
    $prefix = switch ($Kind) {
        'campaign' { 'cmp' }
        'run' { 'run' }
        'grant' { 'grant' }
        'reservation' { 'res' }
        'finding' { 'finding' }
        'lineage' { 'lin' }
        'disposition' { 'disposition' }
    }
    return ([string]$Value -cmatch ('^{0}-[a-z0-9][a-z0-9-]{{0,63}}$' -f $prefix))
}

function Resolve-ReviewCampaignPauseDecision {
    # Feature 203 T008 step (iii) (maintainer ruling 2026-11-09): what a stop's pause fact records about the budget, and
    # nothing else. The old numbered menu this used to build (options, gating counts, a severity-derived recommendation)
    # had no live reader: its two renderers had no production caller and are deleted. A stop's reason is written by that
    # stop's own writer, so the recommendation starts empty and no old menu sentence can reach a stop surface. The other
    # parameters are accepted for older callers and not read.
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()][object[]]$Findings = @(),
        [Parameter(Mandatory)][int]$RoundsUsed,
        [Parameter(Mandatory)][int]$BudgetTotal,
        [double]$ElapsedMinutes = 0,
        [AllowNull()]$Result = $null
    )
    $null = $Findings; $null = $ElapsedMinutes; $null = $Result
    return [pscustomobject][ordered]@{ rounds_used = $RoundsUsed; budget_total = $BudgetTotal; recommendation = '' }
}

function Test-ReviewCampaignPendingPauseQuiet {
    # Maintainer ruling 2026-08-10. A pending pause is recorded AGAINST a tree state, and the human
    # answers it by changing that tree. So quiet must be checked, never assumed: a pause whose target
    # no longer matches the current tree is SUPERSEDED - it describes work that has moved on, stops
    # conferring quiet, and the surface returns to its ordinary route.
    #
    # This is the review-stale class in a new place, and the dangerous direction: a stale RESULT only
    # nags for a fresh review, while a stale PAUSE would SILENCE the surface on a tree it never
    # described. Absent or unreadable input therefore fails closed (no quiet).
    [CmdletBinding()]
    param(
        [AllowNull()]$PendingPause,
        [Parameter(Mandatory)][AllowEmptyString()][string]$CurrentDigest
    )
    if ($null -eq $PendingPause) {
        return [pscustomobject]@{ confers_quiet = $false; reason = 'no-pending-pause' }
    }
    $pauseDigest = [string](Get-ReviewAuthorityProperty -Object $PendingPause -Name 'target_digest')
    if ([string]::IsNullOrWhiteSpace($pauseDigest) -or [string]::IsNullOrWhiteSpace($CurrentDigest)) {
        return [pscustomobject]@{ confers_quiet = $false; reason = 'pause-target-unresolved' }
    }
    if ($pauseDigest -cne $CurrentDigest) {
        return [pscustomobject]@{ confers_quiet = $false; reason = 'pause-superseded-by-moved-tree' }
    }
    return [pscustomobject]@{ confers_quiet = $true; reason = 'pause-pending-on-current-tree' }
}

function Test-ReviewAuthorityFindingResolutionsField {
    # Feature 203 T008 step (iii) (maintainer ruling 2026-11-09): the reviewer's answer to each open finding it was given,
    # `resolved` or `still-open`, by the finding's id. Optional: a candidate that answers nothing leaves every finding open.
    # Closed shape per entry, because this field closes findings: an entry the controller cannot read closes nothing.
    param([Parameter(Mandatory)]$Object, [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.List[string]]$Errors)
    if ((Get-ReviewAuthorityPropertyNames -Object $Object) -notcontains 'finding_resolutions') { return }
    $entries = Get-ReviewAuthorityProperty -Object $Object -Name 'finding_resolutions'
    if ($null -eq $entries -or $entries -is [string] -or $entries -isnot [System.Collections.IEnumerable]) { Add-ReviewAuthorityError -Errors $Errors -Message 'invalid-array:finding_resolutions'; return }
    $count = 0
    foreach ($entry in @($entries)) {
        $count++
        if ($count -gt 200) { Add-ReviewAuthorityError -Errors $Errors -Message 'too-many:finding_resolutions'; return }
        $names = @(Get-ReviewAuthorityPropertyNames -Object $entry)
        if (@($names | Where-Object { $_ -cnotin @('finding_id', 'status') }).Count -gt 0 -or $names.Count -ne 2) { Add-ReviewAuthorityError -Errors $Errors -Message 'invalid-shape:finding_resolutions'; continue }
        Test-ReviewAuthorityStringField -Object $entry -Name 'finding_id' -Errors $Errors -MaxLength 64
        Test-ReviewAuthorityStringField -Object $entry -Name 'status' -Errors $Errors -MaxLength 16 -Enum @('resolved', 'still-open')
    }
}

# Feature 203 T008 step (iii) (FR-006): the four stops, and the only reasons a review pauses for the human.
$script:ReviewCampaignStopKinds = @('a-budget-spent', 'b-dispute-or-defer', 'c-judgment', 'd-host-outside-order')

function New-ReviewCampaignPendingPauseFact {
    # The pause recorded as a FACT (design Option B). A derived pause could only be inferred, which
    # made the quiet-state read heuristic and lost the surface verbatim on resume.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$TargetDigest,
        [Parameter(Mandatory)]$Decision,
        [Parameter(Mandatory)][string]$ObservedAt,
        # Feature 203 T008 step (iii) (FR-006): which stop this is, why, and for (d) the reviewer the engine would try next.
        [AllowEmptyString()][string]$StopKind = '',
        [AllowEmptyString()][string]$StopReason = '',
        [AllowEmptyString()][string]$NextHost = ''
    )
    $fact = New-ReviewCampaignPendingPauseFactBody -CampaignId $CampaignId -RunId $RunId -TargetDigest $TargetDigest -Decision $Decision -ObservedAt $ObservedAt
    # A stop's reason is its own writer's (maintainer ruling 2026-11-09); the fact carries one only when that writer set it.
    if (-not [string]::IsNullOrWhiteSpace([string]$Decision.recommendation)) { $fact | Add-Member -NotePropertyName recommendation -NotePropertyValue ([string]$Decision.recommendation) }
    if (-not [string]::IsNullOrWhiteSpace($StopKind)) {
        if ($script:ReviewCampaignStopKinds -cnotcontains $StopKind) { throw "review-stop-kind-unknown:$StopKind" }
        $fact | Add-Member -NotePropertyName stop_kind -NotePropertyValue $StopKind
        $fact | Add-Member -NotePropertyName stop_reason -NotePropertyValue $StopReason
        if (-not [string]::IsNullOrWhiteSpace($NextHost)) { $fact | Add-Member -NotePropertyName next_host -NotePropertyValue $NextHost }
    }
    return $fact
}

function New-ReviewCampaignPendingPauseFactBody {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$TargetDigest,
        [Parameter(Mandatory)]$Decision,
        [Parameter(Mandatory)][string]$ObservedAt
    )
    return [pscustomobject][ordered]@{
        schema_version = '1.0'
        fact_type      = 'pending-pause'
        campaign_id    = $CampaignId
        run_id         = $RunId
        target_digest  = $TargetDigest
        rounds_used    = [int]$Decision.rounds_used
        budget_total   = [int]$Decision.budget_total
        observed_at    = $ObservedAt
    }
}

function New-ReviewCampaignBudgetResetFact {
    # THE CEILING'S WAY OUT, which the ceiling has been advertising and the engine refused.
    #
    # `Cost so far ... Round budget: 4 of 4 used` withdrew option 1 and told the consumer, in prose, to run the
    # allowance-reset remediation. Under campaign authority that command threw - every
    # remediation except override-block was rejected - so a consumer who reached the ceiling was told
    # exactly one way forward, followed it verbatim, and was refused. Permanently wedged, with no route
    # to another round short of editing configuration or abandoning the campaign. It surfaced only
    # because the maintainer ruled to run INTO the failure state rather than around it (round 4).
    #
    # THE BUDGET IS TOPPED UP BY RECORDING A DECISION, NEVER BY MUTATING A COUNT. Rounds already run are
    # immutable facts and stay on the record; this fact says where the human chose to start counting
    # again, and carries WHO chose and WHY. That keeps the ledger's whole property intact - every round
    # ever run remains visible - while letting the human lift a limit that is theirs to lift.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$AuthorizedBy,
        [Parameter(Mandatory)][string]$Reason,
        [Parameter(Mandatory)][string]$ObservedAt,
        # Feature 203 T012 (FR-041): the typed turn of the `approved for allowance reset` the reset spends.
        [AllowEmptyString()][string]$TurnIdentity = ''
    )
    $token = Get-ReviewCampaignStableToken -Value "$CampaignId/$ObservedAt/$Reason" -Length 20
    $fact = [pscustomobject][ordered]@{
        schema_version = '1.0'
        fact_type      = 'round-budget-reset'
        campaign_id    = $CampaignId
        reset_id       = "reset-$token"
        authority_kind = 'human'
        authorized_by  = $AuthorizedBy
        reason         = $Reason
        observed_at    = $ObservedAt
    }
    if (-not [string]::IsNullOrWhiteSpace($TurnIdentity)) { $fact | Add-Member -NotePropertyName turn_identity -NotePropertyValue $TurnIdentity.Trim() }
    return $fact
}

function New-ReviewCampaignPauseDecisionFact {
    # The human's numbered reply. This fact is the ONLY thing that authorizes another round; an agent
    # cannot mint one from a prior grant, which is the self-minted-continuation failure ledger obs-6
    # recorded (one grant stretched across seven rounds).
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][ValidateSet('stop-here', 'answered')][string]$Choice,
        [Parameter(Mandatory)][string]$ObservedAt,
        # Feature 203 T012 (FR-024, FR-041): the typed turn of the answer this decision lands.
        [AllowEmptyString()][string]$TurnIdentity = ''
    )
    $fact = [pscustomobject][ordered]@{
        schema_version = '1.0'
        fact_type      = 'pause-decision'
        campaign_id    = $CampaignId
        run_id         = $RunId
        choice         = $Choice
        observed_at    = $ObservedAt
    }
    if (-not [string]::IsNullOrWhiteSpace($TurnIdentity)) { $fact | Add-Member -NotePropertyName turn_identity -NotePropertyValue $TurnIdentity.Trim() }
    return $fact
}

function Test-ReviewCampaignFeatureIdentity {
    param([AllowNull()]$Value)
    return ($Value -is [string] -and [string]$Value -cmatch '^[a-z0-9][a-z0-9-]{0,127}$')
}

function Test-ReviewCampaignIterationIdentity {
    param([AllowNull()]$Value)
    return ($Value -is [string] -and [string]$Value -cmatch '^[0-9]{3,}$')
}

function Test-ReviewCampaignScopeIdentity {
    param(
        [AllowNull()]$FeatureId,
        [AllowNull()]$IterationNumber
    )
    return ((Test-ReviewCampaignFeatureIdentity -Value $FeatureId) -and
        (Test-ReviewCampaignIterationIdentity -Value $IterationNumber))
}

function Add-ReviewAuthorityError {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.List[string]]$Errors,
        [Parameter(Mandatory)][string]$Message
    )
    $Errors.Add($Message) | Out-Null
}

function ConvertTo-ReviewAuthorityBoundedText {
    param(
        [AllowNull()]$Value,
        [Parameter(Mandatory)][ValidateRange(16, 1000000)][int]$MaximumLength
    )
    if ($null -eq $Value) { return $null }
    $text = [string]$Value
    if ($text.Length -le $MaximumLength) { return $text }
    $marker = '...[truncated]'
    return $text.Substring(0, $MaximumLength - $marker.Length) + $marker
}

function Test-ReviewAuthorityStringField {
    param(
        [Parameter(Mandatory)]$Object,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.List[string]]$Errors,
        [int]$MaxLength = 4096,
        [string[]]$Enum,
        [switch]$Optional,
        [switch]$AllowEmpty
    )
    $names = Get-ReviewAuthorityPropertyNames -Object $Object
    if ($names -notcontains $Name) {
        if (-not $Optional) { Add-ReviewAuthorityError -Errors $Errors -Message "missing-required:$Name" }
        return
    }
    $value = Get-ReviewAuthorityProperty -Object $Object -Name $Name
    if ($null -eq $value -and $Optional) { return }
    if ($value -isnot [string] -and $value -isnot [datetime] -and $value -isnot [datetimeoffset]) {
        Add-ReviewAuthorityError -Errors $Errors -Message ('wrong-type:{0}:string' -f $Name)
        return
    }
    if ((-not $AllowEmpty) -and [string]::IsNullOrWhiteSpace([string]$value)) {
        Add-ReviewAuthorityError -Errors $Errors -Message "empty-value:$Name"
    }
    if (([string]$value).Length -gt $MaxLength) {
        Add-ReviewAuthorityError -Errors $Errors -Message ('too-long:{0}:{1}' -f $Name, $MaxLength)
    }
    if ($null -ne $Enum -and @($Enum).Count -gt 0 -and ([string]$value -cnotin @($Enum))) {
        Add-ReviewAuthorityError -Errors $Errors -Message "invalid-enum:$Name"
    }
}

function Test-ReviewAuthorityBooleanField {
    param(
        [Parameter(Mandatory)]$Object,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.List[string]]$Errors,
        [switch]$Optional
    )
    $names = Get-ReviewAuthorityPropertyNames -Object $Object
    if ($names -notcontains $Name) {
        if (-not $Optional) { Add-ReviewAuthorityError -Errors $Errors -Message "missing-required:$Name" }
        return
    }
    if ((Get-ReviewAuthorityProperty -Object $Object -Name $Name) -isnot [bool]) {
        Add-ReviewAuthorityError -Errors $Errors -Message ('wrong-type:{0}:boolean' -f $Name)
    }
}

function Test-ReviewAuthorityIntegerField {
    param(
        [Parameter(Mandatory)]$Object,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.List[string]]$Errors,
        [long]$Minimum = 0,
        [long]$Maximum = [long]::MaxValue,
        [switch]$Optional
    )
    $names = Get-ReviewAuthorityPropertyNames -Object $Object
    if ($names -notcontains $Name) {
        if (-not $Optional) { Add-ReviewAuthorityError -Errors $Errors -Message "missing-required:$Name" }
        return
    }
    $value = Get-ReviewAuthorityProperty -Object $Object -Name $Name
    if (($value -isnot [byte]) -and ($value -isnot [int16]) -and ($value -isnot [int]) -and ($value -isnot [long])) {
        Add-ReviewAuthorityError -Errors $Errors -Message ('wrong-type:{0}:integer' -f $Name)
        return
    }
    if ([long]$value -lt $Minimum -or [long]$value -gt $Maximum) {
        Add-ReviewAuthorityError -Errors $Errors -Message "out-of-range:$Name"
    }
}

function Test-ReviewAuthorityIdField {
    param(
        [Parameter(Mandatory)]$Object,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][ValidateSet('campaign', 'run', 'grant', 'reservation', 'finding', 'lineage', 'disposition')][string]$Kind,
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.List[string]]$Errors
    )
    Test-ReviewAuthorityStringField -Object $Object -Name $Name -Errors $Errors -MaxLength 68
    $value = Get-ReviewAuthorityProperty -Object $Object -Name $Name
    if ($null -ne $value -and -not (Test-ReviewAuthorityIdentifier -Value $value -Kind $Kind)) {
        Add-ReviewAuthorityError -Errors $Errors -Message ('invalid-id:{0}:{1}' -f $Name, $Kind)
    }
}

function Test-ReviewAuthorityClosedShape {
    param(
        [Parameter(Mandatory)]$Object,
        [Parameter(Mandatory)][string[]]$Allowed,
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.List[string]]$Errors
    )
    if ($null -eq $Object -or (($Object -isnot [System.Collections.IDictionary]) -and ($Object -isnot [pscustomobject]))) {
        Add-ReviewAuthorityError -Errors $Errors -Message 'wrong-type:$:object'
        return $false
    }
    foreach ($name in (Get-ReviewAuthorityPropertyNames -Object $Object)) {
        if ([string]$name -cnotin $Allowed) {
            Add-ReviewAuthorityError -Errors $Errors -Message "unknown-field:$name"
        }
    }
    return $true
}

function Test-ReviewAuthorityFinding {
    param(
        [Parameter(Mandatory)]$Finding,
        [Parameter(Mandatory)][ValidateSet('candidate', 'terminal')][string]$Kind,
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.List[string]]$Errors,
        [Parameter(Mandatory)][int]$Index
    )
    $limits = Get-ReviewAuthorityCandidateLimits
    $prefix = "findings[$Index]"
    # The CANDIDATE shape stays closed at five fields on purpose (T005/FR-006). `demoted` and
    # `demoted_from` are the CONTROLLER's determination about a reviewer's output, so a reviewer must
    # not be able to supply either one - neither to mark itself demoted nor, far worse, to declare
    # itself un-demotable and keep a gate it did not earn. They exist only on the terminal shape,
    # which the ingestor alone writes.
    $allowed = if ($Kind -ceq 'candidate') {
        @('local_id', 'severity', 'title', 'description', 'location')
    }
    else {
        @('finding_id', 'source_local_id', 'lineage_id', 'severity', 'title', 'description', 'location', 'relevance', 'resolution', 'demoted', 'demoted_from')
    }
    $nested = [System.Collections.Generic.List[string]]::new()
    if (-not (Test-ReviewAuthorityClosedShape -Object $Finding -Allowed $allowed -Errors $nested)) {
        foreach ($error in $nested) { Add-ReviewAuthorityError -Errors $Errors -Message "$prefix.$error" }
        return
    }
    if ($Kind -ceq 'candidate') {
        Test-ReviewAuthorityStringField -Object $Finding -Name 'local_id' -Errors $nested -MaxLength $limits.max_local_id_characters
    }
    else {
        Test-ReviewAuthorityIdField -Object $Finding -Name 'finding_id' -Kind finding -Errors $nested
        Test-ReviewAuthorityStringField -Object $Finding -Name 'source_local_id' -Errors $nested -MaxLength $limits.max_local_id_characters
        Test-ReviewAuthorityIdField -Object $Finding -Name 'lineage_id' -Kind lineage -Errors $nested
        Test-ReviewAuthorityStringField -Object $Finding -Name 'relevance' -Errors $nested -MaxLength 32 -Enum @('current', 'snapshot-moved', 'unknown')
        Test-ReviewAuthorityStringField -Object $Finding -Name 'resolution' -Errors $nested -MaxLength 32 -Enum @('open', 'resolved', 'superseded')
        # Optional so results published before this contract existed still read back. `demoted_from`
        # carries the reviewer's ORIGINAL severity and is empty exactly when nothing was demoted, so
        # the enum admits the empty string rather than pretending an un-demoted finding came from
        # somewhere.
        Test-ReviewAuthorityBooleanField -Object $Finding -Name 'demoted' -Errors $nested -Optional
        Test-ReviewAuthorityStringField -Object $Finding -Name 'demoted_from' -Errors $nested -MaxLength 16 -Enum @('blocking', 'major', '') -Optional -AllowEmpty
    }
    Test-ReviewAuthorityStringField -Object $Finding -Name 'severity' -Errors $nested -MaxLength 16 -Enum @('blocking', 'major', 'minor', 'note')
    Test-ReviewAuthorityStringField -Object $Finding -Name 'title' -Errors $nested -MaxLength $limits.max_title_characters
    Test-ReviewAuthorityStringField -Object $Finding -Name 'description' -Errors $nested -MaxLength $limits.max_description_characters
    Test-ReviewAuthorityStringField -Object $Finding -Name 'location' -Errors $nested -MaxLength $limits.max_location_characters -Optional
    foreach ($error in $nested) { Add-ReviewAuthorityError -Errors $Errors -Message "$prefix.$error" }
}

function Test-ReviewAuthorityContractObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet(
            'ReviewCampaign', 'ReviewRun', 'ReviewInvocation', 'ReviewerCandidate', 'ReviewResult',
            'GrantFact', 'ReservationFact', 'SpendFact', 'ReleaseFact', 'ClaimFact', 'HumanDispositionFact', 'RecoveryFact',
            'ReviewFinalizationFact', 'PendingPauseFact', 'PauseDecisionFact', 'RoundBudgetResetFact', 'BudgetGrantFact', 'AllowedReviewerFact',
            'FindingDispositionFact'
        )][string]$ContractName,
        [Parameter(Mandatory)]$InputObject,
        [string]$ExpectedCampaignId,
        [string]$ExpectedRunId,
        [string]$ExpectedTargetDigest
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $candidateLimits = Get-ReviewAuthorityCandidateLimits
    $fields = switch ($ContractName) {
        'ReviewCampaign' { @('schema_version', 'campaign_id', 'target_lineage', 'created_at') }
        'ReviewRun' { @('schema_version', 'campaign_id', 'run_id', 'target_digest', 'harness_id', 'state') }
        'ReviewInvocation' { @('schema_version', 'campaign_id', 'run_id', 'target_digest', 'snapshot_path', 'review_scope', 'prompt_path', 'candidate_result_path', 'candidate_report_path', 'deadline') }
        # Feature 203 T008 step (iii) (2026-11-09 ruling): finding_resolutions answers the open findings the reviewer was given.
        'ReviewerCandidate' { @('schema_version', 'run_id', 'target_digest', 'completion', 'verdict', 'summary', 'findings', 'examined_paths', 'finding_resolutions') }
        'ReviewResult' { @('schema_version', 'campaign_id', 'run_id', 'target_digest', 'harness_id', 'completion', 'verdict', 'runtime_outcome', 'termination_verified', 'containment', 'currentness', 'validation', 'can_approve_current', 'failure_reason', 'summary', 'findings', 'started_at', 'ended_at', 'duration_ms', 'examined_paths', 'review_collected', 'reviewer_host', 'finding_resolutions') }
        # Feature 203 T008 (FR-009): a launch grant names the reviewer the engine chose for that round.
        'GrantFact' { @('schema_version', 'fact_type', 'campaign_id', 'grant_id', 'slots', 'authority_kind', 'authorization_ref', 'observed_at', 'reviewer_host', 'turn_identity') }
        # Feature 203 T008 (FR-009, FR-006(d)): `allow reviewer <host>` appends a reviewer to the campaign's approved order.
        'AllowedReviewerFact' { @('schema_version', 'fact_type', 'campaign_id', 'host', 'authority_kind', 'authorization_ref', 'observed_at', 'turn_identity') }
        # Feature 203 T008 step (iii) (FR-011): the human's typed `defer finding <id> to <destination>`, `drop finding <id>` or
        # `fix finding <id>` for one open finding. Defer and drop close it; fix keeps it open for the crew.
        'FindingDispositionFact' { @('schema_version', 'fact_type', 'campaign_id', 'finding_key', 'answer', 'argument', 'authority_kind', 'authorization_ref', 'observed_at', 'turn_identity') }
        # Feature 203 T007 (FR-003): the review budget, snapshotted from the plan when the before-implement verdict is recorded.
        'BudgetGrantFact' { @(
            'schema_version', 'fact_type', 'campaign_id', 'grant_id', 'budget_total', 'host_order', 'host_order_stated',
            'infra_failure_cap', 'budget_source', 'ceiling', 'plan_path', 'plan_hash', 'verdict_entry', 'authority_kind', 'observed_at',
            # Feature 203 T008 (DRIFT-052 item 2): a floor grant records why it is the floor and the verdict time it counts from.
            'floor_reason', 'counts_from',
            # Feature 203 T012 (FR-041): the typed turn of the before-implement verdict the grant was snapshotted from.
            'turn_identity'
        ) }
        # Feature 203 T012 (FR-024): a reservation cites the budget grant and the reset that opened the current window, and the
        # typed turn that authorized it; grant_id is the launch grant whose slot it holds, which may be older than the window.
        'ReservationFact' { @('schema_version', 'fact_type', 'campaign_id', 'reservation_id', 'grant_id', 'slot', 'run_id', 'observed_at', 'budget_grant_id', 'reset_id', 'turn_identity') }
        'SpendFact' { @('schema_version', 'fact_type', 'campaign_id', 'reservation_id', 'run_id', 'invocation_started_at') }
        'ReleaseFact' { @('schema_version', 'fact_type', 'campaign_id', 'reservation_id', 'run_id', 'reason', 'observed_at') }
        'ClaimFact' { @('schema_version', 'fact_type', 'campaign_id', 'run_id', 'target_lineage', 'generation', 'disposition', 'observed_at') }
        'HumanDispositionFact' { @('schema_version', 'fact_type', 'disposition_id', 'campaign_id', 'run_id', 'target_digest', 'decision', 'authority_kind', 'authorized_by', 'authorization_ref', 'rationale', 'observed_at', 'turn_identity') }
        'ReviewFinalizationFact' { @('schema_version', 'fact_type', 'campaign_id', 'run_id', 'reviewed_digest', 'finalization_commit') }
        'PendingPauseFact' { @(
            'schema_version', 'fact_type', 'campaign_id', 'run_id', 'target_digest', 'blocking_count',
            'major_count', 'minor_count', 'demoted_count', 'rounds_used', 'budget_total', 'elapsed_minutes',
            'evidence_state', 'result_produced', 'recommendation', 'observed_at',
            # Feature 203 T008 step (iii) (FR-006, FR-011): which of the four stops this pause is. A pause without one was
            # written before step (iii), when every round paused; it is history and stops nothing.
            'stop_kind', 'stop_reason', 'next_host'
        ) }
        'PauseDecisionFact' { @('schema_version', 'fact_type', 'campaign_id', 'run_id', 'choice', 'observed_at', 'turn_identity') }
        # The round budget is topped up by RECORDING a decision, never by mutating a count. Rounds
        # already run are immutable facts and stay on the record; this fact says where the human chose
        # to start counting again, and carries who chose and why.
        'RoundBudgetResetFact' { @('schema_version', 'fact_type', 'campaign_id', 'reset_id', 'authority_kind', 'authorized_by', 'reason', 'observed_at', 'turn_identity') }
        'RecoveryFact' { @(
            'schema_version', 'fact_type', 'campaign_id', 'run_id', 'target_digest', 'harness_id', 'target_lineage',
            'runtime_id', 'platform', 'containment_kind', 'containment_id', 'process_id', 'process_started_at',
            'invocation_started_at', 'invocation_started_monotonic_ms', 'target_kind', 'snapshot_path',
            'workspace_root', 'origin_repo', 'git_root', 'origin_head_before', 'staging_root',
            'verification_plan_present', 'verification_plan_sha256', 'machinery_paths', 'machinery_paths_sha256',
            'excluded_path_patterns', 'excluded_path_patterns_sha256'
        ) }
    }
    if (-not (Test-ReviewAuthorityClosedShape -Object $InputObject -Allowed $fields -Errors $errors)) {
        return [pscustomobject]@{ valid = $false; category = 'schema-invalid'; errors = @($errors) }
    }
    Test-ReviewAuthorityStringField -Object $InputObject -Name 'schema_version' -Errors $errors -MaxLength 8
    $version = [string](Get-ReviewAuthorityProperty -Object $InputObject -Name 'schema_version')
    if (-not [string]::IsNullOrWhiteSpace($version) -and $version -cne '1.0') {
        Add-ReviewAuthorityError -Errors $errors -Message 'unsupported-version:schema_version'
    }

    if ($fields -contains 'campaign_id') { Test-ReviewAuthorityIdField -Object $InputObject -Name 'campaign_id' -Kind campaign -Errors $errors }
    if ($fields -contains 'run_id') { Test-ReviewAuthorityIdField -Object $InputObject -Name 'run_id' -Kind run -Errors $errors }
    if ($fields -contains 'target_digest') { Test-ReviewAuthorityStringField -Object $InputObject -Name 'target_digest' -Errors $errors -MaxLength 128 }
    if ($fields -contains 'harness_id') { Test-ReviewAuthorityStringField -Object $InputObject -Name 'harness_id' -Errors $errors -MaxLength 64 }
    if ($fields -contains 'disposition_id') { Test-ReviewAuthorityIdField -Object $InputObject -Name 'disposition_id' -Kind disposition -Errors $errors }
    # Feature 203 T012 (FR-024, FR-041): the typed human turn that authorized the record. Optional, because every fact stored
    # before T012 lacks it and must still read; the authority audit (AuthorityAudit.ps1) is what fails a record without one.
    if ($fields -contains 'turn_identity') { Test-ReviewAuthorityStringField -Object $InputObject -Name 'turn_identity' -Errors $errors -MaxLength 256 -Optional }
    if ($ContractName -ceq 'ReservationFact') {
        Test-ReviewAuthorityStringField -Object $InputObject -Name 'budget_grant_id' -Errors $errors -MaxLength 64 -Optional
        Test-ReviewAuthorityStringField -Object $InputObject -Name 'reset_id' -Errors $errors -MaxLength 128 -Optional
    }

    switch ($ContractName) {
        'ReviewCampaign' {
            Test-ReviewAuthorityIdField -Object $InputObject -Name 'target_lineage' -Kind lineage -Errors $errors
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'created_at' -Errors $errors -MaxLength 64
        }
        'ReviewRun' {
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'state' -Errors $errors -MaxLength 32 -Enum @('requested', 'reserved', 'preflighted', 'claimed', 'invoked', 'validating', 'terminal')
        }
        'ReviewInvocation' {
            foreach ($name in @('snapshot_path', 'prompt_path', 'candidate_result_path', 'candidate_report_path')) {
                Test-ReviewAuthorityStringField -Object $InputObject -Name $name -Errors $errors -MaxLength 2048
            }
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'review_scope' -Errors $errors -MaxLength 16000
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'deadline' -Errors $errors -MaxLength 64
        }
        'ReviewerCandidate' {
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'completion' -Errors $errors -MaxLength 16 -Enum @('complete', 'partial')
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'verdict' -Errors $errors -MaxLength 16 -Enum @('pass', 'findings', 'incomplete')
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'summary' -Errors $errors -MaxLength $candidateLimits.max_summary_characters
            # W33. What the review says it examined. OPTIONAL by design: a reviewer that never emits
            # it behaves exactly as before, so no project already in flight is refused by a field it
            # has never heard of. The rule lives in the ingest degrade, not in this contract.
            Test-ReviewAuthorityExaminedPathsField -Object $InputObject -Name 'examined_paths' -Errors $errors
            Test-ReviewAuthorityFindingResolutionsField -Object $InputObject -Errors $errors
        }
        'ReviewResult' {
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'completion' -Errors $errors -MaxLength 16 -Enum @('complete', 'partial', 'none')
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'verdict' -Errors $errors -MaxLength 16 -Enum @('pass', 'findings', 'incomplete', 'failed')
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'runtime_outcome' -Errors $errors -MaxLength 32 -Enum @('completed', 'preflight-failed', 'claim-contended', 'launch-failed', 'timed-out', 'terminated', 'invalid-output', 'identity-mismatch', 'containment-violated', 'abandoned')
            Test-ReviewAuthorityBooleanField -Object $InputObject -Name 'termination_verified' -Errors $errors
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'containment' -Errors $errors -MaxLength 16 -Enum @('verified', 'violated', 'unknown')
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'currentness' -Errors $errors -MaxLength 32 -Enum @('current', 'snapshot-moved', 'unknown')
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'validation' -Errors $errors -MaxLength 16 -Enum @('valid', 'invalid', 'not-produced')
            Test-ReviewAuthorityBooleanField -Object $InputObject -Name 'can_approve_current' -Errors $errors
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'failure_reason' -Errors $errors -MaxLength 2000 -Optional
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'summary' -Errors $errors -MaxLength $candidateLimits.max_summary_characters
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'started_at' -Errors $errors -MaxLength 64
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'ended_at' -Errors $errors -MaxLength 64
            Test-ReviewAuthorityIntegerField -Object $InputObject -Name 'duration_ms' -Errors $errors -Minimum 0 -Maximum $script:ReviewAuthorityMaxDurationMilliseconds
            # W33. Carried into the terminal record so the coverage a verdict rests on survives the
            # projection. The declared-coverage rule was reachable only because nothing downstream
            # could see what the reviewer said it had read.
            Test-ReviewAuthorityExaminedPathsField -Object $InputObject -Name 'examined_paths' -Errors $errors
            # Feature 203 T008 (DRIFT-052 item 3): whether a complete review was collected, the fact a round is spent on.
            # Optional: a result written before T008 has none, and its completion stands in for it.
            Test-ReviewAuthorityBooleanField -Object $InputObject -Name 'review_collected' -Errors $errors -Optional
            # Feature 203 T008 (FR-009): which reviewer ran, so its infrastructure failures can be counted. Optional for the same reason.
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'reviewer_host' -Errors $errors -MaxLength 64 -Optional
            Test-ReviewAuthorityFindingResolutionsField -Object $InputObject -Errors $errors
        }
        'GrantFact' {
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'fact_type' -Errors $errors -MaxLength 16 -Enum @('grant')
            Test-ReviewAuthorityIdField -Object $InputObject -Name 'grant_id' -Kind grant -Errors $errors
            Test-ReviewAuthorityIntegerField -Object $InputObject -Name 'slots' -Errors $errors -Minimum 1 -Maximum 100
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'authority_kind' -Errors $errors -MaxLength 16 -Enum @('human')
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'authorization_ref' -Errors $errors -MaxLength 256
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'observed_at' -Errors $errors -MaxLength 64
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'reviewer_host' -Errors $errors -MaxLength 64 -Optional
        }
        'AllowedReviewerFact' {
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'fact_type' -Errors $errors -MaxLength 32 -Enum @('allowed-reviewer')
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'host' -Errors $errors -MaxLength 64
            $allowedHost = [string](Get-ReviewAuthorityProperty -Object $InputObject -Name 'host')
            if (-not [string]::IsNullOrEmpty($allowedHost) -and $allowedHost -cnotmatch '^[a-z][a-z0-9-]{0,31}$') { Add-ReviewAuthorityError -Errors $errors -Message 'invalid-value:host' }
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'authority_kind' -Errors $errors -MaxLength 16 -Enum @('human')
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'authorization_ref' -Errors $errors -MaxLength 256
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'observed_at' -Errors $errors -MaxLength 64
        }
        'BudgetGrantFact' {
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'fact_type' -Errors $errors -MaxLength 16 -Enum @('budget-grant')
            Test-ReviewAuthorityIdField -Object $InputObject -Name 'grant_id' -Kind grant -Errors $errors
            # The floor is 2 (FR-001); the ceiling is co_review_max_rounds, which may be set below the floor.
            Test-ReviewAuthorityIntegerField -Object $InputObject -Name 'budget_total' -Errors $errors -Minimum 2 -Maximum 100
            Test-ReviewAuthorityIntegerField -Object $InputObject -Name 'ceiling' -Errors $errors -Minimum 1 -Maximum 100
            Test-ReviewAuthorityIntegerField -Object $InputObject -Name 'infra_failure_cap' -Errors $errors -Minimum 1 -Maximum 10
            Test-ReviewAuthorityBooleanField -Object $InputObject -Name 'host_order_stated' -Errors $errors
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'budget_source' -Errors $errors -MaxLength 32 -Enum @('plan', 'floor-raised', 'floor-not-stated', 'floor-no-grant')
            # A floor grant (no grant was snapshotted, so the engine grants the FR-008 floor citing the recorded verdict)
            # never reads the plan: it names no plan, and it says why it is the floor and when its rounds count from.
            $isFloorGrant = [string](Get-ReviewAuthorityProperty -Object $InputObject -Name 'budget_source') -ceq 'floor-no-grant'
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'plan_path' -Errors $errors -MaxLength 512 -AllowEmpty:$isFloorGrant
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'floor_reason' -Errors $errors -MaxLength 1000 -Optional:(-not $isFloorGrant)
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'counts_from' -Errors $errors -MaxLength 64 -Optional:(-not $isFloorGrant)
            if ($isFloorGrant -and -not [string]::IsNullOrEmpty([string](Get-ReviewAuthorityProperty -Object $InputObject -Name 'plan_path'))) {
                Add-ReviewAuthorityError -Errors $errors -Message 'invalid-value:plan_path:floor-grant-reads-no-plan'
            }
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'plan_hash' -Errors $errors -MaxLength 64 -AllowEmpty:$isFloorGrant
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'verdict_entry' -Errors $errors -MaxLength 128
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'authority_kind' -Errors $errors -MaxLength 16 -Enum @('human')
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'observed_at' -Errors $errors -MaxLength 64
            $order = Get-ReviewAuthorityProperty -Object $InputObject -Name 'host_order'
            if ($null -ne $order -and $order -isnot [System.Collections.IEnumerable]) { Add-ReviewAuthorityError -Errors $errors -Message 'invalid-type:host_order' }
            elseif (@($order).Count -gt 16) { Add-ReviewAuthorityError -Errors $errors -Message 'too-many:host_order' }
            else {
                foreach ($hostName in @($order)) {
                    if ($hostName -isnot [string] -or $hostName -cnotmatch '^[a-z][a-z0-9-]{0,31}$') { Add-ReviewAuthorityError -Errors $errors -Message 'invalid-value:host_order'; break }
                }
            }
            $planHash = [string](Get-ReviewAuthorityProperty -Object $InputObject -Name 'plan_hash')
            if (-not [string]::IsNullOrEmpty($planHash) -and $planHash -cnotmatch '^[0-9a-f]{64}$') { Add-ReviewAuthorityError -Errors $errors -Message 'invalid-value:plan_hash' }
        }
        'ReservationFact' {
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'fact_type' -Errors $errors -MaxLength 16 -Enum @('reservation')
            Test-ReviewAuthorityIdField -Object $InputObject -Name 'reservation_id' -Kind reservation -Errors $errors
            Test-ReviewAuthorityIdField -Object $InputObject -Name 'grant_id' -Kind grant -Errors $errors
            Test-ReviewAuthorityIntegerField -Object $InputObject -Name 'slot' -Errors $errors -Minimum 1 -Maximum 100
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'observed_at' -Errors $errors -MaxLength 64
        }
        'SpendFact' {
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'fact_type' -Errors $errors -MaxLength 16 -Enum @('spend')
            Test-ReviewAuthorityIdField -Object $InputObject -Name 'reservation_id' -Kind reservation -Errors $errors
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'invocation_started_at' -Errors $errors -MaxLength 64
        }
        'ReleaseFact' {
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'fact_type' -Errors $errors -MaxLength 16 -Enum @('release')
            Test-ReviewAuthorityIdField -Object $InputObject -Name 'reservation_id' -Kind reservation -Errors $errors
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'reason' -Errors $errors -MaxLength 512
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'observed_at' -Errors $errors -MaxLength 64
        }
        'ClaimFact' {
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'fact_type' -Errors $errors -MaxLength 16 -Enum @('claim-held', 'claim-released', 'claim-abandoned')
            Test-ReviewAuthorityIdField -Object $InputObject -Name 'target_lineage' -Kind lineage -Errors $errors
            Test-ReviewAuthorityIntegerField -Object $InputObject -Name 'generation' -Errors $errors -Minimum 1 -Maximum ([int]::MaxValue)
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'disposition' -Errors $errors -MaxLength 16 -Enum @('held', 'released', 'abandoned')
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'observed_at' -Errors $errors -MaxLength 64
        }
        'HumanDispositionFact' {
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'fact_type' -Errors $errors -MaxLength 32 -Enum @('human-disposition')
            Test-ReviewAuthorityIdField -Object $InputObject -Name 'disposition_id' -Kind disposition -Errors $errors
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'decision' -Errors $errors -MaxLength 32 -Enum @('accept-current', 'require-correction')
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'authority_kind' -Errors $errors -MaxLength 16 -Enum @('human')
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'authorized_by' -Errors $errors -MaxLength 200
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'authorization_ref' -Errors $errors -MaxLength 256
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'rationale' -Errors $errors -MaxLength 2000
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'observed_at' -Errors $errors -MaxLength 64
        }
        'ReviewFinalizationFact' {
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'fact_type' -Errors $errors -MaxLength 32 -Enum @('review-finalization')
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'reviewed_digest' -Errors $errors -MaxLength 64
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'finalization_commit' -Errors $errors -MaxLength 64
            foreach ($name in @('reviewed_digest', 'finalization_commit')) {
                $value = [string](Get-ReviewAuthorityProperty -Object $InputObject -Name $name)
                if (-not [string]::IsNullOrWhiteSpace($value) -and $value -cnotmatch '^[0-9a-f]{40,64}$') {
                    Add-ReviewAuthorityError -Errors $errors -Message "invalid-git-object-id:$name"
                }
            }
        }
        'PendingPauseFact' {
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'fact_type' -Errors $errors -MaxLength 32 -Enum @('pending-pause')
            Test-ReviewAuthorityIntegerField -Object $InputObject -Name 'rounds_used' -Errors $errors -Minimum 0 -Maximum ([int]::MaxValue)
            # Feature 203 T008 step (iii): the finding counts are no longer written (nothing live read them); a fact stored
            # before carries them and stays valid.
            foreach ($name in @('blocking_count', 'major_count', 'minor_count', 'demoted_count')) {
                if ((Get-ReviewAuthorityPropertyNames -Object $InputObject) -contains $name) {
                    Test-ReviewAuthorityIntegerField -Object $InputObject -Name $name -Errors $errors -Minimum 0 -Maximum ([int]::MaxValue)
                }
            }
            Test-ReviewAuthorityIntegerField -Object $InputObject -Name 'budget_total' -Errors $errors -Minimum 1 -Maximum ([int]::MaxValue)
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'recommendation' -Errors $errors -MaxLength 4000 -Optional
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'observed_at' -Errors $errors -MaxLength 64
            $pauseNames = Get-ReviewAuthorityPropertyNames -Object $InputObject
            if ($pauseNames -contains 'evidence_state') {
                Test-ReviewAuthorityStringField -Object $InputObject -Name 'evidence_state' -Errors $errors -MaxLength 16 -Enum @('produced', 'not-produced')
            }
            if ($pauseNames -contains 'result_produced') {
                Test-ReviewAuthorityBooleanField -Object $InputObject -Name 'result_produced' -Errors $errors
            }
            if (($pauseNames -contains 'evidence_state') -xor ($pauseNames -contains 'result_produced')) {
                Add-ReviewAuthorityError -Errors $errors -Message 'incomplete-group:pause-evidence-state'
            }
            if ($pauseNames -contains 'stop_kind') {
                Test-ReviewAuthorityStringField -Object $InputObject -Name 'stop_kind' -Errors $errors -MaxLength 32 -Enum $script:ReviewCampaignStopKinds
            }
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'stop_reason' -Errors $errors -MaxLength 64 -Optional
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'next_host' -Errors $errors -MaxLength 64 -Optional
        }
        'FindingDispositionFact' {
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'fact_type' -Errors $errors -MaxLength 32 -Enum @('finding-disposition')
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'finding_key' -Errors $errors -MaxLength 256
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'answer' -Errors $errors -MaxLength 8 -Enum @('defer', 'drop', 'fix')
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'argument' -Errors $errors -MaxLength 512 -Optional
            if ([string](Get-ReviewAuthorityProperty -Object $InputObject -Name 'answer') -ceq 'defer' -and
                [string]::IsNullOrWhiteSpace([string](Get-ReviewAuthorityProperty -Object $InputObject -Name 'argument'))) {
                Add-ReviewAuthorityError -Errors $errors -Message 'missing-destination:argument'
            }
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'authority_kind' -Errors $errors -MaxLength 16 -Enum @('human')
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'authorization_ref' -Errors $errors -MaxLength 256
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'observed_at' -Errors $errors -MaxLength 64
        }
        'RecoveryFact' {
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'fact_type' -Errors $errors -MaxLength 16 -Enum @('recovery')
            Test-ReviewAuthorityIdField -Object $InputObject -Name 'target_lineage' -Kind lineage -Errors $errors
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'runtime_id' -Errors $errors -MaxLength 64
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'platform' -Errors $errors -MaxLength 16 -Enum @('fixture', 'windows', 'linux', 'macos')
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'containment_kind' -Errors $errors -MaxLength 32 -Enum @('fixture', 'job-object', 'cgroup-v2', 'process-group')
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'containment_id' -Errors $errors -MaxLength 4096
            Test-ReviewAuthorityIntegerField -Object $InputObject -Name 'process_id' -Errors $errors -Minimum 1 -Maximum ([int]::MaxValue)
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'process_started_at' -Errors $errors -MaxLength 64
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'invocation_started_at' -Errors $errors -MaxLength 64
            Test-ReviewAuthorityIntegerField -Object $InputObject -Name 'invocation_started_monotonic_ms' -Errors $errors -Minimum 0
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'target_kind' -Errors $errors -MaxLength 64
            foreach ($name in @('snapshot_path', 'workspace_root', 'origin_repo', 'git_root', 'staging_root')) {
                Test-ReviewAuthorityStringField -Object $InputObject -Name $name -Errors $errors -MaxLength 4096
            }
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'origin_head_before' -Errors $errors -MaxLength 128
            $names = Get-ReviewAuthorityPropertyNames -Object $InputObject
            $bindingNames = @(
                'verification_plan_present', 'verification_plan_sha256',
                'machinery_paths', 'machinery_paths_sha256',
                'excluded_path_patterns', 'excluded_path_patterns_sha256'
            )
            $historicalBindingNames = @(
                'verification_plan_present', 'verification_plan_sha256',
                'machinery_paths', 'machinery_paths_sha256'
            )
            $bindingCount = @($bindingNames | Where-Object { $names -contains $_ }).Count
            $historicalBindingComplete =
                @($historicalBindingNames | Where-Object { $names -notcontains $_ }).Count -eq 0 -and
                @(@('excluded_path_patterns', 'excluded_path_patterns_sha256') | Where-Object { $names -contains $_ }).Count -eq 0
            $currentBindingComplete = @($bindingNames | Where-Object { $names -notcontains $_ }).Count -eq 0
            if ($bindingCount -ne 0 -and -not $historicalBindingComplete -and -not $currentBindingComplete) {
                Add-ReviewAuthorityError -Errors $errors -Message 'incomplete-group:recovery-target-bindings'
            }
            if ($names -contains 'verification_plan_present') {
                Test-ReviewAuthorityBooleanField -Object $InputObject -Name 'verification_plan_present' -Errors $errors
            }
            foreach ($name in @('verification_plan_sha256', 'machinery_paths_sha256', 'excluded_path_patterns_sha256')) {
                if ($names -contains $name) { Test-ReviewAuthorityStringField -Object $InputObject -Name $name -Errors $errors -MaxLength 128 }
            }
            if ($names -contains 'excluded_path_patterns') {
                $patterns = Get-ReviewAuthorityProperty -Object $InputObject -Name 'excluded_path_patterns'
                if (($patterns -is [string]) -or ($patterns -isnot [System.Collections.IEnumerable])) {
                    Add-ReviewAuthorityError -Errors $errors -Message 'wrong-type:excluded_path_patterns:array'
                }
                else {
                    $patternArray = @($patterns)
                    if ($patternArray.Count -gt 256) { Add-ReviewAuthorityError -Errors $errors -Message 'too-many:excluded_path_patterns:256' }
                    foreach ($pattern in $patternArray) {
                        if ($pattern -isnot [string] -or [string]::IsNullOrWhiteSpace([string]$pattern) -or ([string]$pattern).Length -gt 1024) {
                            Add-ReviewAuthorityError -Errors $errors -Message 'invalid-value:excluded_path_patterns:item'
                            break
                        }
                    }
                }
            }
            if ($names -contains 'machinery_paths') {
                $paths = Get-ReviewAuthorityProperty -Object $InputObject -Name 'machinery_paths'
                if (($paths -is [string]) -or ($paths -isnot [System.Collections.IEnumerable])) {
                    Add-ReviewAuthorityError -Errors $errors -Message 'wrong-type:machinery_paths:array'
                }
                else {
                    $pathArray = @($paths)
                    if ($pathArray.Count -gt 512) { Add-ReviewAuthorityError -Errors $errors -Message 'too-many:machinery_paths:512' }
                    foreach ($path in $pathArray) {
                        if ($path -isnot [string] -or [string]::IsNullOrWhiteSpace([string]$path) -or ([string]$path).Length -gt 512) {
                            Add-ReviewAuthorityError -Errors $errors -Message 'invalid-value:machinery_paths:item'
                            break
                        }
                    }
                }
            }
        }
    }

    if ($fields -contains 'findings') {
        $names = Get-ReviewAuthorityPropertyNames -Object $InputObject
        if ($names -notcontains 'findings') {
            Add-ReviewAuthorityError -Errors $errors -Message 'missing-required:findings'
        }
        else {
            $findings = Get-ReviewAuthorityProperty -Object $InputObject -Name 'findings'
            if (($findings -is [string]) -or ($findings -isnot [System.Collections.IEnumerable])) {
                Add-ReviewAuthorityError -Errors $errors -Message 'wrong-type:findings:array'
            }
            else {
                $array = @($findings)
                if ($array.Count -gt $candidateLimits.max_findings) { Add-ReviewAuthorityError -Errors $errors -Message ("too-many:findings:$($candidateLimits.max_findings)") }
                $candidateLocalIds = $null
                if ($ContractName -ceq 'ReviewerCandidate') { $candidateLocalIds = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal) }
                for ($i = 0; $i -lt [Math]::Min($array.Count, $candidateLimits.max_findings); $i++) {
                    Test-ReviewAuthorityFinding -Finding $array[$i] -Kind $(if ($ContractName -ceq 'ReviewerCandidate') { 'candidate' } else { 'terminal' }) -Errors $errors -Index $i
                    if ($null -ne $candidateLocalIds) {
                        $localId = Get-ReviewAuthorityProperty -Object $array[$i] -Name 'local_id'
                        if ($localId -is [string] -and -not [string]::IsNullOrWhiteSpace($localId)) {
                            $isNewLocalId = $candidateLocalIds.Add([string]$localId)
                            if (-not $isNewLocalId) { Add-ReviewAuthorityError -Errors $errors -Message "duplicate-value:findings[$i].local_id" }
                        }
                    }
                }
            }
        }
    }

    # Cross-field state invariants: closed fields alone are not enough if their combination is illegal.
    if ($ContractName -ceq 'ReviewerCandidate') {
        $completion = [string](Get-ReviewAuthorityProperty -Object $InputObject -Name 'completion')
        $verdict = [string](Get-ReviewAuthorityProperty -Object $InputObject -Name 'verdict')
        $findingCount = @((Get-ReviewAuthorityProperty -Object $InputObject -Name 'findings')).Count
        if ($completion -ceq 'partial' -and $verdict -cne 'incomplete') { Add-ReviewAuthorityError -Errors $errors -Message 'illegal-state:partial-requires-incomplete-verdict' }
        if ($completion -ceq 'complete' -and $verdict -ceq 'incomplete') { Add-ReviewAuthorityError -Errors $errors -Message 'illegal-state:complete-cannot-be-incomplete' }
        if ($verdict -ceq 'pass' -and $findingCount -gt 0) { Add-ReviewAuthorityError -Errors $errors -Message 'illegal-state:pass-cannot-have-findings' }
        if ($verdict -ceq 'findings' -and $findingCount -eq 0) { Add-ReviewAuthorityError -Errors $errors -Message 'illegal-state:findings-verdict-requires-findings' }
    }
    elseif ($ContractName -ceq 'ReviewResult') {
        $completion = [string](Get-ReviewAuthorityProperty -Object $InputObject -Name 'completion')
        $verdict = [string](Get-ReviewAuthorityProperty -Object $InputObject -Name 'verdict')
        $runtime = [string](Get-ReviewAuthorityProperty -Object $InputObject -Name 'runtime_outcome')
        $termination = Get-ReviewAuthorityProperty -Object $InputObject -Name 'termination_verified'
        $containment = [string](Get-ReviewAuthorityProperty -Object $InputObject -Name 'containment')
        $currentness = [string](Get-ReviewAuthorityProperty -Object $InputObject -Name 'currentness')
        $validation = [string](Get-ReviewAuthorityProperty -Object $InputObject -Name 'validation')
        $approves = Get-ReviewAuthorityProperty -Object $InputObject -Name 'can_approve_current'
        if ($runtime -ceq 'timed-out' -and $termination -is [bool] -and -not [bool]$termination) { Add-ReviewAuthorityError -Errors $errors -Message 'illegal-state:timeout-requires-verified-termination' }
        if ($completion -ceq 'complete' -and ($runtime -cne 'completed' -or $validation -cne 'valid')) { Add-ReviewAuthorityError -Errors $errors -Message 'illegal-state:complete-requires-valid-completed-run' }
        if ($approves -is [bool] -and [bool]$approves -and
            ($completion -cne 'complete' -or $verdict -cne 'pass' -or $runtime -cne 'completed' -or -not [bool]$termination -or $containment -cne 'verified' -or $currentness -cne 'current' -or $validation -cne 'valid')) {
            Add-ReviewAuthorityError -Errors $errors -Message 'illegal-state:approval-prerequisites-not-proven'
        }
    }
    elseif ($ContractName -ceq 'ClaimFact') {
        $factType = [string](Get-ReviewAuthorityProperty -Object $InputObject -Name 'fact_type')
        $disposition = [string](Get-ReviewAuthorityProperty -Object $InputObject -Name 'disposition')
        if (($factType -ceq 'claim-held' -and $disposition -cne 'held') -or
            ($factType -ceq 'claim-released' -and $disposition -cne 'released') -or
            ($factType -ceq 'claim-abandoned' -and $disposition -cne 'abandoned')) {
            Add-ReviewAuthorityError -Errors $errors -Message 'illegal-state:claim-type-disposition-mismatch'
        }
    }

    $digestIdentityField = if ($ContractName -ceq 'ReviewFinalizationFact') { 'reviewed_digest' } else { 'target_digest' }
    foreach ($join in @(
        @{ field = 'campaign_id'; expected = $ExpectedCampaignId },
        @{ field = 'run_id'; expected = $ExpectedRunId },
        @{ field = $digestIdentityField; expected = $ExpectedTargetDigest }
    )) {
        if (-not [string]::IsNullOrWhiteSpace([string]$join.expected) -and
            [string](Get-ReviewAuthorityProperty -Object $InputObject -Name $join.field) -cne [string]$join.expected) {
            Add-ReviewAuthorityError -Errors $errors -Message ('identity-mismatch:' + $join.field)
        }
    }

    $category = if ($errors.Count -eq 0) { 'valid' }
    elseif (@($errors | Where-Object { $_ -like 'identity-mismatch:*' }).Count -gt 0) { 'identity-mismatch' }
    elseif (@($errors | Where-Object { $_ -like 'unsupported-version:*' }).Count -gt 0) { 'unsupported-version' }
    elseif (@($errors | Where-Object { $_ -like 'unknown-field:*' -or $_ -like '*.unknown-field:*' }).Count -gt 0) { 'unknown-field' }
    else { 'schema-invalid' }
    return [pscustomobject]@{ valid = ($errors.Count -eq 0); category = $category; errors = @($errors) }
}

function Test-ReviewAuthorityExaminedPathsField {
    # W33. An OPTIONAL, bounded list of repo-relative paths the review says it examined. Bounded on
    # both count and length for the reason every other field here is: this lands in an immutable
    # store, and an unbounded reviewer-supplied array is an unbounded write.
    param(
        [Parameter(Mandatory)]$Object,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.List[string]]$Errors,
        [int]$MaxCount = 500,
        [int]$MaxLength = 512
    )
    if (-not ($Object.PSObject.Properties.Name -contains $Name)) { return }
    $value = $Object.$Name
    if ($null -eq $value) { return }
    if ($value -is [string] -or -not ($value -is [System.Collections.IEnumerable])) {
        $Errors.Add("wrong-type:${Name}:array") | Out-Null; return
    }
    $items = @($value)
    if ($items.Count -gt $MaxCount) { $Errors.Add("too-many:${Name}:$MaxCount") | Out-Null; return }
    for ($i = 0; $i -lt $items.Count; $i++) {
        $item = $items[$i]
        if ($null -eq $item -or -not ($item -is [string])) { $Errors.Add("wrong-type:${Name}[$i]:string") | Out-Null; continue }
        if (([string]$item).Length -gt $MaxLength) { $Errors.Add("too-long:${Name}[$i]:$MaxLength") | Out-Null }
    }
}

function Test-ReviewAuthorityContractJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet(
            'ReviewCampaign', 'ReviewRun', 'ReviewInvocation', 'ReviewerCandidate', 'ReviewResult',
            'GrantFact', 'ReservationFact', 'SpendFact', 'ReleaseFact', 'ClaimFact', 'HumanDispositionFact',
            'RecoveryFact', 'ReviewFinalizationFact'
        )][string]$ContractName,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Json,
        [int]$MaxBytes = $script:ReviewAuthorityCandidateLimits.max_candidate_bytes,
        [string]$ExpectedCampaignId,
        [string]$ExpectedRunId,
        [string]$ExpectedTargetDigest
    )
    if ([System.Text.Encoding]::UTF8.GetByteCount($Json) -gt $MaxBytes) {
        return [pscustomobject]@{ valid = $false; category = 'payload-too-large'; errors = @("payload-too-large:$MaxBytes") }
    }
    $trimmed = $Json.Trim()
    if (-not $trimmed.StartsWith('{') -or -not $trimmed.EndsWith('}')) {
        return [pscustomobject]@{ valid = $false; category = 'prose-wrapped-json'; errors = @('prose-wrapped-json') }
    }
    try {
        $document = [System.Text.Json.JsonDocument]::Parse($trimmed)
        try {
            if ($document.RootElement.ValueKind -ne [System.Text.Json.JsonValueKind]::Object) {
                return [pscustomobject]@{ valid = $false; category = 'schema-invalid'; errors = @('wrong-type:$:object') }
            }
            $duplicatePaths = [Collections.Generic.List[string]]::new()
            $pending = [Collections.Generic.Stack[object]]::new()
            $pending.Push([pscustomobject]@{ element = $document.RootElement; path = '$' })
            while ($pending.Count -gt 0) {
                $node = $pending.Pop()
                $element = [System.Text.Json.JsonElement]$node.element
                $path = [string]$node.path
                if ($element.ValueKind -eq [System.Text.Json.JsonValueKind]::Object) {
                    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
                    foreach ($property in $element.EnumerateObject()) {
                        $childPath = if ($path -ceq '$') { '$.' + $property.Name } else { $path + '.' + $property.Name }
                        if (-not $seen.Add($property.Name)) { $duplicatePaths.Add($childPath) | Out-Null }
                        $pending.Push([pscustomobject]@{ element = $property.Value; path = $childPath })
                    }
                }
                elseif ($element.ValueKind -eq [System.Text.Json.JsonValueKind]::Array) {
                    $index = 0
                    foreach ($item in $element.EnumerateArray()) {
                        $pending.Push([pscustomobject]@{ element = $item; path = "$path[$index]" })
                        $index++
                    }
                }
            }
            if ($duplicatePaths.Count -gt 0) {
                return [pscustomobject]@{ valid = $false; category = 'duplicate-field'; errors = @($duplicatePaths | ForEach-Object { 'duplicate-field:' + $_ }) }
            }
        }
        finally { $document.Dispose() }
    }
    catch [System.Text.Json.JsonException] {
        return [pscustomobject]@{ valid = $false; category = 'invalid-json'; errors = @('invalid-json') }
    }
    try { $object = $trimmed | ConvertFrom-Json -Depth 20 -ErrorAction Stop }
    catch { return [pscustomobject]@{ valid = $false; category = 'invalid-json'; errors = @('invalid-json') } }
    return Test-ReviewAuthorityContractObject -ContractName $ContractName -InputObject $object -ExpectedCampaignId $ExpectedCampaignId -ExpectedRunId $ExpectedRunId -ExpectedTargetDigest $ExpectedTargetDigest
}

# --- T043: campaign allowance, spend, rerun, and selection policy -------------------------------

function Get-ReviewCampaignAllowanceState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CampaignId,
        [object[]]$Grants = @(),
        [object[]]$Reservations = @(),
        [object[]]$Spends = @(),
        [object[]]$Releases = @()
    )
    $errors = [System.Collections.Generic.List[string]]::new()
    $available = [System.Collections.Generic.List[object]]::new()
    $active = [System.Collections.Generic.List[object]]::new()
    $spent = [System.Collections.Generic.List[object]]::new()
    $seenSlots = @{}
    $releaseIds = @($Releases | ForEach-Object { [string](Get-ReviewAuthorityProperty -Object $_ -Name 'reservation_id') })
    $spendIds = @($Spends | ForEach-Object { [string](Get-ReviewAuthorityProperty -Object $_ -Name 'reservation_id') })

    foreach ($spend in @($Spends)) {
        $validation = Test-ReviewAuthorityContractObject -ContractName SpendFact -InputObject $spend -ExpectedCampaignId $CampaignId
        if (-not $validation.valid) { foreach ($error in $validation.errors) { Add-ReviewAuthorityError -Errors $errors -Message "spend:$error" } }
    }
    foreach ($release in @($Releases)) {
        $validation = Test-ReviewAuthorityContractObject -ContractName ReleaseFact -InputObject $release -ExpectedCampaignId $CampaignId
        if (-not $validation.valid) { foreach ($error in $validation.errors) { Add-ReviewAuthorityError -Errors $errors -Message "release:$error" } }
    }
    foreach ($reservationId in @($spendIds | Where-Object { $_ -cin $releaseIds })) {
        Add-ReviewAuthorityError -Errors $errors -Message "reservation-both-spent-and-released:$reservationId"
    }

    foreach ($grant in @($Grants)) {
        $validation = Test-ReviewAuthorityContractObject -ContractName GrantFact -InputObject $grant -ExpectedCampaignId $CampaignId
        if (-not $validation.valid) { foreach ($error in $validation.errors) { Add-ReviewAuthorityError -Errors $errors -Message "grant:$error" }; continue }
        $grantId = [string](Get-ReviewAuthorityProperty -Object $grant -Name 'grant_id')
        $slots = [int](Get-ReviewAuthorityProperty -Object $grant -Name 'slots')
        for ($slot = 1; $slot -le $slots; $slot++) {
            $matching = @($Reservations | Where-Object {
                [string](Get-ReviewAuthorityProperty -Object $_ -Name 'grant_id') -ceq $grantId -and
                [int](Get-ReviewAuthorityProperty -Object $_ -Name 'slot') -eq $slot
            })
            if ($matching.Count -eq 0) { $available.Add([pscustomobject]@{ grant_id = $grantId; slot = $slot }) | Out-Null; continue }
            $unreleased = [System.Collections.Generic.List[object]]::new()
            $spentForSlot = [System.Collections.Generic.List[object]]::new()
            foreach ($reservation in $matching) {
                $reservationValidation = Test-ReviewAuthorityContractObject -ContractName ReservationFact -InputObject $reservation -ExpectedCampaignId $CampaignId
                if (-not $reservationValidation.valid) { foreach ($error in $reservationValidation.errors) { Add-ReviewAuthorityError -Errors $errors -Message "reservation:$error" }; continue }
                $reservationId = [string](Get-ReviewAuthorityProperty -Object $reservation -Name 'reservation_id')
                if ($spendIds -ccontains $reservationId) { $spentForSlot.Add($reservation) | Out-Null }
                elseif ($releaseIds -cnotcontains $reservationId) { $unreleased.Add($reservation) | Out-Null }
            }
            if ($spentForSlot.Count -gt 1 -or $unreleased.Count -gt 1 -or ($spentForSlot.Count -gt 0 -and $unreleased.Count -gt 0)) {
                Add-ReviewAuthorityError -Errors $errors -Message ('overlapping-reservation-slot:{0}:{1}' -f $grantId, $slot)
            }
            elseif ($spentForSlot.Count -eq 1) { $spent.Add($spentForSlot[0]) | Out-Null }
            elseif ($unreleased.Count -eq 1) { $active.Add($unreleased[0]) | Out-Null }
            else { $available.Add([pscustomobject]@{ grant_id = $grantId; slot = $slot }) | Out-Null }
            $seenSlots["$grantId/$slot"] = $true
        }
    }
    foreach ($reservation in @($Reservations)) {
        $key = '{0}/{1}' -f [string](Get-ReviewAuthorityProperty -Object $reservation -Name 'grant_id'), [int](Get-ReviewAuthorityProperty -Object $reservation -Name 'slot')
        if (-not $seenSlots.ContainsKey($key)) { Add-ReviewAuthorityError -Errors $errors -Message "reservation-without-grant-slot:$key" }
    }
    return [pscustomobject]@{
        valid = ($errors.Count -eq 0); errors = @($errors); available = @($available)
        active = @($active); spent = @($spent); granted_slots = (@($available).Count + @($active).Count + @($spent).Count)
    }
}

function Resolve-ReviewCampaignReservationDecision {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$ReservationId,
        [Parameter(Mandatory)][string]$ObservedAt,
        [object[]]$Grants = @(), [object[]]$Reservations = @(), [object[]]$Spends = @(), [object[]]$Releases = @(),
        # Feature 203 T012 (FR-024): the window the reservation is spent in, and the typed turn that opened it.
        [AllowEmptyString()][string]$BudgetGrantId = '', [AllowEmptyString()][string]$ResetId = '', [AllowEmptyString()][string]$TurnIdentity = ''
    )
    if (-not (Test-ReviewAuthorityIdentifier -Value $RunId -Kind run) -or -not (Test-ReviewAuthorityIdentifier -Value $ReservationId -Kind reservation)) {
        return [pscustomobject]@{ permitted = $false; reason = 'invalid-reservation-identity'; fact = $null }
    }
    if (@($Reservations | Where-Object { [string](Get-ReviewAuthorityProperty -Object $_ -Name 'run_id') -ceq $RunId }).Count -gt 0) {
        return [pscustomobject]@{ permitted = $false; reason = 'run-already-reserved'; fact = $null }
    }
    if (@($Reservations | Where-Object { [string](Get-ReviewAuthorityProperty -Object $_ -Name 'reservation_id') -ceq $ReservationId }).Count -gt 0) {
        return [pscustomobject]@{ permitted = $false; reason = 'reservation-id-already-used'; fact = $null }
    }
    $state = Get-ReviewCampaignAllowanceState -CampaignId $CampaignId -Grants $Grants -Reservations $Reservations -Spends $Spends -Releases $Releases
    if (-not $state.valid) { return [pscustomobject]@{ permitted = $false; reason = 'allowance-corrupt'; fact = $null; errors = $state.errors } }
    if ($state.available.Count -eq 0) { return [pscustomobject]@{ permitted = $false; reason = 'allowance-exhausted'; fact = $null } }
    $slot = @($state.available | Sort-Object grant_id, slot)[0]
    $fact = [pscustomobject][ordered]@{
        schema_version = '1.0'; fact_type = 'reservation'; campaign_id = $CampaignId
        reservation_id = $ReservationId; grant_id = [string]$slot.grant_id; slot = [int]$slot.slot
        run_id = $RunId; observed_at = $ObservedAt
    }
    # Feature 203 T012 (FR-024): the slot's launch grant may have been minted in an older window (a released slot is reused),
    # so the reservation names the window it is spent in, and the turn that opened that window, on its own record.
    if (-not [string]::IsNullOrWhiteSpace($BudgetGrantId)) { $fact | Add-Member -NotePropertyName budget_grant_id -NotePropertyValue $BudgetGrantId.Trim() }
    if (-not [string]::IsNullOrWhiteSpace($ResetId)) { $fact | Add-Member -NotePropertyName reset_id -NotePropertyValue $ResetId.Trim() }
    if (-not [string]::IsNullOrWhiteSpace($TurnIdentity)) { $fact | Add-Member -NotePropertyName turn_identity -NotePropertyValue $TurnIdentity.Trim() }
    return [pscustomobject]@{ permitted = $true; reason = 'slot-available'; fact = $fact }
}

function Resolve-ReviewCampaignSpendDecision {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Reservation,
        [Parameter(Mandatory)][string]$InvocationStartedAt,
        [hashtable]$Preflight,
        [object[]]$Spends = @(),
        [object[]]$Releases = @()
    )
    $reservationValidation = Test-ReviewAuthorityContractObject -ContractName ReservationFact -InputObject $Reservation
    if (-not $reservationValidation.valid) { return [pscustomobject]@{ permitted = $false; reason = 'invalid-reservation'; fact = $null; errors = $reservationValidation.errors } }
    $reservationId = [string](Get-ReviewAuthorityProperty -Object $Reservation -Name 'reservation_id')
    $failedChecks = @()
    foreach ($name in @('target', 'store', 'contract', 'containment', 'verification', 'harness', 'runtime')) {
        if ($null -eq $Preflight -or -not $Preflight.ContainsKey($name) -or -not [bool]$Preflight[$name]) { $failedChecks += $name }
    }
    if ($failedChecks.Count -gt 0) { return [pscustomobject]@{ permitted = $false; reason = ('preflight-failed:' + ($failedChecks -join ',')); fact = $null } }
    if (@($Releases | Where-Object { [string](Get-ReviewAuthorityProperty -Object $_ -Name 'reservation_id') -ceq $reservationId }).Count -gt 0) {
        return [pscustomobject]@{ permitted = $false; reason = 'reservation-released'; fact = $null }
    }
    if (@($Spends | Where-Object { [string](Get-ReviewAuthorityProperty -Object $_ -Name 'reservation_id') -ceq $reservationId }).Count -gt 0) {
        return [pscustomobject]@{ permitted = $false; reason = 'reservation-already-spent'; fact = $null }
    }
    $fact = [pscustomobject][ordered]@{
        schema_version = '1.0'; fact_type = 'spend'
        campaign_id = [string](Get-ReviewAuthorityProperty -Object $Reservation -Name 'campaign_id')
        reservation_id = $reservationId; run_id = [string](Get-ReviewAuthorityProperty -Object $Reservation -Name 'run_id')
        invocation_started_at = $InvocationStartedAt
    }
    return [pscustomobject]@{ permitted = $true; reason = 'preflight-passed-invocation-spends-slot'; fact = $fact }
}

function Resolve-ReviewCampaignReleaseDecision {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Reservation,
        [Parameter(Mandatory)][string]$Reason,
        [Parameter(Mandatory)][string]$ObservedAt,
        [object[]]$Spends = @(),
        [object[]]$Releases = @()
    )
    $reservationValidation = Test-ReviewAuthorityContractObject -ContractName ReservationFact -InputObject $Reservation
    if (-not $reservationValidation.valid) { return [pscustomobject]@{ permitted = $false; reason = 'invalid-reservation'; fact = $null; errors = $reservationValidation.errors } }
    $reservationId = [string](Get-ReviewAuthorityProperty -Object $Reservation -Name 'reservation_id')
    if (@($Spends | Where-Object { [string](Get-ReviewAuthorityProperty -Object $_ -Name 'reservation_id') -ceq $reservationId }).Count -gt 0) {
        return [pscustomobject]@{ permitted = $false; reason = 'invoked-slot-remains-spent'; fact = $null }
    }
    if (@($Releases | Where-Object { [string](Get-ReviewAuthorityProperty -Object $_ -Name 'reservation_id') -ceq $reservationId }).Count -gt 0) {
        return [pscustomobject]@{ permitted = $false; reason = 'reservation-already-released'; fact = $null }
    }
    $fact = [pscustomobject][ordered]@{
        schema_version = '1.0'; fact_type = 'release'
        campaign_id = [string](Get-ReviewAuthorityProperty -Object $Reservation -Name 'campaign_id')
        reservation_id = $reservationId; run_id = [string](Get-ReviewAuthorityProperty -Object $Reservation -Name 'run_id')
        reason = ConvertTo-ReviewAuthorityBoundedText -Value $Reason -MaximumLength 512
        observed_at = $ObservedAt
    }
    return [pscustomobject]@{ permitted = $true; reason = 'proven-pre-invocation-release'; fact = $fact }
}

function Resolve-ReviewRerunDecision {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$PriorResult,
        [Parameter(Mandatory)][string]$ProposedRunId,
        [string[]]$ExistingRunIds = @(),
        [Parameter(Mandatory)][bool]$HasAvailableSlot
    )
    $complete = [string](Get-ReviewAuthorityProperty -Object $PriorResult -Name 'completion') -ceq 'complete'
    $current = [string](Get-ReviewAuthorityProperty -Object $PriorResult -Name 'currentness') -ceq 'current'
    $valid = [string](Get-ReviewAuthorityProperty -Object $PriorResult -Name 'validation') -ceq 'valid'
    if ($complete -and $current -and $valid) { return [pscustomobject]@{ required = $false; launch = $false; action = 'none'; reason = 'complete-current-result' } }
    $priorRunId = [string](Get-ReviewAuthorityProperty -Object $PriorResult -Name 'run_id')
    if (-not (Test-ReviewAuthorityIdentifier -Value $ProposedRunId -Kind run) -or $ProposedRunId -ceq $priorRunId -or $ProposedRunId -cin @($ExistingRunIds)) {
        return [pscustomobject]@{ required = $true; launch = $false; action = 'reject'; reason = 'rerun-requires-new-run-id' }
    }
    if ($HasAvailableSlot) { return [pscustomobject]@{ required = $true; launch = $true; action = 'launch-visible-rerun'; reason = 'authorized-slot-available' } }
    return [pscustomobject]@{ required = $true; launch = $false; action = 'request-human-grant'; reason = 'allowance-exhausted' }
}

function Resolve-ReviewCampaignSelectedResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TargetDigest,
        [Parameter(Mandatory)][string[]]$OrderedRunIds,
        [object[]]$Results = @()
    )
    $eligible = @{}
    foreach ($result in @($Results)) {
        $runId = [string](Get-ReviewAuthorityProperty -Object $result -Name 'run_id')
        if ([string](Get-ReviewAuthorityProperty -Object $result -Name 'target_digest') -ceq $TargetDigest -and
            [string](Get-ReviewAuthorityProperty -Object $result -Name 'completion') -ceq 'complete' -and
            [string](Get-ReviewAuthorityProperty -Object $result -Name 'currentness') -ceq 'current' -and
            [string](Get-ReviewAuthorityProperty -Object $result -Name 'validation') -ceq 'valid') {
            if ($eligible.ContainsKey($runId)) { return [pscustomobject]@{ valid = $false; selected_run_id = $null; reason = 'duplicate-terminal-result-for-run' } }
            $eligible[$runId] = $result
        }
    }
    $selected = $null
    foreach ($runId in @($OrderedRunIds)) { if ($eligible.ContainsKey($runId)) { $selected = $runId } }
    return [pscustomobject]@{ valid = $true; selected_run_id = $selected; reason = $(if ($null -eq $selected) { 'no-applicable-result' } else { 'latest-ordered-applicable-result' }) }
}

function Test-ReviewCampaignDuplicateCombination {
    param(
        [Parameter(Mandatory)][string]$TargetDigest,
        [Parameter(Mandatory)][string]$HarnessId,
        [Parameter(Mandatory)][string]$ContractVersion,
        [object[]]$Runs = @()
    )
    $matchedItems = @($Runs | Where-Object {
        [string](Get-ReviewAuthorityProperty -Object $_ -Name 'target_digest') -ceq $TargetDigest -and
        [string](Get-ReviewAuthorityProperty -Object $_ -Name 'harness_id') -ceq $HarnessId -and
        [string](Get-ReviewAuthorityProperty -Object $_ -Name 'schema_version') -ceq $ContractVersion
    })
    return [pscustomobject]@{ duplicate = ($matchedItems.Count -gt 0); prior_run_ids = @($matchedItems | ForEach-Object { [string](Get-ReviewAuthorityProperty -Object $_ -Name 'run_id') }) }
}

# --- T044: one-invocation run, acceptance/currentness, and finding lineage ----------------------

function Resolve-ReviewRunTransition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('requested', 'reserved', 'preflighted', 'claimed', 'invoked', 'validating', 'terminal')][string]$CurrentState,
        [Parameter(Mandatory)][ValidateSet('reserve', 'preflight-pass', 'claim', 'invoke', 'candidate-ready', 'close-pre-invocation', 'close-post-invocation')][string]$Event,
        [bool]$TerminalResultExists = $false
    )
    if ($CurrentState -ceq 'terminal' -or $TerminalResultExists) { return [pscustomobject]@{ allowed = $false; next_state = $CurrentState; reason = 'terminal-is-immutable' } }
    $key = "$CurrentState/$Event"
    $next = switch ($key) {
        'requested/reserve' { 'reserved' }
        'reserved/preflight-pass' { 'preflighted' }
        'preflighted/claim' { 'claimed' }
        'claimed/invoke' { 'invoked' }
        'invoked/candidate-ready' { 'validating' }
        'reserved/close-pre-invocation' { 'terminal' }
        'preflighted/close-pre-invocation' { 'terminal' }
        'claimed/close-pre-invocation' { 'terminal' }
        'invoked/close-post-invocation' { 'terminal' }
        'validating/close-post-invocation' { 'terminal' }
        default { $null }
    }
    if ($null -eq $next) { return [pscustomobject]@{ allowed = $false; next_state = $CurrentState; reason = 'illegal-run-transition' } }
    return [pscustomobject]@{ allowed = $true; next_state = $next; reason = 'legal-run-transition' }
}

function Resolve-ReviewCurrentness {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$ReviewedDigest,
        [Parameter(Mandatory)][AllowEmptyString()][string]$CurrentDigest,
        [Parameter(Mandatory)][AllowEmptyString()][string]$OriginHeadBefore,
        [Parameter(Mandatory)][AllowEmptyString()][string]$OriginHeadAfter
    )
    if ([string]::IsNullOrWhiteSpace($ReviewedDigest) -or [string]::IsNullOrWhiteSpace($CurrentDigest) -or
        [string]::IsNullOrWhiteSpace($OriginHeadBefore) -or [string]::IsNullOrWhiteSpace($OriginHeadAfter)) {
        return [pscustomobject]@{ classification = 'unknown'; exact = $false; reason = 'currentness-evidence-incomplete' }
    }
    if ($OriginHeadBefore -cne $OriginHeadAfter -or $ReviewedDigest -cne $CurrentDigest) {
        return [pscustomobject]@{ classification = 'snapshot-moved'; exact = $false; reason = 'origin-head-or-reviewed-digest-moved' }
    }
    return [pscustomobject]@{ classification = 'current'; exact = $true; reason = 'exact-head-and-digest-match' }
}

function Resolve-ReviewResultClassification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('completed', 'preflight-failed', 'claim-contended', 'launch-failed', 'timed-out', 'terminated', 'invalid-output', 'identity-mismatch', 'containment-violated', 'abandoned')][string]$RuntimeOutcome,
        [Parameter(Mandatory)][bool]$Invoked,
        [Parameter(Mandatory)][bool]$TerminationVerified,
        [Parameter(Mandatory)][ValidateSet('verified', 'violated', 'unknown')][string]$Containment,
        [Parameter(Mandatory)][ValidateSet('current', 'snapshot-moved', 'unknown')][string]$Currentness,
        [AllowNull()]$Candidate,
        [Parameter(Mandatory)][bool]$CandidateValid
    )
    if ($RuntimeOutcome -ceq 'timed-out' -and -not $TerminationVerified) {
        return [pscustomobject]@{ publish_permitted = $false; reason = 'timeout-requires-verified-tree-death'; completion = 'none'; verdict = 'failed'; findings_advisory = $true; can_approve_current = $false; require_complete_rerun = $true }
    }
    if ($Invoked -and -not $TerminationVerified) {
        return [pscustomobject]@{ publish_permitted = $false; reason = 'runtime-terminal-requires-verified-tree-death'; completion = 'none'; verdict = 'failed'; findings_advisory = $true; can_approve_current = $false; require_complete_rerun = $true }
    }
    $candidateFindings = @()
    if ($CandidateValid -and $null -ne $Candidate) { $candidateFindings = @((Get-ReviewAuthorityProperty -Object $Candidate -Name 'findings') | Where-Object { $null -ne $_ }) }
    $candidateCompletion = if ($CandidateValid -and $null -ne $Candidate) { [string](Get-ReviewAuthorityProperty -Object $Candidate -Name 'completion') } else { 'none' }
    $candidateVerdict = if ($CandidateValid -and $null -ne $Candidate) { [string](Get-ReviewAuthorityProperty -Object $Candidate -Name 'verdict') } else { 'failed' }
    $complete = $RuntimeOutcome -ceq 'completed' -and $CandidateValid -and $candidateCompletion -ceq 'complete' -and $Containment -ceq 'verified' -and $TerminationVerified
    $canApprove = $complete -and $Currentness -ceq 'current' -and $candidateVerdict -ceq 'pass' -and $TerminationVerified
    $advisory = (-not $complete) -or $Currentness -cne 'current' -or $Containment -cne 'verified'
    $completion = if ($complete) { 'complete' } elseif ($candidateFindings.Count -gt 0 -or $candidateCompletion -ceq 'partial') { 'partial' } else { 'none' }
    $verdict = if ($complete) { $candidateVerdict } elseif ($Invoked) { 'incomplete' } else { 'failed' }
    $reason = if (-not $Invoked) { $RuntimeOutcome }
    elseif (-not $CandidateValid) { 'candidate-invalid' }
    elseif ($Containment -ceq 'violated') { 'containment-violated' }
    elseif ($Currentness -ceq 'snapshot-moved') { 'snapshot-moved' }
    elseif (-not $complete) { $RuntimeOutcome }
    else { 'complete-result' }
    return [pscustomobject]@{
        publish_permitted = $true; reason = $reason; completion = $completion; verdict = $verdict
        findings_advisory = $advisory; can_approve_current = $canApprove
        require_complete_rerun = (-not $complete -or $Currentness -cne 'current')
        findings = $candidateFindings
    }
}

function Get-ReviewFindingMatchKey {
    param([Parameter(Mandatory)]$Finding)
    $parts = foreach ($name in @('location', 'title', 'description')) {
        $text = [string](Get-ReviewAuthorityProperty -Object $Finding -Name $name)
        (($text.Trim().ToLowerInvariant()) -replace '\s+', ' ')
    }
    $material = $parts -join "`n"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($material)
    return [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
}

function Resolve-ReviewFindingLineage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RunId,
        [object[]]$CurrentFindings = @(),
        [object[]]$PriorFindings = @()
    )
    $priorByKey = @{}
    foreach ($prior in @($PriorFindings)) {
        $key = Get-ReviewFindingMatchKey -Finding $prior
        if (-not $priorByKey.ContainsKey($key)) { $priorByKey[$key] = $prior }
    }
    $links = [System.Collections.Generic.List[object]]::new()
    $index = 0
    foreach ($current in @($CurrentFindings | Where-Object { $null -ne $_ })) {
        $index++
        $key = Get-ReviewFindingMatchKey -Finding $current
        $prior = if ($priorByKey.ContainsKey($key)) { $priorByKey[$key] } else { $null }
        $lineageId = if ($null -ne $prior -and -not [string]::IsNullOrWhiteSpace([string](Get-ReviewAuthorityProperty -Object $prior -Name 'lineage_id'))) {
            [string](Get-ReviewAuthorityProperty -Object $prior -Name 'lineage_id')
        }
        else { 'lin-' + $key.Substring(0, 16) }
        $findingMaterial = [Text.Encoding]::UTF8.GetBytes(('{0}/{1}/{2}' -f $RunId, $index, $key))
        $findingHash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($findingMaterial)).ToLowerInvariant()
        $links.Add([pscustomobject]@{
            run_id = $RunId; current_local_id = [string](Get-ReviewAuthorityProperty -Object $current -Name 'local_id')
            finding_id = ('finding-' + $findingHash.Substring(0, 16))
            lineage_id = $lineageId; matched_prior_finding_id = $(if ($null -ne $prior) { [string](Get-ReviewAuthorityProperty -Object $prior -Name 'finding_id') } else { $null })
            severity = [string](Get-ReviewAuthorityProperty -Object $current -Name 'severity')
            prior_severity = $(if ($null -ne $prior) { [string](Get-ReviewAuthorityProperty -Object $prior -Name 'severity') } else { $null })
            match_key = $key
        }) | Out-Null
    }
    return @($links)
}
