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

## Notes

- `specrew start` reuses the current terminal by default; use `--new-window` only when you explicitly want a detached shell.
- Newly generated specs should go through **clarify** before planning unless the work is a true resumed, already-clarified feature with a recorded skip rationale.
- Delegated lifecycle runs should leave visible runtime evidence in `.squad\decisions.md`, including requested agent, actual agent, concrete model ID, and fallback reason when applicable.
