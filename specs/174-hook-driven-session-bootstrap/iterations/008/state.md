# Iteration State: 008

**Schema**: v1
**Current Phase**: implement (T048 + T049 done; T050 in progress — handover-provider mirror skew fixed + the anchorless-workshop handover fix IMPLEMENTED + proven; pending the live cross-host re-test)
**Iteration Status**: executing
**Last Completed Task**: T049 — user-profile intake at `specrew init` (FR-025). `Invoke-SpecrewInitProfileCapture` (user-profile.ps1) captures the dials when ABSENT + INTERACTIVE; skips silently on -Force / non-interactive / piped (the load-bearing no-hang guard); preserves an existing profile. Wired into specrew-init.ps1 (fail-open); the bootstrap directive nudges `/specrew-user-profile` when no profile is set. Added `SPECREW_USER_PROFILE_PATH` test seam + `tests/integration/user-profile-init-capture.tests.ps1` (7/7 pass). E2E `specrew init --force` non-interactive confirmed no hang + the skip path. PENDING live dogfood: the INTERACTIVE capture path + the nudge rendering (reuses the proven Invoke-FirstRunExpertisePrompt).
**Tasks Remaining**: T050 handover validation (cross-host exit-mode round-trip + resume restore).
**In Progress**: T050 — handover validation. Two fixes landed this session. (1) Mirror skew: the rolling handover never wrote at Stop because the deployable mirror `extensions/specrew-speckit/scripts/specrew-handover-provider.ps1` was a STALE pre-iter-5 copy (dropped `-Sections` param → silent fail-open); re-synced + generalized `ProviderMirrorParity.Tests.ps1`. (2) Anchorless-workshop handover (the "resync takes minutes" root cause): the pre-specify workshop leaves `session_state.feature_ref` blank → the floor stamped an empty `active_feature` → `Test-SpecrewHandoverValidity` returned `no-feature` → the handover was NEVER surfaced on resume. Fix = the Stop floor-writer resolves the feature from the current branch (`Resolve-SpecrewBranchFeatureRef`, new in `ProjectMetadataAccessor.ps1`) when the anchor is blank, so the handover validates → surfaces → the copilot resume-repair path fires on every host. Handover-first architecture means NO central-state write + NO resume-classification change (advisor-corrected from the prior "early-anchor write-back" design — that's DEFERRED). Proven: 4 resolver unit tests + 1 anchorless-workshop integration test + full bootstrap suite 20/20 + an E2E invalid→valid→welcome-back check. Plus conduct: design-workshop skill step 7 now checkpoints each lens durable before advancing (problem #1; honest agent-dependent residual). Remaining T050: deploy the fix for the dogfood + the live cross-host (claude/codex/copilot) exit/resume re-test on freshly re-init'd trials.
**Note (this session):** an accidental `specrew init --force` in the dev repo (a failed `Set-Location` to an 8.3 temp path left cwd in the repo) redeployed 6 managed-surface files + 2 untracked dirs — all reverted by mtime triage; pre-existing WIP + the T049 work were preserved.
**Baseline Ref**: iter-7 HEAD + this session's multi-host completion (codex format fixes, banner, version)
**Updated**: 2026-06-10T00:00:00Z

## Execution Summary

- **Iteration 008 opened** (maintainer direction, 2026-06-10) on the all-hosts-green baseline: claude / codex
  / copilot observed governed via the SessionStart hook; antigravity launcher-only by design.
- **iter-7 FR-024 multi-host completion landed this session** (the green baseline iter-8 builds on): codex
  entered the parity set after TWO codex-format fixes — (A) `~/.codex/hooks.json` needed codex's
  `{ hooks: { <Event> } }` wrapper (it had top-level event keys, so codex never ran the hook); (B) the
  dispatcher emitted the flat `{ additionalContext }` but codex injects context ONLY via
  `{ hookSpecificOutput: { hookEventName, additionalContext } }` (so the hook ran but its output was dropped).
  Both fixed + validated live (codex rendered the banner + drove the design workshop). Plus the mandatory
  banner hoist+expand (FR-004) and real `-SpecrewVersion` threading.
- **Spec amended**: FR-025 (user-profile intake capturable at `specrew init`, guarded interactive).
- **Scope**: T048 docs (specrew start optional) -> T049 intake-at-init -> T050 handover validation.
