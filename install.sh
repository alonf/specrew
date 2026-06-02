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
#      source (Ubuntu/Debian: the Microsoft apt repository),
#   3. install/update the Specrew module from the PowerShell Gallery (skipped if the
#      module is already present — e.g. a pre-seeded local module under PSModulePath),
#   4. install the native `specrew` shell wrappers.
#
# Safety (FR-016): vendor-recommended source only (never an untrusted curl|bash beyond
# THIS trusted bootstrap); install-only-if-absent (never clobber an existing pwsh);
# idempotent repository registration; privilege escalation is SURFACED through the normal
# sudo prompt (never silent); on an unsupported platform/version or a failed install it
# FAILS CLOSED with manual-install guidance (no partial install reported as success).
#
# Scope (this release): Ubuntu/Debian auto-install. macOS + other distros fail closed with
# manual guidance (planned for a later iteration). The thin wrappers never install pwsh.
set -eu

# --- configuration ---------------------------------------------------------
SPECREW_INSTALL_URL="${SPECREW_INSTALL_URL:-https://raw.githubusercontent.com/alonf/specrew/main/install.sh}"
PWSH_MANUAL_DOCS_URL="https://learn.microsoft.com/powershell/scripting/install/installing-powershell"
OS_RELEASE_FILE="${SPECREW_OS_RELEASE_FILE:-/etc/os-release}"
SPECREW_BIN_DIR=""
MODE="install"

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

Options:
  --bin-dir <dir>   Install the shell wrappers into <dir> (default: ~/.local/bin).
  --check           Detect the platform and report whether auto-install is supported, then exit.
                    Makes no changes (no install, no elevation).
  -h, --help        Show this help and exit.

PowerShell Core is installed automatically as a dependency on supported platforms
(Ubuntu/Debian). On unsupported platforms the installer fails closed with manual docs.
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
    --check|--detect-only) MODE="check" ;;
    -h|--help) usage; exit 0 ;;
    *) err "unknown option: $1"; usage >&2; exit 2 ;;
  esac
  shift
done

# --- platform detection (T012) ---------------------------------------------
# Identifies the OS + distro + version and confirms the auto-install path is in scope.
# Reads os-release from $OS_RELEASE_FILE (overridable via SPECREW_OS_RELEASE_FILE for tests).
detect_platform() {
  os="$(uname -s 2>/dev/null || echo unknown)"
  case "$os" in
    Linux) : ;;
    Darwin)
      fail_closed "macOS auto-install of PowerShell is not yet supported by this Specrew release (planned for a later iteration). Install PowerShell (e.g. 'brew install --cask powershell'), then re-run." ;;
    *)
      fail_closed "Unsupported operating system '$os' for auto-install. Install PowerShell manually, then re-run." ;;
  esac

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
      fail_closed "Auto-install currently supports Ubuntu and Debian only (detected '$PLATFORM_DISTRO'). Install PowerShell manually, then re-run." ;;
  esac

  [ -n "$PLATFORM_VERSION" ] || fail_closed "Could not determine the version of '$PLATFORM_DISTRO' from '$OS_RELEASE_FILE'. Install PowerShell manually, then re-run."
}

# --- privilege resolution (T014; ratified D11a) ----------------------------
# Decides how to run privileged commands, honoring the ratified rules:
#   root            -> run directly (no sudo); the CI/container path
#   non-root + tty  -> surfaced sudo (sudo prompts on its own /dev/tty)
#   non-root no tty -> fail closed with download-then-run guidance (never silent, never hang)
# The script never reads from stdin in the piped path (so 'curl | sh' is never consumed).
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

# --- PowerShell auto-install (T013) ----------------------------------------
# Install-only-if-absent: never clobber/upgrade an existing working pwsh.
ensure_pwsh() {
  if have pwsh; then
    log "PowerShell Core (pwsh) already present ($(pwsh --version 2>/dev/null || echo 'version unknown')); skipping install."
    return 0
  fi
  log "PowerShell Core (pwsh) not found; installing it as a dependency..."
  resolve_privilege
  case "$PLATFORM_DISTRO" in
    ubuntu|debian) install_pwsh_apt ;;
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

# --- Specrew module (install-if-absent; PSGallery in production) -----------
# If the Specrew module is already discoverable (e.g. a local module pre-seeded onto
# PSModulePath in CI), skip the gallery fetch and use it. Production installs from PSGallery.
ensure_specrew_module() {
  if pwsh -NoProfile -NonInteractive -Command "if (Get-Module -ListAvailable -Name Specrew) { exit 0 } else { exit 1 }" >/dev/null 2>&1; then
    log "Specrew module already available; skipping PowerShell Gallery install."
    return 0
  fi
  log "Installing the Specrew module from the PowerShell Gallery..."
  pwsh -NoProfile -NonInteractive -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue; Install-Module -Name Specrew -Scope CurrentUser -Force -AllowClobber" \
    || fail_closed "Failed to install the Specrew module from the PowerShell Gallery."
}

# --- shell wrappers --------------------------------------------------------
install_wrappers() {
  log "Installing the native 'specrew' shell wrappers..."
  if [ -n "$SPECREW_BIN_DIR" ]; then
    pwsh -NoProfile -NonInteractive -Command "Import-Module Specrew -Force; specrew install-shell-wrappers --bin-dir '$SPECREW_BIN_DIR'" \
      || fail_closed "Failed to install the shell wrappers into '$SPECREW_BIN_DIR'."
  else
    pwsh -NoProfile -NonInteractive -Command "Import-Module Specrew -Force; specrew install-shell-wrappers" \
      || fail_closed "Failed to install the shell wrappers."
  fi
}

# --- orchestration (T011) --------------------------------------------------
main() {
  detect_platform
  if [ "$MODE" = "check" ]; then
    log "supported: ${PLATFORM_DISTRO} ${PLATFORM_VERSION} (Ubuntu/Debian apt auto-install path; the exact version is verified against the Microsoft repository at install time)."
    exit 0
  fi
  ensure_pwsh
  ensure_specrew_module
  install_wrappers
  log "Done. The native 'specrew' command is installed."
  log "If the wrapper directory is not on your PATH, add it using the hint printed above, then run: specrew version"
}

main
