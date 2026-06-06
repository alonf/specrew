# Send-Back State Reconciliation

**Feature**: 159-update-ux-small-fixes  
**Date**: 2026-06-05  
**Boundary**: specify send-back, before clarify  
**Action**: Working tree dirt outside Feature 159 specify artifacts was classified and preserved in a named stash before clarify.

## Stash

- **Stash label**: `preexisting-generated-state-before-f159-clarify`
- **Stash commit**: `1164498de5132c4ed7e0229e2338b596fac5138a`
- **Reason**: Keep Feature 159 isolated from generated session/runtime churn and stale Feature 140 state while preserving the changes for later inspection if needed.

## Classification

| Path | Classification | Rationale | Action |
| --- | --- | --- | --- |
| `.github/agents/squad.agent.md` | 3. pre-existing drift | Active generated governance text changed from the older three-section handoff guidance to the six-section packet shape. This is broad lifecycle/Feature 141-adjacent governance state, not Proposal 159 Tier 1 implementation scope. | Preserved in stash; not carried into Feature 159. |
| `.specrew/last-validator-summary.json` | 2. unrelated generated noise | Validator cache/summary updated from a local validation run. It is volatile evidence, not a Feature 159 artifact. | Preserved in stash; not carried into Feature 159. |
| `.squad/casting/registry.json` | 2. unrelated generated noise | JSON field ordering churn with no semantic roster change. | Preserved in stash; not carried into Feature 159. |
| `.squad/config.json` | 3. pre-existing drift | Runtime routing/model override state changed to Codex-specific routing. It may be valid session state, but it is not caused by or required for Proposal 159 Tier 1. | Preserved in stash; not carried into Feature 159. |
| `.squad/decisions.md` | 3. pre-existing drift | Appended delegated-routing and Feature 140 boundary-enforcement migration entries from session start. These entries belong to stale/resume state handling, not Feature 159 scope. | Preserved in stash; not carried into Feature 159. |
| `specs/140-unix-native-install/iterations/003/tasks-progress.yml` | 3. pre-existing drift | Timestamp-only update on closed Feature 140 task progress. Feature 140 is already closed/merged in git history and must not be recarried by Feature 159. | Preserved in stash; not carried into Feature 159. |
| `.codex/agents/*.toml` | 2. unrelated generated noise | Git reported modified files with no substantive diff beyond line-ending/index churn. | Preserved in stash; not carried into Feature 159. |
| `.cursor/rules/**` | 2. unrelated generated noise | Generated Cursor host skill/rule deployment surface. It is not part of Proposal 159 Tier 1 and risks colliding with parallel host-surface work. | Preserved in stash; not carried into Feature 159. |
| `.specrew/active-sessions.yml` | 2. unrelated generated noise | Local session tracking for the stale Feature 140 resume. | Preserved in stash; not carried into Feature 159. |
| `.specrew/version-check-cache.json` | 2. unrelated generated noise | Local PSGallery version-check cache. | Preserved in stash; not carried into Feature 159. |

## Result

No dirty state remains in the working tree after the stash, other than this reconciliation artifact before it is committed. Feature 159 can proceed to clarify only after this reconciliation is committed and pushed.
