# Review: Iteration 001 — engine, channels, dispatcher, breaker, Claude binding

**Schema**: v1
**Reviewed**: 2026-06-07
**Overall Verdict**: accepted

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-001, FR-003, FR-004, FR-005, FR-012, FR-020 | pass | Engine suite 40/40: banner contract, budget clipping (BUDGET_EXCEEDED), path confinement (SOURCE_CONFINED ×2 vectors), fail-open on missing/mismatched catalog, --compact-instructions from live state, --status, --reset-breaker, exit-2 arg errors. Commit `e7efbb7a`. |
| T002 | FR-002, FR-019 | pass | 11 digests, frontmatter contract, declared sources exist, size caps (general ~582 ≤600; composed ≤2,500), drift comparator (warn-lane), {{project_root}}→file:/// substitution through the real engine. Digest suite 118/118. Commits `47a58e26` + `f5aba143` (maintainer-directed 145-grounded revision). |
| T003 | FR-003 | pass | Real catalog: 12 scopes + 3 triggers + budgets + provider registry (kind field); boundary.next successor semantics proven both directions (implement→review-signoff; terminal→general). Dormant-seat invariants ENFORCED by test (no gate rows; no PreToolUse claims). Catalog suite 74/74. Commit `2440e4c6`. |
| T004 | FR-006, FR-020 | pass | Real wrapper + real internal sync on a scratch project: incoming-stage digest rides sync stdout (specify→clarify verified), channel-1 fingerprint written, catalog disable silences, missing/broken engine fails open with sync unaffected. Channels suite 21/21. Commit `df2d3fe6`. |
| T005 | FR-007 | pass | Coordinator governance rule 4 (recovery pointer + treat-banner-as-binding) in canonical + .specify mirror; content asserts green. Cursor channel-2 = skill-as-rule via T011 (recorded). Commit `1f2d7ee6`. |
| T006 | FR-008, FR-012, FR-020 | pass | Kill-switch-first PROVEN (broken catalog unreached), self-gate, stdin event parsing (production path), sanitization, ordered providers + timeout + crash skip + out-of-tree refusal, per-event output shaping, dormant gate path (fixture deny passes; crashed gate fails OPEN). Commit `d22125eb`. |
| T007 | FR-009 | pass | Anchor-on-first-sight (no spurious injection), mtime cheap-guard, crossing→inject (incoming stage), wrapper-fingerprinted crossing→dedupe, bypass→inject, corrupt-state quiet+loud-once. Commit `e008a616`. |
| T008 | FR-010 | pass | Journal ring (20) with outcomes injected/deduped/failed (+budget-clipped detection), banner-fact parsing, per-session files, ~7-day pruning verified. Commit `a8478287`. |
| T009 | FR-011 | pass | Per-trigger runaway trip (b3 alive while b2 tripped), global token-cap trip, loud-once WARN naming re-enable paths, silent suppression after, --reset-breaker clears, slash exemption proven. Commit `90b5ea6b`. |
| T010 | FR-013 (Claude), FR-014, FR-020 | pass | Binding declaration in hosts/claude/host.psd1; merge-aware settings.local.json writer: user entries preserved (incl. mixed groups), byte-idempotent re-deploys, recorded opt-out + -Force re-enable, unparsable-file refusal, PreToolUse never registered. Deploy suite 19/19. Commit `c0ba19d1`. |
| T011 | FR-015, FR-018 | pass | Generic skill template → specrew-refocus in .claude/.github/.agents catalogs (+managed markers); deployed-canonical extension scripts; 19 FileList declarations — bidirectional completeness gate green; distribution + multi-path suites green. Commit `38fded70`. |
| T012 | FR-016, FR-017 | pass | Coordinator rule 4 extended: advisory fallback (non-hook hosts) + managed-compaction-points hygiene line wired to --compact-instructions; mirrors synced; content asserts green. Commit `6348b65e`. |

## Claim-to-Evidence Ledger

| Claim | Evidence |
| --- | --- |
| All six refocus suites green | Re-run at review time: engine 40/40, digests 118/118, catalog 74/74, channels 21/21, dispatcher 58/58, deploy 19/19 — 330 asserts, 0 failures (commands in coverage-evidence.md Tests Run) |
| FileList complete for the 19 new shipped files | `tests/integration/filelist-completeness.tests.ps1` PASS (261 entries; bidirectional guard) after additions |
| Skill deployment regression-free | `slash-command-distribution.tests.ps1` + `slash-command-multi-path.tests.ps1` both fully green at review time |
| Mechanical lenses clean | `run-mechanical-checks.ps1` → `quality/mechanical-findings.json`: `findings: []` |
| Exactly-once across channels (SC-002) | Dispatcher tests 12c/12d + channels test 1: stdout-then-hook order dedupes; hook-only order injects; both asserted against the real engine + real digests |
| Security denial paths (SC-007) | Hostile session-id sanitization (filename-confined), catalog absolute/`..` refusal, out-of-tree provider refusal, malformed event JSON quiet — all fixture-proven |
| P4 latency (SC-004) | MEASURED and MISSED — see Open Decision below; this is the TG-004 contracted human-return, not a hidden gap |
| Drift D-001 (catalog .yml→.json) reconciled | drift-log.md D-001; spec/plan/tasks/contracts/data-model updated; repo-convention rationale recorded |

## Open Decision (TG-004 — returns to the human at this gate, by spec design)

**SC-004 measurements (10-run, this machine):** B3 check path median **~920ms** / p95 ~944ms (bar: ≤150ms p95); B2 end-to-end **~2,043ms** (bar: ≤1s). Root cause is structural: each hook fire spawns a pwsh process (~900ms cold start) — the dispatcher, plus a second spawn for the engine on inject paths. Options are presented in the review-signoff packet; the spec (TG-004) contracted exactly this return-with-data rather than a silent fallback.

## Gap Ledger

- No requirement (FR/SC) gaps: all in-scope requirements verified: fixed-now.
- SC-004 latency bar missed; TG-004 contracted human-return executed at this gate (options in the boundary packet), not a silent fallback: deferred.
- Iteration-002 planned carries (not new gaps): init/update call-site wiring for deploy-refocus-hooks; catalog managed-with-overlay merge on update; host research matrix incl. Copilot re-verification: deferred.

## Notes

- The review applied the disprove-the-report discipline (review-signoff digest rule 9): suite counts re-derived by re-running at review time, not quoted from implementation commits; the latency claim was measured, not asserted.
- The scaffold's form-vs-meaning warning (12 tasks vs 63 changed files) decomposes cleanly: ~30 lifecycle/spec/workshop artifacts + ~33 implementation files (3 scripts ×2 trees, 11 digests ×2 trees, catalog ×2, 4 skill-dir deployments, 6 test suites, host psd1, FileList, governance template ×2) — explained, not anomalous.
