# Feature Closeout: Work Kind and Branch Governance Model

**Schema**: v1
**Feature**: 182-work-kind-branch-governance
**Branch**: 182-work-kind-branch-governance
**Closed**: 2026-06-13
**Status**: COMPLETE (branch-ready evidence) — **supersedes** the reopened iteration-1–3 closeout
**Closer**: Claude, authorized by Alon Fliess for feature-closeout (four-iteration, bounded scope)

> **This is the authoritative four-iteration feature-closeout.** It supersedes the iteration-1–3
> feature-closeout that was preserved with a reopened/superseded banner (verbatim in git history). Feature
> 182 was closed at iterations 1–3 (0.36.0-beta1), then **reopened before merge** for **Iteration 4** after
> a real-GitLab dogfood proved FR-019's neutralization had a runtime/deployed coverage gap. Iteration 4
> (FR-022–FR-026) is now implemented, reviewed (Prop-145 accepted after a send-back rework), and closed.
> Reopening pre-merge did NOT violate FR-004 (which governs **merged** features). DF-006 + F-174's
> `launch-contract.ps1` remain **F-174 handoffs**, out of F-182 scope.

## Executive Summary

Feature 182 delivers Proposal 182 (the Work Kind and Branch Governance Model) across **four iterations
(63.5 SP: 001 = 15.5, 002 = 17, 003 = 14, 004 = 17)**. All **twenty-six functional requirements
(FR-001..026)** and **sixteen success criteria (SC-001..016)** are implemented, reviewed (all four
iterations accepted), and retro'd (all four approved).

The feature ships in four layers:

1. **Methodology layer** (iteration 001) — the work-kind catalog + lifecycle templates + the
   provider-neutral governance model.
2. **Runtime layer** (iteration 002) — the provider-neutral CI work-kind validator + changed-file
   classifier + closeout-evidence checker, honest capability detection, the emergency-bypass audit, the
   GitHub reference adapter (`gh`-confined), brownfield adapt-or-change detection, the read-only
   synthesized-adapter example, the advisory CI workflow template, and the Specrew dogfood.
3. **Forge-neutralization migration** (iteration 003) — decoupling Specrew's downstream-governing
   *methodology* surfaces from its own GitHub-dev habits via a labeled-example pattern + an opt-in
   reviewer-routing gate, with the SC-008 no-over-claim sweep.
4. **Dogfood-findings completion / runtime-surface neutralization** (iteration 004) — completing FR-019's
   "ALL surfaces" claim for the **runtime/deployed** layer: the widened SC-015 sweep (`.ps1` launch-prompt
   text + deployed-agent files, not only methodology markdown), operationalized lifecycle templates
   (work_kind → `<kind>-lifecycle.md` resolved in the deployed shape + surfaced at the session-start
   intake path), forge-aware CI-lane guidance, lifecycle-end routing, and `provider.name` capability
   detection.

This branch is integrated with `origin/main` and version-bumped to **0.36.0** (branch-ready as
`0.36.0-beta1`) but is NOT released, tagged, merged, PR-opened, or pushed to main.

## Delivered Scope

| Layer / Requirements | Iteration | Status | Evidence |
| --- | --- | --- | --- |
| Methodology: work-kind catalog + schemas + lifecycle templates + provider-neutral governance model (FR-001..006, FR-008..010, FR-014, FR-017, FR-018) | 001 | complete | `extensions/specrew-speckit/knowledge/work-kinds.yml` (+ schemas); `templates/work-kind/*`; `work-kind-catalog.tests.ps1` 36 PASS |
| Runtime: CI validator + classifier + closeout-evidence + capability detection + bypass audit + GitHub adapter + brownfield + synthesis + advisory CI + dogfood (FR-007, FR-011..013, FR-015, FR-016, FR-020, FR-021) | 002 | complete | `extensions/specrew-speckit/scripts/{work-kind-validator,work-kind-common,capability-detector,provider-adapter,provider-generic,provider-github}.ps1`; `work-kind-validator.tests.ps1` 12, `work-kind-runtime.tests.ps1` 19, `provider-adapter.tests.ps1` 21 PASS |
| Forge-neutralization migration: decouple downstream-governing methodology surfaces; opt-in reviewer routing; SC-008 no-over-claim sweep (FR-019) | 003 | complete | neutralized coordinator prose + `lifecycle-discipline.md` + index docs (labeled examples); `shared-governance.ps1` opt-in gate; `forge-neutral-reviewer.tests.ps1` 10, `forge-neutralization-sweep.tests.ps1` PASS |
| Dogfood-findings completion: runtime/deployed neutralization (widened SC-015 sweep) + operationalized lifecycle templates (SC-016) + forge-aware CI lane + lifecycle-end routing + provider.name detection (FR-022..026) | 004 | complete | widened sweep over `.ps1` + deployed-agent surfaces; lifecycle resolver + refocus session-start surface; `forge-neutralization-sweep.tests.ps1` (43 md + 84 .ps1 + 22 agent), `work-kind-lifecycle.tests.ps1` 6, `capability-provider-resolution.tests.ps1` PASS |
| Test coverage per FR-020 across all layers | 001–004 | complete | work-kind/forge suites + parity + validators, 0 fail (see Tests and Validation) |

## Dogfood Findings Reconciliation (item 1)

The real-GitLab dogfood (`dogfood-findings.md`) drove the Iteration-4 reopen. Reconciled at this
closeout (full disposition table in `dogfood-findings.md` → "Iteration-4 Resolution Status"). RESOLVED rows
rest on confound-proof **artifact + deterministic-validator** evidence (per the test-validity note), not
behavior-level signals:

| Finding | Disposition | Resolved by |
| --- | --- | --- |
| DF-001 (CI-lane GitHub-only default on a non-GitHub forge) | **RESOLVED** | FR-024 — DevOps lens proposes CI for the project's own forge; honest "no lane ships for `<forge>`"; never defaults non-GitHub to GitHub Actions |
| DF-004 (detector reports `gitlab-ci`, not `gitlab`) | **RESOLVED** | FR-026 — `Resolve-SpecrewGovernanceProvider` reads `provider.name`, never `ci.provider`; reports `gitlab` |
| DF-005 (HEADLINE — runtime/launch-prompt layer un-neutralized) | **RESOLVED** | FR-022 / SC-015 — widened sweep over `.ps1` + deployed-agent surfaces; `specrew-start.ps1` + `squad.agent.md` neutralized to the labeled-example form |
| DF-008 (framework defect mis-scoped downstream; new-kind offered as "iteration N") | **RESOLVED** | FR-025 — lifecycle-end routing distinguishes downstream work / upstream tool defect (→ tool backlog) / new work-kind item (→ separate work item) |
| DF-009 (lifecycle templates inert; not wired to intake) | **RESOLVED** | FR-023 / SC-016 — templates operationalized via catalog/schema/deploy + deployed-shape resolver + refocus (session-start) surface |
| DF-006 (`specrew start` clobbers iteration state) | **F-174 HANDOFF** | Session-start/runtime-state, out of work-kind/forge scope; F-174 owns the rewrite + a resume-preserves-state regression test |
| DF-010 (release-train regression hazard) | **F-174 HANDOFF** | F-174 rebases onto post-F-182 main, preserves F-182's neutralized sources, resolves the `specrew-start.ps1` conflict in favor of its deletion, neutralizes `launch-contract.ps1`; F-182's widened sweep (binding obligation) is **landed** + fixture-proven |

(DF-002 was already RESOLVED-not-a-bug; DF-003 trended a non-finding — boundary discipline held. Neither
was an Iteration-4 deliverable.)

## Tests and Validation (re-run at this four-iteration closeout on the integrated tree)

Local CI/parity/governance sweep — **all PASS** (the F-141 lesson: run the sets the iterations never ran):

- **Governance validator**: `validate-governance` PASS for **all four iterations (001–004)** under the
  default scan AND under the stricter `-IncludeClosed` cross-iteration reconciliation
  (**4 PASS / 0 FAIL**, `iterations_validated=4`). The accepted-verdict + iteration-closeout checks
  (`Test-NoGapClosurePolicy`, `Test-ReviewEvidenceTreeIntegrity`, `Test-IterationCloseoutEvidence`) ran on
  the closeout state for iteration 004 and passed.
- **Work-kind + forge suites**: work-kind-catalog 36, provider-adapter 21, work-kind-validator,
  work-kind-runtime, work-kind-lifecycle 6 (FR-023/SC-016), capability-provider-resolution (FR-026/DF-004),
  forge-neutral-reviewer (T305), forge-neutralization-sweep (SC-008 + SC-015, incl. the F-174
  `launch-contract.ps1` regression fixture), host-coupling-firewall — **all PASS**.
- **Wrapper / version parity** (filelist-completeness, wrapper-filelist-parity, wrapper-docs-parity,
  wrapper-registry-parity, version-info-states, extension-registration-format) — **all PASS** (gate the
  0.36.0 version bump; FileList-completeness confirms the four lifecycle templates moved into the deployed
  extension tree are declared).
- **Regression guards**: gate-stop-skill (F-165 contract intact post-merge), boundary-sync-markdownlint-gate,
  closeout-lifecycle-sync-commands, pr-review-integration (incl. the `shared-governance.ps1` +
  `validate-governance.ps1` `.specify` mirror-parity assertions — mirrors clean after iter-4's `.specify`
  refocus edit) — **all PASS**.
- **Static**: PSScriptAnalyzer the four edited production `.ps1` **0 errors / 0 NEW warnings** (refocus.ps1
  baseline 2 `PSUseSingularNouns` = HEAD 2 on pre-existing functions; my insertion added zero); markdownlint
  **0 errors** on all edited surfaces.

## Accepted Review and Retro Evidence

- **Iteration 001** (methodology): review accepted; retro approved. T013b (extension.yml bump + deploy-time
  `.specify` coverage) deferral to release/deploy APPROVED (Alon Fliess, 2026-06-11; drift D-001).
  `iterations/001/review.md`, `iterations/001/retro.md`.
- **Iteration 002** (runtime): review accepted after one bounded rework round (F1–F4); retro approved.
  `iterations/002/review.md`, `iterations/002/retro.md`.
- **Iteration 003** (forge-neutralization): Prop-145 review accepted; the review's own SC-008
  broad-verification caught D-304 (the shipped narrow sweep's blind spot), fixed in place + sweep widened;
  retro approved. `iterations/003/review.md`, `iterations/003/retro.md`.
- **Iteration 004** (dogfood-findings completion): Prop-145 review **sent back** with three findings
  (F1 SC-016 resolved Exists=false in the real deployed `.specify` shape; F2 the surface was wired only
  into the too-late validator, not the intake/start path; F3 a file-level marker whitewashed a separate
  unlabeled `gh pr`), all **reworked** (commit `61e6b258`) and **accepted**; retro approved; the
  before-implement hardening gate closed with post-implementation runtime evidence recorded.
  `iterations/004/review.md`, `iterations/004/retro.md`.

## Main-Integration Reconciliation (this closeout)

`origin/main` is **fully contained in HEAD** (`git merge-base --is-ancestor origin/main HEAD` = yes; zero
commits in `origin/main` are missing from the branch; ahead 61 / behind 0 after the PR-prep sync below).
During Iteration 4 the branch was synced with main at the **Iteration-4 before-implement boundary** via
merge commit `45415737`, which integrated main through PR #2602 (Proposal 188 — boundary-packet
enforcement) among others, superseding the earlier iteration-1–3 integration (`a2b7ff52`).

**Post-closeout PR-prep sync (2026-06-13).** After this feature-closeout was accepted as branch-ready, the
branch was found 2 commits behind a newer `origin/main` and re-synced via merge commit `64994043` ("Merge
origin/main into 182-work-kind-branch-governance — post-closeout PR-prep sync"), which integrated **PR #2603
(Proposal 174 — variance agility / boundary-variance-disclosure)**. That change touches **only**
`proposals/174-boundary-variance-disclosure.md` + `proposals/INDEX.md` — zero overlap with the feature-182
change set; merge-tree reported 0 conflicts. The branch now contains current `origin/main` and is the
intended **next PR** (must land before F-174 rebases). The definitive remote integration happens at the
PR/merge step, authorized separately.

## Resolved at Closeout

- **Version — 0.36.0-beta1 (unchanged through Iteration 4).** The version was bumped 0.35.0 → 0.36.0 at the
  iteration-1–3 closeout and is consistent across all manifest surfaces (extension.yml source + `.specify`
  mirror, `.specrew/config.yml` per Rule 15, Specrew.psd1 ModuleVersion with `Prerelease='beta1'`, README
  badge + active-development line). Iteration 4 was **pre-merge rework on the same unreleased branch**, so
  no new beta number is warranted (nothing was published). FileList-completeness PASS confirms the new
  feature-182 deployable files — including the four `<kind>-lifecycle.md` templates **moved into the
  deployed extension tree** in Iteration 4 — are declared. **NOT tagged / published / released.**
- **Iteration dashboard WARN — DECIDED: confirm-not-harden (item 2; extended to Iteration 4).** Iterations
  002, 003, and now 004 carry the non-blocking `missing-dashboard-auto-render-regression` WARN (the WARN
  now names `182…004`). Determination (static inspection + the iter-2 retro + this session's experience):
  the only path that writes the iteration `dashboard.md` is `scaffold-reviewer-artifacts.ps1`, which
  **bundles it with the five lint-dirty reviewer supplements**; there is no dashboard-only switch and no
  clean boundary-sync auto-render path for iterations. So the proper path cannot render the iteration
  dashboards cleanly → the WARN stays a **non-blocking WARN** (consistent with iteration 001 being the lone
  iteration with a committed dashboard). It must **never harden into a gate**. Optional future: a
  dashboard-only render switch on the scaffolder, then render iter-2/3/4 for parity with iter-1.
- **Velocity snapshot (`closeout-dashboard.md`) — preserved as the frozen iteration-1–3 capture.** Per its
  own historical notice ("Re-running the dashboard later produces a new live view and **must not overwrite
  this file**"), the velocity snapshot is left as the frozen iter-1–3 closeout capture; it is NOT
  regenerated. **This `closeout.md` is the authoritative four-iteration record.**

## SC-008 Honesty Note (preserved per maintainer instruction)

The originally-shipped SC-008 sweep (committed at T306) checked four mandate tokens and had a gate-coverage
directional blind spot: it **missed the `PSGallery` registry-name class**, leaving a `PSGallery` descriptor
in two downstream-governing methodology index docs. The original narrow sweep was therefore **incomplete**.
The iteration-3 review's post-implementation **broad-verification grep** caught it (D-304); the descriptors
were neutralized and the sweep's token set widened to regression-guard the registry-name class. Iteration 4
then **widened the same sweep again** — from markdown-only to `.ps1` launch-prompt + deployed-agent
surfaces — after the real-GitLab dogfood proved the markdown-only bound left runtime/deployed mandates
un-neutralized (DF-005, the exact bound flagged in the iteration-3 review). The codified sweep guards
specific token classes + surface sets, so **the one-time broad-verification grep remains the backstop** for
any future forge-coupling class or surface. Recorded in `iterations/003/review.md` + `iterations/004/review.md`,
the drift logs (D-304, D-401), and the iteration retros — not papered over.

## Known Non-Blocking Items

| Item | Disposition |
| --- | --- |
| Iterations 002/003/004 missing `dashboard.md` (`missing-dashboard-auto-render-regression` WARN). | confirm-not-harden (above): no clean iteration-dashboard render path; WARN stays non-blocking. |
| Pre-existing `refocus-digests.tests.ps1` red ("specify.md scopes specrew-gate-stop verdict routing by host"). | Carry (maintainer-ratified, NOT a blocker): a gate-stop digest gap (F-165 / F-171 / Proposal-188 territory), out of work-kind/forge scope; confirmed pre-existing (fails on the baseline with the iter-4 rework stashed). Recorded in drift-log D-401. |
| Optional FR-024 GitLab CI **template** (`.gitlab-ci.yml`) not shipped. | Carry (maintainer-ratified, NOT a blocker): the forge-aware CI **lane + routing** ship; the turnkey template is descoped. |
| Work-kind **validator** lifecycle field kept as a **secondary** CI surface. | By design (Iteration-4 F2): the primary lifecycle surface is the refocus session-start path; the validator field is a secondary CI check. |
| `Get-SpecrewAutomatedReviewOptIn` indentation-based hand-YAML parser (brittle to non-standard indentation; fails open to disabled). | Future hardening watch-item — add a contract test as the governance schema evolves. Safe failure direction; does NOT block validation. |
| SC-008/SC-015 codified sweep guards specific token classes + surface sets, not every conceivable forge mandate. | By design; the one-time broad-verification grep is the backstop (SC-008 honesty note above). |
| Repo-wide validator WARNs (pre-existing `missing-dashboard` on 048 / 141; hand-driven handoff-block notes). | Pre-existing on main, outside F-182; validator PASSES for F-182's iterations under default + `-IncludeClosed`. |

## F-174 Coordination (handoffs preserved — out of F-182 scope)

- **DF-006** → F-174 owns the session-start/state rewrite + adds a resume-preserves-state regression test.
- **DF-005 source / `launch-contract.ps1`** → F-174 owns the new `scripts/internal/launch-contract.ps1`
  string and neutralizes it after rebasing onto F-182's labeled-example pattern.
- **DF-010** → F-174 waits for F-182 to merge first, rebases onto post-F-182 main **preserving** F-182's
  neutralized coordinator sources, and resolves the expected `specrew-start.ps1` conflict in favor of its
  deletion.
- **F-182's binding obligation is MET:** the pattern-based widened forge-neutralization sweep is landed and
  a regression fixture proves it flags a synthetic `launch-contract.ps1` mandate (2 hits) — it will catch
  F-174's site at reconciliation.

## Branch-Ready Constraints

- Do not release. Do not tag. Do not merge. Do not open a PR. Do not push to main.
- The branch is release-ready as `0.36.0-beta1`; the next valid action is a separate human authorization
  for the PR / beta-publish / merge / stable-promotion SDLC steps (beta-before-stable; runtime beta
  validation on a real host before stable).

## Branch Hygiene at Closeout

- Branch: `182-work-kind-branch-governance`; `origin/main` fully contained in HEAD (last synced at
  `64994043`, the post-closeout PR-prep sync — see Main-Integration Reconciliation; no conflicts; ahead 61 /
  behind 0).
- Working tree clean before closeout authorization except untracked/modified `.specrew`/`.squad` session +
  cache files (correctly left unstaged); closeout commits are path-limited to F-182 artifacts.

## Final Status

Feature 182 is complete and ready as branch evidence only — **four iterations** delivered (63.5 SP),
reviewed (all accepted; Iteration 4 accepted after a send-back rework), and retro'd; the real-GitLab
dogfood findings reconciled (DF-001/004/005/008/009 resolved; DF-006/DF-010 routed to F-174); integrated
with `origin/main`; version-bumped to `0.36.0-beta1`; the SC-008 incompleteness honestly recorded and
fixed across iterations 3 + 4; the iteration-dashboard WARN dispositioned confirm-not-harden. It is not
released, tagged, merged, PR-opened, or promoted to main.
