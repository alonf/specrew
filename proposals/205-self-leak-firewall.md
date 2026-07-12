---
proposal: 205
title: Self-Leak Firewall - Prevent and Detect Specrew-Self Context in Consumer Surfaces
status: candidate
phase: phase-2
priority-tier: 1
discussion: maintainer question during the 2026-07-09 beta-1 E2E, after the third observed instance of the class - "From time to time I found this kind of Specrew requirements and constraints leaking to downstream projects. Is there a way to (1) prevent it (2) detect it and then prevent it?"
---

# Self-Leak Firewall - Prevent and Detect Specrew-Self Context in Consumer Surfaces

## Why

Everything Specrew deploys to consumers is authored inside the self-hosted Specrew repo, by
contributors and agents marinated in Specrew's OWN lifecycle. Without a firewall, self-facts
fossilize into methodology and ship as if universal. Three observed instances of the class, each
found by field accident rather than by any gate:

1. **Release-model leak** (204-W7): the first consumer feature-closeout taught Specrew's own
   `push -> PR -> beta tag -> publish -> stable promotion` SDLC — and "beta-before-stable is
   universal" — inside a repo with no git remote, no forge, and no publish target.
2. **Identity conflation**: a downstream agent asserted "This project is
   specrew-197-continuous-co-review" about a consumer project, after dev-tree naming reached its
   session context through machinery surfaces.
3. **Self-host CI in every consumer** (Proposal 204's origin): F-019-era workflows with dev-repo
   paths and `001-specrew-product` triggers deployed by `specrew init` since F-031, deterministically
   broken downstream, invisible for months.
4. **Technology/delivery assumption leak** (F-198/T018 design review, 2026-07-13): a proposed
   downstream evidence wrapper treated Pester `-PassThru` as the universal test contract. The same
   audit found unconditional Windows/PowerShell implementation teaching and "software feature
   produces a release" language in consumer-deployed lifecycle surfaces. These statements did not
   identify Specrew by name, so the original self-fact deny-list could miss them while still exporting
   Specrew's implementation stack and delivery model as methodology.

The leak happens at three times, and each needs its own defense: **author time** (templates, skills,
refocus content, prompt-string literals written with self-context), **deploy time** (self-host files
included in the deploy surface), and **runtime** (prompt builders interpolating self-conventions;
agents conflating which project is under governance).

## What

- **W1 — Deny-list hygiene lint over the deployed surface (prevention, author time)**: a CI lane in
  the Specrew repo scans exactly what ships to consumers — the deploy manifest's allowlist
  (`templates/**`, `squad-templates/**`, deployed skills and refocus content) plus the string
  literals of deployed scripts — for self-facts: `PSGallery`, `beta-before-stable`, `alonf/specrew`,
  dev-repo paths (`specrew-197-*`, `C:\Dev\specrew*`), self feature/iteration identifiers
  (`F-19[0-9]`, `iteration-010`), `proposals/NNN` as consumer instruction, `.squad/decisions.md` as
  consumer instruction, and maintainer identifiers. Deny-listed term without an adjacent
  `specrew-self-ok: <reason>` annotation = red build. The list targets self-FACTS, not the product
  name — Specrew naming its own commands is fine.
- **W2 — Parameterization rule (prevention, author time)**: deployed teaching states the abstract
  rule plus a RESOLUTION POINT filled from project governance/config at render time — never
  Specrew's own instantiation as the example-that-reads-as-mandate. 204-W7's release-model resolver
  is the first instance; W1 enforces the rule mechanically by denying the concrete self-terms.
- **W3 — Deny-by-default deploy manifest (prevention, deploy time)**: extends 204-W3's deploy-list
  surgery — nothing ships unless allowlisted, and W1 lints exactly the allowlist, so the scanned
  surface and the shipped surface cannot drift apart.
- **W4 — Runtime prompt-builder fixture test (prevention, runtime)**: render every built prompt
  surface (reviewer round teachings, navigator inject notes, boundary-packet scaffolds) against a
  fixture project named anything-but-Specrew; assert zero deny-list hits. Catches interpolation
  leaks — the identity-conflation class — that static lint of literals cannot see.
- **W5 — Downstream detect-then-heal (detection)**: the SAME deny-list runs consumer-side:
  (a) as an advisory check in the 204 methodology-gateway lane; (b) in `specrew update`'s
  obsolete-file/heal surface (F-116 pattern) so already-shipped leaked artifacts are flagged or
  rewritten on the next update; (c) one refocus inoculation line deployed to consumers: "the
  project under governance is <resolved project name>; Specrew is the tool, never the subject."
- **W6 — The deny-list is data**: one versioned file shipped with the module, read by both the
  repo CI lane (W1) and the consumer-side checks (W5), so prevention and detection cannot disagree
  about what a leak is.

### Amendment - 2026-07-13: technology-assumption firewall

The initial firewall catches concrete Specrew-self facts. It must also catch a broader semantic class:
a downstream-facing statement that presents one stack, forge, test framework, package mechanism, or
delivery model as universal without proving that it applies to the project.

- **W7 — Applicability provenance**: every downstream-facing technology or delivery statement MUST
  satisfy at least one of four shapes: `project-detected` from repository evidence;
  `profile-selected` by an explicit quality/work-kind profile; `provider-gated` by repository
  governance; or `example-only` with wording that cannot be read as a mandate. An unqualified concrete
  technology statement is a leak even when it contains no Specrew identifier.
- **W8 — Extended taxonomy**: the data file gains `stack-assumption` and `delivery-assumption`
  classes. Seed terms cover concrete frameworks/runtimes/test tools used as universal requirements and
  package/prerelease/registry/forge workflows used without a resolution point. Matching remains scoped
  to consumer-deployed surfaces; Specrew implementation code, explicitly selected stack presets, and
  provider-specific templates behind a matching provider gate are not findings.
- **W9 — Heterogeneous fixture matrix**: runtime/static fixture coverage MUST include at least a Python
  project with a non-Pester test command, a non-GitHub repository, and an internal application with no
  publish/release target. Rendered prompts, refocus teaching, lifecycle templates, evidence guidance,
  and deployed CI must contain no inapplicable technology or delivery mandate.
- **W10 — Generic contract before adapters**: shared methodology contracts describe universal
  observations and schemas first. Framework-specific enrichments are optional producers selected by
  project evidence; they cannot define the core contract. For test evidence, the universal floor is
  process execution metadata plus an optional schema-defined result produced by the project — never a
  built-in assumption that every downstream test runner is Pester, pytest, Jest, or any other tool.

This amendment composes with F-198 Iteration 004 for the already-known concrete leaks. It does not
require a general natural-language theorem prover: W8 supplies high-signal lint seeds, W9 catches
rendered semantic leakage, and each new field incident extends the corpus.

## Out of scope

- The release-model resolver implementation (204-W7 owns it; this proposal only guarantees the
  class of defect it fixes cannot silently recur).
- Reviewer-side machinery honesty (203's stripped-paths teaching is the sibling fix on the
  review surface).

## Effort

~5-8 SP: original W1-W6 (3-5 SP); W7-W8 taxonomy/applicability rules (1 SP); W9 heterogeneous
fixture matrix (1-2 SP); W10 is a contract rule exercised through those fixtures.

## Acceptance criteria

- **AC1:** The author-time lint surface equals the deny-by-default deploy allowlist plus deployed-script
  literals; an unannotated self-fact hit fails the build.
- **AC2:** The same versioned taxonomy drives repository prevention and downstream advisory/heal checks.
- **AC3:** A rendered anything-but-Specrew fixture contains no identity, path, release-model, or
  self-host-CI leak.
- **AC4:** Python/non-Pester, non-GitHub, and no-release fixtures receive no inapplicable PowerShell,
  Pester, GitHub Actions/PR, package-registry, or prerelease mandate.
- **AC5:** Provider-specific templates behind the matching provider gate and explicitly selected stack
  presets remain valid, proving the firewall distinguishes specialization from universal leakage.
- **AC6:** A generic downstream test-evidence contract records framework-neutral execution facts and
  accepts optional schema-valid project-produced results without embedding a framework parser in core.
- **AC7:** Every escape annotation includes a reason; missing or empty reasons fail validation.

## Phase placement

With 204 in the post-0.40.0 fast-follow window — and W1 lands FIRST, so every template the beta-2
work touches is born clean instead of retro-scrubbed.

## Open questions

1. Does the lint cover module-shipped docs that consumers read (extension README) — lean yes.
2. Is a last-mile strip in the packet renderers worth adding as defense in depth, or do
   author/deploy/runtime gates suffice? (Start without it; revisit on the first W4 escape.)
3. Annotation syntax per file kind (HTML comment for md, line comment for ps1).

## Risks

- **Over-blocking**: legitimate self-references exist (CHANGELOG, self-host lanes). Mitigation: the
  lint runs ONLY on the deploy allowlist, and the annotation escape records why a hit is
  intentional.
- **False confidence**: a deny-list cannot catch semantic leaks phrased without keywords (a
  workflow that assumes PR-based flow without naming GitHub). W4's fixture rendering plus field
  reports remain the backstop; every field-found leak adds its terms to the list (W6 makes that a
  one-line fix).
- **Stack-term false positives**: names such as PowerShell, pytest, or GitHub are legitimate in
  detected projects, selected presets, and provider-specific templates. Mitigation: W7 applicability
  provenance and AC5; do not ban technology names globally.

## Cross-references

- [204 Consumer CI Methodology Gateway](204-consumer-ci-methodology-gateway.md) — deploy-list
  surgery (W3), the gateway lane W5 rides, and the W7 release-model resolver.
- [203 Reviewer Containment + Identity Hardening](203-reviewer-containment-identity-hardening.md) —
  the review-surface sibling (stripped-paths teaching; W13-W15 field batch).
- F-116 obsolete-file removal surface (the heal path W5b reuses), F-182 advisory-first posture.

## Status history

- **2026-07-09**: status set to `candidate`. Drafted from the maintainer's prevent/detect question
  during the beta-1 E2E, generalizing the 204-W7 release-model leak, the downstream identity
  conflation, and the F-019 CI-template leak into one firewall mechanism.
- **2026-07-13**: amended after the F-198/T018 design review caught a Pester-specific downstream
  evidence contract and an audit found unconditional stack/release teaching. Added applicability
  provenance, `stack-assumption`/`delivery-assumption` taxonomy, heterogeneous fixtures, and the
  generic-contract-before-adapters rule. Estimate increased from 3-5 SP to 5-8 SP.
