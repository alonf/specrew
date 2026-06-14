# Tasks: Work Kind and Branch Governance Model

**Feature**: 182-work-kind-branch-governance
**Plan**: [plan.md](plan.md) · **Design-analysis**: Option B (3-iteration plan)
**Branch**: `182-work-kind-branch-governance`

## Format

`- [ ] T### [P?] [iN] [US#] [Owner: role] [Capacity: N SP] Description with exact path (Trace: FR/SC)`

`[P]` = parallelizable (different files, no dependency). `[iN]` = iteration 1, 2, or 3.

Iteration 1 (methodology layer) is **fully decomposed**; Iterations 2–3 are **epic-level**
(refined into tasks at each iteration's start, per the approved plan→tasks default).

---

## Iteration 1 (i1) — methodology + seam contract + audit (~16 SP, ≤ 20 cap)

### Phase 1: Catalog + schemas (foundational)

- [ ] T001 [i1] [US1] [Owner: Implementer] [Capacity: 1.5 SP] Author the work-kind catalog `extensions/specrew-speckit/knowledge/work-kinds.yml` — the 4 kinds (software-feature/bug-bash/docs-only/devops), each with `id` / `lifecycle_weight` / `required_evidence` / `allowed_scope` / `branch_prefix_hint`; stable IDs, deprecate-not-delete (Trace: FR-001, SC-001).
- [ ] T002 [P] [i1] [US1] [Owner: Implementer] [Capacity: 1 SP] Author the catalog + declaration schema `extensions/specrew-speckit/knowledge/work-kinds.schema.json` — validates the catalog and the `.specrew/work-kind.yml` declaration; encode the allow-list for repository-global/generated files (Trace: FR-001, FR-009).
- [ ] T003 [P] [i1] [US2] [Owner: Implementer] [Capacity: 1.5 SP] Author the governance schema `extensions/specrew-speckit/knowledge/repository-governance.schema.json` — `provider`, `branch_model` (style + named branches + protection + promotion_path), `review_gate`, `apply_to_admins`, `bypass_actors`, `enforcement_mode`, `multi_repo` (Trace: FR-003, FR-008, FR-017, FR-018).

**Checkpoint**: the data substrate (catalog + 2 schemas) exists; surfaces + adapter build on it.

### Phase 2: Methodology surfaces (lens + docs + templates)

- [ ] T004 [i1] [US2] [Owner: Spec Steward] [Capacity: 2 SP] Extend the DevOps lens `extensions/specrew-speckit/knowledge/design-lenses/devops-operations.md` — the repository-governance question set + `branch_model` + `review_gate` (automated review opt-in) + brownfield adapt-or-change + the on-the-fly adapter-synthesis conduct (read-only by default) + the provider/plan/visibility caveat before any enforcement promise (Trace: FR-002, FR-003, FR-008, FR-016, FR-017, FR-021, SC-002).
- [ ] T005 [i1] [US1] [Owner: Spec Steward] [Capacity: 1 SP] Author `docs/methodology/work-kinds.md` — the work-kind taxonomy companion + the feature-closeout-vs-release-validation invariant + the post-merge-finding→new-work-item flow + the GitHub capability caveat (Trace: FR-001, FR-004, SC-001, SC-004).
- [ ] T006 [P] [i1] [US3] [Owner: Spec Steward] [Capacity: 0.5 SP] Author the docs-only lifecycle surface `templates/lifecycle/docs-only-lifecycle.md` (intent, audience, changed docs, markdown/link checks, review, docs-closeout; no release) (Trace: FR-005, SC-003).
- [ ] T007 [P] [i1] [US3] [Owner: Spec Steward] [Capacity: 0.5 SP] Author the devops lifecycle surface `templates/lifecycle/devops-lifecycle.md` (risk/rollback plan, dry-run/CI evidence, devops-closeout) (Trace: FR-006).
- [ ] T008 [P] [i1] [US1] [Owner: Implementer] [Capacity: 0.5 SP] Author the capture templates `templates/work-kind/{work-kind.yml, repository-governance.yml, release-validation-record.md}` (Trace: FR-004, FR-009, FR-018).

### Phase 3: Provider seam (contract + fallback) + honesty

- [ ] T009 [i1] [US5] [Owner: Implementer] [Capacity: 1.5 SP] Author the ProviderAdapter contract `extensions/specrew-speckit/scripts/provider-adapter.ps1` — `detect_capability` / `describe_protection` / `apply_protection` (guarded) / `read_pr_context`; Strategy dispatch (no central provider switch); the `git diff` + `branch_model` fallback so the core needs no adapter; the core imports no forge tool (Trace: FR-014, FR-015).
- [ ] T010 [P] [i1] [US5] [Owner: Implementer] [Capacity: 1 SP] Author the GenericFallbackAdapter `extensions/specrew-speckit/scripts/provider-generic.ps1` — always-present; reports `ci-only`/`manual`; git-diff `read_pr_context` (Trace: FR-015, SC-010).
- [ ] T011 [i1] [US1] [Owner: Reviewer] [Capacity: 0.5 SP] Bake the phased-enforcement honesty labeling into the surfaces — every enforcement claim labeled enforced vs phased/deferred; advisory-default stated; no over-claim (Trace: FR-010, SC-008).

### Phase 4: Forge-neutralization audit / inventory

- [ ] T012 [i1] [US2] [Owner: Implementer] [Capacity: 1.5 SP] Produce the forge-coupling **inventory** `specs/182-work-kind-branch-governance/iterations/001/forge-coupling-inventory.md` — audit ALL downstream-governing surfaces (lifecycle prompt template, deployed skills, extension scripts, charters, lens content, deployed CI templates) for GitHub-dev-habit coupling; classify genuine vs false-positive (the `copilot` host name, generic prose, example histories); EXCLUDE Specrew's own dev infra; list each genuine item with its Iter-3 migration disposition (Trace: FR-019, SC-013).

### Phase 5: Registration + i1 tests

- [x] T013 [i1] [US1] [Owner: Implementer] [Capacity: 0.5 SP] **DONE** — Registration: declare the new deployable files (`work-kinds.yml`, the 2 schemas, the 3 capture templates, the 2 lifecycle templates, the adapter + generic-fallback scripts, the methodology doc) in `Specrew.psd1` FileList, sorted; FileList-completeness test PASS (Trace: FR-013, SC-007).
- [ ] T013b [i1->release/deploy] [US1] [Owner: Implementer] [Capacity: 0.5 SP] **DEFERRED** (to the release/deploy step — Iter-2 dogfood T019 + feature-closeout; the defer was **approved at the Iteration-1 review/closeout** — Alon Fliess, 2026-06-11; see drift-log D-001): bump `extension.yml` version (release-prep — the prepublish harness checks the config-version at publish; the version target is a release decision) AND ensure deploy-time `.specify` coverage for the new files. Note: `.specify` is GENERATED by `deploy-speckit-extension.ps1` at update/deploy and currently mirrors `scripts/` but NOT `knowledge/`, so the **deployed-catalog location** (where the downstream/self-host validator reads `work-kinds.yml`) is an Iter-2 deployment-design item, not a hand-edit (Trace: FR-013, SC-007).
- [ ] T014 [P] [i1] [US1] [Owner: Implementer] [Capacity: 1 SP] Test — catalog + schema integrity `tests/unit/work-kind-catalog.tests.ps1`: 4 kinds present, unique/stable IDs, the catalog + declaration + governance schemas validate their fixtures (Trace: FR-001, FR-003, FR-009, SC-001).
- [ ] T015 [P] [i1] [US5] [Owner: Implementer] [Capacity: 1 SP] Test — provider-neutral core + generic fallback `tests/unit/provider-adapter.tests.ps1`: the core imports no forge tool; the generic fallback returns `ci-only`/`manual`; `read_pr_context` works with no adapter via git-diff (Trace: FR-014, FR-015, SC-010).

**Checkpoint (i1)**: the methodology + data substrate + the forge-neutral seam contract + the
coupling inventory are complete and tested; ~16 SP. No runtime enforcement yet (phased).

---

## Iteration 2 (i2) — runtime validator + capability + synthesis + dogfood (~11 SP epic-level, ≤ 20 cap)

- [ ] T016 [i2] [US4] [Owner: Implementer] [Capacity: 3 SP] **Epic**: the provider-neutral CI validator `extensions/specrew-speckit/scripts/work-kind-validator.ps1` — WorkKindValidator + ChangedFileClassifier + CloseoutEvidenceChecker; advisory default; gap-naming output (SC-005); fail-open (Trace: FR-007, SC-005).
- [ ] T017 [i2] [US5] [Owner: Implementer] [Capacity: 2.5 SP] **Epic**: CapabilityDetector + GitHubAdapter detection (`gh`/API) + the CI workflow template `templates/github/workflows/specrew-work-kind.yml` + the brownfield detector (adapt-or-change) (Trace: FR-012, FR-015, FR-021, SC-006).
- [ ] T018 [i2] [US5] [Owner: Implementer] [Capacity: 2 SP] **Epic**: on-the-fly synthesis exercised (read-only until human-verified) + `apply_protection` human-gated safety + emergency bypass audit (Trace: FR-016, FR-020, FR-011, SC-009, SC-012).
- [ ] T019 [i2] [US1] [Owner: Reviewer] [Capacity: 2 SP] **Epic**: dogfood on Specrew + SC-014 self-consistency — author Specrew's `.specrew/work-kind.yml` + `.specrew/repository-governance.yml` reflecting its actual posture; verify no conflict; beta-before-stable validation (Trace: FR-013, SC-007, SC-014).
- [ ] T020 [i2] [US4] [Owner: Implementer] [Capacity: 1.5 SP] **Epic**: i2 tests — validator (each kind, mismatch, missing evidence), denial-path (too-broad bypass, missing token, apply-without-approval), fail-open, capability, multi-host parity (Trace: FR-007, FR-011, FR-012, FR-020, SC-005, SC-006, SC-009).

---

## Iteration 3 (i3) — forge-neutralization decouple migration (~4 SP epic-level, ≤ 20 cap)

- [ ] T021 [i3] [US2] [Owner: Implementer] [Capacity: 3 SP] **Epic**: migrate the inventoried downstream-governing surfaces behind the ProviderAdapter — the closeout `gh pr create`/merge-commit steps, PR-review-integration (the "check Copilot" mandate → opt-in), GitHub-Actions-only wiring, branch=`main` assumptions; Specrew's own dev infra unchanged (Trace: FR-019, SC-013).
- [ ] T022 [i3] [US2] [Owner: Reviewer] [Capacity: 1 SP] **Epic**: verify SC-008 (no over-claim) + SC-013 (migrated surfaces carry no GitHub-only mandate) across the migrated surfaces; out-of-surface coupling recorded as tight follow-ups (Trace: SC-008, SC-013).

**Iter-3 escape hatch**: if the migration exceeds capacity, split it into a sibling `devops`
work item at iteration-closeout (recorded, not silently dropped).

---

## Traceability summary

- **Every FR has ≥1 task**: FR-001 (T001,T002,T005,T014); FR-002 (T004); FR-003 (T003,T004,T014);
  FR-004 (T005,T008); FR-005 (T006); FR-006 (T007); FR-007 (T016,T020); FR-008 (T003,T004);
  FR-009 (T002,T008,T014); FR-010 (T011); FR-011 (T018,T020); FR-012 (T017,T020); FR-013 (T013,T013b,T019);
  FR-014 (T009,T015); FR-015 (T009,T010,T015,T017); FR-016 (T004,T018); FR-017 (T003,T004);
  FR-018 (T003,T008); FR-019 (T012,T021,T022); FR-020 (T018,T020); FR-021 (T004,T017).
- **Every SC has ≥1 task**: SC-001 (T001,T005,T014); SC-002 (T004); SC-003 (T006); SC-004 (T005);
  SC-005 (T016,T020); SC-006 (T017,T020); SC-007 (T013,T013b,T019); SC-008 (T011,T022); SC-009 (T018,T020);
  SC-010 (T010,T015); SC-011 (T003,T004 branch_model + i2 validator honors it); SC-012 (T018);
  SC-013 (T012,T021,T022); SC-014 (T019).
- **Every task traces to ≥1 FR/SC** (see each `(Trace: …)`).
- **Sizing note (drift-aware)**: the decomposed total is ~31 SP (i1 ~16, i2 ~11, i3 ~4), above the
  plan's rough ~16–24 SP estimate — the workshop's three pillars (esp. the provider-neutral adapter +
  the forge-neutralization) are heavier than the proposal's original 8–14 SP framing. **Each iteration
  is under the 20 SP cap**, so there is no per-iteration overcommit; the total-vs-estimate variance is
  recorded here and the Iter-3 split-to-sibling escape hatch remains the mitigation. Confirm at the
  before-implement readiness.
