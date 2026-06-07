# Implementation Plan: Retire Top-Level Evaluation Surface

**Feature**: 170-retire-evaluation-surface
**Branch**: `170-retire-evaluation-surface`
**Created**: 2026-06-06
**Spec**: `specs/170-retire-evaluation-surface/spec.md`
**Estimated effort**: 1-2 SP, single iteration

## Summary

Proposal 169's implementation already exists on this branch as adoption
snapshot `3b6a3e0d` (produced ungoverned by a Codex session, adopted at
feature creation). This plan therefore directs a **verification-first
iteration**: empirically prove each FR against the adopted changes, fix any
gap found, and produce the governance evidence the adoption skipped. No
greenfield implementation is expected.

## Clarified Decisions

Clarify was skipped with recorded rationale (spec Clarifications section,
human-approved at the specify verdict). Binding decisions from the intake
workshop (architecture-core, human-confirmed):

1. The scorer is **test infrastructure**; supported surface = the two CI
   integration-test entry points only.
2. `tests/support/` is the long-term home for shared test infrastructure.
3. Clean break: no stub or pointer remains for a future evaluation surface;
   docs carry retirement-explanation wording only.
4. Generated report output is untracked scratch/test-result space
   (default `<project>/test-results/process-quality-report.md`).

## Delta From Shipped Behavior

- Shipped behavior (pre-170): tracked `evaluation/` directory with stale
  README/report and the live scorer; tests referenced
  `evaluation/scorers/process-scorer.ps1`.
- Adopted delta (`3b6a3e0d`): directory deleted; scorer at
  `tests/support/process-quality-scorer.ps1` (99% rename); 4 test callers,
  docs, known-traps, copilot-instructions, both
  `handoff-governance-validator.ps1` mirrors, and worf history updated.
- Remaining delta for this iteration: verification evidence + any gap fixes.

## Technical Context

- PowerShell 7 repo; tests are plain `.ps1` PASS/FAIL scripts plus Pester
  `.tests.ps1` suites run by CI (`.github/workflows/specrew-ci.yml`).
- The scorer is a pure, parameterized script (no module export); consumers
  invoke it by path. Param surface: `-ProjectPath`, `-IterationPath`,
  `-AsJson`, `-PassThru`, `-WriteReport`, `-ReportPath`.
- The multi-host lifecycle smoke test parses the scorer file and asserts a
  Linux-safe forward-slash path form (AC4).

## Phase 1 Quality Planning

### Stack Surfaces in Scope

| Surface | In scope | Notes |
| --- | --- | --- |
| PowerShell test scripts (`tests/`) | yes | moved scorer + 4 callers |
| Docs (`docs/`, `.github/`, `.specrew/quality/`) | yes | reference truthfulness only |
| Validator mirrors (`extensions/`, `.specify/`) | yes | path-reference updates only |
| Product runtime (module, scripts/) | no | untouched by this slice |

### Risk Dimensions

| Risk | Materiality | Mitigation |
| --- | --- | --- |
| Scorer move breaks CI consumers | high | run both integration tests empirically (FR-003/FR-004) |
| Report writes into tracked space | medium | assert default path resolves under untracked `test-results/` (FR-004) |
| Path-separator regression on Linux | medium | smoke-test forward-slash assertion (FR-005) |
| Stale references survive in active surfaces | medium | SC-004 repo-wide scan at review |
| History rewritten | low | FR-008 immutability check on fixtures/historical specs |

### Quality Tool Bundle

`validate-governance.ps1` per boundary; `markdownlint-cli` per markdown
boundary commit; the repo's own integration/Pester suites as the empirical
verification layer.

### Required Quality Gates

Specify-lens gate (passed at sync), before-implement hardening gate,
review-signoff with reviewer artifacts, markdownlint per boundary.

### Phase 2 Hardening Planning

**Phase 2 Slice Scope**: `US-2 hardening-gate planning only; pre-implementation readiness must accept planning-time analysis, expected controls, rationale, and explicit non-applicable reasoning, while runtime-only final proof stays pending until later closure or approved runtime-only deferment.`
**Hardening Gate Artifact**: `specs/<feature>/iterations/<NNN>/quality/hardening-gate.md`
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`
**Trap Reapplication Artifact**: `specs/<feature>/iterations/<NNN>/quality/trap-reapplication.md`

#### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status |
| --- | --- | --- | --- |
| Security surface analysis | No auth/secrets/privacy surface; file moves + doc edits only. Explicit non-applicable reasoning recorded at the gate. | `specs/<feature>/iterations/<NNN>/quality/hardening-gate.md` | `not-applicable` |
| Error handling and failure semantics | The report test must tolerate a missing scratch directory (spec edge case); the scorer creates the report directory on demand. | `specs/<feature>/iterations/<NNN>/quality/hardening-gate.md` | `required` |
| Retry and idempotency expectations | Deterministic local test scripts; reruns rebuild scratch space from scratch. Recorded as non-applicable with reasoning. | `specs/<feature>/iterations/<NNN>/quality/hardening-gate.md` | `not-applicable` |
| Test-integrity targets | The whole slice IS test continuity: AC2-AC4 must run empirically, not be inferred from file presence (beta-validation lesson 2026-05-31). | feature plan Phase 2 quality planning section plus `specs/<feature>/iterations/<NNN>/quality/quality-evidence.md` | `required` |

#### Lens Activation Plan

| Lens / Checklist Ref | Activation | Why Activated or Omitted | Planned Evidence / Artifact Path |
| --- | --- | --- | --- |
| `security-baseline@v1.0.0` | `required` | Always a materially reviewed baseline dimension; row-level execution stays deferred. | `specs/<feature>/iterations/<NNN>/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | `required` | Failure semantics of the report-path/scratch handling feed the hardening gate. | `specs/<feature>/iterations/<NNN>/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | `required` | Test-integrity targets are the core of this verification-first slice. | `specs/<feature>/iterations/<NNN>/quality/lenses/test-integrity.md` |

#### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Required hardening and bug-hunter lenses | `strongest-available` | Record when execution happens | Explicit approved lower-tier override required before any downgrade takes effect. | Planning publishes the requested routing baseline only. |

#### Explicit Later Deferrals

- Full line-by-line lens execution evidence remains deferred until the approved implementation/review slice authorizes it.
- Known-traps corpus seeding and trap reapplication remain deferred until the dedicated known-traps slice is in scope.
- Strongest-class routing enforcement details remain deferred until the routed lens execution path exists.

## Expected Implementation Surfaces

Already adopted in `3b6a3e0d` (verification targets, not new work):

- `tests/support/process-quality-scorer.ps1` (moved scorer)
- `tests/integration/process-quality-scorer.ps1`, `process-quality-report.ps1`,
  `multi-host-lifecycle-smoke.tests.ps1`, `project-path-resolution-regression.ps1`
- `docs/user-guide.md`, `docs/release-notes-v0.27.0.md`
- `.specrew/quality/known-traps.md`, `.github/copilot-instructions.md`
- `extensions/specrew-speckit/validators/handoff-governance-validator.ps1` + `.specify` mirror
- `templates/squad/agents/worf/history.md`, `.squad/skills/process-quality-scoring/SKILL.md`

New surfaces this iteration: iteration governance artifacts only (plus any gap
fix the verification uncovers).

## Implementation Strategy

Single iteration, verification-first ordering:

1. Structural assertions (FR-001, FR-002): tracked-file listing + scorer location.
2. Empirical test runs (FR-003, FR-004, FR-005): both integration tests + the
   smoke suite + the path-resolution regression; capture exit codes + report path.
3. Reference truthfulness (FR-006, SC-004): repo-wide `evaluation/` scan with
   the two allowed exception classes.
4. Audit trail + history (FR-007, FR-008): proposal/index evidence; fixture
   immutability vs `main`.
5. Fix any gap found, re-run the affected check, record drift if the spec needs
   reconciliation.

## FR Traceability Matrix

| FR | Verification | Evidence artifact |
| --- | --- | --- |
| FR-001 | `git ls-files evaluation/` empty | quality-evidence.md |
| FR-002 | scorer exists at `tests/support/`; no other copy tracked | quality-evidence.md |
| FR-003 | `tests/integration/process-quality-scorer.ps1` exit 0 | quality-evidence.md (run log) |
| FR-004 | `tests/integration/process-quality-report.ps1` exit 0; report under untracked `test-results/` | quality-evidence.md (run log) |
| FR-005 | smoke suite passes incl. scorer-parse + forward-slash assertions | quality-evidence.md (run log) |
| FR-006 | SC-004 scan: only retirement-wording + frozen-fixture hits | quality-evidence.md (scan output) |
| FR-007 | Proposal 169 on main (`262325d3`) + INDEX entry | review.md |
| FR-008 | `git diff main -- tests/unit/fixtures/ specs/0*` empty for historical paths | quality-evidence.md |

## Test Plan

No new test files are expected: the moved suites ARE the test plan. The
iteration's test work is running them and recording evidence. If verification
exposes a gap (e.g., a missed caller), the fix lands with a covering assertion
in the affected suite.

## Review Output Requirements

Reviewer artifacts (code-map, coverage-evidence, reviewer-index,
review-diagrams, dependency-report) are required because code/manifests were
touched. Review must check the SC-004 scan output and the empirical run logs,
not file presence (runtime-deliverable lesson, 2026-05-31).

## Project Structure

### Planning Artifacts

- `specs/170-retire-evaluation-surface/spec.md`
- `specs/170-retire-evaluation-surface/plan.md` (this file)
- `specs/170-retire-evaluation-surface/data-model.md`
- `specs/170-retire-evaluation-surface/quickstart.md`
- `specs/170-retire-evaluation-surface/contracts/retire-evaluation-surface.md`
- `specs/170-retire-evaluation-surface/review-diagrams.md`
- `specs/170-retire-evaluation-surface/lens-applicability.json` + `workshop/`
- `specs/170-retire-evaluation-surface/iterations/001/` (scaffolded at tasks)

## Complexity Tracking

No new abstractions, no new dependencies, no architectural debt introduced.
Reversibility recorded in the workshop diagram artifact.

## Out of Scope

- Designing the deferred outcome-quality scorer.
- Reworking historical shipped artifacts that mention `evaluation/`.
- Changing CI job names or the process-quality test semantics.
- Creating a new product-facing evaluation command.
