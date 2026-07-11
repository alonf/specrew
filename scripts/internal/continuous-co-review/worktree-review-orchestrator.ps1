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
    # Auto-resolve the design context: the feature's spec.md + the latest iteration's design-analysis.md.
    # Sources, in order (f1 fix, codex finding 2026-07-08): (1) .specify/feature.json (fast, but
    # GITIGNORED machine-local state - a fresh clone lacks it), (2) .specrew/start-context.json
    # session_state (the durable lifecycle pointer), (3) a single specs/*/spec.md directory when
    # unambiguous. Returns project-relative paths (or @() if genuinely unresolved - the CALLER now
    # records + degrades an empty resolution instead of silently reviewing blind).
    param([Parameter(Mandatory)][string]$RepoRoot)
    $out = New-Object System.Collections.Generic.List[string]
    $featureDir = $null
    $fj = Join-Path $RepoRoot '.specify/feature.json'
    if (Test-Path -LiteralPath $fj -PathType Leaf) {
        try { $featureDir = ([string]((Get-Content $fj -Raw -Encoding UTF8 | ConvertFrom-Json).feature_directory)).Replace('\', '/').TrimEnd('/') } catch { $featureDir = $null }
    }
    if ([string]::IsNullOrWhiteSpace($featureDir)) {
        # Durable fallback: the lifecycle start-context names the active feature.
        try {
            $scPath = Join-Path $RepoRoot '.specrew/start-context.json'
            if (Test-Path -LiteralPath $scPath -PathType Leaf) {
                $sc = Get-Content -LiteralPath $scPath -Raw -Encoding UTF8 | ConvertFrom-Json
                if ($sc.PSObject.Properties['session_state'] -and $null -ne $sc.session_state) {
                    $ref = if ($sc.session_state.PSObject.Properties['feature_ref']) { [string]$sc.session_state.feature_ref } else { '' }
                    if (-not [string]::IsNullOrWhiteSpace($ref) -and (Test-Path -LiteralPath (Join-Path $RepoRoot (Join-Path 'specs' $ref)) -PathType Container)) {
                        $featureDir = ('specs/' + $ref)
                    }
                }
            }
        }
        catch { $null = $_ }
    }
    if ([string]::IsNullOrWhiteSpace($featureDir)) {
        # Last resort: a SINGLE unambiguous specs/*/spec.md (multi-feature repos stay unresolved).
        try {
            $specDirs = @(Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'specs') -Directory -ErrorAction Stop | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'spec.md') -PathType Leaf })
            if ($specDirs.Count -eq 1) { $featureDir = ('specs/' + $specDirs[0].Name) }
        }
        catch { $null = $_ }
    }
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
    param([Parameter(Mandatory)][string]$RepoRoot, [string]$CodeWriterHost, [string]$RequestedHost)
    # F-198 FR-023: when no explicit code-writer host was passed, resolve it from the session
    # env the same way --list-hosts does (SPECREW_HOST -> SPECREW_ACTIVE_HOST) and RECORD the
    # provenance: an env-derived independence label is the session's own declaration, not a
    # human assertion, and the audit trail must distinguish them (independence_source:
    # flag | env | unverified; the fail-closed treatment of 'unverified' is unchanged).
    $codeWriterSource = 'unverified'
    if (-not [string]::IsNullOrWhiteSpace($CodeWriterHost)) { $codeWriterSource = 'flag' }
    elseif (-not [string]::IsNullOrWhiteSpace($env:SPECREW_HOST)) { $CodeWriterHost = $env:SPECREW_HOST; $codeWriterSource = 'env' }
    elseif (-not [string]::IsNullOrWhiteSpace($env:SPECREW_ACTIVE_HOST)) { $CodeWriterHost = $env:SPECREW_ACTIVE_HOST; $codeWriterSource = 'env' }
    if (-not (Get-Command 'Select-ContinuousCoReviewReviewerCandidate' -ErrorAction SilentlyContinue)) {
        $loadPath = Join-Path $PSScriptRoot '_load.ps1'
        if (Test-Path -LiteralPath $loadPath -PathType Leaf) { try { . $loadPath } catch { $null = $_ } }
    }
    if (-not (Get-Command 'Get-ContinuousCoReviewReviewerHostCatalog' -ErrorAction SilentlyContinue) -or -not (Get-Command 'Select-ContinuousCoReviewReviewerCandidate' -ErrorAction SilentlyContinue)) { return $null }
    try {
        # Same load path as the legacy navigator (continuous-co-review-navigator.ps1:849-865): the persisted
        # human-authorized config -> catalog -> independent+authorized candidate. T093: an explicit
        # -RequestedHost restricts the selection (honour-or-surface); the returned independence label
        # ('independent' | 'same-host' | 'unverified') is the D4 gate's evidence dimension.
        $reviewerConfig = $null
        $reviewerHostsPath = Join-Path $RepoRoot '.specrew/reviewer-hosts.json'
        if (Test-Path -LiteralPath $reviewerHostsPath -PathType Leaf) {
            try { $reviewerConfig = (Get-Content -LiteralPath $reviewerHostsPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 100) } catch { $reviewerConfig = $null }
        }
        $catalog = Get-ContinuousCoReviewReviewerHostCatalog -Configuration $reviewerConfig
        $cand = Select-ContinuousCoReviewReviewerCandidate -Catalog $catalog -CodeWriterHost $CodeWriterHost -RequestedHost $RequestedHost
        if ($null -eq $cand -or [string]::IsNullOrWhiteSpace([string]$cand.host)) { return $null }
        $indep = if ($cand.PSObject.Properties['independence']) { [string]$cand.independence } else { 'unverified' }
        $selReason = if ($cand.PSObject.Properties['selection_reason']) { [string]$cand.selection_reason } else { '' }
        return [pscustomobject]@{ host = [string]$cand.host; model = [string]$cand.model; independence = $indep; selection_reason = $selReason; independence_source = $codeWriterSource }
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
        # T096/FR-038: PRESERVE an un-consumed remediation choice across the per-run rewrite (the
        # human may record it between runs; only the consumer clears it). T020/FR-019: likewise
        # PRESERVE the resolved-against-disk disposition trail - it is the durable record the halt
        # text reads to show resolved-vs-open, and it must not be wiped by a per-run status write.
        $remediation = $null
        $dispositions = @()
        try {
            if (Test-Path -LiteralPath $p -PathType Leaf) {
                $prior = Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json
                if ($null -ne $prior -and ($prior.PSObject.Properties.Name -contains 'remediation')) { $remediation = $prior.remediation }
                if ($null -ne $prior -and ($prior.PSObject.Properties.Name -contains 'dispositions') -and $null -ne $prior.dispositions) { $dispositions = @($prior.dispositions) }
            }
        }
        catch { $remediation = $null; $dispositions = @() }
        ([pscustomobject]@{ changed_paths = @($ChangedPaths); round = $Round; blocking = $Blocking; findings = $Findings; remediation = $remediation; dispositions = $dispositions } | ConvertTo-Json -Depth 8 -Compress) | Set-Content -LiteralPath $p -Encoding UTF8
    }
    catch { $null = $_ }
}

function Add-ContinuousCoReviewRoundDisposition {
    # T020 (FR-019): append a disposition (e.g. a failed-invocation record) to the round-state trail
    # WITHOUT disturbing the round/blocking/findings fields. The trail is the durable accounting record
    # the halt text and audits read - a failed invocation never disappears from it.
    param([Parameter(Mandatory)][string]$RepoRoot, [Parameter(Mandatory)][object]$Disposition)
    $resolved = (Resolve-Path -LiteralPath $RepoRoot).Path
    $p = Get-ContinuousCoReviewRoundStatePath -RepoRoot $resolved
    $state = Get-ContinuousCoReviewRoundState -RepoRoot $resolved
    if ($null -eq $state) { $state = [pscustomobject]@{ changed_paths = @(); round = 0; blocking = $false; findings = $null; remediation = $null; dispositions = @() } }
    $disp = @()
    if (($state.PSObject.Properties.Name -contains 'dispositions') -and $null -ne $state.dispositions) { $disp = @($state.dispositions) }
    $disp += $Disposition
    $state | Add-Member -NotePropertyName 'dispositions' -NotePropertyValue $disp -Force
    ($state | ConvertTo-Json -Depth 8 -Compress) | Set-Content -LiteralPath $p -Encoding UTF8
    return $Disposition
}

function Get-ContinuousCoReviewRoundSpendClass {
    # T020 (F-198 FR-018/FR-019, before-implement send-back): separate the TWO budgets a review run
    # touches - PROVIDER SPEND (actual model/API cost) and the REVIEW-ROUND ALLOWANCE (the autonomous
    # ceiling). Classifies one run outcome:
    #   'preflight-failed'   -> a required input (e.g. .review/changes.diff) was missing BEFORE the
    #                           model was invoked: an INFRASTRUCTURE failure that consumes NEITHER
    #                           provider budget NOR a round-allowance slot (it prevented the wasteful
    #                           invocation the field da2bc5cc round suffered).
    #   'invoked-reviewed'   -> the model was invoked and produced a review: provider spend recorded,
    #                           the round counts.
    #   'invoked-failed'     -> the model WAS invoked but produced no valid review: provider spend IS
    #                           recorded (real cost), AND the round counts with a failed-invocation
    #                           disposition - it never disappears from accounting.
    # Returns @{ class; consumes_round; records_provider_spend; reason }.
    param(
        [Parameter(Mandatory)][bool]$InputMaterialized,
        [Parameter(Mandatory)][bool]$ModelInvoked,
        [Parameter(Mandatory)][bool]$ProducedReview
    )
    if (-not $InputMaterialized -and -not $ModelInvoked) {
        return [pscustomobject]@{ class = 'preflight-failed'; consumes_round = $false; records_provider_spend = $false; reason = 'required review input was not materialized; the model was never invoked (infrastructure failure)' }
    }
    if ($ModelInvoked -and $ProducedReview) {
        return [pscustomobject]@{ class = 'invoked-reviewed'; consumes_round = $true; records_provider_spend = $true; reason = 'the reviewer was invoked and produced a review' }
    }
    if ($ModelInvoked -and -not $ProducedReview) {
        return [pscustomobject]@{ class = 'invoked-failed'; consumes_round = $true; records_provider_spend = $true; reason = 'the reviewer was invoked but produced no valid review (provider spend still incurred; the round is counted with a failed-invocation disposition)' }
    }
    # Input materialized but the model was (intentionally) not invoked, and no review: treat as a
    # preflight-class no-op that consumes neither (defensive; no spend occurred).
    return [pscustomobject]@{ class = 'preflight-failed'; consumes_round = $false; records_provider_spend = $false; reason = 'the model was not invoked; no provider spend or round consumed' }
}

function Set-ContinuousCoReviewFindingResolvedAgainstDisk {
    # T020 (F-198 FR-018/FR-019): a RESOLVED-AGAINST-DISK disposition. When a held blocking finding
    # has been FIXED and the fix is committed IN THE REVIEWED LINEAGE (an ancestor of HEAD), this
    # records the resolution and CLEARS the sticky blocking round-state + resets the round + the
    # change-set lineage - so the finding can NEITHER re-escalate NOR keep consuming the round
    # allowance. The four field incidents (self-leak c894a74b/970a8d7c, FR-020 efbbb98d/e4e88cb0)
    # were exactly this: a fixed finding whose file-overlap kept climbing the ceiling. This is NOT
    # override-block (which waves a DEGRADED block through): the finding is genuinely resolved, so a
    # fix-evidence commit that is an ANCESTOR OF HEAD is REQUIRED - an unverifiable/absent ref is
    # refused, so a bare 'resolved' claim can never clear the latch (no false-green door). The rounds
    # already spent stay recorded in the disposition trail; only FUTURE consumption on this resolved
    # finding is stopped.
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$FixEvidenceRef,
        [string]$AuthorizedBy,
        [datetime]$Now = [datetime]::UtcNow
    )
    $resolved = (Resolve-Path -LiteralPath $RepoRoot).Path
    $commit = (& git -C $resolved rev-parse --verify "$FixEvidenceRef^{commit}" 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($commit)) {
        throw "resolved-against-disk needs a real fix-evidence commit; '$FixEvidenceRef' does not resolve to a commit (a bare 'resolved' claim cannot clear the review latch)."
    }
    $commit = $commit.Trim()
    & git -C $resolved merge-base --is-ancestor $commit HEAD 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "resolved-against-disk fix evidence '$FixEvidenceRef' is not an ancestor of HEAD: the fix is not in the reviewed tree, so the finding is NOT resolved-against-disk."
    }
    $prior = Get-ContinuousCoReviewRoundState -RepoRoot $resolved
    if ($null -eq $prior) { return $null }   # nothing latched to resolve
    if ([string]::IsNullOrWhiteSpace($AuthorizedBy)) {
        $AuthorizedBy = (& git -C $resolved config user.name 2>$null)
        if ([string]::IsNullOrWhiteSpace([string]$AuthorizedBy)) { $AuthorizedBy = 'human' }
    }
    $findingId = ''
    try { $findingId = [string](($prior.findings | ConvertFrom-Json).findings[0].finding_id) } catch { $findingId = '' }
    $disposition = [pscustomobject][ordered]@{
        state                          = 'resolved-against-disk'
        finding_id                     = $findingId
        fix_evidence_ref               = $commit
        authorized_by                  = ([string]$AuthorizedBy).Trim()
        recorded_at                    = $Now.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ', [System.Globalization.CultureInfo]::InvariantCulture)
        rounds_spent_before_resolution = [int]$prior.round
    }
    $dispositions = @()
    if (($prior.PSObject.Properties.Name -contains 'dispositions') -and $null -ne $prior.dispositions) { $dispositions = @($prior.dispositions) }
    $dispositions += $disposition
    # Clear the latch: blocking=false, round=0, lineage reset - the resolved finding no longer climbs
    # the ceiling nor re-surfaces. The remediation carrier and the (now-appended) disposition trail
    # are preserved.
    $p = Get-ContinuousCoReviewRoundStatePath -RepoRoot $resolved
    $remediation = if (($prior.PSObject.Properties.Name -contains 'remediation')) { $prior.remediation } else { $null }
    ([pscustomobject][ordered]@{ changed_paths = @(); round = 0; blocking = $false; findings = $null; remediation = $remediation; dispositions = $dispositions } | ConvertTo-Json -Depth 8 -Compress) | Set-Content -LiteralPath $p -Encoding UTF8
    return $disposition
}

function Set-ContinuousCoReviewRemediationChoice {
    <#
        T096/FR-038 (iter-009 D6/R6): record the human's remediation choice onto the round-state so
        the NEXT run applies it (the menu's carrier). Choices:
          more-time (+TimeoutSeconds) | different-host (+HostName) | narrow-scope (+Scope) |
          accept-partial (+RunId +Reason: records the T094 degraded ack immediately) |
          override-block (+RunId +Reason: D5 - only a DEGRADED run's block is overridable).
        TRUST BOUNDARY: construct only from a genuinely human-typed command
        (`specrew review --remediate ...`) or a captured human verdict.
    #>
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][ValidateSet('more-time', 'different-host', 'narrow-scope', 'accept-partial', 'override-block', 'resolved-against-disk')][string]$Choice,
        [int]$TimeoutSeconds = 0,
        [string]$HostName,
        [string]$Scope,
        [string]$RunId,
        [string]$Reason,
        [string]$FixEvidenceRef,
        [string]$AuthorizedBy,
        [datetime]$Now = [datetime]::UtcNow
    )
    $resolved = (Resolve-Path -LiteralPath $RepoRoot).Path
    if ([string]::IsNullOrWhiteSpace($AuthorizedBy)) {
        $AuthorizedBy = (& git -C $resolved config user.name 2>$null)
        if ([string]::IsNullOrWhiteSpace([string]$AuthorizedBy)) { $AuthorizedBy = [string]$env:USERNAME }
        if ([string]::IsNullOrWhiteSpace([string]$AuthorizedBy)) { $AuthorizedBy = 'human' }
    }
    $AuthorizedBy = ([string]$AuthorizedBy).Trim()

    switch ($Choice) {
        'different-host' { if ([string]::IsNullOrWhiteSpace($HostName)) { throw "remediation 'different-host' needs --host <name>." } }
        'narrow-scope' {
            if ([string]::IsNullOrWhiteSpace($Scope)) { throw "remediation 'narrow-scope' needs --scope <code|process|path:<p>|function:<name>>." }
            if ($Scope -notmatch '^(code|process|path:.+|function:.+)$') { throw "remediation scope '$Scope' is not one of code | process | path:<p> | function:<name>." }
        }
        'accept-partial' {
            if ([string]::IsNullOrWhiteSpace($RunId) -or [string]::IsNullOrWhiteSpace($Reason)) { throw "remediation 'accept-partial' needs --run-id <id> and --ack-reason '<why>'." }
            # Accepting the partial IS the T094 first-class ack - record it immediately (no rerun).
            if (-not (Get-Command -Name 'Add-ContinuousCoReviewDegradedAck' -ErrorAction SilentlyContinue)) {
                $lp = Join-Path $PSScriptRoot '_load.ps1'; if (Test-Path -LiteralPath $lp -PathType Leaf) { . $lp }
            }
            $null = Add-ContinuousCoReviewDegradedAck -RepoRoot $resolved -RunId $RunId -AuthorizedBy $AuthorizedBy -Rationale $Reason -Now $Now
        }
        'override-block' {
            if ([string]::IsNullOrWhiteSpace($RunId) -or [string]::IsNullOrWhiteSpace($Reason)) { throw "remediation 'override-block' needs --run-id <id> and --ack-reason '<why>'." }
            # D5: ONLY a DEGRADED run's block is overridable - a full+independent review's blocking
            # finding must be addressed, not waved through. Verify from the run's terminal status.
            $rdir = Join-Path $resolved ".specrew/review/pending/$RunId"
            $stPath = Join-Path $rdir 'status.json'
            $labels = $null
            if (Test-Path -LiteralPath $stPath -PathType Leaf) {
                try {
                    $st = Get-Content -LiteralPath $stPath -Raw -Encoding UTF8 | ConvertFrom-Json
                    $comp = if (($st.PSObject.Properties.Name -contains 'completeness') -and -not [string]::IsNullOrWhiteSpace([string]$st.completeness)) { [string]$st.completeness } else { 'full' }
                    $indep = if (($st.PSObject.Properties.Name -contains 'reviewer_independence') -and -not [string]::IsNullOrWhiteSpace([string]$st.reviewer_independence)) { [string]$st.reviewer_independence } else { 'unverified' }
                    $labels = [pscustomobject]@{ completeness = $comp; independence = $indep }
                }
                catch { $labels = $null }
            }
            if ($null -eq $labels) { throw "remediation 'override-block': run '$RunId' has no readable terminal status - cannot verify the review was degraded, so its block is NOT overridable (address the finding or re-run)." }
            if ($labels.completeness -eq 'full' -and $labels.independence -eq 'independent') {
                throw "remediation 'override-block': run '$RunId' was a FULL INDEPENDENT review - its blocking finding must be addressed (or re-reviewed), never overridden (D5 allows overriding DEGRADED blocks only)."
            }
            # Record the durable override + clear the sticky blocking round-state so the loop unblocks.
            $ovDir = Join-Path $resolved ".specrew/review/inline/$RunId"
            New-Item -ItemType Directory -Path $ovDir -Force | Out-Null
            ([pscustomobject][ordered]@{
                schema_version = '1.0'; run_id = $RunId; authorized_by = $AuthorizedBy; rationale = $Reason
                evidence_labels = $labels
                overridden_at = $Now.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ', [System.Globalization.CultureInfo]::InvariantCulture)
            } | ConvertTo-Json -Depth 8) | Set-Content -LiteralPath (Join-Path $ovDir 'degraded-block-override.json') -Encoding UTF8 -NoNewline
            $prior = Get-ContinuousCoReviewRoundState -RepoRoot $resolved
            if ($null -ne $prior) {
                Set-ContinuousCoReviewRoundState -RepoRoot $resolved -ChangedPaths @($prior.changed_paths) -Round ([int]$prior.round) -Blocking $false -Findings ([string]$prior.findings)
            }
        }
        'resolved-against-disk' {
            # T020: the held blocking finding has been FIXED and the fix is committed IN HEAD's
            # lineage. Distinct from override-block (which waves a DEGRADED block through): this
            # requires committed fix evidence (an ancestor of HEAD) and clears the latch + resets the
            # round so the resolved finding can neither re-escalate nor keep consuming the allowance.
            if ([string]::IsNullOrWhiteSpace($FixEvidenceRef)) { throw "remediation 'resolved-against-disk' needs --fix-evidence-ref <commit> (the commit that resolves the finding)." }
            $null = Set-ContinuousCoReviewFindingResolvedAgainstDisk -RepoRoot $resolved -FixEvidenceRef $FixEvidenceRef -AuthorizedBy $AuthorizedBy -Now $Now
        }
    }

    $remediation = [pscustomobject][ordered]@{
        choice          = $Choice
        timeout_seconds = if ($TimeoutSeconds -gt 0) { $TimeoutSeconds } else { $null }
        host            = if ([string]::IsNullOrWhiteSpace($HostName)) { $null } else { $HostName }
        scope           = if ([string]::IsNullOrWhiteSpace($Scope)) { $null } else { $Scope }
        run_id          = if ([string]::IsNullOrWhiteSpace($RunId)) { $null } else { $RunId }
        reason          = if ([string]::IsNullOrWhiteSpace($Reason)) { $null } else { $Reason }
        authorized_by   = $AuthorizedBy
        recorded_at     = $Now.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ', [System.Globalization.CultureInfo]::InvariantCulture)
    }
    # accept-partial / override-block act immediately (above); the rerun-shaping choices ride the
    # round-state to the next run.
    if ($Choice -in @('more-time', 'different-host', 'narrow-scope')) {
        $p = Get-ContinuousCoReviewRoundStatePath -RepoRoot $resolved
        $dir = Split-Path -Parent $p; if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $state = Get-ContinuousCoReviewRoundState -RepoRoot $resolved
        if ($null -eq $state) { $state = [pscustomobject]@{ changed_paths = @(); round = 0; blocking = $false; findings = $null } }
        $state | Add-Member -NotePropertyName 'remediation' -NotePropertyValue $remediation -Force
        ($state | ConvertTo-Json -Depth 8 -Compress) | Set-Content -LiteralPath $p -Encoding UTF8
    }
    return $remediation
}

function Read-ContinuousCoReviewRemediationChoice {
    # ONE-SHOT consumer (T096): return the pending remediation (or $null) and CLEAR it from the
    # round-state - a human choice applies to exactly one rerun, never silently forever.
    param([Parameter(Mandatory)][string]$RepoRoot)
    $state = Get-ContinuousCoReviewRoundState -RepoRoot $RepoRoot
    if ($null -eq $state -or -not ($state.PSObject.Properties.Name -contains 'remediation') -or $null -eq $state.remediation) { return $null }
    $choice = $state.remediation
    try {
        $state.remediation = $null
        $p = Get-ContinuousCoReviewRoundStatePath -RepoRoot $RepoRoot
        ($state | ConvertTo-Json -Depth 8 -Compress) | Set-Content -LiteralPath $p -Encoding UTF8
    }
    catch { $null = $_ }
    return $choice
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

function Get-ContinuousCoReviewEvidenceDeclaredCommands {
    # T015 (FR-010) minimal supply, maintainer-directed: ONLY verification commands EXPLICITLY recorded
    # in the digest-matched implementer evidence ALREADY injected into this worktree (the T111 copy -
    # the digest gate is INHERITED: stale or mismatched evidence never reaches the worktree, so it can
    # never supply commands against a different tree). A suite record without a literal non-empty
    # 'command' string supplies NOTHING - commands are never inferred from suite names, discovered by
    # scanning, or defaulted to repository sweeps. Generalized evidence discovery + richer provenance
    # are deferred to 203-W8 (T018).
    param([Parameter(Mandatory)][string]$WorktreePath)
    $p = Join-Path $WorktreePath '.review/implementer-evidence.json'
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { return @() }
    $record = $null
    try { $record = Get-Content -LiteralPath $p -Raw | ConvertFrom-Json } catch { return @() }
    if ($null -eq $record -or -not ($record.PSObject.Properties.Name -contains 'suites')) { return @() }
    $cmds = New-Object 'System.Collections.Generic.List[string]'
    foreach ($s in @($record.suites)) {
        if ($null -eq $s) { continue }
        if (-not ($s.PSObject.Properties.Name -contains 'command')) { continue }
        $c = [string]$s.command
        if ([string]::IsNullOrWhiteSpace($c)) { continue }
        [void]$cmds.Add($c)
    }
    return $cmds.ToArray()
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
        [string]$RequestedHost,
        [int]$TimeoutSeconds = 900,
        # T015 (FR-010): the DECLARED verification commands the orchestrator runs FOR the reviewer through the
        # bounded wrapper (timeout + process-tree kill + byte-capped streaming output + pre/post mutation
        # hash), injecting the HOST-OBSERVED results. Empty = fall back to commands EXPLICITLY recorded in
        # the digest-matched implementer evidence (verbatim, never inferred); no evidence commands either =
        # nothing runs, reported honestly. AllowedOutputPaths exempt only named build/log artifacts from the
        # read-only mutation check.
        [string[]]$DeclaredVerificationCommands = @(),
        [string[]]$VerificationAllowedOutputPaths = @()
    )
    New-Item -ItemType Directory -Path $RunDir -Force | Out-Null
    $resultOut = Join-Path $RunDir 'result.out'
    $statusPath = Join-Path $RunDir 'status.json'
    $startedAt = [datetime]::UtcNow
    $runTimer = [System.Diagnostics.Stopwatch]::StartNew()

    # T096/FR-038 (iter-009 D6/R6): consume a pending human remediation choice (ONE-SHOT) and shape
    # THIS run with it - more time (budget), different host (selection), narrow scope (the reviewer's
    # human-directed scope). accept-partial/override-block acted immediately at record time.
    $remediation = Read-ContinuousCoReviewRemediationChoice -RepoRoot $RepoRoot
    $humanScope = $null
    $remediationApplied = $null
    $designContextEmpty = $false   # set for real at the design-context-resolution phase (f1)
    if ($null -ne $remediation) {
        $remediationApplied = [string]$remediation.choice
        switch ($remediationApplied) {
            'more-time' {
                $req = 0
                try { if (($remediation.PSObject.Properties.Name -contains 'timeout_seconds') -and $null -ne $remediation.timeout_seconds) { $req = [int]$remediation.timeout_seconds } } catch { $req = 0 }
                if ($req -le 0) { $req = $TimeoutSeconds * 2 }
                $TimeoutSeconds = [math]::Max($TimeoutSeconds, $req)
            }
            'different-host' {
                if (($remediation.PSObject.Properties.Name -contains 'host') -and -not [string]::IsNullOrWhiteSpace([string]$remediation.host)) { $RequestedHost = [string]$remediation.host }
            }
            'narrow-scope' {
                if (($remediation.PSObject.Properties.Name -contains 'scope') -and -not [string]::IsNullOrWhiteSpace([string]$remediation.scope)) { $humanScope = [string]$remediation.scope }
            }
        }
    }

    $phaseTimings = [ordered]@{}
    $phaseTimers = @{}
    $currentPhase = 'initializing'
    $softBudgetSeconds = [math]::Max(60, [math]::Min([int]($TimeoutSeconds * 0.35), 300))
    # T092/R2 (FR-034): the generous-budget bump is computed AFTER worktree materialization (once the diff size is
    # known). Tracked here so every status write records the default vs the effective (possibly bumped) budget.
    $budgetDefaultSeconds = $TimeoutSeconds; $budgetBumped = $false
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
            budget_default_seconds = $budgetDefaultSeconds
            budget_bumped = $budgetBumped
            artifacts = [ordered]@{
                run_dir     = $RunDir
                result_out  = $resultOut
                status_json = $statusPath
            }
            remediation_applied = $remediationApplied
            human_scope = $humanScope
            design_context = if ($designContextEmpty) { 'empty' } else { 'resolved' }
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
        # f1 (codex 2026-07-08): an EMPTY design context is RECORDED + DEGRADES the run - never a
        # silent blind review. The reviewer is told (prompt note), status.json carries it, and the
        # done-write forces completeness=partial so the T094 tier demands a human ack for the
        # evidence. Not a terminal failure: a genuinely spec-less repo (greenfield empty-tree
        # baseline) may legitimately review code-only.
        $designContextEmpty = (@($DesignContextFiles).Count -eq 0)
        if ($designContextEmpty) {
            [Console]::Error.WriteLine('[co-review] WARN DESIGN_CONTEXT_EMPTY no spec/design-analysis resolved (.review/design will be empty); the run is labelled partial and the reviewer is told to flag it.')
        }
        & $recordPhaseEnd 'design-context-resolution'

        # SELECT the reviewer host: independent-preferred + authorized, labelled (T093/FR-035). A
        # same-host fallback FIRES immediately (never blocks); the label makes it first-class evidence.
        # Fail-soft (stated reason) if none - and an un-honourable explicit --host is SURFACED, never
        # silently substituted.
        $currentPhase = 'reviewer-host-selection'
        & $recordPhaseStart $currentPhase
        $reviewerHost = Resolve-ContinuousCoReviewReviewerHost -RepoRoot $RepoRoot -CodeWriterHost $CodeWriterHost -RequestedHost $RequestedHost
        & $recordPhaseEnd 'reviewer-host-selection'
        if ($null -eq $reviewerHost) {
            $selFailure = if (-not [string]::IsNullOrWhiteSpace($RequestedHost)) {
                "requested-host-not-available: '$RequestedHost' is not installed+authorized (an explicit --host is honoured or surfaced, never silently substituted)"
            }
            else { 'no-authorized-reviewer-host' }
            & $writeStatus 'failed' @{ failure_reason = $selFailure; requested_reviewer_host = $RequestedHost }
            return (Get-Content $statusPath -Raw | ConvertFrom-Json)
        }
        # Defensive normalization (regression guard): the status writes below read
        # $reviewerHost.independence_source (added by the T012 live-door provenance). A host object
        # that omits it - a legacy/stubbed selector - must NOT crash the orchestrator under
        # StrictMode; default the provenance to 'unverified' (the SEC-004 fail-closed sense).
        if (-not ($reviewerHost.PSObject.Properties.Name -contains 'independence_source')) {
            $reviewerHost | Add-Member -NotePropertyName 'independence_source' -NotePropertyValue 'unverified' -Force
        }

        # The reviewed-state DIGEST = the gate's identity. Get-...SignoffGateDecision compares ITS current digest to a
        # passing run's recorded reviewed_tree_id. Computed BEFORE materialization (identity-unification fix,
        # escalation 20260708T211331029): the worktree is materialized FROM this digest tree, so the reviewed
        # content and the certified content are the SAME git tree object by construction - uncommitted changes
        # are REVIEWED, never silently certified (the FR-025 false-allow the reviewer escalated). Computed over
        # the MAIN repo (the worktree is a bare git-archive extract, NOT a git repo). _load is dot-sourced only
        # inside Resolve-...ReviewerHost's scope, so lazy-load it for THIS scope.
        if (-not (Get-Command -Name 'Get-ContinuousCoReviewReviewedStateDigest' -ErrorAction SilentlyContinue)) {
            $lp = Join-Path $PSScriptRoot '_load.ps1'; if (Test-Path -LiteralPath $lp -PathType Leaf) { try { . $lp } catch { $null = $_ } }
        }
        # SURFACE a digest failure (do not swallow it to ''): an empty digest makes the gate's freshness loop skip the
        # record -> a genuinely clean review blocks as 'stale' with no visible cause. Carry the reason in the status.
        # On digest failure the materialization falls back to HEAD (reviewedDigestErr says why the identities differ).
        $currentPhase = 'reviewed-state-digest'
        & $recordPhaseStart $currentPhase
        $reviewedDigestId = ''; $reviewedDigestErr = ''
        try { $dg = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $RepoRoot; if ($null -ne $dg -and $dg.ok) { $reviewedDigestId = [string]$dg.tree_id } else { $reviewedDigestErr = if ($null -ne $dg) { [string]$dg.failure_reason } else { 'digest-unavailable' } } } catch { $reviewedDigestErr = $_.Exception.Message }
        & $recordPhaseEnd 'reviewed-state-digest'

        $currentPhase = 'worktree-materialization'
        & $recordPhaseStart $currentPhase
        & $writeStatus 'running' @{ baseline_ref = $BaselineRef; reviewer_host = $reviewerHost.host; reviewer_independence = $reviewerHost.independence; independence_source = $reviewerHost.independence_source; reviewer_selection_reason = $reviewerHost.selection_reason; requested_reviewer_host = $RequestedHost }
        $wt = New-ContinuousCoReviewStrippedWorktree -RepoRoot $RepoRoot -BaselineRef $BaselineRef -DesignContextFiles $DesignContextFiles -SourceTreeId $reviewedDigestId
        & $recordPhaseEnd 'worktree-materialization'
        # T092 pre-flight generous-budget bump REVERTED (Issue 1): a 30-min AUTO checkpoint review is wrong - the
        # navigator fires one on every checkpoint, and even fully detached it should be SHORT. The auto path now
        # uses the passed-in budget (the navigator default). The generous budget belongs to manual
        # `specrew review --live` (where the human explicitly waits) and, for the auto path, is superseded by the
        # Phase-2 activity watchdog (kill on inactivity, not a fixed wall). The helpers
        # (Get-ContinuousCoReviewGenerousBudget / Test-ContinuousCoReviewExplicitTimeoutConfigured) + $wt.diff_bytes
        # are retained (unit-tested) for manual-path / Phase-2 reuse.
        # T111 (DEC-197-I010-004): inject the implementer's MACHINE-RECORDED test evidence into the worktree -
        # ONLY on an exact digest match with the tree under review, so the reviewer can substitute the recorded
        # suites for broad re-runs (the budget-death fix). A mismatch or absence injects NOTHING (never wrong
        # evidence); the prompt block is gated on the same flag so the reviewer is never told to trust a file
        # that is not there.
        $implementerEvidencePresent = $false
        try {
            if (Get-Command -Name 'Copy-ContinuousCoReviewImplementerEvidence' -ErrorAction SilentlyContinue) {
                $implementerEvidencePresent = [bool](Copy-ContinuousCoReviewImplementerEvidence -RepoRoot $RepoRoot -WorktreePath $wt.worktree_path -DigestTreeId $reviewedDigestId)
            }
        } catch { $implementerEvidencePresent = $false }
        # T015 (FR-010) bounded-verification account - initialized HERE so every status write can report
        # it honestly (a ceiling-halted or preflight-failed run declares/runs nothing); the actual run
        # happens in the 'bounded-verification' phase below, AFTER the ceiling + preflight guards.
        $verificationResultsPresent = $false
        $verificationSource = 'none'
        $verificationDeclaredCount = 0
        $verificationRunCount = 0
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
            # T096: a HUMAN-DIRECTED rerun (a consumed remediation) is never auto-halted - the round
            # ceiling guards the AUTO loop; the menu is its escape hatch.
            if (($round -gt $maxRounds) -and ($null -eq $remediationApplied)) {
                # CEILING REACHED — do NOT fire another review round (the deterministic spin-stop / round-9 fix: a
                # round>maxRounds guard provably halts the monotonic climb while the change-set overlaps). BUT a halt
                # is NOT a clean pass. The old code wrote an EMPTY result here, so the run read as
                # 'done / 0 findings / clean' and SILENTLY passed an UNREVIEWED increment — the false-green
                # (D-197-I009-010) that fooled a dogfood coordinator into signing off code the reviewer never saw.
                # Instead emit a VISIBLE escalation finding so the run can NEVER be read as clean: kind='escalation'
                # -> Option A parks it as escalated_to_human (the gate does NOT deadlock); severity 'blocking' -> the
                # navigator surfaces a NOT-REVIEWED stop-block. Persist a STICKY round-state (blocking=true) so
                # overlapping checkpoints stay above the ceiling and review stays bounded for THIS path-set (resets
                # when the change-set no longer overlaps). status carries reviewed=false so any consumer reading
                # status.json knows the increment was NOT reviewed. (F-197 iter-009 Option A #2 + D-010 hardening.)
                $currentPhase = 'ceiling-halt'
                & $recordPhaseStart $currentPhase
                $resolvedCount = 0
                if ($null -ne $prior -and ($prior.PSObject.Properties.Name -contains 'dispositions') -and $null -ne $prior.dispositions) {
                    $resolvedCount = @($prior.dispositions | Where-Object { [string]$_.state -eq 'resolved-against-disk' }).Count
                }
                [System.IO.File]::WriteAllText($resultOut, (New-ContinuousCoReviewCeilingEscalationResult -RunId $RunId -Round $round -MaxRounds $maxRounds -ResolvedAgainstDiskCount $resolvedCount))
                Set-ContinuousCoReviewRoundState -RepoRoot $RepoRoot -ChangedPaths @($wt.changed_paths) -Round $round -Blocking $true -Findings $priorFindings
                & $recordPhaseEnd 'ceiling-halt'
                $runTimer.Stop()
                & $writeStatus 'done' @{ baseline_ref = $BaselineRef; changed_count = $wt.changed_count; changed_paths = @($wt.changed_paths); tree_id = $wt.tree_id; reviewed_digest_tree_id = $reviewedDigestId; reviewed_digest_error = $reviewedDigestErr; reviewer_host = $reviewerHost.host; reviewer_independence = $reviewerHost.independence; independence_source = $reviewerHost.independence_source; round = $round; max_rounds = $maxRounds; blocking = $false; ceiling_halted = $true; reviewed = $false }
                return (Get-Content $statusPath -Raw | ConvertFrom-Json)
            }
            # T020 PREFLIGHT (FR-019 two-budget accounting): the review INPUT must be materialized
            # BEFORE the model is invoked. A missing .review/changes.diff is an INFRASTRUCTURE failure
            # (the field da2bc5cc class where the engine did not materialize its own input) - it must
            # consume NEITHER provider budget NOR a round-allowance slot, so we fail HERE without
            # invoking the reviewer and without touching the round-state. Distinct from an invoked
            # failure below (which DID spend and DOES count).
            $changesDiffPath = Join-Path $wt.worktree_path '.review/changes.diff'
            if (-not (Test-Path -LiteralPath $changesDiffPath -PathType Leaf)) {
                $preflightSpend = Get-ContinuousCoReviewRoundSpendClass -InputMaterialized $false -ModelInvoked $false -ProducedReview $false
                $runTimer.Stop()
                & $writeStatus 'failed' @{ failure_reason = 'input-not-materialized'; spend_class = $preflightSpend.class; provider_spend = $preflightSpend.records_provider_spend; round_consumed = $preflightSpend.consumes_round; reviewer_host = $reviewerHost.host; reviewer_independence = $reviewerHost.independence; independence_source = $reviewerHost.independence_source; reviewed = $false }
                return (Get-Content $statusPath -Raw | ConvertFrom-Json)
            }
            # T015 (FR-010): RUN the declared verification commands through the bounded wrapper HERE, on
            # the real orchestrator path (not an unwired helper), and inject the host-OBSERVED results
            # into the worktree so the reviewer consumes engine-observed evidence rather than being told
            # - falsely - that its own shell runs are wrapped. Wrapping is enforceable only where the
            # ORCHESTRATOR controls the run: the spawned reviewer is an agentic host with direct tool
            # access, so its OWN runs are governed by the confinement CONTRACT (T013 isolated snapshot /
            # T014 origin-reference removal - NOT an OS-enforced sandbox) with the T016 detector
            # monitoring and reporting violations; the prompt states that honestly. Placed AFTER the
            # ceiling + preflight guards: a halted or unmaterialized run never spends verification time.
            # SUPPLY (maintainer-directed minimal path): caller-explicit commands win; otherwise ONLY
            # commands EXPLICITLY recorded in the digest-matched implementer evidence (the T111 injection
            # above) are used - VERBATIM. Never inferred from suite names, never discovered by scanning,
            # never a default repository sweep; evidence without literal command strings supplies NOTHING
            # and the status reports that honestly. Generalized evidence discovery + richer provenance
            # stay deferred to 203-W8 (T018).
            $currentPhase = 'bounded-verification'
            & $recordPhaseStart $currentPhase
            $verificationDeclared = @($DeclaredVerificationCommands | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
            if ($verificationDeclared.Count -gt 0) { $verificationSource = 'caller' }
            elseif ($implementerEvidencePresent) {
                $verificationDeclared = @(Get-ContinuousCoReviewEvidenceDeclaredCommands -WorktreePath $wt.worktree_path)
                if ($verificationDeclared.Count -gt 0) { $verificationSource = 'implementer-evidence' }
            }
            # Dedupe (first occurrence wins), then cap: a runaway declared set must not become the
            # budget-death class this feature exists to stop. The cap is VISIBLE: declared vs run counts
            # both land in the status, so a capped set never reads as full coverage.
            $seenCmd = New-Object 'System.Collections.Generic.HashSet[string]'
            $verificationDeclared = @($verificationDeclared | Where-Object { $seenCmd.Add($_) })
            $verificationDeclaredCount = $verificationDeclared.Count
            $verificationToRun = @($verificationDeclared | Select-Object -First 8)
            $verificationInfraError = $null
            if ($verificationToRun.Count -gt 0) {
                try {
                    if (-not (Get-Command -Name 'Invoke-ContinuousCoReviewBoundedVerification' -ErrorAction SilentlyContinue)) {
                        throw 'Invoke-ContinuousCoReviewBoundedVerification is not loaded in this session'
                    }
                    $vres = Invoke-ContinuousCoReviewBoundedVerification -WorktreePath $wt.worktree_path -DeclaredCommands $verificationToRun -AllowedOutputPaths @($VerificationAllowedOutputPaths) -TimeoutSeconds ([math]::Max(30, [math]::Min($TimeoutSeconds, 300)))
                    $vdir = Join-Path $wt.worktree_path '.review/verification'
                    [void][System.IO.Directory]::CreateDirectory($vdir)
                    [System.IO.File]::WriteAllText((Join-Path $vdir 'results.json'), (ConvertTo-Json @($vres) -Depth 6 -AsArray))
                    $verificationRunCount = @($vres).Count
                    $verificationResultsPresent = $true
                }
                catch { $verificationInfraError = [string]$_.Exception.Message }
            }
            & $recordPhaseEnd 'bounded-verification'
            # NEVER-FALSE-GREEN (finding 06cb3c64-2): a DECLARED verification that could not be EXECUTED
            # or RECORDED must not degrade into no-results silence - the reviewer would proceed and could
            # pass a clean review with the declared verification simply absent. Fail the run LOUDLY here,
            # BEFORE the model is invoked: an infrastructure failure of the engine's own runner consumes
            # NEITHER provider budget NOR a round-allowance slot (the T020 preflight class), and the
            # status carries a diagnosable reason. (A command that RUNS and fails - non-zero exit,
            # timeout, mutation - is a RESULT for the reviewer to judge, never this path.)
            if ($null -ne $verificationInfraError) {
                $verifySpend = Get-ContinuousCoReviewRoundSpendClass -InputMaterialized $true -ModelInvoked $false -ProducedReview $false
                $runTimer.Stop()
                & $writeStatus 'failed' @{ failure_reason = 'verification-not-executed'; message = $verificationInfraError; spend_class = $verifySpend.class; provider_spend = $verifySpend.records_provider_spend; round_consumed = $verifySpend.consumes_round; reviewer_host = $reviewerHost.host; reviewer_independence = $reviewerHost.independence; independence_source = $reviewerHost.independence_source; verification_source = $verificationSource; verification_declared_count = $verificationDeclaredCount; verification_run_count = $verificationRunCount; verification_injected = $false; reviewed = $false }
                return (Get-Content $statusPath -Raw | ConvertFrom-Json)
            }
            $currentPhase = 'reviewer-execution'
            & $writeStatus 'running' @{ baseline_ref = $BaselineRef; changed_count = $wt.changed_count; tree_id = $wt.tree_id; reviewed_digest_tree_id = $reviewedDigestId; reviewed_digest_error = $reviewedDigestErr; reviewer_host = $reviewerHost.host; reviewer_independence = $reviewerHost.independence; independence_source = $reviewerHost.independence_source; round = $round; max_rounds = $maxRounds; blocking = $null; implementer_evidence = $implementerEvidencePresent; verification_source = $verificationSource; verification_declared_count = $verificationDeclaredCount; verification_run_count = $verificationRunCount; verification_injected = $verificationResultsPresent }
            & $recordPhaseStart $currentPhase
            $reviewerHeartbeat = {
                param($Telemetry)
                & $writeStatus 'running' @{ baseline_ref = $BaselineRef; changed_count = $wt.changed_count; tree_id = $wt.tree_id; reviewed_digest_tree_id = $reviewedDigestId; reviewed_digest_error = $reviewedDigestErr; reviewer_host = $reviewerHost.host; reviewer_independence = $reviewerHost.independence; independence_source = $reviewerHost.independence_source; round = $round; max_rounds = $maxRounds; blocking = $null; reviewer_telemetry = $Telemetry }
            }
            $r = Invoke-ContinuousCoReviewWorktreeReviewer -WorktreePath $wt.worktree_path -RunId $RunId -HostName $reviewerHost.host -RoundNumber $round -MaxRounds $maxRounds -PriorFindings $priorFindings -TimeoutSeconds $TimeoutSeconds -Heartbeat $reviewerHeartbeat -HumanScope $humanScope -DesignContextEmpty:$designContextEmpty -ImplementerEvidencePresent:$implementerEvidencePresent -VerificationResultsPresent:$verificationResultsPresent
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
            # T096: a human-SCOPED review covered a SUBSET of the increment - its evidence is honestly
            # PARTIAL (the T094 tiered gate then requires the recorded ack, never a silent full pass).
            if (-not [string]::IsNullOrWhiteSpace([string]$humanScope)) { $completeness = 'partial' }
            # f1: a review that ran WITHOUT design context could not validate design conformance -
            # same honest degradation (partial -> the T094 ack tier), never silent full evidence.
            if ($designContextEmpty) { $completeness = 'partial' }
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
                & $writeStatus 'done' @{ baseline_ref = $BaselineRef; changed_count = $wt.changed_count; changed_paths = @($wt.changed_paths); tree_id = $wt.tree_id; reviewed_digest_tree_id = $reviewedDigestId; reviewed_digest_error = $reviewedDigestErr; reviewer_host = $reviewerHost.host; reviewer_independence = $reviewerHost.independence; independence_source = $reviewerHost.independence_source; round = $round; max_rounds = $maxRounds; blocking = $blocking; completeness = $completeness; implementer_evidence = $implementerEvidencePresent; verification_source = $verificationSource; verification_declared_count = $verificationDeclaredCount; verification_run_count = $verificationRunCount; verification_injected = $verificationResultsPresent; reviewer_telemetry = $reviewerTelemetry }
            }
            else {
                $currentPhase = 'write-failure'
                & $recordPhaseStart $currentPhase
                [System.IO.File]::WriteAllText($resultOut, '')
                # STATE the reason: capture exit code + a stderr tail so an unparseable/empty verdict is diagnosable
                # (the agent invocation otherwise drops stderr and the failure is invisible).
                $stderrTail = if (-not [string]::IsNullOrWhiteSpace([string]$r.stderr)) { (([string]$r.stderr) -split "`n" | Where-Object { $_ } | Select-Object -Last 3) -join ' | ' } else { '' }
                # T020 (FR-019): the model WAS invoked (provider spend incurred) but produced no valid
                # review. Two-budget accounting: record provider spend AND consume a round-allowance slot
                # with a distinct failed-invocation disposition - it never disappears from accounting.
                # The prior blocking/findings are PRESERVED (a failed invocation reviewed nothing, so it
                # resolves nothing); the round is recorded as consumed.
                $failedSpend = Get-ContinuousCoReviewRoundSpendClass -InputMaterialized $true -ModelInvoked $true -ProducedReview $false
                $priorBlocking = ($null -ne $prior) -and [bool]$prior.blocking
                $priorFindingsStr = if ($null -ne $prior) { [string]$prior.findings } else { $null }
                Set-ContinuousCoReviewRoundState -RepoRoot $RepoRoot -ChangedPaths @($wt.changed_paths) -Round $round -Blocking $priorBlocking -Findings $priorFindingsStr
                $null = Add-ContinuousCoReviewRoundDisposition -RepoRoot $RepoRoot -Disposition ([pscustomobject][ordered]@{ state = 'failed-invocation'; run_id = $RunId; round = $round; provider_spend = $true; recorded_at = (ConvertTo-ContinuousCoReviewWorktreeIsoTimestamp) })
                & $recordPhaseEnd 'write-failure'
                $currentPhase = 'failed'
                $runTimer.Stop()
                & $writeStatus 'failed' @{ failure_reason = 'no-parseable-findings-json'; spend_class = $failedSpend.class; provider_spend = $failedSpend.records_provider_spend; round_consumed = $failedSpend.consumes_round; exit_code = $r.exit_code; stderr_tail = $stderrTail; reviewer_independence = $reviewerHost.independence; independence_source = $reviewerHost.independence_source; verification_source = $verificationSource; verification_declared_count = $verificationDeclaredCount; verification_run_count = $verificationRunCount; verification_injected = $verificationResultsPresent; reviewer_telemetry = $reviewerTelemetry }
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
