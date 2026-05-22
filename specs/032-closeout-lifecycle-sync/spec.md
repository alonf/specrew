# Feature Specification: Closeout Lifecycle Sync Commands

**Feature Branch**: `chore-090-closeout-lifecycle-sync-commands`
**Proposal**: [Proposal 090](../../proposals/090-closeout-lifecycle-sync-commands.md)
**Created**: 2026-05-22
**Status**: Draft
**Version**: v0.24.3 small-feature slice (process-optimization bundle, slot 1)

## Clarifications

### Session 2026-05-22

- **Q: Should `retro` become a first-class canonical boundary alongside `iteration-closeout`, or stay implicit?** → **A: First-class. Add `retro` to the ValidateSet at `sync-boundary-state.ps1` lines 188, 222, 253, 670. The new `sync-retro` command needs an explicit boundary target. Keeping `retro` implicit (rolled into `iteration-closeout`) would conflate two distinct lifecycle activities.**

- **Q: Do hooks fire automatically for the new sync commands?** → **A: No. Spec Kit's hook system (`before_plan`, `after_tasks`, `before_implement`) fires only on `/speckit.*` lifecycle commands. The closeout phases have no `/speckit.*` upstream commands, so we can't add hooks at the Spec Kit level. The new sync commands are explicit slash-command targets the Crew invokes manually — but they bake the canonical enum string in, so the bypass bug class can't recur as long as the Crew uses the new commands instead of inline PowerShell.**

- **Q: Should the validator rule retroactively reject existing `feature-closed`/`iteration-closed` strings on main?** → **A: Yes — the validator rule rejects non-canonical strings wherever encountered. Pre-existing legacy strings will need a one-time migration chore (out of scope for this slice; queued as follow-up).**

## User Scenarios & Testing

### User Story 1 — Crew completes feature-closeout via the canonical sync command (Priority: P1)

The Crew finishes a feature's closeout artifacts (INDEX update + state-file feature-closure commits). Instead of inline `pwsh -File .../sync-boundary-state.ps1 -BoundaryType feature-closeout ...` (which the Crew was bypassing in F-030/083), the Crew invokes the new `/speckit.specrew-speckit.sync-feature-closeout` slash command. The command wraps the canonical sync with the correct enum value baked in. State files end up with `active=false`, `boundary=feature-closeout`, and `.specify/feature.json` cleared.

**Why this priority**: This is the primary user journey. It directly closes the root-cause bug class that bit F-030/083 four separate times.

**Independent Test**: From a Crew session at feature-closeout boundary, invoke `/speckit.specrew-speckit.sync-feature-closeout`. Inspect state files post-invocation: `session_state.active == false`, `session_state_boundary == 'feature-closeout'`, `.specify/feature.json.feature_directory == ''`.

**Acceptance Scenarios**:

1. **Given** a feature at feature-closeout boundary with committed closeout artifacts, **When** Crew invokes `/speckit.specrew-speckit.sync-feature-closeout`, **Then** the canonical sync fires and state files end up in the post-feature-closeout state (AC1, AC2, AC7).
2. **Given** the new sync command is invoked, **When** it completes, **Then** `Clear-SpecrewActiveFeature` (line 781) and `active = false` (line 253) BOTH fire (AC7).

---

### User Story 2 — Crew completes review-signoff / retro / iteration-closeout via canonical sync commands (Priority: P1)

Same pattern as US-1 for the other three closeout-phase commands. Crew uses `/speckit.specrew-speckit.sync-review-signoff`, `/speckit.specrew-speckit.sync-retro`, `/speckit.specrew-speckit.sync-iteration-closeout` at the respective boundaries.

**Why this priority**: Without these three, the Crew still has 3 phases to manually invoke sync at. Coverage must be complete to eliminate the bug class.

**Independent Test**: For each of the 3 commands, invoke from the appropriate boundary and verify state files end up in canonical post-boundary state.

**Acceptance Scenarios**:

1. **Given** a feature at review-signoff boundary, **When** Crew invokes `/speckit.specrew-speckit.sync-review-signoff`, **Then** `session_state_boundary` becomes `'review-signoff'` and `active` stays `true` (AC1, AC3).
2. **Given** a feature at retro boundary, **When** Crew invokes `/speckit.specrew-speckit.sync-retro`, **Then** `session_state_boundary` becomes `'retro'` (this requires the ValidateSet extension in Pillar 3) (AC3).
3. **Given** a feature at iteration-closeout boundary, **When** Crew invokes `/speckit.specrew-speckit.sync-iteration-closeout`, **Then** `session_state_boundary` becomes `'iteration-closeout'` and iteration's `Current Phase` becomes `'iteration-closeout'` (AC1, AC3).

---

### User Story 3 — Validator catches non-canonical boundary strings (Priority: P1)

A developer (or future Crew session) writes `feature-closed` or `iteration-closed` (or any other non-canonical string) into any session_state_boundary field or iteration's `Current Phase`. The validator's new `Test-SessionStateBoundaryCanonical` rule rejects the value with a clear `file:line: invalid boundary string` error and a directive to use the canonical sync command.

**Why this priority**: Defense in depth. Even if the new sync commands exist, agents/maintainers may still write non-canonical strings manually. The validator rule catches what the command-based prevention misses.

**Independent Test**: Place `session_state_boundary: feature-closed` in `.specrew/start-context.json`. Run `validate-governance.ps1`. Observe failure with directive pointing at the bad value.

**Acceptance Scenarios**:

1. **Given** `.specrew/start-context.json` contains `session_state.boundary_type: "feature-closed"`, **When** validator runs, **Then** validator emits `FAIL` with a message identifying the non-canonical string and naming the canonical set (AC4).
2. **Given** `iterations/001/state.md` contains `**Current Phase**: iteration-closed`, **When** validator runs, **Then** validator emits `FAIL` with file:line reference (AC4).

---

### User Story 4 — Validator catches active/boundary contradiction (Priority: P1)

A developer (or future Crew session) writes `session_state_active: true` combined with `session_state_boundary` in `{iteration-closeout, feature-closeout}` (a logical contradiction — closure boundaries imply terminal/inactive state). The validator rejects this combination.

**Why this priority**: Catches the specific F-030/083 failure mode where the Crew bypassed sync, leaving active=true post-closeout.

**Independent Test**: Place `session_state_active: true` AND `session_state_boundary: feature-closeout` in `.specrew/last-start-prompt.md` frontmatter. Run `validate-governance.ps1`. Observe failure.

**Acceptance Scenarios**:

1. **Given** any state file with `active=true` + `boundary=feature-closeout`, **When** validator runs, **Then** FAIL with directive to invoke the canonical sync command (AC5).
2. **Given** any state file with `active=true` + `boundary=iteration-closeout`, **When** validator runs, **Then** same FAIL semantics (AC5).
3. **Given** any state file with `active=true` + `boundary` in the non-closure set (`specify`, `clarify`, `plan`, `tasks`, `review-signoff`, `retro`), **When** validator runs, **Then** PASS (no contradiction) (AC5).

---

### User Story 5 — Charter prose guides Crew toward the new commands (Priority: P2)

Agent charters for Implementer, Spec Steward, Reviewer, Retro Facilitator explicitly instruct the Crew to use the new sync commands at each closeout boundary. The coordinator governance prompt rule 5 documents the new commands as the canonical path.

**Why this priority**: Methodology completeness. Even with the commands and validator rule, agents need to know to use them.

**Independent Test**: Grep `extensions/specrew-speckit/squad-templates/agents/<role>/charter.md` for new command names. Pattern present per role's responsibility section.

**Acceptance Scenarios**:

1. **Given** Implementer charter, **When** grep for `sync-iteration-closeout` and `sync-feature-closeout`, **Then** patterns present in the boundary commit responsibility section (AC6).
2. **Given** Reviewer charter, **When** grep for `sync-review-signoff`, **Then** pattern present.
3. **Given** Retro Facilitator charter, **When** grep for `sync-retro`, **Then** pattern present.
4. **Given** coordinator-governance.md rule 5, **When** grep for the new command names, **Then** all 4 referenced.

---

## Functional Requirements

### Authoritative Requirements

- **FR-001**: System MUST provide 4 new sync command files at canonical paths `extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-{review-signoff,retro,iteration-closeout,feature-closeout}.md` (+ mirror at `.specify/extensions/specrew-speckit/commands/`) (AC1, AC2).

- **FR-002**: `extensions/specrew-speckit/extension.yml` (+ mirror) MUST list the 4 new commands in `provides.commands` (AC2).

- **FR-003**: `scripts/internal/sync-boundary-state.ps1` ValidateSet MUST be extended to include `retro` at lines 188, 222, 253 (the `active=` ternary), and 670 (AC3).

- **FR-004**: Each new sync command file MUST follow the template established by `sync-tasks.md` (the existing pattern), with the canonical `-BoundaryType` enum value baked in (AC2).

- **FR-005**: `extensions/specrew-speckit/scripts/validate-governance.ps1` (+ mirror) MUST add a new validator rule `Test-SessionStateBoundaryCanonical` that:
  - Reads `.specrew/start-context.json` `session_state.boundary_type`, `.specrew/last-start-prompt.md` frontmatter `session_state_boundary`, `.squad/identity/now.md` frontmatter `session_state_boundary`, and every `specs/*/iterations/*/state.md` `**Current Phase**` field
  - Rejects any value not in the canonical set `{specify, clarify, plan, tasks, review-signoff, retro, iteration-closeout, feature-closeout}` (AC4)
  - Rejects `session_state_active: true` combined with `session_state_boundary` in `{iteration-closeout, feature-closeout}` (AC5)
  - Emits a clear `file:line: error` message with directive to use the canonical sync command (AC4, AC5).

- **FR-006**: The validator rule MUST auto-scope per Proposal 083 (only checks state files in the diff) when running on a feature branch (AC4, AC5).

- **FR-007**: Charter updates MUST be present for Implementer, Spec Steward, Reviewer, Retro Facilitator at `extensions/specrew-speckit/squad-templates/agents/<role>/charter.md` (+ mirror) (AC6).

- **FR-008**: Coordinator governance prompt at `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` (+ mirror) MUST document the new commands in rule 5 (AC6).

- **FR-009**: Integration tests MUST cover all four new sync commands, the validator rule's canonical-string assertion, and the validator rule's active/boundary contradiction assertion (AC1, AC4, AC5, AC7).

- **FR-010**: Mirror parity MUST be preserved across `extensions/specrew-speckit/` and `.specify/extensions/specrew-speckit/` for all touched files (AC8).

- **FR-011**: CHANGELOG.md MUST contain an entry under `Changed` (or `Added`) referencing Proposal 090, the empirical motivation (F-030/083 four-fold bypass bug class), and the new commands.

### Traceability & Governance Requirements

- All FRs trace to specific Proposal 090 pillars
- All acceptance criteria trace to FRs and user stories
- Mirror parity (FR-010) follows the established pattern from Proposals 082 T1 and 083

---

## Out of Scope

- Auto-invocation of sync at lifecycle boundaries (no daemon, no file-system watcher)
- Migration of existing repos that contain `feature-closed`/`iteration-closed` legacy strings on main (queued as separate chore)
- Cross-host slash-command auto-completion / discoverability UX (Spec Kit's existing discovery surface is sufficient)
- Removal of inline-PowerShell invocation pattern from charters (kept as fallback)

---

## Risks & Assumptions

- **Risk**: Adding `retro` to the ValidateSet might surprise existing test fixtures that hard-code the old 7-value set. **Mitigation**: search for hard-coded enum tests and update them.
- **Assumption**: Spec Kit slash-command discovery picks up the 4 new commands without additional configuration once `extension.yml` is updated. Per existing pattern with `sync-specify`/`sync-clarify`/`sync-plan`/`sync-tasks`, this should hold.
- **Risk**: The validator rule reads `state.md`'s `Current Phase` field, which is a human-readable bold-prefixed line. Parser must be robust to whitespace and variations.

---

## Acceptance Criteria Summary

| AC | Verifies | Trace |
|---|---|---|
| AC1 | 4 new command files exist; SHA256 mirror parity verified | FR-001, FR-010 |
| AC2 | `extension.yml` lists the 4 commands; content correct | FR-002 |
| AC3 | ValidateSet includes `retro` at all 4 sites | FR-003 |
| AC4 | Validator rejects non-canonical boundary strings | FR-005, FR-006 |
| AC5 | Validator rejects active=true + boundary in closure set | FR-005, FR-006 |
| AC6 | Charter + coordinator prose references new commands | FR-007, FR-008 |
| AC7 | Sync via new commands produces canonical state files | FR-001, FR-004 |
| AC8 | Mirror parity across both extension trees | FR-010 |

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22
