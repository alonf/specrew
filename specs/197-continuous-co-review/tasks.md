# Tasks: Continuous Co-Review

**Input**: Design documents from `/specs/197-continuous-co-review/`
**Prerequisites**: `spec.md`, `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `implementation-rules.yml`, `iterations/001/design-analysis.md`, and `contracts/`
**Requested by**: Alon Fliess
**Human verdict**: approved for tasks
**Worktree / branch**: `C:\Dev\197-continuous-co-review` on `197-continuous-co-review`

**Tests**: Required. The approved spec includes acceptance scenarios and SC-001..SC-011; Pester tests and fixtures are intentionally sliced beside the code they prove rather than deferred to the end.

**Organization**: Dependency order is preserved inside story phases: contract + forced-findings schema first, then git-diff change-set + blackboard protocol, then standalone gate validator, then reviewer-domain headless-floor adapters and fresh-context reviewer path.

**Capacity**:

- Iteration 001 spine slice estimate: **18.75 story points**.
- Proposal-level planning range: **13-21 story points**.
- Capacity warning: **18.75/18 SP exceeds the approved Iteration 001 capacity by 0.75 SP**. Before implementation approval, either accept this overcommit explicitly or defer the lowest-priority polish/US3 validation slice that does not weaken the contract spine. Any added rung 1 work, hook/PostToolUse trigger, Proposal 139 foundation work, Proposal 196 provenance/audit work, CI/CD E2E implementation, new dependency, or protected-surface coordination is additional overcommit and must be deferred or re-approved.

**Hard scope guardrails**:

- Do **not** start rung 1, hook/PostToolUse triggers, or Proposal 139 foundation work.
- Do **not** edit `proposals/197-continuous-co-review.md`.
- Do **not** include `.squad/agents/spec-steward/history.md` runtime churn in feature commits.
- Do **not** edit F-184 protected host-runtime, hook, provider, registry, refocus, shared-governance, mirrored `.specify/extensions/specrew-speckit/scripts/` surfaces, or `validate-governance.ps1`.
- Keep Proposal 197 reviewer-provider components in the `scripts/internal/continuous-co-review/` namespace with reviewer-domain names such as `reviewer-host-adapter-*`, `reviewer-model-capability`, and `reviewer-host-catalog`; do not create generic `provider-adapter.ps1`.
- Preserve unnamed CI/CD E2E contract hooks/fixtures only for future Proposal 181 + Proposal 194 canary composition.
- Treat human-confirmed lens-stamp provenance/audit as non-blocking Proposal 196 scope, not Proposal 197 work.

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
- [ ] T035 [P] [US3] [owner: Reviewer] [sp: 0.25] Add Copilot adapter fixture tests in `tests/continuous-co-review/unit/reviewer-host-adapter-copilot-prompt.Tests.ps1` proving `copilot -p` returns valid `FindingsResult` or deterministic `InfrastructureFailure` and uses safe argv/equivalent invocation (Trace: FR-012, SEC-005, INT-009, SC-005, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T036 [P] [US3] [owner: Reviewer] [sp: 0.25] Add Cursor adapter fixture tests in `tests/continuous-co-review/unit/reviewer-host-adapter-cursor-agent-prompt.Tests.ps1` proving `cursor-agent -p` returns valid `FindingsResult` or deterministic `InfrastructureFailure` and uses safe argv/equivalent invocation (Trace: FR-012, SEC-005, INT-009, SC-005, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T037 [P] [US3] [owner: Reviewer] [sp: 0.25] Add Antigravity adapter fixture tests in `tests/continuous-co-review/unit/reviewer-host-adapter-antigravity-prompt.Tests.ps1` proving `antigravity -p` returns valid `FindingsResult` or deterministic `InfrastructureFailure` and uses safe argv/equivalent invocation (Trace: FR-012, SEC-005, INT-009, SC-005, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T038 [P] [US3] [owner: Reviewer] [sp: 0.50] Add `tests/continuous-co-review/unit/reviewer-execution-engine.Tests.ps1` covering synchronous bounded invocation, timeout, at most one pre-authorized availability fallback, hard block for unavailable specifically requested model without exact alternate authorization, requested/actual host-model provenance, and no silent downgrade (Trace: FR-009, FR-010, FR-016, INT-004, OBS-006, SC-010, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T039 [P] [US3] [owner: Reviewer] [sp: 0.25] Add `tests/continuous-co-review/unit/fresh-context-readonly-boundary.Tests.ps1` proving reviewer execution consumes an immutable bundle, does not edit source files, does not stage commits, does not push, does not mutate Specrew state, and does not persist raw prompts/transcripts/full stdout/stderr by default (Trace: FR-009, FR-010, SEC-002, SEC-003, SEC-006, OBS-009, SC-005, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)

### Implementation for User Story 3

- [ ] T040 [US3] [owner: Implementer] [sp: 0.50] Implement `scripts/internal/continuous-co-review/reviewer-host-catalog.ps1`, `scripts/internal/continuous-co-review/reviewer-model-capability.ps1`, `scripts/internal/continuous-co-review/reviewer-selection-policy.ps1`, and `scripts/internal/continuous-co-review/reviewer-authorization-gate.ps1` for non-secret configuration, capability discovery order, review-class recommendation, explicit authorization, and one authorized availability fallback (Trace: FR-016, INT-006, INT-007, INT-008, OBS-006, SC-010, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T041 [US3] [owner: Implementer] [sp: 0.50] Implement `scripts/internal/continuous-co-review/reviewer-execution-engine.ps1` and `scripts/internal/continuous-co-review/reviewer-host-adapter-registry.ps1` to spawn exactly one fresh-context adapter attempt plus at most one authorized availability fallback, using local file/stdin/stdout/process-exit contracts only (Trace: FR-008, FR-009, FR-010, INT-001, INT-004, SC-005, SC-010, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
- [ ] T042 [P] [US3] [owner: Implementer] [sp: 0.50] Implement real headless adapter files `scripts/internal/continuous-co-review/reviewer-host-adapter-claude-prompt.ps1`, `scripts/internal/continuous-co-review/reviewer-host-adapter-codex-exec.ps1`, `scripts/internal/continuous-co-review/reviewer-host-adapter-copilot-prompt.ps1`, `scripts/internal/continuous-co-review/reviewer-host-adapter-cursor-agent-prompt.ps1`, and `scripts/internal/continuous-co-review/reviewer-host-adapter-antigravity-prompt.ps1` with safe argument arrays/equivalent APIs and deterministic infrastructure-failure mapping (Trace: FR-012, SEC-005, INT-009, SC-005, SC-006, TG-011; Rules: specs/197-continuous-co-review/implementation-rules.yml)
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

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 Setup**: No dependencies; can start immediately.
- **Phase 2 Foundational**: Depends on Phase 1; blocks all user stories.
- **Phase 3 US1 (P1 MVP)**: Depends on Phase 2; establishes git-diff, request, controlled fake adapter, normalizer, and minimum deterministic path.
- **Phase 4 US2 (P2)**: Depends on Phase 2 and the US1 result contracts; blackboard protocol precedes the standalone gate validator implementation inside this phase.
- **Phase 5 US3 (P3)**: Depends on Phase 2 plus US1/US2 contract, thread, and gate seams; real adapters must prove valid result or deterministic infrastructure failure.
- **Phase 6 Polish**: Depends on selected story scope completion.

### User Story Dependencies

- **US1 (P1)**: MVP after foundational contracts. Can be validated with the fake adapter without live hosts.
- **US2 (P2)**: Depends on shared contracts and complements US1 by making thread/disposition/gate state auditable.
- **US3 (P3)**: Depends on contracts, request bundle, normalizer, blackboard, and gate seams; each real adapter can be worked in parallel after registry/catalog tests exist.

### Required Dependency Spine

1. Contract validation and forced-findings schema/fixtures (`T004`-`T010`).
2. Mechanical protected-surface guard (`T011`).
3. Git-diff change-set, design context, request bundle, workspace, and result normalization (`T012`-`T023`).
4. Blackboard protocol and disposition evidence (`T024`, `T027`, `T030`).
5. Standalone gate validator (`T025`, `T026`, `T028`, `T029`).
6. Reviewer-domain catalog, authorization, adapter seams, fake adapter, real headless adapters, and fresh-context orchestrator (`T031`-`T043`).
7. Quality evidence, Pester execution, traceability, and protected-surface validation (`T044`-`T048`).

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
# Adapter fixture tests can be authored in parallel after T032 defines registry expectations:
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
4. Deliver US3 catalog, authorization, real headless-floor adapters, and fresh-context orchestrator.
5. Complete polish checks and quality evidence.

### Capacity Deferral Guidance

- If effort exceeds 18 SP, defer lowest-priority slices first while preserving the contract spine:
  1. Defer optional live host smoke and keep deterministic adapter fixture floor only.
  2. Defer richer cross-host/cross-model graduation documentation beyond the existing contract hook notes.
  3. Defer any non-required quality narrative expansion that does not affect SC-001..SC-011.
- Do **not** defer contract schemas, forced findings, SC-006 protected-surface guard, deterministic gate semantics, fake adapter readiness floor, or adapter valid-result/infrastructure-failure proof.

---

## Traceability Summary

- **US1**: `T012`-`T023`; maps to FR-001, FR-002, FR-003, FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, FR-016, SC-001, SC-002, SC-005, SC-007, SC-009, SC-010, SC-011.
- **US2**: `T024`-`T030`; maps to FR-002, FR-004, FR-005, FR-006, FR-007, FR-014, SC-002, SC-003, SC-004, SC-008, SC-009, SC-011.
- **US3**: `T031`-`T043`; maps to FR-001, FR-008, FR-009, FR-010, FR-012, FR-013, FR-015, FR-016, SC-005, SC-006, SC-010, SC-011.
- **Cross-cutting / foundational / polish**: `T001`-`T011`, `T044`-`T048`; maps to FR-001, FR-002, FR-013, FR-014, FR-015, FR-016, INT-009, OBS-003, OPS-006, TG-005, TG-009, TG-011, TG-012, SC-001, SC-005, SC-006, SC-011.

---

## Validation Footer

- All task checklist lines use `- [ ] T###` format.
- User story phase tasks include `[US1]`, `[US2]`, or `[US3]`.
- Setup, foundational, and polish tasks intentionally omit story labels.
- Every task includes at least one FR or SC trace and references `specs/197-continuous-co-review/implementation-rules.yml`.
- `SC-006` is enforced through the concrete deterministic guard task `T011` and validation task `T047`.
- `/speckit.analyze` is available only after this complete `tasks.md` exists and before implementation; do not run it as part of task generation.
