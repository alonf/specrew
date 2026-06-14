$ErrorActionPreference = 'Stop'

# F-174 iteration 011 (P2, FR-002/FR-004): the SessionStart hook payload MUST fit the host's hook-output cap.
# Claude Code v2.1.177 silently drops hook STDOUT over 10,000 chars to a file + a ~2KB preview, so an oversized
# directive never reaches the model (CONFIRMED live in the iter-11 real-host dogfood: the ~58KB inline-contract
# directive was dropped and the orientation banner never rendered). This test proves the two structural fixes:
#   (1) claude is in the POINTER delivery arm (the ~45KB contract is NOT inlined) - Get-SpecrewContractDeliveryMode;
#   (2) the variable-length inlined blocks (handover sections + reconciliation) are BOUNDED so the assembled
#       payload (bootstrap directive + the co-resident refocus fragment) stays under the cap even in the iter-11
#       mid-workshop-resume worst case (fat handover git-delta log + reconciliation + in-flight scan).
# NOTE (the form-check trap): "under the cap" is necessary-NOT-sufficient. It does NOT prove the banner renders on
# live claude - that remains unverified-pending-real-host (the maintainer's acceptance gate).

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

$repoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$provider = (Resolve-Path "$repoRoot/scripts/internal/specrew-bootstrap-provider.ps1").Path
$provSrc = Get-Content -LiteralPath $provider -Raw

# Format-BootstrapDirective depends on Test-SpecrewHandoverSectionAuthored (the placeholder/authored gate) from
# the HandoverStore component - dot-source it so the directive renders with real section-authoring behavior.
. (Resolve-Path "$repoRoot/scripts/internal/bootstrap/HandoverStore.ps1").Path

# Extract the three pure functions under test; their bodies must not run the provider main block.
foreach ($fn in 'Get-SpecrewContractDeliveryMode', 'Limit-SpecrewInlineBlock', 'Format-BootstrapDirective') {
    $m = [regex]::Match($provSrc, "(?s)^function $fn \{.*?\n\}", [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if (-not $m.Success) { throw "FAIL: could not extract $fn" }
    . ([scriptblock]::Create($m.Value))
}

# --- 1: the delivery-mode seam - claude + codex POINTER (cap-bound hosts); copilot/cursor INLINE. ---
Assert-True ((Get-SpecrewContractDeliveryMode -HostKind 'claude') -eq 'pointer') '1: claude is in the pointer arm (10K stdout cap disproved the inline premise)'
Assert-True ((Get-SpecrewContractDeliveryMode -HostKind 'codex') -eq 'pointer')  '1: codex stays pointer (oversized additionalContext drop)'
Assert-True ((Get-SpecrewContractDeliveryMode -HostKind 'copilot') -eq 'inline') '1: copilot stays inline (rendered in-band; unverified-cap residual)'
Assert-True ((Get-SpecrewContractDeliveryMode -HostKind 'cursor') -eq 'inline')  '1: cursor stays inline (same residual)'

# --- 2: Limit-SpecrewInlineBlock bounds any input + leaves under-budget text untouched. ---
$short = "a short line`nsecond line"
Assert-True ((Limit-SpecrewInlineBlock -Text $short -MaxChars 480 -Pointer 'file:///x') -eq $short) '2: under-budget text returned unchanged'
$huge = ('x' * 50000)
$bounded = Limit-SpecrewInlineBlock -Text $huge -MaxChars 420 -Pointer 'file:///handover.md'
Assert-True ($bounded.Length -lt 600) '2: 50KB input is bounded to well under the per-section cap (+elision note)'
Assert-True ($bounded -match 'truncated to fit the session-start delivery cap') '2: the elision note is appended'
Assert-True ($bounded -match 'file:///handover\.md') '2: the elision note carries the on-disk pointer'

# --- 3: the iter-11 worst case (mid-workshop resume) fits under the host cap. ---
# Reproduce the measured iter-11 budget: a fat "What I just did" git-delta log (6 entries each repeating the full
# 11-file uncommitted list, ~5.7KB), the other mechanical sections, a reconciliation file list, and the in-flight
# workshop scan. Source: the real dropped 58.4KB payload (hook-...-stdout.txt), broken down per section.
$fileList = (1..11 | ForEach-Object { "specs/001-layout-corrector/workshop/long-lens-record-name-$_.md" }) -join ', '
$whatIDid = (1..6 | ForEach-Object { "      - [2026-06-14T1$($_):00:00Z] (workshop) 11 changed user file(s) [$fileList] (+501 Specrew-managed); HEAD 205d9c6 (Initial commit from Specify template)" }) -join "`n"
$sections = [ordered]@{
    'What I just did (last 3-5 turns or last boundary work)'      = $whatIDid
    "Why I'm stopping (the switch trigger)"                       = "Hook-captured at trigger 'workshop' (the agent did not author a handover this turn). Boundary: (pre-boundary / workshop). Refresh reason: tracked-change."
    'Recommended next-immediate-step'                            = "Resume feature 001-layout-corrector at boundary (pre-boundary / workshop). 11 of YOUR file(s) are uncommitted [$fileList] (+501 Specrew-managed) - review/commit them before advancing."
    "Context the receiving host needs that artifacts don't carry" = "branch 001-layout-corrector, HEAD 205d9c6. Active feature 001-layout-corrector, boundary (pre-boundary / workshop). Your uncommitted work: $fileList. (501 Specrew-managed files also uncommitted.)"
    'Recent conversation (last few exchanges, hook-captured)'     = '(no conversation transcript exposed by copilot this stop - the next session relies on the git delta)'
}
$result = [pscustomobject]@{
    directive = [pscustomobject]@{
        mode                = 'full'
        required_reads      = @('.specrew/last-start-prompt.md', '.specrew/start-context.json')
        validation_findings = @('no active session anchor')
        handover            = [pscustomobject]@{ present = $true; placeholder = $false; recorded_at = '2026-06-14T13:23:20Z'; active_boundary = ''; sections = $sections }
        reconciliation      = [pscustomobject]@{ directive_text = "Last captured stop: 2026-06-14T13:23:20Z. Files changed since (re-computed NOW - may post-date the last stop): $fileList (+501 Specrew-managed). Review them, then continue." }
    }
}
$inFlight = [pscustomobject]@{
    in_flight        = $true
    feature_ref      = '001-layout-corrector'
    spec_exists      = $true
    spec_path        = 'specs/001-layout-corrector/spec.md'
    has_applicability = $true
    # TRUE worst case: a full ~9-lens workshop, every lens recorded with a decision summary (exercises the
    # in-flight decision-count cap), plus one remaining lens. The lens catalog tops out around here.
    done             = @('architecture-core', 'security-compliance', 'component-design', 'requirements-nfr', 'data-storage', 'observability-resilience', 'product-domain', 'ui-ux', 'integration-external')
    remaining        = @('code-implementation')
    done_decisions   = @(
        [pscustomobject]@{ lens = 'architecture-core';     summary = 'Decomposition Style; Threading Model; Detection Strategy; Volatile Seam' }
        [pscustomobject]@{ lens = 'security-compliance';    summary = 'Identity and Trust; Cloud Data Boundary; Audit and Telemetry; Refusal Boundary (+1 more)' }
        [pscustomobject]@{ lens = 'component-design';       summary = 'Responsibilities and Cohesion; Dependency Direction; Abstraction Shape; Schema and Model Decoupling (+1 more)' }
        [pscustomobject]@{ lens = 'requirements-nfr';       summary = 'Design-Driving NFRs; Mandatory Constraints vs Preferences; Measurable Thresholds; Contextual Detection Scope (+1 more)' }
        [pscustomobject]@{ lens = 'data-storage';           summary = 'Persistent Storage Requirement; Data Ownership; Storage Model and Schema; Consistency and Write Timing (+2 more)' }
        [pscustomobject]@{ lens = 'observability-resilience'; summary = 'Telemetry Signals; Failure Modes; Degradation Strategy; SLO Targets (+1 more)' }
        [pscustomobject]@{ lens = 'product-domain';         summary = 'Problem Framing; User Segments; Success Metrics; Scope Boundaries (+1 more)' }
        [pscustomobject]@{ lens = 'ui-ux';                  summary = 'Interaction Model; Surface Inventory; Accessibility Floor; Error Affordances (+1 more)' }
        [pscustomobject]@{ lens = 'integration-external';   summary = 'External Contracts; Idempotence; Retry/Backoff; Versioning Strategy (+1 more)' }
    )
}

# Render in claude's pointer mode (ContractBody = '' -> the 45KB contract is NOT inlined).
$directive = Format-BootstrapDirective -Result $result -ContractBody '' -InFlight $inFlight -PendingVerdict $null -SpecrewVersion '0.36.0' -Branch '001-layout-corrector'

# The co-resident refocus fragment shares the SessionStart payload (the dispatcher joins both provider fragments
# with "`n`n"). Prop-145 CAP-1: do NOT freeze a stale sample (the old 2,241 constant went silently stale as
# general.md grows). MEASURE the real refocus SessionStart fragment by running the deployed engine, so this test
# TRACKS reality - when the refocus digest grows past the composite headroom, THIS assertion catches the breach
# instead of flattering us. Fall back to the budget-derived ceiling only if the engine cannot run (conservative).
$refocusEngine = (Resolve-Path "$repoRoot/.specify/extensions/specrew-speckit/scripts/refocus.ps1" -ErrorAction SilentlyContinue)
if (-not $refocusEngine) { $refocusEngine = (Resolve-Path "$repoRoot/extensions/specrew-speckit/scripts/refocus.ps1" -ErrorAction SilentlyContinue) }
$refocusLive = 0
if ($refocusEngine) { try { $refocusLive = ((& pwsh -NoProfile -File $refocusEngine.Path 2>$null) -join "`n").Length } catch { $refocusLive = 0 } }
# refocus b2 budget = 1200 tokens (refocus-scopes.json) -> the engine clips at ~1200*4 = 4,800 chars; with the
# banner + any clip note the fragment CEILING is ~4,984. The live measure is normally far below this (general.md
# is well under the cap today). We assert on the LIVE measure (real today, growth-tracking); we also COMPUTE the
# budget-derived CEILING composite and surface it as the known CAP-1 architectural residual (the two fragments'
# self-budgets do not compose under 10K at their ceilings - deferred reconciliation: dispatcher fragment-priority drop).
$refocusCeiling = 4984
$refocusBaseline = if ($refocusLive -gt 0) { $refocusLive } else { $refocusCeiling }
$assembledTotal = $directive.Length + 2 + $refocusBaseline
$cap = 10000
$margin = 9300   # ~700 under the real cap for the realistic worst case; not a byte-tuned floor - the live-refocus assertion above is the growth-tracking regression catcher, and CAP-1 (the ceiling composition) is a surfaced deferred decision, not a static bound chased here.

Write-Host ("   directive (pointer mode) = {0} chars; + refocus LIVE {1} + sep 2 = assembled {2} (cap {3}, margin {4})" -f $directive.Length, $refocusBaseline, $assembledTotal, $cap, $margin) -ForegroundColor Cyan
Assert-True ($refocusLive -gt 0) '3: the real refocus SessionStart fragment was measured live (not a frozen constant) - the composite tracks general.md growth'
Assert-True ($assembledTotal -lt $cap)    "3: the iter-11 worst-case assembled payload ($assembledTotal) is under the 10K host cap"
Assert-True ($assembledTotal -lt $margin) "3: the iter-11 worst-case assembled payload ($assembledTotal) is under the $margin safety margin"

# --- 3b: the TRUE worst case - the integrity-critical AWAITING-VERDICT block (unbounded by design) ALSO present.
# It sits mid-payload after the handover/reconciliation; it must NOT be bounded (a dropped verdict warning is the
# DF-4/DF-5 failure), so it is the right stress on the cap: everything maxed AND the verdict block intact.
# Prop-145 INT-1: use the REAL ~345-char verdict template (shared-governance Get-SpecrewPendingVerdictState), not a
# short stub, so the headroom this reports is honest (the stub flattered the margin by ~235 chars).
$realVerdictMsg = "AWAITING YOUR VERDICT: 'specify' is committed / in-progress but NOT human-authorized (last authorized: (none recorded yet)). A committed boundary is not an approved one - the gate advances only when you confirm. Give the boundary verdict to authorize it; if you already approved, the session may have ended before your verdict was captured, so please re-confirm."
$pendingVerdict = [pscustomobject]@{ HasPendingVerdict = $true; WorkingBoundary = 'specify'; LastAuthorizedBoundary = $null; Message = $realVerdictMsg }
$directiveWithVerdict = Format-BootstrapDirective -Result $result -ContractBody '' -InFlight $inFlight -PendingVerdict $pendingVerdict -SpecrewVersion '0.36.0' -Branch '001-layout-corrector'
$assembledWithVerdict = $directiveWithVerdict.Length + 2 + $refocusBaseline
Write-Host ("   + AWAITING-VERDICT worst case (real 345-char msg) = {0} chars; assembled {1} (cap {2})" -f $directiveWithVerdict.Length, $assembledWithVerdict, $cap) -ForegroundColor Cyan
Assert-True ($directiveWithVerdict -match 'AWAITING YOUR VERDICT \(committed') '3b: the integrity-critical verdict block survives intact (unbounded)'
Assert-True ($assembledWithVerdict -lt $cap) "3b: the in-flight + pending-verdict combined worst case ($assembledWithVerdict) is under the 10K cap"

# --- 3c: CAP-1 architectural residual (SURFACED, not silently asserted-away). The bootstrap directive bounds
# only ITSELF; the refocus fragment self-bounds to its OWN ceiling (~4,984). At BOTH ceilings the two do not
# compose under 10K. This is a deferred reconciliation (lead option: dispatcher fragment-priority drop - keep the
# bootstrap fragment whole, shrink/drop the lower-order refocus fragment when the join exceeds the cap). It is
# NOT a breach today (live refocus is far below its ceiling); we MEASURE and PRINT it so the gap is visible, and
# we do not fail on it here (the live-tracking assertion in 3 is the regression catcher for real growth).
$ceilingComposite = $directiveWithVerdict.Length + 2 + $refocusCeiling
if ($ceilingComposite -ge $cap) {
    Write-Host ("   [CAP-1 RESIDUAL] at refocus's budget CEILING ({0}) the composite would be {1} >= {2} - the two fragment budgets do not compose; deferred reconciliation (dispatcher fragment-priority drop). Live headroom today: {3} chars." -f $refocusCeiling, $ceilingComposite, $cap, ($cap - $assembledWithVerdict)) -ForegroundColor Yellow
} else {
    Write-Host ("   [CAP-1] composite at refocus ceiling = {0} < {1}: the two fragment budgets now compose." -f $ceilingComposite, $cap) -ForegroundColor Green
}

# --- 4: the load-bearing content survives the bound (banner + resume context + the in-flight resume instruction). ---
Assert-True ($directive -match 'MANDATORY FIRST ACTION')              '4: the orientation-banner mandate survives (the P2 user-visible deliverable)'
Assert-True ($directive -match 'Resolved for THIS session')           '4: the resolved version/branch line survives'
Assert-True ($directive -notmatch 'BEGIN SPECREW LAUNCH CONTRACT')    '4: the 45KB contract is NOT inlined in pointer mode'
Assert-True ($directive -match 'IN-FLIGHT WORK ON DISK')              '4: the in-flight resume scan survives'
Assert-True ($directive -match 'code-implementation')                 '4: the remaining-lens resume target survives the bound'
Assert-True ($directive -match 'truncated to fit the session-start delivery cap') '4: the fat handover log was bounded (elision note present)'
Assert-True ($directive -match 'Validated handover captured')         '4: the handover preamble survives'

Write-Host "`n=== DirectiveDeliveryCap.Tests.ps1: all assertions passed (P2 cap-fit: pointer arm + bounded inlining) ===" -ForegroundColor Green
exit 0
