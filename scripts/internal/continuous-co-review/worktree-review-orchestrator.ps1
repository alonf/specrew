$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# iter-008 — the detached "prepare+review" orchestrator. Auto-resolves the inputs (merge-base baseline + design
# context), runs the worktree-reviewer pipeline, and writes a REAP-CONSUMABLE result (result.out = FindingsResult
# JSON, status.json = terminal status) under a run dir, then disposes the ephemeral worktree. BOTH doors — the
# navigator's fast Stop-trigger AND /specrew-review — drive THIS one pipeline (G1/G3 close here). All heavy work
# lives here, off the 20s Stop budget. See specs/197-continuous-co-review/iterations/008/design-analysis.md.

. (Join-Path $PSScriptRoot 'worktree-reviewer.ps1')

function ConvertTo-ContinuousCoReviewWorktreeIsoTimestamp {
    param([datetime]$Timestamp = [datetime]::UtcNow)
    return $Timestamp.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ', [System.Globalization.CultureInfo]::InvariantCulture)
}

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
    $mb = $null
    if ($Trunk) { $mb = (& git -C $gitRoot merge-base HEAD $Trunk 2>$null); if ($LASTEXITCODE -ne 0) { $mb = $null } }
    if ([string]::IsNullOrWhiteSpace($mb)) {
        # No trunk (a GREENFIELD: `specrew init` creates ONLY the feature branch - no main/master/remote) OR no
        # merge-base (unrelated histories): fall back to the EMPTY TREE so the co-review reviews the whole feature's
        # source instead of failing 'baseline-unresolved' and never running. This was the root cause of the first real
        # e2e producing zero co-review evidence. The strip/digest list still excludes .specrew/.specify machinery from
        # what the reviewer sees, so the empty-tree baseline reviews source only, not scaffolding.
        return '4b825dc642cb6eb9a060e54bf8d69288fbee4904'
    }
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
    # Surface the FORMAL contracts (JSON Schema / OpenAPI / proto / Avro / GraphQL) - the AUTHORITY for machine
    # formats (casing, field names, types, enums). spec.md + design-analysis are PROSE and describe intent
    # informally; without the contract the reviewer would rule conformance from the narrative and can confidently
    # contradict the real schema (the curation-steers-the-reviewer failure the worktree pivot was meant to escape).
    $contractsDir = Join-Path $RepoRoot (Join-Path $featureDir 'contracts')
    if (Test-Path -LiteralPath $contractsDir -PathType Container) {
        foreach ($cf in @(Get-ChildItem -LiteralPath $contractsDir -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Extension -match '(?i)^\.(json|ya?ml|proto|graphql|avsc|xsd)$' })) {
            [void]$out.Add(([System.IO.Path]::GetRelativePath($RepoRoot, $cf.FullName)).Replace('\', '/'))
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

function Get-ContinuousCoReviewMaxRounds {
    # co_review_max_rounds (config, default 2). The review->fix->re-review ceiling before escalation.
    param([Parameter(Mandatory)][string]$RepoRoot)
    $cfg = Join-Path $RepoRoot '.specrew/config.yml'
    if (Test-Path -LiteralPath $cfg -PathType Leaf) {
        foreach ($line in (Get-Content -LiteralPath $cfg -Encoding UTF8)) {
            if ($line -match '^\s*co_review_max_rounds\s*:\s*(\d+)') { $n = [int]$Matches[1]; if ($n -ge 1) { return $n } }
        }
    }
    return 2
}

function Get-ContinuousCoReviewRoundStatePath { param([Parameter(Mandatory)][string]$RepoRoot) return (Join-Path $RepoRoot '.specrew/runtime/co-review-round-state.json') }

function Get-ContinuousCoReviewRoundState {
    param([Parameter(Mandatory)][string]$RepoRoot)
    $p = Get-ContinuousCoReviewRoundStatePath -RepoRoot $RepoRoot
    if (Test-Path -LiteralPath $p -PathType Leaf) { try { return (Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { return $null } }
    return $null
}

function Set-ContinuousCoReviewRoundState {
    param([Parameter(Mandatory)][string]$RepoRoot, [string[]]$ChangedPaths, [int]$Round, [bool]$Blocking, [string]$Findings)
    $p = Get-ContinuousCoReviewRoundStatePath -RepoRoot $RepoRoot
    try {
        $dir = Split-Path -Parent $p; if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        ([pscustomobject]@{ changed_paths = @($ChangedPaths); round = $Round; blocking = $Blocking; findings = $Findings } | ConvertTo-Json -Depth 8 -Compress) | Set-Content -LiteralPath $p -Encoding UTF8
    }
    catch { $null = $_ }
}

function Test-ContinuousCoReviewPathLineageOverlap {
    # Same review LINEAGE = the current change-set overlaps the prior round's (a fix attempt on the SAME area) -
    # NOT merely "the prior was blocking" (which conflates unrelated checkpoints -> spurious escalation + irrelevant
    # prior findings). Overlap -> increment + thread prior findings; no overlap -> a new checkpoint (round 1).
    param([string[]]$Current, [string[]]$Prior)
    if (-not $Current -or -not $Prior -or @($Current).Count -eq 0 -or @($Prior).Count -eq 0) { return $false }
    $set = [System.Collections.Generic.HashSet[string]]::new([string[]]@($Prior), [System.StringComparer]::OrdinalIgnoreCase)
    foreach ($c in @($Current)) { if ($set.Contains([string]$c)) { return $true } }
    return $false
}

function Get-ContinuousCoReviewFindingsJson {
    # Robustly extract the FindingsResult JSON from a free-form agentic reviewer's stdout. The reviewer is told to
    # output ONLY the JSON, but a non-deterministic agent may narrate AROUND it with prose containing braces
    # (`if (x) { ... }`), so a naive first-brace..last-brace span can capture non-JSON and false-fail the run. Try,
    # in order: a ```json fence, the whole span, then balanced {...} objects scanned from the END (the prompt asks
    # for the JSON last). Accept the first candidate that PARSES and carries a `findings` property (the contract
    # marker). Returns the JSON string, or $null if no valid FindingsResult is present.
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Raw)
    if ([string]::IsNullOrWhiteSpace($Raw)) { return $null }
    $candidates = New-Object System.Collections.Generic.List[string]
    $fence = [regex]::Match($Raw, '(?s)```(?:json)?\s*(\{.*\})\s*```')
    if ($fence.Success) { [void]$candidates.Add($fence.Groups[1].Value) }
    $s = $Raw.IndexOf('{'); $e = $Raw.LastIndexOf('}')
    if ($s -ge 0 -and $e -gt $s) { [void]$candidates.Add($Raw.Substring($s, $e - $s + 1)) }
    for ($i = $Raw.Length - 1; $i -ge 0 -and $candidates.Count -lt 8; $i--) {
        if ($Raw[$i] -ne '}') { continue }
        $depth = 0
        for ($j = $i; $j -ge 0; $j--) {
            if ($Raw[$j] -eq '}') { $depth++ }
            elseif ($Raw[$j] -eq '{') { $depth--; if ($depth -eq 0) { [void]$candidates.Add($Raw.Substring($j, $i - $j + 1)); break } }
        }
    }
    foreach ($cand in $candidates) {
        if ([string]::IsNullOrWhiteSpace($cand)) { continue }
        try { $o = $cand | ConvertFrom-Json -Depth 100; if ($null -ne $o -and $o.PSObject.Properties['findings']) { return $cand } } catch { $null = $_ }
    }
    return $null
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
    $startedAt = [datetime]::UtcNow
    $runTimer = [System.Diagnostics.Stopwatch]::StartNew()
    $phaseTimings = [ordered]@{}
    $phaseTimers = @{}
    $currentPhase = 'initializing'
    $softBudgetSeconds = [math]::Max(60, [math]::Min([int]($TimeoutSeconds * 0.35), 300))
    $budgetPolicy = 'Use implementer validation evidence first. Spend reviewer runtime where it materially changes confidence; targeted reruns are preferred over broad suites unless broad verification is justified by risk.'
    $recordPhaseStart = {
        param([string]$Name)
        if ([string]::IsNullOrWhiteSpace($Name)) { return }
        $phaseTimers[$Name] = [System.Diagnostics.Stopwatch]::StartNew()
    }
    $recordPhaseEnd = {
        param([string]$Name)
        if ([string]::IsNullOrWhiteSpace($Name)) { return }
        if ($phaseTimers.Contains($Name)) {
            $phaseTimers[$Name].Stop()
            $phaseTimings[$Name] = [math]::Round($phaseTimers[$Name].Elapsed.TotalSeconds, 3)
            $phaseTimers.Remove($Name)
        }
    }
    $writeStatus = {
        param([string]$St, [hashtable]$Extra)
        $obj = [ordered]@{
            schema_version = '1.0'
            run_id         = $RunId
            status         = $St
            phase          = $currentPhase
            started_at     = ConvertTo-ContinuousCoReviewWorktreeIsoTimestamp -Timestamp $startedAt
            updated_at     = ConvertTo-ContinuousCoReviewWorktreeIsoTimestamp
            elapsed_seconds = [math]::Round($runTimer.Elapsed.TotalSeconds, 3)
            timeout_seconds = $TimeoutSeconds
            soft_budget_seconds = $softBudgetSeconds
            budget_policy = $budgetPolicy
            artifacts = [ordered]@{
                run_dir     = $RunDir
                result_out  = $resultOut
                status_json = $statusPath
            }
            phase_durations_seconds = [pscustomobject]$phaseTimings
        }
        if ($Extra) { foreach ($k in $Extra.Keys) { $obj[$k] = $Extra[$k] } }
        [System.IO.File]::WriteAllText($statusPath, (([pscustomobject]$obj) | ConvertTo-Json -Depth 8))
    }
    try {
        & $writeStatus 'running' @{ phase = 'initializing' }
        $currentPhase = 'baseline-resolution'
        & $recordPhaseStart $currentPhase
        if ([string]::IsNullOrWhiteSpace($BaselineRef)) { $BaselineRef = Resolve-ContinuousCoReviewWorktreeBaseline -RepoRoot $RepoRoot }
        & $recordPhaseEnd 'baseline-resolution'
        if ([string]::IsNullOrWhiteSpace($BaselineRef)) { & $writeStatus 'failed' @{ failure_reason = 'baseline-unresolved' }; return (Get-Content $statusPath -Raw | ConvertFrom-Json) }
        $currentPhase = 'design-context-resolution'
        & $recordPhaseStart $currentPhase
        if (-not $DesignContextFiles -or @($DesignContextFiles).Count -eq 0) { $DesignContextFiles = @(Resolve-ContinuousCoReviewWorktreeDesignContext -RepoRoot $RepoRoot) }
        & $recordPhaseEnd 'design-context-resolution'

        # SELECT the reviewer host: independent of the code-writer + authorized. Fail-soft (stated reason) if none.
        $currentPhase = 'reviewer-host-selection'
        & $recordPhaseStart $currentPhase
        $reviewerHost = Resolve-ContinuousCoReviewReviewerHost -RepoRoot $RepoRoot -CodeWriterHost $CodeWriterHost
        & $recordPhaseEnd 'reviewer-host-selection'
        if ($null -eq $reviewerHost) { & $writeStatus 'failed' @{ failure_reason = 'no-authorized-reviewer-host' }; return (Get-Content $statusPath -Raw | ConvertFrom-Json) }

        $currentPhase = 'worktree-materialization'
        & $recordPhaseStart $currentPhase
        & $writeStatus 'running' @{ baseline_ref = $BaselineRef; reviewer_host = $reviewerHost.host }
        $wt = New-ContinuousCoReviewStrippedWorktree -RepoRoot $RepoRoot -BaselineRef $BaselineRef -DesignContextFiles $DesignContextFiles
        & $recordPhaseEnd 'worktree-materialization'
        # The reviewed-state DIGEST = the gate's identity. Get-...SignoffGateDecision compares ITS current digest to a
        # passing run's recorded reviewed_tree_id; recording the worktree HEAD-tree instead (the old bug) NEVER matched
        # the gate's working-tree digest, so every promoted pass read 'stale'. Compute it HERE, off the Stop budget,
        # over the MAIN repo (the worktree is a bare git-archive extract, NOT a git repo, so the digest can't run on
        # it). _load is dot-sourced only inside Resolve-...ReviewerHost's scope, so lazy-load it for THIS scope.
        if (-not (Get-Command -Name 'Get-ContinuousCoReviewReviewedStateDigest' -ErrorAction SilentlyContinue)) {
            $lp = Join-Path $PSScriptRoot '_load.ps1'; if (Test-Path -LiteralPath $lp -PathType Leaf) { try { . $lp } catch { $null = $_ } }
        }
        # SURFACE a digest failure (do not swallow it to ''): an empty digest makes the gate's freshness loop skip the
        # record -> a genuinely clean review blocks as 'stale' with no visible cause. Carry the reason in the status.
        $currentPhase = 'reviewed-state-digest'
        & $recordPhaseStart $currentPhase
        $reviewedDigestId = ''; $reviewedDigestErr = ''
        try { $dg = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $RepoRoot; if ($null -ne $dg -and $dg.ok) { $reviewedDigestId = [string]$dg.tree_id } else { $reviewedDigestErr = if ($null -ne $dg) { [string]$dg.failure_reason } else { 'digest-unavailable' } } } catch { $reviewedDigestErr = $_.Exception.Message }
        & $recordPhaseEnd 'reviewed-state-digest'
        # ROUND: same lineage (change-set overlaps the prior round's) + the prior was blocking -> this is a fix
        # re-review (round+1, thread the prior findings); else a new checkpoint (round 1, no prior). The reviewer
        # escalates at the final round (the counter is the safety ceiling).
        $currentPhase = 'round-state-resolution'
        & $recordPhaseStart $currentPhase
        $maxRounds = Get-ContinuousCoReviewMaxRounds -RepoRoot $RepoRoot
        $prior = Get-ContinuousCoReviewRoundState -RepoRoot $RepoRoot
        $round = 1; $priorFindings = $null
        if ($null -ne $prior -and ([bool]$prior.blocking) -and (Test-ContinuousCoReviewPathLineageOverlap -Current @($wt.changed_paths) -Prior @($prior.changed_paths))) {
            $round = [int]$prior.round + 1
            $priorFindings = [string]$prior.findings
        }
        & $recordPhaseEnd 'round-state-resolution'
        try {
            $currentPhase = 'reviewer-execution'
            & $writeStatus 'running' @{ baseline_ref = $BaselineRef; changed_count = $wt.changed_count; tree_id = $wt.tree_id; reviewed_digest_tree_id = $reviewedDigestId; reviewed_digest_error = $reviewedDigestErr; reviewer_host = $reviewerHost.host; round = $round; max_rounds = $maxRounds; blocking = $null }
            & $recordPhaseStart $currentPhase
            $reviewerHeartbeat = {
                param($Telemetry)
                & $writeStatus 'running' @{ baseline_ref = $BaselineRef; changed_count = $wt.changed_count; tree_id = $wt.tree_id; reviewed_digest_tree_id = $reviewedDigestId; reviewed_digest_error = $reviewedDigestErr; reviewer_host = $reviewerHost.host; round = $round; max_rounds = $maxRounds; blocking = $null; reviewer_telemetry = $Telemetry }
            }
            $r = Invoke-ContinuousCoReviewWorktreeReviewer -WorktreePath $wt.worktree_path -RunId $RunId -HostName $reviewerHost.host -RoundNumber $round -MaxRounds $maxRounds -PriorFindings $priorFindings -TimeoutSeconds $TimeoutSeconds -Heartbeat $reviewerHeartbeat
            & $recordPhaseEnd 'reviewer-execution'
            $reviewerTelemetry = if ($r.PSObject.Properties['telemetry']) { $r.telemetry } else { $null }
            $raw = [string]$r.stdout
            $json = Get-ContinuousCoReviewFindingsJson -Raw $raw   # robust: fence -> span -> balanced-scan, validated
            $completeness = 'full'
            if ([string]::IsNullOrWhiteSpace($json)) {
                # T090/R1: the final blob is empty/unparseable (a timeout / cut-short run). HARVEST the incremental
                # .review/findings.jsonl prefix (or prose-salvage) so a degraded review still surfaces findings
                # (any review > nothing), instead of discarding the whole run as 'no-parseable-findings-json'.
                $json = Get-ContinuousCoReviewHarvestedPartialResult -WorktreePath $wt.worktree_path -RawStdout $raw -RunId $RunId
                if (-not [string]::IsNullOrWhiteSpace($json)) { $completeness = 'partial' }
            }
            if (-not [string]::IsNullOrWhiteSpace($json)) {
                $currentPhase = 'write-result'
                & $recordPhaseStart $currentPhase
                [System.IO.File]::WriteAllText($resultOut, $json)
                # detect a blocking finding -> feed the next round's lineage decision
                $blocking = $false
                try { foreach ($f in @(($json | ConvertFrom-Json -Depth 100).findings)) { if (([string]$f.severity) -match '(?i)block') { $blocking = $true; break } } } catch { $null = $_ }
                Set-ContinuousCoReviewRoundState -RepoRoot $RepoRoot -ChangedPaths @($wt.changed_paths) -Round $round -Blocking $blocking -Findings $json
                & $recordPhaseEnd 'write-result'
                $currentPhase = 'complete'
                $runTimer.Stop()
                & $writeStatus 'done' @{ baseline_ref = $BaselineRef; changed_count = $wt.changed_count; changed_paths = @($wt.changed_paths); tree_id = $wt.tree_id; reviewed_digest_tree_id = $reviewedDigestId; reviewed_digest_error = $reviewedDigestErr; reviewer_host = $reviewerHost.host; round = $round; max_rounds = $maxRounds; blocking = $blocking; completeness = $completeness; reviewer_telemetry = $reviewerTelemetry }
            }
            else {
                $currentPhase = 'write-failure'
                & $recordPhaseStart $currentPhase
                [System.IO.File]::WriteAllText($resultOut, '')
                # STATE the reason: capture exit code + a stderr tail so an unparseable/empty verdict is diagnosable
                # (the agent invocation otherwise drops stderr and the failure is invisible).
                $stderrTail = if (-not [string]::IsNullOrWhiteSpace([string]$r.stderr)) { (([string]$r.stderr) -split "`n" | Where-Object { $_ } | Select-Object -Last 3) -join ' | ' } else { '' }
                & $recordPhaseEnd 'write-failure'
                $currentPhase = 'failed'
                $runTimer.Stop()
                & $writeStatus 'failed' @{ failure_reason = 'no-parseable-findings-json'; exit_code = $r.exit_code; stderr_tail = $stderrTail; reviewer_telemetry = $reviewerTelemetry }
            }
        }
        finally {
            $currentPhase = 'cleanup'
            & $recordPhaseStart $currentPhase
            Remove-Item -LiteralPath $wt.worktree_path -Recurse -Force -ErrorAction SilentlyContinue
            & $recordPhaseEnd 'cleanup'
        }
    }
    catch {
        $currentPhase = 'failed'
        $runTimer.Stop()
        & $writeStatus 'failed' @{ failure_reason = 'orchestrator-exception'; message = ([string]$_.Exception.Message) }
    }
    if (Test-Path -LiteralPath $statusPath) { return (Get-Content $statusPath -Raw | ConvertFrom-Json) }
}
