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
