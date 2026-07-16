$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# F-198 / T042-T044: dependency-free PURE review authority core. This file intentionally performs
# no filesystem, Git, process, environment, or clock I/O. Callers pass immutable facts and observed
# timestamps in; adapters execute the returned decisions.

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

function Test-ReviewAuthorityIdentifier {
    param(
        [AllowNull()]$Value,
        [Parameter(Mandatory)][ValidateSet('campaign', 'run', 'grant', 'reservation', 'finding', 'lineage')][string]$Kind
    )
    if ($Value -isnot [string]) { return $false }
    $prefix = switch ($Kind) {
        'campaign' { 'cmp' }
        'run' { 'run' }
        'grant' { 'grant' }
        'reservation' { 'res' }
        'finding' { 'finding' }
        'lineage' { 'lin' }
    }
    return ([string]$Value -cmatch ('^{0}-[a-z0-9][a-z0-9-]{{0,63}}$' -f $prefix))
}

function Add-ReviewAuthorityError {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.List[string]]$Errors,
        [Parameter(Mandatory)][string]$Message
    )
    $Errors.Add($Message) | Out-Null
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
        [Parameter(Mandatory)][ValidateSet('campaign', 'run', 'grant', 'reservation', 'finding', 'lineage')][string]$Kind,
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
    $prefix = "findings[$Index]"
    $allowed = if ($Kind -ceq 'candidate') {
        @('local_id', 'severity', 'title', 'description', 'location')
    }
    else {
        @('finding_id', 'source_local_id', 'lineage_id', 'severity', 'title', 'description', 'location', 'relevance', 'resolution')
    }
    $nested = [System.Collections.Generic.List[string]]::new()
    if (-not (Test-ReviewAuthorityClosedShape -Object $Finding -Allowed $allowed -Errors $nested)) {
        foreach ($error in $nested) { Add-ReviewAuthorityError -Errors $Errors -Message "$prefix.$error" }
        return
    }
    if ($Kind -ceq 'candidate') {
        Test-ReviewAuthorityStringField -Object $Finding -Name 'local_id' -Errors $nested -MaxLength 64
    }
    else {
        Test-ReviewAuthorityIdField -Object $Finding -Name 'finding_id' -Kind finding -Errors $nested
        Test-ReviewAuthorityStringField -Object $Finding -Name 'source_local_id' -Errors $nested -MaxLength 64
        Test-ReviewAuthorityIdField -Object $Finding -Name 'lineage_id' -Kind lineage -Errors $nested
        Test-ReviewAuthorityStringField -Object $Finding -Name 'relevance' -Errors $nested -MaxLength 32 -Enum @('current', 'snapshot-moved', 'unknown')
        Test-ReviewAuthorityStringField -Object $Finding -Name 'resolution' -Errors $nested -MaxLength 32 -Enum @('open', 'resolved', 'superseded')
    }
    Test-ReviewAuthorityStringField -Object $Finding -Name 'severity' -Errors $nested -MaxLength 16 -Enum @('blocking', 'major', 'minor', 'note')
    Test-ReviewAuthorityStringField -Object $Finding -Name 'title' -Errors $nested -MaxLength 200
    Test-ReviewAuthorityStringField -Object $Finding -Name 'description' -Errors $nested -MaxLength 4000
    Test-ReviewAuthorityStringField -Object $Finding -Name 'location' -Errors $nested -MaxLength 1000 -Optional
    foreach ($error in $nested) { Add-ReviewAuthorityError -Errors $Errors -Message "$prefix.$error" }
}

function Test-ReviewAuthorityContractObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet(
            'ReviewCampaign', 'ReviewRun', 'ReviewInvocation', 'ReviewerCandidate', 'ReviewResult',
            'GrantFact', 'ReservationFact', 'SpendFact', 'ReleaseFact', 'ClaimFact'
        )][string]$ContractName,
        [Parameter(Mandatory)]$InputObject,
        [string]$ExpectedCampaignId,
        [string]$ExpectedRunId,
        [string]$ExpectedTargetDigest
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $fields = switch ($ContractName) {
        'ReviewCampaign' { @('schema_version', 'campaign_id', 'target_lineage', 'created_at') }
        'ReviewRun' { @('schema_version', 'campaign_id', 'run_id', 'target_digest', 'harness_id', 'state') }
        'ReviewInvocation' { @('schema_version', 'campaign_id', 'run_id', 'target_digest', 'snapshot_path', 'review_scope', 'prompt_path', 'candidate_result_path', 'candidate_report_path', 'deadline') }
        'ReviewerCandidate' { @('schema_version', 'run_id', 'target_digest', 'completion', 'verdict', 'summary', 'findings') }
        'ReviewResult' { @('schema_version', 'campaign_id', 'run_id', 'target_digest', 'harness_id', 'completion', 'verdict', 'runtime_outcome', 'termination_verified', 'containment', 'currentness', 'validation', 'can_approve_current', 'failure_reason', 'summary', 'findings', 'started_at', 'ended_at', 'duration_ms') }
        'GrantFact' { @('schema_version', 'fact_type', 'campaign_id', 'grant_id', 'slots', 'authority_kind', 'authorization_ref', 'observed_at') }
        'ReservationFact' { @('schema_version', 'fact_type', 'campaign_id', 'reservation_id', 'grant_id', 'slot', 'run_id', 'observed_at') }
        'SpendFact' { @('schema_version', 'fact_type', 'campaign_id', 'reservation_id', 'run_id', 'invocation_started_at') }
        'ReleaseFact' { @('schema_version', 'fact_type', 'campaign_id', 'reservation_id', 'run_id', 'reason', 'observed_at') }
        'ClaimFact' { @('schema_version', 'fact_type', 'campaign_id', 'run_id', 'target_lineage', 'generation', 'disposition', 'observed_at') }
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
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'summary' -Errors $errors -MaxLength 4000
        }
        'ReviewResult' {
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'completion' -Errors $errors -MaxLength 16 -Enum @('complete', 'partial', 'none')
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'verdict' -Errors $errors -MaxLength 16 -Enum @('pass', 'findings', 'incomplete', 'failed')
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'runtime_outcome' -Errors $errors -MaxLength 32 -Enum @('completed', 'preflight-failed', 'launch-failed', 'timed-out', 'terminated', 'invalid-output', 'identity-mismatch', 'containment-violated', 'abandoned')
            Test-ReviewAuthorityBooleanField -Object $InputObject -Name 'termination_verified' -Errors $errors
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'containment' -Errors $errors -MaxLength 16 -Enum @('verified', 'violated', 'unknown')
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'currentness' -Errors $errors -MaxLength 32 -Enum @('current', 'snapshot-moved', 'unknown')
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'validation' -Errors $errors -MaxLength 16 -Enum @('valid', 'invalid', 'not-produced')
            Test-ReviewAuthorityBooleanField -Object $InputObject -Name 'can_approve_current' -Errors $errors
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'failure_reason' -Errors $errors -MaxLength 2000 -Optional
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'summary' -Errors $errors -MaxLength 4000
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'started_at' -Errors $errors -MaxLength 64
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'ended_at' -Errors $errors -MaxLength 64
            Test-ReviewAuthorityIntegerField -Object $InputObject -Name 'duration_ms' -Errors $errors -Minimum 0 -Maximum 86400000
        }
        'GrantFact' {
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'fact_type' -Errors $errors -MaxLength 16 -Enum @('grant')
            Test-ReviewAuthorityIdField -Object $InputObject -Name 'grant_id' -Kind grant -Errors $errors
            Test-ReviewAuthorityIntegerField -Object $InputObject -Name 'slots' -Errors $errors -Minimum 1 -Maximum 100
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'authority_kind' -Errors $errors -MaxLength 16 -Enum @('human')
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'authorization_ref' -Errors $errors -MaxLength 256
            Test-ReviewAuthorityStringField -Object $InputObject -Name 'observed_at' -Errors $errors -MaxLength 64
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
                if ($array.Count -gt 100) { Add-ReviewAuthorityError -Errors $errors -Message 'too-many:findings:100' }
                for ($i = 0; $i -lt [Math]::Min($array.Count, 100); $i++) {
                    Test-ReviewAuthorityFinding -Finding $array[$i] -Kind $(if ($ContractName -ceq 'ReviewerCandidate') { 'candidate' } else { 'terminal' }) -Errors $errors -Index $i
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

    foreach ($join in @(
        @{ field = 'campaign_id'; expected = $ExpectedCampaignId },
        @{ field = 'run_id'; expected = $ExpectedRunId },
        @{ field = 'target_digest'; expected = $ExpectedTargetDigest }
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

function Test-ReviewAuthorityContractJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet(
            'ReviewCampaign', 'ReviewRun', 'ReviewInvocation', 'ReviewerCandidate', 'ReviewResult',
            'GrantFact', 'ReservationFact', 'SpendFact', 'ReleaseFact', 'ClaimFact'
        )][string]$ContractName,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Json,
        [int]$MaxBytes = 262144,
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
        [object[]]$Grants = @(), [object[]]$Reservations = @(), [object[]]$Spends = @(), [object[]]$Releases = @()
    )
    if (-not (Test-ReviewAuthorityIdentifier -Value $RunId -Kind run) -or -not (Test-ReviewAuthorityIdentifier -Value $ReservationId -Kind reservation)) {
        return [pscustomobject]@{ permitted = $false; reason = 'invalid-reservation-identity'; fact = $null }
    }
    if (@($Reservations | Where-Object { [string](Get-ReviewAuthorityProperty -Object $_ -Name 'run_id') -ceq $RunId }).Count -gt 0) {
        return [pscustomobject]@{ permitted = $false; reason = 'run-already-reserved'; fact = $null }
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
    foreach ($name in @('target', 'store', 'contract', 'containment', 'harness')) {
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
        reason = $Reason; observed_at = $ObservedAt
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
    $matches = @($Runs | Where-Object {
        [string](Get-ReviewAuthorityProperty -Object $_ -Name 'target_digest') -ceq $TargetDigest -and
        [string](Get-ReviewAuthorityProperty -Object $_ -Name 'harness_id') -ceq $HarnessId -and
        [string](Get-ReviewAuthorityProperty -Object $_ -Name 'contract_version') -ceq $ContractVersion
    })
    return [pscustomobject]@{ duplicate = ($matches.Count -gt 0); prior_run_ids = @($matches | ForEach-Object { [string](Get-ReviewAuthorityProperty -Object $_ -Name 'run_id') }) }
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
        [Parameter(Mandatory)][ValidateSet('completed', 'preflight-failed', 'launch-failed', 'timed-out', 'terminated', 'invalid-output', 'identity-mismatch', 'containment-violated', 'abandoned')][string]$RuntimeOutcome,
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
