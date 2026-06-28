# Tasks: Continuous Co-Review

<!-- ============================================================ -->
<!-- RECONCILED 2026-06-28 against git ground-truth — READ FIRST  -->
<!-- ============================================================ -->

## 🔄 Reconciliation banner (2026-06-28) — current truth

This ledger was reconciled against git ground-truth (commit subjects + file mtimes) on 2026-06-28. The original **Phase 1–8 task body below is the original-design ledger** for the *diff-cramming* reviewer architecture, which was **superseded by the iteration-008 worktree cutover** (`c66e5df6` deleted the diff-cramming engine; the reviewer now runs in an ephemeral read-only `git archive` worktree). The Phase 1–8 body is retained as historical record; the active architecture's truth is the table below + the per-iteration artifacts.

### True iteration status (from git)

| Iter | Delivered | Status | Closeout |
|---|---|---|---|
| 001 | Co-review spine `T001–T050` | **complete** | review-accepted; not formally closed |
| 002 | Reviewer-definition repair `T051–T057` | **abandoned** (maintainer-ratified) | — |
| 003 | Always-on gate + content-addressed digest `T058–T069` | **complete** | formally closed (`2ac079b2`) |
| 004 | #2885 latency fix + opt-in gate `T070–T075` | **complete** | formally closed (`cdc9d7f8`) |
| 005 | Async Stop-hook navigator `T076–T081` | **complete** | formally closed (`14f03b4c`) |
| 006 | Real reviewer wired in `T082–T086` | **complete** | not formally closed (superseded by 007) |
| 007 | Real-reviewer hardening + deploy-completeness | **complete** | closed via chore (`32604b86`) |
| 008 | **Worktree-reviewer cutover + dogfood hard-gate** | **in-progress (active)** | open |

### Task-ID reconciliation

- The real ledger spans **T001–T086**. This feature file covers `T001–T069` + an iter-008 addendum; **`T070–T082`** (iter-004/005) and **`T086`** (iter-006) were tracked only in the per-iteration `iterations/00N/plan.md` files.
- **Collision:** the iter-008 "Dogfood Repair Addendum" reuses **`T083/T084/T085`**, which iter-006 already used (`18557e80`, `6a24838b` — commit-cited = authoritative). Read the addendum as **`T087/T088/T089`**; a clean renumber is an iteration-009 cleanup task.
- iter-001's `T001–T050` are shown unchecked in the Phase 1–6 body below; they were **completed in iteration 001 then superseded** by the iter-008 cutover (the code they describe was deleted). Treat the status table above as authoritative, not the Phase 1–6 checkboxes.

---

## Iteration 009 — Reviewer robustness (graceful degradation) — TASKS (approved for tasks, 2026-06-28)

**Why:** live downstream dogfood (EnglishIntake) proved the reviewer is field-unstable on real change-sets — a large diff times out → "no parseable findings" → the review-signoff gate deadlocks; `--host` is silently overridden; the configured timeout is not enforced. Maintainer ruling 2026-06-28: **"make it a robust feature — any review is better than nothing; the gate must never hard-deadlock."** Design-analysis → plan → tasks approved (2026-06-28). Requirements **R1–R6 = FR-033…FR-038 + SC-024**. Sequenced in 4 phases by leverage (R5 first).

### Phase 1 — relieve the deadlock

- [ ] T091 [owner: Implementer] [sp: 3.0] [R5] **Hard timeout = a real wall** — independent watchdog + process-group/job-object **tree-kill** + stdio-redirect + 5s SIGTERM→SIGKILL graceful flush in `scripts/internal/continuous-co-review/worktree-reviewer.ps1`; WSL-validated (hard gate) (Trace: FR-037, SC-024, NFR-001; owns: `worktree-reviewer.ps1`)
- [ ] T090 [owner: Implementer] [sp: 2.5] [R1] **Harvest partial findings** — reviewer instruction contract emits each finding incrementally (one JSON object per line to a findings file); harvest the clean prefix on kill; prose-salvage floor (Trace: FR-033, SC-024, NFR-001; owns: reviewer instruction contract + `worktree-review-orchestrator.ps1` harvest path)

### Phase 2 — the human remediation surface

- [ ] T096 [owner: Implementer] [sp: 3.0] [R6] **Remediation menu** — on a review problem, surface ONE menu at the next Stop (more time / different host / narrow scope: code · process · file · function / accept partial / override block), carried via `co-review-round-state.json` to the re-run; honour the human-directed scope (extends user-code/subtree scoping) (Trace: FR-038, FR-024, FR-025; owns: `continuous-co-review-navigator.ps1` + `specrew-co-review-navigator-provider.ps1` + round-state)
- [ ] T093 [owner: Architect] [sp: 1.5] [R3] **Host-independence fallback** — pre-flight independence check; fire labelled same-host fallback immediately (never block); the answer upgrades the next run; honour-or-surface `--host` (Trace: FR-035, FR-016, SEC-004; owns: `reviewer-selection-policy.ps1` + `reviewer-authorization-gate.ps1`)
- [ ] T092 [owner: Implementer] [sp: 1.5] [R2] **Time-extension gate** — post-hoc "more time" menu option + pre-flight generous-budget heuristic for large diffs (Trace: FR-034, NFR-002; owns: orchestrator budget seam + navigator menu)

### Phase 3 — the honest gate

- [ ] T094 [owner: Reviewer] [sp: 2.5] [R4+D5] **Tiered degraded-evidence gate** — 3-dimension label (completeness/independence/budget); `full`+`independent` auto-allows; `partial` OR `same-host` needs a recorded first-class ack verdict; never deadlock; degraded-review blocking-finding override with recorded reason (Trace: FR-036, SC-019, SC-020, SC-024; owns: `review-signoff-evidence-gate.ps1` + `inline-review-gate-evaluator.ps1`)

### Phase 4 — cleanup

- [ ] T095 [owner: Spec Steward] [sp: 0.5] [governance — non-requirement] **Resolve the T083–T085 collision** — renumber the iter-008 Dogfood Repair Addendum to T087–T089 (iter-006's commit-cited T083–T086 stay canonical) (Trace: governance hygiene — not requirement-driven; explicitly exempt from FR/SC traceability)

**Capacity**: 14.5 / 20 SP — within cap. ~5.5 SP headroom held (iter-009 stays tight on robustness per the plan-boundary default; deferred governance items not pulled in).

### Bidirectional traceability (tasks ↔ requirements)

| Requirement | Covering task(s) |
|---|---|
| FR-033 (R1 partial harvest) | T090 |
| FR-034 (R2 time extension) | T092 |
| FR-035 (R3 host fallback) | T093 |
| FR-036 (R4 degraded gate) | T094 |
| FR-037 (R5 hard timeout) | T091 |
| FR-038 (R6 remediation menu) | T096 |
| SC-024 (never-deadlock acceptance) | T091, T090, T094 |

Forward: every requirement-driven task (T090–T094, T096) traces to ≥1 FR/SC. Reverse: every iter-009 requirement (FR-033…FR-038, SC-024) has ≥1 covering task. T095 is governance hygiene (non-requirement), explicitly noted, not an orphan. **Bidirectional traceability: PASS.**

### Dependencies & parallel safety

- **T091 ∥ T090** (Phase 1) — different files (`worktree-reviewer.ps1` vs the orchestrator harvest path + reviewer contract) → parallel-safe.
- **T096** depends on T090 (harvested partials feed "accept partial") and T091 (the kill produces the timeout that triggers the menu).
- **T093, T092** supply the menu's host/time options → land before or with T096.
- **T094** depends on T090's labels + T093's same-host label → Phase 3 after Phases 1–2.
- **T095** independent (governance) → any time.

**Design-analysis (2026-06-28):** R1–R6 co-designed and agreed one-by-one with the maintainer; record at file:///C:/Dev/197-continuous-co-review/specs/197-continuous-co-review/iterations/009/design-analysis.md. `co_design: true` set in iterations/009/lens-applicability.json.

---

**Input**: Design documents from `/specs/197-continuous-co-review/`
**Prerequisites**: `spec.md`, `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `implementation-rules.yml`, `iterations/001/design-analysis.md`, and `contracts/`
**Requested by**: Alon Fliess
**Human verdict**: Iteration 001 approved for tasks; review send-back requires Iteration 002 before-implement approval before T051 starts.
**Worktree / branch**: `C:\Dev\197-continuous-co-review` on `197-continuous-co-review`

**Tests**: Required. The approved spec includes acceptance scenarios and SC-001..SC-012; Pester tests and fixtures are intentionally sliced beside the code they prove rather than deferred to the end. Manual real-host validation is a maintainer-performed feature-closeout acceptance step; Iteration 001 ships the runbook, planted fixture, and acceptance hook but not automated live-host CI.

**Organization**: Dependency order is preserved inside story phases: contract + forced-findings schema first, then git-diff change-set + blackboard protocol, then standalone gate validator, then reviewer-domain headless-floor adapters and fresh-context reviewer path.

**Capacity**:

- Iteration 001 spine slice estimate: **19.50 story points** after restoring the full five-adapter host-neutral floor and adding manual-validation enablers.
- Iteration 002 reviewer-definition repair estimate: **8.00 story points**. Capacity status: **8.00/20 SP is within the configured Iteration 002 cap**.
- Iteration 003 always-on Phase A estimate: **24.00 story points** after the gate re-architecture (D-197-I003-004/005). Capacity status: **24.00/25 SP is within the configured Iteration 003 cap** (raised 20->25, maintainer-authorized, to keep the re-architecture in 003 rather than splitting). The live Stop-hook trigger (Phase B) is deferred to Iteration 004.
- Proposal-level planning range: **13-21 story points**.
- Capacity status: **19.50/20 SP is within the configured Iteration 001 cap**. `T035`, `T036`, `T037`, and all five real headless adapters in `T042` are restored to Iteration 001. Any added rung 1 work, hook/PostToolUse trigger, Proposal 139 foundation work, Proposal 196 provenance/audit work, automated live cross-host CI implementation, new dependency, or protected-surface coordination is additional overcommit and must be deferred or re-approved.

**Hard scope guardrails**:

- Do **not** start rung 1, hook/PostToolUse triggers, or Proposal 139 foundation work.
- Do **not** edit `proposals/197-continuous-co-review.md`.
- Do **not** include `.squad/agents/spec-steward/history.md` runtime churn in feature commits.
- Do **not** edit F-184 protected host-runtime, hook, provider, registry, refocus, shared-governance, mirrored `.specify/extensions/specrew-speckit/scripts/` surfaces, or `validate-governance.ps1`.
- Keep Proposal 197 reviewer-provider components in the `scripts/internal/continuous-co-review/` namespace with reviewer-domain names such as `reviewer-host-adapter-*`, `reviewer-model-capability`, and `reviewer-host-catalog`; do not create generic `provider-adapter.ps1`.
- Preserve unnamed CI/CD E2E contract hooks/fixtures only for future Proposal 181 + Proposal 194 canary composition.
- Preserve manual real-host validation as a maintainer acceptance step before feature closeout; do not build scheduled/rotating live-host CI, brokered-key automation, or drift-canary automation in Proposal 197.
- Treat human-confirmed lens-stamp provenance/audit as non-blocking Proposal 196 scope, not Proposal 197 work.
- Iteration 002 preserves completed Iteration 001; do not rewrite accepted T001-T050 behavior except where the reviewer-definition repair explicitly threads through the existing request/prompt/adapter seams.
- Before Iteration 002 implementation, merge or rebase latest remote `main` and resolve conflicts.

## Format: `- [ ] T### [P?] [US#?] [owner: ...] [sp: ...] Description with exact file path(s) (Trace: ...; Rules: specs/197-continuous-co-review/implementation-rules.yml)`

- **[P]**: Can run in parallel after dependencies are satisfied because it touches different files and has no dependency on incomplete tasks.
- **[US#]**: User story label for story-phase tasks only.
- Every task includes at least one FR or SC reference plus `TG-011` and `implementation-rules.yml`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the additive Proposal 197 namespace and test/fixture scaffolding without touching protected F-184 surfaces.

- [ ] T001 [P] [owner: Architect] [sp: 0.25] Create additive directories `scripts/internal/continuous-co-review/`, `tests/continuous-co-review/contracts/`, `tests/continuous-co-review/fixtures/`, `tests/continuous-co-review/unit/`, `tests/continuous-co-review/integration/`, and `tests/continuous-co-review/governance/` (Trace: FR-013, SC-006, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T002 [owner: Implementer] [sp: 0.50] Add `scripts/internal/continuous-co-review/_load.ps1` to dot-source only Proposal 197 reviewer-domain modules and avoid `hosts/**`, `extensions/specrew-speckit/scripts/provider-*.ps1`, and `validate-governance.ps1` (Trace: FR-013, IMPL-004, SC-006, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T003 [P] [owner: Spec Steward] [sp: 0.25] Add `tests/continuous-co-review/README.md` describing local Pester invocation, fixture ownership, protected-surface guard usage, and the unnamed future CI/CD E2E composition target Proposal 181 + Proposal 194 canary (Trace: OPS-006, TG-009, SC-011, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)

**Checkpoint**: Proposal 197 implementation and tests have isolated new paths.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish versioned contract validation, forced findings fixtures, infrastructure failure fixtures, run-record fixtures, and a mechanical protected-surface guard before any story work.

**⚠️ CRITICAL**: No user story implementation should begin until this phase is complete.

- [ ] T004 [P] [owner: Architect] [sp: 0.50] Add producer/consumer JSON fixtures for `ReviewRequest`, `FindingsResult`, `ReviewThread`, `GateVerdict`, `InfrastructureFailure`, `SpawnInvocation`, `ReviewRun`, and `ReviewRunSkipped` under `tests/continuous-co-review/fixtures/contracts/` (Trace: FR-001, FR-002, INT-009, OBS-003, SC-001, SC-005, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T005 [P] [owner: Reviewer] [sp: 0.50] Add Pester contract tests in `tests/continuous-co-review/contracts/reviewer-contracts.Tests.ps1` that validate all schema/fixture pairs, reject unknown major versions, and accept additive optional compatible fields (Trace: FR-001, FR-002, INT-002, INT-003, SC-001, SC-005, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T006 [owner: Architect] [sp: 0.50] Implement `scripts/internal/continuous-co-review/reviewer-contracts.ps1` with schema loading, DTO shape validation, unknown-major-version rejection, and no new dependency usage (Trace: FR-001, FR-002, INT-002, IMPL-005, SC-001, SC-011, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T007 [P] [owner: Reviewer] [sp: 0.25] Add forced-findings Pester coverage in `tests/continuous-co-review/contracts/findings-result.Tests.ps1` for finding id, location, severity, kind, design reference, comment, disposition, and resolution metadata (Trace: FR-002, NFR-003, SC-001, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T008 [owner: Implementer] [sp: 0.25] Add forced-findings helper functions to `scripts/internal/continuous-co-review/reviewer-contracts.ps1` for stable finding fingerprints, valid disposition values, and valid resolution states (Trace: FR-002, FR-005, NFR-003, SC-001, SC-004, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T009 [P] [owner: Reviewer] [sp: 0.25] Add infrastructure-failure fixture tests in `tests/continuous-co-review/contracts/infrastructure-failure.Tests.ps1` for timeout, nonzero exit, empty stdout, invalid JSON, schema mismatch, missing provider, unauthorized provider/model, unavailable requested model, and command invocation failure (Trace: FR-007, INT-005, OBS-005, SC-005, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T010 [owner: Implementer] [sp: 0.25] Implement infrastructure-failure constructors in `scripts/internal/continuous-co-review/reviewer-contracts.ps1` with redacted `safe_details` and no raw stdout/stderr, prompts, transcripts, environment variables, tokens, or ambient machine state (Trace: FR-007, SEC-002, SEC-006, INT-005, OBS-009, SC-005, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T011 [owner: Spec Steward] [sp: 0.50] Add deterministic SC-006 guard test in `tests/continuous-co-review/governance/protected-surface-guard.Tests.ps1` that shells `git --no-pager diff --name-only` and fails if any changed path equals the protected files enumerated in `specs/197-continuous-co-review/spec.md` lines 461-479 or their mirrored `.specify/extensions/specrew-speckit/scripts/` equivalents (Trace: FR-013, NFR-006, TG-005, SC-006, SC-011, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)

**Checkpoint**: Contracts and protected-surface guard are executable. This is the dependency gate for all stories.

---

## Phase 3: User Story 1 - Review each checkpoint against the design contract (Priority: P1) 🎯 MVP

**Goal**: Compute a checkpoint git-diff change-set, package bounded design context and request evidence, invoke a deterministic controlled reviewer path, normalize results, persist minimum thread evidence, and block/pass through a standalone gate.

**Independent Test**: Create a checkpoint baseline fixture, add a design-violating diff fixture, run the fake reviewer path, and verify a valid blocking finding prevents advancement while no-reviewable-diff produces skipped/pass-no-op evidence.

### Tests for User Story 1

- [ ] T012 [P] [US1] [owner: Reviewer] [sp: 0.50] Add `tests/continuous-co-review/unit/checkpoint-diff-provider.Tests.ps1` covering `git diff` changed paths, out-of-band worktree edits, excluded paths, no-reviewable-diff, missing baseline failure, and diff hash stability (Trace: FR-003, OBS-004, SC-007, SC-009, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T013 [P] [US1] [owner: Reviewer] [sp: 0.50] Add `tests/continuous-co-review/unit/design-context-collector.Tests.ps1` proving spec/workshop/design-analysis/quality-rule references are included while secrets, raw prompts, raw transcripts, environment variables, token stores, unrelated temp files, and ambient machine state are excluded (Trace: FR-011, SEC-001, SEC-002, SEC-006, OBS-009, SC-011, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T014 [P] [US1] [owner: Reviewer] [sp: 0.50] Add `tests/continuous-co-review/unit/review-request-builder.Tests.ps1` covering `ReviewRequest` schema version, run id, checkpoint id, baseline ref, `code-change-set` kind, allowed/forbidden paths, provider request, output contract, request hash, and created timestamp (Trace: FR-001, FR-011, INT-001, INT-002, OBS-002, SC-011, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T015 [P] [US1] [owner: Reviewer] [sp: 0.50] Add `tests/continuous-co-review/unit/review-run-workspace-manager.Tests.ps1` covering unique run workspaces, immutable request bundles, no bundle reuse, cleanup-by-default, explicit debug preservation, and cleanup failure not converting a block to pass (Trace: DS-003, NFR-008, OBS-007, OBS-008, SC-009, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T016 [P] [US1] [owner: Reviewer] [sp: 0.50] Add `tests/continuous-co-review/unit/review-result-normalizer.Tests.ps1` covering valid findings JSON, invalid JSON, empty stdout, schema mismatch, timeout, nonzero exit, unknown blocking disposition, and deterministic `InfrastructureFailure` output (Trace: FR-002, FR-007, INT-005, OBS-005, SC-001, SC-005, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T017 [P] [US1] [owner: Reviewer] [sp: 0.50] Add `tests/continuous-co-review/integration/fixture-reviewer-path.Tests.ps1` for the controlled fake adapter full path: request bundle -> fixture findings result -> review thread -> gate verdict, with both valid blocking finding and deterministic infrastructure failure scenarios and no live host dependency (Trace: FR-006, INT-009, OBS-003, SC-001, SC-002, SC-005, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)

### Implementation for User Story 1

- [ ] T018 [US1] [owner: Implementer] [sp: 0.50] Implement `scripts/internal/continuous-co-review/checkpoint-diff-provider.ps1` to resolve a checkpoint baseline, run `git diff`, produce `ChangeSet`, write explicit `ReviewRunSkipped` intent for no reviewable diff, and avoid editor-host events or hooks (Trace: FR-003, FR-008, OBS-004, SC-007, SC-009, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T019 [US1] [owner: Spec Steward] [sp: 0.50] Implement `scripts/internal/continuous-co-review/design-context-collector.ps1` and `scripts/internal/continuous-co-review/review-visibility-policy-builder.ps1` to include `spec.md`, `workshop/*.md`, `iterations/001/design-analysis.md`, `implementation-rules.yml`, and quality/testability rule refs while enforcing redaction boundaries (Trace: FR-011, SEC-001, SEC-002, OBS-009, SC-011, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T020 [US1] [owner: Implementer] [sp: 0.50] Implement `scripts/internal/continuous-co-review/review-request-builder.ps1` to assemble deterministic `ReviewRequest` DTOs with output contract `FindingsResult.v1`, provider/model request fields, request hash, run correlation, and path policies (Trace: FR-001, FR-011, FR-016, INT-001, OBS-002, SC-011, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T021 [US1] [owner: Implementer] [sp: 0.50] Implement `scripts/internal/continuous-co-review/review-run-workspace-manager.ps1` to create per-run temporary workspaces, place immutable bundles, prevent overwrite/reuse, clean after durable persistence, and record cleanup status (Trace: DS-003, NFR-008, OBS-007, OBS-008, SC-009, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T022 [US1] [owner: Implementer] [sp: 0.50] Implement `scripts/internal/continuous-co-review/review-result-normalizer.ps1` to parse stdout JSON into `FindingsResult` or deterministic `InfrastructureFailure` without treating operational failures as no findings (Trace: FR-002, FR-007, INT-005, OBS-005, SC-001, SC-005, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T023 [US1] [owner: Implementer] [sp: 0.50] Implement `scripts/internal/continuous-co-review/reviewer-host-adapter-fixture.ps1` and fixture data under `tests/continuous-co-review/fixtures/fake-adapter/` so the deterministic full path is testable without Claude, Codex, Copilot, Cursor, Antigravity, network, or paid provider access (Trace: INT-009, OBS-003, OPS-006, SC-001, SC-005, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)

**Checkpoint**: User Story 1 MVP has a deterministic local request/result path and no live provider requirement.

---

## Phase 4: User Story 2 - Preserve an auditable editor-reviewer thread (Priority: P2)

**Goal**: Persist review findings, dispositions, resolution state, run index, skipped-run evidence, and deterministic gate verdicts under `.specrew/review/inline/<run-id>/...`.

**Independent Test**: Feed fixture findings into the blackboard writer, record accept/reject/resolve/escalate dispositions, and verify valid thread, verdict, skipped-run, malformed-state, and non-convergence outcomes.

### Tests for User Story 2

- [ ] T024 [P] [US2] [owner: Reviewer] [sp: 0.50] Add `tests/continuous-co-review/unit/review-blackboard-writer.Tests.ps1` for `.specrew/review/inline/<run-id>/...` thread writes, complete finding fields, disposition trail, rationale on rejection, fix evidence refs, and idempotent durable writes by run id (Trace: FR-004, FR-005, DS-002, OBS-002, SC-004, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T025 [P] [US2] [owner: Reviewer] [sp: 0.50] Add `tests/continuous-co-review/unit/inline-review-gate-evaluator.Tests.ps1` for pass, block, unsafe malformed state, invalid schema, unknown blocking disposition, resolved blocking findings, advisory-only findings, and explicit pass/no-op skipped verdict (Trace: FR-006, FR-007, NFR-001, SC-002, SC-003, SC-009, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T026 [P] [US2] [owner: Reviewer] [sp: 0.25] Add `tests/continuous-co-review/unit/non-convergence-escalation.Tests.ps1` proving the initial review plus one fix-verification round cap and human escalation when the same blocking finding remains unresolved (Trace: FR-005, FR-006, NFR-005, SC-008, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)

### Implementation for User Story 2

- [ ] T027 [US2] [owner: Implementer] [sp: 0.50] Implement `scripts/internal/continuous-co-review/review-blackboard-writer.ps1` to persist `ReviewThread`, finding dispositions, rationale, fix evidence refs, escalation refs, and redacted evidence under `.specrew/review/inline/<run-id>/...` while keeping temporary bundles out of commits by default (Trace: FR-004, FR-005, DS-002, DS-005, OBS-001, SC-004, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T028 [US2] [owner: Reviewer] [sp: 0.50] Implement `scripts/internal/continuous-co-review/inline-review-gate-evaluator.ps1` as a standalone deterministic validator that blocks unresolved `blocking` findings, marks malformed/unknown state unsafe, passes resolved/advisory-only state, and emits explicit skipped/pass-no-op verdicts (Trace: FR-006, FR-007, INT-003, NFR-010, SC-002, SC-003, SC-009, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T029 [US2] [owner: Implementer] [sp: 0.50] Implement `scripts/internal/continuous-co-review/review-run-index-writer.ps1` to write `ReviewRun` and `ReviewRunSkipped` audit index records tying checkpoint, baseline, request, invocation, result/failure, thread, verdict, provider/model provenance, cleanup status, and timestamps together (Trace: NFR-002, NFR-011, DS-002, OBS-002, OBS-004, SC-009, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T030 [US2] [owner: Spec Steward] [sp: 0.25] Add `tests/continuous-co-review/fixtures/dispositions/README.md` documenting accept-and-fix, reject-with-rationale, mark-resolved, escalate-to-human, and Proposal 145 final review-signoff backstop semantics (Trace: FR-005, FR-014, SC-004, SC-008, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)

**Checkpoint**: User Story 2 can reconstruct why a checkpoint passed, blocked, failed infrastructurally, escalated, or skipped.

---

## Phase 5: User Story 3 - Run everywhere through a host-neutral headless floor (Priority: P3)

**Goal**: Add reviewer-domain host/model catalog, capability discovery, authorization, selection, static adapter registry, five real headless-floor adapters, and fresh-context execution while proving every adapter returns a valid result or deterministic infrastructure failure.

**Independent Test**: Invoke each supported adapter seam with the same request bundle fixture and verify parseable findings or deterministic `InfrastructureFailure`, no source mutation, no raw transcript persistence, no silent downgrade, and no protected-surface edits.

### Tests for User Story 3

- [ ] T031 [P] [US3] [owner: Reviewer] [sp: 0.50] Add `tests/continuous-co-review/unit/reviewer-host-catalog.Tests.ps1` covering non-secret host/model config, allowed adapters, model IDs as data/config, review-class preference, explicit authorization requirement, and no live web search dependency (Trace: FR-016, INT-006, INT-007, INT-008, OPS-004, SC-010, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T032 [P] [US3] [owner: Reviewer] [sp: 0.25] Add `tests/continuous-co-review/unit/reviewer-host-adapter-registry.Tests.ps1` proving only reviewer-domain adapter files named `reviewer-host-adapter-*.ps1` are registered and no `provider-adapter.ps1` or F-184 provider files are referenced (Trace: FR-012, FR-013, IMPL-004, TG-012, SC-006, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T033 [P] [US3] [owner: Reviewer] [sp: 0.25] Add Claude adapter fixture tests in `tests/continuous-co-review/unit/reviewer-host-adapter-claude-prompt.Tests.ps1` proving `claude -p` returns valid `FindingsResult` or deterministic `InfrastructureFailure` and uses safe argv/equivalent invocation (Trace: FR-012, SEC-005, INT-009, SC-005, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T034 [P] [US3] [owner: Reviewer] [sp: 0.25] Add Codex adapter fixture tests in `tests/continuous-co-review/unit/reviewer-host-adapter-codex-exec.Tests.ps1` proving `codex exec` returns valid `FindingsResult` or deterministic `InfrastructureFailure` and uses safe argv/equivalent invocation (Trace: FR-012, SEC-005, INT-009, SC-005, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T035 [P] [US3] [owner: Reviewer] [sp: 0.25] Add Copilot adapter fixture tests in `tests/continuous-co-review/unit/reviewer-host-adapter-copilot-prompt.Tests.ps1` proving `copilot -p` returns valid `FindingsResult` or deterministic `InfrastructureFailure` and uses safe argv/equivalent invocation (Trace: FR-012, SEC-005, INT-009, SC-005, SC-012, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T036 [P] [US3] [owner: Reviewer] [sp: 0.25] Add Cursor adapter fixture tests in `tests/continuous-co-review/unit/reviewer-host-adapter-cursor-agent-prompt.Tests.ps1` proving `cursor-agent -p` returns valid `FindingsResult` or deterministic `InfrastructureFailure` and uses safe argv/equivalent invocation (Trace: FR-012, SEC-005, INT-009, SC-005, SC-012, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T037 [P] [US3] [owner: Reviewer] [sp: 0.25] Add Antigravity adapter fixture tests in `tests/continuous-co-review/unit/reviewer-host-adapter-antigravity-prompt.Tests.ps1` proving `antigravity -p` returns valid `FindingsResult` or deterministic `InfrastructureFailure` and uses safe argv/equivalent invocation (Trace: FR-012, SEC-005, INT-009, SC-005, SC-012, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T038 [P] [US3] [owner: Reviewer] [sp: 0.50] Add `tests/continuous-co-review/unit/reviewer-execution-engine.Tests.ps1` covering synchronous bounded invocation, timeout, at most one pre-authorized availability fallback, hard block for unavailable specifically requested model without exact alternate authorization, requested/actual host-model provenance, and no silent downgrade (Trace: FR-009, FR-010, FR-016, INT-004, OBS-006, SC-010, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T039 [P] [US3] [owner: Reviewer] [sp: 0.25] Add `tests/continuous-co-review/unit/fresh-context-readonly-boundary.Tests.ps1` proving reviewer execution consumes an immutable bundle, does not edit source files, does not stage commits, does not push, does not mutate Specrew state, and does not persist raw prompts/transcripts/full stdout/stderr by default (Trace: FR-009, FR-010, SEC-002, SEC-003, SEC-006, OBS-009, SC-005, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)

### Implementation for User Story 3

- [ ] T040 [US3] [owner: Implementer] [sp: 0.50] Implement `scripts/internal/continuous-co-review/reviewer-host-catalog.ps1`, `scripts/internal/continuous-co-review/reviewer-model-capability.ps1`, `scripts/internal/continuous-co-review/reviewer-selection-policy.ps1`, and `scripts/internal/continuous-co-review/reviewer-authorization-gate.ps1` for non-secret configuration, capability discovery order, review-class recommendation, explicit authorization, and one authorized availability fallback (Trace: FR-016, INT-006, INT-007, INT-008, OBS-006, SC-010, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T041 [US3] [owner: Implementer] [sp: 0.50] Implement `scripts/internal/continuous-co-review/reviewer-execution-engine.ps1` and `scripts/internal/continuous-co-review/reviewer-host-adapter-registry.ps1` to spawn exactly one fresh-context adapter attempt plus at most one authorized availability fallback, using local file/stdin/stdout/process-exit contracts only (Trace: FR-008, FR-009, FR-010, INT-001, INT-004, SC-005, SC-010, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T042 [P] [US3] [owner: Implementer] [sp: 0.75] Implement all five phase-1 real headless adapter files `scripts/internal/continuous-co-review/reviewer-host-adapter-claude-prompt.ps1`, `scripts/internal/continuous-co-review/reviewer-host-adapter-codex-exec.ps1`, `scripts/internal/continuous-co-review/reviewer-host-adapter-copilot-prompt.ps1`, `scripts/internal/continuous-co-review/reviewer-host-adapter-cursor-agent-prompt.ps1`, and `scripts/internal/continuous-co-review/reviewer-host-adapter-antigravity-prompt.ps1` with safe argument arrays/equivalent APIs and deterministic infrastructure-failure mapping for unsupported or quirky host flags instead of crashes (Trace: FR-012, SEC-005, INT-009, SC-005, SC-006, SC-012, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T043 [US3] [owner: Implementer] [sp: 0.50] Implement `scripts/internal/continuous-co-review/checkpoint-review-orchestrator.ps1` to wire checkpoint baseline -> git diff -> request bundle -> capability/authorization -> fresh-context reviewer -> normalizer -> blackboard -> gate verdict without PostToolUse, hook trigger, rung 1, or Proposal 139 foundation work (Trace: FR-008, FR-009, FR-013, INT-001, OBS-002, SC-001, SC-002, SC-006, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)

**Checkpoint**: User Story 3 satisfies the host-neutral headless floor and deterministic adapter failure floor.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validate quality profile evidence, traceability, scope hygiene, and local execution commands without starting implementation beyond the approved spine.

- [ ] T044 [P] [owner: Reviewer] [sp: 0.25] Add `tests/continuous-co-review/integration/continuous-co-review-spine.Tests.ps1` to run the controlled fake-adapter end-to-end path through request, findings, thread, verdict, skipped-run, and infrastructure-failure fixtures (Trace: FR-001, FR-006, INT-009, OBS-003, SC-001, SC-002, SC-005, SC-009, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T045 [P] [owner: Spec Steward] [sp: 0.25] Add `specs/197-continuous-co-review/quality/iteration-001-quality-evidence.md` summarizing `qg-contract-schema-fixtures`, `qg-deterministic-gate-semantics`, `qg-adapter-failure-floor`, `qg-security-boundary`, `qg-protected-surface-guard`, and `qg-implementation-rules-trace` without absorbing Proposal 196 provenance/audit (Trace: FR-014, FR-015, SC-011, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T046 [owner: Reviewer] [sp: 0.25] Run `pwsh -NoProfile -Command "Invoke-Pester -Path tests/continuous-co-review"` and record any failures against the owning task/file in `specs/197-continuous-co-review/quality/iteration-001-quality-evidence.md` (Trace: INT-009, OPS-003, OBS-003, SC-001, SC-002, SC-005, SC-011, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T047 [owner: Spec Steward] [sp: 0.25] Run the SC-006 guard from `tests/continuous-co-review/governance/protected-surface-guard.Tests.ps1` and confirm `git --no-pager diff --name-only` touches none of the protected F-184 files, mirrored `.specify/extensions/specrew-speckit/scripts/` equivalents, `proposals/197-continuous-co-review.md`, or `.squad/agents/spec-steward/history.md` (Trace: FR-013, TG-005, SC-006, SC-011, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T048 [owner: Planner] [sp: 0.00] Update this file `specs/197-continuous-co-review/tasks.md` only if implementation re-planning is explicitly approved, preserving every task's FR/SC trace and `implementation-rules.yml` reference and re-running traceability checks before implementation starts (Trace: TG-001, TG-011, SC-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T049 [owner: Spec Steward] [sp: 0.25] Add `specs/197-continuous-co-review/iterations/001/manual-validation.md` with maintainer-run real-host prerequisites, exact per-host commands (`claude -p`, `codex exec`, `copilot -p`, `cursor-agent -p`, `antigravity -p`), expected parseable blocking finding, and a results table for host, CLI version, pass/fail, notes, and date (Trace: FR-012, FR-014, FR-015, OPS-006, SC-005, SC-012, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T050 [owner: Reviewer] [sp: 0.25] Add canonical planted-design-violation fixture `specs/197-continuous-co-review/iterations/001/planted-design-violation.diff` and document the expected blocking finding that names the violated design decision without requiring network/model/auth/cost in hermetic CI (Trace: FR-011, FR-012, INT-009, OBS-003, OPS-006, SC-001, SC-012, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)

---

## Phase 7: Iteration 002 - Reviewer-Definition Repair

**Purpose**: Repair the review send-back by making the canonical reviewer definition, `ReviewRequest.v2`, injected prompt, read-only/mutation guard, and exact SC-012 validation path authoritative without reopening the completed Iteration 001 spine.

**Capacity**: **8.00/20 SP**. Status: OK. Deferral guidance: if latest-remote-`main` conflict repair exceeds the preparatory slice, stop and split sync into its own human-approved step; do not absorb rung 1, hooks/PostToolUse, Proposal 139 foundation, Proposal 196 provenance, automated live CI, new dependencies, F-184 protected edits, `proposals/197-continuous-co-review.md`, or `.squad/agents/spec-steward/history.md`.

- [X] T051 [owner: Iteration Facilitator] [sp: 1.00] Merge or rebase latest remote `main` into `197-continuous-co-review`, resolve conflicts before runtime repair work, and confirm the changed-file list excludes F-184 protected surfaces, `proposals/197-continuous-co-review.md`, and `.squad/agents/spec-steward/history.md` (Trace: FR-023, IMPL-011, TG-013, SC-006, SC-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [X] T052 [owner: Spec Steward] [sp: 1.00] Add canonical reviewer instruction source `scripts/internal/continuous-co-review/code-review-agent.md` and contract tests/fixtures proving it contains Proposal 145 rubric phases, workshop-decision conformance, claim/design trace, report-falsification, explicit per-lens validation of workshop results, visibility policy, do-policy, and round protocol (Trace: FR-017, SEC-007, IMPL-008, SC-013, TG-013; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [X] T053 [owner: Architect] [sp: 2.00] Update `scripts/internal/continuous-co-review/review-request-builder.ps1`, `scripts/internal/continuous-co-review/reviewer-contracts.ps1`, and a new feature-local `scripts/internal/continuous-co-review/review-prompt-composer.ps1` to implement the already-planned `ReviewRequest.v2` schema contract, carrying reviewer instruction metadata/hash, design-context content and sources, exact diff/change-set content, `round_number`, `prior_findings`, `visibility_policy`, `do_policy`, and output contract `FindingsResult.v1`, then composing the exact adapter-bound prompt from those fields (Trace: FR-018, FR-019, INT-010, INT-013, OBS-010, IMPL-009, SC-014, SC-015, TG-013, TG-014; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [X] T054 [owner: Security Reviewer] [sp: 1.25] Add read-only host invocation propagation where supported and implement `scripts/internal/continuous-co-review/workspace-mutation-guard.ps1` plus execution-engine tests so source, Git, or Specrew-state mutation during reviewer execution invalidates the run uniformly instead of passing or being treated as a fix (Trace: FR-020, SEC-008, SEC-009, OBS-012, SC-016, TG-013; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [X] T055 [owner: Implementer] [sp: 0.75] Add feature-local host mirror support for best-effort native agent copies and reconcile `specs/197-continuous-co-review/contracts/reviewer-spawn-contract.md`, `specs/197-continuous-co-review/quickstart.md`, and `specs/197-continuous-co-review/iterations/001/manual-validation.md` only if implementation details diverge from the already-planned transport-only/composed-prompt contract (Trace: FR-018, FR-022, INT-011, INT-012, SC-017, SC-018, TG-014; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [X] T056 [owner: Reviewer] [sp: 1.50] Add deterministic prompt-composer and adapter-seam tests under `tests/continuous-co-review/` proving the actual outbound prompt contains the canonical rubric, design-context content, exact diff/change-set content, round number, prior findings, visibility policy, do-policy, and `FindingsResult.v1`, and that fixtures fail when the prompt is empty, bypassed, or fixture-owned (Trace: FR-021, OBS-011, IMPL-010, SC-014, SC-017, SC-018, TG-013; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [X] T057 [owner: Reviewer] [sp: 0.50] Run Iteration 002 validation for JSON schema parsing, `ReviewRequest.v2` contract fixtures, prompt-composer fixture tests, mutation-guard tests, protected-surface guard, and traceability verification before implementation review handoff (Trace: FR-021, FR-023, INT-013, OBS-011, SC-006, SC-011, SC-014, SC-015, SC-016, TG-013; Rules: specs/197-continuous-co-review/implementation-rules.yml)

**Checkpoint**: Iteration 002 proves runtime correctness comes from the injected canonical reviewer prompt and mutation-invalidated execution path, while host mirrors remain best-effort and completed Iteration 001 behavior remains preserved.

---

## Phase 8: Iteration 003 - Always-On Per-Checkpoint Co-Review (Phase A)

**Purpose**: Add the 197-owned deterministic gate floor and the gate-keyed dispatcher so code co-review becomes mandatory at every implement checkpoint, without editing F-184 protected surfaces and without the live Stop-hook trigger (Phase B / Iteration 004).

**Capacity**: **24.00/25 SP**. Status: OK (cap raised 20->25, maintainer-authorized, to keep the gate re-architecture in Iteration 003). Deferral guidance: do not start the Stop-hook wiring, host-abstraction edits, FR-008 relaxation, or cross-host hook fixtures in this iteration; those are Iteration 004 (Phase B). `scripts/internal/sync-boundary-state.ps1` is the shared but non-protected boundary-sync engine and is NOT on the F-184 protected list; the FR-025 gate ENFORCEMENT WIRING into it is deferred to coordinate with F-185 (authorized).

Re-architecture (D-197-I003-004/005): the gate's evidence model is replaced after the
feature's own co-reviews found HOLE A (gitignored-source blindness) + HOLE B (unanchored
operator baseline). T058 is done; T061 is superseded by T067; T065-T069 are the
content-addressed + anchored re-architecture; T059/T060/T062/T063 carry; T064 is revised.

- [X] T058 [owner: Implementer] [sp: 1.50] Record `reviewed_ref` and rebaseline each co-review to the last passing reviewed point (`scripts/internal/continuous-co-review/checkpoint-diff-provider.ps1`, `checkpoint-review-orchestrator.ps1`, `review-run-index-writer.ps1`). Done (`bd6ebebc`/`27343ce5`); the `diff_hash` field is retained but superseded as the gate key by the T065 tree-id (Trace: FR-027, IMPL-009, TG-013; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [~] T061 [owner: Reviewer] [sp: 2.00] SUPERSEDED by T067. The first gate-floor decision logic keyed on diff-from-baseline `diff_hash` freshness (`scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1`, committed `717c423f`/`e8493b8a`, 8/8 unit tests) was invalidated by the feature's own 145 co-review (HOLE A/B); re-architected in T067 (Trace: FR-025, NFR-001, TG-013; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [X] T065 [owner: Architect] [sp: 3.00] Add `scripts/internal/continuous-co-review/reviewed-state-digest.ps1`: a content-addressed reviewed-state tree-id via a temporary git index (`GIT_INDEX_FILE` + `read-tree HEAD` + `add -A` + `add -f` for gitignored SOURCE minus the secret/ambient denylist) and `write-tree`; plus the empty-tree no-content guard. Tests: determinism, gitignored-source-in, secret-out, tracked+gitignored drift detection, empty-tree (Trace: FR-025, SEC-002, NFR-001, TG-013; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [X] T066 [owner: Architect] [sp: 2.50] Record `reviewed_tree_id` on the run record and replace the scope filter in `Get-ContinuousCoReviewLastPassingReviewState` (`scripts/internal/continuous-co-review/review-run-index-writer.ps1`) with git lineage (`git merge-base --is-ancestor`) plus chain-to-anchor verification, with `tests/continuous-co-review/` coverage (Trace: FR-025, FR-027, TG-013; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [X] T067 [owner: Reviewer] [sp: 3.50] Re-architect `scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1` (supersedes T061): tree-id-equality freshness + chain-to-merge-base-anchor verification + empty-tree guard + fail-closed git handling + human-authorized recorded override. Falsifying tests: HOLE A blocks, HOLE B blocks, cross-feature isolation, empty, fail-closed-on-git-error (Trace: FR-025, SC-019, SC-020, NFR-001, TG-013; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [X] T068 [owner: Implementer] [sp: 2.50] Producer auto-anchoring in `scripts/internal/continuous-co-review/checkpoint-review-orchestrator.ps1` and `scripts/specrew-review.ps1`: anchor signoff-bearing runs to the last-pass (merge-base-with-trunk fallback), record the digest, flag exploratory custom-baseline runs as non-signoff; configurable trunk name (default `main`), with `tests/continuous-co-review/` coverage (Trace: FR-025, FR-027, INT-004, TG-013; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [X] T069 [owner: Implementer] [sp: 1.50] Retire the diff-hash freshness path as the gate key; keep the reviewable diff only for the reviewer's context bundle; remove the NEW-5 dead full-diff and reconcile `scripts/internal/continuous-co-review/checkpoint-diff-provider.ps1` + `review-signoff-evidence-gate.ps1`, with `tests/continuous-co-review/` coverage (Trace: FR-025, NFR-001, TG-013; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [X] T059 [owner: Architect] [sp: 2.50] Implement `scripts/internal/continuous-co-review/gate-review-dispatcher.ps1` and `scripts/internal/continuous-co-review/gate-review-registry.ps1` (registered in `_load.ps1`) with real-checkpoint-vs-casual-yield detection, gate detection, and a gate-keyed registry whose sole registrant is code review at implement; add `tests/continuous-co-review/` coverage proving zero navigator spawn on casual or unregistered stops (Trace: FR-032, SC-023, IMPL-004, TG-013; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [X] T060 [owner: Implementer] [sp: 1.00] Wire the dispatcher to `scripts/internal/continuous-co-review/checkpoint-review-orchestrator.ps1` so a registered implement checkpoint reviews its incremental diff and writes durable evidence under `.specrew/review/inline/<run-id>/`, with `tests/continuous-co-review/` coverage (Trace: FR-024, INT-004, TG-013; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [X] T062 [owner: Spec Steward] [sp: 1.25] Confirm one-time per-project navigator authorization for automatic runs in `scripts/internal/continuous-co-review/reviewer-authorization-gate.ps1` and wire blocking-finding escalation under the two-round cap in `scripts/internal/continuous-co-review/inline-review-gate-evaluator.ps1`, with `tests/continuous-co-review/` coverage (Trace: FR-028, FR-029, SC-021, NFR-005, SEC-004, TG-013; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [X] T063 [owner: Reviewer] [sp: 0.75] Add the delayed-stdin reviewer-spawn regression test under `tests/continuous-co-review/` proving the timeout bounds a stalled large-stdin child and no child process is orphaned (Trace: NFR-001, INT-004, TG-013; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [X] T064 [owner: Reviewer] [sp: 1.00] Run Iteration 003 closeout validation: full continuous-co-review suite green, the HOLE A and HOLE B repros now BLOCK, dispatcher fixtures, gate-floor blocking, the `tests/continuous-co-review/governance/protected-surface-guard.Tests.ps1` guard proving no F-184 protected-surface edits, and traceability, recording results under `specs/197-continuous-co-review/iterations/003/` (Trace: FR-025, FR-032, SC-006, SC-019, SC-020, SC-023, TG-013; Rules: specs/197-continuous-co-review/implementation-rules.yml)

**Checkpoint**: Iteration 003 ships the SOUND content-addressed + anchored gate floor and the gate-keyed dispatcher in 197-owned, non-protected code (HOLE A/B closed); the live Stop-hook navigator and cross-host proof remain Iteration 004 (Phase B).

---

## Dogfood Repair Addendum - Hard Gate and Self-Review Visibility

**Purpose**: Repair the real-host dogfood failure where host switching and compaction allowed implementation to reach review-signoff without completed co-review evidence, and where Specrew self-review stripped the co-review runtime under test.

- [X] T083 [owner: Implementer] [sp: 1.00] Make `scripts/internal/continuous-co-review/signoff-gate-wiring.ps1` enforce review-signoff by default and persist the gate decision on both allow and block paths; a present `co_review_gate_enforcement: false` config key is informational and cannot bypass the signoff backstop (Trace: FR-025, SC-019, SC-020, NFR-001; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [X] T084 [owner: Reviewer] [sp: 0.50] Make `scripts/internal/continuous-co-review/worktree-reviewer.ps1` Specrew-source-aware so self-review includes `scripts/internal/continuous-co-review/**` as product source, while downstream project reviews still strip that deployed methodology runtime from the review worktree and diff (Trace: FR-025, FR-030, FR-031, SC-019, SC-020; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [X] T085 [owner: Implementer] [sp: 0.75] Add reviewer-runtime telemetry and smart budget guidance in `scripts/internal/continuous-co-review/worktree-review-orchestrator.ps1`, `scripts/internal/continuous-co-review/worktree-reviewer.ps1`, `scripts/internal/continuous-co-review/co-review-service.ps1`, and `scripts/specrew-review.ps1`: intermediate `status.json` updates, elapsed/phase timing, artifact paths, reviewer invocation metadata, implementer-validation-first guidance, and a soft budget signal that does not restrict reviewer tool access (Trace: NFR-001, NFR-002, NFR-011, OBS-002, OBS-005, SC-005; Rules: specs/197-continuous-co-review/implementation-rules.yml)

**Checkpoint**: Dogfood repair keeps the hard gate in 197-owned co-review wiring, preserves F-184 protected shared-governance surfaces, gives the reviewer visibility into the actual co-review implementation when Specrew reviews itself, and makes long reviewer runs diagnosable without forcing a shallow/restricted review mode.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 Setup**: No dependencies; can start immediately.
- **Phase 2 Foundational**: Depends on Phase 1; blocks all user stories.
- **Phase 3 US1 (P1 MVP)**: Depends on Phase 2; establishes git-diff, request, controlled fake adapter, normalizer, and minimum deterministic path.
- **Phase 4 US2 (P2)**: Depends on Phase 2 and the US1 result contracts; blackboard protocol precedes the standalone gate validator implementation inside this phase.
- **Phase 5 US3 (P3)**: Depends on Phase 2 plus US1/US2 contract, thread, and gate seams; all five phase-1 real adapters must prove valid result or deterministic infrastructure failure without live-host dependence in fixture tests.
- **Phase 6 Polish**: Depends on selected story scope completion.
- **Phase 7 Iteration 002 repair**: Depends on completed Iteration 001 and begins with latest remote `main` synchronization (`T051`) before runtime repair tasks.
- **Phase 8 Iteration 003 Phase A**: Depends on the completed Iteration 001/002 spine; adds the per-checkpoint baseline (`T058`), gate-keyed dispatcher (`T059`-`T060`), non-protected gate floor (`T061`), authorization/escalation (`T062`), the owed spawn regression test (`T063`), and closeout validation (`T064`). The live Stop-hook trigger is deferred to Iteration 004 (Phase B).

### User Story Dependencies

- **US1 (P1)**: MVP after foundational contracts. Can be validated with the fake adapter without live hosts.
- **US2 (P2)**: Depends on shared contracts and complements US1 by making thread/disposition/gate state auditable.
- **US3 (P3)**: Depends on contracts, request bundle, normalizer, blackboard, and gate seams; each real adapter can be worked in parallel after registry/catalog tests exist.
- **Iteration 002 repair**: `T052` depends on `T051`; `T053` depends on `T052`; `T054` depends on `T053`; `T055` depends on `T053`; `T056` depends on `T053` and `T054`; `T057` depends on `T052`-`T056`.

### Required Dependency Spine

1. Contract validation and forced-findings schema/fixtures (`T004`-`T010`).
2. Mechanical protected-surface guard (`T011`).
3. Git-diff change-set, design context, request bundle, workspace, and result normalization (`T012`-`T023`).
4. Blackboard protocol and disposition evidence (`T024`, `T027`, `T030`).
5. Standalone gate validator (`T025`, `T026`, `T028`, `T029`).
6. Reviewer-domain catalog, authorization, adapter seams, fake adapter, all five phase-1 real headless adapters, and fresh-context orchestrator (`T031`-`T043`).
7. Quality evidence, Pester execution, traceability, protected-surface validation, and manual-validation enablers (`T044`-`T050`).
8. Iteration 002 reviewer-definition repair (`T051`-`T057`): remote-main sync -> canonical instruction -> `ReviewRequest.v2`/prompt composer -> read-only/mutation guard -> host mirror/runbook -> deterministic prompt evidence -> validation.

---

## Parallel Execution Examples

### User Story 1

```powershell
# After Phase 2 is complete, these tests touch different files and can be authored in parallel:
T012 tests/continuous-co-review/unit/checkpoint-diff-provider.Tests.ps1
T013 tests/continuous-co-review/unit/design-context-collector.Tests.ps1
T014 tests/continuous-co-review/unit/review-request-builder.Tests.ps1
T015 tests/continuous-co-review/unit/review-run-workspace-manager.Tests.ps1
T016 tests/continuous-co-review/unit/review-result-normalizer.Tests.ps1
T017 tests/continuous-co-review/integration/fixture-reviewer-path.Tests.ps1
```

### User Story 2

```powershell
# Thread, gate, and non-convergence tests can be authored in parallel before implementation:
T024 tests/continuous-co-review/unit/review-blackboard-writer.Tests.ps1
T025 tests/continuous-co-review/unit/inline-review-gate-evaluator.Tests.ps1
T026 tests/continuous-co-review/unit/non-convergence-escalation.Tests.ps1
```

### User Story 3

```powershell
# Phase-1 adapter fixture tests can be authored in parallel after T032 defines registry expectations:
T033 tests/continuous-co-review/unit/reviewer-host-adapter-claude-prompt.Tests.ps1
T034 tests/continuous-co-review/unit/reviewer-host-adapter-codex-exec.Tests.ps1
T035 tests/continuous-co-review/unit/reviewer-host-adapter-copilot-prompt.Tests.ps1
T036 tests/continuous-co-review/unit/reviewer-host-adapter-cursor-agent-prompt.Tests.ps1
T037 tests/continuous-co-review/unit/reviewer-host-adapter-antigravity-prompt.Tests.ps1
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 setup.
2. Complete Phase 2 foundational contracts and protected-surface guard.
3. Complete Phase 3 US1 with the controlled fake adapter path.
4. Stop and validate US1 independently with `pwsh -NoProfile -Command "Invoke-Pester -Path tests/continuous-co-review/contracts,tests/continuous-co-review/unit,tests/continuous-co-review/integration/fixture-reviewer-path.Tests.ps1"`.
5. Do not start hooks, rung 1, Proposal 139 foundation, live CI/CD E2E, or Proposal 196 provenance/audit.

### Incremental Delivery

1. Deliver contracts + fixtures + SC-006 guard.
2. Deliver US1 deterministic request/result/gate path with fake adapter.
3. Deliver US2 blackboard/disposition/gate auditability.
4. Deliver US3 catalog, authorization, all five real headless-floor adapters, and fresh-context orchestrator.
5. Complete polish checks, quality evidence, and manual real-host validation enablers.

### Capacity Deferral Guidance

- Current approved capacity position:
  1. Restore `T035`, `T036`, and `T037` Copilot/Cursor/Antigravity adapter fixture tests to Iteration 001.
  2. Restore `T042` to all five phase-1 real adapter implementations: Claude, Codex, Copilot, Cursor, and Antigravity.
  3. Add `T049` and `T050` manual-validation enablers for SC-012 while keeping automated live cross-host CI out of scope.
  4. Keep contract/schema, git-diff change-set, blackboard, standalone gate, SC-006 guard (`T011`/`T047`), fake/fixture adapter (`T017`/`T023`), and infrastructure-failure floor (`T009`) in Iteration 001.
- Do **not** defer contract schemas, forced findings, SC-006 protected-surface guard, deterministic gate semantics, fake adapter readiness floor, or adapter valid-result/infrastructure-failure proof.

---

## Traceability Summary

- **US1**: `T012`-`T023`; maps to FR-001, FR-002, FR-003, FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, FR-016, SC-001, SC-002, SC-005, SC-007, SC-009, SC-010, SC-011.
- **US2**: `T024`-`T030`; maps to FR-002, FR-004, FR-005, FR-006, FR-007, FR-014, SC-002, SC-003, SC-004, SC-008, SC-009, SC-011.
- **US3**: `T031`-`T043`; maps to FR-001, FR-008, FR-009, FR-010, FR-012, FR-013, FR-015, FR-016, SC-005, SC-006, SC-010, SC-011, SC-012.
- **Cross-cutting / foundational / polish**: `T001`-`T011`, `T044`-`T050`; maps to FR-001, FR-002, FR-011, FR-012, FR-013, FR-014, FR-015, FR-016, INT-009, OBS-003, OPS-006, TG-005, TG-009, TG-011, TG-012, SC-001, SC-005, SC-006, SC-011, SC-012.
- **Iteration 002 reviewer-definition repair**: `T051`-`T057`; maps to FR-017, FR-018, FR-019, FR-020, FR-021, FR-022, FR-023, SEC-007, SEC-008, SEC-009, INT-010, INT-011, INT-012, INT-013, OBS-010, OBS-011, OBS-012, IMPL-008, IMPL-009, IMPL-010, IMPL-011, TG-013, TG-014, SC-006, SC-011, SC-013, SC-014, SC-015, SC-016, SC-017, SC-018.
- **Iteration 003 always-on Phase A**: `T058`-`T064`; maps to FR-024, FR-025, FR-027, FR-028, FR-029, FR-032, NFR-001, NFR-005, SEC-004, IMPL-004, IMPL-009, SC-006, SC-019, SC-020, SC-021, SC-023, TG-013. Deferred to Iteration 004 (Phase B): FR-026, FR-030, FR-031, SC-022.
- **Dogfood hard-gate repair**: `T083`-`T085`; maps to FR-025, FR-030, FR-031, NFR-001, NFR-002, NFR-011, OBS-002, OBS-005, SC-005, SC-019, and SC-020. The implementation stays inside 197-owned continuous-co-review runtime and does not edit F-184 protected shared-governance or mirrored `.specify/extensions/specrew-speckit/scripts/` surfaces.

---

## Validation Footer

- All task checklist lines use `- [ ] T###` format.
- User story phase tasks include `[US1]`, `[US2]`, or `[US3]`.
- Setup, foundational, and polish tasks intentionally omit story labels.
- Every task includes at least one FR or SC trace and references `specs/197-continuous-co-review/implementation-rules.yml`.
- `SC-006` is enforced through the concrete deterministic guard task `T011` and validation task `T047`.
- `/speckit.analyze` is available only after this complete `tasks.md` exists and before implementation; do not run it as part of task generation.
