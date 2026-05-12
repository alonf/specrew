# Data Model: Conditional Pause on specrew-start When Session-Loaded Files Changed

**Date**: 2026-05-11  
**Spec**: [spec.md](spec.md)  
**Plan**: [plan.md](plan.md)  
**Iteration**: [iterations/001](iterations/001)

## Entities (Iteration 001 Scope Only)

### Change Detector

Mechanism for identifying whether session-loaded files have been committed between Copilot restarts.

**Location**: `scripts/specrew-start.ps1` (within detector implementation, T032)

| Field | Type | Description |
| --- | --- | --- |
| `detector_phase` | string | Execution phase: `pre-bootstrap`, `post-bootstrap`, `pre-handoff-generation` |
| `baseline_commit_hash` | string (40-char git SHA) | Reference commit for change detection (tracked in `.specrew/last-start-prompt.md` YAML frontmatter) |
| `session_loaded_paths[]` | glob pattern[] | Paths scanned for changes: `.github/agents/*`, `.github/copilot-instructions.md`, `extensions/specrew-speckit/squad-templates/coordinator/*`, `.specify/extensions/specrew-speckit/squad-templates/coordinator/*`, `.squad/agents/*/charter.md` |
| `changed_files[]` | string[] | List of session-loaded files that changed since baseline commit (empty list = no changes detected) |
| `detection_method` | string | `git diff --name-only <baseline_commit> HEAD` against session-loaded paths |

**Validation**:

- Detector must execute after bootstrap check but before handoff directive generation (T032).
- Empty `changed_files` list → preserve auto-continue directive for routine resumes (spec 001 Session 2026-05-04 behavior).
- Detector must return empty list on first run or when no session-loaded files changed between commits.
- Uncommitted working-tree changes are not scanned; committed state only.

**Iteration 001 Scope**: Detection infrastructure and baseline tracking. Pause-and-confirm message rendering deferred to Iteration 002 (User Story 2).

---

### Session-Loaded Path Match

A path glob identifying behavioral files that trigger conditional pause when changed.

**Location**: Scanned during detector execution (T032 task design)

| Field | Type | Description |
| --- | --- | --- |
| `path_glob` | string | Glob pattern for a behavioral file category |
| `rationale` | string | Why this path is considered "session-loaded" (behavioral vs. transient state) |
| `reload_trigger` | boolean | True if committing a change to this path requires user confirmation (pause-and-confirm) before auto-continue |
| `example_files[]` | string[] | Concrete examples matching the glob |

**Validation**:

- Session-loaded paths are limited to behavioral files (`.github/agents/*`, `.squad/agents/*/charter.md`, `.github/copilot-instructions.md`, Spec Kit extension templates).
- Transient session-state files (`.specrew/last-start-prompt.md`, `.specrew/last-lifecycle-state`, etc.) are not scanned.
- Path matching is case-sensitive on POSIX systems, case-insensitive on Windows (git diff behavior).

**Iteration 001 Scope**: Path glob definitions and matching logic. Pause-and-confirm behavior triggered on match deferred to Iteration 002.

---

### Baseline Commit Record

YAML frontmatter field tracking the commit baseline for change detection.

**Location**: `.specrew/last-start-prompt.md` YAML frontmatter, `baseline_commit_hash` field (T033)

| Field | Type | Description |
| --- | --- | --- |
| `baseline_commit_hash` | string (40-char git SHA) or null | The commit against which the next detector run will compare HEAD. Null or missing defaults to HEAD on first run. |
| `record_location` | string | YAML frontmatter key at top of `.specrew/last-start-prompt.md` |
| `format_validation` | regex | `^[0-9a-f]{40}$` for commit SHA format |
| `update_timing` | string | Updated to current HEAD after detector runs and before handoff directives are generated |
| `round_trip_durability` | string | Must survive YAML serialization/deserialization without corruption (YAML round-trip assertion in T040) |

**Validation**:

- Field must be present in YAML frontmatter of every `.specrew/last-start-prompt.md` after detector runs (T033).
- Invalid SHA format (not 40 hex characters) → gracefully default to HEAD and proceed (error recovery, T033).
- Missing field on first run → default to HEAD; baseline is established for subsequent runs.
- Update is atomic: read, validate, update to HEAD, write back.

**Iteration 001 Scope**: YAML frontmatter tracking and round-trip serialization. Baseline integrity testing in T040.

---

### Handoff Prompt State

Transient document state after `specrew-start.ps1` runs the change detector.

**Location**: `.specrew/last-start-prompt.md` markdown content section

| Field | Type | Description |
| --- | --- | --- |
| `state_after_detection` | enum | `routine-resume` (no changes, auto-continue preserved) or `session-files-changed` (pause triggered, iteration 002) |
| `auto_continue_directive_present` | boolean | True when state is `routine-resume`; false when changes detected (pause deferred to iteration 002) |
| `pause_and_confirm_directive_present` | boolean | False in Iteration 001; deferred to Iteration 002 (User Story 2, T047) |
| `baseline_hash_field` | string | Current value of `baseline_commit_hash` in YAML frontmatter |
| `session_ready_for_coordinator` | boolean | True when auto-continue preserved (routine resumes); false when pause needed (iteration 002) |

**Validation**:

- After detector runs: exactly one of `auto-continue` or `pause` state is true, never both.
- Routine resumes: auto-continue is preserved, handoff is ready for Squad coordinator immediately.
- Session-files-changed: pause state is set (iteration 002 rendering), user sees change list and can inject directives before coordinator continues.

**Iteration 001 Scope**: Auto-continue preservation state tracking for routine resumes (T034, T039). Pause-and-confirm state handling deferred to Iteration 002.

---

### Signature Preservation Check

Verification that `specrew-start.ps1` contract remains stable across feature changes.

**Location**: `scripts/specrew-start.ps1` parameter/signature audit (T035)

| Field | Type | Description |
| --- | --- | --- |
| `documented_parameters[]` | string[] | Official `specrew-start.ps1` parameters (e.g., `-ProjectPath`, existing params before Iteration 001; `-PostRestartDirective` deferred to Iteration 002) |
| `documented_defaults[]` | string[] | Default values for each parameter |
| `documented_return_value` | string | Documented contract for return value (e.g., "updates `.specrew/last-start-prompt.md` and returns 0 on success") |
| `error_message_locations[]` | string[] | Hardcoded error messages and their line locations (must remain unchanged across Iteration 001) |
| `breaking_change_flag` | boolean | False if all existing signatures remain unchanged (backward compatible); exception: new optional `-PostRestartDirective` parameter allowed in Iteration 002 only |

**Validation**:

- Pre-implementation: T035 scans `specrew-start.ps1` and compares documented parameters to current implementation (should match spec 001 FR-024).
- Post-implementation: Validation lane includes signature verification to ensure no breaking changes were introduced during Iteration 001.
- Error messages must not be modified in Iteration 001; new pause-and-confirm messages added additively in Iteration 002 only (T036 principle).

**Iteration 001 Scope**: Signature verification and backward-compatibility audit (T035). New optional parameter deferred to Iteration 002.

---

## Relationships

- `Change Detector` scans `Session-Loaded Path Match` globs to find changed files.
- `Baseline Commit Record` provides the comparison point for the detector.
- `Handoff Prompt State` reflects the detector's result: routine-resume (auto-continue) or session-files-changed (pause deferred to iteration 002).
- `Signature Preservation Check` ensures `specrew-start.ps1` remains operationally stable across all feature iterations.

---

## Deferred Iteration 002 Entities

The following entities and behaviors are **explicitly not in scope for Iteration 001** and are deferred to Iteration 002:

- **Pause-and-Confirm Directive Rendering**: User-facing pause message, file list display, and confirmation prompts (User Story 2, T047).
- **PostRestartDirective Parameter**: Optional `-PostRestartDirective` parameter for power users (User Story 3, T050-T054).
- **Visibility Output Structure**: Structured YAML fields or markdown sections in `.specrew/last-start-prompt.md` showing changed file list (T048, Iteration 002).
- **Scaffold-Replay-Path Testing**: Visibility assertions using `scaffold-reviewer-artifacts.ps1` and `specrew-review.ps1` (T045, Iteration 002).
- **Known-Traps Corpus Entry**: Seed corpus entry for "auto-handoff bypass" pattern (T055, Iteration 002 Polish phase).

Iteration 001 focuses solely on the **detection infrastructure, baseline tracking, and auto-continue preservation** that these Iteration 002 features depend on.
