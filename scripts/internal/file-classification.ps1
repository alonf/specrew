<#
.SYNOPSIS
    File-classification helpers for Specrew multi-session foundation (F-051, US2).

.DESCRIPTION
    Classifies Specrew-managed paths into four categories (FR-004), generates the
    per-session .gitignore block (FR-005), and removes previously tracked per-session
    files from the git index without deleting working copies (FR-006).

    Categories:
      shared             - committed, identical across developers
      per-session        - gitignored (ephemeral per-developer state)
      append-only-shared - committed, atomic-append discipline (JSON Lines)
      regenerable        - generated from shared sources

    Dot-source this file to use Get-FileClassification / Update-GitignoreForSession /
    Remove-TrackedPerSessionFiles.
#>

Set-StrictMode -Version Latest

# Canonical per-session patterns (FR-005). Order is the gitignore write order.
$script:SpecrewPerSessionPatterns = @(
    '.specrew/last-*'
    '.specify/feature.json'
    '.specrew/start-context.json'
    '.specrew/host-history.json'
    '.specrew/.cache/'
    '.squad/sessions/'
    '.squad/decisions/inbox/'
    '.specrew/last-validator-summary.json'
    '.specrew/active-sessions.yml'
    '.specrew/workshop-visuals/'
)

$script:SpecrewGitignoreSectionHeader = '# Specrew per-session files (F-051 multi-session foundation) - do not commit'

function Get-FileClassification {
    <#
    .SYNOPSIS
        Return the static file-classification rule set (FR-004): pattern, category, reason.
    #>
    [OutputType([System.Collections.Generic.List[psobject]])]
    param()

    $rules = [System.Collections.Generic.List[psobject]]::new()

    foreach ($pattern in $script:SpecrewPerSessionPatterns) {
        $rules.Add([pscustomobject]@{
                pattern  = $pattern
                category = 'per-session'
                reason   = 'Ephemeral per-developer session state; gitignored to avoid cross-developer merge conflicts.'
            })
    }

    # Representative shared / append-only-shared / regenerable rules. Shared and
    # regenerable paths are NOT gitignored; append-only-shared is committed with
    # JSON Lines atomic-append discipline (FR-018, Iteration 2b).
    $rules.Add([pscustomobject]@{ pattern = '.specrew/config.yml'; category = 'shared'; reason = 'Project configuration; committed and identical across developers.' })
    $rules.Add([pscustomobject]@{ pattern = '.squad/team.md'; category = 'shared'; reason = 'Crew roster; shared project truth.' })
    $rules.Add([pscustomobject]@{ pattern = '.squad/decisions.md'; category = 'append-only-shared'; reason = 'Decision ledger; append-only, mechanically mergeable.' })
    $rules.Add([pscustomobject]@{ pattern = '.specrew/session-start.log'; category = 'append-only-shared'; reason = 'JSON Lines event log; atomic append per FR-018.' })
    $rules.Add([pscustomobject]@{ pattern = 'specs/*/iterations/*/dashboard.md'; category = 'regenerable'; reason = 'Rendered from iteration state; regenerable from shared sources.' })

    return $rules
}

function Get-SpecrewPerSessionPattern {
    <# Return the canonical per-session glob patterns (FR-005). #>
    [OutputType([string[]])]
    param()
    return $script:SpecrewPerSessionPatterns
}

function Update-GitignoreForSession {
    <#
    .SYNOPSIS
        Merge the per-session patterns into <ProjectRoot>/.gitignore (FR-005).
    .DESCRIPTION
        Idempotent and non-destructive: existing lines (comments, unrelated entries,
        already-present per-session patterns) are preserved; only missing per-session
        patterns are appended under a managed section header. Returns the patterns added.
    #>
    [OutputType([string[]])]
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $gitignorePath = Join-Path $ProjectRoot '.gitignore'

    $existingLines = @()
    if (Test-Path -LiteralPath $gitignorePath -PathType Leaf) {
        $existingLines = @(Get-Content -LiteralPath $gitignorePath -Encoding UTF8)
    }
    $existingTrimmed = @($existingLines | ForEach-Object { $_.Trim() })

    $missing = @($script:SpecrewPerSessionPatterns | Where-Object { $existingTrimmed -notcontains $_ })
    if ($missing.Count -eq 0) {
        return @()
    }

    $appendLines = [System.Collections.Generic.List[string]]::new()
    # Separate from prior content with a blank line when the file is non-empty.
    if ($existingLines.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace(($existingLines -join ''))) {
        $appendLines.Add('')
    }
    if ($existingTrimmed -notcontains $script:SpecrewGitignoreSectionHeader) {
        $appendLines.Add($script:SpecrewGitignoreSectionHeader)
    }
    foreach ($pattern in $missing) {
        $appendLines.Add($pattern)
    }

    $finalLines = @($existingLines) + @($appendLines)
    $content = ($finalLines -join "`n").TrimEnd() + "`n"

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $tempPath = '{0}.{1}.tmp' -f $gitignorePath, ([System.Guid]::NewGuid().ToString('N'))
    [System.IO.File]::WriteAllText($tempPath, $content, $utf8NoBom)
    Move-Item -LiteralPath $tempPath -Destination $gitignorePath -Force

    return $missing
}

function Test-PathMatchesPerSession {
    <# True when a forward-slash git path matches any canonical per-session pattern. #>
    [OutputType([bool])]
    param([Parameter(Mandatory = $true)][string]$Path)

    $normalized = $Path -replace '\\', '/'
    foreach ($pattern in $script:SpecrewPerSessionPatterns) {
        if ($pattern.EndsWith('/')) {
            if ($normalized.StartsWith($pattern, [System.StringComparison]::Ordinal)) { return $true }
        }
        elseif ($pattern.Contains('*')) {
            if ($normalized -like $pattern) { return $true }
        }
        elseif ($normalized -eq $pattern) {
            return $true
        }
    }
    return $false
}

function Remove-TrackedPerSessionFiles {
    <#
    .SYNOPSIS
        Remove previously tracked per-session files from the git index (FR-006).
    .DESCRIPTION
        Runs `git rm --cached` (NOT a working-tree delete) for every tracked path that
        matches a per-session pattern, mirroring the F-049 437338f6 cleanup. Returns the
        list of paths removed from the index. A no-op (returns @()) when none are tracked.
    #>
    [OutputType([string[]])]
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    Push-Location -LiteralPath $ProjectRoot
    try {
        $insideRepo = (git rev-parse --is-inside-work-tree 2>$null)
        if ($LASTEXITCODE -ne 0 -or $insideRepo -ne 'true') {
            return @()
        }

        $tracked = @(git ls-files)
        $toRemove = @($tracked | Where-Object { Test-PathMatchesPerSession -Path $_ })
        if ($toRemove.Count -eq 0) {
            return @()
        }

        foreach ($path in $toRemove) {
            git rm --cached --quiet -- $path 2>$null | Out-Null
        }
        return $toRemove
    }
    finally {
        Pop-Location
    }
}
