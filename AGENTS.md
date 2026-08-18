<!-- >>> specrew-managed coordinator >>> -->
## How this project works

This project uses Specrew. Work here runs through a spec → plan → implement → review → retro lifecycle,
and each stage boundary is authorized by the human before the next one starts.

**A session opens by orienting the human, not by starting work.** Your first reply shows them, as
visible prose: that Specrew is active and which version and host, where this project currently stands
in the lifecycle, where their artifacts live, what will be asked of them at boundaries, and how you are
adapting to them — the user-profile expertise dials, so they can see what you believe about them and
correct it if it is wrong. The session hook hands you that orientation to SHOW; reading it to orient
yourself is not rendering it, and the difference is invisible from the inside. A human who never sees
it learns this project by being interrupted by it later, at a boundary they did not know was coming,
and cannot correct an adaptation they were never shown. A concrete request in the human's first message
does not replace the orientation: announce what is starting and render the orientation with it.

**New features start with the design workshop.** The `specrew-design-workshop` skill is the discovery,
analysis and design step for a new feature: its lenses gather users, pain, MVP, language and stack,
constraints and limits, with the human, one lens at a time. It comes before the spec. Grounding and
clarification questions belong inside it rather than ahead of it, because it already covers them, and
`speckit-specify` is the spec-writer the workshop leads to rather than a parallel route into the same
work. A spec written before the workshop skips the part that decides what the spec should say — including
when the request already reads as complete, since a clear request is where that shortcut is most
tempting and the assumptions it hides are the ones nobody notices.
Workshop questions are visible prose answered by a typed human reply on every host. Closing or dismissing a
question UI (including Copilot Ctrl+O / `User skipped question`) is an absence, not permission to choose defaults
or record delegation. The governed feature/controller exists before the first grounding question.
User-facing refusals state what could not be completed without asserting that Specrew is broken or at fault.
When true, they say that the human's answers or work are safe, propose one concrete recovery action, and ask
for approval before taking it. Technical diagnosis belongs in the project's drift record, not in the message
shown to the human.

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
<!-- <<< specrew-managed coordinator <<< -->
