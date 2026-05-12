# Specrew

Specrew bootstraps and runs a **Squad + Spec Kit** delivery flow with stronger lifecycle governance, delegated-agent routing, and iteration artifact discipline for feature work.

## What Specrew does

- bootstraps a repository for **Spec Kit**, **Squad**, and **Specrew** governance
- provides `specrew init`, `specrew start`, and team-management scripts
- uses `specrew start` as the canonical downstream entrypoint
- expects Squad to drive `speckit.specify -> speckit.clarify -> speckit.plan -> speckit.tasks -> speckit.implement`
- keeps **Copilot CLI** as the mandatory host runtime and supports optional delegated agents such as **Claude** and **Codex**
- records governance and delegated-routing expectations for planning, implementation, review, and retrospective work

## Recommended flow

1. Bootstrap a repository with `scripts\specrew-init.ps1`.
2. Start feature work with `scripts\specrew.ps1 start`.
   - Every later session also begins with `specrew start`.
   - `specrew start` regenerates `.specrew/last-start-prompt.md`, `.specrew/start-context.json`, and `.specrew/start-summary.md` before launch.
   - Do not run `copilot` directly: it bypasses the runtime handoff refresh, so the launch contract is not regenerated for the new session.
3. Let Squad gather missing information, run the Spec Kit lifecycle, and implement from the generated artifacts.
4. Keep iteration artifacts current under `specs\<feature>\iterations\<NNN>\`.

## Key documents

- `docs\getting-started.md` - bootstrap and quickstart guidance
- `docs\user-guide.md` - day-to-day lifecycle usage
- `docs\github-project.md` - Specrew self-development board guidance
- `tests\README.md` - integration and smoke test entrypoints

## Reviewer-regression governance highlights

- A human-found defect in work the Squad reviewer already approved or marked ready creates a **Reviewer Regression Event**. Specrew keeps the event as a soft-warning governance signal, escalates the next review to the lowest stronger reviewer class that is actually available, falls back to an independent reviewer at the same class when no stronger class exists, and holds for human direction only when neither path is safe.
- Reviewer-regression routing is additive to the existing implementer escalation policy: it changes the remaining reviewer path for the affected feature, but it does not replace the original implementer-side FR-027 flow.
- Specrew caps implementer rotation at **two extra owners beyond the original implementer** by default. After that cap is active, the next revision must go to a human or to an explicitly justified alternate owner recorded in `.squad\decisions.md`; Specrew does not synthesize another implementer specialist.
- Withdrawn or misreported reviewer-regression events keep their ledger history, reverse only still-pending routing or hold state derived from that event, and do not retroactively erase completed ownership changes or auto-remove already approved known-trap entries.

## Session-loaded file change detection

When you restart Copilot/Squad, `specrew start` detects whether you've committed changes to session-loaded files (agent charters, Copilot instructions, or Spec Kit extension templates). If changes are detected, **the auto-continue behavior pauses** and prompts you to confirm or provide additional directives before the lifecycle resumes.

**Session-loaded paths checked**:
- `.github/agents/*`
- `.github/copilot-instructions.md`
- `extensions/specrew-speckit/squad-templates/coordinator/*`
- `.specify/extensions/specrew-speckit/squad-templates/coordinator/*`
- `.squad/agents/*/charter.md`

**Pause-and-confirm workflow**:
1. You commit changes to one or more session-loaded files (e.g., updating `.github/agents/squad.agent.md`).
2. You restart Copilot/Squad and run `specrew start`.
3. The regenerated `.specrew/last-start-prompt.md` includes a **PAUSE-AND-CONFIRM** message listing the changed files.
4. You can review the changes and provide directives (e.g., "Focus on reviewer escalation testing") before typing `CONFIRM` or a directive to continue.

**Routine resumes (no changes)**: When no session-loaded files have changed, `specrew start` auto-continues immediately per the documented baseline behavior.

**Optional parameter for custom directives**: Power users can prepend a custom directive using the `-PostRestartDirective` parameter:

```powershell
pwsh -File C:\Dev\Specrew\scripts\specrew.ps1 start -PostRestartDirective "Validate reviewer escalation contract before continuing."
```

The custom directive is prepended to the handoff prompt, followed by any pause-and-confirm or auto-continue logic.

**Baseline tracking**: `specrew start` records a baseline commit hash in `.specrew/last-start-prompt.md` YAML frontmatter (`baseline_commit_hash: <40-char SHA>`). The detector compares this baseline against HEAD to identify committed changes. Uncommitted work-in-progress modifications do not trigger the pause.

## Notes

- `specrew start` reuses the current terminal by default; use `--new-window` only when you explicitly want a detached shell.
- Newly generated specs should go through **clarify** before planning unless the work is a true resumed, already-clarified feature with a recorded skip rationale.
- Delegated lifecycle runs should leave visible runtime evidence in `.squad\decisions.md`, including requested agent, actual agent, concrete model ID, and fallback reason when applicable.
