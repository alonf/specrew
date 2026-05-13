# Feature Specification: Public-Readiness Pass

**Feature Branch**: `015-public-readiness-pass`  
**Created**: 2026-05-13  
**Status**: Complete  
**Input**: User description: "Open Feature 015 Public-Readiness Pass from `C:\Temp\public-readiness-pass.md`, keep it grounded in the source draft, create `specs/015-public-readiness-pass/spec.md`, and stop at normal specify-phase outputs without beginning hardening-gate sign-off or implementation authorization."

## Problem Statement

Specrew is approaching a public-open milestone, but key public-readiness surfaces still misrepresent the project's actual state. A first-time visitor cannot yet rely on the repository to understand whether the project is legally reusable, what version they are looking at, what has already shipped, what remains intentionally unfinished, or how future feature closeout work updates public-facing release information.

These gaps are coupled. Licensing, attribution, README accuracy, release versioning, changelog history, product-spec status, and future closeout discipline all need to align before the repository can credibly present itself as an openly reusable alpha product.

## Scope Boundaries

### In Scope

- Establishing explicit repository licensing and upstream attribution for public consumption.
- Rewriting public-facing documentation so first-time observers can quickly understand current state, working capability, known limitations, roadmap direction, release lifecycle, contribution posture, and licensing.
- Reconciling the declared Specrew version with the 14 already shipped features and documenting the alpha versioning scheme going forward.
- Creating a retroactive changelog and release-tag baseline that matches the current shipped state.
- Updating the product spec and future feature-closeout guidance so version-management work becomes part of normal closeout behavior.

### Out of Scope

- Approving or performing the repository visibility change from private to public.
- Beginning work beyond the bounded Iteration 001 slice (previously); Iteration 002 is now explicitly authorized on 2026-05-13 via user directive for the specific scope listed below.
- Packaging Specrew as an installable CLI, documenting multi-host support, or creating a polished public demo repository.
- Launch marketing, announcements, blog posts, conference collateral, or other external promotion work.
- Broad CI/CD redesign unrelated to public-readiness documentation and release bookkeeping.

## Relationship to Existing Features

- **Feature 013 — validator hardening** established the governance discipline that this feature now extends into public-readiness and release hygiene.
- **Feature 014 — handoff-format scoping** is the most recent shipped feature and is part of the "14 shipped features" state this feature must reconcile across README, versioning, and product status surfaces.
- **The product spec (`001-specrew-product`)** remains the canonical product vision artifact and now needs its status updated to reflect that the product is actively shipping through version 0.14.0.

## Clarifications

### Session 2026-05-13

- Q: Should the README Contributing section accept external pull requests during alpha? → A: No. During alpha Specrew should welcome reading, issues, and discussion, but explicitly defer external pull requests until the operating model stabilizes.
- Q: Should the attribution notice live at repo root or under `docs/`? → A: Use a top-level `NOTICE.md` at the repository root so it is discoverable alongside `LICENSE`.
- Q: How much historical detail must retroactive changelog entries carry? → A: Each entry must include the feature ordinal and a one-line summary, and should include commit or merge references when known; PR references are optional rather than required.
- Q: Should `v0.13.0` be tagged retroactively or should tagging start only at `v0.14.0`? → A: Tag both milestones, with `v0.13.0` created retroactively at the historical catch-up merge and `v0.14.0` at the current shipped baseline.
- Q: Where should the versioning schema live? → A: Keep a concise versioning summary in `README.md` and the detailed policy in `docs/versioning.md`.
- Q: Should the new public-readiness drift rule run only at feature closeout or on every governance validation? → A: Run it on every `validate-governance.ps1` invocation as an additive soft warning so drift is surfaced at each lifecycle gate.
- Q: Should the closeout-template extension be validated through a synthetic feature or through the next real feature closeout? → A: Validate it through the next real feature closeout, with helper-level regression coverage where needed, rather than inventing a synthetic end-to-end feature.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Understand the repo at a glance (Priority: P1)

A first-time public observer can land on the repository and quickly understand what Specrew is, what state it is in, what already works, what is intentionally not ready yet, and whether they may legally reuse it.

**Why this priority**: Public-open is blocked unless an outside reader can interpret the repository accurately and confidently from the top-level public surfaces.

**Independent Test**: Give a fresh-context reviewer only the repository landing files and confirm they can summarize the product, its alpha status, its version, and its license without needing insider explanation.

**Acceptance Scenarios**:

1. **Given** a first-time observer opens the repository, **When** they read the rewritten README, **Then** they can identify the current version, alpha framing, shipped strengths, known gaps, lifecycle model, roadmap direction, and contribution posture.
2. **Given** a first-time observer wants to know whether the repository is legally reusable, **When** they inspect the top-level licensing files, **Then** they find a standard MIT license plus clear upstream attribution for copied or derived materials.
3. **Given** a first-time observer compares the README and the repository's actual shipped history, **When** they review the public-readiness surfaces, **Then** Features 001 through 014 are reflected accurately enough that the repository no longer presents stale project state.

---

### User Story 2 - Reconcile release truth across repo artifacts (Priority: P1)

A maintainer can look at the declared version, changelog, historical tags, and product-spec status and see one coherent story of what has shipped so far and what version line the project is now on.

**Why this priority**: Public-readiness fails if the repo's official version, release history, and product status disagree with one another.

**Independent Test**: Review the version declaration, changelog, tags, and product-spec status together and confirm they consistently represent the 14-feature shipped baseline and the intended alpha versioning scheme.

**Acceptance Scenarios**:

1. **Given** Specrew has 14 shipped features before Feature 015 closes, **When** a maintainer reviews the declared version and release documentation, **Then** the repository presents itself as version 0.14.0 and documents how future alpha versions advance.
2. **Given** a maintainer wants historical release anchors, **When** they inspect the release history, **Then** they can trace a retroactive 0.13.0 point and the current 0.14.0 point without ambiguity about which shipped state each represents.
3. **Given** a maintainer reads the product specification status, **When** they compare it to the shipped feature history, **Then** the product spec no longer appears stuck in draft form.

---

### User Story 3 - Close future features with release discipline (Priority: P2)

A future feature owner can complete closeout work with explicit version-management steps already embedded in the normal closeout guidance, so release bookkeeping no longer depends on ad hoc human reminders.

**Why this priority**: Public-readiness is not durable unless the release/version tasks become part of the default closeout workflow for future features.

**Independent Test**: Review the closeout template and governance guidance and confirm they require the next real feature closeout to update version, changelog, and release tag artifacts as part of normal closure.

**Acceptance Scenarios**:

1. **Given** a future feature reaches closeout, **When** Squad and the human reviewer follow the updated closeout guidance, **Then** version bump, changelog update, and release tagging are treated as standard closeout steps rather than optional reminders.
2. **Given** a planner prepares the next feature after this one, **When** they read the coordination and governance guidance, **Then** they can see that public-facing release artifacts must stay synchronized at feature close.

---

### Edge Cases

- A repository can have a correct license but still fail public-readiness if upstream attribution is missing or unclear; both must be discoverable together.
- Historical release tagging must preserve the correct older ship point without implying that current HEAD moved or that later work belongs to the earlier release.
- README improvements must stay concise enough for quick scanning even while adding missing lifecycle, roadmap, licensing, and contribution sections.
- The contribution posture must be explicit even if the choice is to defer external pull requests during alpha; silence would read as ambiguity to outsiders.
- Future closeout guidance must stay durable even if one release artifact is temporarily missing; the workflow should make the missing element visible rather than silently accepting drift.
- Repo-wide public-readiness drift checks should surface early at routine governance gates as soft warnings, not wait until feature closeout to reveal missing or stale public-facing artifacts.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The repository MUST provide a top-level `LICENSE` file containing the standard MIT license text with the copyright line `Copyright (c) 2026 Alon Fliess and contributors`. **Owner role**: Repository steward. **Delivery window**: Iteration 1.
- **FR-002**: The repository MUST provide a top-level `NOTICE.md` that credits Squad and Spec Kit as MIT-licensed upstream sources, preserves their required notice information, and clearly identifies the Specrew directories whose templates or scripts are derived from those upstream projects. **Owner role**: Repository steward. **Delivery window**: Iteration 1.
- **FR-003**: `README.md` MUST include a **Current State** section that states the repository is at version 0.14.0, frames Specrew as an alpha validated through dogfooding, and clearly states that multi-developer and multi-host support are not yet ready. **Owner role**: Documentation steward. **Delivery window**: Iteration 1.
- **FR-004**: `README.md` MUST include a **What's working** section that summarizes the shipped Specrew capabilities through Feature 014 in plain language for an outside reader. **Owner role**: Documentation steward. **Delivery window**: Iteration 1.
- **FR-005**: `README.md` MUST include a **What's NOT working yet** section that explicitly names the current roadmap deferrals, including multi-developer reconciliation, multi-host runtime, just-in-time brownfield cartography, and installable packaging. **Owner role**: Documentation steward. **Delivery window**: Iteration 1.
- **FR-006**: `README.md` MUST include both a **Recommended Lifecycle** section and a **PR-at-feature-close Workflow** section so an outside reader understands Specrew's current delivery phases, planning gates, and merge-at-close operating model. **Owner role**: Documentation steward. **Delivery window**: Iteration 1.
- **FR-007**: `README.md` MUST include **Roadmap**, **License**, and **Contributing** sections. The Contributing section MUST explicitly state that Specrew is still alpha-stage, welcomes reading, issues, and discussion, and is not yet accepting external pull requests until the operating model stabilizes. **Owner role**: Documentation steward. **Delivery window**: Iteration 1.
- **FR-008**: The declared Specrew version in `.specrew/config.yml` MUST be reconciled from the stale bootstrap-era value (`specrew_version: "0.1.0-dev"`) to `0.14.0`, and the alpha versioning scheme MUST be documented as `0.NN.0` per shipped feature with `0.NN.M` reserved for hotfixes. `.specrew/config.yml` serves as the authoritative source-of-truth for the active product version. **Owner role**: Release steward. **Delivery window**: Iteration 2.
- **FR-009**: The repository MUST provide a top-level `CHANGELOG.md` with retroactive entries for Features 001 through 014. Each entry MUST identify the feature ordinal and a one-line summary, SHOULD include historical commit or merge references when known, and does not need PR references when those would add noise without new clarity. **Owner role**: Release steward. **Delivery window**: Iteration 2.
- **FR-010**: The repository's release history MUST include `v0.13.0` retroactively anchored to the historical ship point for the Features 008-013 catch-up merge and `v0.14.0` anchored to the current mainline ship point, so maintainers and observers can identify both release milestones. **Owner role**: Release steward. **Delivery window**: Iteration 2.
- **FR-011**: `specs/001-specrew-product/spec.md` MUST update its status from draft to `Active 0.14.0` and briefly explain that the product vision is now backed by 14 shipped implementing features. **Owner role**: Product spec steward. **Delivery window**: Iteration 1.
- **FR-012**: The feature-closeout guidance MUST be extended so future closeouts explicitly include the next version bump, changelog update, and release-tag creation as standard closure work. **Owner role**: Governance steward. **Delivery window**: Iteration 2.
- **FR-013**: The coordinator and governance guidance MUST instruct Squad to perform the release-version management steps during future feature closeout without needing case-by-case human reminders. **Owner role**: Governance steward. **Delivery window**: Iteration 2.
- **FR-014**: A human-readable versioning reference MUST exist for future readers, combining a brief README summary with a dedicated detailed reference at `docs/versioning.md` so the release policy is easy to find without overloading the README. **Owner role**: Documentation steward. **Delivery window**: Iteration 2.
- **FR-015**: Planning and downstream execution artifacts for this feature MUST preserve the current authorization boundary: this feature is approved only through specification, Iteration 001 planning scaffold, and upstream-tracking push; hardening-gate sign-off and implementation start require later explicit human approval. **Owner role**: Planner and human reviewer. **Delivery window**: Iteration 1 planning boundary.
- **FR-016**: `validate-governance.ps1` MUST check the public-readiness surfaces (`README.md`, `LICENSE`, `NOTICE.md`, `CHANGELOG.md`, and the versioning reference) on every invocation and emit additive soft warnings when those artifacts are missing or materially stale, rather than waiting until feature closeout to surface the drift. **Owner role**: Governance steward. **Delivery window**: Iteration 2.
- **FR-017**: Four previously shipped and delivered feature specifications (`specs/007-user-facing-progress-handoff/spec.md`, `specs/009-project-path-resolution/spec.md`, `specs/011-specrew-start-conditional-pause/spec.md`, and `specs/012-descriptive-id-handoffs/spec.md`) MUST have their status field updated from the stale `Draft` label to the canonical shipped-spec status label `Complete` to accurately reflect their delivered and implemented state. **Owner role**: Spec steward. **Delivery window**: Iteration 2. **Canon choice**: Status label `Complete` aligns with spec 013 (validator hardening) as the standard label for shipped and fully delivered features.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: User Story 1 maps to FR-001 through FR-007 and FR-011.
- **TG-002**: User Story 2 maps to FR-008 through FR-011, FR-014, FR-016, and FR-017 (stale status reconciliation).
- **TG-003**: User Story 3 maps to FR-012 through FR-016.
- **TG-004**: Planning and execution artifacts MUST preserve the source-draft intent that public-open readiness is the goal, but repository visibility change, hardening-gate approval, and implementation authorization remain outside this specification's current approval scope.
- **TG-005**: Iteration 002 is explicitly authorized on 2026-05-13 for the scope items: version bump (FR-008), changelog (FR-009), release tags (FR-010), closeout governance (FR-012, FR-013), versioning schema (FR-014), public-readiness drift check (FR-016), and stale shipped-feature spec status reconciliation (FR-017). These items are deferred from Iteration 1 and require separate authorization before implementation begins.

### Key Entities *(include if feature involves data)*

- **Public-Readiness Surface**: The set of top-level repository artifacts that shape first impressions for outside readers, including README, LICENSE, NOTICE, CHANGELOG, and the declared product/version status.
- **Licensing Notice Record**: The attribution document that preserves MIT notice obligations for upstream-derived Specrew materials.
- **Release Version Record**: The combined truth surface formed by the declared current version, changelog history, and release tags.
- **Product Status Record**: The status declaration in the product specification that tells readers whether the product vision is still draft or actively shipping.
- **Closeout Versioning Checklist**: The future-facing governance steps that ensure version bumping, changelog updates, and release tagging happen during every feature closeout.
- **Public-Readiness Drift Warning**: The validator-emitted soft-warning signal that flags missing or stale public-facing release artifacts during routine governance validation.

## Non-Functional Constraints

- **NFR-001**: The README rewrite must remain concise enough for a first-time reader to scan quickly; detailed policy and release explanation should move into dedicated docs rather than turning the README into a long-form manual.
- **NFR-002**: Public-facing documentation must be written for a non-technical observer first, even when it references Specrew's internal lifecycle and governance model.
- **NFR-003**: Public-readiness changes must be additive and must not alter unrelated runtime behavior.
- **NFR-004**: The versioning reference must remain readable and durable enough that future maintainers can follow it without tribal knowledge.
- **NFR-005**: Public-readiness drift detection must remain advisory and low-noise: it should surface on every governance validation as a soft warning, but it must not become a hard blocker by itself.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In a quick-read check with 2-3 fresh-context reviewers, at least 2 reviewers can explain within 30 seconds what Specrew is, what version they are looking at, and that it is still an alpha product.
- **SC-002**: A first-time observer can determine within 60 seconds that the repository is MIT-licensed and can locate the upstream attribution notice without needing guidance from a maintainer.
- **SC-003**: The repository's declared current version, changelog headline, product-spec status, and latest release tag all align to the same 0.14.0 shipped baseline before Feature 015 implementation closes.
- **SC-004**: A maintainer can identify from the documented release history where the earlier 0.13.0 shipped state ended and where the 0.14.0 shipped state begins without ambiguity.
- **SC-005**: The next real feature closeout after this feature includes the documented version bump, changelog update, and release-tag steps without requiring a fresh manual reminder or a synthetic end-to-end proving feature.
- **SC-006**: No additional clarification round is required before planning begins because the public-readiness scope, release-policy choices, and approval boundary are all explicit in the specification.
- **SC-007**: A `validate-governance.ps1` run at any normal lifecycle gate surfaces missing or stale public-readiness artifacts as soft warnings rather than discovering the drift only at final closeout.

## Assumptions

- The public-readiness feature uses `NOTICE.md` at the repository root rather than hiding attribution under `docs/`, because public discoverability matters more than top-level file count.
- During alpha, the repository explicitly welcomes reading, issues, and discussion, while external pull requests remain deferred until the operating model stabilizes.
- The versioning policy appears both as a concise README summary and as a fuller `docs/versioning.md` reference so the README stays scannable without burying release discipline.
- Retroactive changelog entries require a feature ordinal plus one-line summary, while commit or merge references are included when known and PR references remain optional.
- Historical release tagging is documentary bookkeeping and does not authorize or imply any additional implementation work for this feature.
- Public-readiness drift warnings run on every `validate-governance.ps1` invocation as additive soft warnings.
- The closeout-template extension is validated on the next real feature closeout rather than through a synthetic end-to-end feature created only for proof.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Alon Fliess as requesting human, with Squad preserving fidelity to the source draft.
- **Iteration Facilitator**: Specrew planner/coordinator pairing responsible for preserving the two-iteration split: Iteration 001 = `T001-T009` (completed 2026-05-13), Iteration 002 = `T010-T024` (now explicitly authorized 2026-05-13 for the scope items listed in TG-005).
- **Capacity Model**: Two planned iterations totaling roughly 18 story points from the source draft baseline, with Iteration 1 focused on licensing, README, and product-status reconciliation (completed), and Iteration 2 focused on versioning, changelog, tags, closeout-governance extension, and stale shipped-feature spec status reconciliation (now authorized).
- **Drift Signals**: Any mismatch among README public state, top-level licensing/notice files, declared version, changelog, release tags, product-spec status, shipped-feature spec status labels, or future closeout guidance indicates drift from this specification.
- **Human Oversight Points**: Explicit human approval recorded on 2026-05-13 authorized `T001-T009` for Iteration 001 and `T010-T024` for Iteration 002. Public-repo visibility change and any new scope or lifecycle artifacts beyond this bounded two-iteration slice still require later human authorization.
