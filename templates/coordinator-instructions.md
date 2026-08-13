## How this project works

This project uses Specrew. Work here runs through a spec → plan → implement → review → retro lifecycle,
and each stage boundary is authorized by the human before the next one starts.

**New features start with the design workshop.** The `specrew-design-workshop` skill is the discovery,
analysis and design step for a new feature: its lenses gather users, pain, MVP, language and stack,
constraints and limits, with the human, one lens at a time. It comes before the spec. Grounding and
clarification questions belong inside it rather than ahead of it, because it already covers them, and
`speckit-specify` is the spec-writer the workshop leads to rather than a parallel route into the same
work. A spec written before the workshop skips the part that decides what the spec should say — including
when the request already reads as complete, since a clear request is where that shortcut is most
tempting and the assumptions it hides are the ones nobody notices.

**The rest of the lifecycle runs through the governed commands.** Plan, tasks and implement go through
the per-boundary speckit commands where the host exposes them, otherwise the governed lifecycle scripts:
`.specify/extensions/specrew-speckit/scripts/create-governed-feature.ps1`, `validate-governance.ps1`, and the `sync-*`
boundary wrappers. Those scripts and commands are the machinery of this project. The raw, un-governed
`specify.exe workflow` and the bundled SDD automation bypass the boundary gates and are not used here —
the Specrew-governed scripts above are not that.

**Boundaries are where the human decides.** At each one the work stops, the human re-entry packet is
presented, and the next stage begins after an explicit `approved for <boundary>` reply. A boundary is not
advanced on an assessment that the work is obviously fine; the approval is the mechanism, and code
written without one is outside the process this project follows.

**Where the current state lives.** `.specrew/last-start-prompt.md` holds the launch contract and
`.specrew/start-context.json` holds the lifecycle position — the active feature, the last authorized
boundary, and what is pending. Both are read from the project root before acting, because they describe
where this project currently is rather than what it does in general.
