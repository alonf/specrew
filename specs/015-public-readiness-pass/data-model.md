# Data Model: Public-Readiness Pass

**Feature**: 015 Public-Readiness Pass  
**Branch**: `015-public-readiness-pass`  
**Phase**: 1 — Design  
**Date**: 2026-05-13

---

## Overview

This feature is a documentation and governance tooling pass; it introduces no runtime data
structures or database schemas. The "data model" here describes the **logical entities** whose
content and state are governed by this feature, their required fields, validation rules, and
relationships.

---

## Entity 1: Public-Readiness Surface

**Definition**: The set of top-level repository artifacts that shape first impressions for public
observers. All of these must be present and accurate before the repository can be considered
public-ready.

**Artifact Members**:

| Artifact | Path | Required By | State at Planning | Target State |
| --- | --- | --- | --- | --- |
| MIT License | `LICENSE` | FR-001 | Missing | Present; MIT text with correct copyright line |
| Attribution Notice | `NOTICE.md` | FR-002 | Missing | Present; Squad + Spec Kit credits |
| README | `README.md` | FR-003–FR-007 | Stale; missing sections | Rewritten with all 8 required sections |
| Changelog | `CHANGELOG.md` | FR-009 | Missing | Present; 14 retroactive entries |
| Version Reference | `docs/versioning.md` | FR-014 | Missing | Present; full versioning policy |

**Validation Rules** (enforced by `Test-PublicReadinessSurfaces` in `validate-governance.ps1`):

- `LICENSE` file must exist at repo root
- `NOTICE.md` file must exist at repo root
- `CHANGELOG.md` file must exist at repo root
- `docs/versioning.md` file must exist
- `README.md` must exist and contain at least one occurrence of the current version string
  (heuristic staleness check)

**Staleness Detection**:

- Missing file → `WARN [public-readiness] missing-artifact: <path>`
- README does not contain version string → `WARN [public-readiness] stale-version-in-readme`
- Missing `docs/versioning.md` → `WARN [public-readiness] missing-artifact: docs/versioning.md`

**Warning Severity**: Soft warning only (`Write-Host ... -ForegroundColor Yellow`). MUST NOT
trigger `exit 1`.

---

## Entity 2: Licensing Notice Record

**Definition**: The `NOTICE.md` document that preserves MIT license attribution obligations for
upstream-derived Specrew materials.

**Required Fields**:

| Field | Value / Format | Notes |
| --- | --- | --- |
| `upstream-name` | "Squad" / "Spec Kit" | One section per upstream |
| `upstream-license` | "MIT License" | Explicit statement |
| `upstream-authors` | Per upstream project's NOTICE or README | Required by MIT attribution |
| `derived-directories` | List of Specrew paths that derive from each upstream | FR-002 explicit |
| `notice-text` | Required MIT notice text from upstream project | Copy verbatim or reference |

**Structure** (per upstream):

```markdown
## [Upstream Project Name]

This project incorporates materials derived from [Upstream], which is licensed under the MIT License.

**Derived Specrew directories**: [list]

[MIT notice text or reference to upstream project repository for full notice]
```

**Validation**: No automated schema enforcement; human reviewer confirms presence of Squad and
Spec Kit sections and that derived directories are identified.

---

## Entity 3: Release Version Record

**Definition**: The combined truth surface formed by the declared current version, changelog
history, and release tags.

**Sub-entities**:

### 3a. Declared Version

| Field | Value | Location |
| --- | --- | --- |
| current version | `0.14.0` | `.specrew/config.yml` (`specrew_version`), `README.md` Current State section, `docs/versioning.md` |
| versioning scheme | `0.NN.0` per feature; `0.NN.M` hotfix | `README.md` summary + `docs/versioning.md` |
| previous stale value | `0.1.0-dev` (bootstrap-era Specrew version declaration) | `.specrew/config.yml` |

### 3b. Changelog Entry

Each `CHANGELOG.md` entry for a retroactive feature release:

| Field | Required | Format |
| --- | --- | --- |
| version header | Yes | `## [0.NN.0] — YYYY-MM-DD` |
| feature ordinal | Yes | `### Feature NNN — <name>` |
| one-line summary | Yes | Plain-language description |
| commit/merge ref | Recommended | `(commit <sha> / PR #NN)` |
| PR reference | Optional | Include only when it adds clarity |

**Example Entry**:

```markdown
## [0.13.0] — 2026-04-XX

### Feature 013 — Validator Hardening
Canonical schema enforcement, structured validator failures, and approval-reuse detection.
(Merge PR #79, commit 21d9e7f)
```

### 3c. Release Tag

| Field | Value | Notes |
| --- | --- | --- |
| tag name | `v0.13.0` | Lightweight annotated tag |
| tag target | commit `21d9e7f` | Merge PR #79 — Features 008–013 catch-up merge |
| tag message | `Specrew v0.13.0 — Features 008-013 catch-up merge (PR #79)` | |
| tag name | `v0.14.0` | Lightweight annotated tag |
| tag target | commit `3ff32d4` | Merge PR #99 — Feature 014 current mainline |
| tag message | `Specrew v0.14.0 — Feature 014 handoff-format-scoping (PR #99)` | |

**State Transitions**:

```
[no tags] → v0.13.0 created retroactively at 21d9e7f
           → v0.14.0 created at 3ff32d4 (current HEAD of main)
           → both pushed to origin
```

---

## Entity 4: Product Status Record

**Definition**: The status declaration in `specs/001-specrew-product/spec.md` that tells readers
whether the product vision is still in draft or actively shipping.

| Field | Current Value | Target Value | Location |
| --- | --- | --- | --- |
| `Status` | `Draft` | `Active 0.14.0` | `specs/001-specrew-product/spec.md` front-matter line |
| accompanying note | (none) | One-sentence explanation that the vision is backed by 14 shipped implementing features | After status line or in a brief note |

**Validation**: Human reviewer confirms the status line reads `Active 0.14.0` and a brief
justification note is present.

---

## Entity 5: Closeout Versioning Checklist

**Definition**: The governance steps that ensure version bumping, changelog updates, and release
tagging happen during every future feature closeout.

**Location**: `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`
(additive new rule), mirrored in `.specify/extensions/specrew-speckit/squad-templates/coordinator/`

**Required Steps** (to be added as a new numbered rule):

```markdown
## Feature Closeout Version Management

At every feature closeout, the coordinator and governance artifacts MUST include:

1. **Version bump**: Advance `.specrew/config.yml` `specrew_version` from `0.NN.0` to `0.(NN+1).0`
   where NN+1 matches the feature ordinal being closed.
2. **Changelog update**: Append a new entry to `CHANGELOG.md` with the feature ordinal,
   one-line summary, and commit/merge reference.
3. **Release tag**: Create and push an annotated git tag `v0.(NN+1).0` pointing to the
   merge commit of the feature branch.
4. **README version**: Update the current-version reference in `README.md` Current State
   section to match the new version.
5. **Verification**: Run `validate-governance.ps1` after tagging; confirm soft warnings
   for public-readiness surfaces are resolved.
```

**Validation**: Proof is at next real feature closeout (Feature 016+). The governance guidance
update is independently auditable from the artifact.

---

## Entity 6: Public-Readiness Drift Warning

**Definition**: The validator-emitted soft-warning signal that flags missing or stale
public-facing release artifacts during routine `validate-governance.ps1` runs.

**Emitted by**: New function `Test-PublicReadinessSurfaces` in:

- `extensions/specrew-speckit/scripts/validate-governance.ps1`
- `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1` (mirror copy)

**Warning Record**:

| Field | Type | Example |
| --- | --- | --- |
| `prefix` | string | `WARN` |
| `namespace` | string | `[public-readiness]` |
| `category` | string | `missing-artifact` / `stale-version-in-readme` |
| `detail` | string | path or description of what is missing/stale |

**Output Format**:

```
WARN [public-readiness] missing-artifact: LICENSE
WARN [public-readiness] missing-artifact: NOTICE.md
WARN [public-readiness] stale-version-in-readme: README.md does not contain version string
```

**Severity Contract**:

- Output colour: Yellow (`Write-Host ... -ForegroundColor Yellow`)
- Exit code: NOT affected — exit 0 if only soft warnings are present
- Existing hard-fail paths: unchanged

---

## Entity Relationships

```
Public-Readiness Surface
  ├── LICENSE ──────────────────────────────── required by MIT obligations
  ├── NOTICE.md ─── Licensing Notice Record ── required by upstream attribution
  ├── README.md ─── contains version ref ───── links to Release Version Record
  ├── CHANGELOG.md ─ Changelog Entry × 14 ──── links to Release Version Record  
  └── docs/versioning.md ───────────────────── detailed policy for Release Version Record

Release Version Record
  ├── Declared Version (.specrew/config.yml + README + docs/versioning.md)
  ├── Changelog Entry (CHANGELOG.md × N)
  └── Release Tag (git tag v0.NN.0)

Product Status Record
  └── specs/001-specrew-product/spec.md (Status: Active 0.14.0)

Closeout Versioning Checklist
  └── specrew-governance.md (additive rule → future Closeout Versioning steps)

Public-Readiness Drift Warning
  └── validate-governance.ps1 / Test-PublicReadinessSurfaces()
      ├── checks: LICENSE, NOTICE.md, CHANGELOG.md, docs/versioning.md (existence)
      └── checks: README.md (contains version string — heuristic staleness)
```

---

## State Transition Summary

| Entity | Before Feature 015 | After Iteration 001 | After Iteration 002 |
| --- | --- | --- | --- |
| LICENSE | Missing | Present | Present |
| NOTICE.md | Missing | Present | Present |
| README sections | Stale / incomplete | Rewritten (8 sections) | Updated with version |
| Product spec status | Draft | Active 0.14.0 | Active 0.14.0 |
| CHANGELOG.md | Missing | Missing | Present (14 entries) |
| docs/versioning.md | Missing | Missing | Present |
| version declaration | Stale `.specrew/config.yml` value `0.1.0-dev` | `0.14.0` in `.specrew/config.yml`, README, and docs/versioning.md | Fully reconciled |
| git tags v0.13.0/v0.14.0 | Missing | Missing | Created and pushed |
| Closeout governance | No version steps | No version steps | Steps added |
| Drift check | No check | No check | Soft warning active |
