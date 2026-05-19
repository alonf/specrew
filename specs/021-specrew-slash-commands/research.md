# Phase 0 Research: Specrew Slash-Command Surface

**Feature**: 021-specrew-slash-commands  
**Date**: 2026-05-18  
**Objective**: Resolve all planning unknowns before Phase 1 design and stop with a plan-ready slash-command contract.

---

## Decision 1: Use Squad-native skill deployment for the slash-command surface

**Decision**: Source slash-command assets from Specrew-managed templates and deploy the runtime command surface into `.copilot/skills/specrew-*/SKILL.md`, rather than inventing a new local plugin model or treating `.squad/skills/` as the primary deployed surface.

**Rationale**: The existing Squad-native integration contract already defines `.copilot/skills/<skill>/SKILL.md` as the deployed discovery surface and `specrew init` already owns skill deployment there. Reusing that path keeps Feature 021 additive to the current runtime model and composes with Feature 019 distribution/update flows.

**Alternatives considered**:

- Treat `.squad/skills/` as the primary deployed surface — rejected because the established runtime contract in this repo points to `.copilot/skills/` for deployed skill discovery.
- Introduce a new plugin package or extension-specific runtime — rejected because Specrew already documents a Squad-native deployment model and local bundled plugins are not the supported path.

---

## Decision 2: Route `/specrew.*` through the existing PowerShell dispatcher and explicit script entry points

**Decision**: Implement slash-command routing as a thin normalization layer over the existing `scripts/specrew.ps1` dispatcher, `Specrew.psm1` alias/module surface, and the explicit script entry points for `where`, `update`, `team`, and `review`.

**Rationale**: The current repository already has canonical command semantics, alias behavior, and error handling in PowerShell. Reusing those semantics minimizes drift, preserves raw/native command output, and keeps `/specrew.status` aligned as a true alias for the existing `where` workflow.

**Alternatives considered**:

- Build a separate slash-only router with duplicated logic — rejected because command drift would become likely and user trust would suffer.
- Route everything through natural-language prompts — rejected because the feature exists specifically to avoid natural-language routing as the primary path.

---

## Decision 3: Whitelist only documented per-command arguments and reject all unsupported extras

**Decision**: Adopt an explicit per-command argument whitelist derived from the repository's current Unix-style PowerShell parsing patterns. Unsupported or ambiguous extras are rejected with help guidance instead of being silently ignored or blindly forwarded.

**Rationale**: `specrew-update.ps1`, `specrew-review.ps1`, and `specrew-where.ps1` already parse documented `--` arguments and throw on unknown inputs. Extending the same discipline to `/specrew.*` satisfies FR-009, keeps failure modes inspectable, and avoids accidental boundary expansion through arbitrary passthrough arguments.

**Alternatives considered**:

- Pass all arguments through to the backend scripts — rejected because it would weaken the contract and make errors harder to distinguish from missing setup or routing faults.
- Create a slash-only argument vocabulary unrelated to existing scripts — rejected because it would force a second public contract for the same workflows.

---

## Decision 4: Keep `/specrew.help` as the canonical discovery fallback while preferring host-native `/specrew.` discovery

**Decision**: Prefer host-native `/specrew.` prefix discovery when the host supports it, but make `/specrew.help` the deterministic catalog fallback in every supported environment.

**Rationale**: The feature's primary value is discoverability, but host suggestion surfaces may vary across Copilot/Squad environments and across the PowerShell 7+ platform baseline. A canonical fallback prevents the command surface from feeling broken when inline suggestions are weak or unavailable.

**Alternatives considered**:

- Require inline discovery support before shipping — rejected because it would tie the feature to host behavior Specrew does not fully control.
- Make broader `/help` the only catalog — rejected because Feature 021 explicitly preserves a distinct Specrew namespace and does not want `/speckit.*` lifecycle commands to be obscured.

---

## Decision 5: Treat compatibility as “first release shipping Feature 021,” operationally expected to be the next post-0.20.0 Specrew release

**Decision**: Keep the normative compatibility rule as “the first published Specrew release that ships Feature 021 slash commands,” while planning operationally against the current repository baseline of `0.20.0` so the next shipping release becomes the minimum compatible slash-command version.

**Rationale**: The specification resolves the policy but does not need a final release stamp before implementation. The current project baseline is `0.20.0`, so planning can safely assume the slash-command surface will pin to the next release that includes this feature, while the actual numeric stamp remains a release-cut responsibility rather than a planning blocker.

**Alternatives considered**:

- Freeze an exact version number inside the plan now — rejected because it would create unnecessary drift risk before release management happens.
- Leave compatibility fully unspecified until implementation — rejected because the spec already requires clear upgrade/remediation behavior.

---

## Decision 6: Carry forward Feature 020 governance defaults as explicit planning rules

**Decision**: Apply the Feature 020 governance defaults directly to Feature 021: 3 repair cycles, 30 minutes wall-clock per failing test, live bookkeeping updates, per-lane drift labels, upfront hardening-gate scaffolding, push-after-every-commit, Write-Output-visible warnings, no case-insensitive PowerShell variable collisions, and file:/// prose-path discipline.

**Rationale**: These defaults are already documented in Feature 020 retro/proposal artifacts and in the Feature 021 spec and hardening scaffold. Making them explicit in the plan prevents them from being treated as informal memory and keeps the planning slice aligned with current Specrew governance.

**Alternatives considered**:

- Re-negotiate governance defaults during implementation — rejected because these settings are now stable enough to be planning-time defaults.
- Carry only the repair budget and ignore the observability/path/collision rules — rejected because the later retro specifically identified those as recurring failure patterns worth standardizing.

---

## Resolved Planning Unknowns

| Unknown | Resolution |
| --- | --- |
| Slash-command asset location | Deploy runtime assets under `.copilot/skills/specrew-*/SKILL.md`; keep source assets distribution-managed |
| Backend routing model | Reuse existing PowerShell dispatcher and explicit script entry points |
| Argument forwarding policy | Whitelist documented args only; reject unsupported extras |
| Discovery fallback | `/specrew.help` is canonical when inline suggestions are missing |
| Compatibility pin | First release shipping Feature 021; plan against the current `0.20.0` baseline |
| Governance carry-forward | Feature 020 defaults apply explicitly to Feature 021 |

**Outcome**: All planning unknowns are resolved. No `NEEDS CLARIFICATION` items remain for Phase 1 design.
