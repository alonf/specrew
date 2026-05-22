# Plan: PR Review Integration (Minimal Viable Slice)

**Spec**: [spec.md](spec.md)
**Proposal**: [Proposal 089](../../proposals/089-pr-review-integration-address-pr-review-gate.md)
**Created**: 2026-05-22
**Status**: Approved

## Approach

Ship the artifact path helper + host detection + a soft (non-blocking) validator warning. The hard-blocking lifecycle gate is explicitly out of scope here — that's a larger refactor (boundary state machine + new sync command + flow doc updates) deferred to a follow-up.

### Phase 1 — Helpers in shared-governance.ps1

1. `Get-SpecrewPrReviewResolutionPath` — returns canonical path `specs/<feature>/iterations/<N>/pr-review-resolution.md`.
2. `Test-HostProvidesAutomatedPrReview` — checks `gh` CLI presence + git remote URL containing `github.com`. Returns `@{Active, Host, Reviewer}`.

### Phase 2 — Validator soft-warning surface

Add a lightweight check that runs after iteration enumeration: for each target iteration whose state shows it's past pr-open boundary (or has a non-empty state.md mentioning PR), if the host has auto-review AND the artifact is missing, emit `[pr-review-soft-warning] ...`. NOT counted toward exit code; informational only.

### Phase 3 — Tests + sign-off

1. Integration tests at `tests/integration/pr-review-integration.tests.ps1` covering helpers, host detection, soft warning being non-blocking.
2. CHANGELOG entry; INDEX update; proposal status update.

## Risk + Mitigation

| Risk | Mitigation |
|---|---|
| Soft warning becomes noise | Only fires when artifact missing AND host detected AND past pr-open boundary |
| Host detection wrong | Conservative — defaults to `Active = false` (no warning) when uncertain |
| Future hard-gate breaks existing PRs | Hard-gate explicitly out of scope; future work introduces it via opt-in then default-on transition |

## Composition with Other Proposals

- **Proposal 089 full Pillars 2-4** (boundary gate + sync command + automation): builds on this foundation
- **Proposal 086 Pillar 5 (Repetition Detector)**: orthogonal; same "lightweight diagnostic surface" pattern
- **Proposal 045 (CI Watchdog)**: CI-side complement; could be paired in a future release

## Out of Scope (explicit deferral)

- Hard-blocking address-pr-review boundary
- New sync command for the boundary
- Multi-host detection beyond GitHub
- Automated Copilot finding extraction
- CI enforcement
