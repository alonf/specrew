# Release Gate — Iteration 3 (T024, beta-before-stable)

**Feature**: 140-unix-native-install
**Iteration**: 003
**Task**: T024 (FR-015, FR-017; SC-006, SC-008)
**Status**: 🛑 **BLOCKED — awaiting explicit maintainer beta-publish authorization.** The Crew has **not**
tagged, published, or triggered the publish workflow. This is the procedure + evidence template; the publish
and the on-host validation are maintainer-driven and require real Unix hosts.

## The beta + its version (READ FIRST)

This feature's beta MUST be **`0.31.0-beta3`** — NOT a `0.30.0-betaN`. `0.30.0` stable is already published,
and a `0.30.0-betaN` sorts *below* `0.30.0` in semver, so `Install-Module -AllowPrerelease` would silently
install the **stable**, never the beta. The PSGallery prerelease label cannot contain a dot, so the tag is
**`v0.31.0-beta3`** (dotless — matches the published `v0.30.0-beta1 … beta6` convention; a dotted
`beta.3` is normalized to `beta3` anyway). The branch already carries Spec Kit 0.9.0 (commit `ca897ee6`),
Feature 051, and Proposal 152, so a **branch-cut** beta from `140-unix-native-install` validates FR-015's
0.9.0 claim without a premature merge to main.

**Beta history (beta-before-stable iterate loop — the process working as designed):**

- `0.31.0-beta1` — first prerelease. Linux validation found 3 Unix-install bugs (install-if-absent /
  side-by-side false-"Done"; wrapper exec-bit `Permission denied`; clone-mode `pwsh -File …` guidance).
- `0.31.0-beta2` — carried the 3 beta1 fixes. Linux validation found the **interactive `specrew start`
  bug** (see the finding below): the native wrapper launched the host headless and exited instead of
  opening an interactive session.
- `0.31.0-beta3` — carries the interactive-`start` re-dispatch fix + its CI regression guard. **Current.**

**Version prep (committed on the branch; tag/publish intentionally NOT done by the Crew):**
`.specrew/config.yml` `specrew_version: "0.31.0"`; `Specrew.psd1` `ModuleVersion = '0.31.0'` / `Prerelease = 'beta3'`;
CHANGELOG `## [0.31.0-beta3]` entry.

## Empirical finding from the 0.31.0-beta2 Linux validation (drove beta3)

Two issues surfaced when the maintainer ran the published `0.31.0-beta2` on a real Linux host:

1. **Interactive `specrew start` ran the host headless (BLOCKING — fixed in beta3).** `bin/specrew` and
   clone-mode run `scripts/specrew.ps1` via `pwsh -File` (SCRIPT context). On Linux/macOS, PowerShell strips
   the controlling TTY from native command children spawned in a script body, so `specrew-start.ps1` took its
   no-TTY fallback (`& copilot …`); Copilot ran once (≈50s, ~143k tokens) and exited straight back to the
   shell. The TTY-preserving launch lives in the module function `Invoke-SpecrewScript` (the R-019-V2
   deferred-launch handoff), which the native wrapper never entered. **Fix:** a top-of-dispatch guard in
   `scripts/specrew.ps1` re-dispatches `start` on Unix through the module function (host launches in FUNCTION
   context; proven launch body untouched). Guarded by a new regression test
   (`tests/integration/start-deferred-launch.sh`, Ubuntu + macOS lanes).

2. **`specrew version` reports the base version, not the prerelease label (non-blocking — fast-follow).**
   The report prints `0.31.0` (the manifest `ModuleVersion`); the `Prerelease` label lives in
   `PrivateData.PSData.Prerelease` and is never surfaced. So `specrew version` cannot, by itself, distinguish
   `0.31.0-beta3` from a hypothetical `0.31.0` stable. Surfacing the label reliably needs side-by-side-aware
   resolution (the same trap as beta1's install-if-absent bug), so it is a **fast-follow** chore, not a
   beta3 blocker. The release-gate version-proof row below is amended accordingly.

## The gate (universal beta-before-stable mandate)

No stable promotion without first publishing the **`0.31.0-beta3`** beta, installing it on real Unix hosts,
and validating BOTH a greenfield and a brownfield project on **EACH required surface** — including the
**interactive** `specrew start` (an interactive host session must actually open; the beta2 bug above is
exactly what a headless/file-presence check would miss). This also validates the bundled Spec Kit 0.9.0
support (PR #1626).

**Required validation surfaces — BOTH required before Iteration 3 closeout:**

- **Linux** *(surface added 2026-06-03)* — a clean host, ideally **without** `pwsh` so the apt auto-install
  runs on a real host (stronger than the CI container).
- **macOS** *(unchanged requirement)* — the **T021** clean-install manual proof (`macos-manual-proof.md`)
  **plus** the macOS greenfield/brownfield release-gate evidence below, owned by the external macOS tester.
  **Adding Linux does NOT replace or waive the macOS evidence.**

**Upstream gates (branch CI):** `validate-macos` (T020) + `feature140-*` Ubuntu jobs + the parity cascade
incl. the docs arm (T023) + the new interactive-`start` deferred-launch regression on the Ubuntu **and**
macOS lanes. **Caveat:** CI has no TTY, so the deferred-launch test proves the mechanism **engages**, not
that the TUI renders — the interactive proof is the on-host validation below.

## Publish (maintainer-driven; the Crew did NOT do this)

```text
0. PRECONDITION: maintainer explicitly authorizes the 0.31.0-beta3 beta publish. (Do not proceed without it.)
1. Tag the 140-unix-native-install HEAD `v0.31.0-beta3` and push it (-> publish-module.yml publish-prerelease),
   OR run the "Publish Specrew module" workflow via workflow_dispatch ON the 140 branch with
   release_mode=publish-prerelease, release_tag=v0.31.0-beta3.
   The workflow stamps the manifest from the tag and cross-checks .specrew/config.yml specrew_version (0.31.0).
2. Confirm 0.31.0-beta3 is live on the PowerShell Gallery.
```

## Validate — per surface (run on a clean host; record outputs; commit)

Run this on EACH required surface (Linux, then macOS):

```text
A. Install the PUBLISHED beta via the BRANCH install.sh (main has no install.sh until 140 merges):
     curl -fsSL https://raw.githubusercontent.com/alonf/specrew/140-unix-native-install/install.sh | sh -s -- --prerelease
   (or, from a 140 checkout: bash ./install.sh --prerelease)
   Expect: output STATES PRERELEASE; pwsh auto-installed if absent (Linux: apt; macOS: Homebrew);
   the wrapper-surface mismatch check passes (the beta exposes bin/specrew).
B. Confirm the prerelease installed (NOT the stable):
     Get-Module Specrew -ListAvailable | Select-Object Version, @{n='Prerelease';e={$_.PrivateData.PSData.Prerelease}}
     -> MUST show Version 0.31.0 with Prerelease 'beta3'. (`specrew version` reports the base 0.31.0 only;
        surfacing the label in `specrew version` is a fast-follow — see finding #2 above.)
C. INTERACTIVE start (the beta2 regression): specrew start  ->  an interactive host session MUST OPEN
   (not a one-shot run that prints a token summary and returns to the shell).
D. GREENFIELD: mkdir gf && cd gf && git init && specrew init && specrew start "build something small"
   -- specrew init MUST actually bootstrap/validate Spec Kit (0.9.0 exercised here -- the real deliverable,
      not just a version check)
E. BROWNFIELD: cd <an existing project> && specrew init && specrew start "..."
F. Record outputs in the matching surface table below.
```

Stable promotion is a SEPARATE, separately-authorized step AFTER **both** surfaces pass. Not part of this task.

## Evidence — Linux surface (added 2026-06-03)

| Step | Expected | Actual | Pass? |
| --- | --- | --- | --- |
| Beta published (0.31.0-beta3) | version + Gallery link | published; `Find-Module … -RequiredVersion 0.31.0-beta3 -AllowPrerelease` → FOUND; GitHub release `v0.31.0-beta3` | ✅ |
| install.sh `--prerelease` (branch URL) | states PRERELEASE; pwsh ensured; mismatch check passes | maintainer-run 2026-06-03: "Installing the Specrew module (PRERELEASE / beta)…"; pwsh 7.6.1 already present (no-pwsh apt path NOT exercised here — covered by the clean-container CI job); 8 wrappers installed; native `specrew` works | ✅ |
| Prerelease confirmed | beta3 actually installed | beta3 behavior present (the interactive-start fix below); explicit `Get-Module … Prerelease` recommended as the canonical check (finding #2: `specrew version` still prints base `0.31.0`) | ✅ |
| **Interactive `specrew start`** | an interactive host session OPENS (not a headless one-shot) | **maintainer-confirmed 2026-06-03: interactive Copilot session opened** (the beta2 headless exit is resolved) | ✅ |
| Greenfield `init` / `start` | succeeds; Spec Kit 0.9.0 bootstrapped | (pending — fresh greenfield run not yet recorded) | ☐ |
| Brownfield `init` / `start` | succeeds on existing content | `specrew start` confirmed interactive in the existing `~/testspecrew` project; full `init`/`start` greenfield evidence still pending | ◑ |

**Linux host**: HOMEALON11 (Linux, pwsh 7.6.1 present) · **By**: Alon Fliess · **Date**: 2026-06-03
**Note**: the headline interactive-`start` deliverable is PROVEN on Linux. Remaining for a complete Linux gate: a fresh greenfield `init`/`start` exercising the Spec Kit 0.9.0 bootstrap.

## Evidence — macOS surface (REQUIRED; external tester)

| Step | Expected | Actual | Pass? |
| --- | --- | --- | --- |
| install.sh `--prerelease` (branch URL) | states PRERELEASE; pwsh ensured (Homebrew); mismatch check passes | (paste) | ☐ |
| Prerelease confirmed | `Get-Module … Prerelease` shows 0.31.0 / beta3 | (paste) | ☐ |
| **Interactive `specrew start`** | an interactive host session OPENS (not a headless one-shot) | (paste) | ☐ |
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
- Could NOT prove the interactive TUI renders in CI (no TTY) — the deferred-launch regression test proves
  the mechanism engages; the interactive proof is the on-host validation above.

## Authorization

**Authorized by**: (name) · **Beta version**: 0.31.0-beta3 · **Date**: (YYYY-MM-DD)
