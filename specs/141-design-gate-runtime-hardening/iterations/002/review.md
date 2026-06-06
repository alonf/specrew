# Review: Iteration 002

**Schema**: v1
**Reviewed**: 2026-06-02
**Overall Verdict**: accepted

## Summary

Iteration 002 of feature 141-design-gate-runtime-hardening delivered the start-packet/runtime
hardening bundle plus the folded-in stale cross-worktree session recovery: FR-024 (T007/T008/T009),
FR-011 (T002), FR-014 (T003), the gate-harness verify-clean (T004), tests (T005), and docs (T006).
All nine tasks are `done`, the governance validator reports iteration 002 **PASS**, and the targeted
test suites are green. Verdict: **accepted**.

Reviewed against the maintainer-requested Proposal 145 dimensions (state truth, branch hygiene,
functional correctness, test integrity, evidence integrity).

## Review Dimensions (Proposal 145 framing)

### State truth

- The iteration ledger is internally consistent: file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/002/state.md, file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/002/tasks-progress.yml, and the file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/002/plan.md Status column all agree (T001-T009 done). An earlier task-progress source-of-truth defect (the resume summary read Iteration 1's feature-root `tasks.md` and downgraded Iteration 2's done tasks) was fixed in `3cf2a79e` and is regression-guarded.
- `boundary_enforcement.verdict_history` carries the reconciled `tasks -> before-implement` authorization (`Alon Fliess`, recorded at the current commit/timestamp, **not** backdated — `d4680fb3`); the validator `state-advance-without-verdict` soft-warn is cleared.
- `Current Phase` was deliberately kept at `before-implement` / `Iteration Status: executing` until this review.md existed (claiming `review-signoff` without review.md FAILs the required-artifact check).

### Branch hygiene

- Branch `141-design-gate-runtime-hardening`. Full iteration commit range: **`65e157fa..fcccfad3`** (10 commits), each a focused, boundary-disciplined slice with a descriptive message.
- **`fcccfad3` is the required-CI test fix** (review-signoff send-back): it repaired a pre-existing stale assertion in file:///C:/Dev/Specrew-design-analysis/tests/integration/non-specrew-session-bypass.tests.ps1 that grepped `scripts/specrew-start.ps1` for feature-closeout phrases that had moved into file:///C:/Dev/Specrew-design-analysis/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md. Test-only; no production code touched.
- No unrelated refactors landed; each commit traces to an iteration-002 task or an explicitly-approved reconciliation.

### Functional correctness

- **FR-024 (stale cross-worktree recovery):** strict full-slug `--fixed-strings` merge detection (`65e157fa`) ends the bare-number false positive; the recovery guard refuses to re-anchor to a deleted/external worktree; confirm-gated cleanup clears only runtime refs and **sticks** end-to-end — the enforcement-gap fix (`5d1367d2`) nulls the in-memory session so the end-of-run regeneration cannot silently re-anchor (drift-log Event 1).
- **FR-011 (empty `specs//` paths):** the greenfield orientation browse line no longer emits a `file:///.../specs/<feature>/` URL that collapses to `specs//`; packet-wide grep confirms 0 collapsing-form references in all greenfield artifacts.
- **FR-014 (host-wording leak):** the launch guidance is host-accurate (`Approval mode:`, host-aware delegation); runtime-verified on a Claude launch (no `Copilot` terminology).
- **T004 (gate harness):** verified ALREADY CLEAN — the harness returns `Valid` with `$LASTEXITCODE=0` and no stray error on a valid artifact; the "GATE_VALID: True"/trailing-error symptom was a manual-smoke artifact, not a code path.

### Test integrity

- Reproduce-first was followed: the FR-011, FR-014, task-progress, and stale-detection regressions each FAILED on the pre-fix code and pass after; T004 is a verify-clean guard (passes on current code, locks the behavior).
- Targeted suites (all `exit=0`, 0 FAIL): file:///C:/Dev/Specrew-design-analysis/tests/integration/multi-host-launch-path.tests.ps1 (FR-011 Test 9b + FR-014 Test 18b), file:///C:/Dev/Specrew-design-analysis/tests/integration/start-recovery-flow.tests.ps1 (FR-024 e2e), file:///C:/Dev/Specrew-design-analysis/tests/unit/design-gate-runtime-hardening-session-recovery.tests.ps1 (0 transcript-noise lines), file:///C:/Dev/Specrew-design-analysis/tests/unit/design-gate-runtime-hardening.tests.ps1 (T004 guard), file:///C:/Dev/Specrew-design-analysis/tests/integration/task-progress-tracking.tests.ps1, file:///C:/Dev/Specrew-design-analysis/tests/integration/stale-state-detection.tests.ps1, file:///C:/Dev/Specrew-design-analysis/tests/integration/feature-051-iteration2a-callsite-wiring.tests.ps1, and file:///C:/Dev/Specrew-design-analysis/tests/integration/non-specrew-session-bypass.tests.ps1.
- Mechanical lenses (dead-field / anti-pattern / test-integrity): **0 findings** — file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/002/quality/mechanical-findings.json.
- Coverage posture: focused regression + runtime verification per FR (see file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/002/coverage-evidence.md). Confidence: high for FR-024/FR-011/FR-014.

### Evidence integrity

- **Validator:** `validate-governance.ps1 -NoCacheRead` → iteration 002 **PASS**, no FAIL (scoped, 3 iterations).
- Runtime-vs-form: FR-024 cleanup and FR-011/FR-014 were verified by exercising the real `specrew start` flow, not just file presence. The one source-only assertion (FR-014 new-window delegation line 3985, not reachable under `-NoLaunch`) is labeled as such in state.md.
- No new dependencies (pure PowerShell) — see file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/002/dependency-report.md.
- The reviewer code-map/coverage-evidence carry a Proposal-073 form-vs-meaning **WARNING** (9 tasks vs 27 files in the diff from baseline `464e0d3e`). Expected and benign: the 27-file diff spans the full multi-slice iteration — the Slice-1 session-recovery extraction (prior-session commits) + FR-024/FR-011/FR-014 + tests + iteration artifacts — all committed. No uncommitted implementation exists; the validator reports iteration 002 PASS.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-011, FR-014, FR-015 | pass | Reproduced empty-path + host-wording; recorded in drift-log Reproduction Evidence. |
| T002 | FR-011 | pass | Greenfield browse-line guard; packet-wide verified (0 collapsing-form refs). |
| T003 | FR-014 | pass | Two host-wording leaks fixed (approval-mode 3916 runtime-verified; delegation 3985 source-asserted). |
| T004 | FR-015 | pass | Verify-clean (no code defect) + durable guard test; maintainer-approved disposition. |
| T005 | SC-007, SC-010 | pass | no-`specs//` (Test 9b) + per-host wording (Test 18b) + clean-harness-exit (T004 guard). |
| T007 | FR-024 | pass | Stale detection + no-re-anchor guard; strict merge detection. |
| T008 | FR-024 | pass | Confirm-gated cleanup (runtime-only, no artifacts/commits) + enforcement bridge. |
| T009 | FR-024 | pass | Unit + e2e enforcement test; caught and drove the stick fix. |
| T006 | TG-006 | pass | quickstart + contract notes refreshed to as-built Iteration 2. |

## Gap Ledger

- No requirement (FR/SC) gaps: all in-scope requirements verified: fixed-now.

## Follow-ups (not iteration-002 requirement gaps)

- **`recorded_at` datetime coercion** — the start-context regeneration round-trips `recorded_at` through `ConvertTo-Json`/`ConvertFrom-Json`, coercing the ISO-8601 string to a culture-formatted `MM/dd/yyyy` DateTime on the session-preserved path. Recorded as a **follow-up, not completed work** (moot on the FR-024 cleared-session path where session_state is null). Candidate for a later iteration.

## Dirty-file classification (working tree, not part of this iteration)

All iteration-002 source work is committed (`65e157fa..fcccfad3`). The remaining working-tree changes are runtime/pre-existing churn and were **not** committed (no justification to):

- Deployed agent definitions (`.claude/agents/*.md`, `.codex/agents/*.toml`, `.github/agents/squad.agent.md`) — re-sync churn from `specrew start`/`init`.
- Squad runtime ledgers (`.squad/decisions.md` routing ledger, `.squad/casting/registry.json`).
- Runtime caches (`.specrew/last-validator-summary.json`, untracked `.specrew/active-sessions.yml`, `.specrew/version-check-cache.json`).
- Other features' scaffolded ledgers (`specs/051-.../iterations/003/tasks-progress.yml`, untracked `specs/140-.../iterations/001/tasks-progress.yml`).
- Cursor host scaffold (untracked `.cursor/`).

## Notes

- Per-task drift was tracked in file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/002/drift-log.md (Event 1 = the FR-024 enforcement gap, fixed-now; plus the reproduction/verify-clean evidence).
- Reviewer artifacts: file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/002/reviewer-index.md, code-map.md, coverage-evidence.md, review-diagrams.md, dependency-report.md.
