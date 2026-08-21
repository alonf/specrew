---
name: "specrew-local-build"
description: "Run Specrew's own fixes against a real project: which install route to use, why the module and the project are two separate sides, and how to tell what is actually installed."
domain: "development-loop"
confidence: "high"
source: "Written 2026-08-21 after a week in which every local install was hand-assembled, one install's stamp named a commit that did not describe its contents, and a session concluded from a release script's cleanup that no install path existed at all."
---

# specrew-local-build

**Type**: Procedure Skill
**Schema**: v1

## Why this exists

Three separate sessions reached three wrong conclusions about this in one week, each reasonably:

- One concluded there was **no supported local install path**, because `invoke-module-release.ps1`
  deletes its stage in a `finally`. That is a release tool behaving correctly; it was never the install
  path. The wrong tool was picked up and its correct behaviour read as an absence.
- One installed by **hand-copying individual files** into the module directory. The code became current
  and the build stamp did not, so the install reported a commit that did not describe its contents. It
  was caught only because someone diffed 82 files.
- One updated a **project** from repo source and found every review refused with
  `review-engine-version-mismatch`, and concluded the local-source capability had been removed. It had
  not. Only half the handshake had been satisfied.

The through-line: **there are two sides, and both have to move together.**

## The two sides

| side | what it is | how it moves |
| --- | --- | --- |
| **module** | the installed Specrew (`Get-Module -ListAvailable Specrew`) | `scripts/internal/install-local-build.ps1` |
| **project** | the runtime bundle deployed into a governed project | `specrew update --project-path <project>` |

`scripts/internal/review-engine-resolution.ps1` compares them and **refuses every review** when they
disagree. That check is deliberate — it is what makes a review's provenance verifiable — and it is why
moving only one side wedges the project.

## The routes, and when each is right

### 1. Testing a build — the default

Use when running a manual walk, reproducing a defect, or handing a build to someone. Exercises **what
ships**, from a committed tree.

```powershell
pwsh -File scripts/internal/install-local-build.ps1          # package HEAD, install, verify
specrew update --project-path C:\Path\To\Project             # then the other side, per project
```

It refuses a dirty tree by default (scoped to packaged files, so uncommitted specs and drift logs do not
block it). `-WhatIfOnly` reports the identity it would install without touching anything. `-AllowDirty`
packages uncommitted work and says so loudly — the result is reproducible from no commit.

### 2. Fast inner loop — editing Specrew itself

A junction makes the module *be* the repo, so both sides are the same tree and cannot disagree:

```powershell
New-Item -ItemType Junction -Path "$HOME\Documents\PowerShell\Modules\Specrew\0.40.0-dev" -Target C:\Dev\specrew-beta3-stabilization
```

**Do not walk a test on this.** It points at a working tree, so what you are exercising changes as you
type and matches no commit. That is the exact drift the packaged route exists to prevent.

### 3. Project side only — from repo source, no install

Has always worked, and is easy to miss because the `specrew` alias resolves to the *installed* module:

```powershell
pwsh -File C:\Dev\specrew-beta3-stabilization\scripts\specrew-update.ps1 -ProjectPath C:\Path\To\Project
```

`specrew-update.ps1` resolves its repo root from its own location, so invoking the **repo copy by path**
sources from the repo. On its own this moves one side only, and reviews will refuse until the module
matches.

### 4. Releasing

`scripts/internal/invoke-module-release.ps1` — dry-run, publish-prerelease, publish-stable. It stages,
stamps and publishes, and deletes its stage afterwards. It is not an installer and should not be made
into one; both it and the installer call the same `scripts/internal/module-packaging.ps1`.

## Reading what is actually installed

```powershell
specrew version                                    # e.g. 0.40.0-beta3 (182f87ba)
$m = (Get-Module -ListAvailable Specrew | Sort-Object Version -Descending | Select-Object -First 1).ModuleBase
Get-Content (Join-Path $m 'build-stamp.json') -Raw | ConvertFrom-Json
```

The stamp carries `commit`, `content_sha256` and `content_file_count`. **The commit records intent; the
content hash is the checkable part** — a stamp used to name a commit that did not describe its files, and
that is what the hash prevents.

`content_file_count` records the scope, because a hash without one is not reproducible: the first
independent verification of a new stamp disagreed with it purely because the verifier hashed FileList
while the stamp covers every staged file (FileList plus the optional README/CHANGELOG/LICENSE/NOTICE).
Compare counts before comparing hashes.

## Diagnosing the common failures

| symptom | cause | fix |
| --- | --- | --- |
| `specrew: command not found` in Git Bash | it is a PowerShell module command | run from PowerShell, or `pwsh -NoProfile -Command "specrew ..."` |
| `review-engine-version-mismatch` | module and project disagree | install the module, then `specrew update --project-path` for each project |
| `review-engine-project-runtime-drifted` | the project's bundle was edited after deployment | re-run `specrew update` for that project |
| `specrew update` fetches the same build | the module is older than the repo | install first — updating a project cannot introduce code the module does not have |
| install claims a commit whose code it lacks | files hand-copied into the module | use the installer; it byte-verifies and re-checks the stamp against what landed |

## The rule underneath

Both mechanisms this skill documents were assumed to exist and did not: a supported installer, and a
stamp that could be checked. Each was honoured by something downstream and produced by nothing, and each
went unnoticed until the moment it was needed.

**If you did it by hand and did not pin it, it is not a mechanism yet.**
