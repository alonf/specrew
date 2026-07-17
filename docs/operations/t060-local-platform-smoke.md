# T060 Local Windows and Linux Smokes

This runner owns the three remaining T060 allocations only: Cursor on Windows, Antigravity on Windows, and Copilot on WSL Ubuntu. It uses an external campaign authority store while the checked-in production mode remains `legacy`.

`Preflight` performs repository, digest, CLI/auth-readiness, harness, and OS-containment checks without invoking a model. `Invoke` requires an exact run ID, authorization reference, and acknowledgement; it contains one synchronous provider-capable call and no retry. Every second attempt therefore requires a new run ID and a new human grant.

Run from a clean detached worktree at the supplied 40-character commit. Put every output directory outside that worktree. The runner places transient Windows target and candidate staging under short sibling directories (`.t060-targets` and `.t060-staging`). The target port uses a fixed-length token in its disposable directory name while retaining the complete run ID in authority metadata, keeping every currently tracked path below the legacy Windows boundary; terminal cleanup removes the transient roots when empty.

## Windows preflight

Cursor uses 600 seconds and Antigravity uses 900 seconds:

```powershell
$PinnedCommit = '<40_CHARACTER_COMMIT>'
$HostName = 'cursor-agent' # or: antigravity
$TimeoutSeconds = 600      # use 900 for antigravity
$Model = 'auto'             # Cursor Free; omit for Antigravity
$PreflightOut = Join-Path $env:TEMP "t060-$HostName-preflight-$PinnedCommit"

pwsh -NoProfile -File ./scripts/t060-local-platform-smoke.ps1 `
  -Mode Preflight `
  -HostName $HostName `
  -RepoRoot $PWD `
  -ExpectedCommit $PinnedCommit `
  -OutputDirectory $PreflightOut `
  -Model $Model `
  -TimeoutSeconds $TimeoutSeconds
```

For Antigravity, omit `-Model`. Cursor preflight verifies the exact selection against the authenticated account-visible list without invoking it. The live Free-plan evidence requires `auto`: attempt 04 proved that appearance in `cursor-agent models` does not grant a Free account permission to execute a named model. Expected: `provider_invoked` is `false`; `auto` is recorded; the harness is file-primary ready; the runtime is `windows-job-object-runtime` and ready.

## WSL Copilot preflight

The command must execute inside the already-proven transient delegated service; it must not grant a permanent or globally writable cgroup root:

```powershell
wsl.exe -d Ubuntu-24.04 -u root -e systemd-run --quiet --wait --collect --pipe --uid=alon `
  --property=Delegate=yes --property=Type=exec `
  --setenv=HOME=/home/alon `
  --setenv=PATH=/home/alon/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin `
  pwsh -NoProfile -File '<LINUX_CHECKOUT>/scripts/t060-local-platform-smoke.ps1' `
    -Mode Preflight `
    -HostName copilot `
    -RepoRoot '<LINUX_CHECKOUT>' `
    -ExpectedCommit '<40_CHARACTER_COMMIT>' `
    -OutputDirectory '/home/alon/t060-copilot-preflight-<40_CHARACTER_COMMIT>' `
    -TimeoutSeconds 300
```

Expected: `provider_invoked` is `false`; Copilot is file-primary ready; the runtime is `linux-cgroup-v2-runtime` and ready. `systemd-run --wait --collect` collects the transient unit after the command.

## One authorized invocation

After a human grants one exact slot, repeat the applicable platform command with a fresh output directory and these substitutions:

```text
-Mode Invoke
-RunId <EXACT_GRANTED_RUN_ID>
-AuthorizationRef <EXACT_GRANTED_AUTHORIZATION_REF>
-AcknowledgeProviderInvocation
```

Do not rerun on a finding, incomplete/invalid output, timeout, launch failure, or any other non-clean result. Preserve the output directory. The runner writes `preflight.json`, `progress.json`, `result.json`, `report.md`, `manifest.json`, the external `campaign-authority.json`, and the append-only `authority/` subtree. It then fails closed unless the repository is unchanged, exactly one matching grant/reservation/spend exists, the terminal result is schema-valid and current for the canonical digest, containment and termination are verified, and the complete verdict is clean with zero findings.
