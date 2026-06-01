---
proposal: 156
title: Native Bootstrap Installer UX (Bash/macOS/Linux + PowerShell Wrapper over PSGallery)
status: candidate
phase: phase-2
estimated-sp: 6-10
priority-tier: 1
discussion: surfaced 2026-06-01 during v0.30.0-beta6 release-readiness discussion; maintainer asked to hide PowerShell ceremony from bash/macOS/Linux users by providing native bootstrap entry points that use PowerShell internally to install Specrew from PSGallery
---

# Native Bootstrap Installer UX (Bash/macOS/Linux + PowerShell Wrapper over PSGallery)

## Why

Specrew's current distribution answer is technically correct but audience-mismatched for non-PowerShell users:

```powershell
Install-Module Specrew -Scope CurrentUser
```

That is the right canonical package source for Specrew because Proposal 031 established PSGallery as the distribution channel and Proposal 060 establishes prerelease discipline there. But for macOS/Linux/bash users, exposing PowerShell syntax as the first install instruction creates avoidable friction. The user wants to install a tool, not first understand `Install-Module`, `-Scope CurrentUser`, `-AllowPrerelease`, execution policy implications, and module paths.

The product problem is not "replace PSGallery." The product problem is "make PSGallery feel native from the user's shell."

This proposal adds a thin native bootstrap UX:

- bash/zsh users run a shell-native installer command.
- Windows users can still use a PowerShell-native installer command.
- The bootstrap delegates to PowerShell internally and installs Specrew from PSGallery.
- PSGallery remains the source of truth for stable and prerelease packages.

This is adoption UX, not a packaging-system fork.

## What

Ship native bootstrap entry points that hide PowerShell ceremony while preserving the PSGallery install path.

### Pillar 1: Bash/zsh bootstrap

Add an `install.sh` bootstrap for macOS/Linux users. Expected UX:

```bash
curl -fsSL https://<specrew-install-url>/install.sh | bash
```

Supported flags:

```bash
./install.sh --channel stable
./install.sh --channel prerelease
./install.sh --version 0.30.0
./install.sh --version 0.30.0-beta.6 --prerelease
./install.sh --yes
./install.sh --dry-run
```

Core behavior:

1. Detect OS and shell context.
2. Detect `pwsh`.
3. If `pwsh` exists, call PowerShell internally to install Specrew from PSGallery.
4. If `pwsh` is missing, print clear platform-specific guidance and stop, unless an explicit future opt-in supports installing PowerShell.
5. Run `specrew version` after install and print the resolved installed version.
6. Keep the generated command visible enough for troubleshooting without making PowerShell the main user-facing path.

The bash bootstrap must not silently install PowerShell by default. That is a separate trust decision.

### Pillar 2: PowerShell bootstrap wrapper

Add an `install.ps1` convenience wrapper for Windows and PowerShell-first users:

```powershell
irm https://<specrew-install-url>/install.ps1 | iex
```

The wrapper should accept the same conceptual options as `install.sh`: stable/prerelease channel, exact version, current-user scope, dry-run, and non-interactive confirmation. It remains a wrapper over `Install-Module Specrew`, not a second installer implementation.

### Pillar 3: Shared install command builder

Avoid drift between `install.sh`, `install.ps1`, docs, and tests by centralizing the PSGallery command shape as much as practical.

Minimum command cases:

| User intent | PowerShell command shape |
|---|---|
| Latest stable | `Install-Module Specrew -Scope CurrentUser -Force` |
| Latest prerelease | `Install-Module Specrew -Scope CurrentUser -Force -AllowPrerelease` |
| Pinned stable | `Install-Module Specrew -Scope CurrentUser -Force -RequiredVersion <version>` |
| Pinned prerelease | `Install-Module Specrew -Scope CurrentUser -Force -RequiredVersion <version> -AllowPrerelease` |

Exact internal factoring is an implementation decision, but tests should pin these command shapes so the wrappers do not diverge.

### Pillar 4: Documentation and release surface

Update the install docs so non-PowerShell users see the shell-native bootstrap first, while PowerShell users still see the canonical PSGallery command.

Documentation surfaces:

- `README.md` install section
- `docs/getting-started.md`
- release notes install/upgrade snippet
- prerelease instructions from Proposal 060

The docs must explicitly state:

- PSGallery remains the canonical package source.
- The bash installer requires PowerShell 7+ (`pwsh`) to be present in v1.
- The bootstrap does not silently install PowerShell.
- The wrapper is safe to inspect and can be downloaded before execution.

### Pillar 5: Tests and validation

Add deterministic tests that do not depend on PSGallery network availability in normal CI.

Required coverage:

- `install.sh --dry-run` emits the expected `pwsh` command for stable, prerelease, pinned stable, and pinned prerelease cases.
- Missing `pwsh` path produces a clear error with install guidance and no partial install.
- `install.ps1` command builder covers the same cases.
- README/getting-started snippets stay in sync with supported flags.
- Release-validation checklist includes one clean bash-path smoke test when publishing a beta/stable package.

Networked PSGallery smoke tests remain release-gate/manual or explicitly opted-in CI, not default unit tests.

## Parallel implementation fit

This is a good parallel-track feature because its primary surfaces are install wrappers, docs, and release-validation snippets. It is largely unrelated to reviewer/runtime features.

Recommended parallel bundle:

- **Proposal 156: Native Bootstrap Installer UX** — install/docs/release packaging surface.
- **Proposal 140 or 145: Reviewer Instruction / Structured Reviewer Surface** — reviewer methodology and validation surface.

This pair minimizes merge contention:

- Proposal 156 touches installer scripts, README/getting-started/release notes, and focused installer tests.
- Proposal 140/145 touches reviewer templates, validator/review artifacts, and methodology files.

Avoid pairing Proposal 156 with broad release-pipeline rewrites or PSGallery publishing internals unless needed, because those share release surfaces and increase coordination cost.

## Relationship to Proposal 153

Proposal 153 is about Unix-native wrapper commands for normal Specrew CLI usage after Specrew is already installed. This proposal is narrower and earlier in the adoption funnel: it makes the installation entry point shell-native while still delegating to PSGallery.

The two should compose cleanly:

- Proposal 156 gets the user from "no Specrew" to "Specrew installed from PSGallery."
- Proposal 153 gets the installed user from "PowerShell command surface" to "normal Unix command surface."

They can ship independently, but the best end-state is one native-feeling Unix path from install through day-to-day usage.

## Out of scope

- Replacing PSGallery as Specrew's package source.
- Publishing to Homebrew, winget, Chocolatey, Scoop, apt, rpm, or npm.
- Silently installing PowerShell by default from the bash bootstrap.
- Changing Specrew's implementation language away from PowerShell.
- Reworking the module manifest, release workflow, or prerelease policy beyond the installer-facing snippets needed for this UX.
- Solving corporate proxy and private gallery configuration in v1.

## Effort

Single feature, likely one iteration.

| Work | SP estimate |
|---|---|
| Bash bootstrap (`install.sh`) with dry-run, channel/version flags, `pwsh` detection | 2-3 |
| PowerShell bootstrap (`install.ps1`) with equivalent flags | 1-2 |
| Shared command-shape tests and missing-`pwsh` behavior tests | 1-2 |
| README/getting-started/release-note install updates | 1 |
| Release-validation checklist update | 1 |
| Cross-platform smoke pass on Windows + Linux/macOS shell where available | 1 |

**Total: ~6-10 SP.**

## Phase placement

**Phase 2** — distribution and onboarding hardening.

This extends the shipped Specrew Distribution Module (Proposal 031) by improving first-run ergonomics without changing the package source. It also composes with the PSGallery prerelease discipline (Proposal 060) because the bootstrap must support stable and prerelease channels cleanly.

## Open questions

1. **Hosting URL**: where should `install.sh` and `install.ps1` live for public `curl` / `irm` usage: GitHub raw, GitHub Releases asset, docs site, or a short stable redirect?
2. **PowerShell missing behavior**: v1 recommendation is guidance-only. Should a later opt-in flag (`--install-pwsh`) install PowerShell through platform package managers?
3. **Shim behavior**: does the bootstrap need to add a shell shim or PATH hint for `specrew`, or is module install enough on all supported platforms?
4. **Prerelease default**: should `--channel prerelease` install the latest prerelease, or require `--version` for betas during the current release discipline?
5. **Script signing/checksum story**: for public docs, do we publish checksums or signed installer artifacts, or rely on HTTPS + visible script source for v1?

## Risks

- **Trust concerns around `curl | bash`**: common UX, but security-sensitive. Mitigation: document inspect-first commands and publish stable script URLs/checksums when available.
- **PowerShell still required**: this hides ceremony, not the dependency. Mitigation: make the missing-`pwsh` message excellent and defer automatic installation to explicit opt-in.
- **Shell quoting drift**: bash flags and PowerShell arguments can diverge. Mitigation: dry-run tests pin exact generated command shapes.
- **Docs overclaim native install**: the bootstrap is native shell UX, not a native package manager. Mitigation: docs state PSGallery remains canonical and PowerShell is used internally.
- **Release-surface collisions**: installer docs touch release notes and getting-started docs. Mitigation: run this in parallel with reviewer/runtime work, not with broad release-pipeline changes.

## Cross-references

- [031](031-specrew-distribution-module.md) — shipped PSGallery distribution foundation.
- [060](060-prerelease-channel-staging.md) — prerelease channel discipline; installer must support stable/prerelease selection.
- [153](153-unix-native-wrapper-commands.md) — sibling native Unix command-surface proposal for post-install usage.
- [058](058-plugin-based-multi-host-distribution.md) — broader future distribution/plugin packaging; this proposal is narrower and does not wait for 058.
- [125](125-vscode-companions-and-default-md-preview.md) — onboarding-adjacent docs surface.
- [140](140-reviewer-instruction-surface.md) and [145](145-structured-multi-phase-reviewer.md) — recommended unrelated parallel implementation candidates.

## Status history

- 2026-06-01: candidate drafted from maintainer direction after v0.30.0-beta6 release-readiness discussion. Key decision: hide PowerShell ceremony from bash/macOS/Linux users with native bootstrap wrappers while preserving PSGallery as the canonical package source. Marked as a parallel-track candidate for the next release because it is mostly installer/docs/release-packaging work and can run alongside reviewer/runtime features with low merge contention.
