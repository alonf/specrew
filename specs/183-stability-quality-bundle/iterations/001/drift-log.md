# Drift Log: Iteration 001

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

**Total drift events**: 4
**Resolution rate**: 75% (3/4 resolved)
**Specification drift**: Governance drift, release-line drift, and scope-boundary drift detected and recorded

## Events

### DR-001 - Before-implement Gate Slip

**Detected At**: 2026-06-16T01:34:46Z
**Type**: `violation`
**Severity**: `moderate`
**Task/Boundary Ref**: T001 / before-implement
**Requirement Ref**: file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/spec.md Human Oversight Points
**Requirement Citation**: "Human approval required at specify, clarify, design-analysis, plan, tasks, before-implement, review, retro, iteration-closeout, feature-closeout, and release validation."
**Evidence**: file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/iterations/001/state.md and file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/iterations/001/plan.md record T001 as done, while file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/iterations/001/quality/hardening-gate.md still has `Approval Ref: —` and the before-implement packet was not stopped for an explicit human verdict before T001 ran.
**Description**: The crew treated the tasks approval as sufficient to author the before-implement readiness gate and begin implementation. That collapsed the tasks -> before-implement crossing and the before-implement human-judgment stop into one approval.
**Resolution**: `human-decision`
**Resolution Detail**: Fully resolved by `f183-i001-before-implement-approved`: T001 is ratified on its merits, T001 is not redone, Condition A is accepted, and T003 is authorized serial after T001.
**Status**: `resolved`.

### DR-002 - Boundary State and Execution State Conflation

**Detected At**: 2026-06-16T01:34:46Z
**Type**: `incomplete`
**Severity**: `minor`
**Task/Boundary Ref**: governance-only follow-up / before-implement
**Requirement Ref**: file:///C:/Dev/183-stability-quality-bundle/docs/methodology/lifecycle-discipline.md Honest state discipline
**Requirement Citation**: "state.md, task statuses, and capacity lines reflect disk truth, in canonical enums only."
**Evidence**: file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/iterations/001/state.md correctly keeps `Current Phase: before-implement` as the last canonical boundary while also recording `Iteration Status: executing` and `Last Completed Task: T001`. file:///C:/Dev/183-stability-quality-bundle/scripts/internal/task-progress.ps1 attempts to write `Current Phase: implement` once tasks start, but file:///C:/Dev/183-stability-quality-bundle/extensions/specrew-speckit/scripts/shared-governance.ps1 omits `implement` from canonical boundary types and file:///C:/Dev/183-stability-quality-bundle/extensions/specrew-speckit/scripts/validate-governance.ps1 rejects non-canonical `Current Phase` values.
**Description**: The artifacts and helper scripts use `Current Phase` for two different concepts: last authorized lifecycle boundary and active task-execution phase. That makes valid post-T001 state look confusing and would make the task-progress helper produce validator-invalid state if allowed to update the field.
**Resolution**: `human-decision`
**Resolution Detail**: Track as a separate governance-only repair outside F-183's 20 SP scope. It has no FR/SC trace and is not bound to T004 because the repair surface crosses file:///C:/Dev/183-stability-quality-bundle/scripts/internal/task-progress.ps1, file:///C:/Dev/183-stability-quality-bundle/extensions/specrew-speckit/scripts/shared-governance.ps1, and file:///C:/Dev/183-stability-quality-bundle/extensions/specrew-speckit/scripts/validate-governance.ps1, which sit outside T004's owner globs. If it must land during this iteration, add its own capacity line rather than absorbing it into T004.
**Status**: `open-nonblocking-governance-follow-up`.

### DR-003 - Planned 0.37.0 Beta Line Superseded

**Detected At**: 2026-06-16T10:16:36Z
**Type**: `incomplete`
**Severity**: `moderate`
**Task/Boundary Ref**: T008 / release readiness
**Requirement Ref**: file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/spec.md SC-007 and release target clarification
**Requirement Citation**: "The exact `0.37.0-beta<N>` target remains a release-time decision after inspecting local tags, origin tags, and published release/package state."
**Evidence**: file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/iterations/001/quality/release-readiness.md records local tags, origin tags, PSGallery packages, and GitHub releases showing `0.37.0-beta1` and `0.37.0` already published, with no `0.37.1*` or `0.38.0*` artifacts reserved.
**Description**: The feature was planned while `0.37.0-beta<N>` was the active release line, but the public release state moved before this iteration completed. Publishing another `0.37.0` prerelease after stable `0.37.0` exists would violate the beta-before-stable release discipline and create a lower-precedence prerelease behind an already-promoted stable package.
**Resolution**: `human-decision`
**Resolution Detail**: The human-approved dynamic target rule is applied by T008: the current release-readiness artifact selects `0.38.0-beta1` as the next valid beta target for this feature, with `0.38.0` as the later stable promotion target after T009 real-host validation and manual beta PASS. Version-bearing files remain unchanged in T008 because this task only records release readiness; release prep must bump them before publishing.
**Status**: `resolved`.

### DR-004 - FR-007 Split Guard Scope Expansion

**Detected At**: 2026-06-16T14:17:10Z
**Type**: `gold-plating`
**Severity**: `critical`
**Task/Boundary Ref**: T006 / review-signoff
**Requirement Ref**: file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/spec.md FR-007 and file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/iterations/001/plan.md split guard
**Requirement Citation**: "FR-007: Specrew MUST add Antigravity to the hook-capable host path using the current official Antigravity project hook configuration surface, provision Specrew-owned hook entries without clobbering user hooks, map only verified Antigravity events to Specrew behavior, and remove stale user-facing Antigravity-no-hooks wording. Delivery window: stability bundle unless capacity planning explicitly splits/defer it." The iteration plan also says: "Overcommit guardrail: if Antigravity verification expands beyond the bounded adapter/config/docs/test slice, pause for a human split/defer decision before implementation continues."
**Evidence**: The bounded T006 slice authorized project-scoped `.agents/hooks.json`, verified Antigravity event/output behavior, user-hook preservation, stale-doc cleanup, and fallback guidance. The working tree also introduces a generalized `RefocusHookBindings` host-manifest contract in file:///C:/Dev/183-stability-quality-bundle/hosts/_contract.md, adds hook binding rows to existing Claude/Codex/Copilot/Cursor manifests plus Antigravity, rewrites file:///C:/Dev/183-stability-quality-bundle/scripts/internal/deploy-refocus-hooks.ps1 from concrete host cases to manifest-driven config shapes/command modes/registrations, mirrors that 511-line deploy rewrite into both extension copies, and rewrites file:///C:/Dev/183-stability-quality-bundle/scripts/internal/specrew-hook-health.ps1 to derive hook health from manifests. `git diff --numstat` shows 381 insertions and 130 deletions in each deploy script copy, 160 insertions and 41 deletions in hook health, and hook-binding schema additions across all hook-capable host manifests, not only Antigravity.
**Description**: T006 appears to have crossed the FR-007 split guard. A minimal Antigravity adapter/config/docs/test slice may require some generic support so core scripts do not hard-code a new Antigravity branch, but the current working tree goes further by moving the whole hook-capable host model to `RefocusHookBindings` and migrating existing host hook registrations/status behavior into host manifests. That is a host-model refactor, not just a 4 SP bounded Antigravity slice.
**Resolution**: `human-decision`
**Resolution Detail**: Resolved by Alon's 2026-06-16 Option A verdict. The expanded `RefocusHookBindings` host-model refactor is accepted into F-183, FR-008/SC-010/TG-006/T011 are added as explicit scope, and capacity is re-baselined to 24/20 story_points as a human-approved over-cap exception. Review-signoff still requires durability repair, lifecycle-state reconciliation, configured reviewer-command repair or formal deferral, and a fresh Proposal 145 review against the expanded scope.
**Status**: `resolved`.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- DR-001 is fully resolved by `f183-i001-before-implement-approved`.
- DR-002 remains open as a separate governance-only repair outside F-183's 20 SP scope and does not block T003.
- DR-003 is resolved by file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/iterations/001/quality/release-readiness.md and changes the release target from the superseded `0.37.0-beta<N>` line to `0.38.0-beta1`.
- DR-004 is resolved by the 2026-06-16 Option A scope verdict; F-183 now includes the explicit 24/20 host-model refactor scope.
