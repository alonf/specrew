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

11. **Fail fast on artifact-generation errors**
   - A lifecycle phase is not complete unless its required artifact exists on disk and the generating agent did not report a file-write or tool-contract failure.
   - If `speckit.specify`, `speckit.plan`, or `speckit.tasks` reports a write failure or leaves the expected artifact missing, stop and repair that underlying error before invoking the next governance gate.

12. **Shape the team after spec clarity**
   - After `speckit.specify` and the clarify outcome are grounded, analyze the feature, current roster, and technology/domain constraints to decide whether specialists are actually missing and whether the clarified work justifies safe same-specialty parallelism.
   - Only propose Junior/Senior same-specialty pairs when the work can be partitioned cleanly enough to avoid conflicting execution. Treat Junior/Senior pairs as distinct named members with different task profiles, not as cloned identities.
   - Preserve any user-added Specrew members, propose only the missing specialists or justified Junior/Senior pairs, and present the resulting team composition clearly before implementation.
   - If the human approves new specialists or Junior/Senior pairs, materialize them before implementation with `specrew team add ...`.
   - Route bounded, lower-risk, well-scoped work to Junior roles, but keep the quality bar high: Junior execution must still be careful, responsible, knowledgeable, and review-ready, with explicit checks for correctness, edge cases, tests, and maintainability. Route ambiguous, cross-cutting, integration-heavy, concurrency-sensitive, or reviewer-gated work to Senior roles, whose ownership should reflect deep technical judgment across architecture, systems thinking, computer science depth, tradeoff analysis, and long-range software engineering consequences.
   - If Junior-owned work hits repeated governance failures, shared-surface conflict, or integration risk, escalate that slice to the Senior role or to an independent reviewer rather than persisting in unsafe parallel loops.

13. **Carry requirement-driven quality governance**
    - Derive the applicable production-grade quality attributes from the grounded feature and project context instead of applying a one-size-fits-all checklist.
    - Carry those quality attributes into clarifications, planning, tasks, implementation, and review, including robustness, retries, idempotency, error handling, logging, telemetry, security, maintainability, and semantic correctness when they materially apply.
    - Before `speckit.plan`, run or consult `resolve-quality-profile.ps1` for the active clarified feature so planning receives an explicit Phase 1 / first-slice quality profile with preset refs or bounded custom composition, stack surfaces, risk dimensions, quality tool bundle, required gates, and not-applicable rationale.
    - Treat the resolver output as planning input, not as proof that later review execution exists.
    - When the active slice includes Phase 2 hardening-gate scope (`FR-031` through `FR-033`), planning must make the next lifecycle boundary explicit: `quality/hardening-gate.md` sign-off is required before implementation starts, and unresolved critical concerns need human-approved deferral rather than agent-only acceptance.
    - Keep hardening gates, dedicated bug-hunter execution, strongest-class routing enforcement, known-traps workflows, and quality-drift automation explicitly deferred unless the current in-scope slice has actually implemented them.
    - Treat revisions, idempotency keys, retries, conflict detection, locks, and telemetry as incomplete until they have real runtime semantics and review evidence; flag ceremonial sophistication instead of accepting decorative protocol fields.

14. **Require explicit implementation approval**
    - Before `speckit.implement`, summarize readiness for the human developer: active feature, clarify outcome, quality focus, and final team composition.
    - If the active slice includes Phase 2 hardening-gate scope, include the hardening-gate verdict and any human-approved deferral status in that readiness summary.
    - Ask the human developer to explicitly start implementation, and do not invoke `speckit.implement` until that approval is given.
    - After `speckit.specrew-speckit.after-tasks` succeeds, treat `speckit.specrew-speckit.before-implement` as the next automatic lifecycle step once implementation approval is granted. Do not stop at the `after-tasks` boundary to ask the human to manually trigger hardening review, explain the blocker, or request a deferral decision that belongs to `before-implement`.
    - If `speckit.specrew-speckit.before-implement` blocks, explain the concrete blocking artifact or verdict, why it blocks implementation, and the next valid human action before stopping.

15. **Provide a review-ready implementation briefing**
   - At the end of implementation and review, provide a developer-facing briefing that summarizes what was built, how it maps to requirements, the main happy path and relevant alternative flows, dependency/package usage including newly introduced packages, the testing strategy, and an explicitly labeled estimate of coverage or confidence.

16. **Honor delegated routing plans**
   - When Specrew provides an effective delegated routing plan for lifecycle roles, use that plan for planning, implementation, review, spec-governance, and repair work unless the human explicitly overrides it.
   - Treat review-heavy and problem-solving-heavy work as delegated-routing candidates when enabled agents make that possible: planning/problem-solving work should prefer Planner or Spec Steward delegated routing, while review/governance work should prefer Reviewer or Spec Steward delegated routing.
   - Materialize that plan into `.squad/config.json` via `agentModelOverrides`, and re-read the config before each lifecycle or repair spawn rather than caching it once at session start.
   - For every delegated lifecycle, review, governance, or repair spawn, append a short dated runtime-evidence entry to `.squad/decisions.md` with the role or work item, requested agent, actual agent, concrete model ID, whether the assignment was honored or fell back, and any fallback reason.
   - Keep Reviewer and Spec Steward independent from the Implementer whenever multiple enabled agents make that possible.

17. **Enforce the no-gap policy**
   - Do not close a lifecycle-governed run as complete when review, governance, or validation still reveals a known gap across spec, implementation, tests, docs, or observability.
   - Fix the gap in the current iteration, or obtain explicit human approval to defer it and record that defer in the governing artifacts so it does not roll forward invisibly.
   - A known gap is not merely review commentary; it becomes tracked work or an approved defer before closure.

18. **Run critical evidence-driven review**
   - During review and final readiness, classify hardened lifecycle/governance requirements as implemented, enforced, observable, and documented.
   - Emit a gap ledger whenever any one of those dimensions is missing, and make the next repair or defer action explicit.
   - If review finds an ambiguity, contradiction, or missing decision in the governing spec, stop closure, ask the human targeted clarification question, update the spec, and reconcile the affected plan/tasks/governance artifacts before continuing.

19. **Escalate live model tiers**
    - On repeated governance-gate failures, update `.squad/config.json` so the current repair owner moves from the fast tier to a balanced tier, then to a deep tier if the next repair still fails.
    - Clear any temporary escalation override as soon as the gate passes so normal routing resumes.

20. **Route reviewer regressions conservatively**
    - When a human reports a concrete defect in Squad-approved or reviewer-ready work, treat it as a reviewer-regression event for the active feature.
    - Route the remaining review work to the lowest strictly stronger reviewer class that is available.
    - If no stronger reviewer class exists, use an independent reviewer owner at the same class.
    - If the strongest reviewer class is already active and no independent same-class reviewer remains, hold the review for explicit human direction.
