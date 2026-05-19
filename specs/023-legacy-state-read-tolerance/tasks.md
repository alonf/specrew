---
description: "Tasks for Feature 023: Legacy-State Read-Tolerance + Schema Migration Discipline"
---

# Tasks: Legacy-State Read-Tolerance + Schema Migration Discipline

**Feature Branch**: `023-legacy-state-read-tolerance`  
**Input**: Design documents from `/specs/023-legacy-state-read-tolerance/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/state-file-schema-v1.md, quickstart.md

**Organization**: Tasks are grouped into two iterations as mandated by the spec. Iteration 1 (~14.5 SP) establishes schema markers, reader migrations, and legacy fixture corpus. Iteration 2 (~5.5 SP) adds validator rule, documentation, and closeout template updates.

**Format**: `- [ ] T### [P?] [assigned_to: role] [effort: SP] Description with exact file path(s) (Trace: requirement-id)`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[assigned_to]**: Responsible role (AI-Developer, AI-Facilitator, Human-Steward)
- **[effort]**: Story Points (SP) - repo's bounded capacity unit per plan.md
- Include exact file paths in descriptions
- Include explicit traceability to FR-### requirements

---

## Iteration 1: Schema Markers + Reader Migrations + Legacy Fixtures (~14.5 SP)

**Purpose**: Establish schema versioning discipline, migrate readers to hashtable-based parsing, create legacy fixture corpus for continuous regression testing on Windows and Linux.

**Critical Path**: Setup (T001-T002) → State Reader Audit (T003) → BLOCKS → Reader Migrations (T004-T008) → Legacy Schema Handling (T032) while Schema Markers (T009-T014) run in parallel → Fixture Corpus (T015-T019, T033, T020) → Integration Tests (T021-T023) → Linux CI (T024)

**Success Criteria**: Zero crashes from legacy state files (SC-001), 100% pass rate for fixture tests (SC-002), 100% schema markers in new state files (SC-003), cross-platform CI evidence (SC-006)

### Phase 1.1: Setup & Infrastructure

- [X] T001 [assigned_to: AI-Developer] [effort: 0.5 SP] Create legacy fixture directory structure at tests/fixtures/legacy-versions/ with subdirectories for 0.18.0, 0.19.0, 0.20.0, 0.21.0, 0.22.0 (Trace: FR-007)
- [X] T002 [assigned_to: AI-Developer] [effort: 0.5 SP] Create Pester test script tests/integration/Test-LegacyStateReaders.Tests.ps1 with test structure per quickstart.md template (Trace: FR-008)

**Checkpoint**: Test infrastructure ready for fixture population and reader migrations

---

### Phase 1.2: State Reader Audit

- [X] T003 [assigned_to: AI-Developer] [effort: 1 SP] Audit all PowerShell scripts in scripts/ and .specify/extensions/ to identify state reader functions using ConvertFrom-Json; generate specs/023-legacy-state-read-tolerance/checklists/state-reader-audit.md mapping each reader to its state files, whether missing schema must be treated as v0, and where v0/v1 dispatch comments are required per research.md Decision 2 table (Trace: FR-002, FR-004, FR-005, FR-006)

**Checkpoint**: Complete inventory of state readers ready for hashtable migration; blocks all reader migration tasks

**Independent Test**: Run audit script and verify output matches research.md table (13 scripts identified)

---

### Phase 1.3: High-Priority Reader Migrations (BLOCKS Iteration 1 Completion)

**Purpose**: Migrate HIGH-priority readers that cause crashes or StrictMode errors

- [X] T004 [P] [assigned_to: AI-Developer] [effort: 0.5 SP] Migrate scripts/specrew-start.ps1 line 375 feature.json parsing to use ConvertFrom-Json -AsHashtable -Depth 12; replace all PSCustomObject property access ($state.field) with hashtable indexer ($state['field']) (Trace: FR-004, FR-005, research.md Decision 2)
- [X] T005 [P] [assigned_to: AI-Developer] [effort: 0.5 SP] Migrate scripts/internal/worktree-awareness.ps1 lines 57-75 feature.json parsing to use ConvertFrom-Json -AsHashtable -Depth 12; replace PSCustomObject property access with hashtable indexers (Trace: FR-004, FR-005, research.md Decision 2)
- [X] T006 [P] [assigned_to: AI-Developer] [effort: 0.5 SP] Migrate .specify/extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1 lines 106-121 feature.json parsing to use ConvertFrom-Json -AsHashtable -Depth 12 plus null-safe access for missing feature_directory field (Trace: FR-004, FR-005, research.md Decision 2)
- [X] T007 [P] [assigned_to: AI-Developer] [effort: 0.5 SP] Migrate scripts/internal/version-check.ps1 lines 113-143 version-check-cache.json parsing to use ConvertFrom-Json -AsHashtable -Depth 12; handle optional fields safely per FR-005 (Trace: FR-004, FR-005, research.md Decision 2)
- [X] T008 [P] [assigned_to: AI-Developer] [effort: 0.5 SP] Migrate scripts/internal/coordinator-resume.ps1 lines 28-56 last-validator-summary.json parsing to use ConvertFrom-Json -AsHashtable -Depth 12; replace try/catch with null-safe hashtable access (Trace: FR-004, FR-005, research.md Decision 2)
- [X] T032 [assigned_to: AI-Developer] [effort: 0.5 SP] Update migrated legacy-state readers in scripts/specrew-start.ps1, scripts/internal/worktree-awareness.ps1, .specify/extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1, and scripts/internal/coordinator-resume.ps1 to treat a missing top-level schema field as v0, emit `schema-implied-v0` debug logging for legacy reads, and add inline comments wherever v0/v1 reader behavior diverges per contracts/state-file-schema-v1.md Reader Contract (Trace: FR-002, FR-006)

**Checkpoint**: All HIGH-priority readers migrated and legacy schema handling added; StrictMode compatibility achieved for crash-prone code paths

**Independent Test**: Run each migrated script against missing-field legacy state files; verify no PropertyNotFoundException thrown under Set-StrictMode -Version Latest and debug output includes `schema-implied-v0` when schema is absent

- [X] T034 [assigned_to: Human-Steward] [effort: 0.5 SP] Review the v0/v1 dispatch logic and inline schema-version comments added by T032 in scripts/specrew-start.ps1, scripts/internal/worktree-awareness.ps1, .specify/extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1, and scripts/internal/coordinator-resume.ps1; approved with no further changes required because the explicit v0/v1 comment-pair pattern is now the forward-looking discipline (Trace: FR-006, plan.md Human Oversight)

---

### Phase 1.4: Schema Markers for State Writers

**Purpose**: Add explicit schema: v1 markers to all state file writers

- [X] T009 [P] [assigned_to: AI-Developer] [effort: 0.5 SP] Add schema: v1 marker to scripts/specrew-init.ps1 writer for .specrew/config.yml (YAML format) per contracts/state-file-schema-v1.md Writer Contract (Trace: FR-001)
- [X] T010 [P] [assigned_to: AI-Developer] [effort: 0.5 SP] Add schema: v1 marker to scripts/specrew-start.ps1 writer for .specrew/start-context.json (JSON format) per contracts/state-file-schema-v1.md Writer Contract (Trace: FR-001)
- [X] T011 [P] [assigned_to: AI-Developer] [effort: 0.5 SP] Add schema: v1 marker to validator framework writer for .specrew/last-validator-summary.json (JSON format) per contracts/state-file-schema-v1.md Writer Contract (Trace: FR-001)
- [X] T012 [P] [assigned_to: AI-Developer] [effort: 0.5 SP] Add schema: v1 marker to .specify/feature.json writers in scaffold scripts (JSON format) per contracts/state-file-schema-v1.md Writer Contract (Trace: FR-001)
- [X] T013 [P] [assigned_to: AI-Developer] [effort: 0.5 SP] Add separate schema: v1 field to .specify/extensions/specrew-speckit/extension.yml writer (distinct from extension.version field per FR-003) in YAML format (Trace: FR-001, FR-003, contracts/state-file-schema-v1.md)
- [X] T014 [P] [assigned_to: AI-Developer] [effort: 0.5 SP] Add schema: v1 marker to scripts/internal/sync-boundary-state.ps1 writer for .squad/identity/now.md frontmatter (YAML frontmatter format) per contracts/state-file-schema-v1.md Writer Contract (Trace: FR-001)

**Checkpoint**: All state writers include schema: v1 markers; new state files satisfy SC-003

**Independent Test**: Create new project with specrew init; verify all state files contain schema: v1 marker

---

### Phase 1.5: Legacy Fixture Corpus Generation

**Purpose**: Hand-curate legacy fixtures from versions 0.18.0-0.22.0 and add the current 0.23.0 schema-v1 fixture for regression testing

- [X] T015 [P] [assigned_to: AI-Developer] [effort: 0.5 SP] Hand-curate tests/fixtures/legacy-versions/0.18.0/ state files from real 0.18.0 project snapshot: .specrew/config.yml, .specrew/start-context.json, .specify/feature.json per FR-007 catalog (Trace: FR-007, research.md Decision 4)
- [X] T016 [P] [assigned_to: AI-Developer] [effort: 0.5 SP] Hand-curate tests/fixtures/legacy-versions/0.19.0/ state files from real 0.19.0 project snapshot (motivating crash repro with missing session_state field in start-context.json) per FR-007 catalog (Trace: FR-007, research.md Decision 4)
- [X] T017 [P] [assigned_to: AI-Developer] [effort: 0.5 SP] Hand-curate tests/fixtures/legacy-versions/0.20.0/ state files from real 0.20.0 project snapshot per FR-007 catalog (Trace: FR-007, research.md Decision 4)
- [X] T018 [P] [assigned_to: AI-Developer] [effort: 0.5 SP] Hand-curate tests/fixtures/legacy-versions/0.21.0/ state files from real 0.21.0 project snapshot per FR-007 catalog including tasks-progress.yml (Trace: FR-007, research.md Decision 4)
- [X] T019 [P] [assigned_to: AI-Developer] [effort: 0.5 SP] Hand-curate tests/fixtures/legacy-versions/0.22.0/ state files from real 0.22.0 project snapshot per FR-007 catalog (Trace: FR-007, research.md Decision 4)
- [X] T033 [assigned_to: AI-Developer] [effort: 0.5 SP] Add tests/fixtures/legacy-versions/0.23.0/ from a post-migration Specrew 0.23.0 project snapshot with `schema: v1` state files so this feature's schema bump leaves behind the required current-version fixture directory (Trace: FR-007, FR-009, spec.md Fixture Generation Strategy)
- [X] T020 [assigned_to: Human-Steward] [effort: 0.5 SP] Human review of fixture corpus completeness: verify all 6 versions (0.18.0-0.23.0) exercise all state readers from T003 audit, confirm the new 0.23.0 fixture exists because this feature introduced schema v1, and validate edge cases covered (missing optional fields, partial state, crash repro 0.19.0); approved after adding the fixture coverage matrix and written absence rationale to `checklists/state-reader-audit.md` (Trace: FR-007, FR-009, plan.md Human Oversight)

**Checkpoint**: Legacy fixture corpus complete for versions 0.18.0-0.23.0; ready for CI integration

**Independent Test**: Manually inspect each fixture directory; verify historical fixtures remain version-appropriate and the 0.23.0 fixture contains explicit `schema: v1` markers per data-model.md

---

### Phase 1.6: Regression Tests Against Legacy Fixtures

**Purpose**: Implement Pester tests invoking all state readers against all legacy fixtures

- [X] T021 [assigned_to: AI-Developer] [effort: 1 SP] Implement Pester tests in tests/integration/Test-LegacyStateReaders.Tests.ps1 for each reader function (Get-SpecrewStartContextSessionState, Get-FeatureJson, Get-ConfigMap, Get-SpecrewIdentitySessionState, etc.) against each fixture version (0.18.0-0.23.0); verify no exceptions, no $null reference errors per FR-008 pass criteria, and `schema-implied-v0` debug logging for legacy fixtures without explicit schema fields (Trace: FR-002, FR-008, quickstart.md Pester template)
- [X] T022 [assigned_to: AI-Developer] [effort: 0.5 SP] Add negative test cases to tests/integration/Test-LegacyStateReaders.Tests.ps1 for parse errors, missing files, unsupported schema versions per spec.md Edge Cases (Trace: FR-008, spec.md Edge Cases)
- [X] T023 [assigned_to: AI-Developer] [effort: 0.5 SP] Run tests/integration/Test-LegacyStateReaders.Tests.ps1 on Windows; verify 100% pass rate for all readers against all fixtures and retain Windows evidence for the required cross-platform validation pair with T024 (Trace: FR-008, FR-014, SC-002, SC-006)

**Checkpoint**: All legacy fixture tests pass on Windows; ready for Linux CI integration

**Independent Test**: Invoke-Pester tests/integration/Test-LegacyStateReaders.Tests.ps1 → all tests pass

---

### Phase 1.7: Cross-Platform CI Integration (Linux Validation)

**Purpose**: Extend CI workflow to include Linux test lane per FR-014

- [X] T024 [assigned_to: AI-Developer] [effort: 0.5 SP] Add Linux test lane to .github/workflows/specrew-ci.yml after validator step: run pwsh -File tests/integration/Test-LegacyStateReaders.Tests.ps1 on ubuntu-latest runner per research.md Decision 6 (Trace: FR-014, research.md Decision 6)

**Checkpoint**: Linux CI lane active; all PRs touching state readers require cross-platform evidence (SC-006)

**Independent Test**: Trigger CI workflow; verify Linux lane runs tests/integration/Test-LegacyStateReaders.Tests.ps1 and passes

---

## Iteration 1 Acceptance

**Delivery Goal**: Iteration 1 complete when:

1. All HIGH-priority state readers migrated to hashtables with legacy schema handling and human-approved dispatch logic (T004-T008, T032, T034)
2. All state writers include schema: v1 markers (T009-T014)
3. Legacy fixture corpus (0.18.0-0.23.0) complete and human-reviewed (T015-T020, T033)
4. Regression tests pass 100% on Windows and Linux (T021-T024)
5. Bootstrap principle satisfied: F-023's own readers/writers demonstrate the pattern

**Independent Test**: Run specrew start on a 0.19.0 project (motivating crash repro) after upgrade to 0.23.0 → no crashes, full functionality

**Verification Command**:

```powershell
# Run full Iteration 1 test suite
Invoke-Pester tests/integration/Test-LegacyStateReaders.Tests.ps1 -Output Detailed
# Verify all tests pass on Windows and Linux
# Expected: 0 failures, 0 exceptions
```

**Human Oversight**: After T020 fixture corpus review, Human Steward approves fixture completeness before proceeding to Iteration 2

---

## Iteration 2: Validator Rule + Documentation + Closeout Template (~5.5 SP)

**Purpose**: Add validator rule to enforce reader tolerance pattern, document schema versioning discipline, update closeout template to maintain fixture corpus for future versions.

**Critical Path**: Validator Rule Implementation (T025-T027) → BLOCKS → Validator Effectiveness Audit (T028) → Documentation (T029-T030) can run in parallel with Closeout Template Update (T031)

**Success Criteria**: Validator detects 100% PSCustomObject-based state readers (SC-004), documentation complete (FR-012), closeout template updated (FR-013)

### Phase 2.1: Validator Rule Implementation (gap #11)

- [X] T025 [assigned_to: AI-Developer] [effort: 1.5 SP] Implement Test-ReaderTolerance function in .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 per research.md Decision 5 structure: scope to Get-Specrew*State functions or scripts reading .specrew/*, .specify/*, .squad/* paths; check ConvertFrom-Json lacks -AsHashtable; emit structured violations with category "reader-tolerance" per FR-011 (Trace: FR-010, FR-011, research.md Decision 5)
- [X] T026 [assigned_to: AI-Developer] [effort: 0.5 SP] Integrate Test-ReaderTolerance call into main validator orchestration in .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 near existing Test-StateArtifact, Test-ReviewArtifact calls (Trace: FR-010, research.md Decision 5)
- [X] T027 [assigned_to: AI-Developer] [effort: 0.5 SP] Add validator invocation to .github/workflows/specrew-ci.yml PR checks: run validate-governance.ps1 -ProjectPath . and block merge on "reader-tolerance" violations (Trace: FR-010, FR-011)

**Checkpoint**: Validator rule active in CI; all PRs checked for hashtable compliance

**Independent Test**: Manually create script with ConvertFrom-Json (no -AsHashtable) reading .specrew/config.yml; run validator; verify violation detected

---

### Phase 2.2: Validator Effectiveness Audit

- [X] T028 [assigned_to: Human-Steward] [effort: 1 SP] Manual audit of all PowerShell scripts using ConvertFrom-Json: verify validator detects 100% of PSCustomObject-based state readers (SC-004); check for false positives (scripts reading non-state JSON files); human review before Iteration 2 merge; approved as v1 with the mirrored heuristic-widening TODO recorded above the validator allowlist (Trace: FR-010, FR-011, SC-004, plan.md Human Oversight)

**Checkpoint**: Validator rule effectiveness confirmed; zero false negatives, minimal false positives

**Independent Test**: Compare validator output to T003 audit report; verify all HIGH-priority readers from research.md Decision 2 would be caught if not migrated

---

### Phase 2.3: Documentation

- [X] T029 [P] [assigned_to: AI-Developer] [effort: 1 SP] Create docs/data-contracts.md per FR-012 requirements: schema versioning discipline (v0 → v1 → v2 evolution), reader tolerance principles (hashtable-based parsing, StrictMode compatibility), writer contract (always include schema: v1), reader contract (use -AsHashtable, handle missing fields gracefully), how to add new fixtures when schema evolves, cross-platform considerations (line endings, path separators) per quickstart.md Resources section (Trace: FR-012, contracts/state-file-schema-v1.md)
- [X] T030 [assigned_to: Human-Steward] [effort: 0.5 SP] Human review of docs/data-contracts.md for clarity, completeness, and alignment with contracts/state-file-schema-v1.md; final approval before Iteration 2 merge after adding the schema-helper and regression-contract bullets (Trace: FR-012, plan.md Human Oversight)

**Checkpoint**: Documentation complete and human-approved

**Independent Test**: Developer reads docs/data-contracts.md and can answer: "How do I add a new state file?" and "How do I add a fixture for a new schema version?"

---

### Phase 2.4: Closeout Template Update

- [X] T031 [P] [assigned_to: AI-Developer] [effort: 0.5 SP] Update .specify/templates/closeout-template.md per FR-013: add reminder "If this feature modified any state file schema, add a legacy fixture for the current Specrew version to tests/fixtures/legacy-versions/" with instructions for hand-curated vs generated vs snapshot-based fixture generation (Trace: FR-013)

**Checkpoint**: Closeout template updated; future features will maintain fixture corpus discipline

**Independent Test**: Review closeout template; verify reminder is visible and actionable

---

## Iteration 2 Acceptance

**Delivery Goal**: Iteration 2 complete when:

1. Validator rule implemented and integrated into CI (T025-T027)
2. Validator effectiveness confirmed by human audit (T028, SC-004)
3. Documentation complete and human-approved (T029-T030)
4. Closeout template updated (T031)

**Independent Test**: Create new script with PSCustomObject-based state reader; run validator; verify violation detected and remediation hint clear

**Verification Command**:

```powershell
# Run validator with manual test violation
pwsh -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .
# Expected: "reader-tolerance" violation detected for test script
```

**Human Oversight**: After T028 validator audit and T030 documentation review, Human Steward approves Iteration 2 merge

---

## Dependencies & Execution Order

### Iteration Dependencies

- **Iteration 1**: No external dependencies; can start immediately after planning
- **Iteration 2**: Depends on Iteration 1 completion (reader migrations provide validator test cases)

### Within Iteration 1

1. **Setup (T001-T002)** → **State Reader Audit (T003)** [BLOCKS all reader migrations]
2. **State Reader Audit (T003)** → **Reader Migrations (T004-T008)** → **Legacy Schema Handling (T032)** → **Dispatch Review (T034)** [HIGH-priority, T004-T008 can run in parallel before T032]
3. **State Reader Audit (T003)** → **Schema Markers (T009-T014)** [can run in parallel with reader migrations]
4. **Setup (T001)** → **Fixture Corpus (T015-T019, T033)** [can run in parallel with reader migrations and schema markers]
5. **Fixture Corpus (T015-T019, T033)** → **Fixture Review (T020)** [BLOCKS Iteration 1 completion]
6. **Reader Migrations (T004-T008, T032, T034) + Setup (T002)** → **Regression Tests (T021-T023)** [depends on migrated readers, legacy schema handling, dispatch approval, and test infrastructure]
7. **Regression Tests (T023)** → **Linux CI (T024)** [final Iteration 1 task]

### Within Iteration 2

1. **Validator Rule (T025-T027)** → **Validator Audit (T028)** [BLOCKS Iteration 2 completion]
2. **Validator Rule (T025-T027)** → **Documentation (T029)** [can run in parallel after T027]
3. **Documentation (T029)** → **Documentation Review (T030)** [BLOCKS Iteration 2 completion]
4. **Validator Rule (T025-T027)** → **Closeout Template (T031)** [can run in parallel with T029]

### Parallel Opportunities

**Iteration 1 Parallelism**:

- After T003 audit completes:
  - T004-T008 (reader migrations) can run in parallel (different files)
  - T032 (legacy schema handling + dispatch comments) follows the reader migrations once affected readers are updated
  - T034 (dispatch review) follows T032 before regression tests begin
  - T009-T014 (schema markers) can run in parallel (different files)
  - T015-T019 and T033 (fixture corpus) can run in parallel (different fixture directories)
- T021-T023 (regression tests) are sequential but T022 and T023 can overlap if T021 partial results available

**Iteration 2 Parallelism**:

- After T027 validator integration:
  - T028 (validator audit) runs independently
  - T029 (documentation) can run in parallel with T031 (closeout template)

---

## Parallel Example: Iteration 1 Reader Migrations

```bash
# Launch all HIGH-priority reader migrations together after T003 audit:
Task T004: "Migrate scripts/specrew-start.ps1 line 375"
Task T005: "Migrate scripts/internal/worktree-awareness.ps1 lines 57-75"
Task T006: "Migrate scaffold-feature-closeout-dashboard.ps1 lines 106-121"
Task T007: "Migrate scripts/internal/version-check.ps1 lines 113-143"
Task T008: "Migrate scripts/internal/coordinator-resume.ps1 lines 28-56"

# All operate on different files; no dependencies between them
```

## Parallel Example: Iteration 1 Fixture Corpus

```bash
# Launch all fixture generation tasks together after T001 directory creation:
Task T015: "Hand-curate 0.18.0 fixtures"
Task T016: "Hand-curate 0.19.0 fixtures (crash repro)"
Task T017: "Hand-curate 0.20.0 fixtures"
Task T018: "Hand-curate 0.21.0 fixtures"
Task T019: "Hand-curate 0.22.0 fixtures"

# All operate on separate fixture directories; no dependencies between them
```

---

## Implementation Strategy

### Iteration 1 First (MVP Foundation)

1. Complete Setup (T001-T002)
2. Complete State Reader Audit (T003) [CRITICAL: blocks all reader migrations]
3. Complete Reader Migrations (T004-T008) + Schema Markers (T009-T014) in parallel
4. Complete Fixture Corpus (T015-T020) [includes human review gate]
5. Complete Regression Tests (T021-T023)
6. Complete Linux CI Integration (T024)
7. **STOP and VALIDATE**: All fixture tests pass on Windows and Linux; zero crashes from legacy state files

### Iteration 2 Enforcement and Documentation

1. Complete Validator Rule (T025-T027)
2. Complete Validator Audit (T028) [human review gate]
3. Complete Documentation (T029-T030) + Closeout Template (T031) in parallel
4. **STOP and VALIDATE**: Validator detects all PSCustomObject-based readers; documentation approved

### Always-in-Flow Evidence Discipline

- **Universal evidence at every boundary** (feedback rule 2026-05-18):
  - After T003: Audit report showing all state readers
  - After T020: Human-approved fixture corpus completeness review
  - After T023: CI logs showing 100% pass rate on Windows
  - After T024: CI logs showing 100% pass rate on Linux
  - After T028: Human-approved validator effectiveness audit
  - After T030: Human-approved documentation review
- **3-cycle repair budget**: At clarify/plan/tasks boundaries; conflicts escalate to human Spec Steward

---

## Notes

- **[P] marker**: Tasks marked [P] can run in parallel (different files, no dependencies)
- **Traceability**: Every task traces to FR-### functional requirement from spec.md
- **Ownership**: AI-Developer (implementation), AI-Facilitator (iteration cadence), Human-Steward (schema design, fixture validation, validator audit, docs review)
- **Capacity**: Story Points (SP) per plan.md; Iteration 1 ~14.5 SP, Iteration 2 ~5.5 SP, Total ~20 SP
- **Cross-platform**: FR-014 mandates Windows + Linux validation; T023 and T024 provide the required evidence pair
- **Bootstrap principle**: Iteration 1 implementation serves as reference implementation of schema versioning + reader tolerance patterns
- **F-021 out of scope**: Slash-command investigation explicitly non-blocking per spec.md Scope Boundaries
- **Success criteria validation**: SC-001, SC-002, SC-003, SC-004, and SC-006 map to specific execution tasks; SC-005 is a post-release operational metric measured from support ticket resolution time and session logs
- **Human oversight points**: T020 (fixture review), T028 (validator audit), T030 (docs review) per plan.md

**Total Task Count**: 34 tasks (27 in Iteration 1, 7 in Iteration 2)

**Iteration Split**:

- Iteration 1 (T001-T024 plus T032-T034): ~14.5 SP → Schema markers, reader migrations, fixture corpus, Linux CI
- Iteration 2 (T025-T031): ~5.5 SP → Validator rule, documentation, closeout template

**Dependency Sequencing**: Setup → Audit (BLOCKS) → Reader Migrations + Schema Markers + Fixtures (parallel) → Regression Tests → Linux CI → Validator Rule → Validator Audit + Documentation + Closeout (parallel) → Human Reviews

**Parallel Opportunities**: 16 tasks marked [P] in Iteration 1 (T004-T008, T009-T014, T015-T019), 2 tasks marked [P] in Iteration 2 (T029, T031)
