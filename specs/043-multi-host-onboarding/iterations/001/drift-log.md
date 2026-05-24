# Iteration 001 Drift Log

**Feature**: F-043 | **Iteration**: 001

Drift = anything that diverged from the spec during implementation. Documenting drift honestly is required by Specrew's review-gate discipline (Proposal 073 Review Evidence Integrity).

## Drift #1 — Spec called `.yml`, implementation shipped `.json`

- **Spec text** (FR-001): "A new file `.specrew/host-history.yml` MUST be created"
- **Shipped reality**: `.specrew/host-history.json`
- **Reason**: Avoiding a `powershell-yaml` external module dependency. Specrew's existing on-disk state (`.specrew/start-context.json`, `.specrew/feature-status.json`) already uses JSON. Matching the existing pattern keeps the dependency surface minimal.
- **Schema impact**: None. All schema fields are spec-conformant; only the serialization format differs.
- **User impact**: None — `host-history` is internal state, not user-edited.
- **Reviewer disposition**: Accepted. Will be called out in CHANGELOG entry for this feature.

## Drift #2 — FR-008, FR-009, FR-011 deferred

- **Spec text**: Mandated migration of Category A files (coordinator-governance.md, charters, ceremonies, directives) from `.squad/coordinator/` to `.specrew/coordinator/`, with `specrew update` brownfield migration and breadcrumb-file pattern.
- **Shipped reality**: Not implemented.
- **Reason**: F-044 (Per-Host Architecture Refactor / Proposal 108) was running in parallel and consuming sprint capacity. Category A migration is a brownfield-impacting change that needs a tested migration path; sequencing it behind F-044's stable substrate reduces risk. The non-migration FRs are independently valuable.
- **Schema impact**: None for this iteration. FR-008/009/011 will land via a follow-up small-fix slice.
- **User impact**: Validators continue to read coordinator content from `.squad/coordinator/` (unchanged from pre-F-043). No regression.
- **Reviewer disposition**: Accepted as explicit scope cut; tracked in [`scope.md`](./scope.md) "Out-of-scope (deferred)" section.

## Drift #3 — F-040 review gap fix in F-043 (incidental)

- **Spec text**: F-043 spec mentions "closes Gap 1 from F-040 review (default_host persistence)" implicitly via FR-002.
- **Shipped reality**: Confirmed — `755c87f1` explicitly closes Gap 1.
- **Reason**: F-040 had shipped `Resolve-SpecrewHostFromHistory` but never called it. F-043's wiring closes the gap as a side effect of implementing FR-002.
- **Schema impact**: None.
- **User impact**: Positive — `specrew host use claude` now actually persists.
- **Reviewer disposition**: Accepted; documented in F-040 closeout dashboard's "Gap 1 → closed by F-043" entry (already present).

## Drift #4 — A-1 host-gate regression fix bundled with F-044 iter-002

- **Spec text**: FR-002 + FR-013 (non-TTY exit with guidance).
- **Implementation**: `755c87f1` (F-043 wiring) added `exit 1` for `non-interactive-no-default` and `no-hosts-available` branches — but these exits fired BEFORE `Save-StartArtifacts`, breaking the `-NoLaunch` dry-run contract assumed by `specrew-start-baseline-tracking.ps1` and two other tests.
- **Detection**: Caught by F-044 iter-001's deep-review-agent A (lint + parse + tests sweep).
- **Fix**: A `-NoLaunch` carve-out that falls back to `selectedHost='copilot'` + `host_resolution='no-launch-default'`. Landed in commit `dcc4beb7` as part of F-044 iter-002's bug-fix bundle.
- **Schema impact**: New `host_resolution` enum value: `no-launch-default`.
- **Reviewer disposition**: F-043 closes acknowledging the bug shipped in this iteration but was incidentally fixed by F-044 iter-002 on the same branch. Both feature artifact sets cross-reference this drift entry.
- **Cross-reference**: see `../../../044-per-host-architecture-refactor/iterations/002/scope.md` § "A-1 incidental cross-feature fix"
