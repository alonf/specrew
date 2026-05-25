## Formal Spec-Kit + Specrew Lifecycle

These rules override generic Squad coordination whenever the repository is bootstrapped for both Spec Kit and Specrew (for example, `.specify/workflows/speckit/workflow.yml` and `.specrew/config.yml` both exist).

1. **Default to the formal lifecycle**
   - Treat Spec-Kit + Specrew as the default delivery path for feature work and requirement changes.
   - Route the work through the canonical sequence by invoking the dedicated Speckit agents or commands (not generic skills): `speckit.specify` -> `speckit.clarify` -> `speckit.specrew-speckit.before-plan` -> `speckit.plan` -> `speckit.tasks` -> `speckit.specrew-speckit.after-tasks` -> `speckit.specrew-speckit.before-implement` -> `speckit.implement`.
   - After `speckit.specify`, run `speckit.clarify` for every newly generated spec before planning so Spec Kit can surface unresolved questions and validate the spec shape.
   - Only skip `speckit.clarify` when resuming an existing feature whose current spec has already been clarified or is demonstrably unchanged and already materially complete for planning, and record the skip rationale first.
   - When those dedicated Speckit agents or commands are available, use them instead of jumping straight to generic planning or coding agents, and do not invoke them as generic skills.

2. **No direct idea-to-code bypass**
   - Do NOT route a new feature, requirement change, or scoped product work directly from a user request, PRD, or issue into implementation.
   - The only allowed exceptions are:
     1. the work is clearly a small fix inside an already-active `specs/<feature>/` directory and current iteration
     2. the user explicitly instructs you to bypass the formal lifecycle
   - If you bypass it, say so plainly and do not describe the run as Spec-Kit/Specrew compliant.

3. **Artifact contract is mandatory**
   - Spec Kit feature artifacts: `specs/<feature>/spec.md`, `specs/<feature>/plan.md`, `specs/<feature>/tasks.md`
   - Specrew iteration artifacts: `specs/<feature>/iterations/<NNN>/plan.md`, `state.md`, `drift-log.md`, `review.md`, `retro.md`
   - Do not claim a phase has started or completed unless the corresponding artifact exists and is current.

4. **Scaffold missing lifecycle artifacts before continuing**
   - When planning begins without an iteration plan, scaffold `iterations/<NNN>/plan.md`.
   - When execution begins without state tracking, scaffold `state.md` and `drift-log.md`.
   - When review or retrospective begins without artifacts, scaffold `review.md` or `retro.md`.
   - Use the installed Specrew helpers: `scaffold-iteration-plan.ps1`, `scaffold-iteration-artifacts.ps1`, `scaffold-review-artifact.ps1`, and `scaffold-retro-artifact.ps1`.

5. **Gate phase transitions**
   - Run `validate-governance.ps1` before moving from planning -> execution, execution -> review, and review -> retrospective when iteration artifacts are present.
   - A failed governance check blocks the transition; do not work around it with a narrative summary.
   - Local validator runs on feature branches now auto-scope by default: the validator resolves the local base ref and applies the equivalent of `-ChangedOnly` unless the Crew explicitly passes `-FullRun` for a deliberate full-repo check.
   - When `.specrew/`, `.squad/identity/`, `.squad/decisions.md`, `.squad/team.md`, `.squad/config.json`, `extensions/specrew-speckit/`, `.specify/feature.json`, or `.specify/extensions/specrew-speckit/` changes are detected, the validator automatically falls back to full validation even during an auto-scoped or explicit `-ChangedOnly` run.
   - Interactive lifecycle gates typically still run without `-FullRun` so the complete artifact tree is checked when the boundary calls for full validation.
   - **Closeout-phase state syncs MUST use the canonical sync slash commands** (Proposal 090): `/speckit.specrew-speckit.sync-review-signoff` at the review-signoff boundary, `/speckit.specrew-speckit.sync-retro` at the retro boundary, `/speckit.specrew-speckit.sync-iteration-closeout` at iteration-closeout, and `/speckit.specrew-speckit.sync-feature-closeout` at feature-closeout. These commands wrap `Invoke-SpecrewBoundaryStateSync` with the correct canonical `-BoundaryType` enum value baked in. Do NOT invoke `sync-boundary-state.ps1` with inline PowerShell, and do NOT edit `.specrew/start-context.json`, `.specrew/last-start-prompt.md`, `.squad/identity/now.md`, `.specify/feature.json`, or any iteration `state.md` by hand at closeout — the canonical sync clears `feature_directory`, sets `session_state_active = false` at feature-closeout, and writes canonical boundary strings. Manual edits bypass this logic and produce contradictory state (non-canonical strings like `feature-closed` / `iteration-closed`, `session_state_active = true` post-closeout) that the new `Test-SessionStateBoundaryCanonical` validator rule will hard-fail on.

6. **Process-claim discipline**
   - Only say the team followed Spec-Kit or Specrew end-to-end when the work was actually routed through the canonical lifecycle and the artifact chain exists on disk.
   - Otherwise describe the result accurately as Squad-driven work informed by Specrew governance, or as an explicit process bypass.

7. **Handoff discipline**
   - Every spawned agent working inside the lifecycle must receive the active feature directory, iteration directory, requirement references, and relevant artifact paths.
   - No agent should infer which spec or iteration governs the work from branch names or memory alone.

8. **Persist repair escalation state**
   - When the same artifact keeps failing a governance gate, record the active repair escalation in `iterations/<NNN>/state.md` by using `manage-escalation-state.ps1`.
   - After every escalation activation or resolution, run `sync-squad-model-overrides.ps1 -IterationDirectory <active-iteration>` so `.squad/config.json` reflects the current escalation tier immediately.
   - Each repeated failure must increment the stored failure count, lock out the previous repair owner for that artifact, and escalate the reasoning tier from `balanced` to `deep` when warranted.
   - On resume, treat an active repair escalation as the highest-priority recovery step before normal task execution.
   - As soon as the gate passes, resolve the stored escalation so the temporary owner override clears and the default `efficiency` tier is restored for subsequent work.

9. **Preserve Specrew-managed rosters**
   - If `.squad/team.md` contains a Specrew-managed baseline roster, treat it as operational state rather than generic Squad bootstrap state.
   - Do NOT enter generic team-setup or recast mode while that managed roster exists.
   - Preserve both baseline roles and any supplemental members already recorded in the project roster.

10. **Drive intake to grounded scope**

- For `greenfield-new` work without a grounded request, ask an explicit interactive question such as "What do you want to build?", wait for the human developer's answer, and continue with one targeted follow-up question at a time until the scope is concrete enough for `speckit.specify`.
- For `brownfield-new` work, perform discovery first and then ask targeted follow-up questions about the intended change; discovery alone is never sufficient scope, and unresolved intake still requires a human answer before lifecycle execution begins.
- If the human provides a URL, pasted draft, or other source document during intake, extract the relevant scope from it, confirm any remaining behavior questions at intake, and only then invoke `speckit.specify`.
- Do not ask about specialist team additions before `speckit.specify` and the clarify outcome make the required stack/domain constraints concrete.

1. **Fail fast on artifact-generation errors**

- A lifecycle phase is not complete unless its required artifact exists on disk and the generating agent did not report a file-write or tool-contract failure.
- If `speckit.specify`, `speckit.plan`, or `speckit.tasks` reports a write failure or leaves the expected artifact missing, stop and repair that underlying error before invoking the next governance gate.

1. **Shape the team after spec clarity**

- After `speckit.specify` and the clarify outcome are grounded, analyze the feature, current roster, and technology/domain constraints to decide whether specialists are actually missing and whether the clarified work justifies safe same-specialty parallelism.
- Only propose Junior/Senior same-specialty pairs when the work can be partitioned cleanly enough to avoid conflicting execution. Treat Junior/Senior pairs as distinct named members with different task profiles, not as cloned identities.
- Preserve any user-added Specrew members, propose only the missing specialists or justified Junior/Senior pairs, and present the resulting team composition clearly before implementation.
- If the human approves new specialists or Junior/Senior pairs, materialize them before implementation with `specrew team add ...`.
- Route bounded, lower-risk, well-scoped work to Junior roles, but keep the quality bar high: Junior execution must still be careful, responsible, knowledgeable, and review-ready, with explicit checks for correctness, edge cases, tests, and maintainability. Route ambiguous, cross-cutting, integration-heavy, concurrency-sensitive, or reviewer-gated work to Senior roles, whose ownership should reflect deep technical judgment across architecture, systems thinking, computer science depth, tradeoff analysis, and long-range software engineering consequences.
- If Junior-owned work hits repeated governance failures, shared-surface conflict, or integration risk, escalate that slice to the Senior role or to an independent reviewer rather than persisting in unsafe parallel loops.

1. **Carry requirement-driven quality governance**
    - Derive the applicable production-grade quality attributes from the grounded feature and project context instead of applying a one-size-fits-all checklist.
    - Carry those quality attributes into clarifications, planning, tasks, implementation, and review, including robustness, retries, idempotency, error handling, logging, telemetry, security, maintainability, and semantic correctness when they materially apply.
    - Before `speckit.plan`, run or consult `resolve-quality-profile.ps1` for the active clarified feature so planning receives an explicit Phase 1 / first-slice quality profile with preset refs or bounded custom composition, stack surfaces, risk dimensions, quality tool bundle, required gates, and not-applicable rationale.
    - Treat the resolver output as planning input, not as proof that later review execution exists.
    - When the active slice includes Phase 2 hardening-gate scope (`FR-031` through `FR-033`), planning must make the next lifecycle boundary explicit: `quality/hardening-gate.md` sign-off is required before implementation starts, and unresolved critical concerns need human-approved deferral rather than agent-only acceptance.
    - Keep hardening gates, dedicated bug-hunter execution, strongest-class routing enforcement, known-traps workflows, and quality-drift automation explicitly deferred unless the current in-scope slice has actually implemented them.
    - Treat revisions, idempotency keys, retries, conflict detection, locks, and telemetry as incomplete until they have real runtime semantics and review evidence; flag ceremonial sophistication instead of accepting decorative protocol fields.

2. **Require explicit implementation approval**
     - Before `speckit.implement`, summarize readiness for the human developer: active feature, clarify outcome, quality focus, and final team composition.
     - If the active slice includes Phase 2 hardening-gate scope, include the hardening-gate verdict and any human-approved deferral status in that readiness summary.
     - Ask the human developer to explicitly start implementation, and do not invoke `speckit.implement` until that approval is given.
     - After `speckit.specrew-speckit.after-tasks` succeeds, treat `speckit.specrew-speckit.before-implement` as the next automatic lifecycle step once implementation approval is granted. Do not stop at the `after-tasks` boundary to ask the human to manually trigger hardening review, explain the blocker, or request a deferral decision that belongs to `before-implement`.
     - If `speckit.specrew-speckit.before-implement` blocks, explain the concrete blocking artifact or verdict, why it blocks implementation, and the next valid human action before stopping.

14A. **Enforce Feature 016 substantive interaction**
    - Treat planning, hardening-gate-and-implementation-auth, implementation, review-boundary, review-verdict-signoff, retro-boundary, and iteration-closeout as separate per-iteration boundaries. `feature-closeout` is separate and feature-level.
    - One human authorization advances at most one boundary. `continue` means advance to the next single boundary stop, then halt and ask again.
    - If one approval paste covers hardening-gate sign-off and implementation authorization, create two `.squad/decisions.md` entries that preserve the same verbatim authorization text.
    - **Every boundary stop MUST use the three-section handoff format.** This is a fundamental Specrew UX guarantee, not a stylistic suggestion. The format is what makes the human able to scan the handoff in seconds and decide whether to advance. Skipping it silently degrades the substantive-interaction guarantee (Feature 016 Pillar 1) — and the human loses the contextual signal they rely on. The canonical template (copy this shape exactly at every boundary stop):

      ```text
      ## What I just did

      [Substantive narration of what changed: features advanced, artifacts written, tests run,
       decisions captured. Pair every numeric reference (FR-NNN, T-NNN, commit SHA) with a short
       plain-language scope phrase, e.g. "FR-007, the sin/cos/atan extension" or "T003, the
       precision-normalization helper". Include the committed-evidence reference (commit SHA or
       hash range) per 14B boundary-commit discipline.]

      ## Why I stopped

      I stopped at the [exact boundary name] boundary because [why the next step needs human input].
      [Boundary names are: specify / clarify / plan / tasks / before-implement / implement /
       review-signoff / retro / iteration-closeout / feature-closeout.]

      ## What I need from you

      [State the single best immediate action. Reference review targets with BARE `file:///` URIs
       pointing to absolute paths so the human can click through. Name the canonical verdict shape
       they should type (e.g. `approved for plan`, `approved for review-signoff`, `rejected for
       clarify`, `parked`).]
      ```

      Welcoming, contextual, flow-oriented — not technical or terse. The reader is the human who has been away from this session and now needs to re-enter it. Give them what they need to advance, in the order they will read it.
    - **Use BARE `file:///` URIs, NOT markdown-link form `[name](file:///...)`.** PowerShell terminals (Windows Terminal, VS Code integrated terminal) auto-detect bare `file:///` URIs and make them clickable via Ctrl+Click. They do NOT render markdown, so wrapping a URI in `[name](url)` hides the URL inside parentheses and the human cannot click through. Emit `file:///C:/Dev/project/specs/001/plan.md` on its own (or as part of a sentence), never `[plan.md](file:///...)`.
    - The three-section format is reserved for **boundary stops** where the human is the immediate blocker. In-flight progress updates (Crew still actively working, waiting on background work, mid-task acknowledgement) MUST use single-line prose without the user-action section. Do not pad routine progress updates into the three-section shape — that dilutes the signal of an actual boundary stop.
    - Use BARE `file:///` artifact references in authored narration and handoffs outside approved exempt contexts.
    - After each committed boundary handoff, synchronize `Commit Reference` away from `pending`, keep `Recorded At` in UTC seconds precision, run a stale-reference scan on the cited `file:///` targets, and rerun validation on the exact committed tree before claiming readiness.

14B. **Enforce boundary commit + upstream push discipline (Proposal 082 Tier 1)**
    - At EVERY lifecycle boundary (specify, clarify, plan, tasks, implementation, review-signoff, retro, iteration-closeout, feature-closeout), the Crew MUST commit the boundary-phase work in semantic commit groups BEFORE invoking `Invoke-SpecrewBoundaryStateSync` or emitting the boundary handoff. Working-tree-only changes are not boundary-durable evidence.
    - After every commit, the Crew MUST push the feature branch to `origin/<feature-branch>` immediately. Local-only commits are not upstream-backed-up and are subject to working-tree corruption / force-quit loss.
    - The Crew MUST verify `git rev-parse HEAD` equals `git rev-parse origin/<feature-branch>` BEFORE signaling boundary readiness in the three-section handoff. Mention the committed evidence reference (commit SHA or hash range) in `What I just did`.
    - Boundary-sync's validator passes when working-tree content matches expected state. That is NOT sufficient — the Crew's commit and push discipline is the durable evidence boundary readiness requires. Any boundary signal without committed-and-pushed evidence is a violation and the next coordinator audit MUST reject it.
    - Conditional skip: if `git remote` returns empty (no `origin` configured), push silently skips. Commit discipline still applies.
    - When commits at a boundary land trivially small or status-only (e.g., a status-tracking-only update to plan.md), commit them anyway. The rule is "commit-and-push at every boundary," not "produce substantial code at every boundary."
    - This rule operates at the same authority level as 14A and applies to every Crew role (Implementer, Planner, Reviewer, Spec Steward, Retro Facilitator). Per-role responsibilities are detailed in each agent's charter.

1. **Carry feature closeout version management**
    - When a feature closeout is preparing to claim shipped work, treat release-version bookkeeping as required closure work rather than an optional reminder.
    - Update the authoritative product version in `.specrew/config.yml`, the matching `version:` field in `extensions/specrew-speckit/extension.yml` (and the deployed mirror at `.specify/extensions/specrew-speckit/extension.yml`), add the corresponding `CHANGELOG.md` entry, refresh any README version summary or linked versioning references that surfaced the previous version, and create the release tag that anchors the closed feature state.
    - Rerun `validate-governance.ps1` after the version/changelog/tag updates so the closeout evidence reflects the final public-readiness state.
    - If any release-version step is intentionally deferred, keep the feature open until explicit human-approved defer evidence is recorded in the governing artifacts.

2. **Provide a review-ready implementation briefing**
    - At the end of implementation and review, provide a developer-facing briefing that summarizes what was built, how it maps to requirements, the main happy path and relevant alternative flows, dependency/package usage including newly introduced packages, the testing strategy, and an explicitly labeled estimate of coverage or confidence.

3. **Honor delegated routing plans**

- When Specrew provides an effective delegated routing plan for lifecycle roles, use that plan for planning, implementation, review, spec-governance, and repair work unless the human explicitly overrides it.
- Treat review-heavy and problem-solving-heavy work as delegated-routing candidates when enabled agents make that possible: planning/problem-solving work should prefer Planner or Spec Steward delegated routing, while review/governance work should prefer Reviewer or Spec Steward delegated routing.
- Materialize that plan into `.squad/config.json` via `agentModelOverrides`, and re-read the config before each lifecycle or repair spawn rather than caching it once at session start.
- For every delegated lifecycle, review, governance, or repair spawn, append a short dated runtime-evidence entry to `.squad/decisions.md` with the role or work item, requested agent, actual agent, concrete model ID, whether the assignment was honored or fell back, and any fallback reason.
- Keep Reviewer and Spec Steward independent from the Implementer whenever multiple enabled agents make that possible.

1. **Enforce the no-gap policy**

- Do not close a lifecycle-governed run as complete when review, governance, or validation still reveals a known gap across spec, implementation, tests, docs, or observability.
- Fix the gap in the current iteration, or obtain explicit human approval to defer it and record that defer in the governing artifacts so it does not roll forward invisibly.
- A known gap is not merely review commentary; it becomes tracked work or an approved defer before closure.

1. **Run critical evidence-driven review**

- During review and final readiness, classify hardened lifecycle/governance requirements as implemented, enforced, observable, and documented.
- Emit a gap ledger whenever any one of those dimensions is missing, and make the next repair or defer action explicit.
- If review finds an ambiguity, contradiction, or missing decision in the governing spec, stop closure, ask the human targeted clarification question, update the spec, and reconcile the affected plan/tasks/governance artifacts before continuing.

1. **Escalate live model tiers**
    - On repeated governance-gate failures, update `.squad/config.json` so the current repair owner moves from the fast tier to a balanced tier, then to a deep tier if the next repair still fails.
    - Clear any temporary escalation override as soon as the gate passes so normal routing resumes.

2. **Route reviewer regressions conservatively**
    - When a human reports a concrete defect in Squad-approved or reviewer-ready work, treat it as a reviewer-regression event for the active feature.
    - Route the remaining review work to the lowest strictly stronger reviewer class that is available.
    - If no stronger reviewer class exists, use an independent reviewer owner at the same class.
    - If the strongest reviewer class is already active and no independent same-class reviewer remains, hold the review for explicit human direction.

3. **Recognize the `/specrew-*` slash-command surface (Feature 024)**
    - The user may invoke any of seven canonical Specrew slash commands at any time during a session. Treat them as first-class command invocations, not as conversational text. The v1 catalog:
      - `/specrew-where` — show the project status dashboard (backed by `specrew where` / `scripts/specrew-where.ps1`)
      - `/specrew-status` — alias of `/specrew-where`; semantic parity required
      - `/specrew-update` — refresh Specrew-managed assets and platform baselines (backed by `specrew update`)
      - `/specrew-team` — manage Squad team members and baseline roster (backed by `specrew team`)
      - `/specrew-review` — trigger or inspect the review workflow (backed by `specrew review`)
      - `/specrew-help` — show the full Specrew slash-command catalog and next-step guidance
      - `/specrew-version` — show the installed Specrew version and slash-command compatibility state
    - Each slash command has a corresponding skill at `.claude/skills/specrew-<name>/SKILL.md`, `.github/skills/specrew-<name>/SKILL.md`, and `.agents/skills/specrew-<name>/SKILL.md` with full per-command argument whitelist, failure semantics, and invocation contract. Load that skill content when routing a slash invocation.
    - When the user types `/specrew-<command>` (or a legacy `/specrew.<command>` form that can be safely normalized), route to the matching skill and the underlying `specrew <command>` shell entry point.
    - **Discovery fallback**: if host-native `/specrew-` prefix autocomplete is unavailable in this environment, `/specrew-help` is the canonical catalog fallback. The user can always type `/specrew-help` to see the catalog even when other commands aren't surfaced by the host UI.
    - **Boundary safety**: no `/specrew-*` command authorizes lifecycle advancement. `/specrew-where`, `/specrew-status`, and `/specrew-version` are read-only. `/specrew-update`, `/specrew-team`, and `/specrew-review` can modify state but never advance a Spec-Kit lifecycle boundary on their own. Explicit human approval per Rule 14A still governs every boundary transition.
    - **Coexistence with `/speckit.*`**: both namespaces are additive. Neither shadows the other. `/specrew-help` shows the Specrew catalog; `/speckit.*` discovery comes from Spec Kit. Use both freely in the same session.
    - **Argument whitelist enforcement**: the underlying PowerShell scripts reject unsupported arguments with a `WARNING:` prefix and `--help` guidance. Pass through user arguments as-is rather than silently filtering — let the backend reject, surface the rejection to the human, then offer help guidance.
    - **Compatibility gate**: minimum compatibility is Specrew 0.24.0 (the version that shipped the multi-host slash-command surface). If the project's `.specrew/config.yml` `specrew_version` is older, the command may emit an upgrade hint; do not silently no-op.
