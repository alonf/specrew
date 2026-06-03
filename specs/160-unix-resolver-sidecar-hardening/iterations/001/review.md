# Review: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-03
**Overall Verdict**: accepted

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-010 | pass | Dirty tree classified; unrelated `.codex`/`.squad`/`.cursor`/`.specrew` + F-140 files excluded from every stage. |
| T002 | FR-001 | pass | `investigation-evidence.md` created with both finding headings before any code change. |
| T003 | FR-002 | pass | Resolver surfaces inspected; exact backslash ChildPath expressions recorded (Path 0/1/2 + config probes). |
| T004 | FR-002 | pass | Deterministic resolver path-semantics probe authored before any fix (repro-first). |
| T005 | FR-001 | pass | Probe run; resolver disposition CONFIRMED with recorded evidence. |
| T006 | FR-006 | pass | Marker/classifier surfaces inspected; front-matter-enforced templates identified as the reachability driver. |
| T007 | FR-005 | pass | Direct deploy-logic fixture authored (Cases A/B/C/D) before any fix. |
| T008 | FR-005 | pass | Fixture run; sidecar disposition CONFIRMED with recorded evidence. |
| T009 | FR-009 | pass | No-blind-fix gate verified dispositions exist and no behavior changed before them; both fix paths activated. |
| T010 | FR-003 | pass | Separator-safe multi-segment `Join-Path` applied (source + mirror) only after confirmation. |
| T011 | FR-004 | pass | Resolver regression green (Windows behavioral + host-independent POSIX-semantic proof). |
| T012 | FR-007 | pass | Marker-provenance fix applied (source + mirror) only after confirmation; scope limited to the classifier. |
| T013 | FR-008 | pass | Sidecar regression green incl. preserve-user-edits (Case D) and source/mirror parity. |
| T014 | FR-010 | pass | CHANGELOG `Unreleased` entry added for both confirmed behavior changes (necessary maintainer-visible doc). |
| T015 | FR-010 | pass | Focused tests + governance validation run; commands/exit codes recorded. |
| T016 | FR-009 | pass | Review evidence assembled; every touched source/mirror/test/docs file listed; no unrelated files staged. |
| T017 | FR-009 | pass | Drift log updated with the scope-discovery finding (codebase-wide sibling backslash pattern). |
| T018 | FR-010 | pass | Reviewer readiness verified: all tasks terminal, both findings dispositioned, confirmed fixes have regression coverage. |

<!--
  Gap Ledger schema (validator-enforced):
    EVERY non-empty line MUST be a bullet entry classified with one of two tokens:
      - "fixed-now"  — the gap was repaired during this iteration
      - "deferred"   — the gap is parked with explicit human approval (the approval
                       reference must be recorded in .squad/decisions.md)
-->

## Gap Ledger

- No in-scope requirement (FR-001..FR-010) gaps: both findings reproduced, dispositioned, fixed, and regression-covered: fixed-now.

## Findings and Dispositions

### Finding 1 — resolver-path (Proposal 160): CONFIRMED + fixed

The boundary-sync wrapper (`extensions/specrew-speckit/scripts/sync-boundary-state.ps1` + `.specify` mirror) built module-resolution candidates with hardcoded backslash ChildPaths at Path 0/1/2 plus two `.specrew\config.yml` probes. `tests/integration/unix-resolver-path-semantics.tests.ps1` proves, host-independently, that an embedded-backslash ChildPath is a single literal segment under POSIX `/` (so `Test-Path` fails on Unix) and behaviorally that the separator-safe multi-segment form resolves on every platform. The fix replaces all five constructions with multi-segment `Join-Path` in source + mirror. The Windows symptom from F-140 closeout was root-caused to the `$env:SPECREW_MODULE_PATH` override selecting the installed module by design (Proposal 160 hypothesis (a)), not a walk-up bug. **High confidence; low-risk fix (identical on Windows, correct on Unix).**

### Finding 2 — managed-refresh-sidecar (Proposal 161): MECHANISM CONFIRMED; fix scoped narrowly

What is confirmed: `Test-IsManagedLegacySkillDirectory` classifies a marker-less skill dir whose SKILL.md carries front matter (`---`) as user-edited, and **all** current canonical skill templates start with front matter (F-044-enforced), so the front-matter heuristic short-circuits before the managed-signature check. The synthetic Case A in `tests/integration/managed-runtime-sidecar.tests.ps1` reproduces the misclassification deterministically.

What the fix does and does NOT cover (honest scope):

- The fix recognizes a dir whose SKILL.md **byte-matches the definition's current/legacy canonical content** as managed (ordinal exact match) before the front-matter bail. It is data-loss-safe: genuinely user-edited content never matches and stays preserved (Case D), and the legacy-signature fallback still works (Case C).
- It covers the **byte-current-canonical-content** case. It does **NOT** retroactively reclassify a marker-less legacy dir carrying **older** front-matter canonical content (that content does not match current canonical), which remains conservatively preserved.
- Real-world harm reachability is **uncertain**: the active-root deploy already always writes markers, and `Test-IsManagedLegacySkillDirectory` only governs legacy `.copilot/skills/` cleanup, so the practical trigger is a marker-less legacy dir from an older Specrew. This is a classifier-mechanism fix, not a proven user-facing outage fix.
- **Maintainer decision at signoff**: keep as-is (narrow, safe), expand (e.g. recognize any known-canonical *signature* incl. old front-matter shapes — higher reach, more care needed), or revert and track as investigation-only. The conservative-preserve default is intentionally retained.

## Fix Correctness and Test Evidence

- Repro-first ordering is in git history: `boundary(implement): repro-first evidence` (failing tests) precedes `boundary(implement): ...fixes`.
- Both repro tests now pass (exit 0). Regression batch green with no regressions: `unix-resolver-path-semantics`, `managed-runtime-sidecar`, `skill-templates`, `slash-command-legacy-migration`, `lifecycle-boundary-sync`.
- Source/mirror parity asserted by the sidecar test; resolver test asserts both files are separator-safe.
- Mechanical checks (`quality/mechanical-findings.json`): no findings.

## Scope Boundary — Codebase-wide Unix path pattern (NOT fixed here)

The embedded-backslash `Join-Path`/`Test-Path` pattern is **not unique to the boundary-sync wrapper**. A grep of production scripts (`extensions/specrew-speckit/scripts`, excluding tests and the `.specify` mirror) found **~105 occurrences across 18 files**, including a **sibling resolver** in `validate-governance.ps1` (L1491/L1500) that resolves `scripts\internal\dashboard-renderer.ps1` via the same dev-tree-vs-installed pattern and would exhibit the identical Unix failure. Proposal 160 explicitly scoped only the boundary-sync resolver, and the no-blind-fix discipline plus iteration capacity argue against a blind 105-site sweep here. **Recommendation**: file a follow-up proposal for a governed, test-backed codebase-wide Unix path-separator portability sweep (with a CI lint that rejects new embedded-backslash ChildPaths). This is the highest-value follow-up surfaced by the iteration.

## FR/SC Coverage

All FR-001..FR-010 and SC-001..SC-005 are satisfied within scope: both suspicions have explicit CONFIRMED dispositions (SC-001), no behavior changed before a failing repro existed (SC-002), the confirmed resolver fix has Windows + Unix-equivalent regression coverage (SC-003), the confirmed sidecar fix has refresh + preserve coverage (SC-004), and review evidence lists every touched file and confirms no unrelated untracked/runtime files were staged (SC-005).

## Notes

- Verdict `accepted` reflects that the work is correct and complete **within F-160's scope**. The sidecar harm-reachability nuance and the codebase-wide scope boundary are documented above as honest caveats + follow-up recommendations, not in-scope gaps.
- The reviewer's `accepted` is a recommendation; the human review-signoff verdict is the authoritative gate.
