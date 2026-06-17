$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-ContinuousCoReviewCatalogValue {
    param(
        [AllowNull()]
        $Object,

        [Parameter(Mandatory)]
        [string] $Name,

        [AllowNull()]
        $DefaultValue = $null
    )

    if ($null -eq $Object) {
        return $DefaultValue
    }

    if (Test-ReviewerContractPropertyExists -Object $Object -Name $Name) {
        $value = Get-ReviewerContractPropertyValue -Object $Object -Name $Name
        if ($null -ne $value) {
            return $value
        }
    }

    return $DefaultValue
}

function Test-ContinuousCoReviewReviewerHostInstalled {
    param(
        [Parameter(Mandatory)]
        [string] $CommandName,

        [scriptblock] $CommandResolver
    )

    if ($CommandResolver) {
        return [bool] (& $CommandResolver -CommandName $CommandName)
    }

    return ($null -ne (Get-Command -Name $CommandName -ErrorAction SilentlyContinue))
}

function New-ContinuousCoReviewDefaultReviewerHostConfig {
    param(
        [scriptblock] $CommandResolver
    )

    $hostRows = @(
        @{ host = 'claude'; command = 'claude'; model = 'configured-by-user'; adapter_id = 'reviewer-host-adapter-claude-prompt'; rank = 80 }
        @{ host = 'codex'; command = 'codex'; model = 'configured-by-user'; adapter_id = 'reviewer-host-adapter-codex-exec'; rank = 75 }
        @{ host = 'copilot'; command = 'copilot'; model = 'configured-by-user'; adapter_id = 'reviewer-host-adapter-copilot-prompt'; rank = 85 }
        @{ host = 'cursor-agent'; command = 'cursor-agent'; model = 'configured-by-user'; adapter_id = 'reviewer-host-adapter-cursor-agent-prompt'; rank = 70 }
        @{ host = 'antigravity'; command = 'antigravity'; model = 'configured-by-user'; adapter_id = 'reviewer-host-adapter-antigravity-prompt'; rank = 65 }
    )

    return [pscustomobject][ordered]@{
        schema_version = '1.0'
        hosts          = @(
            foreach ($row in $hostRows) {
                [pscustomobject][ordered]@{
                    host              = $row.host
                    model             = $row.model
                    adapter_id        = $row.adapter_id
                    allowed           = $false
                    installed         = (Test-ContinuousCoReviewReviewerHostInstalled -CommandName $row.command -CommandResolver $CommandResolver)
                    review_class_rank = [int] $row.rank
                    model_source      = 'human-entered'
                    cost_class        = 'non-default'
                    authorization_ref = $null
                    fallback_allowed  = $false
                }
            }
        )
    }
}

function ConvertTo-ContinuousCoReviewReviewerHostCatalogEntry {
    param(
        [Parameter(Mandatory)]
        $Entry
    )

    $adapterId = [string] (Get-ContinuousCoReviewCatalogValue -Object $Entry -Name 'adapter_id')
    if ($adapterId -notmatch '^reviewer-host-adapter-[a-z0-9-]+$') {
        throw "Reviewer host catalog entry uses an invalid adapter id '$adapterId'."
    }

    return [pscustomobject][ordered]@{
        host              = [string] (Get-ContinuousCoReviewCatalogValue -Object $Entry -Name 'host')
        model             = [string] (Get-ContinuousCoReviewCatalogValue -Object $Entry -Name 'model')
        adapter_id        = $adapterId
        allowed           = [bool] (Get-ContinuousCoReviewCatalogValue -Object $Entry -Name 'allowed' -DefaultValue $false)
        installed         = [bool] (Get-ContinuousCoReviewCatalogValue -Object $Entry -Name 'installed' -DefaultValue $false)
        review_class_rank = [int] (Get-ContinuousCoReviewCatalogValue -Object $Entry -Name 'review_class_rank' -DefaultValue 0)
        model_source      = [string] (Get-ContinuousCoReviewCatalogValue -Object $Entry -Name 'model_source' -DefaultValue 'human-entered')
        cost_class        = [string] (Get-ContinuousCoReviewCatalogValue -Object $Entry -Name 'cost_class' -DefaultValue 'non-default')
        authorization_ref = Get-ContinuousCoReviewCatalogValue -Object $Entry -Name 'authorization_ref'
        fallback_allowed  = [bool] (Get-ContinuousCoReviewCatalogValue -Object $Entry -Name 'fallback_allowed' -DefaultValue $false)
    }
}

function Get-ContinuousCoReviewReviewerHostCatalog {
    param(
        [AllowNull()]
        $Configuration,

        [scriptblock] $CommandResolver
    )

    $resolvedConfiguration = if ($null -eq $Configuration) {
        New-ContinuousCoReviewDefaultReviewerHostConfig -CommandResolver $CommandResolver
    }
    else {
        $Configuration
    }

    $hosts = @(
        foreach ($entry in @($resolvedConfiguration.hosts)) {
            ConvertTo-ContinuousCoReviewReviewerHostCatalogEntry -Entry $entry
        }
    )

    return [pscustomobject][ordered]@{
        schema_version = '1.0'
        hosts          = @($hosts)
    }
}
