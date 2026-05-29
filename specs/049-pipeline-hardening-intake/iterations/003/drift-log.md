# Drift Log - Iteration 003

## Purpose

Track deviations between spec/plan and implementation, per Specrew governance.

## Findings

### 1. FR-024 Schema Mismatch (RESOLVED)

- **Severity:** Critical
- **Category:** Implementation drift
- **Detection:** Reviewer inspection
- **Description:** Implementation wrote `schema_version`, `updated_at`, `expertise_dials.*` instead of FR-024 spec fields (`schema`, `specrew_version_at_creation`, `last_updated_at`, `expertise.*`)
- **Impact:** User profiles incompatible with FR-024 schema contract
- **Resolution:** Updated `user-profile.ps1` to use correct FR-024 field names and structure
- **Status:** Fixed (2026-05-28)

### 2. FR-023 Auto-Decision Path Broken (RESOLVED)

- **Severity:** Critical
- **Category:** Implementation drift
- **Detection:** Reviewer inspection
- **Description:** "auto" expertise dial coerced to numeric 0, breaking auto-decision transparency
- **Impact:** Auto-path (FR-023) failed to deliver Mode C with annotations
- **Resolution:** Preserved "auto" as string throughout pipeline, added FR-024→legacy mapping
- **Status:** Fixed (2026-05-28)

### 3. Lifecycle Artifacts State Mismatch (RESOLVED)

- **Severity:** Minor
- **Category:** Process drift
- **Detection:** Reviewer inspection
- **Description:** plan.md showed status="planning" and tasks="planned" despite work completion
- **Impact:** Misrepresented iteration readiness
- **Resolution:** Updated status to "reviewing", dates set, all 34 tasks marked "done"
- **Status:** Fixed (2026-05-28)

### 4. Fabricated Timestamps (RESOLVED)

- **Severity:** Critical
- **Category:** Governance violation
- **Detection:** Reviewer inspection
- **Description:** tasks-progress.yml contained fabricated completion times
- **Impact:** Falsified historical record
- **Resolution:** Applied exact commit timestamps from reviewer-provided evidence
- **Status:** Fixed (2026-05-28)

### 5. Missing SC-005 Evidence (RESOLVED)

- **Severity:** Minor
- **Category:** Documentation drift
- **Detection:** Reviewer inspection
- **Description:** quality-evidence.md missing third-clause evidence (Mode A rate ≥ 70%)
- **Impact:** Success criteria validation incomplete
- **Resolution:** Added evidence row showing 100% Mode A rate for senior intake
- **Status:** Fixed (2026-05-28)

## Summary

Five critical/minor drifts detected during review, all resolved through systematic repair cycle.
