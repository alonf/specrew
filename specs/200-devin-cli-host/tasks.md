# Tasks: Devin CLI Host — Clean-Extensibility Proof

**Feature**: 200-devin-cli-host
**Plan**: plan.md
**Design-analysis verdict**: approved for plan with Option B
**Total Capacity**: 45 story_points
**Iteration Capacity**: 20 story_points maximum

## Format

`- [ ] T### [I###] [US#] [Owner: role] [Capacity: N SP] Deliverable and acceptance criteria (Trace: FR/SC)`

Tasks are serial unless marked `[P]` and their owner file globs do not overlap.
Approval of this backlog does not authorize implementation. Iteration 001
requires a separate tasks-to-before-implement verdict; Iterations 002 and 003
require their own iteration planning and before-implement gates.

## Iteration 001 — Abstraction Foundation (14/20 SP)

**Goal**: Prove the handover path and remove the first three shared host
couplings before the Devin package lands.

**Independent test**: registry validation, generated host package membership,
purity firewall, and FileList-faithful prepublish checks pass without a Devin
package or new allow-list entry.

- [x] T001 [I001] [US4] [Owner: Planner, Reviewer] [Capacity: 3 SP] Complete and preserve the pinned-build Devin Stop/export spike in `specs/200-devin-cli-host/iterations/001/research/devin-stop-payload-spike.md`; prove Stop lacks an assistant message, ATIF is written before Stop, a scratch normalizer emits the existing Claude-like JSONL shape, and the unchanged `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1` captures both canary turns (Trace: FR-011, FR-012, SC-008).
- [x] T002 [I001] [US2] [Owner: Implementer] [Capacity: 2 SP] Add one reusable registry-backed host-kind validator in `hosts/_registry.ps1` and replace the hardcoded host `[ValidateSet]` boundaries in `scripts/specrew-start.ps1`, `scripts/internal/host-flag-translation.ps1`, and `scripts/internal/coordinator-prompt-surgery.ps1`; tests must cover registered, differently-cased, and unknown input with actionable current-catalog guidance (Trace: FR-001, FR-004, SC-002).
- [ ] T003 [I001] [US2] [Owner: Implementer] [Capacity: 3 SP] Implement deterministic host-package FileList derivation and generate/check behavior in a focused generic helper under `scripts/internal/`, update `hosts/_contract.md`, and compose the generated segment into `Specrew.psd1`; tests must reject missing required package files, stale/duplicate/escaping paths, prove ordinal Windows/Unix path determinism, and prove a fixture host is packaged without editing an independent host list (Trace: FR-002, SC-004).
- [ ] T004 [I001] [US2] [Owner: Implementer, Reviewer] [Capacity: 3 SP] Extend `tests/integration/host-coupling-firewall.tests.ps1` with the permanent host-addition purity scan, generated-artifact exemptions, allow-list non-growth assertion, and same-scanner planted-literal/clean-content tests; remove the three validator exceptions and add no host exception (Trace: FR-003, FR-004, SC-002, SC-003, SC-012).
- [ ] T005 [I001] [US2, US5] [Owner: Implementer, Reviewer] [Capacity: 2 SP] Wire registry/manifest, FileList generation parity, purity firewall, and FileList-faithful package checks into the applicable jobs in `.github/workflows/specrew-ci.yml`, `.github/workflows/cross-platform-validation.yml`, `.github/workflows/publish-module.yml`, and `scripts/internal/test-publish-harness.ps1`; preserve existing workflow behavior and test generic path/argument handling on Windows and Unix (Trace: FR-019, SC-010).
- [ ] T006 [I001] [US2, US4] [Owner: Reviewer, Spec Steward] [Capacity: 1 SP] Record Iteration 001 requirement evidence and diff classification under `specs/200-devin-cli-host/iterations/001/`; rerun focused governance/package/firewall checks, verify all three exceptions are gone, generated output is reproducible, and `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1` has no diff (Trace: FR-012, SC-002, SC-012).

## Iteration 002 — Devin Package and Handover (15/20 SP)

**Goal**: Add the complete experimental Devin package, governed lifecycle, and
full handover without host-specific shared routing.

**Independent test**: a disposable project launches the pinned Devin CLI,
deploys package-owned runtime assets, fires lifecycle hooks, and captures a
real handover through the unchanged parser.

- [ ] T007 [I002] [US1, US6] [Owner: Implementer] [Capacity: 3 SP] Add `hosts/devin/host.psd1`, `hosts/devin/handlers.ps1`, `hosts/devin/coordinator-rules.psd1`, package-private adapter assets, tested-build metadata, compatibility-monitor metadata, and Spec Kit integration identifier; registry, manifest, handler, and package validation must pass through existing five-handler dispatch with experimental status and no sixth handler slot (Trace: FR-005, FR-006, FR-010, SC-004).
- [ ] T008 [I002] [US1, US5] [Owner: Implementer] [Capacity: 4 SP] Implement the five Devin handlers for interactive positional-prompt launch, `auto`/`smart`/`dangerous` permission translation with dangerous precedence/notice, runtime detection/signals, root `AGENTS.md`, `.devin/skills/` plus shared `.agents/skills/`, and `.devin/agents/<name>/AGENT.md` Crew deployment; preserve existing hosts and keep `devin -p` canary-only (Trace: FR-007, FR-008, FR-016, FR-018, SC-005).
- [ ] T009 [I002] [US1, US5] [Owner: Implementer, Reviewer] [Capacity: 3 SP] Add the single focused generic hook-integration seam needed for a manifest-selected package-local event adapter and root-level direct event-map merge/remove/status behavior in `hosts/_contract.md`, `scripts/internal/deploy-refocus-hooks.ps1`, the generic launcher/health owners, and focused tests. Acceptance criteria: (a) the shared seam is host-neutral and contains no hand-authored Devin/Windsurf literal; the firewall scans the seam and its same-scanner negative test detects a planted host-specific literal there; (b) every host declaring no adapter follows byte/argv/output-equivalent pre-feature behavior, proven by a no-adapter regression fixture; (c) user hook rows survive install/remove and malformed JSON is never overwritten; no parallel shared adapter path is added (Trace: FR-003, FR-009, FR-016, FR-018, SC-003, SC-005, SC-009, SC-012).
- [ ] T010 [I002] [US4, US5] [Owner: Implementer, Reviewer] [Capacity: 3 SP] Implement the ATIF-to-existing-JSONL normalizer and Stop enrichment inside `hosts/devin/`; use controlled fixed paths under `.specrew/runtime/`, atomic bounded writes, accepted `source=user|agent` string-message steps, and bounded reason codes; tests must prove the unchanged handover provider/parser captures user, assistant, Unicode, and boundary-packet canaries while logs/fixtures expose no full transcript or credentials (Trace: FR-011, FR-012, FR-017, SC-007, SC-008, SC-009, SC-012).
- [ ] T011 [I002] [US1, US6] [Owner: Implementer, Reviewer] [Capacity: 2 SP] Attempt the host-neutral Windows hook command form that invokes `pwsh` directly and validate it on the pinned CLI; if the host still requires `sh.exe`, retain experimental status, document the Git Bash prerequisite and bounded reason, and add no host-specific core branch. Complete Iteration 002 launch/hook/handover regression evidence (Trace: FR-006, FR-009, FR-018, FR-021, SC-005, SC-007).

## Iteration 003 — Coordinator Migration, Compatibility, and Promotion (16/20 SP)

**Goal**: Complete the five-entry coupling cleanup, migrate existing projects,
and collect release-quality compatibility and documentation evidence.

**Independent test**: all four managed-agent input shapes converge in one
update run, all five prior hosts remain green, the firewall has removed all five
entries, and the pinned Devin run satisfies the promotion matrix.

- [ ] T012 [I003] [US2, US3] [Owner: Implementer] [Capacity: 3 SP] Add backward-compatible manifest coordinator eligibility/default fields and a registry descriptor query, migrate existing host manifests, and replace hardcoded coordinator catalogs in `scripts/init/agent-detection.ps1` and `scripts/specrew-init.ps1`; remove the final two firewall exceptions and prove eligibility is not derived from status (Trace: FR-004, FR-013, SC-002, SC-004).
- [ ] T013 [I003] [US3] [Owner: Implementer, Reviewer] [Capacity: 4 SP] Implement ownership-safe managed `agents:` projection/migration for init, update, start, and start-heal paths using focused generic helpers; absent, legacy-three-host, partial, and current fixtures must preserve mutable values/unrelated YAML, add eligible hosts, remove only managed ineligible rows, set Devin to disabled plus `host_process` unless selected, converge in one run, and be byte-idempotent on the second run (Trace: FR-014, FR-015, FR-016, SC-006).
- [ ] T014 [I003] [US2, US5] [Owner: Implementer, Reviewer] [Capacity: 3 SP] Run and extend the full existing-host compatibility, registry, launch, hooks, instructions, Crew, coordinator, package, transcript-golden, FileList-faithful prepublish, and Windows/Unix CI lanes; failures must identify the owning host/capability without weakening the firewall or parser boundary (Trace: FR-018, FR-019, SC-005, SC-009, SC-010).
- [ ] T015 [I003] [US6] [Owner: Spec Steward, Reviewer] [Capacity: 2 SP] Update `README.md`, host/user docs, architecture/add-host guidance, test docs, changelog/release notes, and `proposals/194-*`; document Devin's exact tested build and fragile launch/hook/Stop/ATIF/handover surfaces, make future monitoring inventory registry/manifest-driven, and do not implement a scheduled monitor (Trace: FR-020, SC-011).
- [ ] T016 [I003] [US1, US4, US6] [Owner: Reviewer] [Capacity: 3 SP] Run the complete prerelease real-host matrix on `devin 2026.7.23 (3bd47f77)` for interactive start, permission translation, SessionStart, UserPromptSubmit, Stop enforcement, user-hook preservation, export ordering, normalized handover, Windows constraint, OS, mechanism, result, and bounded reason codes; permit one recorded transient retry only and promote to supported only on complete PASS evidence (Trace: FR-006, FR-011, FR-017, FR-021, SC-001, SC-007, SC-008).
- [ ] T017 [I003] [US2, US6] [Owner: Spec Steward, Reviewer] [Capacity: 1 SP] Complete feature-closeout diff classification and follow-up recording: prove Devin-specific production logic exists only under `hosts/devin/`, shared edits are generic, all five allow-list entries are gone, generated FileList output is reproducible, the accessor is untouched, and a separate arbitrary multi-version update-validation proposal/PR remains required but is not authored or implemented here (Trace: FR-004, FR-012, FR-022, SC-002, SC-012).

## Dependencies and Execution Order

- T001 is complete and gates the handover mechanism used by T007–T011.
- Iteration 001 executes T002 → T003 → T004 → T005 → T006 serially because
  registry, packaging, firewall, workflow, and evidence surfaces overlap.
- Iteration 002 starts only after Iteration 001 closes. T007 precedes T008–T10;
  T009 defines the only shared hook integration seam, T010 consumes it, and T011
  closes the real Windows compatibility question.
- Iteration 003 starts only after Iteration 002 closes. T012 precedes T013; T014
  follows the migration; T015 may proceed in parallel with T14 only after paths
  are final; T016 follows all runtime changes; T017 is last.
- No task may edit
  `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1`.

## Capacity Check

| Iteration | Task Sum | Cap | Status |
| --- | ---: | ---: | --- |
| 001 | 3 + 2 + 3 + 3 + 2 + 1 = 14 | 20 | ok |
| 002 | 3 + 4 + 3 + 3 + 2 = 15 | 20 | ok |
| 003 | 3 + 4 + 3 + 2 + 3 + 1 = 16 | 20 | ok |
| **Feature** | **45** | **60 across three iterations** | **ok** |

No unused capacity automatically pulls a later task into an earlier iteration.
Scope movement requires an explicit human re-baseline.

## Bidirectional Traceability Check

**Verdict**: PASS
**Coverage**: 34/34 authoritative FR/SC items covered; 17/17 tasks have valid
FR/SC authority, owner, story, effort, and iteration metadata.

### FR → Tasks

| Requirement | Tasks |
| --- | --- |
| FR-001 | T002 |
| FR-002 | T003 |
| FR-003 | T004, T009 |
| FR-004 | T002, T004, T012, T017 |
| FR-005 | T007 |
| FR-006 | T007, T011, T016 |
| FR-007 | T008 |
| FR-008 | T008 |
| FR-009 | T009, T011 |
| FR-010 | T007 |
| FR-011 | T001, T010, T016 |
| FR-012 | T001, T006, T010, T017 |
| FR-013 | T012 |
| FR-014 | T013 |
| FR-015 | T013 |
| FR-016 | T008, T009, T013 |
| FR-017 | T010, T016 |
| FR-018 | T008, T009, T011, T014 |
| FR-019 | T005, T014 |
| FR-020 | T015 |
| FR-021 | T011, T016 |
| FR-022 | T017 |

### SC → Tasks

| Criterion | Tasks |
| --- | --- |
| SC-001 | T016 |
| SC-002 | T002, T004, T012, T017 |
| SC-003 | T004, T009 |
| SC-004 | T003, T007, T012 |
| SC-005 | T008, T009, T011, T014 |
| SC-006 | T013 |
| SC-007 | T010, T011, T016 |
| SC-008 | T001, T010, T016 |
| SC-009 | T009, T010, T014 |
| SC-010 | T005, T014 |
| SC-011 | T015 |
| SC-012 | T004, T006, T009, T010, T017 |

### Task → Authority

Every task T001–T017 carries at least one valid FR and one SC where observable
acceptance evidence exists. No orphan task, stale reference, or uncovered FR/SC
remains.

## Before-Implement Readiness Inputs

- Iteration 001 implementation scope is T002–T006 only; T001 is completed
  planning research.
- The hardening gate at
  `specs/200-devin-cli-host/iterations/001/quality/hardening-gate.md` must be
  `ready` before implementation authorization.
- T009's two sharpened acceptance criteria are binding but do not authorize
  Iteration 002 work. They must be repeated in Iteration 002's hardening gate.
- Governance, markdown, capacity arithmetic, and bidirectional traceability
  must pass on the committed tree.
