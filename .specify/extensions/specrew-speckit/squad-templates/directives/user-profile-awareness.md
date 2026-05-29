# Directive: User-Profile Awareness (Crew Interaction Profile)

**Schema**: v1  
**Status**: Active governance directive

## Principle

The user's **Crew Interaction Profile** is a collaboration calibration signal, not an identity claim. It tells agents HOW the current user wants to be engaged (concise expert questions vs more explanation + auto-decisions) across four decision areas, but it is NOT a job-title profile and it does NOT rename Specrew's internal persona lenses.

## Scope

This directive applies to all Squad agents (Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator) and the Coordinator. Each role applies it scope-specifically to its own interactions with the human user.

## Rules

1. **Where to find the profile**
   - At session start, read the `user_profile` section from `.specrew/start-context.json`
   - Persisted source is the per-user file at `$env:USERPROFILE\.specrew\user-profile.yml` (Windows) or `~/.specrew/user-profile.yml` (Unix-like), resolved by `scripts/internal/user-profile.ps1`
   - If the section is missing or empty, behave as if all dials are `auto` (recommend defaults, surface transparent auto-decisions)

2. **Four decision areas + their persisted keys**
   - **Product Strategy** ↔ `expertise.product_management` ↔ internal persona `product-manager`
   - **UX/UI Design** ↔ `expertise.ui_ux` ↔ internal persona `ux-ui-specialist`
   - **Software Architecture** ↔ `expertise.software_architecture` ↔ internal persona `architect`
   - **AI Delivery Planning** ↔ `expertise.ai_research_project_management` ↔ internal persona `ai-researcher-project-manager`

3. **Calibration per dial setting**
   - `8-10` (senior): ask concise expert-level questions; assume the user decides; minimal explanation; let the user pick trade-offs without belaboring them
   - `4-7` (mid): balanced; explain trade-offs but defer the decision to the user
   - `1-3` or `auto` (junior/unspecified): explain more; recommend defaults; surface auto-decisions transparently so the user can override

4. **Soft-vs-hard application boundary**
   - The profile is **soft session guidance** outside `/speckit.specify` — agents adapt question depth, explanation density, and recommendation-vs-decide balance, but do not record per-area decisions to durable artifacts as a consequence of dial values
   - `/speckit.specify` is the **only surface that hard-applies** the profile — it uses dial values to drive per-lens question depth in the substantive intake engine
   - Other lifecycle surfaces (planning, implementation, review, retro, sync, closeout) MUST remain soft-application only in this release; role/gate-specific hard application is future work that requires its own approved proposal

5. **Stable-key + persona-ID compatibility**
   - Persisted schema keys (`expertise.*`, including `expertise.ai_research_project_management`) and internal persona IDs (including `ai-researcher-project-manager`) MUST NOT be renamed, migrated, or aliased
   - Legacy `user-profile.yml` files must load unchanged
   - Display labels (the four decision-area names above) are the user-facing surface; persisted keys + persona IDs are the internal contract

6. **Multi-developer safety (shared repository discipline)**
   - Durable shared instructions (constitution, `AGENTS.md`, `CLAUDE.md`, installed agent prompts, charter files, shared docs) MUST reference the current-user profile loader/path rule — NOT concrete dial values from any one developer's profile
   - No resolved per-developer profile values may be persisted into shared repository artifacts (`.squad/decisions.md`, `specs/<feature>/**`, etc.) as a consequence of this directive
   - Per-developer session context (`.specrew/start-context.json`, `.specrew/last-start-prompt.md`, `.squad/identity/now.md`) MAY carry the resolved profile but must be marked as user-specific runtime context (`shared_project_truth: false`), not project truth

## How each role applies this directive

- **Coordinator** — surfaces the profile to the user at session start (Welcome Orientation paragraph) BEFORE asking the first intake question or confirming resume; injects relevant calibration context into per-role task prompts
- **Spec Steward** — adapts intake question depth + explanation density per the relevant dial (Product Strategy + UX/UI for product/UX intake; Software Architecture for technical intake; AI Delivery Planning for delivery + risk intake)
- **Planner** — calibrates the depth at which trade-offs are surfaced + the explanation density of plan rationale per Software Architecture + AI Delivery Planning dials
- **Implementer** — calibrates implementation-decision explanation depth + recommendation-vs-decide balance per Software Architecture dial
- **Reviewer** — enforces capability-vs-lens separation when reviewing user-profile, intake wording, session context, or shared instructions; verifies stable-key compatibility, soft-vs-hard boundary discipline, loader-rule correctness, multi-developer safety
- **Retro Facilitator** — calibrates retro-question depth per Product Strategy + AI Delivery Planning dials

## Discoverability

- The persisted profile can be inspected, edited, or reset via the `/specrew-user-profile` skill (`show` / `edit` / `reset` subcommands)
- The directive itself is shipped at `.squad/directives/user-profile-awareness.md` (deployed by `specrew init` / `specrew update`)

## Empirical foundation

This directive captures the per-role calibration rules empirically established by Feature 049 Iteration 005 (Proposal 141 — Crew Interaction Profile / Persona Lens Separation). The producer side ships the profile in start-context.json; this directive ships the consumer-side discipline that closes the feature's "soft session guidance for all agents" promise.
