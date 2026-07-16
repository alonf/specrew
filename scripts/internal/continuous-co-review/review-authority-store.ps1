$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# F-198 / T045: dependency-free immutable JSON repositories. There is no generic lock, mutable
# revision/CAS layer, database, event store, process-owner handoff, or delete-on-completion path.
# Every authority fact has one deterministic unique path and is published with FileMode.CreateNew.

if (-not (Get-Command -Name 'Test-ReviewAuthorityContractObject' -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'review-authority-core.ps1')
}

function ConvertTo-ReviewAuthorityCanonicalValue {
    param([AllowNull()]$Value)
    if ($null -eq $Value) { return $null }
    if ($Value -is [System.Collections.IDictionary]) {
        $ordered = [ordered]@{}
        foreach ($key in @($Value.Keys | Sort-Object { [string]$_ })) { $ordered[[string]$key] = ConvertTo-ReviewAuthorityCanonicalValue -Value $Value[$key] }
        return [pscustomobject]$ordered
    }
    if ($Value -is [pscustomobject]) {
        $ordered = [ordered]@{}
        foreach ($property in @($Value.PSObject.Properties | Sort-Object Name)) { $ordered[$property.Name] = ConvertTo-ReviewAuthorityCanonicalValue -Value $property.Value }
        return [pscustomobject]$ordered
    }
    if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) {
        $items = @($Value | ForEach-Object { ConvertTo-ReviewAuthorityCanonicalValue -Value $_ })
        Write-Output -NoEnumerate $items
        return
    }
    return $Value
}

function ConvertTo-ReviewAuthorityCanonicalJson {
    param([Parameter(Mandatory)]$Fact)
    return ((ConvertTo-ReviewAuthorityCanonicalValue -Value $Fact) | ConvertTo-Json -Depth 30 -Compress)
}

function Assert-ReviewAuthoritySafeRelativePath {
    param([Parameter(Mandatory)][string]$RelativePath)
    $normalized = $RelativePath.Replace('\', '/')
    if ([string]::IsNullOrWhiteSpace($normalized) -or [System.IO.Path]::IsPathRooted($RelativePath) -or
        @($normalized.Split('/') | Where-Object { $_ -ceq '..' }).Count -gt 0) {
        throw "review-store-invalid-relative-path:$RelativePath"
    }
}

function Get-ReviewAuthorityStorePath {
    param(
        [Parameter(Mandatory)][string]$StoreRoot,
        [Parameter(Mandatory)][string]$RelativePath
    )
    Assert-ReviewAuthoritySafeRelativePath -RelativePath $RelativePath
    $root = [System.IO.Path]::GetFullPath($StoreRoot).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $full = [System.IO.Path]::GetFullPath((Join-Path $root $RelativePath))
    $prefix = $root + [System.IO.Path]::DirectorySeparatorChar
    $comparison = if ([System.OperatingSystem]::IsWindows()) { [System.StringComparison]::OrdinalIgnoreCase } else { [System.StringComparison]::Ordinal }
    if (-not $full.StartsWith($prefix, $comparison)) { throw "review-store-path-escape:$RelativePath" }
    return $full
}

function Write-ReviewAuthorityImmutableFact {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StoreRoot,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)]$Fact,
        [Parameter(Mandatory)][ValidateSet(
            'ReviewCampaign', 'ReviewRun', 'ReviewInvocation', 'ReviewerCandidate', 'ReviewResult',
            'GrantFact', 'ReservationFact', 'SpendFact', 'ReleaseFact', 'ClaimFact'
        )][string]$ContractName,
        [string]$ExpectedCampaignId,
        [string]$ExpectedRunId,
        [string]$ExpectedTargetDigest
    )
    $validation = Test-ReviewAuthorityContractObject -ContractName $ContractName -InputObject $Fact -ExpectedCampaignId $ExpectedCampaignId -ExpectedRunId $ExpectedRunId -ExpectedTargetDigest $ExpectedTargetDigest
    if (-not $validation.valid) { throw ('review-store-contract-invalid:{0}:{1}' -f $validation.category, ($validation.errors -join ',')) }
    $path = Get-ReviewAuthorityStorePath -StoreRoot $StoreRoot -RelativePath $RelativePath
    $directory = Split-Path -Parent $path
    [System.IO.Directory]::CreateDirectory($directory) | Out-Null
    $json = ConvertTo-ReviewAuthorityCanonicalJson -Fact $Fact
    $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($json)
    try {
        $stream = [System.IO.FileStream]::new($path, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        try { $stream.Write($bytes, 0, $bytes.Length); $stream.Flush($true) }
        finally { $stream.Dispose() }
        return [pscustomobject]@{ created = $true; idempotent = $false; path = $path }
    }
    catch [System.IO.IOException] {
        if (-not [System.IO.File]::Exists($path)) { throw }
        # Validate that the completed CreateNew winner is readable, then compare the canonical bytes
        # that were actually persisted. ConvertFrom-Json coerces ISO-8601 strings to DateTime on newer
        # PowerShell versions; reserializing that object can change offset/precision and falsely turn an
        # identical replay into corruption.
        $null = Read-ReviewAuthorityFactFile -Path $path
        $existing = [System.IO.File]::ReadAllText($path, [System.Text.UTF8Encoding]::new($false))
        if ($existing -ceq $json) { return [pscustomobject]@{ created = $false; idempotent = $true; path = $path } }
        throw "review-store-corruption:conflicting-immutable-fact:$RelativePath"
    }
}

function Read-ReviewAuthorityFactFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [ValidateSet(
            'ReviewCampaign', 'ReviewRun', 'ReviewInvocation', 'ReviewerCandidate', 'ReviewResult',
            'GrantFact', 'ReservationFact', 'SpendFact', 'ReleaseFact', 'ClaimFact'
        )][string]$ContractName,
        [int]$MaxBytes = 1048576
    )
    $stream = $null
    for ($attempt = 0; $attempt -lt 20; $attempt++) {
        try { $stream = [System.IO.FileStream]::new($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read); break }
        catch [System.IO.IOException] { if ($attempt -eq 19) { throw "review-store-fact-unavailable:$Path" }; Start-Sleep -Milliseconds 10 }
    }
    try {
        if ($stream.Length -le 0 -or $stream.Length -gt $MaxBytes) { throw "review-store-corruption:invalid-fact-size:$Path" }
        $reader = [System.IO.StreamReader]::new($stream, [System.Text.UTF8Encoding]::new($false), $true, 4096, $true)
        try { $json = $reader.ReadToEnd() } finally { $reader.Dispose() }
    }
    finally { if ($null -ne $stream) { $stream.Dispose() } }
    try { $fact = $json | ConvertFrom-Json -Depth 30 -ErrorAction Stop }
    catch { throw "review-store-corruption:invalid-json:$Path" }
    if (-not [string]::IsNullOrWhiteSpace($ContractName)) {
        $validation = Test-ReviewAuthorityContractObject -ContractName $ContractName -InputObject $fact
        if (-not $validation.valid) { throw ('review-store-corruption:invalid-contract:{0}:{1}' -f $ContractName, ($validation.errors -join ',')) }
    }
    return $fact
}

function Get-ReviewAuthorityCampaignRelativeRoot {
    param([Parameter(Mandatory)][string]$CampaignId)
    if (-not (Test-ReviewAuthorityIdentifier -Value $CampaignId -Kind campaign)) { throw "review-store-invalid-campaign-id:$CampaignId" }
    return "campaigns/$CampaignId"
}

function Get-ReviewAuthorityCampaignFacts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StoreRoot,
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][ValidateSet('grants', 'reservations', 'spend', 'releases')][string]$Kind
    )
    $contract = switch ($Kind) { 'grants' { 'GrantFact' }; 'reservations' { 'ReservationFact' }; 'spend' { 'SpendFact' }; 'releases' { 'ReleaseFact' } }
    $relative = (Get-ReviewAuthorityCampaignRelativeRoot -CampaignId $CampaignId) + "/$Kind"
    $path = Get-ReviewAuthorityStorePath -StoreRoot $StoreRoot -RelativePath $relative
    if (-not [System.IO.Directory]::Exists($path)) { return @() }
    $facts = [System.Collections.Generic.List[object]]::new()
    foreach ($file in [System.IO.Directory]::EnumerateFiles($path, '*.json', [System.IO.SearchOption]::AllDirectories) | Sort-Object) {
        $facts.Add((Read-ReviewAuthorityFactFile -Path $file -ContractName $contract)) | Out-Null
    }
    return @($facts)
}

function Add-ReviewCampaignGrantFact {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$StoreRoot, [Parameter(Mandatory)]$Fact)
    $campaignId = [string](Get-ReviewAuthorityProperty -Object $Fact -Name 'campaign_id')
    $grantId = [string](Get-ReviewAuthorityProperty -Object $Fact -Name 'grant_id')
    $relative = (Get-ReviewAuthorityCampaignRelativeRoot -CampaignId $campaignId) + "/grants/$grantId.json"
    return Write-ReviewAuthorityImmutableFact -StoreRoot $StoreRoot -RelativePath $relative -Fact $Fact -ContractName GrantFact -ExpectedCampaignId $campaignId
}

function Request-ReviewCampaignReservationFact {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StoreRoot,
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$ReservationId,
        [Parameter(Mandatory)][string]$ObservedAt
    )
    for ($attempt = 0; $attempt -lt 101; $attempt++) {
        $grants = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $StoreRoot -CampaignId $CampaignId -Kind grants)
        $reservations = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $StoreRoot -CampaignId $CampaignId -Kind reservations)
        $spends = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $StoreRoot -CampaignId $CampaignId -Kind spend)
        $releases = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $StoreRoot -CampaignId $CampaignId -Kind releases)
        $decision = Resolve-ReviewCampaignReservationDecision -CampaignId $CampaignId -RunId $RunId -ReservationId $ReservationId -ObservedAt $ObservedAt -Grants $grants -Reservations $reservations -Spends $spends -Releases $releases
        if (-not $decision.permitted) { return [pscustomobject]@{ acquired = $false; reason = $decision.reason; fact = $null } }
        $fact = $decision.fact
        # A pre-invocation release restores an allowance slot. Each reuse appends an immutable
        # generation; concurrent contenders derive the same next generation and CreateNew selects
        # exactly one winner before all losers reread the authority facts.
        $slotReservations = @($reservations | Where-Object {
            [string](Get-ReviewAuthorityProperty -Object $_ -Name 'grant_id') -ceq [string]$fact.grant_id -and
            [int](Get-ReviewAuthorityProperty -Object $_ -Name 'slot') -eq [int]$fact.slot
        })
        $generation = $slotReservations.Count + 1
        $relative = (Get-ReviewAuthorityCampaignRelativeRoot -CampaignId $CampaignId) + ('/reservations/{0}/slot-{1:d3}/generation-{2:d3}.json' -f $fact.grant_id, [int]$fact.slot, $generation)
        try {
            $write = Write-ReviewAuthorityImmutableFact -StoreRoot $StoreRoot -RelativePath $relative -Fact $fact -ContractName ReservationFact -ExpectedCampaignId $CampaignId -ExpectedRunId $RunId
            if ($write.created) { return [pscustomobject]@{ acquired = $true; reason = 'reservation-created'; fact = $fact; path = $write.path } }
            return [pscustomobject]@{ acquired = $false; reason = 'reservation-already-owned-by-run'; fact = $fact; path = $write.path }
        }
        catch {
            if ($_.Exception.Message -notlike 'review-store-corruption:conflicting-immutable-fact:*') { throw }
            # Expected slot-contention race: reread all immutable facts and choose the next visible free slot.
            continue
        }
    }
    throw 'review-store-corruption:reservation-contention-did-not-converge'
}

function Write-ReviewCampaignSpendFact {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$StoreRoot, [Parameter(Mandatory)]$Fact)
    $campaignId = [string](Get-ReviewAuthorityProperty -Object $Fact -Name 'campaign_id')
    $reservationId = [string](Get-ReviewAuthorityProperty -Object $Fact -Name 'reservation_id')
    $relative = (Get-ReviewAuthorityCampaignRelativeRoot -CampaignId $campaignId) + "/spend/$reservationId.json"
    return Write-ReviewAuthorityImmutableFact -StoreRoot $StoreRoot -RelativePath $relative -Fact $Fact -ContractName SpendFact -ExpectedCampaignId $campaignId
}

function Write-ReviewCampaignReleaseFact {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$StoreRoot, [Parameter(Mandatory)]$Fact)
    $campaignId = [string](Get-ReviewAuthorityProperty -Object $Fact -Name 'campaign_id')
    $reservationId = [string](Get-ReviewAuthorityProperty -Object $Fact -Name 'reservation_id')
    $relative = (Get-ReviewAuthorityCampaignRelativeRoot -CampaignId $campaignId) + "/releases/$reservationId.json"
    return Write-ReviewAuthorityImmutableFact -StoreRoot $StoreRoot -RelativePath $relative -Fact $Fact -ContractName ReleaseFact -ExpectedCampaignId $campaignId
}

function Write-ReviewRunAuthorityFact {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StoreRoot,
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][ValidateSet('requested', 'reserved', 'preflighted', 'claimed', 'invoked', 'validating')][string]$Stage,
        [Parameter(Mandatory)]$Fact
    )
    if ([string](Get-ReviewAuthorityProperty -Object $Fact -Name 'state') -cne $Stage) { throw "review-store-contract-invalid:run-stage-mismatch:$Stage" }
    $relative = (Get-ReviewAuthorityCampaignRelativeRoot -CampaignId $CampaignId) + "/runs/$RunId/$Stage.json"
    return Write-ReviewAuthorityImmutableFact -StoreRoot $StoreRoot -RelativePath $relative -Fact $Fact -ContractName ReviewRun -ExpectedCampaignId $CampaignId -ExpectedRunId $RunId
}

function Publish-ReviewRunResultFact {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StoreRoot,
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)]$Fact
    )
    $relative = (Get-ReviewAuthorityCampaignRelativeRoot -CampaignId $CampaignId) + "/runs/$RunId/result.json"
    return Write-ReviewAuthorityImmutableFact -StoreRoot $StoreRoot -RelativePath $relative -Fact $Fact -ContractName ReviewResult -ExpectedCampaignId $CampaignId -ExpectedRunId $RunId
}

function Get-ReviewRunAuthorityFact {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StoreRoot,
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][ValidateSet('requested', 'reserved', 'preflighted', 'claimed', 'invoked', 'validating', 'result')][string]$Stage
    )
    $relative = (Get-ReviewAuthorityCampaignRelativeRoot -CampaignId $CampaignId) + "/runs/$RunId/$Stage.json"
    $path = Get-ReviewAuthorityStorePath -StoreRoot $StoreRoot -RelativePath $relative
    if (-not [System.IO.File]::Exists($path)) { return $null }
    return Read-ReviewAuthorityFactFile -Path $path -ContractName $(if ($Stage -ceq 'result') { 'ReviewResult' } else { 'ReviewRun' })
}

function Get-ReviewAuthorityClaimFacts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StoreRoot,
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$TargetLineage
    )
    if (-not (Test-ReviewAuthorityIdentifier -Value $TargetLineage -Kind lineage)) { throw "review-store-invalid-lineage-id:$TargetLineage" }
    $relative = (Get-ReviewAuthorityCampaignRelativeRoot -CampaignId $CampaignId) + "/claims/$TargetLineage"
    $path = Get-ReviewAuthorityStorePath -StoreRoot $StoreRoot -RelativePath $relative
    if (-not [System.IO.Directory]::Exists($path)) { return @() }
    $facts = [System.Collections.Generic.List[object]]::new()
    foreach ($file in [System.IO.Directory]::EnumerateFiles($path, '*.json', [System.IO.SearchOption]::TopDirectoryOnly) | Sort-Object) {
        $fact = Read-ReviewAuthorityFactFile -Path $file -ContractName ClaimFact
        $fact | Add-Member -NotePropertyName '_fact_path' -NotePropertyValue $file
        $facts.Add($fact) | Out-Null
    }
    return @($facts)
}

function Get-ReviewAuthorityActiveClaim {
    param([object[]]$Facts = @())
    $byGeneration = @{}
    foreach ($fact in @($Facts)) {
        $generation = [int](Get-ReviewAuthorityProperty -Object $fact -Name 'generation')
        if (-not $byGeneration.ContainsKey($generation)) { $byGeneration[$generation] = [System.Collections.Generic.List[object]]::new() }
        $byGeneration[$generation].Add($fact) | Out-Null
    }
    foreach ($generation in @($byGeneration.Keys | Sort-Object -Descending)) {
        $factsAtGeneration = @($byGeneration[$generation])
        $held = @($factsAtGeneration | Where-Object { [string](Get-ReviewAuthorityProperty -Object $_ -Name 'disposition') -ceq 'held' })
        $retired = @($factsAtGeneration | Where-Object { [string](Get-ReviewAuthorityProperty -Object $_ -Name 'disposition') -in @('released', 'abandoned') })
        if ($held.Count -gt 1 -or $retired.Count -gt 1) { throw "review-store-corruption:conflicting-claim-generation:$generation" }
        if ($held.Count -eq 1 -and $retired.Count -eq 0) { return $held[0] }
    }
    return $null
}

function Request-ReviewAuthorityClaim {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StoreRoot,
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$TargetLineage,
        [Parameter(Mandatory)][string]$ObservedAt
    )
    for ($attempt = 0; $attempt -lt 100; $attempt++) {
        $facts = @(Get-ReviewAuthorityClaimFacts -StoreRoot $StoreRoot -CampaignId $CampaignId -TargetLineage $TargetLineage)
        $active = Get-ReviewAuthorityActiveClaim -Facts $facts
        if ($null -ne $active) { return [pscustomobject]@{ acquired = $false; reason = 'active-claim'; claim = $active } }
        $generation = if ($facts.Count -eq 0) { 1 } else { 1 + [int](($facts | ForEach-Object { [int]$_.generation } | Measure-Object -Maximum).Maximum) }
        $fact = [pscustomobject][ordered]@{
            schema_version = '1.0'; fact_type = 'claim-held'; campaign_id = $CampaignId; run_id = $RunId
            target_lineage = $TargetLineage; generation = $generation; disposition = 'held'; observed_at = $ObservedAt
        }
        $relative = (Get-ReviewAuthorityCampaignRelativeRoot -CampaignId $CampaignId) + ('/claims/{0}/{1:d8}-held.json' -f $TargetLineage, $generation)
        try {
            $write = Write-ReviewAuthorityImmutableFact -StoreRoot $StoreRoot -RelativePath $relative -Fact $fact -ContractName ClaimFact -ExpectedCampaignId $CampaignId -ExpectedRunId $RunId
            if ($write.created) { return [pscustomobject]@{ acquired = $true; reason = 'claim-created'; claim = $fact; path = $write.path } }
            return [pscustomobject]@{ acquired = $false; reason = 'claim-already-held-by-run'; claim = $fact; path = $write.path }
        }
        catch {
            if ($_.Exception.Message -notlike 'review-store-corruption:conflicting-immutable-fact:*') { throw }
            continue
        }
    }
    throw 'review-store-corruption:claim-contention-did-not-converge'
}

function Complete-ReviewAuthorityClaim {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StoreRoot,
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$TargetLineage,
        [Parameter(Mandatory)][ValidateSet('released', 'abandoned')][string]$Disposition,
        [Parameter(Mandatory)][string]$ObservedAt
    )
    $facts = @(Get-ReviewAuthorityClaimFacts -StoreRoot $StoreRoot -CampaignId $CampaignId -TargetLineage $TargetLineage)
    $active = Get-ReviewAuthorityActiveClaim -Facts $facts
    if ($null -eq $active) { return [pscustomobject]@{ completed = $false; reason = 'no-active-claim' } }
    if ([string]$active.run_id -cne $RunId) { return [pscustomobject]@{ completed = $false; reason = 'claim-owned-by-other-run' } }
    $generation = [int]$active.generation
    $factType = if ($Disposition -ceq 'released') { 'claim-released' } else { 'claim-abandoned' }
    $fact = [pscustomobject][ordered]@{
        schema_version = '1.0'; fact_type = $factType; campaign_id = $CampaignId; run_id = $RunId
        target_lineage = $TargetLineage; generation = $generation; disposition = $Disposition; observed_at = $ObservedAt
    }
    $relative = (Get-ReviewAuthorityCampaignRelativeRoot -CampaignId $CampaignId) + ('/claims/{0}/{1:d8}-{2}.json' -f $TargetLineage, $generation, $Disposition)
    $write = Write-ReviewAuthorityImmutableFact -StoreRoot $StoreRoot -RelativePath $relative -Fact $fact -ContractName ClaimFact -ExpectedCampaignId $CampaignId -ExpectedRunId $RunId
    return [pscustomobject]@{ completed = $true; reason = $(if ($write.created) { 'claim-retired' } else { 'claim-retirement-idempotent' }); fact = $fact; path = $write.path }
}

function Get-ReviewRunReconciliationPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StoreRoot,
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$TargetLineage
    )
    $result = Get-ReviewRunAuthorityFact -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -Stage result
    $validating = Get-ReviewRunAuthorityFact -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -Stage validating
    $invoked = Get-ReviewRunAuthorityFact -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -Stage invoked
    $reservations = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $StoreRoot -CampaignId $CampaignId -Kind reservations | Where-Object { [string]$_.run_id -ceq $RunId })
    $spends = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $StoreRoot -CampaignId $CampaignId -Kind spend | Where-Object { [string]$_.run_id -ceq $RunId })
    $releases = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $StoreRoot -CampaignId $CampaignId -Kind releases | Where-Object { [string]$_.run_id -ceq $RunId })
    $claims = @(Get-ReviewAuthorityClaimFacts -StoreRoot $StoreRoot -CampaignId $CampaignId -TargetLineage $TargetLineage)
    $activeClaim = Get-ReviewAuthorityActiveClaim -Facts $claims
    $actions = [System.Collections.Generic.List[string]]::new()

    if ($null -ne $result) {
        if ($null -ne $activeClaim -and [string]$activeClaim.run_id -ceq $RunId) { $actions.Add('retire-claim-released') | Out-Null }
        else { $actions.Add('complete') | Out-Null }
    }
    elseif ($null -ne $validating) { $actions.Add('continue-validation-and-classification') | Out-Null }
    elseif ($spends.Count -gt 0 -or $null -ne $invoked) {
        $actions.Add('publish-spent-abandoned-result') | Out-Null
        if ($null -ne $activeClaim -and [string]$activeClaim.run_id -ceq $RunId) { $actions.Add('retire-claim-abandoned') | Out-Null }
    }
    elseif ($reservations.Count -gt 0 -and $releases.Count -eq 0) {
        $actions.Add('release-non-invoked-reservation') | Out-Null
        if ($null -ne $activeClaim -and [string]$activeClaim.run_id -ceq $RunId) { $actions.Add('retire-claim-abandoned') | Out-Null }
    }
    else { $actions.Add('no-work') | Out-Null }
    return [pscustomobject]@{ run_id = $RunId; actions = @($actions); reservation_count = $reservations.Count; spend_count = $spends.Count; release_count = $releases.Count; active_claim_run_id = $(if ($null -ne $activeClaim) { [string]$activeClaim.run_id } else { $null }) }
}
