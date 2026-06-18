$ErrorActionPreference = 'Stop'
# CRITICAL: run under the SAME strictness the real provider runs under. The provider's main block + its dot-sourced
# components Set-StrictMode -Version Latest, so Format-BootstrapDirective executes strict at runtime. The extracted-
# function tests historically did NOT set it, so `$null.Count` returned $null silently instead of throwing - which
# is exactly how the real-host empty-done_decisions crash (the directive failed -> no banner) slipped past the suite.
Set-StrictMode -Version Latest

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

function Invoke-SyntheticSessionStartComposite {
    param(
        [Parameter(Mandatory)][string]$BootstrapFragment,
        [Parameter(Mandatory)][string]$RefocusFragment,
        [string]$SessionId = 'directive-cap-synthetic'
    )

    $dispatcher = (Resolve-Path "$repoRoot/scripts/internal/specrew-hook-dispatcher.ps1").Path
    $projectRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-directive-cap-" + [guid]::NewGuid().ToString('N'))
    $scriptsDir = Join-Path $projectRoot '.specify/extensions/specrew-speckit/scripts'
    New-Item -ItemType Directory -Path (Join-Path $projectRoot '.specrew/runtime') -Force | Out-Null
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null

    $catalog = @{
        schema_version = '1'
        providers      = @(
            @{ id = 'refocus'; kind = 'inject'; events = @('SessionStart'); order = 10; budget_share = 1.0; command = 'synthetic-refocus.ps1' }
            @{ id = 'bootstrap'; kind = 'inject'; events = @('SessionStart'); order = 20; budget_share = 1.0; command = 'synthetic-bootstrap.ps1' }
        )
    } | ConvertTo-Json -Depth 6
    Set-Content -LiteralPath (Join-Path $projectRoot '.specify/extensions/specrew-speckit/refocus-scopes.json') -Value $catalog -Encoding UTF8

    [System.IO.File]::WriteAllText((Join-Path $scriptsDir 'bootstrap.payload.txt'), $BootstrapFragment, [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $scriptsDir 'refocus.payload.txt'), $RefocusFragment, [System.Text.UTF8Encoding]::new($false))

    $providerStub = @'
param()
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { $null = $_ }
$payloadName = if ($MyInvocation.MyCommand.Name -match 'bootstrap') { 'bootstrap.payload.txt' } else { 'refocus.payload.txt' }
[Console]::Out.Write([System.IO.File]::ReadAllText((Join-Path $PSScriptRoot $payloadName), [System.Text.Encoding]::UTF8))
exit 0
'@
    Set-Content -LiteralPath (Join-Path $scriptsDir 'synthetic-bootstrap.ps1') -Value $providerStub -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $scriptsDir 'synthetic-refocus.ps1') -Value $providerStub -Encoding UTF8

    $eventJson = @{ session_id = $SessionId; source = 'startup'; hook_event_name = 'SessionStart' } | ConvertTo-Json -Compress
    $stdinPath = Join-Path $projectRoot 'event.json'
    $stdoutPath = Join-Path $projectRoot 'stdout.txt'
    $stderrPath = Join-Path $projectRoot 'stderr.txt'
    [System.IO.File]::WriteAllText($stdinPath, $eventJson, [System.Text.UTF8Encoding]::new($false))

    $proc = Start-Process -FilePath 'pwsh' `
        -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $dispatcher, '-Event', 'SessionStart', '-HostKind', 'claude') `
        -WorkingDirectory $projectRoot -NoNewWindow -PassThru -Wait `
        -RedirectStandardInput $stdinPath -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath

    return [pscustomobject]@{
        ProjectRoot = $projectRoot
        EventJson   = $eventJson
        ExitCode    = $proc.ExitCode
        StdOut      = ((Get-Content -LiteralPath $stdoutPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue) ?? '')
        StdErr      = ((Get-Content -LiteralPath $stderrPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue) ?? '')
    }
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

$cap = 10000
# FR-004/SC-004: measure a hermetic shipped-composite path. The old fixture invoked the local refocus engine with
# this repo's ambient lifecycle state, so growth in general.md/current-stage state could make the test red without
# proving the shipped SessionStart dispatcher behavior. Here the over-cap peer fragment is synthetic, the event is a
# synthetic startup SessionStart payload, and the real dispatcher performs the production priority/cap composition.
$syntheticRefocus = "[specrew-refocus] trigger=b2 scope=general sources=1 tokens~3000`n" + ('R' * 12000) + "`nSYNTHETIC-REFOCUS-END"
$rawSyntheticTotal = $directive.Length + 2 + $syntheticRefocus.Length
Write-Host ("   directive (pointer mode) = {0} chars; + synthetic refocus {1} + sep 2 = raw {2} (cap {3})" -f $directive.Length, $syntheticRefocus.Length, $rawSyntheticTotal, $cap) -ForegroundColor Cyan
Assert-True ($rawSyntheticTotal -gt $cap) '3: the synthetic shipped composite is genuinely over cap before dispatcher policy is applied'
$composite = Invoke-SyntheticSessionStartComposite -BootstrapFragment $directive -RefocusFragment $syntheticRefocus
try {
    Assert-True ($composite.EventJson -match '"source":"startup"') '3: fixture uses a synthetic startup SessionStart event'
    Assert-True ($composite.ExitCode -eq 0) '3: synthetic shipped SessionStart composite exits 0'
    Assert-True ($composite.StdOut.Length -gt 0) '3: synthetic shipped SessionStart composite emits host-facing output'
    Assert-True ($composite.StdOut.Length -le $cap) "3: synthetic shipped SessionStart composite is under the 10K host cap after dispatcher policy (got $($composite.StdOut.Length))"
    Assert-True ($composite.StdOut -match 'MANDATORY FIRST ACTION') '3: bootstrap fragment survives dispatcher cap policy'
    Assert-True ($composite.StdOut -match 'truncated to fit the session-start delivery cap') '3: bounded bootstrap resume context survives dispatcher cap policy'
    Assert-True (-not ($composite.StdOut -match 'SYNTHETIC-REFOCUS-END')) '3: lower-priority synthetic refocus tail is clipped before it can overrun the cap'
    Assert-True ($composite.StdErr -match 'PAYLOAD_CLIPPED') '3: dispatcher reports the lower-priority cap clipping'
}
finally {
    Remove-Item -LiteralPath $composite.ProjectRoot -Recurse -Force -ErrorAction SilentlyContinue
}

# --- 3b: the TRUE worst case - the integrity-critical AWAITING-VERDICT block (unbounded by design) ALSO present.
# It sits mid-payload after the handover/reconciliation; it must NOT be bounded (a dropped verdict warning is the
# DF-4/DF-5 failure), so it is the right stress on the cap: everything maxed AND the verdict block intact.
# Prop-145 INT-1: use the REAL ~345-char verdict template (shared-governance Get-SpecrewPendingVerdictState), not a
# short stub, so the headroom this reports is honest (the stub flattered the margin by ~235 chars).
$realVerdictMsg = "AWAITING YOUR VERDICT: 'specify' is committed / in-progress but NOT human-authorized (last authorized: (none recorded yet)). A committed boundary is not an approved one - the gate advances only when you confirm. Give the boundary verdict to authorize it; if you already approved, the session may have ended before your verdict was captured, so please re-confirm."
$pendingVerdict = [pscustomobject]@{ HasPendingVerdict = $true; WorkingBoundary = 'specify'; LastAuthorizedBoundary = $null; Message = $realVerdictMsg }
$directiveWithVerdict = Format-BootstrapDirective -Result $result -ContractBody '' -InFlight $inFlight -PendingVerdict $pendingVerdict -SpecrewVersion '0.36.0' -Branch '001-layout-corrector'
Assert-True ($directiveWithVerdict -match 'AWAITING YOUR VERDICT \(committed') '3b: the integrity-critical verdict block survives intact (unbounded)'
$compositeWithVerdict = Invoke-SyntheticSessionStartComposite -BootstrapFragment $directiveWithVerdict -RefocusFragment $syntheticRefocus -SessionId 'directive-cap-verdict'
try {
    Write-Host ("   + AWAITING-VERDICT worst case (real 345-char msg) = {0} chars; dispatcher output {1} (cap {2})" -f $directiveWithVerdict.Length, $compositeWithVerdict.StdOut.Length, $cap) -ForegroundColor Cyan
    Assert-True ($compositeWithVerdict.ExitCode -eq 0) '3b: pending-verdict synthetic composite exits 0'
    Assert-True ($compositeWithVerdict.StdOut.Length -le $cap) "3b: pending-verdict synthetic composite is under the 10K cap after dispatcher policy (got $($compositeWithVerdict.StdOut.Length))"
    Assert-True ($compositeWithVerdict.StdOut -match 'AWAITING YOUR VERDICT \(committed') '3b: the integrity-critical verdict block survives the shipped composite'
    Assert-True ($compositeWithVerdict.StdErr -match 'PAYLOAD_CLIPPED') '3b: lower-priority refocus clipping remains observable with a pending verdict'
}
finally {
    Remove-Item -LiteralPath $compositeWithVerdict.ProjectRoot -Recurse -Force -ErrorAction SilentlyContinue
}

# --- 4: the load-bearing content survives the bound (banner + resume context + the in-flight resume instruction). ---
Assert-True ($directive -match 'MANDATORY FIRST ACTION')              '4: the orientation-banner mandate survives (the P2 user-visible deliverable)'
Assert-True ($directive -match 'Resolved for THIS session')           '4: the resolved version/branch line survives'
Assert-True ($directive -notmatch 'BEGIN SPECREW LAUNCH CONTRACT')    '4: the 45KB contract is NOT inlined in pointer mode'
Assert-True ($directive -match 'IN-FLIGHT WORK ON DISK')              '4: the in-flight resume scan survives'
Assert-True ($directive -match 'code-implementation')                 '4: the remaining-lens resume target survives the bound'
Assert-True ($directive -match 'truncated to fit the session-start delivery cap') '4: the fat handover log was bounded (elision note present)'
Assert-True ($directive -match 'Validated handover captured')         '4: the handover preamble survives'

# --- 4b: RESUME-FLOOR GUARD (2026-06-15). The cap fix must NEVER be paid by starving resume. The handover inline
# budget (380) and the reconciliation excerpt cap (300) are the floors that passed real-host dogfood. Recover cap
# headroom from the co-resident refocus B2 fragment (general.md tail) or Proposal 191 (pre-compute the in-flight
# digest to a file + pointer) - NOT by cutting these. This guard fails the moment a change trades resume quality
# for cap headroom, so the "solve cap by starving resume" regression cannot recur silently.
$hoBudgetMatch = [regex]::Match($provSrc, '\$hoBudget\s*=\s*(\d+)')
Assert-True ($hoBudgetMatch.Success -and [int]$hoBudgetMatch.Groups[1].Value -ge 380) ("4b RESUME-FLOOR: handover inline budget >= 380 (dogfooded floor; do not starve resume for cap headroom) - found {0}" -f $(if ($hoBudgetMatch.Success) { $hoBudgetMatch.Groups[1].Value } else { 'NONE' }))
$reconCapMatch = [regex]::Match($provSrc, 'reconciliation\.directive_text\) -MaxChars (\d+)')
Assert-True ($reconCapMatch.Success -and [int]$reconCapMatch.Groups[1].Value -ge 300) ("4b RESUME-FLOOR: reconciliation excerpt cap >= 300 (dogfooded floor; recover cap from refocus / Proposal 191, not resume) - found {0}" -f $(if ($reconCapMatch.Success) { $reconCapMatch.Groups[1].Value } else { 'NONE' }))

# --- 5: REAL-HOST REGRESSION (2026-06-14). A workshop with done lenses but NO parseable decision summaries gives
# done_decisions = an EMPTY array. Under StrictMode-Latest (the provider's real context) the old idiom
# `$decisions = if(..){@(..)}else{@()}` collapsed the empty @() to $null, so `$decisions.Count` THREW -> the whole
# directive failed -> EMPTY output -> the orientation banner never surfaced on the live host. The extracted-function
# suite missed it because it did not run under StrictMode. This case reproduces the exact shape and asserts the
# directive renders (no throw), the banner survives, and the bare-names fallback is used (no decision recap). Test
# all three empty/null shapes that Get-SpecrewWorkshopProgress / a hand-built InFlight can produce.
foreach ($emptyShape in @{ name = 'untyped @()'; v = @() }, @{ name = 'typed [object[]]@()'; v = ([object[]]@()) }, @{ name = '$null'; v = $null }) {
    $inflightNoDecisions = [pscustomobject]@{
        in_flight = $true; feature_ref = '001-atm-kids-simulator'; spec_exists = $true; spec_path = 'specs/001-atm-kids-simulator/spec.md'
        has_applicability = $true
        done = @('product-domain', 'requirements-nfr', 'ui-ux', 'data-storage', 'security-compliance')
        remaining = @('architecture-core', 'component-design', 'observability-resilience', 'code-implementation')
        done_decisions = $emptyShape.v
    }
    $d5 = $null
    try { $d5 = Format-BootstrapDirective -Result $result -ContractBody '' -InFlight $inflightNoDecisions -PendingVerdict $null -SpecrewVersion '0.36.0' -Branch '001-atm-kids-simulator' }
    catch { Assert-True $false ("5: directive render MUST NOT throw on empty done_decisions [$($emptyShape.name)] - it did: $($_.Exception.Message)") }
    Assert-True ($d5 -and $d5.Length -gt 0)                  "5: directive renders non-empty with empty done_decisions [$($emptyShape.name)] (the real-host crash shape)"
    Assert-True ($d5 -match 'MANDATORY FIRST ACTION')        "5: the banner survives with empty done_decisions [$($emptyShape.name)]"
    Assert-True ($d5 -match 'lenses already DONE')           "5: the bare-names fallback renders (no decision recap) [$($emptyShape.name)]"
    Assert-True ($d5 -notmatch 'DECISIONS recorded so far')  "5: the decisions-recap block is absent when there are no decisions [$($emptyShape.name)]"
}

Write-Host "`n=== DirectiveDeliveryCap.Tests.ps1: all assertions passed (P2 cap-fit + StrictMode empty-decisions regression) ===" -ForegroundColor Green
exit 0
