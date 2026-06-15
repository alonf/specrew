# DevOps and Operations Lens Record: Stability and Quality Bundle

**Feature**: 183-stability-quality-bundle
**Date**: 2026-06-16
**Depth**: Medium
**Confirmation**: human-confirmed (lens-question scope)

## Operational Surfaces

```text
Hook provisioning
  - specrew init
  - specrew update
  - specrew hooks status|install|remove
  - deploy-refocus-hooks.ps1
  - per-host config files, including Antigravity .agents/hooks.json

Runtime validation
  - synthetic Pester fixtures for dispatcher/provider/session/closeout behavior
  - source-to-.specify mirror parity checks
  - real-host validation before stable promotion

Release path
  - check current tags/published beta state
  - publish next appropriate 0.37.0-beta<N>
  - real-host validate beta
  - promote 0.37.0 stable only after PASS

Docs
  - update stale Antigravity-no-hooks docs
  - update any user-facing fallback wording changed by FR-002 or FR-005
```

## Validation Matrix

```text
Local deterministic tests
  - DirectiveDeliveryCap hermetic test
  - dispatcher over-cap fragment priority
  - provider fail-loud fallback
  - session-id fallback/journal/dedupe behavior
  - closeout dirty classification / upstream message / dashboard auto-detect
  - #1761 mechanical red fixes
  - hook deployment tests for existing hosts + Antigravity

Mirror/parity checks
  - source extension scripts/templates vs .specify mirror
  - version/FileList readiness if new files are added

Manual / real-host evidence
  - at least one hook-capable host for SessionStart delivery path
  - Antigravity real-host hook validation if FR-007 ships
  - beta install/use validation before stable promotion
```

## Release Target Rule

Do not hard-code a specific beta suffix.

At release time:

1. Inspect current local tags, origin tags, and published release/package state.
2. Choose the next valid `0.37.0-beta<N>`.
3. Publish and validate that beta.
4. If validation fails, fix and publish the next beta number.
5. Promote `0.37.0` stable only from a beta that passed real-host validation.

## Operational Fallbacks

If hook deploy/config write fails:

- Fail open.
- Report the host and config path.
- Leave user config untouched when parse/merge is unsafe.
- Surface `specrew hooks status/install` as the repair path.
- Tell the user to run `specrew start --host <host>` for governed bootstrap
  fallback.

If hook config exists but hooks do not fire or cannot inject context:

- Use always-loaded capability surfaces where available:
  - host skills / slash commands;
  - `AGENTS.md` / coordinator instructions;
  - `/specrew-refocus`;
  - `specrew where`.
- Tell the user to run `specrew start --host <host>` for a full governed launch.
- Do not claim hook parity for that host/session.

If Antigravity hook behavior is partially verified:

- Ship only the verified subset, or defer FR-007 explicitly.
- Keep `.agents/skills` and `AGENTS.md` guidance as fallback surfaces.
- Keep `specrew start --host antigravity` as the authoritative fallback.
- Docs must name the limitation honestly.

If real-host validation fails:

- Do not promote stable.
- Record failure.
- Fix and publish the next beta.
