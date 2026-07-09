# Code Map: Iteration 010

**Schema**: v1
**Reviewed**: 2026-07-08
**Baseline Ref**: 16bc485f6cb38b783963095ee360481ba8335562
**Test-to-Code Ratio**: 20:18

> **⚠️ Review Evidence Warning** _(Form-vs-Meaning Gap Detected)_
>
> This iteration's task tracking declares **11 completed task(s)**, but the git diff against baseline `16bc485f6cb38b783963095ee360481ba8335562` contains **65 file(s)**.
>
> **Severity**: WARNING  
> **Implication**: Review evidence may be incomplete or misleading.
>
> **Possible causes**:
>
> - Implementation work was not committed before scaffolding review artifacts
> - Task status markers in plan.md or review.md do not match actual progress
> - Baseline reference in state.md is stale or incorrect
>
> **Remediation**:
>
> 1. Verify implementation is committed: `git diff 16bc485f6cb38b783963095ee360481ba8335562...HEAD --stat`
> 2. If uncommitted work exists: `git add . && git commit -m "Implementation complete"`
> 3. Re-run scaffolder with `-Force` flag to regenerate review artifacts after commit
> 4. Re-run `validate-governance.ps1` to clear pre-review commit gate error
>
> _See Proposal 073 (Review Evidence Integrity) for background on this validation._

---

## Files Touched

| Path | Lines Added | Lines Removed | Owning Task ID(s) | Owning Role |
| ---- | ----------- | ------------- | ----------------- | ----------- |
| .specify/extensions/specrew-speckit/scripts/specrew-co-review-navigator-provider.ps1 | 7 | 3 | T093, T096, T099, T106, T107, T108 | Implementer |
| .specify/extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1 | 8 | 4 | T093, T096, T099, T106, T107, T108 | Implementer |
| .specrew/iteration-config.yml | 11 | 1 | T093, T096, T099, T106, T107, T108 | Implementer |
| .squad/active-features.yml | 1 | 1 | T093, T096, T099, T106, T107, T108 | Implementer |
| .squad/decisions.md | 9 | 0 | T093, T096, T099, T106, T107, T108 | Implementer |
| .squad/events/lifecycle-events.jsonl | 1 | 0 | T093, T096, T099, T106, T107, T108 | Implementer |
| .squad/identity/now.md | 6 | 6 | T093, T096, T099, T106, T107, T108 | Implementer |
| Specrew.psd1 | 0 | 1 | T093, T096, T099, T106, T107, T108 | Implementer |
| {scripts/internal/continuous-co-review => docs/reference}/code-review-agent.md | 16 | 4 | T093, T096, T099, T106, T107, T108 | Implementer |
| extensions/specrew-speckit/scripts/specrew-co-review-navigator-provider.ps1 | 7 | 3 | T093, T096, T099, T106, T107, T108 | Implementer |
| extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1 | 8 | 4 | T093, T096, T099, T106, T107, T108 | Implementer |
| scripts/internal/agent-tasks/isolated-task-launcher.ps1 | 73 | 1 | T093, T096, T099, T106, T107, T108 | Implementer |
| scripts/internal/agent-tasks/isolated-task-supervisor.ps1 | 67 | 22 | T093, T096, T099, T106, T107, T108 | Implementer |
| scripts/internal/agent-tasks/process-tree.ps1 | 269 | 2 | T093, T096, T099, T106, T107, T108 | Implementer |
| scripts/internal/continuous-co-review/_load.ps1 | 1 | 0 | T093, T096, T099, T106, T107, T108 | Implementer |
| scripts/internal/continuous-co-review/co-review-service.ps1 | 11 | 2 | T093, T096, T099, T106, T107, T108 | Implementer |
| scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1 | 164 | 12 | T093, T096, T099, T106, T107, T108 | Implementer |
| scripts/internal/continuous-co-review/review-run-index-writer.ps1 | 11 | 0 | T093, T096, T099, T106, T107, T108 | Implementer |
| scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1 | 97 | 5 | T093, T096, T099, T106, T107, T108 | Implementer |
| scripts/internal/continuous-co-review/reviewer-selection-policy.ps1 | 27 | 12 | T093, T096, T099, T106, T107, T108 | Implementer |
| scripts/internal/continuous-co-review/worktree-navigator.ps1 | 4 | 1 | T093, T096, T099, T106, T107, T108 | Implementer |
| scripts/internal/continuous-co-review/worktree-review-detached-entry.ps1 | 5 | 0 | T093, T096, T099, T106, T107, T108 | Implementer |
| scripts/internal/continuous-co-review/worktree-review-orchestrator.ps1 | 238 | 22 | T093, T096, T099, T106, T107, T108 | Implementer |
| scripts/internal/continuous-co-review/worktree-reviewer.ps1 | 240 | 73 | T093, T096, T099, T106, T107, T108 | Implementer |
| scripts/specrew-review.ps1 | 83 | 4 | T093, T096, T099, T106, T107, T108 | Implementer |
| specs/197-continuous-co-review/current-architecture.md | 15 | 0 | T093, T096, T099, T106, T107, T108 | Implementer |
| specs/197-continuous-co-review/iterations/009/code-map.md | 145 | 0 | T093, T096, T099, T106, T107, T108 | Implementer |
| specs/197-continuous-co-review/iterations/009/coverage-evidence.md | 66 | 0 | T093, T096, T099, T106, T107, T108 | Implementer |
| specs/197-continuous-co-review/iterations/009/dashboard.md | 38 | 0 | T093, T096, T099, T106, T107, T108 | Implementer |
| specs/197-continuous-co-review/iterations/009/dependency-report.md | 48 | 0 | T093, T096, T099, T106, T107, T108 | Implementer |
| specs/197-continuous-co-review/iterations/009/plan.md | 7 | 6 | T093, T096, T099, T106, T107, T108 | Implementer |
| specs/197-continuous-co-review/iterations/009/retro.md | 166 | 0 | T093, T096, T099, T106, T107, T108 | Implementer |
| specs/197-continuous-co-review/iterations/009/review-diagrams.md | 54 | 0 | T093, T096, T099, T106, T107, T108 | Implementer |
| specs/197-continuous-co-review/iterations/009/review.md | 56 | 0 | T093, T096, T099, T106, T107, T108 | Implementer |
| specs/197-continuous-co-review/iterations/009/reviewer-index.md | 63 | 0 | T093, T096, T099, T106, T107, T108 | Implementer |
| specs/197-continuous-co-review/iterations/009/state.md | 5 | 4 | T093, T096, T099, T106, T107, T108 | Implementer |
| specs/197-continuous-co-review/iterations/010/design-analysis.md | 127 | 0 | T093, T096, T099, T106, T107, T108 | Implementer |
| specs/197-continuous-co-review/iterations/010/drift-log.md | 76 | 0 | T093, T096, T099, T106, T107, T108 | Implementer |
| specs/197-continuous-co-review/iterations/010/plan.md | 84 | 0 | T093, T096, T099, T106, T107, T108 | Implementer |
| specs/197-continuous-co-review/iterations/010/quality/cross-host-validation.md | 72 | 0 | T093, T096, T099, T106, T107, T108 | Implementer |
| specs/197-continuous-co-review/iterations/010/quality/flush-race-forensic.md | 60 | 0 | T093, T096, T099, T106, T107, T108 | Implementer |
| specs/197-continuous-co-review/iterations/010/quality/hardening-gate.md | 40 | 0 | T093, T096, T099, T106, T107, T108 | Implementer |
| specs/197-continuous-co-review/iterations/010/state.md | 50 | 0 | T093, T096, T099, T106, T107, T108 | Implementer |
| specs/197-continuous-co-review/iterations/010/tasks-progress.yml | 71 | 0 | T093, T096, T099, T106, T107, T108 | Implementer |
| specs/197-continuous-co-review/tasks.md | 19 | 1 | T093, T096, T099, T106, T107, T108 | Implementer |
| tests/continuous-co-review/contracts/reviewer-instruction.Tests.ps1 | 66 | 31 | T091, T094, T096, T100, T106, T107, T109, T110 | Architect |
| tests/continuous-co-review/fixtures/contracts/reviewer-instruction.expected-markers.json | 0 | 21 | T091, T094, T096, T100, T106, T107, T109, T110 | Architect |
| tests/continuous-co-review/governance/host-neutral-core.Tests.ps1 | 44 | 0 | T091, T094, T096, T100, T106, T107, T109, T110 | Architect |
| tests/continuous-co-review/integration/escalation-latch-wiring.Tests.ps1 | 167 | 0 | T091, T094, T096, T100, T106, T107, T109, T110 | Architect |
| tests/continuous-co-review/integration/signoff-gate-digest-promotion.Tests.ps1 | 3 | 3 | T091, T094, T096, T100, T106, T107, T109, T110 | Architect |
| tests/continuous-co-review/integration/signoff-gate-digest-threading.Tests.ps1 | 5 | 1 | T091, T094, T096, T100, T106, T107, T109, T110 | Architect |
| tests/continuous-co-review/unit/conformance-material-turn-gate.Tests.ps1 | 55 | 0 | T091, T094, T096, T100, T106, T107, T109, T110 | Architect |
| tests/continuous-co-review/unit/degraded-evidence-gate.Tests.ps1 | 129 | 0 | T091, T094, T096, T100, T106, T107, T109, T110 | Architect |
| tests/continuous-co-review/unit/empty-result-retry.Tests.ps1 | 92 | 0 | T091, T094, T096, T100, T106, T107, T109, T110 | Architect |
| tests/continuous-co-review/unit/flush-race-forensic.Tests.ps1 | 49 | 0 | T091, T094, T096, T100, T106, T107, T109, T110 | Architect |
| tests/continuous-co-review/unit/inline-reviewer-containment.Tests.ps1 | 152 | 0 | T091, T094, T096, T100, T106, T107, T109, T110 | Architect |
| tests/continuous-co-review/unit/isolated-task-containment.Tests.ps1 | 243 | 0 | T091, T094, T096, T100, T106, T107, T109, T110 | Architect |
| tests/continuous-co-review/unit/isolated-task-launcher.Tests.ps1 | 4 | 1 | T091, T094, T096, T100, T106, T107, T109, T110 | Architect |
| tests/continuous-co-review/unit/isolated-task-tree-kill.Tests.ps1 | 2 | 1 | T091, T094, T096, T100, T106, T107, T109, T110 | Architect |
| tests/continuous-co-review/unit/remediation-menu.Tests.ps1 | 219 | 0 | T091, T094, T096, T100, T106, T107, T109, T110 | Architect |
| tests/continuous-co-review/unit/review-context-and-harvest-hardening.Tests.ps1 | 185 | 0 | T091, T094, T096, T100, T106, T107, T109, T110 | Architect |
| tests/continuous-co-review/unit/review-signoff-evidence-gate.Tests.ps1 | 5 | 1 | T091, T094, T096, T100, T106, T107, T109, T110 | Architect |
| tests/continuous-co-review/unit/reviewer-host-catalog.Tests.ps1 | 4 | 1 | T091, T094, T096, T100, T106, T107, T109, T110 | Architect |
| tests/continuous-co-review/unit/reviewer-independence-fallback.Tests.ps1 | 140 | 0 | T091, T094, T096, T100, T106, T107, T109, T110 | Architect |
| tests/continuous-co-review/unit/signoff-gate-wiring.Tests.ps1 | 3 | 1 | T091, T094, T096, T100, T106, T107, T109, T110 | Architect |

## Public-API Delta

### Added

- Get-SpecrewIsolatedTaskSessionId (scripts/internal/agent-tasks/isolated-task-launcher.ps1)
- Import-SpecrewIsolatedTaskProcessTree (scripts/internal/agent-tasks/isolated-task-launcher.ps1)
- Initialize-SpecrewProcessContainmentRuntime (scripts/internal/agent-tasks/process-tree.ps1)
- Initialize-SpecrewJobObjectType (scripts/internal/agent-tasks/process-tree.ps1)
- Get-SpecrewProcessGroupId (scripts/internal/agent-tasks/process-tree.ps1)
- New-SpecrewProcessContainment (scripts/internal/agent-tasks/process-tree.ps1)
- Stop-SpecrewProcessContainment (scripts/internal/agent-tasks/process-tree.ps1)
- Close-SpecrewProcessContainment (scripts/internal/agent-tasks/process-tree.ps1)
- Get-ContinuousCoReviewRunEvidenceLabels (scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1)
- Test-ContinuousCoReviewEvidenceIsDegraded (scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1)
- Add-ContinuousCoReviewDegradedAck (scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1)
- Get-ContinuousCoReviewDegradedAck (scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1)
- Set-ContinuousCoReviewRemediationChoice (scripts/internal/continuous-co-review/worktree-review-orchestrator.ps1)
- Read-ContinuousCoReviewRemediationChoice (scripts/internal/continuous-co-review/worktree-review-orchestrator.ps1)
- the (specs/197-continuous-co-review/iterations/009/retro.md)
- script (tests/continuous-co-review/integration/escalation-latch-wiring.Tests.ps1)
- Invoke-GateGit (tests/continuous-co-review/unit/degraded-evidence-gate.Tests.ps1)
- New-FeatureRepo (tests/continuous-co-review/unit/degraded-evidence-gate.Tests.ps1)
- Write-LabelledPassRun (tests/continuous-co-review/unit/degraded-evidence-gate.Tests.ps1)
- New-FreshRepoWithRun (tests/continuous-co-review/unit/degraded-evidence-gate.Tests.ps1)
- script (tests/continuous-co-review/unit/inline-reviewer-containment.Tests.ps1)
- script (tests/continuous-co-review/unit/isolated-task-containment.Tests.ps1)
- script (tests/continuous-co-review/unit/remediation-menu.Tests.ps1)
- script (tests/continuous-co-review/unit/review-context-and-harvest-hardening.Tests.ps1)
- script (tests/continuous-co-review/unit/reviewer-independence-fallback.Tests.ps1)

### Removed

- none

## Module Hotspots

- Threshold: 250 changed lines per file
- scripts/internal/agent-tasks/process-tree.ps1 (271 changed lines)
- scripts/internal/continuous-co-review/worktree-review-orchestrator.ps1 (260 changed lines)
- scripts/internal/continuous-co-review/worktree-reviewer.ps1 (313 changed lines)
