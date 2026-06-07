# Implementation Plan: Specrew Refocus — Slash Command + Event-Driven Auto-Refocus

**Feature**: 171-specrew-refocus
**Date**: 2026-06-06
**Design input (authoritative)**: `iterations/001/design-analysis.md` — Human Decision: **approved for plan with Option C** (recorded `e1b55cf1`, pinned `2ca0c7fa`; gate packet `gates/design-analysis-001.md`; pre-plan gate PASS)
**Spec**: `spec.md` (FR-001..020, SC-001..010)

## Architecture (consumes Option C — not re-decided here)

Volatility-cut layering per the Co-Design Record: N thin per-host trigger adapters → one stable host-neutral engine → versioned data (catalog + digests). Three delivery channels: (1) boundary-sync wrapper stdout (all hosts), (2) instruction-file primer pointer (all hosts), (3) host event hooks via ONE dispatcher per event with an ordered/budgeted provider registry (hook-capable hosts, research-gated). Per-session runtime state carries dedupe + breaker + journal.

### Component plan with FR mapping

| Component | Deliverable | FRs | Test seam |
|---|---|---|---|
| RefocusEngine | `scripts/internal/refocus.ps1` (canonical) + deployed mirror | FR-001, 003, 004, 005, 017 | pure invocation, fixture digests/catalog, golden payloads |
| RefocusDigests | `extensions/specrew-speckit/refocus/general.md` + 10 stage digests | FR-002 | size caps; frontmatter schema; drift fixtures |
| RefocusScopeCatalog | `extensions/specrew-speckit/refocus-scopes.json` | FR-003, 005 | schema validation; version-mismatch fail-open |
| WrapperEmission | augmentation in deployed `sync-boundary-state.ps1` WRAPPER (not crew-169's module-internal file) | FR-006 | scratch-project integration test |
| Primer pointer | one-line addition per host instruction template | FR-007 | template content assert |
| SpecrewHookDispatcher | `scripts/internal/specrew-hook-dispatcher.ps1` + deployed mirror | FR-008, 011, 012 | simulated event JSON stdin per host shape |
| RefocusProvider | registry row + event→scope routing in dispatcher module | FR-009 | routing table tests; state-diff fixtures |
| RefocusRuntimeState | `.specrew/runtime/refocus-state-<sid>.json` handling | FR-010 | dedupe both orders; journal entries; pruning |
| Circuit breaker | in dispatcher + state | FR-011 | trip fixtures per condition; exemption asserts |
| HostHookBindings | `hosts/<kind>/` binding declarations + research matrix | FR-013 | per-host registration fixtures (post-research) |
| DeployIntegration | deploy-loop additions + merge-aware settings writer + FileList | FR-014, 018 | idempotence; user-entry byte-preservation |
| RefocusSkill | `squad-templates/skills/specrew-refocus/SKILL.md` + per-host deploy | FR-015 | catalog deployment tests (F-021/F-044 pattern) |
| CoordinatorAdvisory | governance template rule + boundary-packet hygiene line | FR-016 | template content assert |
| DigestDriftCheck | test-lane check | FR-019 | source-changed-after-review fixtures |

### Key flows

1. **B3 dedupe-correct** (Co-Design Record): wrapper emits + fingerprints → hook state-diff → dedupe/silent; bypass → inject.
2. **B1 post-compaction**: SessionStart(compact) → dispatcher → provider → engine(general+stage+role) → injected + journaled.
3. **Breaker trip**: runaway detected → per-trigger/global trip → ONE WARN + journal → session-scoped silence; slash + channel 1 unaffected.

## Quality planning (resolved profile embedded)

- **Profile**: `quality-profile.custom-composition.v1` (bounded custom composition; Phase-1 scope).
- **Lenses**: security-baseline@v1.0.0 (denial paths: session-id sanitization, path confinement, out-of-tree provider rejection — SC-007), robustness-baseline@v1.0.0 (fail-open everywhere — SC-001; breaker — SC-005), test-integrity@v1.0.0 (runtime claims need runtime evidence — SC-008; no file-presence proofs).
- **Required risk dimensions**: code-quality, design-quality-and-separation-of-concerns (the volatility cut is the review yardstick), verification-confidence (SC-002 exactly-once counts; SC-004 measured latency), maintainability (data-driven catalog; digest drift check).
- **Note on the resolver's n/a dimensions**: retry-idempotency auto-resolved n/a, but this feature's exactly-once/dedupe semantics ARE idempotency concerns — they are covered explicitly under verification-confidence via SC-002/P2 rather than left to the omitted gate.
- **Mechanical gates**: dead-field / anti-pattern / test-integrity checks run after implement (`run-mechanical-checks.ps1`) per standard flow.

## FR-to-test mapping (verification plan)

| FR group | Test vehicle | SC evidence |
|---|---|---|
| FR-001..005 (engine+content) | `tests/integration/refocus-engine.tests.ps1` | SC-003 size caps; SC-007 confinement |
| FR-006..007 (channels) | `tests/integration/refocus-channels.tests.ps1` (scratch project) | SC-002 stdout leg |
| FR-008..012 (dispatcher/state/breaker/codes) | `tests/integration/refocus-dispatcher.tests.ps1` (simulated stdin) | SC-001, SC-002, SC-005 |
| FR-013 (bindings) | per-host fixtures post-research + `research-matrix.md` artifact | SC-008 (live, beta) |
| FR-014, 018 (deploy) | `tests/integration/refocus-deploy.tests.ps1` | SC-006, SC-009 |
| FR-015..017 (skill/advisory/compact) | catalog deployment tests + template asserts + engine golden output | SC-010 |
| FR-019..020 | drift fixtures; the suites above ARE FR-020 | SC-001..SC-007 |

## Iteration split (TG-003)

- **Iteration 001 (~15-18 SP, within the 20 SP cap)**: engine + digests + catalog + channels 1-2 + skill + dispatcher/provider/state/journal + breaker + Claude binding + deploy integration + core test suites + `--compact-instructions` + advisory/hygiene lines. Exit: SC-001..SC-007, SC-009, SC-010 green locally; Claude binding live-smoke on this repo.
- **Iteration 002 (~5-8 SP)**: research matrix (Antigravity, Cursor, Codex surfaces) → verified bindings for those that pass; documented-variance entries for those that don't; docs (user-guide + troubleshooting + README touch); SC-008 beta validation evidence; B4/compaction-steering research NOTE (research-gated OUT — findings recorded, not shipped).

## Research tasks (iteration 002, gating FR-013 per host)

1. Antigravity: hook events, registration file, stdin shape, injection mechanism (105 research as starting point).
2. Cursor: hooks.json events (beforeShellExecution/afterFileEdit/stop/...) → which of B1/B2/B3 are expressible; rules-variant fallback.
3. Codex: notify mechanism → expressible subset; else documented variance.
4. Claude trust-prompt behavior for settings.local.json hooks (C6 verification).
5. **Copilot surface re-verification** (maintainer-raised at the plan boundary): the "no hook surface" finding is 2026-05 research — re-verify against current Copilot CLI; if ANY event surface exists or has shipped since, Copilot is hook-capable and gets a binding declaration under the Option C "all hook-capable hosts" decision, exactly like the others. Until then: channels 1+2 + slash + advisory (B1 is the only uncovered trigger — documented variance).

## Effort Model

- Effort unit: story points (SP); iteration cap: 20 SP; bounding: per-iteration hard cap; overcommit threshold + defer strategy per `.specrew/iteration-config.yml`.
- Capacity: iteration 001 = 18/20 SP planned; iteration 002 = 8/20 SP planned; total 18-26 SP consistent with Option C's 18-25 estimate.

## Risks + mitigations (carried from workshop)

- P4 pwsh-spawn latency on hook paths → measured during iter-001; miss → TG-004 channel-1 fallback decision returns to the human with data.
- Host fixture drift → research matrix records doc sources; EVENT_PARSE fail-open; SC-008 re-proves live per release.
- Hook-config merge hazards → C6 invariants + byte-preservation tests (SC-009).
- Scope creep via registry generality → registry stays minimal (ordered rows in the catalog; no plugin framework) per the lens-2 caution.
