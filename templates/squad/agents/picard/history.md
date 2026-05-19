# Project Context

- **Owner:** Alon
- **Project:** Specrew
- **Stack:** Markdown, YAML, PowerShell, Spec Kit extension assets, Squad extension structure
- **Description:** A spec-governed AI crew operating model built as a monorepo with companion Spec Kit and Squad extensions.
- **Created:** 2026-04-17

## Core Context

I am the spec alignment gate for Specrew. My job is to keep every plan, task, decision, and implementation traceable to the authoritative source requirements.

**Authority Foundation** (Iteration 0):

- Iteration lifecycle is **normative and binding** (spec.md, contracts/iteration-artifacts.md)
- Four-phase state machine: Planning → Execution → Review/Demo → Retrospective (enforced by validator)
- Dogfooding obligation: Specrew must follow its own iteration lifecycle (binding per spec.md)
- Single Coordinator Protocol (`.squad/protocol.md` v1.0): 6 roles, decision workflows, escalation paths
- Governance validator deployed (`.squad/agents/scribe/scripts/validate-governance.ps1`) and operational at CI gates
- Iteration 0 closure: Complete (2026-04-18), Alon sign-off recorded, all closure artifacts aligned, validator PASS

**Active Work Track** (2026-04-19 Carryover Plan Correction):

- ✅ Filed board-management gap carryover (T-024): `speckit.taskstoissues` + Squad GitHub Project wiring
- ✅ Filed worktree execution-model carryover (T-025): Squad worktree + branch + PR-per-task execution flow
- ✅ Repaired Iteration 1 plan.md: Added T-024, T-025 to task table; normalized narrative + capacity math
- ✅ Data capacity revision: Explicit distinction between total (23.5 pts) and committed slice (Iter 1a: 20.0 pts, Iter 1b: 3.5 pts)
- ✅ Worf carryover review: PASS verdict on corrected plan with all carryovers traceable + capacity coherent
- **Status**: Carryover correction set complete; ready for decision merge and session close

## Learnings

- **FR-022 narrow revision pattern**: For contract-facing PowerShell CLIs, disable positional binding and parse GNU-style `--flag` arguments from `ValueFromRemainingArguments` so the documented standalone surface cannot silently misbind into typed parameters.
- **Bootstrap probe order**: `scripts\specrew-init.ps1` must run `copilot --version`, then non-fatal `gh api /user`, then delegated metadata parsing from `copilot help config`; missing auth context is warning-only, not a bootstrap blocker.
- **Consent display requirement**: FR-022 interactive consent is only aligned when the prompt shows agent name, raw access path, and availability before the yes/no question.

- Phase state machine is **normative** — not optional governance. Skipping phases is a contract violation.
- Dogfooding is binding: Specrew must follow its own iteration lifecycle for its own development.
- Phase gates prevent drift: spec-authority gate (pre-execute), traceability gate (pre-execute), drift-check (per-task), review gate (end-execute).
- Completion semantics must stay single-purpose: `retro.md` closes retrospective, but iteration status remains `retro` until Alon records final sign-off.
- Closure evidence tables must be regenerated at sign-off time, not copied from draft versions (prevents stale claims).
- **Artifact contract enforcement is precise**: Metadata fields (Started, Completed) require `YYYY-MM-DD` format; task table columns (Story) require non-null values. Governance validator treats these as hard failures, not warnings.
- **Story reference mapping**: User stories should align with task narrative scope. Validation/testing tasks map to the user story for the capability they enable, not to the user story for the immediate feature under test (e.g., CI pipeline validation maps to US-2 "Run iteration end-to-end", not just the individual feature story).
- **Narrow revision protocol**: When fixing governance defects, change only the identified fields. Do not expand scope to "while I'm here" improvements. Picard's charter: "I do not let the fix drift wider than necessary."
- **Source-of-truth alignment**: When runtime surfaces diverge from documentation, correct the docs if they conflict with authoritative spec.md. Document divergence rationale (e.g., FR-019 deferred) to prevent future misalignment.
- **Reviewer lockout ensures quality**: Requiring a different author for rejection corrections prevents same-author confirmation bias and surfaces fresh perspectives on the same defect.
- **Carryover representation is mandatory**: Iteration plans must represent every named carryover as an explicit, traceable task. Narrative-only acknowledgment is drift. If capacity math differs from baseline, document the buffer/slice explicitly.
- **Iteration-scoped spike artifacts are independent**: Spike results files (`spikes.md`) capture iteration-specific validation outcomes without claiming the spike existed before. Iteration-scoped spikes are orthogonal to research.md general findings; iteration artifacts record *when findings are validated against real blockers*.

- **Clone-vs-Package Documentation Drift** (2026-04-19): User-facing documentation must explicitly distinguish between interim clone-based paths and future package-based paths. Hardcoded repository paths (e.g., `C:\Dev\Specrew\scripts\specrew-init.ps1`) create brittle product truth that breaks when distribution model changes. Requirement: Label each instruction block with deployment context ("Clone-Based Path (Current)", "Package-Based Path (Planned)"). Relative paths in clone examples are preferred over absolute paths for clarity. Missing dual-form labeling is HIGH-risk drift when product supports multiple installation forms.

- **PATH Convenience is Not a Contract Violation** (2026-04-18): When specs define **what** (command-driven interface) but are silent on **how** (distribution model, PATH management), documentation may present optional convenience guidance without violating the contract. The minimal-truth-sufficient pattern: if implementation delivers contract requirements (commands exist and work), and documentation shows **working invocation first** (clone-based full path) with convenience notes second (PATH addition optional), no spec clarification is needed. Clone-based invocation is v1's normative distribution model (binding per FR-002 "standalone CLI/script at the repo root"). Package-based global CLI is planned future work, not current contract. Spec does not prohibit PATH guidance; documentation truthfully presents both required method and optional enhancement.

### 2026-04-19: V-R7-1 + T-011 Scope Guardrails Defined

**Task**: Picard defines authoritative scope boundaries for agent-detection slice (V-R7-1 spike + T-011 implementation).

**Scope Decision Delivered**:

- Authoritative requirement boundaries confirmed from spec.md FR-022 and specrew-init.md contract
- Three detection probes specified (Copilot runtime, auth context, Agent HQ enumeration) with non-fatal failure semantics
- Interactive consent prompt format finalized (per-agent display, Copilot non-disableable, optional delegates)
- Non-interactive flag set complete (`--agents=copilot|claude|codex|all`, `--no-agents`, `--force`)
- Persistence schema locked (enabled, access_path, availability, detected_at fields in iteration-config.yml)
- Graceful degradation patterns approved: all probe failures are recoverable; no blocking errors
- Out-of-scope boundaries clarified: billing/cost out, routing orchestration out (FR-021 deferred), resume behavior out, collision detection out (FR-012 deferred)
- V-R7-1 spike research deliverables defined: detection API endpoint, response schema, error cases, edge cases, backwards compatibility

**Artifacts**:

- `.squad/decisions/inbox/picard-fr022-guardrails.md` created (7 sections: boundaries, degradation, out-of-scope, V-R7-1 research, acceptance criteria, decision recording)
- Decision forwarded to Alon (Coordinator) for team merge

**Pattern Insight**: Agent-detection consent must be orthogonal to execution routing. T-011 writes configuration; T-011 does not use it. This preserves separation of concerns: detection is v1-slice, routing is v2-future (FR-021). Consent gate is strict ("no billing data shown") but graceful degradation is permissive ("iteration proceeds spec-only if agents unavailable").

**Traceability**: All guardrails trace back to FR-022 source requirement or explicit iteration-2+ deferral. No undocumented scope.

### 2026-04-19: Iteration 001 Early Completion Closure (V-R7-1 + T-011)

**Task**: Picard records completed work from Iteration 1a agent-detection slice and brings iteration artifacts into contract compliance.

**Completed Work**:

- ✅ V-R7-1 (0.5 pts): Detection API research spike complete. Validated Copilot runtime detection surface, Agent HQ enumeration, graceful-degradation patterns.
- ✅ T-011 (1.5 pts): Agent detection + consent implementation complete. Interactive prompt, per-agent flags, config persistence, non-interactive defaults.

**Closure Corrections** (4 artifacts):

1. **plan.md**: Status planning → executing; Capacity 0/24.0 → 20.5/24.0 (Iter 1a baseline); V-R7-1 + T-011 rows: planned → done with Agent/Actual/Verdict filled
2. **state.md** (created): Contract-compliant execution state. Last Completed Task: T-011; Tasks Remaining: T-001–T-010, T-012–T-025; Phase tracking table
3. **spikes.md** (created): Iteration 001-scoped spike results for V-R7-1. Objective, findings (runtime/auth/delegated-agent probes), acceptance criteria ✅ 6/6, design decisions for T-011, unresolved questions (FR-021/cost deferred)
4. **README.md**: Current Phase "Foundation (Iteration 0)" → "MVP Development (Iteration 1 - 1a Execution)"; Bootstrap instructions updated to reference Iter 1a gate + Iter 1b tests

**Traceability**: All corrections map to spec.md requirements or contracts/iteration-artifacts.md gates. Contract compliance checklist ✅ all pass.

**Pattern Insight**: Iteration-scoped spike artifacts are independent records of *when findings are validated against real blockers* — they are not backdated claims. Spikes.md links research.md findings to iteration-specific acceptance and unblocking conditions.

### 2026-04-20: FR-022 Closeout Decision Recorded

**Task**: Picard records FR-022 (V-R7-1 + T-011) early-completion closure decision after Worf re-review pass.

**Closure Status**: ✅ COMPLETE

- Iteration 001 state.md and spikes.md prepared in working tree and ready for version control (Worf re-review PASS)
- Following re-review pass, different author commits both files to git
- Closure decision merged to .squad/decisions.md (2026-04-20T00:27:10Z)
- Three review verdicts consolidated: Initial NEEDS-WORK, lockout-compliant re-revision, re-review PASS

**Pattern Insight**: Multiple-verdict consolidation pattern. When Worf issues initial NEEDS-WORK, then lockout-compliant correction (different author fixes), then re-review PASS, all three verdicts are tracked. Closure decision records the verdict sequence to preserve full review history.

**Traceability**: Closure decision includes full review sequence (Worf → Picard fix → Worf re-review), maps to contract-required lockout protocol, confirms no same-author confirmation bias.

### 2026-04-21: Bootstrap Next-Step Handoff & Configured Team State Requirements

**Task**: Picard updates spec.md to require terminal-based next-step handoff after bootstrap and ensure downstream repos are treated as configured Squad teams.

**User Requirement** (Alon):

- After Specrew initialization, developers should not need to read README/getting-started just to know what to do next
- Bootstrap should state the next command to run and explain the usage/development flow directly in the terminal
- Freshly bootstrapped downstream repos should be treated as already-configured Squad teams, not unconfigured scaffolds

**Spec Updates**:

1. **FR-002**: Added two new mandates:
   - "Upon successful completion, `specrew init` MUST output explicit next-step guidance directly in the terminal: (1) the next command(s) to run (e.g., starting spec authoring with Spec Kit workflows), (2) concise flow orientation (baseline crew → specify features → plan iteration → execute), and (3) references to team extension commands without requiring the developer to leave the terminal for baseline orientation or read separate getting-started documentation."
   - "The bootstrapped downstream repository MUST be left in a state recognizable by the Squad coordinator as a configured, operation-ready team (not an unconfigured scaffold requiring fresh team creation)."

2. **US-1 (Bootstrap User Story)**: Updated narrative and acceptance criteria (AC-1, AC-4) to require:
   - Terminal-based next-step guidance (next command, workflow summary, team extension instructions)
   - No requirement to leave terminal or read docs for baseline orientation
   - Downstream repo left in Squad-coordinator-recognizable configured team state

**Implementation Impact**:

- `scripts/specrew-init.ps1`: Update `Write-PostBootstrapGuidance` function to output next-step commands and workflow summary
- Validation: Test that Squad coordinator recognizes bootstrapped repos as configured teams (no additional initialization prompts)

**Decision Artifact**: `.squad/decisions/inbox/picard-bootstrap-next-step-spec.md`

**Pattern Insight**: Bootstrap UX must eliminate documentation dependency for baseline orientation. Terminal output should provide sufficient context for the user to proceed with the next command and understand the basic workflow. Documentation serves as reference/depth, not first-line orientation.

**Traceability**: User input → FR-002 requirement update → US-1 acceptance criteria refinement → implementation guidance. All changes map to explicit user requirement without scope drift.

**Learnings**:

- Reviewer lockout ensures fresh perspectives on rejection reasons; different author breaking the same defect provides confidence
- Untracked proof artifacts block acceptance even when narrative content is correct — durability matters

### 2026-04-20: FR-020 Brownfield Merge Audit (Iteration 002 T-205/T-206)

**Task**: Picard audits Iteration 002 scope (T-205/T-206, FR-020) to identify concrete acceptance boundaries, spec-drift traps in bootstrap scripts, and reviewer-gate constraints for La Forge before implementation.

**Audit Scope**: Brownfield merge behavior in `specrew init` and `deploy-squad-runtime.ps1`; dry-run safety hardening.

**Core Spec Requirements (FR-020)**:

- Detect existing Spec Kit specs, governance artifacts, Squad team config, installed extensions
- Merge Specrew baseline roles/config into existing setup WITHOUT overwriting user data
- Report conflicts when versions incompatible; suggest upgrade path without proceeding

**Critical Findings** (7 spec-drift traps):

1. **Role-name collision detection missing** — code appends baseline roles without checking for pre-existing "Spec Steward", "Planner", etc. roles
2. **Ceremony-name collision detection missing** — appends ceremonies.md block without checking for existing `Specrew: Planning` titles
3. **Agent charter conflict detection missing** — doesn't warn if charter already has `## Directives` section outside managed block
4. **Dry-run does not surface conflicts** — claims safety but skips collision detection during --dry-run
5. **-Force bypasses conflict resolution prompts** — FR-020 says "asks user"; code has zero interactive conflict prompts
6. **Non-empty directory rejection contradicts merge intent** — rejects bootstrap into repos with existing .git/.README unless -Force (vs. spec's "merge into existing")
7. **Config version staleness risk** — .specrew/config.yml from v0.1 bootstrap persists when v0.2 Specrew runs; silent staleness

**Acceptance Criteria (Reviewer Gates for La Forge)**:

T-205 MUST:

- ✅ Preserve user customizations outside managed blocks (already working)
- ✅ Create governance files additively (already working)
- ❌ Implement role-name collision detection + reporting
- ❌ Implement ceremony-name collision detection + reporting
- ❌ Implement agent charter conflict detection + warning
- ⚠️ Clarify non-empty directory behavior (decision needed from Alon)

T-206 MUST:

- ❌ Create `.specrew/bootstrap-dry-run-{timestamp}.md` safety report during --dry-run
- ❌ Implement interactive conflict-resolution prompts (ALWAYS surface conflicts, even with -Force)
- ❌ Enforce conflict prompts are mandatory; -Force only skips consent/confirmation, not conflict resolution

**Traceability**: All 7 findings map directly to FR-020 requirement text or implied contract boundaries (Iteration-artifacts.md dry-run validation).

**Decision-Inbox**: Created `.squad/decisions/inbox/picard-fr020-brownfield-guardrails.md` with full audit report, 3 decision questions for Alon, and phase-wise resolution path.

**Reviewer Gate Status**: ❌ NOT READY — T-205/T-206 cannot pass review without collision detection code and dry-run safety hardening. Blocks implementation until findings resolved.

**Pattern Insight**: Brownfield merge is different from greenfield bootstrap; it requires TWO safety gates that greenfield skips: (1) collision detection (what data exists?), (2) conflict resolution (what should we do about it?). Current code implements merge (additive-only blocks) but skips both safety gates. This is why the spec says "asks user" — merging without asking is silent data corruption risk.

### 2026-05-03: Iteration 002 Remaining-Scope Alignment Review (T-204 + Sequencing)

**Task**: Picard performs spec-drift guard review for Iteration 2 remaining scope while T-204 is completing. Verifies T-204 (FR-019) alignment, identifies sequencing constraints for six remaining tasks, and produces reviewer/spec note for Coordinator.

**T-204 (FR-019) Findings**:

- ✅ **Functionally Aligned**: resume-iteration.ps1 script covers all FR-019 requirement text (persist state, provide resume command, handle interruptions)
- ✅ **Tests Passing**: Integration test validates 4/4 scenarios (continue, repair-metadata, blocked, abort)
- ❌ **Delivery Surface Incomplete**: Script exists but missing Squad skill wrapper (.copilot/skills/specrew-iteration-resume/SKILL.md) required by contracts/squad-extension.md
- ❌ **User-Facing Docs Missing**: No "Resume" section in docs/user-guide.md; integration point with iteration workflow undocumented

**Verdict**: Core logic is production-ready and tested. Recommend **NEEDS-WORK** for review acceptance until Squad skill wrapper and user documentation are in place. Estimated +0.5 pts to complete deliverable surface.

**Remaining Tasks Sequencing** (V-R7-2, T-201, T-202, T-203, T-207, T-208):

- ✅ **No blocking interdependencies** prevent parallel start on most tasks
- **Explicit sequential**: T-201 → T-203 (effort model schema must exist before wiring), T-207 → T-208 (scorer impl before output)
- **Implicit integration**: T-202 overcommit logic should feed into T-203 planning output (soft coupling, but natural integration)
- **Independent validation**: V-R7-2 validates routing surface for future FR-021; no blocker for current iteration work

**Capacity Check**: Remaining 9 pts + accepted 7 pts (T-204/205/206 estimated) = 16 pts planned. ✅ Balanced.

**Traceability**: All 6 remaining tasks + T-204 mapped to FR (100% coverage). No orphans.

**Deliverable**: `.squad/decisions/inbox/picard-iteration-002-alignment-review.md` — comprehensive reviewer/spec note with task dependency graph, sequencing recommendations, and Coordinator handoff actions.

**Pattern Insight**: Incomplete delivery surface (logic correct, contractual wrapping missing) is a distinct drift class from incorrect logic. Squad-skill wrapper pattern must be validated during implementation-readiness gate, not at final review. Consider adding "Contract Readiness Checklist" to planning phase for skills/ceremonies/directives deliverables.

**Traceability**: All findings trace to spec.md FR-019/FR-007/FR-015/FR-017/FR-021 requirements and contracts/squad-extension.md skill/ceremony delivery surfaces. No undocumented scope.

- Iteration-early-completion pattern: Record work truthfully, trace to requirements, validate contract compliance before closure

### 2026-04-23: Specrew Command Truth Audit (`specrew team` Post-Bootstrap Availability)

**Task**: Audit alignment between FR-023 contract, user documentation, implementation, and post-bootstrap runtime truth for `specrew team` commands.

**Audit Scope**: Four user-facing truth surfaces (README.md, getting-started.md, user-guide.md, specrew-init.ps1 bootstrap output) vs. FR-023 specification vs. scripts/specrew-team.ps1 implementation.

**Verdict**: ✅ **ALIGNED** — no changes required to spec, docs, or implementation.

**What Proves Alignment**:

1. **Implementation**: `scripts\specrew-team.ps1` exists with all 4 commands (`add`, `update`, `remove`, `list`), atomic operations, baseline protection, edge-case handling
2. **Spec (FR-023)**: Requires "command-driven team management commands" — satisfied by PowerShell script with subcommands (does NOT require packaged CLI distribution)
3. **Documentation Pattern**: All four docs show aspirational short form (`specrew team add`) followed by explicit invocation guidance (`.\scripts\specrew-team.ps1` or PATH setup)
4. **Bootstrap Output**: Shows short form (valid for PATH-configured users); docs clarify invocation for all contexts
5. **No Overclaiming**: Docs never claim globally-available CLI or packaged distribution (interim clone-based model is documented in getting-started.md with "Future: Packaged Installation" section)

**Truth Pattern Confirmed**: Contract-aligned truth = show aspirational form + explicit invocation guidance + PATH alternative. This pattern lets users see future convenience while documenting current reality.

**Traceability**: All alignment claims trace to FR-023 requirement text, implementation code, and documented invocation patterns.

**Decision Artifact**: `.squad/decisions/inbox/picard-specrew-command-truth.md` with full audit report, proof surfaces, and no-change rationale.

**Pattern Insight**: "Command-driven interface" is implementation-agnostic. PowerShell scripts with subcommands satisfy the requirement if atomic operations and protection logic are delivered. Distribution model (clone vs. package) is orthogonal to interface contract. Documenting both invocation forms (short + PATH, long + relative) prevents overclaiming while preserving aspirational UX.

### 2026-04-20: Team-Member CRUD Command-Gap Analysis

**Task**: Analyze whether Specrew's documented team-extension workflow is command-driven or requires manual multi-file editing, and determine spec changes needed for alignment.

**Key Findings**:

- **Current documented workflow**: 3-file manual editing (team.md row + charter.md + history.md) per getting-started.md lines 109-112 and user-guide.md lines 114-117
- **Spec assumption**: FR-002 references "Squad's standard team configuration workflows" without validating whether Squad provides command-driven CRUD
- **Squad CLI surface**: `squad hire` command exists but returns "full implementation pending" (v0.9.1); no working CRUD surface for team members
- **Gap classification**: Documented workflow is accurate to current Squad capability, but spec language implies non-manual workflows that don't exist yet

**Spec Delta Required**:

1. **FR-002 Amendment**: Clarify that "Squad's standard team configuration workflows" currently means manual file editing until Squad completes `squad hire`
2. **New FR-023**: Contingent wrapper command (`specrew team add/remove`) if Squad doesn't deliver native CRUD by Iteration 2
3. **Documentation precision**: Add "Known Limitation" notes acknowledging Squad's incomplete command surface and Specrew's planned response path

**Decision Artifact**: `.squad/decisions/inbox/picard-team-command-gap.md` with three-option recommendation (Status Quo + Clarity / Specrew Wrapper / Documented Gap), spec amendment text, traceability mapping

**Pattern Insight**: When documenting user-facing workflows, distinguish between *working as designed* (current manual path is accurate to Squad v0.9.1 capability) and *spec assumption drift* (spec language implies command-driven path that doesn't exist). FR-002's "standard team configuration workflows" is an *upstream dependency assumption* rather than a product defect, but documentation must make the interim manual path explicit rather than burying it in implicit "after bootstrap" guidance.

**Recommendation**: Hybrid Option A+C — Document current state accurately, record as known limitation, defer Specrew wrapper until Iteration 2-3 contingent on Squad roadmap.

### 2026-04-19: Baseline Validation Scope Verification (Alon Request)

**Task**: Verify spec alignment with command-driven team management, protected baseline roles, and validator scope behavior.

**Requirement Verified**: Validator must require mandatory baseline members (Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator) but NOT constrain custom team members added via `specrew team add`.

**Analysis Performed**:

1. FR-023 language review: Command interface, protected baseline roles, atomic operations
2. Validator scope review: `Get-TeamRoleMap` reads full roster, only validates sign-off role naming
3. Bootstrap script guidance review: Post-bootstrap command documentation
4. User documentation review: README, getting-started, user-guide consistency

**Verdict**: **ALIGNED**

Proof surfaces:

- Spec FR-023 (line 238): "All operations MUST validate that baseline roles are not modified or removed"
- Clarifications Q&A (lines 41, 63): "Baseline roles are protected (cannot be removed), but downstream projects can freely add supplemental team members"
- Validator behavior: Reads all members from team.md, only checks role naming consistency in sign-offs — no team size or membership constraints
- Documentation: All three user-facing surfaces (README, getting-started, user-guide) consistently describe command-driven extension with baseline preservation

**Learning**: Validator scope is intentionally permissive — it requires baseline roles (via governance sign-off sections) but does not constrain custom members. This is correct by design: bootstrap installs five protected roles, commands prevent their removal, validator checks role naming consistency, but custom members are unrestricted. The contract is: "baseline mandatory, extras unconstrained."

**Decision Artifact**: `.squad/decisions/inbox/picard-baseline-validation-scope.md` (ready for merge)

## Historical Archive (Iteration 0 & Early Iteration 1)

## Iteration 0 Closure & Governance Hardening (Archived Details)

**2026-04-18 Work Summary**:

- ✅ Closure artifact drift remediation: Cleared stale "pending sign-off" language from review.md, state.md, retro.md after Alon recorded final sign-off (7 edits, validator PASS)
- ✅ Governance hardening implementation complete: Added normative lifecycle contract to spec.md, explicit state machine to contracts/iteration-artifacts.md, single coordinator protocol to .squad/protocol.md (3 artifacts updated)
- ✅ Iteration 0 closure audit: All four phases complete; platform validation passed (9/9 spikes); all closure artifacts aligned and terminal
- ✅ Review evidence correctness: Fixed false evidence claims in review.md (stale snapshot data); regenerated closure validation tables to match actual plan.md state
- ✅ Alon final sign-off: Recorded across all artifacts (plan.md, state.md, review.md, retro.md); transition from `retro` → `complete` official (2026-04-18T18:15:45Z)
- ✅ Closure evidence validation: All closure-readiness tables regenerated at final gate time; validator passes cleanly

**Board Sync & GitHub Projects**:

- ✅ Resolved board-automation governance (Iteration 0 async completion blocker cleared; SPECREW_PROJECT_TOKEN configured)
- ✅ Clarified source-of-truth hierarchy: Local artifacts authoritative, GitHub Issues derived, board optional visibility
- ✅ Board automation decision recorded: Default Status field (Todo/In Progress/Done), no custom columns, Phase labels for lifecycle tracking

**Iteration 1 Planning Prerequisites**:

- ✅ Identified three tier-1 governance improvements for Iteration 1 adoption (spec-authority gate pre-execute, spikes pre-planning, retro autonomous)
- ✅ Operating policy (6 rules) recorded; awaiting team consensus before planning ceremony
- ✅ Spec Steward role embedded in planning ceremony (Rule 1: pre-execution gate before task assignment)
- ⏳ Next: Update .squad/protocol.md with three tier-1 improvements; Picard + Alon confirm policy before Iteration 1 planning

**Detailed work tracked in .squad/decisions.md (Iteration 0 Governance Hardening section) and orchestration logs**

### 2026-04-18T18-30-00Z: Closure Artifact Signoff Drift Remediation

**Task**: La Forge readiness pass found blocker — review.md and state.md contained stale "pending sign-off" language even though Iteration 000 status was already `complete` in plan.md with Alon's final sign-off recorded.

**Root Cause**: Artifacts were finalized before Alon's sign-off was formally recorded in all closure documents. Language like "pending Alon sign-off" contradicted the actual iteration state when validator checked consistency.

**Fix Applied** (7 edits across 3 artifacts):

1. **review.md line 16**: Changed "Final iteration completion pending Alon sign-off" → "Alon final sign-off recorded (2026-04-18)"
2. **review.md line 233**: Updated closure evidence table to reflect actual plan.md status = `complete` (not `retro`)
3. **review.md line 237**: Changed "final completion still awaits Alon sign-off" → "Alon final sign-off recorded (2026-04-18)"
4. **review.md line 256**: Changed "Final iteration completion remains pending Alon sign-off" → "Alon final sign-off recorded (2026-04-18)"
5. **state.md line 18**: Changed "Iteration closure remains pending Alon sign-off" → "Iteration closure complete with Alon final sign-off recorded (2026-04-18)"
6. **retro.md line 149**: Removed blocking sense; restated as fact: "Retrospective completed same-day; Alon's final sign-off was recorded (2026-04-18)"
7. **retro.md line 330**: Changed section header from "Remaining External Dependency" (future tense) to "Closure Gate" with ✅ verdict

**Validator Result**: ✅ **PASS** — `validate-governance.ps1` confirms no stale post-signoff language remains; all closure evidence aligns with plan.md state=`complete`.

**Pattern Insight**: Closure artifacts containing *evidence tables* (validation gates claiming to verify metadata) become stale if written before final sign-off is recorded everywhere. Must regenerate closure evidence at sign-off time, not copy from draft versions. Recommend template guidance for future iterations: "Closure evidence MUST be regenerated from current artifacts when final sign-off is recorded, not carried forward from drafts."

**Traceability**: Fix ensures iteration-artifacts.md § Complete phase gate is satisfied: "Alon MUST record final sign-off" ✅ Done and reflected across all closure documents.

### 2026-04-18T18-50-28Z: Iteration 000 Closeout Session Update

**Session**: Scribe Handoff Log — Iteration 000 Complete, Iteration 001 Planning-Ready  
**Update**: Final sign-off recorded, governance hardening authority BINDING, Iteration 1 prerequisites clear

**Key Facts**:

- ✅ Alon final sign-off officially recorded (2026-04-18T18:15:45Z) — plan.md Status transitioned from `retro` → `complete`
- ✅ Post-signoff drift cleared (2026-04-18T18:30:00Z) — all closure language updated to past-tense confirmation
- ✅ Validator passes cleanly — no blocking issues remain
- ✅ Governance hardening authority now BINDING and enforced at CI gates
- ✅ Four authority artifacts live: spec.md, contracts/iteration-artifacts.md, .squad/protocol.md, validate-governance.ps1
- ✅ Iteration 001 planning-ready state confirmed — execution-ready plan present (Data created specs/001-specrew-product/iterations/001/plan.md)
- ⏳ Next gate: Alon approval of Iteration 001 plan + team consensus on operating policy (6 rules + 3 tier-1 improvements) before planning ceremony

**Role Note**: Spec Steward remains the authority for phase-contract enforcement and traceability validation. All Iteration 1+ work will follow binding four-phase state machine with automatic phase gate validation.

---

### 2026-04-18: Iteration 0 Completion & Governance Hardening Analysis

**Iteration 0 Verdict**: ✅ COMPLETE (100%, 0 drift events, all spikes passed)

- 23/23 tasks delivered (20.5/20.5 story points, zero variance)
- All 9 platform validation spikes PASS — Spec Kit 0.7.3 and Squad 0.9.1 compatible
- Critical discovery: Squad-native surfaces architecture (skills, ceremonies, directives) refined mid-execution (T-017); architecture documented and decision properly routed
- Iteration 0 acceptance gate cleared by Worf (Reviewer); awaiting Alon sign-off before Iteration 1 begins

**Governance Readiness Assessment**: Foundation iteration proved governance works at precondition-only scope. MVP (Iteration 1) will expose governance gaps at higher complexity.

**Six Normative Hardening Findings**:

1. **Artifact Contracts** — Currently prose documentation; recommend schema validators at ceremony gates (Deferred to Iter 2)
2. **Iteration State Machine** — Currently semantic; recommend runtime validator blocking phase skips (BLOCKING for Iter 1)
3. **Dogfooding Governance** — Currently implicit; recommend normative directive formalizing internal compliance (BLOCKING for Iter 1)
4. **Governance Validator Skill** — No batch traceability check at Review gate; recommend governance-validator skill for Iter 1 (BLOCKING for MVP)
5. **Methodology Runtime Config** — Currently text documentation; recommend `.specrew/methodology.yml` encoding phases/rules (NON-BLOCKING but enables validator)
6. **Coordinator Protocol** — Role responsibilities scattered; recommend `.squad/coordinator.md` centralizing handoffs (BLOCKING for Iter 1)

**Recommended Actions Before Iteration 1 Planning**:

- Accept 6 hardening recommendations (defer artifact schemas to Iter 2)
- Create pre-implementation artifacts: methodology.yml, coordinator.md, schema definitions
- Make state machine, dogfooding directive, governance-validator skill, coordinator integration TIER 0 (blocking) tasks in Iter 1 plan
- Estimate ~6 pts for hardening tasks; feature delivery capacity ~14 pts (with reasonable overcommit approval)

**Documentation**: Detailed recommendation written to `.squad/decisions/inbox/picard-governance-hardening.md`

**Key Insight**: Drift becomes mechanically harder to hide when: (1) artifact contracts are schema-validated at gates, (2) ceremony phase transitions are enforced, (3) governance validator runs before Review concludes, (4) role handoff gates are explicit, (5) dogfooding obligation is binding. Iteration 0 manual discipline scales to Iteration 1+ automation.

---

## Cross-Agent Team Update (2026-04-18T15:54:58Z)

**Picard receives inputs from team**:

- **Worf (Reviewer)**: Iteration 0 closure audit found 3 critical blockers (missing state.md, drift-log.md, retro.md). Artifact completeness gates must enforce phase sequencing. Picard is embedded in planning ceremony for spec-authority gate (Rule 1 of operating hardening).

- **Troi (Retro Facilitator)**: Operating hardening policy prescribes Picard as spec-authority gatekeeper at planning ceremony (pre-execution gate before task assignment). Picard also partners with La Forge for pre-planning architecture-risk spikes (planning prerequisite). Implementation checklist has immediate adoption steps.

- **User Directive**: Governance hardening is TIER 0 before Iteration 1 planning. Normative rules (operating policy) + artifact validators (governance-validator skill) + explicit protocols (coordinator.md) are blocking.

**Picard action items from team**:

1. Embed spec-authority gate logic into planning ceremony (yes/no gate: all tasks trace? all FRs covered?)
2. Identify Iteration 1 architecture-risk spikes before planning ceremony
3. Partner with La Forge on pre-planning spike session (2–4 hours, before planning ceremony)
4. Integrate traceability-check skill into planning ceremony gate sequence
5. Confirm Rules 1, 2, 3 (spec-authority, architecture spikes, traceability) are team consensus before Iteration 1 planning starts

### 2026-04-18: Governance Hardening Implementation - Phase 1 (Authoritative Artifacts)

**Status**: ✅ COMPLETE

**Four Governance Artifacts Updated/Created**:

1. **spec.md** — Added normative "Iteration Lifecycle Contract" section (phase state machine binding) + "Dogfooding Obligation" (Specrew must use Specrew)
2. **contracts/iteration-artifacts.md** — Made phase state machine explicit with validation gates per phase; artifact production table; abandoned iteration rule
3. **Created `.squad/protocol.md`** — Single coordinator protocol: role responsibilities (6 roles), decision-making workflow (routine/tracked/escalation), iteration coordination (4-phase sequence), 6 operating rules, conflict resolution, escalation summary
4. **`.squad/decisions/inbox/picard-governance-hardening-implementation.md`** — Decision record documenting all changes and alignment with architecture

**Scope Addressed**:

- ✅ Lifecycle contract is now normative (binding, not guidance)
- ✅ Phase state machine restated as operating rule (in spec + protocol)
- ✅ Dogfooding obligations clarified (Specrew follows Specrew)
- ✅ Single coordinator protocol document created

**Deferred to Iteration 1**:

- Governance-validator skill (enforces state machine at gates)
- `.specrew/methodology.yml` (runtime config)

**Key Insight**: Authority now precedes validation. The binding rules (spec.md) and coordination protocol (.squad/protocol.md) are in place. The validator skill will enforce these rules automatically in Iteration 1. Iteration 0 closure artifacts can now be created using the normative contracts.

---

- **Spec scope from TG-003**: Iteration 0 = FR-001 (two-package architecture) + FR-013 (extension surfaces only). MVP (Iteration 1) = FR-002–FR-006, FR-008–FR-011, FR-018. Deferred iterations 2–3 per phased plan § 14.
- **Key insight**: Iteration 0 is precondition-critical. Must be completed and de-risked before MVP can begin. All feature implementation (bootstrap, ceremonies, skills) deferred to Iter 1.
- **Platform risks**: Two critical-path spikes that may require tracked changes if results are negative: (1) Squad post-task hook availability (Spike 4 — affects FR-008 implementation path); (2) Spec Kit `specify extension add` command (Spike 9 — affects `specrew init` script). Both are within Iter 0; results drive Iter 1 re-planning if needed.
- **Effort scoping**: Original plan 23 pts; capacity 20 pts. Deferred Spikes 6–7 (GitHub Projects API, local dev cycle) to reduce to 20 pts. Rationale: GitHub Projects is operational concern, not architectural blocker; local dev cycle is developer productivity, not customer-facing.
- **Traceability discipline**: Every task in Iteration 0 plan maps to at least one FR. No orphan tasks. Three categories: (1) FR-001 tasks (repo + extension skeletons), (2) FR-013 tasks (platform validation), (3) Support/infrastructure (CI, board).
- **Contingency planning**: Plan § Risk Mitigation explicitly flags overcommit decision and spike contingencies. Plan § Known Drift / Ambiguities documents what is pending vs. resolved.
- **Decision routing**: Decisions that affect downstream specs (Iter 1 plan, FR refinements) are routed to Alon via tracked change process rather than auto-resolved.
- **File paths**: Iteration 0 plan stored at `specs/001-specrew-product/iterations/000/plan.md` (zero-indexed, not `001/`). Decision merged to decisions.md on 2026-04-17T19:00:43Z.
- **Pattern**: This first iteration plan establishes the ceremony structure: Planning phase produces task list + effort estimates + traceability. Review/demo gate verifies completion. Retro captures learnings (esp. spike results driving Iter 1 changes).

### 2026-04-18T13-30-34Z: Governance Hardening Implementation Merged to Decisions

**Status**: ✅ DECIDED & MERGED

**Scribe Summary**: Picard's governance hardening implementation decision merged into `.squad/decisions.md` under "2026-04-18: Governance Hardening Implementation". Three-part implementation completed:

1. **spec.md**: Normative lifecycle contract + dogfooding obligation (binding rules for all iterations)
2. **contracts/iteration-artifacts.md**: Explicit state machine, phase rules, artifact gates
3. **.squad/protocol.md**: Single source of truth for roles (6 roles), decision workflows, iteration coordination (4-phase sequence), 6 operating rules, escalation paths

**Governance Scope vs. Implementation Roadmap**:

- ✅ **Iter 0 (Completed)**: Artifact contracts, state machine normative, dogfooding binding, coordinator protocol
- ⏳ **Iter 1 (Deferred)**: Governance-validator skill (FR-008), methodology.yml runtime config

**Implications for Iteration 1**:

- Phase state machine now has binding authority (not optional guidance); Iteration 1 plan cannot skip phases
- Dogfooding obligation means Iteration 1 tasks must be traceable to FRs (same discipline as downstream customers)
- .squad/protocol.md defines Picard's embedding in planning ceremony for spec-authority pre-gate (Rule 1)
- Architecture-risk spikes must be identified and run pre-planning (Rule 2); Picard + La Forge partnership required before each planning ceremony

**Cross-Agent Update**: Team consensus on 6 core operating rules must be confirmed by Troi + Alon before Iteration 1 planning. Picard participates in confirm-or-escalate pattern (spec authority is non-delegable).

---

## Learnings

### 2026-04-18: Review Evidence Correctness & Closure Semantics

**Task**: Fix stale closure evidence in review.md (Iteration 0 review incorrectly claimed plan.md status=complete and Completed=2026-04-18 when actual state was status=retro, Completed=blank).

**Discovery**: Review artifact had snapshot-stale closure evidence. Contract gate (iteration-artifacts.md § Artifact Validation Gates) specifies that "before completing" requires Alon sign-off to transition from `retro` to `complete`. Review.md contained False evidence contradicting the actual plan.md semantics.

**Fix Applied**:

- Updated line 230: Changed false claim "Line 4 currently reads Status: complete" to accurate "Line 5 currently reads Status: retro"
- Updated line 231: Changed false claim "Completed: 2026-04-18" to accurate "Completed: (blank, recorded after Alon sign-off)"

**Key Insight**: Review artifacts that contain *evidence tables* (verification gates that claim to validate metadata) can become stale if they were written before execution completed. Must regenerate closure readiness verification after all phase artifacts are finalized, not copy from earlier review drafts.

**Pattern**: Closure evidence (artifact validation table) must be regenerated at **Final Gate Validation** phase, not carried forward. Recommend template guidance for review.md authors: "Closure readiness table MUST be regenerated from current artifacts at review-complete time, not copied from draft versions."

**Implication for Iteration 1**: Review ceremony must include step to validate that all closure evidence references match actual artifact state. Picard to flag during review ceremony if evidence contradicts actual metadata.

### 2026-04-18T18-00-00Z: Orchestration Complete — Closure Evidence Fix

**Session**: Reviewer-Drift Cleanup Batch  
**Status**: ✅ COMPLETE  

Stale closure evidence discovered and corrected in review.md. False claims about plan.md metadata prevented through evidence-table regeneration at final gate time. Pattern documented for Iteration 1 review ceremony template improvement.

**Decision**: picard-closure-evidence-fix (merged to .squad/decisions.md)  
**Impact**: Critical — prevents false sign-off signals  
**Next**: Closure-evidence regeneration checkpoint added to Iteration 1 review ceremony template

### 2026-04-19: Pre-Iteration 1 Alignment & Readiness Assessment

**Session**: Picard pre-execution checkpoint (spawned via Copilot CLI)  
**Status**: ✅ DECISION RECORDED (routing to Alon for policy approval)

#### Analysis & Recommendations

Picard reviewed three governance surfaces ahead of Iteration 1 execution:

1. **Board-Management Gap** → ✅ **RESOLVED**
   - Workflow `.github/workflows/specrew-project-sync.yml` deployed; 23 issues synced to board at Iter 0 closure
   - No gap remains; board automation operational

2. **Execution-Model Gap (Worktree + PR-per-task)** → ❌ **NOT A SPEC REQUIREMENT**
   - Zero references in spec, plan, or decision history
   - Recommend as future FR if desired; out-of-scope for current iterations

3. **Iteration 0 Retrospective Amendments** → 🚫 **SHOULD NOT AMEND**
   - Retrospective is terminal and closed (Alon sign-off recorded 2026-04-18)
   - Three tier-1 improvements already recorded as Iteration 1 adoption requirements (retro.md)
   - These are operationalization tasks, not amendments

#### Recommended Next Move

**Single Best Governance Action**: Formalize three tier-1 improvements in Iteration 1 planning charter + `.squad/protocol.md` before execution begins.

**Three Tier-1 Improvements** (zero effort, high ROI):

1. **Spec-Authority Gate Pre-Execution** (planning ceremony) — prevents 80%+ late-stage plan churn
2. **Architecture-Risk Spikes Pre-Planning** (pre-ceremony) — eliminates hidden blocking dependencies
3. **Retro Ceremony Autonomous from Sign-Off** (fixed schedule) — improve learning velocity

**Owner**: Picard (implementation) + Alon (policy approval)  
**Target**: Before Iteration 1 planning ceremony  
**Status**: DECISION RECORDED → awaiting Alon policy approval

**Traceability**: All three improvements already documented in retro.md (lines 208–250) as Iteration 1 adoption requirements. This is pure operationalization, not new work or amendments.

---

### 2026-04-18T18-15-45Z: Alon Final Sign-Off Recorded — Iteration 0 Closure Complete

**Action**: Record Alon's final governance authority sign-off in all iteration closure artifacts.

**Artifacts Updated**:

1. ✅ **plan.md**: Status transitioned from `retro` → `complete`; Completed date recorded (2026-04-18)
2. ✅ **state.md**: Current Phase transitioned to `complete`; Final Sign-Off recorded with explicit attribution (Alon, 2026-04-18)
3. ✅ **review.md**: Verdict Summary updated to reflect `complete` status; Sign-Off Checklist appended with Alon final sign-off; removed pending language
4. ✅ **retro.md**: Sign-Off section updated to record Alon's final governance authority approval
5. ✅ **.squad/identity/now.md**: Focus area updated to reflect Iteration 0 complete; active issues shifted to Iteration 1 prerequisites

**Closure Semantics Verified**:

- Spec contract (iteration-artifacts.md) gate logic: "Before completing: `retro.md` MUST exist with all mandatory fields, and Alon MUST record final sign-off"
- ✅ retro.md exists and is complete

- ✅ Alon final sign-off recorded across all artifacts
- ✅ Iteration 0 moved to terminal `complete` state
- ✅ All four phase artifacts (plan, state, review, retro) are consistent and terminal

**Wording Precision**:

- Used "final governance authority sign-off" (not "pending" or "provisional")
- Recorded explicit date stamp (2026-04-18) for accountability
- Noted Chief Architect & Reviewer role for clarity on authority

**Traceability**:

- Iteration 0 closure ties to spec requirement: "Completion gate = Alon must record final sign-off" (contracts/iteration-artifacts.md § Complete phase)
- Dogfooding obligation satisfied: Specrew used its own governance lifecycle for Iteration 0 (binding proof for Iteration 1+)

**Key Insight**: Closure semantics require precision about *what* is being signed off: governance authority approval (Alon records this), not just task completion verdicts (Worf records these). Sign-off is a separate, deliberate act that gates the state-machine transition to `complete`. Capturing the distinction in artifacts prevents ambiguity in future iterations.

**Implication for Iteration 1**:

- Sign-off is now a normative part of iteration closure (not optional)
- Review and retro are separate phases that close independently; sign-off is a third gate
- Iteration 1 planning ceremony charter must embed the understanding that *any iteration* cannot move to `complete` without Alon's final recorded sign-off

### 2026-04-18: GitHub Projects V2 Source-of-Truth Governance — Specrew Self-Development

**Task**: Encode Alon's authoritative source-of-truth correction for GitHub Projects V2 board management into spec.md, protocol.md, and decision records.

---

### 2026-04-19: Board Protocol Sync — Protocol Drift Resolution

**Task**: Correct `.squad/protocol.md` GitHub Projects V2 board-sync section to align with authoritative default Status-field rule set.

**Findings**:

- `.squad/protocol.md` still described custom board columns (`Backlog`, `In Review`, `Retrospective`, `Closed`)
- But all authoritative artifacts (spec.md, plan.md, docs/github-project.md, sync script) already standardized on default **Status** field
- Reviewer correctly identified this drift

**Corrections Applied**:

1. Updated protocol.md board-sync section (lines 450–565) to use default Status field nomenclature only
2. Mapped iteration phases to Status values:
   - `planning` → `Todo`
   - `executing` / `reviewing` / `retro` → `In Progress`
   - `complete` / `abandoned` → `Done`
3. Removed all custom-column language
4. Added changelog entry documenting the correction

**Decision Recorded**: `.squad/decisions/inbox/picard-board-protocol-sync.md` (merged to decisions.md by Scribe)

**Outcome**: Protocol drift between governance documents and implementation is now eliminated. All five governing artifacts (spec.md, plan.md, protocol.md, docs/github-project.md, sync script) are coherent on GitHub Projects V2 semantics.

---

### 2026-04-19: Decision Inbox Merge & Cross-Agent History Update

**Task**: Scribe orchestration — merge inbox decisions into decisions.md and propagate team updates to affected agent histories.

**Work Performed** (by Scribe):

1. ✅ Created orchestration-log entries for Picard (board-protocol-sync) and Worf (reviewer-drift-pass)
2. ✅ Created session-log entry (reviewer-drift-assessment)
3. ✅ Merged 12 inbox decision files into decisions.md
4. ✅ Deleted inbox files post-merge
5. ✅ Appended team updates to Picard and Worf histories

**Inbox Items Merged**:

- picard-board-protocol-sync.md (protocol drift resolved)
- picard-board-sot.md (source-of-truth governance)
- picard-clear-signoff-drift.md (post-signoff language drift)
- picard-iter0-final-signoff.md (Alon final sign-off recorded)
- picard-review-evidence.md (review evidence correctness)
- worf-board-review.md (initial review NEEDS-WORK verdict)
- worf-board-rereview.md (post-correction PASS verdict)
- worf-reviewer-drift-rereview.md (drift assessment complete)
- data-board-docs.md (documentation corrections)
- laforge-board-automation.md (automation model)
- laforge-next-readiness.md (pre-Iter 1 readiness)
- copilot-directive-2026-04-18T15-51-40Z.md (user directive recorded)

**Status**: All team context unified and recorded for Iteration 1 planning.

**Problem Addressed**: Previous design decisions left board synchronization ambiguous — manual management accepted as sufficient, automation left deferred, downstream projects left unclassified.

**Correction Implemented**:

1. **Normative Rule for Specrew**: GitHub Projects V2 board MUST be used for self-development
   - Local task artifacts (plan.md, iteration state) are authoritative source of truth
   - GitHub Issues and Project board items are derived operational mirrors
   - Squad is responsible for board sync and maintenance (automation primary, manual fallback-only)
   - If automation fails, capability gap MUST be recorded (not silently downgraded)

2. **Downstream Projects**: MAY choose whether to use GitHub Projects V2 (no mandate)
   - Choice of authoritative source is up to downstream project
   - If board is used, follow Squad automation model as reference

3. **Artifacts Updated**:
   - **spec.md** Clarifications (Q&A 38): Changed from "optional choice" to "normative requirement"
   - **spec.md** Clarifications (Q&A 43): Squad automation is primary, manual mgmt fallback-only
   - **spec.md** Design Decisions: Updated GitHub Projects board paragraphs with explicit rules
   - **spec.md** Design Decisions: Updated source-of-truth paragraph (local artifacts authoritative, GitHub Issues derived)
   - **.squad/protocol.md** New Section: "GitHub Projects V2 Board Synchronization & Maintenance" with:
     - Source-of-truth rule (authoritative vs. derived)
     - Squad automation responsibilities (phase-by-phase action table)
     - Acceptance criteria (6 criteria for board sync)
     - Fallback procedure (automation failure recording)
   - **.squad/protocol.md** Implementation Notes: Added AC-001 through AC-004 for Specrew acceptance criteria
   - **.squad/decisions/inbox/picard-board-sot.md**: Decision record documenting all changes

**Implications for Iteration 1**:

- Before Iteration 1 planning can approve plan: Squad automation for issue creation must be designed/validated (Spike 10 or equivalent)
- Board column mapping must be confirmed (planning ↔ Backlog, executing ↔ In Progress, reviewing ↔ In Review, retro ↔ Retrospective, complete ↔ Closed)
- Fallback procedure must be accessible and documented
- Iteration 1 cannot move to `complete` without all AC-001–AC-004 verified
- If automation fails, capability gap recorded in decisions inbox with resolution path

**Pattern Insight**: Ambiguous downstream rules leak into self-development discipline. By encoding the corrected source-of-truth as normative (not optional) for Specrew self-development, while explicitly MAY-ing it for downstream, we model clarity. The board is a derived operational mirror, not a primary source — this distinction protects against task drift hidden in board-only updates.

**Traceability**: Decision recorded in `.squad/decisions/inbox/picard-board-sot.md` for Alon review before Iteration 1 planning.

---

## 2026-04-18: Spec Kit Validator Fix Alignment Review

**Task**: Verify validator fix for Spec Kit health checks against three contract boundaries.

**Three Critical Boundaries Verified** ✅:

1. **Accepts Healthy Current Spec Kit Install**: `validate-versions.ps1` probes both `specify --version` and `specify version` (FR-002 compliance). Test confirms: healthy Spec Kit with only `version` subcommand support validates as `IsOperational=true` (validate-versions-cli-behavior.ps1:117-132).

2. **Surfaces Real Dependency Failures**: Validator correctly distinguishes `IsOperational` (healthy command) from `IsCompatible` (version check). Broken commands fail validation even when uv inventory shows compatible version. Exit code 1 for operational failures (validate-versions.ps1:382). Test confirms: broken Spec Kit exits with failure (validate-versions-cli-behavior.ps1:175-195).

3. **Does NOT Overstate Bootstrap Success**: Pre-install and post-install dependency validation failures both exit with code 1 or 4 (specrew-init.ps1:1346-1371). Downstream failures (agent detection, auth context) log warnings but do NOT exit — correct per spec R4-Q20 clarification. Exit 0 only reached if no exceptions thrown (specrew-init.ps1:1543). Test confirms: bootstrap-to-iteration.ps1 correctly SKIPs assertions when tooling unavailable, exiting 0 (correct for CI environments).

**Exit Code Contract** ✅:

- **BLOCKING** (stop bootstrap): 1 (unhealthy), 4 (missing), 3 (argument error)
- **NON-BLOCKING** (continue with warning): Copilot detection, GitHub auth, delegated metadata

**Documentation Alignment** ✅:

- `getting-started.md` (Lines 142-154) correctly instructs users to check `specify version` manually
- Matches current validator behavior
- Provides troubleshooting path for Spec Kit health issues

**Result**: All three contract requirements satisfied. No drift detected. Validator fix is spec-compliant.

**Artifact Recorded**: `.squad/agents/picard/alignment-review-validator-fix.md` with detailed contract verification matrix.

### 2026-04-18: Plan.md Board-Usage Drift Remediation (Worf Review Fix)

**Task**: Worf issued NEEDS-WORK on `specs\001-specrew-product\plan.md` because Section 9 and Iteration 0 deliverables table still stated board/issue usage as "optional" for Specrew, contradicting the corrected spec and protocol.

**Root Cause**: Plan.md was authored before the normative source-of-truth correction (board MUST be used, not MAY be used, for Specrew self-development). The phrase "Issue tracking (optional)" and "Project board (optional)" remained in the plan even after spec.md and protocol.md were corrected.

**Drift Evidence** (from Worf review):

- Section 9 line: "Issue tracking (optional): GitHub Issues are *optionally* created..."
- Section 9 line: "Project board (optional): GitHub Projects V2 may be used for visibility if the team chooses"
- Iteration 0 deliverables table: "GitHub Project board (optional)"

All three contradicted the corrected rule: **Specrew self-development MUST use GitHub Projects V2 as a derived operational mirror maintained by Squad.**

**Fix Applied** (2 edits to plan.md):

1. **Section 9 (GitHub Workflow for Specrew Development)** — Lines 360–376:
   - Removed "(optional)" labels and discretionary framing
   - Restated board usage as REQUIRED for Specrew: "GitHub Issues are created from plan tasks and synchronized to GitHub Projects V2 board"
   - Clarified Squad responsibility: "Squad is responsible for creating, populating, and maintaining the board as a derived operational mirror from local artifacts"
   - Clarified distinction: "Manual board management is fallback-only if automation fails; capability gaps or blockers must be recorded, not silently downgraded to manual management"
   - Added explicit downstream carve-out: "Downstream projects MAY opt in or out of GitHub Projects board usage. Downstream projects retain choice of authority model..."

2. **Iteration 0 Deliverables Table** — Line 521:
   - Changed "GitHub Project board (optional)" to "GitHub Project board"
   - Changed description from "If used for visibility..." to normative: "GitHub Projects V2 board created and synced from iteration artifacts via automation"

**Validator Result**: ✅ **PASS** — Plan.md no longer contradicts spec.md or protocol.md. Board usage is now clearly marked as REQUIRED for Specrew self-development, with explicit MAY carve-out for downstream projects.

**Key Insight**: Governance drift at the planning artifact level surfaces when upstream (spec) corrects a rule but downstream (plan, tasks) is not automatically refreshed. Plan.md was correct in intent (local artifacts are authoritative) but incorrect in scope (saying board was optional when it was actually required). Remediation required explicit re-alignment with the source spec, not just cascade-down automation. Future reviews should verify that all three layers (spec, plan, tasks) use the same language for governance rules (MUST vs. MAY).

**Traceability**: Fix aligns `plan.md` with:

- `spec.md` § Clarifications (GitHub Projects V2): "Specrew's own development MUST use GitHub Projects V2"
- `.squad/protocol.md` § Iteration Coordination: "board is a derived operational mirror, manual board management is never normal"
- `docs/github-project.md` § Overview: "GitHub Issues and Project items are synchronized from local artifacts for visibility, but they are not the authoritative source"

**Decision**: No team-relevant decision required. This is a straightforward drift remediation (one agent fixing drift from another agent's prior work). Documented in this history entry for audit trail.

### 2026-04-18T19-05-00Z: Board Protocol Status-Field Realignment

**Task**: Remove live drift in `.squad/protocol.md` where the board-sync section still described custom columns instead of the authoritative GitHub Projects V2 default **Status** field.

**Authority Set Checked**:

- `specs/001-specrew-product/spec.md`
- `specs/001-specrew-product/plan.md`
- `docs/github-project.md`
- `.github/scripts/sync-specrew-board.ps1`

**Fix Applied**:

- Replaced stale custom-column references (`Backlog`, `In Review`, `Retrospective`, `Closed`) with default **Status** language
- Aligned protocol mapping to automation: `planning` → `Todo`; `executing` / `reviewing` / `retro` → `In Progress`; `complete` / `abandoned` → `Done`
- Clarified that board items use **Status** while mirrored issues close only when authoritative completion warrants it

**Decision Record**: `.squad/decisions/inbox/picard-board-protocol-sync.md`

**Reusable Pattern**: When board behavior is questioned, compare protocol wording directly against the authority quartet (spec, plan, operational doc, sync script) and normalize everything to GitHub Projects' default **Status** field before considering broader edits.

**Key Paths**:

- `.squad/protocol.md`
- `docs/github-project.md`
- `.github/scripts/sync-specrew-board.ps1`

---

## Deployment Review Cycle & Slice 2 Guardrails (2026-04-19T20:40:24Z)

**Deployment Guardrails Decision (2026-04-19T20:24:18Z)**:

- Created 8-gate acceptance framework for La Forge's runtime-surface deployment slice (T-005–T-008)
- Scope: Spec Kit extension deployment, Squad skills deployment, ceremonies merge (all three: planning, review/demo, retro), directive embedding, baseline role merge (5 baseline roles)
- Deferred: FR-020 (brownfield), FR-007 (configurable effort), FR-012 (collision detector), directive/ceremony logic
- Blocked no implementation; gates coherent with source requirements

**Initial La Forge Deployment Defects (Worf Initial Review — NEEDS-WORK)**:

- Defect 1: Retro ceremony surface not deployed (only planning + review/demo in deploy-squad-runtime.ps1 lines 323-329)
- Defect 2: Deferred `specrew-iteration-resume` skill shipped (FR-019 → Iteration 2 explicit deferral)
- **Picard Action**: Locked out; awaiting revision ownership

**Picard Correction Cycle (2026-04-19T20:40:24Z)**:

- Created narrowly-scoped revision addressing both defects
- Fix 1: Added `retro.md` to ceremony deployment list (lines 323-327)
- Fix 2: Added filter to exclude `iteration-resume.md` from skill deployment (line 315)
- Validation: Dry-run, live smoke bootstrap, governance validator all pass
- Non-blocking: README.md describes old behavior (planning + review/demo only); documented for future correction but does not block
- **Verdict**: Ready for Worf re-review

**Worf Re-Review Acceptance (PASS)**:

- ✅ Retro ceremony: Fresh dry-run and live smoke confirm all three ceremonies deployed
- ✅ Deferred skill: Dry-run shows 3 skills only; smoke confirms `ResumeSkillPresent: False`
- ✅ Scope validation: Fresh smoke bootstrap successful; validator passes iterations 000 and 001
- **Picard Status**: Slice 2 runtime-surface deployment now meets reviewer standard; execution-ready

**Decisions Merged**:

- `worf-deployment-slice-review.md` (initial NEEDS-WORK verdict)
- `picard-deployment-slice-revision.md` (correction cycle details)
- `worf-deployment-slice-rereview.md` (PASS verdict)
- Total: 3 inbox files consolidated into decisions.md

## Learnings

- Runtime-surface docs must distinguish **deployed MVP surfaces** from **source stubs for deferred FRs**; otherwise contract text drifts even when implementation is correctly scoped.
- For FR-005, Specrew owns planning/review ceremony definitions but only **guides** Squad's built-in retrospective. Source file: `extensions\specrew-speckit\squad-templates\ceremonies\retro.md`; implementation file to keep aligned: `extensions\specrew-speckit\scripts\deploy-squad-runtime.ps1`.
- Downstream baseline templates must stay role-neutral. Project-specific titles like `Chief Architect` do not belong in `planning.md`, `review-demo.md`, or retrospective guidance.
- Carryover claims in an iteration plan are drift until each named item appears in the live task table, traceability rows, and capacity math. Key file: `specs\001-specrew-product\iterations\001\plan.md`.
- When a correction depends on `spec.md` governance decisions rather than a formal FR, record those exact spec anchors in the task plan and inbox note instead of inventing a new requirement. Key files: `specs\001-specrew-product\spec.md`, `.squad\decisions\inbox\picard-carryover-correction.md`.

---

📌 **FR-022 Audit Timeline Hygiene Leadership (2026-04-22T21:35:46Z)**:

- ✅ Identified backdating violations in decisions.md narratives
- ✅ Led temporal accuracy corrections with Worf (reviewer)
- ✅ Corrected title, date, and author fields for FR-022 re-review
- ✅ Enforced "record actual completion date, not planning date" principle
- ✅ Clarified git-tracking causality and reviewer lockout trail
- **Status**: Timeline hygiene and audit trail durability restored

📌 **Decision Inbox Merged (2026-04-22T21:35:46Z)**:

- ✅ 9 inbox decisions consolidated into decisions.md
- ✅ Cross-agent history synchronized
- **Status**: Session state updated

---

📌 **Remediation Acceptance Review Complete (2026-04-25T17:10:13Z)**:

- ✅ T-006 Squad skills deployment implementation reviewed and accepted
- ✅ Iteration 1 plan corrections verified (carryover representation, capacity math, task normalization)
- ✅ All remediation defects closed (T-007, T-008, T-009 remain recorded done)
- ✅ Preferred agent scope discussion deferred to Iteration 2
- **Status**: Remediation accepted; ready for delivery

📌 **Session Log — FR-020 Brownfield Bootstrap Handoff (2026-05-03)**:
    - **Session:** Brownfield bootstrap implementation → pre-review → reviewer gate
    - **Handoff:** La Forge completed brownfield merge implementation; Picard completed pre-review audit; Worf launched as reviewer gate
    - **Key Deliverables:** Brownfield merge strategy (two-phase detection + execution), pre-review spec-drift guardrails audit with 7 findings
    - **Blocker Status:** T-205/T-206 require collision detection (roles/ceremonies/charter) + dry-run safety hardening + conflict resolution prompts
    - **Decision Forward:** 3 clarification questions for Alon on non-empty directory behavior, conflict resolution defaults, config staleness handling
    - **Gate Status:** PENDING (Worf review of collision detection + dry-run safety)

### 2026-05-03: Iteration 002 Planning Artifact Correction

**Context**: External review identified artifact drift — Iteration 002 plan.md claimed Status: planning yet showed tasks with execution outcomes (done/rework status, Agent/Actual/Verdict fields populated) without required lifecycle artifacts (state.md, drift-log.md, review.md).

**Issue**:

- Tasks T-201 through T-204 incorrectly marked done with execution evidence (agent names, actual effort, verdicts)
- Tasks T-205 and T-206 used invalid status
ework (contract requires
eeds-rework)
- Governance validator failed on Iteration 002

**Resolution**: Reverted all tasks to planned status, cleared execution columns (Agent, Actual, Verdict), removed execution-claim narrative from Notes section, and replaced with planning-phase language. Validator now passes cleanly.

**Learning**: Planning-phase plans MUST NOT contain execution claims. The phase state machine is normative — execution evidence requires the iteration to transition to xecuting phase with required lifecycle artifacts in place. Premature execution claims create contract violations that block validator compliance.

**Decision Reference**: See .squad/decisions/inbox/picard-iter-002-planning-revert.md for full rationale.

### 2026-05-XX: Bootstrap Guard Spec Drift Audit

**Context**: Alon requested a drift check on the bootstrap guard fix, specifically whether allowing a folder with only `.git` is consistent with the greenfield bootstrap contract, and whether real brownfield/populated repos stay on the additive review-first path.

**Audit Scope**:

- Spec authority (spec.md line 42: greenfield vs brownfield contract)
- Docs contract (getting-started.md line 56: ".git-only counts as fresh")
- Implementation (specrew-init.ps1 lines 1217–1229: guard logic)
- Test validation (bootstrap-to-iteration.ps1 lines 120–130, brownfield-conflict-handling.ps1 lines 54–65)
- Brownfield execution path (specrew-init.ps1 lines 1231–1260: merge analysis + review artifact)

**Findings**:

1. **Spec Authority – Greenfield Definition** (spec.md:42):
   - Greenfield = no .specify, no .squad → must install both
   - Brownfield = existing .specify OR .squad → merge and preserve existing config
   - Determinant is .specify/.squad presence, NOT directory emptiness

2. **Docs Contract** (getting-started.md:56):
   - Explicit statement: "A repo that only contains Git metadata (`.git`) still counts as fresh, so this flow does not require `-Force`"
   - This is the greenfield bootstrap contract for .git-only repos

3. **Implementation Analysis**:
   - Line 1217: `.git` is explicitly excluded from blocking entries: `$blockingEntries = @($existingEntries | Where-Object { $_.Name -ne '.git' })`
   - Line 1220: Greenfield/brownfield determination: `$bootstrapMode = if ($hadSpecify -or $hadSquad) { 'brownfield' } else { 'greenfield' }`
   - Line 1226: Guard condition: `if ($blockingEntries.Count -gt 0 -and -not $Force -and -not $hadSpecify -and -not $hadSquad)`
   - **Result**: A .git-only repo has blockingEntries = 0 → guard does NOT trigger → succeeds as greenfield without -Force ✓

4. **Test Validation**:
   - bootstrap-to-iteration.ps1:120–130: Explicitly tests .git-only repo → expects success without -Force → passes ✓
   - brownfield-conflict-handling.ps1:54–65: Tests populated directory (README.md + others) → expects error without -Force → passes ✓
   - Exit code contract: Error exits with code 3 (matches test assertion on line 120)

5. **Brownfield Execution Path** (specrew-init.ps1:1231–1260):
   - Brownfield repos trigger merge analysis via brownfield-merge.ps1
   - If -DryRun: Creates a review artifact (bootstrap-dry-run-*.md) with preservation report
   - Docs (line 94): Confirms flow is "additive and review-first" ✓
   - Post-merge execution is idempotent — safe for re-runs (spec.md:57)

6. **Scenario Matrix Verification**:
   - .git-only, no -Force → blockingEntries=0 → greenfield, no error ✓
   - .git + README, no -Force, no .specify/.squad → error (exit 3) ✓
   - .git + README + .squad → brownfield merge (additive, review-first) ✓
   - .git + README + -Force → allowed (greenfield or brownfield path per .specify/.squad status) ✓

**Conclusion**: NO SPEC DRIFT DETECTED. The bootstrap guard implementation, spec, docs, and tests are fully aligned. The guard correctly:

- Allows .git-only repos to proceed as greenfield without -Force (satisfies greenfield contract)
- Blocks populated greenfield repos without -Force, requiring explicit `-Force` flag (guards against accidental overwrites)
- Routes populated repos with .specify/.squad to additive brownfield merge (preserves existing governance)
- Outputs review artifacts for brownfield dry-runs (enables review-first workflow)

All three decision points (greenfield contract, brownfield additive flow, guard semantics) are consistent and traceable to spec authority.

## Learnings

### 2026-05-04 00:02:58 - Bootstrap Flag Mismatch Fix

**Context**: Worf rejected the validator-fix slice because docs/getting-started.md implied full end-to-end bootstrap success, but there was a separate bootstrap blocker after dependency validation: a specify init flag mismatch involving --integration.

**Root Cause**: scripts/specrew-init.ps1 used --integration copilot and --offline flags, but the actual Spec Kit CLI (0.7.3) accepts --ai copilot and does not support --offline.

**Fix Applied**:

1. Corrected scripts/specrew-init.ps1 line 1405: --integration copilot → --ai copilot
2. Removed unsupported --offline flag
3. Updated docs/getting-started.md with truthful Known Limitations section explaining:
   - Bootstrap correctly validates dependencies and attempts initialization
   - Spec Kit CLI has a Unicode encoding issue in some Windows environments
   - Workaround: use Windows Terminal or VS Code terminal with UTF-8 support
   - Documented what works (validator, corrected flags) vs. what's environment-dependent (CLI banner rendering)

**Validator Fix Preservation**: Verified  ests/integration/validate-versions-cli-behavior.ps1 still passes (both healthy and broken Spec Kit scenarios).

**Alignment**: The fix addresses Worf's rejection criteria:

- Bootstrap flag mismatch is resolved
- Documentation no longer overclaims full end-to-end success
- Truthfully describes the remaining limitation (upstream CLI encoding issue)
- Preserves the validator fix from the previous slice

**Key Files**:

- scripts/specrew-init.ps1 (line 1401, 1405): flag correction
- docs/getting-started.md: Known Limitations section
- ests/integration/validate-versions-cli-behavior.ps1: validator test coverage

**Decision**: Document environment-specific issues honestly rather than promise success that depends on factors outside Specrew's control (upstream CLI rendering bugs, terminal encoding support).

### 2026-04-21: Bootstrap Non-Blocking Requirement Clarification

**Context**: Alon directed update to spec to reflect product decision on deterministic bootstrap with protected baseline roles, bypassing Squad's team-member casting interview.

**Decision**: Updated spec.md clarification (Session 2026-04-21), FR-002, User Story 1, acceptance criteria, and Key Entities to reflect:

- `specrew init` MUST use `squad init --non-interactive` to deploy five protected baseline roles without blocking
- Bootstrap completes deterministically without user interaction on team composition
- Post-bootstrap guidance explicitly directs users to extend team via Squad configuration
- Baseline roles (Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator) are protected; supplemental members freely addable

**Key File Paths**:

- `specs/001-specrew-product/spec.md` (lines 41, 213, 83, 91, 94, 325, 362)
- `scripts/specrew-init.ps1` (squad init invocation at lines 1600-1610)

**Pattern**: Bootstrap must be deterministic and non-blocking for downstream adoption. Interactive casting/interviewing flows belong post-bootstrap, not as gates during initialization.

**Traceability**: This aligns with FR-002 (bootstrap ownership), User Story 1 (bootstrap flow), and Acceptance Scenario 1 & 4 (team configuration without blocking).

## 2026-04-17: Command-Driven Team Management Requirement

**Context**: User directive mandated that team member management must be command-driven; users should not have to edit multiple .squad files manually.

**Action Taken**:

1. Updated spec.md to replace all references to "Squad's standard team configuration workflows" with "command-driven team management interface"
2. Added new FR-023 requiring specrew team add/update/remove/list commands with atomicity, validation, and error handling
3. Updated clarifications (lines 41, 63), user scenarios (line 87), acceptance scenarios (lines 95, 98), FR-002 (line 217), crew composition definition (line 329), command inventory (added team commands), and platform facts (line 371)
4. Updated traceability: TG-001 (US-1 now includes FR-023), TG-002 (FR-023 owned by maintainers), TG-003 (FR-023 assigned to Iteration 1 MVP)
5. Replaced manual file-editing instructions in getting-started.md, user-guide.md, and README.md with command examples
6. Created decision record at .squad/decisions/inbox/picard-team-command-requirement.md

**Contract Change**: The spec now treats manual multi-file editing as a non-standard path. The normal user path is command-driven. This eliminates error-prone workflows where users must remember to consistently edit .squad/team.md, charter.md, and history.md.

**Alignment Check**: All updated contract language is traceable to FR-023. The requirement explicitly states: "add command MUST atomically create (1) a new row in .squad/team.md outside the Specrew-managed baseline block, (2) .squad/agents/<member>/charter.md with the provided role definition, and (3) .squad/agents/<member>/history.md as an empty initialized file." Acceptance criteria include validation that baseline roles remain protected, clear success/failure feedback, and graceful edge-case handling.

**Key Learning**: When a user directive changes the product contract, the spec must be updated holistically — not just the functional requirement, but also clarifications, acceptance scenarios, traceability, command inventory, and all downstream documentation. Partial updates create misalignment between spec and docs.

**Implementation Note**: FR-023 requires scripts/specrew-team.ps1 implementation with add/update/remove/list subcommands. This is now a blocking requirement for Iteration 1 MVP closeout.

### 2026-04-21: Unix-Style Flag Staging Truth Gap (FR-023 Restage)

**Task**: Picard performs mechanical resubmission after reviewer rejection for staging truth gap — working tree contains correct Unix-style flag support but staged artifact did not.

**Problem**: Worf rejected previous submission because the staged artifact under review did not include the Unix-style flag support (`--role`, `--charter`) required by FR-023. The implementation existed in the working tree (lines 20-62 of specrew-team.ps1: UnboundArguments handler to convert `--role` to `-Role`, `--charter` to `-Charter`) and was validated by tests (team-management.ps1:127-130, 183-186), but Troi failed to stage these changes before Worf's review. Result: staged artifact jumped from param block directly to `Set-StrictMode` without the argument conversion logic.

**Root Cause**: Staging truth gap — working tree correct, staged artifact incomplete. Not a logic defect.

**Solution**: Re-stage both files (`scripts/specrew-team.ps1`, `tests/integration/team-management.ps1`) to include the Unix-style flag handler. No code changes required; this is a mechanical staging operation.

**Validation**:

- ✅ Unix-style flag handler present in staged artifact (lines 20-62)
- ✅ Tests validate `--role` and `--charter` syntax (8/8 integration test scenarios pass)
- ✅ Documentation alignment confirmed (README.md:70-72, getting-started.md:111-113, user-guide.md:116-118 all show Unix-style flags)
- ✅ Spec contract fulfilled (FR-023, spec.md:238, 296-298 explicitly require `--role` and `--charter` flags)

**Key Learning**: When reviewer rejects for "missing feature X in artifact", first verify if X exists in working tree but is unstaged. Use `git diff --cached` to compare staged vs. working tree. Staging truth gaps are mechanical fixes, not logic rework. This is distinct from:

- **Logic drift** (implementation deviates from spec)
- **Contract drift** (spec requires feature not implemented)
- **Documentation drift** (docs contradict implementation)

**Pattern**: Staging truth gaps occur when working-tree fixes are not staged before review. The artifact under review (staged index) must match the intended deliverable. Reviewer lockout protocol applies: Troi authored previous revision, Picard performs restage to provide fresh perspective.

**Decision Artifact**: `.squad/decisions/inbox/picard-team-command-restage.md` with context, problem analysis, validation checklist, and traceability to FR-023.
