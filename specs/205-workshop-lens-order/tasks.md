# Tasks: Workshop Lens Order (Proposal 220, iteration 1)

**Input**: file:///C:/Dev/specrew-220-workshop-lens-order/specs/205-workshop-lens-order/plan.md (approved 2026-11-10, with the plan-verdict changes applied)
**Iteration**: 001 | **Effort unit**: story points | **Owner**: implementer (Claude) | **Reviewer**: codex co-review

## Format: `- [ ] T### [P?] [US#?] [assigned_to: ...] [effort: ...] Description with exact file path(s) or action (Trace: ...)`

**Rules that bind every task**:

- Test-first: the parity test exists and fails on the unchanged tree before any surface changes.
- No question is filed under the wrong heading to make a check pass (FR-015). A tag disagreement goes to the maintainer.
- `specrew-conformance-provider.ps1` is not edited (203's T011 owns it). `scripts/specrew-update.ps1` is never run in this worktree.
- `.squad/active-features.yml` is never committed.
- Not edited by this feature (maintainer, 2026-11-10): anything under `scripts/internal/continuous-co-review/`
  (feature 203's folder; a changed file there can make the review launch refuse with a runtime-drift error) and
  the bootstrap capture stores (`scripts/internal/bootstrap/ConversationCaptureAccessor.ps1`, `HandoverStore.ps1`,
  `HumanAuthorityStore.ps1`). A run found there is exempted with its reason, never edited.
- **Existing-test safety** (tasks verdict, 2026-11-10). Before any existing workshop test runs, check it for hook
  deployment or writes outside the project, and skip and report any test that does either. Hash the real-home hook
  files before and after each run: `~/.specrew/specrew-hook-launch.ps1`, every file inside
  `~/.specrew/hook-bindings/`, `~/.codex/hooks.json`, `~/.copilot/hooks/*.json` and `~/.cursor/hooks.json`. Stop
  if any hash changes.
- Before every push: `validate-governance.ps1 -ProjectPath . -ChangedOnly` and the CI markdownlint command must both exit 0. After every push: follow Specrew CI, Test and Cross-Platform Validation to their conclusion; a skipped gate job counts as red.

## Phase 1: Proof first (red before green)

- [x] T001 [US2] [assigned_to: implementer] [effort: 4] Write `tests/unit/lens-order-parity.tests.ps1` (script-style). It reads `index.yml` through `Read-IntakeYaml`. It has the block scanner from plan.md's sweep definition (prose line, list, table, fenced line, and consecutive code/data lines that each carry an id). It names the full surfaces. It holds the shipped-text scope with the accepted exclusions and the exemption list, with the conformance-provider alternation as its one entry, and fails on a stale exemption. It compares the touched files' deployed copies by full content, ignoring the deploy wrapper. It runs FR-005 checks a/b/c, counting bullet and numbered decision points itself. It runs the extractor test against the SC-002 expected counts and the FR-018 sentence check. Its report is all-mismatch, with file:line, expected order, found order and fix (Trace: FR-001, FR-005, FR-015, FR-018, FR-019, SC-002)
- [x] T002 [US2] [assigned_to: implementer] [effort: 1] Add self-test cases to `tests/unit/lens-order-parity.tests.ps1` over scratch fixtures under the test's temp root: every "matches" and "does not match" example from plan.md, and a seeded tree with several mismatches that must all be reported in one run (Trace: FR-001, FR-019)
- [x] T003 [US2] [assigned_to: implementer] [effort: 0.5] Run the parity test on the unchanged tree and record the red output in `specs/205-workshop-lens-order/iterations/001/quality/quality-evidence.md`. It must list at least the five known order definitions (Trace: SC-001)
- [x] T017 [US2] [assigned_to: implementer] [effort: 1] Baseline, before T005 (tasks verdict). Run every existing workshop test on the unchanged tree under the existing-test safety rule: screen first, hash before and after each run, and skip and report any test that writes outside the project. Record each result in `specs/205-workshop-lens-order/iterations/001/quality/quality-evidence.md`, so that T013 can tell a test that was already red from one this feature broke (Trace: FR-021)
- [x] T004 [US4] [assigned_to: implementer] [effort: 1.5] Extend `tests/integration/workshop-agenda-confirmation.tests.ps1` with three cases: an out-of-order new agenda is refused, with nothing written and nothing reordered; an in-order agenda is accepted; an agenda confirmed in the old order resumes and completes (FR-013). Run it red-first (Trace: FR-016, FR-013, SC-004)

## Phase 2: The one order and the tags

- [x] T005 [US1] [assigned_to: implementer] [effort: 0.5] Rewrite `extensions/specrew-speckit/knowledge/design-lenses/index.yml` to the problem-first order (option A) and give each lens its `space` from plan.md's tag table (Trace: FR-015)
- [x] T006 [US3] [assigned_to: implementer] [effort: 2.5] Tag all 11 lens files in `extensions/specrew-speckit/knowledge/design-lenses/*.md` with `### Problem questions` and `### Solution questions` inside `## Design Decision Points`. This covers the S1 to S3 splits (words kept), the FR-004 merge and move between `architecture-core.md` and `requirements-nfr.md`, and the "No <space> questions: <reason>" lines. Write the final per-lens gap list to `specs/205-workshop-lens-order/iterations/001/problem-gap-list.md`, including observability's problem halves. Add no new questions. Stop and ask on any tag disagreement (Trace: FR-005, FR-004, FR-015, FR-020, SC-006)
- [x] T007 [US1] [assigned_to: implementer] [effort: 1] Add the relative-order refusal to `extensions/specrew-speckit/scripts/confirm-workshop-agenda.ps1`. It uses `New-SpecrewWorkshopAgendaRefusal` with the out-of-order lenses, the `index.yml` order and one action. It applies to render and confirm of a new agenda only. It never reorders, and never re-checks an agenda that is already confirmed (Trace: FR-016, FR-013)

## Phase 3: The prose surfaces

- [x] T008 [US1] [assigned_to: implementer] [effort: 1] Update the skill source `extensions/specrew-speckit/squad-templates/skills/design-workshop.md`: rewrite the full lens list to the new order; add the sentence "if any list disagrees with index.yml, index.yml wins; a confirmed agenda keeps the order it was confirmed in"; add the problem-section-first conduct inside each lens; reorder the short-name frontmatter list by hand (Trace: FR-017, FR-018)
- [x] T009 [US1] [assigned_to: implementer] [effort: 1] Rewrite the lens lists in `docs/methodology/design-workshop-methodology.md`. The full lists are the Band 1/2/3 catalog tables read in order and the diagram table. The partial lists are the "normally always-on" list, the example agenda and the JSON example, which get relative order. Also describe the single-pass, problem-first order (Trace: FR-017, FR-001)
- [x] T010 [P] [US2] [assigned_to: implementer] [effort: 0.5] Rewrite the full lists in `extensions/specrew-speckit/commands/speckit.specrew-speckit.before-specify.md` and `extensions/specrew-speckit/knowledge/design-lenses/README.md` to the `index.yml` order (Trace: FR-001)
- [x] T011 [US2] [assigned_to: implementer] [effort: 0.5] Refresh the deployed copies with `pwsh -File extensions/specrew-speckit/scripts/deploy-speckit-extension.ps1 -ProjectPath . -RefreshExisting` and `pwsh -File extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1 -ProjectPath .`. Commit only the intended copies, review the `.squad` restamps, and never commit `.squad/active-features.yml` (Trace: FR-001, FR-019)
- [x] T012 [US2] [assigned_to: implementer] [effort: 0.5] Bring the parity test and the extended agenda test to green, record their output in `quality-evidence.md`, and check the SC-002 counts per lens (Trace: SC-001, SC-002, SC-003, SC-004)

## Phase 4: Regression, CI and the proposal

- [x] T013 [US2] [assigned_to: implementer] [effort: 1] Under the existing-test safety rule, and compared against the T017 baseline, run every existing workshop test locally (the roughly 31 files named for workshop, lens, agenda, design-analysis, product-domain or code-implementation), out of process, on a committed tree. Report every result. Classify which ones cover a touched file. Report an already-red test as a finding, and do not fix it silently (Trace: FR-021)
- [x] T014 [US2] [assigned_to: implementer] [effort: 0.5] Add named steps to `.github/workflows/specrew-ci.yml` for `tests/unit/lens-order-parity.tests.ps1`, `tests/integration/workshop-agenda-confirmation.tests.ps1`, and every existing workshop test from T013 that covers a touched file and passes (Trace: FR-021, SC-005)
- [x] T015 [P] [US2] [assigned_to: implementer] [effort: 0.5] Update `proposals/220-workshop-lens-order-and-cross-lens-consistency.md` to `status: active`, `shipped-as: feature-205`, plus the status-history line (the three iterations, the fifth order surface, option A). Update `proposals/INDEX.md`, both the table row and the summary line (Trace: FR-022)
- [x] T016 [US2] [assigned_to: implementer] [effort: 0.5] Pre-push gate: `validate-governance.ps1 -ProjectPath . -ChangedOnly` and markdownlint, both exit 0. Then push, and follow all three workflows to a green conclusion with no skipped gate job (Trace: SC-005)

## Dependencies

- T001 → T002 → T003 must finish before T005 to T011 (red-first).
- T017 (baseline) must finish before T005.
- T004 must finish before T007.
- T005 must finish before T006, T008, T009 and T010, because the order and the tags come from `index.yml`.
- T006 to T010 must finish before T011, then T012.
- T012 must finish before T013 and T014, then T016.
- T015 is independent.

## Effort

17 tasks, 18 SP against the 20 SP iteration cap. The prompt 1 ruling keeps the effort whole, and T017 was added at the tasks verdict. Proposal 220 estimated 10 to 15 SP. The overshoot is T001/T002, the sweep and self-test machinery the maintainer specified at the plan verdict.

## Iteration 002 tasks (Amendment A1, Option A)

Plan: the "Iteration 002 plan" section of `plan.md` (approved 2026-11-13). Format as above. The lens catalog is
`extensions/specrew-speckit/knowledge/design-lenses/`. Every test run is out of process, on a committed tree, with the
home hook files hashed before and after; nothing on the never-run list is run.

### Phase 5: Proof first (red before green)

- [x] T018 [US6] [assigned_to: implementer] [effort: 4] Write `tests/unit/workshop-length-budget.tests.ps1` (script-style) with two checks over the lens files and `applicability-map.json`. (a) Length: for the reference profile (product-domain, the agenda, the three always-on lenses, code-implementation, security-compliance, data-storage, integration-api), compute must-answer points, minimum typed replies and recommendation lines at Light, Standard and Deep from each question's suffix; fail when Light exceeds 51 points or 18 replies, and fail when any other number differs from its recorded value in the test. (b) Consumers: every suffix names an existing `## Problem Context` line in the spec template or an existing lens, every hand-forward names a product-domain area key, and every recommendation has a reason. Self-tests over scratch fixtures prove each failure, report every problem in one run, and accept the valid suffix forms from the plan. Run it on today's tree and record the red output in `iterations/002/quality/quality-evidence.md` (Trace: FR-028, FR-029, SC-007, SC-008)

### Phase 6: The questions

- [x] T019 [US6] [assigned_to: implementer] [effort: 2] product-domain: add the six facts (area keys `compliance_regime`, `data_residency`, `carry_over`, `platform_constraints`, `operators`, `budget`) to `product-domain.md`'s decision areas and its Light/Standard/Deep content. The compliance regime is asked at every depth with no default (the named regulation or "none"). The other five are recommendation lines at Light with their defaults ("not stated" where nothing shows; operators never guessed) and questions at Standard and Deep. Each carries the suffix (Trace: FR-023, FR-027, SC-009)
- [x] T020 [US6] [assigned_to: implementer] [effort: 2] Hand-forward lines in requirements-nfr, security-compliance, data-storage, integration-api, devops-operations and observability-resilience, per the plan's six-fact table: each is a recommendation line naming its product-domain area key, shown as "product-domain: <answer>" or "product-domain: not stated" (Trace: FR-024, SC-009)
- [x] T021 [US6] [assigned_to: implementer] [effort: 3] Add the twelve FR-025 questions under their lenses' `### Problem questions`, each with its suffix: the recommended answer and reason from the plan's table, and its consumer. Do not add the six questions that repeat product-domain (Trace: FR-025, FR-026, FR-029, SC-008, SC-010)
- [x] T022 [US6] [assigned_to: implementer] [effort: 2.5] Light/Standard/Deep content for each touched lens (product-domain, requirements-nfr, ui-ux, security-compliance, data-storage, integration-api, devops-operations, observability-resilience): Light asks today's questions and shows the added items as recommendation lines; Standard asks them; Deep as Standard (Trace: FR-027)
- [x] T023 [US6] [assigned_to: implementer] [effort: 1.5] Workshop skill source `extensions/specrew-speckit/squad-templates/skills/design-workshop.md`: each lens's recommendations are shown once as one list closed by one reply, never one prompt per line; "accept" closes a lens whose open items are all recommendations; product-domain asks the compliance regime at every depth (Trace: FR-026, FR-023)
- [x] T024 [US6] [assigned_to: implementer] [effort: 1] Spec template source `templates/specify/templates/spec-template.md`: add `## Problem Context` with one named line per consumer in the plan's tables. The consumer test reads the source. The deployed copy `.specify/templates/spec-template.md` is refreshed only if one of the two project-only deploy scripts writes it; if only `specrew update` does (on the never-run list), leave the copy, record it in the drift log and say so at the review stop (Trace: FR-029)

### Phase 7: Green, regression and evidence

- [ ] T025 [US6] [assigned_to: implementer] [effort: 2] Refresh the deployed copies with the two project-only deploy scripts; bring `workshop-length-budget.tests.ps1` to green with the tested numbers recorded in it and in the plan; run the iteration 001 parity, tagging and agenda tests (the extractor counts change by exactly the added questions, SC-010) and every existing workshop test against the iteration 001 results; add the new test as a named `specrew-ci.yml` step (Trace: FR-025, FR-028, SC-007, SC-010)
- [ ] T026 [US6] [assigned_to: implementer] [effort: 2] Last: one recorded Light workshop run on a small sample feature in a scratch project under the session temp folder (never this worktree; deployed copies only through the two project-only deploy scripts; no `specrew init` or `specrew start`; home hashed before and after). A Light pass through product-domain and two touched lenses, with the maintainer typing the replies. Keep the transcript as evidence in `iterations/002/quality/`. If the setup needs anything on the never-run list, stop and ask (Trace: SC-012)

### Iteration 002 dependencies

- T018 first, red on today's tree, before any lens change.
- T019 before T020 (the hand-forward names product-domain's keys).
- T019 to T022 before T025; T023 and T024 before T025.
- T025 before T026 (the recorded run uses the shipped lens files).

### Iteration 002 effort

9 tasks, 20 SP against the 20 SP cap. The review-signoff crossing is not planned capacity (maintainer, 2026-11-13;
iteration 002 DRIFT-004). FR-030 and FR-031 are iteration 003.
