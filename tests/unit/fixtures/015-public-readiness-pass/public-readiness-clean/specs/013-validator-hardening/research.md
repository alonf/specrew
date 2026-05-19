# Research: Validator Hardening

**Date**: 2026-05-12
**Spec**: [spec.md](spec.md)
**Plan**: [plan.md](plan.md)

## Decisions

### R1: Where should new validator rules be implemented?

**Decision**: All new rules are implemented inside the existing `extensions/specrew-speckit/scripts/validate-governance.ps1` and `shared-governance.ps1`. No new top-level validator script or separate entrypoint is introduced.

**Rationale**: FR-010 explicitly requires preserving the existing command surface. The validator already uses `shared-governance.ps1` as a shared helper, so adding new helper functions there is consistent with the established pattern. Introducing a second entrypoint would split the validator surface and break FR-010 compatibility.

**Alternatives considered**:

- Separate `validate-governance-v2.ps1`: rejected — breaks FR-010 command-surface preservation.
- Inline all new logic directly in the entrypoint without helpers: rejected — reduces testability and increases coupling between unrelated checks.

---

### R2: What is the canonical `state.md` field pattern that must be enforced?

**Decision**: The canonical pattern is `**Field Name**:` (bold label followed by colon) on its own line. The eight required field names are: `Schema`, `Last Completed Task`, `Tasks Remaining`, `In Progress`, `Baseline Ref`, `Updated`, `Current Phase`, and `Iteration Status`. The validator uses a regex of the form `^\*\*<FieldName>\*\*:\s*` per the existing `Get-MarkdownMetadataValue` function.

**Rationale**: The existing `Get-MarkdownMetadataValue` helper already implements this pattern for current checks. The spec clarification (2026-05-12) confirms the eight field names and allows pending values as long as canonical field names are present. Extra narrative sections are allowed.

**Alternatives considered**:

- YAML front-matter for `state.md`: rejected — the repository uses the `**Field**:` Markdown convention throughout.
- Looser heading-based detection: rejected — headings are not the canonical pattern and would accept non-canonical field names silently.

---

### R3: What is the canonical hardening-gate Concern Review table format that must be enforced?

**Decision**: The validator checks that the `Concern Review` table section of `hardening-gate.md` contains exactly the five canonical concern identifiers — `security-surface`, `error-handling-expectations`, `retry-idempotency-requirements`, `test-integrity-targets`, `operational-resilience-concerns` — as the first five rows in that order. Additional feature-specific rows are allowed afterward.

**Rationale**: The spec (FR-002, clarification 2026-05-12) and the known-traps corpus entry (governance trap: "hardening gate missing canonical concerns") confirm the canonical five as the required first-five rows. The existing `Get-MarkdownSectionTableAnyLevel` helper parses Markdown tables and is sufficient for extracting concern rows.

**Alternatives considered**:

- Check only that the five concerns appear anywhere in any order: rejected — the known-traps corpus documents canonical ordering as required; order enforcement is part of FR-002.
- Require all five concerns to appear in a strict schema column: rejected — the validator reads existing Markdown tables; imposing a new required column format would break backward compatibility for compliant existing artifacts.

---

### R4: How should approval-evidence reuse be detected (FR-003)?

**Decision**: Collect all `Implementation Approval` sections from `plan.md` and `state.md` across sibling iterations within the same feature. Normalize each evidence quote (whitespace collapse, strip `*` and `_` Markdown emphasis). Compare normalized quotes across iterations. Flag any pair with a matching quote unless the artifact contains a blanket-authorization scope declaration (a line containing `blanket` or `multi-iteration authorization` within the approval block).

**Rationale**: The spec clarification defines duplicate evidence as "quotes that match after whitespace normalization and markdown-emphasis stripping." The blanket-authorization exception is explicit. A per-feature scan across sibling iterations is required because duplicates appear in different artifact files.

**Alternatives considered**:

- Hash-based deduplication without normalization: rejected — minor formatting differences would evade detection; the spec requires normalized comparison.
- Requiring a separate approval ledger file: rejected — the spec says detection must operate on existing `plan.md` / `state.md` without requiring new artifact format changes.

---

### R5: How should the over-claim / closeout-evidence check be scoped for the dirty-tree check (FR-004)?

**Decision**: The dirty-tree check scopes to files inside the iteration directory path only (e.g., `specs/<feature>/iterations/<NNN>/`). Files such as `.squad/decisions.md` and `.squad/identity/now.md` may be used as evidence sources but are excluded from the dirty-tree failure condition.

**Rationale**: The spec clarification (2026-05-12) is explicit: "Dirty-tree enforcement is limited to the iteration directory's canonical artifacts." Scoping to the iteration directory prevents false positives from normal in-flight governance trace files.

**Alternatives considered**:

- Repo-wide dirty-tree check: rejected — creates false positives for governance traces outside the iteration; spec clarification explicitly disallows this.
- No dirty-tree check at all: rejected — FR-004 explicitly requires it for the iteration directory.

---

### R6: Where should the bookkeeping classifier for `.github/copilot-instructions.md` live (FR-006)?

**Decision**: Implement as a standalone PowerShell helper function `Test-CopilotInstructionsChangeType` (or equivalent) in a new script under `extensions/specrew-speckit/scripts/` or `scripts/`. The function takes the diff text or before/after file content and returns `bookkeeping` or `behavior`. It is consumed by `scripts/specrew-start.ps1`. The validator may call or validate the classifier result but does not own the restart-policy decision.

**Rationale**: The spec clarification explicitly states "restart-policy ownership must stay outside the validator entrypoint." A reusable helper keeps the classifier testable independently and allows `specrew-start.ps1` to own the policy decision.

**Alternatives considered**:

- Embedding classifier logic inline in `validate-governance.ps1`: rejected — the spec explicitly requires a separate reusable helper consumed by `specrew-start.ps1`.
- Adding a new command-line flag to the validator for restart classification: rejected — changes the validator command surface, violating FR-010.

---

### R7: What iteration split best fits the dependency graph?

**Decision**: Adopt the preferred two-iteration split from the spec:

- **Iteration 1**: FR-001 (canonical schema), FR-002 (canonical concerns), FR-005 (graceful errors), FR-008 slice 1 (Iteration 1 fixtures), FR-009 (contracts), FR-010 slice 1.
- **Iteration 2**: FR-003 (approval reuse), FR-004 (over-claim), FR-006 (bookkeeping classifier), FR-007 (corpus graduation), FR-008 slice 2, FR-010 slice 2.

**Rationale**: FR-009 (contracts) must precede FR-001 and FR-002 enforcement because the contracts define the authoritative normative reference for the rules. FR-005 is a shared foundation for all structured FAIL output and must land in Iteration 1 so Iteration 2 rules inherit it. FR-003 and FR-004 are independent of FR-001/FR-002 but depend on the FAIL output infrastructure from FR-005. FR-006 (classifier) can be deferred to Iteration 2 because it does not block FR-001/FR-002. FR-007 (corpus graduation) naturally closes after all rules are implemented.

**Alternatives considered**:

- Three iterations with corpus graduation as a standalone: rejected — FR-007 is bounded enough to fit Iteration 2 and does not justify a separate iteration boundary.
- Single iteration: rejected — the combined surface (six rules + contracts + corpus graduation + classifier) exceeds a bounded deliverable unit and risks scope overload.
