# Implementation Plan: Design Gate Runtime Hardening + Smoke-Test Bundle

**Branch**: `141-design-gate-runtime-hardening` (stacked on the Feature 140 tip `d2363037`)  
**Date**: 2026-06-02  
**Spec**: file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/spec.md  
**Design Analysis**: file:///C:/Dev/Specrew-design-analysis/specs/141-design-gate-runtime-hardening/iterations/001/design-analysis.md (verdict `approved for plan with Option B`, decided at `337e2523`)  
**Input**: The clarified spec, the human design-analysis decision (Option B), Proposals 137/155/156, and before-plan quality readiness output.

## Summary

This feature hardens the Feature 140 design-analysis gate into an end-to-end,
human-felt, enforced experience and folds in a four-defect smoke-test bundle. It
is delivered across three iterations. Per the human design-analysis decision,
**Option B (Reasonable)** is the selected architecture: a template-file scaffold
reconciled with the validator contract, a callable pre-plan validator with
coordinator-prompt enforcement (no host-native hooks), a typed design-analysis
gate packet that is rendered-and-validated with a narrow durable "155-lite" packet
stored under `specs/<feature>/gates/` for the design-analysis gate only, a
lightweight read-only "Applicable Lenses" section, and focused block/pass tests.

The smoke-test defects (empty start-packet path segments, noisy downstream
warnings, fresh greenfield baseline commit handling, host wording leak) stay in
this feature and are sequenced into later iterations.

Deferred (out of this feature): the full Proposal 155 multi-boundary typed-packet
system, Proposal 156 lens overrides/schema/automation, Proposal 105 host-native
hooks, broad validator rollout, Unix install/wrapper surfaces, and beta/stable
publishing.

## Context Load

| Source | Loaded Context | Planning Effect |
| --- | --- | --- |
| Spec + clarify decisions | FR-021 = prompt + pre-plan validator (no 105 hooks); FR-020 = render+validate min, durable 155-lite preferred if narrow/cheap, design-analysis-gate-scoped; multi-iteration split; stacked-on-140 branch. | Plan adopts Option B inside these locked constraints and proposes the split + capacity below. |
| Design-analysis decision | Option B selected; durable packet stays scoped; no host hooks. | Architecture section reflects Option B; out-of-scope items preserved. |
| Proposal 137 | The parent gate; Feature 140 shipped only the validator + plan-boundary-sync enforcement. | Iteration 1 adds the missing scaffold, pre-plan validation, and typed packet. |
| Proposal 155 (scoped) | Typed packet rendering/validation/storage pattern. | Apply only to the design-analysis gate; do not generalize. |
| Proposal 156 (lightweight) | Repo-local design-lens files exist under the extension templates dir. | Render a read-only Applicable Lenses section; defer overrides/schema/automation. |
| Before-plan quality profile | Bounded custom Phase-1 composition: required code-quality, design-quality/SoC, verification-confidence, maintainability; N/A concurrency/resiliency/retry; lenses security/robustness/test-integrity baselines. | Plan embeds these dimensions; security lens is available but not exercised by this feature's behavior. |
| Dogfooding the F140 validator | Empirically found the validator's recommendation parser and By-the-book detection are brittle (see Dogfooding Findings). | Folded into Iteration 1 as FR-022/FR-023 per the 2026-06-02 directive; the scaffold/template also emits validator-passing artifacts. |

## Technical Context

**Language/Version**: PowerShell 7.x plus Markdown/YAML/JSON governance artifacts  
**Primary Dependencies**: Git, `.specrew/start-context.json`, Feature 140 `scripts/internal/design-analysis-gate.ps1`, `scripts/internal/sync-boundary-state.ps1`, `scripts/specrew-start.ps1`, extension templates, existing PowerShell tests  
**Storage**: File-based repository state under `.specrew/`, `scripts/`, `extensions/`, `.specify/extensions/`, `specs/<feature>/gates/`, `tests/`, `specs/`  
**Testing**: Focused PowerShell unit/integration tests plus existing governance validation  
**Target Platform**: Windows-hosted Specrew runtime and downstream/greenfield project flows  
**Project Type**: Specrew lifecycle governance/tooling  
**Constraints**: No host-native hooks; durable packet scoped to design-analysis gate only; no Unix/wrapper/bootstrap edits except minimal unavoidable smoke-bug fixes; no beta/stable publish; extend (not rewrite) the Feature 140 helper; stop again at plan -> tasks

## Branch and State Hygiene

This branch stacks on the unmerged Feature 140 tip because Iteration 1 depends on
Feature 140 runtime code. The worktree carries unrelated runtime/agent edits that
must not be staged for this feature.

| Status Class | Paths / Evidence | Planned Handling |
| --- | --- | --- |
| Existing unrelated runtime/session edits | `.claude/agents/*`, `.codex/agents/*.toml`, `.github/agents/squad.agent.md`, `.squad/*`, `specs/051-multi-session-foundation/iterations/003/tasks-progress.yml`, `.cursor/`, `.specrew/active-sessions.yml`, `.specrew/version-check-cache.json` | Leave unstaged. |
| Feature 140 reconciliation | `specs/140-design-analysis-gate/iterations/001/tasks-progress.yml` (reconciled to committed state during resume) | Out of this feature; leave for the Feature 140 owner. |
| Feature 141 artifacts | `specs/141-design-gate-runtime-hardening/*` | Stage and commit as boundary evidence. |
| Future implementation edits | helper extension, scaffold/template, pre-plan validator, packet renderer, start-prompt fixes, tests, docs | Stage only feature-scoped changes with focused boundary commits. |

## Architecture Decision

The design-analysis artifact compared three structural options (A Simplest, B
Reasonable, C By-the-book). The human verdict selected **Option B**.

| Option | Approach | Decision |
| --- | --- | --- |
| A: Simplest | Inline-template scaffold + prompt-only enforcement + transient packet. | Rejected — unauditable packet, scaffold/validator drift risk. |
| B: Reasonable | Template-file scaffold (reconciled with validator) + callable pre-plan validator + scoped durable 155-lite packet + lightweight lenses + tests. | **Selected.** |
| C: By-the-book | B plus host hooks, packet hashing/replay, lens-index automation. | Deferred — distinguishing elements are already-deferred scope and it breaks the cap. |

### Selected Pattern

Layered governance-helper extension:

1. A versioned `design-analysis.md` **template** owns the canonical artifact shape,
   reconciled with the Feature 140 validator contract (TG-007).
2. The Feature 140 `design-analysis-gate.ps1` helper gains a **scaffold path** and a
   **callable pre-plan validator** that reuses the existing validation core.
3. A **typed packet renderer/validator** for the design-analysis gate renders the
   six-section human packet from typed fields and persists a narrow durable packet
   under `specs/<feature>/gates/`.
4. Generated coordinator guidance owns the "don't author plan.md before the
   artifact + decision are valid" enforcement (FR-021), backed by the callable
   validator so it is checkable, not only narrated.
5. Tests own regression coverage for scaffold conformance, pre-plan block/pass,
   packet render/validate, and compatibility.

## Phase 1 Quality Planning

**Phase Scope**: `phase-1-first-slice`  
**Resolved Quality Profile**: `quality-profile.custom-composition.v1` (bounded custom composition; weak/unsupported preset signals for this governance-tooling surface)

### Risk Dimensions

| Risk Dimension | Status | Rationale |
| --- | --- | --- |
| Code quality | required | The pre-plan validator, scaffold, and packet renderer must be explicit and reviewable, not buried in prompt text. |
| Design quality and separation of concerns | required | Scaffold, validator, packet renderer, and enforcement must stay layered and extend (not rewrite) the Feature 140 helper. |
| Verification confidence | required | Tests must prove real block/pass and render/validate behavior, not file-presence. |
| Maintainability | required | The template-file + helper-function shape must remain simple enough to extend toward full Proposals 155/156 later. |
| Governance integrity | required | The feature changes a pre-plan stop and must not create a new silent bypass; human decision evidence must not be fabricated. |
| Robustness | required | Missing/invalid artifact, recommendation, or human decision must fail closed with actionable messages. |
| Concurrency correctness | not-applicable | No material shared-state/parallel/realtime behavior in this slice. |
| Resiliency | not-applicable | No retry/reconnect/degraded-recovery dependency in this slice. |
| Retry/idempotency and recovery | not-applicable | No retry or recovery workflow introduced. |
| Security | available, not exercised | Lens available; the feature only reads/validates local lifecycle artifacts — no auth, secrets, permissions, or network surfaces. |

### Quality Tool Bundle

| Area | Selection |
| --- | --- |
| Bundle ID | `phase1-custom-quality-bundle` from before-plan readiness |
| Mechanical Checks | dead-field, anti-pattern, test-integrity |
| Lens Refs | `security-baseline@v1.0.0`, `robustness-baseline@v1.0.0`, `test-integrity@v1.0.0` |
| Manual Evidence | This plan, the four review artifacts, the per-iteration review gap ledger |

### Explicit Deferrals

- Full Proposal 155 multi-boundary typed-packet system (packet hashing/replay, all gate-type templates, `gates/` for every boundary).
- Proposal 156 lens overrides, lens-schema validation, and broad lens automation.
- Proposal 105 host-native hook enforcement.
- Broad validator enforcement across existing/in-flight projects.
- Unix install/shell-wrapper/bootstrap surfaces and beta/stable publishing.

## Phase 2 Hardening Planning

**Hardening Gate Artifact** (per iteration): `specs/141-design-gate-runtime-hardening/iterations/<NNN>/quality/hardening-gate.md`

| Focus Area | Why It Matters | Planned Evidence | Status |
| --- | --- | --- | --- |
| Governance integrity / no-bypass | Pre-plan enforcement gates plan authoring; a bypass would defeat the feature. | Tests proving plan authoring is blocked before a valid artifact + decision. | required |
| Error handling / fail-closed | Missing/invalid evidence must produce actionable blocking output. | Negative tests + quickstart edge cases. | required |
| Test-integrity | Governance-heavy feature; file-presence ≠ runtime behavior. | Block/pass + render/validate tests, not existence checks. | required |
| Retry/idempotency | No retry workflow. | Hardening-gate not-applicable rationale. | not-applicable |

## Capacity Model and Iteration Split

Iteration capacity is **20 story_points** with no overcommit tolerance (the cap is
intentional and not raised). This feature is planned as **three iterations**, each
within the cap. Smoke-bug iterations confirm reproduction during their own
planning before implementation.

### Iteration 1 — Design-gate runtime path + validator robustness (18 SP)

| Work Item | Requirement Refs | Owner | Effort |
| --- | --- | --- | --- |
| `design-analysis.md` template file + scaffold path, reconciled with validator contract | FR-001, TG-007 | Implementer | 3 |
| Callable pre-plan validator + coordinator-prompt enforcement (no host hooks) | FR-002, FR-003, FR-021 | Implementer | 3 |
| Typed packet render + validate + narrow durable 155-lite packet under `gates/` | FR-004, FR-005, FR-006, FR-020 | Implementer | 4 |
| Selected-option → plan input continuity; extend (not rewrite) F140 helper | FR-007, FR-008 | Implementer | 1 |
| Validator robustness: tolerant By-the-book detection + single-recommendation parsing (incl. tests) | FR-022, FR-023, SC-014 | Implementer | 3 |
| Focused tests (scaffold conformance, block/pass, packet render/validate, compatibility) | SC-001..SC-005, SC-012 | Implementer, Reviewer | 3 |
| Docs (contract/quickstart/data-model/diagrams) + review gap ledger | TG-006, SC-011 | Planner, Reviewer | 1 |

**Total**: 18 story_points · **Capacity Status**: ok (2 SP headroom under the cap).
Per the 2026-06-02 directive, the lightweight **Applicable Lenses section
(FR-009/FR-010/SC-006, 2 SP) is pre-deferred** to a later Feature 141 iteration
(deferred-within-feature, not dropped) so Iteration 1 keeps headroom for
implementation reality. The validator robustness work (FR-022/FR-023) stays firm in
Iteration 1.

### Iteration 2 — Start-packet correctness (~7 SP)

| Work Item | Requirement Refs | Owner | Effort |
| --- | --- | --- | --- |
| Reproduce + fix empty `specs//...` path segments in generated start/handoff packets | FR-011 | Implementer | 2 |
| Reproduce + fix host wording leak (host-accurate launch guidance) | FR-014 | Implementer | 2 |
| Tests for path correctness and per-host wording | SC-007, SC-010 | Implementer, Reviewer | 2 |
| Docs + review evidence | TG-006 | Reviewer | 1 |

**Total**: 7 story_points · **Capacity Status**: ok · Both defects live in the start-prompt generator surface, so they bundle to reduce churn.

### Iteration 3 — Greenfield/downstream runtime hygiene (~9 SP)

| Work Item | Requirement Refs | Owner | Effort |
| --- | --- | --- | --- |
| Reproduce + suppress spurious greenfield/downstream warnings | FR-012 | Implementer | 3 |
| Reproduce + fix fresh greenfield baseline commit handling | FR-013 | Implementer | 3 |
| Tests for warning scope and baseline commit resolution | SC-008, SC-009 | Implementer, Reviewer | 2 |
| Docs + review evidence | TG-006 | Reviewer | 1 |

**Total**: 9 story_points · **Capacity Status**: ok · Both are greenfield/downstream behavior.

**Feature total**: ~36 story_points. Iteration 1 is **18 SP** (FR-022/FR-023 validator-robustness fixes folded in; the FR-009/FR-010 lens section pre-deferred per the 2026-06-02 directive). The pre-deferred lens (2 SP) is carried into a later Feature 141 iteration (sequenced at that iteration's planning — appended to a smoke-bundle iteration or a dedicated lens slice). The smoke-bug iteration scopes (2 and 3) will be re-confirmed at their own planning once reproduction is captured (spec assumption).

## Dogfooding Findings (Feature 140 validator)

Routing Feature 141 through its own design-analysis gate surfaced two brittle
behaviors in the Feature 140 validator (`scripts/internal/design-analysis-gate.ps1`):

1. **By-the-book detection is token-exact.** The option-block regex matches only
   the hyphenated `By-the-book`; an "Option C: By the book" heading is not
   recognized, firing a false "missing By-the-book" error.
2. **Recommendation parser fails on more than one option token.** It collects every
   `Option X|Simplest|Reasonable|By-the-book` token in the recommendation section
   and rejects more than one — so "Option B (Reasonable)" trips it (two tokens),
   and any comparative mention of other options fails. Under the case-insensitive
   flag, `[A-Z]` also matches lowercase, so prose like "option over" can create
   false tokens.

Per the 2026-06-02 human directive, both are **folded into this feature as FR-022
and FR-023** (validator robustness), scheduled in Iteration 1 within the cap. They
are not deferred to another feature. The fixes make the validator tolerant of
well-authored prose while still enforcing the option shape and a single
recommendation; in tandem, the Iteration 1 template/scaffold (FR-001) emits
artifacts that pass the validator. If realistic estimation pushes them over the cap,
they remain a named later-iteration obligation within Feature 141.

### Boundary-state hygiene findings (captured 2026-06-02; not Iteration 1 scope)

Initializing Feature 141's boundary state surfaced three boundary/runtime-state
hygiene issues. They are recorded here as **hardening findings / smoke-bundle
candidates** for a later Feature 141 iteration (or a sibling proposal); they do not
block before-implement and are not added to Iteration 1 scope:

1. **Global verdict-history (single active-feature model).** `boundary_enforcement.
   verdict_history` is one global list with no per-feature field, so Feature 140's
   entries remain above Feature 141's. The 141 cursor is clean (a real
   `approved for tasks` 141 crossing was recorded at `3d65dbc3`), and a real
   `tasks -> before-implement` 141 crossing is recorded on advance — so 140 entries
   do not authorize 141 advancement. Candidate fix: per-feature verdict scoping or a
   feature field on verdict entries.
2. **Decisions-ledger churn.** A boundary sync rewrote `.squad/decisions.md` 411/178
   lines for four small appends (line-ending / iteration-split churn), forcing
   clean-file-only commits (consistent with the Feature 140 retro). Candidate fix:
   stable line-ending handling / append-only discipline in the ledger writer.
3. **Active-session pointer lag.** `.specrew/active-sessions.yml` still named
   Feature 140 after the 141 sync (it is `specrew start`-managed); the authoritative
   141 signal is `start-context.json` `session_state`. Candidate fix: update the
   active-session pointer on boundary sync, or document the precedence.

## Constitution Check

- **Spec Authority Gate**: PASS — plan follows the clarified spec and the Option B design-analysis decision.
- **Lifecycle Boundary Gate**: PASS — planning is authorized only through `plan`; next stop is `plan -> tasks`. The plan-boundary design-analysis gate validates (Option B decision recorded).
- **Scope Gate**: PASS — full 155, 156 automation, 105 hooks, broad validator rollout, Unix surfaces, and release publishing remain out of scope.
- **Traceability Gate**: PASS — every FR maps to an iteration and a test/evidence surface below.
- **Compatibility Gate**: PASS — extends Feature 140; existing/in-flight features are not newly hard-failed.
- **Quality Gate**: PASS — before-plan quality output embedded; negative/runtime tests planned.

## FR Traceability Matrix

| Requirement | Iteration | Implementation Surface | Planned Tests / Evidence |
| --- | --- | --- | --- |
| FR-001 | 1 | `design-analysis.md` template file + scaffold path | Scaffolded artifact passes the F140 validator. |
| FR-002 | 1 | Callable pre-plan validator | Pre-plan check blocks before plan.md when artifact invalid. |
| FR-003 | 1 | Pre-plan validator + enforcement | Block until artifact valid + human decision recorded. |
| FR-004 | 1 | Typed packet renderer | Packet rendered from typed fields contains required sections. |
| FR-005 | 1 | Packet validator | Missing section / bare path fails packet validation. |
| FR-006 | 1 | Scope guard | Review confirms no multi-boundary 155 system added. |
| FR-007 | 1 | Selected-option propagation | Plan input preserves chosen option/modifications. |
| FR-008 | 1 | Helper extension | Review confirms F140 helper extended, not rewritten. |
| FR-009 | 1 | Applicable Lenses renderer | Artifact includes Applicable Lenses referencing existing lens files. |
| FR-010 | 1 | Scope guard | Review confirms no lens override/schema/automation added. |
| FR-011 | 2 | Start-packet path generation | No emitted path contains `specs//`. |
| FR-012 | 3 | Greenfield/downstream warning logic | No spurious warnings in greenfield/downstream runs. |
| FR-013 | 3 | Greenfield baseline commit handling | Baseline commit resolves to a real hash, recorded consistently. |
| FR-014 | 2 | Host wording in generated guidance | No non-selected-host terminology on a given host. |
| FR-015 | all | Scope guard | Smoke bugs remain in this feature. |
| FR-016 | planning | This capacity model | Iteration split + capacity recorded here. |
| FR-017 | all | Branch/state hygiene | Feature 140 closeout not forced; stacked branch documented. |
| FR-018 | all | Release scope review | No beta/stable publish changes. |
| FR-019 | all | Implementation scope review | Unix/wrapper/bootstrap untouched except minimal unavoidable fixes. |
| FR-020 | 1 | Packet persistence | Durable packet scoped to design-analysis gate under `gates/`. |
| FR-021 | 1 | Enforcement mechanism | Prompt + callable validator; no host hooks. |
| FR-022 | 1 | Validator By-the-book detection | Tolerant prose accepted; option shape still enforced. |
| FR-023 | 1 | Validator recommendation parser | One recommendation enforced; contextual mentions of rejected options pass. |

## Test Plan

| Test Area | Positive Coverage | Negative Coverage | Iteration |
| --- | --- | --- | --- |
| Scaffold conformance | Scaffolded `design-analysis.md` passes the F140 validator. | Stale/edited scaffold that breaks a required section fails. | 1 |
| Pre-plan enforcement | Plan authoring proceeds after valid artifact + decision. | Plan authoring blocked before valid artifact / before human decision. | 1 |
| Typed packet | Packet rendered from typed fields validates. | Missing section / bare path fails packet validation. | 1 |
| Applicable Lenses | Section lists relevant lenses; degrades gracefully when none apply. | — | 1 |
| Start-packet paths | All emitted paths have a non-empty feature segment. | Missing feature ref omits/placeholders rather than `specs//`. | 2 |
| Host wording | Selected host's wording only. | Claude launch shows no Copilot approval-mode text. | 2 |
| Downstream warnings | Greenfield/downstream emits only actionable warnings. | Self-host-only/in-flight warnings suppressed in greenfield. | 3 |
| Greenfield baseline commit | Baseline resolves to a real commit, recorded consistently. | Missing/wrong baseline detected. | 3 |

Expected commands during implementation/review:

```powershell
pwsh -File tests/unit/design-analysis-gate.tests.ps1
pwsh -File tests/integration/design-analysis-boundary.tests.ps1
pwsh -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .
```

## Project Structure

### Documentation and Planning Artifacts

```text
specs/141-design-gate-runtime-hardening/
├── spec.md
├── plan.md
├── data-model.md
├── quickstart.md
├── review-diagrams.md
├── checklists/requirements.md
├── contracts/
│   └── design-gate-runtime-hardening.md
└── iterations/001/
    └── design-analysis.md
```

### Expected Implementation Surfaces (Iteration 1)

```text
scripts/
├── specrew-start.ps1                      # coordinator enforcement guidance (iter 1); host wording + paths (iter 2)
└── internal/
    └── design-analysis-gate.ps1           # scaffold path + callable pre-plan validator + packet renderer (extend)

extensions/specrew-speckit/templates/
└── design-analysis.template.md            # new versioned scaffold template

specs/<feature>/gates/                     # narrow durable design-analysis packet (iter 1)

tests/
├── unit/
└── integration/
```

## Out of Scope

- Full Proposal 155 multi-boundary typed-packet system.
- Proposal 156 lens overrides, schema validation, and broad automation.
- Proposal 105 host-native hooks.
- Broad validator enforcement across existing/in-flight projects.
- Unix install/shell-wrapper/bootstrap surfaces; beta/stable publishing.
- Forcing Feature 140 feature-closeout.
