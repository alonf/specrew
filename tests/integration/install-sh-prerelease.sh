#!/usr/bin/env sh
# T019: install.sh --prerelease surface + wrapper-surface mismatch predicate (FR-017).
# Pure POSIX sh; no root, network, or pwsh. Runs on any POSIX sh (Ubuntu/macOS CI + local).
# The real --prerelease install + the live mismatch check against a published beta are
# proven at the release gate (T024); this asserts the unit-level surface + predicate.
set -u

here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
shbin="$(command -v sh)"

pass=0
fail=0
ok() { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
no() { fail=$((fail + 1)); printf 'FAIL  %s\n' "$1"; }

# 1. --help documents the --prerelease flag.
help="$("$shbin" "$repo/install.sh" --help 2>&1)"
if printf '%s\n' "$help" | grep -q -- '--prerelease'; then
  ok "--help documents --prerelease"
else
  no "--help documents --prerelease"
fi

# 2. wrapper_surface_present predicate (FR-017 version/source mismatch check).
# Source install.sh as a library (SPECREW_NO_MAIN=1, empty $@) and assert the pure predicate.
pred() {
  "$shbin" -c 'd="$1"; m="$2"; set --; SPECREW_NO_MAIN=1; export SPECREW_NO_MAIN; . "$m"; set +e; wrapper_surface_present "$d"; echo $?' _ "$1" "$repo/install.sh"
}

present_dir="$(mktemp -d 2>/dev/null || mktemp -d -t specrew-present)"
mkdir -p "$present_dir/bin"
: > "$present_dir/bin/specrew"
absent_dir="$(mktemp -d 2>/dev/null || mktemp -d -t specrew-absent)"

[ "$(pred "$present_dir")" = "0" ] && ok "module with bin/specrew -> surface present" || no "module with bin/specrew -> surface present"
[ "$(pred "$absent_dir")" != "0" ] && ok "module without bin/specrew -> mismatch (fail closed)" || no "module without bin/specrew -> mismatch"
[ "$(pred "")" != "0" ] && ok "empty module base -> mismatch (fail closed)" || no "empty module base -> mismatch"

rm -rf "$present_dir" "$absent_dir" 2>/dev/null || true

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
