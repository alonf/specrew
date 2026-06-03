#!/usr/bin/env sh
# Specrew Unix bootstrap installer.
#
# This is the user-facing, shell-native entrypoint for macOS/Linux:
#
#   curl -fsSL <trusted-specrew-install-url> | sh
#
# It makes PowerShell Core an INTERNAL dependency, not a manual prerequisite:
#   1. detect the platform / package manager,
#   2. if `pwsh` is absent, auto-install PowerShell Core from the vendor-recommended
#      source (Ubuntu/Debian: the Microsoft apt repository; macOS: Homebrew),
#   3. install/update the Specrew module from the PowerShell Gallery (skipped if the
#      module is already present — e.g. a pre-seeded local module under PSModulePath),
#   4. install the native `specrew` shell wrappers.
#
# Safety (FR-016): vendor-recommended source only (never an untrusted curl|bash beyond
# THIS trusted bootstrap); install-only-if-absent (never clobber an existing pwsh);
# idempotent repository registration; privilege escalation is SURFACED through the normal
# sudo prompt (never silent; macOS Homebrew runs as the user, never sudo); on an
# unsupported platform/version or a failed install it FAILS CLOSED with manual-install
# guidance (no partial install reported as success).
#
# Scope (this release): Ubuntu/Debian (apt) + macOS (Homebrew) auto-install. Other distros
# fail closed with manual guidance (planned for a later iteration). The thin wrappers never
# install pwsh.
set -eu

# --- configuration ---------------------------------------------------------
SPECREW_INSTALL_URL="${SPECREW_INSTALL_URL:-https://raw.githubusercontent.com/alonf/specrew/main/install.sh}"
PWSH_MANUAL_DOCS_URL="https://learn.microsoft.com/powershell/scripting/install/installing-powershell"
HOMEBREW_DOCS_URL="https://brew.sh"
OS_RELEASE_FILE="${SPECREW_OS_RELEASE_FILE:-/etc/os-release}"
SPECREW_BIN_DIR=""
MODE="install"
PRERELEASE=0
SPECREW_MODULE_VERSION=""

PLATFORM_DISTRO=""
PLATFORM_VERSION=""
PRIVILEGE_MODE=""

# --- output helpers --------------------------------------------------------
log()  { printf 'specrew-install: %s\n' "$*"; }
warn() { printf 'specrew-install: %s\n' "$*" >&2; }
err()  { printf 'specrew-install: error: %s\n' "$*" >&2; }

# Fail closed: print the reason + the manual-install docs link, then exit non-zero.
# Never leaves a partial install reported as success.
fail_closed() {
  err "$1"
  printf 'specrew-install: install PowerShell manually, then re-run: %s\n' "$PWSH_MANUAL_DOCS_URL" >&2
  exit 1
}

have() { command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<EOF
Specrew Unix bootstrap installer.

Usage: install.sh [options]
       curl -fsSL <url> | sh
       curl -fsSL <url> | sh -s -- --prerelease

Options:
  --bin-dir <dir>   Install the shell wrappers into <dir> (default: ~/.local/bin).
  --prerelease      Install a PRERELEASE (beta) Specrew from the PowerShell Gallery
                    (Install-Module -AllowPrerelease). Default is the stable release.
  --check           Detect the platform and report whether auto-install is supported, then exit.
                    Makes no changes (no install, no elevation).
  -h, --help        Show this help and exit.

PowerShell Core is installed automatically as a dependency on supported platforms
(Ubuntu/Debian via the Microsoft apt repository; macOS via Homebrew). On unsupported
platforms the installer fails closed with manual docs.
EOF
}

# --- argument parsing ------------------------------------------------------
while [ "$#" -gt 0 ]; do
  case "$1" in
    --bin-dir)
      shift
      [ "$#" -gt 0 ] || fail_closed "--bin-dir requires a directory argument."
      SPECREW_BIN_DIR="$1"
      ;;
    --bin-dir=*) SPECREW_BIN_DIR="${1#--bin-dir=}" ;;
    --prerelease) PRERELEASE=1 ;;
    --check|--detect-only) MODE="check" ;;
    -h|--help) usage; exit 0 ;;
    *) err "unknown option: $1"; usage >&2; exit 2 ;;
  esac
  shift
done

# --- platform detection (T012 Linux; T018 macOS) ---------------------------
# Identifies the OS + distro + version and confirms the auto-install path is in scope.
# `uname -s` is overridable via SPECREW_UNAME_OVERRIDE so the macOS branch is reachable
# from Linux CI for testing; os-release is overridable via SPECREW_OS_RELEASE_FILE.
detect_platform() {
  os="${SPECREW_UNAME_OVERRIDE:-$(uname -s 2>/dev/null || echo unknown)}"
  case "$os" in
    Linux)  detect_platform_linux ;;
    Darwin) detect_platform_macos ;;
    *)
      fail_closed "Unsupported operating system '$os' for auto-install. Install PowerShell manually, then re-run." ;;
  esac
}

# macOS: Homebrew is the package manager; there is no /etc/os-release. The product
# version is informational only (Homebrew handles version compatibility).
detect_platform_macos() {
  PLATFORM_DISTRO="macos"
  PLATFORM_VERSION="$(sw_vers -productVersion 2>/dev/null || echo '')"
}

detect_platform_linux() {
  [ -r "$OS_RELEASE_FILE" ] || fail_closed "Cannot read '$OS_RELEASE_FILE' to identify the Linux distribution. Install PowerShell manually, then re-run."

  # Source os-release in a subshell to read ID / VERSION_ID (the Microsoft-documented
  # approach); os-release is a trusted system file and assignment handles any quoting.
  # shellcheck disable=SC1090
  PLATFORM_DISTRO="$( . "$OS_RELEASE_FILE" >/dev/null 2>&1; printf '%s' "${ID:-}" )"
  # shellcheck disable=SC1090
  PLATFORM_VERSION="$( . "$OS_RELEASE_FILE" >/dev/null 2>&1; printf '%s' "${VERSION_ID:-}" )"

  [ -n "$PLATFORM_DISTRO" ] || fail_closed "Could not determine the distribution ID from '$OS_RELEASE_FILE'. Install PowerShell manually, then re-run."

  case "$PLATFORM_DISTRO" in
    ubuntu|debian) : ;;
    *)
      fail_closed "Auto-install currently supports Ubuntu, Debian, and macOS only (detected '$PLATFORM_DISTRO'). Install PowerShell manually, then re-run." ;;
  esac

  [ -n "$PLATFORM_VERSION" ] || fail_closed "Could not determine the version of '$PLATFORM_DISTRO' from '$OS_RELEASE_FILE'. Install PowerShell manually, then re-run."
}

# --- privilege resolution (T014; ratified D11a) ----------------------------
# Decides how to run privileged commands, honoring the ratified rules:
#   root            -> run directly (no sudo); the CI/container path
#   non-root + tty  -> surfaced sudo (sudo prompts on its own /dev/tty)
#   non-root no tty -> fail closed with download-then-run guidance (never silent, never hang)
# The script never reads from stdin in the piped path (so 'curl | sh' is never consumed).
# NOTE: this is the apt (Linux) elevation path; macOS Homebrew runs as the user (no sudo).
usable_tty() {
  # True if a controlling terminal exists that sudo can prompt on.
  { true >/dev/tty; } 2>/dev/null
}

resolve_privilege() {
  if [ "$(id -u)" = "0" ]; then
    PRIVILEGE_MODE="root"
    return 0
  fi
  if ! have sudo; then
    fail_closed "PowerShell install needs root privileges, but 'sudo' is not available and you are not root. Re-run as root, or install PowerShell manually, then re-run."
  fi
  if sudo -n true 2>/dev/null; then
    PRIVILEGE_MODE="sudo"   # passwordless sudo (works, though not the primary path)
    return 0
  fi
  if usable_tty; then
    PRIVILEGE_MODE="sudo"   # sudo will prompt for the password on /dev/tty (surfaced)
    log "PowerShell install needs administrator rights; sudo will prompt for your password."
    return 0
  fi
  fail_closed "PowerShell install needs sudo, but there is no terminal to prompt for a password (the script was piped via 'curl | sh'). Re-run by downloading first:
    curl -fsSL ${SPECREW_INSTALL_URL} -o install-specrew.sh && sh install-specrew.sh
  or run as root."
}

run_privileged() {
  case "$PRIVILEGE_MODE" in
    root) "$@" ;;
    sudo) sudo "$@" ;;
    *) fail_closed "internal error: privilege mode not resolved before a privileged command." ;;
  esac
}

# --- PowerShell auto-install (T013 apt; T018 brew) -------------------------
# Install-only-if-absent: never clobber/upgrade an existing working pwsh.
ensure_pwsh() {
  if have pwsh; then
    log "PowerShell Core (pwsh) already present ($(pwsh --version 2>/dev/null || echo 'version unknown')); skipping install."
    return 0
  fi
  log "PowerShell Core (pwsh) not found; installing it as a dependency..."
  case "$PLATFORM_DISTRO" in
    ubuntu|debian) resolve_privilege; install_pwsh_apt ;;
    macos)         install_pwsh_brew ;;
    *) fail_closed "No supported auto-install path for '$PLATFORM_DISTRO'. Install PowerShell manually, then re-run." ;;
  esac
  have pwsh || fail_closed "PowerShell install ran but 'pwsh' is still not on PATH. Install manually, then re-run."
  log "PowerShell Core installed ($(pwsh --version 2>/dev/null || echo 'version unknown'))."
}

# Microsoft package repository (PMC) flow, per the current MS install docs.
# The per-version packages-microsoft-prod.deb registers the Microsoft signing key + apt
# source; a missing .deb (download failure / 404) is the deliberate unsupported-version
# signal and triggers fail-closed (MS publishes the .deb only for supported versions).
install_pwsh_apt() {
  log "Installing PowerShell from the Microsoft package repository (apt)..."
  run_privileged apt-get update
  run_privileged apt-get install -y wget apt-transport-https software-properties-common

  deb_url="https://packages.microsoft.com/config/${PLATFORM_DISTRO}/${PLATFORM_VERSION}/packages-microsoft-prod.deb"
  tmp_deb="$(mktemp 2>/dev/null || mktemp -t pmprod)" || fail_closed "Could not create a temporary file for the Microsoft repository package."
  log "Registering the Microsoft package repository: $deb_url"
  if ! wget -q -O "$tmp_deb" "$deb_url"; then
    rm -f "$tmp_deb"
    fail_closed "PowerShell is not published for '${PLATFORM_DISTRO} ${PLATFORM_VERSION}' on the Microsoft package repository (could not fetch $deb_url). This version is unsupported for auto-install."
  fi
  # Idempotent: re-installing packages-microsoft-prod re-registers the same key + source
  # (no duplicate apt source is created on re-run).
  run_privileged dpkg -i "$tmp_deb"
  rm -f "$tmp_deb"
  run_privileged apt-get update
  run_privileged apt-get install -y powershell
}

# Homebrew flow (macOS), per the current MS macOS install docs.
# Homebrew is the vendor-recommended source on macOS. It manages its own privileges and
# REFUSES to run under sudo, so this path never elevates (the surfaced-never-silent rule
# is honored trivially: there is no privileged step). Install-only-if-absent is enforced
# by ensure_pwsh's `have pwsh` guard; absent Homebrew fails closed with manual guidance.
install_pwsh_brew() {
  have brew || fail_closed "macOS auto-install needs Homebrew, but 'brew' was not found. Install Homebrew from ${HOMEBREW_DOCS_URL}, then re-run (or install PowerShell manually)."
  log "Installing PowerShell from Homebrew (brew install --cask powershell)..."
  brew install --cask powershell || fail_closed "Homebrew failed to install PowerShell ('brew install --cask powershell'). Install PowerShell manually, then re-run."
}

# --- Specrew module --------------------------------------------------------
# Echo the (base) version of the highest installed Specrew module that ships the native
# `bin/specrew` wrapper surface; empty if none. Prereleases are included (their Version is the
# BASE, e.g. 0.31.0 for 0.31.0-beta1), so install_wrappers can `Import-Module -RequiredVersion`
# that exact version and load the beta even when an older stable is also installed.
resolve_specrew_module_version() {
  pwsh -NoProfile -NonInteractive -Command "
    \$m = Get-Module -ListAvailable -Name Specrew |
      Where-Object { Test-Path -LiteralPath (Join-Path \$_.ModuleBase 'bin/specrew') } |
      Sort-Object Version -Descending | Select-Object -First 1
    if (\$m) { \$m.Version.ToString() }
  " 2>/dev/null || true
}

# Pure predicate: does a module base expose the native wrapper surface? Sourced + asserted by
# tests/integration/install-sh-prerelease.sh (the FR-017 mismatch check); resolve_specrew_module_version
# applies the same rule in PowerShell at runtime.
# shellcheck disable=SC2329  # invoked by the test suite via SPECREW_NO_MAIN sourcing, not within install.sh
wrapper_surface_present() {
  [ -n "${1:-}" ] && [ -e "$1/bin/specrew" ]
}

# Install/resolve the Specrew module. Skip the gallery fetch ONLY when a WRAPPER-CAPABLE module
# (one shipping bin/specrew) is already installed AND we are not explicitly fetching a prerelease.
# A pre-existing OLD Specrew (predating the Unix wrappers) is NOT reused — it lacks the
# `install-shell-wrappers` command. `--prerelease` always fetches the latest published beta.
# Afterward, resolve the wrapper-capable version and FAIL CLOSED if none — never a partial success
# reported as done (FR-016/FR-017).
ensure_specrew_module() {
  if [ "$PRERELEASE" != "1" ] && [ -n "$(resolve_specrew_module_version)" ]; then
    log "A wrapper-capable Specrew module is already installed; skipping the PowerShell Gallery install."
  elif [ "$PRERELEASE" = "1" ]; then
    log "Installing the Specrew module (PRERELEASE / beta) from the PowerShell Gallery..."
    # \$ProgressPreference suppresses Install-Module's Write-Progress bar (it renders via cursor
    # positioning and otherwise leaves the terminal cursor mid-screen after the install). \$ escaped
    # so POSIX sh passes the literal token to pwsh instead of expanding it as a shell variable.
    pwsh -NoProfile -NonInteractive -Command "\$ProgressPreference='SilentlyContinue'; Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue; Install-Module -Name Specrew -Scope CurrentUser -Force -AllowClobber -AllowPrerelease" \
      || fail_closed "Failed to install the PRERELEASE Specrew module from the PowerShell Gallery."
  else
    log "Installing the Specrew module (stable) from the PowerShell Gallery..."
    pwsh -NoProfile -NonInteractive -Command "\$ProgressPreference='SilentlyContinue'; Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue; Install-Module -Name Specrew -Scope CurrentUser -Force -AllowClobber" \
      || fail_closed "Failed to install the Specrew module from the PowerShell Gallery."
  fi

  # FR-017 version/source check: an OLD Specrew (no bin/specrew) does NOT count — and on a host
  # where an old stable sits side-by-side with the new beta, a plain `Import-Module` would load
  # the old stable, so we pin the resolved wrapper-capable version in install_wrappers.
  SPECREW_MODULE_VERSION="$(resolve_specrew_module_version)"
  [ -n "$SPECREW_MODULE_VERSION" ] || fail_closed "No installed Specrew version exposes the native 'specrew' wrapper command surface (a version/source mismatch — e.g. only an older Specrew without the Unix wrappers is present). Re-run 'install.sh --prerelease' to fetch the beta, or install a compatible version, then re-run."
  log "Using Specrew module version ${SPECREW_MODULE_VERSION} (native wrapper surface present)."
}

# --- shell wrappers --------------------------------------------------------
install_wrappers() {
  log "Installing the native 'specrew' shell wrappers..."
  # The bootstrap is an explicit, user-invoked install, so it must CREATE the target bin
  # directory if it is missing (a fresh account often has no ~/.local/bin) — pass --force,
  # which install-shell-wrappers requires both to create a missing dir and to overwrite a
  # non-Specrew entry at a wrapper path (FR-006). Without it, the advertised one-step
  # `curl | sh` install would fail at this step on a clean host. (The standalone
  # `specrew install-shell-wrappers` command, run outside the bootstrap, stays safe-by-default:
  # it creates managed wrappers without --force but refuses to clobber a foreign file/symlink.)
  # Import the RESOLVED wrapper-capable version explicitly — a plain `Import-Module Specrew` loads
  # the highest *stable* (which may be an old, pre-wrappers version installed side-by-side).
  if [ -n "$SPECREW_BIN_DIR" ]; then
    pwsh -NoProfile -NonInteractive -Command "Import-Module Specrew -RequiredVersion '$SPECREW_MODULE_VERSION' -Force; specrew install-shell-wrappers --bin-dir '$SPECREW_BIN_DIR' --force" \
      || fail_closed "Failed to install the shell wrappers into '$SPECREW_BIN_DIR'."
  else
    pwsh -NoProfile -NonInteractive -Command "Import-Module Specrew -RequiredVersion '$SPECREW_MODULE_VERSION' -Force; specrew install-shell-wrappers --force" \
      || fail_closed "Failed to install the shell wrappers."
  fi

  # Install-Module (NuGet/PSGallery) strips the Unix execute bit from the packaged wrappers, so the
  # freshly symlinked targets can be non-executable ("Permission denied"). Restore +x on the module's
  # wrapper sources (the symlink targets) — defense-in-depth alongside install-shell-wrappers' own
  # chmod; no-op if already executable.
  module_bin="$(pwsh -NoProfile -NonInteractive -Command "(Get-Module -ListAvailable -Name Specrew | Where-Object { \$_.Version.ToString() -eq '$SPECREW_MODULE_VERSION' } | Select-Object -First 1).ModuleBase" 2>/dev/null || true)"
  if [ -n "$module_bin" ] && [ -d "$module_bin/bin" ]; then
    chmod +x "$module_bin"/bin/* 2>/dev/null || true
  fi
}

# --- orchestration (T011) --------------------------------------------------
main() {
  detect_platform
  if [ "$MODE" = "check" ]; then
    case "$PLATFORM_DISTRO" in
      macos)
        have brew || fail_closed "macOS auto-install needs Homebrew, but 'brew' was not found. Install Homebrew from ${HOMEBREW_DOCS_URL}, then re-run (or install PowerShell manually)."
        log "supported: macOS ${PLATFORM_VERSION:-(version unknown)} (Homebrew 'brew install --cask powershell' path)."
        ;;
      *)
        log "supported: ${PLATFORM_DISTRO} ${PLATFORM_VERSION} (Ubuntu/Debian apt auto-install path; the exact version is verified against the Microsoft repository at install time)."
        ;;
    esac
    exit 0
  fi
  ensure_pwsh
  ensure_specrew_module
  install_wrappers
  log "Done. The native 'specrew' command is installed."
  log "If the wrapper directory is not on your PATH, add it using the hint printed above, then run: specrew version"
}

# Run main unless sourced for unit testing (SPECREW_NO_MAIN=1 sources the function
# definitions without executing the installer, so pure helpers can be asserted directly).
[ "${SPECREW_NO_MAIN:-0}" = "1" ] || main
