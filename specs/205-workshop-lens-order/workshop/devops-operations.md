# devops-operations: 205-workshop-lens-order

**Depth**: light. **Confirmation**: human-confirmed (lens-question). Decisions 2 to 4 came in one typed reply. Decision 1 closed after a human-approved scratch verification, on 2026-11-10.

## Copy map (verified in scratch)

```text
source (extensions/specrew-speckit/...)        deployed copy                                         refreshed by
---------------------------------------------  ----------------------------------------------------  ------------------------
knowledge/design-lenses/index.yml + *.md       .specify/.../knowledge/design-lenses/                 deploy-speckit-extension
commands/...before-specify.md                  .specify/.../commands/                                deploy-speckit-extension
scripts/confirm-workshop-agenda.ps1            .specify/.../scripts/                                 deploy-speckit-extension
squad-templates/skills/design-workshop.md      .specify/.../squad-templates/skills/                  deploy-speckit-extension
                                               .claude/.agents/.github skills, .cursor/rules SKILL   deploy-squad-runtime
```

## Decisions

1. **Sync named in the failure message (rule a):** the two project-only deploy scripts. The full update is never named, and `scripts/specrew-update.ps1` is never run in this worktree while 203 is unmerged: it writes the hook launcher and user-level host settings to the home folder, and on main it cannot redirect them (`SPECREW_USER_HOME_OVERRIDE` exists only on 203).

   ```text
   Deployed copy differs from its source: <copy path>:<line> vs <source path>:<line>.
   Refresh the copies (writes inside this project only, never your home folder):
     pwsh -File extensions/specrew-speckit/scripts/deploy-speckit-extension.ps1 -ProjectPath . -RefreshExisting
     pwsh -File extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1 -ProjectPath .
   These also restamp .squad runtime files; review git status and commit only the copies you meant to refresh.
   ```

   **Verification:**
   - A marker added to each source reached every checked copy, including `.cursor`.
   - The scripts also restamp `.squad` charters (line endings), `team.md`, `routing.md`, `ceremonies.md`, `casting/registry.json`, the extension runtime version stamp and `.github/agents/squad.agent.md`.
   - The real-home hook files hashed the same before and after.
   - **Correction (human):** `~/.specrew/hook-bindings/` is a folder holding one antigravity binding file, and the check missed it. Its mtime (2026-11-02) shows it was not touched. Every future home check hashes the files inside that folder too.
2. **Copy comparison:** full content of the copies of the files this feature touches, ignoring only the deploy wrapper (frontmatter and the `.specrew-managed` stamp).
3. **CI:**
   - A named step in specrew-ci.yml.
   - Before every push, run the CI's own markdownlint command, and do not push on a non-zero exit.
   - After every push, follow Specrew CI, Test and Cross-Platform Validation to their conclusion and report the result. A skipped gate job counts as red.
4. **Downstream:**
   - The skill's sentence becomes: if any list disagrees with index.yml, index.yml wins, and a confirmed agenda keeps the order it was confirmed in.
   - Rollback is a revert in the next beta. Nothing is migrated on disk.
