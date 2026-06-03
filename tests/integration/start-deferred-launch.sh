#!/usr/bin/env sh
# Regression guard for the feature-140 interactive-`start` TTY bug found in beta2 validation.
#
# Symptom: `specrew start` via the native wrapper launched the host (Copilot) HEADLESS and
# exited straight back to the shell instead of opening an interactive session. Root cause:
# the native wrapper (bin/specrew) and clone-mode both run scripts/specrew.ps1 via
# `pwsh -File`, i.e. SCRIPT context. On Linux/macOS, PowerShell strips the controlling TTY
# from native command children spawned in a script body, so specrew-start.ps1 fell into its
# no-TTY fallback (`& copilot ...`). The TTY-preserving launch lives in the module function
# Invoke-SpecrewScript (the deferred-launch handoff). The fix re-dispatches `start` through
# that module function so the launch happens in FUNCTION context.
#
# This test exercises the BROKEN entry paths (bin/specrew start AND pwsh -File specrew.ps1
# start), with a stub specrew-start.ps1 + stub host, and asserts the deferred-launch
# mechanism engaged: SPECREW_DEFERRED_LAUNCH_FILE was set when start ran, and the host was
# launched by the module consumer with that env var set.
#
# IMPORTANT: CI has no TTY, so this proves the mechanism ENGAGES, not that the TUI renders.
# The real interactive proof is the maintainer's on-host validation (release gate).
set -u

here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"

if ! command -v pwsh >/dev/null 2>&1; then
  echo "start-deferred-launch: pwsh is required for this proof (it runs after auto-install)." >&2
  exit 1
fi

# The guard is Unix-only (-not $IsWindows); this proof is meaningless on Windows.
case "$(uname -s 2>/dev/null || echo unknown)" in
  Linux|Darwin) : ;;
  *) echo "start-deferred-launch: Unix-only proof; skipping on $(uname -s 2>/dev/null)." >&2; exit 0 ;;
esac

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# Isolated module root = full repo copy with a STUB specrew-start.ps1, so we drive the REAL
# dispatcher (scripts/specrew.ps1 re-dispatch guard) + REAL module (Specrew.psm1 deferred
# consumer) WITHOUT having to drive the full interactive start UI (host pick, profile, etc.).
mod="$work/Specrew"
mkdir -p "$mod"
cp -R "$repo/." "$mod/"
rm -rf "$mod/.git"
chmod +x "$mod/bin/specrew" 2>/dev/null || true

# Sentinels (paths handed to both stubs via the environment -> the stubs use fully-literal
# heredocs, so there is no sh/PowerShell escaping to get wrong).
export SPECREW_TEST_START_ENV="$work/start-saw-deferred-env.txt"
export SPECREW_TEST_HOST_LAUNCHED="$work/host-launched.txt"
export SPECREW_TEST_HOST_ENV="$work/host-saw-deferred-env.txt"
export SPECREW_TEST_STUB_HOST="$work/stub-host"
export SPECREW_TEST_WORKDIR="$work"
# Must start unset so the dispatcher guard fires; Invoke-SpecrewScript sets it.
unset SPECREW_DEFERRED_LAUNCH_FILE 2>/dev/null || true
unset SPECREW_INVOKED_FROM_MODULE 2>/dev/null || true

# Stub host (stands in for `copilot`): record that it ran + whether the deferred env var was
# set in ITS environment (proves it was launched through the deferred/function-context path).
cat > "$SPECREW_TEST_STUB_HOST" <<'EOF'
#!/usr/bin/env sh
echo "launched: $*" > "$SPECREW_TEST_HOST_LAUNCHED"
if [ -n "${SPECREW_DEFERRED_LAUNCH_FILE:-}" ]; then
  echo 1 > "$SPECREW_TEST_HOST_ENV"
else
  echo 0 > "$SPECREW_TEST_HOST_ENV"
fi
exit 0
EOF
chmod +x "$SPECREW_TEST_STUB_HOST"

# Stub specrew-start.ps1: mimic the real deferred-launch contract.
#  - record whether SPECREW_DEFERRED_LAUNCH_FILE is set when start runs (the regression signal)
#  - if set (FIXED path): write a minimal deferred-launch JSON -> module consumer launches host
#  - if unset (BUG path): emulate the script-context fallback by launching the host directly
cat > "$mod/scripts/specrew-start.ps1" <<'PS'
param([Parameter(ValueFromRemainingArguments = $true)] $CliArgs)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$deferred      = $env:SPECREW_DEFERRED_LAUNCH_FILE
$startSentinel = $env:SPECREW_TEST_START_ENV
$stubHost      = $env:SPECREW_TEST_STUB_HOST
$workDir       = $env:SPECREW_TEST_WORKDIR

if ([string]::IsNullOrEmpty($deferred)) {
    Set-Content -LiteralPath $startSentinel -Value '0'
    # BUG path: script-context fallback (what the real specrew-start.ps1 does when unset).
    & $stubHost --agent stub --add-dir $workDir -i 'bootstrap'
    exit 0
}

Set-Content -LiteralPath $startSentinel -Value '1'
$payload = [pscustomobject]@{
    CopilotPath      = $stubHost
    CopilotArgs      = @('--agent', 'stub', '--add-dir', $workDir, '-i', 'bootstrap')
    WorkingDirectory = $workDir
    HostKind         = 'copilot'
}
$payload | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $deferred -Encoding UTF8
exit 0
PS

pass=0
fail=0
ok() { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
no() { fail=$((fail + 1)); printf 'FAIL  %s\n  %s\n' "$1" "$2"; }

run_case() {
  desc="$1"
  shift
  rm -f "$SPECREW_TEST_START_ENV" "$SPECREW_TEST_HOST_LAUNCHED" "$SPECREW_TEST_HOST_ENV"
  "$@" >/dev/null 2>&1 || true
  start_seen="$(cat "$SPECREW_TEST_START_ENV" 2>/dev/null || echo missing)"
  host_ran=0
  [ -f "$SPECREW_TEST_HOST_LAUNCHED" ] && host_ran=1
  host_seen="$(cat "$SPECREW_TEST_HOST_ENV" 2>/dev/null || echo missing)"
  # 1/1/1 = re-dispatch happened and the host launched via the module function (deferred path).
  # 0/1/* = start ran in script context and used the fallback = the bug.
  if [ "$start_seen" = "1" ] && [ "$host_ran" = "1" ] && [ "$host_seen" = "1" ]; then
    ok "$desc (deferred-launch engaged; host launched in function context)"
  else
    no "$desc" "start_saw_env=$start_seen host_ran=$host_ran host_saw_env=$host_seen (expected 1/1/1; 0/* = script-context fallback = the bug)"
  fi
}

# Entry path 1: the real native wrapper (the maintainer's exact `specrew start`).
run_case "bin/specrew start (native wrapper)" "$mod/bin/specrew" start "build something small"

# Entry path 2: clone-mode `pwsh -File scripts/specrew.ps1 start`.
run_case "pwsh -File specrew.ps1 start (clone-mode)" \
  pwsh -NoProfile -ExecutionPolicy Bypass -File "$mod/scripts/specrew.ps1" start "build something small"

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
