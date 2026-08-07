#requires -Version 7.0
# F-198 (0.40.0-beta2 hardening) honesty regression suite — the NFR-007 enforcement lane in CI.
#
# EXPLICIT registry, never a glob: this iteration's core honesty tests must not merge as manual-only.
# Each entry runs in its own child pwsh with a PER-TEST TIMEOUT and its output captured, so a hang
# fails loud (not a silent CI hang) and a failure prints the offending suite's tail. Add a row here
# when a new F-198 honesty/regression suite lands; do NOT convert this to a directory glob (a bounded
# list is the point - it states exactly what the beta2 honesty bar depends on).
#
# 'script' suites use the repo's Write-Pass/Write-Fail convention (exit 0 green / 1 red).
# 'pester' suites run via Invoke-Pester and fail on any FailedCount.
[CmdletBinding()]
param(
    [ValidateRange(1, 3600)]
    [int]$PerTestTimeoutSeconds = 300,

    [ValidateRange(1, 32)]
    [int]$MaxParallel = 4,

    [switch]$Serial,

    [string]$TimingOutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Get-CallerRepositorySnapshot {
    $head = @(& git -C $repoRoot rev-parse --verify HEAD 2>$null)
    if ($LASTEXITCODE -ne 0 -or $head.Count -ne 1) {
        throw "Cannot snapshot the caller repository HEAD at '$repoRoot'."
    }

    $branch = @(& git -C $repoRoot symbolic-ref --quiet --short HEAD 2>$null)
    if ($LASTEXITCODE -eq 1) {
        $branch = @('(detached)')
    }
    elseif ($LASTEXITCODE -ne 0 -or $branch.Count -ne 1) {
        throw "Cannot snapshot the caller repository branch at '$repoRoot'."
    }

    $localConfig = @(& git -C $repoRoot config --local --list --show-origin 2>$null)
    if ($LASTEXITCODE -ne 0) {
        throw "Cannot snapshot the caller repository local Git configuration at '$repoRoot'."
    }

    $status = @(& git -C $repoRoot status --porcelain=v1 --untracked-files=all 2>$null)
    if ($LASTEXITCODE -ne 0) {
        throw "Cannot snapshot the caller repository status at '$repoRoot'."
    }

    return [pscustomobject]@{
        Head        = [string]$head[0]
        Branch      = [string]$branch[0]
        LocalConfig = @($localConfig | ForEach-Object { [string]$_ })
        Status      = @($status | ForEach-Object { [string]$_ })
    }
}

function Get-CallerRepositoryContamination {
    param(
        [Parameter(Mandatory = $true)]$Baseline
    )

    $current = Get-CallerRepositorySnapshot
    $changes = [System.Collections.Generic.List[string]]::new()
    if ($current.Branch -cne $Baseline.Branch) { $changes.Add("branch '$($Baseline.Branch)' -> '$($current.Branch)'") | Out-Null }
    if ($current.Head -cne $Baseline.Head) { $changes.Add("HEAD '$($Baseline.Head)' -> '$($current.Head)'") | Out-Null }
    if (($current.LocalConfig -join "`n") -cne ($Baseline.LocalConfig -join "`n")) { $changes.Add('worktree-local Git config changed') | Out-Null }
    if (($current.Status -join "`n") -cne ($Baseline.Status -join "`n")) { $changes.Add('tracked/untracked status changed') | Out-Null }
    return @($changes)
}

$registry = @(
    @{ area = 'boundary ratchet (FR-001..FR-005, cycle-scoped)'; path = 'tests/unit/boundary-ratchet.tests.ps1'; kind = 'script' }
    @{ area = 'append-only scoped authorization correction ledger (FR-004/SC-014)'; path = 'tests/unit/boundary-correction-ledger.tests.ps1'; kind = 'script' }
    @{ area = 'current commit/tree pending-crossing binding (FR-041/FR-042/FR-044/FR-045)'; path = 'tests/integration/pending-verdict-stop-artifact.tests.ps1'; kind = 'script' }
    @{ area = 'DRIFT-198-I008-056–058 caller isolation, Pester container honesty, and closed automation stdin'; path = 'tests/unit/regression-harness-isolation.tests.ps1'; kind = 'script' }
    @{ area = 'F6 review-engine version handshake - project/runtime identity, drift refusal, deployed marker'; path = 'tests/unit/review-engine-resolution.tests.ps1'; kind = 'script' }
    @{ area = 'F6/F197 deployed review-engine identity and complete fire path'; path = 'tests/continuous-co-review/integration/co-review-deploy-completeness.Tests.ps1'; kind = 'pester' }
    @{ area = 'F15 consumer runtime file classification - ignore evidence, preserve contracts'; path = 'tests/unit/feature-051-file-classification.tests.ps1'; kind = 'script' }
    @{ area = 'budget resolution + provenance (FR-021..FR-023)'; path = 'tests/unit/budget-resolution.tests.ps1'; kind = 'script' }
    @{ area = 'tracker honesty check (FR-020)'; path = 'tests/unit/tracker-honesty-check.tests.ps1'; kind = 'script' }
    @{ area = 'self-leak firewall (FR-033/FR-037)'; path = 'tests/unit/self-leak-lint.tests.ps1'; kind = 'script' }
    @{ area = 'verdict-capture integrity (FR-041..FR-044)'; path = 'tests/integration/verdict-capture-blocks.tests.ps1'; kind = 'script' }
    @{ area = 'T069 production hook/writer capture - injected-context exclusion, complete instructions, contiguous crossing, idempotence'; path = 'tests/bootstrap/HookVerdictCapture.Tests.ps1'; kind = 'script'; serial = $true }
    @{ area = 'T069 dispatcher session-ownership delivery - sanitized genuine host identity as a clean provider argument'; path = 'tests/bootstrap/DispatcherTranscriptDelivery.Tests.ps1'; kind = 'script'; serial = $true }
    @{ area = 'reviewer containment (FR-008/SC-002)'; path = 'tests/continuous-co-review/unit/worktree-containment.Tests.ps1'; kind = 'pester' }
    # The path-identity family was NOT in this registry, which is why "registry green" could be true
    # through six rounds of path-identity defects. Registered 2026-07-29 so the phrase means something:
    # the primitive itself, the machinery dedup, the volume-differential harness whose oracle is the
    # filesystem, the mutation gate that proves that harness can FAIL, and the grant write-scope
    # regression for DRIFT-198-I009-028.
    @{ area = 'the ONE path-identity primitive + structural enforcement (DRIFT-198-I009-015/016/017/027/031/033)'; path = 'tests/continuous-co-review/unit/path-identity.Tests.ps1'; kind = 'pester' }
    @{ area = 'path identity DIFFERENTIAL harness - the volume is the oracle (DRIFT-198-I009-032/033)'; path = 'tests/continuous-co-review/unit/path-identity-volume-differential.Tests.ps1'; kind = 'pester' }
    @{ area = 'differential harness falsifiability - mutation gate (maintainer decision 2026-07-29)'; path = 'tests/continuous-co-review/unit/path-identity-mutation-gate.Tests.ps1'; kind = 'pester'; serial = $true }
    @{ area = 'machinery path resolution + case-distinct dedup (DRIFT-198-I009-016/019)'; path = 'tests/continuous-co-review/unit/worktree-reviewer-machinery-paths.Tests.ps1'; kind = 'pester' }
    @{ area = 'reviewer-host grant write scope - one field of one row (DRIFT-198-I009-028)'; path = 'tests/continuous-co-review/unit/reviewer-host-grant-write-scope.Tests.ps1'; kind = 'pester'; serial = $true }
    @{ area = 'authority-store link-containment falsifiability - mutation gate (DRIFT-198-I009-041, T081)'; path = 'tests/continuous-co-review/unit/review-authority-store-mutation-gate.Tests.ps1'; kind = 'pester'; serial = $true }
    @{ area = 'reviewer origin-path hygiene (FR-009/SC-002)'; path = 'tests/continuous-co-review/unit/origin-path-hygiene.Tests.ps1'; kind = 'pester' }
    @{ area = 'bounded verification opt-in helper + regression evidence (FR-010)'; path = 'tests/continuous-co-review/unit/bounded-verification.Tests.ps1'; kind = 'pester' }
    @{ area = 'no auto-verification + reviewer-invocation integrity (FR-010)'; path = 'tests/continuous-co-review/unit/orchestrator-reviewer-integrity.Tests.ps1'; kind = 'pester' }
    @{ area = 'review spend allowance (FR-018/FR-019)'; path = 'tests/continuous-co-review/unit/review-spend-allowance.Tests.ps1'; kind = 'pester' }
    @{ area = 'signoff evidence gate (FR-020 wiring)'; path = 'tests/continuous-co-review/unit/degraded-evidence-gate.Tests.ps1'; kind = 'pester' }
    # Shared co-review engine that F-198 modifies (T012/T014/T020 touch the orchestrator run path):
    # these guard against the exact regression class that slipped when they were manual-only (a T012
    # host-field addition crashed the orchestrator under StrictMode; only these full-run suites catch it).
    @{ area = 'orchestrator run context + harvest (shared engine)'; path = 'tests/continuous-co-review/unit/review-context-and-harvest-hardening.Tests.ps1'; kind = 'pester' }
    @{ area = 'remediation menu + ceiling (shared engine)'; path = 'tests/continuous-co-review/unit/remediation-menu.Tests.ps1'; kind = 'pester' }
    @{ area = 'reviewer independence/fallback (shared engine)'; path = 'tests/continuous-co-review/unit/reviewer-independence-fallback.Tests.ps1'; kind = 'pester' }
    @{ area = 'empty-result retry-once (shared engine)'; path = 'tests/continuous-co-review/unit/empty-result-retry.Tests.ps1'; kind = 'pester' }
    @{ area = 'reviewer hook suppression - empty-exit0 root cause (shared engine)'; path = 'tests/continuous-co-review/unit/reviewer-hook-suppression.Tests.ps1'; kind = 'pester' }
    @{ area = 'file-primary reviewer result - codex empty-stdout file delivery (shared engine)'; path = 'tests/continuous-co-review/unit/reviewer-file-primary-result.Tests.ps1'; kind = 'pester' }
    @{ area = 'reviewed-state digest + exec-bit restoration (T034b partial)'; path = 'tests/continuous-co-review/unit/reviewed-state-digest.Tests.ps1'; kind = 'pester' }
    @{ area = 'universal recorded-run runner - language/framework-neutral evidence (T018/FR-015)'; path = 'tests/continuous-co-review/unit/recorded-run.Tests.ps1'; kind = 'pester' }
    @{ area = 'recorded-run PURE CORE (harness/core split 2026-07-15) - output-meta + record assembly over synthetic facts, NO spawn'; path = 'tests/continuous-co-review/unit/recorded-run-core.Tests.ps1'; kind = 'pester' }
    @{ area = 'T019 review-identity + artifact-lifecycle contracts (characterization, UNWIRED)'; path = 'tests/continuous-co-review/unit/t019-identity-contracts.Tests.ps1'; kind = 'pester' }
    @{ area = 'T019 step 6 per-lineage review lease (atomic acquire, owner-only release, crash recovery)'; path = 'tests/continuous-co-review/unit/lineage-lease.Tests.ps1'; kind = 'pester'; serial = $true }
    @{ area = 'T019 step 6 lease-gated reviewer spawn - suppress on failed acquire (co-review-service)'; path = 'tests/continuous-co-review/unit/co-review-service.Tests.ps1'; kind = 'pester' }
    @{ area = 'T019 step 6 navigator reap - registry-key-drift fix, resolver hardening, lease authority + release'; path = 'tests/continuous-co-review/unit/continuous-co-review-navigator.Tests.ps1'; kind = 'pester'; serial = $true }
    @{ area = 'T041 singular review-authority cutover - legacy/disabled/campaign matrix, no dual authority, fail-closed invalid or missing configuration'; path = 'tests/continuous-co-review/unit/review-authority-cutover.Tests.ps1'; kind = 'pester' }
    @{ area = 'T042-T044 closed authority contracts + pure campaign/run/currentness/finding-lineage policies'; path = 'tests/continuous-co-review/unit/review-authority-core.Tests.ps1'; kind = 'pester' }
    @{ area = 'T045 immutable JSON review store - CreateNew idempotency/conflict, multi-process reservation+claim winners, append-only generations, deterministic reconciliation'; path = 'tests/continuous-co-review/unit/review-authority-store.Tests.ps1'; kind = 'pester'; serial = $true }
    @{ area = 'T046 ReviewTargetPort - external linked Git worktree, exact dirty-state digest/currentness, origin immutability, non-code neutrality'; path = 'tests/continuous-co-review/unit/review-target-port.Tests.ps1'; kind = 'pester' }
    @{ area = 'T047 strict candidate ingress - bounded identity validation, timeout-after-kill ordering, immutable controller JSON + Markdown, partial/moved lineage'; path = 'tests/continuous-co-review/unit/review-result-ingestor.Tests.ps1'; kind = 'pester' }
    @{ area = 'T048 synchronous campaign orchestration - production Git + fixture ports, preflight-before-spend, timeout/crash/recovery/moved/visible-rerun flows, live clock'; path = 'tests/continuous-co-review/unit/review-campaign-orchestrator.Tests.ps1'; kind = 'pester' }
    @{ area = 'T064 frozen-target verification execution, exact-digest evidence join/injection, and pre-spend refusal'; path = 'tests/continuous-co-review/unit/review-campaign-verification.Tests.ps1'; kind = 'pester' }
    @{ area = 'T021 consumer methodology workflow - generic advisory checks, deployed validator path, provider-keyed scratch deployment'; path = 'tests/unit/methodology-gate-template.tests.ps1'; kind = 'script' }
    @{ area = 'T022 consumer work-kind workflow - deployed-only validator path and advisory default'; path = 'tests/unit/work-kind-deployed-resolution.tests.ps1'; kind = 'script' }
    @{ area = 'T023 deny-by-default consumer workflow allowlist - source, package manifest, repository CI, and real deploy'; path = 'tests/unit/consumer-workflow-allowlist.tests.ps1'; kind = 'script' }
    @{ area = 'T024 machine-local Claude host config - fresh-init ordering, gitignore, untracking, and idempotence'; path = 'tests/unit/local-host-config-ignore.tests.ps1'; kind = 'script' }
    @{ area = 'T025 beta1-shaped update healing - exact-hash retired-template removal, modified-file preservation warning, refocus catalog sync'; path = 'tests/integration/distribution-module-update.ps1'; kind = 'script' }
    @{ area = 'T026 greenfield bootstrap commit and brownfield recorded offer/decline - exact subject, clean baseline, no surprise history mutation'; path = 'tests/unit/bootstrap-commit.tests.ps1'; kind = 'script' }
    @{ area = 'T027 release-model resolver and applicable closeout teaching - local/push/PR/publish inference, record-once, named N/A'; path = 'tests/unit/release-model.tests.ps1'; kind = 'script' }
    @{ area = 'T028 consumer technology/delivery applicability firewall - shared rules, advisory/no-mutation, heterogeneous prompt rendering, update/gateway wiring'; path = 'tests/unit/consumer-applicability-firewall.tests.ps1'; kind = 'script' }
    @{ area = 'T053 shared production harness contract - bounded file-primary prompt, catalog dispatch, stdout non-authority, strict malformed-output matrix, no hidden retry'; path = 'tests/continuous-co-review/unit/review-harness-contract.Tests.ps1'; kind = 'pester' }
    @{ area = 'T054 Codex and Copilot production harness adapters - exact catalog vectors, shared contract, file-primary authority, one invocation'; path = 'tests/continuous-co-review/unit/review-codex-copilot-harness.Tests.ps1'; kind = 'pester' }
    @{ area = 'T055 Cursor and Antigravity production harness adapters - verified headless vectors, order-sensitive prompts, shared file-primary authority, one invocation'; path = 'tests/continuous-co-review/unit/review-cursor-antigravity-harness.Tests.ps1'; kind = 'pester' }
    @{ area = 'FR-016/SC-022 host-neutral CCR core - closed auditable host-bound seam, generic policy and orchestration contain no host literals'; path = 'tests/continuous-co-review/governance/host-neutral-core.Tests.ps1'; kind = 'pester' }
    @{ area = 'T056 Windows Job Object production runtime - preflight-before-spend, descendant reap, stream closure, timeout terminal ordering'; path = 'tests/continuous-co-review/unit/review-windows-runtime.Tests.ps1'; kind = 'pester' }
    @{ area = 'T057 Linux cgroup v2 and macOS process-group production runtimes - fail-closed capability, OS dispatch, tree reap, timeout terminal ordering'; path = 'tests/continuous-co-review/unit/review-posix-runtime.Tests.ps1'; kind = 'pester'; serial = $true }
    @{ area = 'T058 non-authoritative progress, heartbeat/timing/usage diagnostics, duplicate warning, and validated-JSON retro provenance'; path = 'tests/continuous-co-review/unit/review-progress-retro.Tests.ps1'; kind = 'pester' }
    @{ area = 'T059 all-adapter deterministic fake-provider matrix - native containment, strict ingress, no hidden retry, timeout-after-tree-death; NEVER live-support evidence'; path = 'tests/continuous-co-review/integration/review-cross-platform-fault-matrix.Tests.ps1'; kind = 'pester' }
    @{ area = 'T060 local macOS execution package - pinned clean clone, explicit one-slot invocation, local-machine provenance, digest/hash/authority validation'; path = 'tests/continuous-co-review/unit/t060-local-macos-evidence.Tests.ps1'; kind = 'pester' }
    @{ area = 'T060 local Windows/Linux execution package - fixed allocations, no-spend preflight, one explicit invocation, fail-closed evidence'; path = 'tests/continuous-co-review/unit/t060-local-platform-smoke.Tests.ps1'; kind = 'pester' }
    # These two integration-heavy suites measured 278–300 seconds in clean
    # detached review worktrees. Preserve the 300-second default for all other
    # suites, but give the known slow paths a bounded 40% environment margin.
    @{ area = 'T051 public campaign delegation + one-way cutover + exact-digest verdict-packet route matrix'; path = 'tests/continuous-co-review/unit/review-public-campaign-command.Tests.ps1'; kind = 'pester'; timeout_seconds = 420 }
    @{ area = 'beta2 release blocker - packaged-artifact Squad-runtime deploy (FileList completeness + contracts deployed)'; path = 'tests/integration/packaged-artifact-deploy.Tests.ps1'; kind = 'pester' }
    @{ area = 'shared trunk resolver - 6-level precedence, no branch mutation (CLI/navigator/gate/baseline/lineage)'; path = 'tests/continuous-co-review/unit/trunk-resolver.Tests.ps1'; kind = 'pester' }
    @{ area = 'T019 FR-048 verification-plan seam contract - plan/command validation, path safety, auditable provenance, bounded timeout, evidence-join'; path = 'tests/continuous-co-review/unit/verification-plan-contract.Tests.ps1'; kind = 'pester' }
    @{ area = 'T019 FR-048 verification-plan runner - ordered execution, record-every-attempt, engine-bounded timeout, never clean-on-failure'; path = 'tests/continuous-co-review/unit/verification-plan-runner.Tests.ps1'; kind = 'pester' }
    @{ area = 'T062 FR-049 deterministic verification-plan supplier - strict precedence, bounded catalog, stable identity, no inferred default'; path = 'tests/continuous-co-review/unit/verification-plan-supplier.Tests.ps1'; kind = 'pester' }
    @{ area = 'T063 FR-049 verification-plan materialization - real source capture, explicit preservation, hash-guarded refresh, actionable no-source'; path = 'tests/continuous-co-review/unit/verification-plan-materializer.Tests.ps1'; kind = 'pester' }
    @{ area = 'T029/FR-039/SC-012 Squad 0.11.0 live-console init - probe and production call receive immediate stdin EOF'; path = 'tests/integration/squad-init-closed-stdin.tests.ps1'; kind = 'script' }
    @{ area = 'T065 SC-015 supplier-to-campaign deterministic project matrix - source precedence, ordered evidence, safe paths, zero-spend failures'; path = 'tests/continuous-co-review/integration/verification-plan-end-to-end.Tests.ps1'; kind = 'pester' }
    @{ area = 'T019 FR-045a stop-intent classifier - continue|intermediate|real precedence, marker corrections, packet consistency'; path = 'tests/continuous-co-review/unit/stop-intent-contract.Tests.ps1'; kind = 'pester' }
    @{ area = 'T019 FR-045a stop-intent WIRING into the conformance Stop-provider - continue directive / intermediate suppress / real fail-safe / boundary-never-downgraded / bounded runaway'; path = 'tests/integration/conformance-stop-intent-wiring.tests.ps1'; kind = 'script' }
    # T086/T087 (iteration 011). Both were authored RED-first and deliberately left UNREGISTERED
    # while red, so the registry could not go green on a known-failing suite. They are registered
    # here now that T088/T089/T090 have made them pass - discharging the obligation recorded in
    # specs/198-beta2-hardening/iterations/011/drift-log.md. A deliberate RED must never quietly
    # become a skipped test, and an unregistered suite is one nobody runs (see DRIFT-198-I011-001,
    # which is that exact failure mode found live in another file).
    @{ area = 'FR-068 verdict-demand reproduction - a demand against a stage with no evidence (half 1, GREEN after T090) plus the emit/do-not-emit marker contradiction (half 2, CHARACTERIZED for beta3)'; path = 'tests/integration/fr068-verdict-demand-reproduction.tests.ps1'; kind = 'script' }
    @{ area = 'DRIFT-198-I011-011 generator parity - governed writers must emit markdown that passes the repository''s OWN required lint, the same markdownlint step consumers are instructed to run'; path = 'tests/integration/generator-markdown-parity.tests.ps1'; kind = 'script' }
    @{ area = 'FR-066 first-boundary arrival - an unrecordable crossing is a branchable state, not a silent success, and the surface names what is missing'; path = 'tests/integration/fr066-first-boundary-arrival.tests.ps1'; kind = 'script' }
    @{ area = 'DRIFT-198-I011-012 shipped orchestration arrival - the skill''s OWN blocks executed in stated order: arrival recorded before the advancement gate, stop carries controller truth, and the gate authorizes the capture-minted first crossing (registered GREEN at slice close, discharging the drift-log obligation)'; path = 'tests/integration/shipped-orchestration-arrival.tests.ps1'; kind = 'script' }
    @{ area = 'FR-055 Stop-packet classification honesty - session-baseline turn-delta, long-turn lane, PostToolUse pre-arrangement nudge, boundary contract untouched, maintainer fixtures (a)-(f)'; path = 'tests/integration/conformance-detection.tests.ps1'; kind = 'script'; timeout_seconds = 420 }
    @{ area = 'FR-056/SC-016 workshop question delivery - shared conduct with deterministic host-specific capability materialization'; path = 'tests/integration/code-rules-skill-multihost.tests.ps1'; kind = 'script' }
    @{ area = 'Beta2 manual-test blocker - Claude workshop cannot call AskUserQuestion and swallow the rendered agenda; other hosts retain structured questions'; path = 'tests/integration/design-workshop-claude-tool-safety.tests.ps1'; kind = 'script' }
    @{ area = 'DRIFT-198-I008-060 pre-agenda controller initialization - exact feature scope, atomic shape, no overwrite, governed complete scaffold only'; path = 'tests/integration/workshop-controller-initialization.tests.ps1'; kind = 'script' }
    @{ area = 'FR-056/SC-016 strict durable workshop lifecycle state - active/complete plus missing-record, out-of-order, and malformed denial'; path = 'tests/bootstrap/ProjectMetadataAccessor.Tests.ps1'; kind = 'script' }
    @{ area = 'T070 host-independent live turn-delta core - fingerprints, consecutive turns, degraded attribution, owner suppression, commit delta'; path = 'tests/unit/conformance-turn-delta.tests.ps1'; kind = 'script' }
    @{ area = 'DRIFT-198-I003-009 state-narrative preservation - task-progress sync refreshes a marker-bounded managed digest and NEVER destroys hand-authored Execution Summary narrative'; path = 'tests/unit/task-progress-managed-summary.tests.ps1'; kind = 'script' }
    @{ area = 'T035 FR-050 host+surface support-tier model - closed set enforced, exact tiers, Copilot-VS-Code/cloud never verified, unknown -> unverified, doctor/status renderer'; path = 'tests/continuous-co-review/unit/host-support-tier.Tests.ps1'; kind = 'pester' }
    @{ area = 'T037 FR-052 Copilot CLI contract (observed 1.0.70) - user-hook governs -p+interactive, repo-hook trustedFolders opt-in, decision-block gate, reviewer-suppression vs bypass'; path = 'tests/continuous-co-review/unit/copilot-cli-contract.Tests.ps1'; kind = 'pester' }
    @{ area = 'FR-053a Prop-145 hook-health - v3 7-field receipt (version_source), INDEPENDENT hook-liveness (healthy|stale|malformed|conflicting|absent) + NON-PROMOTING ambient-path-binding version diagnostic, byte-capped shell-safe probe, receipts are monitoring-not-authenticated'; path = 'tests/continuous-co-review/unit/hook-health-receipt.Tests.ps1'; kind = 'pester' }
    @{ area = 'FR-051/FR-053a Codex headless-governance preflight - ready rests on FRESH hook-liveness (never the version diagnostic) + no ~/.codex mutation + operational-confidence framing, never claims host authentication'; path = 'tests/continuous-co-review/unit/codex-headless-preflight.Tests.ps1'; kind = 'pester' }
    @{ area = 'T036 FR-051 Codex Stop-gate fail-open regression - dispatcher emits well-formed decision-block JSON; malformed/continue-shape/garbage rejected (never a silent bypass)'; path = 'tests/continuous-co-review/unit/codex-stop-gate-fail-open.Tests.ps1'; kind = 'pester' }
    @{ area = 'T039 FR-050/FR-053a host-support/hook-health/evidence reconciliation - codex+copilot cli verified WITH provenance, cloud/Copilot-VS-Code unsupported, unknown->unverified, closed hook-liveness + version-diagnostic sets never health-wash, verified tier != healthy liveness, doctor aggregator surfaces all three'; path = 'tests/continuous-co-review/unit/host-support-reconciliation.Tests.ps1'; kind = 'pester' }
    # iter-005 co-review findings 2/3/4/5 fixed with PRODUCTION-PATH coverage (the prior suites exercised the helpers
    # directly and missed the real firing paths): the REAL dispatcher records a receipt ONLY after the host envelope
    # validates (F2, no false-green) and NEVER persists an ambient secret version (F3, collapses to 'unknown'); the
    # resolver + Codex preflight default path treat 'unknown'/unobserved as unverified not healthy (F5); and the REAL
    # `specrew hooks doctor` command surfaces tiers + hook-health + the Codex preflight without health-washing (F4).
    @{ area = 'Prop-145 production-path honesty - receipt-after-validation, SessionStart ambient version DIAGNOSTIC (env removed, byte-capped, System32 cmd.exe), Stop launches no probe, hook-liveness INDEPENDENT of the non-promoting version, a substituted PATH shim stays diagnostic-only, doctor never claims authentication, `specrew hooks doctor` surfacing'; path = 'tests/integration/f198-iter005-hook-health-production-path.tests.ps1'; kind = 'script' }
)

function Start-F198RegisteredSuite {
    param(
        [Parameter(Mandatory)]$Suite,
        [Parameter(Mandatory)][int]$Index
    )

    $full = Join-Path $repoRoot $Suite.path
    $effectiveTimeoutSeconds = if ($Suite.ContainsKey('timeout_seconds')) {
        [Math]::Max($PerTestTimeoutSeconds, [int]$Suite.timeout_seconds)
    }
    else {
        $PerTestTimeoutSeconds
    }
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        return [pscustomobject][ordered]@{
            completed = $true
            result    = [pscustomobject][ordered]@{
                index = $Index; area = [string]$Suite.area; path = [string]$Suite.path
                kind = [string]$Suite.kind; serial = [bool]($Suite.serial -eq $true)
                status = 'missing'; exit_code = $null; duration_ms = 0; output = ''
                timeout_seconds = $effectiveTimeoutSeconds
            }
        }
    }

    $outFile = [System.IO.Path]::GetTempFileName()
    $errFile = [System.IO.Path]::GetTempFileName()
    if ($Suite.kind -eq 'pester') {
        # FailedCount can remain zero for a failed BeforeAll/AfterAll container.
        # Honor Pester's terminal Result so suite-level failures never become green.
        $cmd = ("`$env:SPECREW_MODULE_PATH='{0}'; `$r = Invoke-Pester -Path '{1}' -Output Detailed -PassThru; if (`$r.Result -ne 'Passed') {{ exit 1 }}; exit 0" -f $repoRoot, $full)
        $procArgs = @('-NoProfile', '-Command', $cmd)
    }
    else {
        $procArgs = @('-NoProfile', '-File', $full)
    }

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $proc = Start-Process pwsh -ArgumentList $procArgs -PassThru -NoNewWindow `
        -RedirectStandardOutput $outFile -RedirectStandardError $errFile `
        -WorkingDirectory $repoRoot

    return [pscustomobject][ordered]@{
        completed = $false
        index = $Index
        suite = $Suite
        process = $proc
        stopwatch = $stopwatch
        stdout_path = $outFile
        stderr_path = $errFile
        timeout_seconds = $effectiveTimeoutSeconds
    }
}

function Complete-F198RegisteredSuite {
    param(
        [Parameter(Mandatory)]$Running,
        [switch]$ForceTimeout
    )

    $proc = $Running.process
    $timedOut = [bool]$ForceTimeout
    if ($timedOut) {
        try { $proc.Kill($true) } catch { $null = $_ }
        try { $null = $proc.WaitForExit(5000) } catch { $null = $_ }
    }
    else {
        # Flush redirected stdout/stderr after the process has reported exit.
        $proc.WaitForExit()
    }
    $Running.stopwatch.Stop()

    $exitCode = if ($timedOut) { $null } else { [int]$proc.ExitCode }
    $output = ((Get-Content -LiteralPath $Running.stdout_path -Raw -ErrorAction SilentlyContinue) +
        "`n" +
        (Get-Content -LiteralPath $Running.stderr_path -Raw -ErrorAction SilentlyContinue))
    Remove-Item -LiteralPath $Running.stdout_path, $Running.stderr_path -Force -ErrorAction SilentlyContinue

    $status = if ($timedOut) {
        'timeout'
    }
    elseif ($exitCode -eq 0) {
        'passed'
    }
    else {
        'failed'
    }

    return [pscustomobject][ordered]@{
        index       = [int]$Running.index
        area        = [string]$Running.suite.area
        path        = [string]$Running.suite.path
        kind        = [string]$Running.suite.kind
        serial      = [bool]($Running.suite.serial -eq $true)
        status      = $status
        exit_code   = $exitCode
        duration_ms = [long]$Running.stopwatch.ElapsedMilliseconds
        output      = [string]$output
        timeout_seconds = [int]$Running.timeout_seconds
    }
}

function Write-F198SuiteResult {
    param(
        [Parameter(Mandatory)]$Result,
        [Parameter(Mandatory)]$Failed
    )

    $seconds = [Math]::Round(([double]$Result.duration_ms / 1000.0), 3)
    switch ([string]$Result.status) {
        'passed' {
            Write-Host ("PASS ({0:N3}s): {1} -> {2}" -f $seconds, $Result.area, $Result.path) -ForegroundColor Green
        }
        'missing' {
            Write-Host ("FAIL (missing, {0:N3}s): {1} -> {2}" -f $seconds, $Result.area, $Result.path) -ForegroundColor Red
            $Failed.Add("$($Result.path) — MISSING") | Out-Null
        }
        'timeout' {
            Write-Host ("FAIL (TIMEOUT > {0}s, elapsed {1:N3}s): {2} -> {3}" -f $Result.timeout_seconds, $seconds, $Result.area, $Result.path) -ForegroundColor Red
            $Failed.Add("$($Result.path) — TIMEOUT (>$($Result.timeout_seconds) s)") | Out-Null
        }
        default {
            Write-Host ("FAIL (exit {0}, {1:N3}s): {2} -> {3}" -f $Result.exit_code, $seconds, $Result.area, $Result.path) -ForegroundColor Red
            Write-Host '----- last 40 lines -----'
            @($Result.output -split "`r?`n") | Select-Object -Last 40 | ForEach-Object { Write-Host "  $_" }
            Write-Host '-------------------------'
            $Failed.Add("$($Result.path) — exit $($Result.exit_code)") | Out-Null
        }
    }
}

$failed = [System.Collections.Generic.List[string]]::new()
$results = [System.Collections.Generic.List[object]]::new()
$callerBaseline = Get-CallerRepositorySnapshot
$registryStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$registryStartedAt = [DateTimeOffset]::UtcNow

for ($index = 0; $index -lt $registry.Count; $index++) {
    $registry[$index]['index'] = $index
    if (-not $registry[$index].ContainsKey('serial')) {
        $registry[$index]['serial'] = $false
    }
}

$parallelSuites = @($registry | Where-Object { -not [bool]$_.serial })
$serialSuites = @($registry | Where-Object { [bool]$_.serial })
if ($Serial) {
    $serialSuites = @($registry)
    $parallelSuites = @()
}

$active = [System.Collections.Generic.List[object]]::new()
$nextParallel = 0
$abortForContamination = $false
while (($nextParallel -lt $parallelSuites.Count) -or ($active.Count -gt 0)) {
    while ((-not $abortForContamination) -and
        ($nextParallel -lt $parallelSuites.Count) -and
        ($active.Count -lt $MaxParallel)) {
        $suite = $parallelSuites[$nextParallel]
        $started = Start-F198RegisteredSuite -Suite $suite -Index ([int]$suite.index)
        $nextParallel++
        if ($started.completed) {
            $results.Add($started.result) | Out-Null
            Write-F198SuiteResult -Result $started.result -Failed $failed
        }
        else {
            $active.Add($started) | Out-Null
        }
    }

    $madeProgress = $false
    foreach ($running in @($active.ToArray())) {
        $timedOut = $running.stopwatch.Elapsed.TotalSeconds -ge $running.timeout_seconds
        if ($running.process.HasExited -or $timedOut) {
            $result = Complete-F198RegisteredSuite -Running $running -ForceTimeout:$timedOut
            $results.Add($result) | Out-Null
            Write-F198SuiteResult -Result $result -Failed $failed
            $active.Remove($running) | Out-Null
            $madeProgress = $true

            $contamination = @(Get-CallerRepositoryContamination -Baseline $callerBaseline)
            if ($contamination.Count -gt 0) {
                Write-Host ("FAIL (CALLER REPOSITORY CONTAMINATED): {0} -> {1}" -f $result.area, ($contamination -join '; ')) -ForegroundColor Red
                $failed.Add("$($result.path) — caller repository contamination") | Out-Null
                $abortForContamination = $true
                foreach ($remaining in @($active.ToArray())) {
                    $aborted = Complete-F198RegisteredSuite -Running $remaining -ForceTimeout
                    $active.Remove($remaining) | Out-Null
                }
                break
            }
        }
    }

    if ($abortForContamination) { break }
    if (-not $madeProgress -and $active.Count -gt 0) {
        Start-Sleep -Milliseconds 100
    }
}

if (-not $abortForContamination) {
    foreach ($suite in $serialSuites) {
        $started = Start-F198RegisteredSuite -Suite $suite -Index ([int]$suite.index)
        if ($started.completed) {
            $result = $started.result
        }
        else {
            $timedOut = -not $started.process.WaitForExit($started.timeout_seconds * 1000)
            $result = Complete-F198RegisteredSuite -Running $started -ForceTimeout:$timedOut
        }
        $results.Add($result) | Out-Null
        Write-F198SuiteResult -Result $result -Failed $failed

        $contamination = @(Get-CallerRepositoryContamination -Baseline $callerBaseline)
        if ($contamination.Count -gt 0) {
            Write-Host ("FAIL (CALLER REPOSITORY CONTAMINATED): {0} -> {1}" -f $result.area, ($contamination -join '; ')) -ForegroundColor Red
            $failed.Add("$($result.path) — caller repository contamination") | Out-Null
            break
        }
    }
}

$registryStopwatch.Stop()
$registryEndedAt = [DateTimeOffset]::UtcNow
$orderedResults = @($results | Sort-Object index)

if (-not [string]::IsNullOrWhiteSpace($TimingOutputPath)) {
    $resolvedTimingPath = if ([System.IO.Path]::IsPathRooted($TimingOutputPath)) {
        $TimingOutputPath
    }
    else {
        Join-Path $repoRoot $TimingOutputPath
    }
    $timingDirectory = Split-Path -Parent $resolvedTimingPath
    if (-not [string]::IsNullOrWhiteSpace($timingDirectory) -and
        -not (Test-Path -LiteralPath $timingDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $timingDirectory -Force | Out-Null
    }
    $timingDocument = [ordered]@{
        schema_version = '1.0'
        mode = if ($Serial) { 'serial' } else { 'bounded-parallel' }
        max_parallel = if ($Serial) { 1 } else { $MaxParallel }
        per_test_timeout_seconds = $PerTestTimeoutSeconds
        started_at = $registryStartedAt.ToString('o')
        ended_at = $registryEndedAt.ToString('o')
        duration_ms = [long]$registryStopwatch.ElapsedMilliseconds
        suite_count = $registry.Count
        failed_count = $failed.Count
        suites = @($orderedResults | ForEach-Object {
                [ordered]@{
                    area = $_.area
                    path = $_.path
                    kind = $_.kind
                    serial = $_.serial
                    status = $_.status
                    exit_code = $_.exit_code
                    duration_ms = $_.duration_ms
                    timeout_seconds = $_.timeout_seconds
                }
            })
    }
    [System.IO.File]::WriteAllText(
        $resolvedTimingPath,
        ($timingDocument | ConvertTo-Json -Depth 8),
        [System.Text.UTF8Encoding]::new($false))
}

Write-Host ''
if ($failed.Count -gt 0) {
    Write-Host ("F-198 honesty regression suite: {0} of {1} FAILED in {2:N3}s" -f $failed.Count, $registry.Count, $registryStopwatch.Elapsed.TotalSeconds) -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
Write-Host ("F-198 honesty regression suite: all {0} suites green in {1:N3}s." -f $registry.Count, $registryStopwatch.Elapsed.TotalSeconds) -ForegroundColor Green
exit 0
