# Quickstart: Public-Readiness Pass

**Feature**: 015 Public-Readiness Pass  
**Branch**: `015-public-readiness-pass`  
**Phase**: 1 — Design  
**Date**: 2026-05-13

---

## What This Feature Delivers

Feature 015 makes the Specrew repository ready for public-open by creating licensing files,
rewriting public documentation, reconciling the version number, adding a retroactive changelog,
creating git release tags, updating the product-spec status, and extending future feature-closeout
governance so release bookkeeping is embedded by default.

No new runtime code is introduced. The primary deliverables are Markdown files, git tags, and a
targeted additive extension to `validate-governance.ps1`.

---

## Iteration Overview

### Iteration 001 — Licensing, README, Product Status

**Scope**: FR-001, FR-002, FR-003–FR-007, FR-011, FR-015  
**Effort**: ≈10 story points  
**Authorization boundary**: Spec + Iteration 001 planning scaffold + upstream-tracking push
(FR-015). Hardening-gate sign-off and implementation start require later explicit human approval.

**Deliverables**:

| Deliverable | Path | Requirement |
| --- | --- | --- |
| MIT License | `LICENSE` | FR-001 |
| Attribution notice | `NOTICE.md` | FR-002 |
| Rewritten README | `README.md` | FR-003–FR-007 |
| Product spec status update | `specs/001-specrew-product/spec.md` | FR-011 |
| Iteration 001 planning scaffold | `specs/015-public-readiness-pass/iterations/001/` | FR-015 |

**Acceptance Check for Iteration 001**:
- `LICENSE` exists at repo root and contains the MIT license text
- `NOTICE.md` exists at repo root and has sections for Squad and Spec Kit
- `README.md` contains all 8 required sections (Current State, What's working, What's NOT working,
  Recommended Lifecycle, PR-at-feature-close Workflow, Roadmap, License, Contributing)
- README Contributing section explicitly defers external PRs during alpha
- `specs/001-specrew-product/spec.md` status line reads `Active 0.14.0`
- markdownlint passes on all modified `.md` files

---

### Iteration 002 — Versioning, Changelog, Tags, Governance Extension

**Scope**: FR-008–FR-010, FR-012–FR-014, FR-016  
**Effort**: ≈8 story points  
**Authorization**: Requires explicit human authorization after Iteration 001 closes

**Deliverables**:

| Deliverable | Path | Requirement |
| --- | --- | --- |
| Version reconciliation | `.specrew/config.yml` (`specrew_version`), `README.md` update | FR-008 |
| Versioning reference | `docs/versioning.md` | FR-014 |
| Retroactive CHANGELOG | `CHANGELOG.md` | FR-009 |
| Git tags | `v0.13.0` @ `21d9e7f`, `v0.14.0` @ `3ff32d4` | FR-010 |
| Closeout governance extension | `extensions/.../coordinator/specrew-governance.md` | FR-012, FR-013 |
| Public-readiness drift check | `extensions/.../scripts/validate-governance.ps1` | FR-016 |

**Acceptance Check for Iteration 002**:
- `.specrew/config.yml` sets `specrew_version: "0.14.0"`
- `docs/versioning.md` explains `0.NN.0` scheme and hotfix `0.NN.M` rule
- `CHANGELOG.md` contains entries for Features 001–014 (each with ordinal + summary)
- `git tag -l "v0.13.0" "v0.14.0"` returns both tags
- `git tag -v v0.13.0` points to `21d9e7f`; `git tag -v v0.14.0` points to `3ff32d4`
- `validate-governance.ps1` exits 0 and emits no public-readiness WARN for a clean repo
- `validate-governance.ps1` emits `WARN [public-readiness] missing-artifact: LICENSE` when
  `LICENSE` is absent (regression test for soft-warning behaviour)
- Coordinator governance document contains a "Feature Closeout Version Management" section

---

## Key File Paths

```text
# Created in Iteration 001
LICENSE
NOTICE.md
README.md                                       (rewritten)
specs/001-specrew-product/spec.md               (status line updated)
specs/015-public-readiness-pass/iterations/001/ (planning scaffold)

# Created in Iteration 002
CHANGELOG.md
docs/versioning.md
.specrew/config.yml                             (specrew_version updated to 0.14.0)
extensions/specrew-speckit/scripts/validate-governance.ps1  (extended)
.specify/extensions/specrew-speckit/scripts/validate-governance.ps1 (mirror extended)
extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md (extended)
.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md (mirror)

# Git tags (created in Iteration 002)
v0.13.0  →  21d9e7f
v0.14.0  →  3ff32d4
```

---

## Developer Workflow Reference

### Iteration 001 Steps (after hardening-gate authorization)

1. Create `LICENSE` at repo root:
   - Standard MIT license text
   - Copyright line: `Copyright (c) 2026 Alon Fliess and contributors`

2. Create `NOTICE.md` at repo root:
   - Section for Squad (MIT upstream, derived `.specify/extensions/specrew-speckit/squad-templates/`)
   - Section for Spec Kit (MIT upstream, derived `.specify/` layer)
   - Include required upstream notice text verbatim or by reference

3. Rewrite `README.md`:
   - Lead with Current State (version 0.14.0, alpha, dogfooding)
   - Add What's working, What's NOT working, Recommended Lifecycle, PR-at-feature-close sections
   - Add Roadmap, License, Contributing at the end
   - Preserve accurate existing sections (reviewer regression governance, session-loaded file detection)

4. Update `specs/001-specrew-product/spec.md`:
   - Change `**Status**: Draft` → `**Status**: Active 0.14.0`
   - Add one-sentence note: "14 implementing features have shipped as of 2026-05-13."

5. Scaffold Iteration 001 planning artifacts:
   ```powershell
   .\.specify\scripts\powershell\scaffold-iteration-plan.ps1 `
     -FeatureDirectory specs\015-public-readiness-pass `
     -IterationNumber 001
   ```

6. Run quality gates:
   ```powershell
   npx markdownlint-cli LICENSE NOTICE.md README.md specs/001-specrew-product/spec.md
   ```

### Iteration 002 Steps (after hardening-gate authorization)

1. Update `.specrew/config.yml` so `specrew_version: "0.14.0"`

2. Create `docs/versioning.md` with full versioning policy

3. Create `CHANGELOG.md` with 14 retroactive entries

4. Create git tags:
   ```sh
   git tag -a v0.13.0 21d9e7f -m "Specrew v0.13.0 — Features 008-013 catch-up merge (PR #79)"
   git tag -a v0.14.0 3ff32d4 -m "Specrew v0.14.0 — Feature 014 handoff-format-scoping (PR #99)"
   git push origin v0.13.0 v0.14.0
   ```

5. Extend `specrew-governance.md` (both `extensions/` and `.specify/extensions/` copies) with
   "Feature Closeout Version Management" rule

6. Add `Test-PublicReadinessSurfaces` function to both copies of `validate-governance.ps1`

7. Run quality gates:
   ```powershell
   Invoke-ScriptAnalyzer -Path extensions\specrew-speckit\scripts\validate-governance.ps1
   pwsh -File extensions\specrew-speckit\scripts\validate-governance.ps1
   npx markdownlint-cli CHANGELOG.md docs/versioning.md README.md
   git tag -l "v0.13.0" "v0.14.0"
   ```

---

## Dependencies and Constraints

- Iteration 002 depends on Iteration 001 completing (README must include version 0.14.0 for the
  staleness check to pass after both iterations close)
- Git tags are idempotent on re-create with the same SHA but will error if the tag already points
  to a different commit — verify no existing v0.13.0 or v0.14.0 before tagging
- Both `extensions/specrew-speckit/` and `.specify/extensions/specrew-speckit/` copies of
  `validate-governance.ps1` and `specrew-governance.md` must be kept in sync

---

## Authorization Boundary Reminder (FR-015)

> Current approval covers: specification, Iteration 001 planning scaffold, upstream-tracking push.
>
> **Not yet authorized**: hardening-gate sign-off, implementation start, public repository
> visibility change.
>
> Explicit human approval is required before beginning implementation of either iteration.
