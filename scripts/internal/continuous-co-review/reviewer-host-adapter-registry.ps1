$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-ContinuousCoReviewReviewerHostAdapterFunctionName {
    param(
        [Parameter(Mandatory)]
        [string] $AdapterId
    )

    if ($AdapterId -eq 'reviewer-host-adapter-fixture') {
        return 'Invoke-ContinuousCoReviewFixtureReviewerPath'
    }

    $adapterPrefix = 'reviewer-host-adapter-'
    if (-not $AdapterId.StartsWith($adapterPrefix, [System.StringComparison]::Ordinal)) {
        return $null
    }

    $adapterName = $AdapterId.Substring($adapterPrefix.Length)
    if ([string]::IsNullOrWhiteSpace($adapterName)) {
        return $null
    }

    $functionSuffixParts = @(
        foreach ($segment in ($adapterName -split '-')) {
            if ($segment -notmatch '^[a-z0-9]+$') {
                return $null
            }

            if ($segment.Length -eq 1) {
                $segment.ToUpperInvariant()
            }
            else {
                $segment.Substring(0, 1).ToUpperInvariant() + $segment.Substring(1)
            }
        }
    )

    return "Invoke-ContinuousCoReviewReviewerHostAdapter$($functionSuffixParts -join '')"
}

function Get-ContinuousCoReviewReviewerHostAdapterRegistry {
    param(
        [string] $AdapterRoot
    )

    $resolvedRoot = if ([string]::IsNullOrWhiteSpace($AdapterRoot)) {
        $PSScriptRoot
    }
    else {
        (Resolve-Path -LiteralPath $AdapterRoot).Path
    }

    $adapters = @(
        Get-ChildItem -LiteralPath $resolvedRoot -File -Filter 'reviewer-host-adapter-*.ps1' |
            Sort-Object -Property Name |
            ForEach-Object {
                $adapterId = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
                [pscustomobject][ordered]@{
                    adapter_id    = $adapterId
                    path          = $_.FullName
                    function_name = Get-ContinuousCoReviewReviewerHostAdapterFunctionName -AdapterId $adapterId
                }
            }
    )

    return [pscustomobject][ordered]@{
        schema_version = '1.0'
        adapter_root   = $resolvedRoot
        adapters       = @($adapters)
    }
}
