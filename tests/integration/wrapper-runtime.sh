#!/usr/bin/env sh
# Unix wrapper runtime proof (FR-002/003/004/008) — the Iteration-1-deferred proof, run on
# real POSIX sh + pwsh (Ubuntu CI is authoritative; macOS in a later iteration).
# Exercises the committed bin/specrew wrapper against a stub module-root that echoes the
# forwarded args, so forwarding/symlink/pwsh-missing/passthrough are proven, not asserted on faith.
set -u

here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"

pass=0
fail=0
ok() { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
no() { fail=$((fail + 1)); d="$1"; shift; printf 'FAIL  %s\n%s\n' "$d" "$*"; }

if ! command -v pwsh >/dev/null 2>&1; then
  echo "wrapper-runtime: pwsh is required for this proof (it runs after auto-install)." >&2
  exit 1
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/scripts" "$work/bin"

# Stub module entrypoint: print each forwarded argument unambiguously.
cat > "$work/scripts/specrew.ps1" <<'PS'
foreach ($a in $args) { [Console]::Out.WriteLine("ARG=[$a]") }
PS

cp "$repo/bin/specrew" "$work/bin/specrew"
chmod +x "$work/bin/specrew"

# --- FR-002: exact argument forwarding (spaces, quote, empty, --, glob char) ---
# tr -d '\r' keeps the comparison CR-insensitive (no-op on Linux pwsh; defensive only).
out="$("$work/bin/specrew" "a b" "c'd" "" -- "*.txt" | tr -d '\r')"
want="ARG=[a b]
ARG=[c'd]
ARG=[]
ARG=[--]
ARG=[*.txt]"
if [ "$out" = "$want" ]; then ok "FR-002 exact argument forwarding"; else no "FR-002 exact argument forwarding" "got:
$out
want:
$want"; fi

# --- FR-003: module-root resolution through a symlink ---
ln -s "$work/bin/specrew" "$work/link-specrew"
out="$("$work/link-specrew" hello | tr -d '\r')"
if [ "$out" = "ARG=[hello]" ]; then ok "FR-003 module-root resolution via symlink"; else no "FR-003 symlink resolution" "got: $out"; fi

# --- FR-004: pwsh missing -> exit 127 + clear message (clean PATH without pwsh) ---
nopwsh="$work/nopwsh"
mkdir -p "$nopwsh"
for t in env sh dash readlink dirname; do
  p="$(command -v "$t" 2>/dev/null || true)"
  [ -n "$p" ] && ln -sf "$p" "$nopwsh/$t"
done
# No pipe here: rc must capture the wrapper's exit (127), not tr's. The message substring
# has no internal CR, so the case-glob match is already CR-tolerant.
set +e
out="$(env -i PATH="$nopwsh" "$work/bin/specrew" version 2>&1)"
rc=$?
set -e
case "$out" in
  *"PowerShell Core (pwsh) is required"*) msg_ok=1 ;;
  *) msg_ok=0 ;;
esac
if [ "$rc" = "127" ] && [ "$msg_ok" = "1" ]; then ok "FR-004 pwsh-missing exit 127 + message"; else no "FR-004 pwsh-missing" "rc=$rc msg_ok=$msg_ok out=$out"; fi

# --- FR-008: unknown-option passthrough (wrapper must forward, not reject) ---
out="$("$work/bin/specrew" --some-future-flag=foo | tr -d '\r')"
if [ "$out" = "ARG=[--some-future-flag=foo]" ]; then ok "FR-008 unknown-option passthrough"; else no "FR-008 passthrough" "got: $out"; fi

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
