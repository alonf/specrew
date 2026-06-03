# Release Gate — Iteration 3 (T024, beta-before-stable)

**Feature**: 140-unix-native-install
**Iteration**: 003
**Task**: T024 (FR-015, FR-017; SC-006, SC-008)
**Status**: 🛑 **BLOCKED — awaiting explicit maintainer beta-publish authorization.** The Crew has **not**
tagged, published, or triggered the publish workflow. This is the procedure + evidence template; the publish
and the on-host validation are maintainer-driven and require real Unix hosts.

## The beta + its version (READ FIRST)

This feature's beta MUST be **`0.31.0-beta4`** — NOT a `0.30.0-betaN`. `0.30.0` stable is already published,
and a `0.30.0-betaN` sorts *below* `0.30.0` in semver, so `Install-Module -AllowPrerelease` would silently
install the **stable**, never the beta. The PSGallery prerelease label cannot contain a dot, so the tag is
**`v0.31.0-beta4`** (dotless — matches the published `v0.30.0-beta1 … beta6` convention; a dotted
`beta.4` is normalized to `beta4` anyway). The branch already carries Spec Kit 0.9.0 (commit `ca897ee6`),
Feature 051, and Proposal 152, so a **branch-cut** beta from `140-unix-native-install` validates FR-015's
0.9.0 claim without a premature merge to main.

**Beta history (beta-before-stable iterate loop — the process working as designed):**

- `0.31.0-beta1` — first prerelease. Linux validation found 3 Unix-install bugs (install-if-absent /
  side-by-side false-"Done"; wrapper exec-bit `Permission denied`; clone-mode `pwsh -File …` guidance).
- `0.31.0-beta2` — carried the 3 beta1 fixes. Linux validation found the **interactive `specrew start`
  bug** (see the finding below): the native wrapper launched the host headless and exited instead of
  opening an interactive session.
- `0.31.0-beta3` — carried the interactive-`start` re-dispatch fix + cursor fix. **Linux-PROVEN 2026-06-03**
  (`specrew start` opens interactive Copilot). Missing only the post-tag fast-follow.
- `0.31.0-beta4` — adds the fast-follow: `specrew version` now shows the prerelease label (finding #2 fixed),
  and the regression test is strengthened to prove TTY survival. **Current — the beta-before-stable vehicle
  for the merged code before stable promotion.**

**Version prep (committed on the branch; tag/publish intentionally NOT done by the Crew):**
`.specrew/config.yml` `specrew_version: "0.31.0"`; `Specrew.psd1` `ModuleVersion = '0.31.0'` / `Prerelease = 'beta4'`;
CHANGELOG `## [0.31.0-beta4]` entry.

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

2. **`specrew version` reported the base version, not the prerelease label — FIXED in beta4.**
   It printed `0.31.0` (the manifest `ModuleVersion`); the `Prerelease` label in
   `PrivateData.PSData.Prerelease` was never surfaced, so the report could not distinguish a beta from a
   hypothetical `0.31.0` stable — which is exactly what hid "tested the wrong build" three times during this
   cycle. beta4 adds a display-only label path (`Get-SpecrewInstalledVersionInfo`); the base version still
   feeds every semver comparison. On beta4, `specrew version` reports **`0.31.0-beta4`** directly.

## The gate (universal beta-before-stable mandate)

No stable promotion without first publishing the **`0.31.0-beta4`** beta, installing it on the required
surface (Linux; macOS manual is waived — see Validation surfaces), and confirming the **interactive**
`specrew start` opens a real host session (the beta2 bug above is exactly what a headless/file-presence
check would miss). This also validates the bundled Spec Kit 0.9.0 support (PR #1626).

**Validation surfaces:**

- **Linux — REQUIRED, DONE.** Maintainer-confirmed 2026-06-03: native `specrew start` opens an
  interactive Copilot session (the headline deliverable). See the Linux evidence table below.
- **macOS — manual on-host validation WAIVED by the maintainer 2026-06-03.** Rationale: the
  `validate-macos` CI lane covers the wrapper runtime (FR-002/003/004/008), the native command surface
  (`specrew version` / `start --help`), install.sh detection incl. the Homebrew branch, and the
  interactive-`start` **PTY TTY-survival** regression — all green on `macos-latest`. The residual
  *unvalidated* slice is a live no-`pwsh` Homebrew auto-install + a real-terminal session on actual Mac
  hardware; the maintainer accepts this with a **reactive-fix posture** (fix on a user bug report). The
  T021 manual proof + the macOS evidence table below are therefore **NOT required** for this iteration's
  closeout. (Decision owner: Alon Fliess.)

**Upstream gates (branch CI):** `validate-macos` (T020) + `feature140-*` Ubuntu jobs + the parity cascade
incl. the docs arm (T023) + the new interactive-`start` deferred-launch regression on the Ubuntu **and**
macOS lanes. **Caveat:** CI has no TTY, so the deferred-launch test proves the mechanism **engages**, not
that the TUI renders — the interactive proof is the on-host validation below.

## Publish (maintainer-driven; the Crew did NOT do this)

```text
0. PRECONDITION: maintainer explicitly authorizes the 0.31.0-beta4 beta publish. (Do not proceed without it.)
1. Tag the 140-unix-native-install HEAD `v0.31.0-beta4` and push it (-> publish-module.yml publish-prerelease),
   OR run the "Publish Specrew module" workflow via workflow_dispatch ON the 140 branch with
   release_mode=publish-prerelease, release_tag=v0.31.0-beta4.
   The workflow stamps the manifest from the tag and cross-checks .specrew/config.yml specrew_version (0.31.0).
2. Confirm 0.31.0-beta4 is live on the PowerShell Gallery.
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
     specrew version   -> MUST report 0.31.0-beta4 (beta4 fixes finding #2 — the label is surfaced directly).
     (Backup check: Get-Module Specrew -ListAvailable | Select Version,@{n='Pre';e={$_.PrivateData.PSData.Prerelease}}.)
C. INTERACTIVE start (the beta2 regression): specrew start  ->  an interactive host session MUST OPEN
   (not a one-shot run that prints a token summary and returns to the shell).
D. GREENFIELD: mkdir gf && cd gf && git init && specrew init && specrew start "build something small"
   -- specrew init MUST actually bootstrap/validate Spec Kit (0.9.0 exercised here -- the real deliverable,
      not just a version check)
E. BROWNFIELD: cd <an existing project> && specrew init && specrew start "..."
F. Record outputs in the matching surface table below.
```

Stable promotion is a SEPARATE, separately-authorized step AFTER **both** surfaces pass. Not part of this task.

## Evidence — Linux surface

**beta3 (2026-06-03 · host HOMEALON11 · Alon Fliess) — headline PROVEN.** `install.sh --prerelease` installed
beta3 (pwsh 7.6.1 already present, so the no-`pwsh` apt path was not exercised here — that is covered by the
clean-container CI job); 8 wrappers installed; native `specrew` works; **`specrew start` opened an interactive
Copilot session** (the beta2 headless exit is resolved). This proof carries to beta4 — the interactive-`start`
fix is byte-identical; beta4 only adds the `specrew version` label + a test change.

**beta4 (the to-be-stable build) — confirm on the published beta4:**

| Step | Expected | Actual | Pass? |
| --- | --- | --- | --- |
| Beta published (0.31.0-beta4) | Gallery link + GitHub release | `Find-Module … -RequiredVersion 0.31.0-beta4 -AllowPrerelease` → FOUND; release `v0.31.0-beta4` | ✅ |
| install.sh `--prerelease` (branch URL) | states PRERELEASE; wrapper surface present | maintainer-run 2026-06-03: installed beta4 (pwsh 7.6.1 present); 8 wrappers; native `specrew` works | ✅ |
| `specrew version` | reports **0.31.0-beta4** (finding #2 fixed — label surfaced directly) | reports **`0.31.0-beta4`** (finding #2 confirmed fixed — the label now disambiguates the build) | ✅ |
| Interactive `specrew start` | interactive Copilot session OPENS (re-confirm; proven on beta3) | maintainer-confirmed 2026-06-03: Copilot session opened (logo + `copilot --resume=<id>` shown — the interactive display, not the beta2 headless exit) | ✅ |
| Greenfield `init` / `start` *(optional)* | Spec Kit 0.9.0 bootstrap (`init` is also CI-covered on validate-ubuntu) | not run — optional; `specrew init` clean-dir bootstrap is CI-covered on validate-ubuntu | n/a |

**Linux host**: HOMEALON11 · **By**: Alon Fliess · **Date**: 2026-06-03
**Result**: beta4 (the to-be-stable build) PASSES on Linux — both the headline interactive `start` and the finding-#2 label fix confirmed. macOS manual waived (see Validation surfaces). Release gate satisfied for stable promotion.

## Evidence — macOS surface (WAIVED 2026-06-03 — CI-covered; manual on-host validation NOT required; see the waiver under "Validation surfaces" above)

| Step | Expected | Actual | Pass? |
| --- | --- | --- | --- |
| install.sh `--prerelease` (branch URL) | states PRERELEASE; pwsh ensured (Homebrew); mismatch check passes | (paste) | ☐ |
| Prerelease confirmed | `Get-Module … Prerelease` shows 0.31.0 / beta4 | (paste) | ☐ |
| **Interactive `specrew start`** | an interactive host session OPENS (not a headless one-shot) | (paste) | ☐ |
| Greenfield `init` / `start` | succeeds; Spec Kit 0.9.0 bootstrapped | (paste) | ☐ |
| Brownfield `init` / `start` | succeeds on existing content | (paste) | ☐ |

**macOS host**: (version) · **By**: (external tester) · **Date**: (YYYY-MM-DD)
Clean no-`pwsh` auto-install manual proof: see `macos-manual-proof.md` (T021).

## What the Crew did NOT do (by design)

- Did NOT tag, publish, or trigger the publish workflow — the maintainer authorizes/pushes the tag.
- Did NOT promote anything to stable.
- macOS manual on-host validation is **WAIVED** by maintainer decision 2026-06-03 (CI-covered; reactive-fix posture) — see the "Validation surfaces" waiver above. Linux is the validated manual surface.
- Built `install.sh --prerelease` (T019) + asserted its surface/mismatch predicate (unit-level); the live
  prerelease install against the published beta is proven HERE, per surface, once authorized.
- Could NOT prove the interactive TUI renders in CI (no TTY) — the deferred-launch regression test proves
  the mechanism engages; the interactive proof is the on-host validation above.

## Authorization

**Authorized by**: (name) · **Beta version**: 0.31.0-beta4 · **Date**: (YYYY-MM-DD)
