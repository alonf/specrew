# Release Gate — Iteration 3 (T024, beta-before-stable)

**Feature**: 140-unix-native-install
**Iteration**: 003
**Task**: T024 (FR-015, FR-017; SC-006, SC-008)
**Status**: 🛑 **BLOCKED — awaiting explicit maintainer beta-publish authorization.** The Crew has **not**
tagged, published, or triggered the publish workflow. This is the procedure + evidence template; the publish
and the on-host validation are maintainer-driven and require real Unix hosts.

## The beta + its version (READ FIRST)

This feature's beta MUST be **`0.31.0-beta2`** — NOT a `0.30.0-betaN`. `0.30.0` stable is already published,
and a `0.30.0-betaN` sorts *below* `0.30.0` in semver, so `Install-Module -AllowPrerelease` would silently
install the **stable**, never the beta. The PSGallery prerelease label cannot contain a dot, so the tag is
**`v0.31.0-beta2`** (dotless — matches the published `v0.30.0-beta1 … beta6` convention; a dotted
`beta.1` is normalized to `beta1` anyway). The branch already carries Spec Kit 0.9.0 (commit `ca897ee6`),
Feature 051, and Proposal 152, so a **branch-cut** beta from `140-unix-native-install` validates FR-015's
0.9.0 claim without a premature merge to main.

**Version prep (committed on the branch; tag/publish intentionally NOT done by the Crew):**
`.specrew/config.yml` `specrew_version: "0.31.0"`; `Specrew.psd1` `ModuleVersion = '0.31.0'` / `Prerelease = 'beta2'`;
CHANGELOG `## [0.31.0-beta2]` entry.

## The gate (universal beta-before-stable mandate)

No stable promotion without first publishing the **`0.31.0-beta2`** beta, installing it on real Unix hosts,
and validating BOTH a greenfield and a brownfield project on **EACH required surface**. This also validates
the bundled Spec Kit 0.9.0 support (PR #1626).

**Required validation surfaces — BOTH required before Iteration 3 closeout:**

- **Linux** *(surface added 2026-06-03)* — a clean host, ideally **without** `pwsh` so the apt auto-install
  runs on a real host (stronger than the CI container).
- **macOS** *(unchanged requirement)* — the **T021** clean-install manual proof (`macos-manual-proof.md`)
  **plus** the macOS greenfield/brownfield release-gate evidence below, owned by the external macOS tester.
  **Adding Linux does NOT replace or waive the macOS evidence.**

**Upstream gates (already green):** branch CI green — `validate-macos` (T020) + `feature140-*` Ubuntu jobs +
the parity cascade incl. the docs arm (T023) — run `26852247885`.

## Publish (maintainer-driven; the Crew did NOT do this)

```text
0. PRECONDITION: maintainer explicitly authorizes the 0.31.0-beta2 beta publish. (Do not proceed without it.)
1. Tag the 140-unix-native-install HEAD `v0.31.0-beta2` and push it (-> publish-module.yml publish-prerelease),
   OR run the "Publish Specrew module" workflow via workflow_dispatch ON the 140 branch with
   release_mode=publish-prerelease, release_tag=v0.31.0-beta2.
   The workflow stamps the manifest from the tag and cross-checks .specrew/config.yml specrew_version (0.31.0).
2. Confirm 0.31.0-beta2 is live on the PowerShell Gallery.
```

## Validate — per surface (run on a clean host; record outputs; commit)

Run this on EACH required surface (Linux, then macOS):

```text
A. Install the PUBLISHED beta via the BRANCH install.sh (main has no install.sh until 140 merges):
     curl -fsSL https://raw.githubusercontent.com/alonf/specrew/140-unix-native-install/install.sh | sh -s -- --prerelease
   (or, from a 140 checkout: bash ./install.sh --prerelease)
   Expect: output STATES PRERELEASE; pwsh auto-installed if absent (Linux: apt; macOS: Homebrew);
   the wrapper-surface mismatch check passes (the beta exposes bin/specrew).
B. specrew version            # MUST report 0.31.0-beta2 (proves the prerelease installed, not the stable)
C. GREENFIELD: mkdir gf && cd gf && git init && specrew init && specrew start "build something small"
   -- specrew init MUST actually bootstrap/validate Spec Kit (0.9.0 exercised here -- the real deliverable,
      not just `specrew version`)
D. BROWNFIELD: cd <an existing project> && specrew init && specrew start "..."
E. Record outputs in the matching surface table below.
```

Stable promotion is a SEPARATE, separately-authorized step AFTER **both** surfaces pass. Not part of this task.

## Evidence — Linux surface (added 2026-06-03)

| Step | Expected | Actual | Pass? |
| --- | --- | --- | --- |
| Beta published (0.31.0-beta2) | version + Gallery link | (record) | ☐ |
| install.sh `--prerelease` (branch URL) | states PRERELEASE; pwsh ensured (apt); mismatch check passes | (paste) | ☐ |
| `specrew version` | reports 0.31.0-beta2 | (paste) | ☐ |
| Greenfield `init` / `start` | succeeds; Spec Kit 0.9.0 bootstrapped | (paste) | ☐ |
| Brownfield `init` / `start` | succeeds on existing content | (paste) | ☐ |

**Linux host**: (distro + version) · **By**: (name) · **Date**: (YYYY-MM-DD)

## Evidence — macOS surface (REQUIRED; external tester)

| Step | Expected | Actual | Pass? |
| --- | --- | --- | --- |
| install.sh `--prerelease` (branch URL) | states PRERELEASE; pwsh ensured (Homebrew); mismatch check passes | (paste) | ☐ |
| `specrew version` | reports 0.31.0-beta2 | (paste) | ☐ |
| Greenfield `init` / `start` | succeeds; Spec Kit 0.9.0 bootstrapped | (paste) | ☐ |
| Brownfield `init` / `start` | succeeds on existing content | (paste) | ☐ |

**macOS host**: (version) · **By**: (external tester) · **Date**: (YYYY-MM-DD)
Clean no-`pwsh` auto-install manual proof: see `macos-manual-proof.md` (T021).

## What the Crew did NOT do (by design)

- Did NOT tag, publish, or trigger the publish workflow — the maintainer authorizes/pushes the tag.
- Did NOT promote anything to stable.
- Did NOT waive the macOS evidence — Linux is **added**; macOS (T021 + macOS release-gate) **remains required**.
- Built `install.sh --prerelease` (T019) + asserted its surface/mismatch predicate (unit-level); the live
  prerelease install against the published beta is proven HERE, per surface, once authorized.

## Authorization

**Authorized by**: (name) · **Beta version**: 0.31.0-beta2 · **Date**: (YYYY-MM-DD)
