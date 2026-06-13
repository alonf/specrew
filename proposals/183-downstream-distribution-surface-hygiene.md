---
proposal: 183
title: Downstream Distribution Surface Hygiene
status: candidate
phase: phase-2
estimated-sp: 6-10
priority-tier: 1
type: governance
discussion: surfaced 2026-06-13 after downstream project artifacts exposed Specrew internal feature, proposal, iteration, and requirement identifiers inside installed prompts, skills, copied scripts, and runtime diagnostics
composes-with:
  - 031  # Specrew Distribution Module
  - 074  # Code Commentary Standards
  - 099  # Installed-File SDLC Instruction Audit
  - 145  # Structured Multi-Phase Reviewer
  - 166  # Concurrent Development Hygiene
  - 167  # Post-Ship Proposal Amendment Discipline
  - 174  # Boundary Variance Disclosure
---

# Downstream Distribution Surface Hygiene

## Why

Specrew's internal implementation history is leaking into downstream projects.

Examples observed in the current tree include:

- agent-visible skills that explain instructions by saying they came from `F-174`, `Feature 176`, or
  `Proposal 162`;
- copied extension scripts under `.specify/extensions/specrew-speckit/scripts/` with comments such as
  `F-174 iter-10`, `Prop-145 P3`, and `Feature 171`;
- runtime/user-facing validation guidance that tells downstream users to follow a command "per Proposal 090";
- shipped FileList assets containing hundreds of lines with Specrew feature/proposal/iteration identifiers.

Internal traceability is useful while building Specrew. It is not appropriate in downstream project prompts,
managed skills, copied scripts, runtime diagnostics, or generated artifacts. A downstream user should see Specrew
as a product and methodology, not as Specrew's own feature backlog. A downstream agent should follow durable
product rules, not internal implementation chronology.

The invariant should be:

```text
Specrew-owned implementation identifiers stay inside Specrew's internal design/history surfaces.
Downstream-visible surfaces speak in product concepts, public rule names, and actionable remediation.
```

## What

Add a formal **distribution surface hygiene** policy, cleanup pass, and automated leak gate.

### Surface classes

Specrew should classify files by where their text can appear:

| Class | Examples | Internal IDs allowed? |
| --- | --- | --- |
| `internal-history` | `proposals/`, `specs/`, review reports, retros, drift logs, maintainer-only design notes | Yes |
| `public-docs` | `README.md`, `docs/**`, changelog/release notes | Limited, only when explaining public roadmap/history |
| `agent-visible` | squad templates, skills, host agent files, coordinator prompts, refocus text | No by default |
| `downstream-runtime-script` | files copied to `.specify/extensions/specrew-speckit/scripts/**` | No by default, including comments |
| `runtime-output` | `Write-Host`, warnings, errors, thrown messages, validation failures | No |
| `generated-downstream-artifact` | scaffolded `state.md`, `review.md`, quality gates, decision ledgers | No Specrew-owned IDs; downstream project FR/SC IDs remain valid |

### Rewrite rule

Distributed text should explain the product invariant, not the feature that introduced it.

Examples:

```text
Bad:  F-174 iter-10 double-render dedupe.
Good: Prevent duplicate bootstrap when a host fires SessionStart twice for one launch.

Bad:  Use the sync command (Proposal 090) instead of manual edits.
Good: Use the canonical sync command; manual edits bypass state normalization.

Bad:  Prop-145 round-4 containment.
Good: Contain one provider launch failure so later providers still run.
```

### Public rule ids

Some Specrew concepts need stable names for validation output and review evidence. Use public rule ids instead
of proposal or feature numbers.

Examples:

| Internal reference | Public rule id |
| --- | --- |
| Proposal 090 closeout sync | `boundary-sync/canonical-boundary` |
| Proposal 145 review evidence | `review/evidence-integrity` |
| Feature 174 rolling handover | `session-continuity/rolling-handover` |
| Feature 171 refocus | `context/refocus` |
| Feature 016 boundary handoff | `boundary/human-approval-stop` |

The first implementation can ship a small registry file, for example
`extensions/specrew-speckit/governance/public-rule-ids.yml`, used by prompts, diagnostics, and tests.

### Automated leak gate

Add a CI/test gate that scans **distributable surfaces**, not the whole repository.

The gate should scan at least:

1. every `Specrew.psd1 FileList` entry;
2. `extensions/specrew-speckit/**`;
3. a temp project after `specrew init`;
4. the same temp project after `specrew update`;
5. generated host surfaces: `.agents/**`, `.claude/**`, `.cursor/**`, `.github/agents/**`, `AGENTS.md`;
6. generated `.specify/extensions/specrew-speckit/**`.

Default forbidden patterns on distributed surfaces:

```text
\bF-\d+\b
\bFeature\s+\d+\b
\bProposal\s+\d+\b
\bProp-\d+\b
\biter(?:ation)?[- ]?\d+\b
```

`FR-\d+`, `SC-\d+`, and task ids need more careful handling. They are valid inside a downstream project's own
spec/tasks/review artifacts, but Specrew-owned requirement ids should not appear in Specrew-authored distributed
runtime guidance. The first gate should:

- allow `FR-*` / `SC-*` in user/project spec examples and generated project requirement tables;
- block them in Specrew-owned runtime output, prompt instructions, comments, public rule descriptions, and
  generated decision/remediation text unless allowlisted.

### Allowlist

Use an explicit allowlist only where the public value is higher than the leak risk.

Allowlist entries should include:

```yaml
- path: docs/user-guide.md
  pattern: "Proposal 105"
  reason: "public roadmap reference in user documentation"
  owner: maintainer
```

Inline markers can be allowed for comments when needed:

```text
SPECREW-PUBLIC-REF-OK: public roadmap reference, not runtime guidance
```

The allowlist is not a cleanup bypass. It is an exception ledger that reviewers can challenge.

### Cleanup order

Migrate in risk order:

1. **Agent-visible prompts/skills/charters**: replace internal IDs with product concepts and public rule ids.
2. **Runtime diagnostics**: make messages actionable without proposal/feature references.
3. **Copied extension script comments**: rewrite chronology comments as invariant/rationale comments.
4. **Generated artifacts**: ensure Specrew-owned IDs do not enter downstream project artifacts.
5. **Public docs**: keep only intentional roadmap/history references, preferably behind a public docs section.

### Review integration

Proposal 145 review should add a distribution-boundary check when a change touches:

- `Specrew.psd1 FileList`;
- `extensions/specrew-speckit/**`;
- host agent/skill templates;
- start/update/deploy paths;
- runtime validation output.

The reviewer should ask:

1. Can this text be copied into a downstream project?
2. Can an agent read this text as instruction?
3. Can a user see this text during normal operation?
4. Does it mention Specrew implementation history instead of product behavior?
5. Is the intended reference a public rule id, user-facing doc link, or internal-only traceability?

## Functional requirements

- **FR-001**: Specrew MUST define distribution surface classes that distinguish internal history from
  downstream-visible prompts, skills, scripts, runtime output, and generated artifacts.
- **FR-002**: Specrew-owned feature, proposal, iteration, and implementation task identifiers MUST NOT appear in
  agent-visible or downstream-copied surfaces unless explicitly allowlisted with a reason.
- **FR-003**: Runtime/user-facing diagnostics MUST explain the actionable product rule and remediation, not the
  internal proposal or feature that introduced the rule.
- **FR-004**: Specrew MUST provide stable public rule ids for product rules that need durable names in diagnostics,
  validation output, review evidence, or generated artifacts.
- **FR-005**: The leak gate MUST scan both repository distributable inputs and a freshly initialized/updated
  downstream project, so packaging and deployment paths are covered.
- **FR-006**: The gate MUST treat downstream project `FR-*` / `SC-*` references as distinct from Specrew-owned
  internal requirement ids, avoiding false positives on legitimate project requirements.
- **FR-007**: The implementation MUST migrate existing high-risk leaks in agent-visible surfaces and runtime
  output before enforcing the gate as hard failure.
- **FR-008**: Proposal 145 review guidance SHOULD include a distribution-boundary check for changes to FileList,
  extension assets, host templates, and deploy/update paths.

## Out of scope

- Rewriting all historical proposals, specs, reviews, retros, or drift logs. Those are internal history surfaces.
- Banning public roadmap references from user documentation. Public docs may mention proposals when the reference
  is intentional and useful.
- Removing downstream project `FR-*` / `SC-*` identifiers. Those are part of the user's own lifecycle artifacts.
- Packaging-time comment stripping as the primary solution. It can be a later optimization, but the source of
  distributable assets should be clean and reviewable.
- Renumbering old proposals or features.

## Effort

- **Iteration 1 (~3-4 SP)**: Define surface classes, public rule-id registry, allowlist format, and reviewer
  checklist. Add a report-only leak scanner over FileList and extension surfaces. Clean the most visible
  agent-facing and runtime-output leaks.
- **Iteration 2 (~3-6 SP)**: Extend the scanner to temp-project `specrew init` / `specrew update` outputs, add
  generated-surface coverage, migrate copied script comments, and turn the gate to fail for high-risk surfaces.
- **Total**: ~6-10 SP.

## Phase placement

Phase 2, priority tier 1.

This belongs with distribution, installed-file discipline, and structural fidelity work. The leak is not cosmetic:
it affects downstream agent behavior, user trust, review signal, and the boundary between Specrew's internal
development process and the product Specrew distributes.

## Open questions

1. Should `public-docs` allow proposal numbers freely, or require allowlist entries for all roadmap/history
   references?
2. Should the first hard gate block only agent-visible/runtime-output leaks, leaving copied script comments as
   warnings until the migration lands?
3. Where should the public rule-id registry live, and should validator diagnostics link to user docs for each
   public rule id?
4. Should `FR-*` / `SC-*` detection use path classification only, or should generated artifacts carry provenance
   markers that distinguish Specrew-owned rules from downstream project requirements?
5. Should release packaging include a secondary sanitized-distribution check as defense in depth after source
   cleanup?

## Risks

- **False positives on legitimate project requirements**: mitigate with surface classification and careful
  handling of downstream `FR-*` / `SC-*` references.
- **Loss of useful maintainer context**: mitigate by keeping internal IDs in internal history surfaces and by
  rewriting distributed comments to preserve the invariant/rationale.
- **Allowlist decay**: mitigate by requiring reasons and reviewer scrutiny for every exception.
- **Gate friction during migration**: start report-only or warn-only for medium-risk classes, then hard-fail
  high-risk agent-visible/runtime-output classes first.
- **Source/distribution drift**: avoid making packaging-time stripping the primary fix; keep shipped source clean.

## Cross-references

- [031 Specrew Distribution Module](031-specrew-distribution-module.md) owns what ships and how FileList assets
  enter downstream installations.
- [074 Code Commentary Standards](074-code-commentary-standards.md) supplies the comment-quality baseline:
  comments should explain intent/rationale, not implementation chronology.
- [099 Installed-File SDLC Instruction Audit](099-installed-file-sdlc-instruction-audit.md) is the closest
  installed-surface audit precedent.
- [145 Structured Multi-Phase Reviewer](145-structured-multi-phase-reviewer.md) should consume the new
  distribution-boundary review check.
- [166 Concurrent Development Hygiene](166-concurrent-development-hygiene.md) is adjacent because generated
  mirrors and distributed surfaces need explicit ownership and drift rules.
- [167 Post-Ship Proposal Amendment Discipline](167-post-ship-proposal-amendment-discipline.md) is adjacent
  because both separate historical proposal truth from active implementation truth.
- [174 Boundary Variance Disclosure](174-boundary-variance-disclosure.md) should use public rule names when its
  guidance is distributed.

## Status history

- 2026-06-13: Created as candidate after maintainer observed Specrew feature/proposal identifiers leaking into
  downstream project comments, prompts, scripts, and runtime guidance.
