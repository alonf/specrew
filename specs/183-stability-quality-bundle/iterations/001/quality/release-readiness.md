# Release Readiness Evidence

**Schema**: v1
**Feature**: 183-stability-quality-bundle
**Iteration**: 001
**Task**: T008
**Recorded At**: 2026-06-16T10:16:36Z
**Result**: PASS WITH RELEASE-LINE UPDATE; STANDALONE BETA SKIPPED BY HUMAN DECISION

## Decision

The planned `0.37.0-beta<N>` line is no longer a valid target for this feature:
`0.37.0-beta1` and `0.37.0` are already tagged, released, and published. This
feature must not publish a new `0.37.0` prerelease after the stable `0.37.0`
package exists.

**Selected next beta target**: `0.38.0-beta1`

**Stable promotion target after validation**: `0.38.0`

No beta or stable promotion is authorized until T009 records real-host validation
PASS, including the Antigravity hook-firing evidence required by FR-007/SC-009.

## Feature-Closeout Release Decision

At feature closeout, the maintainer elected to skip a standalone
`0.38.0-beta1` publish for F-183 and continue directly into the full
Antigravity refocus feature. This is a human-authorized release-discipline
deviation recorded as DR-005 in
`file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/iterations/001/drift-log.md`.

Rationale:

- F-183 bounded Antigravity surfaces were manually validated on a real `agy`
  host in `file:///C:/Temp/f183-test/`.
- The remaining Antigravity gaps are known and named: same-worktree concurrency
  false-positive and missing per-session refocus state/anchor on the
  Antigravity bootstrap path.
- Publishing a standalone beta before the full-Antigravity feature would create
  a short-lived beta that still carries intentionally bounded behavior.

Release consequence:

- Do not tag or publish a standalone F-183 `v0.38.0-beta1`.
- Do not promote stable from F-183.
- The next beta/stable release decision moves to the combined release gate after
  the full-Antigravity feature closes.
- If packaged PSGallery install/upgrade validation or the legacy
  `MigrateLegacyTopLevelEventMap` path cannot be validated without a packaged
  beta, stop at that release gate for an explicit human verdict rather than
  proceeding silently.

## Inputs Checked

### Local Tags

Command:

```powershell
git tag --list "v0.37.0*" "v0.36.0*" "v0.35.0*" | Sort-Object
git tag --list "v0.38.0*" "v0.37.1*" | Sort-Object
```

Observed:

```text
v0.35.0
v0.35.0-beta1
v0.36.0
v0.36.0-beta1
v0.37.0
v0.37.0-beta1
```

No local `v0.37.1*` or `v0.38.0*` tags exist.

### Origin Tags

Command:

```powershell
git ls-remote --tags origin "refs/tags/v0.37.0*" "refs/tags/v0.36.0*" "refs/tags/v0.35.0*"
git ls-remote --tags origin "refs/tags/v0.38.0*" "refs/tags/v0.37.1*"
```

Observed:

```text
b9df548d9b24b39ce9e2d2ff5034ac8193a73214 refs/tags/v0.35.0
17bf1c72422bbd82442e544233f21f7de2abeb75 refs/tags/v0.35.0-beta1
6900f63ae0beefe707b854987531b64b0d147a24 refs/tags/v0.36.0
6900f63ae0beefe707b854987531b64b0d147a24 refs/tags/v0.36.0-beta1
767f8c2ac13d2609683b1a9f6f06141e026d3791 refs/tags/v0.37.0
cf7848147ae99bebfca6b21e9f11579bdd505e94 refs/tags/v0.37.0-beta1
```

No origin `v0.37.1*` or `v0.38.0*` tags exist.

### PowerShell Gallery Package State

Command:

```powershell
Find-Module -Name Specrew -Repository PSGallery -AllVersions -AllowPrerelease |
  Select-Object -First 20 Name,Version,PublishedDate
Find-Module -Name Specrew -Repository PSGallery -AllVersions -AllowPrerelease |
  Where-Object { $_.Version -like '0.38.0*' -or $_.Version -like '0.37.1*' }
```

Observed top entries:

```text
Specrew 0.37.0       2026-06-15 23:33:54
Specrew 0.37.0-beta1 2026-06-15 05:41:55
Specrew 0.36.0       2026-06-13 22:59:32
Specrew 0.36.0-beta1 2026-06-13 16:21:27
Specrew 0.35.0       2026-06-11 02:03:02
Specrew 0.35.0-beta1 2026-06-10 23:31:38
```

No PSGallery `0.37.1*` or `0.38.0*` package exists.

### GitHub Release State

Command:

```powershell
gh release list --repo alonf/specrew --limit 20
gh release list --repo alonf/specrew --limit 50 | Select-String -Pattern '0\.38\.0|0\.37\.1'
```

Observed top entries:

```text
Specrew v0.37.0       Latest      v0.37.0       2026-06-15T23:34:01Z
Specrew v0.37.0-beta1 Pre-release v0.37.0-beta1 2026-06-15T05:42:02Z
Specrew v0.36.0                   v0.36.0       2026-06-13T22:59:40Z
Specrew v0.36.0-beta1 Pre-release v0.36.0-beta1 2026-06-13T16:21:36Z
```

No GitHub release for `0.37.1*` or `0.38.0*` exists.

## Release Prep Guardrails

- Before the next publish, update version-bearing surfaces from the stale
  `0.37.0-beta1` development line to the human-selected beta target for the
  combined release.
- Do not publish a standalone F-183 `v0.38.0-beta1`; the maintainer explicitly
  skipped it at feature closeout.
- Promote stable only from a beta that passed manual validation.
- If the maintainer chooses a patch line instead, record that human decision and
  retarget to `0.37.1-beta1`; no current artifact reserves that line.
