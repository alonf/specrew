# Contract: Discovery Contract

**Contract Version**: 1.0.0  
**Feature**: 024-slash-command-multi-host-correctness  
**Effective Boundary**: Plan-complete / pre-implementation

## Overview

This contract defines the slash-command discovery behavior, host-coverage claims, and truthfulness requirements for Specrew v0.24.0, ensuring public messaging accurately describes the restored Claude Code + GitHub Copilot CLI discoverability while deploying `.agents/skills/` as a host-neutral future-proof path.

---

## v0.24.0 Host Coverage Claims

### Supported Hosts for Slash-Command Discoverability

Specrew v0.24.0 **publicly claims slash-command discoverability** for:

1. **Claude Code** (via `.claude/skills/` deployment path)
2. **GitHub Copilot CLI** (via `.github/skills/` and `.agents/skills/` deployment paths)

**Evidence required for support claim**:

- Host officially documents project-skill discovery in the claimed deployment path.
- Prerelease validation (v0.24.0-beta.1) includes manual smoke test confirming `/specrew-where` appears in the host's slash-command discovery menu.
- Automated tests validate deployment to the claimed paths with valid YAML frontmatter.

### Future-Proof Host-Neutral Path

Specrew v0.24.0 **deploys to `.agents/skills/`** as a host-neutral future-proof path, but does **not publicly claim discoverability guarantees** for hosts beyond Claude Code and GitHub Copilot CLI in the v0.24.0 release messaging.

**Rationale**:

- `.agents/skills/` is recognized by GitHub Copilot CLI today (covered by Copilot CLI support claim).
- Deploying to `.agents/skills/` provides future-proofing for other AI coding agents (e.g., Codex CLI) when their project-skill guidance stabilizes.
- Public v0.24.0 messaging limits discoverability claims to Claude Code + GitHub Copilot CLI only, avoiding overpromise until other hosts provide stable project-skill documentation.

**Deferred host coverage**:

- **Codex CLI**: `.agents/skills/` deployment path is present in v0.24.0, but Codex CLI discoverability is not a v0.24.0 acceptance guarantee. Discoverability claims for Codex CLI are deferred until its project-skill guidance stabilizes and can be validated in prerelease smoke testing.

---

## Discovery Mechanism by Host

### Claude Code

**Discovery path**: `.claude/skills/`

**Discovery behavior**:

- Claude Code scans `.claude/skills/` for subdirectories containing `SKILL.md` files.
- `description` field in YAML frontmatter is used for skill discovery menu display.
- `name` field is optional but recommended for parity with other hosts.

**Validation requirement**:

- Manual smoke test during v0.24.0-beta.1 prerelease: Open Claude Code, invoke slash-command discovery menu, confirm `/specrew-where` appears with correct description.

### GitHub Copilot CLI

**Discovery path**: `.github/skills/`, `.claude/skills/`, or `.agents/skills/` (GitHub Copilot CLI recognizes all three)

**Discovery behavior**:

- GitHub Copilot CLI scans `.github/skills/`, `.claude/skills/`, and `.agents/skills/` for subdirectories containing `SKILL.md` files.
- Both `name` (mandatory, must match directory) and `description` (mandatory, non-empty) fields in YAML frontmatter are required for discovery.
- If multiple paths contain the same skill (e.g., `specrew-where/` in both `.github/skills/` and `.claude/skills/`), host-specific precedence applies (outside Specrew control; content-identical deployment ensures consistent behavior).

**Validation requirement**:

- Manual smoke test during v0.24.0-beta.1 prerelease: Open GitHub Copilot CLI, invoke slash-command discovery menu, confirm `/specrew-where` appears with correct description.

### Host-Neutral Path (`.agents/skills/`)

**Discovery path**: `.agents/skills/`

**Current coverage**:

- GitHub Copilot CLI recognizes `.agents/skills/` (covered by Copilot CLI support claim above).

**Future-proof coverage**:

- Codex CLI and other AI coding agents may recognize `.agents/skills/` when their project-skill guidance stabilizes.
- v0.24.0 deploys to `.agents/skills/` today, but public discoverability claims are limited to Claude Code + GitHub Copilot CLI until other hosts provide stable evidence.

---

## Canonical Namespace Rules

### Hyphenated Naming (`/specrew-*`)

All active user-facing, operational, and governance references to the slash-command catalog MUST use the **hyphenated form** `/specrew-*`:

- Canonical command references: `/specrew-where`, `/specrew-status`, `/specrew-update`, `/specrew-team`, `/specrew-review`, `/specrew-help`, `/specrew-version`.
- Directory names: `specrew-where/`, `specrew-status/`, etc. (no change from Feature 021).
- YAML frontmatter `name` field: `specrew-where`, `specrew-status`, etc.
- Markdown body guidance: Replace all `/specrew.X` references with `/specrew-X`.
- Documentation, changelog, test assertions, governance artifacts: Use `/specrew-*` form.

**Historical preservation**:

- Pre-v0.24.0 artifacts (Feature 021 spec, archived proposals, older changelog entries) retain their original `/specrew.X` dot-notation as historical record.
- No rewriting of historical artifacts is permitted (preserves audit trail).

### Namespace Coexistence

- The `/specrew-*` namespace remains **additive to `/speckit.*`**.
- No shadowing or collision is permitted: `/specrew-*` commands are slash-command runtime surfaces, while `/speckit.*` commands are lifecycle governance surfaces.
- Discovery menus MUST present both namespaces without ambiguity or hidden shadowing.

---

## v1 Catalog (Feature 024)

| Canonical command | Alias of | Backend route / intent | Discovery/help summary | Host coverage |
| --- | --- | --- | --- | --- |
| `/specrew-where` | — | Existing project-status workflow via `specrew where` / `scripts/specrew-where.ps1` | Show the current Specrew dashboard/status surface | Claude Code, GitHub Copilot CLI |
| `/specrew-status` | `/specrew-where` | Alias to the same backend and semantic result as `/specrew-where` | Alias for project status | Claude Code, GitHub Copilot CLI |
| `/specrew-update` | — | Existing refresh/update workflow via `specrew update` | Refresh Specrew-managed assets and supported platform baselines | Claude Code, GitHub Copilot CLI |
| `/specrew-team` | — | Existing team-management workflow via `specrew team` | Manage Squad team members and baseline-role composition | Claude Code, GitHub Copilot CLI |
| `/specrew-review` | — | Existing review replay workflow via `specrew review` | Trigger or inspect the review-oriented workflow | Claude Code, GitHub Copilot CLI |
| `/specrew-help` | — | Canonical Specrew catalog/help surface | Show the full Specrew slash-command catalog and next-step guidance | Claude Code, GitHub Copilot CLI |
| `/specrew-version` | — | Version/baseline display using installed/runtime and project config state | Show the installed Specrew version and slash-command compatibility state | Claude Code, GitHub Copilot CLI |

**Alias semantics**:

- `/specrew-status` is the **only** alias in v1.
- Alias behavior is **semantic parity**, not "similar output."
- Alias routing MUST preserve the same validation, diagnostics, and dashboard semantics as `/specrew-where`.

---

## Truthfulness Requirements

### Form vs. Meaning Distinction

Feature 024 exists to repair the **form-vs-meaning failure** from Feature 021:

- **Form**: Slash-command `SKILL.md` files exist on disk.
- **Meaning**: Slash commands are discoverable in AI coding host UI and have valid metadata.

**v0.24.0 acceptance criteria**:

- Slash commands MUST be discoverable in Claude Code or GitHub Copilot CLI (manual smoke test during prerelease validation).
- Slash commands MUST have valid YAML frontmatter (automated test coverage).
- Slash commands MUST be deployed to all three target paths with content-identical files (automated test coverage).

### Public Messaging Constraints

**v0.24.0 release messaging** (changelog, module manifest, documentation) MUST:

1. Describe the restored slash-command discoverability in **Claude Code and GitHub Copilot CLI**.
2. Mention host-neutral `.agents/skills/` deployment as future-proofing, **without** claiming Codex CLI or other host discoverability as a v0.24.0 guarantee.
3. Describe cleanup of managed legacy `.copilot/skills/` directories on `specrew update`.
4. Use hyphenated `/specrew-*` form in all active references.
5. NOT rewrite historical pre-v0.24.0 artifacts (preserve `/specrew.X` in historical record).

**Example changelog entry** (v0.24.0):

```markdown
## v0.24.0 - 2026-MM-DD

### Restored Slash-Command Discoverability

- **Multi-host deployment**: Slash commands are now deployed to `.claude/skills/`, `.github/skills/`, and `.agents/skills/` with content-identical `SKILL.md` files, restoring discoverability in **Claude Code** and **GitHub Copilot CLI**.
- **YAML frontmatter**: All slash-command `SKILL.md` files now include valid YAML frontmatter with `name` and `description` fields, ensuring compatibility with host discovery mechanisms.
- **Hyphenated naming**: All active references use the `/specrew-*` form (e.g., `/specrew-where`, `/specrew-status`) to align with directory structure and frontmatter validation.
- **Legacy migration**: `specrew update` safely removes Specrew-managed legacy `.copilot/skills/specrew-*` directories while preserving unmanaged content.
- **Host-neutral future-proofing**: `.agents/skills/` deployment provides a host-neutral path recognized by GitHub Copilot CLI today, with future-proofing for other AI coding agents as their project-skill guidance stabilizes.

### Breaking Changes

- Slash commands are no longer deployed to `.copilot/skills/` (legacy path deprecated). Existing projects must run `specrew update` to migrate to the new multi-host deployment.
```

---

## Discovery Fallback and Help Surface

### Preferred Discovery Path

- **Host-native slash-command discovery** is the preferred experience when the environment supports it (Claude Code or GitHub Copilot CLI).

### Required Fallback

- `/specrew-help` is the **canonical fallback catalog** in every supported environment.
- Broader help surfaces (e.g., `/speckit.help`, GitHub Copilot CLI general help) may reference `/specrew-help`, but they MUST NOT absorb the full Specrew catalog in a way that obscures `/speckit.*` lifecycle commands.

---

## Testing Requirements

### Required Manual Validation (Prerelease Smoke)

1. **Claude Code discoverability smoke test**:
   - Install v0.24.0-beta.1 prerelease.
   - Run `specrew init` in a clean test project.
   - Open Claude Code in the test project.
   - Invoke slash-command discovery menu (typically via `/` prefix or AI chat prompt).
   - Confirm `/specrew-where` appears with description: "Show the current Specrew project status dashboard — the 'where am I?' velocity view for the active feature and iteration."

2. **GitHub Copilot CLI discoverability smoke test**:
   - Install v0.24.0-beta.1 prerelease.
   - Run `specrew init` in a clean test project.
   - Open GitHub Copilot CLI in the test project.
   - Invoke slash-command discovery menu (typically via `/` prefix or help command).
   - Confirm `/specrew-where` appears with description: "Show the current Specrew project status dashboard — the 'where am I?' velocity view for the active feature and iteration."

**Blocking requirement**:

- Stable v0.24.0 promotion is **blocked** until at least one of the two smoke tests passes (Claude Code or GitHub Copilot CLI discoverability confirmed).
- If both hosts are unavailable during prerelease validation, automated test coverage + deployment path validation is accepted as provisional evidence, but manual smoke test must be completed before public release announcement.

### Required Automated Validation

1. **Multi-path deployment test**: Verify all seven commands deployed to all three paths.
2. **Frontmatter validity test**: Verify every deployed `SKILL.md` has valid YAML frontmatter with `name` matching directory and non-empty `description`.
3. **Hyphenated-form migration test**: Verify no `/specrew.X` references remain in active `SKILL.md` body guidance.

---

## Open Questions and Deferrals

- **Codex CLI discoverability validation**: When will Codex CLI project-skill guidance stabilize enough to validate discoverability and expand v0.24.x claims? → Deferred to post-v0.24.0 feature when Codex CLI provides stable project-skill documentation.
- **Discovery menu automation**: Can slash-command discovery be validated via API or headless UI automation instead of manual smoke tests? → Deferred to post-v0.24.0 feature; v0.24.0 uses manual smoke tests.
- **Host-specific metadata extensions**: If future hosts require additional YAML frontmatter fields, will Specrew maintain content-identical deployment or introduce host-specific variations? → Deferred to post-v0.24.0 feature when evidence of host-specific requirements surfaces.

---

## Version and Governance

**Contract Version**: 1.0.0  
**Effective Date**: 2026-05-19 (Feature 024 plan-complete)  
**Amendment Policy**: Changes to this contract require explicit feature scope, spec approval, and cross-reference from tasks.md and implementation plan.  
**Supersedes**: Feature 021 discovery contract (single-path `.copilot/skills/` deployment, dot-notation `/specrew.X` naming, no frontmatter).
