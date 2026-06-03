#!/usr/bin/env sh
# Table-driven detection test for install.sh --check (T012 Linux, T018 macOS; FR-007/FR-016).
# Pure POSIX sh; no root or network. Runs in Ubuntu CI, macOS CI, and locally on any POSIX sh.
#
# Host-independent by design: each case forces the OS via SPECREW_UNAME_OVERRIDE and (for
# Linux) points at a fixture os-release via SPECREW_OS_RELEASE_FILE, so the SAME suite proves
# the Ubuntu/Debian apt branch AND the macOS Homebrew branch regardless of the runner OS.
# macOS Homebrew presence is controlled per-case (a stub brew on PATH, or an empty PATH).
set -u

here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
fix="$here/../fixtures/install-sh/os-release"
shbin="$(command -v sh)"

pass=0
fail=0

# run: desc  uname  os-release-fixture(or -)  path(or -)  want_rc  want_regex
run() {
  desc="$1"; un="$2"; fixture="$3"; pathval="$4"; want_rc="$5"; want_re="$6"
  if [ "$fixture" = "-" ]; then
    osr="$fix/does-not-exist-$$"
  else
    osr="$fix/$fixture"
  fi
  if [ "$pathval" = "-" ]; then
    out="$(SPECREW_UNAME_OVERRIDE="$un" SPECREW_OS_RELEASE_FILE="$osr" "$shbin" "$repo/install.sh" --check 2>&1)"
  else
    out="$(PATH="$pathval" SPECREW_UNAME_OVERRIDE="$un" SPECREW_OS_RELEASE_FILE="$osr" "$shbin" "$repo/install.sh" --check 2>&1)"
  fi
  rc=$?
  ok=1
  [ "$rc" = "$want_rc" ] || ok=0
  if [ -n "$want_re" ]; then
    printf '%s\n' "$out" | grep -Eq "$want_re" || ok=0
  fi
  if [ "$ok" = 1 ]; then
    pass=$((pass + 1))
    printf 'PASS  %s\n' "$desc"
  else
    fail=$((fail + 1))
    printf 'FAIL  %s (rc=%s, wanted rc=%s / re=%s)\n----\n%s\n----\n' "$desc" "$rc" "$want_rc" "$want_re" "$out"
  fi
}

# --- Linux apt branch (T012) — forced via uname override so it runs on any host ---
run "ubuntu 22.04 -> supported"          Linux ubuntu-2204      - 0 "supported: ubuntu 22.04"
run "debian 12 -> supported"             Linux debian-12        - 0 "supported: debian 12"
run "arch -> fail closed (distro)"       Linux arch             - 1 "supports Ubuntu, Debian, and macOS only"
run "ubuntu missing VERSION_ID -> fail"  Linux ubuntu-noversion - 1 "Could not determine the version"
run "missing os-release -> fail closed"  Linux -                - 1 "Cannot read"

# --- macOS Homebrew branch (T018) — forced via uname override; brew presence controlled ---
# brew absent: an empty PATH makes `command -v brew` fail -> fail closed with manual guidance.
brew_absent_dir="$(mktemp -d 2>/dev/null || mktemp -d -t specrew-noBrew)"
run "macOS + no Homebrew -> fail closed"  Darwin - "$brew_absent_dir" 1 "Homebrew"

# brew present: a stub brew on PATH -> supported macOS path reported.
brew_stub_dir="$(mktemp -d 2>/dev/null || mktemp -d -t specrew-brew)"
printf '#!/bin/sh\nexit 0\n' > "$brew_stub_dir/brew"
chmod +x "$brew_stub_dir/brew"
run "macOS + Homebrew -> supported"       Darwin - "$brew_stub_dir" 0 "supported: macOS"

rm -rf "$brew_absent_dir" "$brew_stub_dir" 2>/dev/null || true

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
