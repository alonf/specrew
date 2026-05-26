# Feature Specification: Specrew v0.27.3 Trust-Hardening Bug-Bash Bundle

**Feature Branch**: `047-bug-bash-trust-hardening`  
**Created**: 2026-05-26  
**Status**: Draft  
**Input**: F-047 Bug-Bash + Improvement Brief — 7 bundled lifecycle-tooling reliability and downstream-user trust-hardening fixes, theme "downstream-user trust hardening + lifecycle-tooling reliability", shipping as the v0.27.3 minor patch. Under Proposal 055's bug-bash slice pattern (3+ related issues in one session = bug-bash with running findings.md).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Handoff-Block Validator Enforcement (Priority: P1)

A reviewer or operator runs governance validation on an iteration. The validator detects three classes of handoff-discipline failure and surfaces each as a backward-compatible WARN: (1) an iteration/boundary commit landed without a preceding `=== SPECREW HANDOFF ===` block, (2) a missing `dashboard.md` is correctly diagnosed as either a non-Specrew-managed iteration OR an auto-render code regression rather than a generic miss, and (3) canonical artifacts (review.md, retro.md, etc.) are found in ephemeral host-scratch directories instead of the project tree.

**Why this priority**: This is the foundation for Items 2 and 4 and the strongest single lever against the autopilot/host prose-discipline drops empirically observed across F-046 (Antigravity) and the PlanningPoC sessions.

**Independent Test**:

- Construct a fixture iteration whose boundary commit has no preceding handoff block; run `validate-governance.ps1` and assert a WARN (not FAIL) is emitted via the shared `Test-SpecrewHandoffBlockPresent` helper.
- Construct a fixture where `dashboard.md` is absent because the iteration is not Specrew-managed; assert the diagnosis distinguishes it from an auto-render regression.
- Construct a fixture where `review.md` exists under a path resembling `.../.gemini/antigravity-cli/brain/...`; assert a wrong-location WARN.

**Acceptance Scenarios**:

1. **Given** an iteration commit lacks a preceding handoff block, **When** validation runs, **Then** a handoff-presence WARN is emitted and validation does not FAIL.
2. **Given** `dashboard.md` is missing, **When** validation runs, **Then** the diagnosis differentiates "non-Specrew-managed iteration" from "auto-render code regression".
3. **Given** a canonical artifact is located in an ephemeral host-scratch directory, **When** validation runs, **Then** a wrong-location WARN is emitted.

---

### User Story 2 - Post-Compaction Handoff-Drop Regression Lock (Priority: P1)

A reviewer wants assurance that the most insidious handoff-drop variant — an agent that emits a proper handoff block before context compaction but drops it immediately after — is permanently covered. An acceptance test exercises Proposal 120 sub-trigger 3c: an iteration commit with no preceding handoff block AND a compaction marker visible in session metadata must produce the WARN.

**Why this priority**: Locks the empirically-observed 2026-05-26 PlanningPoC post-compaction drop (commit `f06491e5`) in as a regression test so the Item 1 detector cannot silently regress on this case.

**Independent Test**:

- Add the scenario to `tests/integration/non-specrew-session-bypass.tests.ps1` (created by Item 1); assert WARN fires when both the missing-handoff condition and the compaction marker are present.

**Acceptance Scenarios**:

1. **Given** an iteration commit with no preceding handoff block AND a compaction marker in session metadata, **When** validation runs, **Then** the post-compaction handoff-drop WARN is emitted.

---

### User Story 3 - Review-Diagrams Mermaid Template Hardening (Priority: P2)

A reviewer relies on `review-diagrams.md` containing real Mermaid diagrams for review. The validator soft-WARNs when the file exists but contains no ` ```mermaid ` block; the scaffolder ships a Mermaid skeleton (component `graph TD` + `sequenceDiagram`) instead of empty fences; and per-host Reviewer charter templates direct authors to use Mermaid rather than ` ```text ` ASCII trees.

**Why this priority**: The 2026-05-25 PlanningPoC iter-001 review passed lint with ` ```text ` ASCII trees and no validator caught the missing Mermaid — degrading reviewer value without any signal.

**Independent Test**:

- Create a `review-diagrams.md` with only a ` ```text ` block; run validation and assert a soft-WARN.
- Run `scaffold-reviewer-artifacts.ps1` and assert the emitted `review-diagrams.md` contains a non-empty ` ```mermaid ` skeleton.

**Acceptance Scenarios**:

1. **Given** `review-diagrams.md` exists with no ` ```mermaid ` block, **When** validation runs, **Then** a soft-WARN is emitted.
2. **Given** the reviewer scaffolder runs, **When** it writes `review-diagrams.md`, **Then** the output contains a Mermaid skeleton (component + sequence examples).

---

### User Story 4 - Downstream-Language Audit + Internal-Reference Regex Check (Priority: P1)

A downstream Specrew user reading a coordinator handoff or installed instruction must never encounter an opaque internal reference (e.g., "Feature 016 only allows one human approval...") they cannot decode. All `installed-instructions/` files and coordinator-prompt templates are audited and rewritten so prose names the methodology concept being referenced rather than an internal feature/proposal number, and the validator emits a WARN when `\bF-\d{3,}\b`, `\bProposal \d{3,}\b`, or `\bFeature \d{3,}\b` patterns appear in handoff-block prose.

**Why this priority**: Directly serves the bundle's headline theme (downstream-user trust). Opaque internal references are a concrete, repeatedly-observed trust leak (2026-05-26 PlanningPoC handoff prose).

**Independent Test**:

- Grep `installed-instructions/` for the three patterns after the rewrite; assert zero matches in user-facing prose.
- Feed a handoff block containing "Feature 016" through the validator regex check; assert a WARN.

**Acceptance Scenarios**:

1. **Given** an installed instruction or coordinator template, **When** audited, **Then** no `\bF-\d{3,}\b` / `\bProposal \d{3,}\b` / `\bFeature \d{3,}\b` internal reference remains in user-facing prose.
2. **Given** a handoff block containing an internal feature/proposal reference, **When** validation runs, **Then** a WARN is emitted.

---

### User Story 5 - Skill-Catalog Empty-Directory UX (Priority: P3)

An operator whose per-host skill directory (e.g., `.claude/skills/`) exists but contains zero `SKILL.md` files runs `specrew start`. Auto-repair fires (redeploying the skills) instead of the contradictory current behavior where `Get-SpecrewSkillCatalogState` reports the root present (so repair is skipped) while a separate per-host check WARNs that skill files are missing.

**Why this priority**: A real but low-severity UX wart documented as a docs-only note in F-046 Bug 5; sharpening it removes a confusing mixed signal.

**Independent Test**:

- Create a skill root directory with zero `SKILL.md` files; call `Get-SpecrewSkillCatalogState` and assert `HasMissingRoots` is `true` (content-based, not existence-only), so auto-repair runs and no contradictory WARN survives.

**Acceptance Scenarios**:

1. **Given** a skill root directory exists but is empty of `SKILL.md` files, **When** `specrew start` runs, **Then** auto-repair fires and the catalog is treated as having a missing root.

---

### User Story 6 - Feature-Closeout SDLC Actions in Handoff (Priority: P2)

At the feature-closeout boundary, every host's coordinator emits the same PR-at-feature-close SDLC action items (push → open PR → address automated PR review → merge) as `HUMAN ACTION NEEDED`, regardless of whether the agent's loaded memory happens to contain that pattern. The SDLC sequence is embedded in the coordinator-prompt feature-closeout HANDOFF template (per-host) and optionally echoed by the boundary-sync helper's post-feature-closeout console output.

**Why this priority**: F-046 (Antigravity) emitted only "review the dashboard and findings" at feature-closeout while F-045 (Codex) correctly emitted the full PR sequence — a host-inconsistency that bypassed the adopted SDLC.

**Independent Test**:

- Inspect each per-host coordinator-prompt feature-closeout HANDOFF template; assert all include the push/PR/review/merge action items.

**Acceptance Scenarios**:

1. **Given** any supported host reaches feature-closeout, **When** the coordinator emits the HANDOFF block, **Then** the PR-at-feature-close SDLC action items are present.

---

### User Story 7 - tasks-progress.yml Resume Reconciliation (Priority: P2)

An operator resumes a session on a feature whose iteration is complete. `specrew start` regenerates `tasks-progress.yml` by deriving per-task status from the authoritative `tasks.md` (`[x]` checkboxes) and `state.md` (`Last Completed Task`), so the welcome-back snapshot reflects on-disk truth instead of unconditionally marking every task `planned` and telling the agent to "Start T001" on a finished feature.

**Why this priority**: Empirically confused the 2026-05-26 Claude resume on F-046 at feature-closeout. Form-vs-meaning gap at the persistence layer (same class as F-046 G5).

**Independent Test**:

- Create a fixture where `tasks.md` shows all tasks `[x]` and `state.md` shows the last task complete; run the regeneration path and assert the resulting `tasks-progress.yml` marks those tasks `done`, not `planned`.

**Acceptance Scenarios**:

1. **Given** `tasks.md` marks tasks complete (`[x]`) and `state.md` confirms completion, **When** `specrew start` regenerates `tasks-progress.yml`, **Then** the derived per-task status matches `tasks.md` (tasks.md authoritative).

---

### Edge Cases

- **Handoff detection (US1)**: an iteration that is legitimately not Specrew-managed must NOT be flagged as a missing-handoff regression — diagnosis must distinguish the two.
- **Mermaid check (US3)**: a `review-diagrams.md` that contains a ` ```mermaid ` block alongside explanatory ` ```text ` must NOT WARN.
- **Internal-ref regex (US4)**: legitimate non-internal numeric tokens (version strings like `v0.27.3`, RFC numbers, years) must not trip the `\bF-\d{3,}\b` / `\bProposal \d{3,}\b` / `\bFeature \d{3,}\b` patterns — patterns are anchored to the internal-reference prefixes.
- **Empty skill dir (US5)**: a skill root with non-`SKILL.md` files only (e.g., a stray README) is still treated as missing.
- **Resume reconciliation (US7)**: when `tasks.md` and `state.md` disagree with each other, `tasks.md` is authoritative and the divergence is surfaced rather than silently resolved.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Governance validation MUST detect when an iteration/boundary commit lacks a preceding `=== SPECREW HANDOFF ===` block and emit a WARN, using a shared `Test-SpecrewHandoffBlockPresent` helper in `shared-governance.ps1`. (Proposal 120 Pillar 1)
- **FR-002**: Governance validation MUST augment trigger-bypass diagnosis to differentiate "non-Specrew-managed iteration" from "auto-render code regression" when `dashboard.md` is missing, and emit the appropriate WARN. (Proposal 120 Pillar 2)
- **FR-003**: Governance validation MUST emit a WARN when canonical artifacts are detected in ephemeral host-scratch directories (e.g. paths under `.gemini/antigravity-cli/brain/`). (Proposal 120 Pillar 3)
- **FR-004**: An acceptance test MUST verify that an iteration commit with no preceding handoff block AND a compaction marker in session metadata triggers the WARN (Proposal 120 sub-trigger 3c), added to `tests/integration/non-specrew-session-bypass.tests.ps1`.
- **FR-005**: Governance validation MUST soft-WARN when `review-diagrams.md` exists but contains no ` ```mermaid ` block. (Proposal 121 Pillar 1)
- **FR-006**: The reviewer-artifacts scaffolder MUST emit a non-empty Mermaid skeleton (component `graph TD` + `sequenceDiagram` examples) in `review-diagrams.md` instead of empty fences. (Proposal 121 Pillar 2)
- **FR-007**: Per-host Reviewer charter templates MUST direct authors to use Mermaid for diagrams and not substitute ` ```text ` ASCII trees. (Proposal 121 Pillar 3)
- **FR-008**: All `installed-instructions/` files and coordinator-prompt templates MUST be audited and rewritten so user-facing prose names the methodology concept rather than an internal `\bF-\d{3,}\b` / `\bProposal \d{3,}\b` / `\bFeature \d{3,}\b` reference. (Proposal 078 Pillar 2b)
- **FR-009**: Governance validation MUST add a regex check that emits a WARN when internal feature/proposal references appear in handoff-block prose. (Proposal 078 Pillar 5)
- **FR-010**: `Get-SpecrewSkillCatalogState` MUST treat a skill root directory containing zero `SKILL.md` files as a missing root (content-based check, not existence-only) so auto-repair fires and no contradictory per-host "missing skill files" WARN survives. (F-046 Bug 5 follow-up, fix option a)
- **FR-011**: The coordinator-prompt feature-closeout HANDOFF template MUST embed the PR-at-feature-close SDLC sequence (push → open PR → address automated PR review → merge) as `HUMAN ACTION NEEDED` items across all per-host templates; the boundary-sync helper MAY additionally echo the same sequence in post-feature-closeout console output. (F-046 retro improvement #2)
- **FR-012**: The `specrew-start.ps1` `tasks-progress.yml` regeneration path MUST derive per-task status from `tasks.md` (`[x]` checkboxes) and `state.md` (`Last Completed Task`) — with `tasks.md` authoritative — instead of unconditionally writing all tasks as `planned`. (New 2026-05-26 finding, fix option a)
- **FR-013**: The feature MUST record per-item Surface / Repro / Validation Criterion / Evidence Pointer / Status in a durable `findings.md` ledger.
- **FR-014**: Any change to `extensions/specrew-speckit/scripts/*` MUST be mirrored byte-identical in `.specify/extensions/specrew-speckit/scripts/`.
- **FR-015**: The feature MUST bump the Specrew version to `v0.27.3` consistently across `.specrew/config.yml`, `extension.yml`, and `Specrew.psd1` (ModuleVersion), and record the change in `CHANGELOG.md`, per Rule 15.
- **FR-016**: All new detection rules added by this feature MUST be severity WARN (not FAIL) to remain backward-compatible.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: US1 maps to FR-001, FR-002, FR-003, FR-016. Owner: Implementer. Delivery: iteration 001.
- **TG-002**: US2 maps to FR-004. Owner: Implementer. Delivery: iteration 001 (immediately after US1).
- **TG-003**: US3 maps to FR-005, FR-006, FR-007, FR-016. Owner: Reviewer. Delivery: iteration 001.
- **TG-004**: US4 maps to FR-008, FR-009, FR-016. Owner: Spec Steward (audit) + Implementer (regex check). Delivery: iteration 001.
- **TG-005**: US5 maps to FR-010. Owner: Implementer. Delivery: iteration 001.
- **TG-006**: US6 maps to FR-011. Owner: Spec Steward. Delivery: iteration 001.
- **TG-007**: US7 maps to FR-012. Owner: Implementer. Delivery: iteration 001.
- **TG-008**: FR-013 (findings ledger), FR-014 (mirror parity), and FR-015 (version bump) are global governance constraints applying across all items. Owner: Reviewer (verification).
- **TG-009**: Any spec/implementation conflict surfaced during implement MUST be reconciled via spec update before review sign-off (no silent drift).

### Key Entities *(include if feature involves data)*

- **HandoffBlock**: The `=== SPECREW HANDOFF ===` fenced block; presence/absence relative to a boundary commit is the detection subject for US1/US2.
- **ReviewDiagramArtifact**: `review-diagrams.md`; its Mermaid-block content is validated and scaffolded by US3.
- **InstalledInstruction**: User-facing prose under `installed-instructions/` and coordinator-prompt templates; audited by US4 for internal references.
- **SkillCatalogState**: The computed state of per-host skill roots (`HasMissingRoots`); redefined by US5 to be content-aware.
- **TaskProgressRecord**: The `tasks-progress.yml` per-task status, reconciled from `tasks.md` + `state.md` by US7.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of fixture iterations whose boundary commit lacks a preceding handoff block emit the handoff-presence WARN; 0 false positives on iterations with a correctly-emitted block.
- **SC-002**: Missing-`dashboard.md` diagnosis correctly classifies both the non-Specrew-managed case and the auto-render-regression case in fixtures (2/2).
- **SC-003**: 100% of fixtures with a canonical artifact in an ephemeral host-scratch directory emit the wrong-location WARN.
- **SC-004**: The post-compaction handoff-drop acceptance test (sub-trigger 3c) passes and fails-closed if the Item 1 detector regresses.
- **SC-005**: `review-diagrams.md` with no ` ```mermaid ` block emits a soft-WARN (100% of fixtures); the scaffolder emits a non-empty Mermaid skeleton.
- **SC-006**: 0 `\bF-\d{3,}\b` / `\bProposal \d{3,}\b` / `\bFeature \d{3,}\b` internal references remain in `installed-instructions/` user-facing prose; the validator regex WARNs on a planted internal reference.
- **SC-007**: A skill root that exists but contains zero `SKILL.md` files yields `HasMissingRoots = true` and triggers auto-repair, with no contradictory residual WARN.
- **SC-008**: 100% of per-host coordinator-prompt feature-closeout HANDOFF templates contain the PR-at-feature-close SDLC action items.
- **SC-009**: Regenerating `tasks-progress.yml` on a fixture whose `tasks.md` shows all tasks `[x]` yields all tasks `done` (0 false `planned`).
- **SC-010**: Mirror parity is byte-identical for every modified `extensions/specrew-speckit/scripts/*` file; all integration suites pass with 0 regressions; v0.27.3 is consistent across the 3 manifests.

## Assumptions

- The bundle is confined to the 7 listed items; no new features.
- New detection rules are WARN-only and backward-compatible; existing FAIL behaviors are unchanged.
- Item 4 implements only Proposal 078 Pillar 2b (regex check + `installed-instructions/` audit); the full 5-pillar Proposal 078 and the full Proposal 099 installed-file audit are out of scope and may follow as separate slices.
- Effort values may be numeric or t-shirt (per F-045 iter-002 retro signal); unification is a separate feature.
- Existing legacy and non-targeted behaviors remain unchanged.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Claude (session coordinator) under requestor authority from Alon Fliess.
- **Iteration Facilitator**: Specrew Crew Coordinator (Claude Code).
- **Capacity Model**: Single-iteration bug-bash defect-bundle closure, ~12-20 SP within the 20 SP cap.
- **Drift Signals**: Spec-to-plan/task mismatch, unresolved findings, pointer drift, mirror-parity divergence, version-manifest drift.
- **Human Oversight Points**: Specify completion, before-implement, review sign-off, retro, feature-closeout (PR-at-feature-close SDLC).
