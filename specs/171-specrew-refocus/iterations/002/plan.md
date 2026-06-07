# Iteration Plan: 002 — research-gated host bindings, carries, docs, beta evidence

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 9.5/20 story_points
**Started**: 2026-06-07
**Completed**:

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
    (Common mistakes the validator REJECTS: `approved`, `in-progress`, `done`, `ready`.)
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
    Append explanatory notes in the Notes section at the bottom instead.
  - Task Status (in the Tasks table) MUST be one of:
      planned | in-progress | done | needs-rework | deferred | blocked
    (Note `in-progress` uses a hyphen, not an underscore. `done` not `completed`.)
-->

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-001 | A host-neutral refocus engine MUST resolve scope flags (`no-args \| --boundary <name> \| --role <name> \| --shape-catalog \| --everything \| --trigger <b1\|b2\|b3> \| --compact-instructions \| --status \| --reset-breaker`) to a markdown payload whose first line is the banner `[specrew-refocus] trigger=<t> scope=<s> sources=<n> tokens~<est>`; warnings go to stderr as `[specrew-refocus] WARN <CODE> <msg>`. The engine ships as a canonical internal script mirrored to the deployed extension scripts directory; hooks and the wrapper invoke the project-local copy directly. | — |
| FR-002 | A purpose-authored digest family MUST exist: `refocus/general.md` (always-true core) plus one digest per lifecycle stage (specify, clarify, plan, tasks, before-implement, implement, review-signoff, retro, iteration-closeout, feature-closeout); each digest declares frontmatter `{scope, sources[], reviewed_at}` and ends with `file:///`-style pointers to its canonical sources. Every injection composes `general` + the stage digest. | — |
| FR-003 | Scope→digest, trigger→scope, per-trigger token budgets, and the provider registry MUST live in a data-driven catalog (`refocus-scopes.json`) carrying a required `schema_version`; evolution is additive-only; version mismatch fails open with `CATALOG_SCHEMA` WARN. | — |
| FR-004 | The engine MUST refuse non-repo-relative content sources (absolute paths, `..` traversal) with `SOURCE_CONFINED` WARN; provider registry commands MUST resolve under the project's deployed tree (validated at deploy time). | — |
| FR-005 | The engine MUST enforce the catalog's per-trigger budget caps — clipping with `BUDGET_EXCEEDED` WARN and journaling outcome=budget-clipped — and report the token estimate in the banner. The engine never dedupes (purity); dedupe lives in the trigger layer. | — |
| FR-006 | The deployed boundary-sync **wrapper** MUST append the engine's `--boundary <next>` payload to its stdout after a successful boundary advance (all hosts) and fingerprint the injection in runtime state; when state is unavailable it emits without dedupe (intrinsically bounded) rather than going quiet. | — |
| FR-007 | Host instruction files (primer floor) MUST point at `/specrew-refocus` as the recovery surface — minimal touch; full primer content remains Proposal 133's scope. | — |
| FR-008 | A single `SpecrewHookDispatcher` MUST be the ONLY Specrew-registered handler per bound host event: it parses host event JSON strictly (never evaluating content), sanitizes `session_id` to `[a-zA-Z0-9-]` before any filename use, runs registry providers sequentially by `order` under total budget arbitration with per-provider timeout (crash/timeout → skip + `PROVIDER_FAILED` WARN), applies one dedupe layer, and self-gates on `.specrew/` presence. Its first executable line checks `SPECREW_REFOCUS_DISABLE` and exits silently when set. **Forward-compat (maintainer-directed, 2026-06-07, F-165 coordination)**: the provider contract carries `kind: inject \| gate` (default `inject`); `gate` providers run on `PreToolUse`, receive `tool_input`, and return an allow/deny `permissionDecision` instead of a markdown fragment, failing OPEN to allow + WARN (P1 applied to gating). This feature ships NO gate provider and does NOT register `PreToolUse` — the dispatcher's gate code path is fixture-tested and dormant; the registration flips on via the same merge-aware deploy when the first gate row (e.g., F-165's file-link gate) lands in the catalog. Ownership rule: any future Specrew hook mechanism routes through this dispatcher — never a second registration on the settings surface. | — |
| FR-009 | `RefocusProvider` (registry row #1) MUST route events to triggers: `SessionStart source:compact` → B1 (general + current stage + active role); `SessionStart source:startup\|resume\|clear` → B2 (pointer set + lifecycle position); B3 boundary-cross detection MUST diff the boundary cursor in `start-context.json` against the runtime-local last-seen value (watch the state, never the actor) behind a LastWriteTime cheap-guard. | — |
| FR-010 | Per-session runtime state files (`.specrew/runtime/refocus-state-<sanitized-session-id>.json`, gitignored, opportunistically pruned ~7 days) MUST hold the last-seen boundary, injection fingerprints, breaker state, and a bounded injection journal (~20 entries: `{at, trigger, scope, channel, tokens, outcome}` with outcome ∈ injected \| deduped \| budget-clipped \| breaker-suppressed \| failed). | — |
| FR-011 | A per-session circuit breaker MUST trip automatically on: repeat-injection runaway (same trigger > N fires in a short window → trips ONLY that trigger), session token runaway (total injected > cap → trips all hook triggers), or state unavailability (→ trips all hook triggers). Trips emit exactly ONE visible WARN naming reason + re-enable paths, persist `{tripped, reason, at}`, and last for the current session only; `--reset-breaker` clears trip flags. The slash command and channel-1 emission are constitutionally exempt from the breaker. | — |
| FR-012 | All warnings MUST carry one of the enumerated reason codes: `EVENT_PARSE, CATALOG_SCHEMA, SOURCE_MISSING, SOURCE_CONFINED, STATE_UNAVAILABLE, BUDGET_EXCEEDED, BREAKER_TRIPPED, PROVIDER_FAILED`. | — |
| FR-013 | Hook bindings MUST be declared per host package: Claude binds B1+B2+B3 (documented surface); Antigravity, Cursor, and Codex bind the subset their VERIFIED surfaces express — a research-matrix artifact recording each host's hook events, stdin shape, injection mechanism, settings-file analog, and trust-prompt behavior is REQUIRED before that host's binding is implemented. Copilot binds none (channels 1+2 + advisory) until a surface exists — documented host variance. | — |
| FR-014 | Hook registration MUST deploy merge-aware to per-user project-local settings (`.claude/settings.local.json` analog per host): add-if-absent, update only entries recognized as Specrew's by command path, user entries byte-untouched, idempotent re-deploys; opt-out (`--no-refocus-hooks`) is RECORDED and respected by subsequent plain updates; `specrew update` NEVER silently flips a human disable decision in either direction and prints a re-enable hint only when the update changed refocus components. | — |
| FR-015 | The `/specrew-refocus` skill MUST deploy to all host skill catalogs (`.claude/skills/`, `.github/skills/`, `.agents/skills/`; Cursor as an always-attached rule variant) following the established deploy-loop pattern. | — |
| FR-016 | Coordinator governance MUST gain the advisory fallback (suggest refocus at risk moments on hosts without hook bindings) and the boundary-packet context-hygiene line (suggest `/compact` with engine-generated preserve-instructions at heavy-context boundary stops). | — |
| FR-017 | `--compact-instructions` MUST generate a paste-ready `/compact <preserve-list>` from live lifecycle state (feature, boundary, active role, pending verdict, binding constraints, artifact root). | — |
| FR-018 | The deploy loop MUST treat engine/dispatcher/digests as managed mirrors (refresh), the catalog as managed-with-overlay (canonical keys refresh; user keys — `enabled:` flags, added providers — preserved), and every new module-shipped file MUST be declared in the module FileList (manifest completeness gate). | — |
| FR-019 | A test-lane digest drift check MUST warn when a digest's declared canonical source changed after the digest's `reviewed_at`. | — |
| FR-020 | Test suites MUST cover: engine golden payloads per scope + budget caps + confinement refusals; dispatcher simulated-event fixtures per host shape (ordering, dedupe both channel orders, budget arbitration, fail-open, sanitization); breaker trip fixtures per condition; kill-switch matrix incl. update-preserves-disables; deploy idempotence + user-entry preservation; denial paths (malformed event JSON, hostile session id, escaping catalog paths, out-of-tree provider commands). | — |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T013 | Research matrix: Antigravity/Cursor/Codex/Copilot hook surfaces + Claude trust-prompt (C6) + per-event latency measurement | FR-013 | US3 | 3.0 | Implementer | specs/171-specrew-refocus/research-matrix.md | planned | claude | | |
| T014 | Verified host bindings per matrix + simulated-event fixtures; documented-variance entries for failures | FR-013, FR-014 | US3 | 3.0 | Implementer | hosts/**, tests/integration/refocus-dispatcher.tests.ps1 | planned | claude | | |
| T015 | Docs (user-guide, troubleshooting failure trace, README touch) + SC-008 beta validation script/evidence prep | FR-007, FR-016 | US4 | 1.5 | Implementer | docs/**, README.md | planned | claude | | |
| T016 | B4 compaction-steering research record (research-gated OUT; findings only) | FR-016 | US5 | 0.5 | Implementer | specs/171-specrew-refocus/research-matrix.md | planned | claude | | |
| T017 | Defer-approved carries: init/update wiring for deploy-refocus-hooks + catalog managed-with-overlay merge on update + wiring tests | FR-014, FR-018 | US4 | 1.5 | Implementer | scripts/specrew-init.ps1, scripts/specrew-update.ps1, extensions/specrew-speckit/scripts/deploy-speckit-extension.ps1, tests/integration/refocus-deploy.tests.ps1 | planned | claude | | |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points (capacity 20 x threshold 1.0). |
| Defer Strategy | manual | How planning should choose deferrals when the iteration is over capacity. |
| Calibration Enabled | true | When true, retrospectives should suggest future capacity adjustments. |

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator
- Technology and scope signals: Mixed frontend and backend/service signals are present in the scoped requirements.
- Task dependency graph: detailed dependencies are still pending task decomposition in this stub; revisit once the task table is populated.
- Workstream separability: Current scope does not yet prove enough safe parallelism for same-specialty expansion; default to a smaller serial team until tasks are clearer.
- Shared-surface conflict risk: no elevated shared-surface warning inferred yet.
- Prior reviewer ownership/hotspot evidence: Latest reviewer hotspots: .specify/extensions/specrew-speckit/scripts/refocus.ps1 (494 changed lines); .specify/extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1 (538 changed lines); extensions/specrew-speckit/scripts/refocus.ps1 (494 changed lines); extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1 (538 changed lines); scripts/internal/refocus.ps1 (494 changed lines); scripts/internal/specrew-hook-dispatcher.ps1 (538 changed lines); tests/integration/refocus-dispatcher.tests.ps1 (338 changed lines)
- Recommendation: do not propose Junior/Senior same-specialty expansion until the task table and ownership boundaries make safe parallelism explicit. If a same-specialty pair is approved later, record `Owner File Globs` for the parallel tasks or keep the work serial.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 0 | Completed in this ceremony (task table above; capacity check 9.5/20) |
| Discovery/Spikes | 3.0 | T013 research matrix IS the risk-reduction work; it gates T014 per host |
| Implementation | 6.5 | T014 + T015 + T016 + T017 per the task table |
| Review | 0 | Review effort tracked at the boundary, not as task SP |
| Rework | 0 | 10.5 SP headroom under the cap is the buffer |

## Traceability Summary

- Requirement scope for this stub: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012, FR-013, FR-014, FR-015, FR-016, FR-017, FR-018, FR-019, FR-020
- User stories represented in current scope: US3 (hook triggers — research-verified bindings), US4 (operator safety — wiring + docs), US5 (compaction — B4 findings record)
- Capacity check: 9.5/20 story_points — research-first sequencing binding (T013 gates T014 per host).
- Overcommit guardrail: compare planned task effort against the configured threshold and record any required deferrals from the lowest-priority requirement slices before leaving planning.

## Notes

- This stub captures the planned scope pending detailed planning in the Specrew Planning ceremony.
- Add task rows only for work that is traceable to the scoped requirements above.
- Keep Status: planning until the plan is fully decomposed and approved.
- If task effort exceeds the configured threshold, make the deferral decision explicit in this plan before execution starts and name the lowest-priority requirement slices proposed for deferral.
