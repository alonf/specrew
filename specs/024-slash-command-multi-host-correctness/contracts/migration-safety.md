# Contract: Migration Safety

**Contract Version**: 1.0.0  
**Feature**: 024-slash-command-multi-host-correctness  
**Effective Boundary**: Plan-complete / pre-implementation

## Overview

This contract defines the safe migration behavior for legacy `.copilot/skills/specrew-*` directories during `specrew update`, ensuring Specrew-managed content is removed while preserving unmanaged or third-party content without silent deletion.

---

## Legacy Deployment Context

**Pre-v0.24.0 behavior** (Feature 021):

- Specrew slash commands were deployed to `.copilot/skills/specrew-*/SKILL.md`.

- Directory naming used hyphenated form (`specrew-where/`, `specrew-status/`, etc.).

- Command references in body guidance used dot-notation (`/specrew.where`, `/specrew.status`, etc.).

- No YAML frontmatter was present in `SKILL.md` files.

**v0.24.0+ behavior** (Feature 024):

- Specrew slash commands are deployed to `.claude/skills/`, `.github/skills/`, `.agents/skills/`.

- Legacy `.copilot/skills/specrew-*` path is **deprecated** and considered migration-only.

- `specrew update` MUST safely remove Specrew-managed legacy content while preserving unmanaged content.

---

## Migration Scope

### In Scope for Migration

**Managed Legacy Directories**:

- Directories under `.copilot/skills/` matching the pattern `specrew-*` (e.g., `specrew-where/`, `specrew-status/`, etc.).

- Directories confirmed to be **Specrew-managed** via managed-marker detection from `Set-ManagedFile` tracking.

**Migration action**: **Remove** managed legacy directories during `specrew update`.

### Out of Scope for Migration (Must Preserve)

**Unmanaged Legacy Directories**:

- Directories under `.copilot/skills/` matching the pattern `specrew-*` but **not** confirmed as Specrew-managed.

- User-created content, third-party skills, or experimental skills that happen to use the `specrew-*` naming pattern.

**Migration action**: **Preserve** unmanaged directories and surface them as leftover non-discoverable content in migration logs or reports.

**Other Legacy Content**:

- Directories under `.copilot/skills/` that do **not** match the `specrew-*` pattern (e.g., `my-custom-skill/`, `third-party-integration/`).

- These are outside migration scope and MUST remain untouched.

---

## Ownership Detection

### Authority

Feature 024 requires an **explicit Specrew ownership signal** before any legacy `.copilot/skills/specrew-*` directory may be removed.

- Deletion by directory name alone is forbidden.

- The implementation may reuse or extract a repo-consistent managed-artifact ownership check during the migration work.

- During migration, the logic MUST check for that explicit ownership signal to determine whether a directory is Specrew-managed.

**Rules**:

- If an explicit Specrew ownership signal is **present**: Directory is Specrew-managed → **safe to remove**.

- If that signal is **absent**: Directory is unmanaged → **must preserve**.

### Detection Implementation

The migration logic MUST centralize an explicit ownership test rather than scatter ad-hoc deletion logic. Planning leaves the exact mechanism to implementation so long as the contract above is preserved. Possible implementation options:

1. **Option A: Managed-marker file** (e.g., `.specrew-managed` in each skill directory).
2. **Option B: Tracking database** (e.g., `.specrew/managed-artifacts.json` at project root).
3. **Option C: File attributes** (e.g., extended attributes or alternate data streams on Windows).

The chosen implementation MUST be consistent with other Specrew-managed artifacts and reviewable in code/tests.

---

## Migration Workflow

### Step 1: Scan Legacy Path

1. Check if `.copilot/skills/` directory exists under the project path.
2. If absent, skip migration (no legacy content to migrate).
3. If present, scan for subdirectories matching the pattern `specrew-*`.

### Step 2: Classify Discovered Directories

For each discovered `specrew-*` directory:

1. Apply managed-marker detection.
2. Classify as **managed** (safe to remove) or **unmanaged** (must preserve).

### Step 3: Execute Migration Actions

**For managed directories**:

1. Remove the directory and all its contents recursively.
2. Increment `managedRemovalCount` metric.
3. Log removal action (e.g., "Removed managed legacy directory: `.copilot/skills/specrew-where/`").

**For unmanaged directories**:

1. Preserve the directory and all its contents (no deletion).
2. Increment `unmanagedPreserveCount` metric.
3. Log preservation action (e.g., "Preserved unmanaged legacy directory: `.copilot/skills/specrew-custom/`").
4. Surface as leftover non-discoverable content in migration report or logs.

### Step 4: Report Migration Results

At the end of `specrew update`, output a migration summary:

```text
Migration Summary:
  Legacy path scanned: .copilot/skills/
  Discovered legacy directories: 8
  Managed directories removed: 7
  Unmanaged directories preserved: 1
  Preserved directories (non-discoverable):
    - .copilot/skills/specrew-custom/
```

**User guidance for preserved content**:

- "The following directories under `.copilot/skills/` were preserved because they are not Specrew-managed. They will not be discovered by AI coding hosts in this location. Consider moving them to `.agents/skills/` or another supported path if you want to retain them."

---

## Failure Modes and Remediation

| Failure Mode | Detection | Behavior | Remediation |
| --- | --- | --- | --- |
| Ownership detection fails (e.g., tracking data missing/corrupted) | Migration logic cannot determine ownership | Fail migration with error; do NOT delete any content | Report issue to Specrew maintainers; manual review of `.copilot/skills/` required |
| Filesystem permission error during removal | Deletion of managed directory fails | Fail migration with error; partial removal may occur | Check filesystem permissions; retry `specrew update` after fixing permissions |
| Unmanaged directory silently deleted | Automated test detects missing unmanaged content after migration | Test failure (critical violation of safe-migration contract) | Report issue to Specrew maintainers (indicates migration logic bug) |
| Legacy path contains non-`specrew-*` directories | Migration logic scans `.copilot/skills/` | Ignored (out of scope for migration) | No action required; non-`specrew-*` content remains untouched |

---

## Testing Requirements

### Required Automated Tests

1. **Migration Behavior Test** (`SlashCommand.Migration.Tests.ps1`):
   - **Setup**: Seed a test project with:
     - Managed legacy directories: `.copilot/skills/specrew-where/`, `.copilot/skills/specrew-status/` (with managed-markers).
     - Unmanaged legacy directory: `.copilot/skills/specrew-custom/` (without managed-marker).
     - Non-`specrew-*` directory: `.copilot/skills/other-skill/` (out of scope).
   - **Action**: Run `specrew update`.
   - **Assertions**:
     - Managed directories `.copilot/skills/specrew-where/` and `.copilot/skills/specrew-status/` are removed.
     - Unmanaged directory `.copilot/skills/specrew-custom/` is preserved.
     - Non-`specrew-*` directory `.copilot/skills/other-skill/` is preserved.
     - Migration summary reports correct counts: `managedRemovalCount = 2`, `unmanagedPreserveCount = 1`.

2. **Ownership Detection Test**:
   - **Setup**: Create two `specrew-*` directories, one with explicit Specrew ownership signal, one without.
   - **Action**: Apply the ownership detection logic.
   - **Assertions**:
      - Directory with explicit Specrew ownership signal is classified as **managed**.
      - Directory without that signal is classified as **unmanaged**.

3. **Idempotency Test**:
   - **Setup**: Seed managed legacy directories, run `specrew update` (removes them), run `specrew update` again.
   - **Assertions**:
     - Second `specrew update` does not fail (no legacy content to migrate).
     - Migration summary reports: `discoveredLegacyCount = 0`, `managedRemovalCount = 0`, `unmanagedPreserveCount = 0`.

---

## Coexistence with Multi-Host Deployment

Migration MUST occur **before** or **alongside** multi-host deployment during `specrew update`:

1. **Scan and migrate legacy `.copilot/skills/specrew-*` content** (remove managed, preserve unmanaged).
2. **Deploy slash commands to new multi-host paths** (`.claude/skills/`, `.github/skills/`, `.agents/skills/`).

The order ensures:

- No orphaned legacy directories remain after update.

- New multi-host deployment is populated with current source templates.

- Users see a clean migration experience with no manual cleanup required (except for unmanaged preserved content, which is surfaced in migration report).

---

## Rollback and Disaster Recovery

### Pre-Migration Backup (Optional)

Specrew v0.24.0 does **not** include automatic pre-migration backup of `.copilot/skills/` content. Users who want to preserve legacy content before migration should:

1. Manually copy `.copilot/skills/` to a backup location before running `specrew update`.
2. OR ensure Git working directory is clean and committed before running `specrew update` (Git provides rollback via `git restore` or `git reset`).

**Rationale**: Managed-marker detection provides high-confidence ownership proof, making silent deletion of user content extremely unlikely. Automatic backup adds complexity and filesystem overhead for a low-probability failure mode.

### Post-Migration Rollback

If migration removes content incorrectly (e.g., unmanaged directory deleted due to managed-marker detection bug):

1. User reports issue to Specrew maintainers.
2. Maintainer investigates managed-marker detection logic and root cause.
3. User restores content from Git history or manual backup.
4. Migration logic is patched and released in next Specrew version.

**Testing**: Automated tests MUST catch incorrect deletion before release (see **Migration Behavior Test** above).

---

## Open Questions and Deferrals

- **Pre-migration backup option**: Should `specrew update` include a `--backup-legacy` flag to automatically backup `.copilot/skills/` before migration? → Deferred to post-v0.24.0 feature if user feedback indicates demand.

- **Migration dry-run mode**: Should `specrew update` support a `--dry-run` flag to preview migration actions without executing them? → Deferred to post-v0.24.0 feature; v0.24.0 migration is non-reversible except via Git restore.

- **Legacy path cleanup after N updates**: Should Specrew automatically delete the entire `.copilot/skills/` directory after it has been empty for N consecutive updates? → Deferred to post-v0.24.0 feature; v0.24.0 leaves empty `.copilot/skills/` in place if all `specrew-*` content is removed.

---

## Version and Governance

**Contract Version**: 1.0.0  
**Effective Date**: 2026-05-19 (Feature 024 plan-complete)  
**Amendment Policy**: Changes to this contract require explicit feature scope, spec approval, and cross-reference from tasks.md and implementation plan.  
**Supersedes**: N/A (Feature 021 had no migration contract; this is the first migration behavior definition).
