# macOS Manual-Proof Evidence — Iteration 3 (T021)

**Feature**: 140-unix-native-install
**Iteration**: 003
**Task**: T021 (FR-007, FR-016 macOS; SC-007 macOS)
**Status**: ⏳ **PENDING — requires a real macOS host.** Not executable by the automated Crew (authoring
host is Windows; macOS CI runners cannot provide a clean *no-`pwsh`* environment). A maintainer (or a
macOS contributor) runs the steps below on a real Mac and pastes the outputs into the Evidence section.

## Why this is manual (CI-vs-manual split)

Per the Iteration-3 hardening gate, the macOS surface splits as:

- **CI-proven (T020, `validate-macos`)**: the wrapper runtime suite (forwarding / symlink / pwsh-missing /
  passthrough) + a real `install-shell-wrappers` → `specrew version` / `start --help`. macOS runners have
  `pwsh` pre-installed, so the *wrapper* surface is genuinely CI-proven.
- **MANUAL (this artifact, T021)**: the clean `install.sh` Homebrew `pwsh` auto-install (a Mac *without*
  PowerShell), the surfaced/interactive nature of Homebrew, idempotent re-run, and the end-to-end
  `specrew init` / `start` on a real Mac. macOS runners ship `pwsh`, so the clean auto-install path is not
  CI-reachable — it must be proven by hand.

Git Bash on Windows is a development proxy, never the macOS verdict.

## Preconditions

- A Mac (Apple Silicon or Intel) where you can either temporarily remove PowerShell or use a fresh user.
- Homebrew installed (`brew --version`). Internet access (Homebrew + PowerShell Gallery).
- For the prerelease/release-gate variant, a published beta must exist — that is **T024**, not this task.

## Procedure (run on the Mac, zsh/bash)

```sh
# 0. Capture the environment
sw_vers ; uname -m ; brew --version ; (command -v pwsh && pwsh --version) || echo "pwsh: absent (good — clean path)"

# 1. (Optional, for the truly-clean path) ensure pwsh is absent
#    brew uninstall --cask powershell   # only if you want to prove the auto-install from scratch

# 2. --check first: detection + supported report (no changes, no elevation)
sh ./install.sh --check
#    Expect: "supported: macOS <version> (Homebrew 'brew install --cask powershell' path)."
#    With Homebrew absent, expect a fail-closed "Homebrew ... not found" message instead.

# 3. Full install via the native entrypoint (no pwsh, no Install-Module typed by you)
sh ./install.sh --bin-dir "$HOME/.local/bin"
#    Expect: brew installs PowerShell (as YOU, never sudo) -> module installs -> wrappers install.

# 4. Native command surface
export PATH="$HOME/.local/bin:$PATH"
command -v specrew
specrew version
specrew start --help

# 5. Idempotent re-run (must skip the already-present pwsh, no duplicate work, exit 0)
sh ./install.sh --bin-dir "$HOME/.local/bin"

# 6. Greenfield lifecycle smoke (uses specrew init — see Node/Spec Kit prerequisites below)
mkdir -p ~/specrew-macos-smoke && cd ~/specrew-macos-smoke && git init
specrew init
specrew version
```

### Prerequisites surfaced during step 6 (documented per FR-018/FR-019 carve-out)

These are documented in `docs/troubleshooting.md` (the diagnostic *implementation* is the separate
`specrew init` slice — FR-018/FR-019 — not feature 140):

- **Node / `nvm` shadowing**: if `specrew init` reports Node too old after a `brew` upgrade, `nvm` is
  shadowing Homebrew Node. Verify `pwsh -NoProfile -Command "node -v"` (the runtime Specrew uses), then
  `nvm install 24 && nvm use 24 && nvm alias default 24`.
- **Spec Kit too old**: run the exact `uv tool install specify-cli --from git+…@v<floor> --force` command
  `specrew init` prints (`<floor>` from `scripts/internal/supported-versions.yml` `speckit.min`).

## Evidence (fill in on the Mac; commit with outputs)

| Check | Expected | Actual | Pass? |
| --- | --- | --- | --- |
| Environment | macOS version / arch / brew / pwsh state recorded | (paste) | ☐ |
| `--check` (Homebrew present) | exit 0, "supported: macOS …" | (paste) | ☐ |
| `--check` (Homebrew absent) | exit 1, "Homebrew … not found" | (paste) | ☐ |
| Clean auto-install (no pwsh → installed) | `brew install --cask powershell` runs as user, no `sudo`; exit 0 | (paste) | ☐ |
| `specrew version` via wrapper | prints version, exit 0 | (paste) | ☐ |
| `specrew start --help` | help renders, exit 0 | (paste) | ☐ |
| Idempotent re-run | "pwsh already present; skipping", no duplicate, exit 0 | (paste) | ☐ |
| `specrew init` (greenfield) | succeeds after prerequisites | (paste) | ☐ |

**Recorded by**: (name) · **Date**: (YYYY-MM-DD) · **Host**: (macOS version / arch)

> Until this section is filled with real outputs from a Mac, T021 is **not** discharged and SC-007 (macOS)
> remains unproven. Do not mark Iteration 3 review-signoff complete on the strength of CI alone — CI proves
> the wrapper surface (T020); this proves the clean auto-install + lifecycle on real macOS.
