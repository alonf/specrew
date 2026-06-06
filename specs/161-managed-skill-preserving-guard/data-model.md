# Data Model: Managed-Skill "Stuck Preserving" Guard

**Feature**: 161-managed-skill-preserving-guard
**Date**: 2026-06-06
**Purpose**: Define the entities, attributes, and classification rules that
govern the managed/preserve decision under investigation. No application
persistence is involved; all state is file-system layout plus an in-memory
deployment-action record.

## Entity: SkillDefinition

**Purpose**: One canonical Specrew skill as the deploy script materializes it
from `extensions/specrew-speckit/squad-templates/skills/`.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| Directory | string | yes | `specrew-*` name | Target skill directory name |
| CurrentContent | string | yes | non-empty | Current canonical `SKILL.md` text |
| Kind | string | yes | `generic` \| `slash-command` | Drives the legacy-signature fallback shape |
| LegacyContent | string | generic only | equals CurrentContent at build time | Legacy comparison text for generic skills |
| LegacySlashCommand | string | slash only | `/specrew.*` | Legacy command line used by the signature fallback |

### Lifecycle / Relationships

Built per deploy run from the template root; never persisted. Each legacy
`.copilot/skills/specrew-*` directory is matched to at most one definition by
name; unmatched directories are preserved without classification.

## Entity: SkillDirectoryState

**Purpose**: The on-disk state of one skill directory at classification time —
the input the classifier actually sees.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| Path | string | yes | exists | Directory under a legacy or active skill root |
| HasMarker | bool | yes | — | `.specrew-managed` sidecar file present |
| SkillContent | string | no | raw text | `SKILL.md` content (may be absent/empty) |
| ContentClass | enum | derived | see classification rules | current-canonical \| stale-canonical \| legacy-signature \| user-authored \| empty/absent |

### Classification rules (current behavior, `Test-IsManagedLegacySkillDirectory`)

1. HasMarker → **managed**.
2. No `SKILL.md` / empty → **not managed** (preserved).
3. Exact ordinal match to CurrentContent/LegacyContent → **managed** (F-160).
4. Content starts with `---` → **not managed** (preserved) — *this is where
   stale-canonical front-matter content lands: the residual hypothesis.*
5. Generic kind: exact equality to LegacyContent; slash kind: legacy heading +
   namespace + command signature → **managed**.
6. Otherwise → **not managed** (preserved).

## Entity: DeploymentActionRecord

**Purpose**: The observable outcome trail (`Add-DeploymentAction`) the repro
harness asserts on.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| Action | string | yes | known action vocabulary | e.g. `removed-legacy-managed-skill`, `preserved-legacy-unmanaged-skill`, `created`, `updated`, `preserved` |
| Path | string | yes | inside scratch project | Affected file/directory |

### Lifecycle / Relationships

Produced per deploy run; the harness captures it (and the resulting disk
state) per scenario S1–S6 and derives the verdict input from S4.

## Entity: VerdictRecord

**Purpose**: The durable investigation outcome (FR-003).

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| Outcome | enum | yes | CONFIRMED \| REFUTED | Residual stuck-preserving risk |
| CodePath | string | yes | file + function + rule number | Exact classification rule responsible |
| Reachability | string | yes | evidence-backed | Whether a real upgrade path produces the triggering state |
| FixApplied | bool | yes | true only if Outcome=CONFIRMED | Tier 1 gate |

### Lifecycle / Relationships

Written into iteration quality evidence and review.md before review-signoff;
referenced by retro and feature closeout.
