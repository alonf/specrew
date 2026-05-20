# Contract: Multi-Host Deployment

**Contract Version**: 1.0.0  
**Feature**: 024-slash-command-multi-host-correctness  
**Effective Boundary**: Plan-complete / pre-implementation

## Overview

This contract defines the multi-host deployment behavior for Specrew slash commands, ensuring content-identical `SKILL.md` files are deployed to three supported project skill locations with synchronized updates and consistent discovery experience across Claude Code, GitHub Copilot CLI, and host-neutral `.agents/skills/` future-proofing.

---

## Deployment Targets

Specrew slash commands MUST be deployed to **three supported project skill locations**:

| Target Path | Host Primary Discovery | Purpose |
| --- | --- | --- |
| `.claude/skills/` | Claude Code | Primary discovery path for Claude Code users |
| `.github/skills/` | GitHub Copilot CLI | Primary discovery path for GitHub Copilot CLI users |
| `.agents/skills/` | Host-neutral | Future-proof host-neutral path recognized by GitHub Copilot CLI today |

---

## Content Identity Requirement

All three deployment targets MUST contain **content-identical `SKILL.md` files** for each slash command. Content identity is defined as:

- **Byte-for-byte match**: The same file content (including line endings, whitespace, YAML frontmatter, markdown body) across all three target paths.
- **No host-specific divergence**: The v0.24.0 deployment logic MUST NOT introduce host-specific variations in command metadata, body guidance, or tool constraints.
- **Synchronized updates**: When `specrew init` or `specrew update` runs, all three targets MUST be updated together with the same command definitions from the source templates.

**Validation**:
- Automated tests MUST verify byte-for-byte content identity across all three target paths for each command.
- If any target contains different content, the deployment operation MUST fail with a clear diagnostic message identifying which command and which target diverged.

---

## Deployment Lifecycle

### Initial Bootstrap (`specrew init`)

When a new Specrew project is initialized:

1. All seven existing slash commands MUST be deployed to all three target paths.
2. Each command directory structure: `{targetPath}/{commandName}/SKILL.md` (e.g., `.claude/skills/specrew-where/SKILL.md`).
3. All deployed `SKILL.md` files MUST contain valid YAML frontmatter (see **Frontmatter Validity Contract**).
4. Deployment is atomic: if any target fails, the entire deployment operation MUST be marked as failed.

**Acceptance criteria**:
- AC1: Fresh bootstrap deploys every existing slash command to `.claude/skills/`, `.github/skills/`, and `.agents/skills/`, with content-identical `SKILL.md` files across the three paths.

### Refresh/Update (`specrew update`)

When a Specrew project is updated:

1. All seven slash commands MUST be re-synchronized to all three target paths with the latest source template content.
2. Legacy `.copilot/skills/specrew-*` directories MUST be migrated according to **Migration Safety Contract**.
3. Re-synchronization MUST preserve content identity across all three new target paths.
4. Update is atomic: if any target fails, the entire update operation MUST be marked as failed.

**Acceptance criteria**:
- AC2: `specrew update` refreshes all seven commands to all three target paths with content-identical `SKILL.md` files.
- AC4: `specrew update` removes Specrew-managed legacy `.copilot/skills/specrew-*` directories but preserves non-Specrew content.

---

## Source-of-Truth

The **authoritative source** for slash-command content is:

```text
extensions/specrew-speckit/squad-templates/skills/
├── specrew-where/SKILL.md
├── specrew-status/SKILL.md
├── specrew-update/SKILL.md
├── specrew-team/SKILL.md
├── specrew-review/SKILL.md
├── specrew-help/SKILL.md
└── specrew-version/SKILL.md
```

**Rules**:
- The deployment logic in `deploy-squad-runtime.ps1` MUST read from these source templates and write content-identical copies to all three target paths.
- No transformation, substitution, or host-specific customization is permitted during deployment.
- Manual edits to deployed `SKILL.md` files are **not supported** and will be overwritten on the next `specrew update`.

---

## Failure Handling

### Deployment Failure Modes

| Failure Mode | Behavior | Remediation Guidance |
| --- | --- | --- |
| Target directory creation fails (permission denied) | Deployment operation fails with diagnostic message identifying which target path and why | Check filesystem permissions, ensure project path is writable |
| Source template missing or invalid | Deployment operation fails with diagnostic message identifying which source template | Report issue to Specrew maintainers, verify Specrew installation integrity |
| Partial deployment (some targets succeed, some fail) | Deployment operation fails, successful targets left in deployed state | Retry `specrew update` after fixing permission/filesystem issue |
| Content divergence detected during validation | Deployment operation fails with diagnostic message identifying which command and which target diverged | Report issue to Specrew maintainers (indicates deployment logic bug) |

---

## Coexistence and Compatibility

### Namespace Coexistence

- Slash commands deployed to `.claude/skills/`, `.github/skills/`, and `.agents/skills/` MUST NOT conflict with other project skills in those directories.
- Directory naming (`specrew-*`) provides namespace isolation from other project skills.
- Host discovery MUST present Specrew commands alongside other project skills without shadowing or collision.

### Compatibility with Legacy Deployments

- Legacy `.copilot/skills/specrew-*` deployments from pre-v0.24.0 installations are considered **deprecated**.
- The multi-host deployment logic MUST NOT write to `.copilot/skills/` (legacy path is migration-only, not active deployment).
- Projects upgrading from pre-v0.24.0 MUST run `specrew update` to trigger legacy migration and new multi-host deployment.

---

## Testing Requirements

### Required Automated Tests

1. **Multi-Path Deployment Test** (`SlashCommand.MultiPath.Tests.ps1`):
   - Verify that `specrew init` deploys all seven commands to all three target paths.
   - Verify content-identical `SKILL.md` files across all three paths for each command.
   - Verify directory structure: `{targetPath}/{commandName}/SKILL.md`.

2. **Content Identity Validation**:
   - For each command, compute checksum (e.g., SHA256) of `SKILL.md` content in all three target paths.
   - Assert all three checksums are identical.
   - If divergence detected, fail test with diagnostic message identifying which command and which target diverged.

3. **Update Re-Synchronization Test**:
   - Deploy slash commands to all three paths.
   - Manually modify one deployed `SKILL.md` file in one target path.
   - Run `specrew update`.
   - Verify all three paths are re-synchronized with content-identical source template content (manual edit overwritten).

---

## Open Questions and Deferrals

- **Host-specific metadata extensions**: If future hosts require additional YAML frontmatter fields (e.g., `allowed-tools`, `cost-tier`), how will content identity be preserved? → Deferred to post-v0.24.0 feature when evidence of host-specific requirements surfaces.
- **Selective deployment**: Should `specrew init` support deploying to a subset of target paths (e.g., only `.claude/skills/` for Claude Code-only projects)? → Deferred to post-v0.24.0 feature; v0.24.0 always deploys to all three paths.
- **Discovery priority**: If a host recognizes multiple target paths (e.g., GitHub Copilot CLI recognizes `.github/skills/`, `.claude/skills/`, `.agents/skills/`), which path takes precedence? → Host-specific behavior, outside Specrew control; Specrew ensures content identity so precedence does not affect user experience.

---

## Version and Governance

**Contract Version**: 1.0.0  
**Effective Date**: 2026-05-19 (Feature 024 plan-complete)  
**Amendment Policy**: Changes to this contract require explicit feature scope, spec approval, and cross-reference from tasks.md and implementation plan.  
**Supersedes**: Feature 021 deployment contract (single-path `.copilot/skills/` deployment, dot-notation `/specrew.X` naming).
