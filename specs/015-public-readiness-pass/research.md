# Research: Public-Readiness Pass

**Feature**: 015 Public-Readiness Pass  
**Branch**: `015-public-readiness-pass`  
**Phase**: 0 — Research and Clarification Resolution  
**Date**: 2026-05-13  
**Status**: Complete — all NEEDS CLARIFICATION resolved

---

## 1. Contribution Posture During Alpha

**Question**: Should the README Contributing section accept external pull requests during alpha?

**Decision**: Defer external pull requests; explicitly welcome reading, issues, and discussion.

**Rationale**: The operating model has not yet stabilised for multi-developer external contribution.
Silence on this point would read as ambiguity to outside readers. The spec clarification session
(2026-05-13) resolved this explicitly.

**Alternatives Considered**:

- Accept all external PRs → rejected; operating model not ready; would require review/merge
  governance work not in scope.
- Complete silence in README → rejected; creates confusion about whether the project is open.

**Requirement Satisfied**: FR-007 (Contributing section must explicitly state alpha status and
defer external PRs).

---

## 2. Attribution Notice Location

**Question**: Should the attribution notice live at repo root or under `docs/`?

**Decision**: Top-level `NOTICE.md` at repository root.

**Rationale**: Public discoverability matters more than top-level file count. A root-level placement
ensures that any GitHub repository visitor scanning the file list sees it alongside `LICENSE`
without needing to navigate into subdirectories. MIT license compliance requires that the notice
text be distributed alongside the software; root placement satisfies this with zero ambiguity.

**Alternatives Considered**:

- `docs/NOTICE.md` → rejected; less discoverable for first-time visitors unfamiliar with the
  project structure.
- Inline in README → rejected; would make README verbose and harder to scan.

**Requirement Satisfied**: FR-002 (top-level NOTICE.md).

---

## 3. Retroactive Changelog Detail Level

**Question**: How much historical detail must retroactive changelog entries carry?

**Decision**: Each entry must include (required) the feature ordinal and a one-line summary, and
should include (recommended) commit or merge reference when known. PR references are optional
and should be omitted when they add noise without new clarity.

**Rationale**: Retroactive entries for 14 features need to be honest about what is historically
reconstructed. Requiring ordinals + summaries ensures future readers can trace any entry to a
known feature. Commit/merge references improve traceability without mandating extensive archaeology.
PR numbers are generally available from the `git log --oneline --all` history and may be included
where clearly associated.

**Alternatives Considered**:

- Full per-task granularity → rejected; this is retroactive bookkeeping, not a live changelog;
  per-task detail would be speculative and noisy.
- Ordinal-only, no commit refs → rejected; commit refs are available from git history and add
  genuine traceability at low cost.

**Known Commit/Merge References (from `git log --oneline --all`)**:

- Features 001–006: landed in early bootstrap commits before formal PR merge workflow; reference
  point is the branch tips (`001-specrew-product` through `006-stack-aware-quality-bar`).
- Feature 007: `f198702` (feature-closeout commit on branch `007`).
- Feature 008: `c8d2042` (feature-closeout commit on branch `008`).
- Feature 009: branch `009-project-path-resolution` (no single clean merge commit).
- Feature 010: `2afe007` (feature-closeout commit on branch `010`).
- Feature 011: `9f2ec92` (feature-closeout commit on branch `011`).
- Feature 012: `f35f319` (feature-closeout commit on branch `012`).
- Feature 013: `21d9e7f` (Merge PR #79 to main — canonical merge commit).
- Feature 014: `3ff32d4` (Merge PR #99 to main — canonical merge commit).

**Requirement Satisfied**: FR-009.

---

## 4. Retroactive Tag Strategy

**Question**: Should `v0.13.0` be tagged retroactively or should tagging start only at `v0.14.0`?

**Decision**: Tag both milestones.

- `v0.13.0` → commit `21d9e7f` (Merge PR #79 from `alonf/013-validator-hardening` — the
  historical catch-up merge bringing Features 008–013 to main)
- `v0.14.0` → commit `3ff32d4` (Merge PR #99 from `alonf/014-handoff-format-scoping` — the
  current mainline shipped baseline)

**Rationale**: Two observable milestones exist in the public history: the catch-up merge where
Features 008–013 landed together on main (PR #79), and the Feature 014 merge (PR #99). Tagging
both provides unambiguous release anchors without implying anything about earlier individual
features. Creating `v0.13.0` retroactively is pure documentary bookkeeping; git lightweight tags
do not alter history.

**Tag Creation Commands** (to be executed as part of Iteration 002):

```sh
git tag v0.13.0 21d9e7f -m "Specrew v0.13.0 — Features 008-013 catch-up merge (PR #79)"
git tag v0.14.0 3ff32d4 -m "Specrew v0.14.0 — Feature 014 handoff-format-scoping (PR #99)"
git push origin v0.13.0 v0.14.0
```

**Why Not Additional Earlier Tags?** The spec explicitly scopes tagging to these two milestones.
Earlier releases had no formal merge-PR workflow and their precise ship points are less clear from
commit history; tagging them would be speculative.

**Alternatives Considered**:

- Tag only `v0.14.0` → rejected per spec clarification; removes traceability for the 008–013
  catch-up milestone.
- Tag every feature → rejected; spec explicitly scopes to just these two anchor points.

**Requirement Satisfied**: FR-010.

---

## 5. Versioning Schema and Location

**Question**: Where should the versioning schema live, and what is the schema?

**Decision**:

- Brief versioning summary in `README.md` (current version + scheme in one paragraph)
- Full versioning policy at `docs/versioning.md`

**Schema**:

- `0.NN.0` — each shipped feature advances the minor version; NN matches the feature ordinal
- `0.NN.M` — hotfix patch for feature NN shipped state; M starts at 1
- Pre-alpha bootstrap-era value (`0.1.0-dev` in `.specrew/config.yml`) is deprecated and replaced
- Current version: **0.14.0** (14 shipped features)
- Declared version location: `.specrew/config.yml` `specrew_version` + README summary + `docs/versioning.md`
- The stale bootstrap-era declaration in `.specrew/config.yml` must be updated from `0.1.0-dev`
  to `0.14.0` so the canonical version source matches the public documentation surfaces.

**Rationale**: README stays scannable (NFR-001). Readers who need release policy detail can follow
the `docs/versioning.md` link without wading through policy in the README. The 0.NN.0 scheme is
already implicit in the 14-feature history and becomes explicit and documented here.

**Alternatives Considered**:

- Version only in README → rejected; makes README too long (NFR-001).
- Separate `VERSIONING.md` at root → rejected; spec explicitly chose `docs/versioning.md` in
  clarification session.

**Requirement Satisfied**: FR-008, FR-014.

---

## 6. Public-Readiness Drift Rule Frequency

**Question**: Should the new public-readiness drift rule run only at feature closeout or on every
`validate-governance.ps1` invocation?

**Decision**: Run on every `validate-governance.ps1` invocation as an additive soft warning.

**Rationale**: NFR-005 explicitly requires it to remain advisory and low-noise rather than a hard
blocker. Running it on every invocation means drift is surfaced at each lifecycle gate (planning →
execution, execution → review, review → retro) rather than at closeout only, matching SC-007.

**Implementation Design**:

- New function `Test-PublicReadinessSurfaces` in `validate-governance.ps1` (and mirrored to
  `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`)
- Checks for: existence of `LICENSE`, `NOTICE.md`, `CHANGELOG.md`; presence of version line in
  `README.md`; existence of `docs/versioning.md`
- Emits `WARN` prefix lines (not `FAIL`) via `Write-Host ... -ForegroundColor Yellow`
- MUST NOT set `$hasFailures = $true` or call `exit 1`
- Called unconditionally at the top of the main validation function before iteration-level checks

**Alternatives Considered**:

- Hard block if any public-readiness file is missing → rejected; NFR-005 and spec clarification
  explicitly prohibit this.
- Run only at closeout → rejected; SC-007 and the spec clarification session require every
  `validate-governance.ps1` invocation.

**Requirement Satisfied**: FR-016, NFR-005, SC-007.

---

## 7. Closeout Template Extension Validation Strategy

**Question**: Should the closeout-template extension be validated through a synthetic feature
or through the next real feature closeout?

**Decision**: Validate through the next real feature closeout (Feature 016+), with helper-level
regression coverage where needed.

**Rationale**: A synthetic feature would be an artificial ceremony that adds noise without genuine
proof that the closeout guidance works in a real workflow. The next real feature closeout
provides authentic proof. Helper-level Pester tests can cover the validate-governance.ps1
extension independently without needing a full synthetic feature.

**Implications for This Feature**:

- The closeout governance extension is delivered in Iteration 002 of this feature.
- Validation evidence is recorded as "pending — to be proven at next real feature closeout".
- The `validate-governance.ps1` soft-warning function is independently testable and provides
  immediate proof of that specific acceptance criterion.

**Requirement Satisfied**: FR-012, FR-013, SC-005.

---

## 8. README Sections Required

**Decision**: The rewritten README must include all of the following sections (FR-003–FR-007):

| Section | Requirement | Key Content |
| --- | --- | --- |
| Current State | FR-003 | Version 0.14.0, alpha dogfooding framing, multi-dev/multi-host not ready |
| What's working | FR-004 | Shipped capabilities through Feature 014 in plain language |
| What's NOT working yet | FR-005 | Multi-developer reconciliation, multi-host runtime, brownfield cartography, installable packaging |
| Recommended Lifecycle | FR-006 | Delivery phases and planning gates |
| PR-at-feature-close Workflow | FR-006 | Merge-at-close operating model |
| Roadmap | FR-007 | Future direction |
| License | FR-007 | MIT license reference |
| Contributing | FR-007 | Alpha status, welcomes reading/issues/discussion, defers external PRs |

The existing README (as of 2026-05-13) contains "What Specrew does" and "Recommended flow" sections
but lacks Current State, What's NOT working, explicit versioning, License, and Contributing sections.
It also lacks the PR-at-feature-close section. The rewrite should preserve the detailed reviewer
regression and session-loaded-file sections (which are accurate and useful) while reorganising
to lead with public-readiness sections first.

**Requirement Satisfied**: FR-003–FR-007.

---

## 9. LICENSE Copyright Line

**Decision**: `Copyright (c) 2026 Alon Fliess and contributors`

**Rationale**: This matches FR-001 exactly. "Contributors" is standard MIT practice for open
projects. The year reflects first public-readiness pass rather than the initial private bootstrapping
date.

**Requirement Satisfied**: FR-001.

---

## 10. NOTICE.md Attribution Scope

**Decision**: NOTICE.md must identify:

1. **Squad** as an MIT-licensed upstream source — credit the Squad project and its authors
2. **Spec Kit** as an MIT-licensed upstream source — credit the Spec Kit project and its authors
3. **Which Specrew directories** contain templates or scripts derived from each upstream

**Directories identified for attribution** (from repo structure review):

- `.specify/` — Spec Kit extension layer templates, scripts, and workflows
- `.specify/extensions/specrew-speckit/squad-templates/` — Squad-derived ceremony/directive/agent
  templates adapted for Specrew
- Extensions in `extensions/specrew-speckit/` mirror and extend the `.specify/` layer

The NOTICE.md should follow the pattern: state the upstream project name and license, include
required notice text (or refer readers to the upstream repo for full notice), and identify the
derived Specrew directories.

**Requirement Satisfied**: FR-002.

---

## 11. Feature Ordinal Map (for CHANGELOG)

The following 14 shipped features are confirmed from `git log --oneline --all` and the `specs/`
directory structure:

| Ordinal | Directory | Summary |
| --- | --- | --- |
| 001 | `001-specrew-product` | Specrew product vision, architecture, and bootstrap scaffolding |
| 002 | `002-planning-flow-hardening` | Planning flow hardening and governance gates |
| 003 | `003-post-planning-review` | Post-planning review ceremony |
| 004 | `004-default-specialty-pairing` | Default specialty-pairing model |
| 005 | `005-stack-aware-quality-bar` | Stack-aware quality bar and quality profile foundation |
| 006 | `006-human-architecture-checkpoint` | Human architecture checkpoint ceremony |
| 007 | `007-user-facing-progress-handoff` | User-facing progress handoff and soft validator |
| 008 | `008-reviewer-escalation-symmetry` | Reviewer escalation symmetry and regression routing |
| 009 | `009-project-path-resolution` | Project path resolution audit and regression coverage |
| 010 | `010-onboarding-resume-visibility` | Onboarding resume-mode visibility |
| 011 | `011-specrew-start-conditional-pause` | Specrew start conditional pause and post-restart directives |
| 012 | `012-descriptive-id-handoffs` | Descriptive reference IDs in handoffs |
| 013 | `013-validator-hardening` | Validator hardening: canonical schema, structured failures, approval-reuse detection |
| 014 | `014-handoff-format-scoping` | Handoff format scoping: bounded stop-vs-progress selector |

**Requirement Satisfied**: FR-009 (changelog requires all 14 entries).

---

## Summary: All Clarifications Resolved

| # | Question | Status |
| --- | --- | --- |
| 1 | Contributing posture during alpha | ✅ Resolved — defer external PRs |
| 2 | Attribution notice location | ✅ Resolved — top-level NOTICE.md |
| 3 | Changelog detail level | ✅ Resolved — ordinal + summary + commit refs when known |
| 4 | Tag strategy | ✅ Resolved — v0.13.0 (21d9e7f) + v0.14.0 (3ff32d4) |
| 5 | Versioning schema and location | ✅ Resolved — README summary + docs/versioning.md |
| 6 | Drift rule frequency | ✅ Resolved — every validate-governance.ps1 invocation |
| 7 | Closeout template validation | ✅ Resolved — next real feature closeout |
| 8 | README sections required | ✅ Resolved — 8 sections enumerated |
| 9 | LICENSE copyright line | ✅ Resolved — "Copyright (c) 2026 Alon Fliess and contributors" |
| 10 | NOTICE.md attribution scope | ✅ Resolved — Squad + Spec Kit; .specify/ and extensions/ dirs |
| 11 | Feature ordinal map | ✅ Resolved — 14 features confirmed from git + specs/ |

No NEEDS CLARIFICATION items remain. Planning may proceed without a further clarification round
(SC-006 satisfied).
