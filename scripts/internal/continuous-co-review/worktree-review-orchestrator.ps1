$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# iter-008 — the detached "prepare+review" orchestrator. Auto-resolves the inputs (merge-base baseline + design
# context), runs the worktree-reviewer pipeline, and writes a REAP-CONSUMABLE result (result.out = FindingsResult
# JSON, status.json = terminal status) under a run dir, then disposes the ephemeral worktree. BOTH doors — the
# navigator's fast Stop-trigger AND /specrew-review — drive THIS one pipeline (G1/G3 close here). All heavy work
# lives here, off the 20s Stop budget. See specs/197-continuous-co-review/iterations/008/design-analysis.md.

. (Join-Path $PSScriptRoot 'worktree-reviewer.ps1')

function Resolve-ContinuousCoReviewTrunkName {
    param([Parameter(Mandatory)][string]$GitRoot)
    $head = (& git -C $GitRoot symbolic-ref --quiet refs/remotes/origin/HEAD 2>$null)
    if ($head) { return ($head.Trim() -replace '^refs/remotes/', '') }
    foreach ($t in @('origin/main', 'origin/dev', 'main', 'dev', 'master')) {
        & git -C $GitRoot rev-parse --verify --quiet "$t^{commit}" 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { return $t }
    }
    return $null
}

function Resolve-ContinuousCoReviewWorktreeBaseline {
    # The review baseline = merge-base with trunk (the user's INCREMENT since branching, not the inception).
    param([Parameter(Mandatory)][string]$RepoRoot, [string]$Trunk)
    $gitRoot = (& git -C $RepoRoot rev-parse --show-toplevel 2>$null).Trim()
    if ([string]::IsNullOrWhiteSpace($gitRoot)) { return $null }
    if (-not $Trunk) { $Trunk = Resolve-ContinuousCoReviewTrunkName -GitRoot $gitRoot }
    if (-not $Trunk) { return $null }
    $mb = (& git -C $gitRoot merge-base HEAD $Trunk 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($mb)) { return $null }
    return ([string]$mb).Trim()
}

function Resolve-ContinuousCoReviewWorktreeDesignContext {
    # Auto-resolve the design context: the feature's spec.md + the latest iteration's design-analysis.md,
    # from .specify/feature.json. Returns project-relative paths (or @() if unresolved). (G1: the manual door
    # no longer needs an explicit --design-context-ref.)
    param([Parameter(Mandatory)][string]$RepoRoot)
    $out = New-Object System.Collections.Generic.List[string]
    $fj = Join-Path $RepoRoot '.specify/feature.json'
    if (-not (Test-Path -LiteralPath $fj -PathType Leaf)) { return @() }
    $featureDir = $null
    try { $featureDir = ([string]((Get-Content $fj -Raw -Encoding UTF8 | ConvertFrom-Json).feature_directory)).Replace('\', '/').TrimEnd('/') } catch { return @() }
    if ([string]::IsNullOrWhiteSpace($featureDir)) { return @() }
    if (Test-Path -LiteralPath (Join-Path $RepoRoot (Join-Path $featureDir 'spec.md')) -PathType Leaf) { [void]$out.Add("$featureDir/spec.md") }
    $iterRoot = Join-Path $RepoRoot (Join-Path $featureDir 'iterations')
    if (Test-Path -LiteralPath $iterRoot -PathType Container) {
        $latest = @(Get-ChildItem -LiteralPath $iterRoot -Directory -EA SilentlyContinue | Where-Object { $_.Name -match '^\d+$' } | Sort-Object { [int]$_.Name } -Descending | Select-Object -First 1)
        if ($latest -and (Test-Path -LiteralPath (Join-Path $latest[0].FullName 'design-analysis.md') -PathType Leaf)) {
            [void]$out.Add(([System.IO.Path]::GetRelativePath($RepoRoot, (Join-Path $latest[0].FullName 'design-analysis.md')).Replace('\', '/')))
        }
    }
    return @($out)
}

function Resolve-ContinuousCoReviewReviewerHost {
    # Select the reviewer host: code-writer-INDEPENDENT + AUTHORIZED (reviewer-hosts.json), via the legacy policy
    # (reused, NOT reinvented). Returns @{ host; model } or $null (no authorized host -> the caller fails-soft with
    # a stated reason). Lazy-loads the CCR engine (_load) if the catalog/policy aren't in scope (the detached path
    # dot-sources only the orchestrator). This is what makes the worktree reviewer host-NEUTRAL + authorized, not
    # claude-pinned.
    param([Parameter(Mandatory)][string]$RepoRoot, [string]$CodeWriterHost)
    if (-not (Get-Command 'Select-ContinuousCoReviewReviewerCandidate' -ErrorAction SilentlyContinue)) {
        $loadPath = Join-Path $PSScriptRoot '_load.ps1'
        if (Test-Path -LiteralPath $loadPath -PathType Leaf) { try { . $loadPath } catch { $null = $_ } }
    }
    if (-not (Get-Command 'Get-ContinuousCoReviewReviewerHostCatalog' -ErrorAction SilentlyContinue) -or -not (Get-Command 'Select-ContinuousCoReviewReviewerCandidate' -ErrorAction SilentlyContinue)) { return $null }
    try {
        # Same load path as the legacy navigator (continuous-co-review-navigator.ps1:849-865): the persisted
        # human-authorized config -> catalog -> independent+authorized candidate.
        $reviewerConfig = $null
        $reviewerHostsPath = Join-Path $RepoRoot '.specrew/reviewer-hosts.json'
        if (Test-Path -LiteralPath $reviewerHostsPath -PathType Leaf) {
            try { $reviewerConfig = (Get-Content -LiteralPath $reviewerHostsPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 100) } catch { $reviewerConfig = $null }
        }
        $catalog = Get-ContinuousCoReviewReviewerHostCatalog -Configuration $reviewerConfig
        $cand = Select-ContinuousCoReviewReviewerCandidate -Catalog $catalog -CodeWriterHost $CodeWriterHost
        if ($null -eq $cand -or [string]::IsNullOrWhiteSpace([string]$cand.host)) { return $null }
        return [pscustomobject]@{ host = [string]$cand.host; model = [string]$cand.model }
    }
    catch { return $null }
}

function Invoke-ContinuousCoReviewWorktreeReviewRun {
    # The full detached run: auto-resolve → materialize stripped worktree + .review/ → agentic review → write a
    # reap-consumable result under $RunDir, then dispose. Returns the terminal status object.
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$RunDir,
        [Parameter(Mandatory)][string]$RunId,
        [string]$BaselineRef,
        [string[]]$DesignContextFiles,
        [string]$CodeWriterHost,
        [int]$TimeoutSeconds = 900
    )
    New-Item -ItemType Directory -Path $RunDir -Force | Out-Null
    $resultOut = Join-Path $RunDir 'result.out'
    $statusPath = Join-Path $RunDir 'status.json'
    $writeStatus = {
        param([string]$St, [hashtable]$Extra)
        $obj = [ordered]@{ schema_version = '1.0'; run_id = $RunId; status = $St }
        if ($Extra) { foreach ($k in $Extra.Keys) { $obj[$k] = $Extra[$k] } }
        [System.IO.File]::WriteAllText($statusPath, (([pscustomobject]$obj) | ConvertTo-Json -Depth 8))
    }
    try {
        if ([string]::IsNullOrWhiteSpace($BaselineRef)) { $BaselineRef = Resolve-ContinuousCoReviewWorktreeBaseline -RepoRoot $RepoRoot }
        if ([string]::IsNullOrWhiteSpace($BaselineRef)) { & $writeStatus 'failed' @{ failure_reason = 'baseline-unresolved' }; return (Get-Content $statusPath -Raw | ConvertFrom-Json) }
        if (-not $DesignContextFiles -or @($DesignContextFiles).Count -eq 0) { $DesignContextFiles = @(Resolve-ContinuousCoReviewWorktreeDesignContext -RepoRoot $RepoRoot) }

        # SELECT the reviewer host: independent of the code-writer + authorized. Fail-soft (stated reason) if none.
        $reviewerHost = Resolve-ContinuousCoReviewReviewerHost -RepoRoot $RepoRoot -CodeWriterHost $CodeWriterHost
        if ($null -eq $reviewerHost) { & $writeStatus 'failed' @{ failure_reason = 'no-authorized-reviewer-host' }; return (Get-Content $statusPath -Raw | ConvertFrom-Json) }

        $wt = New-ContinuousCoReviewStrippedWorktree -RepoRoot $RepoRoot -BaselineRef $BaselineRef -DesignContextFiles $DesignContextFiles
        try {
            $r = Invoke-ContinuousCoReviewWorktreeReviewer -WorktreePath $wt.worktree_path -RunId $RunId -HostName $reviewerHost.host -TimeoutSeconds $TimeoutSeconds
            $raw = [string]$r.stdout
            $s = $raw.IndexOf('{'); $e = $raw.LastIndexOf('}')
            if ($s -ge 0 -and $e -gt $s) {
                $json = $raw.Substring($s, $e - $s + 1)
                $null = $json | ConvertFrom-Json -Depth 100   # validate it parses before declaring done
                [System.IO.File]::WriteAllText($resultOut, $json)
                & $writeStatus 'done' @{ baseline_ref = $BaselineRef; changed_count = $wt.changed_count; tree_id = $wt.tree_id; reviewer_host = $reviewerHost.host }
            }
            else {
                [System.IO.File]::WriteAllText($resultOut, '')
                & $writeStatus 'failed' @{ failure_reason = 'no-findings-json'; exit_code = $r.exit_code }
            }
        }
        finally {
            Remove-Item -LiteralPath $wt.worktree_path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        & $writeStatus 'failed' @{ failure_reason = 'orchestrator-exception'; message = ([string]$_.Exception.Message) }
    }
    if (Test-Path -LiteralPath $statusPath) { return (Get-Content $statusPath -Raw | ConvertFrom-Json) }
}
