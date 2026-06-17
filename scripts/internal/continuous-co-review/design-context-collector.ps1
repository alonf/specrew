$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function ConvertTo-ContinuousCoReviewContextRef {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [Parameter(Mandatory)]
        [string] $Path
    )

    $relative = [System.IO.Path]::GetRelativePath($RepoRoot, $Path)
    return $relative.Replace('\', '/')
}

function Get-ContinuousCoReviewRuleRefs {
    param(
        [Parameter(Mandatory)]
        [string] $ImplementationRulesPath
    )

    if (-not (Test-Path -LiteralPath $ImplementationRulesPath -PathType Leaf)) {
        return @()
    }

    $refs = [System.Collections.Generic.List[string]]::new()
    foreach ($line in (Get-Content -LiteralPath $ImplementationRulesPath)) {
        if ($line -match '^\s*-\s*id:\s*[''"]?([^''"\s]+)[''"]?\s*$') {
            $refs.Add($Matches[1])
        }
    }

    return @($refs)
}

function Get-ContinuousCoReviewDesignContext {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [Parameter(Mandatory)]
        [string] $FeatureRoot,

        [Parameter(Mandatory)]
        [string] $CheckpointId
    )

    $resolvedRepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
    $featureRootPath = Join-Path $resolvedRepoRoot $FeatureRoot
    $policy = New-ContinuousCoReviewVisibilityPolicy
    $refs = [System.Collections.Generic.List[string]]::new()

    $directContextPaths = @(
        (Join-Path $featureRootPath 'spec.md'),
        (Join-Path $featureRootPath 'iterations/001/design-analysis.md'),
        (Join-Path $featureRootPath 'implementation-rules.yml')
    )

    foreach ($contextPath in $directContextPaths) {
        if (Test-Path -LiteralPath $contextPath -PathType Leaf) {
            $refs.Add((ConvertTo-ContinuousCoReviewContextRef -RepoRoot $resolvedRepoRoot -Path $contextPath))
        }
    }

    $workshopRoot = Join-Path $featureRootPath 'workshop'
    if (Test-Path -LiteralPath $workshopRoot -PathType Container) {
        foreach ($workshopFile in @(Get-ChildItem -LiteralPath $workshopRoot -Filter '*.md' -File | Sort-Object -Property Name)) {
            $refs.Add((ConvertTo-ContinuousCoReviewContextRef -RepoRoot $resolvedRepoRoot -Path $workshopFile.FullName))
        }
    }

    $implementationRulesPath = Join-Path $featureRootPath 'implementation-rules.yml'
    $qualityRuleRefs = Get-ContinuousCoReviewRuleRefs -ImplementationRulesPath $implementationRulesPath

    return [pscustomobject][ordered]@{
        schema_version       = '1.0'
        checkpoint_id        = $CheckpointId
        design_context_refs  = @($refs | Select-Object -Unique)
        quality_rule_refs    = @($qualityRuleRefs | Select-Object -Unique)
        redaction_policy     = $policy.redaction_policy
        visibility_policy    = [pscustomobject][ordered]@{
            allowed_design_context_patterns = $policy.allowed_design_context_patterns
        }
        excluded_refs        = @('redacted:non-design-context-by-policy')
    }
}
