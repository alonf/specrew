# Retrospective: Iteration 002

**Schema**: v1
**Date**: 2026-05-30

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T011 | 0.5 | 0.5 | 0 |
| T012 | 1.5 | 1.5 | 0 |
| T013 | 0.5 | 0.5 | 0 |

**Average variance**: 0 SP/task. Test-only iteration estimated accurately; no production-code surprises.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | done | done | 0 | Small scoped slice; plan + hardening gate clean. |
| Discovery/Spikes | 0 | 0 | 0 | Contract settled in iter-001. |
| Implementation | 2.5 | 2.5 | 0 | 3 test files; real-binary fixtures executed green (cursor-agent on PATH). |
| Review | ~0.5 | ~1.5 | +1 | Two narrow cross-reviewer DECLINEs (review.md control chars + over-strong real-binary claim) + a git-cleanliness DECLINE + a missed-test-files catch. None were code defects. |
| Rework | buffer | ~0.5 | — | Artifact wording + broader test sweep; no code changes. |

## Drift Summary

- Total drift events: 0
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0

## What Went Well

- Review verdict recorded as **accepted** (review-signoff approved by Alon Fliess).
- **Real-binary fixtures actually executed** (cursor-agent v2026.05.28 on PATH) rather than only skip-passing — genuine end-to-end evidence for the launch path + version probe.
- **Launch integration smoke proves the DRIFT-001 fix end-to-end**: `host-cursor-launch.tests.ps1` extracts `Get-SpecrewHostLaunchInvocation` and confirms its `-HostKind` ValidateSet now accepts `cursor` through to the interactive argv.
- Proactively dispositioned the form-vs-meaning false-positive this iteration (learned from iter-001) instead of waiting for a DECLINE on it.
- Tests were correct on the first pass; every DECLINE was an artifact/evidence-wording issue, not a behavior defect.

## What Didn't Go Well

- **Review evidence ran only the obviously-related host-test subset, not the full affected surface (caught by the human, not by me).** Adding cursor touched `Get-ActiveSkillRoots` (skill-root deploy) and `Specrew.psd1` FileList — surfaces exercised by `slash-command-*` and `distribution-module-*` tests that my review never ran. **Repeatable failure pattern**: "review the diff's tests" must mean "run every test that touches a changed surface," derived from the changed files, not just the new tests. The two failures the broader sweep surfaced turned out to be pre-existing/environmental (stale `slash-command-distribution` assertion; version-skew in `distribution-module-publish` from being 169 commits behind main) — but I could only assert that *after* running them; the gap was that I hadn't.
- **Repeated artifact-integrity friction** (control chars in scaffolded review.md Notes; over-strong "executed" claim for skip-guarded fixtures; git-cleanliness). Same family as iter-001's reviewer-artifact churn — the review *package* keeps needing cleanup the *code* doesn't.

## Improvement Actions

1. Owner: Crew coordinator | Phase: every review boundary | Type: process | Expected effect: derive the review test-set from the changed-file surfaces (skill-roots → slash-command-* + distribution tests; FileList → distribution tests; host enums → host-* tests), and run ALL of them — not just the iteration's new tests. Record the full command list + pass/fail in coverage-evidence. (Prevents the iter-002 missed-test-files gap.)
2. Owner: methodology | Phase: proposal | Type: tooling | Expected effect: the reviewer-artifact scaffolder should (a) emit clean Notes without control characters, and (b) the coverage-evidence test-runner should auto-include tests that reference any changed file's exported symbols/paths, so "review missed test files" cannot recur silently. (Extends the iter-001 scaffolder-hardening proposal candidate.)
3. Owner: methodology | Phase: pre-PR | Type: process | Expected effect: capture the pre-existing failures found here (`slash-command-distribution` stale-string assertion; `distribution-module-publish` version-skew) as baseline-cleanup items so the F-050 PR's CI signal is interpretable — distinguish "red because of my change" from "red on main already."

## Calibration Suggestion

- Suggested capacity adjustment: test-only iterations → keep ~2.5 SP for implementation, but add ~1 SP of "review-evidence breadth" (full affected-surface test run + artifact cleanup) that the last two iterations both consumed unbudgeted.
- Rationale: implementation estimates were exact; the unbudgeted cost was entirely in review-package integrity + test-evidence breadth.

## Notes

- Iteration 002 = test coverage (launch integration smoke + real-binary fixture + detection-matrix assertion). All 3 tasks pass.
- The two broader-suite failures are NOT F-050 regressions: `slash-command-distribution` greps `specrew-init.ps1` for a string that lives in `post-bootstrap-output.ps1` (fails on main too); `distribution-module-publish` rejects local `0.27.6` < PSGallery `0.28.0` (version-skew from 169-commit lag; resolves on the feature-closeout rebase).
- Iteration 003 (docs FR-008 + live-Cursor smoke) + feature-closeout rebase onto post-F-049 main remain.
