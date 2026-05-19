# Feature Specification: Legacy-State Read-Tolerance + Schema Migration Discipline

**Feature Branch**: `023-legacy-state-read-tolerance`  
**Created**: 2026-05-19  
**Status**: Draft  
**Input**: Feature request from file:///C:/Dev/Specrew/proposals/059-legacy-state-read-tolerance.md

## Clarifications

### Session 2026-05-19

**Coverage Analysis Result**: No human clarification required. All potential ambiguities from Proposal 059's open questions were resolved through spec analysis and repo context grounding:

- **Q: YAML schema marker format (top-level vs. nested)?** → A: Top-level `schema: v1` per FR-001 explicit requirement
- **Q: Migration writer policy (silent vs. prompt)?** → A: Silent upgrade-on-write per Assumptions section; opaque caches silent, user-visible configs may log one-time notice
- **Q: Validator rule scope (narrow vs. broad)?** → A: Narrow scope (state readers only) per FR-010; may widen post-Phase 2 retrospective per Assumptions
- **Q: Fixture generation strategy (generated vs. hand-curated)?** → A: Iteration 1 (versions 0.18.0-0.22.0) hand-curated from real snapshots; future versions may use generated fixtures per Assumptions
- **Q: Validator integration point (which validator framework)?** → A: Extends existing validator from Proposal 004/F-013 as "gap #11" per FR-010
- **Q: Cross-platform fixture variance handling?** → A: Git `core.autocrlf` normalizes line endings per Assumptions; binary files deferred (all state files are text)

**Functional Scope**: Clear. Core goals (prevent legacy crashes, safe upgrades), out-of-scope boundaries (F-021, breaking changes, roadmap schema, multi-dev reconciliation), and user roles explicit.

**Domain Model**: Clear. State File, Schema Version Marker, and Legacy Fixture entities fully specified with attributes, lifecycle, and relationships.

**Non-Functionals**: Clear. Performance (+2min CI acceptable), scalability (linear growth monitored), reliability (zero-crash target SC-001), observability (schema-implied-v0 logging), security (N/A for local state).

**Integration Points**: Clear. PowerShell 7.0+ dependency, Git line-ending normalization, validator framework extension point grounded from F-013.

**Edge Cases**: Clear. Parse errors, missing files, unsupported schema versions, downgrade scenarios all covered with explicit failure modes.

**Governance**: Clear. Two-iteration split mandated, bootstrap principle enforced (F-023 demonstrates its own pattern), Linux validation mandatory, 3-cycle repair budget at boundaries, always-in-flow evidence discipline.

**Traceability**: User Stories map to FRs (TG-001), iteration assignments explicit (TG-003), human oversight points identified (Governance Alignment section).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Project Upgrade Without Breaking Existing State (Priority: P1)

A developer who initialized their Specrew project several months ago at version 0.19.0 upgrades to the latest Specrew version (0.22.0+) using `specrew update`. They expect to continue working on their project without encountering crashes, data loss, or manual migration steps.

**Why this priority**: This is the highest-value scenario because it directly addresses the reported production crash and enables safe adoption of new Specrew versions. Without this, every version upgrade risks breaking existing projects.

**Independent Test**: Can be fully tested by creating a project at version 0.19.0, persisting state files, then upgrading to 0.22.0 and running `specrew start`. Success means no crashes and all commands work correctly.

**Acceptance Scenarios**:

1. **Given** a project initialized at Specrew 0.19.0 with persisted state in file:///[project]/.specrew/start-context.json, **When** the developer upgrades to Specrew 0.22.0 and runs `specrew start`, **Then** the system reads the legacy state file successfully without throwing errors and provides full functionality
2. **Given** a project at version 0.20.0 with file:///[project]/.specrew/config.yml, **When** upgraded to 0.22.0, **Then** all configuration settings are preserved and no manual migration is required
3. **Given** a project with legacy file:///[project]/.specify/feature.json from version 0.19.0, **When** any speckit command is executed after upgrade, **Then** the system reads the file without errors and continues normal operation
4. **Given** legacy file:///[project]/tasks-progress.yml from version 0.21.0, **When** accessed by Specrew 0.22.0, **Then** task progress is correctly interpreted and preserved

### User Story 2 - Safe Schema Evolution Across Team Members (Priority: P2)

A development team works on the same Specrew project. Team members may temporarily be on different Specrew versions (e.g., one developer hasn't upgraded yet, another is on the latest version). When they commit changes to shared state files, no team member experiences crashes or data corruption.

**Why this priority**: Multi-developer scenarios are common in production and schema version skew naturally occurs during rolling upgrades. This prevents team-wide disruption.

**Independent Test**: Can be tested by having two developers on different Specrew versions (e.g., 0.21.0 and 0.22.0) commit changes to the same project and verify both can read each other's state files.

**Acceptance Scenarios**:

1. **Given** Developer A writes file:///[project]/.specrew/config.yml using Specrew 0.21.0 and commits it, **When** Developer B pulls and reads it with Specrew 0.22.0, **Then** Developer B's Specrew reads the file successfully without errors
2. **Given** Developer B adds a new field to file:///[project]/.specify/feature.json using Specrew 0.22.0, **When** Developer A (still on 0.21.0) reads the file, **Then** Developer A's Specrew ignores unknown fields gracefully and doesn't crash
3. **Given** mixed-version state files in a shared repository, **When** any team member runs validation commands, **Then** the validator reports schema version compatibility information without blocking work

### User Story 3 - Transparent Schema Version Migration (Priority: P3)

A developer observes that their project's state files contain schema version markers (e.g., `schema: v1`) that help troubleshoot compatibility issues. When a state file lacks a schema marker (legacy file), the system automatically interprets it as version 0 and handles it with backward compatibility logic.

**Why this priority**: While lower priority than preventing crashes, explicit schema versioning enables better diagnostics, faster support resolution, and clearer migration paths for future breaking changes.

**Independent Test**: Can be tested by inspecting state files before and after operations, verifying schema markers are present and correctly incremented when schemas evolve.

**Acceptance Scenarios**:

1. **Given** a legacy file:///[project]/.specrew/start-context.json without a schema field, **When** Specrew reads it, **Then** the system logs "schema-implied-v0" and applies v0-compatible reading logic
2. **Given** Specrew writes a new file:///[project]/.specrew/config.yml, **When** the file is created, **Then** it contains an explicit `schema: v1` marker at the top level
3. **Given** a developer encounters a state file compatibility issue, **When** they examine the file, **Then** the schema version marker helps identify which Specrew version wrote it

### Edge Cases

- What happens when a state file is manually corrupted or contains invalid JSON/YAML syntax?
  - System should detect parse errors and provide clear error messages indicating which file is invalid, without affecting other state files
- How does the system handle partial state (e.g., file:///[project]/.specrew/ directory exists but individual files are missing)?
  - System should tolerate missing optional files and initialize with safe defaults, logging which files were missing
- What happens when a future breaking change requires a schema version bump from v1 to v2?
  - Readers should explicitly check schema version and apply version-specific logic; migration paths should be documented
- How does the system behave when a developer downgrades Specrew to an older version?
  - Older Specrew versions may not recognize newer schema versions; system should fail gracefully with clear error messages rather than silent corruption
- What if a state file has a schema version higher than what the current Specrew version supports?
  - System should detect this and provide a clear error: "This file requires Specrew version X.Y.Z or higher. Current version: A.B.C"

## Requirements *(mandatory)*

### Functional Requirements

#### Schema Versioning (Iteration 1)

- **FR-001**: System MUST add an explicit `schema: v1` field to every Specrew-managed state file written after this feature ships
  - Applies to: file:///[project]/.specrew/config.yml, file:///[project]/.specrew/start-context.json, file:///[project]/.specify/feature.json, file:///[project]/.squad/identity/now.md frontmatter, file:///[project]/.specrew/last-validator-summary.json
  - Exception: file:///[project]/tasks-progress.yml and file:///[project]/.specrew/version-check-cache.json already have schema markers (from F-020); reaffirm those
  
- **FR-002**: System MUST treat any state file lacking a schema field as schema version 0 (v0) for backward compatibility
  - When reading a v0 file, system MUST log "schema-implied-v0" at debug level
  
- **FR-003**: System MUST distinguish between extension content version and schema version in file:///[project]/.specify/extensions/specrew-speckit/extension.yml
  - Existing `version:` field refers to extension content version
  - Add separate `schema: v1` field for schema version

#### Reader Tolerance (Iteration 1)

- **FR-004**: System MUST use hashtable-based data structures (not PSCustomObject) when parsing JSON and YAML state files
  - PowerShell: use `ConvertFrom-Json -AsHashtable` for JSON; use YAML parsers that return hashtables
  - Rationale: Hashtable indexers return `$null` for missing keys; PSCustomObject property access throws under StrictMode
  
- **FR-005**: System MUST NOT throw exceptions when accessing optional fields that don't exist in a state file
  - All fields are optional unless explicitly documented as required for a specific schema version
  - Missing optional fields MUST default to appropriate null/empty values (`$null`, `''`, `@()`)
  
- **FR-006**: System MUST provide schema-version-aware dispatch logic when reader behavior differs between v0 and v1+
  - Include comments in code identifying which schema version each code path handles
  - Example: `if ($schema -eq 'v0') { # Legacy compatibility: field X didn't exist }` 

#### Legacy State Fixture Corpus (Iteration 1)

- **FR-007**: System MUST maintain a test fixture corpus under file:///C:/Dev/Specrew/tests/fixtures/legacy-versions/ containing representative state files from each shipped Specrew version (0.18.0, 0.19.0, 0.20.0, 0.21.0, 0.22.0, and future versions)
  - Each fixture directory contains: .specrew/config.yml, .specrew/start-context.json, .specrew/last-validator-summary.json, .specify/feature.json, .specify/extensions/specrew-speckit/extension.yml, .squad/identity/now.md, tasks-progress.yml (if applicable for that version)
  
- **FR-008**: System MUST execute all state reader functions against all legacy fixtures in continuous integration (CI) on every pull request
  - Pass criteria: no exceptions thrown, no `$null` reference errors, return values structurally consistent with function contracts
  - Readers in scope: `Get-SpecrewStartContextSessionState`, `Get-FeatureJson`, `Get-ConfigMap`, `Get-SpecrewIdentitySessionState`, and any other function reading from file:///[project]/.specrew/*, file:///[project]/.specify/*, or file:///[project]/.squad/*
  
- **FR-009**: System MUST add a new fixture directory when any feature bumps a schema version
  - Feature closeout requirements must include "add fixture for version X.Y.Z to legacy-versions/"

#### Validator Rule (Iteration 2)

- **FR-010**: System MUST provide a validator rule (gap #11 extending Proposal 004) that enforces hashtable-based JSON parsing in state readers
  - Rule scope: PowerShell functions whose name matches `Get-Specrew*SessionState`, `Get-Specrew*State`, or any function reading from .specrew/*, .specify/*, .squad/* paths
  - Rule check: if function includes `ConvertFrom-Json`, it MUST use the `-AsHashtable` parameter
  - Violation severity: error (blocks PR merge)
  
- **FR-011**: Validator rule MUST provide clear violation messages with remediation guidance
  - Example: "Function Get-XYZ uses ConvertFrom-Json without -AsHashtable. State readers must use hashtables to tolerate missing fields. Add -AsHashtable parameter."

#### Documentation & Closeout Template (Iteration 2)

- **FR-012**: System MUST provide documentation at file:///C:/Dev/Specrew/docs/data-contracts.md explaining schema versioning discipline, reader tolerance principles, and how to add new fixtures
  
- **FR-013**: System MUST update the feature closeout template to include a reminder: "If this feature modified any state file schema, add a legacy fixture for the current Specrew version"

#### Cross-Platform Validation (Both Iterations)

- **FR-014**: System MUST test all reader changes on both Windows and Linux explicitly
  - CI pipeline must include Linux test lane
  - Rationale: Cross-platform bugs were a motivating factor (2026-05-19 WSL trial surfaced six bugs)

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story MUST map to one or more functional requirements.
  - User Story 1 → FR-001, FR-002, FR-004, FR-005, FR-006, FR-008, FR-014
  - User Story 2 → FR-002, FR-005, FR-006, FR-008
  - User Story 3 → FR-001, FR-002, FR-003, FR-009
  
- **TG-002**: Each requirement MUST identify expected owner role(s).
  - FR-001 through FR-014: Implementation by AI-driven developer agents (Specrew's normal development model)
  - Schema design decisions: Specrew maintainer (human oversight)
  - Fixture content validation: Specrew maintainer (human oversight at PR merge)
  
- **TG-003**: Each requirement MUST identify intended iteration or delivery window.
  - Iteration 1 (~14.5 SP): FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-009, FR-014
  - Iteration 2 (~5.5 SP): FR-010, FR-011, FR-012, FR-013, FR-014 (continued)
  
- **TG-004**: Any known spec/implementation conflict MUST include an explicit reconciliation path.
  - No known conflicts at specification time
  - Reconciliation process: if conflicts emerge during implementation, apply 3-cycle repair budget pattern at the clarify/plan boundary (feedback rule 2026-05-18)

### Key Entities *(include if feature involves data)*

- **State File**: A persisted JSON or YAML file managed by Specrew that contains configuration, session state, or feature metadata
  - Key attributes: file path (e.g., file:///[project]/.specrew/config.yml), schema version (e.g., v0, v1), content structure (varies by file type)
  - Lifecycle: written by Specrew commands, read by subsequent Specrew operations, may persist across version upgrades
  
- **Schema Version Marker**: A top-level field in a state file indicating its structural contract version
  - Key attributes: version identifier (e.g., "v1"), format (string), location (top-level field named "schema")
  - Purpose: enables readers to apply version-specific compatibility logic
  
- **Legacy Fixture**: A test artifact representing the state files from a specific Specrew version
  - Key attributes: Specrew version (e.g., "0.19.0"), file set (config, start-context, feature metadata), location (file:///C:/Dev/Specrew/tests/fixtures/legacy-versions/[version]/)
  - Purpose: exercised by CI to ensure reader tolerance across versions

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Zero crashes reported from legacy state files after upgrade in production use (target: 0 incidents in 3 months post-release)
  - Baseline: 2026-05-19 WSL trial surfaced 1 critical crash from legacy start-context.json
  
- **SC-002**: All Specrew state readers pass CI tests against legacy fixtures from versions 0.18.0 through 0.22.0 without exceptions (target: 100% pass rate)
  
- **SC-003**: Schema version markers present in 100% of newly written state files after this feature ships
  
- **SC-004**: Reader tolerance validator rule detects 100% of PSCustomObject-based JSON parsing in state readers (target: 0 false negatives in manual audit)
  
- **SC-005**: Developer time to diagnose and resolve state file compatibility issues reduced by 80% (target: from ~30 minutes to ~6 minutes per incident)
  - Measured by support ticket resolution time and session logs
  
- **SC-006**: All reader changes validated on both Windows and Linux before merge (target: 100% of PRs touching state readers include cross-platform CI evidence)

## Assumptions

- **Bootstrap Assumption**: This feature's own readers and writers will demonstrate the schema versioning and reader tolerance patterns being established, serving as reference implementations for future features
  
- **CI Infrastructure**: Specrew's CI pipeline has capacity to run the legacy fixture test suite on every PR without significant performance degradation (estimated: +2 minutes per PR, acceptable within 10-minute CI budget)
  
- **PowerShell Version**: Specrew requires PowerShell 7.0+ (per Specrew.psd1), so `ConvertFrom-Json -AsHashtable` is available (parameter introduced in PS 6.0)
  
- **Fixture Maintenance**: Future releases will continue the discipline of adding new fixtures when schemas evolve, per updated closeout template (FR-013)
  
- **Migration Writer Policy**: When a reader detects a v0 file, it reads in compatibility mode but silently upgrades on next write (no user prompt). User-visible config files may log a one-time upgrade notice; opaque caches upgrade silently.
  
- **Validator Scope**: Validator rule (FR-010) starts narrow (state readers only) and may widen to all PowerShell scripts in future iterations based on Phase 2 retrospective findings
  
- **Non-Breaking Change**: This feature introduces additive schema changes (adding `schema: v1` field) but no breaking changes to existing fields. Future breaking changes will require explicit migration strategies.
  
- **Cross-Platform Line Endings**: Git's `core.autocrlf` setting normalizes line endings for text files, so fixtures committed from Windows or Linux will have consistent content when checked out on either platform
  
- **Fixture Generation Strategy**: Iteration 1 fixtures (0.18.0 through 0.22.0) will be hand-curated from real project snapshots. Future fixtures (0.23.0+) may be generated by running `specrew init` + recorded lifecycle, or hand-curated for edge cases as appropriate.

## Scope Boundaries

### In Scope

- Schema versioning discipline for all currently persisted Specrew state files
- Reader tolerance principle enforcement via hashtable-based parsing
- Legacy fixture corpus for versions 0.18.0 through 0.22.0 (Iteration 1)
- Validator rule for reader patterns (Iteration 2)
- Documentation of schema discipline at file:///C:/Dev/Specrew/docs/data-contracts.md (Iteration 2)
- Cross-platform validation (Windows and Linux) for all reader changes
- Always-in-flow discipline: universal evidence at every boundary (feedback rule 2026-05-18)
- 3-cycle repair budget pattern at clarify/plan/tasks boundaries
- Bootstrap principle: F-023's own implementation demonstrates the pattern

### Out of Scope (Explicitly Deferred)

- **F-021 Slash-Command Surface Investigation**: The question of whether Copilot CLI exposes `/specrew.*` commands as first-class remains open and is independent of F-023. No dependency.
  
- **Breaking Schema Changes**: This feature addresses additive schema evolution only. Breaking changes (e.g., removing or renaming required fields) are deferred to future proposals when needed.
  
- **Roadmap Spine Schema**: Proposal 057 (Roadmap Spine) will define file:///[project]/.specrew/roadmap.yml schema from day 1 using the discipline established by F-023, but roadmap.yml itself is out of scope for F-023.
  
- **Multi-Developer Reconciliation**: Proposal 010 addresses merge conflict resolution and concurrent edit handling. F-023 provides schema-version tolerance as a precursor, but multi-developer reconciliation logic is out of scope.
  
- **Automated Schema Migration UI**: This feature uses silent upgrade-on-write for most files. A future proposal may add explicit migration prompts or commands (e.g., `specrew migrate-state`) but that is deferred.
  
- **Binary State Files**: All Specrew state files are text (JSON/YAML). Binary state file handling is out of scope.
  
- **Performance Optimization**: The fixture test suite is designed for correctness, not performance. If CI time grows beyond 10 minutes, optimization is deferred to a future proposal.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Specrew maintainer (human) — accountable for schema design decisions, fixture content validation, and alignment with Proposals 059/060/042 triad
  
- **Iteration Facilitator**: AI-driven session orchestrator — accountable for iteration cadence, 3-cycle repair budget enforcement at boundaries, and blocker escalation
  
- **Capacity Model**: Story points (SP) as effort unit; ~14.5 SP for Iteration 1, ~5.5 SP for Iteration 2. Iteration capacity: standard Specrew development cadence (1-2 weeks per iteration).
  
- **Drift Signals**: 
  - **Spec-to-plan drift**: Detected by `/speckit.specrew-speckit.before-plan` validator (existing hook)
  - **Plan-to-tasks drift**: Detected by `/speckit.specrew-speckit.after-tasks` validator (existing hook)
  - **Tasks-to-implementation drift**: Detected by PR-time validator runs against legacy fixtures (FR-008); failures block merge
  - **Cross-artifact consistency**: Proposal 030 (Quality Hardening Bundle) patterns apply — form-vs-meaning checks at boundaries
  
- **Human Oversight Points**:
  - **Before planning**: Human review of clarified spec to confirm schema versioning strategy aligns with long-term roadmap (Proposals 057, 010)
  - **After Iteration 1 closeout**: Human review of fixture corpus completeness (verify 0.18.0-0.22.0 fixtures exercise all readers)
  - **Before Iteration 2 merge**: Human review of validator rule to ensure it doesn't produce false positives
  - **Final PR merge**: Human review of file:///C:/Dev/Specrew/docs/data-contracts.md for clarity and completeness

## Cross-References

- **Source Proposal**: file:///C:/Dev/Specrew/proposals/059-legacy-state-read-tolerance.md (Phase 2, Tier 1)
- **Proposal Triad Context**: F-023 is the first of the 059 → 060 → 042 Iteration 1 bug-prevention triad
  - file:///C:/Dev/Specrew/proposals/060-prerelease-channel-staging.md (staging channel for safer upgrades)
  - file:///C:/Dev/Specrew/proposals/042-specrew-integration-test-suite.md (E2E lifecycle tests)
- **Composes With**:
  - file:///C:/Dev/Specrew/proposals/030-quality-hardening-bundle.md (form-vs-meaning discipline)
  - file:///C:/Dev/Specrew/proposals/035-session-state-durability.md (F-020/F-022 — the schema this generalizes)
- **Motivating Evidence**:
  - 2026-05-19 WSL trial: six bugs in one session, four were form-vs-meaning gaps
  - Hotfix b97a74b: one-function patch for start-context.json crash; F-023 generalizes the discipline

## Notes

- **file:/// URL Format**: All path references in this spec use file:/// URI format per Specrew discipline
- **Always-In-Flow**: This spec adheres to feedback rule 2026-05-18 — universal evidence at every boundary, no orphaned validation runs
- **Recovery Context**: This is a fresh Feature 023 intake; previous F-022 session state is stale and not resumed per recovery choice B
