# Drift Log: Iteration 003

**Schema**: v1

<!--
  Markdown authoring note (Specrew lifecycle convention):

  When you add new drift events to this file, watch for MD032 (blanks-around-lists).
  A sentence ending with a colon, immediately followed by a bullet list, is the most
  common violation. Always put a BLANK LINE between the colon line and the list:

      BAD:                              GOOD:
      Resolution steps:                 Resolution steps:
      - Step one                        <— blank line here
      - Step two                        - Step one
                                        - Step two

  The F-033 pre-boundary markdownlint gate runs markdownlint-cli --fix on .md
  changes before every boundary-sync write, so most violations auto-fix — but the
  blank line you write in the first place avoids the cleanup churn.
-->

## Summary

**Total drift events**: 0
**Resolution rate**: 100% (0/0 resolved)
**Specification drift**: None detected

## Events

No specification drift detected during Iteration 003 execution to date.

## Reproduction Evidence (T001 — FR-012 / FR-013)

Reproduce-first + classify (maintainer instruction 2026-06-03), captured before any fix. **Both defects reproduce** once the right conditions are exercised; the intake-only fixtures masked them.

### FR-013 — fresh-greenfield baseline commit (REPRODUCED — but the omission is intentional fail-safe)

- **With a prior commit** (`git init` + commit + `specrew init` + `specrew start`): `baseline_commit_hash` = real HEAD (`d5d0266c…`), consistent — correct.
- **No prior history** (`git init`, **no commit** + `specrew init` + `specrew start`): `specrew init` creates no commit; `specrew start` writes the prompt with **no `baseline_commit_hash`** line (guarded at `scripts/specrew-start.ps1:2912`, which writes the line only when `git rev-parse HEAD` returns a 40-hex), and HEAD never resolves.

**Discriminator (advisor-directed prove-first — the spec anchors US6-AC1 at "when the first boundary is recorded," not intake-start):**

- Once ANY commit exists, `Get-SpecrewCurrentHeadCommitHash` resolves and the boundary refresh stamps `baseline_commit_hash == HEAD` (empirically confirmed on the no-history fixture: throws with 0 commits → after the first commit, stamped baseline == HEAD == `1678ddc…`, consistent = True). Every boundary re-refreshes from HEAD (`scripts/internal/sync-boundary-state.ps1:1209-1210`).
- The no-commit omission is the **existing, intentional, tested fail-safe contract**: `tests/integration/baseline-hygiene.tests.ps1:357-376` asserts that when HEAD cannot be resolved, boundary sync MUST warn, continue (exit 0), and **NOT stamp `baseline_commit_hash`** (leave the prompt uncorrupted). The Feature-029 lifecycle test (`:251-354`) asserts `baseline == HEAD` at every boundary once commits exist.
- No "wrong"/stale baseline at boundaries (refreshed each boundary); between boundaries it is the last-boundary HEAD by design (the diff anchor for session-loaded-file change detection).

**Classification:** the reproduced "missing baseline" is the *designed* fail-safe for a zero-commit repo (there is no commit to resolve to), NOT corruption or a wrong hash. FR-013's behavior is effectively satisfied the moment a commit exists, which it does by the first meaningful boundary (the agent commits the spec). **Open tension (maintainer's call):** US6-AC1's literal "MUST resolve to a real commit hash … with no prior history" vs the Feature-029 tested contract that forbids stamping a baseline when HEAD cannot resolve. Resolving it by auto-establishing a commit (option B) would contradict `baseline-hygiene.tests.ps1:372-375` and create commits on the user's behalf — against the "fix only reproduced / be conservative" guidance. See the checkpoint for options C / C+nudge / B.

### FR-012 — spurious greenfield/downstream warnings (REPRODUCED)

- Black-box `specrew start` in greenfield + downstream **intake** mode emits 0 surfaced warnings (the multi-session guard no-ops with no active feature) — clean until a feature is active.
- Signal-layer probe is decisive: `Get-SpecrewMultiDeveloperSignals` on a **single-developer fresh greenfield** (0 git authors, 0 branches, `session_mode=single`) returns **"Multiple developers detected (2 close-together shared-state writes)."** The "writes" are specrew's **own bootstrap footprint** — `.specrew/start-context.json` + `.specrew/last-start-prompt.md` + `.squad/decisions.md`, all written within ~1s by `specrew init`/`specrew start`. `Get-SpecrewConcurrentWriteSignalCount` (`scripts/auto-detection.ps1:31-52`) counts those ≤60s-apart writes, and `$writeSignals -ge 1` **alone** trips `$hasSignals` (`auto-detection.ps1:75`). This surfaces at the first feature boundary via `Invoke-SpecrewStartMultiSessionGuard`. **Classified: spurious** — a lone developer's bootstrap is not multi-developer activity.
- **version-mismatch** (`installed 0.30.0 vs project 0.0.0`) and **author/branch-fanout** multi-dev signals fire in the **Specrew SOURCE/dev repo** (placeholder `0.0.0`, 3 authors, 23 branches) but NOT in a fresh greenfield/downstream (real version, no history). **Classified: not-applicable to greenfield/downstream** (self-host-only; no leak observed; not reproduced as spurious there).

### Fix scope (per "fix only reproduced spurious warnings")

- **T002 (FR-012):** stop the bootstrap-write false positive — `$writeSignals` alone must not trigger the multi-dev recommendation in a single-author / single-machine project; keep it as a corroborating detail only when a genuine distinct-actor signal (authors≥2 / machines≥2 / numbered-branch fanout≥3) is present, so real multi-dev is still surfaced (never hide an actionable warning).
- **T003 (FR-013):** prove-first shows the baseline already resolves to a real hash + refreshes consistently once a commit exists, and the zero-commit omission is intentional tested fail-safe — so T003 is gated on the maintainer's call on the spec-vs-tested-contract tension (C: verify-clean + SC-009 test + document; C+nudge: add a no-commit greenfield guidance line; B: auto-establish a commit, contradicting `baseline-hygiene.tests.ps1:372-375`). NOT auto-committing without that decision.
- **Not reproduced → follow-up only, NOT fixed here:** version-mismatch-vs-placeholder and author/branch-fanout false positives (no greenfield/downstream leak observed); the `branch_fanout >= 3` single-dev edge (the greenfield fixture had 0 numbered branches).

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.
