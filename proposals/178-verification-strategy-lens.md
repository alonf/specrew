---
proposal: 178
title: Verification Strategy Lens (QA and Test Evidence Workshop)
status: candidate
phase: phase-2
estimated-sp: 10-16
priority-tier: 2
discussion: surfaced 2026-06-10 after the maintainer observed that Specrew has product, architecture, UI, NFR, risk, domain/platform, and code-craft workshop lenses, but no explicit QA/testing lens that decides unit/component/integration/E2E/manual evidence, CI gates, coverage posture, test runtime budget, framework choice, and TDD posture before implementation starts.
---

# Verification Strategy Lens (QA and Test Evidence Workshop)

## Why

Specrew has several places where quality is discussed, but none of them owns
the complete testing and proof strategy before code is written.

The current lenses can identify important qualities:

- `requirements-nfr` decides which non-functional qualities matter;
- `architecture-core`, `component-design`, `data-storage`, `integration-api`,
  `security-compliance`, `observability-resilience`, `devops-operations`, and
  `ui-ux` expose surfaces that need proof;
- the hardening gate and reviewer inspect evidence near implementation time.

That is not enough. The Crew still needs a design-time decision about **how the
feature will be proven correct**:

- Do we need unit, component, contract, integration, E2E, performance,
  accessibility, security, snapshot/golden, property/fuzz, or manual tests?
- Which test framework should be used, and should we reuse project defaults?
- Is TDD expected, optional, or inappropriate for this slice?
- What coverage target or coverage exception is meaningful?
- Which checks must run locally, in CI, before merge, before beta, or nightly?
- How much test runtime is acceptable for the inner loop and the full gate?
- What manual validation instructions and result record does the human need?
- What evidence is enough for the reviewer to accept the feature?

Without an explicit verification strategy, two bad outcomes recur:

1. **Under-proofing**: the implementation has happy-path tests but misses
   negative cases, integration boundaries, UI behavior, migration safety, or
   manual user acceptance.
2. **Over-proofing**: tiny low-risk changes spend minutes or hours in expensive
   gates, broad E2E suites, or arbitrary coverage targets that do not improve
   confidence.

Specrew needs a dedicated QA/testing lens that converts feature risk and
surface area into a right-sized evidence contract.

## What

Add a workshop lens with working id `verification-strategy`.

The lens decides the feature's test and evidence plan before tasks are written.
It is separate from `requirements-nfr`:

- `requirements-nfr` defines what qualities matter.
- `verification-strategy` defines how Specrew will prove those qualities and
  which evidence is required at review.

The lens should normally run near the end of the design workshop, after the
feature has enough product, requirement, architecture, component, UI, data,
integration, security, and operations context to choose a sensible evidence
mix. It should still run for tiny features, but at Light depth.

## Run Cadence

Use a two-tier cadence, aligned with the product/context direction from
Proposal 162 and the skill/context-pack direction from Proposal 177:

1. **Project-level defaults**: run once, then reopen only when the stack,
   organization policy, CI platform, risk profile, or preferred frameworks
   change. This records the default test frameworks, CI gate shape, coverage
   philosophy, flake policy, manual evidence standard, TDD posture, and test
   runtime budgets.
2. **Per-feature delta**: run for every feature. The feature pass inherits the
   project defaults, then records only the changed surfaces, risk tier,
   required evidence, accepted exceptions, and any manual validation script.

For V1, if project-level inheritance is not available, the per-feature lens may
record the project-default assumptions inline and mark them as inherited-later
compatible.

## Lens Decision Areas

### 1. Risk and Depth

Classify the feature into Light, Standard, or Deep verification depth.

Inputs:

- user-visible impact;
- data loss, privacy, security, safety, money, compliance, or migration risk;
- changed runtime surface area;
- existing coverage and regression history;
- amount of uncertain or research-needed behavior;
- blast radius across hosts, packages, platforms, or integrations.

Expected depth:

- **Light**: tiny or low-risk changes. Usually unit tests or focused smoke
  checks, plus a review evidence note.
- **Standard**: ordinary feature work. Unit/component tests plus boundary,
  negative, and integration proof for changed contracts.
- **Deep**: high-risk or broad changes. Adds E2E, migration, performance,
  security, accessibility, cross-platform, manual, or staged-release evidence
  as applicable.

### 2. Automated Test Mix

Select which automated evidence is required and why:

- unit tests for pure logic and edge cases;
- component tests for isolated modules, UI components, or service components;
- contract/API tests for public surfaces, schemas, CLIs, plugins, or host
  adapters;
- integration tests for real boundaries, storage, network, filesystem, process,
  browser, package, or host interactions;
- E2E tests for critical user journeys;
- snapshot/golden tests when the stable output shape matters;
- property-based or fuzz tests for parsers, serializers, path handling, and
  broad input domains;
- performance/load tests where latency, throughput, memory, or startup cost is
  load-bearing;
- accessibility tests for user-facing UI;
- security smoke tests when auth, permissions, secrets, input validation,
  dependency trust, or policy gates are touched.

The lens should also record which test types are intentionally not required,
with a reason.

### 3. Test Framework and Tooling

Prefer established project tools. Ask a framework question only when no project
default exists or when the feature changes stack/runtime.

Record:

- test framework(s);
- assertion/mocking/fixture libraries;
- browser/device/host automation tools;
- coverage tooling;
- linters/analyzers/static checks;
- required local commands and CI commands;
- tool installation assumptions.

If a tool choice depends on current ecosystem state, mark it
`research-needed`.

### 4. Coverage Posture

Coverage is a signal, not a substitute for meaningful evidence.

The lens should capture:

- project-level default coverage threshold, if one exists;
- feature-specific coverage target or exemption;
- whether branch/condition coverage matters more than line coverage;
- critical files or behaviors that must be covered regardless of aggregate
  percentage;
- accepted reasons for not raising coverage, such as generated code, host
  glue, test harness code, or manually validated UI-only behavior.

The lens should avoid hard-coded universal thresholds. Different stacks and
risk levels need different bars.

### 5. CI/CD Gate Shape

Decide where each check runs:

- inner-loop local command;
- pre-boundary or pre-commit check;
- PR CI;
- merge gate;
- prerelease/beta dogfood;
- nightly or scheduled full suite;
- release promotion gate.

Record which failures block progress and which produce warnings. The default
should be risk-based: fast deterministic checks block early; slow or flaky
checks need explicit placement and owner.

### 6. Runtime Budget and Flake Policy

Record the expected runtime budgets:

- fast local check target;
- full local verification target;
- PR CI target;
- long-running/nightly allowance.

Record a flake policy:

- retries allowed or forbidden;
- quarantine rules;
- when a flaky test blocks release;
- how flaky evidence is reported in review.

This prevents the Crew from treating all tests as equally appropriate at every
gate.

### 7. TDD Posture

TDD should be an explicit posture, not an assumed virtue signal.

Options:

- **Strict test-first**: required before production code for the targeted
  behavior.
- **Risk-targeted test-first**: required for core logic, defect fixes, parsers,
  contracts, or risky edge cases.
- **Test-alongside**: tests may be written during implementation, but evidence
  must be complete before review.
- **Review-only exception**: allowed only for spikes, generated output, or
  hard-to-automate manual UX validation, with a replacement evidence plan.

### 8. Manual Validation

When manual validation is required, the lens should produce a runnable
human-facing script, not a vague instruction.

Record:

- environment prerequisites;
- exact steps;
- expected observations;
- pass/fail form;
- required screenshots, logs, videos, or transcripts;
- who performs the validation;
- where the result is persisted.

For Specrew itself, beta dogfood is a common manual validation mode and should
be represented as first-class evidence.

### 9. Evidence Contract for Review

The lens should define what the reviewer must see:

- required commands and their output locations;
- required artifacts such as coverage reports, screenshots, logs, dogfood
  notes, manual forms, or CI links;
- negative-case evidence;
- skipped-test rationale;
- known residual risks and accepted exceptions.

This gives Proposal 145 reviewer conformance a concrete testing strategy to
check instead of relying on generic reviewer judgment.

## Artifacts

For each feature, persist:

- `specs/<feature>/workshop/verification-strategy.md`: human-readable workshop
  record and decisions.
- `specs/<feature>/verification-strategy.yml`: structured strategy record.
- `specs/<feature>/iterations/<NNN>/quality/verification-evidence.md` or an
  equivalent review-time evidence record: what actually ran, what passed, what
  was skipped, and why.

The structured record should include:

- `depth`;
- `risk_reasons`;
- inherited project defaults;
- changed surfaces;
- required automated test types;
- not-required test types with reasons;
- framework/tool choices;
- coverage target or exception;
- CI/CD gate placement;
- runtime budgets;
- flake policy;
- TDD posture;
- manual validation plan;
- review evidence contract;
- assumptions and `research-needed` items;
- human confirmation provenance.

## Integration Points

### Spec

`spec.md` should summarize the verification intent at feature scope, especially
manual validation, high-risk proof, and accepted exceptions.

### Plan

`plan.md` should include the verification strategy in the quality profile and
name the exact commands and artifacts expected before review.

### Tasks

`tasks.md` should contain explicit test/evidence tasks traced to the required
verification strategy entries. A required evidence type without a task is a
traceability defect.

### Implementation

Before implementation, the active strategy should be surfaced to the agent.
When Proposal 177 ships, the durable project defaults should be available
through `specrew-quality-rules`, and the feature deltas should be available
through the implementation context pack.

### Review

The reviewer should check conformance to the approved verification strategy:

- required evidence exists;
- skipped evidence has an approved reason;
- manual validation has a result record when required;
- coverage and runtime budgets match the strategy or have a variance record;
- negative cases were attempted for the defect classes named by the lens.

## Functional Requirements

- **FR-001**: Specrew MUST provide a `verification-strategy` workshop lens that
  decides how the feature will be proven correct before tasks are finalized.
- **FR-002**: The lens MUST separate quality goals from proof strategy, and MUST
  compose with `requirements-nfr` rather than replace it.
- **FR-003**: The lens MUST run at Light, Standard, or Deep depth based on
  risk, changed surface area, and uncertainty.
- **FR-004**: The lens MUST record required and intentionally-not-required test
  types with reasons.
- **FR-005**: The lens MUST record framework/tool choices, preferring existing
  project defaults unless a stack change or missing default requires a decision.
- **FR-006**: The lens MUST record coverage posture, including any target,
  critical behavior requirement, or accepted exemption.
- **FR-007**: The lens MUST record CI/CD gate placement and blocking semantics
  for each required check.
- **FR-008**: The lens MUST record test runtime budgets and flake policy when
  automated tests are required.
- **FR-009**: The lens MUST record TDD posture as a deliberate choice.
- **FR-010**: The lens MUST produce manual validation instructions and a result
  record requirement when manual evidence is part of the strategy.
- **FR-011**: The lens MUST persist both human-readable and structured feature
  records.
- **FR-012**: Planning MUST translate required evidence into explicit tasks.
- **FR-013**: Review MUST verify conformance to the approved verification
  strategy and record any accepted variance.
- **FR-014**: Durable project-level testing defaults SHOULD be promotable into
  the future `specrew-quality-rules` skill/context-pack surface from Proposal
  177.

## Out of Scope

- Replacing the hardening gate or Proposal 145 review discipline.
- Building a full QA management suite, test-case database, or test reporting
  dashboard.
- Mandating one universal coverage percentage across all projects.
- Replacing stack-specific testing expertise or current framework research.
- Forcing strict TDD for all work.
- Running every possible test at every boundary.

## Effort

- **Iteration 1 (~6-8 SP)**: lens content, catalog registration, structured
  `verification-strategy.yml` schema, and workshop conduct.
- **Iteration 2 (~4-6 SP)**: plan/tasks/review integration, traceability
  checks, manual validation evidence record, and tests.
- **Total**: ~10-16 SP.

## Phase Placement

Phase 2. This is methodology and governance infrastructure: it improves
feature quality before implementation without waiting for broader Phase 3+
multi-developer or dashboard work.

## Open Questions

1. Should the public lens id be `verification-strategy`,
   `quality-test-strategy`, or `qa-strategy`?
2. Should the lens be always-on for every feature, or activated by the
   requirements/NFR and risk profile with an always-on Light fallback?
3. Should project-level defaults live under Proposal 162 product context, under
   a dedicated `.specrew/quality/` surface, or only in Proposal 177's future
   quality skill data?
4. Should manual validation records be mandatory for all user-facing features,
   or only when the lens explicitly selects manual evidence?
5. What minimum CI gate should Specrew require for its own repository before
   this lens is used to govern external projects?

## Risks

- **Quality theater**: the lens could add checklists without improving proof.
  Mitigation: require evidence tasks and review conformance, not just workshop
  text.
- **Over-testing small work**: always asking every QA question would slow tiny
  features. Mitigation: adaptive depth and explicit not-required decisions.
- **Coverage misuse**: arbitrary line coverage can hide untested behavior.
  Mitigation: record coverage as posture plus critical behavior proof, not as a
  universal number.
- **Framework churn**: asking framework questions on every feature creates
  inconsistency. Mitigation: inherit project defaults and ask only for deltas.
- **Slow gates**: broad tests at every boundary can make Specrew feel stuck.
  Mitigation: separate inner-loop, PR, nightly, beta, and release gates with
  runtime budgets.

## Cross-References

- Related proposals: 008, 030, 042, 073, 112, 145, 156, 162, 163, 164, 174,
  175, 177.
- Composes with Proposal 177 by feeding future `specrew-quality-rules` and
  feature context packs.
- Composes with Proposal 145 by giving the reviewer a concrete
  workshop-approved verification strategy to check.
- Composes with Proposal 164 by converting identified risks into proof
  requirements.
- Composes with Proposal 175 by allowing domain/platform packs to inject
  stack-specific test questions and source-backed testing defaults.

## Status History

- 2026-06-10: status set to candidate from maintainer discussion about the
  missing QA/testing workshop lens.
