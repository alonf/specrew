# Research: Slash-Command Multi-Host Correctness

**Feature**: 024-slash-command-multi-host-correctness  
**Phase**: Phase 0 (Research)  
**Date**: 2026-05-19

## Overview

This research document resolves all NEEDS CLARIFICATION items from the Technical Context and provides the foundational knowledge required for Phase 1 design artifacts (data-model.md, contracts/, quickstart.md).

## Research Areas

### 1. YAML Frontmatter Requirements for Claude Code and GitHub Copilot CLI

#### Decision

Claude Code and GitHub Copilot CLI both support project skills with YAML frontmatter in `SKILL.md` files, but have slightly different requirements:

- **GitHub Copilot CLI**: Requires YAML frontmatter with `name` (mandatory) and `description` (mandatory) fields. The `name` must match the directory name. Optional `allowed-tools` can restrict which tools the skill can invoke.

- **Claude Code**: Supports YAML frontmatter with `description` (recommended) and `name` (optional). The `description` field helps with skill discovery, while the `name` field is optional but recommended for parity.

For Feature 024, we will standardize on the **strictest superset** to ensure cross-host compatibility:

```yaml
---
name: specrew-where
description: Show the current Specrew project status dashboard — the "where am I?" velocity view for the active feature and iteration.
---
```

#### Rationale

- Using `name` as mandatory ensures directory-name matching validation works consistently.

- Using `description` as mandatory ensures both hosts have rich discovery metadata.

- The `name` field uses lowercase-hyphen format matching the directory name (e.g., `specrew-where` for directory `specrew-where/`).

- The `description` field preserves the existing "Purpose" and "When to Use" guidance from Feature 021 templates in a condensed single-line form suitable for discovery menus.

- Optional `allowed-tools` remains available for future constraints but is not required for v0.24.0.

#### Alternatives Considered

- **Use GitHub Copilot CLI requirements only**: Would leave Claude Code discovery with weaker metadata. Rejected because Feature 024 claims parity across both hosts.

- **Use minimal frontmatter with only `description`**: Would fail GitHub Copilot CLI validation which requires `name`. Rejected because it breaks discoverability.

- **Add custom Specrew-specific fields**: Would create vendor lock-in and reduce portability. Rejected in favor of standard fields only.

#### Evidence

- GitHub Copilot CLI documentation (public): Project skills require `name` and `description` in YAML frontmatter.

- Claude Code documentation (public): Project skills support `description` (recommended) and `name` (optional) in YAML frontmatter.

- User input from Feature 024 spec clarification (2026-05-19): "Official evidence: GitHub Copilot CLI project skills can live in `.github/skills`, `.claude/skills`, or `.agents/skills`, and require YAML frontmatter with `name` and `description`; Claude Code project skills live in `.claude/skills` and use YAML frontmatter with `description` recommended and `name` optional, but this feature should standardize frontmatter for cross-host parity."

---

### 2. Multi-Host Deployment Patterns and Path Selection

#### Decision

Feature 024 will deploy all seven existing Specrew slash commands to **three supported project skill locations**:

1. `.claude/skills/` — Primary discovery path for Claude Code
2. `.github/skills/` — Primary discovery path for GitHub Copilot CLI
3. `.agents/skills/` — Host-neutral future-proof deployment path

Each deployment location receives **content-identical `SKILL.md` files**. The three copies are managed as one logical deployment set. The deployment logic in `deploy-squad-runtime.ps1` will be refactored from the current single-path `.copilot/skills/` deployment (lines ~377-416) to iterate over all three target paths.

#### Rationale

- Claude Code officially looks for project skills in `.claude/skills/`.

- GitHub Copilot CLI officially looks for project skills in `.github/skills/`, `.claude/skills/`, or `.agents/skills/`.

- `.agents/skills/` serves as a host-neutral path that GitHub Copilot CLI recognizes today and provides future-proofing for other AI coding agents (e.g., Codex CLI when its project-skill guidance stabilizes).

- Content-identical deployment ensures no host-specific divergence in slash-command behavior, metadata, or discovery experience.

- The legacy `.copilot/skills/` path is deprecated for new deployments but will be preserved for historical installations and cleaned up during migration on `specrew update`.

#### Alternatives Considered

- **Deploy only to `.github/skills/` and `.claude/skills/`, skip `.agents/skills/`**: Would reduce future-proofing and require a later migration when other hosts stabilize. Rejected because `.agents/skills/` is recognized by GitHub Copilot CLI today at zero incremental cost.

- **Deploy only to `.agents/skills/` and skip host-specific paths**: Would rely on every host treating `.agents/skills/` as canonical, which Claude Code does not currently prioritize. Rejected because Claude Code discovery works best with `.claude/skills/`.

- **Deploy to all four paths including `.copilot/skills/`**: Would preserve legacy path as active deployment, contradicting Feature 024's migration intent. Rejected because the goal is to replace, not add to, the legacy deployment.

#### Evidence

- GitHub Copilot CLI public documentation: "Project skills can be placed in `.github/skills`, `.claude/skills`, or `.agents/skills`."

- Claude Code public guidance: "Project skills are discovered in `.claude/skills`."

- User input from Feature 024 spec clarification (2026-05-19): "Multi-deploy across `.claude/skills/`, `.github/skills/`, `.agents/skills/` with content-identical `SKILL.md`."

---

### 3. Managed-Marker Detection for Safe Legacy Migration

#### Decision

Feature 024 will classify a legacy `.copilot/skills/specrew-*` directory as removable only when an **explicit Specrew ownership signal** is present. The implementation should reuse or extract a repo-consistent managed-artifact ownership check during the migration work, but deletion by path/name alone is forbidden.

The migration logic will:

1. Scan `.copilot/skills/` for directories matching `specrew-*`.
2. For each directory, check if it contains a managed-marker (indicating Specrew created it).
3. If managed: **remove the directory** (Specrew owns it, and the new three-path deployment replaces it).
4. If unmanaged: **preserve the directory** and surface it as leftover non-discoverable content in the migration report or logs.

#### Rationale

- Safe migration requires explicit proof of Specrew ownership before deletion.

- The implementation may extract or centralize a helper for the legacy slash-command surface, but the contract is the ownership rule, not a specific storage mechanism.

- Unmanaged content (e.g., third-party skills, user experiments) must not be silently deleted, as that would violate the safe-migration promise in FR-005 and User Story 2.

#### Alternatives Considered

- **Remove all `.copilot/skills/specrew-*` directories without checking markers**: Would risk deleting user-authored content. Rejected because FR-005 mandates preservation of unmanaged content.

- **Delete by directory name alone**: Would assume every `specrew-*` directory under `.copilot/skills/` is Specrew-owned. Rejected because FR-005 requires preservation of unmanaged content.

- **Leave legacy `.copilot/skills/` content in place and require manual cleanup**: Would leave projects with orphaned non-discoverable directories after upgrade. Rejected because FR-005 requires active migration, not passive guidance.

#### Evidence

- User input from Feature 024 spec: "Assumptions: Managed-marker detection from existing Specrew hygiene tooling remains the authority for deciding whether legacy `.copilot/skills/` content is safe to remove."

- Feature 021 deployment logic (lines ~377-416 in deploy-squad-runtime.ps1) shows the current legacy deployment surface that Feature 024 must migrate away from.

---

### 4. Hyphenated Naming Migration: `/specrew.X` → `/specrew-X`

#### Decision

All active user-facing, operational, and governance references to the slash-command catalog will migrate from dot-notation `/specrew.X` to hyphenated notation `/specrew-X`:

- Directory names: `specrew-where/`, `specrew-status/`, etc. (already hyphenated in Feature 021, no change)

- YAML frontmatter `name` field: `specrew-where`, `specrew-status`, etc.

- Canonical command references in body guidance: `/specrew-where`, `/specrew-status`, etc.

- Test assertions, documentation, changelog language, and governance artifacts: `/specrew-*` form

Historical pre-v0.24.0 artifacts (Feature 021 spec, archived proposals, older changelog entries) **remain unchanged** to preserve historical record.

#### Rationale

- The hyphenated form aligns with the directory-based skill structure already used in Feature 021 (`specrew-where/`, `specrew-status/`, etc.).

- The YAML frontmatter `name` field must match the directory name for GitHub Copilot CLI validation, so `name: specrew-where` is required for directory `specrew-where/`.

- The dot-notation `/specrew.where` was a historical artifact from Feature 021's initial design before multi-host deployment requirements were clarified. It does not match the directory structure and creates confusion.

- Historical artifacts remain unchanged to preserve the audit trail and allow future readers to understand the evolution of the slash-command surface.

#### Alternatives Considered

- **Keep dot-notation in body guidance and only use hyphenated form in frontmatter**: Would create inconsistency between metadata and user-facing documentation. Rejected because FR-004 requires active references to use one canonical form.

- **Rewrite all historical artifacts to use hyphenated form**: Would destroy the historical record and make it harder to understand Feature 021's original design. Rejected because FR-004 explicitly preserves historical pre-v0.24.0 records unchanged.

- **Support both forms as valid aliases**: Would require additional routing logic and create ambiguity about which form is canonical. Rejected because FR-004 defines `/specrew-*` as the single canonical form for v0.24.0+.

#### Evidence

- Feature 021 directory structure: `extensions/specrew-speckit/squad-templates/skills/specrew-where/`, `specrew-status/`, etc.

- User input from Feature 024 spec: "Active artifacts must use `/specrew-*`; historical pre-v0.24.0 `/specrew.*` references stay unchanged where archival."

- GitHub Copilot CLI validation: `name` field must match directory name, so `specrew-where` directory requires `name: specrew-where`.

---

### 5. Integration Test Migration Strategy

#### Decision

Feature 024 will **migrate four existing integration tests** and **add three new integration tests**:

**Existing tests to migrate**:

1. `SlashCommand.Distribution.Tests.ps1` — Update from `.copilot/skills` single-path checks to multi-path checks across `.claude/skills/`, `.github/skills/`, `.agents/skills/`.
2. `SlashCommand.Discovery.Tests.ps1` — Update from `/specrew.X` dot-notation assertions to `/specrew-X` hyphenated-notation assertions.
3. `SlashCommand.Compatibility.Tests.ps1` — Update from `/specrew.X` to `/specrew-X` in version-compatibility validation.
4. `SlashCommand.Coexistence.Tests.ps1` — No changes expected (namespace coexistence with `/speckit.*` remains valid regardless of hyphenation).

**New tests to add**:

1. `SlashCommand.MultiPath.Tests.ps1` — Verify that fresh `specrew init` deploys all seven commands to all three paths with content-identical `SKILL.md` files.
2. `SlashCommand.Frontmatter.Tests.ps1` — Verify that every deployed `SKILL.md` contains valid YAML frontmatter with `name` matching directory and non-empty `description`.
3. `SlashCommand.Migration.Tests.ps1` — Verify that `specrew update` removes Specrew-managed legacy `.copilot/skills/specrew-*` directories while preserving unmanaged content.

#### Rationale

- Migrating existing tests ensures regression safety for the refreshed slash-command surface and hyphenated naming.

- Adding three new tests directly validates the three core restoration promises: multi-path deployment (FR-001, FR-002), frontmatter validity (FR-003), and safe migration (FR-005).

- Pester v5.3+ provides the test framework, already used by Specrew's integration test suite.

#### Alternatives Considered

- **Skip existing test migration and only add new tests**: Would leave old tests failing after deployment logic changes, creating false-negative signals. Rejected because FR-007 requires all pre-existing coverage to remain active and pass.

- **Combine all new tests into one multi-assertion test**: Would make failure diagnosis harder and violate the one-concern-per-test pattern. Rejected because FR-006 explicitly calls for three new integration tests as separate concerns.

- **Add manual validation only, skip automated tests**: Would make regression detection slower and less reliable. Rejected because FR-006 mandates automated validation.

#### Evidence

- Existing integration test structure: `tests/integration/SlashCommand.*.Tests.ps1` files.

- User input from Feature 024 spec: "Existing integration coverage includes distribution/discovery/compatibility/coexistence tests and will need migration plus three new tests for multi-path deployment, frontmatter validity, and legacy-path migration."

- FR-006: "Automated validation MUST add three new integration tests covering multi-path deployment, frontmatter validity, and legacy-path migration."

- FR-007: "All pre-existing slash-command validation coverage MUST remain active and pass against the hyphenated, multi-host surface with no skipped assertions."

---

### 6. Prerelease Validation Strategy for v0.24.0-beta.1

#### Decision

v0.24.0 stable promotion will be **blocked until prerelease validation succeeds** via v0.24.0-beta.1. The prerelease validation cycle includes:

1. **Clean PowerShell session install**: `Install-Module -Name Specrew -RequiredVersion 0.24.0-beta.1` (or local dev build).
2. **Fresh project bootstrap**: `specrew init` in a clean test project.
3. **Multi-path deployment validation**: Confirm all seven commands are deployed to `.claude/skills/`, `.github/skills/`, `.agents/skills/`.
4. **Frontmatter validity validation**: Confirm every deployed `SKILL.md` contains valid YAML frontmatter with `name` matching directory and non-empty `description`.
5. **Migration behavior validation**: Seed a test project with managed and unmanaged legacy `.copilot/skills/specrew-*` content, run `specrew update`, confirm managed content is removed and unmanaged content is preserved.
6. **Manual discoverability smoke**: Open Claude Code or GitHub Copilot CLI (whichever is available) and confirm `/specrew-where` appears in the slash-command discovery menu.
7. **Automated test pass**: Run all integration tests (migrated + new) and confirm 100% pass rate.

If any prerelease validation step fails, stable promotion is blocked until the failure is resolved and retested.

#### Rationale

- Prerelease validation proves the restored surface has **meaning** (discoverable in real hosts) rather than only **form** (files exist on disk).

- Manual discoverability smoke is critical because the form-vs-meaning failure in Feature 021 was only detected through manual host validation, not automated tests.

- Prerelease beta.1 allows safe rollback if unexpected host-specific issues surface during validation.

- FR-008 mandates this validation cycle as a release-readiness gate.

#### Alternatives Considered

- **Skip prerelease and promote directly to v0.24.0 stable**: Would risk repeating the Feature 021 form-vs-meaning failure. Rejected because FR-008 requires prerelease validation before stable promotion.

- **Use only automated tests, skip manual discoverability smoke**: Would miss host-specific discovery regressions that automated tests cannot detect. Rejected because manual validation is how the original failure was discovered.

- **Require validation in all three hosts (Claude Code, GitHub Copilot CLI, and Codex CLI)**: Would block release on Codex CLI availability when its project-skill guidance is still unstabilized. Rejected because FR-012 limits v0.24.0 claims to Claude Code + GitHub Copilot CLI only.

#### Evidence

- User input from Feature 024 spec: "Binding inputs from before-plan: […] target release line v0.24.0 with beta.1 prerelease validation first."

- FR-008: "Release readiness for v0.24.0 MUST include a prerelease validation cycle through v0.24.0-beta.1 in a clean PowerShell session, verifying bootstrap deployment, frontmatter validity, migration behavior, and manual `/specrew-where` discoverability in Claude Code or GitHub Copilot CLI before stable promotion."

- Feature 024 spec rationale: "This is the core promise being restored. If fresh bootstrap does not produce a discoverable slash-command surface, the feature has not fixed the form-vs-meaning failure that triggered Feature 024."

---

## Summary of Decisions

| Research Area | Decision | Key Rationale |
| --- | --- | --- |
| YAML Frontmatter | Mandatory `name` (directory-matching) + `description` (non-empty) | Strictest superset for Claude Code + GitHub Copilot CLI parity |
| Multi-Host Paths | Deploy to `.claude/skills/`, `.github/skills/`, `.agents/skills/` | Claude Code primary, GitHub Copilot CLI primary, host-neutral future-proofing |
| Managed-Marker | Reuse existing `Set-ManagedFile` tracking for safe migration | Consistent with other Specrew-managed artifacts, explicit ownership proof |
| Hyphenated Naming | `/specrew-X` in all active references, `/specrew.X` preserved in historical artifacts | Directory-name alignment, frontmatter validation, historical record preservation |
| Test Migration | Migrate 4 existing tests + add 3 new tests | Regression safety + validation of multi-path/frontmatter/migration |
| Prerelease Validation | v0.24.0-beta.1 cycle with manual discoverability smoke + automated test pass | Proof of meaning (discoverable) rather than only form (files exist) |

---

## Next Steps

Proceed to **Phase 1** to generate:

- `data-model.md` — Define slash-command entity, deployment-target entity, legacy-migration entity

- `contracts/` — Define multi-host deployment contract, frontmatter validity contract, migration safety contract, discovery contract

- `quickstart.md` — Developer onboarding for slash-command deployment, frontmatter editing, test execution
