<#
.SYNOPSIS
    Feature-claim management for Specrew multi-session foundation (F-051 Iteration 2a).

.DESCRIPTION
    Maintains the committed, append-only-shared claims file `.squad/active-features.yml`
    (FR-012 through FR-016). Unlike the gitignored session lock, claims ARE committed - this
    is the cross-machine coordination surface (drift D-003). `claimed_by` carries only the
    coarse `user@machine` token (NOT the rich local fingerprint), per FR-043.

    Reuses the shared atomic-write, yaml-list, and time helpers. Corrupt/missing files
    degrade to empty. Dot-source to use.
#>

Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'atomic-write.ps1')
. (Join-Path $PSScriptRoot 'yaml-list.ps1')
. (Join-Path $PSScriptRoot 'specrew-time.ps1')

$script:SpecrewActiveFeaturesTopKey = 'claims'

function Get-FeatureClaimsPath {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)
    return (Join-Path $ProjectRoot '.squad/active-features.yml')
}

function Get-SpecrewCoarseIdentity {
    <# Coarse user@machine identity for a committed claim (no localhash; FR-043). #>
    return ('{0}@{1}' -f [System.Environment]::UserName, [System.Environment]::MachineName)
}

function Read-FeatureClaims {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)
    return @(Read-SpecrewYamlList -Path (Get-FeatureClaimsPath -ProjectRoot $ProjectRoot) -TopKey $script:SpecrewActiveFeaturesTopKey)
}

function Write-FeatureClaims {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowEmptyCollection()][AllowNull()][object[]]$Claims
    )
    $content = ConvertTo-SpecrewYamlList -TopKey $script:SpecrewActiveFeaturesTopKey -Entries $Claims
    Write-SpecrewFileAtomic -Path (Get-FeatureClaimsPath -ProjectRoot $ProjectRoot) -Content $content
}

function Add-FeatureClaim {
    <# Upsert a claim for a feature at the specify boundary; one claim per feature (FR-013). #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$FeatureId,
        [string]$ClaimedBy = (Get-SpecrewCoarseIdentity),
        [string]$BranchName = $FeatureId,
        [string]$NowUtc = (Get-SpecrewUtcNow)
    )
    $claims = @(Read-FeatureClaims -ProjectRoot $ProjectRoot)
    $existing = $claims | Where-Object { $_['feature_id'] -eq $FeatureId } | Select-Object -First 1
    if ($null -ne $existing) {
        $existing['last_refresh_time'] = $NowUtc   # upsert: refresh, do not duplicate
    }
    else {
        $claims = @($claims) + ,([ordered]@{
                feature_id        = $FeatureId
                claimed_by        = $ClaimedBy
                claim_start_time  = $NowUtc
                last_refresh_time = $NowUtc
                branch_name       = $BranchName
            })
    }
    Write-FeatureClaims -ProjectRoot $ProjectRoot -Claims $claims
}

function Update-FeatureClaim {
    <#
    Advance last_refresh_time monotonically at every boundary (FR-014, SC-008). If the claim is
    missing but ClaimedBy is supplied (an active session), re-add it (FR-014 reconciliation /
    manual-removal Edge Case). Missing + no ClaimedBy = no-op.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$FeatureId,
        [string]$ClaimedBy,
        [string]$BranchName = $FeatureId,
        [string]$NowUtc = (Get-SpecrewUtcNow)
    )
    $claims = @(Read-FeatureClaims -ProjectRoot $ProjectRoot)
    $existing = $claims | Where-Object { $_['feature_id'] -eq $FeatureId } | Select-Object -First 1
    if ($null -ne $existing) {
        $now = ConvertTo-SpecrewUtc -Value $NowUtc
        $cur = ConvertTo-SpecrewUtc -Value ([string]$existing['last_refresh_time'])
        if ($null -eq $cur -or ($null -ne $now -and $now -gt $cur)) {
            $existing['last_refresh_time'] = $NowUtc   # monotonic: only advance
        }
        Write-FeatureClaims -ProjectRoot $ProjectRoot -Claims $claims
    }
    elseif (-not [string]::IsNullOrEmpty($ClaimedBy)) {
        Add-FeatureClaim -ProjectRoot $ProjectRoot -FeatureId $FeatureId -ClaimedBy $ClaimedBy -BranchName $BranchName -NowUtc $NowUtc
    }
}

function Remove-FeatureClaim {
    <# Remove the claim for a feature (at feature-closeout when merged); no-op if absent (FR-016). #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$FeatureId
    )
    $claims = @(Read-FeatureClaims -ProjectRoot $ProjectRoot)
    $kept = @($claims | Where-Object { $_['feature_id'] -ne $FeatureId })
    if ($kept.Count -ne $claims.Count) {
        Write-FeatureClaims -ProjectRoot $ProjectRoot -Claims $kept
    }
}

function Test-FeatureClaimConflict {
    <# Return a claim on the same feature held by a DIFFERENT developer, else $null (FR-015). #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$FeatureId,
        [string]$ClaimedBy = (Get-SpecrewCoarseIdentity)
    )
    $claims = @(Read-FeatureClaims -ProjectRoot $ProjectRoot)
    return ($claims | Where-Object { $_['feature_id'] -eq $FeatureId -and $_['claimed_by'] -ne $ClaimedBy } | Select-Object -First 1)
}
