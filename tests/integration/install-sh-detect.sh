#!/usr/bin/env sh
# Table-driven detection test for install.sh --check (T012, FR-007/FR-016).
# Pure POSIX sh; no root or network. Runs in Ubuntu CI and locally on any POSIX sh.
# Each case points install.sh at a fixture os-release via SPECREW_OS_RELEASE_FILE and
# asserts the --check exit code + message (supported -> 0; unsupported -> fail-closed 1).
set -u

here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
fix="$here/../fixtures/install-sh/os-release"

pass=0
fail=0

check() {
  # desc, fixture-file (or __missing__), want_rc, want_regex
  desc="$1"; fixture="$2"; want_rc="$3"; want_re="$4"
  if [ "$fixture" = "__missing__" ]; then
    osr="$fix/does-not-exist-$$"
  else
    osr="$fix/$fixture"
  fi
  out="$(SPECREW_OS_RELEASE_FILE="$osr" sh "$repo/install.sh" --check 2>&1)"
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

# On a non-Linux host (e.g. macOS runner) uname is Darwin and install.sh fails closed
# before reading os-release; this detection test is Linux-only by design.
if [ "$(uname -s 2>/dev/null)" != "Linux" ]; then
  printf 'SKIP  install-sh-detect: not Linux (uname=%s); detection is verified on Ubuntu CI.\n' "$(uname -s 2>/dev/null)"
  exit 0
fi

check "ubuntu 22.04 -> supported"          ubuntu-2204       0 "supported: ubuntu 22.04"
check "debian 12 -> supported"             debian-12         0 "supported: debian 12"
check "arch -> fail closed (distro)"       arch              1 "supports Ubuntu and Debian only"
check "ubuntu missing VERSION_ID -> fail"  ubuntu-noversion  1 "Could not determine the version"
check "missing os-release -> fail closed"  __missing__       1 "Cannot read"

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
