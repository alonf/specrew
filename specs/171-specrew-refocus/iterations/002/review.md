# Review: Iteration 002 — research-gated host bindings, carries, docs, beta evidence

**Schema**: v1
**Reviewed**: 2026-06-07
**Overall Verdict**: accepted

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T013 | FR-013 | pass | Research matrix with ALL sources fetched live 2026-06-07 (none from memory, per the gate's test-integrity control): Claude re-verified (C6 trust-prompt CLOSED — no prompt for project hooks), Codex full-triad capable, Copilot hooks GA (the obsolete "no surface" premise OVERTURNED → spec reconciled as D-002, commit `7a27b48c`), Cursor B2+B3-capable with B1 documented variance, Antigravity deferred-with-path (JS-rendered docs; SDK corroboration only). Latency analysis re-confirmed TG-004: pwsh ~900ms cold spawn rejects per-tool-call events on EVERY host; UserPromptSubmit-class is the cheap B3 home. T014 estimate honestly revised 3.0→6.0 SP in-plan at matrix completion. Commit `287090c6`. |
| T014 | FR-013, FR-014 | pass | Verified bindings shipped from the matrix, never from memory: Codex B1+B2+B3 (`~/.codex/hooks.json`, top-level event keys, SessionStart source matchers + UserPromptSubmit additionalContext), Copilot B2 (`~/.copilot/hooks/specrew-refocus.json`, wholly-owned file, bash+powershell pair), Cursor B2 (`~/.cursor/hooks.json`, snake_case `additional_context` shaping). hosts/{codex,copilot,cursor}/host.psd1 carry RefocusHookBindings declarations; the dispatcher gained per-host event-shape normalization (camelCase/snake_case session keys, per-host injection output). Catalog provider row gained UserPromptSubmit (the codex-silent bug caught by fixture, fixed at root). Per-host opt-out markers (`refocus-hooks-optout-<kind>`). Deploy suite codex/copilot/cursor sections + dispatcher per-host fixtures all green at review re-run. Commit `287d05b6`. |
| T015 | FR-007, FR-016 | pass | User-guide refocus section (operator surface: kill-switch matrix, breaker, `--status`/`--reset-breaker`), troubleshooting failure-trace, README bullet; SC-008 beta-validation script authored as a 10-step runtime-evidence-only release gate (file presence explicitly non-satisfying, v0.30.0 lesson) including the Copilot B1 source-check as step 9. Commit `30fc5e24`. |
| T016 | FR-016 | pass | B4 compaction-steering research record: hook-driven summary steering is UNDOCUMENTED on all four hosts (Claude PostCompact side-effect-only; Copilot preCompact notification-only; Codex systemMessage is surfacing not steering; Cursor observational) → B4 stays research-gated OUT with re-open condition recorded; shipped managed-compaction-points + B1 disk-truth re-injection make summary-survival a nice-to-have, not a dependency. Recorded in research-matrix.md. Commit `30fc5e24`. |
| T017 | FR-014, FR-018 | pass | Defer-approved carries landed: `refocus-deploy-integration.ps1` (FileListed) with catalog managed-with-overlay merge — per-trigger `enabled` flags + user provider rows captured BEFORE the wholesale canonical refresh and re-applied AFTER; unparsable catalog aborts fail-SAFE in BOTH directions (never merges an aborted capture; never merges INTO an unparsable target). Hook deployment wired into `specrew update` (summary actions) and `specrew init` (after bundled-template deployment so `.claude` detection sees the deployed folder; DryRun-aware; fail-open). Update never silently flips a disable: proven by the overlay round-trip test (user b1 disable survives canonical refresh). +24 asserts. Commit `64a908e7`. |

## Claim-to-Evidence Ledger

| Claim | Evidence |
| --- | --- |
| All six refocus suites green at review time | Re-run 2026-06-07 post-T017: engine 40/40, digests 118/118, catalog 74/74, channels 21/21, dispatcher 65/65, deploy 58/58 — 336 asserts, 0 failures |
| T017 wiring does not regress the real update path (producer/consumer rule) | `tests/integration/update-command.ps1` full lane re-run green (exit 0) AFTER the wiring commit — the consumer-side demonstration, not just unit asserts |
| T017 wiring does not regress the real init path | `tests/integration/bootstrap-to-iteration.ps1` e2e re-run green at review time |
| FileList complete incl. the new integration script | `tests/integration/filelist-completeness.tests.ps1` PASS (262 entries; bidirectional guard) |
| No binding shipped from memory (FR-013 research gate) | research-matrix.md cites primary URL + fetch date per host; Antigravity honestly classified deferred-with-path because its primary contract was NOT fetchable — exactly the contracted no-verification-no-binding outcome |
| Update never silently flips a human disable (FR-014) | Deploy suite sections 5–6 (opt-out memory) + section 11 (user `b1 enabled:false` survives simulated canonical refresh) |
| Overlay merge fails SAFE (hardening-gate error-handling concern) | Deploy suite section 13: corrupt catalog → capture aborts, aborted capture never merged, corrupt target never written |
| Mechanical lenses clean | `run-mechanical-checks.ps1` → `quality/mechanical-findings.json`: `findings: []` (generated 2026-06-07T02:52Z) |
| Drift D-002 (Copilot hooks GA overturns FR-013 premise) reconciled | drift-log.md D-002; spec.md FR-013 clause updated same-day with the matrix as citation; commit `7a27b48c` |

## Release-Blocking Reminder (not an iteration gap)

SC-008 runtime beta validation (≥2 hook-bound hosts, 10-step script in `specs/171-specrew-refocus/beta-validation.md`) gates stable promotion at feature-closeout/beta time, per the universal beta-before-stable mandate; the Copilot B1 `source`-value check rides as its step 9. This is the contracted release gate, recorded here so review-signoff acceptance is not misread as release readiness; approvals at closeout land in `.squad\decisions.md`.

## Gap Ledger

- No requirement (FR/SC) gaps: all in-scope requirements verified: fixed-now.

## Notes

- Disprove-the-report discipline applied: every suite count above was re-derived by re-running at review time after the final commit (`64a908e7`), not quoted from implementation-time runs; the consumer-side lanes (update-command, bootstrap-to-iteration) were run because T017 modified the producer scripts (`specrew-update.ps1`, `specrew-init.ps1`) — the iter-5 producer/consumer meta-rule.
- Host-binding asymmetry (Codex triad vs Copilot/Cursor B2-only vs Antigravity none) is CONTRACTED behavior under FR-013 as amended by D-002 — hosts bind exactly the subset their verified surfaces express; B3 reaches every host via channel 1 regardless.
- Dispatcher suite grew 58→65 and deploy 19→58 versus iteration 001 — the growth is the T014 per-host fixtures and T017 wiring asserts, matching the revised 6.0 SP scope.
