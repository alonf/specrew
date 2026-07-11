# Tasks: 0.40.0-beta2 Hardening Bundle

**Feature**: 198-beta2-hardening
**Plan**: file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/plan.md
**Date**: 2026-07-10
**Effort unit**: story points (feature envelope ~25 SP across four iterations)

Tasks are feature-globally numbered. Iteration 001 is decomposed to
execution grain (approved design Option B); iterations 002–004 carry
planned-grain tasks that keep FR traceability complete and are refined at
each iteration's own design-analysis before execution.

## Iteration 001 — Substrate + firewall-first (5.0 SP)

### Phase 1 — toolchain substrate

- [x] T001 [owner: Implementer] [sp: 0.5] **Spec-Kit 0.12.9 scratch probe** — flag survey on the 0.12.9 CLI in a scratch dir (`--integration` key set incl. the copilot key; `--script ps`; `--ignore-agent-tools`), extension.yml hooks-schema load check, git/agent-context opt-in behavior notes; evidence recorded at `iterations/001/quality/toolchain-probe-evidence.md` (Trace: FR-038, SC-012; owns: probe evidence file only — no product code)
- [x] T002 [owner: Implementer] [sp: 1.0] **Spec-Kit migration + pin surfaces** — `scripts/specrew-init.ps1` `--ai copilot` → `--integration <key>`; pins updated together: CI env `SPEC_KIT_VERSION`, `scripts/internal/version-check.ps1` supported-versions, `extensions/specrew-speckit/extension.yml` requires/min_speckit + `.specify` mirror, `Get-SpecKitGitReference`; integration suites green on a no-extensions 0.12.9 fixture; opt-in extension added ONLY on demonstrated dependency with evidence (Trace: FR-038, SC-012; owns: `scripts/specrew-init.ps1`, pin surfaces, `tests/integration/**`; depends: T001)
- [x] T003 [owner: Implementer] [sp: 0.5] **Squad 0.11.0 bump** — `scripts/internal/dependency-install.ps1` minimum, CI `SQUAD_VERSION`, `validate-versions.ps1` defaults; scratch-dir `squad init --non-interactive` probe; `.squad` layout suites green (Trace: FR-039, SC-012; owns: `scripts/internal/dependency-install.ps1`, CI env, `scripts/internal/validate-versions.ps1`)

### Phase 2 — the firewall

- [x] T004 [owner: Implementer] [sp: 1.0] **SelfLeakDenyList data file** — `extensions/specrew-speckit/data/self-leak-deny-list.json`: `schema_version` + proposal-205 seed across the seven classes (release-model, dev-path, feature-id, maintainer-id, registry, repo-ref, decision-ref); Specrew.psd1 FileList; schema/entry-shape validation tests + annotation-semantics cases (md HTML comment; ps1/psd1/yml `#` comment; same-line + line-above; missing reason = unannotated) (Trace: FR-037, SC-011; owns: `extensions/specrew-speckit/data/self-leak-deny-list.json`, `Specrew.psd1`, `tests/unit/**`)
- [x] T005 [owner: Implementer] [sp: 1.5] **Self-leak lint + blocking CI job** — `scripts/internal/lint-self-leak.ps1`: scan surface DERIVED from the deploy-manifest source (enumeration test asserts surface == deploy allowlist) + deployed-script string literals; exit-code contract 0/1/2 (2 = unreadable list, fails loud); red output names file/term/class/escape/rule-doc; paired fixtures per class (seeded red / annotated green-with-reason / clean green); blocking job wired into the Specrew CI workflow (Trace: FR-033, SC-011, NFR-007; owns: `scripts/internal/lint-self-leak.ps1`, `.github/workflows/specrew-ci.yml`, `tests/unit/**`; depends: T004)
- [x] T006 [owner: Implementer] [sp: 0.5] **Parameterization rule doc** — the abstract-rule + resolution-point teaching (205-W2) as a methodology doc section; T005's red output points at it (pointer asserted in the T005 fixtures) (Trace: FR-034; owns: `docs/methodology/**`; depends: T005)

## Iteration 002 — Governance correctness core (7.0 SP, planned grain)

- [x] T007 [owner: Implementer] [sp: 1.5] **Boundary ratchet + shared primitive** — resurrect `Test-SpecrewBoundaryAuthorization` as the delta check; sync refuses a second unapproved advance (loud, names boundary + both doors); validator FAIL finding on unreconciled skip; hooks stay surfacing-only (Trace: FR-001, FR-002, FR-003, FR-006, SC-001; owns: `extensions/specrew-speckit/scripts/shared-governance.ps1` + mirror, `scripts/internal/sync-boundary-state.ps1`)
- [x] T008 [owner: Implementer] [sp: 1.5] **Reconciliation flows** — retroactive approval (recorded distinctly) and revert-to-AuthCommitHash after explicit confirm; honest-limit teaching in refusal + packet text (Trace: FR-005, FR-007, SC-001; owns: sync + refocus/packet content)
- [x] T009 [owner: Implementer] [sp: 0.5] **Resume/start re-confirm surface** — skipped-boundary state surfaces as awaiting-verdict re-confirm independent of inline hook output (Trace: FR-004; owns: resume/start reconciliation path)
- [x] T010 [owner: Implementer] [sp: 2.0] **Tracker honesty check (gate-level bypass)** — deterministic claims-subset comparison vs accepted review + run records; fail-closed on parse; announce granted bypass; paired tests reconcile-toward-truth / falsify-forward (Trace: FR-020, SC-005, NFR-007; owns: digest/gate path in shared governance + signoff gate)
- [x] T011 [owner: Implementer] [sp: 1.0] **Catalog budgets + downgrade warning + timeout teaching** — `default_timeout_seconds` column (antigravity 900, claude 600); resolution explicit→config→catalog→600 floor; W14 warning off the RESOLVED value; timeout records teach the human-typed doors; codex 600 / copilot 300 rows added from iteration-001 SELF-HOST timing evidence (maintainer-approved deviation at the 002 design-analysis: the recorded Human Decision accepted self-host measurements in place of the consumer-test-project run) (Trace: FR-021, FR-022, SC-006; owns: `reviewer-host-catalog.ps1`, budget resolution, teaching text)
- [x] T019a [owner: Implementer] [sp: 1.0] **Stale-verdict surfacing (pulled forward from T019, maintainer-approved 2026-07-11)** — reviewed_tree_id stamped into findings-result via the blackboard route; the navigator digest-matches before blocking (both ids known + differing -> the verdict surfaces as ADVISORY stale-vs-current, never a fresh stop-block; unknown ids keep blocking, fail-closed) (Trace: FR-017; owns: continuous-co-review-navigator.ps1)
- [x] T012 [owner: Implementer] [sp: 0.5] **Live-door independence defaulting** — `--list-hosts` env cascade applied to `--live`; `independence_source` recorded; SEC-004 unchanged (Trace: FR-023; owns: live-door resolution + run record)

## Iteration 003 — Reviewer containment + round economy (8.0 SP planned grain + capture-integrity addendum 2.75 SP + Devin-integration T034 0.75 SP, both provisional, sized at 003 design-analysis)

- [x] T013 [owner: Implementer] [sp: 1.0] **Worktree relocation** — materialize outside origin root (system temp); upward-walk cannot resolve origin (Trace: FR-008, SC-002; owns: worktree materialization)
- [x] T014 [owner: Implementer] [sp: 1.0] **Bundle origin-path hygiene** — strip/relativize origin-absolute paths from reviewer-visible context (Trace: FR-009, SC-002; owns: bundle builder)
- [x] T015 [owner: Implementer] [sp: 0.5] **Confinement contract + stripped-paths teaching** — slim prompt + spawn contract carry worktree-only rules and the what-is-absent teaching (Trace: FR-010, FR-013; owns: `Get-ContinuousCoReviewSlimPrompt`, `reviewer-spawn-contract.md`)
- [ ] T016 [owner: Implementer] [sp: 1.0] **Containment detector** — T100-registry cwd/commandline sampling; `containment-violated` loud fail; origin-side record; never mid-flight kill; false-kill guard test (Trace: FR-011, SC-003, NFR-007; owns: process-registry watch path)
- [ ] T017 [owner: Implementer] [sp: 1.5] **ONE machinery list, both strips** — path-granular list per S2; digest strip == worktree strip by construction; reviewer-can-still-see-it regression per exclusion (Trace: FR-012, SC-004, NFR-007; owns: machinery list data file, digest + worktree strip consumers)
- [ ] T018 [owner: Implementer] [sp: 1.0] **Recorded-run evidence wrapper** — `Invoke-ContinuousCoReviewRecordedTestRun` runs Pester `-PassThru` itself; caller-supplied numbers rejected/labeled; refocus duty line (W7 floor) (Trace: FR-014, FR-015, NFR-007; owns: evidence recorder + refocus content)
- [ ] T019 [owner: Implementer] [sp: 1.5] **Checkpoint baselines + frozen digest + stale-verdict surfacing** — last-REVIEWED identity threaded as next baseline (merge-base fallback); fire-time tree id through the detached chain AND stamped into every run record surface incl. findings-result; the navigator digest-matches before blocking (stale verdicts surface as stale-vs-current advisory, never fresh blocks); in-flight dedup per lineage (clarify 2026-07-11, Devin-crew field diagnosis); SHARPENED by the second Devin field report (run da2bc5cc): obsolete in-flight results rejected/superseded, findings bound to reviewed tree AND baseline, and MIXED runs distinguish stale replays from still-valid findings per-finding — their forensics arrive as fixture data (Trace: FR-016, FR-017; owns: navigator + detached entry + run record writers)
- [x] T020 [owner: Implementer] [sp: 1.0] **Review-loop spend allowance UX + two-budget accounting** — consumer-legible allowance-halt text (spend-guard explanation, N-of-M rounds, exact human-typed reset command, resolved-vs-open state computed from the disposition trail); every round that actually reviewed counts (clarify 2026-07-10 supersedes the no-increment design). SEPARATE two budgets that the second Devin field report proved were conflated (provider spend = actual model/API cost; review-round allowance = the autonomous-round ceiling): (a) PREFLIGHT detects a missing input (e.g. absent `changes.diff`) BEFORE model invocation → infrastructure failure that consumes NEITHER provider budget NOR round allowance; (b) a model that WAS invoked records its ACTUAL provider spend even when no valid review resulted; (c) such a post-invocation failure DOES consume a round-allowance slot, recorded with a distinct `failed-invocation` disposition — it never disappears from accounting. Paired tests prove BOTH: preflight prevents invocation when `changes.diff` is absent (no spend, no round), and a post-invocation failure stays visible in spend telemetry with its round counted; message-content test asserts zero Specrew-internal identifiers in the halt (Trace: FR-018, FR-019, SC-007, NFR-007; owns: ceiling governor + halt text + preflight input check + spend/round telemetry)
- [ ] T030 [owner: Implementer] [sp: 0.75 provisional, resized at 003 design-analysis] **Machinery-turn exclusion from verdict evidence** — hook-injected/machinery-generated transcript turns (Stop-hook blocking feedback, injected governance text) are never verdict evidence regardless of role labeling; paired test: same text as genuine human turn captures, as hook feedback does not (Trace: FR-041, NFR-007; owns: `ConversationCaptureAccessor.ps1` turn reader)
- [ ] T031 [owner: Implementer] [sp: 0.5 provisional, resized at 003 design-analysis] **Approval-tokenizer tightening** — approval-shaped mention/quote/teach text ("if you already approved…") never parses as a verdict; only an actual verdict utterance authorizes; abuse-path message-content tests (Trace: FR-042, NFR-007; owns: `Test-SpecrewHumanVerdictToken` + fallback capture guards)
- [ ] T032 [owner: Implementer] [sp: 0.5 provisional, resized at 003 design-analysis] **Fabrication-sequence regression fixtures** — reproduce the exact 2026-07-11 sequence (rendered packet → Stop-hook feedback as user-role turn → no human reply) and assert capture records nothing (no entry, no artifact consumption) (Trace: FR-043, NFR-007; owns: `tests/integration/verdict-capture-blocks.tests.ps1` fixture set)
- [ ] T033 [owner: Implementer] [sp: 1.0 provisional, resized at 003 design-analysis] **Ledger correction door (append-only invalidation)** — designed mechanism appends an invalidation/correction record (original entry identity, correcting authority, reason, timestamp, resulting boundary state); effective-state readers honor invalidations; human-approval-bound per the approvals-bind-the-decision doctrine (Trace: FR-044, NFR-002; owns: `shared-governance.ps1` ledger surface + mirror)
- [ ] T034 [owner: Implementer] [sp: 0.75 provisional, resized at 003 design-analysis] **Devin-crew shared-engine integration + compat/regression verification (maintainer-instructed, 2026-07-11)** — inspect and reuse/cherry-pick the Devin design-context validation work from branch `200-devin-cli-host` (precursors a697cefe, ec90e1b6; the STRICT-RESOLUTION fix `cca79708` — worktree-reviewer.ps1, specrew-review.ps1, co-review-service.ps1, reviewed-state-digest.ps1, worktree-review-orchestrator.ps1), never reimplement. The strict fail-before-reviewer-selection behavior for EXPLICITLY-supplied unresolved design-context refs (`design-context-unresolved:` listing every unresolved ref; status `unresolved_design_context`; only omitted/empty keeps the `DESIGN_CONTEXT_EMPTY` degrade) is LOAD-BEARING and MUST be preserved — never softened to a warn; paired tests mirror their 7f/7g (mixed valid+invalid and all-invalid → reviewer never invoked). Then run the co-review engine regression set + a live round as compatibility verification because both crews touch the shared machinery; ec90e1b6's exec-bit restoration is verified against the DRIFT-198-I001-001 materialization class; SEMANTIC conflicts touching containment/authorization/evidence/fail-closed ESCALATE to the maintainer, never auto-resolved (Trace: FR-012, FR-017, NFR-006; owns: `scripts/internal/continuous-co-review/**` integration surface, `tests/continuous-co-review/**`)

## Iteration 004 — Distribution + release (5.5 SP, planned grain)

- [ ] T021 [owner: Implementer] [sp: 0.75] **Methodology gate template + provider-keyed deploy** — `specrew-methodology-gate.yml` (markdownlint F-033 set + deployed-path validator full run + conditional PSSA; generic triggers; advisory-first; action pins by major); deployed only for recorded provider github/unset (Trace: FR-024, FR-031, SC-008; owns: `templates/github/workflows/**`, installer)
- [ ] T022 [owner: Implementer] [sp: 0.25] **Work-kind template path fix** — deployed validator location; advisory default kept (Trace: FR-025; owns: `templates/github/workflows/specrew-work-kind.yml`)
- [ ] T023 [owner: Implementer] [sp: 0.75] **Deploy-list surgery (deny-by-default)** — only the consumer-ized set deploys; self-host lanes move to `.github/workflows/`; distribution assertions updated (Trace: FR-026; owns: `scripts/internal/distribution-module-init.ps1`, `templates/**`, `.github/workflows/**`)
- [ ] T024 [owner: Implementer] [sp: 0.25] **Gitignore deployed local host config** (Trace: FR-027; owns: init gitignore surface)
- [ ] T025 [owner: Implementer] [sp: 0.75] **Update heal: retired templates + refocus-scopes sync** — hash-guarded removal (user-modified → WARN); `refocus-scopes.json` synced into existing `.specify` (closes #2903) (Trace: FR-028, FR-032, SC-009; owns: F-116 heal surface)
- [ ] T026 [owner: Implementer] [sp: 0.5] **Bootstrap commit** — greenfield auto `chore(specrew): bootstrap scaffold` announced; brownfield explicit recorded offer (Trace: FR-029, SC-008; owns: init tail)
- [ ] T027 [owner: Implementer] [sp: 1.0] **Release-model resolver + closeout teaching** — governance-file-else-inference; closeout renders ONLY applicable steps + names N/A reasons; beta-before-stable scoped to publish targets; init records model ask-once; lifecycle template line fixed (Trace: FR-030, SC-010; owns: `shared-governance.ps1` resolver + closeout rendering + `templates/lifecycle/software-feature-lifecycle.md`)
- [ ] T028 [owner: Implementer] [sp: 0.5] **Consumer-side deny checks + prompt fixture + inoculation** — gateway advisory + update heal read the shipped list (flag-only user files; rewrite hash-verified Specrew-owned); `PromptFixtureTest` renders all prompt surfaces vs anything-but-Specrew fixture, zero hits; refocus inoculation line deployed (Trace: FR-035, FR-036, SC-011; owns: gateway advisory step, heal surface, `tests/**`, refocus content)
- [ ] T029 [owner: Implementer] [sp: 0.75] **Release v0.40.0-beta2** — seven-surface pre-tag deterministic check via extended `validate-versions.ps1`; `psgallery-release-credentials.md` rewritten to auto-publish reality; tag `v0.40.0-beta2` (ModuleVersion 0.40.0, Prerelease beta2) (Trace: FR-040, SC-013; owns: manifests, CHANGELOG, README, docs/operations, tag)

## Bidirectional traceability (tasks ↔ requirements)

| FR | Tasks | | FR | Tasks |
| --- | --- | --- | --- | --- |
| FR-001..003, FR-006 | T007 | | FR-020 | T010 |
| FR-004 | T009 | | FR-021, FR-022 | T011 |
| FR-005, FR-007 | T008 | | FR-023 | T012 |
| FR-008 | T013 | | FR-024, FR-031 | T021 |
| FR-009 | T014 | | FR-025 | T022 |
| FR-010, FR-013 | T015 | | FR-026 | T023 |
| FR-011 | T016 | | FR-027 | T024 |
| FR-012 | T017 | | FR-028, FR-032 | T025 |
| FR-014, FR-015 | T018 | | FR-029 | T026 |
| FR-016, FR-017 | T019 | | FR-030 | T027 |
| FR-018, FR-019 | T020 | | FR-035, FR-036 | T028 |
| FR-033 | T005 | | FR-040 | T029 |
| FR-034 | T006 | | FR-037 | T004 |
| FR-038 | T001, T002 | | FR-039 | T003 |
| FR-041 | T030 | | FR-042 | T031 |
| FR-043 | T032 | | FR-044 | T033 |

Every FR-001..FR-044 has ≥1 task; every task traces to ≥1 FR. NFR-001..007
are cross-cutting and ride every honesty-invariant task as the paired-test
and message-content shape (NFR-007 explicitly tagged on T005, T010, T016,
T017, T018, T020). SC-014 (fresh consumer E2E on published beta2 bits) is
the maintainer's manual stable-promotion gate input — post-feature by
design (clarify 2026-07-09), deliberately not a task.

## Dependencies & parallel safety

- T001 → T002 (probe before migration); T004 → T005 → T006 (list before
  lint before doc-pointer assert). T003 is independent.
- Iterations execute serially (002 needs 001's substrate; 003 needs the
  lint live; 004 converges deploy surgery + release).
- T030/T031 precede T032 (the fixtures assert both guards); T033 is
  independent. The T030-T033 addendum (DEC-198-GOV-001) is sized at 003
  design-analysis and never silently displaces containment (T013-T017)
  or T020 — maintainer instruction, retro verdict 2026-07-11.
- T034 (Devin-crew integration, maintainer-instructed at the 003
  planning approval) is timing-gated on their forthcoming commit landing;
  its placement relative to T013-T017 is an explicit 003 design-analysis
  decision because both crews touch worktree-reviewer.ps1 and the digest
  surfaces. Traceability: T034 -> FR-012/FR-017 verification surface.
- Single-implementer serial execution within iterations; no same-specialty
  parallelism proposed (per the iteration plan's concurrency rationale —
  shared-surface risk on `shared-governance.ps1` and the deploy manifest).
- Iterations 002–004 task grain is refined at each iteration's
  design-analysis before execution; FR coverage above stays the floor.
