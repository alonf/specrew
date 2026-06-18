$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-ContinuousCoReviewHostAgentMirrorTargets {
    param(
        [string[]] $Hosts = @('claude', 'github-copilot', 'generic-agents')
    )

    $targetMap = @{
        'claude'         = '.claude/agents/specrew-code-review-agent.md'
        'github-copilot' = '.github/agents/specrew-code-review-agent.md'
        'generic-agents' = '.agents/specrew-code-review-agent.md'
    }

    foreach ($hostName in @($Hosts)) {
        if ([string]::IsNullOrWhiteSpace($hostName)) { continue }
        if (-not $targetMap.ContainsKey($hostName)) { continue }
        [pscustomobject][ordered]@{
            host              = $hostName
            mirror_path       = $targetMap[$hostName]
            authoritative     = $false
            runtime_required  = $false
            mirror_semantics  = 'best-effort-native-copy-only'
        }
    }
}

function New-ContinuousCoReviewHostAgentMirrorPlan {
    param(
        [string] $RepoRoot,

        [string] $CanonicalPath = 'scripts/internal/continuous-co-review/code-review-agent.md',

        [string[]] $Hosts = @('claude', 'github-copilot', 'generic-agents')
    )

    $root = if ($RepoRoot) { (Resolve-Path -LiteralPath $RepoRoot).Path } else { (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path }
    $canonicalFullPath = Join-Path $root $CanonicalPath
    if (-not (Test-Path -LiteralPath $canonicalFullPath -PathType Leaf)) {
        throw "Canonical reviewer instruction source not found: $CanonicalPath"
    }

    $canonicalContent = Get-Content -LiteralPath $canonicalFullPath -Raw
    $canonicalHash = "sha256:$(Get-ReviewerContractSha256Hex -Text $canonicalContent)"
    $targets = @(Get-ContinuousCoReviewHostAgentMirrorTargets -Hosts $Hosts)
    return [pscustomobject][ordered]@{
        schema_version       = '1.0'
        canonical_path       = $CanonicalPath.Replace('\\', '/')
        canonical_hash       = $canonicalHash
        authoritative_source = $CanonicalPath.Replace('\\', '/')
        runtime_authority    = 'composed-prompt'
        mirror_authority     = $false
        targets              = @($targets)
    }
}

function ConvertTo-ContinuousCoReviewHostAgentMirrorContent {
    param(
        [Parameter(Mandatory)]
        [string] $CanonicalContent,

        [Parameter(Mandatory)]
        [string] $CanonicalPath,

        [Parameter(Mandatory)]
        [string] $CanonicalHash
    )

    return @(
        '<!-- Specrew Proposal 197 best-effort native host mirror. -->',
        '<!-- Runtime authority remains the injected composed prompt from scripts/internal/continuous-co-review/review-prompt-composer.ps1. -->',
        "<!-- Canonical source: $CanonicalPath -->",
        "<!-- Canonical hash: $CanonicalHash -->",
        '',
        $CanonicalContent
    ) -join "`n"
}

function Sync-ContinuousCoReviewHostAgentMirrors {
    param(
        [string] $RepoRoot,

        [string] $CanonicalPath = 'scripts/internal/continuous-co-review/code-review-agent.md',

        [string[]] $Hosts = @('claude', 'github-copilot', 'generic-agents'),

        [switch] $PassThru
    )

    $root = if ($RepoRoot) { (Resolve-Path -LiteralPath $RepoRoot).Path } else { (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path }
    $plan = New-ContinuousCoReviewHostAgentMirrorPlan -RepoRoot $root -CanonicalPath $CanonicalPath -Hosts $Hosts
    $canonicalFullPath = Join-Path $root $CanonicalPath
    $canonicalContent = Get-Content -LiteralPath $canonicalFullPath -Raw
    $written = @()
    foreach ($target in @($plan.targets)) {
        $targetPath = Join-Path $root $target.mirror_path
        $targetDir = Split-Path -Parent $targetPath
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        $mirrorContent = ConvertTo-ContinuousCoReviewHostAgentMirrorContent -CanonicalContent $canonicalContent -CanonicalPath $plan.canonical_path -CanonicalHash $plan.canonical_hash
        Set-Content -LiteralPath $targetPath -Value $mirrorContent -Encoding UTF8 -NoNewline
        $written += [pscustomobject][ordered]@{
            host             = $target.host
            mirror_path      = $target.mirror_path
            canonical_hash   = $plan.canonical_hash
            authoritative    = $false
            runtime_required = $false
            status           = 'written'
        }
    }

    $result = [pscustomobject][ordered]@{
        schema_version    = '1.0'
        canonical_path    = $plan.canonical_path
        canonical_hash    = $plan.canonical_hash
        runtime_authority = 'composed-prompt'
        mirror_authority  = $false
        written           = @($written)
    }
    if ($PassThru) { return $result }
}
