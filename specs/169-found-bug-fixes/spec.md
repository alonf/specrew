# Feature Specification: Found-Bug Fixes (closeout/SDLC hygiene + amendment-validator coverage)

**Feature**: 169-found-bug-fixes
**Created**: 2026-06-06
**Status**: Draft
**Source**: GitHub issue #1761 (governed bug-fix slice off `main`)
**Branch**: 169-found-bug-fixes

## Summary

A governed bug-fix slice for the fixable items in #1761: the 3 pre-existing-on-main
local-test reds (closeout/SDLC hygiene) plus the 2 deferred Feature-168
post-ship-amendment validator coverage gaps. Each fix is the REAL fix — the test is the
spec, and no production gate is weakened to go green. Every gate/validator fix ships
with a negative/falsification test that fails for the target defect class and passes
after the fix (Proposal 145 Phase 5 discipline).

## In Scope

| FR | Bug | Fix approach | Evidence target |
| --- | --- | --- | --- |
| FR-001 | `beta-before-stable-sdlc.tests.ps1` red — `scripts/specrew-start.ps1` (and `docs/release-discipline.md`) lack the Steps 5-14 feature-closeout SDLC surface | Propagate the Steps 5-14 split AGENT/HUMAN-ownership SDLC surface (already present in the coordinator governance template) into `specrew-start.ps1`'s feature-closeout handoff block; complete `docs/release-discipline.md` for Steps 5-14 + PASS-gating, exemptions, audit modes, fail-loop | `beta-before-stable-sdlc.tests.ps1` green |
| FR-002 | `closeout-identity-schema-parity.tests.ps1` red — its `.scratch/` scaffold trips the production feature-closeout working-tree gate (sees the real repo's dirty tree) | Isolate the test's git context (scratch as its own git repo / scoped git env) — test-side only; the production working-tree gate is NOT relaxed | `closeout-identity-schema-parity.tests.ps1` green; production gate unchanged |
| FR-003 | `closeout-lifecycle-sync-commands.tests.ps1` red — 0 ValidateSet sites contain `'retro'` in module-internal `sync-boundary-state.ps1` | Ensure `'retro'` is a valid `-BoundaryType` ValidateSet member at the sites the test checks (`retro` is a canonical boundary) — the real fix, not a test relax | `closeout-lifecycle-sync-commands.tests.ps1` green |
| FR-004 | Feature-168 post-ship-amendment validator P2 ×2 — downgrade-then-edit bypass; deleted-proposal bypass | `validate-governance.ps1`: inspect the BASE-ref proposal status (catch shipped→mutable downgrade + body-edit); include deletions in the changed-proposal scan; apply to source + `.specify` mirror | New negative tests (evasion caught) + mirror parity; existing `validate-governance.post-ship-proposal-amendment.tests.ps1` still green |

## Out of Scope → Proposal 166 (concurrent-development / deploy hygiene)

- Find 4: slash legacy-signature exact-match symmetry — **unreachable** (released slash skills carry front matter → preserved earlier), so untestable; pre-existing F-160.
- Find 6: deployed `.github/agents/squad.agent.md` stale vs its source (six-section packet).
- Find 7: systemic uncommitted `reviewer.md` drift across worktrees.
- The systemic gate-wiring finding (iteration-closeout did not run parity/mechanical/markdownlint gates).

These are deploy/process hygiene (proposal-level), not test-driven bug fixes.

## Discipline (Proposal 145 / 146 grounding)

- The test is the spec; fix the real cause, never weaken a production gate to go green.
- Every gate/validator fix has a negative/falsification test (fails for the target defect, passes after the fix).
- Gate-local preflight before the PR: markdownlint + parity + the bounded CI test set + the 3 now-green red tests + the new tests.
- Claim-to-evidence: each FR maps to a passing test command.
