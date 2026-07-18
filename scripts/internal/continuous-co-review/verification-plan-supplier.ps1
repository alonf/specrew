# FR-049 / T062 — deterministic, framework-neutral verification-plan selection.
#
# The selector is intentionally PURE: callers resolve filesystem/config/profile/provider facts into the
# bounded identities accepted here. It never scans file extensions, guesses a framework, executes a command,
# or mutates `.specrew/verification-plan.json`. T063 owns capture/materialization; T018 owns execution.

if (-not (Get-Command -Name 'Test-ContinuousCoReviewVerificationPlan' -ErrorAction SilentlyContinue)) {
    $contractPath = Join-Path $PSScriptRoot 'verification-plan-contract.ps1'
    if (Test-Path -LiteralPath $contractPath -PathType Leaf) { . $contractPath }
}

function Get-ContinuousCoReviewSupplierProp {
    param([AllowNull()]$Object, [Parameter(Mandatory)][string]$Name)
    if ($null -eq $Object) { return $null }
    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) { return , $Object[$Name] }
        return $null
    }
    $prop = $Object.PSObject.Properties[$Name]
    if ($null -eq $prop) { return $null }
    return , $prop.Value
}

function ConvertTo-ContinuousCoReviewSupplierCanonicalValue {
    param([AllowNull()]$Value)
    if ($null -eq $Value) { return $null }
    if ($Value -is [string] -or $Value -is [char] -or $Value -is [bool] -or $Value.GetType().IsPrimitive -or $Value -is [decimal] -or $Value -is [System.Numerics.BigInteger]) {
        return $Value
    }
    if ($Value -is [System.Collections.IDictionary]) {
        $ordered = [ordered]@{}
        foreach ($key in @($Value.Keys | ForEach-Object { [string]$_ } | Sort-Object -CaseSensitive)) {
            $ordered[$key] = ConvertTo-ContinuousCoReviewSupplierCanonicalValue -Value $Value[$key]
        }
        return $ordered
    }
    if ($Value -is [System.Collections.IEnumerable]) {
        $items = [System.Collections.Generic.List[object]]::new()
        foreach ($item in $Value) { $items.Add((ConvertTo-ContinuousCoReviewSupplierCanonicalValue -Value $item)) }
        return , $items.ToArray()
    }
    $object = [ordered]@{}
    foreach ($name in @($Value.PSObject.Properties.Name | Sort-Object -CaseSensitive)) {
        $object[$name] = ConvertTo-ContinuousCoReviewSupplierCanonicalValue -Value $Value.PSObject.Properties[$name].Value
    }
    return $object
}

function ConvertTo-ContinuousCoReviewSupplierCanonicalJson {
    param([AllowNull()]$Value)
    $normalized = ConvertTo-ContinuousCoReviewSupplierCanonicalValue -Value $Value
    return (ConvertTo-Json -InputObject $normalized -Depth 30 -Compress)
}

function Get-ContinuousCoReviewSupplierSha256 {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $hash = [System.Security.Cryptography.SHA256]::HashData($bytes)
    return [Convert]::ToHexString($hash).ToLowerInvariant()
}

function Test-ContinuousCoReviewSupplierIdentity {
    param([AllowNull()]$Value)
    return (($Value -is [string]) -and ([string]$Value -cmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$'))
}

function Get-ContinuousCoReviewSupplierRows {
    param([AllowNull()]$Catalog, [Parameter(Mandatory)][string]$Name)
    $present = if ($Catalog -is [System.Collections.IDictionary]) { $Catalog.Contains($Name) } else { $null -ne $Catalog.PSObject.Properties[$Name] }
    if (-not $present) { return [pscustomobject]@{ valid = $true; rows = @() } }
    $raw = $null
    if ($Catalog -is [System.Collections.IDictionary]) { $raw = $Catalog[$Name] }
    else { $raw = $Catalog.PSObject.Properties[$Name].Value }
    if ($raw -is [string] -or -not ($raw -is [System.Collections.IEnumerable])) {
        return [pscustomobject]@{ valid = $false; rows = @() }
    }
    return [pscustomobject]@{ valid = $true; rows = @($raw) }
}

function Test-ContinuousCoReviewVerificationPlanCatalog {
    param([Parameter(Mandatory)][AllowNull()]$Catalog)
    if ($null -eq $Catalog) { return [pscustomobject]@{ valid = $false; reason = 'supplier catalog is required' } }
    $unknownCatalog = @(Get-ContinuousCoReviewUnknownProperties -Object $Catalog -Allowed @('schema_version', 'catalog_id', 'project_metadata', 'quality_profiles', 'providers'))
    if ($unknownCatalog.Count -gt 0) {
        return [pscustomobject]@{ valid = $false; reason = 'supplier catalog contains unsupported fields (the catalog contract is closed)' }
    }
    if ([string](Get-ContinuousCoReviewSupplierProp $Catalog 'schema_version') -cne '1.0') {
        return [pscustomobject]@{ valid = $false; reason = 'supplier catalog schema_version must be 1.0' }
    }
    $catalogId = Get-ContinuousCoReviewSupplierProp $Catalog 'catalog_id'
    if (-not (Test-ContinuousCoReviewSupplierIdentity $catalogId)) {
        return [pscustomobject]@{ valid = $false; reason = 'supplier catalog_id is missing or unsafe' }
    }

    $sections = @(
        @{ name = 'project_metadata'; identity = 'detector_id' },
        @{ name = 'quality_profiles'; identity = 'profile_id' },
        @{ name = 'providers'; identity = 'provider_id' }
    )
    $entryIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($section in $sections) {
        $sectionResult = Get-ContinuousCoReviewSupplierRows -Catalog $Catalog -Name $section.name
        if (-not $sectionResult.valid) { return [pscustomobject]@{ valid = $false; reason = "supplier catalog '$($section.name)' must be an array" } }
        $rows = @($sectionResult.rows)
        $identities = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($row in $rows) {
            $unknownRow = @(Get-ContinuousCoReviewUnknownProperties -Object $row -Allowed @('entry_id', $section.identity, 'plan'))
            if ($unknownRow.Count -gt 0) {
                return [pscustomobject]@{ valid = $false; reason = "supplier catalog '$($section.name)' contains unsupported row fields" }
            }
            $entryId = Get-ContinuousCoReviewSupplierProp $row 'entry_id'
            $identity = Get-ContinuousCoReviewSupplierProp $row $section.identity
            if (-not (Test-ContinuousCoReviewSupplierIdentity $entryId) -or -not (Test-ContinuousCoReviewSupplierIdentity $identity)) {
                return [pscustomobject]@{ valid = $false; reason = "supplier catalog '$($section.name)' contains a missing or unsafe identity" }
            }
            if (-not $entryIds.Add(([string]$entryId).ToLowerInvariant())) {
                return [pscustomobject]@{ valid = $false; reason = 'supplier catalog entry_id values must be unique' }
            }
            if (-not $identities.Add(([string]$identity).ToLowerInvariant())) {
                return [pscustomobject]@{ valid = $false; reason = "supplier catalog '$($section.name)' identities must be unique" }
            }
            if ($null -eq (Get-ContinuousCoReviewSupplierProp $row 'plan')) {
                return [pscustomobject]@{ valid = $false; reason = "supplier catalog entry '$entryId' has no plan" }
            }
        }
    }
    return [pscustomobject]@{ valid = $true; reason = $null }
}

function Copy-ContinuousCoReviewSupplierPlan {
    param(
        [Parameter(Mandatory)]$Plan,
        [Parameter(Mandatory)][ValidateSet('project-config', 'project-detected', 'profile-selected', 'provider-gated')][string]$Kind,
        [Parameter(Mandatory)][string]$Source,
        [string]$Profile,
        [string]$Provider
    )
    # JSON round-trip makes a detached copy so this pure selector never mutates caller/catalog inputs.
    $copy = (ConvertTo-ContinuousCoReviewSupplierCanonicalJson $Plan) | ConvertFrom-Json
    foreach ($command in @($copy.commands)) {
        $provenance = [ordered]@{ kind = $Kind; source = $Source }
        if ($Kind -eq 'profile-selected') { $provenance.profile = $Profile }
        if ($Kind -eq 'provider-gated') { $provenance.provider = $Provider }
        $command | Add-Member -NotePropertyName provenance -NotePropertyValue ([pscustomobject]$provenance) -Force
    }
    return $copy
}

function New-ContinuousCoReviewSupplierSelection {
    param(
        [Parameter(Mandatory)][ValidateSet('selected', 'verification-not-configured', 'invalid')][string]$State,
        [AllowNull()][string]$SourceKind,
        [AllowNull()]$SourceIdentity,
        [AllowNull()]$Plan,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$SkippedSources,
        [AllowNull()][string]$FailureReason,
        [AllowNull()][string]$Action
    )
    $normalizedSourceKind = if ([string]::IsNullOrWhiteSpace($SourceKind)) { $null } else { $SourceKind }
    $normalizedFailureReason = if ([string]::IsNullOrWhiteSpace($FailureReason)) { $null } else { $FailureReason }
    $normalizedAction = if ([string]::IsNullOrWhiteSpace($Action)) { $null } else { $Action }
    $planJson = if ($null -eq $Plan) { $null } else { ConvertTo-ContinuousCoReviewSupplierCanonicalJson $Plan }
    $planDigest = if ($null -eq $planJson) { $null } else { Get-ContinuousCoReviewSupplierSha256 $planJson }
    $basis = [ordered]@{
        state = $State
        source_kind = $normalizedSourceKind
        source_identity = $SourceIdentity
        plan_digest = $planDigest
        skipped_sources = @($SkippedSources)
        failure_reason = $normalizedFailureReason
    }
    $selectionId = 'selection-' + (Get-ContinuousCoReviewSupplierSha256 (ConvertTo-ContinuousCoReviewSupplierCanonicalJson $basis))
    return [pscustomobject][ordered]@{
        schema_version = '1.0'
        selection_id = $selectionId
        state = $State
        source_kind = $normalizedSourceKind
        source_identity = $SourceIdentity
        plan_id = if ($null -eq $Plan) { $null } else { [string]$Plan.plan_id }
        plan_digest = $planDigest
        skipped_sources = @($SkippedSources)
        failure_reason = $normalizedFailureReason
        action = $normalizedAction
        generated_content_hash = $planDigest
        plan = $Plan
    }
}

function Select-ContinuousCoReviewVerificationPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][AllowNull()]$Catalog,
        [switch]$ExplicitPlanPresent,
        [AllowNull()]$ExplicitPlan,
        [string[]]$DetectedMetadataIds = @(),
        [AllowNull()][string]$QualityProfileId,
        [string[]]$ActiveProviders = @()
    )
    $catalogCheck = Test-ContinuousCoReviewVerificationPlanCatalog -Catalog $Catalog
    if (-not $catalogCheck.valid) {
        return New-ContinuousCoReviewSupplierSelection -State invalid -SourceKind $null -SourceIdentity $null -Plan $null -SkippedSources @() -FailureReason 'verification-plan-invalid' -Action 'Repair the versioned verification-plan supplier catalog before retrying.'
    }

    $skipped = [System.Collections.Generic.List[object]]::new()
    if ($ExplicitPlanPresent) {
        $explicitCopy = if ($null -eq $ExplicitPlan) { $null } else { Copy-ContinuousCoReviewSupplierPlan -Plan $ExplicitPlan -Kind 'project-config' -Source '.specrew/verification-plan.json' }
        $check = Test-ContinuousCoReviewVerificationPlan -Plan $explicitCopy -RepoRoot $RepoRoot
        if (-not $check.valid) {
            return New-ContinuousCoReviewSupplierSelection -State invalid -SourceKind 'project-config' -SourceIdentity ([pscustomobject][ordered]@{ path = '.specrew/verification-plan.json' }) -Plan $null -SkippedSources @() -FailureReason 'verification-plan-invalid' -Action 'Repair or remove the explicit .specrew/verification-plan.json; lower-precedence sources are not consulted while it is present.'
        }
        return New-ContinuousCoReviewSupplierSelection -State selected -SourceKind 'project-config' -SourceIdentity ([pscustomobject][ordered]@{ path = '.specrew/verification-plan.json' }) -Plan $explicitCopy -SkippedSources @() -FailureReason $null -Action $null
    }
    $skipped.Add([pscustomobject][ordered]@{ source_kind = 'project-config'; reason = 'absent' })

    $detected = @($DetectedMetadataIds | Where-Object { Test-ContinuousCoReviewSupplierIdentity $_ } | ForEach-Object { $_.ToLowerInvariant() } | Sort-Object -Unique)
    $metadataRows = @((Get-ContinuousCoReviewSupplierRows $Catalog 'project_metadata').rows)
    $metadataRow = $metadataRows | Where-Object { ([string]$_.detector_id).ToLowerInvariant() -in $detected } | Select-Object -First 1
    if ($null -ne $metadataRow) {
        $source = [string]$metadataRow.detector_id
        $plan = Copy-ContinuousCoReviewSupplierPlan -Plan $metadataRow.plan -Kind 'project-detected' -Source $source
        $check = Test-ContinuousCoReviewVerificationPlan -Plan $plan -RepoRoot $RepoRoot
        if (-not $check.valid) {
            return New-ContinuousCoReviewSupplierSelection -State invalid -SourceKind 'project-detected' -SourceIdentity ([pscustomobject][ordered]@{ detector_id = $source; entry_id = [string]$metadataRow.entry_id }) -Plan $null -SkippedSources $skipped.ToArray() -FailureReason 'verification-plan-invalid' -Action 'Repair the selected project-metadata catalog entry before retrying.'
        }
        return New-ContinuousCoReviewSupplierSelection -State selected -SourceKind 'project-detected' -SourceIdentity ([pscustomobject][ordered]@{ detector_id = $source; entry_id = [string]$metadataRow.entry_id }) -Plan $plan -SkippedSources $skipped.ToArray() -FailureReason $null -Action $null
    }
    $skipped.Add([pscustomobject][ordered]@{ source_kind = 'project-detected'; reason = 'no eligible named detector' })

    $profile = if (Test-ContinuousCoReviewSupplierIdentity $QualityProfileId) { $QualityProfileId.ToLowerInvariant() } else { $null }
    $profileRows = @((Get-ContinuousCoReviewSupplierRows $Catalog 'quality_profiles').rows)
    $profileRow = if ($null -eq $profile) { $null } else { $profileRows | Where-Object { ([string]$_.profile_id).ToLowerInvariant() -ceq $profile } | Select-Object -First 1 }
    if ($null -ne $profileRow) {
        $source = [string]$profileRow.profile_id
        $plan = Copy-ContinuousCoReviewSupplierPlan -Plan $profileRow.plan -Kind 'profile-selected' -Source $source -Profile $source
        $check = Test-ContinuousCoReviewVerificationPlan -Plan $plan -RepoRoot $RepoRoot
        if (-not $check.valid) {
            return New-ContinuousCoReviewSupplierSelection -State invalid -SourceKind 'profile-selected' -SourceIdentity ([pscustomobject][ordered]@{ profile_id = $source; entry_id = [string]$profileRow.entry_id }) -Plan $null -SkippedSources $skipped.ToArray() -FailureReason 'verification-plan-invalid' -Action 'Repair the selected quality-profile catalog entry before retrying.'
        }
        return New-ContinuousCoReviewSupplierSelection -State selected -SourceKind 'profile-selected' -SourceIdentity ([pscustomobject][ordered]@{ profile_id = $source; entry_id = [string]$profileRow.entry_id }) -Plan $plan -SkippedSources $skipped.ToArray() -FailureReason $null -Action $null
    }
    $skipped.Add([pscustomobject][ordered]@{ source_kind = 'profile-selected'; reason = 'no eligible explicit profile' })

    $providers = @($ActiveProviders | Where-Object { Test-ContinuousCoReviewSupplierIdentity $_ } | ForEach-Object { $_.ToLowerInvariant() } | Sort-Object -Unique)
    $providerRows = @((Get-ContinuousCoReviewSupplierRows $Catalog 'providers').rows)
    $providerRow = $providerRows | Where-Object { ([string]$_.provider_id).ToLowerInvariant() -in $providers } | Select-Object -First 1
    if ($null -ne $providerRow) {
        $source = [string]$providerRow.provider_id
        $plan = Copy-ContinuousCoReviewSupplierPlan -Plan $providerRow.plan -Kind 'provider-gated' -Source $source -Provider $source
        $check = Test-ContinuousCoReviewVerificationPlan -Plan $plan -RepoRoot $RepoRoot
        if (-not $check.valid) {
            return New-ContinuousCoReviewSupplierSelection -State invalid -SourceKind 'provider-gated' -SourceIdentity ([pscustomobject][ordered]@{ provider_id = $source; entry_id = [string]$providerRow.entry_id }) -Plan $null -SkippedSources $skipped.ToArray() -FailureReason 'verification-plan-invalid' -Action 'Repair the selected provider-gated catalog entry before retrying.'
        }
        return New-ContinuousCoReviewSupplierSelection -State selected -SourceKind 'provider-gated' -SourceIdentity ([pscustomobject][ordered]@{ provider_id = $source; entry_id = [string]$providerRow.entry_id }) -Plan $plan -SkippedSources $skipped.ToArray() -FailureReason $null -Action $null
    }
    $skipped.Add([pscustomobject][ordered]@{ source_kind = 'provider-gated'; reason = 'no eligible active provider row' })

    return New-ContinuousCoReviewSupplierSelection -State 'verification-not-configured' -SourceKind $null -SourceIdentity $null -Plan $null -SkippedSources $skipped.ToArray() -FailureReason 'verification-not-configured' -Action 'Create .specrew/verification-plan.json, configure a supported named metadata source, explicitly select a supported quality profile, or activate a provider with a reviewed catalog row.'
}
