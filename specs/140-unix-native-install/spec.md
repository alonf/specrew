# Feature Specification: Unix-Native Install & Command Surface

**Feature Branch**: `140-unix-native-install`
**Created**: 2026-06-02
**Status**: Draft
**Proposal**: 153 (Unix-Native Wrapper Commands for Specrew CLI)
**Input**: Make macOS/Linux usage feel native. Ship POSIX shell wrapper commands + a bootstrap installer so normal users run `specrew` from their shell without typing `pwsh`. PowerShell Core may remain the internal runtime/implementation dependency, but routine Specrew usage on Unix must not require invoking PowerShell directly.

## Clarifications

### Session 2026-06-02

- Q: How should the `bin/` wrappers stay in sync with the command registry? → A: **Generate-then-commit (hybrid)** — a generator is the single source of truth; the generated wrapper files are committed (so they ship in `FileList` and are reviewable), and CI regenerates + diffs to catch drift.
- Q: How should the Unix bootstrap (`install.sh`) be delivered, and how is the module-before-wrappers ordering resolved? → A: **Repo-committed `install.sh` runnable via `curl … | sh`** — it verifies `pwsh`, installs the module via `Install-Module Specrew` through pwsh, then invokes `install-shell-wrappers` (module first, wrappers second). *(Superseded 2026-06-02 on the `pwsh` step — `install.sh` now auto-installs PowerShell Core as a dependency rather than only verifying it; see the auto-install clarification below. The `curl … | sh` delivery + module-first ordering still stand.)*
- Q: Default behavior when `install-shell-wrappers` targets a missing bin dir or one not on `PATH`? → A: **Require `-Force` to create a missing bin dir (never silent); warn-only when not on `PATH`** (clear hint, no shell-profile mutation).
- Q: When `pwsh` is missing on a Unix host, must the user install PowerShell manually, or should `install.sh` provision it? → A: **`install.sh` auto-installs PowerShell Core as a dependency (supersedes the earlier verify-and-hint answer).** `install.sh` is the user-facing entrypoint; when `pwsh` is absent it MUST attempt to install PowerShell Core via the native platform / package-manager flow (prompting for `sudo` / package-manager confirmation as the OS requires), then use `pwsh` internally to install Specrew from PSGallery and run `install-shell-wrappers`. An unsupported platform/package manager, or a failed auto-install → fail with a clear message + a link to manual dependency-install docs. PowerShell Core is thereby an INTERNAL dependency, not a manual prerequisite (except on unsupported platforms or after a failed auto-install). The thin **wrappers** are unchanged — they only verify `pwsh` and error (FR-004); auto-install belongs to the bootstrap. **Security note:** this enlarges `install.sh`'s trust surface (package-manager invocation + privilege elevation + the provenance of the PowerShell source), so Iteration 2's security lens MUST review it (FR-016).
- Q: Can `install.sh` install Specrew **prerelease** (beta) versions, for the beta-before-stable Unix validation? → A: **Yes — `install.sh` MUST support `--prerelease` (FR-017).** `curl … | sh -s -- --prerelease` (and `bash ./install.sh --prerelease`) installs Specrew from PSGallery with prerelease support (`Install-Module -AllowPrerelease` / the PSResourceGet `-Prerelease` equivalent for this module). The `--help` text documents the flag; the output states stable vs prerelease; a version/source mismatch (the installed module lacks the native `specrew` wrapper command) fails closed. **Placement: Iteration 3** — its correctness (does `-AllowPrerelease` actually fetch + install the *published* beta, and does the installed beta expose the wrapper command) can only be proven once a beta is published, which is the Iteration-3 release-gate moment; building it in Iteration 2 (no published beta) would be build-without-proof. The beta-before-stable validation flow (FR-015 / SC-006) MUST use this prerelease flow. **Not optional** — it is required for the Unix beta-before-stable release-validation path.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Native command surface on macOS/Linux (Priority: P1)

A macOS or Linux developer with Specrew + PowerShell Core installed drives Specrew entirely through normal shell commands — `specrew version`, `specrew init`, `specrew start --host codex`, `specrew where`, `specrew update` — without ever typing `pwsh -File ...`. The wrappers forward to the existing PowerShell implementation invisibly.

**Why this priority**: This is the headline adoption value — removing the PowerShell command surface from routine Unix usage. It is the reason the feature exists; everything else enables or protects it.

**Independent Test**: With wrappers present on `PATH` and `pwsh` installed, run `specrew version` and `specrew start --help`; verify they behave identically to the PowerShell module commands and that no PowerShell syntax is required.

**Acceptance Scenarios**:

1. **Given** Specrew + `pwsh` installed and wrappers on `PATH` on Ubuntu, **When** the user runs `specrew version`, **Then** it prints the same version as the module command and exits 0.
2. **Given** the same setup on macOS, **When** the user runs `specrew start --help`, **Then** help renders and exits 0.
3. **Given** a wrapper invoked via a symlink from a user bin directory, **When** it runs, **Then** it resolves the real module root and works.
4. **Given** an argument containing spaces/quotes (e.g. a project path `My Project`), **When** passed to a wrapper, **Then** it reaches the PowerShell command unchanged.
5. **Given** `pwsh` is not on `PATH`, **When** a wrapper runs, **Then** it exits non-zero with a clear "PowerShell Core (pwsh) is required" message plus an install hint.

---

### User Story 2 - One-step wrapper install + bootstrap (Priority: P1)

A new macOS/Linux user gets Specrew's native commands onto their `PATH` through a shell-native step: either `specrew install-shell-wrappers` when the module is already installed, or the `install.sh` bootstrap that — on a supported platform without PowerShell Core — first auto-installs `pwsh` as a dependency via the native package manager, then installs Specrew from PSGallery via `pwsh` internally and installs the wrappers — all presented as a normal bash/zsh flow with no manual PowerShell step.

**Why this priority**: The wrappers from US1 deliver value only if users can actually get them onto `PATH` without PowerShell ceremony.

**Independent Test**: In a clean Unix environment, run the installer into a temp bin directory (or run the bootstrap), prepend it to `PATH`, and run `specrew version` successfully.

**Acceptance Scenarios**:

1. **Given** the module installed, **When** the user runs `specrew install-shell-wrappers -BinDir <dir>`, **Then** the expected wrapper files appear in `<dir>` and nothing outside `<dir>` is modified.
2. **Given** the installer is run a second time, **When** it runs, **Then** it is idempotent (no duplication, no error) with explicit overwrite behavior.
3. **Given** `-WhatIf` / dry-run, **When** the installer runs, **Then** it reports what it would do and changes nothing.
4. **Given** the chosen bin directory is not on `PATH`, **When** the installer finishes, **Then** it warns clearly and prints the exact commands installed plus a `PATH` hint.
5. **Given** a clean Unix host with `pwsh`, **When** the user runs the bootstrap, **Then** Specrew installs from PSGallery and wrappers are installed, and `specrew version` works.
6. **Given** a clean Unix host on a **supported** platform **without** `pwsh`, **When** the user runs `install.sh`, **Then** it installs PowerShell Core via the native package manager (prompting for `sudo`/confirmation as the OS requires), installs Specrew, installs wrappers, and `specrew version` works — with no manual PowerShell install by the user.
7. **Given** an **unsupported** platform/package manager or a failed `pwsh` auto-install, **When** `install.sh` runs, **Then** it exits non-zero with a clear message and a link to manual dependency-install docs, and does not present a partial/half-installed state as success.

---

### User Story 3 - Command-registry parity (Priority: P2)

A Specrew maintainer adds, removes, or renames an exported command alias. The wrapper set, package `FileList`, and documentation examples stay coherent because they are generated from — or parity-validated against — the canonical command registry, and CI fails on divergence while naming the dependency cascade.

**Why this priority**: Prevents silent drift where a new command ships without a Unix wrapper, or a removed alias leaves a stale wrapper/docs reference. This is Proposal 153's core dependency-cascade discipline.

**Independent Test**: Add a dummy exported alias without a matching wrapper; assert the parity check fails and names the cascade (registry → wrappers → installer → FileList → docs).

**Acceptance Scenarios**:

1. **Given** a new exported alias without a matching wrapper, **When** parity tests run, **Then** they fail and identify the missing wrapper.
2. **Given** a removed or renamed alias, **When** parity + docs checks run, **Then** they flag stale wrapper/docs references.
3. **Given** the `specrew` wrapper, **When** passed an unknown future option, **Then** the wrapper forwards it unchanged and does not reject it.

---

### User Story 4 - Honest, native-first documentation (Priority: P3)

A macOS/Linux user reading the README, getting-started, and user-guide sees native shell commands first, with honest wording that PowerShell Core is required internally and that module commands remain a fallback.

**Why this priority**: First impression and honest expectations; lowest risk, high adoption polish, depends on US1/US2 existing.

**Independent Test**: Review the docs; confirm macOS/Linux examples lead with `specrew ...` rather than `pwsh -File ...`, and that the "PowerShell Core required internally" note + module-command fallback are present.

**Acceptance Scenarios**:

1. **Given** the README macOS/Linux section, **When** read, **Then** the primary path is native `specrew` commands.
2. **Given** the docs, **When** checked, **Then** they state PowerShell Core is required internally and that module commands remain a fallback.

---

### Edge Cases

- `pwsh` missing or not on `PATH` at **wrapper** runtime → clear non-zero error + install hint; the wrapper does NOT install pwsh (auto-install is `install.sh`'s job — FR-004 vs FR-007).
- `install.sh` on a **supported** platform without `pwsh` → auto-install PowerShell Core via the native package manager (may prompt for `sudo`/package-manager confirmation), then continue with module + wrapper install.
- `install.sh` on an **unsupported** platform/package manager, or pwsh auto-install fails → clear failure message + link to manual dependency-install docs; no silent or partial install presented as success.
- Wrapper invoked through a single or chained symlink from various bin directories → resolves the real module root.
- Arguments with spaces, quotes, glob characters, `--` passthrough, and empty strings → forwarded byte-for-byte to the PowerShell command.
- Requested bin directory does not exist → explicit create behavior (require `-Force`), never a silent `mkdir` outside the request.
- Bin directory not on `PATH` → warn, do not fail.
- Stale wrappers after a module update point to an old module path → symlink strategy or an update-time reminder/regeneration (resolution finalized at plan).
- `install-shell-wrappers` invoked on Windows → explain it is Unix-focused and no-op unless explicitly requested; Windows command surface unchanged.
- PSGallery/NuGet packaging drops or garbles wrapper files or symlink metadata → packaging parity test catches it; prefer real files over symlinks if symlink metadata proves unreliable.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Specrew MUST include POSIX-compatible wrapper scripts for the root `specrew` command and each exported alias in the canonical command registry (`specrew-init`, `specrew-start`, `specrew-update`, `specrew-version`, `specrew-review`, `specrew-team`, `specrew-where`).
- **FR-002**: Wrappers MUST preserve argument forwarding exactly, including quoted values, paths with spaces, glob characters, empty strings, and host-native passthrough flags.
- **FR-003**: Wrappers MUST resolve their installed module root robustly, including when invoked through a symlink from `~/.local/bin`, `/usr/local/bin`, or another user-selected bin directory, using only POSIX `sh` constructs (no Bash-only or GNU-only behavior).
- **FR-004**: Wrappers MUST fail with a clear, non-zero error when `pwsh` is not installed or not on `PATH`, including a short install hint and a reference to Specrew installation docs. Wrappers MUST NOT attempt to install PowerShell.
- **FR-005**: Specrew MUST provide a `specrew install-shell-wrappers` command that installs or refreshes the Unix wrappers into a user-visible bin directory, defaulting to `$HOME/.local/bin` on macOS/Linux.
- **FR-006**: Wrapper installation MUST be idempotent and safe: dry-run / `-WhatIf` support, explicit overwrite behavior, and no mutation outside the requested bin directory. When the bin directory does not exist, installation MUST require `-Force` (never silently create it). When the bin directory is not on `PATH`, the installer MUST warn clearly with a hint and MUST NOT modify shell profiles. *(Clarified 2026-06-02.)*
- **FR-007**: Specrew MUST provide a repo-committed Unix bootstrap script (`install.sh`) runnable via a shell-native flow (e.g. `curl … | sh`) that is the **user-facing entrypoint** for Unix install. When `pwsh` is absent, `install.sh` MUST attempt to install PowerShell Core **as a dependency** using the native platform / package-manager flow (it MAY prompt for `sudo` or package-manager confirmation as the OS requires — see FR-016 for the safety constraints). Once `pwsh` is available, `install.sh` MUST use it internally to install/update Specrew from PSGallery (`Install-Module Specrew`; **stable by default, or a prerelease via `--prerelease` — FR-017**) and then invoke `install-shell-wrappers` (module first, wrappers second — resolving the bootstrap-before-wrappers dependency). On an unsupported platform/package manager, or if the dependency auto-install fails, `install.sh` MUST fail with a clear message and a link to manual dependency-install docs. PowerShell Core is thereby an internal dependency, NOT a manual prerequisite — except on unsupported platforms or after a failed auto-install. *(Clarified 2026-06-02; auto-install supersedes the earlier verify-only behavior.)*
- **FR-008**: Wrappers MUST be thin forwarders. They MUST NOT duplicate option parsing or subcommand semantics; a wrapper MAY determine the subcommand implied by its alias name, but every user-provided argument MUST be forwarded unchanged to the PowerShell command surface.
- **FR-009**: Wrappers MUST be produced by a generator that is the single source of truth, driven by the canonical Specrew command registry (v1 = `Specrew.psd1` `AliasesToExport` plus the root `specrew`; v2 = Proposal 150's `.specrew/agent-command-manifest.json` when available). The generated wrapper files MUST be committed (so they ship in `FileList` and are reviewable), and CI MUST regenerate and diff to detect drift (generate-then-commit). *(Clarified 2026-06-02.)*
- **FR-010**: Package publishing MUST include the wrapper scripts and the bootstrap file in `Specrew.psd1` `FileList`, and packaging MUST verify they are present in the published module artifact.
- **FR-011**: A command-surface change touching `Specrew.psd1`, `scripts/specrew.ps1`, `scripts/specrew-*.ps1`, or the future command-manifest generator MUST trigger wrapper / `FileList` / docs parity checks in CI, and CI output MUST name the dependency cascade on failure (registry → wrappers → installer → FileList → docs).
- **FR-012**: CI MUST validate wrapper runtime behavior on both Ubuntu and macOS — these are the authoritative verification surfaces for all Unix-runtime requirements (FR-001 through FR-008).
- **FR-013**: Windows behavior MUST remain unchanged except for documentation explaining the platform-specific command surfaces; `install-shell-wrappers` on Windows MUST be an explained no-op unless explicitly requested.
- **FR-014**: Documentation for macOS/Linux (`README.md`, `docs/getting-started.md`, `docs/user-guide.md`, `docs/troubleshooting.md`) MUST present native bash/zsh commands first — install via `install.sh`, then native `specrew …` usage — NOT `pwsh -File …`. PowerShell Core MAY be mentioned as an internal dependency but MUST NOT be presented as a manual prerequisite, except for unsupported platforms or a failed auto-install (where the manual dependency-install docs apply). Module / `pwsh -File` commands remain a documented fallback. Doc command examples MUST be parity-checked against the canonical registry where practical, or allowlisted with rationale.
- **FR-015**: The feature's release MUST be gated by validating an installed Specrew (prerelease) on a real Unix host across BOTH a greenfield and a brownfield project — which also validates the bundled, currently-unreleased Spec Kit 0.9.0 support (merged via PR #1626, commit `ca897ee6`). The Unix beta-before-stable validation MUST install the prerelease via the shell-native flow (`curl … | sh -s -- --prerelease`, FR-017) and then exercise `specrew version` / `specrew init` / `specrew start` as appropriate. No beta or stable publication MUST occur without explicit maintainer authorization.
- **FR-016**: When `install.sh` auto-installs the PowerShell Core dependency (FR-007), it MUST do so safely and transparently: detect the platform / package manager before acting; use only the platform-standard or vendor-recommended PowerShell source (the distribution package, Microsoft's official repository, or Homebrew on macOS) — never an ad-hoc `curl | sh` of an untrusted script; surface (not hide) any privilege escalation by going through the normal `sudo` / package-manager confirmation prompt rather than silently elevating; and on an unsupported platform/manager or a failed install, fail closed with a clear message + a link to manual dependency-install docs (no partial install reported as success). *(Security surface introduced by the 2026-06-02 auto-install clarification; Iteration 2's security lens MUST review it.)*
- **FR-017**: `install.sh` MUST support a `--prerelease` flag (`curl … | sh -s -- --prerelease` and `bash ./install.sh --prerelease`) that installs Specrew from the PowerShell Gallery **with prerelease support** (the `Install-Module -AllowPrerelease` / PSResourceGet `-Prerelease` equivalent for this module). The `--help` text MUST document the flag; the installer output MUST state whether it is installing a **stable** or a **prerelease** version. If the installed module does not expose the native `specrew` wrapper command surface (a version/source mismatch — e.g. a version predating the wrappers), `install.sh` MUST fail closed (non-zero) and explain that the installed version is not compatible. Required for the Unix beta-before-stable validation path (FR-015 / SC-006). *(Added 2026-06-02; Iteration 3 — built AND proven once a beta is published, since the prerelease install + the mismatch check can only be exercised against a real published beta.)*

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story MUST map to one or more functional requirements. (US1 → FR-001/002/003/004/008/012; US2 → FR-005/006/007/012/015/016/017; US3 → FR-009/010/011; US4 → FR-013/014.)
- **TG-002**: Each requirement MUST identify expected owner role(s) at plan time (Implementer for wrappers/installer; Reviewer for parity + packaging; Spec Steward for docs honesty).
- **TG-003**: Each requirement MUST identify its intended iteration / delivery window at plan time (this feature is estimated 10-15 SP, likely 1-2 iterations under the 20 SP cap).
- **TG-004**: Any known spec/implementation conflict MUST include an explicit reconciliation path. (Known reconciliation: Proposal 153 lists broad package-manager distribution as follow-up; this spec includes only a thin `install.sh` bootstrap, not Homebrew/apt/npm — see Out of Scope.)

### Key Entities

- **Canonical command registry**: the single source of truth for command names. v1 = `Specrew.psd1` `AliasesToExport` (8 aliases) + root `specrew`; v2 = Proposal 150 command manifest when available.
- **Wrapper script**: a POSIX `sh` thin forwarder that resolves the module root, verifies `pwsh`, and execs `pwsh -NoProfile -ExecutionPolicy Bypass -File <module>/scripts/specrew.ps1 "$@"` (or the alias's subcommand).
- **Wrapper installer**: the `specrew install-shell-wrappers` command surface and its bin-directory placement behavior.
- **Bootstrap installer**: the shell-native `install.sh`/equivalent that installs the module then the wrappers.
- **Package FileList set**: the `Specrew.psd1` `FileList` entries for wrappers + bootstrap that must ship in the published artifact.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On Ubuntu and macOS CI with `pwsh` installed, `specrew version` invoked through the wrapper returns the same version string as the PowerShell module command.
- **SC-002**: 100% of exported aliases in the canonical registry have a matching wrapper (parity test green); adding an alias without a wrapper fails CI.
- **SC-003**: Arguments containing spaces and quotes are preserved byte-for-byte from the wrapper into the PowerShell command (forwarding test green on Ubuntu + macOS).
- **SC-004**: `install-shell-wrappers` is idempotent across repeated runs and modifies nothing outside the requested bin directory (verified by before/after file inventory).
- **SC-005**: macOS/Linux documentation leads with native `specrew` commands; `pwsh -File` is no longer the primary documented Unix path.
- **SC-006** *(release gate)*: The release is validated by installing Specrew and exercising BOTH a greenfield and a brownfield project on a real Unix host (covering the bundled Spec Kit 0.9.0 support), and no beta/stable is published without explicit maintainer authorization.
- **SC-007** *(auto-install)*: On a supported Unix host **without** PowerShell Core, running `install.sh` provisions `pwsh` via the native package manager, installs Specrew, installs wrappers, and `specrew version` works — with no manual PowerShell installation by the user. On an unsupported platform or a failed dependency install, `install.sh` exits non-zero with a clear message + a manual-docs link.
- **SC-008** *(prerelease install)*: `install.sh --prerelease` installs the prerelease (beta) Specrew from PSGallery, the output states it is installing a **prerelease**, and `specrew version` then reports that prerelease version; if the installed module lacks the `specrew` wrapper surface, `install.sh` exits non-zero with an incompatibility message. (Proven at the Iteration-3 release gate, when a published beta exists to install.)

## Assumptions

- Authoring happens on Windows, but the **authoritative** Unix-runtime verification surface is the Ubuntu + macOS CI lanes. Git Bash on Windows is a fast local proxy only and is NOT sufficient to call any Unix-runtime requirement done.
- PowerShell Core remains the runtime dependency. The thin **wrappers** never install `pwsh` — they verify it and error with an install hint (FR-004). The **bootstrap (`install.sh`)** DOES auto-install PowerShell Core as a dependency on supported platforms (FR-007/FR-016), so on Unix `pwsh` is an internal dependency, not a manual user prerequisite — except on unsupported platforms or after a failed auto-install, where manual dependency-install docs apply.
- `install.sh` installs the **stable** Specrew by default; `--prerelease` (FR-017) installs a beta from PSGallery for the beta-before-stable validation path. The prerelease install + the version/source-mismatch fail-closed are **built AND proven at the Iteration-3 release gate** (a published beta is required to exercise them — proving them in Iteration 2 is impossible, no beta exists yet).
- The v1 canonical registry is `Specrew.psd1` `AliasesToExport` (the 8 current aliases) plus the root `specrew`; Proposal 150's command manifest is a future v2 source.
- GitHub issue #1627 (feature-closeout `.specify` bootstrap-state classifier inconsistency) is a separate subsystem concern and is **deferred** — explicitly not part of this feature, to avoid scope expansion.
- The Spec Kit 0.9.0 support (merged to main, currently unreleased) rides this feature's release; its greenfield+brownfield install-validation is folded into this feature's release gate (FR-015 / SC-006).

## Out of Scope

- Rewriting Specrew in Bash, Go, Node, Rust, or any other language; removing PowerShell Core as a runtime dependency.
- Distributing **Specrew itself** as a Homebrew formula, apt package, or npm module (natural follow-ups after wrapper behavior is stable). The only Specrew installer in scope is the thin `install.sh`/equivalent bootstrap. *(Note: `install.sh` MAY invoke the platform package manager — apt/dnf/brew/etc. — to install the PowerShell Core **dependency** per FR-007; that is in scope. What stays out of scope is packaging Specrew's own distribution through those managers.)*
- Windows command reshaping beyond keeping existing PowerShell commands working + docs.
- Host-specific AI CLI wrapper behavior (this feature wraps only Specrew's own commands).
- GitHub issue #1627 (deferred; separate closeout-gate fix).

## Governance Alignment *(mandatory)*

- **Spec Steward**: Crew baseline Spec Steward — accountable for spec integrity + docs-honesty wording.
- **Iteration Facilitator**: Crew baseline (Planner / Retro Facilitator) — cadence + blockers.
- **Capacity Model**: story points; Proposal 153 estimate 10-15 SP → likely 1-2 iterations, each within the 20 SP cap; finalized at plan/capacity.
- **Drift Signals**: registry ↔ wrapper ↔ FileList ↔ docs parity tests in CI (the dependency cascade); spec ↔ plan ↔ tasks traceability checks.
- **Human Oversight Points**: clarify → plan (next boundary), plan → tasks, before-implement, review-signoff, and the release gate (no publish without explicit authorization).
