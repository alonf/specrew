# Feature Closeout: Work Kind and Branch Governance Model

**Schema**: v1
**Feature**: 182-work-kind-branch-governance
**Branch**: 182-work-kind-branch-governance
**Closed**: 2026-06-12
**Status**: COMPLETE — branch-ready evidence only
**Closer**: Claude, authorized by Alon Fliess for feature-closeout

## Executive Summary

Feature 182 is complete as branch-ready evidence. It delivers Proposal 182 (the Work Kind and Branch
Governance Model) across **three iterations (46.5 SP: 001 = 15.5, 002 = 17, 003 = 14)**. All twenty-one
functional requirements (FR-001..021) and fourteen success criteria (SC-001..014) are implemented,
reviewed (all three iterations accepted), and retro'd (all three approved).

The feature ships in three layers: (1) the **methodology layer** — the work-kind catalog + lifecycle
templates + the provider-neutral governance model (iteration 001); (2) the **runtime layer** — the
provider-neutral CI work-kind validator + changed-file classifier + closeout-evidence checker, honest
capability detection, the emergency-bypass audit, the GitHub reference adapter (`gh`-confined), brownfield
adapt-or-change detection, the read-only synthesized-adapter example, the advisory CI workflow template,
and the Specrew dogfood (iteration 002); and (3) the **forge-neutralization migration** — decoupling
Specrew's downstream-governing surfaces from its own GitHub-dev habits via a labeled-example pattern + an
opt-in reviewer-routing gate, with the SC-008 no-over-claim sweep (iteration 003).

This branch is integrated with `origin/main` and version-bumped to **0.36.0** (branch-ready as
`0.36.0-beta1`) but is NOT released, tagged, merged, PR-opened, or pushed to main.

## Delivered Scope

| Layer / Requirements | Iteration | Status | Evidence |
| --- | --- | --- | --- |
| Methodology: work-kind catalog + schemas + lifecycle templates + provider-neutral governance model (FR-001..006, FR-008..010, FR-014, FR-017, FR-018) | 001 | complete | `extensions/specrew-speckit/knowledge/work-kinds.yml` (+ schemas); `templates/work-kind/*`, `templates/lifecycle/*`; `work-kind-catalog.tests.ps1` 36 PASS |
| Runtime: CI validator + classifier + closeout-evidence + capability detection + bypass audit + GitHub adapter + brownfield + synthesis + advisory CI + dogfood (FR-007, FR-011..013, FR-015, FR-016, FR-020, FR-021) | 002 | complete | `extensions/specrew-speckit/scripts/{work-kind-validator,work-kind-common,capability-detector,provider-adapter,provider-generic,provider-github}.ps1`; `work-kind-validator.tests.ps1` 12, `work-kind-runtime.tests.ps1` 19, `provider-adapter.tests.ps1` 21 PASS |
| Forge-neutralization migration: decouple downstream-governing surfaces; opt-in reviewer routing; SC-008 no-over-claim sweep (FR-019) | 003 | complete | neutralized coordinator prose + `lifecycle-discipline.md` + index docs (labeled examples); `shared-governance.ps1` opt-in gate; `forge-neutral-reviewer.tests.ps1` 10, `forge-neutralization-sweep.tests.ps1` 7 groups PASS |
| Test coverage per FR-020 across all layers | 001–003 | complete | work-kind/forge suites + parity + validators, 0 fail (see Tests and Validation) |

## Tests and Validation (run at closeout on the integrated tree)

Local CI/parity sweep — **all PASS** (the F-141 lesson: run the sets the iterations never ran), incl.:

- **Work-kind + FR-019 suites**: work-kind-catalog 36, provider-adapter 21, work-kind-validator 12,
  work-kind-runtime 19, forge-neutral-reviewer 10, forge-neutralization-sweep 7 groups,
  pr-review-integration 7, host-coupling-firewall 2 — all PASS.
- **Wrapper / version parity** (docs / registry / filelist / filelist-completeness / version-info-states)
  — all PASS (gate the 0.36.0 version bump).
- **Regression guards**: `gate-stop-skill.tests.ps1` PASS (F-165 contract intact post-merge),
  `extension-registration-format.tests.ps1` PASS (validates the bumped `extension.yml`),
  `boundary-sync-markdownlint-gate.tests.ps1` PASS, `closeout-lifecycle-sync-commands.tests.ps1` PASS.
- **Governance validator**: PASS for all three iterations (default scan) AND under the stricter
  `-IncludeClosed` cross-iteration reconciliation (3 PASS / 0 FAIL).
- **Static**: PSScriptAnalyzer production code 0 errors / 0 NEW warnings (the G5 change left
  `shared-governance.ps1`'s warning profile byte-identical); markdownlint 0 errors on all edited surfaces.

## Accepted Review and Retro Evidence

- **Iteration 001** (methodology): review accepted; retro approved. T013b (extension.yml bump + deploy-time
  `.specify` coverage) deferral to release/deploy APPROVED (Alon Fliess, 2026-06-11; drift D-001).
  `iterations/001/review.md`, `iterations/001/retro.md`.
- **Iteration 002** (runtime): review accepted after one bounded rework round (F1–F4: a forge-neutral-core
  honesty reword, dead-code + empty-catch cleanup, an MD047 lint fix); retro approved.
  `iterations/002/review.md`, `iterations/002/retro.md`.
- **Iteration 003** (forge-neutralization): Prop-145 review accepted; the review's own SC-008
  broad-verification caught D-304 (the shipped narrow sweep's blind spot), fixed in place + sweep widened;
  retro approved. `iterations/003/review.md`, `iterations/003/retro.md`.

## Main-Integration Reconciliation (this closeout)

`origin/main` was merged into the branch at closeout (merge commit `a2b7ff52`): Proposals 186 (crew mission
alias) + 187 (volatile runtime dependency monitoring) + `INDEX.md` — **docs-only, zero overlap** with the
feature-182 change set; no conflicts.

## Resolved at Closeout

- **T013b (drift D-001) — RESOLVED.** Version bumped 0.35.0 → 0.36.0 consistently across all manifest
  surfaces (extension.yml source + `.specify` mirror, `.specrew/config.yml` per Rule 15, Specrew.psd1
  ModuleVersion with `Prerelease='beta1'`, README badge + active-development-line). Branch-ready as
  `0.36.0-beta1`. Deploy-time `.specify` coverage confirmed: FileList-completeness PASS (all 16 new
  feature-182 deployable files declared). **NOT tagged / published / released** — the deferred SDLC step.
- **Iteration dashboard WARN — DECIDED: confirm-not-harden.** Iterations 002 + 003 carry the non-blocking
  `missing-dashboard-auto-render-regression` WARN. Determination (static inspection + the iter-2 retro +
  this session's experience): the only path that writes the iteration `dashboard.md` is
  `scaffold-reviewer-artifacts.ps1`, which **bundles it with the five lint-dirty reviewer supplements**
  (code-map, dependency-report, coverage-evidence, reviewer-index, review-diagrams); there is no
  dashboard-only switch and no clean boundary-sync auto-render path for iterations. So the proper path
  cannot render the iteration dashboards cleanly → the WARN stays a non-blocking WARN (consistent with
  iteration 001 being the lone iteration with a committed dashboard). The **feature** `closeout-dashboard.md`
  DID render cleanly (its scaffolder writes only that one file) and is committed.

## SC-008 Honesty Note (preserved per maintainer instruction)

The shipped SC-008 sweep (committed at T306) checked four mandate tokens and had a gate-coverage
directional blind spot: it **missed the `PSGallery` registry-name class**, leaving a `PSGallery` descriptor
in two downstream-governing methodology index docs. The original narrow sweep was therefore **incomplete**.
The review's post-implementation **broad-verification grep** caught it (D-304); the descriptors were
neutralized and the sweep's token set widened to regression-guard the registry-name class. The codified
sweep guards specific token classes, so **the one-time broad-verification grep remains the backstop** for
any future forge-coupling class. This is recorded in `iterations/003/review.md`, `drift-log.md` (D-304),
and the iteration-003 retro — not papered over.

## Known Non-Blocking Items

| Item | Disposition |
| --- | --- |
| Iteration 002 + 003 missing `dashboard.md` (`missing-dashboard-auto-render-regression` WARN). | confirm-not-harden (above): no clean iteration-dashboard render path; WARN stays non-blocking. Optional future: a dashboard-only render switch on the scaffolder, then render iter-2/iter-3 for parity with iter-1. |
| `Get-SpecrewAutomatedReviewOptIn` indentation-based hand-YAML parser (brittle to non-standard indentation; fails open to disabled). | Future hardening watch-item — add a contract test as the governance schema evolves. Does NOT block validation (correct for Specrew's canonical YAML + the test fixtures; safe failure direction). |
| SC-008 codified sweep guards specific token classes, not every conceivable forge mandate. | By design; the one-time broad-verification grep is the backstop (SC-008 honesty note above). |
| Repo-wide validator WARNs (pre-existing `missing-dashboard` on 048 / 141; hand-driven handoff-block notes). | Pre-existing on main, outside F-182; validator PASSES for F-182's iterations under default + `-IncludeClosed`. |

## Branch-Ready Constraints

- Do not release. Do not tag. Do not merge. Do not open a PR. Do not push to main. Do not open Iteration 4.
- The branch is release-ready as `0.36.0-beta1`; the next valid action is a separate human authorization
  for the PR / beta-publish / merge / stable-promotion SDLC steps (beta-before-stable; runtime beta
  validation on a real host before stable).

## Branch Hygiene at Closeout Preparation

- Branch: `182-work-kind-branch-governance`; integrated with `origin/main` via merge commit `a2b7ff52`
  (docs-only, no conflict).
- Working tree clean before closeout authorization except untracked/modified `.specrew`/`.squad` session +
  cache files (correctly left unstaged); closeout commits are path-limited to F-182 artifacts + the version
  bump + the integration merge.

## Final Status

Feature 182 is complete and ready as branch evidence only — three iterations delivered, reviewed (all
accepted), and retro'd; integrated with `origin/main`; version-bumped to `0.36.0-beta1`; the SC-008
incompleteness honestly recorded and fixed; the iteration-dashboard WARN dispositioned confirm-not-harden.
It is not released, tagged, merged, PR-opened, or promoted to main.
