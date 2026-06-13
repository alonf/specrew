# Review: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-11
**Overall Verdict**: accepted

## Summary

Iteration 001 (methodology layer) delivers the work-kind taxonomy, the governance schemas, the
extended DevOps lens, the methodology doc + the closeout-vs-release-validation invariant, the
docs-only/devops lifecycle surfaces + capture templates, the provider-neutral `ProviderAdapter`
contract + generic fallback, the forge-coupling inventory, and the FileList registration. **No
runtime enforcement** in this iteration — that is the planned, honestly-labelled phasing (the CI
validator, capability detection, synthesis, and dogfood are Iteration 2). Evidence is behavioural
(58 Pester assertions across 2 suites), not file-presence.

**Verification state**: T014 catalog/schema integrity 36/0; T015 provider-neutral core/fallback/guard
21/0; markdownlint clean; PSScriptAnalyzer 0 errors (2 non-blocking style warnings, Proposal-037
queue); FileList-completeness PASS; mechanical-checks 0 findings; `validate-governance` 0 FAIL.

**Review-caught issue (resolved)**: T013 had been over-marked `done` while only its FileList sub-part
was complete (drift D-001). Corrected: T013 (FileList) = done; T013b (extension.yml bump + deploy-time
`.specify` coverage) = deferred to release/deploy, maintainer-approved.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-001 | pass | `work-kinds.yml` catalog: 4 stable kinds × weight/evidence/scope; T014-verified. |
| T002 | FR-009 | pass | catalog + declaration JSON schema; enum agrees with catalog (T014). |
| T003 | FR-003 | pass | `repository-governance.schema.json`: branch_model + review_gate + multi_repo. |
| T004 | FR-002 | pass | DevOps lens extended: governance Qs + branch_model + review_gate + brownfield + synthesis + honesty. |
| T005 | FR-004 | pass | `docs/methodology/work-kinds.md`: taxonomy + closeout-vs-release invariant + worked example. |
| T006 | FR-005 | pass | docs-only lifecycle surface (no release). |
| T007 | FR-006 | pass | devops lifecycle surface (risk/rollback + dry-run/CI evidence). |
| T008 | FR-018 | pass | 3 capture templates (declaration, governance, release-validation-record). |
| T009 | FR-014 | pass | ProviderAdapter contract + Strategy dispatch + git-diff fallback + apply guard; T015-verified. |
| T010 | FR-015 | pass | GenericFallbackAdapter: honest ci-only/manual; T015-verified. |
| T011 | FR-010 | pass | phased-enforcement honesty baked into lens/docs/adapter (advisory default; no over-claim). |
| T012 | FR-019 | pass | forge-coupling inventory: 5 genuine downstream items + false positives classified. |
| T013 | FR-013 | pass | FileList registration (sorted; completeness test PASS). |
| T013b | FR-013 | pass | Deferral to release/deploy APPROVED (Alon Fliess, 2026-06-11; drift D-001) — the deferral DECISION passes review; out of Iter-1 scope. |
| T014 | FR-001 | pass | catalog/schema integrity suite green (36 assertions). |
| T015 | FR-014 | pass | provider-neutral core + fallback + guard suite green (21 assertions). |

## Requirement coverage (Iteration-1 scope)

- **Implemented + evidenced**: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-008, FR-009, FR-010,
  FR-014, FR-015 (contract+fallback), FR-016 (conduct doc), FR-017, FR-018, FR-019 (inventory),
  FR-021 (content). SC-001, SC-003, SC-008, SC-010 (core runs with no adapter — tested), SC-011
  (user-named branches honored in describe_protection — tested).
- **Planned for Iteration 2 (not gaps)**: FR-007 (validator), FR-011 (bypass audit runtime), FR-012
  (capability detection), FR-013 dogfood + SC-007/SC-014, FR-015 (GitHub detect), FR-016 (exercised),
  FR-020 (apply runtime), FR-021 (detector). SC-005, SC-006, SC-009, SC-012.
- **Iteration 3 (not gaps)**: FR-019 migration; SC-008 over-claim sweep; SC-013.

## Quality assessment

- **Strengths**: forge-neutral by construction (core invokes no `gh`/GitHub API — test-asserted);
  dependency-free YAML reader honors the no-new-dependency policy; the `apply_protection` safety guard
  (read-only/unverified/unapproved all refused) is tested; honest phasing throughout.
- **Watch items carried (not blocking Iter-1)**: (1) the hand-rolled YAML reader is a maintenance
  surface — covered by T014 but worth a contract test as the schemas evolve; (2) the **deployed-catalog
  location** is an open Iter-2 design item (`.specify` mirrors `scripts/` but not `knowledge/`) —
  recorded in T013b; (3) PSScriptAnalyzer `New-SpecrewProviderAdapter` ShouldProcess warning is a
  false positive (pure constructor) left on the Proposal-037 queue.

## Gap Ledger

- No requirement (FR/SC) gaps in Iteration-1 scope (in-scope requirements implemented + evidenced; Iter-2/Iter-3 requirements are planned phasing, not gaps): fixed-now.

## Notes

- The T013b deferral is task-level (release-prep), maintainer-approved, recorded in drift-log D-001;
  it is carried to Iteration 2 (T019) / feature-closeout, where it is resolved (not deferred-at-close).
- Per-task drift was tracked; drift-log carries 1 resolved event (D-001).
- Stop at review-signoff for the maintainer's verdict; no push/PR/merge/tag/publish/release; no
  Iteration-2 work.
