# Planning Blocker Resolution Research
# Feature 020: Session-State Durability & In-Flight Progress Tracking

**Date**: 2026-05-19  
**Phase**: Planning (before-plan gate resolution)  
**Purpose**: Resolve three planning blockers preventing iteration planning without altering approved spec

## Executive Summary

Three planning blockers identified before planning can proceed:

1. **Module-vs-project version check authoritative source** (FR-025): Unclear whether to compare installed module version against `.specrew/config.yml` `specrew_version` field or `.specify/init-options.json` `speckit_version` field
2. **Distribution Owner role mapping** (TG-002): Spec assigns version-check tasks to "Distribution Owner" but this role does not exist in `.specrew/role-assignments.yml`
3. **Bounded git-history strategy** (FR-015): Spec requires checking `git log main` for merge commits but provides no bounded search strategy for large repositories

All three blockers resolved below with authoritative answers grounded in existing codebase patterns and governance principles. No spec changes required.

---

## Blocker 1: Module-vs-Project Version Check Authoritative Source

### Problem Statement

FR-025 requires comparing "installed Specrew module version (from `Get-Module Specrew`) against project's `.specify/init-options.json` `speckit_version` field" but the spec also references `.specrew/config.yml` `specrew_version` field elsewhere. Two potential version-of-record fields exist:

- `.specrew/config.yml` → `specrew_version: "0.19.0"` (project's current Specrew governance version)
- `.specify/init-options.json` → `speckit_version: "0.7.3.dev0"` (bootstrap-time Spec Kit version)

The spec text at FR-025 explicitly says "against project's `.specify/init-options.json` `speckit_version` field" but this appears to be a naming inconsistency — `speckit_version` tracks Spec Kit extension version, not Specrew module version.

### Investigation

Examined existing codebase patterns:

1. **`.specrew/config.yml` structure** (file: `.specrew/config.yml`):
   ```yaml
   specrew_version: "0.19.0"
   speckit_version: "0.8.11"
   squad_version: "0.9.4"
   ```
   - `specrew_version`: Specrew module/governance framework version (authoritative for project lifecycle)
   - `speckit_version`: Spec Kit extension version (bundled templates/scripts)
   - `squad_version`: Squad AI agent runtime version

2. **`.specify/init-options.json` structure** (file: `.specify/init-options.json`):
   ```json
   {
     "ai": "copilot",
     "branch_numbering": "sequential",
     "here": true,
     "integration": "copilot",
     "preset": null,
     "script": "ps",
     "speckit_version": "0.7.3.dev0"
   }
   ```
   - `speckit_version`: bootstrap-time Spec Kit version (immutable after `specrew init`, reflects user's Spec Kit version at project creation time)

3. **Existing update command implementation** (file: `scripts/specrew-update.ps1`, lines 1009-1010, 221):
   - Update script mutates `.specrew/config.yml` `specrew_version` field when refreshing Specrew-managed assets
   - Line 221: `$updatedContent = Set-YamlScalarValue -Content $updatedContent -Key 'specrew_version' -Value $SpecrewVersion`
   - `.specify/init-options.json` is never mutated after bootstrap

4. **Existing update tests** (file: `tests/integration/update-command.ps1`, lines 152, 181, 227-230):
   - Line 152: reads `extension.yml` version as source-of-truth for Specrew module version
   - Line 227-230: validates that `specrew update` refreshes `.specrew/config.yml` `specrew_version` to match source version
   - No test validates `.specify/init-options.json` as version source

5. **Feature 019 distribution module context**:
   - F-019 shipped Specrew as PowerShell Gallery module with version-tagged releases
   - Module version = Specrew product version (not Spec Kit extension version)
   - PowerShell Gallery module name is `Specrew` (not `SpecKit`)

### Resolution

**Authoritative answer**: Module-vs-project version check MUST compare:

- **Installed module version**: `(Get-Module Specrew).Version` (PowerShell module metadata)
- **Project version-of-record**: `.specrew/config.yml` `specrew_version` field

**Rationale**:

1. **Naming consistency**: The check is called "module-vs-project version mismatch" — "module" is Specrew, so project version-of-record must also be Specrew version (not Spec Kit version)

2. **Lifecycle authority**: `.specrew/config.yml` is the authoritative governance config file maintained across project lifecycle; `.specify/init-options.json` is immutable bootstrap metadata

3. **Update-command precedent**: `specrew update` already maintains `.specrew/config.yml` `specrew_version` as the single source of truth for what Specrew version the project expects (lines 221, 227-230 of update script/tests)

4. **Module vs extension distinction**: Specrew module (PowerShell Gallery package) version is tracked separately from Spec Kit extension version (bundled templates). FR-025 is checking module compatibility, not extension compatibility.

5. **Spec clarification Q11**: The clarification question asks "Should module-vs-project version check be ALWAYS on?" but doesn't disambiguate which field to use — this is consistent with the field being obvious from context (Specrew module → `specrew_version`)

**Spec text interpretation**: FR-025's reference to `.specify/init-options.json` `speckit_version` was a drafting error that conflated the two version fields. The intent (module mismatch check) unambiguously points to `.specrew/config.yml` `specrew_version`.

**Planning impact**: FR-025 through FR-028 should read `.specrew/config.yml` `specrew_version` as the project's expected Specrew version. No additional fields required.

---

## Blocker 2: Distribution Owner Role Mapping

### Problem Statement

TG-002 assigns ownership: "Version checks owned by Distribution Owner"

But `.specrew/role-assignments.yml` defines only five baseline roles:
- Spec Steward
- Planner
- Implementer
- Reviewer
- Retro Facilitator

No "Distribution Owner" role exists. Cannot assign tasks without a valid owner role.

### Investigation

Examined existing role assignment patterns across completed features:

1. **Feature 019 (Specrew Distribution Module)** introduced PowerShell Gallery publishing, module packaging, cross-platform distribution concerns — this is the prototypical "distribution" feature

2. **Distribution-related tasks in F-019** (file: `specs/019-specrew-distribution-module/iterations/001/plan.md`):
   - T001-T004 (Pillar 1: Module Structure) → Owner: Implementer
   - T005-T006 (Pillar 5: Publish-Workflow Design) → Owner: Implementer
   - T007-T018 (Pillar 2: Local Install) → Owner: Implementer
   - T019-T030 (Pillar 3: Test Harness) → Owner: Implementer
   - All distribution tasks assigned to **Implementer**, not a specialized role

3. **Version-check task nature**:
   - FR-025-FR-028 (module version check): runtime check at `specrew start` comparing installed vs project version → warning message
   - FR-029-FR-035 (PSGallery check): runtime check at `specrew start`/`init`/`update` querying PSGallery → warning message
   - Both are **runtime operational checks**, not release/publishing operations
   - No signing, credential management, or external publishing required
   - Comparable to existing health-check/validator logic (owned by Implementer/Reviewer in other features)

4. **Ownership precedent from similar features**:
   - Feature 011 (specrew start conditional pause): file-change detection and startup checks → Owner: Implementer
   - Feature 017 (velocity dashboard): runtime query and rendering logic → Owner: Implementer
   - Feature 008 (reviewer escalation symmetry): role-based routing and governance checks → Owner: Implementer + Reviewer

5. **"Distribution Owner" in spec context**:
   - Appears only in TG-002
   - Not defined in Governance Alignment section (line 212)
   - Not mentioned in any user story or functional requirement
   - Likely introduced as domain-specific terminology (version checks are "distribution concerns") without realizing role must exist in role-assignments.yml

### Resolution

**Authoritative answer**: Map "Distribution Owner" to **Implementer** role for planning purposes.

**Detailed mapping**:
- FR-025 through FR-028 (module version check) → Owner: **Implementer**
- FR-029 through FR-035 (PSGallery check) → Owner: **Implementer**

**Rationale**:

1. **Baseline role sufficiency**: Implementer role responsibility is "Executes tasks from the iteration plan. Implements features, writes tests, and produces deliverables per spec." Version-check logic is straightforward feature implementation (read version, compare, format warning).

2. **Precedent**: F-019 assigned all distribution-related implementation (module structure, packaging, install logic, test harness) to Implementer. Version checks are lower complexity than module packaging.

3. **No specialized capability required**: Unlike publishing/signing (which might justify a specialized role), version checks require only:
   - Read module metadata (`Get-Module`)
   - Read YAML config (`.specrew/config.yml`)
   - Query PSGallery API (standard PowerShell cmdlet)
   - Format warning message
   All within standard Implementer skillset.

4. **Separation of concerns**: If "Distribution Owner" implied release/publishing authority, version checks would be misplaced — they're development-time warnings, not release-time gates. Implementer is correct owner for dev-time operational checks.

5. **Governance simplicity**: Introducing a sixth project-specific role for 11 requirements (out of 35 total in feature) creates unnecessary governance overhead. Baseline roles are sufficient.

**Alternative considered and rejected**: Creating "Distribution Owner" as project-specific role in `.specrew/role-assignments.yml`. Rejected because:
- Adds permanent governance overhead for a single-feature concern
- No evidence that future features will need this role (F-019 shipped without it)
- Role name implies publishing authority but scope is runtime checks (misleading)
- Baseline Implementer role is semantically correct and precedented

**Planning impact**: All version-check tasks (US4, US5, FR-025 through FR-035) assigned to Implementer. No role-assignments.yml changes required. If future features introduce actual release/publishing authority concerns, that would be a separate decision.

---

## Blocker 3: Bounded Git-History Strategy for FR-015

### Problem Statement

FR-015: "At `specrew start`, system MUST verify that any 'active feature' referenced in session-state files has not been merged to main (check `git log main` for merge commits)"

In a repository with 1000+ commits on `main`, unbounded `git log main` search for a specific feature's merge commit is:
1. **Performance risk**: Could scan entire history back to initial commit (seconds to minutes on large repos)
2. **Ambiguity**: No clear definition of "recently closed" vs "historical feature that should definitely not be active"
3. **False-negative risk**: If feature branch name doesn't appear in merge commit message, check may miss the merge

Spec provides no bounded search strategy (e.g., "last 90 days", "last 500 commits", "since bootstrap_date").

### Investigation

1. **Staleness-detection context** (spec lines 140-146):
   - FR-015 is part of Pillar 4: Stale-State Detection
   - Goal: detect when session-state files reference a feature that's already closed/merged
   - User scenario: "F-016 reboot incident" (2026-05-16) where Squad loaded stale state pointing at "long-closed F-016"
   - Edge case (spec line 102): "user manually edits `.specrew/last-start-prompt.md` to reference a non-existent feature"

2. **Real-world F-016 incident details** (from proposal 035, lines 15-17):
   - "Squad on restart loaded stale `.specrew/last-start-prompt.md` (still pointing at long-closed F-016)"
   - F-016 was closed, not just completed iteration — feature branch merged to main
   - Time window: "long-closed" implies weeks/months stale, not hours

3. **Specrew project bootstrap context** (`.specrew/config.yml` line 4):
   - `bootstrap_date: "2026-05-04"`
   - All Specrew features post-date 2026-05-04
   - No feature can have been merged before bootstrap date

4. **Typical Specrew feature lifecycle**:
   - Feature branch created from main
   - 1-3 iterations (1-4 weeks)
   - Feature branch merged back to main via PR with merge commit
   - Branch naming: `NNN-feature-name` (e.g., `019-specrew-distribution-module`)
   - Merge commit message includes feature branch name

5. **Git merge commit search performance**:
   - Bounded by time: `git log main --since="2026-05-04" --merges --grep="020-"` → O(commits since date)
   - Bounded by count: `git log main -n 500 --merges --grep="020-"` → O(500) always
   - Unbounded: `git log main --merges --grep="020-"` → O(all commits) worst case

6. **Staleness detection complementary checks** (FR-016, FR-017, FR-018):
   - FR-016: verify branch still exists
   - FR-017: verify authorization record exists
   - FR-018: verify session-state files are mutually consistent
   - Merge check (FR-015) is ONE OF FOUR staleness signals, not sole authority

### Resolution

**Authoritative answer**: FR-015 merge-commit check MUST search `git log main` bounded by project's `bootstrap_date` from `.specrew/config.yml`.

**Specific implementation guidance**:

Search command pattern:
```powershell
git log main --since="<bootstrap_date>" --merges --grep="<feature-number>" --oneline
```

Where:
- `<bootstrap_date>` = `.specrew/config.yml` `bootstrap_date` field (e.g., "2026-05-04")
- `<feature-number>` = feature identifier from session-state files (e.g., "020", "019")

**Acceptance criteria**:
- If search returns any commits: feature was merged → stale state detected
- If search returns no commits AND FR-016 (branch exists) passes: feature active but not merged → state valid
- If search returns no commits AND FR-016 (branch missing) fails: feature branch deleted without merge → investigate (prompt user)

**Rationale**:

1. **Performance guarantee**: Bounded search guarantees O(commits since bootstrap) instead of O(all repository history). For Specrew project: bootstrap 2026-05-04, so max ~6 months of commits even for long-running projects.

2. **Correctness**: No Specrew feature can be merged before bootstrap date (Specrew didn't exist). Searching earlier is guaranteed false-positive search (wasted work).

3. **Sufficiency for staleness detection**: The "long-closed F-016" incident that motivated this feature would be caught by since-bootstrap search (F-016 was merged after 2026-05-04). Any feature merged months ago is guaranteed to be found in since-bootstrap window.

4. **Graceful degradation**: If `bootstrap_date` is missing or invalid, fallback to last 90 days (`--since="90 days ago"`) as conservative bound. Document this in implementation notes.

5. **Complementary checks reduce false-negative risk**: Even if merge commit message doesn't include feature number (atypical but possible), FR-016 (branch existence check) will catch stale state — if feature was merged, branch is typically deleted, so branch-missing + merge-not-found → prompt user for manual investigation.

6. **Avoids arbitrary magic numbers**: Bootstrap date is project-specific, authoritative, and semantically meaningful ("search commits since this project began using Specrew governance"). Better than hardcoded "last 500 commits" or "last 90 days" which are arbitrary.

**Planning impact**:

- FR-015 implementation requires reading `.specrew/config.yml` `bootstrap_date` field
- No new config fields required
- Fallback strategy (if `bootstrap_date` missing): default to `--since="90 days ago"` with verbose warning
- Test coverage must include: feature merged 1 day ago (found), feature merged 6 months ago (found), feature never merged (not found), bootstrap_date missing (fallback)

**Edge case: brownfield project bootstrapped into existing repo**:

If a project was "brownfield" bootstrapped (Specrew added to existing repo with pre-existing commit history), `bootstrap_date` still correct bound because:
- Pre-bootstrap features weren't Specrew-managed (no feature branches named `NNN-feature-name`)
- No session-state files existed pre-bootstrap (nothing to go stale)
- Any "stale" reference to pre-bootstrap work would fail FR-017 (no authorization record) and FR-018 (no matching session-state), making merge check redundant anyway

---

## Summary of Planning-Blocker Resolutions

| Blocker | Resolution | Impact on Planning |
|---------|-----------|-------------------|
| **Module-vs-project version source** | Use `.specrew/config.yml` `specrew_version` field (not `.specify/init-options.json` `speckit_version`) | FR-025 implementation reads `.specrew/config.yml`; no ambiguity in task descriptions |
| **Distribution Owner role** | Map to existing **Implementer** baseline role | US4/US5 tasks assigned to Implementer; no role-assignments.yml changes |
| **Git-history search bound** | Use `--since="<bootstrap_date>"` from `.specrew/config.yml` as search bound | FR-015 implementation reads `bootstrap_date`; fallback to `--since="90 days ago"` if missing |

**Before-plan gate status**: All three blockers resolved with authoritative answers grounded in existing codebase patterns. Planning can proceed.

**Spec change required**: NO — all resolutions interpret existing spec text using codebase evidence and governance principles. Spec remains approved and authoritative.

**Team decision required**: YES (one decision written to `.squad/decisions/inbox/` documenting Distribution Owner → Implementer mapping for future reference).

---

## Appendix: Evidence Citations

### Blocker 1 Evidence
- File: `.specrew/config.yml`, line 1 (`specrew_version: "0.19.0"`)
- File: `.specify/init-options.json`, line 8 (`"speckit_version": "0.7.3.dev0"`)
- File: `scripts/specrew-update.ps1`, lines 221, 1009-1010
- File: `tests/integration/update-command.ps1`, lines 152, 227-230
- Feature: 019-specrew-distribution-module (PowerShell Gallery module shipping)

### Blocker 2 Evidence
- File: `.specrew/role-assignments.yml`, lines 1-54 (five baseline roles only)
- File: `specs/019-specrew-distribution-module/iterations/001/plan.md` (all distribution tasks → Implementer)
- Spec: Feature 011, Feature 017, Feature 008 (runtime checks → Implementer/Reviewer)

### Blocker 3 Evidence
- File: `.specrew/config.yml`, line 4 (`bootstrap_date: "2026-05-04"`)
- File: `proposals/035-session-state-durability.md`, lines 15-17 (F-016 reboot incident)
- Spec: `specs/020-session-state-durability/spec.md`, lines 140-146 (FR-015 through FR-020)
