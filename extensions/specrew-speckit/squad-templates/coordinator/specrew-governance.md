## Formal Spec-Kit + Specrew Lifecycle

These rules override generic Squad coordination whenever the repository is bootstrapped for both Spec Kit and Specrew (for example, `.specify/workflows/speckit/workflow.yml` and `.specrew/config.yml` both exist).

1. **Default to the formal lifecycle**
   - Treat Spec-Kit + Specrew as the default delivery path for feature work and requirement changes.
   - Route the work through the canonical sequence: `speckit.specify` -> `speckit.specrew-speckit.before-plan` -> `speckit.plan` -> `speckit.tasks` -> `speckit.specrew-speckit.after-tasks` -> `speckit.specrew-speckit.before-implement` -> `speckit.implement`.
   - When those dedicated Speckit agents or commands are available, use them instead of jumping straight to generic planning or coding agents.

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
