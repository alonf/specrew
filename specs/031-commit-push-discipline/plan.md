# Feature Plan: Boundary Commit + Upstream Push Discipline (Proposal 082 Tier 1)

**Spec**: [./spec.md](./spec.md)
**Status**: planning
**Approved**: ✓ (Tier 1 scope per Proposal 082; user direction 2026-05-22 "evidence and structure as if Specrew did it")
**Created**: 2026-05-22

---

## Summary

Proposal 082 Tier 1 adds methodology-surface instructions for **commit-at-every-boundary + push-after-commit** discipline. Text-only edits to the coordinator governance prompt + all 5 baseline agent charters + downstream-user documentation. No runtime enforcement (that's Tier 2/3 in later releases).

**Empirical motivation**: 4 boundary-discipline rejection cycles in F-029 + 1 in F-030/083, all stemming from the absence of explicit commit-discipline instructions in any Crew-governing surface (grep across `extensions/specrew-speckit/` returns zero matches for "commit at every boundary" or "push after commit" pre-082).

**Solution shape**: pure text additions. The Crew's host runtime (Squad CLI, future Claude Code agents, etc.) reads charters and governance prompt at agent-context load time. Adding the discipline to those files propagates to every future agent invocation.

---

## Requirements Traceability

| Requirement | Scope | Owner |
|-------------|-------|-------|
| **FR-001**: Coordinator Governance Prompt Rule | New rule in `coordinator/specrew-governance.md` | Spec Steward (this slice) |
| **FR-002**: Implementer Charter Addition | New responsibility in `agents/implementer/charter.md` | Spec Steward (this slice) |
| **FR-003**: Spec Steward Charter Addition | New oversight in `agents/spec-steward/charter.md` | Spec Steward (this slice) |
| **FR-004**: Reviewer Charter Addition | Pre-merge committed-work check in `agents/reviewer/charter.md` | Spec Steward (this slice) |
| **FR-005**: Retro Facilitator Charter Addition | Retro prompt in `agents/retro-facilitator/charter.md` | Spec Steward (this slice) |
| **FR-006**: Planner Charter Addition (light) | Light reference in `agents/planner/charter.md` | Spec Steward (this slice) |
| **FR-007**: User-Guide Section | New `## Boundary Commit Discipline` section in `docs/user-guide.md` | Spec Steward (this slice) |
| **FR-008**: Mirror Parity | Mirrored to `.specify/extensions/specrew-speckit/` | Spec Steward (this slice) |
| **FR-009**: Terminology Compliance | "the Crew" in all new prose | Spec Steward (this slice) |
| **FR-010**: Test | `tests/integration/boundary-commit-discipline.tests.ps1` | Reviewer (this slice) |

Note: This slice is authored by Claude acting as all agent roles in sequence per the 2026-05-22 user direction. The Author trailer in commits captures this honestly via Co-authored-by lines.

---

## Design

### Architecture

- **Primary change sites** (8 files in `extensions/specrew-speckit/`):
  - `squad-templates/coordinator/specrew-governance.md` — new rule
  - `squad-templates/agents/implementer/charter.md` — primary commit responsibility
  - `squad-templates/agents/spec-steward/charter.md` — oversight responsibility
  - `squad-templates/agents/reviewer/charter.md` — pre-merge check
  - `squad-templates/agents/retro-facilitator/charter.md` — retro prompt
  - `squad-templates/agents/planner/charter.md` — light reference
- **Mirror sites** (8 mirror files in `.specify/extensions/specrew-speckit/`)
- **Documentation**: `docs/user-guide.md` — new top-level section
- **Test**: `tests/integration/boundary-commit-discipline.tests.ps1` — new file; verifies the new text appears in the right files + mirror parity

### Data Model

No data model changes. Methodology-text only.

### Lifecycle Flow

No lifecycle flow changes. Tier 1 is observation-only: the Crew reads the new instructions but no runtime gate enforces them. Tier 2 (validator rule) and Tier 3 (boundary-sync gate + auto-push) deliver enforcement in later releases.

---

## Iterations

### Iteration 001 (Tier 1 — Text Discipline)

- **Effort**: ~5 SP (small-fix slice per Proposal 067)
- **Status**: planning
- **Scope**:
  - Coordinator governance prompt rule (FR-001)
  - 5 agent charter additions (FR-002 through FR-006)
  - User-guide section (FR-007)
  - Mirror parity (FR-008)
  - Test suite (FR-010)
  - CHANGELOG entry (under Added)

**Tasks** (10 total — see [iterations/001/tasks.md](./iterations/001/tasks.md)):

| Task | Title | Requirement | Effort | Owner |
|------|-------|-------------|--------|-------|
| `coord-rule` | Add commit+push rule to coordinator governance prompt | FR-001, FR-009 | 0.5 SP | Spec Steward |
| `implementer-charter` | Implementer commit responsibility | FR-002, FR-009 | 0.5 SP | Spec Steward |
| `spec-steward-charter` | Spec Steward oversight responsibility | FR-003, FR-009 | 0.5 SP | Spec Steward |
| `reviewer-charter` | Reviewer pre-merge committed-work check | FR-004, FR-009 | 0.5 SP | Spec Steward |
| `retro-facilitator-charter` | Retro Facilitator commit-discipline prompt | FR-005, FR-009 | 0.5 SP | Spec Steward |
| `planner-charter` | Planner light reference | FR-006, FR-009 | 0.25 SP | Spec Steward |
| `user-guide` | `## Boundary Commit Discipline` section | FR-007, FR-009 | 0.5 SP | Spec Steward |
| `mirror-parity` | Mirror 7 files to `.specify/extensions/specrew-speckit/` | FR-008 | 0.5 SP | Implementer |
| `tests` | Methodology-surface verification test | FR-010 | 1 SP | Reviewer |
| `changelog` | CHANGELOG entry under Added | (closeout requirement) | 0.25 SP | Spec Steward |

**Total**: ~5 SP.

---

## Success Criteria

- **SC-001**: After Tier 1 ships, the next feature has commit-discipline instructions visible in 6 files: coordinator governance prompt + 5 charters + user-guide. Mechanically verified by file inspection.
- **SC-002**: Empirical reduction in human-rejection cycles for boundary-commit discipline (baseline: 4 in F-029 + 1 in F-030; target: 0 in next feature that reads updated charters).
- **SC-003**: Mirror parity preserved across `extensions/specrew-speckit/` + `.specify/extensions/specrew-speckit/`.
- **SC-004**: Test suite passes; methodology-surface assertions verify the new content + mirror parity.

---

## Quality Gates

| Gate | Evidence | Status |
|------|----------|--------|
| **Coordinator governance prompt rule** | New rule in `specrew-governance.md` + mirror | pending |
| **5 agent charters carry per-role responsibilities** | Inline grep for "commit" and "push" in each charter | pending |
| **User-guide section published** | `## Boundary Commit Discipline` heading in `docs/user-guide.md` | pending |
| **Mirror parity** | `Compare-Object` between `extensions/` and `.specify/extensions/` for the 6 modified files | pending |
| **Test suite passes** | `pwsh -File tests/integration/boundary-commit-discipline.tests.ps1` returns exit 0 | pending |

---

## Deferred Out of Scope

- Validator rule (`boundary-wip-uncommitted` at warning severity) — **Proposal 082 Tier 2**, ~6 SP, future release.
- Hard enforcement in `Invoke-SpecrewBoundaryStateSync` (refuse advancement on WIP) — **Tier 3**, ~10 SP, future release.
- Auto-push hook after every commit — **Tier 3**.
- Configuration via `iteration-config.yml` for `boundary_discipline.commit_required` and `.auto_push` — **Tier 3**.

---

## Files Modified

| File | Change | Scope |
|------|--------|-------|
| `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` | Add new boundary-commit-discipline rule | Primary |
| `extensions/specrew-speckit/squad-templates/agents/implementer/charter.md` | Add commit responsibility | Primary |
| `extensions/specrew-speckit/squad-templates/agents/spec-steward/charter.md` | Add oversight responsibility | Primary |
| `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md` | Add pre-merge committed-work check | Primary |
| `extensions/specrew-speckit/squad-templates/agents/retro-facilitator/charter.md` | Add retro prompt | Primary |
| `extensions/specrew-speckit/squad-templates/agents/planner/charter.md` | Add light reference | Primary |
| `docs/user-guide.md` | Add `## Boundary Commit Discipline` section | Documentation |
| `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` | Mirror | Mirror |
| `.specify/extensions/specrew-speckit/squad-templates/agents/<5 roles>/charter.md` | Mirror | Mirror |
| `tests/integration/boundary-commit-discipline.tests.ps1` | New test | Verification |
| `CHANGELOG.md` | Entry under Added | Documentation |

---

## Team & Ownership

| Role | Owner | Responsibilities |
|------|-------|------------------|
| Spec Steward | Alon Fliess (via Claude as authoring agent) | Approve spec, draft governance prompt + charter additions |
| Implementer | Alon Fliess (via Claude as authoring agent) | Apply edits to all 8 primary files + 7 mirrors |
| Reviewer | Alon Fliess (via Claude as authoring agent) | Write methodology-surface verification test; self-review |
| Retro Facilitator | Alon Fliess (via Claude as authoring agent) | Produce retro.md at retro-boundary |

Acting-as-all-roles is honest in commit metadata (Co-authored-by lines). The 2026-05-22 user direction explicitly accepted Claude running the full lifecycle as a substitute for the Crew's quota constraints.

---

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| Tier 1 ships text-only, no runtime enforcement | Per Proposal 082 scope; Tier 2/3 add validator + boundary-sync enforcement in later releases |
| Mirror parity preserved | Existing pattern across `extensions/specrew-speckit/` work — every charter/prompt edit gets mirrored |
| Test verifies METHODOLOGY surface presence, not runtime behavior | Text-only scope; no runtime to test |
| Per-agent charter additions worded for each role's natural responsibility | Implementer commits, Spec Steward oversees, Reviewer rejects WIP, Retro Facilitator audits |
| Use "the Crew" in all new prose | Per 2026-05-21 naming decision (memory `[[project-naming-the-crew-2026-05-21]]`) and going-forward rule (memory `[[feedback-no-squad-in-new-proposals-2026-05-21]]`) |
| Acceptance test is integration-shaped, not unit | Test verifies file content + mirror parity; doesn't unit-test pure functions |

---

## Related Features

- **Proposal 082 (Boundary Commit + Upstream Push Discipline)** — this is Tier 1 implementation
- **Proposal 067 (Small-Fix Slice Type)** — this slice follows the small-fix slice contract: code + tests + CHANGELOG + proposal entry (082 already exists) + INDEX update
- **Proposal 081 Pillar 6 (Mermaid Mandate)** — sibling methodology integrity slice (queued after 082 T1)
- **F-029 (Baseline Hygiene)** — empirical case study; 4 rejection cycles motivated 082 prioritization
- **F-030/083 (Local Validator Speedup)** — in-flight, sibling v0.24.2 bundle slice
- **PR #423 (Closeout Body Clear)** — sibling fix; both ship in v0.24.2

---

## Maintained By

**Alon Fliess** | Last Updated: 2026-05-22
