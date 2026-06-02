# Release Gate — Iteration 3 (T024, beta-before-stable)

**Feature**: 140-unix-native-install
**Iteration**: 003
**Task**: T024 (FR-015, FR-017; SC-006, SC-008)
**Status**: 🛑 **BLOCKED — awaiting explicit maintainer beta-publish authorization.** The Crew has
**not** published anything. No beta, no stable. This artifact is the procedure + evidence template; the
publish + on-host validation are maintainer-driven and require a real Unix host.

## The gate (universal beta-before-stable mandate)

No stable publication without first publishing a **beta**, installing that published beta on a **real Unix
host**, and validating BOTH a greenfield and a brownfield project. This also validates the bundled, still
unreleased **Spec Kit 0.9.0** support (PR #1626) that rides this feature's release. The prerelease install
MUST use the shell-native flow (`curl … | sh -s -- --prerelease`, FR-017).

**Two gates upstream of this one must be green first:**

1. **CI green** on the branch — `validate-macos` (T020), `feature140-*` Ubuntu jobs, parity cascade incl.
   the new docs arm (T023).
2. **T021 macOS manual proof** filed with real outputs (`macos-manual-proof.md`). The release gate installs
   the *published* beta; T021 proves the *branch* install path on macOS first.

## Procedure (maintainer-driven)

```text
0. PRECONDITION: maintainer explicitly authorizes a beta publish for this feature. (Do not proceed without it.)
1. Bump the prerelease version and publish the beta to the PowerShell Gallery
   (publish-module.yml / the prerelease publish path). Record the exact version, e.g. 0.31.0-beta.1.
2. On a real Unix host (macOS for this feature's surface), in a clean shell:
     curl -fsSL https://raw.githubusercontent.com/alonf/specrew/main/install.sh | sh -s -- --prerelease
   Expect: installer states it is installing a PRERELEASE; pwsh auto-installed if absent (Homebrew);
   the version/source-mismatch check passes (the published beta exposes bin/specrew).
3. Confirm the prerelease is what got installed:
     specrew version        # MUST report the beta version from step 1
4. GREENFIELD validation:
     mkdir gf && cd gf && git init && specrew init && specrew start "..."   # exercise version/init/start
5. BROWNFIELD validation:
     cd <an existing project> && specrew init && specrew start "..."        # exercise on existing content
6. Confirm bundled Spec Kit 0.9.0 support is active (specrew init bootstraps/validates Spec Kit).
7. Record all outputs in the Evidence section below and commit.
8. ONLY after the beta is validated green here may a stable release be promoted — as a separate,
   separately-authorized step. Stable promotion is NOT part of this task.
```

## Evidence (fill in from the real host; commit with outputs)

| Step | Expected | Actual | Pass? |
| --- | --- | --- | --- |
| Maintainer authorization recorded | explicit go-ahead (who / when) | (record) | ☐ |
| Beta published | version + Gallery link | (record) | ☐ |
| `curl … \| sh -s -- --prerelease` | states PRERELEASE; pwsh ensured; mismatch check passes | (paste) | ☐ |
| `specrew version` | reports the beta version from step 1 | (paste) | ☐ |
| Greenfield `init`/`start` | succeeds end-to-end | (paste) | ☐ |
| Brownfield `init`/`start` | succeeds on existing content | (paste) | ☐ |
| Spec Kit 0.9.0 active | bootstrapped/validated by init | (paste) | ☐ |

**Authorized by**: (name) · **Beta version**: (x.y.z-beta.N) · **Host**: (macOS version) · **Date**: (YYYY-MM-DD)

## What the Crew did NOT do (by design)

- Did not publish a beta or stable (FR-015: no publish without explicit maintainer authorization).
- Did not promote anything to stable.
- Built `install.sh --prerelease` (T019) and asserted its surface + the mismatch predicate (unit-level);
  the live prerelease install against a published beta is proven HERE, once authorized.
