# Tasks: Specrew Refocus — Slash Command + Event-Driven Auto-Refocus

**Feature**: 171-specrew-refocus
**Date**: 2026-06-07
**Input**: `plan.md` (Option C, approved `247fa0ba` + `aa107f9e`)
**Effort unit**: story points (SP); iteration cap 20 SP

## Iteration 001 — engine, channels, dispatcher, breaker, Claude binding (18.5 SP)

| Task | Description | Traces to | SP | Owner |
|---|---|---|---|---|
| T001 | RefocusEngine core: scope/flag resolution, catalog read + schema check, digest composition, banner line, budget clipping, path confinement, WARN envelope + reason codes; engine test suite (golden payloads, caps, confinement refusals) | FR-001, FR-003, FR-004, FR-005, FR-012, FR-020 / SC-003, SC-007 | 2.5 | Implementer |
| T002 | Digest family: author `refocus/general.md` + 10 per-stage digests with frontmatter `{scope, sources[], reviewed_at}` + file:/// pointers; size-cap tests; DigestDriftCheck test-lane (source-changed-after-review fixtures) | FR-002, FR-019 / SC-003 | 2.0 | Implementer |
| T003 | Scope catalog: `refocus-scopes.json` (scopes, triggers, budgets, provider registry incl. `kind: inject\|gate` field, enabled flags, schema_version) + deploy-time schema validation + version-mismatch fail-open fixture | FR-003 / SC-001 | 1.0 | Implementer |
| T004 | WrapperEmission (channel 1): deployed boundary-sync WRAPPER appends `--boundary <next>` payload post-sync + fingerprints injection; emits without dedupe when state unavailable; scratch-project integration test | FR-006, FR-020 / SC-002 | 1.0 | Implementer |
| T005 | Primer pointer (channel 2): one-line `/specrew-refocus` recovery pointer in host instruction templates; template content asserts | FR-007 / SC-010 | 0.5 | Implementer |
| T006 | SpecrewHookDispatcher: `-Event` entry, strict event-JSON parse, session-id sanitization, `.specrew/` self-gate, `SPECREW_REFOCUS_DISABLE` first-line check, sequential provider execution by registry order under budget arbitration with per-provider timeout, fail-open wrapper; **dormant gate-kind code path** (PreToolUse semantics, tool_input passthrough, permissionDecision output, fail-open-to-allow) fixture-tested but UNREGISTERED (F-165 seat); simulated-stdin test suite | FR-008, FR-012, FR-020 / SC-001, SC-007 | 2.5 | Implementer |
| T007 | RefocusProvider: event/source → engine-scope routing (B1/B2/B3); B3 state-diff detection with LastWriteTime cheap-guard; routing-table + state-diff fixtures (dedupe both channel orders) | FR-009 / SC-002 | 1.5 | Implementer |
| T008 | RuntimeSessionState: per-session files (sanitized id), fingerprints, bounded injection journal with outcomes, opportunistic pruning; journal + pruning tests | FR-010 / SC-002, SC-010 | 1.5 | Implementer |
| T009 | Circuit breaker: per-trigger/global trip conditions (runaway, token cap, state unavailability), single trip WARN naming reason + re-enable paths, session-scoped reset, `--reset-breaker` + `--status`; trip fixtures per condition + exemption asserts (slash + channel 1 unaffected) | FR-011 / SC-005 | 1.5 | Implementer |
| T010 | Claude binding + merge-aware hook deploy: `hosts/claude` binding declaration (B1+B2+B3), settings.local.json merge-aware writer (C6 invariants: add-if-absent, ours-by-command-path, user entries byte-untouched, idempotent), opt-out memory; deploy tests (byte-preservation, idempotence, opt-out respected) | FR-013 (Claude), FR-014, FR-020 / SC-006, SC-009 | 2.0 | Implementer |
| T011 | Skill + deploy integration: `specrew-refocus` SKILL.md + per-host catalog deploy (.claude/.github/.agents + Cursor rules variant); deploy-loop classes (managed mirrors; managed-with-overlay catalog); FileList declarations for all shipped files | FR-015, FR-018 / SC-009 | 1.5 | Implementer |
| T012 | Managed compaction points + advisory: `--compact-instructions` preserve-list generation from lifecycle state; coordinator advisory fallback rule; boundary-packet context-hygiene line | FR-016, FR-017 / SC-010 | 1.0 | Implementer |

**Iteration 001 capacity: 18.5/20 SP**

## Iteration 002 — research-gated host bindings, docs, beta evidence (8.0 SP)

| Task | Description | Traces to | SP | Owner |
|---|---|---|---|---|
| T013 | Research matrix artifact: verify hook surfaces for Antigravity, Cursor, Codex, **Copilot (re-verification, maintainer-raised)** + Claude trust-prompt behavior for settings.local.json (C6); record events, stdin shape, injection mechanism, settings analog per host with doc sources | FR-013 / SC-008 | 3.0 | Implementer |
| T014 | Verified host bindings: binding declarations + dispatcher registration + simulated-event fixtures for every host the matrix confirms hook-capable; documented-variance entries for hosts that fail verification | FR-013, FR-014 / SC-008 | 3.0 | Implementer |
| T015 | Docs + beta evidence prep: user-guide section, troubleshooting failure-trace walk, README touch; SC-008 beta validation script (real compaction + real boundary cross on ≥2 hook-bound hosts; kill-switch walk; journal citations) | FR-007 (docs), SC-008, SC-010 | 1.5 | Implementer |
| T016 | Compaction-steering research record (B4, research-gated OUT): PreCompact augmentation + persistent-instruction efficacy findings recorded as follow-up input — no shipping in this feature | scope-line disposition 1 | 0.5 | Implementer |
| T017 | Defer-approved carries (review-signoff 2026-06-07): init/update call-site wiring for deploy-refocus-hooks (opt-out respected); catalog managed-with-overlay merge on update (user keys preserved); wiring tests | FR-014, FR-018 / SC-006, SC-009 | 1.5 | Implementer |

**Iteration 002 capacity: 9.5/20 SP · Feature total: 28.0 SP (Option C envelope +0.5 F-165 gate-seat +1.5 defer-approved carries made explicit, 2026-06-07)**

## Traceability check (after-tasks)

- **Every task → ≥1 FR/SC**: T001..T016 all carry explicit traces (table column 3). ✓
- **Every FR → ≥1 task** (T017 added 2026-06-07 per approved defers; FR-014 also T017, FR-018 also T017): FR-001 (T001) · FR-002 (T002) · FR-003 (T001, T003) · FR-004 (T001) · FR-005 (T001) · FR-006 (T004) · FR-007 (T005, T015) · FR-008 (T006) · FR-009 (T007) · FR-010 (T008) · FR-011 (T009) · FR-012 (T001, T006) · FR-013 (T010, T013, T014) · FR-014 (T010, T014) · FR-015 (T011) · FR-016 (T012) · FR-017 (T012) · FR-018 (T011) · FR-019 (T002) · FR-020 (T001, T004, T006, T010). ✓
- **Every SC → covering tasks**: SC-001 (T003, T006) · SC-002 (T004, T007, T008) · SC-003 (T001, T002) · SC-004 (measured during T006/T007; TG-004 return path) · SC-005 (T009) · SC-006 (T010) · SC-007 (T001, T006) · SC-008 (T013, T014, T015) · SC-009 (T010, T011) · SC-010 (T005, T008, T012, T015). ✓

## Sequencing notes

- T001→T003 before T004/T006 (engine + catalog are dependencies); T006→T007→T008→T009 in order (dispatcher → provider → state → breaker); T010/T011 after T006; T012 after T001. T013 gates T014 per host.
- No file-surface collision with active crews (169: specrew-start/sync-internal/validator; 170: evaluation surface) — verified at intake; T004 touches the deployed WRAPPER, not crew-169's module-internal copy.
