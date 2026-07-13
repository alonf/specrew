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
    @{ area = 'T019 review-identity + artifact-lifecycle contracts (characterization, UNWIRED)'; path = 'tests/continuous-co-review/unit/t019-identity-contracts.Tests.ps1'; kind = 'pester' }
    @{ area = 'T019 step 6 per-lineage review lease (atomic acquire, owner-only release, crash recovery)'; path = 'tests/continuous-co-review/unit/lineage-lease.Tests.ps1'; kind = 'pester' }
    @{ area = 'T019 step 6 lease-gated reviewer spawn - suppress on failed acquire (co-review-service)'; path = 'tests/continuous-co-review/unit/co-review-service.Tests.ps1'; kind = 'pester' }
    @{ area = 'T019 step 6 navigator reap - registry-key-drift fix, resolver hardening, lease authority + release'; path = 'tests/continuous-co-review/unit/continuous-co-review-navigator.Tests.ps1'; kind = 'pester' }
    @{ area = 'beta2 release blocker - packaged-artifact Squad-runtime deploy (FileList completeness + contracts deployed)'; path = 'tests/integration/packaged-artifact-deploy.Tests.ps1'; kind = 'pester' }
    @{ area = 'shared trunk resolver - 6-level precedence, no branch mutation (CLI/navigator/gate/baseline/lineage)'; path = 'tests/continuous-co-review/unit/trunk-resolver.Tests.ps1'; kind = 'pester' }
    @{ area = 'T019 FR-048 verification-plan seam contract - plan/command validation, path safety, auditable provenance, bounded timeout, evidence-join'; path = 'tests/continuous-co-review/unit/verification-plan-contract.Tests.ps1'; kind = 'pester' }
    @{ area = 'T019 FR-048 verification-plan runner - ordered execution, record-every-attempt, engine-bounded timeout, never clean-on-failure'; path = 'tests/continuous-co-review/unit/verification-plan-runner.Tests.ps1'; kind = 'pester' }
    @{ area = 'T019 FR-045a stop-intent classifier - continue|intermediate|real precedence, marker corrections, packet consistency'; path = 'tests/continuous-co-review/unit/stop-intent-contract.Tests.ps1'; kind = 'pester' }
    @{ area = 'T019 FR-045a stop-intent WIRING into the conformance Stop-provider - continue directive / intermediate suppress / real fail-safe / boundary-never-downgraded / bounded runaway'; path = 'tests/integration/conformance-stop-intent-wiring.tests.ps1'; kind = 'script' }
    @{ area = 'T035 FR-050 host+surface support-tier model - closed set enforced, exact tiers, Copilot-VS-Code/cloud never verified, unknown -> unverified, doctor/status renderer'; path = 'tests/continuous-co-review/unit/host-support-tier.Tests.ps1'; kind = 'pester' }
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
