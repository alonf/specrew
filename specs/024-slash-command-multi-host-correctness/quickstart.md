# Quickstart: Validate Feature 024 Planning Slice

**Feature**: 024-slash-command-multi-host-correctness  
**Audience**: Runtime maintainer, template steward, QA owner, release owner  
**Purpose**: Provide an implementation-ready walkthrough for the Feature 024 runtime, template, and validation changes.

## Scope Map

```text
extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1
extensions/specrew-speckit/squad-templates/skills/specrew-*/SKILL.md
extensions/specrew-speckit/squad-templates/skills/README.md
tests/integration/slash-command-distribution.tests.ps1
tests/integration/slash-command-discovery.tests.ps1
tests/integration/slash-command-compatibility.tests.ps1
tests/integration/slash-command-coexistence.tests.ps1
tests/integration/slash-command-multi-path.tests.ps1          # new
tests/integration/slash-command-frontmatter.tests.ps1         # new
tests/integration/slash-command-legacy-migration.tests.ps1    # new
CHANGELOG.md
proposals/058-plugin-based-multi-host-distribution.md
```

## Step 1: Refresh the seven source templates

For each `extensions/specrew-speckit/squad-templates/skills/specrew-*/SKILL.md`:

1. Add YAML frontmatter:

```yaml
---
name: specrew-where
description: Show the current Specrew project status dashboard for the active feature and iteration.
---
```

2. Keep the existing body guidance intact.
3. Replace active legacy dotted slash-command references with `/specrew-*`.
4. Update `extensions/specrew-speckit/squad-templates/skills/README.md` to describe the corrected multi-host surface.
5. Keep `/specrew-help` documented as the canonical discovery fallback when host-native slash discovery is incomplete.

**Checks**

```powershell
rg '/specrew\.' extensions/specrew-speckit/squad-templates/skills
rg '^---$|^name: |^description: ' extensions/specrew-speckit/squad-templates/skills/specrew-*/SKILL.md
```

## Step 2: Replace single-path deployment with three-path deployment

Update `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` so slash-command skills are deployed as one logical set to:

- `.claude/skills/`

- `.github/skills/`

- `.agents/skills/`

Implementation expectations:

1. Read one canonical `SKILL.md` source per command.
2. Write content-identical copies to all three targets.
3. Stop treating `.copilot/skills/` as an active deployment target.
4. Preserve the existing deployment-action reporting style.

## Step 3: Add safe legacy cleanup to `specrew update`

During `specrew update`:

1. Scan `.copilot/skills/` for `specrew-*` directories.
2. Remove a legacy directory only when the implementation can prove it is Specrew-owned.
3. Preserve unmanaged content and surface it as leftover non-discoverable content.
4. Make repeat runs safe and non-destructive.

**Rule**: deletion by directory name alone is forbidden.

## Step 4: Migrate the existing validation scripts

Update these existing scripts to the corrected surface:

- `tests/integration/slash-command-distribution.tests.ps1`

- `tests/integration/slash-command-discovery.tests.ps1`

- `tests/integration/slash-command-compatibility.tests.ps1`

- `tests/integration/slash-command-coexistence.tests.ps1` (only where active slash-command spelling needs adjustment)

Expected migration themes:

- `.copilot/skills/` assumptions become three-path assertions

- `/specrew.*` assertions become `/specrew-*`

- active docs/contracts under test point to Feature 024 artifacts rather than Feature 021’s historical single-path contract

## Step 5: Add three new standalone integration scripts

Create:

- `tests/integration/slash-command-multi-path.tests.ps1`

- `tests/integration/slash-command-frontmatter.tests.ps1`

- `tests/integration/slash-command-legacy-migration.tests.ps1`

Each should follow the repo’s existing standalone PowerShell test-script style (`Set-StrictMode`, custom `Write-Pass` / `Write-Fail`, explicit `exit 1` on failure), not a new Pester-only harness.

Required assertions:

1. **Multi-path**: all seven commands land in all three active paths, with byte-identical `SKILL.md` content.
2. **Frontmatter**: every deployed `SKILL.md` has valid YAML frontmatter, directory-matching `name`, and non-empty `description`.
3. **Legacy migration**: `specrew update` removes only explicit Specrew-owned legacy `.copilot/skills/specrew-*` content and preserves unmanaged content.

## Step 6: Validate the automated lane

Run the migrated/new scripts from repo root:

```powershell
pwsh -NoProfile -File tests/integration/slash-command-distribution.tests.ps1
pwsh -NoProfile -File tests/integration/slash-command-discovery.tests.ps1
pwsh -NoProfile -File tests/integration/slash-command-compatibility.tests.ps1
pwsh -NoProfile -File tests/integration/slash-command-coexistence.tests.ps1
pwsh -NoProfile -File tests/integration/slash-command-multi-path.tests.ps1
pwsh -NoProfile -File tests/integration/slash-command-frontmatter.tests.ps1
pwsh -NoProfile -File tests/integration/slash-command-legacy-migration.tests.ps1
```

Also run active-reference audits:

```powershell
rg '/specrew\.' CHANGELOG.md docs extensions scripts tests .github .specify proposals --glob '!specs/021-specrew-slash-commands/**' --glob '!specs/024-slash-command-multi-host-correctness/**'
rg '\.copilot/skills|\.copilot\\skills' extensions scripts tests docs .github
```

## Step 7: Update release/governance messaging

Before closeout:

1. Update `CHANGELOG.md` for v0.24.0 with truthful wording:
   - discoverability claims only for Claude Code + GitHub Copilot CLI
   - `.agents/skills/` described as host-neutral deployment, not Codex proof
   - managed legacy cleanup on update
2. Reframe `proposals/058-plugin-based-multi-host-distribution.md` so skills are no longer an unresolved delivery concern; keep Proposal 058 focused on non-skill instruction-file harmonization.

## Step 8: Run prerelease validation before stable promotion

For `v0.24.0-beta.1`:

1. Start from a clean PowerShell session.
2. Bootstrap a clean project with `specrew init`.
3. Verify `.claude/skills/`, `.github/skills/`, and `.agents/skills/` each contain the seven commands.
4. Confirm deployed files have valid frontmatter and byte-identical content.
5. Seed managed + unmanaged legacy `.copilot/skills/specrew-*` content, run `specrew update`, and verify only managed content is removed.
6. Perform a manual discoverability smoke test in **Claude Code or GitHub Copilot CLI** and confirm `/specrew-where` appears.

**Release stop condition**: do not promote stable v0.24.0 until Step 8 succeeds.

## Handoff to `/speckit.tasks`

Task generation should produce work packages for:

1. template/frontmatter refresh
2. deployment-logic refactor
3. legacy-cleanup implementation
4. existing-test migration
5. three new standalone integration scripts
6. release/proposal/changelog truthfulness updates

7. prerelease smoke and evidence capture

- If hashes differ, inspect file content with `Compare-Object` to identify divergence.

**Remediation**:

- Report issue to Specrew maintainers (indicates deployment logic bug).

- Re-run `specrew update` to re-deploy from single source template.

### Legacy migration deletes unmanaged content

**Symptom**: User-created `.copilot/skills/specrew-custom/` directory is deleted after `specrew update`.

**Diagnosis**:

- Check if managed-marker detection incorrectly classified unmanaged content as managed.

- Review deployment logs for `removed-legacy-managed-skill` action against the unmanaged directory.

**Remediation**:

- Report critical issue to Specrew maintainers (violates safe-migration contract).

- Restore content from Git history or manual backup.

- Patch managed-marker detection logic and release hotfix.

---

## Next Steps

After completing Phase 1 (research, data-model, contracts, quickstart), proceed to **Phase 2** (`/speckit.tasks` command) to generate `tasks.md` with dependency-ordered implementation tasks.
