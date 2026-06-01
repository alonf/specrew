# Implementation Plan: Boundary Authorization Prompt Truth + Human Re-entry Packet

**Branch**: `139-boundary-authorization-prompt-truth`
**Date**: 2026-06-01
**Spec**: [spec.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/spec.md)
**Input**: Feature specification from [spec.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/spec.md), Proposal 154, Feature 016, and human-approved planning instructions for Proposal 145 review-lens quality.

## Summary

This feature fixes the generated `specrew start` lifecycle contract so prompt truth, state truth, and boundary policy agree. The implementation will make `.specrew/config.yml` the authoritative boundary policy source, project the resolved policy into `boundary_enforcement.policy_classes` in generated [start-context.json](file:///C:/tmp/Specrew-main-boundary-auth/.specrew/start-context.json), and render [last-start-prompt.md](file:///C:/tmp/Specrew-main-boundary-auth/.specrew/last-start-prompt.md) from that resolved policy rather than from the beta2-bad four-gate hard-coded list.

The feature also replaces thin approval prompts with the clarified six-section human re-entry packet:

- `What I just did`
- `Why I stopped`
- `What needs your review`
- `What happens next`
- `Discussion prompts`
- `What I need from you`

The future generated prompt should use that packet as the primary stop contract rather than requiring duplicate legacy `=== SPECREW HANDOFF ===` output. Current handoff blocks remain transitional until the feature is implemented. Packet review targets must include bare `file:///` links, release-blocking items must be highlighted, discussion prompts must be shown together with an "approve with the defaults" affordance, and `discuss prompt #N` must run a short item-specific discussion loop before asking again for explicit boundary approval.

The implementation remains narrow: it does not implement full Proposal 150, hook-based runtime enforcement, broad historical Proposal 151 migration, or a new lifecycle model.

## Context Load

Planning loaded and preserves these governing inputs:

| Source | Loaded Context | Planning Effect |
| --- | --- | --- |
| [Proposal 154](file:///C:/tmp/Specrew-main-boundary-auth/proposals/154-boundary-authorization-prompt-truth.md) | Beta2 prompt told agents only four gates hard-block and to continue automatically from clarify into plan/tasks. | Remove the false four-gate rule and auto-chain guidance; make default `clarify -> plan` stop explicit. |
| Beta2 smoke failure | Fresh Copilot/Squad smoke auto-ran from clarify into plan, changed `Status: Approved`, and lacked human verdict evidence. | Add negative prompt tests, a narrow `Status: Approved` evidence check, and committed beta3 smoke evidence. |
| Feature 016 contract | Boundary stops are human re-entry points; one approval advances at most one boundary; handoffs must explain substance, stop reason, review target, and verdict. | Preserve one-boundary-at-a-time discipline and console-first human understanding. |
| Clarified Feature 139 spec | The new packet has six sections, contextual prompts, bare `file:///` links, explicit approval requirement, and plan/task previews. | Implement the six-section packet and test non-compliant handoff fixtures. |
| [Proposal 145](file:///C:/tmp/Specrew-main-boundary-auth/proposals/145-structured-multi-phase-reviewer.md) | Structured review lens: context load, branch hygiene, functional correctness, NFRs, code quality, test integrity, system safety, output synthesis. | Use the lens as planning/review quality bar only; do not implement Proposal 145 artifacts or validators. |

## Technical Context

**Language/Version**: PowerShell 7.x scripts plus Markdown/YAML/JSON governance artifacts
**Primary Dependencies**: Git, `.specrew/config.yml`, `.specrew/start-context.json`, `.squad/decisions.md`, Pester-style PowerShell integration tests
**Storage**: File-based repository state under `.specrew/`, `.squad/`, `scripts/`, `extensions/`, `.specify/extensions/`, `tests/`, and `specs/`
**Testing**: PowerShell integration scripts, validator checks, prompt fixture assertions, beta smoke evidence
**Target Platform**: Windows and downstream Specrew project startup flows
**Project Type**: Specrew governance/prompt generation tooling
**Constraints**: Do not alter tool-call approval defaults; do not bypass lifecycle boundary approval; keep implementation scoped to prompt/state/validator/test surfaces

## Branch and State Hygiene

Before implementation begins, classify dirty state so unrelated runtime/session edits do not enter feature commits.

| Status Class | Paths / Evidence | Planned Handling |
| --- | --- | --- |
| Existing unrelated runtime/session edits | `.codex/agents/*.toml`, `.github/agents/squad.agent.md`, `.squad/casting/registry.json`, `.squad/config.json`, `.squad/decisions.md`, `.squad/identity/now.md`, `specs/051-multi-session-foundation/iterations/003/tasks-progress.yml`, `.cursor/`, `.specrew/version-check-cache.json`, `.squad/active-features.yml`, `.squad/events/` | Do not stage unless a file becomes a required lifecycle artifact for Feature 139. Review diffs before any boundary commit. |
| Feature 139 planning artifacts | `specs/139-boundary-authorization-prompt-truth/*` | Stage and commit as focused lifecycle evidence. |
| Future implementation edits | `scripts/specrew-start.ps1`, prompt/governance templates, validator/tests, mirrors | Stage only feature-scoped changes with focused boundary commits. |

Boundary commits are durable evidence. Each lifecycle boundary must be committed before sync and before requesting the next human verdict.

## Phase 1 Quality Planning

**Phase Scope**: `proposal-154-prompt-truth-and-re-entry-contract`
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`
**Selected Review Lens**: Proposal 145 structured review lens as a quality bar, not as implementation scope.

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| `start-prompt-generation` | `scripts/specrew-start.ps1` | PowerShell prompt generator | Owns generated [last-start-prompt.md](file:///C:/tmp/Specrew-main-boundary-auth/.specrew/last-start-prompt.md) and generated lifecycle instructions. |
| `coordinator-governance-text` | `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`, `.github/agents/squad.agent.md`, host mirrors if touched | Markdown prompt/governance templates | Must agree with generated prompt vocabulary and human re-entry packet contract. |
| `boundary-policy-state` | `.specrew/config.yml`, generated `.specrew/start-context.json` | YAML/JSON state | Policy classes must resolve from config and become auditable in start context. |
| `validator-and-status-check` | `extensions/specrew-speckit/scripts/validate-governance.ps1`, `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`, related helpers if needed | PowerShell validator | Narrowly flags `Status: Approved` without human verdict evidence. |
| `regression-tests` | `tests/integration/start-command.ps1`, `tests/integration/launch-mode-boundary-enforcement.tests.ps1`, new fixtures if needed | PowerShell integration tests | Proves prompt truth, six-section packet, negative fixtures, and status-evidence checks. |
| `smoke-evidence` | `specs/139-boundary-authorization-prompt-truth/smoke/` | Markdown evidence | Records beta3 smoke version, fresh project path, stop boundary, pre-approval plan state, packet excerpt, and PASS/FAIL. |

### Risk Dimensions

| Risk Dimension | Status | Rationale |
| --- | --- | --- |
| Governance integrity | required | The bug is a governance truth mismatch that caused a lifecycle boundary bypass. |
| State truth | required | Generated prompt text must match generated `boundary_enforcement.policy_classes`. |
| Test integrity | required | Tests must reject beta2-bad phrases and non-compliant handoffs, not merely check happy-path text exists. |
| Human factors | required | Boundary stops must be useful re-entry points, not thin approval prompts. |
| Branch hygiene | required | Existing dirty runtime/session files must not be mixed into feature evidence. |
| Security/privacy | required | Human verdict evidence and approval semantics are authorization-adjacent and must not be fabricated. |
| Runtime concurrency | not-applicable | The feature changes startup prompt/state generation and validation, not concurrent runtime behavior. |

### Proposal 145 Gate-Validation Plan

| Review Phase | Required Checks for This Feature | Planned Evidence |
| --- | --- | --- |
| Phase 0 - Context load | Load Proposal 154, beta2 smoke failure, Feature 016 handoff contract, six-section packet, and Proposal 145 lens. | This plan, [data-model.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/data-model.md), [quickstart.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/quickstart.md). |
| Phase 1 - Branch hygiene | Classify dirty files before next boundary; keep unrelated session/runtime edits out of feature commits; use boundary commits as durable evidence. | Plan branch hygiene table, `git status`, focused commits. |
| Phase 2 - Functional correctness | Map every FR to implementation and tests; derive policy from `.specrew/config.yml`; include resolved `policy_classes`; stop at `clarify -> plan`. | FR traceability matrix, tests, smoke evidence. |
| Phase 3 - Non-functional requirements | Keep prompt/state behavior auditable, preserve backwards-compatible startup flows, avoid secret/PII leakage in smoke evidence. | Review gap ledger and smoke evidence redaction check. |
| Phase 4 - Code quality | Keep helper changes small, deterministic, and mirrored where repository convention requires. | Code review, PSScriptAnalyzer/lint where available, no speculative abstraction. |
| Phase 5 - Test coverage and integrity | Positive prompt contract tests; negative beta2 phrase tests; status-approved contradiction test; missing `Why I stopped` fixture; approve-only fixture. | New/updated integration tests and fixtures. |
| Phase 6 - System safety and ops | Committed beta3 smoke evidence; out-of-scope protections for Proposal 150, hook enforcement, and broad Proposal 151 migration. | Smoke artifact, review gap ledger, explicit out-of-scope checks. |
| Phase 7 - Output synthesis | Review must classify implemented/enforced/observable/documented and fix or send back any gap. | `review.md` gap ledger at review boundary. |

## Constitution Check

- **Spec Authority Gate**: PASS - the plan follows [spec.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/spec.md), Proposal 154, and the approved clarify instructions.
- **Lifecycle Boundary Gate**: PASS - planning is authorized only for `clarify -> plan`; the next stop is `plan -> tasks`.
- **Scope Gate**: PASS - full Proposal 150, hook enforcement, broad historical Proposal 151 migration, and lifecycle model redesign remain out of scope.
- **Traceability Gate**: PASS - every FR maps to implementation surface and test/evidence below.
- **State Truth Gate**: PASS - plan requires `.specrew/config.yml` as authority and `start-context.json` policy snapshot as audit evidence.
- **Review Lens Gate**: PASS - Proposal 145 is applied as a quality bar without implementing its skill, static validator, phase outputs, or schema.
- **Branch Hygiene Gate**: PASS - dirty files are classified and excluded unless required by Feature 139.

## Implementation Strategy

1. Add or update a deterministic policy-resolution path used by `specrew start` so boundary classes come from `.specrew/config.yml`.
2. Persist the resolved snapshot to `boundary_enforcement.policy_classes` in generated [start-context.json](file:///C:/tmp/Specrew-main-boundary-auth/.specrew/start-context.json).
3. Render lifecycle quick-reference and boundary authorization guidance from the resolved classes, including the default `clarify -> plan` human-judgment stop.
4. Replace generated human approval-stop wording with the six-section human re-entry packet contract and explicit one-boundary approval semantics.
5. Add prompt-regression tests and fixtures for:
   - positive policy-derived boundary list/snapshot rendering
   - `clarify -> plan` stop
   - all six packet sections
   - contextual discussion prompts
   - mandatory bare `file:///` review targets
   - beta2-bad phrase rejection
   - missing `Why I stopped`
   - approve-only handoff without discussion prompts
6. Add the narrow `Status: Approved` without human verdict evidence check.
7. Add grouped discussion prompt and `discuss prompt #N` guidance without expanding into runtime hook enforcement.
8. Add committed beta3 smoke evidence under [smoke/](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/smoke/).

## FR Traceability Matrix

| Requirement | Implementation Surface | Planned Tests / Evidence |
| --- | --- | --- |
| FR-001 | Remove four-gate-only generated wording from `scripts/specrew-start.ps1` and templates. | Negative prompt test rejects `only gate that HARD-BLOCKS`. |
| FR-002 | Resolve policy from `.specrew/config.yml` into prompt rendering. | Test compares generated boundary list to configured human-judgment classes. |
| FR-003 | Remove auto-chain guidance for clarify through plan/tasks. | Negative prompt test rejects `continue automatically through` plus plan/tasks context. |
| FR-004 | Render explicit `clarify -> plan` authorization rule. | Positive generated prompt assertion; beta3 smoke stop evidence. |
| FR-005 | Prompt guidance forbids agent-authored `Status: Approved` without verdict. | Status-approved contradiction fixture/check. |
| FR-006 | Align sync docs/governance/generated prompt vocabulary. | Review diff across prompt surfaces; prompt vocabulary assertion. |
| FR-007 | Add beta2-bad phrase tests. | Integration prompt-regression test seeded with bad prompt text. |
| FR-008 | Define approval stop as re-entry packet. | Generated prompt includes packet contract, not bare approval. |
| FR-009 | Include all six packet sections. | Positive section-name assertion; negative missing-section fixture. |
| FR-010 | Require meaningful `What I just did`. | Handoff fixture contract test or reviewer checklist assertion. |
| FR-011 | Require concrete `Why I stopped`. | Missing `Why I stopped` fixture fails. |
| FR-012 | Require targeted `file:///` review surfaces. | Positive bare `file:///` assertion; handoff fixture review. |
| FR-013 | Preview next phase, artifacts, code/planning status, hard-to-change decisions, next stop. | Positive packet-content assertion. |
| FR-014 | Require contextual, proactive, decision-reducing prompts. | Context-free prompt fixture fails unless no-known-dilemma question is present. |
| FR-015 | Prompt structure includes context, question, default, and consequence when relevant. | Positive targeted-prompt fixture. |
| FR-016 | Enumerate allowed response shapes. | Generated prompt assertion. |
| FR-017 | Free-form feedback is not approval. | Prompt assertion and smoke evidence notes. |
| FR-018 | Encourage discussion as normal path. | Generated prompt assertion. |
| FR-019 | Preserve discussion/free-form menu affordance. | Host-guidance assertion where structured menu text is generated. |
| FR-020 | Write `boundary_enforcement.policy_classes` snapshot. | Start-context JSON assertion. |
| FR-021 | Narrow status/verdict evidence check. | Validator/unit fixture with `Status: Approved` and no verdict evidence. |
| FR-022 | Committed beta3 smoke evidence. | Smoke artifact with version, project path, stop boundary, plan state, packet excerpt, PASS/FAIL. |
| FR-023 | Human re-entry packet is the primary future stop contract, not duplicated with legacy handoff block. | Prompt assertion for no required legacy duplication. |
| FR-024 | Bare `file:///` links in primary packet review targets. | Positive review-target assertion. |
| FR-025 | High-impact/release-blocking items called out in review section. | Prompt assertion for `Status: Approved` and beta3 smoke evidence callouts. |
| FR-026 | Discussion prompts shown together with approve-with-defaults affordance. | Positive grouped-prompt assertion. |
| FR-027 | `discuss prompt #N` loop summarizes decision and re-asks for explicit approval. | Prompt/fixture assertion for discussion-loop semantics. |
| FR-028 | Response options include approve as-is, approve with instructions, send back, and discuss prompt `#N`. | Positive response-option assertion. |

## Test Plan

| Test Area | Positive Coverage | Negative Coverage |
| --- | --- | --- |
| Policy-derived prompt truth | Generated prompt lists/summarizes configured `human-judgment-required` boundaries and `clarify -> plan`. | Prompt with hard-coded four-gate-only language fails. |
| Start-context snapshot | Generated [start-context.json](file:///C:/tmp/Specrew-main-boundary-auth/.specrew/start-context.json) includes `boundary_enforcement.policy_classes`. | Missing snapshot fails prompt-generation or regression assertion. |
| Auto-chain prevention | Prompt says readiness helpers do not authorize boundary crossing. | `continue automatically through` plan/tasks fixture fails. |
| Six-section packet | Generated packet contract includes all six sections. | Missing `Why I stopped` fixture fails. |
| Discussion prompts | Targeted prompt includes context/default/consequence; no-known-dilemma prompt uses general improvement question. | Approve-only fixture and context-free targeted prompt fail. |
| Discussion loop | Generated guidance supports grouped prompts, approve-with-defaults, and `discuss prompt #N`. | Missing grouped prompts or no renewed explicit approval after discussion fails. |
| Status approval contradiction | Feature artifact `Status: Approved` with no verdict evidence is flagged. | `Status: Ready for Planning` or `Status: Approved` with matching verdict evidence does not fail. |
| Smoke evidence | Beta3 smoke records tested version, fresh project path, stop boundary, pre-approval `plan.md` state, packet excerpt, PASS/FAIL. | Missing smoke fields block release closeout. |

Expected commands during implementation/review:

```powershell
pwsh -File tests/integration/start-command.ps1
pwsh -File tests/integration/launch-mode-boundary-enforcement.tests.ps1
pwsh -File tests/unit/validate-governance.interaction-model.tests.ps1
pwsh -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .
```

Exact command set may be narrowed during implementation if test ownership lands in more focused new files.

## Review Output Requirements

Review must include a gap ledger classifying every lifecycle/governance behavior as:

- `implemented`
- `enforced`
- `observable`
- `documented`

Any gap in those dimensions must be fixed or explicitly sent back before release promotion. The review must not accept a feature whose prompt text, state snapshot, tests, smoke evidence, or documentation disagree about boundary authorization.

## Project Structure

### Documentation and Planning Artifacts

```text
specs/139-boundary-authorization-prompt-truth/
├── spec.md
├── plan.md
├── data-model.md
├── quickstart.md
├── review-diagrams.md
├── contracts/
│   └── boundary-authorization-prompt-truth.md
└── smoke/
    └── beta3-smoke-evidence.md
```

### Expected Implementation Surfaces

```text
scripts/
└── specrew-start.ps1

extensions/specrew-speckit/
├── squad-templates/coordinator/specrew-governance.md
└── scripts/validate-governance.ps1

.specify/extensions/specrew-speckit/
└── scripts/validate-governance.ps1

tests/
├── integration/
└── unit/
```

## Complexity Tracking

No constitutional violations are planned. The main complexity control is keeping this as a prompt/state/test/validator slice and using Proposal 145 only as a review lens.

## Out of Scope

- Full Proposal 150 "next authorized action only"
- Hook-based runtime enforcement
- Broad historical Proposal 151 migration or backfill
- New lifecycle boundary types or lifecycle redesign
- Tool-call approval mode changes
- Fixing unrelated dirty runtime/session files
