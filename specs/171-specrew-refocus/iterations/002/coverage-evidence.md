# Coverage Evidence: Iteration 002 — research-gated host bindings, carries, docs, beta evidence

**Schema**: v1
**Reviewed**: 2026-06-07
**Overall Verdict**: accepted

> **Review Evidence Warning disposition** _(reviewed, explained)_: the scaffold flagged 5 tasks vs 39 changed files against baseline `3ba1d8d7`. Decomposition: 19 implementation files (deploy-refocus-hooks ×3 trees, dispatcher ×3 trees, catalog ×2 trees, implement/plan digests ×2 trees [retro-action rules], refocus-deploy-integration ×1, init+update wiring ×2, Specrew.psd1, hosts/{codex,copilot,cursor}/host.psd1 ×3) + 2 test suites + 3 docs (README, user-guide, troubleshooting) + 9 spec/lifecycle artifacts (research-matrix, beta-validation, spec D-002, tasks, 001 retro, 002 plan/state/drift-log/hardening-gate) + 6 squad/runtime state-trail files. Every implementation file is committed and traceable to a T0NN boundary commit — the count gap is the governed-lifecycle artifact trail, not unexplained churn.

---

## Test Strategy

- Implementation briefing: (unavailable)
- Review-time strategy: use `reviewer.test_commands` when configured; otherwise record `not_executed` explicitly and keep the signal visible in closeout output.

## Tests Run

| Command | Result | Pass Count | Fail Count | Duration | Exit Code | Notes |
| ------- | ------ | ---------- | ---------- | -------- | --------- | ----- |
| & '.\\tests\\integration\\refocus-engine.tests.ps1' | pass | 40 | 0 | ~01:10 | 0 | Re-run at review time after `64a908e7` — no engine changes this iteration; regression-clean |
| & '.\\tests\\integration\\refocus-digests.tests.ps1' | pass | 118 | 0 | ~00:25 | 0 | Re-run at review time — digest family + drift comparator regression-clean |
| & '.\\tests\\integration\\refocus-catalog.tests.ps1' | pass | 74 | 0 | ~00:20 | 0 | Re-run at review time — provider row gained UserPromptSubmit (T014); dormant-seat invariants still hold |
| & '.\\tests\\integration\\refocus-channels.tests.ps1' | pass | 21 | 0 | ~00:40 | 0 | Re-run at review time — channel 1 through REAL wrapper + sync regression-clean |
| & '.\\tests\\integration\\refocus-dispatcher.tests.ps1' | pass | 65 | 0 | ~02:30 | 0 | T014 deliverable — 58→65: per-host event-shape fixtures (codex/copilot/cursor session keys + injection output shaping) |
| & '.\\tests\\integration\\refocus-deploy.tests.ps1' | pass | 58 | 0 | ~00:45 | 0 | T014+T017 deliverable — 19→58: codex/copilot/cursor writers + overlay merge round-trip/fail-safe + wiring content/ordering/parse asserts |
| & '.\\tests\\integration\\filelist-completeness.tests.ps1' | pass | 3 | 0 | ~00:10 | 0 | T017 — bidirectional FileList gate green with refocus-deploy-integration.ps1 declared (262 entries) |
| & '.\\tests\\integration\\update-command.ps1' | pass | all | 0 | ~01:30 | 0 | T017 consumer-side demonstration (producer/consumer rule): the REAL `specrew update` lane green with the overlay+hook wiring in the path |
| & '.\\tests\\integration\\bootstrap-to-iteration.ps1' | pass | all | 0 | ~04:00 | 0 | T017 consumer-side demonstration: the REAL greenfield `specrew init` e2e green with the refocus-hooks deploy step in the path |
| & '.\\tests\\integration\\quality-profile-foundation.ps1' | pass | 1 | 0 | 00:00:03.4123338 | 0 | PASS: Quality profile foundation scaffold and Phase 1/Phase 2 planning contracts expose versioned quality assets, bounded hardening metadata, preserve local overrides, and define recognized-stack/custom-composition expectations |
| & '.\\tests\\integration\\mechanical-findings-contract.ps1' | pass | 1 | 0 | 00:00:01.0914768 | 0 | PASS: Mechanical findings contract fixtures keep the Phase 1 rule set schema-compliant and make demoted rules remain visible with disposition references |
| & '.\\tests\\integration\\quality-evidence-governance.ps1' | pass | 1 | 0 | 00:00:29.8066469 | 0 | PASS: Quality evidence governance regressions passed. |
| & '.\\tests\\integration\\process-quality-scorer.ps1' | pass | 1 | 0 | 00:00:02.2263633 | 0 | PASS: Process scorer returns structured artifact and phase adherence results |
| & '.\\tests\\integration\\process-quality-report.ps1' | pass | 1 | 0 | 00:00:02.0131531 | 0 | PASS: Process scorer writes a Markdown report with process and deferred outcome sections |

## Coverage Estimate

- Kind: qualitative
- Label: focused_regression
- Tool: unknown

## Coverage-to-Requirements

| Requirement | Test Files / Commands |
| ----------- | --------------------- |
| FR-013 | specs/171-specrew-refocus/spec.md, tests/integration/refocus-deploy.tests.ps1, tests/integration/refocus-dispatcher.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-014 | specs/171-specrew-refocus/spec.md, tests/integration/refocus-deploy.tests.ps1, tests/integration/refocus-dispatcher.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-007 | specs/171-specrew-refocus/spec.md, tests/integration/refocus-deploy.tests.ps1, tests/integration/refocus-dispatcher.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-016 | specs/171-specrew-refocus/spec.md, tests/integration/refocus-deploy.tests.ps1, tests/integration/refocus-dispatcher.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
| FR-018 | specs/171-specrew-refocus/spec.md, tests/integration/refocus-deploy.tests.ps1, tests/integration/refocus-dispatcher.tests.ps1, cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\mechanical-findings-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\process-quality-scorer.ps1', cmd:& '.\\tests\\integration\\process-quality-report.ps1' |
