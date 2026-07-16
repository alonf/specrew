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
param([int]$PerTestTimeoutSeconds = 300)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

$registry = @(
    @{ area = 'boundary ratchet (FR-001..FR-005, cycle-scoped)'; path = 'tests/unit/boundary-ratchet.tests.ps1'; kind = 'script' }
    @{ area = 'append-only scoped authorization correction ledger (FR-004/SC-014)'; path = 'tests/unit/boundary-correction-ledger.tests.ps1'; kind = 'script' }
    @{ area = 'budget resolution + provenance (FR-021..FR-023)'; path = 'tests/unit/budget-resolution.tests.ps1'; kind = 'script' }
    @{ area = 'tracker honesty check (FR-020)'; path = 'tests/unit/tracker-honesty-check.tests.ps1'; kind = 'script' }
    @{ area = 'self-leak firewall (FR-033/FR-037)'; path = 'tests/unit/self-leak-lint.tests.ps1'; kind = 'script' }
    @{ area = 'verdict-capture integrity (FR-041..FR-044)'; path = 'tests/integration/verdict-capture-blocks.tests.ps1'; kind = 'script' }
    @{ area = 'reviewer containment (FR-008/SC-002)'; path = 'tests/continuous-co-review/unit/worktree-containment.Tests.ps1'; kind = 'pester' }
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
    @{ area = 'T019 step 6 per-lineage review lease (atomic acquire, owner-only release, crash recovery)'; path = 'tests/continuous-co-review/unit/lineage-lease.Tests.ps1'; kind = 'pester' }
    @{ area = 'T019 step 6 lease-gated reviewer spawn - suppress on failed acquire (co-review-service)'; path = 'tests/continuous-co-review/unit/co-review-service.Tests.ps1'; kind = 'pester' }
    @{ area = 'T019 step 6 navigator reap - registry-key-drift fix, resolver hardening, lease authority + release'; path = 'tests/continuous-co-review/unit/continuous-co-review-navigator.Tests.ps1'; kind = 'pester' }
    @{ area = 'T041 singular review-authority cutover - legacy/disabled/campaign matrix, no dual authority, fail-closed invalid or missing configuration'; path = 'tests/continuous-co-review/unit/review-authority-cutover.Tests.ps1'; kind = 'pester' }
    @{ area = 'T042-T044 closed authority contracts + pure campaign/run/currentness/finding-lineage policies'; path = 'tests/continuous-co-review/unit/review-authority-core.Tests.ps1'; kind = 'pester' }
    @{ area = 'T045 immutable JSON review store - CreateNew idempotency/conflict, multi-process reservation+claim winners, append-only generations, deterministic reconciliation'; path = 'tests/continuous-co-review/unit/review-authority-store.Tests.ps1'; kind = 'pester' }
    @{ area = 'T046 ReviewTargetPort - external linked Git worktree, exact dirty-state digest/currentness, origin immutability, non-code neutrality'; path = 'tests/continuous-co-review/unit/review-target-port.Tests.ps1'; kind = 'pester' }
    @{ area = 'T047 strict candidate ingress - bounded identity validation, timeout-after-kill ordering, immutable controller JSON + Markdown, partial/moved lineage'; path = 'tests/continuous-co-review/unit/review-result-ingestor.Tests.ps1'; kind = 'pester' }
    @{ area = 'T048 synchronous campaign orchestration - production Git + fixture ports, preflight-before-spend, timeout/crash/recovery/moved/visible-rerun flows, live clock'; path = 'tests/continuous-co-review/unit/review-campaign-orchestrator.Tests.ps1'; kind = 'pester' }
    @{ area = 'T053 shared production harness contract - bounded file-primary prompt, catalog dispatch, stdout non-authority, strict malformed-output matrix, no hidden retry'; path = 'tests/continuous-co-review/unit/review-harness-contract.Tests.ps1'; kind = 'pester' }
    @{ area = 'T054 Codex and Copilot production harness adapters - exact catalog vectors, shared contract, file-primary authority, one invocation'; path = 'tests/continuous-co-review/unit/review-codex-copilot-harness.Tests.ps1'; kind = 'pester' }
    @{ area = 'T055 Cursor and Antigravity production harness adapters - verified headless vectors, order-sensitive prompts, shared file-primary authority, one invocation'; path = 'tests/continuous-co-review/unit/review-cursor-antigravity-harness.Tests.ps1'; kind = 'pester' }
    @{ area = 'T051 public campaign delegation + one-way cutover + exact-digest verdict-packet route matrix'; path = 'tests/continuous-co-review/unit/review-public-campaign-command.Tests.ps1'; kind = 'pester' }
    @{ area = 'beta2 release blocker - packaged-artifact Squad-runtime deploy (FileList completeness + contracts deployed)'; path = 'tests/integration/packaged-artifact-deploy.Tests.ps1'; kind = 'pester' }
    @{ area = 'shared trunk resolver - 6-level precedence, no branch mutation (CLI/navigator/gate/baseline/lineage)'; path = 'tests/continuous-co-review/unit/trunk-resolver.Tests.ps1'; kind = 'pester' }
    @{ area = 'T019 FR-048 verification-plan seam contract - plan/command validation, path safety, auditable provenance, bounded timeout, evidence-join'; path = 'tests/continuous-co-review/unit/verification-plan-contract.Tests.ps1'; kind = 'pester' }
    @{ area = 'T019 FR-048 verification-plan runner - ordered execution, record-every-attempt, engine-bounded timeout, never clean-on-failure'; path = 'tests/continuous-co-review/unit/verification-plan-runner.Tests.ps1'; kind = 'pester' }
    @{ area = 'T019 FR-045a stop-intent classifier - continue|intermediate|real precedence, marker corrections, packet consistency'; path = 'tests/continuous-co-review/unit/stop-intent-contract.Tests.ps1'; kind = 'pester' }
    @{ area = 'T019 FR-045a stop-intent WIRING into the conformance Stop-provider - continue directive / intermediate suppress / real fail-safe / boundary-never-downgraded / bounded runaway'; path = 'tests/integration/conformance-stop-intent-wiring.tests.ps1'; kind = 'script' }
    @{ area = 'FR-055 Stop-packet classification honesty - session-baseline turn-delta, long-turn lane, PostToolUse pre-arrangement nudge, boundary contract untouched, maintainer fixtures (a)-(f)'; path = 'tests/integration/conformance-detection.tests.ps1'; kind = 'script' }
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

$failed = New-Object System.Collections.Generic.List[string]
foreach ($t in $registry) {
    $full = Join-Path $repoRoot $t.path
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        Write-Host ("FAIL (missing): {0} -> {1}" -f $t.area, $t.path) -ForegroundColor Red
        $failed.Add("$($t.path) — MISSING") | Out-Null
        continue
    }
    $outFile = [System.IO.Path]::GetTempFileName()
    $errFile = [System.IO.Path]::GetTempFileName()
    if ($t.kind -eq 'pester') {
        $cmd = ("`$env:SPECREW_MODULE_PATH='{0}'; `$r = Invoke-Pester -Path '{1}' -Output Detailed -PassThru; exit ([int]`$r.FailedCount)" -f $repoRoot, $full)
        $procArgs = @('-NoProfile', '-Command', $cmd)
    }
    else {
        $procArgs = @('-NoProfile', '-File', $full)
    }
    $proc = Start-Process pwsh -ArgumentList $procArgs -PassThru -NoNewWindow -RedirectStandardOutput $outFile -RedirectStandardError $errFile -WorkingDirectory $repoRoot
    $exited = $proc.WaitForExit($PerTestTimeoutSeconds * 1000)
    if (-not $exited) {
        try { $proc.Kill($true) } catch { $null = $_ }
        Write-Host ("FAIL (TIMEOUT > {0}s): {1} -> {2}" -f $PerTestTimeoutSeconds, $t.area, $t.path) -ForegroundColor Red
        $failed.Add("$($t.path) — TIMEOUT (>$PerTestTimeoutSeconds s)") | Out-Null
        Remove-Item -LiteralPath $outFile, $errFile -Force -ErrorAction SilentlyContinue
        continue
    }
    $proc.WaitForExit()
    $exit = $proc.ExitCode
    $out = ((Get-Content -LiteralPath $outFile -Raw -ErrorAction SilentlyContinue) + "`n" + (Get-Content -LiteralPath $errFile -Raw -ErrorAction SilentlyContinue))
    Remove-Item -LiteralPath $outFile, $errFile -Force -ErrorAction SilentlyContinue
    if ($exit -ne 0) {
        Write-Host ("FAIL (exit {0}): {1} -> {2}" -f $exit, $t.area, $t.path) -ForegroundColor Red
        Write-Host "----- last 40 lines -----"
        @($out -split "`r?`n") | Select-Object -Last 40 | ForEach-Object { Write-Host "  $_" }
        Write-Host "-------------------------"
        $failed.Add("$($t.path) — exit $exit") | Out-Null
    }
    else {
        Write-Host ("PASS: {0} -> {1}" -f $t.area, $t.path) -ForegroundColor Green
    }
}

Write-Host ""
if ($failed.Count -gt 0) {
    Write-Host ("F-198 honesty regression suite: {0} of {1} FAILED" -f $failed.Count, $registry.Count) -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
Write-Host ("F-198 honesty regression suite: all {0} suites green." -f $registry.Count) -ForegroundColor Green
exit 0
