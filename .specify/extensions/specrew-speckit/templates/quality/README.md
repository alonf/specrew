# Quality Governance Template Sources

## Overview

This directory is the extension-owned source of truth for Phase 1 stack-aware quality assets. Presets and lens checklists are authored here, then scaffolded into downstream `.specrew/presets/` and `.specrew/lenses/` locations.

## Structure

```text
templates/quality/
├── README.md
├── lenses/
│   ├── security-baseline-v1.md
│   ├── robustness-baseline-v1.md
│   └── test-integrity-v1.md
└── presets/
```

## Phase 1 Authoring Rules

1. Keep assets Markdown-first and git-reviewable; required checklist content stays in Markdown tables.
2. Use versioned filenames for published sources (for example, `security-baseline-v1.md`) and include an explicit semantic version inside the document.
3. Every lens source must include: title, purpose/scope, row-status vocabulary, line-item checklist table, upgrade guidance, and change log.
4. Keep row criteria execution-ready. A reviewer should be able to mark `pass`, `fail`, `not-applicable`, or `advisory` without hidden policy.
5. Preserve Phase 1 scope. Do not imply later-phase hardening, bug-hunter routing, drift automation, or mixed-stack override behavior in these baseline assets.
6. Version presets independently from lenses so stack-specific evolution does not force unrelated checklist upgrades.

## Reviewed Lens-Upgrade Workflow

Use this workflow when a new defect pattern should change a versioned lens checklist:

1. **Capture the proposed delta** in the extension source lens file, not only in a downstream scaffolded copy.
2. **Describe the trigger** in the change log so reviewers can see why the checklist changed.
3. **Review each proposed row** and classify it as approved now, deferred for later, or advisory-only.
4. **Bump the semantic version** only after the checklist delta is reviewed.
5. **Update preset references separately** when a stack should adopt the newer lens version.
6. **Merge approved changes into active project lens versions** through the scaffold/update path; deferred rows remain out of the active version until later approval.

This keeps FR-026 explicit: teams review proposed checklist updates, approve or defer specific line items, and then adopt the approved lens revision intentionally instead of through silent overwrite.

## Change Management Notes

- Record additive checklist deltas in the asset's change log.
- Keep upgrade guidance actionable so downstream teams know whether the new version requires additional evidence or only clarifies an existing expectation.
- If a new trap belongs in a mechanical rule instead of a manual lens, document that in review and avoid duplicating the requirement as hidden prose.
