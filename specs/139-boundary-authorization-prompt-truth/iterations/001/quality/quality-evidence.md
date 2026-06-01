# Quality Evidence: Iteration 001

**Feature**: 139-boundary-authorization-prompt-truth
**Iteration**: 001
**Status**: review evidence accepted
**Current Evidence / Feature-Closeout Ref**: 62683c15148f2d9602ed75ec4d1755a5536f1f50
**D-006 Implementation Review Ref**: 2b84245284f3a530609f24cd24d18f9dbbfee5ee
**D-009 Release Repair Ref**: 79ceb2e8ceabcf8403e48023ea822abe73b466c9
**Stable Release Ref**: c745258c52c575f4704f4866d2b74b2f50381a5a
**Evidence-Only Delta**: `2b842452..62683c15` changes only Feature 139 evidence artifacts. No product-code, validator, script, prompt, or test implementation files changed in that delta.

## Planned Evidence

| Evidence Area | Planned Source | Blocking? |
| --- | --- | --- |
| Policy-derived prompt truth | T004-T010 tests and generated prompt diff | yes |
| `boundary_enforcement.policy_classes` snapshot | T005-T006 tests | yes |
| Six-section human re-entry packet | T011-T016 tests | yes |
| No legacy duplication / grouped prompts / `discuss prompt #N` | T017-T021 tests | yes |
| Non-compliant handoff fixtures | T022-T024 tests | yes |
| `Status: Approved` evidence check | T025-T026 tests | yes |
| Beta3 smoke evidence | T027 artifact | yes |
| Governance validation | T028 command output | yes |
| Implemented/enforced/observable/documented gap ledger | T029 review evidence | yes |

## Commands To Record During Implementation

```powershell
pwsh -File <focused prompt/status/handoff test selected by T003>
pwsh -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .
```

## Current Evidence

- `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\unit\validate-governance.interaction-model.tests.ps1` — PASS after send-back repair. The prior failure was the exact assertion `Assert-True -Condition ($readmeText -match 'Post-Commit Verification Protocol')`, which exposed an existing Feature 016 README docs/template-truth defect. The adjacent defect was repaired by adding the missing [README.md](file:///C:/tmp/Specrew-main-boundary-auth/README.md) protocol section.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\unit\boundary-authorization-prompt-truth.tests.ps1` — PASS after send-back repair. Covers policy snapshot resolution, generated prompt contract text, beta2-bad phrase rejection, six-section packet guidance, no required legacy duplication, non-compliant handoff fixtures, and positive/negative `Status: Approved` contradiction validation.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\integration\launch-mode-boundary-enforcement.tests.ps1` — PASS after send-back repair. Confirms policy seam and boundary authorization behavior still block unauthorised `plan -> tasks` progression.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\integration\start-command.ps1` — PASS after send-back repair. Confirms fresh project start artifact generation remains functional after prompt/state changes.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .specify\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .` — PASS after send-back repair for Feature 139 scoped validation. Existing warnings remain for old Feature 048 dashboard auto-render evidence and historical missing handoff evidence.
- Review rerun evidence: the same four required test suites passed during review, and scoped governance validation passed again after review artifact repair with only the known historical warnings.
- Automated pre-publish smoke artifact updated at [beta3-smoke-evidence.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/smoke/beta3-smoke-evidence.md). It records the local candidate PASS, the beta3/beta4 replay failures, the beta5 package-version resolver escape, the beta6 Step 11 PASS, and stable `v0.30.0` promotion.
- Send-back repair D-004: `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\unit\validate-governance.interaction-model.tests.ps1` — PASS after packet-wide clickable reference enforcement was strengthened.
- Send-back repair D-004: `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\unit\boundary-authorization-prompt-truth.tests.ps1` — PASS after stored boundary packet evidence validation and packet-wide bare-path regression tests were added.
- Send-back repair D-004: `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\integration\start-command.ps1` — PASS after generated start prompt guidance changed.
- Send-back repair D-004: `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\integration\launch-mode-boundary-enforcement.tests.ps1` — PASS after validator/evidence-path changes.
- Send-back repair D-004: `pwsh -NoProfile -ExecutionPolicy Bypass -File .specify\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .` — PASS for scoped Feature 139 validation after the repair. Remaining warnings are historical release-process warnings and legacy empty handoff-evidence warnings, not Feature 139 hard failures.
- Send-back repair D-005: direct handoff-validator replay of the exact bare primary review-section packet reported by the human — FAIL as expected with `validation-fail.bare-path-in-boundary-handoff` for all four bare repository paths. This proves the validator catches the exact case when the emitted packet text is supplied.
- Send-back repair D-005: the enforcement gap was packet/evidence parity, not bare-path detection. The generated prompt and coordinator governance template now require the packet text recorded as boundary evidence to be the exact human-visible packet emitted for approval, without post-validation summary or artifact-reference rewrite.
- Send-back repair D-006: the escape after D-004 and D-005 was that markdown file links were stripped before bare-path scanning, and boundary sync recorded evidence after state advancement instead of validating supplied packet text as a hard pre-advance gate. `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\unit\boundary-authorization-prompt-truth.tests.ps1` PASS at D-006 implementation review ref `2b842452` covers bare primary `specs/...` paths with a compliant legacy block, markdown-link primary packet references with a compliant legacy block, stored evidence validation for the exact visible packet text, and boundary-sync rejection before state advancement.
- Send-back repair D-006: `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\unit\validate-governance.interaction-model.tests.ps1` PASS at D-006 implementation review ref `2b842452`; Feature 016 navigation graduation remains covered after the common validator change.
- Send-back repair D-006 evidence refresh: `.specify\extensions\specrew-speckit\scripts\run-mechanical-checks.ps1` PASS at current evidence / feature-closeout ref `62683c15`; [mechanical-findings.json](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/iterations/001/quality/mechanical-findings.json) is regenerated and no longer `planned`.
- Send-back repair D-006 evidence refresh: scoped governance validation PASS at current evidence / feature-closeout ref `62683c15` after exact packet sync; remaining warnings are historical empty handoff-evidence and Feature 048 dashboard release-process risks, not Feature 139 failures.
- Proposal 145 evidence refresh: review evidence now uses the full Phase 0 through Phase 7 model, includes explicit n/a reasons for non-applicable phase checks, and records `2b842452..62683c15` as evidence-only.
- Branch hygiene: Feature 139 branch publication completed during release closeout through PR `#1562`; the D-009 release repair completed through PR `#1625`. Unrelated runtime/session dirty files remain excluded from the evidence commit.
- Release-closeout D-007: published `v0.30.0-beta3` Step 11 clean Codex replay FAIL because generated orientation said Claude Code and claimed Crew roles ran inside the session while `start-context.json` recorded `selected_host: codex`.
- Release-closeout D-007 repair: `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\integration\multi-host-launch-path.tests.ps1` — PASS. Covers host-orientation rendering for Codex, Claude, and Copilot/Squad and rejects false hard-coded host/runtime claims.
- Release-closeout D-007 repair: `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\integration\start-command.ps1` — PASS. Checks actual generated `.specrew\last-start-prompt.md` orientation against `.specrew\start-context.json` for Codex, Claude, and Copilot.
- Release-closeout D-007 repair: `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\manual\copilot-squad-smoke.ps1` — PASS in manual-handoff mode. Adds the release smoke assertion scanning actual emitted `.specrew\last-start-prompt.md` for false hard-coded host/runtime claims.
- Release-closeout D-007 repair: `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\unit\boundary-authorization-prompt-truth.tests.ps1` — PASS after host-orientation repair and prompt-code backtick correction.
- Release-closeout D-008 failure: published `v0.30.0-beta4` Step 11 clean Codex replay FAIL because visible orientation omitted the active Specrew prerelease/version, shared Rule 53 still implied Squad lifecycle automation for non-Squad hosts, and the approval gate rendered as plain numbered text instead of host-specific structured interaction where available.
- Release-closeout D-008 repair commit `6507c6af`: `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\integration\multi-host-launch-path.tests.ps1` — PASS. Covers initial/resume version + host + runtime orientation for Codex, Claude, and Copilot/Squad, and host-specific interaction guidance.
- Release-closeout D-008 repair commit `6507c6af`: `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\integration\start-command.ps1` — PASS. Checks actual generated `.specrew\last-start-prompt.md` and `.specrew\start-context.json` for `specrew_version`, `selected_host`, `runtime_class`, and host-rendered interaction guidance.
- Release-closeout D-008 repair commit `6507c6af`: `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\manual\copilot-squad-smoke.ps1` — PASS in manual-handoff mode. Adds release smoke assertions for missing version truth and false hard-coded host/runtime claims.
- Release-closeout D-008 repair commit `6507c6af`: `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\unit\boundary-authorization-prompt-truth.tests.ps1` — PASS. Confirms shared prompt Rule 53 delegates host-specific rendering and no longer embeds stale host/Squad automation copy.
- Release-closeout D-008 scratch Codex replay: [last-start-prompt.md](file:///C:/tmp/Specrew-main-boundary-auth/.scratch/d008-codex-replay/.specrew/last-start-prompt.md) and [start-context.json](file:///C:/tmp/Specrew-main-boundary-auth/.scratch/d008-codex-replay/.specrew/start-context.json) showed `Specrew: 0.30.0-beta4`, `Host: codex`, `runtime: non-Squad`, no Claude/Squad false claim, and Codex-only `request_user_input` guidance.
- Release-closeout D-008 evidence refresh: `.specify\extensions\specrew-speckit\scripts\run-mechanical-checks.ps1` — PASS after D-008; [mechanical-findings.json](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/iterations/001/quality/mechanical-findings.json) regenerated at 2026-06-01T17:50:18Z with no findings.
- Release-closeout D-008 evidence refresh: scoped governance validation with `-NoCacheRead` — PASS after evidence updates. Remaining warnings are historical Feature 048 dashboard and empty handoff-evidence release-process risks, not Feature 139 failures.
- Release-closeout D-009 failure: published `v0.30.0-beta5` package replay generated `0.30.0-beta4` version truth because `specrew start` selected a stale same-base installed prerelease instead of the running package manifest. Stable promotion remained blocked until the resolver was repaired and beta6 replay passed.
- Release-closeout D-009 repair commit `79ceb2e8`: `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\integration\start-command.ps1` — PASS. Adds regression coverage proving a running `0.30.0-beta5` manifest wins over a stale installed `0.30.0-beta4` module.
- Release-closeout D-009 repair commit `79ceb2e8`: `pwsh -NoProfile -ExecutionPolicy Bypass -File tests\integration\multi-host-launch-path.tests.ps1`, `tests\manual\copilot-squad-smoke.ps1`, and `tests\unit\boundary-authorization-prompt-truth.tests.ps1` — PASS. Confirms host rendering, smoke scanning, and packet contracts remain green.
- Published beta6 replay and release-readiness review — PASS. Covered Copilot/Squad greenfield, Claude greenfield, Antigravity greenfield, and beta6 release-tree validation at `origin/main` commit `c745258c` / tag `v0.30.0-beta6`.
- Stable promotion — PASS. `v0.30.0` was tagged on `c745258c52c575f4704f4866d2b74b2f50381a5a`; PowerShell Gallery resolves `Specrew 0.30.0`; GitHub Release `Specrew v0.30.0` is published, not draft, and not prerelease.

## Gap Ledger

| Behavior | Implemented | Enforced | Observable | Documented | Gap / Action |
| --- | --- | --- | --- | --- | --- |
| Policy-derived boundary prompt truth | yes | yes | yes | yes | No gap. Implemented in `scripts/specrew-start.ps1`; tested by `boundary-authorization-prompt-truth.tests.ps1` and start-command coverage. |
| `boundary_enforcement.policy_classes` snapshot | yes | yes | yes | yes | No gap. Implemented in shared governance state helpers and start artifact persistence; observable in generated `start-context.json`. |
| Removal of beta2-bad four-gate / auto-chain guidance | yes | yes | yes | yes | No gap. Unit test rejects the bad generated prompt phrases. |
| Six-section human re-entry packet | yes | yes | yes | yes | No gap. Generated prompt and coordinator governance template define all six sections. |
| Bare `file:///` review target guidance | yes | yes | yes | yes | No gap. Packet guidance and coordinator governance require bare URIs; existing handoff validator still enforces bare-path failures. |
| Packet-wide `file:///` artifact reference guidance | yes | yes | yes | yes | No gap after D-006. Generated prompt and coordinator governance require every artifact/file/directory reference in every packet section to use visible bare `file:///` URL form, stored packet evidence fails validation when bare repository paths or markdown file links appear outside command/code exemptions, boundary sync validates supplied packet text before state advancement, and boundary evidence must match the exact human-visible approval packet. |
| Contextual discussion prompts and `discuss prompt #N` loop | yes | yes | yes | yes | No gap. Generated prompt includes grouped prompts, approve-with-defaults affordance, response shapes, and renewed approval after prompt-specific discussion. |
| Future packet primary, no required legacy duplication | yes | yes | yes | yes | No gap. Generated prompt removed the mandatory legacy block template and states the packet is primary. |
| `Status: Approved` without verdict evidence check | yes | yes | yes | yes | No gap. Implemented as an active-feature validator check that exits non-zero when `Status: Approved` lacks matching human verdict evidence. |
| Non-compliant handoff fixtures | yes | yes | yes | yes | No gap. Missing `Why I Stopped`, approve-only, and context-free prompt fixtures fail the handoff validator. |
| Published beta replay and stable promotion evidence | yes | yes | yes | yes | Automated pre-publish prompt/state smoke PASS was committed; beta3 failed on D-007, beta4 failed on D-008, beta5 exposed D-009, beta6 passed Step 11 and release-readiness review, and stable `v0.30.0` was promoted. |
| D-007 host/runtime orientation truth | yes | yes | yes | yes | No gap after repair. Core prompt contains only host-neutral orientation requirements; selected-host rendering injects Codex, Claude, or Copilot/Squad wording from host metadata and `crew_runtime_status`; tests scan the actual generated prompt for false hard-coded claims. |
| D-008 version truth and host interaction rendering | yes | yes | yes | yes | No gap after repair. Orientation includes installed runtime version/prerelease, selected host, runtime class, and lifecycle position; Rule 53 is core response-contract guidance only; selected host adapters render structured question/menu guidance or exact textual fallback. |
| D-009 running module version truth | yes | yes | yes | yes | No gap after repair. The version resolver prefers the running module manifest before installed-module fallback, and start-command coverage proves stale same-base installed prereleases cannot override visible orientation/version truth. |
| Proposal 145 review lens | yes | yes | yes | yes | No gap for this feature scope after evidence refresh. The review uses the full Phase 0 through Phase 7 model with explicit n/a reasons. Full Proposal 145 implementation remains out of scope. |
| Scope exclusions | yes | yes | yes | yes | No gap. No full Proposal 150, hook enforcement, broad Proposal 151 migration, or lifecycle redesign was implemented. |
