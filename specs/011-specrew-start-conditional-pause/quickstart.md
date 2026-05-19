# Quickstart: Conditional Pause on specrew-start When Session-Loaded Files Changed

This quickstart defines the validation path for **Iteration 001 scope only**. It documents the tests planned to prove that change detection infrastructure, baseline tracking, and auto-continue preservation work correctly for routine resumes. This is a **planning artifact** and does not claim that implementation is complete.

**Date**: 2026-05-11  
**Iteration**: [iterations/001](iterations/001)  
**Scope**: Change detector, baseline tracking, auto-continue preservation (Phase 1 + Phase 2 foundational work, tasks T029-T042)

---

## Prerequisites

- PowerShell 7+
- Existing Specrew bootstrap in the target repo
- Git available in PATH
- Accepted feature 011 spec from 2026-05-11
- Approved iteration 001 plan and hardening-gate artifact
- Feature 001 Session 2026-05-04 auto-continue clarification understood (spec-001-session-2026-05-04.md or equivalent)

---

## 1. Confirm the plan is scoped to Iteration 001 only

Review `specs/011-specrew-start-conditional-pause/iterations/001/plan.md` and confirm it:

- Targets only Phase 1 + Phase 2 foundational work (change detector implementation, baseline tracking, auto-continue preservation).
- Covers tasks T029-T042 (setup, detector implementation, User Story 1 tests) only.
- **Explicitly defers** User Story 2 (pause-and-confirm directive injection), User Story 3 (optional `-PostRestartDirective` parameter), and Polish phase to Iteration 002.
- Preserves the auto-continue behavior from spec 001 Session 2026-05-04 for routine resumes (no session-loaded changes).

---

## 2. Confirm the hardening-gate artifact exists and is signed off

Review `specs/011-specrew-start-conditional-pause/iterations/001/quality/hardening-gate.md` and confirm it:

- **Overall Verdict**: `ready` (signed off by Alon Fliess on 2026-05-11)
- **Scope**: Detector infrastructure, baseline tracking, auto-continue preservation, signature stability, error-message fidelity
- **Deferred concerns**: Pause-and-confirm visibility and parameter handling (marked explicitly as Iteration 002 deferments)
- **Implementation Authorized**: Yes, for Iteration 001 scope only (T029-T042)

---

## 3. Validate the core change detector integration

The three integration tests in Iteration 001 validate the foundational change detection infrastructure:

### Test 3a: Change Detector Accuracy (`specrew-start-change-detector.ps1`)

This test validates that the `git diff --name-only` detector correctly identifies whether session-loaded files have changed.

```powershell
pwsh -NoProfile -File .\tests\integration\specrew-start-change-detector.ps1
```

**Expected Behavior**:

- Detector returns **empty list** when no session-loaded files have been committed since baseline.
- Detector returns **non-empty list** containing changed session-loaded file paths when commits exist (validates glob matching for `.github/agents/*`, `.squad/agents/*/charter.md`, etc.).
- Uncommitted working-tree changes are **not scanned** (committed state only).
- First run with no prior baseline gracefully defaults to HEAD and returns empty list.

**Required Pass Condition**:

- All detector accuracy assertions pass.
- Routine resume scenario (no changes) returns empty list consistently.

**Iteration 002 Deferment**: Tests validating pause-and-confirm trigger on changed files (T046) are deferred to Iteration 002.

---

### Test 3b: Baseline Tracking Durability (`specrew-start-baseline-tracking.ps1`)

This test validates that the baseline commit hash is correctly recorded in `.specrew/last-start-prompt.md` YAML frontmatter and survives round-trip serialization/deserialization.

```powershell
pwsh -NoProfile -File .\tests\integration\specrew-start-baseline-tracking.ps1
```

**Expected Behavior**:

- Baseline commit hash is stored in `.specrew/last-start-prompt.md` YAML frontmatter field `baseline_commit_hash`.
- Field value is exactly 40 hexadecimal characters (valid git SHA format).
- Field survives read → validate → update → write → read cycle without corruption.
- Invalid SHA format gracefully defaults to HEAD and proceeds without crashing.
- Missing field on first run defaults to HEAD, and subsequent run reads the updated hash correctly.

**Required Pass Condition**:

- YAML round-trip assertion passes: `baseline_commit_hash` field read equals field write (minus timestamp).
- Format validation passes: all stored SHA values match `^[0-9a-f]{40}$` regex.
- Fallback to HEAD works gracefully for missing/invalid field.

**Iteration 002 Deferment**: Tests validating baseline updates after pause-and-confirm (Iteration 002) are deferred.

---

### Test 3c: Auto-Continue Preservation (`specrew-start-auto-continue-preservation.ps1`)

This test validates that the auto-continue directive is preserved in regenerated `.specrew/last-start-prompt.md` when the detector finds zero changes (routine resumes), maintaining spec 001 Session 2026-05-04 behavior.

```powershell
pwsh -NoProfile -File .\tests\integration\specrew-start-auto-continue-preservation.ps1
```

**Expected Behavior**:

- When detector returns empty list (no session-loaded files changed), the regenerated `.specrew/last-start-prompt.md` **must include** an auto-continue directive.
- Auto-continue directive is verbatim and functionally identical to the directive generated by spec 001 `specrew-start.ps1` behavior.
- Running `specrew-start.ps1` multiple times in the same session state (no commits to session-loaded paths) preserves auto-continue both times.
- Squad coordinator processes the handoff and launches immediately without waiting for user input (no pause).

**Required Pass Condition**:

- Auto-continue directive is present in handoff when zero changes detected.
- Directive text is consistent and matches expected format.
- No pause-and-confirm directive is injected when changes = empty list.
- Routine resume workflow is unaffected by the new detector infrastructure.

**Iteration 002 Deferment**: Tests validating pause-and-confirm rendering when changes are detected (User Story 2, T044-T045) are deferred to Iteration 002.

---

## 4. Run the integrated test suite

Once implementation is complete, run all three Iteration 001 tests together:

```powershell
pwsh -NoProfile -File .\tests\integration\specrew-start-change-detector.ps1
pwsh -NoProfile -File .\tests\integration\specrew-start-baseline-tracking.ps1
pwsh -NoProfile -File .\tests\integration\specrew-start-auto-continue-preservation.ps1
```

**Expected Outcome**:

- All three tests pass with zero failures.
- Detector accurately identifies zero changes in routine-resume scenarios.
- Baseline commit hash survives serialization/deserialization.
- Auto-continue directive is preserved for routine resumes.

---

## 5. Enforce feature 001 signature stability (backward compatibility)

Run the signature verification scan:

```powershell
# Scan specrew-start.ps1 for parameter, default, and error-message preservation
Get-Content .\scripts\specrew-start.ps1 | Select-String -Pattern "param\(" -Context 0, 30 | Out-Host
```

**Expected Pass Condition**:

- `specrew-start.ps1` parameters (documented in spec 001 FR-024) are unchanged.
- Error messages ("Project is not fully bootstrapped", "Session state invalid", etc.) remain in their current locations.
- No breaking changes to public contract (exception: new optional `-PostRestartDirective` parameter deferred to Iteration 002).

---

## 6. Validate against governance rules

Run the governance validation script:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

**Expected Pass Conditions for Iteration 001**:

- Hardening-gate artifact exists and is signed off (Alon Fliess, 2026-05-11).
- Implementation authorization is recorded in `iterations/001/plan.md`.
- All task statuses in Iteration 001 plan are updated post-implementation (status = `done`).
- Iteration 001 is marked closed with retrospective artifact.
- Iteration 002 planning is ready (artifacts exist for User Story 2 and 3 deferments).

---

## Iteration 001 Validation Outcome

Iteration 001 is complete and ready for review when:

1. **Change detector works accurately**: Routine resumes return zero changes; baseline hash is updated correctly.
2. **Baseline tracking is durable**: YAML round-trip survives; invalid formats default gracefully.
3. **Auto-continue behavior is preserved**: Routine resumes trigger auto-continue directive, Squad coordinator launches immediately.
4. **Signature is stable**: No breaking changes to `specrew-start.ps1` parameters or error messages.
5. **All three integration tests pass**: `specrew-start-change-detector.ps1`, `specrew-start-baseline-tracking.ps1`, `specrew-start-auto-continue-preservation.ps1` all run successfully.
6. **Governance validation passes**: Hardening-gate sign-off and implementation authorization are recorded correctly.

---

## Explicit Iteration 002 Deferments

The following functionality is **explicitly not validated in Iteration 001** and is deferred to Iteration 002:

- **Pause-and-Confirm Rendering** (User Story 2, T043-T049): When detector identifies changed session-loaded files, the regenerated handoff pauses with a clear message, lists the changed files, and waits for user confirmation. Tests: `specrew-start-pause-and-confirm.ps1` (Iteration 002).
- **PostRestartDirective Parameter** (User Story 3, T050-T054): Power users can supply `-PostRestartDirective "Directive text"` to prepend a custom first-message directive. Tests: `specrew-start-parameter-handling.ps1`, `specrew-start-end-to-end.ps1` (Iteration 002).
- **Visibility Output Assertions** (T048, Iteration 002): Structured file lists and change summaries rendered in handoff output, testable via scaffold-replay-path (per test-integrity corpus from specs/005).
- **Known-Traps Corpus Seeding** (T055, Iteration 002 Polish phase): Seed entry for "auto-handoff bypass when session-loaded files change" pattern in `.specrew/quality/known-traps.md`.

Iteration 002 will layer these behaviors on top of the Iteration 001 detector infrastructure, with a separate planning-time hardening-gate artifact documenting the new quality concerns.

---

## Next Steps

1. Implement Iteration 001 tasks T029-T042 following the plan.
2. Run the three integration tests as each implementation task completes.
3. Record test results and any edge-case discoveries in `iterations/001/quality/evidence.md`.
4. Conduct before-implement review of detector logic and baseline tracking mechanism.
5. Upon Iteration 001 closeout, hand off to Iteration 002 planning for User Story 2 and 3 features.
