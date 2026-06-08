# Review: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-08
**Overall Verdict**: accepted

Structured per Proposal 145 (7-phase reviewer + claim-to-evidence discipline). The
machine-readable matrix, claim ledger, and design-code trace are in
[review-report.yml](./review-report.yml). Report-falsification stance: the agent's own
implementation report is treated as a claim to disprove, not testimony.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-001, FR-005 | pass | HostEventAdapter normalizes + sanitizes; 9 asserts. FR-005 Claude-only (others -> it003). |
| T002 | FR-013, FR-015 | pass | SessionStateAccessor: fail-open read, marker, portability; 12 asserts. |
| T003 | FR-014, FR-015 | pass | ProjectMetadataAccessor: presence + git merged-status; 8 asserts. FR-014 read-side only. |
| T004 | FR-001, FR-017 | pass | ClassificationEngine pure mode decision; 5 asserts. |
| T005 | FR-013, FR-015, FR-017 | pass | ValidationEngine clears non-portable/missing/merged; 7 asserts incl. real git fixture (SC-004). |
| T006 | FR-002, FR-004 | pass | DirectiveEngine pure render_first directive; 7 asserts. |
| T007 | FR-001, FR-002, FR-003, FR-016, FR-020 | pass | SessionBootstrapManager orchestration + live provider; 9 asserts + dispatcher smoke. |

## Seven-Phase Structured Review (Proposal 145)

- **Phase 0 — Context load**: pass. Loaded spec.md (FR-001..021, SC-001..007), plan.md,
  tasks.md (3-iteration split), design-analysis.md (Option B Co-Design Record), drift-log
  (D-001), and the F-171 dispatcher contract. Iteration-001 scope = US-1 + US-4 (T001-T007).
- **Phase 1 — Branch hygiene**: pass with one info. All cited evidence IS committed (no
  Shape-5 working-tree-only evidence); per-task boundary-commit cadence honored. **Info:** the
  `174-...` branch has no upstream yet (push happens at feature-closeout per the SDLC — expected
  at this stage, not a defect). Feature-174 artifacts are clean; remaining dirty files are
  pre-existing unrelated host-asset/runtime churn.
- **Phase 2 — Functional correctness**: pass with one recorded limitation. Logic is
  unit-traced (not test-green-only): full/welcome-back/cleared paths and each clear reason are
  asserted. Design-code conformance verified — IDesign roles match the Co-Design Record;
  ClassificationEngine/DirectiveEngine are pure; ValidationEngine owns its accessor reads per
  the agreed call-rule. **Limitation (gap ledger):** ProjectMetadataAccessor merged-detection
  relies on the feature branch still existing; a merged-then-branch-deleted feature is not
  detected as merged. The original incident (merged Feature 171) is covered by the
  **non-portable** path, which is robustly tested.
- **Phase 3 — Non-functional**: pass. Security: local-tree trust boundary (per spec);
  session-id sanitized before any path use; absolute-path anchors treated non-portable;
  external state is advisory and never auto-authorizes a boundary; hook event JSON parsed
  defensively (fail-open). No secrets, no network. Observability: basic journal record (full
  per-path journal assertions are it003 T018). Performance: trivial (bounded file reads + one
  git ancestry check).
- **Phase 4 — Code quality**: pass (after fixes). **PSScriptAnalyzer surfaced 3 findings, all
  repaired now** (commit `6638c2db`): `$event` automatic-variable shadow renamed; em-dashes
  replaced with ASCII (BOM-less UTF-8 convention); a justified suppression on the pure
  `New-SpecrewBootstrapDirective` factory. PSScriptAnalyzer is now clean on all 8 files. SOLID
  / IDesign layering respected; one `.ps1` per component; comment-based help carries each
  contract.
- **Phase 5 — Test coverage + integrity**: pass. Every iteration-001-scoped FR has at least one
  test; tests are isolated (temp dirs, `finally` cleanup); **fixtures are real** (a real git
  repo for the merged case; the real F-171 dispatcher for the live smoke — no synthetic
  stand-ins, Shape-6 clear). Negative/falsification cases present (malformed JSON, missing,
  non-portable, compact-silent). **Tests-run-at-review evidence:** 8 suites / 62 assertions,
  exit 0 each, recorded in [coverage-evidence.md](./coverage-evidence.md).
- **Phase 6 — System safety + ops**: pass. Fail-open doctrine throughout (provider exits 0 on
  error; accessors return null on missing/corrupt). Rollback: the provider rides the F-171
  dispatcher, so the existing kill switch (`SPECREW_REFOCUS_DISABLE`) and `refocus-scopes.json`
  disable it. **Backward compatibility:** B1 (compact) stays silent and B3 is untouched
  (FR-011) — proven by the provider's compact-silent test.
- **Phase 7 — Synthesis + falsification**: APPROVE for review-signoff. Aggregation: all
  applicable phases pass (Phase 4 only after the 3 fixes). Falsification performed — the review
  re-ran the suites + PSScriptAnalyzer and a live dispatcher smoke; the "implemented" claims map
  to committed files in [review-report.yml](./review-report.yml); no claim is stronger than its
  evidence; no new dependencies (verified, `new_deps=0`).

## Gap Ledger

- 3 PSScriptAnalyzer phase-4 findings (automatic-variable shadow, non-ASCII/BOM, ShouldProcess on a pure factory) repaired in commit `6638c2db`: fixed-now.
- D-001 downstream extension-tree deploy of the provider + components (self-host wiring is live + proven): deferred (iteration 003 T016/T017; approved via the 3-iteration tasks split, approved in `.squad\decisions.md` (Decision ID `defer-f174-i001-downstream-deploy`)).
- ProjectMetadataAccessor merged-detection misses a merged feature whose branch was deleted; the actual incident class is covered by the non-portable check: deferred (iteration 003; add active-features.yml / closeout-marker as the robust closed signal, approved in `.squad\decisions.md` (Decision ID `defer-f174-i001-merged-branch-deleted`)).
- FR-005 per-host verification for Codex/Copilot/Cursor (Claude-first in 001): deferred (iteration 003 / closeout, approved in `.squad\decisions.md` (Decision ID `defer-f174-i001-per-host`)).
- FR-014 sync-side committed-anchor prevention (read-side only in this slice): deferred (iteration 003 / closeout, approved in `.squad\decisions.md` (Decision ID `defer-f174-i001-fr014-syncside`)).

## Notes

- Mechanical-checks lens not run (script param mismatch on this version); PSScriptAnalyzer
  (clean) + the 8 executed suites (62 assertions) are the deterministic Phase-4/5 evidence.
- No requirement (FR/SC) in iteration-001 scope is unverified; deferred items are out-of-slice
  scope carried to iteration 003 under the approved 3-iteration split, not gaps in 001's scope.
