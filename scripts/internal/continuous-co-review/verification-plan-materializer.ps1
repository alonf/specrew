# FR-049 / T063 — project source capture plus hash-guarded materialization for the pure T062 selector.

if (-not (Get-Command -Name 'Select-ContinuousCoReviewVerificationPlan' -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'verification-plan-supplier.ps1')
}

function Resolve-ContinuousCoReviewVerificationPlanCatalogPath {
    param([Parameter(Mandatory)][string]$RepoRoot, [AllowNull()][string]$CatalogPath)
    if (-not [string]::IsNullOrWhiteSpace($CatalogPath)) { return $CatalogPath }
    $deployed = Join-Path $RepoRoot '.specify/extensions/specrew-speckit/data/verification-plan-catalog.json'
    if (Test-Path -LiteralPath $deployed -PathType Leaf) { return $deployed }
    $moduleRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../..'))
    return (Join-Path $moduleRoot 'extensions/specrew-speckit/data/verification-plan-catalog.json')
}

function Get-ContinuousCoReviewProjectMetadataIds {
    param([Parameter(Mandatory)][string]$RepoRoot)
    $packagePath = Join-Path $RepoRoot 'package.json'
    if (-not (Test-Path -LiteralPath $packagePath -PathType Leaf)) { return @() }
    try {
        $package = Get-Content -LiteralPath $packagePath -Raw | ConvertFrom-Json
        $scripts = $package.PSObject.Properties['scripts']
        if ($null -eq $scripts -or $null -eq $scripts.Value) { return @() }
        $test = $scripts.Value.PSObject.Properties['test']
        if ($null -eq $test -or -not ($test.Value -is [string]) -or [string]::IsNullOrWhiteSpace([string]$test.Value)) { return @() }
        $declared = ([string]$test.Value).Trim()
        # npm's generated placeholder is not a trustworthy verification command.
        if ($declared -match '(?i)no\s+test\s+specified' -or $declared -match '(?i)^echo\b.*\bexit\s+1\s*$') { return @() }
        return @('package-json.scripts-test.v1')
    }
    catch { return @() }
}

function Get-ContinuousCoReviewActiveProjectProviders {
    param([Parameter(Mandatory)][string]$RepoRoot)
    $path = Join-Path $RepoRoot '.specrew/repository-governance.yml'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return @() }
    $block = ''
    foreach ($rawLine in @(Get-Content -LiteralPath $path)) {
        $line = ($rawLine -replace '\s+#.*$', '').TrimEnd()
        if ($line -match '^(?<name>[A-Za-z0-9_-]+):\s*$') { $block = $Matches.name; continue }
        $value = $null
        if ($line -match '^provider:\s*(?<value>[^\s]+)\s*$') { $value = $Matches.value }
        elseif ($block -eq 'provider' -and $line -match '^\s+name:\s*(?<value>[^\s]+)\s*$') { $value = $Matches.value }
        elseif ($block -eq 'repository_governance' -and $line -match '^\s{2}provider:\s*(?<value>[^\s]+)\s*$') { $value = $Matches.value }
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            $normalized = $value.Trim('"', "'", ' ').ToLowerInvariant()
            if (Test-ContinuousCoReviewSupplierIdentity $normalized) { return @($normalized) }
            return @()
        }
    }
    return @()
}

function Write-ContinuousCoReviewVerificationPlanFile {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][AllowEmptyString()][string]$Content)
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    $temp = Join-Path $parent ('.verification-plan-' + [guid]::NewGuid().ToString('N') + '.tmp')
    try {
        [System.IO.File]::WriteAllText($temp, $Content, [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::Move($temp, $Path, $true)
    }
    finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue } }
}

function New-ContinuousCoReviewVerificationMaterializationResult {
    param(
        [Parameter(Mandatory)][string]$State,
        [Parameter(Mandatory)][string]$Action,
        [Parameter(Mandatory)][bool]$Mutated,
        [AllowNull()][string]$Warning,
        [AllowNull()]$Selection,
        [Parameter(Mandatory)][string]$PlanPath,
        [Parameter(Mandatory)][string]$MarkerPath
    )
    return [pscustomobject][ordered]@{
        schema_version = '1.0'
        state = $State
        action = $Action
        mutated = $Mutated
        warning = if ([string]::IsNullOrWhiteSpace($Warning)) { $null } else { $Warning }
        plan_path = $PlanPath
        marker_path = $MarkerPath
        selection = $Selection
    }
}

function Invoke-ContinuousCoReviewVerificationPlanMaterialization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [AllowNull()][string]$CatalogPath,
        [AllowNull()][string]$QualityProfileId,
        [AllowNull()][string[]]$ActiveProviders,
        [switch]$PreviewOnly
    )
    $root = [System.IO.Path]::GetFullPath($RepoRoot)
    $planPath = Join-Path $root '.specrew/verification-plan.json'
    $markerPath = Join-Path $root '.specrew/verification-plan.generated.json'
    $resolvedCatalog = Resolve-ContinuousCoReviewVerificationPlanCatalogPath -RepoRoot $root -CatalogPath $CatalogPath
    if (-not (Test-Path -LiteralPath $resolvedCatalog -PathType Leaf)) {
        return New-ContinuousCoReviewVerificationMaterializationResult -State invalid -Action 'catalog-missing' -Mutated $false -Warning 'Verification-plan catalog is missing; no project plan was changed.' -Selection $null -PlanPath $planPath -MarkerPath $markerPath
    }
    try { $catalog = Get-Content -LiteralPath $resolvedCatalog -Raw | ConvertFrom-Json }
    catch {
        return New-ContinuousCoReviewVerificationMaterializationResult -State invalid -Action 'catalog-invalid' -Mutated $false -Warning 'Verification-plan catalog is malformed; no project plan was changed.' -Selection $null -PlanPath $planPath -MarkerPath $markerPath
    }

    $planExists = Test-Path -LiteralPath $planPath -PathType Leaf
    $markerExists = Test-Path -LiteralPath $markerPath -PathType Leaf
    $generatedAndUnmodified = $false
    if ($planExists -and $markerExists) {
        try {
            $marker = Get-Content -LiteralPath $markerPath -Raw | ConvertFrom-Json
            $expectedHash = [string](Get-ContinuousCoReviewSupplierProp $marker 'generated_content_hash')
            $currentHash = Get-ContinuousCoReviewSupplierSha256 (Get-Content -LiteralPath $planPath -Raw)
            $generatedAndUnmodified = ([string](Get-ContinuousCoReviewSupplierProp $marker 'schema_version') -ceq '1.0') -and ($expectedHash -cmatch '^[0-9a-f]{64}$') -and ($currentHash -ceq $expectedHash)
        }
        catch { $generatedAndUnmodified = $false }
        if (-not $generatedAndUnmodified) {
            return New-ContinuousCoReviewVerificationMaterializationResult -State 'preserved-modified' -Action 'preserved-modified-generated-plan' -Mutated $false -Warning 'The generated verification plan or its ownership marker changed; preserving both files byte-for-byte. Reconcile them explicitly before refresh.' -Selection $null -PlanPath $planPath -MarkerPath $markerPath
        }
    }
    elseif ($planExists) {
        $explicit = $null
        try { $explicit = Get-Content -LiteralPath $planPath -Raw | ConvertFrom-Json } catch { $explicit = $null }
        $selection = Select-ContinuousCoReviewVerificationPlan -RepoRoot $root -Catalog $catalog -ExplicitPlanPresent -ExplicitPlan $explicit
        $action = if ($selection.state -eq 'selected') { 'preserved-explicit-plan' } else { 'preserved-invalid-explicit-plan' }
        $warning = if ($selection.state -eq 'selected') { $null } else { $selection.action }
        return New-ContinuousCoReviewVerificationMaterializationResult -State $selection.state -Action $action -Mutated $false -Warning $warning -Selection $selection -PlanPath $planPath -MarkerPath $markerPath
    }
    elseif ($markerExists) {
        if (-not $PreviewOnly) { Remove-Item -LiteralPath $markerPath -Force }
        $markerExists = $false
    }

    $metadataIds = @(Get-ContinuousCoReviewProjectMetadataIds -RepoRoot $root)
    $providers = if ($PSBoundParameters.ContainsKey('ActiveProviders')) { @($ActiveProviders) } else { @(Get-ContinuousCoReviewActiveProjectProviders -RepoRoot $root) }
    $selection = Select-ContinuousCoReviewVerificationPlan -RepoRoot $root -Catalog $catalog -DetectedMetadataIds $metadataIds -QualityProfileId $QualityProfileId -ActiveProviders $providers

    if ($selection.state -ne 'selected') {
        $removed = $false
        if ($generatedAndUnmodified) {
            $removed = $true
            if (-not $PreviewOnly) {
                Remove-Item -LiteralPath $planPath -Force
                Remove-Item -LiteralPath $markerPath -Force -ErrorAction SilentlyContinue
            }
        }
        $action = if ($removed) { if ($PreviewOnly) { 'would-remove-unconfigured-generated-plan' } else { 'removed-unconfigured-generated-plan' } } else { 'verification-not-configured' }
        if ($selection.state -eq 'invalid') { $action = if ($removed) { 'removed-invalid-generated-plan' } else { 'verification-plan-invalid' } }
        return New-ContinuousCoReviewVerificationMaterializationResult -State $selection.state -Action $action -Mutated ($removed -and -not $PreviewOnly) -Warning $selection.action -Selection $selection -PlanPath $planPath -MarkerPath $markerPath
    }

    $planContent = ConvertTo-ContinuousCoReviewSupplierCanonicalJson $selection.plan
    $catalogId = [string](Get-ContinuousCoReviewSupplierProp $catalog 'catalog_id')
    $markerObject = [ordered]@{
        schema_version = '1.0'
        selection_id = $selection.selection_id
        generated_content_hash = $selection.generated_content_hash
        plan_id = $selection.plan_id
        catalog_id = $catalogId
        source_kind = $selection.source_kind
        source_identity = $selection.source_identity
    }
    $markerContent = ConvertTo-ContinuousCoReviewSupplierCanonicalJson $markerObject
    if ($generatedAndUnmodified -and (Get-Content -LiteralPath $planPath -Raw) -ceq $planContent -and (Get-Content -LiteralPath $markerPath -Raw) -ceq $markerContent) {
        return New-ContinuousCoReviewVerificationMaterializationResult -State selected -Action 'generated-plan-current' -Mutated $false -Warning $null -Selection $selection -PlanPath $planPath -MarkerPath $markerPath
    }
    $action = if ($generatedAndUnmodified) { if ($PreviewOnly) { 'would-refresh-generated-plan' } else { 'refreshed-generated-plan' } } else { if ($PreviewOnly) { 'would-create-generated-plan' } else { 'created-generated-plan' } }
    if (-not $PreviewOnly) {
        Write-ContinuousCoReviewVerificationPlanFile -Path $planPath -Content $planContent
        Write-ContinuousCoReviewVerificationPlanFile -Path $markerPath -Content $markerContent
    }
    return New-ContinuousCoReviewVerificationMaterializationResult -State selected -Action $action -Mutated (-not $PreviewOnly) -Warning $null -Selection $selection -PlanPath $planPath -MarkerPath $markerPath
}
