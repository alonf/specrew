# Feature Specification: Specrew Refocus — Slash Command + Event-Driven Auto-Refocus

**Feature Branch**: `171-specrew-refocus`
**Created**: 2026-06-06
**Status**: Draft
**Input**: User description: "Implement Proposal 146: /specrew.refocus slash command (Pillar A — reactive scoped methodology-corpus re-load with 5 invocation modes) plus event-driven automatic refocus via host hooks (Pillar B — post-compaction, session launch/resume, boundary-transition triggers; Claude-first with per-host degradation)" — amended during the intake workshop (maintainer-directed) to: host-neutral trigger contract with hook bindings for ALL hook-capable hosts in this feature, two host-neutral delivery channels, a general + per-stage digest payload family, an automatic circuit breaker, and managed compaction points.

**Workshop provenance**: all 7 selected design lenses human-confirmed — see `lens-applicability.json` + `workshop/*.md`.

## Clarifications

### Session 2026-06-06

- **Clarify skipped with recorded rationale (human-approved at the specify verdict, commit `570e38d4`)**: the 7-lens intake workshop was the clarification — every materially open design question was surfaced and resolved interactively with the human (engine placement, trigger contract + host bindings, scope-mapping form, payload structure, binding constraints, scope line, dispatcher/registry, state placement, NFR bars, contracts + hook-config placement, trust boundaries, kill-switch/breaker semantics + reset matrix, journal + reason codes). The spec carries zero `[NEEDS CLARIFICATION]` markers; the single conditional (TG-004 latency fallback) is an explicit human-return path, not an ambiguity.

### User Story 1 - Manual refocus recovery (Priority: P1)

A developer (or the Crew itself, advised by the coordinator) notices methodology drift — reviews going shallow, boundary discipline slipping, role rules forgotten — and invokes `/specrew-refocus` (optionally scoped: `--boundary review-signoff`, `--role reviewer`, `--shape-catalog`, `--everything`). The current stage's discipline digest plus the always-true core is re-loaded into context immediately, with a banner naming the scope and sourced files.

**Why this priority**: the manual surface is the MVP and the recovery path of last resort — every other story degrades to this one; it must work on all 5 hosts with no hook support at all.

**Independent Test**: on any host, run the slash command with each scope; verify payload content, banner format, and token budget without any hook machinery deployed.

**Acceptance Scenarios**:

1. **Given** a Specrew project mid-feature at any boundary, **When** the human invokes `/specrew-refocus` with no args, **Then** the payload composes `general` + the current-stage digest, opens with the `[specrew-refocus]` banner naming trigger=manual, scope, sources, and token estimate, and stays within the catalog budget.
2. **Given** a missing canonical source file, **When** the command runs, **Then** a partial payload is emitted with a `SOURCE_MISSING` WARN naming the file and suggesting `specrew update` (fail-open).
3. **Given** the circuit breaker has tripped this session, **When** the human invokes the slash command, **Then** the payload is emitted anyway — human invocations are never deduped or breaker-suppressed.

---

### User Story 2 - Boundary-cross refocus on every host (Priority: P2)

The Crew finishes a phase and advances the lifecycle boundary (the boundary-sync wrapper runs). The wrapper's own stdout now carries the next stage's discipline digest — so on EVERY host, hook-capable or not, the next phase's rules are fresh in context exactly when that phase begins, mechanically, with no one needing to remember.

**Why this priority**: this is the host-neutral half of the feature's thesis (drift is born at gate crossings) and it works on all 5 hosts including Copilot — the widest-coverage automatic trigger.

**Independent Test**: on a scratch project, advance a boundary via the wrapper; assert stdout contains the banner + `general` + next-stage digest and that the injection is fingerprinted in runtime state.

**Acceptance Scenarios**:

1. **Given** a boundary advance via the deployed wrapper, **When** sync succeeds, **Then** the wrapper appends the `--boundary <next>` payload to its stdout and fingerprints the injection.
2. **Given** runtime state is unavailable, **When** the wrapper emits, **Then** it emits WITHOUT dedupe (intrinsically bounded — once per sync call) rather than going quiet.

---

### User Story 3 - Hook-bound automatic triggers on hook-capable hosts (Priority: P3)

On Claude (and each researched hook-capable host: Antigravity, Cursor, Codex-if-expressible), host events fire the Specrew hook dispatcher: post-compaction (B1) re-injects the active role + current stage after context was destroyed; session start/resume (B2) re-grounds position on launches that bypassed `specrew start`; boundary-cross (B3) enforces the US2 injection even when the stdout path was bypassed — detected by watching the boundary cursor state, never by recognizing a command.

**Why this priority**: hooks are the only non-discretionary layer — they fire outside the model's context and cannot drift; but they build on the engine and channels from US1/US2.

**Independent Test**: feed the dispatcher simulated host-event JSON per event/source; assert provider routing, dedupe (stdout-then-hook and hook-only orders), budget arbitration, and fail-open on provider crash.

**Acceptance Scenarios**:

1. **Given** a `SessionStart` event with `source: compact`, **When** the dispatcher runs, **Then** the B1 payload (general + current stage + active role) is injected once, journaled, and the banner names trigger=compact.
2. **Given** a boundary crossed via the wrapper (already fingerprinted), **When** the next hook check runs, **Then** the dispatcher stays silent (outcome=deduped journaled).
3. **Given** a boundary advanced WITHOUT the wrapper path, **When** the next hook check runs, **Then** the state-diff detects the un-fingerprinted crossing and injects (outcome=injected).
4. **Given** a provider crash or timeout, **When** the dispatcher runs, **Then** that provider is skipped with `PROVIDER_FAILED` WARN and the session is unaffected.

---

### User Story 4 - Operator safety: breaker, kill switches, diagnosis (Priority: P4)

A trigger misbehaves (runaway injection, broken state, host event change). The per-session circuit breaker trips automatically — malfunction-focused (per-trigger for runaway; global for token-cap/state-loss) — loudly, once, naming the reason and the manual switches. The operator can disable at three levels (env var / catalog flag / de-registration), reset deliberately, and diagnose end-to-end with `--status` + the injection journal, where every failure-trace branch ends in one named action.

**Why this priority**: an automation feature that cannot be disarmed or diagnosed by users who never read the docs is not shippable; but it protects the machinery built in US1-US3.

**Independent Test**: trip fixtures (repeat-injection, token cap, corrupt state) assert trip scope, single WARN, journal records, and that slash + channel 1 remain constitutionally unaffected; kill-switch matrix verified level by level.

**Acceptance Scenarios**:

1. **Given** the same trigger firing 3 times within 10 events, **When** the breaker evaluates, **Then** ONLY that trigger trips for the rest of the session, one WARN names reason + re-enable paths, and other triggers keep working.
2. **Given** `SPECREW_REFOCUS_DISABLE=1`, **When** any hook fires, **Then** the dispatcher exits silently on its first line, before any parsing.
3. **Given** a user-disabled trigger in the catalog, **When** `specrew update` runs, **Then** the disable is preserved and a re-enable hint is printed only if the update changed refocus components.
4. **Given** hooks de-registered via the opt-out, **When** a plain `specrew update` runs, **Then** the hooks are NOT silently re-registered.

---

### User Story 5 - Managed compaction points (Priority: P5)

At a heavy-context boundary stop (where the human is already at the keyboard), the re-entry packet includes a context-hygiene line with a paste-ready `/compact` command whose preserve-instructions are generated by the engine from live lifecycle state. The human compacts at the clean watershed instead of being ambushed mid-task; B1 then auto-restores the digest after the compaction.

**Why this priority**: turns compaction from a drift threat into a managed lifecycle event, but rides entirely on machinery from US1-US3 (+1-2 SP).

**Independent Test**: invoke `--compact-instructions` at a known lifecycle state; assert the preserve-list names the feature, boundary, active role, pending verdict, and binding constraints.

**Acceptance Scenarios**:

1. **Given** an active feature at a boundary stop, **When** the engine runs `--compact-instructions`, **Then** it emits a paste-ready `/compact <preserve-list>` line derived from `start-context.json` truth.

---

### Edge Cases

- **Unknown/custom boundary name** (downstream project with custom policy classes): engine falls back to `general` + a pointer set with `SOURCE_MISSING` WARN — never crashes, never guesses a wrong digest.
- **Compaction during a boundary crossing** (B1 and B3 both pending): dispatcher runs providers under one budget arbitration; dedupe fingerprints prevent double-delivery of the same stage digest; journal shows both outcomes.
- **Host event schema change** (host update breaks our fixture assumptions): `EVENT_PARSE` WARN once, automation quiet, session unaffected; research-matrix doc pointer in the WARN.
- **Concurrent sessions on one project**: per-session state files keyed by sanitized host session id — no cross-suppression, no write races.
- **Project not Specrew-initialized** (stray hook firing in a non-Specrew directory): dispatcher self-gates on `.specrew/` presence and exits silently.
- **Hook fires while catalog is mid-update** (deploy in progress): schema/parse failure → fail-open WARN once; next event re-reads.

## Requirements *(mandatory)*

### Functional Requirements

**Engine + content (owner: Implementer; iteration 001):**

- **FR-001**: A host-neutral refocus engine MUST resolve scope flags (`no-args | --boundary <name> | --role <name> | --shape-catalog | --everything | --trigger <b1|b2|b3> | --compact-instructions | --status | --reset-breaker`) to a markdown payload whose first line is the banner `[specrew-refocus] trigger=<t> scope=<s> sources=<n> tokens~<est>`; warnings go to stderr as `[specrew-refocus] WARN <CODE> <msg>`. The engine ships as a canonical internal script mirrored to the deployed extension scripts directory; hooks and the wrapper invoke the project-local copy directly.
- **FR-002**: A purpose-authored digest family MUST exist: `refocus/general.md` (always-true core) plus one digest per lifecycle stage (specify, clarify, plan, tasks, before-implement, implement, review-signoff, retro, iteration-closeout, feature-closeout); each digest declares frontmatter `{scope, sources[], reviewed_at}` and ends with `file:///`-style pointers to its canonical sources. Every injection composes `general` + the stage digest.
- **FR-003**: Scope→digest, trigger→scope, per-trigger token budgets, and the provider registry MUST live in a data-driven catalog (`refocus-scopes.json`) carrying a required `schema_version`; evolution is additive-only; version mismatch fails open with `CATALOG_SCHEMA` WARN.
- **FR-004**: The engine MUST refuse non-repo-relative content sources (absolute paths, `..` traversal) with `SOURCE_CONFINED` WARN; provider registry commands MUST resolve under the project's deployed tree (validated at deploy time).
- **FR-005**: The engine MUST enforce the catalog's per-trigger budget caps — clipping with `BUDGET_EXCEEDED` WARN and journaling outcome=budget-clipped — and report the token estimate in the banner. The engine never dedupes (purity); dedupe lives in the trigger layer.

**Host-neutral channels (owner: Implementer; iteration 001):**

- **FR-006**: The deployed boundary-sync **wrapper** MUST append the engine's `--boundary <next>` payload to its stdout after a successful boundary advance (all hosts) and fingerprint the injection in runtime state; when state is unavailable it emits without dedupe (intrinsically bounded) rather than going quiet.
- **FR-007**: Host instruction files (primer floor) MUST point at `/specrew-refocus` as the recovery surface — minimal touch; full primer content remains Proposal 133's scope.

**Hook layer (owner: Implementer; iterations 001-002):**

- **FR-008**: A single `SpecrewHookDispatcher` MUST be the ONLY Specrew-registered handler per bound host event: it parses host event JSON strictly (never evaluating content), sanitizes `session_id` to `[a-zA-Z0-9-]` before any filename use, runs registry providers sequentially by `order` under total budget arbitration with per-provider timeout (crash/timeout → skip + `PROVIDER_FAILED` WARN), applies one dedupe layer, and self-gates on `.specrew/` presence. Its first executable line checks `SPECREW_REFOCUS_DISABLE` and exits silently when set. **Forward-compat (maintainer-directed, 2026-06-07, F-165 coordination)**: the provider contract carries `kind: inject | gate` (default `inject`); `gate` providers run on `PreToolUse`, receive `tool_input`, and return an allow/deny `permissionDecision` instead of a markdown fragment, failing OPEN to allow + WARN (P1 applied to gating). This feature ships NO gate provider and does NOT register `PreToolUse` — the dispatcher's gate code path is fixture-tested and dormant; the registration flips on via the same merge-aware deploy when the first gate row (e.g., F-165's file-link gate) lands in the catalog. Ownership rule: any future Specrew hook mechanism routes through this dispatcher — never a second registration on the settings surface. **[Post-merge reconciliation, 2026-06-07 — drift D-003]**: F-165 shipped (0.32.0 stable, PR #2082) and **superseded its own render-gate** (commit `49c3ba13`), delivering the `specrew-gate-stop` skill (`disallowed-tools: AskUserQuestion`) instead of a `PreToolUse` gate provider. The named consumer of this dormant seat therefore no longer exists. The forward-compat `kind: inject|gate` contract REMAINS as generic, dormant extensibility (no behavior change, no PreToolUse registration), but its justification is now general, not F-165-specific. Keep-vs-remove of the dormant seat is a maintainer ruling surfaced at feature-closeout.
- **FR-009**: `RefocusProvider` (registry row #1) MUST route events to triggers: `SessionStart source:compact` → B1 (general + current stage + active role); `SessionStart source:startup|resume|clear` → B2 (pointer set + lifecycle position); B3 boundary-cross detection MUST diff the boundary cursor in `start-context.json` against the runtime-local last-seen value (watch the state, never the actor) behind a LastWriteTime cheap-guard.
- **FR-010**: Per-session runtime state files (`.specrew/runtime/refocus-state-<sanitized-session-id>.json`, gitignored, opportunistically pruned ~7 days) MUST hold the last-seen boundary, injection fingerprints, breaker state, and a bounded injection journal (~20 entries: `{at, trigger, scope, channel, tokens, outcome}` with outcome ∈ injected | deduped | budget-clipped | breaker-suppressed | failed).
- **FR-011**: A per-session circuit breaker MUST trip automatically on: repeat-injection runaway (same trigger > N fires in a short window → trips ONLY that trigger), session token runaway (total injected > cap → trips all hook triggers), or state unavailability (→ trips all hook triggers). Trips emit exactly ONE visible WARN naming reason + re-enable paths, persist `{tripped, reason, at}`, and last for the current session only; `--reset-breaker` clears trip flags. The slash command and channel-1 emission are constitutionally exempt from the breaker.
- **FR-012**: All warnings MUST carry one of the enumerated reason codes: `EVENT_PARSE, CATALOG_SCHEMA, SOURCE_MISSING, SOURCE_CONFINED, STATE_UNAVAILABLE, BUDGET_EXCEEDED, BREAKER_TRIPPED, PROVIDER_FAILED`.
- **FR-013**: Hook bindings MUST be declared per host package: Claude binds B1+B2+B3 (documented surface); Antigravity, Cursor, and Codex bind the subset their VERIFIED surfaces express — a research-matrix artifact recording each host's hook events, stdin shape, injection mechanism, settings-file analog, and trust-prompt behavior is REQUIRED before that host's binding is implemented. Copilot binds the subset its VERIFIED surface expresses (hooks GA 2026-02-25 per the T013 research matrix — the earlier no-surface finding is obsolete); any host genuinely without a surface ships channels 1+2 + advisory as documented variance.
- **FR-014**: Hook registration MUST deploy merge-aware to per-user project-local settings (`.claude/settings.local.json` analog per host): add-if-absent, update only entries recognized as Specrew's by command path, user entries byte-untouched, idempotent re-deploys; opt-out (`--no-refocus-hooks`) is RECORDED and respected by subsequent plain updates; `specrew update` NEVER silently flips a human disable decision in either direction and prints a re-enable hint only when the update changed refocus components.

**Manual surface + guidance (owner: Implementer; iteration 001):**

- **FR-015**: The `/specrew-refocus` skill MUST deploy to all host skill catalogs (`.claude/skills/`, `.github/skills/`, `.agents/skills/`; Cursor as an always-attached rule variant) following the established deploy-loop pattern.
- **FR-016**: Coordinator governance MUST gain the advisory fallback (suggest refocus at risk moments on hosts without hook bindings) and the boundary-packet context-hygiene line (suggest `/compact` with engine-generated preserve-instructions at heavy-context boundary stops).
- **FR-017**: `--compact-instructions` MUST generate a paste-ready `/compact <preserve-list>` from live lifecycle state (feature, boundary, active role, pending verdict, binding constraints, artifact root).

**Deployment + verification (owner: Implementer + Reviewer; iterations 001-002):**

- **FR-018**: The deploy loop MUST treat engine/dispatcher/digests as managed mirrors (refresh), the catalog as managed-with-overlay (canonical keys refresh; user keys — `enabled:` flags, added providers — preserved), and every new module-shipped file MUST be declared in the module FileList (manifest completeness gate).
- **FR-019**: A test-lane digest drift check MUST warn when a digest's declared canonical source changed after the digest's `reviewed_at`.
- **FR-020**: Test suites MUST cover: engine golden payloads per scope + budget caps + confinement refusals; dispatcher simulated-event fixtures per host shape (ordering, dedupe both channel orders, budget arbitration, fail-open, sanitization); breaker trip fixtures per condition; kill-switch matrix incl. update-preserves-disables; deploy idempotence + user-entry preservation; denial paths (malformed event JSON, hostile session id, escaping catalog paths, out-of-tree provider commands).

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story maps to FRs — US1: FR-001..005, FR-015; US2: FR-006, FR-007; US3: FR-008..013; US4: FR-010..012, FR-014, FR-020; US5: FR-016, FR-017.
- **TG-002**: Owner roles are annotated per FR group above (Implementer builds; Reviewer owns FR-019/FR-020 evidence verification).
- **TG-003**: Delivery windows annotated per FR group: iteration 001 = engine + content + channels + skill + Claude bindings + core tests; iteration 002 = breaker hardening + remaining host bindings (research-gated) + compaction points + docs. Re-planned at `/speckit.plan`.
- **TG-004**: Known conflict path: if P4's latency bar proves unreachable on a host (pwsh spawn cost), that host's B3 falls back to channel-1-only — the decision RETURNS TO THE HUMAN with measurement data; recorded here so the plan inherits it explicitly.

### Key Entities

- **Refocus digest**: purpose-authored injection unit (`general` or per-stage); frontmatter `{scope, sources[], reviewed_at}`; body ends in canonical-source pointers.
- **Scope catalog**: versioned data file mapping scopes→digests, triggers→scopes, budgets; hosts the provider registry.
- **Provider registry row**: `{id, kind: inject|gate, events[], order, budget_share, command}` — the extension seat for future mechanisms (130-P4 handover as `inject`; the `gate` kind reserved as generic forward-compat — its original example consumer, F-165's render-gate, was superseded by the gate-stop skill; see drift D-003) without host-config changes.
- **Runtime session state**: per-session gitignored file — last-seen boundary, fingerprints, breaker state, injection journal.
- **Journal entry**: `{at, trigger, scope, channel, tokens, outcome}` — the post-hoc evidence unit that survives compaction.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001 (fail-open)**: across the full fault-injection suite (missing catalog, corrupt digest, locked/corrupt state, dead provider, malformed event JSON), ZERO session blocks; every fault yields exactly one visible WARN with the correct reason code.
- **SC-002 (exactly-once)**: in a simulated full-lifecycle run, injection count equals boundary-crossing count (+1 per compaction event); dedupe fixtures pass in both orders (stdout-then-hook, hook-only).
- **SC-003 (token economy)**: size tests enforce digest caps (general ≤~600 tokens; stage digests ≤~1,500; composed payloads ≤~2,500; B2 set ≤~1,200); clipped payloads journal outcome=budget-clipped.
- **SC-004 (latency)**: measured B2 dispatcher path ≤1s; measured B3 check path ≤150ms p95; if a host misses the bar, the channel-1 fallback decision is presented to the human WITH the measurements (TG-004), never silently taken.
- **SC-005 (breaker)**: trip fixtures per condition produce the agreed trip scope, exactly one WARN naming reason + re-enable paths, correct journal records; slash command and channel-1 emission remain live during every trip.
- **SC-006 (kill-switch matrix)**: env var silences the dispatcher first-line; catalog disables persist across `specrew update` (with hint only on component change); recorded opt-out prevents silent hook re-registration.
- **SC-007 (security denial paths)**: hostile session id, escaping catalog source, out-of-tree provider command, and malformed event JSON are each refused/sanitized with the correct WARN code and zero filesystem writes outside `.specrew/runtime/`.
- **SC-008 (runtime beta validation — release gate)**: on at least TWO hook-bound hosts (Claude + one researched host), a REAL compaction produces the B1 banner + journal entry, and a REAL boundary cross produces exactly one injection across channels; kill-switch walk verified live. File-presence evidence does not satisfy this criterion.
- **SC-009 (deploy integrity)**: re-deploy is byte-idempotent; user-authored hook entries and catalog user keys survive deploys byte-untouched; FileList completeness gate passes with the ~15 new files.
- **SC-010 (diagnosability)**: in dogfooding, the documented failure trace resolves each seeded failure to its one named action using only `--status` + journal + WARN codes — no source reading.

## Assumptions

- Claude Code's documented hook surface (SessionStart sources, PostToolUse, settings files, additionalContext injection) remains as researched; other hosts' surfaces are NOT assumed — each is verified by the research-matrix artifact before its binding is built (FR-013).
- Lifecycle stage names derive from the boundary policy classes shipped in this repo; custom downstream boundaries degrade per the edge case (general + pointer fallback).
- Proposal 140's per-boundary checklist matrix is not yet shipped; digests point at today's canonical sources and integrate 140 as a declared source when it lands.
- Crews 169/170 land before this feature merges; no file-surface collision exists (verified at intake); shared-churn files (INDEX/CHANGELOG/ledgers) merge serially.
- The amended Proposal 146 (commit `2199a8dd`) is the authoritative source-spec; this spec supersedes its sizing with the workshop outcome (~15-25 SP, 2 iterations).

## Governance Alignment *(mandatory)*

- **Spec Steward**: Spec Steward role (claude-routed) — owns spec integrity + drift reconciliation.
- **Iteration Facilitator**: Planner role — cadence, capacity, blockers.
- **Capacity Model**: story points; 20 SP iteration cap; ~15-25 SP total → 2 iterations (TG-003 split).
- **Drift Signals**: drift-log.md per iteration; digest drift check (FR-019) for content drift; research-matrix vs host-surface drift named in EVENT_PARSE WARN flow.
- **Human Oversight Points**: all policy-class boundaries (specify → … → feature-closeout) per `boundary_enforcement`; design-analysis stop before plan (substantive feature, co-design record required); TG-004 latency fallback decision; SC-008 beta validation PASS before stable promotion.
