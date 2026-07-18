# Iteration Plan: 008 — Beta2 Finish Line

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 18/26 story_points
**Started**: 2026-07-18
**Completed**:
**Planning Baseline**: `ec2287c0b950ceb78522f3b5aae8dd94d4710a88`

## Planning Authority and Boundary

The human verdict authorizes planning only and binds this iteration to the actual Iteration 007 closeout commit
`ec2287c0b950ceb78522f3b5aae8dd94d4710a88`. The pending crossing record that cited `744e77d8` and tree
`542c54f0` is a known stale-binding defect and carries no authority. At planning time, task authoring and
implementation required later verdicts; the amendment below records the subsequent tasks verdict. Neither
verdict grants a provider invocation or release action.

### Tasks Verdict Amendment — 2026-07-18

The maintainer approved task authoring from plan commit `08e86496f2475bb970ff1eafeedf3d58ee897a53`
and explicitly selected both priced repairs. T068 and T069 therefore move into the execution baseline, increasing
capacity from 15 to 18 SP. They execute first so the remaining Iteration 008 lifecycle boundaries dogfood the
repair. T069 is hard-capped at 2.25 SP: if its observed scope exceeds that estimate, stop and replan rather than
expand the release slice. Implementation, provider invocation, and release action remain unauthorized.

## Objective

Finish the Beta2 release line in one capacity-bounded iteration by combining:

1. the missing FR-048/FR-049/SC-015 verification-plan supplier, production execution, and exact-digest review
   injection path; and
2. the unstarted Iteration 004 consumer distribution and release tail.

The implementation must reuse the framework-neutral verification-plan schema, validator, runner, and evidence
recorder already delivered by T018. It adds the smallest supplier and production wiring needed to feed that seam;
it does not create a second runner or a general discovery framework.

## Scope Summary

| Requirement | Iteration 008 obligation | Acceptance claim |
| --- | --- | --- |
| FR-041, FR-042, FR-044, FR-045 | Rebind pending crossings to their actual closeout commit/tree and reject stale authority | Remaining boundaries use current scoped identity and stable explicit verdict semantics |
| FR-055, FR-056 | Repair injected-context and multi-session Stop/capture attribution without losing instruction-bearing verdicts | Routine discussion stays conversational; genuine scoped verdict plus instructions remains complete |
| FR-024, FR-025, FR-031 | Ship consumer-safe methodology/work-kind workflows with provider-gated deployment and valid deployed paths | Fresh GitHub-provider consumer has usable generic CI |
| FR-026, FR-027 | Keep template deployment deny-by-default and ignore local host configuration | No self-host-only lane or local secret/config leaks into consumers |
| FR-028, FR-032 | Hash-guard retired-template healing and synchronize refocus scopes | Unmodified obsolete files heal; modified files warn and survive |
| FR-029 | Provide announced greenfield bootstrap commit and explicit recorded brownfield offer | Init finishes in a usable, honest repository state |
| FR-030 | Resolve release model once and render only applicable closeout guidance | Local-only and publish-target fixtures receive different truthful guidance |
| FR-035, FR-036, FR-046, FR-047 | Complete consumer deny checks, all-prompt fixture, applicability provenance, and heterogeneous fixtures | No inapplicable stack/provider/release mandate reaches a consumer |
| FR-048 | Reuse the ordered plan runner and exact-digest/command-id evidence join in the production campaign | Every configured attempt is recorded and matching evidence is injected |
| FR-049 | Supply a minimal deterministic plan by the specified precedence, or fail with actionable `verification-not-configured` | No extension inference, no Specrew/Pester default, no silent success |
| FR-040 | Complete seven-surface version agreement, credentials teaching, and tag/publish `v0.40.0-beta2` | Release action occurs only after its own explicit human authorization |
| SC-008–SC-013, SC-015 | Prove init/update/distribution/release and verification-plan behavior with deterministic fixtures and three-OS CI | All pre-publish Beta2 gates are green |
| SC-014 | Run one maintainer-assessed fresh-consumer E2E from the published beta bits | Evidence becomes stable-promotion input; no stable promotion is performed |
| NFR-002, NFR-007 | Keep selection, execution, joins, failure reasons, and release evidence visible; pair honesty invariants | False-allow and false-deny directions are covered |

## Architecture

### Verification-Plan Supplier Boundary

The production boundary is deliberately narrow:

`project/config inputs -> pure ordered selector -> canonical selected plan -> existing T018 runner -> exact-digest evidence -> review campaign injection`

- The canonical selected-plan path remains `.specrew/verification-plan.json`.
- Explicit project configuration is authoritative. If it exists but is invalid, selection fails closed; it does
  not fall through to a lower-precedence source.
- Reliable detection uses only named, versioned detectors over project-owned CI/build/package metadata. It never
  infers a command from file extensions.
- Quality-profile and provider-gated entries are considered only at their defined precedence and retain auditable
  provenance.
- The small selection catalog is data, not a broad plug-in DSL. It maps trusted source shapes to complete command
  arrays and stable identifiers.
- Init/update/setup owns materializing or hash-guard refreshing generated plans. A user-authored explicit plan is
  never overwritten.
- Review loads the plan from the frozen external target, runs it before provider invocation, and joins only
  evidence matching both the exact reviewed-state digest and command ID.
- Missing or invalid configuration fails before provider spend with an actionable setup path. Configured command
  failures remain visible evidence and cannot produce approval.
- Neither verification execution nor review mutates the origin worktree. The repository remains the sole code
  mutation authority.

The detailed input/output/failure contract is [../../contracts/verification-plan-supplier.md](../../contracts/verification-plan-supplier.md).

### Distribution and Release Boundary

The Iteration 004 tail keeps the approved design: data-seam and provider-keyed deployment, hash-guarded healing,
release-model-specific teaching, a technology-assumption firewall, and tag-driven prerelease publication. T029 is
sequenced after the supplier/injection proof and requires a fresh explicit human release grant. T067 then tests
the published beta from a fresh consumer; it does not promote a stable version.

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| --- | --- | --- | --- | ---: | --- | --- | --- | --- | --- | --- |
| T068 | Narrow stale-binding rebind | FR-041, FR-042, FR-044, FR-045, NFR-007 | US1 | 0.75 | Implementer | extensions/specrew-speckit/scripts/shared-governance.ps1, .specify/extensions/specrew-speckit/scripts/shared-governance.ps1, scripts/internal/sync-boundary-state.ps1, tests/integration/** | done | Implementer | 0.75 | passed |
| T069 | Multi-session stop/capture integrity repair | FR-041, FR-042, FR-055, FR-056, NFR-002, NFR-007 | US1 | 2.25 | Implementer | scripts/internal/bootstrap/ConversationCaptureAccessor.ps1, shared-governance + hook-dispatcher mirrors, conformance-provider mirrors, tests/integration/**, tests/bootstrap/** | done | Implementer | 2.25 | passed |
| T021 | Methodology gate template and provider-keyed deploy | FR-024, FR-031, SC-008 | US4 | 0.75 | Implementer | templates/github/workflows/**, scripts/internal/distribution-module-init.ps1, tests/** | planned | — | — | — |
| T022 | Work-kind template deployed-path correction | FR-025, SC-008 | US4 | 0.25 | Implementer | templates/github/workflows/specrew-work-kind.yml, tests/** | planned | — | — | — |
| T023 | Deny-by-default consumer deploy-list surgery | FR-026, SC-008 | US4 | 0.75 | Implementer | scripts/internal/distribution-module-init.ps1, templates/**, .github/workflows/**, tests/** | planned | — | — | — |
| T024 | Ignore deployed local host configuration | FR-027, SC-008 | US4 | 0.25 | Implementer | scripts/specrew-init.ps1, scripts/internal/**, tests/** | planned | — | — | — |
| T025 | Hash-guard update healing and refocus-scope synchronization | FR-028, FR-032, SC-009 | US4 | 0.75 | Implementer | scripts/specrew-update.ps1, scripts/internal/**, extensions/specrew-speckit/**, .specify/extensions/specrew-speckit/**, tests/** | planned | — | — | — |
| T026 | Announced greenfield bootstrap commit and brownfield offer | FR-029, SC-008 | US4 | 0.5 | Implementer | scripts/specrew-init.ps1, scripts/internal/**, tests/** | planned | — | — | — |
| T027 | Release-model resolver and applicable closeout teaching | FR-030, SC-010 | US4 | 1.0 | Implementer | extensions/specrew-speckit/scripts/shared-governance.ps1, .specify/extensions/specrew-speckit/scripts/shared-governance.ps1, templates/lifecycle/**, tests/** | planned | — | — | — |
| T028 | Consumer deny checks, prompt fixture, and applicability firewall | FR-035, FR-036, FR-046, FR-047, SC-011 | US5 | 2.0 | Implementer | extensions/specrew-speckit/data/**, extensions/specrew-speckit/**, .specify/extensions/specrew-speckit/**, scripts/internal/**, templates/**, tests/** | planned | — | — | — |
| T029 | Release `v0.40.0-beta2` after separately authorized release gate | FR-040, SC-012, SC-013 | Release | 0.75 | Implementer | Specrew.psd1, CHANGELOG.md, README.md, docs/**, scripts/internal/validate-versions.ps1, .github/workflows/** | planned | — | — | — |
| T062 | Deterministic verification-plan supplier and bounded selection catalog | FR-049, SC-015, NFR-007 | US3 | 1.25 | Implementer | scripts/internal/continuous-co-review/verification-plan-supplier.ps1, extensions/specrew-speckit/data/**, .specify/extensions/specrew-speckit/data/**, tests/continuous-co-review/** | in-progress | Implementer | — | — |
| T063 | Init/update/setup materialization, guarded refresh, and actionable configuration UX | FR-049, SC-008, SC-009, SC-015 | US3 | 1.5 | Implementer | scripts/specrew-init.ps1, scripts/specrew-update.ps1, scripts/internal/**, extensions/specrew-speckit/**, .specify/extensions/specrew-speckit/**, tests/** | planned | — | — | — |
| T064 | Frozen-target verification execution and exact-digest campaign evidence injection | FR-048, FR-049, SC-015 | US3 | 1.5 | Implementer | scripts/internal/continuous-co-review/**, scripts/specrew-review.ps1, tests/continuous-co-review/** | planned | — | — | — |
| T065 | Supplier/runner/injection deterministic end-to-end fixture matrix | FR-048, FR-049, SC-015, NFR-007 | US3 | 1.25 | Implementer | tests/continuous-co-review/**, tests/fixtures/**, specs/198-beta2-hardening/iterations/008/quality/** | planned | — | — | — |
| T066 | Full deterministic verification, three-OS CI, and independent signoff | FR-024, FR-025, FR-026, FR-027, FR-028, FR-029, FR-030, FR-031, FR-032, FR-035, FR-036, FR-040, FR-046, FR-047, FR-048, FR-049, SC-008, SC-009, SC-010, SC-011, SC-012, SC-013, SC-014, SC-015, NFR-002, NFR-007 | Release | 1.5 | Reviewer | tests/**, .github/workflows/**, .specrew/review/**, specs/198-beta2-hardening/iterations/008/** | planned | — | — | — |
| T067 | Published-beta fresh-consumer dogfood and stable-promotion input | SC-014, NFR-002 | Release | 1.0 | Maintainer | specs/198-beta2-hardening/iterations/008/quality/**, docs/** | planned | — | — | — |

T021–T029 retain their feature-global identifiers from the never-opened Iteration 004 slice. New work continues
after T061. The feature-level tasks artifact is amended under the recorded plan-to-tasks verdict.

## Requirements-to-Test and Evidence Mapping

| Requirement | Required test/evidence shape |
| --- | --- |
| FR-041, FR-042, FR-044, FR-045 | Exact current closeout commit/tree binds; stale pre-closeout identity rejected; repeat rendering stable; bare-number alias non-authoritative |
| FR-055, FR-056 | Real injected-environment-context reproduction, shared-baseline cross-session attribution, concurrent sessions, stale-binding class, and leading approval-plus-instructions preservation |
| FR-024–FR-027, FR-031 | Scratch GitHub/unset-provider init fixtures; deployed files exist; generic triggers; deny-by-default manifest; local host config ignored |
| FR-028, FR-032 | Beta1-shaped update fixture: unmodified retired file removed, modified file warned/preserved, refocus rows synchronized |
| FR-029 | Greenfield Git fixture proves announced bootstrap commit; brownfield fixture proves no surprise commit and an explicit recorded offer |
| FR-030 | No-remote/local-only and publish-target fixtures assert mutually appropriate closeout text and named N/A reasons |
| FR-035, FR-036, FR-046, FR-047 | Seeded deny-list red/annotated green pair; every prompt surface rendered; Python/non-Pester, non-GitHub, and no-publish fixtures retain only applicable claims |
| FR-048 | Ordered mixed-command fixture; duplicate/unjoinable/digest-mismatch/path escape/timeout/result-contract pairs; every attempted command recorded |
| FR-049 | One fixture per precedence source; invalid explicit config does not fall through; inactive provider ignored; no-source yields actionable `verification-not-configured`; extension-only bait never selects |
| SC-015 | Production-path downstream fixture selects a plan, runs T018 in order, injects matching exact-digest evidence, and fails before spend on unconfigured/invalid selection |
| FR-040, SC-012, SC-013 | Full registry; three-OS CI; seven version surfaces agree; credential docs match tag workflow; authorized tag-push publication evidence |
| SC-014 | Fresh consumer installed from published beta; maintainer records pass/fail against the four beta1 friction classes |

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Repository-configured unit |
| Capacity per Iteration | 26 | Current project cap |
| Planned Effort | 18.0 | Core finish line plus both explicitly selected repairs |
| Overcommit Threshold | 1.0 | No overcommit allowed |
| Capacity Status | ok | 8 SP headroom |
| Iteration Bounding | scope | Beta2 supplier, distribution, release, and published-beta proof form one coherent finish line |
| Time Limit (hours) | n/a | Scope-bounded iteration |
| Defer Strategy | manual | No requirement or optional repair is silently included or dropped |
| Calibration Enabled | true | Retro records engineering variance and provider wall time separately |

### Estimate Reconciliation

- Historical Iteration 004 distribution/release tasks T021–T029 total 7.0 SP after the approved T028 technology-assumption amendment.
- The T018 verification schema, validator, runner, evidence recorder, and selected-plan load seam already exist and are not re-estimated.
- Residual supplier/materialization/campaign injection and deterministic fixture work T062–T065 totals 5.5 SP.
- Full validation/signoff and post-publish consumer proof T066–T067 totals 2.5 SP.
- The tasks verdict selected T068 (0.75 SP) and T069 (2.25 SP), raising the executable baseline to 18.0 SP.
- Selected total: 18.0 SP. The combined slice fits within 26 SP and keeps 8 SP unallocated.

Iterations 001 and 002 expanded about 16–17% from plan to actual. Applying 17% to the selected 18.0 SP baseline
yields about 21.1 SP, still below capacity. Iterations 006 and 007 reported estimated effort as actual but did not meter it
independently; they are not used as zero-variance evidence.

### Phase Baseline

| Phase | Estimated Effort | Included work |
| --- | ---: | --- |
| Early boundary and capture integrity repair | 3.0 | T068–T069 |
| Supplier selection and materialization | 2.75 | T062–T063 |
| Production execution and exact-digest injection | 1.5 | T064 |
| Consumer distribution hardening | 6.25 | T021–T028 |
| Deterministic end-to-end acceptance | 1.25 | T065 |
| Full verification and independent review | 1.5 | T066 |
| Authorized prerelease publication | 0.75 | T029 |
| Published-beta consumer dogfood | 1.0 | T067 |
| **Total** | **18.0** | Matches selected capacity consumption |

### Provider and Review-Round Budget

- Planning and task authoring grant zero provider slots.
- T066 starts with one independently authorized provider invocation against the committed candidate digest.
- Any correction rerun uses a new run ID and a separately visible authorization. No hidden retry exists.
- The expected correction reserve is one to three additional slots, not pre-spent and not silently assumed.
- Stop and replan if the same finding class recurs for three consecutive rounds or the validated finding count
  does not decrease across three consecutive rounds. Progress, not merely activity, governs further spend.

## Selected Governance Repairs

The tasks verdict selected both repairs. Their total is included in the 18 SP baseline.

| Task | Selected scope | Requirement/defect | Effort | Selection state | Hard boundary |
| --- | --- | --- | ---: | --- | --- |
| T068 | Narrow stale-binding rebind | `DRIFT-198-I008-001`; FR-041, FR-042, FR-044, FR-045, NFR-007 | 0.75 | selected; executes first | Bind a pending crossing to the actual closeout commit/tree; stale parent citations carry no authority; paired current/stale tests. No matcher redesign. |
| T069 | Remaining stop/capture integrity repair | `DRIFT-198-I007-025`; FR-041, FR-042, FR-055, FR-056, NFR-002, NFR-007 | 2.25 | selected; executes after T068 | Reproduce injected-context, shared-baseline attribution, stale-binding-class, concurrent-session, and approval-plus-instructions defects; key attribution to session/owner; preserve full instructions; prevent cross-session billing. Stop and replan before exceeding 2.25 SP. |

## Dependencies and Execution Order

1. T068 lands the narrow current-crossing rebind and paired stale/current fixtures.
2. T069 then lands the bounded multi-session/injected-context capture repair and regression matrix. Every
   subsequent Iteration 008 boundary exercises both repairs. If T069 cannot remain within 2.25 SP, stop and replan.
3. T062 freezes the supplier output and precedence behavior before setup or campaign wiring depends on it.
4. T063 materializes the canonical plan through real init/update/setup paths while preserving explicit user-owned
   configuration.
5. T064 integrates the frozen-target runner and exact-digest evidence join. Missing/invalid plans stop before
   provider invocation.
6. T021–T028 complete the consumer distribution tail using the same applicability and provider provenance rules.
7. T065 exercises the supplier, existing T018 runner, evidence recorder, and campaign path together.
8. T066 runs focused suites, the full registry, scoped governance, three-OS CI, and independent exact-digest
   review. Finding corrections follow the bounded non-convergence rule.
9. T029 may update version surfaces and publish only after T066 passes and a fresh human explicitly authorizes
   the release action.
10. T067 consumes the actually published beta in a fresh project and records SC-014 evidence. It does not publish
   a stable release.

## Concurrency Rationale

Implementation should remain mostly serial because supplier, init/update, campaign injection, distribution, and
release all touch shared setup/governance surfaces. Parallel work is safe only after task authoring assigns
disjoint owner globs—for example, provider workflow fixtures versus the pure supplier catalog. Exact-digest
selection/execution/injection and any optional multi-session repair require explicit concurrency tests even
though the production feature is not a high-throughput service.

## Quality Planning

The generated quality-profile resolver detected Node/React/Postgres strings from repository tooling; those are
not runtime technologies for this slice. The reconciled profile is:

- Runtime surfaces: PowerShell 7.x plus Markdown, YAML, and JSON; Node is tooling for markdownlint only.
- Required lenses: security/hardening, robustness/fault injection, and test integrity.
- Required honesty pairs: explicit-plan valid/invalid; every precedence source selected/skipped; current/stale
  digest; joinable/unjoinable evidence; safe/escaping paths; eligible/ineligible provider; release/not-release
  model; unmodified/modified heal target.
- Concurrency: required for exact-digest campaign injection and the selected stop/capture repair.
- UI/browser, database, and load testing: not applicable.
- Performance: secondary to stability; command timeouts are bounded and full-suite/provider wall time is recorded.

## Wave B Artifacts

- [../../contracts/verification-plan-supplier.md](../../contracts/verification-plan-supplier.md) defines the new supplier boundary.
- [../../data-model.md](../../data-model.md) adds the supplier-selection entity and invariants.
- [../../quickstart.md](../../quickstart.md) describes plan-time operator and acceptance flow.
- [../../review-diagrams.md](../../review-diagrams.md) shows selection, materialization, execution, evidence join, release, and dogfood sequence.
- [state.md](state.md) records planning authority and the unstarted execution state.
- [drift-log.md](drift-log.md) records the stale crossing-binding defect without treating it as authority.
- [quality/hardening-gate.md](quality/hardening-gate.md) records before-implementation controls and evidence obligations.

## Explicit Exclusions and Deferrals

- Proposal 209 remains a separately scheduled engine/governance item. No Proposal 209 optimization or redesign is
  folded into Iteration 008.
- Generic gate/artifact review adapters remain Beta3 scope under FR-065.
- Stable promotion is outside this feature; SC-014 supplies evidence only.
- Automatic campaign retention/pruning remains deferred.
- T068 and T069 are selected only at their stated bounds. T069 cannot silently grow beyond 2.25 SP.
- A broad verification discovery DSL, file-extension inference, and a Specrew/Pester default are prohibited.

## Traceability Summary

- Every core task maps to at least one scoped FR, SC, or NFR.
- Every selected requirement FR-024–FR-032, FR-035, FR-036, FR-040–FR-042, FR-044–FR-049, FR-055, FR-056 and
  SC-008–SC-015 maps to at least one task and one evidence shape.
- T068/T069 trace separately to named defects and are included in the 18 SP selected baseline.
- The official plan scaffold was created first. Its scope parser rejected decorated requirement IDs such as
  `FR-024 (W1)` and produced an overbroad stub; this authored plan uses the canonical IDs and explicit mapping.

## Stop Condition

After task artifacts and readiness evidence are validated, committed, and pushed, stop at the
`tasks -> before-implement` boundary. Do not implement code, invoke a provider, or perform a release action
without the corresponding later human verdict.
