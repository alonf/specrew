$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# F-198 / T041: the ONE production authority cutover seam. Consumers ask this module whether
# the legacy or campaign path may act; they never infer authority from a missing file, a parse
# failure, or the presence of legacy artifacts. The closed enum makes dual authority
# unrepresentable. The explicit disabled state supports the two-step operational cutover:
# legacy -> disabled -> campaign.

function New-ContinuousCoReviewDisabledAuthorityDecision {
    param(
        [Parameter(Mandatory)][string]$Reason,
        [AllowNull()][string]$ConfigPath
    )

    return [pscustomobject]@{
        schema_version             = '1.0'
        mode                       = 'disabled'
        valid                      = $false
        legacy_promotion_enabled   = $false
        campaign_authority_enabled = $false
        reason                     = $Reason
        config_path                = $ConfigPath
    }
}

function Get-ContinuousCoReviewAuthorityDecision {
    [CmdletBinding()]
    param([string]$ConfigPath)

    if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
        $ConfigPath = Join-Path $PSScriptRoot 'review-authority-mode.json'
    }
    if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
        return (New-ContinuousCoReviewDisabledAuthorityDecision -Reason 'authority-config-missing' -ConfigPath $ConfigPath)
    }

    try {
        $item = Get-Item -LiteralPath $ConfigPath -ErrorAction Stop
        if ($item.Length -gt 4096) {
            return (New-ContinuousCoReviewDisabledAuthorityDecision -Reason 'authority-config-too-large' -ConfigPath $ConfigPath)
        }
        $raw = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($raw)) {
            return (New-ContinuousCoReviewDisabledAuthorityDecision -Reason 'authority-config-empty' -ConfigPath $ConfigPath)
        }
        $config = $raw | ConvertFrom-Json -Depth 4 -ErrorAction Stop
    }
    catch {
        return (New-ContinuousCoReviewDisabledAuthorityDecision -Reason 'authority-config-invalid-json' -ConfigPath $ConfigPath)
    }

    $properties = @($config.PSObject.Properties.Name)
    if (@($properties | Where-Object { $_ -notin @('schema_version', 'mode') }).Count -gt 0 -or
        -not ($properties -contains 'schema_version') -or
        -not ($properties -contains 'mode')) {
        return (New-ContinuousCoReviewDisabledAuthorityDecision -Reason 'authority-config-invalid-shape' -ConfigPath $ConfigPath)
    }
    if ([string]$config.schema_version -cne '1.0') {
        return (New-ContinuousCoReviewDisabledAuthorityDecision -Reason 'authority-config-unsupported-version' -ConfigPath $ConfigPath)
    }

    $mode = [string]$config.mode
    if ($mode -cnotin @('legacy', 'disabled', 'campaign')) {
        return (New-ContinuousCoReviewDisabledAuthorityDecision -Reason 'authority-config-invalid-mode' -ConfigPath $ConfigPath)
    }

    return [pscustomobject]@{
        schema_version             = '1.0'
        mode                       = $mode
        valid                      = $true
        legacy_promotion_enabled   = ($mode -ceq 'legacy')
        campaign_authority_enabled = ($mode -ceq 'campaign')
        reason                     = ('authority-mode-' + $mode)
        config_path                = $ConfigPath
    }
}

function Test-ContinuousCoReviewAuthorityEnabled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('legacy', 'campaign')][string]$Authority,
        [AllowNull()]$Decision
    )

    if ($null -eq $Decision) {
        $Decision = Get-ContinuousCoReviewAuthorityDecision
    }
    if (-not $Decision.valid) { return $false }
    if ($Authority -ceq 'legacy') { return [bool]$Decision.legacy_promotion_enabled }
    return [bool]$Decision.campaign_authority_enabled
}
