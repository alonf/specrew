# Iteration Plan: 005

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 6.6/25 story_points
**Started**: 2026-05-28
**Completed**: 2026-05-28

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
    (Common mistakes the validator REJECTS: `approved`, `in-progress`, `done`, `ready`.)
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
    Append explanatory notes in the Notes section at the bottom instead.
  - Task Status (in the Tasks table) MUST be one of:
      planned | in-progress | done | needs-rework | deferred | blocked
    (Note `in-progress` uses a hyphen, not an underscore. `done` not `completed`.)
-->

## Summary

Iteration `005` is the bounded **6-8 SP** Proposal `141` **Crew Interaction Profile / Persona Lens Separation** correction slice for Feature `049`. It updates user-facing wording and proof surfaces so Specrew clearly treats the four saved values as a **Crew Interaction Profile** for decision areas rather than job-title identities, preserves the internal four-lens architecture and stable persisted keys/internal persona IDs, carries soft collaboration guidance for all agents through current-user session context, keeps `/speckit.specify` as the only hard-applied behavior in this release, and preserves all Iteration `004` Proposal `120` commitments unchanged.

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-032 | First-run, `/specrew-user-profile`, `/speckit.specify`, and summary surfaces must describe the four saved values as a **Crew Interaction Profile** for `Product Strategy`, `UX/UI Design`, `Software Architecture`, and `AI Delivery Planning`. | US3 |
| FR-033 | Persisted schema keys and internal persona lens IDs remain unchanged, including `expertise.ai_research_project_management` and `ai-researcher-project-manager`. | US3 |
| FR-034 | The fourth visible decision-area label is fixed to `AI Delivery Planning` everywhere the user sees it. | US3 |
| FR-035 | Guidance must explicitly distinguish the user's **Crew Interaction Profile** from Specrew's **internal persona lenses** and explain the higher/lower-value behavior. | US3 |
| FR-036 | Docs, skills, and reviewer/operator guidance must explain two-level behavior consistently: soft session guidance for all agents, hard application only in `/speckit.specify`, and no Iteration `004` drift. | US3 |
| FR-037 | Tests and scripted evidence must prove legacy `user-profile.yml` compatibility with unchanged routing/depth behavior and updated visible wording. | US3 |
| FR-038 | `specrew start` and related session-context generation must surface the resolved current user's Crew Interaction Profile as soft runtime guidance for all agents without presenting it as shared project truth. | US3 |
| FR-039 | Durable shared instructions and shared agent guidance must point to the current-user profile loader/path rule rather than hard-coded dial values. | US3 |
| FR-040 | Outside `/speckit.specify`, the Crew Interaction Profile remains soft guidance only in this release. | US3 |
| FR-041 | Multi-developer safety must be preserved so different developers can use different local `user-profile.yml` files in the same repository without shared repo changes. | US3 |
| SC-007 | 100% of audited first-run/profile/help/session-context surfaces use Crew Interaction Profile framing and preserve 100% legacy profile compatibility without regression. | US3 |
| SC-008 | 100% of audited shared instruction surfaces point to the current-user loader/path rule, 0 shared-repository artifacts persist resolved per-developer settings, and paired-developer validation proves divergent local profiles are safe. | US3 |
| TG-016 | Proposal `120` remains fully anchored to Iteration `004`; this slice must not weaken it. | US3 |
| TG-017 | Iteration `005` is a bounded follow-on correction slice, not an Iteration `003` reopen. | US3 |
| TG-018 | Display labels stay fixed to the four decision areas, internal lenses stay unchanged, `/speckit.specify` stays the only hard-applied behavior, and durable guidance points to the loader/path rule. | US3 |

## Governance Consistency Check

| Gate | Verdict | Notes |
| ---- | ------- | ----- |
| Spec Authority | PASS | Scope is limited to `FR-032..FR-041`, `SC-007..SC-008`, and `TG-016..TG-018`. |
| Traceability | PASS | All planned workstreams and task rows below map directly to Proposal `141` and User Story `3`. |
| Capacity | PASS | Authorized effort band is now **6-8 SP** inside the canonical `25` story-point iteration-capacity model; this refreshed plan budgets `6.6` SP planned work plus `0.8` SP repair reserve without widening beyond the approved slice. |
| Roadmap Discipline | PASS | Iteration `003` stays closed, Iteration `004` stays reserved for Proposal `120`, and Iteration `005` remains the next bounded slice. |
| Compatibility Discipline | PASS | No schema migration, no key rename, no persona-ID rename, no fifth-lens work, and no committed per-developer profile values are allowed here. |
| Soft-vs-Hard Boundary | PASS | Current-user profile guidance is soft runtime context for all agents; `/speckit.specify` is the only hard-applied behavior in this release. |
| Before-Implement Readiness | PASS | The validator-facing task table now covers the full `FR-032..FR-041` / `SC-007..SC-008` scope with explicit owners, effort, and bounded execution order. |

## Open Questions Resolved

| Proposal 141 Question | Planning Decision |
| --------------------- | ----------------- |
| Final fourth visible decision-area label? | Use **AI Delivery Planning**. |
| How should the four visible labels be framed? | As a **Crew Interaction Profile** for decision areas, not as job titles or identity/persona claims the user must hold. |
| How should the profile behave outside `/speckit.specify`? | As **soft collaboration guidance** in current-user session context only; no other role, gate, or lifecycle surface hard-applies it in this release. |
| How should durable shared instructions refer to the profile? | By pointing to the **current-user profile loader/path rule** (`$env:USERPROFILE\.specrew\user-profile.yml` on Windows, `~/.specrew/user-profile.yml` on Unix-like systems, or the shared loader that resolves them). |
| How is multi-developer safety preserved? | By forbidding committed per-developer resolved settings and requiring paired-developer proof that different local profiles can coexist in the same repo. |

## Audit Inventory

| Surface Group | Why It Must Be Audited | Candidate Paths |
| ------------- | ---------------------- | --------------- |
| First-run bootstrap | The first prompt shapes how users answer the four decision-area dials and is the highest-risk wording surface. | `scripts/internal/user-profile.ps1`, `scripts/specrew-start.ps1` |
| Profile display / edit / reset | Existing profile management surfaces must show decision-area labels while keeping persisted keys and internal persona IDs unchanged. | `scripts/internal/user-profile.ps1`, `.github/skills/specrew-user-profile/SKILL.md`, `.claude/skills/specrew-user-profile/SKILL.md`, `.agents/skills/specrew-user-profile/SKILL.md` |
| Start summaries / reusable session context | Visible summaries and start-context artifacts must carry current-user soft guidance without implying shared project truth. | `scripts/specrew-start.ps1`, generated `.specrew/start-summary.md`, `.specrew/start-context.json`, `.specrew/last-start-prompt.md` |
| Specify prompt / agent guidance | These surfaces must explain that personas stay internal, the Crew Interaction Profile drives question depth, and `/speckit.specify` is the only hard-applied behavior. | `.github/prompts/speckit.specify.prompt.md`, `.github/agents/speckit.specify.agent.md` |
| Intake engine help / mirror surface | If the engine emits or documents user-facing wording, shipped and mirrored copies must stay aligned with the soft-vs-hard boundary. | `extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1`, `.specify/extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1` |
| Shared instructions / durable guidance | Shared guidance must reference the loader/path rule instead of concrete dial values or a specific developer's resolved settings. | `README.md`, `docs/user-guide.md`, reviewer/operator guidance surfaces |
| Reviewer / operator guidance | Reviewers must enforce capability-vs-lens separation, stable-key compatibility, soft-vs-hard boundary discipline, loader-rule correctness, and multi-developer safety. | `.specrew/team/agents/reviewer.md`, `.agents/agents/reviewer.md`, `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md`, `.specify/extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md`, Iteration `005` review/evidence artifacts |
| Tests / scripted evidence | This slice is not complete without explicit legacy-profile compatibility proof, shared-instruction audit, and paired-developer safety evidence. | `tests/integration/f049-i003-intake-engine-tests.ps1`, start/smoke tests if needed, `specs/049-pipeline-hardening-intake/iterations/005/quality/quality-evidence.md` |

## Planned Workstreams

| Workstream | Outcome | Requirements | Candidate Surfaces | Effort | Owner |
| ---------- | ------- | ------------ | ------------------ | ------ | ----- |
| W001 | Lock the shared Crew Interaction Profile wording and decision-area display contract without changing persisted keys or internal lens IDs | FR-032, FR-033, FR-034, FR-035, TG-017, TG-018 | `scripts/internal/user-profile.ps1`, runtime/help surfaces | 1.0-1.4 | Implementer |
| W002 | Surface current-user runtime session guidance for all agents while keeping the profile soft outside `/speckit.specify` | FR-035, FR-036, FR-038, FR-040 | `scripts/specrew-start.ps1`, start-summary/context artifacts, specify guidance | 1.1-1.5 | Implementer |
| W003 | Replace hard-coded shared guidance with current-user loader/path-rule references and preserve multi-developer safety | FR-039, FR-040, FR-041, SC-008 | Docs, reviewer/operator guidance, shared instruction surfaces | 1.0-1.4 | Implementer + Reviewer |
| W004 | Extend tests and scripted evidence to prove legacy-profile compatibility, loader-rule correctness, and paired-developer safety | FR-037, FR-039, FR-041, SC-007, SC-008 | `tests/integration/f049-i003-intake-engine-tests.ps1`, Iteration `005` evidence artifacts | 1.2-1.7 | Reviewer |

**Planned Total**: 4.3-6.0 story_points

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Create Iteration 005 audit scaffold and evidence envelope | FR-036, FR-037, FR-039, FR-041, SC-007, SC-008, TG-016, TG-017 | US3 | 0.4 | Reviewer | `specs/049-pipeline-hardening-intake/iterations/005/quality/quality-evidence.md` | done | claude | as-planned | pass |
| T002 | Add shared display-label metadata and Crew Interaction Profile helpers | FR-032, FR-033, FR-034, FR-035, TG-017, TG-018 | US3 | 0.8 | Implementer | `scripts/internal/user-profile.ps1` | done | claude | as-planned | pass |
| T003 | Add session-context profile summary helpers and current-user runtime markers | FR-032, FR-035, FR-038, FR-040, TG-018 | US3 | 0.8 | Implementer | `scripts/specrew-start.ps1`, `scripts/internal/user-profile.ps1` | done | claude | as-planned | pass |
| T004 | Add loader/path-rule guidance for shared instructions and agent surfaces | FR-039, FR-040, FR-041, TG-018 | US3 | 0.6 | Implementer | `README.md`, `docs/user-guide.md`, reviewer/operator guidance surfaces | done | claude | as-planned | pass |
| T005 | Add legacy-profile and paired-developer fixtures plus failing assertions | FR-033, FR-037, FR-039, FR-041, SC-007, SC-008, TG-018 | US3 | 0.8 | Reviewer | `tests/integration/fixtures/f049-legacy-user-profile/**`, `tests/integration/f049-i003-intake-engine-tests.ps1` | done | claude | as-planned | pass |
| T006 | Update first-run and profile/runtime wording to Crew Interaction Profile semantics | FR-032, FR-033, FR-034, FR-035, FR-038, TG-017, TG-018 | US3 | 0.9 | Implementer | `scripts/internal/user-profile.ps1`, `scripts/specrew-start.ps1` | done | claude | as-planned | pass |
| T007 | Refresh `/specrew-user-profile` help copy across shipped skill surfaces | FR-032, FR-034, FR-035, FR-036, FR-040, TG-018 | US3 | 0.5 | Implementer | `.github/skills/specrew-user-profile/SKILL.md`, `.claude/skills/specrew-user-profile/SKILL.md`, `.agents/skills/specrew-user-profile/SKILL.md` | done | claude | as-planned | pass |
| T008 | Align `/speckit.specify` and intake guidance to the hard-boundary + mirror-parity contract | FR-032, FR-035, FR-036, FR-038, FR-040, TG-017, TG-018 | US3 | 0.6 | Implementer | `.github/prompts/speckit.specify.prompt.md`, `.github/agents/speckit.specify.agent.md`, `extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1`, `.specify/extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1` | done | claude | as-planned | pass |
| T009 | Update downstream docs and reviewer/operator guidance for loader rule and multi-developer safety | FR-036, FR-039, FR-040, FR-041, SC-008, TG-016, TG-017, TG-018 | US3 | 0.6 | Implementer | `docs/user-guide.md`, `README.md`, `.specrew/team/agents/reviewer.md`, `.agents/agents/reviewer.md`, `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md`, `.specify/extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md` | done | claude | as-planned | pass |
| T010 | Run compatibility, shared-instruction, and paired-developer checks and record Proposal 141 evidence | FR-037, FR-038, FR-039, FR-040, FR-041, SC-007, SC-008, TG-016, TG-017, TG-018 | US3 | 0.6 | Reviewer | `tests/integration/f049-i003-intake-engine-tests.ps1`, `specs/049-pipeline-hardening-intake/iterations/005/quality/quality-evidence.md` | done | claude | as-planned | pass |

**Planned Task Total**: 6.6 story_points  
**Reserved Repair Headroom**: 0.8 story_points  
**Bounded Slice Truth**: Proposal `141` remains a **6-8 SP** correction slice inside the repository-wide `25` story-point iteration-capacity model.

## Required Quality Gates

| Gate | Target | Notes |
| ---- | ------ | ----- |
| Crew Interaction Profile audit | required | 100% of audited first-run/profile/help/session-context surfaces use `Product Strategy`, `UX/UI Design`, `Software Architecture`, and `AI Delivery Planning`. |
| Profile-vs-lens separation | required | Copy must explicitly distinguish the user's Crew Interaction Profile from Specrew's internal persona lenses. |
| Soft-vs-hard boundary | required | Only `/speckit.specify` may claim hard application in this release; all other surfaces must describe soft session guidance only. |
| Stable-key compatibility | required | No rename or migration of persisted keys or internal persona IDs is allowed. |
| Legacy profile proof | required | Existing `user-profile.yml` fixtures must load unchanged and preserve internal routing/depth behavior. |
| Loader/path-rule audit | required | Shared instruction surfaces must point to the current-user profile loader/path rule, not concrete dial values. |
| Multi-developer safety | required | Evidence must show divergent local profiles can coexist in the same repo without shared-repository profile-value persistence. |
| Reviewer guidance consistency | required | Reviewer/operator guidance must inspect wording correctness, loader-rule correctness, soft-vs-hard discipline, and preserved `004` vs `005` roadmap truth. |
| Mirror parity | required | Any wording/help change in shipped intake surfaces must be mirrored under `.specify` in the same boundary. |
| Planning truthfulness | required | No stale “3-5 SP” or `FR-032..FR-037`-only truth may remain in the feature-level or iteration-level planning package. |

## Planned Execution Order

1. **Lock the display and behavior contract first** — finalize the shared wording, decision-area mapping, soft-vs-hard boundary, and loader/path-rule language.
2. **Add failing proof next** — legacy-profile and paired-developer assertions must codify the contract before implementation is considered complete.
3. **Update runtime/profile/session surfaces next** — user-profile helpers and start flow carry the highest user-facing risk.
4. **Refresh skills, prompts, docs, and reviewer guidance after the runtime contract is stable** — this prevents terminology drift.
5. **Add evidence last** — the evidence artifact must validate the exact wording and shared-guidance rule that ships.

## Dependencies

- `W001` must establish the authoritative wording/mapping contract before downstream docs or tests can freeze.
- `W002` depends on the wording contract from `W001` and locks the runtime soft-guidance semantics.
- `W003` depends on the wording contract and runtime boundary established by `W001-W002`.
- `W004` depends on the wording, shared-guidance, and runtime surfaces being stable enough to audit.
- Task generation and execution must keep shipped and mirrored intake guidance coupled.

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Same unit used across Feature `049`. |
| Capacity per Iteration | 25 | Canonical repository iteration-capacity value from `.specrew/iteration-config.yml`; this plan remains a bounded slice within that wider model. |
| Iteration Bounding | scope | `scope` keeps Proposal `141` fixed to the approved correction slice only. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Authorized Slice | 6-8 | Human-approved correction band for Proposal `141`. |
| Planned Task Load | 6.6 | Explicit task-row total in this refreshed plan. |
| Repair Reserve | 0.8 | Preserves bounded headroom inside the `6-8 SP` slice. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds `25` story_points (capacity `25` x threshold `1.0`); this slice stays well below that cap. |
| Defer Strategy | manual | Any spillover requires explicit human approval; do not silently merge into Iteration `004`. |
| Calibration Enabled | true | Capture variance after execution because the slice is intentionally terminology-heavy and shared-guidance-sensitive. |

## Concurrency Rationale

- Shared wording, boundary, and loader-rule logic create a strong serial dependency up front.
- After the runtime/session contract lands, docs/skills/reviewer guidance can parallelize moderately.
- Compatibility tests should codify the contract early and validate the shipped wording later.
- Recommendation: keep implementation mostly sequential until the shared mapping + boundary are stable, then split docs/skills/reviewer guidance from final evidence preparation.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 0.60 | This artifact plus feature-plan refresh. |
| Implementation | 2.50-3.20 | Runtime wording, session-context, loader-rule, prompt, and skill updates. |
| Review Guidance | 0.80-1.20 | Reviewer/operator instruction refresh and shared-guidance audit shaping. |
| Verification / Evidence | 1.60-2.00 | Legacy-profile compatibility proof, loader-rule audit, and paired-developer safety evidence. |
| Rework Buffer | 0.20-0.80 | Only if wording or shared-guidance drift is caught during review. |

## Traceability Summary

- Requirement scope: `FR-032..FR-041`.
- Success scope: `SC-007`, `SC-008`.
- Governance anchors: `TG-016..TG-018`.
- Protected adjacent scope: `FR-018..FR-022`, `SC-004`, and `TG-008` remain reserved for Iteration `004`.
- Planning boundary: this iteration plan is the refreshed validator-facing package for Proposal `141` and is ready for downstream task refresh and governance rerun without widening scope.

## Notes

- Iteration `003` is closed history and MUST NOT be reopened by this plan.
- Iteration `004` remains the reserved Proposal `120` five-pillar bypass-detection slice exactly as approved.
- Current repository state still lacks an Iteration `004` plan artifact; downstream validators and task packaging must treat that as an explicit roadmap reservation, not as silent sequencing drift.
- `personas.yml`, question-bank IDs, persisted profile keys, and internal persona IDs remain authoritative internal contracts unless an explicitly approved non-breaking display-metadata addition is later justified.
- Durable shared instructions must point to the current-user profile loader/path rule rather than embedding concrete dial values into shared repository artifacts.
- Multi-developer safety is part of the planned slice and requires explicit evidence, not just documentation wording.
