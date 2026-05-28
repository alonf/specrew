---
proposal: 141
title: Crew Interaction Profile / Persona Lens Separation
status: draft
phase: phase-2
estimated-sp: 6-8
discussion: feature-049 iteration-005
---

# Crew Interaction Profile / Persona Lens Separation

## Why

Feature 049 Iteration 003 introduced a user-level expertise profile so Specrew can adapt substantive intake depth. The implementation works, but the user-facing language currently exposes internal persona labels as if they were personal job-title self-assessments.

The clearest example is the fourth dial: `AI Researcher / Project Manager`. That internal lens is meant to cover capacity planning, safe parallelism, specialist pairing, agent charters, delivery risk, and AI-agent workflow design. However, asking the human to rate themselves as an "AI Researcher / Project Manager" is ambiguous and overlaps with "Product Manager". The user is not choosing who they are; they are telling Specrew how much judgment to expect from them in a decision area.

This is a methodology clarity issue. Specrew should preserve internal persona lenses for structured intake while presenting the user profile as an interaction contract: "how should the Crew work with me when decisions in this area come up?"

The user-facing intent is not "rate yourself as a professional". The intent is:

> Tell Specrew how much guidance, explanation, and auto-decision support you want from the Crew in each decision area.

Higher values mean the Crew can ask concise, expert-level questions and assume the human wants to make the call. Lower values or `auto` mean the Crew should explain more, recommend defaults, and surface auto-decisions transparently.

There is a second release-facing clarity issue: persistence is not the same as hard behavioral enforcement. Feature 049 persists the profile and wires it into `/speckit.specify` intake, but it does not yet provide role-specific rules for every gate. However, the profile can still be placed in the Crew's session context as a general interaction hint: when talking to the human, agents should adjust question phrasing, explanation depth, and recommendation/assertion balance according to the user's dial for the relevant decision area.

That means this proposal should make two levels explicit:

- **General interaction context now**: every agent can see the Crew Interaction Profile and use it as a collaboration hint when asking the human questions or explaining decisions.
- **Specific gate behavior later**: future work can add role/gate-specific rules for Planner, Implementer, Reviewer, Retro, handoff prose, and other lifecycle surfaces.

Because Specrew projects may have multiple human developers, shared project instructions must not hard-code one developer's interaction settings into durable files such as constitution, `AGENTS.md`, `CLAUDE.md`, or installed agent prompts. Those files should describe the rule and point agents to the current user's profile path. The concrete dials must be loaded at session start from the user-level profile (`$env:USERPROFILE\.specrew\user-profile.yml` on Windows, `~/.specrew/user-profile.yml` on Unix-like systems) and then surfaced in session context. This preserves per-developer behavior and survives context compaction without leaking one developer's settings into the shared repository.

## What

Separate the internal intake lens model from the user-facing profile model:

1. Keep existing persona lens IDs stable for compatibility, including `ai-researcher-project-manager`.
2. Present first-run and `/specrew-user-profile` prompts as a **Crew Interaction Profile**, not a role, identity claim, or capability badge.
3. Explain each dial as an interaction-level preference for a decision area: how much the Crew should ask, explain, recommend, or auto-decide.
4. Rename the user-facing fourth decision area from `AI Researcher / Project Manager` to **AI Delivery Planning**.
5. Surface the resolved current user's profile in Crew start context as general interaction guidance for all agents.
6. Update profile summaries, prompt descriptions, docs, and reviewer guidance so they explain the two levels: general interaction hint for all Crew conversations now; hard `/speckit.specify` intake behavior now; role/gate-specific behavior later.
7. Update durable shared agent instructions to reference the user-level profile location and loading rule, not concrete per-user dial values.
8. Preserve existing persisted profile schema and migration behavior.

### Functional requirements

- **FR-001**: User-facing setup MUST introduce the profile as a **Crew Interaction Profile**: the user's preferred collaboration level for different decision areas.
- **FR-002**: Specrew MUST keep internal persona lens IDs stable so existing `user-profile.yml` files, question banks, tests, and intake catalogs remain compatible.
- **FR-003**: User-facing setup MUST explain the meaning of the scale in interaction terms: high values mean concise expert-level questions; low values or `auto` mean more guidance, recommendations, and transparent auto-decisions.
- **FR-004**: The fourth user-facing decision area MUST be labeled **AI Delivery Planning** and reflect AI-agent workflow, safe parallelism, delivery planning, task slicing, and agent coordination.
- **FR-005**: Profile summaries emitted by `specrew start` and `/specrew-user-profile show` MUST distinguish "your Crew interaction settings" from "Specrew's internal persona lenses".
- **FR-006**: Documentation for substantive intake MUST state that personas are internal review/intake lenses, while the profile asks how the Crew should interact with the human when decisions in each area come up.
- **FR-007**: Tests or scripted evidence MUST verify that existing profiles using `ai-researcher-project-manager` still load and drive the same intake behavior after the display-label change.
- **FR-008**: `specrew start` context MUST include a concise agent-facing instruction that surfaces the resolved current user's Crew Interaction Profile as general collaboration guidance for all human-facing agent interactions.
- **FR-009**: Documentation and start/profile summaries MUST state the current application boundary: interaction dials are hard-applied to `/speckit.specify` intake in this release and soft-applied as general agent interaction context elsewhere; role/gate-specific adaptation is future work unless a later feature implements it.
- **FR-010**: Review evidence MUST include at least one assertion that user-facing text accurately distinguishes soft general interaction guidance from hard role/gate-specific behavior.
- **FR-011**: Shared project-level durable instructions MUST NOT hard-code concrete user dial values. They MUST point to the user-level profile source and require loading the current user's profile at session start.
- **FR-012**: Session context artifacts MAY contain the current user's resolved profile summary for the active session, but must make clear it is user-specific runtime context, not shared project truth.
- **FR-013**: Multi-developer behavior MUST be preserved: two developers working in the same project can have different local `user-profile.yml` files and receive different interaction guidance without changing shared repository files.

### Out of scope

- Splitting the fourth internal lens into separate `AI Researcher` and `Project Manager` lenses.
- Changing F-049's four-lens architecture or adding a fifth persona.
- Changing persisted `user-profile.yml` schema fields.
- Implementing implicit expertise inference from answer quality.
- Redesigning the full substantive intake catalog.
- Making all Crew lifecycle roles enforce role/gate-specific interaction rules. This proposal may provide general agent-facing context; detailed Planner/Implementer/Reviewer/Retro adaptations should be handled as separate follow-up work.
- Storing per-developer profile values in shared repository files.

## Effort

- **Iteration 1 (~6-8 SP)**: Rename display labels and prompt wording, update profile summary text, add agent-facing start-context guidance, update durable shared instructions to reference the user-level profile loader instead of concrete values, update docs, add compatibility evidence for existing profile keys, and verify the release promise distinguishes soft general interaction guidance from hard `/speckit.specify` behavior.
- **Total**: ~6-8 SP

## Phase placement

Phase 2. This is a small methodology clarity fix on top of the substantive intake and expertise-profile work. It should be handled before broad downstream onboarding because first-run wording shapes how users answer their profile dials.

## Resolved decisions for F-049 Iteration 005

1. The user-facing surface is named **Crew Interaction Profile**.
2. The fourth visible decision area is **AI Delivery Planning**.
3. The other visible decision areas remain **Product Strategy**, **UX/UI Design**, and **Software Architecture**.
4. The profile is surfaced as **soft collaboration guidance for all agents** in active session context.
5. `/speckit.specify` remains the only **hard-applied** behavior in this release.
6. Durable shared instructions must point to the **current user's profile path/loader rule**, not resolved per-user dial values.
7. Multi-developer behavior is explicit: different developers may have different local `user-profile.yml` values with no shared-repo changes.
8. Persisted keys and internal persona lens IDs remain unchanged.

## Risks

- **Compatibility risk**: Renaming the persisted key would break existing profiles. Mitigation: keep IDs and schema stable; only change display labels and explanatory prose.
- **Terminology drift**: Labels could diverge across scripts, catalogs, skills, and docs. Mitigation: centralize display metadata or add a small consistency test.
- **Scope creep**: This could become a broader persona redesign. Mitigation: explicitly limit the slice to Crew Interaction Profile framing, soft session-context guidance, durable instruction safety, and compatibility evidence.
- **Over-promise risk**: Users may believe the whole Crew has detailed role/gate-specific adaptations because the profile is persisted globally. Mitigation: explicitly state the current boundary: soft collaboration guidance everywhere, hard intake behavior in `/speckit.specify`, and detailed role/gate behavior later.
- **Multi-developer leakage risk**: One developer's interaction settings could be accidentally committed into shared durable instructions. Mitigation: shared files point to the user-level profile path and loader; only session-local context contains resolved values.

## Cross-references

- Related proposals: 015, 063, 100, 140
- Source artifacts: `specs/049-pipeline-hardening-intake/spec.md`, `.specify/intake/personas.yml`, `scripts/internal/user-profile.ps1`, `.agents/skills/specrew-user-profile/SKILL.md`
- Composability with: Feature 049 Iteration 003, Proposal 053 auto-decision transparency, Proposal 140 reviewer instruction surface

## Status history

- 2026-05-28: candidate captured from Specrew dogfooding feedback after first-run profile intake exposed `AI Researcher / Project Manager` as a confusing user self-rating label.
- 2026-05-28: promoted to draft for Feature 049 Iteration 005 planning refresh after human feedback expanded scope to Crew Interaction Profile semantics, soft all-agent guidance, durable loader/path rules, and multi-developer safety.
