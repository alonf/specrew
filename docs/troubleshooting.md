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
| You launch your host but no Specrew orientation banner appears; the agent acts ungoverned | The SessionStart hook is not installed for that host, or the banner did not reach the session | Go to [No orientation banner when you launch your host](#no-orientation-banner-when-you-launch-your-host). |
| On restart the agent asks "what do you want to build?" instead of resuming | No valid handover or anchor surfaced; or the deployed providers are stale | Go to [Resume starts blind instead of welcoming you back](#resume-starts-blind-instead-of-welcoming-you-back). |
| Resume reopens "`=== AWAITING YOUR VERDICT ===`" at a boundary you thought was done | A committed boundary is not an authorized boundary | Go to [Resume re-asks for a verdict you already gave](#resume-re-asks-for-a-verdict-you-already-gave). |
| A `HOLLOW HANDOVER` warning, or "another session may be active in this worktree" | Expected advisories: an unauthored handover body; a fresh session marker from the previous session | Go to [Handover and concurrency advisories](#handover-and-concurrency-advisories). |
| A crash lost the last few minutes, or Antigravity shows no welcome-back banner | Expected continuity limits: a hard kill fires no stop hook; Antigravity hooks may be unavailable or may not fire in that host build | Go to [A crash lost recent conversation, or Antigravity shows no welcome-back](#a-crash-lost-recent-conversation-or-antigravity-shows-no-welcome-back). |

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

## No orientation banner when you launch your host

After `specrew init`, you normally just launch your host — run `claude`, `codex`, `copilot`, `cursor-agent`, or `agy` — and Specrew greets you with an orientation banner and drives the governed lifecycle. Antigravity uses `.agents/hooks.json` for `PreInvocation` bootstrap plus B3 boundary refocus and `Stop` handover decisions; if that host does not fire those hooks, start or recover with `specrew start --host antigravity`.

If you launch your host inside an initialized project and no banner appears — the agent behaves as if the project were ungoverned — the SessionStart hook is not installed for that host, or it ran but the banner did not reach the session.

Here is what to do:

1. Check whether the hook is installed for your host. This works even in a broken project and prints the exact repair command:

   ```powershell
   specrew hooks status
   ```

   It reports each host as installed, missing, stale, opted-out, or failed.

2. Install or repair the hook for your host:

   ```powershell
   specrew hooks install
   ```

   Add `--host <claude|codex|copilot|cursor|antigravity>` to target one host. `specrew hooks remove [--host h]` is the inverse — it removes the hook and records an opt-out so the next `specrew update` does not re-add it.

3. If `specrew hooks status` shows the host installed but the banner still does not appear, re-run `specrew init` in the project root to refresh the project's hook and runtime surfaces, then relaunch.

`specrew hooks status | install | remove` is the supported, discoverable surface for all hook install, repair, and diagnostic work — reach for it rather than editing host config files by hand.

### The banner was delivered to a file (`WARN PAYLOAD_OVERSIZE`)

Some hosts cap how much a SessionStart hook may print — on Claude Code and Codex the limit is about **10,000 characters**. When Specrew's launch contract would exceed that cap, the host saves the hook output to a file and hands the agent only a short preview plus a file pointer, so the full orientation never reaches the session and the agent acts as if the project were ungoverned. The tell is a `WARN PAYLOAD_OVERSIZE` line in the hook output (or the host's own "output too large, saved to file" notice).

Specrew handles this automatically: on Claude and Codex it delivers the contract in **pointer mode** — it writes the full contract to `.specrew/last-start-prompt.md` and keeps the hook output small. If you still land in a session with no orientation, point the agent at the file yourself:

```text
Read .specrew/last-start-prompt.md and follow it.
```

That file always holds the complete launch contract for the current session, regardless of how it was delivered.

### Running a dev or branch build (`SPECREW_MODULE_PATH`)

If you are dogfooding an unreleased Specrew (a feature branch or a local dev tree), note that `SPECREW_MODULE_PATH` redirects the **runtime module commands** but **not** `specrew init`'s template source. So `specrew init` silently deploys templates from your **globally installed** version instead of your dev tree, and the project never picks up the changes you are trying to exercise — there is no warning, just stale files. To deploy a branch's surfaces, import the module **by path** first, then init:

```powershell
Import-Module C:\path\to\dev-tree\Specrew.psd1 -Force
specrew init
```

The import-by-path makes `specrew init` deploy that tree's templates. (`SPECREW_MODULE_PATH` alone is enough for the runtime commands; it does not redirect the one-time template deploy.)

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

## Resume re-asks for a verdict you already gave

If a resumed session reopens `=== AWAITING YOUR VERDICT ===` at a boundary you thought was already approved, this is verdict integrity working as designed, not a regression. A *committed* boundary is not an *authorized* boundary: artifacts can land in the tree without a recorded human verdict, so on resume a committed-but-unauthorized boundary surfaces the awaiting-verdict prompt and waits for you.

The rules the resuming agent must hold:

- It must not auto-advance on a bare "continue" — one approval advances at most one boundary.
- The recorded approver is never fabricated; only your explicit verdict authorizes the boundary.

What to do: read the surfaced packet and give the verdict explicitly (approve / redirect / send back). The boundary then advances exactly once.

One plain behavior note: if you switch to a non-Claude host mid-feature, the new session may ask you to re-confirm your last approval. Re-confirming the verdict on the resuming host is the safe path; do not have the agent assume authorization from the committed artifacts alone.

## Handover and concurrency advisories

Two messages around session start are advisories, not errors:

- **`HOLLOW HANDOVER` / "the previous session did NOT author a handover body"** — the rolling handover's frontmatter floor is present (feature, boundary, commit), but the eight rich body sections were never authored by the previous agent (a section starting with "(placeholder" is the tell). The resuming agent is told to re-derive from the lifecycle artifacts instead — workshop records, spec, tasks. Work is not lost; the resume is simply artifact-derived rather than narrative. To prevent the hollow handover on a deliberate switch, have the outgoing agent persist its interpretive sections first: `specrew handover author --from <file>` (or `--stdin`) writes the agent-authored sections — notably the open questions and working hypothesis that no hook can derive — so the next session/host inherits authored context instead of placeholders. The Markdown `##` headers in that file name the sections (it also accepts `--feature`, `--boundary`, and `--host`).
- **"another session may be active in this worktree (marker within 1h)"** — the previous session's `.specrew/runtime/session-marker.json` is less than an hour old. After a normal exit-and-relaunch (or a host switch) this is expected and safe to ignore. It matters only if you really do have two live agents in the same worktree — then coordinate or close one. Deleting the marker file silences it immediately; it is local scratch state.

## A crash lost recent conversation, or Antigravity shows no welcome-back

These are the two expected continuity limits — by design, not bugs:

- **A hard kill (SIGKILL, power loss, a force-closed window) loses the conversation tail since the last capture.** No hook can fire after the process is already gone, so this floor is universal and uncloseable. What you lose is bounded by the host's capture cadence: on Claude the handover refreshes every PostToolUse (seconds), so a crash loses little; on Codex / Copilot / Cursor the last capture is the previous *graceful* Stop, so an ungraceful kill loses back to there. **Durable state never goes** — every committed artifact and the working tree survive, and the next session's disk scan re-derives the position. To minimize exposure, end sessions with `/exit` (a graceful stop) rather than closing the window.
- **Antigravity produces no orientation banner, refocus injection, or handover** — its project hooks did not fire or did not deliver into the host session. Specrew supports `.agents/hooks.json` with `PreInvocation` bootstrap + B3 boundary refocus and `Stop` handover, but that is not a guarantee across every Antigravity build or channel. Antigravity is still fully governed and resumable: recover through `specrew start --host antigravity`, which reads the handover written by whichever host last ran and runs the same reconciliation, and its own work survives on disk for the next session. If you need conversation capture from an Antigravity stretch and Stop did not fire, run a graceful stop in another hook-capable host (Claude / Codex / Copilot / Cursor) at the next switch so a handover gets written.

For Antigravity-specific resume checks:

```powershell
agy --version
agy -c
agy --conversation <conversation-id>
```

If Antigravity is asking for permission on every tool call and you intentionally want auto-approval between Specrew boundaries, either launch through Specrew with `specrew start --host antigravity --allow-all` or launch Antigravity directly with `agy --dangerously-skip-permissions`. Do not confuse that with `agy --sandbox`: sandboxing constrains terminal execution, while `--dangerously-skip-permissions` skips the interactive tool permission prompts.

To inspect Antigravity-native permissions without changing Specrew hooks, run `/permissions` inside `agy`. To constrain terminal execution, use Antigravity sandboxing (`agy --sandbox` or `enableTerminalSandbox` in Antigravity settings). To disable only Specrew's Antigravity hooks while preserving user-owned `.agents/hooks.json` entries, run:

```powershell
specrew hooks remove --host antigravity
specrew hooks status --host antigravity
```

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

## Refocus automation seems dead this session

Run the status probe first — every branch ends in one named action:

1. `pwsh -File .specify/extensions/specrew-speckit/scripts/refocus.ps1 --status`
2. **Breaker tripped?** The journal shows `BREAKER_TRIPPED` + the reason. Re-enable: `--reset-breaker`, or start a new session. Recurring? Disable that trigger durably in `refocus-scopes.json` and file the journal evidence.
3. **Env kill switch set?** `SPECREW_REFOCUS_DISABLE` silences all hook triggers — unset it.
4. **Trigger disabled in the catalog?** `--status` lists per-trigger `enabled` flags with no guesswork.
5. **All green but silent?** Check the journal tail: `deduped` means channel 1 already delivered (working as designed); `budget-clipped` means the payload hit its token cap; nothing at all means the hook isn't registered — re-provision with `specrew hooks install` (it respects a recorded opt-out; add `--host <host>` or `--force` to re-enable an opted-out host explicitly). `specrew hooks status | install | remove` is the canonical, run-anywhere hook surface.

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

The supported floor and the latest tested version are declared in `scripts/internal/supported-versions.yml` (`speckit.min` / `speckit.max_tested`) — currently floor **0.8.4**, tested up to **0.9.0**. `specrew init` prints the exact remediation command for the floor; run it (add `--force` to replace an existing tool install):

```sh
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git@v0.8.4 --force
```

Then re-run `specrew init`. (`uv` is required — see [getting-started](getting-started.md#1-check-dependencies).) The `@v…` tag tracks Specrew's supported floor; if the command `specrew init` prints names a different version, prefer the printed one — it is generated from the runtime baseline, not from this doc.
