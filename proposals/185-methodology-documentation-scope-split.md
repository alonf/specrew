---
proposal: 185
title: Methodology Documentation Scope Split and Reading Order
status: candidate
phase: phase-2
estimated-sp: 6-10
priority-tier: 1
discussion: surfaced 2026-06-12 while reviewing docs/methodology during Feature 182. The maintainer observed that the methodology documents mix downstream-project guidance, Specrew's own repository/release rules, and Specrew dogfood incident history without a clear reading order or scope boundary.
---

# Methodology Documentation Scope Split and Reading Order

## Why

The current `docs/methodology/` folder contains valuable guidance, but it blends
three different scopes:

1. **Downstream Specrew methodology** - rules any project governed by Specrew
   should understand and can adopt.
2. **Specrew self-governance** - rules specific to building and publishing the
   Specrew PowerShell module from this repository.
3. **Dogfood provenance** - empirical incidents from Specrew's own development
   that explain why a rule exists.

The mix makes the documents harder to use for downstream projects. A downstream
maintainer reading lifecycle guidance can encounter `PSGallery`, `Specrew.psd1`,
FileList, proposal-index maintenance, this repository's `main` branch, and
Specrew-specific beta/stable release steps. Those are real rules for Specrew
itself, but they are not universal methodology rules.

The issue is not that Specrew-specific history exists. It is useful evidence.
The issue is that the documents do not consistently label whether a rule is:

- normative for every Specrew-governed project;
- normative only for the Specrew repository;
- an example/history item that motivates a rule.

Feature 182 makes this sharper because work kinds and branch governance are
intended for downstream repositories. The documentation surface should teach the
general model first, then show Specrew's own dogfood implementation as one
instance of that model.

## What

Reorganize and rewrite the methodology documentation so the scope and reading
order are explicit.

### Pillar 1 - Scope taxonomy for methodology docs

Define three documentation layers and use them consistently:

| Layer | Purpose | Example content |
| --- | --- | --- |
| Core downstream methodology | Rules and concepts that any Specrew-governed project can use | lifecycle boundaries, traceability, drift, review standards, work kinds, branch governance, design workshop |
| Specrew self-governance | Rules for this repository while building and publishing Specrew | PSGallery, `Specrew.psd1`, FileList, version pins, proposal index, this repo's branch policy, beta/stable release discipline |
| Empirical provenance | Dogfood incidents and examples that justify methodology rules | Shape Catalog, F-049/F-177/F-182 examples, historical release failures |

Each methodology document should state its layer at the top, or the section
should be moved to the document that owns that layer.

### Pillar 2 - Correct reading order by audience

Rewrite the methodology README into a clear reading map:

- **Downstream project maintainer**: start with core lifecycle, work kinds,
  branch governance, review expectations, and design workshop.
- **Downstream contributor / Crew agent**: read the core methodology plus the
  project's local `.specrew/` governance files.
- **Specrew repository contributor**: read the core methodology, then the
  Specrew self-governance document.
- **Specrew release reviewer**: read the Specrew self-governance release
  section in addition to core review guidance.
- **Methodology maintainer**: read empirical provenance when changing rules or
  adding new review failure patterns.

The first path should not require a downstream user to mentally filter out
Specrew's PSGallery or proposal-index rules.

### Pillar 3 - Split Specrew-specific release and repository rules

Move Specrew-only rules out of the core lifecycle contract into a dedicated
Specrew self-governance document. This includes:

- `alonf/specrew` repository conventions;
- `main` protection and merge strategy for Specrew itself;
- PSGallery beta/stable release steps;
- `Specrew.psd1` FileList and module packaging checks;
- version-pin surfaces specific to this repository;
- proposal-index maintenance rules if they remain Specrew-roadmap-specific.

The core lifecycle document should keep the general concept:

```text
Feature closeout happens before merge.
Post-merge release validation belongs to a separate validation record.
Post-merge findings create a new work item.
```

It should not present PSGallery or Specrew module packaging as universal
downstream requirements.

### Pillar 4 - Separate dogfood evidence from normative rules

Keep the empirical incident history, but make its role explicit:

- normative rule first;
- "why this exists" provenance second;
- worked examples labeled as examples, not universal process.

The Shape Catalog can remain in methodology, but it should be either:

- a dedicated `empirical-provenance.md` / `dogfood-provenance.md`; or
- a clearly marked appendix referenced from core review guidance.

Specrew dogfood examples should use neutral downstream examples first where
possible, then a Specrew-specific example as an optional sidebar.

### Pillar 5 - Rewrite, do not only move files

This is not just a file shuffle. The implementation should rewrite headings and
transition text so readers know:

- what applies to their downstream project;
- what applies only when contributing to Specrew itself;
- what is historical evidence;
- which document to read next.

Links and cross-references must be updated so no document sends a downstream
reader into Specrew-only release instructions unless that is the intended path.

## Functional requirements

- **FR-001**: The methodology documentation MUST define a visible scope taxonomy:
  core downstream methodology, Specrew self-governance, and empirical/dogfood
  provenance.
- **FR-002**: `docs/methodology/README.md` MUST provide an explicit reading order
  for downstream maintainers, downstream contributors/Crew agents, Specrew
  contributors, Specrew release reviewers, and methodology maintainers.
- **FR-003**: General lifecycle guidance MUST separate universal lifecycle
  invariants from Specrew-specific PSGallery/module-release rules.
- **FR-004**: Specrew repository conventions MUST be grouped under a
  Specrew-self-governance surface, not embedded as if every downstream project
  should follow them.
- **FR-005**: Proposal discipline MUST be labeled as Specrew roadmap governance
  unless or until a downstream proposal-system model is explicitly designed.
- **FR-006**: Review guidance MUST distinguish downstream review rules from
  Specrew dogfood evidence and Specrew release-review additions.
- **FR-007**: Dogfood incidents and Shape Catalog evidence MUST be preserved, but
  labeled as empirical provenance rather than primary downstream instructions.
- **FR-008**: Work-kind and branch-governance docs MUST lead with provider-neutral
  downstream concepts, with Specrew's own repository posture shown as an
  example, not the default for every project.
- **FR-009**: All moved or split documents MUST preserve link integrity and pass
  markdownlint.
- **FR-010**: The rewrite MUST avoid changing runtime behavior, validators,
  release workflows, or proposal semantics beyond documentation scope unless a
  separate feature explicitly authorizes that work.

## Out of scope

- Changing Specrew runtime behavior.
- Changing CI validators or work-kind enforcement.
- Changing branch protection settings.
- Shipping a methodology website.
- Designing a full downstream proposal-management feature.
- Rewriting historical proposal bodies.

## Effort

- **Iteration 1 (~3-4 SP)**: Inventory and target structure. Classify every
  current methodology section by layer; propose the new document map; decide
  filenames and reading paths.
- **Iteration 2 (~3-5 SP)**: Rewrite and split docs. Update README reading order,
  move Specrew-specific release/repo rules, label provenance, update links, and
  run markdown/link checks.
- **Total**: ~6-10 SP

## Phase placement

Phase 2. This is methodology clarity and downstream-readiness work. It composes
with the work-kind and branch-governance model from Proposal 182 and should land
before the methodology docs are used as the primary public/downstream guidance.

## Open questions

1. Should the new Specrew-only surface live under `docs/methodology/` or under a
   separate `docs/maintainers/` / `docs/specrew-maintainers/` directory?
2. Should empirical provenance be one appendix file or remain near the rules it
   motivates with explicit "Provenance" callouts?
3. Should proposal-discipline stay in `docs/methodology/` as Specrew roadmap
   governance, or move under Specrew self-governance?
4. Should this feature also add a small docs-link check, or should link
   validation remain manual/markdownlint-only for the first slice?

## Risks

- **Risk: over-splitting makes docs harder to follow**. Mitigation: keep the
  README reading paths as the primary navigation surface and avoid tiny files.
- **Risk: losing empirical context while making docs cleaner**. Mitigation:
  preserve dogfood incidents in a clearly labeled provenance surface.
- **Risk: downstream docs become too generic and lose Specrew's practical edge**.
  Mitigation: use neutral examples first, then Specrew dogfood examples as
  explicit examples.

## Cross-references

- Related proposals: [182](182-work-kind-branch-governance.md),
  [140](140-reviewer-instruction-surface.md),
  [162](162-two-tier-product-then-feature-workshop.md),
  [179](179-workshop-pairing-orientation.md)
- Source artifacts:
  [docs/methodology/README.md](../docs/methodology/README.md),
  [docs/methodology/lifecycle-discipline.md](../docs/methodology/lifecycle-discipline.md),
  [docs/methodology/review-instructions.md](../docs/methodology/review-instructions.md),
  [docs/methodology/proposal-discipline.md](../docs/methodology/proposal-discipline.md),
  [docs/methodology/design-workshop-methodology.md](../docs/methodology/design-workshop-methodology.md)
- Composability with: Feature 182 runtime work-kind validator and downstream
  branch-governance guidance.

## Status history

- 2026-06-12: Created as candidate after maintainer review of
  `docs/methodology/` found mixed downstream, Specrew-self, and dogfood-history
  guidance without explicit scope labels or reading order.
