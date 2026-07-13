# Shared TRUNK RESOLUTION - the one repository capability that decides which branch the co-review gate treats as
# the shipped trunk (the merge-base anchor / diff baseline). Replaces the duplicated 'main' defaults + ad-hoc
# candidate loops across the CLI, navigator, signoff gate, worktree baseline resolver, and lineage resolver.
#
# PRECEDENCE (maintainer 2026-07-13):
#   1. Explicit co_review_trunk (a -Trunk override, else .specrew/config.yml co_review_trunk).
#   2. refs/remotes/origin/HEAD (the remote's advertised default branch).
#   3. The configured UPSTREAM of the current branch (branch.<name>.merge -> @{upstream}).
#   4. Existing CONVENTIONAL refs (main, master, develop, dev), local or origin/, in that priority order.
#   5. A LOCAL-ONLY repository with exactly ONE pre-feature branch -> that branch.
#   6. AMBIGUOUS -> fail with a clear configuration instruction.
#
# It NEVER creates, renames, or moves a branch to satisfy the gate. A repo whose ONLY branch is the feature
# branch (no trunk) resolves to `greenfield` (ok, trunk_ref = $null) so the baseline resolver uses the empty tree
# - that is a legitimate state, not an ambiguity.
#
# Returns [pscustomobject]@{ ok; trunk_ref; source; message }:
#   ok=$true,  trunk_ref=<ref>  -> a trunk resolved (source names the precedence level).
#   ok=$true,  trunk_ref=$null, source='greenfield' -> no trunk (single feature branch); caller uses the empty tree.
#   ok=$false, trunk_ref=$null  -> failure (source: no-commit-repo | explicit-trunk-unresolvable | ambiguous),
#                                  message carries the human-facing configuration instruction.

function Invoke-ContinuousCoReviewTrunkGit {
    # Prefer the encoding-immune resolver-git wrapper (hook-provider context); fall back to a direct call.
    param([Parameter(Mandatory)][string]$RepoRoot, [Parameter(Mandatory)][string[]]$Arguments)
    if (Get-Command -Name 'Invoke-ContinuousCoReviewResolverGit' -ErrorAction SilentlyContinue) {
        $r = Invoke-ContinuousCoReviewResolverGit -RepoRoot $RepoRoot -Arguments $Arguments
        return [pscustomobject]@{ ok = ($r.ExitCode -eq 0); lines = @($r.Output | ForEach-Object { ([string]$_).Trim() } | Where-Object { $_ -ne '' }) }
    }
    $out = @(& git -C $RepoRoot @Arguments 2>$null)
    return [pscustomobject]@{ ok = ($LASTEXITCODE -eq 0); lines = @($out | ForEach-Object { ([string]$_).Trim() } | Where-Object { $_ -ne '' }) }
}

function Test-ContinuousCoReviewGitRefExists {
    param([Parameter(Mandatory)][string]$RepoRoot, [Parameter(Mandatory)][AllowEmptyString()][string]$Ref)
    if ([string]::IsNullOrWhiteSpace($Ref)) { return $false }
    return (Invoke-ContinuousCoReviewTrunkGit -RepoRoot $RepoRoot -Arguments @('rev-parse', '--verify', '--quiet', ("{0}^{{commit}}" -f $Ref))).ok
}

# The explicit co_review_trunk from .specrew/config.yml (quote-strip + inline-comment tolerant). '' when unset.
function Get-ContinuousCoReviewConfiguredTrunk {
    param([Parameter(Mandatory)][string]$RepoRoot)
    $configPath = Join-Path $RepoRoot '.specrew/config.yml'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) { return '' }
    foreach ($line in Get-Content -LiteralPath $configPath -Encoding UTF8) {
        if ($line -match '^\s*co_review_trunk:\s*[''"]?(?<value>[^''"#]+?)[''"]?\s*(?:#.*)?$') {
            $value = $Matches['value'].Trim()
            if (-not [string]::IsNullOrWhiteSpace($value)) { return $value }
        }
    }
    return ''
}

function Resolve-ContinuousCoReviewTrunkRef {
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [AllowEmptyString()][string]$Trunk = ''   # an explicit override (e.g. the CLI --trunk); wins over config
    )
    $mk = {
        param([bool]$ok, $ref, [string]$source, [string]$message)
        [pscustomobject]@{ ok = $ok; trunk_ref = $ref; source = $source; message = $message }
    }

    # 0. The repo must have commits (else HEAD - and every merge-base - is unresolvable).
    if (-not (Test-ContinuousCoReviewGitRefExists -RepoRoot $RepoRoot -Ref 'HEAD')) {
        return & $mk $false $null 'no-commit-repo' "The repository at '$RepoRoot' has no commits, so a trunk cannot be resolved. Commit a base branch, or set 'co_review_trunk: <branch>' in .specrew/config.yml."
    }
    $currentBranch = ''
    $cb = Invoke-ContinuousCoReviewTrunkGit -RepoRoot $RepoRoot -Arguments @('rev-parse', '--abbrev-ref', 'HEAD')
    if ($cb.ok -and $cb.lines.Count -gt 0) { $currentBranch = $cb.lines[0] }

    # 1. EXPLICIT co_review_trunk (override wins over config). Try the bare name, then origin/<name>
    #    (a fresh checkout may hold the trunk only as a remote-tracking ref - the F5/145 case).
    $explicit = if (-not [string]::IsNullOrWhiteSpace($Trunk)) { $Trunk.Trim() } else { Get-ContinuousCoReviewConfiguredTrunk -RepoRoot $RepoRoot }
    if (-not [string]::IsNullOrWhiteSpace($explicit)) {
        $explicitCandidates = @($explicit)
        if ($explicit -notmatch '/') { $explicitCandidates += "origin/$explicit" }
        foreach ($cand in $explicitCandidates) {
            if (Test-ContinuousCoReviewGitRefExists -RepoRoot $RepoRoot -Ref $cand) { return & $mk $true $cand 'explicit-co_review_trunk' '' }
        }
        $tried = if ($explicit -notmatch '/') { "'$explicit' and 'origin/$explicit'" } else { "'$explicit'" }
        return & $mk $false $null 'explicit-trunk-unresolvable' "The configured co_review_trunk '$explicit' does not resolve to a ref (tried $tried). Set a valid branch in .specrew/config.yml (co_review_trunk), or remove it to auto-detect."
    }

    # 2. refs/remotes/origin/HEAD (the remote's advertised default).
    $oh = Invoke-ContinuousCoReviewTrunkGit -RepoRoot $RepoRoot -Arguments @('symbolic-ref', '--quiet', '--short', 'refs/remotes/origin/HEAD')
    if ($oh.ok -and $oh.lines.Count -gt 0 -and (Test-ContinuousCoReviewGitRefExists -RepoRoot $RepoRoot -Ref $oh.lines[0])) {
        return & $mk $true $oh.lines[0] 'origin-head' ''
    }

    # 3. The configured UPSTREAM of the current branch.
    $up = Invoke-ContinuousCoReviewTrunkGit -RepoRoot $RepoRoot -Arguments @('rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{upstream}')
    if ($up.ok -and $up.lines.Count -gt 0) {
        $upstream = $up.lines[0]
        if ($upstream -ne $currentBranch -and (Test-ContinuousCoReviewGitRefExists -RepoRoot $RepoRoot -Ref $upstream)) {
            return & $mk $true $upstream 'branch-upstream' ''
        }
    }

    # 4. Existing CONVENTIONAL refs (priority order), local then origin/, excluding the current branch.
    foreach ($c in @('main', 'master', 'develop', 'dev')) {
        if ($c -eq $currentBranch) { continue }
        if (Test-ContinuousCoReviewGitRefExists -RepoRoot $RepoRoot -Ref $c) { return & $mk $true $c 'conventional-ref' '' }
        if (Test-ContinuousCoReviewGitRefExists -RepoRoot $RepoRoot -Ref "origin/$c") { return & $mk $true "origin/$c" 'conventional-ref' '' }
    }

    # 5. LOCAL-ONLY repo with exactly ONE pre-feature branch.
    $remotes = @((Invoke-ContinuousCoReviewTrunkGit -RepoRoot $RepoRoot -Arguments @('remote')).lines)
    if ($remotes.Count -eq 0) {
        $branches = @((Invoke-ContinuousCoReviewTrunkGit -RepoRoot $RepoRoot -Arguments @('branch', '--format=%(refname:short)')).lines)
        $others = @($branches | Where-Object { $_ -ne $currentBranch })
        if ($others.Count -eq 1) { return & $mk $true $others[0] 'single-pre-feature-branch' '' }
        if ($others.Count -eq 0) {
            return & $mk $true $null 'greenfield' 'The repository has only the feature branch (no trunk); the co-review baseline is the empty tree.'
        }
        # multiple pre-feature branches, none conventional -> ambiguous (fall through).
    }

    # 6. AMBIGUOUS -> fail with a clear configuration instruction (never guess, never move a branch).
    return & $mk $false $null 'ambiguous' "Could not unambiguously determine the trunk branch for '$RepoRoot'. Set 'co_review_trunk: <branch>' in .specrew/config.yml, or configure origin/HEAD or a branch upstream. Specrew never creates, renames, or moves a branch to resolve this."
}
