# Implementation Plan: 206-bug-bash

**Branch**: `206-bug-bash` | **Date**: 2026-11-10 | **Spec**: [spec.md](spec.md)
**Bug list**: [bug-list.md](bug-list.md) | **Design decision**: [iterations/001/design-analysis.md](iterations/001/design-analysis.md)
**Iteration plan and tasks**: [iterations/001/plan.md](iterations/001/plan.md)

## Summary

Iteration 001 fixes the diagnosed defects of items 1, 2, 4 and 5 and records item 3's hand-over; iteration
002 carries FR-013 and FR-014 (T016, T017), deferred to keep 001 within its 20 SP cap. All under
the maintainer's design decision: **modified-Option B** (one source of truth per signal), with four
conditions that this plan carries as tasks and acceptance checks (see "The maintainer's conditions" below).
Conduct is bug-bash: every fix starts with a failing test, and each bug lands in its own commit.

## Technical Context

**Language/Version**: PowerShell 7 (Windows, Linux, macOS), GitHub Actions YAML
**Primary Dependencies**: Pester 5 (already in the repository); `gh` CLI on the Actions runner (preinstalled)
**New dependencies**: none
**Storage**: repository files only: `.specrew/closed-iterations.yml` (gains a closure stamp),
`.specrew/legacy-frozen.yml` (new), the nightly's tracking issue on GitHub
**Testing**: Pester unit suites under `tests/unit/`, script-style integration suites under `tests/integration/`
**Target Platform**: the Specrew module and this repository's CI
**Constraints**: no file under `scripts/internal/continuous-co-review/` or the bootstrap capture stores
(`HumanAuthorityStore`, `HandoverStore`) is touched; the real home folder is never written;
`scripts/specrew-update.ps1` is never run; `.squad/active-features.yml` is never committed

## Design (from the design analysis, Option B)

| Decision | Requirement | What is built |
| --- | --- | --- |
| D1 | FR-001 | `Read-SpecrewRecoveryChoice` refuses in plain words when console input is not available; an interactive console gets at most three invalid answers, then the same refusal; `specrew start` exits non-zero |
| D2 | FR-003 | the change classifier strips `specrew-managed` blocks from both sides before comparing, **only for matched marker pairs**; any missing or unbalanced marker means the whole file is compared as today |
| D3 | FR-008a | one function, `Test-SpecrewIterationClosed`: closed = in the closed index, or `Iteration Status` `complete` / `abandoned`; frozen entries are not closed; used by the validator's closed filter, the dashboard check and the renderer; the state.md heuristic and the review-verdict rule are removed |
| D4 | FR-007, FR-008 | `.specrew/legacy-frozen.yml` (closed list, guarded); the dashboard check declares `since: 2026-05-26`; iteration closeout writes a closure stamp from now on; an index entry without one is not judged by a `since` check |
| D5 | FR-009 | `scripts/internal/nightly-tracking-issue.ps1` with injectable `gh` calls and a Pester suite; the validator writes a findings file the notifier reads; a separate notifier job holds `issues: write` |
| D6 | FR-011 | one census function in `tests/support/` used by the lane guard and the release full sweep, classifying by content, with one exclusion list carrying reasons |

The shapes of the new records are in [data-model.md](data-model.md); how each success criterion is checked
is in [quickstart.md](quickstart.md).

## The maintainer's conditions (design verdict, 2026-11-10)

Each one is a task or an acceptance check in the iteration plan.

1. **D3, table first (T005, T010).** Before `Test-SpecrewIterationClosed` replaces anything, a table lists
   every iteration with its closed/open answer under the index, the state.md heuristic, the renderer rule
   and the new function, plus every iteration whose answer changes and why. Then the nightly validation runs
   locally in CI mode on the full repository: **no iteration whose answer changes may produce a new
   finding.** If one does, the work stops and that iteration goes to the maintainer; it is **not** added to
   the frozen list (FR-007 closes it).
2. **D3/D4, frozen means judged by nothing (T008).** A frozen entry is judged by no check: neither the
   open-iteration checks nor the closed-iteration checks. A test runs the validator over every frozen entry
   and asserts zero findings. **197/006 is resolved explicitly** (below).
3. **D2, matched markers only (T003).** Tests: a matched block is stripped and Specrew's heal does not pause;
   a missing or unbalanced marker compares the whole file, so the heal pauses (the error is toward pausing);
   a user change outside the markers is still classified as the user's.
4. **D5, nothing private in the issue (T012).** The issue title, body and comments carry iteration ids and
   rule names only: no local paths, no user or machine names. A test proves it on the rendered text. The
   workflow grants `issues: write` to the notifier job only; the workflow default stays `contents: read`.

### 197/006, resolved

The spec's ruling (FR-006) marks 197/006 **abandoned**; it is **not** a frozen-list entry. The frozen list
holds exactly the 18 entries FR-006 names: 048/001, 197/001, 198/008, and the 15 dashboards. The design
analysis grouped 197/006 with the frozen entries because the dashboard check called it closed; that was a
description of the bug, not a ruling.

Under the new definition 197/006 (and 198/011, newly abandoned) count as closed. So that marking them
abandoned produces no new finding, **the dashboard check applies to `complete` iterations only**: an
abandoned iteration delivered nothing, so it owes no dashboard. The same rule covers 174/007, which was
abandoned before this feature. This is the one rule change the triage needs. An iteration counts as
abandoned only when it records the maintainer's ruling that abandoned it (iteration plan, Notes; tested in T009). Condition 1's local replay
proves it produces no new finding. If the maintainer prefers a different resolution, it is decided at the
plan verdict.

## Quality plan (resolved profile replaced)

The resolver picked `react-spa-public@v1.0.0` for this feature: that is bug 6a, reproduced live, and it is
kept as FR-014's evidence. **A custom PowerShell composition replaces it:**

| Dimension | Required | Why |
| --- | --- | --- |
| security / privacy | yes | the tracking issue is public text (condition 4); tests must never write the real home folder |
| robustness | yes | no-console refusal (FR-001), unbalanced markers fail toward pausing (FR-003) |
| test-integrity | yes | failing test first per fix; the census guard proves itself (SC-004, SC-005) |
| retry / idempotency | yes, narrow | the notifier must stay quiet on a repeated failure set and act once per change |
| browser, UI, accessibility | no | no web surface; the root `package.json` that suggested one is removed by FR-014 |

`iterations/001/quality/hardening-gate.md` is filled at the before-implement boundary.

## Confirmations (maintainer's request at the design verdict)

- **The custom PowerShell quality profile replaces `react-spa-public`.** Recorded above and in
  `iterations/001/quality/quality-evidence.md` at before-implement.
- **Nothing in feature 203's protected files is touched.** No task's owner globs include
  `scripts/internal/continuous-co-review/**` or `scripts/internal/bootstrap/**`; acceptance check T018 diffs
  the branch against `main` and fails on any path under either.
- **`.squad/active-features.yml` stays uncommitted.** Every commit stages explicit paths; T018 checks that
  the branch diff does not contain it.
- **Push** when `plan.md` is in and Lint passes locally (the CI's own markdownlint command, then
  `validate-governance -ChangedOnly`), then Specrew CI, Test and Cross-Platform Validation are followed to
  conclusion; a skipped gate job is red.

## Constitution Check

| Principle | Status |
| --- | --- |
| I Spec authoritative / VIII reconciliation | Pass. The plan resolves 197/006 per FR-006 and states the one rule change it needs |
| II/XXVII Layered system | Pass. Validator, start script, CI workflow and tests only; no Squad-layer change |
| IV Compatibility | Pass. History is not re-judged (FR-008); consumer projects without a closure stamp see no new findings |
| XV Human oversight | Pass. The 35 scripts' exclusions, durations and per-push cost go to the maintainer before registration |
| XVI Capacity-aware | Pass. Iteration 001 at 20/20; T016 and T017 deferred to iteration 002 by the maintainer (2026-11-11); OVERRIDE 5 reverted |
| XXI/XXIII-XXV Verification | Pass. Failing test first per fix; the nightly is replayed locally before push |

## Project structure touched

```text
scripts/internal/session-recovery.ps1          D1
scripts/specrew-start.ps1                      D2 (Get-RestartTriggerFiles path)
scripts/internal/instruction-file-merge.ps1    D2 (marker constants, read only if shared)
scripts/internal/dashboard-renderer.ps1        D3
scripts/internal/nightly-tracking-issue.ps1    D5 (new)
extensions/specrew-speckit/scripts/{validate-governance,shared-governance,resolve-quality-profile}.ps1
.specify/extensions/specrew-speckit/scripts/   deployed mirrors of the three above
.specrew/legacy-frozen.yml                     D4 (new)
.specrew/closed-iterations.yml                 D4 (stamp on new entries only)
.github/workflows/specrew-nightly-truth-check.yml   D5
tests/support/test-census.ps1                  D6 (new)
tests/unit/every-suite-is-named-by-a-lane.tests.ps1, tests/full-powershell-test-sweep.ps1   D6
package.json                                   FR-014 (deleted, iteration 002)
```
