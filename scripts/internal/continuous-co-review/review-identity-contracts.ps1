# T019 — review identity, lineage, evidence, and artifact-lifecycle CONTRACTS (characterization slice).
#
# STATUS: this is the UNWIRED contract layer authored 2026-07-13 per the maintainer's
# "characterization and contract work before changing runtime behavior" directive. Every function
# here is PURE (no filesystem/git/process I/O, no global state) and NOTHING in the shipped runtime
# calls it yet — it is deliberately NOT added to _load.ps1. Step 6 of T019 ("implement against those
# contracts") wires these decisions into the live navigator / Stop path / orchestrator; that is a
# SEPARATE slice. These functions are the executable specification the fixtures assert against and
# the shipped runtime must satisfy once wired.
#
# The characterization these contracts pin (current shipped behavior → target), with file:line refs,
# lives in specs/198-beta2-hardening/iterations/003/research/t019-review-identity-and-artifact-lifecycle.md.

Set-StrictMode -Version Latest

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

# ---------------------------------------------------------------------------------------------------
# EVIDENCE DIGEST identity (step 1) — DRIFT-198-I003-002 gate.
# Contract: a recorded evidence record gains standing for a review ONLY when its evidence digest
# EXACTLY equals the reviewed digest under review. A digest-A record injected (fully OR as a subset)
# into a digest-B review is a mismatch, surfaced honestly — never clean, never proof the A-runs did
# not occur. Mirrors Get-ContinuousCoReviewTestEvidenceForDigest's exact-string match rule
# (test-evidence-recorder.ps1:112) but makes the PARTIAL-subset case an explicit, named outcome.
function Test-ContinuousCoReviewEvidenceInjectable {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$EvidenceDigest,
        [Parameter(Mandatory)][AllowEmptyString()][string]$ReviewDigest,
        [switch]$IsSubset
    )
    $exact = (-not [string]::IsNullOrWhiteSpace($EvidenceDigest)) -and ($EvidenceDigest -ceq $ReviewDigest)
    if ($exact) {
        return [pscustomobject]@{ injectable = $true; classification = 'exact-digest-injected' }
    }
    if ($IsSubset) {
        return [pscustomobject]@{ injectable = $false; classification = 'partial-injection-mismatch-surfaced' }
    }
    return [pscustomobject]@{ injectable = $false; classification = 'digest-mismatch-not-injected' }
}

# ---------------------------------------------------------------------------------------------------
# RUN LINEAGE + in-flight dedup (step 1 + step 4).
# Contract: at most ONE tracked in-flight review per lineage. A Stop-fired review that finds a running
# review for its lineage MUST wait/poll the existing run, never launch a duplicate. Lineage is keyed
# by the review-target baseline lineage, NOT the per-fire checkpoint_id (nav-<run_id>).
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
        if (($entryLineage -eq $LineageId) -and ($entryStatus -eq 'running')) {
            $existing = $entry
            break
        }
    }
    if ($null -ne $existing) {
        return [pscustomobject]@{
            is_duplicate   = $true
            existing_run_id = [string](Get-ContinuousCoReviewContractProp -Object $existing -Name 'run_id')
            launch         = $false
            action         = 'wait-poll-existing'
        }
    }
    return [pscustomobject]@{ is_duplicate = $false; existing_run_id = $null; launch = $true; action = 'launch' }
}

# OUT-OF-ORDER completion (step 4): a terminal result is authoritative ONLY when its reviewed digest
# equals the current reviewed digest. An obsolete in-flight run completing after a newer one is
# SUPERSEDED (digest != current), never a fresh block or authorization.
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

# ---------------------------------------------------------------------------------------------------
# PER-FINDING identity (step 1).
# Contract: a finding's GLOBAL identity binds its local (finding_id, source_run_id) to the reviewed
# tree AND baseline of its run — so a MIXED run set can distinguish a stale replay from a still-valid
# finding PER-FINDING. Today findings carry no tree/baseline (findings-result.schema.json is
# additionalProperties:false with neither field); the run record (review-run.json) carries
# reviewed_tree_id + baseline_ref. This resolver composes the target identity from both.
function Get-ContinuousCoReviewFindingIdentity {
    param(
        [Parameter(Mandatory)]$Finding,
        [Parameter(Mandatory)]$RunRecord
    )
    $reviewedTreeId = Get-ContinuousCoReviewContractProp -Object $RunRecord -Name 'reviewed_tree_id'
    if ([string]::IsNullOrWhiteSpace([string]$reviewedTreeId)) {
        # tolerate the status.json spelling; the durable run record uses reviewed_tree_id, status.json uses reviewed_digest_tree_id
        $reviewedTreeId = Get-ContinuousCoReviewContractProp -Object $RunRecord -Name 'reviewed_digest_tree_id'
    }
    return [pscustomobject]@{
        finding_id      = [string](Get-ContinuousCoReviewContractProp -Object $Finding -Name 'finding_id')
        source_run_id   = [string](Get-ContinuousCoReviewContractProp -Object $Finding -Name 'source_run_id')
        reviewed_tree_id = [string]$reviewedTreeId
        baseline_ref    = [string](Get-ContinuousCoReviewContractProp -Object $RunRecord -Name 'baseline_ref')
        fingerprint     = [string](Get-ContinuousCoReviewContractProp -Object $Finding -Name 'fingerprint')
    }
}

# ---------------------------------------------------------------------------------------------------
# FR-045 Stop-ordering routing (step 5).
# Contract: given the review state at a Stop, which routing is allowed. render_marker/capturable are
# true for EXACTLY the terminal + clean + exact-current-digest state; launch_review is ALWAYS false on
# the Stop path (the navigator owns firing, gated by Test-ContinuousCoReviewInFlightDuplicate).
function Resolve-ContinuousCoReviewStopRouting {
    param(
        [Parameter(Mandatory)][bool]$ReviewTerminal,
        [Parameter(Mandatory)][AllowEmptyString()][string]$ReviewOutcome,
        [Parameter(Mandatory)][bool]$DigestMatchesCurrent,
        [bool]$InFlightPresent = $false
    )
    $blocked = [pscustomobject]@{ render_packet = $false; render_marker = $false; launch_review = $false; action = 'wait-poll-existing'; capturable_as_verdict = $false }

    # Not terminal (running / duplicate Stop during in-flight): wait, never a packet, never a duplicate.
    if (-not $ReviewTerminal) { return $blocked }

    # Terminal but an earlier-digest result while a current-digest review is still in flight: superseded, wait.
    if ($InFlightPresent -and (-not $DigestMatchesCurrent)) { return $blocked }

    switch ($ReviewOutcome) {
        'clean' {
            if ($DigestMatchesCurrent) {
                return [pscustomobject]@{ render_packet = $true; render_marker = $true; launch_review = $false; action = 'render-boundary-packet'; capturable_as_verdict = $true }
            }
            # stale-completion: clean but the reviewed digest != current tree.
            return [pscustomobject]@{ render_packet = $false; render_marker = $false; launch_review = $false; action = 're-review-current-digest'; capturable_as_verdict = $false }
        }
        'actionable' {
            return [pscustomobject]@{ render_packet = $false; render_marker = $false; launch_review = $false; action = 'fix-and-re-review'; capturable_as_verdict = $false }
        }
        'human-judgment' {
            return [pscustomobject]@{ render_packet = $false; render_marker = $false; launch_review = $false; action = 'narrow-non-boundary-question'; capturable_as_verdict = $false }
        }
        'infra-failure' {
            return [pscustomobject]@{ render_packet = $false; render_marker = $false; launch_review = $false; action = 'report-specific-failure'; capturable_as_verdict = $false }
        }
        default {
            # Unknown terminal outcome fails closed: never a packet, never capturable.
            return [pscustomobject]@{ render_packet = $false; render_marker = $false; launch_review = $false; action = 'report-specific-failure'; capturable_as_verdict = $false }
        }
    }
}

# ---------------------------------------------------------------------------------------------------
# ARTIFACT lifecycle classes (step 2).
# Base class from the on-disk family (path-static): transient (ephemeral, deleted at run/reap end) vs
# durable (retained review evidence) vs unknown. git_tracked mirrors the shipped .gitignore reality
# (inline/, test-evidence/, signoff-gate/ tracked; pending/, runtime/, .review/ ignored/ephemeral).
function Get-ContinuousCoReviewArtifactClass {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Path)
    $p = ([string]$Path).Replace('\', '/')
    $mk = {
        param($base, $tracked, $supersedable, $retention)
        [pscustomobject]@{ base_class = $base; git_tracked = $tracked; supersedable = $supersedable; retention = $retention }
    }
    if ($p -match '(^|/)\.specrew/review/pending(/|$)')      { return & $mk 'transient' $false $false 'deleted by reap/stop at run end' }
    if ($p -match '(^|/)\.specrew/runtime(/|$)')             { return & $mk 'transient' $false $false 'machine-local runtime state; rewritten each cycle' }
    if ($p -match '(^|/)\.review(/|$)')                      { return & $mk 'transient' $false $false 'ephemeral disposable-worktree bundle; discarded at run end' }
    if ($p -match '(^|/)\.specrew/review/inline/')           { return & $mk 'durable'   $true  $true  'retained until superseded by a later reviewed digest for its lineage; then archive or prune per T019 policy' }
    if ($p -match '(^|/)\.specrew/review/test-evidence/')    { return & $mk 'durable'   $true  $true  'retained for its digest; a stale digest is prunable once no live lineage references it (T019 policy)' }
    if ($p -match '(^|/)\.specrew/review/signoff-gate/')     { return & $mk 'durable'   $true  $false 'latest.json overwritten each decision; history/ append-only (not supersedable)' }
    return & $mk 'unknown' $false $false 'unclassified — a contract gap to resolve before it accumulates'
}

# Disposition resolves a DURABLE record to one of the five lifecycle states given whether it is still
# the latest for its lineage and the (T019-owned) archive-vs-prune policy for obsolete records. The
# WINDOW/threshold that decides archive vs prune is deliberately a policy input, not hard-coded here.
function Resolve-ContinuousCoReviewRecordDisposition {
    param(
        [Parameter(Mandatory)][ValidateSet('transient', 'durable', 'unknown')][string]$BaseClass,
        [bool]$IsLatestForLineage = $true,
        [ValidateSet('retain', 'archive', 'prune')][string]$ObsoletePolicy = 'retain'
    )
    if ($BaseClass -eq 'transient') { return 'prunable' }        # ephemeral: always safe to delete after its run
    if ($BaseClass -eq 'unknown')   { return 'unknown' }
    if ($IsLatestForLineage)        { return 'durable' }         # current evidence for a live lineage
    switch ($ObsoletePolicy) {                                   # obsolete durable record → T019 policy decides
        'archive' { return 'archived' }
        'prune'   { return 'prunable' }
        default   { return 'superseded' }                        # retained-but-obsolete, pending an archive/prune decision
    }
}
