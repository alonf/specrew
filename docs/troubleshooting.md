# Specrew Troubleshooting

Use this guide when a Specrew install, update, packaging run, or resumed session does not behave the way the current branch and module version say it should.

## Start with the right command

| If you need to... | Use this command | Why |
| --- | --- | --- |
| Upgrade the installed PowerShell module from PSGallery | `Update-Module Specrew` | This changes the module bits available on your machine. |
| Refresh Specrew-managed files inside the current project | `specrew update` | This redeploys project runtime, template, and skill surfaces from the module you already have installed. |
| Recover both the machine install and the project surfaces | `Update-Module Specrew`, then `Import-Module Specrew -Force`, then `specrew update` | Upgrade first, then redeploy the project from the upgraded module. |

If you run `specrew update` when the installed module itself is stale, you only reapply old project assets. If you run `Update-Module Specrew` but skip `specrew update`, the project may still carry older managed files.

## Symptom guide

| Symptom | Likely cause | First move |
| --- | --- | --- |
| `specrew --version` or `Import-Module` keeps loading the wrong version | Side-by-side stable or prerelease installs, or stale PSGallery cache | Go to [PSGallery side-by-side installs or stale cache](#psgallery-side-by-side-installs-or-stale-cache). |
| `specrew start` or `specrew update` reports missing runtime surfaces | Packaged `FileList` drift, partial install, or stale project assets | Go to [FileList omissions or missing deployed files](#filelist-omissions-or-missing-deployed-files). |
| `specrew update` throws during runtime deployment | The project assets are out of sync with the installed module, or the update run is partial | Go to [Deploy-script exceptions during `specrew update`](#deploy-script-exceptions-during-specrew-update). |
| `specrew start` resumes the wrong feature or boundary | Local session-state files are stale | Go to [Stale session-state or wrong-feature resume](#stale-session-state-or-wrong-feature-resume). |
| You want the cleanest recovery path after repeated drift | Mixed module versions or stale local assets | Go to [Clean reinstall flow](#clean-reinstall-flow). |
| `specrew init` says Node is too old right after a `brew` upgrade (macOS) | `nvm` shadows the Homebrew Node on `PATH`; `pwsh` uses the same old Node | Go to [macOS: Node version shadowed by nvm](#macos-node-version-shadowed-by-nvm). |
| `specrew init` says Spec Kit is missing or too old | `specify-cli` is absent or below the supported floor | Go to [Spec Kit missing or too old](#spec-kit-missing-or-too-old). |
| Launching the host shows no Specrew banner; the agent acts ungoverned | The SessionStart hook never fired (per-host hook config missing or malformed) | Go to [SessionStart hook never fires](#sessionstart-hook-never-fires). |
| On restart the agent asks "what do you want to build?" instead of resuming | No valid handover or anchor surfaced; or the deployed providers are stale | Go to [Resume starts blind instead of welcoming you back](#resume-starts-blind-instead-of-welcoming-you-back). |
| A `HOLLOW HANDOVER` warning, or "another session may be active in this worktree" | Expected advisories: an unauthored handover body; a fresh session marker from the previous session | Go to [Handover and concurrency advisories](#handover-and-concurrency-advisories). |

## PSGallery side-by-side installs or stale cache

PowerShellGet can keep stable and prerelease builds side by side. That is useful for testing, but it also means a plain `Import-Module Specrew` can load a version you did not expect.

Check what is installed:

```powershell
Get-Module Specrew -ListAvailable |
    Select-Object Name, Version, @{Name = 'Prerelease'; Expression = { $_.PrivateData.PSData.Prerelease }}
```

If the wrong version keeps loading:

1. Remove the loaded module from the current shell.
2. Uninstall every installed Specrew version if you want a clean baseline.
3. Reinstall only the version you intend to use.
4. Re-import the module and verify `specrew --version`.

```powershell
Get-Module Specrew | Remove-Module -Force
Uninstall-Module Specrew -AllVersions -Force
Install-Module Specrew -Scope CurrentUser -SkipPublisherCheck -Force
Import-Module Specrew -Force
specrew --version
```

If PSGallery or PowerShellGet still serves a stale package layout, clear the local package caches after closing all PowerShell sessions that might have the module loaded. On Windows the usual cache locations are:

- `$env:TEMP\PowerShellGet`
- `$env:LOCALAPPDATA\NuGet\Cache`

Remove only the cached package contents, then reinstall. On macOS or Linux, clear the equivalent local PowerShellGet and NuGet cache directories before reinstalling.

## FileList omissions or missing deployed files

If a shipped file is missing from the installed module, downstream projects cannot recover it with `specrew update` because the module package itself is incomplete.

For maintainers working in this repository:

```powershell
(Test-ModuleManifest .\Specrew.psd1).FileList
pwsh -NoProfile -File .\scripts\internal\test-publish-harness.ps1
```

Use the manifest output to confirm the file is registered, then use the publish harness to prove the packaged candidate actually contains every `FileList` entry on disk before publication.

For downstream users:

1. Upgrade or reinstall the module if the installed copy is suspect.
2. Run `specrew update` in the project root to redeploy managed project assets.
3. Run `specrew init` again only when the release notes or the command output say the runtime or template surfaces are missing.

Do not hand-copy managed files into the project as a long-term fix. The next managed update can overwrite the manual patch while the underlying package problem remains.

## Deploy-script exceptions during `specrew update`

Bare `specrew update` refreshes Specrew-managed project assets only. It does not upgrade the installed module.

When `specrew update` fails:

1. Run it from the project root, not from a nested directory.
2. Check the installed module version first.
3. Use `specrew update --info` to inspect the current and latest supported versions before retrying.
4. If the project was upgraded to a newer module version, run `specrew init` once so missing runtime or template surfaces are redeployed before retrying `specrew update`.

```powershell
specrew --version
specrew update --info
specrew init
specrew update
```

If the failure names a specific script or managed file, treat that path as the source of truth for the broken deployment surface. Fix the missing prerequisite or reinstall the module instead of editing the generated project artifact by hand and assuming the next update will preserve it.

## Stale session-state or wrong-feature resume

The session-state files below are local runtime artifacts. They are intentionally regenerated and should never be committed:

- `.specrew\start-context.json`
- `.specrew\last-start-prompt.md`

If `specrew start` resumes the wrong feature or boundary:

1. Check out the correct git branch first.
2. Delete the local session-state files.
3. Start Specrew again so it regenerates the handoff from the current branch and project artifacts.

```powershell
Remove-Item .\.specrew\start-context.json, .\.specrew\last-start-prompt.md -Force -ErrorAction SilentlyContinue
specrew start
```

Do not re-add those files to git to make the state feel durable. They are host-session scratch state, not authoritative delivery artifacts.

## SessionStart hook never fires

If launching `claude` / `codex` / `copilot` inside an initialized project produces no Specrew orientation banner and the agent behaves as if the project were ungoverned, the SessionStart hook did not run or its output was dropped.

First check the journal — every successful bootstrap appends one JSON line:

```powershell
Get-Content .\.specrew\runtime\bootstrap-journal.jsonl -Tail 3
```

- **No new line for your launch** — the hook never ran. Verify the per-host registration: Claude reads the project's `.claude/settings.json`; Codex reads the user-level `~/.codex/hooks.json` and requires its events wrapped as `{ "hooks": { "<Event>": [...] } }` — top-level event keys are silently ignored. Re-run `specrew init` (or `deploy-refocus-hooks.ps1`) to redeploy the registrations.
- **A line exists but nothing surfaced in the session** — the hook ran and the host dropped its output. On Codex this happens when the injected context is malformed for its envelope (it accepts only `hookSpecificOutput.additionalContext`) — redeploy so the current dispatcher is in place, and prefer the current module version.
- The hook is fail-open by design: any internal error exits silently rather than blocking your session, so a broken deployment looks like "no banner", never a hang. `[specrew-bootstrap] WARN PROVIDER_FAILED ...` on stderr names the reason when the host shows hook diagnostics.

## Resume starts blind instead of welcoming you back

If a restarted (or switched) host asks "what do you want to build?" while `specs/<feature>/` clearly holds work in flight, read the latest journal line first:

```powershell
Get-Content .\.specrew\runtime\bootstrap-journal.jsonl -Tail 1
```

- `"mode":"welcome-back","handover_valid":true` — the resume context WAS surfaced; the agent under-used it. Reply with a nudge ("we were in the middle of a workshop — continue from the artifacts") and it should re-derive from `specs/<feature>/` and `.specrew/handover/session-handover.md`.
- `"mode":"full","handover_valid":false` — nothing validated. Check, in order:
  1. The branch is the feature branch — the workshop-window feature resolution is branch-keyed: the branch name must exactly match the `specs/<branch>/` directory (`git branch --show-current`).
  2. The handover floor exists and names the feature: `Get-Content .\.specrew\handover\session-handover.md -TotalCount 8` — `active_feature:` blank on a feature branch means the deployed providers predate the fix; run `specrew update` (and update the module) to redeploy current providers.
  3. The handover is fresher than 24 hours — older floors are intentionally not trusted.
- A hard-killed session (closed window, no `/exit`) writes no floor at death. The resume then relies on the previous floor plus the on-disk feature artifacts — position in conversation is lost, work on disk is not.

## Handover and concurrency advisories

Two messages around session start are advisories, not errors:

- **`HOLLOW HANDOVER` / "the previous session did NOT author a handover body"** — the rolling handover's frontmatter floor is present (feature, boundary, commit), but the six rich body sections were never authored by the previous agent. The resuming agent is told to re-derive from the lifecycle artifacts instead — workshop records, spec, tasks. Work is not lost; the resume is simply artifact-derived rather than narrative.
- **"another session may be active in this worktree (marker within 1h)"** — the previous session's `.specrew/runtime/session-marker.json` is less than an hour old. After a normal exit-and-relaunch (or a host switch) this is expected and safe to ignore. It matters only if you really do have two live agents in the same worktree — then coordinate or close one. Deleting the marker file silences it immediately; it is local scratch state.

## Clean reinstall flow

Use this when multiple recovery attempts leave you unsure which module version or project asset set is active.

```powershell
Get-Module Specrew | Remove-Module -Force -ErrorAction SilentlyContinue
Uninstall-Module Specrew -AllVersions -Force
Install-Module Specrew -Scope CurrentUser -SkipPublisherCheck -Force
Import-Module Specrew -Force
specrew --version
```

Then refresh each existing Specrew project from the known-good module:

```powershell
cd C:\path\to\your-project
specrew init
specrew update
```

That sequence restores the installed module first, then redeploys the project-managed runtime and template surfaces from the recovered module.

## Shape-5 lesson: review evidence must match the committed tree

Validator passes against a working tree are not proof of delivery. If the files cited in review evidence are only staged or unstaged, they can disappear on session loss, cleanup, or reset.

Before claiming a review or closeout verdict:

1. Commit the implementation artifacts.
2. Push the branch.
3. Verify the cited files exist in `HEAD`.
4. Only then cite them in `review.md`, `quality-evidence.md`, or closeout artifacts.

Example check:

```powershell
git ls-tree -r HEAD --name-only |
    Select-String 'docs/troubleshooting.md|README.md|docs/getting-started.md|docs/user-guide.md|Specrew.psd1'
```

If the file is not present in the committed tree under review, it is not shipped evidence yet.

## Refocus automation seems dead this session

Run the status probe first — every branch ends in one named action:

1. `pwsh -File .specify/extensions/specrew-speckit/scripts/refocus.ps1 --status`
2. **Breaker tripped?** The journal shows `BREAKER_TRIPPED` + the reason. Re-enable: `--reset-breaker`, or start a new session. Recurring? Disable that trigger durably in `refocus-scopes.json` and file the journal evidence.
3. **Env kill switch set?** `SPECREW_REFOCUS_DISABLE` silences all hook triggers — unset it.
4. **Trigger disabled in the catalog?** `--status` lists per-trigger `enabled` flags with no guesswork.
5. **All green but silent?** Check the journal tail: `deduped` means channel 1 already delivered (working as designed); `budget-clipped` means the payload hit its token cap; nothing at all means the hook isn't registered — re-run `deploy-refocus-hooks.ps1` (it respects a recorded opt-out; use `-Force` to re-enable explicitly).

Every warning carries a reason code (`EVENT_PARSE`, `CATALOG_SCHEMA`, `SOURCE_MISSING`, `SOURCE_CONFINED`, `STATE_UNAVAILABLE`, `BUDGET_EXCEEDED`, `BREAKER_TRIPPED`, `PROVIDER_FAILED`) — `EVENT_PARSE` after a host update usually means the host changed its event schema; see the research matrix in the Specrew repo.

## macOS: Node version shadowed by nvm

On macOS, `specrew init` can fail dependency validation with a Node version *older* than what you just installed:

```text
[macOS] Node.js v22.17.0 / required: 24.0+
```

— even right after `brew install node` / `brew upgrade node`. The usual cause is **`nvm` shadowing the Homebrew Node**: the `nvm` shim sits ahead of Homebrew on your `PATH`, so `node` resolves to an old `nvm` default no matter what `brew` installed. PowerShell — the runtime Specrew actually uses — inherits the same `PATH`, so it sees the old Node too.

Diagnose:

```sh
which -a node          # an nvm shim ahead of the Homebrew path means nvm wins
node -v                # the ACTIVE version (what Specrew sees)
```

Fix it through `nvm` (not `brew`), then confirm in the runtime Specrew uses:

```sh
nvm install 24
nvm use 24
nvm alias default 24
node -v                              # v24.x in your login shell
pwsh -NoProfile -Command "node -v"   # MUST also report v24.x — this is the one Specrew checks
```

The last line is the one that matters: always verify `node -v` **inside `pwsh`**, not only in zsh/bash. If the two disagree, `nvm` is still shadowing and `specrew init` will keep failing.

## Spec Kit missing or too old

`specrew init` validates the bundled Spec Kit (`specify-cli`) against Specrew's supported baseline and fails closed if it is missing or below the floor:

```text
Specrew requires Spec Kit >= 0.8.4 but found 0.0.22.
```

The supported floor and the latest validated version are declared in `scripts/internal/supported-versions.yml` (`speckit.min` / `speckit.max_tested`) — currently floor **0.8.4**, validated up to **0.9.0**. `specrew init` prints the exact remediation command for the floor; run it (add `--force` to replace an existing tool install):

```sh
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git@v0.8.4 --force
```

Then re-run `specrew init`. (`uv` is required — see [getting-started](getting-started.md#1-check-dependencies).) The `@v…` tag tracks Specrew's supported floor; if the command `specrew init` prints names a different version, prefer the printed one — it is generated from the runtime baseline, not from this doc.
