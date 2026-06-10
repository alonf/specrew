# Review: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-10
**Overall Verdict**: accepted

> Proposal-145-style structured packet (Phase 0-7 + FR x phase matrix + falsification). Proposal 145 is
> unshipped, so this is authored manually, not produced by 145 machinery. Machine-readable companion:
> `review-report.yml`. Re-issued after a human send-back that correctly caught stale sibling reviewer
> artifacts (coverage-evidence / reviewer-index / dependency-report were preserved from the first scaffold
> run); all reviewer artifacts are now reconciled to one truth (verdict=accepted, baseline=before-implement).

## Summary

Iteration 001 (i1 -- capture substrate) delivers the data + validation half of the code-implementation
lens. There is **no agent-facing runtime surface in i1** (the workshop conduct turn + the
`specrew-code-rules` guidance skill + the SC-004/SC-007/SC-008 **dogfood** are iteration 002), so i1 is
reviewed against unit/static evidence; the **deployed dogfood is i2's gate** (not unit-green).

## Phase 0-7 Review

| Phase | Name | Verdict | Evidence |
| --- | --- | --- | --- |
| 0 | Context load | pass | spec/plan/tasks/design-analysis/data-model/contracts loaded; scope = i1 (T001-T009). |
| 1 | Branch hygiene | pass-with-notes | ahead 19 (F-177 commits), behind 4 (merge at feature-closeout); dirty tree classified below -- none F-177 source. |
| 2 | Functional correctness | pass | writer -> schema-valid reference-by-ID manifest; validator catches unknown id / bad provenance / bad context_scope; overlay never drops a shipped rule; dependency_policy captured; catalog 60 unique ids + additions + per-stack; registration present. |
| 3 | NFR | pass | one source of truth (catalog, stable ids); constrained-YAML (no powershell-yaml); forward-compat hooks. Multi-host parity + rule-volume UX are i2. |
| 4 | Code quality | pass | PSScriptAnalyzer Errors=0 (Warnings repo-tolerated, CI Error-only); ASCII .ps1; markdownlint clean. |
| 5 | Test coverage + integrity | pass | code-implementation-lens.tests.ps1 (38 assertions) + lens-conduct-delivery + lens-applicability-selector PASS; behavior-proving, not file-presence. |
| 6 | System safety + ops | pass | no auth/secrets/PII/network; fail-open everywhere; mechanical-checks 0 findings; FileList/extension.yml deployment is i2/release. |
| 7 | Falsification + synthesis | pass | see Report Falsification; accepted survives refutation for i1 scope; runtime dogfood carried to i2 (not claimed). |

## Branch Hygiene Classification (Phase 1)

Branch ahead 19 (the F-177 lifecycle commits), behind 4 (origin/main advanced -> reconcile by **merge at
feature-closeout**, not mid-iteration). The dirty working tree is **not** F-177 source:

| Path(s) | Class | F-177? | Action |
| --- | --- | --- | --- |
| `.claude/agents/*.md` (5) | pre-existing session churn | no | present before this session (session-start git status); review separately |
| `.specrew/last-validator-summary.json`, `.specrew/runtime/refocus-channel1.json`, `.specrew/version-check-cache.json` | runtime state/cache | no | gitignore-class; not source |
| `.squad/active-features.yml`, `config.json`, `decisions.md`, `events/lifecycle-events.jsonl`, `identity/now.md` | Squad runtime state | no | written by sync-boundary-state during the lifecycle; runtime-local |
| `specs/171-specrew-refocus/iterations/002/tasks-progress.yml` | stale 171 leftover | no | unrelated (recovery-B bypassed feature); cleanup-class |

**Conclusion**: every F-177 deliverable is committed under `specs/177` + `extensions/` + `scripts/` + `tests/`; no F-177 source change is uncommitted.

## FR x Phase Coverage Matrix

| Requirement | Status | Phases | Evidence |
| --- | --- | --- | --- |
| FR-001 | verified | 2,5 | registration (index.yml + $lensIds); T009 + selector |
| FR-002 | verified | 2,5 | code-rules.yml 60 rules; T007 + YAML parse |
| FR-003 | partial-i1 | 2 | lens md grouping content; interactive turn is i2 (T012) |
| FR-004 | verified | 2,5 | schema + writer; T008 |
| FR-005 | deferred-i2 | - | guidance skill (T010/T011) |
| FR-006 | deferred-i2 | - | plan/implement wiring (T014) |
| FR-007 | verified | 2,5 | context_scope hook; T008 |
| FR-008 | deferred-i2 | - | baseline-only skill mode (T010/T015) |
| FR-009 | partial-i1 | 2,5 | checked/unchecked in writer + T008; set/unset UI is i2 (T012) |
| FR-010 | partial-i1 | 2 | guideline-first content; conduct is i2 (T012) |
| FR-011 | deferred-i2 | - | assisted ingestion (T013) |
| FR-012 | verified | 2,5 | overlay never-drops + custom provenance; T008 |
| FR-013 | verified | 2,5 | dependency_policy; T006 + T008 |

SC coverage: SC-001/SC-002/SC-005 verified (tests); SC-003/SC-004/SC-006/SC-007/SC-008 deferred to the i2 deployed dogfood + parity. Full matrix in `review-report.yml`.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-002 | pass | catalog: 60 unique ids, additions + per-stack; T007 + parse. |
| T002 | FR-004 | pass | manifest schema shipped; optional fields accept null (ConvertTo-Json padding); T008. |
| T003 | FR-001 | pass | lens md with required sections + conduct; T009 + lens-conduct-delivery. |
| T004 | FR-001 | pass | registration (conduct-driven, D-001); selector + registration tests. |
| T005 | FR-004 | pass | writer/validator round-trip + schema + invariants; PSScriptAnalyzer Errors=0. |
| T006 | FR-013 | pass | dependency_policy capture; T008. |
| T007 | FR-002 | pass | catalog-integrity test green. |
| T008 | FR-004 | pass | manifest schema + overlay test green. |
| T009 | FR-001 | pass | registration test green. |

## Gap Ledger

- No requirement (FR/SC) gaps in iteration-001 scope: catalog, schema, lens md, registration, writer/validator, and the i1 unit tests are all verified: fixed-now.

## Report Falsification (Phase 7)

Adversarial attempts to refute the accepted verdict (full list in `review-report.yml`):

- "Catalog invalid?" -> FAILS (60 unique ids, parses, additions+per-stack — T007).
- "Writer mis-validates?" -> FAILS (unknown id + bad provenance both caught — T008 negative).
- "An in-scope FR unverified?" -> FAILS (every i1-scope FR has phase+test evidence; FR-005/006/008/011 are explicitly i2).
- "Review artifacts inconsistent?" -> FAILS post-reconcile (all accepted, all baseline=before-implement — was the human finding, now fixed).
- "Runtime behavior over-claimed?" -> FAILS (i1 has no runtime surface; SC-004/007/008 carried to i2, not claimed).
- "Branch hygiene hides F-177 changes?" -> FAILS (all dirty paths classified non-F-177; no F-177 source uncommitted).

**Result**: the accepted verdict survives for iteration-001 scope; the one honest caveat (the runtime dogfood) is an i2 gate, not an i1 claim.

## Notes

- **Drift D-001** (conduct-driven registration, not the deterministic map) recorded + resolved; surface at feature-level review (Proposal 174).
- **code-map.md form-vs-meaning WARNING reviewed + benign**: it reports 9 tasks vs ~20 files since the before-implement baseline; the heuristic expects a 1:1 task-to-file mapping, which does not hold (some tasks edit multiple files; the diff also spans the review-phase governance artifacts). Every changed file maps to a task or a review/governance artifact in code-map's Files-Touched table; no untracked or unexplained source change. (The prior "0 tasks / 28 files" was a real state-truth gap, fixed by setting task statuses to done + the before-implement baseline.)
- **Carried to iteration 002 (by design)**: the workshop conduct turn, the `specrew-code-rules` guidance skill, the plan/implement wiring, and the **deployed runtime dogfood** proving SC-004/SC-007/SC-008 (installed-module layout, fresh `specrew init`).
- Mechanical-checks: 0 findings. Validator: PASSES iterations/001.
