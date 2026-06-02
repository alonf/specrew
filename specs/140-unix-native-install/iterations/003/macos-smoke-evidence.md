# macOS Manual-Smoke Evidence — Iteration 3 Planning Input

**Feature**: 140-unix-native-install
**Iteration**: 003 (planning input — this is evidence, NOT the iteration plan/tasks)
**Date**: 2026-06-02
**Source**: macOS tester manual smoke on a real host, reported to the maintainer
**Status**: evidence captured. The FR / scope changes proposed in this file are **proposed only** and await
maintainer approval before they are folded into `spec.md` or an Iteration 3 `plan.md`.

## Why this matters (do not treat as solved by the Ubuntu work)

Iteration 2 proved the `install.sh` auto-install + wrapper runtime on **Ubuntu CI only** (a clean no-`pwsh`
container). This is **macOS** evidence on a real host, and it surfaces failure modes the Ubuntu lane cannot
exercise: the Homebrew/`nvm` Node environment, the PSGallery interactive trust prompt, and the manual
`Install-Module` path a macOS user reaches for first. It is Iteration 3 macOS evidence and is recorded here
as a planning input for the macOS / native-install slice.

## Tester environment

- OS: macOS
- Default shell: `zsh`
- PowerShell Core: 7.2.3
- Node: managed through `nvm`
- Homebrew: installed
- Project path used during testing: a `~/Desktop/...` working directory

## Observed sequence (chronological)

1. Followed the **manual module** install command from `zsh`:
   `Install-Module Specrew -Scope CurrentUser -SkipPublisherCheck` → `zsh: command not found: Install-Module`
   (and `command not found: specrew`). `Install-Module` only exists inside PowerShell.
2. Switched to PowerShell (`pwsh`) and re-ran. PSGallery prompted that the repository is **untrusted**; the
   default answer is **`N`**, so pressing **Enter** declined: `WARNING: User declined to install module (Specrew).`
3. Re-ran and chose **`A` / Yes to All** → the Specrew module installed.
4. Ran `specrew init` → failed dependency validation: `[macOS] Node.js v22.17.0 / required: 24.0+`,
   message `Update from https://nodejs.org/`.
5. Ran `brew update && brew install node && brew upgrade node`; Homebrew installed Node 26
   (`/usr/local/Cellar/node/26.0.0/bin/node`) **but `node -v` still showed `v22.17.0`**. Cause: `nvm`
   shadowed the Homebrew Node — `node (shadowed by ~/.nvm/versions/node/v22.17.0/bin/node)`, and PowerShell
   resolved that same `nvm` path.
6. Fixed Node via `nvm`: `nvm install 24` → `nvm use 24` → `nvm alias default 24`; `node -v` → `v24.16.0`.
   Confirmed inside `pwsh` that `node -v` reported `v24.16.0`.
7. Ran `specrew init` again → failed on Spec Kit: `Specrew requires Spec Kit >= 0.8.4 but found 0.0.22.`
   The diagnostic printed the exact remediation:
   `uv tool install specify-cli --from git+https://github.com/github/spec-kit.git@v0.8.4`. Tester ran it
   with `--force` → succeeded.
8. `specrew init` then succeeded.

### Tester's final working path (verbatim intent)

1. Start in `zsh`; ensure Node 24+ is active through `nvm` (`nvm install 24 && nvm use 24 && nvm alias default 24`).
2. Open PowerShell (`pwsh`).
3. Install Specrew (`Install-Module Specrew -Scope CurrentUser -SkipPublisherCheck`); if PSGallery prompts, choose `A` / Yes to All.
4. Upgrade Spec Kit (`uv tool install specify-cli --from git+https://github.com/github/spec-kit.git@v0.8.4 --force`).
5. Run `specrew init`.

## Analysis — which path the tester used vs. the feature's intended path

The single most important observation: **the tester did not use `install.sh`.** They followed the legacy
manual `Install-Module` path. Findings #1 and #2 are exactly the manual-path friction the `install.sh`
bootstrap exists to remove — which **validates** the feature's native-first thesis (US2 / FR-007 / FR-014):

- The current `install.sh` (`ensure_specrew_module`) already runs
  `Set-PSRepository -Name PSGallery -InstallationPolicy Trusted` and
  `Install-Module -Name Specrew -Scope CurrentUser -Force -AllowClobber` under `-NonInteractive`, and
  `fail_closed`s if the install fails. A user who runs `install.sh` therefore would **not** hit the
  "command not found in zsh" error (#1) nor the "default `N` declines the install" prompt (#2), and a
  declined/failed module install **already** fails closed rather than printing success.
- The gap is therefore **path-priority and documentation (FR-014)**, plus **proving `install.sh` on macOS**:
  the tester fell into the manual trap because the native `install.sh` path was not the one they followed.
  Iteration 2 only proved `install.sh` on Ubuntu; the macOS proof (manual, per the Iteration-2 plan) is
  Iteration 3 work.

Findings #4–#7 (Node version, `nvm` shadowing, Spec Kit version) are **`specrew init` dependency-validation**
concerns, not wrapper/`install.sh` concerns. They are adjacent to this feature's core scope but the
maintainer has explicitly scoped them into the Iteration 3 macOS slice. They need new or extended
requirements (see below) rather than being covered by any current FR.

## Mapping the six maintainer-stated Iteration-3 requirements to spec coverage

| # | Maintainer requirement | Current coverage | Gap / proposed action |
| - | ---------------------- | ---------------- | --------------------- |
| 1 | macOS users start from zsh/bash via `install.sh`/`curl \| sh`, not `Install-Module` as primary | FR-007 (entrypoint), FR-014 (native-first docs) | Mostly covered; **strengthen FR-014** so the README/getting-started macOS path leads with `install.sh` and the manual `Install-Module` path is demoted to a clearly-labelled fallback. Prove on macOS. |
| 2 | Installer output makes stable vs prerelease explicit; avoid PSGallery prompt confusion; non-interactive install fails closed on a declined/failed module install | FR-016 (fail-closed), FR-017 (stable-vs-prerelease output), and `install.sh` already sets PSGallery Trusted + `-Force -NonInteractive` + `fail_closed` | Largely **already implemented** for the `install.sh` path. Action: **verify on macOS** + add a docs note that the manual path can decline at the PSGallery prompt (use `install.sh` instead). Confirm FR-017's stable/prerelease wording is printed. |
| 3 | macOS dependency diagnostics must call out `nvm` shadowing Homebrew Node and tell users to verify `node -v` in the environment Specrew uses (`pwsh`) | **Not covered.** Current message is generic (`Update from https://nodejs.org/`). | **NEW requirement proposed (FR-018):** macOS Node diagnostics detect/mention `nvm`-vs-Homebrew shadowing and instruct verifying `node -v` inside `pwsh` (the runtime Specrew uses), not only in `zsh`. |
| 4 | macOS smoke must include an `nvm`-shadowing scenario or a documented manual proof | Partially — FR-012 macOS lane + SC-001/003/007 macOS halves are Iteration 3, but no `nvm` scenario | **Extend the macOS smoke plan** with an explicit `nvm`-shadows-Homebrew-Node scenario (manual proof acceptable per the Iteration-2 plan; macOS runners cannot give a clean controlled env). |
| 5 | Spec Kit old-version handling documented and validated; show the exact `uv tool install`/upgrade command, or perform the supported upgrade if in scope | The diagnostic **already** prints the exact `uv tool install ...@v0.8.4` command | **NEW/extended requirement proposed (FR-019 or FR-014/FR-015 extension):** document the old-Spec-Kit remediation in troubleshooting + validate it in the macOS smoke; decide whether to append `--force` to the suggested command; **reconcile** the `>= 0.8.4` minimum with the bundled Spec Kit 0.9.0 support this feature rides (see Open items). |
| 6 | Keep PowerShell an internal implementation detail for Unix users wherever possible | FR-014 (PowerShell as internal dependency, not a manual prerequisite) | Covered in principle; reinforced by #1/#2 (lead with `install.sh`; manual `pwsh`/`Install-Module` is fallback only). |

## Proposed Iteration-3 scope additions (await maintainer approval)

These shape `spec.md` and the Iteration 3 `plan.md`. They are **not** applied yet:

- **FR-014 (extend):** macOS docs lead with `install.sh` / `curl | sh`; the manual `Install-Module` path is
  demoted to a labelled fallback with a one-line note that the PSGallery prompt defaults to `N`.
- **FR-018 (new):** macOS dependency diagnostics for Node MUST call out `nvm`-vs-Homebrew shadowing and
  instruct the user to verify `node -v` inside the environment Specrew runs in (`pwsh`), not only the login
  shell. (This is a `specrew init` / preflight diagnostic change — adjacent to the core wrapper/install
  scope; confirm the maintainer wants it inside this feature vs. a separate `specrew init` slice.)
- **FR-019 (new) or FR-014/FR-015 extension:** Spec Kit old-version handling MUST be documented in
  troubleshooting and validated in the macOS smoke, surfacing the exact `uv tool install ... --from git+...@<ver> --force`
  remediation, and the `0.8.4`-minimum vs `0.9.0`-bundled messaging MUST be reconciled.
- **macOS smoke scenarios (FR-012 macOS lane / SC-001/003/007 macOS halves):** add the `nvm`-shadowing
  scenario and an `install.sh`-as-primary-path scenario as **documented manual proofs**.

## macOS smoke scenarios for Iteration 3 (manual proof per the Iteration-2 plan)

1. **`install.sh` primary path on macOS:** from `zsh`, run the bootstrap (or `curl … | sh`); confirm it
   ensures `pwsh` (Homebrew), installs Specrew without a PSGallery decline, installs wrappers, and
   `specrew version` works — no manual `Install-Module`.
2. **`nvm`-shadowing Node:** with `nvm` active and an old default Node, confirm `specrew init` diagnostics
   detect/explain the shadowing and that the documented fix (`nvm install 24 && nvm use 24 && nvm alias default 24`,
   then verify in `pwsh`) resolves it.
3. **Old Spec Kit:** with an old `specify-cli`, confirm the diagnostic prints the exact `uv tool install …`
   remediation and that running it (with `--force`) unblocks `specrew init`.
4. **Stable vs prerelease output (FR-017):** `install.sh` and `install.sh --prerelease` each state which
   channel they are installing; the prerelease path is proven at the release gate once a beta is published.

## CI-proven vs manual (honesty note)

Per the Iteration-2 plan, macOS auto-install (Homebrew) + interactive `sudo` + the `nvm`/Homebrew Node
environment **cannot** be given a clean controlled state on hosted macOS runners, so these scenarios are
**manual proofs** budgeted for Iteration 3 — they are NOT discharged by the Ubuntu CI evidence. Git Bash on
Windows is never the runtime verdict.

## Open reconciliation items

- **Spec Kit version messaging:** the dependency minimum is `>= 0.8.4` (`scripts/init/preflight.ps1`,
  `scripts/specrew-init.ps1`) while this feature rides the bundled Spec Kit **0.9.0** support
  (`scripts/internal/supported-versions.yml`; PR #1626). The remediation the tester saw pinned `@v0.8.4`.
  Decide whether the suggested upgrade should target a newer pinned version and whether to append `--force`.
- **Scope boundary for FR-018:** Node/`nvm` diagnostics live in `specrew init` preflight, not in the
  wrapper/`install.sh` surface. Confirm whether this belongs inside feature 140 (Iteration 3) or a separate
  `specrew init` dependency-diagnostics slice.
