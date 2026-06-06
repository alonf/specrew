---
proposal: 166
title: Concurrent Development Hygiene (Tracked-State Separation + Collision Floors)
status: candidate
phase: phase-2
estimated-sp: 14-24
priority-tier: 1
type: tooling
discussion: surfaced 2026-06-06 during parallel Feature 141 / 159 / 160 / 161 dogfooding and a repo churn audit; active worktrees collided mostly on repo-global lifecycle state, generated mirrors, proposal indexes, and active governance surfaces rather than feature-owned source code
composes-with:
  - 008  # NFR governance: cohesion/coupling discipline
  - 010  # Multi-Developer Reconciliation
  - 026  # Refactor Track Features
  - 091  # Technology Debt Control
  - 097  # Coupling Surface Catalog
  - 115  # Spec-first concurrent development workflow
  - 134  # Tooling/version reconciliation in multi-dev projects
  - 145  # Structured multi-phase reviewer
  - 148  # Collision-aware feature selection
  - 149  # Merge brief extraction
  - 159  # Update staleness guard
  - 160  # Boundary-sync resolver paths
  - 161  # Managed skill preserving guard
  - 163  # Code & Implementation Lens
audience: tooling
---

# Concurrent Development Hygiene

## Why

Specrew can already use Git worktrees to run several Crews in parallel, but the repo shape makes
unrelated features collide more than they should. A 2026-06-06 audit across the active parallel
worktrees (`141-design-gate-runtime-hardening`, `159-update-ux-small-fixes`,
`160-unix-resolver-sidecar-hardening`, and `161-managed-skill-preserving-guard`) showed that the
major conflict surfaces are not always the product source files. They are shared lifecycle state,
generated mirrors, proposal/release indexes, and central hub scripts.

Recent churn confirms the same pattern. In the prior 30 days, the hottest files included
`.squad/decisions.md` (319 changes), `.squad/identity/now.md` (216), `proposals/INDEX.md` (149),
`CHANGELOG.md` (87), `scripts/specrew-start.ps1` (80), `Specrew.psd1` (62),
`validate-governance.ps1`, `.specify/feature.json`, `.specrew/last-validator-summary.json`,
`shared-governance.ps1`, and `sync-boundary-state.ps1`.

This creates two problems:

1. **Artificial merge conflict**: a feature can be logically independent while still editing
   `.squad/decisions.md`, `.specify/feature.json`, generated skills, or proposal indexes.
2. **Unclear ownership**: reviewers cannot quickly tell whether a changed file is source,
   generated output, session-local runtime state, release-only metadata, or a required feature
   artifact.

Proposal 148 defines a larger collision-aware feature-selection system. This proposal is the
smaller foundation: classify the file surfaces, stop committing avoidable volatile state, warn on
high-risk shared files, and make concurrent branch readiness cheaper before building full
predictive scheduling.

## Fit With Existing Proposals

This proposal remains a standalone proposal. It should not be folded into an existing one because
its core deliverable is a concrete concurrency substrate: a file-surface registry, changed-file
classification, collision reporting, generated-mirror discipline, runtime-state policy, and
global-ledger compatibility tests.

It deliberately does **not** become the general "architecture health" proposal:

| Concern | Owner |
| --- | --- |
| Cohesion, coupling, and quality attributes as lifecycle questions | [008 NFR Governance](008-nfr-governance.md) |
| Large-script modularization and behavior-preserving refactors | [026 Refactor Track Features](026-refactor-track-features.md) |
| Recording, aging, and repaying debt after it exists | [091 Technology Debt Control](091-tech-debt-control.md) |
| External/tool/vendor coupling inventory | [097 Coupling Surface Catalog](097-coupling-surface-catalog.md) |
| Review-time claim verification and code/design/report evidence | [145 Structured Multi-Phase Reviewer](145-structured-multi-phase-reviewer.md) |
| Predictive feature-pair scheduling | [148 Collision-Aware Feature Selection](148-collision-aware-feature-selection.md) |
| Implementation-craft conventions such as file size, OCP posture, patterns, comments, and per-stack analyzer use | [163 Code & Implementation Lens](163-code-implementation-lens.md) |

The boundary is practical:

- **166 prevents avoidable parallel-work collisions** by making volatile surfaces explicit and
  testable.
- **008/163 prevent architecture and implementation drift** by deciding maintainability
  constraints early enough to bind implementation.
- **091 records unavoidable or discovered debt** and creates repayment paths.
- **026 repays already-known large refactor debt** once enough test coverage exists.
- **145 checks that reports of "done" match code, tests, diagrams, and evidence.**

Therefore no new proposal is needed for the concurrency part. Broader refactor-prevention lessons
belong as amendments to 008/091/145/163, not as scope expansion inside 166.

## What

### Iteration 0: Coverage Foundation First

This proposal MUST NOT begin by moving tracked state, splitting ledgers, or changing generated
surface behavior. Those are high-blast-radius refactors. The first implementation slice is a
coverage foundation that proves Specrew can detect and reason about the concurrency surfaces before
it mutates them.

Required Iteration 0 tests:

| Test | Purpose |
| --- | --- |
| `file-surface-classification.tests.ps1` | Verifies the registry classifies source, generated mirror, runtime-local, global-ledger, worktree-pointer, release-only, and central-hub paths correctly. |
| `changed-file-policy.tests.ps1` | Given a changed-file list, emits the expected warnings/errors and only suppresses noise through the registry. |
| `collision-report.tests.ps1` | Creates controlled multi-worktree or multi-branch diffs and verifies low/medium/high collision classification. |
| `ledger-split-compat.tests.ps1` | Proves existing `.squad/decisions.md` readers still work while per-feature decision/event logs are introduced in compatibility mode. |
| `generated-mirror-discipline.tests.ps1` | Proves generated mirror changes require canonical-source traceability or an explicit parity reason. |
| `runtime-local-state-policy.tests.ps1` | Proves runtime-local files are warned/ignored according to policy without breaking bootstrap, update, or boundary-sync flows. |

Iteration 0 acceptance criteria:

- The tests can run without changing the actual tracked-state policy.
- The tests define the expected behavior for the later refactor.
- No runtime-local file is untracked, no ledger is split, and no generated mirror policy is enforced
  until this coverage foundation is green.
- Any behavior that cannot be tested deterministically is recorded as a gap before Iteration 1.

### Pillar 1: File-Surface Classification Registry

Add a canonical registry, for example `scripts/internal/concurrency-surfaces.yml`, that classifies
known path patterns:

| Class | Meaning | Examples | Default policy |
| --- | --- | --- | --- |
| `source-owned` | Real implementation/template/test source | `scripts/**`, `extensions/**`, `tests/**` | Normal feature edits allowed |
| `generated-mirror` | Regenerated copy of canonical source | `.agents/skills/**`, `.claude/skills/**`, `.github/skills/**`, `.specify/extensions/**`, `.github/agents/squad.agent.md` | Prefer canonical edit; require reason if committed |
| `runtime-local` | Per-session or cache-like state | `.specrew/last-validator-summary.json`, `.specrew/version-check-cache.json`, local host routing/caches | Should be ignored or stashed, not merged |
| `global-ledger` | Append/shared lifecycle ledger | `.squad/decisions.md`, `.squad/events/lifecycle-events.jsonl`, `.squad/active-features.yml` | Split or append-only merge discipline |
| `worktree-pointer` | Current worktree active-feature pointer | `.specify/feature.json` | Worktree-local; clear at closeout; avoid as merge signal |
| `release-only` | Version/release/index aggregate | `CHANGELOG.md`, `Specrew.psd1`, `extensions/specrew-speckit/extension.yml`, `proposals/INDEX.md` | Landing/release branch only unless explicitly authorized |
| `central-hub` | High-risk shared dispatcher/validator | `scripts/specrew-start.ps1`, `validate-governance.ps1`, `shared-governance.ps1`, `sync-boundary-state.ps1` | Warn and prefer helper-module decomposition |

The registry is data, not hardcoded prompt text, so validators and start/status commands can reuse
the same classification.

### Pillar 2: Runtime-State Cleanup and Tracking Policy

Audit tracked runtime-like files and move the obvious ones out of normal feature diffs.

Initial candidates:

- `.specrew/last-validator-summary.json`
- `.specrew/version-check-cache.json`
- `.squad/config.json` when it contains session routing/model state
- `.squad/casting/registry.json` when it is regenerated with no semantic roster change
- `.specify/feature.json` as a worktree-local pointer

The implementation must be conservative. If a file is currently tracked because a shipped feature
depends on it, the first slice may only add classification warnings and docs. Actual untracking
must include migration/backward-compatibility handling.

### Pillar 3: Split Global Ledgers

Stop making every feature append to a single large merge hotspot.

Target direction:

- Replace `.squad/decisions.md` as the primary write target with per-feature ledgers such as
  `.squad/decisions/159-update-ux-small-fixes.md`.
- Replace or supplement `.squad/events/lifecycle-events.jsonl` with per-feature event logs such as
  `.squad/events/159-update-ux-small-fixes.jsonl`.
- Generate aggregate views when needed for humans or validators.

This can be phased: v1 writes both old and new files, validators read both, then a later version
switches the canonical write target.

### Pillar 4: Generated-Mirror Discipline

Codify the rule already used in Feature 159:

- Edit canonical templates/sources first.
- Treat generated active surfaces as mirrors.
- Commit generated mirrors only when parity or active-user evidence requires it.
- When generated mirrors are committed, require a reason in the boundary packet and keep the diff
  scoped to the feature-owned wording or behavior.

This prevents unrelated generated governance drift, for example six-section packet edits, from
riding along with a small compatibility wording change.

### Pillar 5: Release-Only File Discipline

Add validator warnings when a feature branch changes release-only aggregate files without a
declared reason:

- `CHANGELOG.md`
- `Specrew.psd1`
- `extensions/specrew-speckit/extension.yml`
- `.specrew/config.yml`
- `proposals/INDEX.md`

Feature branches may still update their proposal/spec/closeout files. Index, changelog, version
bumps, and package metadata should normally be centralized in a landing/release pass.

### Pillar 6: Collision Floor MVP

Implement a small subset of Proposal 148 before the full predictive system:

- `specrew where --collisions` or `specrew status --collisions`
- Compare current branch changed files with active worktree and remote branch diffs.
- Classify overlaps using the file-surface registry.
- Report:
  - clean
  - low-risk overlap (generated/runtime/release-only with known policy)
  - medium-risk overlap (same templates/tests/docs)
  - high-risk overlap (central hubs, same source files, governance templates)
- Run the same check at plan, before-implement, review-signoff, and feature-closeout.

This is not task scheduling. It is a cheap collision floor that makes manual parallel work safer.

### Pillar 7: Central-Hub Decomposition Guidance

When a feature edits a central hub, the plan must answer: "Can this become a helper module or rule
file instead?"

Near-term decomposition targets:

- `validate-governance.ps1` loads `validators/rules/*.ps1`
- `sync-boundary-state.ps1` delegates to per-artifact writer helpers
- `specrew-start.ps1` delegates host launch, profile resolution, orientation, and recovery to
  separate modules
- `shared-governance.ps1` splits parsing, authorization, and file-reference helpers

## Functional Requirements

- **FR-000**: Specrew MUST add the concurrency coverage foundation before performing tracked-state
  migration, ledger splitting, or generated-mirror enforcement. The first slice MUST include
  deterministic tests for file-surface classification, changed-file policy, collision reporting,
  ledger compatibility, generated-mirror discipline, and runtime-local state policy.
- **FR-001**: Specrew MUST maintain a file-surface classification registry covering source,
  generated mirrors, runtime-local state, global ledgers, worktree pointers, release-only files,
  and central hubs.
- **FR-002**: Boundary packets and review artifacts MUST use the registry to classify changed files
  when a feature changes generated mirrors, global ledgers, release-only files, or central hubs.
- **FR-003**: Validators SHOULD warn when runtime-local files are tracked or modified as feature
  content without an explicit justification.
- **FR-004**: Validators SHOULD warn when release-only files change outside a declared
  release/landing task.
- **FR-005**: Specrew MUST provide a collision report command that compares current branch changes
  with active worktrees and/or remote feature branches and classifies overlap by risk.
- **FR-006**: The collision report MUST ignore or downgrade known low-value noise only through the
  registry, not hardcoded ad hoc filters.
- **FR-007**: Generated mirror changes MUST require canonical-source traceability or an explicit
  parity reason.
- **FR-008**: Global ledger splitting MUST preserve existing historical records and provide
  backward-compatible reader behavior during migration.
- **FR-009**: Central-hub edits MUST surface a decomposition check during plan or before-implement.

## Out of Scope

- Full Proposal 148 predictive feature-pair ranking.
- Full Proposal 010 multi-developer reconciliation and Spec Steward mediation.
- Full Proposal 115 spec-first branch workflow.
- Solving semantic conflicts between two changes in different files.
- Removing historical ledgers immediately without a compatibility migration.
- Requiring a central service or lock server.

## Effort

- **Iteration 0 (~4-6 SP)**: Coverage foundation: the six deterministic tests above, minimal
  fixtures, and any test-only helper seams needed to make the later refactor observable.
- **Iteration 1 (~4-6 SP)**: File-surface registry + changed-file classification helper +
  validator warnings for generated/runtime/release-only/high-risk files.
- **Iteration 2 (~4-6 SP)**: Collision report MVP for current branch vs active worktrees/remote
  branches, with risk classification and tests.
- **Iteration 3 (~4-6 SP)**: Ledger split v1 for decisions/events, dual-write or backward-compatible
  reader, and generated-mirror discipline enforcement.
- **Total**: ~14-24 SP depending on how much migration is included.

## Phase Placement

Phase 2, priority tier 1.

Although the parent multi-developer story belongs to Phase 5, this proposal is already blocking
today's Phase 2 dogfooding. It reduces merge drag for the current parallel feature model without
requiring the full multi-developer architecture.

## Open Questions

1. Which Iteration 0 tests are hard blockers before any migration, and which may be marked as
   planned gaps if a deterministic fixture is too expensive?
2. Which tracked runtime files can be safely untracked immediately, and which require one-release
   compatibility warnings first?
3. Should `.specify/feature.json` remain tracked as a bootstrap baseline with an empty value, or
   become fully worktree-local?
4. Should `.squad/decisions.md` dual-write continue forever as an aggregate, or become generated
   from per-feature decision logs?
5. Should collision checks use only local worktrees by default, or also fetch and inspect remote
   feature branches?
6. What is the hard-error threshold: same central hub file, same source file, release-only file, or
   only same source file plus same function/section?

## Risks

- **Over-warning**: developers may ignore noisy collision warnings. Mitigate with the registry and
  risk tiers instead of treating every overlap as equal.
- **State migration risk**: untracking a state file too early may break older installed Specrew
  versions. Mitigate with dual-read and phased migration.
- **Generated mirror ambiguity**: some generated files are currently user-visible active surfaces.
  Mitigate by requiring canonical-source traceability or a parity reason.
- **False confidence**: file-level collision checks do not catch semantic conflicts. Mitigate by
  framing this as a floor, not a replacement for review or merge coordination.

## Cross-References

- Related proposals: 008, 010, 026, 091, 097, 115, 134, 145, 148, 149, 159, 160, 161, 163.
- Current empirical sources: active parallel worktrees for Feature 141, Feature 159, Proposal 160,
  and Proposal 161; 2026-06-06 churn audit of last-30-day changed files.
- Composability: Proposal 148 can consume the registry and collision report; Proposal 149 can use
  the same classification for merge briefs; Proposal 115 can use the classifications to assign
  high-independence task slices.

## Status History

- 2026-06-06: Created as a candidate after concurrent-worktree audit showed repeated collisions on
  tracked runtime state, generated mirrors, proposal indexes, release metadata, and central hub
  scripts.
- 2026-06-06: Amended to require an Iteration 0 coverage foundation before any major state,
  generated-surface, or ledger refactor.
- 2026-06-06: Scope-fit review kept this as a standalone concurrency proposal, while routing
  broader refactor-prevention concerns to 008, 091, 145, and 163.
