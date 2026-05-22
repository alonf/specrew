# Tasks: Closeout Lifecycle Sync Commands (Proposal 090)

**Feature**: 032-closeout-lifecycle-sync
**Proposal**: 090
**Version**: v0.24.3
**Spec**: [spec.md](../../spec.md)
**Plan**: [plan.md](plan.md)
**Branch**: `chore-090-closeout-lifecycle-sync-commands`
**Capacity**: 6.5 story_points

---

## Executive Summary

**Goal**: Close the architectural gap where the closeout half of Specrew's lifecycle (review-signoff, retro, iteration-closeout, feature-closeout) has no automated sync coverage. Add 4 new sync commands + extend ValidateSet to include `retro` + new validator rule catching the Crew-bypass bug class.

**Scope**: Bounded to Proposal 090's 4 pillars. Implementation reuses Proposal 083's `Get-SpecrewLocalScopeBaseRef` for validator auto-scope.

**User Stories**: US-1 through US-5
**Functional Requirements**: FR-001 through FR-011
**Acceptance Criteria**: AC1 through AC8

---

## Phase 1: Setup & Context Verification

**Purpose**: Validate environment and locate all surfaces.

### T001: Verify Implementation Context (0.25 SP)

**Objective**: Confirm environment + locate all surfaces touched by this feature.

**Acceptance Criteria**:

- [X] On branch `chore-090-closeout-lifecycle-sync-commands` off main
- [X] Existing sync commands (`sync-specify`, `sync-clarify`, `sync-plan`, `sync-tasks`) located at `extensions/specrew-speckit/commands/`
- [X] `extension.yml` located at `extensions/specrew-speckit/extension.yml`
- [X] `sync-boundary-state.ps1` located at `scripts/internal/sync-boundary-state.ps1` with ValidateSet sites confirmed at lines 188, 222, 253, 670
- [X] `validate-governance.ps1` + `shared-governance.ps1` located at `extensions/specrew-speckit/scripts/`
- [X] 4 agent charters located at `extensions/specrew-speckit/squad-templates/agents/<role>/charter.md`
- [X] Coordinator governance prompt located at `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`
- [X] All mirror paths exist at `.specify/extensions/specrew-speckit/`

**Owner**: Spec Steward
**Trace**: All FRs (orientation)

---

## Phase 2: Core Implementation

**Goal**: Implement commands, ValidateSet extension, and validator rule.

### T002: Create 4 New Sync Command Files (1.0 SP)

**Objective**: Create the 4 closeout-phase sync command files at canonical paths with mirrored copies.

**Acceptance Criteria**:

- [X] Create `extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-review-signoff.md` wrapping `Invoke-SpecrewBoundaryStateSync -BoundaryType review-signoff`
- [X] Create `extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-retro.md` wrapping `Invoke-SpecrewBoundaryStateSync -BoundaryType retro`
- [X] Create `extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-iteration-closeout.md` wrapping `Invoke-SpecrewBoundaryStateSync -BoundaryType iteration-closeout`
- [X] Create `extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-feature-closeout.md` wrapping `Invoke-SpecrewBoundaryStateSync -BoundaryType feature-closeout`
- [X] Each file follows the existing `sync-tasks.md` template shape (frontmatter, body, error-handling guidance)
- [X] All 4 files mirrored at `.specify/extensions/specrew-speckit/commands/`

**Owner**: Implementer
**Trace**: FR-001, FR-004

---

### T003: Update extension.yml provides.commands (0.25 SP)

**Objective**: Register the 4 new commands in the extension manifest.

**Acceptance Criteria**:

- [X] Edit `extensions/specrew-speckit/extension.yml`
- [X] Add 4 entries to `provides.commands` referencing the new files with descriptions
- [X] Mirror at `.specify/extensions/specrew-speckit/extension.yml` matches byte-for-byte

**Owner**: Implementer
**Trace**: FR-002

---

### T004: Add `retro` to ValidateSet (0.5 SP)

**Objective**: Extend the canonical boundary ValidateSet in `sync-boundary-state.ps1`.

**Acceptance Criteria**:

- [X] Edit `scripts/internal/sync-boundary-state.ps1`
- [X] Add `'retro'` to ValidateSet at line 188 (Get-CanonicalBoundaryTypes or equivalent)
- [X] Add `'retro'` to ValidateSet at line 222 (parameter declaration)
- [X] Update `active=` ternary at line 253 to set `active = 'true'` for retro (iteration still active during retro)
- [X] Add `'retro'` to ValidateSet at line 670 (public entry function parameter)
- [X] Smoke-invoke `Invoke-SpecrewBoundaryStateSync -BoundaryType retro` against a fixture; expect no ValidateSet error

**Owner**: Implementer
**Trace**: FR-003

---

### T005: Add `Test-SessionStateBoundaryCanonical` Validator Rule (1.5 SP)

**Objective**: New validator rule that catches non-canonical boundary strings + active/boundary contradictions.

**Acceptance Criteria**:

- [X] Add helper `Get-SpecrewCanonicalBoundaryTypes` to `extensions/specrew-speckit/scripts/shared-governance.ps1` returning the canonical 8-value set
- [X] Add validator rule function `Test-SessionStateBoundaryCanonical` to `extensions/specrew-speckit/scripts/validate-governance.ps1`
- [X] Rule reads `.specrew/start-context.json` (session_state.boundary_type), `.specrew/last-start-prompt.md` (session_state_boundary frontmatter), `.squad/identity/now.md` (session_state_boundary frontmatter), and every `specs/*/iterations/*/state.md` (`**Current Phase**` field)
- [X] Rule rejects any value not in the canonical set with clear `file:line: invalid boundary string '<value>'; canonical set: {...}`
- [X] Rule rejects `session_state_active: true` combined with `session_state_boundary` in `{iteration-closeout, feature-closeout}`
- [X] Rule auto-scopes via Proposal 083's `Get-SpecrewLocalScopeBaseRef` when on feature branch
- [X] Mirror copies at `.specify/extensions/specrew-speckit/scripts/` updated

**Owner**: Implementer
**Trace**: FR-005, FR-006

---

## Phase 3: Methodology Surface Updates

**Goal**: Update charters and coordinator prompt to guide Crew toward the new commands.

### T006: Update 4 Agent Charters (0.5 SP)

**Objective**: Add new sync command references to relevant agent charters.

**Acceptance Criteria**:

- [X] Implementer charter at `extensions/specrew-speckit/squad-templates/agents/implementer/charter.md` references `sync-iteration-closeout` + `sync-feature-closeout` in boundary commit responsibility
- [X] Spec Steward charter at `extensions/specrew-speckit/squad-templates/agents/spec-steward/charter.md` references all 4 new commands in oversight responsibility
- [X] Reviewer charter at `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md` references `sync-review-signoff`
- [X] Retro Facilitator charter at `extensions/specrew-speckit/squad-templates/agents/retro-facilitator/charter.md` references `sync-retro`
- [X] All 4 charter changes mirrored at `.specify/extensions/specrew-speckit/squad-templates/agents/`

**Owner**: Spec Steward
**Trace**: FR-007

---

### T007: Update Coordinator Governance Prompt Rule 5 (0.25 SP)

**Objective**: Document the 4 new sync commands as the canonical closeout path.

**Acceptance Criteria**:

- [X] Edit `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` rule 5
- [X] Add bullet listing the 4 new commands and noting they replace inline-PowerShell invocation for closeout phases
- [X] Mirror at `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` matches

**Owner**: Spec Steward
**Trace**: FR-008

---

## Phase 4: Testing

**Goal**: Mechanical verification of all acceptance criteria.

### T008: Integration Test for 4 New Sync Commands (1.0 SP)

**Objective**: Verify each new sync command invokes the canonical script with correct enum.

**Acceptance Criteria**:

- [X] Create `tests/integration/closeout-lifecycle-sync-commands.tests.ps1`
- [X] Test: invoke each of 4 sync commands against a fixture project; verify state files end up in canonical post-boundary state
- [X] Test: `sync-feature-closeout` causes `active=false` AND `.specify/feature.json.feature_directory=''`
- [X] Test: `sync-review-signoff` causes `boundary=review-signoff` and `active=true` (iteration still active)
- [X] Test: `sync-retro` causes `boundary=retro` and `active=true`
- [X] Test: `sync-iteration-closeout` causes `boundary=iteration-closeout` and iteration `state.md` Current Phase = `iteration-closeout`
- [X] Test exits 0 when all assertions pass

**Owner**: Test Owner
**Trace**: FR-009, AC1, AC7

---

### T009: Integration Test for Validator Rule (0.5 SP)

**Objective**: Verify Test-SessionStateBoundaryCanonical rejects non-canonical strings AND active/boundary contradictions.

**Acceptance Criteria**:

- [X] Create `tests/integration/session-state-boundary-canonical.tests.ps1`
- [X] Test: validator rejects `session_state_boundary: feature-closed` (non-canonical)
- [X] Test: validator rejects `session_state_boundary: iteration-closed` (non-canonical)
- [X] Test: validator rejects `active=true` + `boundary=feature-closeout` (contradiction)
- [X] Test: validator rejects `active=true` + `boundary=iteration-closeout` (contradiction)
- [X] Test: validator passes `active=true` + `boundary=review-signoff` (no contradiction)
- [X] Test: validator passes `active=false` + `boundary=feature-closeout` (correct closure state)
- [X] Test: validator catches non-canonical string in iteration state.md `Current Phase`
- [X] Test exits 0 when all assertions pass

**Owner**: Test Owner
**Trace**: FR-009, AC4, AC5

---

## Phase 5: Mirror Parity + Closeout

### T010: Mirror Parity Sweep (0.25 SP)

**Objective**: Verify all touched files are mirrored byte-for-byte.

**Acceptance Criteria**:

- [X] All 4 new sync command files SHA256-match between `extensions/specrew-speckit/` and `.specify/extensions/specrew-speckit/`
- [X] `extension.yml` matches
- [X] `validate-governance.ps1` matches
- [X] `shared-governance.ps1` matches
- [X] All 4 charter files match
- [X] `coordinator/specrew-governance.md` matches

**Owner**: Implementer
**Trace**: FR-010

---

### T011: CHANGELOG + INDEX + Closeout Artifacts (0.25 SP)

**Objective**: Final polish before PR-at-feature-close.

**Acceptance Criteria**:

- [X] CHANGELOG.md entry under `### Changed` (or `### Added`) describing Proposal 090's scope + empirical motivation (F-030/083 four-fold bypass)
- [X] proposals/INDEX.md updated: 090 transitions from Candidate to Shipped with `feature-032 (v0.24.3 bundle)` reference
- [X] specs/032-closeout-lifecycle-sync/iterations/001/review.md (self-review)
- [X] specs/032-closeout-lifecycle-sync/iterations/001/retro.md
- [X] specs/032-closeout-lifecycle-sync/iterations/001/drift-log.md
- [X] specs/032-closeout-lifecycle-sync/iterations/001/state.md (final state)
- [X] specs/032-closeout-lifecycle-sync/closeout-dashboard.md (feature-level closeout)

**Owner**: Spec Steward + Retro Facilitator
**Trace**: closeout requirements

---

### T012: Branch Push + PR + Copilot Review + Merge (0.25 SP)

**Objective**: Complete feature delivery through PR-at-feature-close, addressing Copilot review per the new memory feedback discipline.

**Acceptance Criteria**:

- [X] Branch `chore-090-closeout-lifecycle-sync-commands` pushed to origin
- [X] PR opened on GitHub referencing Proposal 090 with brief test plan
- [X] Wait for GitHub Copilot PR review (per memory `[[feedback-check-github-copilot-pr-review-2026-05-22]]`)
- [X] Address every Copilot finding (outcome fix + queued root-cause if applicable)
- [X] CI passes
- [X] PR merged with `--merge` (merge commit per PR-at-feature-close SDLC)

**Owner**: Spec Steward (acting maintainer for Claude-authored slice)
**Trace**: closeout requirements

---

## Notes

- **Mirror Parity**: All changes must be applied to two locations: primary (`extensions/specrew-speckit/`) and mirror (`.specify/extensions/specrew-speckit/`). Task T010 verifies parity.
- **Auto-scope**: Validator rule reuses Proposal 083's helper. Only checks state files in the PR diff on feature branches.
- **Out of scope**: Migration of legacy `feature-closed`/`iteration-closed` strings (separate chore queue).

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22
