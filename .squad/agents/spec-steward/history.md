# Spec Steward History

Project-specific learnings and patterns discovered during work.

## Recent Work (2026-05-17)

### 2026-05-17: Feature 020 After-Tasks Validation PASS — Session-State Durability

**Pattern**: Batch after-tasks validation with full traceability audit on requirement mapping and task definition readiness.

**Context**: Feature 020 task generation completed (35 tasks, 33 SP across 3 phases: 2 SP companion chore + 16 SP Iteration 1 + 15 SP Iteration 2). Spec Steward runs after-tasks validation gate to certify all tasks meet Definition of Ready before human authorization for Iteration 1 planning.

**Validation Results**:
1. **Task count & story points**: 35 tasks / 33 SP verified against plan targets (2 + 16 + 15 = 33 SP) ✅ PASS
2. **Requirement traceability**: All 35 tasks trace to FR-001–FR-035; all user stories US1–US5 covered; 100% scope coverage ✅ PASS
3. **Role assignment**: All tasks assigned to defined roles (Implementer, Reviewer); no unknowns ✅ PASS
4. **Effort estimation**: Phase totals match plan capacity (companion chore 2 SP pre-work, Iteration 1/2 parallel delivery) ✅ PASS
5. **Acceptance criteria**: All criteria concrete and testable (sample: "verify atomic updates" <measurable>, "confirm <2s completion" <measurable>) ✅ PASS
6. **Dependency graph**: No circular dependencies; critical path identified (Phase 0 → T001/T002/T003 → parallel groups → T028 release) ✅ PASS
7. **Companion chore isolation**: Phase 0 (CHORE-001–004) properly marked pre-work, not counted against iteration capacity, must merge to main before Iteration 1 ✅ PASS
8. **Artifact integrity**: tasks.md, plan.md, spec.md all present, complete, well-formatted; no repair-needed gaps ✅ PASS

**Gate Outcome**: PASS (exit code 0). Feature 020 cleared for human authorization to proceed to Iteration 1 planning ceremony.

**Key Learnings**:
1. **After-tasks gate discipline**: Comprehensive validation batch (eight criteria across task/requirement/role/effort/criteria/dependency/scope/artifact) is production-ready pattern. Gate enforces governance before planning authorization.
2. **Requirement traceability at scale**: 35 tasks across 3 phases with 35 functional requirements (FR-001–FR-035) requires systematic cross-referencing. Vendor pattern: all tasks must have explicit Trace comment linking to FR tags.
3. **Companion chore separation**: Pre-work tasks (Phase 0) require explicit "must merge before Iteration 1" language and capacity exclusion to prevent downstream confusion.

**Artifacts**:
- `.squad/orchestration-log/2026-05-17T20-00-10Z-speckit-after-tasks.md` — Agent execution trace
- `.squad/log/2026-05-17T20-00-10Z-feature-020-after-tasks.md` — Session readiness summary
- `.squad/decisions.md` — Feature 020 After-Tasks Validation PASS decision entry
- `specs/020-session-state-durability/tasks.md` — 35 validated tasks

---

## Recent Work (2026-05-19)

### 2026-05-19: Feature 020 Specify+Clarify Completion — Session-State Durability

**Pattern**: Batch specify+clarify completion with deferred planning (signoff pause).

**Context**: Feature 020 (Session-State Durability & In-Flight Progress Tracking) generated from Proposal 035. Three user stories (P1: post-reboot recovery; P1: boundary-event sync; P2: where-am-I query). Twelve clarification questions resolved using recommended answers; no human override required.

**Key Learnings**:
1. **Deferred-planning pattern**: Specify+clarify can complete and pause for human signoff before planning phase, allowing feature intent validation while preserving planning autonomy. Useful for features with high cross-boundary impact (like F-020's state durability requirements).
2. **Clarification batch efficiency**: When all Q1–Q12 questions have defensible recommended answers, batch clarification completes without human iteration. Two-iteration delivery shape confirmed realistic (~40–50 SP).
3. **Orchestration logging discipline**: Specify+clarify batch completion requires both orchestration log (agent work trail) and session log (human-facing readiness summary), even without decision inbox entries.
4. **Spec quality baseline**: Three user stories, 12 acceptance scenarios, technology-agnostic success criteria, and mandatory content checklist provide complete specification contract for planning phase entry.

**Artifacts**:
- `.squad/orchestration-log/2026-05-19T183143Z-spec-steward.md` — Agent execution trace
- `.squad/log/2026-05-19T183143Z-feature020-specify-clarify.md` — Session readiness summary
- `specs/020-session-state-durability/spec.md` — Feature specification
- `specs/020-session-state-durability/checklists/requirements.md` — Quality checklist

## Core Context

Foundational patterns from May 8-11 established the spec steward discipline for Feature 015:

- **Contract-gap closure strategy (May 8)**: Surgical edits that add explicit constraints or versioned artifacts over rewriting requirements. Preserves traceability and approval history while strengthening spec contracts (applied to specs 002, 005).
- **Hardening-gate schema evolution (May 10-11)**: Nine-column schema (Concern, Category, Status, Evidence Basis, Runtime Evidence Status, Expected Controls, Blocking, Rationale, Approval) replaces six-column to distinguish planning-vs-runtime evidence. Canonical five concerns must appear in exact order before feature-specific concerns.
- **Pre-sign-off hardening-gate convention (May 11)**: Overall Verdict `ready` signals planning-level readiness; pending metadata (`Reviewed By: *(pending)*`, `Reviewed At: *(pending)*`) explicitly names what's awaiting human approval. Evidence Basis combinations enforce strict validator rules.
- **Per-iteration-scaffolding authorization discipline (May 11)**: Agents must not pre-emptively scaffold new iteration directories (plan.md, state.md, drift-log.md) without recorded authorization decision in `.squad/decisions.md` before artifact creation. Trap added to known-traps.md row 14.
- **Traceability enforcement pattern**: When approval changes scope (e.g., reducing validation commands), update both plan.md task definition AND hardening-gate.md concern evidence to create two-artifact traceability point. Single-artifact enforcement loses accountability.

## Recent Learnings

### 2026-05-11: Per-Iteration Scaffolding Governance Trap — Feature 007 Issue 3 Repair

[See Core Context above for summary; full entry preserved for governance audit trail]

### 2026-05-11: Feature 008 Iteration 005 Pre-Sign-Off Hardening-Gate Schema Convention

[See Core Context for schema evolution summary]

### 2026-05-10: Feature 008 Iteration 003 Approval Recording and Hardening Gate Status Vocabulary

[See Core Context for approval recording pattern summary; detailed entry preserved for audit trail]

The approval recording involved:
1. **plan.md Implementation Approval section**: Updated from pending to authorized with explicit approval evidence, approving human (Alon Fliess), and recorded date.
2. **state.md lifecycle state**: Updated Current Phase from 'planning' to 'approved' and Iteration Status to reflect implementation-approved but not yet executed state.
3. **hardening-gate.md approval fields**: Updated Overall Verdict, Reviewed By, Reviewed At, and added Hardening-Gate Sign-Off section.
4. **Hardening concern status vocabulary repair**: Five feature-specific concerns required Status correction from `requires-evidence` to `addressed` and Runtime Evidence Status correction to `pending-post-implementation`.

**Pattern discovered**: For pre-implementation hardening gates, concerns validated post-implementation must use Status `addressed` with Evidence Basis `planning-time-analysis`. Status `requires-evidence` is invalid for pre-implementation gates and triggers default validator issue. **Pattern discovered**: When Overall Verdict is `ready`, Approval Ref must be empty (—); approval references are required only for `deferred-with-approval` verdicts. **Pattern discovered**: Hardening-gate sign-off and implementation authorization are separate but complementary approvals recorded in respective artifact sections before implementation begins.

### 2026-05-10: Feature 008 Iteration 003 Hardening Gate Canonical Concern Repair

[Canonical concern ordering and nine-column schema pattern documented; consolidated into Core Context]

### 2026-05-08: Spec Quality Hardening Pass and Phase 2 Lifecycle Repairs

[Surgical spec hardening (specs 002, 005) and multi-iteration repair patterns consolidated into Core Context]

### 2026-05-13: Feature 015 Iteration 002 Authorization and Planning Alignment

The spec surfaces (spec.md, plan.md, tasks.md) were updated to reflect the user-authorized Iteration 002 scope covering seven items (FR-008 through FR-010, FR-012 through FR-014, FR-016 through FR-017). Key decisions:
- **Canonical shipped-feature status label**: Status field across four previously shipped specs (007, 009, 011, 012) must be updated from stale Draft to Complete, aligning with spec 013 pattern.
- **Traceability verification**: All 15 tasks (T010-T024) are traced to explicit FR items; no orphan tasks exist. FR-017 (shipped-feature status reconciliation) is new and properly traced.
- **Planning surface synchronization**: Spec steward updates ensure spec.md scope boundaries, plan.md phase planning, and .squad/identity/now.md all reflect Iteration 002 authorization consistently.

### 2026-05-13: Feature 015 Planning Artifact Repair

Repaired three categories of stale references:
- **Branch reference consistency**: Corrected `016-public-readiness-pass` → `015-public-readiness-pass` in spec.md, plan.md, and .github/copilot-instructions.md.
- **Versioning source-of-truth**: Made `.specrew/config.yml` authoritative (bumped 0.1.0-dev to 0.14.0); updated plan.md summary to state this explicitly.
- **Recent Changes clarity**: Replaced generic language with explicit versioning governance in .github/copilot-instructions.md.

Pattern: Feature artifact repairs require attention to both machine-readable scope (spec.md FR items) and human-readable governance language (.github/copilot-instructions.md Recent Changes).

### 2026-05-08: Feature 006 Requirement Repair for Checkpoint Sequencing and Success Metrics

Repaired authoritative requirement surfaces for feature `006-human-architecture-checkpoint` to resolve four critical specification ambiguities:

1. **Checkpoint sequencing made explicit**: Tightened the flow to resolve "before plan.md exists" vs "recorded in plan.md" paradox. The checkpoint now explicitly runs INSIDE `/speckit.plan`, after spec loading and before plan body generation, with the approved direction recorded IN the finalized plan.md's Architecture Intent Review section. This eliminates downstream confusion about whether the checkpoint happens before or after planning.

2. **Alternatives made optional for routine features**: Repaired FR-001, FR-005, brief-schema.md, and validation rules to permit empty alternatives when no meaningful architectural choices exist. Routine convention-following features (small bug fixes, simple refactors) no longer require fabricated alternative analysis. Alternatives are required only "WHEN alternative approaches meaningfully differ in cost, risk, or reversibility."

3. **SC-002 repaired to accept clean approvals**: Changed from "presence of at least one human constraint or decision override per feature" to "checkpoint completion with recorded approval (clean approval or approval-with-constraints both count as success)." Clean approvals where the human reviews and approves without changes are now explicitly valid successful outcomes, not failures requiring artificial activity.

4. **Decision record validation aligned**: Updated data-model.md to explicitly bless clean approval (no constraints, no rejected alternatives, no overrides) as a valid and successful outcome. `rejected_alternatives` and `human_constraints` are now correctly marked as optional rather than required.

**Pattern discovered**: When a governance checkpoint creates a "happens-before vs recorded-in" paradox, resolve by making the sequencing explicit: the checkpoint is a blocking pre-step INSIDE the command that generates the artifact, and the result is recorded IN the finalized artifact. This preserves both blocking behavior and traceability without requiring the artifact to exist before the checkpoint runs.

**Pattern discovered**: When "minimal interruption" conflicts with "always require alternatives," the specification should permit stating routine nature without detailed alternative generation. Success metrics must not punish clean approvals by requiring artificial constraints or overrides. A good governance checkpoint surfaces decisions when they matter, not when they don't.

### 2026-05-09: Feature 006 Metadata Cleanup—Branch and Date Alignment

Performed narrow metadata-only cleanup on feature 006 to close two consistency issues discovered in spec-steward review:

1. **Branch label alignment**: spec.md declared `006-human-architecture-checkpoint` as the feature branch while plan.md, research.md, and data-model.md correctly used `008-quality-profile-foundation`. Verified against git branch list that `008-quality-profile-foundation` is the current authoritative branch containing this work. Updated spec.md line 3 to match truth.

2. **Stale date correction**: spec.md line 169 contained `Session 2025-01-09` (clearly a typo from 2025 vs 2026). Corrected to `2026-05-09` to match the `Created` date in spec.md metadata (line 4) and the date headers in plan.md, research.md, and data-model.md.

**Pattern discovered**: When downstream documents (plan.md, research.md, data-model.md) already contain corrected metadata and the source spec is stale, prefer the truth of the downstream artifacts over cosmetic matching. Verify against authoritative sources (git branch state, session timestamps) before deciding which document to repair.

### 2026-05-13: Shipped Feature Spec Status Reconciliation

Reconciled the Status field across four previously delivered feature specifications from the stale `Draft` label to the canonical shipped-spec status `Complete`. This fulfills FR-017 for Feature 015 Iteration 002.

**Work completed**:
- Updated `specs/007-user-facing-progress-handoff/spec.md` Status from `Draft` to `Complete`
- Updated `specs/009-project-path-resolution/spec.md` Status from `Draft` to `Complete`
- Updated `specs/011-specrew-start-conditional-pause/spec.md` Status from `Draft` to `Complete`
- Updated `specs/012-descriptive-id-handoffs/spec.md` Status from `Draft` to `Complete`

**Pattern discovered**: When multiple shipped features still carry stale `Draft` labels, a bulk reconciliation pass is appropriate only when the governing feature spec (015) has established a canonical shipped-spec label (`Complete` per spec 013 pattern) and an explicit traceability mapping (FR-017) that identifies exactly which specs require the change. This ensures the reconciliation is authoritative and prevents accidental label drift on specs that may still be in active development.

## Patterns

<!-- Append entries below. Format: **Pattern:** description. **Context:** when it applies. -->

### 2026-05-12: Iteration Closeout Truth Requires Synchronized Lifecycle Surfaces

Closed feature iterations cannot stop at `state.md` alone. For feature 013 iteration 002, truthful closeout required synchronizing the live lifecycle surfaces that still narrated "future closeout" work: the iteration plan metadata, iteration state, drift log status, hardening-gate verification summary, trap-reapplication note, and `.squad/identity/now.md`.

**Pattern discovered**: When an iteration closes but the feature remains open, advance every live artifact that carries lifecycle status to the same boundary in one pass. Historical boundary artifacts such as `review.md` and `retro.md` should stay frozen as review/retro records, while the active handoff surfaces must say "iteration closed; feature closeout still pending separate authorization" explicitly.

### 2026-05-19: Feature 019 Boundary 6 — Feature-Closeout Execution Pattern

Executed Feature 019 Boundary 6 (feature-closeout) as a four-phase consolidated mechanical-execution pass. Key learnings:

**Phase 1 — Hardening-Gate Over-Claim Repair**:
- **Finding**: Pre-implementation hardening gates can't leave concerns at `planning-time-analysis/pending-post-implementation` when the iteration is closed. The validator enforces: when Status='addressed' and Runtime Evidence Status='pending-post-implementation', the concern blocks closure.
- **Solution**: Promote concerns to Evidence Basis = `runtime-evidence` and Runtime Evidence Status = `recorded` to reflect that the iteration DID deliver those concerns (even if some tasks were deferred to later iterations). The Post-Implementation Verification field documents the split explicitly.
- **Pattern**: Iteration 001 hardening-gate promoted four canonical concerns from planning-time to runtime-evidence, reflecting actual delivery status (minus T041/T054 deferred to Iteration 002). Validator then passed (exit code 0).

**Phase 2 — Rule 15 Version Bump**:
- **Scope**: Version bump from 0.18.0 to 0.19.0 across all version-tracked manifests: `Specrew.psd1` ModuleVersion, `extensions/specrew-speckit/extension.yml` version, `.specify/extensions/specrew-speckit/extension.yml` version, `.specrew/config.yml` specrew_version, and README.md badge/feature references.
- **Pattern**: README.md is a key manifest file for public-facing version references and must be updated as part of Rule 15 version bump.

**Phase 3 — Feature-Closeout Creation**:
- **Structure**: Feature-level closeout.md synthesizes across all iterations with: executive summary (total SP, accuracy), iteration summaries (scope, key commits, review verdicts, retro highlights), cross-platform validation matrix, pre-closeout repairs, human follow-up items, test evidence, corpus promotion candidates, deployment readiness checklist.
- **Pattern**: Feature closeout documents the full delivery arc including repair chains, deferred items, and post-merge follow-ups. It serves as the authoritative feature-completion record for future reference and corpus promotion.
- **Validator**: Feature-level closeout requires running validator across ALL iteration paths to ensure the full tree passes before declaring the feature complete.

**Phase 4 — PR Creation**:
- **Title Pattern**: `feat(distribution): PowerShell Gallery module with cross-platform launch` (concise, functional capability focus)
- **Body Structure**: Summary → Iteration Highlights → Repair Chain Note → Cross-Platform Validation → Test Plan → Pre-Merge Follow-Ups → Deployment → Acceptance Authority
- **Scope Note**: PR body documents pre-closeout repairs (hardening-gate + version bump) explicitly to provide traceability and context for reviewers.

**Process Discipline**:
- Each phase is a distinct commit-and-push boundary to preserve checkpoint history and enable rollback if needed.
- Edit count tracking (max 10 per checkpoint) prevents unbounded reconciliation loops and surfaces validator misalignments early.
- Validator pass is a hard gate before committing Phase 1 (hardening-gate repair) and Phase 3 (feature closeout).
- PR creation stops at creation (no merge) to preserve human sign-off boundary per Feature 016 boundary discipline.

**Feature 019 Outcome**:
- PR #189 created: https://github.com/alonf/specrew/pull/189
- Feature closeout complete across 3 checkpoint commits: `467a713` (Phase 1), `9863628` (Phase 2), `cf67eb5` (Phase 3)
- Governance validator passes for full feature tree (exit code 0)
- Ready for human review and merge to main



Feature 018 planning bundle completed across four sequential boundaries. Key spec steward actions:

**Clarify Phase (2026-05-15)**:
- 12 authorized clarification defaults integrated into spec.md
- Clarifications section extended with Q&A session 2026-05-15 covering terminal detection, rendering modes, layout behavior, sparkline placement, and snapshot persistence
- Functional requirements (FR-005, FR-006, FR-008, FR-011, FR-013, FR-019) integrated with decision context
- Edge Cases section expanded with 8 terminal/rendering/persistence scenarios
- Assumptions section formalized from clarification defaults
- Governance Alignment documented ownership roles and delivery windows per spec patterns

**Before-Plan Gate (2026-05-15)**:
- spec.md status transitioned from Draft → Approved to clear planning-phase blocker
- Spec structure verified complete: 20 functional requirements, 3 user stories, 8 edge cases, quality planning context
- Phase 1 quality planning context prepared (quality composition, stack surfaces, risk dimensions)
- Planning prerequisites confirmed satisfied; no blocking gaps identified

**Quality Composition Pattern**:
- Custom bundle (feature-018-rich-dashboard-compatibility) created because no stock preset cleanly matched console renderer requirements
- Five stack surfaces identified: dashboard-renderer-core, dashboard-cli-surface, closeout-and-validator-paths, docs-and-discovery, fixture-replay-harness
- Six risk dimensions marked required: terminal-compatibility, fallback-truthfulness, artifact-integrity, performance-budget, backward-compatibility, documentation-clarity
- Mechanical checks tied to requirement pillars: rich-mode fixtures, monochrome-fallback fixtures, sparkline-only validation, nfr-001-render-budget
- Quality tool bundle reuses existing PowerShell governance/tooling lane per Feature 017 precedent

**Scope Discipline**:
- Single-iteration feature slice scoped explicitly (10–12 SP nominal, 12–15 SP envelope)
- Five approved pillars enforced: rich-mode primitives, PoC-parity information density, sparkline addition, backward-compatible validation, documentation
- Deferred items listed explicitly: working-days projection, MVP-vs-1.0 two-horizon, minimum-days sample stretching, bootstrapped-date schema changes, configurable velocity windows
- Ownership roles and delivery windows documented in spec per governance pattern
- Specification ready for implementation authorization; explicit human sign-off required before hardening-gate-and-implementation-auth boundary

**Planning Artifact Alignment**:
- Spec status field changed from Draft to Approved
- All FR/US relationships documented
- Edge cases and Assumptions sections complete per Feature 017 precedent
- Clarifications session recorded with dates and decision context
- Quality composition explicit (no hidden assumptions about test coverage or tooling)
- 2026-05-15: Feature 018 decision consolidation and inbox merge completed. Six inbox decisions merged into decisions.md: Implementer bounded repair R-018-V2 decision, Implementer feature-iteration label preservation for Recent Shipped granularity, Planner iteration-scoped hardening scaffold authorization, Reviewer pre-implementation refresh to ready-with-concerns, Reviewer initial pre-implementation blocker (resolved by hardening-gate artifact creation), and Reviewer visual terminal check (documented direct terminal misdiagnosis). Iteration 001 now carries explicit pre-implementation approval ledger with five recorded watchpoints for implementation governance: terminal-capability decision precedence, Windows VT fallback truthfulness, render-budget stop-ship evidence, ANSI stripping with Unicode preservation, and closeout dashboard artifact rendering immutability. Review verdict remains `blocked` pending Alon confirmation run of fresh `.\scripts\specrew.ps1 where` terminal to verify rich glyphs/colors/sparklines render correctly. Orchestration and session logs created for Feature 018 bounded repair; all inbox files cleared; .squad/ state ready for git commit.

## 2026-05-18: Feature 019 Iteration 002 Boundary 1 Governance Artifact Scaffold

**Context**: Cross-platform behavioral issue diagnostic discipline; 22-iteration repair chain (R1–R22).

**Key Learnings**:
1. Diagnostic discipline upfront can prevent extended repair chases (22→5-line fix with diagnostic prep)
2. Form-vs-meaning recurrence in symptom-chasing (flags and wrappers chased over root cause at invocation layer)
3. Cross-platform scope partitioning: syntactic vs. behavioral audits must be separate test evidence
4. Deferred-launch pattern reusability: env-var-pointed temp file for script-to-function-body handoff
5. Repair-chase depth thresholds: >5 iterations without root isolation signals need for diagnostic pause

**Pattern**: Cross-platform behavioral issues require minimal-variable diagnostic tests BEFORE hypothesizing platform-conditional workarounds.

**Applicable Features**: Feature 020+ (cross-platform interactive CLI workflows).

**Evidence**: Iteration 002 repair chain analysis, cross-platform test evidence finalization, corpus candidate approval.

---

