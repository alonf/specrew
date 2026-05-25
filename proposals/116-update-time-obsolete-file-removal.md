---
proposal: 116
title: Update-Time Obsolete-File Removal — Manifest-Driven Pruning of Deprecated Specrew Artifacts
status: candidate
phase: phase-2
estimated-sp: 10-15
priority-tier: 2
type: methodology+tooling
discussion: tbd
depends-on:
  - F-044 # Per-Host Architecture Refactor (provides Specrew-managed sentinel + canonical-source pattern)
composes-with:
  - 110 # Specrew Update Experience (pre-update commit + agent-driven explanation)
  - 075 # Update Artifact Backfill Discipline (companion: 075 ADDS missing artifacts to old iterations; 116 REMOVES obsolete deployed files)
  - 091 # Tech Debt Control (orphan files are accumulated debt)
audience: methodology
---

# Update-Time Obsolete-File Removal — Manifest-Driven Pruning of Deprecated Specrew Artifacts

## Why

`specrew init` and `specrew update` today are both **additive only**. They detect missing canonical files and deploy them — they do not detect or remove deployed files that the current Specrew version no longer wants there.

Specrew evolves. File paths change across versions:

- **Renames**: a skill file moved from `.copilot/skills/specrew-validate.md` (v0.20 path) to `.github/skills/specrew-validate.md` (v0.24 path, F-024). The `init`/`update` machinery deploys the new path, but the old path's file remains in the user's project as an orphan.
- **Directory restructuring**: a template moved from `.specify/scripts/powershell/foo.ps1` to `.specify/scripts/foo.ps1`. Old location stays.
- **Removal**: a file that was canonical at v0.22 was retired at v0.25 (concept replaced, validator subsumed, etc.). The retired file remains forever in user projects that upgraded across that boundary.

Symptoms of this accumulation:

- **User confusion**: which file is authoritative? The validator may now key off the new path, but tooling that defaults to "any file in the directory" reads both.
- **Stale-content drift**: orphan files capture a frozen-in-time view of conventions that no longer apply. A user looking at `.copilot/skills/foo.md` (v0.20 era) may follow obsolete guidance.
- **Hard to bootstrap forensics**: "did you `init` after upgrading?" becomes a recurring support question because there's no command that means "make my project match the canonical layout for my current Specrew version".
- **Empirical 2026-05-25 evidence**: Specrew's own dev tree (`C:\Dev\Specrew`) was missing `.claude/skills/` because it was bootstrapped pre-F-024 and never re-init'd. Conversely, when projects upgrade across path-change boundaries, the opposite happens — old paths stay. Both are symptoms of the same gap: **no command reconciles deployed layout against canonical-for-this-version layout**.

The current workaround — telling users "run `specrew init` after `Update-Module`" — is UX-confusing for external testers (the word "init" suggests a fresh setup, not a refresh) AND incomplete (init is additive, never subtractive).

### User question (2026-05-25 chat session)

> "If I do init again, we may leave old files that is no longer in use (name change or location change). This is why it has to be update, it should also clear unneeded files."

The correct answer is: yes, **`specrew update` should be the source-of-truth reconciliation command** — adding new canonical files AND removing files that are no longer canonical at the current Specrew version. This proposal defines that machinery.

## What — Five Pillars

### Pillar 1: Per-Version Canonical Manifest

Every released Specrew module version ships a manifest declaring all files it expects to be present in a target project at that version. Manifest lives at:

```text
<module-root>/manifests/deployed-files.yml
```

Schema:

```yaml
manifest-version: 1
specrew-version: "0.27.0"
files:
  - path: ".claude/skills/specrew-validate.md"
    deploy-source: "extensions/specrew-speckit/skill-catalog/specrew-validate.md"
    sentinel-required: true
    introduced-in: "0.24.0"
    description: "Slash-command surface for /specrew-validate on Claude host"
  - path: ".github/skills/specrew-validate.md"
    deploy-source: "extensions/specrew-speckit/skill-catalog/specrew-validate.md"
    sentinel-required: true
    introduced-in: "0.24.0"
    description: "Slash-command surface for /specrew-validate on Copilot host"
  - path: ".specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md"
    deploy-source: "extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md"
    sentinel-required: true
    introduced-in: "0.16.0"
    description: "Coordinator governance template (mirror of canonical at extensions/)"
  # ... ~80-120 entries covering full deployment surface
```

The manifest is **authoritative for deployment intent at this version**. `specrew init` reads it to know what to deploy; `specrew update` reads BOTH the previous-version manifest (cached from last update) AND the current-version manifest to compute the diff.

### Pillar 2: Update-Time Diff Engine

At `specrew update`, the engine computes:

| Set | Definition | Action |
|---|---|---|
| **New canonical** | In current manifest, not in previous manifest | Deploy (existing init behavior) |
| **Retained canonical** | In both manifests | Refresh if template changed (existing update behavior) |
| **Obsolete canonical** | In previous manifest, NOT in current manifest | **NEW**: candidate for removal (safety gates below) |
| **Unmanaged** | On disk but never in any Specrew manifest | Leave alone (user files) |

The diff itself is small and fast (~ms). Computing it requires the previous manifest to be cached locally. New requirement: `specrew init` and `specrew update` **persist the manifest they applied** to `.specrew/state/last-deployed-manifest.yml`.

### Pillar 3: Safety Gates

Removal is gated by four checks, ALL of which must pass before a file is removed:

1. **Sentinel check (F-044 Slice 9 pattern)**: file contains the `<!-- specrew-managed -->` marker (or equivalent for non-markdown file types). Files without the sentinel are skipped regardless — the user may have replaced the canonical file with their own version.
2. **User-edit detection**: file's content-hash matches a known canonical version (either current OR any prior version Specrew deployed). If the hash matches no known version, the user has modified the file post-deployment → skip removal + surface to user.
3. **Pre-update commit gate (composes with Proposal 110 Pillar)**: working tree must be clean OR user opts in via `--allow-dirty` flag. Without a clean working tree, there's no rollback if removal goes wrong.
4. **Dry-run mode**: `specrew update --dry-run` always available, prints the full removal list + reasons without acting. Default `specrew update` interactive run shows the list + asks for confirmation (one-shot, not per-file).

Files that fail safety gates 1 or 2 are surfaced to the user via the update output:

```text
The following files are no longer canonical at Specrew 0.27.0 but were not removed:

  .copilot/skills/specrew-validate.md
    Reason: file modified by user (hash differs from any known canonical)
    Action: review + delete manually if desired, or keep your customized version

  .specify/scripts/powershell/legacy-helper.ps1
    Reason: sentinel marker missing (file may have been intentionally replaced)
    Action: review + delete manually if desired
```

### Pillar 4: Audit Trail

Every update-time removal logs to `.specrew/state/update-log.md` as a structured append-only record:

```markdown
## 2026-05-25 09:42 — Specrew 0.24.1 → 0.27.0

### Files Removed (path no longer canonical at 0.27.0)

- `.copilot/skills/specrew-init.md` — retired at 0.24.0 (replaced by multi-host deploy to `.github/skills/`)
- `.specify/scripts/powershell/old-validator.ps1` — retired at 0.25.0 (subsumed by extensions/specrew-speckit/scripts/validate-governance.ps1)

### Files Added (new canonical at 0.27.0)

- `.claude/skills/specrew-validate.md`
- `.agents/skills/specrew-validate.md`

### Files Skipped (safety-gate failure)

- `.copilot/skills/specrew-where.md` — user-modified (hash differs from known canonical)
```

The audit trail composes with Proposal 110's "what's-new surface" — the Crew can reference it when explaining the update to the user.

### Pillar 5: Crew-Driven Explanation (composes with Proposal 110)

Update-time messaging in the coordinator prompt explains the diff:

```text
### Specrew updated: 0.24.1 → 0.27.0

What changed in your project layout:

- Added 3 files (new multi-host skill catalog)
- Refreshed 17 files (templates updated)
- Removed 2 obsolete files (paths changed in v0.24.0)
- Skipped 1 file (user-modified — see .specrew/state/update-log.md)

Full audit: file:///<project>/.specrew/state/update-log.md
```

The "Why" for each removed file comes from the manifest's `retired-in` field (added to manifest schema), so the agent can narrate "we removed `foo.md` because it was retired at 0.24.0 when multi-host skill deploy replaced the single-host pattern".

## How — Implementation Surface

| Component | File | Effort |
|---|---|---|
| Manifest authoring (one-time backfill for current version) | `manifests/deployed-files.yml` | 3-4 SP |
| Manifest generation script (extract from init/update logic) | `scripts/internal/generate-deployed-manifest.ps1` | 2 SP |
| Diff engine | `scripts/internal/compute-deployment-diff.ps1` | 2 SP |
| Safety-gate logic (sentinel + hash + clean-tree + dry-run) | `scripts/internal/apply-deployment-diff.ps1` | 2-3 SP |
| `specrew update` integration | `scripts/specrew-update.ps1` | 1 SP |
| Manifest persistence (after init/update) | `scripts/specrew-init.ps1` + `scripts/specrew-update.ps1` | 1 SP |
| Audit-log writer | `scripts/internal/write-update-log.ps1` | 1 SP |
| Tests (golden manifest fixtures + dry-run + safety-gate failures) | `tests/update-time-pruning.tests.ps1` | 2-3 SP |
| Docs (`docs/updating.md` extension) | `docs/updating.md` | 0.5 SP (folded into v0.27.1 patch's docs/updating.md) |

**Total estimate**: ~14-16 SP. Skewed toward the upper end if rename detection (Pillar 3 enhancement) gets included.

### Phasing within v0.28.x

The deliverable is a single iteration ~Phase 2 (post-v0.27.x quality bundle). Phasing internally:

1. **Slice 1**: Manifest schema + generator + persistence (no removal yet — only emit + cache the manifest for the current version)
2. **Slice 2**: Diff engine + dry-run mode (prints what WOULD be removed, doesn't act)
3. **Slice 3**: Removal with safety gates + audit log + Crew explanation

Slice 1+2 is non-destructive and can ship as a checkpoint. Slice 3 is the user-visible removal behavior.

## Composition Notes

### With Proposal 110 (Specrew Update Experience)

110's Pillars (multi-host awareness, what's-new surface, pre-update safety, agent-driven explanation) and 116's Pillars are **highly complementary**:

- 110's "pre-update safety" pillar (commit before update, rollback if needed) is the precondition for 116's destructive removal action.
- 110's "agent-driven explanation" pillar narrates the diff; 116 supplies the structured data (manifest delta + audit log) for the narration.
- 110's "what's-new surface" advertises NEW features; 116 supplies the symmetric "what's-removed" surface.

These could ship as a bundle (Proposal 110 + 116 combined) or as two compositional proposals. Recommendation: **ship 110 first** to land the pre-update commit + agent-explanation infrastructure, then **ship 116** to extend the same machinery with removal capability. The author of 110 is best positioned to decide whether to fold 116 in or keep separate.

### With Proposal 075 (Update Artifact Backfill Discipline)

075 and 116 are mirror images:

- **075** addresses: "we shipped NEW artifacts at 0.30 that old iterations don't have — should we backfill them?"
- **116** addresses: "we RETIRED files at 0.30 that old projects still have — should we remove them?"

Both proposals operate on the same conceptual diff but in different directions and on different scopes (075 = artifacts inside iterations; 116 = deployed files at project level). They share no machinery directly but share the design philosophy: "Specrew evolution should reconcile project state with current canonical layout, with user-opt-in safety."

### With Proposal 091 (Tech Debt Control)

Orphan files are a special case of tech debt — unintentional accumulation due to additive-only tooling. 091's debt-ledger could optionally surface orphan files as a debt category, but 116's manifest-driven approach prevents accumulation in the first place. They compose: 116 prevents new orphans; 091 surfaces legacy orphans that pre-date 116's manifest era.

## Open Questions

1. **Manifest hand-authoring vs auto-generation?** First-time manifest authoring requires sweeping the codebase to enumerate every deployed file. Could auto-generate from init/update deployment code (paths it touches → manifest entries). Probably want both: generator runs on every commit + checks output into repo for hand-edit + commit.

2. **Should `specrew update --refresh-only` run without removal?** As an opt-out for users who don't want destructive behavior at update time. Plausible flag: `specrew update --no-prune`.

3. **Rename detection — smart or naive?** Smart rename detection (file at old path with sentinel + identical content-hash to file at new path = treat as rename, no removal needed) is a nice-to-have but adds complexity. Naive: always delete old + deploy new. Recommend naive for v1; smart as Phase 3 enhancement.

4. **First-time bootstrap (no previous manifest cached)?** When `specrew update` runs but no `.specrew/state/last-deployed-manifest.yml` exists (pre-116 project), what should happen? Options: (a) skip removal that update entirely + cache current manifest for next time; (b) infer previous-version manifest from `.specrew/config.yml`'s `specrew_version` field + module's historical manifest archive. (b) is better UX but requires shipping historical manifests with the module.

5. **How are user-added team agents (via `specrew team add`) protected?** Per F-044 Slice 9, user-added agents in `.specrew/team/agents/` lack the Specrew-managed sentinel — they're naturally excluded from removal by safety gate 1. Confirm this is sufficient or whether an explicit allow-list is needed.

6. **Cross-version skip (e.g., 0.22 → 0.27 directly)?** User skips 5 versions. The previous manifest cache says 0.22, but they're updating to 0.27. Should the removal diff use the 0.22 manifest, OR walk through each intermediate version's manifest and accumulate? Walking is more thorough (catches files retired-then-reintroduced) but slower. Recommend single-jump diff for v1; walking as Phase 3 enhancement.

## Not in Scope

- Removing user-authored files (only files Specrew deployed are candidates)
- Removing `.specrew/decisions.md`, `.specrew/config.yml`, or any non-template state file
- Reorganizing the deployment surface itself (this proposal observes the surface; doesn't redesign it)
- Backfilling artifacts inside existing iterations (that's Proposal 075's scope)
- Pre-update commit machinery (that's Proposal 110's scope; 116 depends on it but doesn't re-author it)
- Custom-extension files installed by user-authored Specrew extensions (out of scope until the extension model is more mature)

## Empirical Motivation Captured

- **2026-05-25**: User identified the gap during v0.27.0 release work. `Update-Module Specrew` left missing `.claude/skills/` in the dev tree because the dev tree was bootstrapped pre-F-024. Conversely, projects that upgrade across path-change boundaries (like F-024's multi-host skill deploy) accumulate orphans at old paths. Both symptoms = same gap.
- **Pattern across project history**: F-024 (multi-host skill deploy), F-044 (per-host architecture refactor), and the speculative F-019 (PSGallery distribution) all shifted deployed-file paths. Every path-change boundary creates a generation of orphans for projects that don't run `specrew init` afterward. The init step is currently the only safety valve, and it's both UX-confusing AND additive-only (doesn't remove).

## Status History

- **2026-05-25** — Drafted from empirical motivation surfaced during v0.27.0 release work. Candidate status. Composes with Proposal 110 (Specrew Update Experience) which the concurrent Claude session authored same day; sequencing recommendation is 110 ships first to land pre-update-commit + agent-explanation infrastructure, then 116 extends with removal capability.
