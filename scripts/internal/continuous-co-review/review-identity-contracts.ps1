# T019 — review identity, lineage, evidence, and artifact-lifecycle CONTRACTS (characterization slice).
#
# STATUS: the UNWIRED contract layer. Authored 2026-07-13; CONTRACT-CORRECTION pass 2026-07-13 after the
# maintainer's needs-rework review (wiring against the first cut would have encoded stale-authority + cleanup
# defects). Every function here is PURE (no filesystem/git/process I/O, no global state) and NOTHING in the
# shipped runtime calls it yet — it is deliberately NOT added to _load.ps1. Step 6 of T019 ("implement against
# those contracts") wires these decisions into the live navigator / Stop path / orchestrator; that is a SEPARATE
# slice not started. These functions are the executable specification the fixtures assert against.
#
# Corrections applied (maintainer review 2026-07-13):
#  1. baseline_tree_id (the tree the auto-fire diffs advance from = last ACCEPTED reviewed tree) is SEPARATE
#     from commit refs (git ancestry keeps using reviewed_ref/baseline_ref commits).
#  2. digest-mismatch precedence is ABSOLUTE across every outcome: a stale result never blocks, requests a
#     decision, or authorizes a packet.
#  3. finding->run joins FAIL CLOSED: source_run_id must equal run_id, and tree + baseline identities present.
#  4. a transient artifact is prunable ONLY after its owning run is terminal/reaped or explicitly abandoned.
#  5. a deterministic, persisted lineage id + a monotonic authority rule for same-digest concurrent completions.
#  6. injection validates the envelope digest AND every embedded suite/run digest.
#
# Full current->target characterization: iterations/003/research/t019-review-identity-and-artifact-lifecycle.md.

# StrictMode-safe property read: returns the property value or $null when absent.
function Get-ContinuousCoReviewContractProp {
    param([Parameter(Mandatory)]$Object, [Parameter(Mandatory)][string]$Name)
    if ($null -eq $Object) { return $null }
    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) { return $Object[$Name] }
        return $null
    }
    $prop = $Object.PSObject.Properties[$Name]
    if ($null -ne $prop) { return $prop.Value }
    return $null
}

# Reviewed-tree id, tolerating the two shipped spellings (durable run record `reviewed_tree_id`,
# status.json `reviewed_digest_tree_id`). Returns '' when neither is present.
function Get-ContinuousCoReviewRecordReviewedTreeId {
    param([Parameter(Mandatory)]$RunRecord)
    $t = [string](Get-ContinuousCoReviewContractProp -Object $RunRecord -Name 'reviewed_tree_id')
    if ([string]::IsNullOrWhiteSpace($t)) {
        $t = [string](Get-ContinuousCoReviewContractProp -Object $RunRecord -Name 'reviewed_digest_tree_id')
    }
    return $t
}

# ---------------------------------------------------------------------------------------------------
# Correction 1 — AUTO-FIRE BASELINE is a TREE-ID, separate from commit ancestry.
# The next auto-fire diffs advance from the last ACCEPTED reviewed TREE (a tree-id / digest), NOT a commit
# ref. Git ancestry (the lineage chain walk) continues to use commit refs (reviewed_ref / baseline_ref).
# When no accepted run exists, the runtime falls back to the merge-base anchor (a commit ref) — signalled here
# by a null baseline_tree_id so the caller uses the commit-ref path.
function Resolve-ContinuousCoReviewAutoFireBaselineTreeId {
    param([object[]]$AcceptedRuns = @())
    $accepted = @($AcceptedRuns | Where-Object { $null -ne $_ })
    if ($accepted.Count -eq 0) {
        return [pscustomobject]@{ baseline_tree_id = $null; from_run_id = $null; reason = 'no accepted run; fall back to the merge-base anchor (commit ref)' }
    }
    # "last accepted" = the accepted run with the max run_id (run_ids are fire-time-sortable, so this is monotone).
    $last = $accepted | Sort-Object { [string](Get-ContinuousCoReviewContractProp -Object $_ -Name 'run_id') } | Select-Object -Last 1
    return [pscustomobject]@{
        baseline_tree_id = Get-ContinuousCoReviewRecordReviewedTreeId -RunRecord $last
        from_run_id      = [string](Get-ContinuousCoReviewContractProp -Object $last -Name 'run_id')
        reason           = 'auto-fire diffs advance from this last-accepted reviewed TREE; ancestry uses commit refs separately'
    }
}

# Correction 5 (part a) — DETERMINISTIC, persisted lineage id from the STABLE lineage anchor (merge-base
# commit) + target ref, so every run in a lineage computes the same id (the baseline_tree_id advances WITHIN
# a lineage, so it cannot key the lineage; the anchor + target do not).
function Get-ContinuousCoReviewLineageId {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$AnchorRef,
        [Parameter(Mandatory)][AllowEmptyString()][string]$TargetRef
    )
    $material = "$AnchorRef`n$TargetRef"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($material)
    $hash = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::HashData($bytes)).Replace('-', '').ToLowerInvariant()
    return 'lin-' + $hash.Substring(0, 16)
}

# ---------------------------------------------------------------------------------------------------
# Correction 6 — EVIDENCE injection validates the envelope digest AND every embedded suite/run digest.
# An envelope claiming digest X that contains an embedded run/suite stamped digest Y is a surfaced mismatch,
# never injected. DRIFT-198-I003-002: a digest-A record (full OR subset) is never injected into a digest-B
# review; empty digests never match (fail-closed).
function Test-ContinuousCoReviewEvidenceInjectable {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$EnvelopeDigest,
        [Parameter(Mandatory)][AllowEmptyString()][string]$ReviewDigest,
        [string[]]$EmbeddedDigests = @(),
        [switch]$IsSubset
    )
    $envelopeMatch = (-not [string]::IsNullOrWhiteSpace($EnvelopeDigest)) -and ($EnvelopeDigest -ceq $ReviewDigest)
    if (-not $envelopeMatch) {
        $cls = if ($IsSubset) { 'partial-injection-mismatch-surfaced' } else { 'envelope-digest-mismatch-not-injected' }
        return [pscustomobject]@{ injectable = $false; classification = $cls }
    }
    foreach ($d in @($EmbeddedDigests)) {
        if ([string]::IsNullOrWhiteSpace([string]$d) -or ([string]$d -cne $ReviewDigest)) {
            return [pscustomobject]@{ injectable = $false; classification = 'embedded-digest-mismatch-surfaced' }
        }
    }
    return [pscustomobject]@{ injectable = $true; classification = 'exact-digest-injected' }
}

# ---------------------------------------------------------------------------------------------------
# RUN LINEAGE + in-flight dedup. At most ONE tracked in-flight review per lineage; a Stop-fired review that
# finds a running review for its lineage waits/polls it, never launches a duplicate.
function Test-ContinuousCoReviewInFlightDuplicate {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$LineageId,
        [object[]]$InFlightRegistry = @()
    )
    $existing = $null
    foreach ($entry in @($InFlightRegistry)) {
        if ($null -eq $entry) { continue }
        $entryLineage = [string](Get-ContinuousCoReviewContractProp -Object $entry -Name 'lineage_id')
        $entryStatus = [string](Get-ContinuousCoReviewContractProp -Object $entry -Name 'status')
        if (($entryLineage -eq $LineageId) -and ($entryStatus -eq 'running')) { $existing = $entry; break }
    }
    if ($null -ne $existing) {
        return [pscustomobject]@{
            is_duplicate    = $true
            existing_run_id = [string](Get-ContinuousCoReviewContractProp -Object $existing -Name 'run_id')
            launch          = $false
            action          = 'wait-poll-existing'
        }
    }
    return [pscustomobject]@{ is_duplicate = $false; existing_run_id = $null; launch = $true; action = 'launch' }
}

# Pure digest supersession: a completion is authoritative ONLY when its reviewed digest equals the current
# tree. A different digest is superseded (never a fresh block or authorization). Same-digest ties are resolved
# by Resolve-ContinuousCoReviewSameDigestAuthority (correction 5).
function Test-ContinuousCoReviewResultSuperseded {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$CompletingDigest,
        [Parameter(Mandatory)][AllowEmptyString()][string]$CurrentDigest
    )
    $authoritative = (-not [string]::IsNullOrWhiteSpace($CompletingDigest)) -and ($CompletingDigest -ceq $CurrentDigest)
    return [pscustomobject]@{
        authoritative  = $authoritative
        classification = if ($authoritative) { 'current' } else { 'superseded' }
    }
}

# Correction 5 (part b) — MONOTONIC authority for SAME-DIGEST concurrent completions. Among terminal runs whose
# reviewed digest equals the current tree, EXACTLY ONE is authoritative: the max run_id (run_ids are fire-time
# sortable, so authority advances monotonically to the latest assessment of the same tree and never regresses).
# Every other run — wrong digest OR a lower same-digest run_id — is superseded.
function Resolve-ContinuousCoReviewSameDigestAuthority {
    param(
        [object[]]$Runs = @(),
        [Parameter(Mandatory)][AllowEmptyString()][string]$CurrentDigest
    )
    $eligible = @()
    foreach ($r in @($Runs)) {
        if ($null -eq $r) { continue }
        $rd = Get-ContinuousCoReviewRecordReviewedTreeId -RunRecord $r
        $terminal = [bool](Get-ContinuousCoReviewContractProp -Object $r -Name 'terminal')
        if ((-not [string]::IsNullOrWhiteSpace($CurrentDigest)) -and ($rd -ceq $CurrentDigest) -and $terminal) { $eligible += $r }
    }
    if ($eligible.Count -eq 0) {
        return [pscustomobject]@{ authoritative_run_id = $null; superseded_run_ids = @() }
    }
    $sorted = @($eligible | Sort-Object { [string](Get-ContinuousCoReviewContractProp -Object $_ -Name 'run_id') })
    $auth = [string](Get-ContinuousCoReviewContractProp -Object ($sorted | Select-Object -Last 1) -Name 'run_id')
    $superseded = @($sorted | ForEach-Object { [string](Get-ContinuousCoReviewContractProp -Object $_ -Name 'run_id') } | Where-Object { $_ -ne $auth })
    return [pscustomobject]@{ authoritative_run_id = $auth; superseded_run_ids = $superseded }
}

# ---------------------------------------------------------------------------------------------------
# Correction 3 — PER-FINDING identity, FAIL-CLOSED. A finding's global identity is valid ONLY when
# source_run_id EXACTLY equals the run's run_id AND the reviewed tree AND baseline (tree) identities are both
# present. Any violation returns valid=$false with a reason; a mixed run set is separated per-finding only on
# valid joins.
function Get-ContinuousCoReviewFindingIdentity {
    param(
        [Parameter(Mandatory)]$Finding,
        [Parameter(Mandatory)]$RunRecord
    )
    $findingId = [string](Get-ContinuousCoReviewContractProp -Object $Finding -Name 'finding_id')
    $sourceRunId = [string](Get-ContinuousCoReviewContractProp -Object $Finding -Name 'source_run_id')
    $runId = [string](Get-ContinuousCoReviewContractProp -Object $RunRecord -Name 'run_id')
    $reviewedTreeId = Get-ContinuousCoReviewRecordReviewedTreeId -RunRecord $RunRecord
    $baselineTreeId = [string](Get-ContinuousCoReviewContractProp -Object $RunRecord -Name 'baseline_tree_id')

    $reason = $null
    if ([string]::IsNullOrWhiteSpace($sourceRunId) -or [string]::IsNullOrWhiteSpace($runId) -or ($sourceRunId -cne $runId)) {
        $reason = 'source_run_id must equal the run record run_id (fail-closed)'
    }
    elseif ([string]::IsNullOrWhiteSpace($reviewedTreeId)) {
        $reason = 'reviewed tree identity absent (fail-closed)'
    }
    elseif ([string]::IsNullOrWhiteSpace($baselineTreeId)) {
        $reason = 'baseline_tree_id identity absent (fail-closed)'
    }
    return [pscustomobject]@{
        valid            = [string]::IsNullOrEmpty($reason)
        reason           = $reason
        finding_id       = $findingId
        source_run_id    = $sourceRunId
        run_id           = $runId
        reviewed_tree_id = $reviewedTreeId
        baseline_tree_id = $baselineTreeId
        fingerprint      = [string](Get-ContinuousCoReviewContractProp -Object $Finding -Name 'fingerprint')
    }
}

# ---------------------------------------------------------------------------------------------------
# Correction 2 — FR-045 Stop-ordering routing, with ABSOLUTE digest-mismatch precedence. A stale result
# (reviewed digest != current) is superseded for EVERY outcome — it never blocks (actionable), requests a
# decision (human-judgment), reports as a failure to act on, or authorizes a packet (clean). Only a terminal
# result at the EXACT current digest routes by outcome. launch_review is ALWAYS false on the Stop path.
function Resolve-ContinuousCoReviewStopRouting {
    param(
        [Parameter(Mandatory)][bool]$ReviewTerminal,
        [Parameter(Mandatory)][AllowEmptyString()][string]$ReviewOutcome,
        [Parameter(Mandatory)][bool]$DigestMatchesCurrent,
        [bool]$InFlightPresent = $false
    )
    $wait = [pscustomobject]@{ render_packet = $false; render_marker = $false; launch_review = $false; action = 'wait-poll-existing'; capturable_as_verdict = $false }

    # Not terminal (running / duplicate Stop during in-flight): wait, never a packet, never a duplicate.
    if (-not $ReviewTerminal) { return $wait }

    # ABSOLUTE PRECEDENCE: a stale (digest-mismatched) terminal result of ANY outcome is superseded.
    if (-not $DigestMatchesCurrent) {
        $action = if ($InFlightPresent) { 'wait-poll-existing' } else { 're-review-current-digest' }
        return [pscustomobject]@{ render_packet = $false; render_marker = $false; launch_review = $false; action = $action; capturable_as_verdict = $false }
    }

    # Terminal AND at the exact current digest: route by outcome.
    switch ($ReviewOutcome) {
        'clean'          { return [pscustomobject]@{ render_packet = $true;  render_marker = $true;  launch_review = $false; action = 'render-boundary-packet';       capturable_as_verdict = $true } }
        'actionable'     { return [pscustomobject]@{ render_packet = $false; render_marker = $false; launch_review = $false; action = 'fix-and-re-review';            capturable_as_verdict = $false } }
        'human-judgment' { return [pscustomobject]@{ render_packet = $false; render_marker = $false; launch_review = $false; action = 'narrow-non-boundary-question'; capturable_as_verdict = $false } }
        'infra-failure'  { return [pscustomobject]@{ render_packet = $false; render_marker = $false; launch_review = $false; action = 'report-specific-failure';      capturable_as_verdict = $false } }
        default          { return [pscustomobject]@{ render_packet = $false; render_marker = $false; launch_review = $false; action = 'report-specific-failure';      capturable_as_verdict = $false } }
    }
}

# ---------------------------------------------------------------------------------------------------
# ARTIFACT lifecycle classes. Base class is path-static; disposition is digest + run-state driven.
function Get-ContinuousCoReviewArtifactClass {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Path)
    $p = ([string]$Path).Replace('\', '/')
    $mk = {
        param($base, $tracked, $supersedable, $retention)
        [pscustomobject]@{ base_class = $base; git_tracked = $tracked; supersedable = $supersedable; retention = $retention }
    }
    if ($p -match '(^|/)\.specrew/review/pending(/|$)')      { return & $mk 'transient' $false $false 'prunable only after the owning run is terminal/reaped/abandoned' }
    if ($p -match '(^|/)\.specrew/runtime(/|$)')             { return & $mk 'transient' $false $false 'machine-local runtime state; prunable only when its owning cycle/run is terminal' }
    if ($p -match '(^|/)\.review(/|$)')                      { return & $mk 'transient' $false $false 'ephemeral disposable-worktree bundle; prunable only after the run ends' }
    if ($p -match '(^|/)\.specrew/review/inline/')           { return & $mk 'durable'   $true  $true  'retained until superseded by a later reviewed digest for its lineage; then archive or prune per T019 policy' }
    if ($p -match '(^|/)\.specrew/review/test-evidence/')    { return & $mk 'durable'   $true  $true  'retained for its digest; prunable once no live lineage references it (T019 policy)' }
    if ($p -match '(^|/)\.specrew/review/signoff-gate/')     { return & $mk 'durable'   $true  $false 'latest.json overwritten each decision; history/ append-only (not supersedable)' }
    return & $mk 'unknown' $false $false 'unclassified — a contract gap to resolve before it accumulates'
}

# Correction 4 — a durable record resolves to one of the five lifecycle states; a TRANSIENT record is
# prunable ONLY after its owning run is terminal/reaped or explicitly abandoned (never while the run is
# running). The archive-vs-prune WINDOW for obsolete durable records is a T019-owned policy input.
function Resolve-ContinuousCoReviewRecordDisposition {
    param(
        [Parameter(Mandatory)][ValidateSet('transient', 'durable', 'unknown')][string]$BaseClass,
        [bool]$IsLatestForLineage = $true,
        [ValidateSet('retain', 'archive', 'prune')][string]$ObsoletePolicy = 'retain',
        [ValidateSet('running', 'terminal', 'reaped', 'abandoned', 'unknown')][string]$OwningRunState = 'unknown'
    )
    if ($BaseClass -eq 'transient') {
        if ($OwningRunState -in @('terminal', 'reaped', 'abandoned')) { return 'prunable' }
        return 'transient'   # in-use while its owning run is running/unknown — NOT prunable
    }
    if ($BaseClass -eq 'unknown') { return 'unknown' }
    if ($IsLatestForLineage) { return 'durable' }
    switch ($ObsoletePolicy) {
        'archive' { return 'archived' }
        'prune'   { return 'prunable' }
        default   { return 'superseded' }
    }
}
