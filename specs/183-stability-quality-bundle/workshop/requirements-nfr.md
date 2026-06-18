# Requirements and NFR Lens Record: Stability and Quality Bundle

**Feature**: 183-stability-quality-bundle
**Date**: 2026-06-15
**Depth**: Medium
**Confirmation**: human-confirmed (lens-question scope)

## Functional Requirements

- **FR-001 — SessionStart fragment-priority drop**: When the SessionStart
  composite would exceed the host hook-output cap, the dispatcher keeps the
  bootstrap fragment intact and drops or shrinks the lower-priority refocus
  fragment so the lifecycle banner survives.
- **FR-002 — Hook provider fail-loud fallback**: When the bootstrap/refocus
  provider fails, the hook emits a minimal under-cap fallback directive on
  stdout, exits 0, and tells the agent this is degraded but governed.
- **FR-003 — Refocus unknown-session-id fix**: SessionStart
  journal/status/dedupe/breaker state must not collapse under global `unknown`;
  missing or malformed session IDs get a per-launch fallback token.
- **FR-004 — DirectiveDeliveryCap hermeticity**: The delivery-cap test must
  measure a synthetic shipped SessionStart composite, not ambient
  developer-machine refocus state.
- **FR-005 — Feature-closeout `.specify` classification and messaging**:
  Closeout sync must handle `.specify` dirty surfaces coherently, say “must be
  pushed” only when a remote/upstream exists, and refresh the closeout dashboard
  on auto-detect paths.
- **FR-006 — Mechanical local-test hygiene for #1761 reds #2/#3**: The two named
  local tests must stop failing because of dirty real-tree context or assertions
  against the wrong sync script copy.
- **FR-007 — Antigravity hook support**: Specrew must add Antigravity to the
  hook-capable host path using the current official Antigravity hook
  configuration surface, provision Specrew-owned hook entries without clobbering
  user hooks, map only verified Antigravity events to Specrew behavior, and
  remove stale user-facing Antigravity-no-hooks wording.

## Success Criteria

- **SC-001 — Cap-aware delivery**: A deterministic test proves an over-cap
  SessionStart composite preserves the bootstrap fragment and prevents the host
  from dropping the whole payload.
- **SC-002 — Fail-loud fallback**: A deterministic test proves provider failure
  emits a non-empty under-cap fallback directive on stdout, exits 0, and includes
  the recovery instruction to run `specrew where` or `/specrew-refocus`.
- **SC-003 — Session identity correctness**: Tests prove blank/missing/malformed
  host session IDs no longer write or report under global
  `refocus-state-unknown.json`, and per-session dedupe/breaker behavior keys by
  a per-launch token.
- **SC-004 — Hermetic cap fixture**: `tests/bootstrap/DirectiveDeliveryCap.Tests.ps1`
  passes using a synthetic startup SessionStart event and does not depend on
  ambient refocus state.
- **SC-005 — Closeout classification correctness**: Tests prove
  `.specify/extensions/` and companion `.specify` config/state files are
  classified coherently, no-upstream paths do not say “must be pushed,” and
  auto-detect closeout regenerates the dashboard.
- **SC-006 — Local red cleanup**: The two in-scope #1761 tests pass for the
  intended reasons: scratch git isolation and module-internal ValidateSet
  assertion.
- **SC-007 — Mirror and release readiness**: For touched extension/runtime files,
  source and `.specify` mirror remain byte-aligned; release readiness records the
  next actual beta target only after checking current tags/published state.
- **SC-008 — Real-host bootstrap validation**: Before stable promotion, a real
  host run confirms the SessionStart bootstrap/fallback behavior reaches the
  agent and does not silently degrade.
- **SC-009 — Antigravity hook parity evidence**: Tests and at least one
  Antigravity real-host validation prove Specrew provisions Antigravity hooks,
  preserves user hook entries, invokes the Specrew dispatcher/provider path for
  verified events, and does not claim SessionStart/Stop parity for any
  Antigravity event whose injection/capture behavior is unverified.

## NFR Priority Order

```text
1. Reliability / fail-safe behavior
   SessionStart must degrade visibly rather than silently losing governance.

2. Test integrity
   Tests must measure shipped behavior, not ambient state or the wrong file copy.

3. Lifecycle truth
   Closeout state/messages/dashboard must reflect actual repo/upstream state.

4. Maintainability
   Volatile text/policy/session-id/classifier logic stays localized.

5. Release discipline
   Beta-before-stable, mirror parity, and real-host validation remain mandatory.
```

Non-drivers:

- Performance beyond hook-output cap and test runtime sanity.
- UI polish beyond clear fallback/closeout wording.
- New security/compliance controls beyond local trust-boundary checks.

## Capacity and Deferral Rule

The amended FR set is in scope only if the plan fits within the 20 SP cap or is
explicitly split with human approval.

If planning shows over 20 SP:

1. Keep FR-001, FR-002, and FR-004 together as the SessionStart delivery anchor.
2. Include FR-007 in the explicit capacity discussion because it changes the
   host-support matrix and may be larger than a small fix.
3. Prefer keeping FR-003 if it is small enough, because it touches the same
   hook/journal path.
4. Defer FR-005 sub-parts or FR-006 mechanical fixes only with explicit human
   approval.
5. Do not pull in any excluded proposal/issue to fill or reshape the bundle.
