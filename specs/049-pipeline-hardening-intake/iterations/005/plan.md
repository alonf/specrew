# Iteration Plan: 005

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 4.4/25 story_points
**Started**: 2026-05-28
**Completed**:

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

Iteration `005` is the bounded **3-5 SP** Proposal `141` correction slice for Feature `049`. It updates user-facing wording and proof surfaces so Specrew clearly treats the four saved values as **capability/confidence dials** instead of job-title identities, while preserving the internal four-lens architecture, stable persisted keys, and all Iteration `004` Proposal `120` commitments unchanged.

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-032 | First-run, `/specrew-user-profile`, `/speckit.specify`, and summary surfaces must describe the four saved values as capability/confidence dials for `Product Strategy`, `UX/UI Design`, `Software Architecture`, and `AI Delivery Planning`. | US3 |
| FR-033 | Persisted schema keys and internal persona lens IDs remain unchanged, including `expertise.ai_research_project_management` and `ai-researcher-project-manager`. | US3 |
| FR-034 | The fourth visible capability label is fixed to `AI Delivery Planning` everywhere the user sees it. | US3 |
| FR-035 | Guidance must explicitly distinguish **your capability dials** from **Specrew's internal persona lenses**. | US3 |
| FR-036 | Docs, skills, and reviewer/operator guidance must stay semantically consistent and preserve Iteration `004` as the Proposal `120` lane. | US3 |
| FR-037 | Tests and scripted evidence must prove legacy `user-profile.yml` compatibility with unchanged behavior and updated visible labels. | US3 |
| SC-007 | 100% of audited first-run/profile/help surfaces use capability labels, and 100% of legacy profile fixtures load without migration while preserving routing/depth behavior. | US3 |
| TG-016 | Proposal `120` remains fully anchored to Iteration `004`; this slice must not weaken it. | US3 |
| TG-017 | Iteration `005` is a bounded follow-on correction slice, not an Iteration `003` reopen. | US3 |
| TG-018 | Display labels are fixed to `Product Strategy`, `UX/UI Design`, `Software Architecture`, and `AI Delivery Planning`; internal lenses remain unchanged. | US3 |

## Governance Consistency Check

| Gate | Verdict | Notes |
| ---- | ------- | ----- |
| Spec Authority | PASS | Scope is limited to `FR-032..FR-037`, `SC-007`, and `TG-016..TG-018`. |
| Traceability | PASS | All planned workstreams below map directly to Proposal `141` and User Story `3`. |
| Capacity | PASS | Authorized effort band remains **3-5 SP** inside the canonical `25` story-point iteration-capacity model; the imported task set plans `4.4` SP plus `0.6` SP repair reserve without broadening scope. |
| Roadmap Discipline | PASS | Iteration `003` stays closed, Iteration `004` stays reserved for Proposal `120`, and Iteration `005` is planned as the next bounded slice. |
| Compatibility Discipline | PASS | No schema migration, no key rename, no persona-ID rename, and no fifth-lens work is allowed here. |
| `004`-Absent / `005`-Present Caveat | PASS | Planning may proceed with explicit human authorization, but downstream validators/task generation must treat Iteration `004` as reserved rather than silently inferring a sequencing error. |
| Before-Implement Readiness | PASS | Existing Iteration `005` task packaging (`T001-T008`) is now mirrored in this plan so validator-facing task rows, owners, effort, and bounded execution order remain explicit without regenerating scope. |

## Open Questions Resolved

| Proposal 141 Question | Planning Decision |
| --------------------- | ----------------- |
| Final fourth capability label? | Use **AI Delivery Planning**. |
| Should the other three labels also become capability areas? | Yes: **Product Strategy**, **UX/UI Design**, and **Software Architecture**. |
| Should `personas.yml` gain separate internal/user-facing fields? | Not required by this slice. The plan assumes a shared presentation-layer mapping over unchanged persisted keys and internal persona IDs; no schema/catalog rewrite is authorized. |
| Should reviewer instructions check capability-vs-identity wording? | Yes. Reviewer/operator guidance and evidence must verify that user-facing copy talks about capability dials, not self-identity personas. |

## Audit Inventory

| Surface Group | Why It Must Be Audited | Candidate Paths |
| ------------- | ---------------------- | --------------- |
| First-run bootstrap | The first prompt shapes how users answer the dials and is the highest-risk wording surface. | `scripts/internal/user-profile.ps1`, `scripts/specrew-start.ps1` |
| Profile display / edit / reset | Existing profile management surfaces currently present persona/job-title labels directly. | `scripts/internal/user-profile.ps1`, `.github/skills/specrew-user-profile/SKILL.md`, `.claude/skills/specrew-user-profile/SKILL.md`, `.agents/skills/specrew-user-profile/SKILL.md` |
| Start summaries / reusable context | Visible summaries must reflect the corrected labels without changing persisted keys. | `scripts/specrew-start.ps1`, generated `.specrew/start-summary.md`, `.specrew/start-context.json`, `.specrew/last-start-prompt.md` |
| Specify prompt / agent guidance | These surfaces must explain that personas stay internal while dials control depth. | `.github/prompts/speckit.specify.prompt.md`, `.github/agents/speckit.specify.agent.md` |
| Intake engine help / mirror surface | If the engine emits or documents user-facing wording, shipped and mirrored copies must stay aligned. | `extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1`, `.specify/extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1` |
| Docs / help | Downstream user docs must not keep identity-framed language or stale roadmap truth. | `docs/user-guide.md`, `README.md`, release/help notes if changed in slice execution |
| Reviewer / operator guidance | Reviewers must enforce capability-vs-lens separation, stable-key compatibility, and preserved Iteration `004` truth. | `.specrew/team/agents/reviewer.md`, `.agents/agents/reviewer.md`, `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md`, `.specify/extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md`, Iteration `005` review/evidence artifacts |
| Tests / scripted evidence | This slice is not complete without explicit compatibility proof for legacy profiles and audited wording coverage. | `tests/integration/f049-i003-intake-engine-tests.ps1`, start/smoke tests if needed, `specs/049-pipeline-hardening-intake/iterations/005/quality/quality-evidence.md` |

## Planned Workstreams

| Workstream | Outcome | Requirements | Candidate Surfaces | Effort | Owner |
| ---------- | ------- | ------------ | ------------------ | ------ | ----- |
| W001 | Replace user-facing persona/job-title framing with capability-area wording in first-run, profile, and summary surfaces | FR-032, FR-034, FR-035 | `scripts/internal/user-profile.ps1`, `scripts/specrew-start.ps1` | 0.75-1.00 | Implementer |
| W002 | Preserve stable keys and internal lens IDs while introducing a shared display-label mapping | FR-033, TG-017, TG-018 | `scripts/internal/user-profile.ps1`, intake guidance surfaces | 0.50-0.75 | Implementer |
| W003 | Align skills, docs, prompt/agent guidance, and reviewer/operator guidance to the corrected semantics | FR-035, FR-036 | Skill markdown, prompt/agent files, docs, reviewer guidance files | 1.0-1.5 | Implementer + Reviewer |
| W004 | Extend tests and scripted evidence to prove legacy-profile compatibility and audited-surface coverage | FR-037, SC-007 | `tests/integration/f049-i003-intake-engine-tests.ps1`, Iteration `005` evidence artifacts | 0.75-1.50 | Reviewer |

**Planned Total**: 3.0-4.75 story_points

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Create Iteration 005 audit scaffold and evidence envelope | FR-036, FR-037, SC-007, TG-016, TG-017 | US3 | 0.3 | Reviewer | `specs/049-pipeline-hardening-intake/iterations/005/quality/quality-evidence.md` | planned | | | |
| T002 | Add shared display-label metadata and capability-vs-lens helpers | FR-032, FR-033, FR-034, FR-035, TG-017, TG-018 | US3 | 0.6 | Implementer | `scripts/internal/user-profile.ps1` | planned | | | |
| T003 | Add legacy-profile fixture and failing compatibility assertions | FR-033, FR-034, FR-037, SC-007, TG-018 | US3 | 0.6 | Reviewer | `tests/integration/fixtures/f049-legacy-user-profile/legacy-user-profile.yml`, `tests/integration/f049-i003-intake-engine-tests.ps1` | planned | | | |
| T004 | Update first-run and profile/runtime wording to capability dials | FR-032, FR-033, FR-034, FR-035, TG-017, TG-018 | US3 | 0.8 | Implementer | `scripts/internal/user-profile.ps1`, `scripts/specrew-start.ps1` | planned | | | |
| T005 | Refresh `/specrew-user-profile` help copy across shipped skill surfaces | FR-032, FR-034, FR-035, FR-036, TG-018 | US3 | 0.4 | Implementer | `.github/skills/specrew-user-profile/SKILL.md`, `.claude/skills/specrew-user-profile/SKILL.md`, `.agents/skills/specrew-user-profile/SKILL.md` | planned | | | |
| T006 | Align specify and intake guidance to capability-vs-lens semantics | FR-032, FR-035, FR-036, TG-017, TG-018 | US3 | 0.5 | Implementer | `.github/prompts/speckit.specify.prompt.md`, `.github/agents/speckit.specify.agent.md`, `extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1`, `.specify/extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1` | planned | | | |
| T007 | Update downstream docs and reviewer/operator guidance | FR-035, FR-036, TG-016, TG-017, TG-018 | US3 | 0.5 | Implementer | `docs/user-guide.md`, `README.md`, `.specrew/team/agents/reviewer.md`, `.agents/agents/reviewer.md`, `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md`, `.specify/extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md` | planned | | | |
| T008 | Run compatibility checks and record Proposal 141 evidence | FR-037, SC-007, TG-016, TG-017, TG-018 | US3 | 0.7 | Reviewer | `tests/integration/f049-i003-intake-engine-tests.ps1`, `specs/049-pipeline-hardening-intake/iterations/005/quality/quality-evidence.md` | planned | | | |

**Planned Task Total**: 4.4 story_points  
**Reserved Repair Headroom**: 0.6 story_points  
**Bounded Slice Truth**: Proposal `141` remains a **3-5 SP** correction slice even though iteration metadata must align to the repository-wide `25` story-point capacity model.

## Required Quality Gates

| Gate | Target | Notes |
| ---- | ------ | ----- |
| Capability-label audit | required | 100% of audited first-run/profile/help surfaces use `Product Strategy`, `UX/UI Design`, `Software Architecture`, and `AI Delivery Planning`. |
| Capability-vs-lens separation | required | Copy must explicitly say the dials control question depth and auto-decision behavior while personas remain internal lenses. |
| Stable-key compatibility | required | No rename or migration of persisted keys or internal persona IDs is allowed. |
| Legacy profile proof | required | Existing `user-profile.yml` fixtures must load unchanged and preserve routing/depth behavior. |
| Reviewer guidance consistency | required | Reviewer/operator guidance must inspect wording correctness and preserved `004` vs `005` roadmap truth. |
| Mirror parity | required | Any wording/help change in shipped intake surfaces must be mirrored under `.specify` in the same boundary. |
| Planning truthfulness | required | No stale “four-iteration” or “Iteration `003` planning” truth may remain in the feature-level or iteration-level planning package. |

## Planned Execution Order

1. **Lock the wording contract first** — finalize the shared capability-label mapping and explicit capability-vs-lens explanation.
2. **Update first-run/profile surfaces next** — user-profile helper and start flow carry the highest user-facing risk.
3. **Refresh skills, prompts, docs, and reviewer guidance after the mapping is stable** — this prevents terminology drift.
4. **Add compatibility proof and audited-surface evidence last** — evidence must validate the exact wording that ships.

## Dependencies

- `W001` and `W002` must establish the authoritative wording/mapping contract before downstream docs or tests can freeze.
- `W003` depends on the final wording contract from `W001-W002`.
- `W004` depends on the wording and guidance surfaces being stable enough to audit.
- Task generation must preserve the sequencing rule above and keep mirror-surface updates coupled.

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Same unit used across Feature `049`. |
| Capacity per Iteration | 25 | Canonical repository iteration-capacity value from `.specrew/iteration-config.yml`; this plan remains a small slice within that wider model. |
| Iteration Bounding | scope | `scope` keeps Proposal `141` fixed to the approved correction slice only. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Authorized Slice | 3-5 | Human-approved small-slice correction band for Proposal `141`. |
| Planned Task Load | 4.4 | Imported directly from `iterations/005/tasks.md` without widening scope. |
| Repair Reserve | 0.6 | Preserves the existing bounded headroom inside the `3-5 SP` slice. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds `25` story_points (capacity `25` x threshold `1.0`); this slice stays well below that cap. |
| Defer Strategy | manual | Any spillover requires explicit human approval; do not silently merge into Iteration `004`. |
| Calibration Enabled | true | Capture variance after execution because the slice is intentionally small and terminology-heavy. |

## Concurrency Rationale

- Shared wording and mapping logic create a strong serial dependency up front.
- After the wording contract lands, docs/skills/reviewer guidance can parallelize moderately.
- Compatibility tests should trail the wording changes so they assert the shipped contract instead of a moving target.
- Recommendation: keep implementation mostly sequential until the shared mapping is stable, then split doc/skill updates from evidence preparation.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 0.50 | This artifact plus feature-plan refresh. |
| Implementation | 1.50-2.00 | User-profile/start/prompt/skill wording and mapping updates. |
| Review Guidance | 0.50-1.00 | Reviewer/operator instruction refresh and audit checklist shaping. |
| Verification / Evidence | 1.00-1.50 | Legacy-profile compatibility proof and audited-surface evidence. |
| Rework Buffer | 0.00-0.50 | Only if wording drift is caught during review. |

## Traceability Summary

- Requirement scope: `FR-032..FR-037`.
- Success scope: `SC-007`.
- Governance anchors: `TG-016..TG-018`.
- Protected adjacent scope: `FR-018..FR-022`, `SC-004`, and `TG-008` remain reserved for Iteration `004`.
- Planning boundary: this iteration plan now mirrors the existing bounded task package and is ready for validator rerun / before-implement review without regenerating scope.

## Notes

- Iteration `003` is closed history and MUST NOT be reopened by this plan.
- Iteration `004` remains the reserved Proposal `120` five-pillar bypass-detection slice exactly as approved.
- Current repository state has an Iteration `005` plan before an Iteration `004` plan artifact exists; downstream validators and task packaging must treat that as an explicit roadmap reservation, not as silent sequencing drift.
- `personas.yml`, question-bank IDs, persisted profile keys, and internal persona IDs remain authoritative internal contracts unless an explicitly approved non-breaking display-metadata addition is later justified.
- The validator-facing `## Tasks` table mirrors the existing `iterations/005/tasks.md` package; it was repaired for schema compliance without regenerating or broadening the bounded Proposal `141` scope.
