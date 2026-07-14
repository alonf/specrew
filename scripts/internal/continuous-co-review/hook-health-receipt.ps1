$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# F-198 Iteration 005 / T038 (FR-053) + T036 (FR-051): minimum hook-health EVIDENCE, the doctor/status
# health renderer, the Codex untrusted-headless governance PREFLIGHT, and the Stop-gate fail-open guard.
#
# WHY THIS FILE EXISTS (FR-053): a DEPLOYED hook configuration is NOT proof the host loaded and fired it. The
# only durable proof is a RECEIPT written from a REAL host-triggered SessionStart/Stop invocation. This module
# is the SINGLE source of truth for writing, reading, and CLASSIFYING that receipt-based health - plus the two
# consumers Beta2 needs: the doctor/status renderer and the Codex headless preflight.
#
# F-184 FOOTPRINT: NONE. This is a NEW, non-protected leaf module under the CCR internal location - the same
# pattern as T035's host-support-tier.ps1: the protected doctor/status surface (scripts/specrew-hooks.ps1) and
# the protected inspector (scripts/internal/specrew-hook-health.ps1) can CALL Format-SpecrewHookHealthReport /
# Resolve-SpecrewHookHealth here without either protected file being edited. Pure I/O + string building.
# No function here collides with the protected specrew-hook-health.ps1 surface (distinct receipt-scoped names).
#
# THE MODEL (Prop-145, maintainer decision 2026-07-14) - TWO INDEPENDENT concepts, never one overloaded status:
#   HOOK LIVENESS (hook_status): whether the configured hook path was recently OBSERVED firing. This is MONITORING
#     evidence, NOT authenticated - the receipt store is project-writable and the dispatcher can be invoked directly,
#     so a same-user process could write a receipt. `healthy` here is OPERATIONAL confidence, never proof of the host
#     process; do not describe a receipt as authenticated or as something a PATH shim / same-user process cannot
#     produce. Values: healthy (fresh + well-formed lifecycle receipt) | stale | malformed (incl. a pre-v3 receipt
#     missing version_source, wrong adapter contract) | conflicting (SessionStart receipts / host field disagree) |
#     absent (no receipt).
#   VERSION DIAGNOSTIC (version_status + version_source): a NON-AUTHORITATIVE, NON-PROMOTING ambient PATH-resolved
#     `--version` reading. It NEVER changes hook_status or readiness. A 'diagnostic-match' means only that the
#     SessionStart reading and a later probe resolved EQUIVALENT reported versions through the ambient command
#     binding. Values: diagnostic-match | diagnostic-drift | unavailable | untrusted-source; source ambient-path-binding.
#   A version probe failure leaves version_status 'unavailable' but does NOT erase valid hook liveness.
# No strong executable identity is available on current host contracts, so none is claimed. The observed version is
# a BOUNDED SessionStart reading (the host CLI's own --version), NEVER an env value.
#
# THE CODEX TRUST GATE (FR-051, maintainer decision 2026-07-14) = NO-PERSISTENT-MUTATION. Codex OWNS its trust
# decision. Specrew NEVER writes ~/.codex, NEVER seeds a trusted_hash, NEVER passes --dangerously-bypass-hook-trust
# as a general solution. The supported flow: Specrew configures the hook -> interactive Codex shows its NATIVE
# trust prompt -> the user approves -> a REAL hook fire records a health RECEIPT -> a HEADLESS `codex exec` proceeds
# as governed ONLY when Test-SpecrewCodexHeadlessGovernanceReady confirms that receipt is CURRENT. No current
# receipt -> NOT ready -> fail/degrade with the actionable instruction; NEVER silently continue as governed.
# (Evidence: iterations/005/evidence/codex-stop-contract-characterization.md - untrusted headless hooks are
# SILENTLY skipped; and malformed hook stdout SILENTLY fails open. Both are the dominant real-world risks.)

# ------------------------------------------------------------------------------------------------------------
# Versioned contract + closed sets
# ------------------------------------------------------------------------------------------------------------

# The Specrew-owned ADAPTER CONTRACT VERSION stamped into every receipt. Bump this when the receipt shape or the
# host adapter's hook contract changes - a receipt written under a DIFFERENT value is contract drift (the reader
# rejects it), so an old receipt can never masquerade as current evidence across a contract change.
# v3 (F-198 iter-005, Prop-145 amendment 2026-07-14): the receipt now records a version_source classification and
# SEPARATES two concepts - HOOK-LIVENESS evidence (host/surface/event/timestamp: the configured hook path was
# OBSERVED firing) from the VERSION DIAGNOSTIC (observed_host_version + version_source='ambient-path-binding': a
# bounded PATH-binding `--version` reading that is NON-AUTHORITATIVE and NEVER promotes health/readiness). Every
# pre-v3 receipt lacks version_source, so it fails the field-set check as malformed and is retired.
$script:SpecrewHookHealthAdapterContractVersion = 3

# Beta2 is CLI-first (FR-050). Receipts describe the CLI surface unless a caller overrides it.
$script:SpecrewHookHealthSurface = 'cli'

# Freshness bound (hours). A receipt older than this is STALE hook-liveness: the configured hook path was observed
# firing THEN, not NOW. This is also how hook-removal / trust-revocation surfaces - no new fire ages the last
# receipt out. Overridable per call so a governed headless run can demand a tighter window.
$script:SpecrewHookHealthDefaultFreshnessHours = 24

# Clock-skew tolerance for FUTURE-dated receipts (review finding f2, run 20260714T172315119): a receipt
# whose timestamp is ahead of now by more than this is NOT plausible clock skew - it is a malformed (or
# tampered, the store is project-writable) record that would otherwise read 'healthy' until its future
# instant plus the freshness window. Beyond the tolerance -> MALFORMED, never healthy/ready.
$script:SpecrewHookHealthClockSkewToleranceMinutes = 5

# The EXACT receipt field set. Sanitized BY CONSTRUCTION: the writer builds a receipt field-by-field from ONLY
# these keys, and the reader REJECTS any receipt whose key-set differs (missing OR extra) as MALFORMED. There is no
# code path by which a prompt, a command argument, an environment value, or a secret can enter a receipt.
# host/surface/event/timestamp = HOOK-LIVENESS evidence; observed_host_version + version_source = VERSION DIAGNOSTIC.
$script:SpecrewHookHealthReceiptFields = @(
    'host'
    'surface'
    'event'
    'observed_host_version'
    'version_source'
    'timestamp'
    'adapter_contract_version'
)

# Closed set: HOOK-LIVENESS status - whether the configured hook path was recently OBSERVED firing. This is
# MONITORING evidence, NOT authenticated: the receipt store is project-writable and the dispatcher can be invoked
# directly, so a same-user process could write a receipt. `healthy` here is operational confidence, never proof of
# the host process. Do not describe a receipt as authenticated or as something a PATH shim/same-user process cannot
# produce.
$script:SpecrewHookLivenessStatusSet = @('healthy', 'stale', 'malformed', 'conflicting', 'absent')

# Closed set: VERSION DIAGNOSTIC status. NEVER promotes hook-liveness or readiness. A 'diagnostic-match' means only
# that SessionStart and the current probe resolved EQUIVALENT reported versions through the AMBIENT command binding.
$script:SpecrewHookVersionStatusSet = @('diagnostic-match', 'diagnostic-drift', 'unavailable', 'untrusted-source')

# The only recognized version-diagnostic source: an ambient PATH-resolved `--version` reading (non-authoritative).
$script:SpecrewHookVersionSource = 'ambient-path-binding'

# Recognized Stop-gate BLOCK envelopes (must mirror the dispatcher's StopBlockShape map + the observed FR-051
# contract): decision:block (claude/codex/copilot), decision:continue (antigravity), followup_message (cursor).
$script:SpecrewHookHealthAcceptedBlockDecisions = @('block', 'continue')

function Get-SpecrewHookHealthAdapterContractVersion {
    # The current Specrew hook-health adapter contract version (the value stamped into new receipts).
    return $script:SpecrewHookHealthAdapterContractVersion
}

function Get-SpecrewHookHealthReceiptFields {
    # The EXACT allowed receipt field set (the sanitization allow-list).
    return @($script:SpecrewHookHealthReceiptFields)
}

function Get-SpecrewHookLivenessStatusSet {
    # The closed HOOK-LIVENESS status set (healthy | stale | malformed | conflicting | absent).
    return @($script:SpecrewHookLivenessStatusSet)
}

function Get-SpecrewHookVersionStatusSet {
    # The closed VERSION-DIAGNOSTIC status set (diagnostic-match | diagnostic-drift | unavailable | untrusted-source).
    return @($script:SpecrewHookVersionStatusSet)
}

# ------------------------------------------------------------------------------------------------------------
# Host CLI version probe (Prop-145 amendment) - a NON-AUTHORITATIVE, NON-PROMOTING version DIAGNOSTIC
# ------------------------------------------------------------------------------------------------------------
#
# WHY (Prop-145, maintainer decision 2026-07-14): no supported host contract exposes a way to identify the host
# executable/version that a project could not also influence - the probe can only resolve the host command through
# the AMBIENT PATH. So this probe is a DIAGNOSTIC, labeled source 'ambient-path-binding': the `--version` a project
# could equally influence by prepending a shim. It is NON-AUTHORITATIVE and NEVER promotes hook-liveness or
# readiness. Both the WRITE side (the dispatcher, at SessionStart ONLY) and the READ side (the doctor's per-host
# boundary) obtain it through THIS one probe: resolve the host command on PATH, run its fixed host-declared version
# argument SHELL-SAFE + cross-platform (a native binary or shebang script is exec'd DIRECTLY with an argument vector
# - shell-free on every OS; a Windows .cmd/.bat shim, the only interpreter-mediated case, uses the System32 cmd.exe
# with an injection-guarded path), byte-cap the output (bounds memory), and NORMALIZE stdout to the tool's
# self-reported version line. A 'match' between the SessionStart reading and a later probe means only that both
# resolved EQUIVALENT reported versions through the ambient command binding. Any failure (no spec, unresolved
# executable, launch failure, timeout, non-zero exit, oversized/empty/ambiguous/malformed output) fails CLOSED to
# 'unknown'. No user path and no env value is ever persisted.

# The CLI-first gated hosts (FR-050) and the fixed, single version argument each exposes. An unlisted host has no
# probe spec, so its probe fails to 'unknown' (unverified) - support is never assumed.
$script:SpecrewHostVersionProbeSpec = @{
    claude  = @{ command = 'claude';  args = @('--version') }
    codex   = @{ command = 'codex';   args = @('--version') }
    copilot = @{ command = 'copilot'; args = @('--version') }
}

# Byte (char) cap for a --version probe's captured stdout AND stderr - bounds MEMORY, not just time (Prop-145
# finding 1). A real `--version` prints a few bytes; anything past this cap is a misbehaving / hostile process, so
# the probe FAILS CLOSED (-> unknown -> unverified). The pipe keeps draining past the cap (discarded) so the child
# never blocks; NOTHING is written to disk.
$script:SpecrewHostVersionProbeMaxOutputChars = 8192

function Get-SpecrewHostVersionProbeSpec {
    # The probe spec for a host key (a COPY), or $null if the host has no spec. Read-only accessor.
    param([Parameter(Mandatory)][string]$HostName)
    $key = ConvertTo-SpecrewHookHealthToken -Value $HostName
    if (-not $script:SpecrewHostVersionProbeSpec.ContainsKey($key)) { return $null }
    $spec = $script:SpecrewHostVersionProbeSpec[$key]
    return [pscustomobject]@{ host = $key; command = [string]$spec.command; args = @($spec.args) }
}

function ConvertTo-SpecrewNormalizedVersionLine {
    # Normalize raw `--version` stdout to a single, comparison-stable version line (the tool's self-reported
    # identity+version). Rules: drop blank lines; require EXACTLY ONE line bearing a dotted-numeric token
    # (\d+\.\d+...) - zero = malformed, more than one = AMBIGUOUS - then return that line sanitized (control chars
    # stripped, whitespace collapsed, printable-ASCII, capped). Empty string on ANY failure. Applied IDENTICALLY on
    # the write (SessionStart) and read (doctor/preflight) sides, so the same CLI yields the same token on both and
    # a match is meaningful. Ambiguity fails CLOSED to '' (-> unknown -> unverified) - never a guessed version.
    param([AllowNull()][string]$Stdout)
    if ([string]::IsNullOrWhiteSpace($Stdout)) { return '' }
    $lines = @($Stdout -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
    if ($lines.Count -eq 0) { return '' }
    $versionLines = @($lines | Where-Object { $_ -match '\d+\.\d+' })
    if ($versionLines.Count -ne 1) { return '' }   # 0 -> malformed, >1 -> ambiguous; both fail closed
    $line = (($versionLines[0] -replace '[\x00-\x1F\x7F]+', ' ') -replace '\s{2,}', ' ').Trim()
    if ($line.Length -gt 80) { $line = $line.Substring(0, 80).Trim() }
    if ($line -notmatch '^[\x20-\x7E]+$' -or $line -notmatch '\d+\.\d+') { return '' }
    return $line
}

function Invoke-SpecrewBoundedVersionProcess {
    # Run a RESOLVED executable with a fixed argument VECTOR, bounded by a timeout, capturing stdout. SHELL-SAFE
    # (FR-053a) + CROSS-PLATFORM:
    #   * A NATIVE executable image (Windows .exe) OR ANY POSIX binary / shebang script (Linux/macOS) is invoked
    #     DIRECTLY (UseShellExecute=$false, FileName=the resolved path, args as an ArgumentList VECTOR). The OS
    #     execs it - a shebang is honored by the KERNEL, never by a shell WE spawn - so there is NO shell process in
    #     the invocation and NO shell-string is built. This is the ONLY path on non-Windows, and the path Windows
    #     .exe hosts (codex/claude here) take: genuinely shell-free.
    #   * A Windows .cmd/.bat shim (e.g. an npm-installed CLI) is the ONE case the OS cannot exec directly - only
    #     cmd.exe interprets it - and it is WINDOWS-ONLY (guarded on $onWindows; a POSIX shim is a shebang script the
    #     kernel execs above). It is hardened on BOTH the interpreter and the argument:
    #       - TRUSTED INTERPRETER: cmd.exe is resolved from the OS system directory ([Environment]::SystemDirectory,
    #         the Win32 GetSystemDirectory) - NOT the mutable %ComSpec%/%SystemRoot% env vars and NOT PATH - so a
    #         caller controlling the inherited environment cannot substitute an arbitrary executable; fail-closed if
    #         the trusted cmd.exe is absent.
    #       - INJECTION-SAFE ARGUMENT: the resolved shim path is REFUSED if it bears any cmd expansion/operator
    #         metacharacter (%, !, &, ^, |, <, >, ") - a legitimate install path never has one - so no untrusted
    #         content reaches the interpreter, and the command line is `/d /c "<refused-safe path>" <fixed args>`.
    #     No untrusted input reaches a shell and the interpreter is trusted; both surfaces are FALSIFIED by test.
    # Returns { ok; stdout; problem }. Never throws; a hung probe is killed (tree) on timeout.
    param(
        [Parameter(Mandatory)][string]$ExecutablePath,
        [string[]]$Arguments = @('--version'),
        [int]$TimeoutSeconds = 6
    )
    $out = [ordered]@{ ok = $false; stdout = ''; problem = $null }
    $proc = $null
    try {
        $onWindows = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)
        $psi = [System.Diagnostics.ProcessStartInfo]::new()
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.CreateNoWindow = $true
        $ext = [System.IO.Path]::GetExtension($ExecutablePath).ToLowerInvariant()
        if ($onWindows -and ($ext -eq '.cmd' -or $ext -eq '.bat')) {
            # INJECTION GUARD: refuse a shim path bearing any cmd expansion/operator metacharacter, so nothing
            # untrusted can reach the interpreter (the fixed --version args carry none). A refused path -> unknown.
            if ($ExecutablePath -match '[%!&^|<>"]') {
                $out.problem = 'resolved shim path contains a shell metacharacter; refused (injection guard)'
                return [pscustomobject]$out
            }
            # TRUSTED INTERPRETER: bind cmd.exe to the OS command processor in the system directory, resolved via the
            # Win32 API ([Environment]::SystemDirectory -> GetSystemDirectory, NOT the mutable %ComSpec%/%SystemRoot%
            # env vars and NOT PATH). A caller/project that controls the inherited environment must NOT be able to
            # substitute an arbitrary executable for the interpreter (which would run attacker code during
            # SessionStart / doctor / preflight, and could still emit a matching version so the receipt reads healthy).
            # FAIL CLOSED (-> unknown) if the trusted cmd.exe is not present.
            $sysDir = [System.Environment]::SystemDirectory
            if ([string]::IsNullOrWhiteSpace($sysDir)) { $out.problem = 'cannot resolve the trusted system directory for the shim interpreter'; return [pscustomobject]$out }
            $comspec = Join-Path $sysDir 'cmd.exe'
            if (-not (Test-Path -LiteralPath $comspec -PathType Leaf)) { $out.problem = 'trusted cmd.exe not found in the system directory; shim probe refused'; return [pscustomobject]$out }
            $psi.FileName = $comspec
            # Explicit, self-quoted command line: /d (no AutoRun) /c "<path>" <fixed args>. Built explicitly because
            # .NET ArgumentList's C-runtime quoting does NOT match cmd.exe's rules; the path is refused above if it
            # bears an injection metacharacter, so this raw string has no injection surface.
            $argline = '/d /c "' + $ExecutablePath + '"'
            foreach ($a in $Arguments) { $argline += ' ' + [string]$a }
            $psi.Arguments = $argline
        }
        else {
            $psi.FileName = $ExecutablePath
            foreach ($a in $Arguments) { $psi.ArgumentList.Add([string]$a) }
        }
        $proc = [System.Diagnostics.Process]::Start($psi)

        # BYTE-CAPPED CONCURRENT DRAIN (Prop-145 finding 1): the timeout bounds TIME; this bounds MEMORY. Read BOTH
        # streams concurrently on THIS thread via ReadAsync + WaitAny (no PowerShell scriptblock on a threadpool
        # thread), accumulating at most $cap chars each, then CONTINUING to read + DISCARD so the child never blocks
        # on a full pipe. Nothing is written to disk. Exceeding the cap fails CLOSED. On the deadline the whole
        # descendant tree is killed.
        $cap = $script:SpecrewHostVersionProbeMaxOutputChars
        $deadlineMs = [Math]::Max(1000, $TimeoutSeconds * 1000)
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $sbOut = [System.Text.StringBuilder]::new(); $ovOut = $false; $outEof = $false
        $sbErr = [System.Text.StringBuilder]::new(); $ovErr = $false; $errEof = $false
        $bufOut = [char[]]::new(4096); $bufErr = [char[]]::new(4096)
        $tOut = $proc.StandardOutput.ReadAsync($bufOut, 0, $bufOut.Length)
        $tErr = $proc.StandardError.ReadAsync($bufErr, 0, $bufErr.Length)
        $timedOut = $false
        while (-not ($outEof -and $errEof)) {
            if ($sw.ElapsedMilliseconds -ge $deadlineMs) { $timedOut = $true; break }
            $pending = @(); if (-not $outEof) { $pending += $tOut }; if (-not $errEof) { $pending += $tErr }
            $slice = [int][Math]::Min(200, [Math]::Max(1, $deadlineMs - $sw.ElapsedMilliseconds))
            $idx = [System.Threading.Tasks.Task]::WaitAny([System.Threading.Tasks.Task[]]$pending, $slice)
            if ($idx -lt 0) { continue }
            $done = $pending[$idx]
            if (-not $outEof -and $done -eq $tOut) {
                $n = 0; try { $n = $tOut.GetAwaiter().GetResult() } catch { $n = 0 }
                if ($n -le 0) { $outEof = $true }
                else {
                    if (-not $ovOut) { $room = $cap - $sbOut.Length; if ($room -gt 0) { [void]$sbOut.Append($bufOut, 0, [Math]::Min($n, $room)) }; if ($n -gt $room) { $ovOut = $true } }
                    $tOut = $proc.StandardOutput.ReadAsync($bufOut, 0, $bufOut.Length)
                }
            }
            elseif (-not $errEof -and $done -eq $tErr) {
                $n = 0; try { $n = $tErr.GetAwaiter().GetResult() } catch { $n = 0 }
                if ($n -le 0) { $errEof = $true }
                else {
                    if (-not $ovErr) { $room = $cap - $sbErr.Length; if ($room -gt 0) { [void]$sbErr.Append($bufErr, 0, [Math]::Min($n, $room)) }; if ($n -gt $room) { $ovErr = $true } }
                    $tErr = $proc.StandardError.ReadAsync($bufErr, 0, $bufErr.Length)
                }
            }
        }
        if ($timedOut) {
            try { $proc.Kill($true) } catch { $null = $_ }   # kill the whole descendant tree
            $out.problem = ("version probe timed out after {0}s" -f $TimeoutSeconds)
            return [pscustomobject]$out
        }
        # Both streams reached EOF -> the process finished writing; confirm it exited (bounded) and read the code.
        $graceMs = [int][Math]::Max(0, $deadlineMs - $sw.ElapsedMilliseconds)
        if (-not $proc.WaitForExit($graceMs)) {
            try { $proc.Kill($true) } catch { $null = $_ }
            $out.problem = ("version probe timed out after {0}s" -f $TimeoutSeconds)
            return [pscustomobject]$out
        }
        if ($ovOut -or $ovErr) {
            $out.problem = 'version probe output exceeded the byte cap; refused (fail-closed)'
            return [pscustomobject]$out
        }
        if ($proc.ExitCode -ne 0) {
            $out.problem = ("version probe exited {0}" -f $proc.ExitCode)
            return [pscustomobject]$out
        }
        $out.ok = $true
        $out.stdout = $sbOut.ToString()
        return [pscustomobject]$out
    }
    catch {
        $out.problem = ("version probe launch failed: {0}" -f $_.Exception.Message)
        return [pscustomobject]$out
    }
    finally {
        if ($null -ne $proc) { try { $proc.Dispose() } catch { $null = $_ } }
    }
}

function Get-SpecrewHostVersionProbe {
    # The ONE host-CLI version probe - a NON-AUTHORITATIVE, NON-PROMOTING DIAGNOSTIC. Resolves the host command on
    # the AMBIENT PATH and runs its fixed host-declared version argument bounded + shell-safe / cross-platform
    # (see Invoke-SpecrewBoundedVersionProcess), then normalizes stdout to the tool's self-reported version line.
    # Returns { ok; host; version; source; problem }; source is always 'ambient-path-binding'. ANY failure ->
    # ok=$false, version='unknown'. NEVER throws, NEVER reads an ambient version env value. The production probe uses
    # ONLY the fixed host-declared arguments from the spec; -CommandOverride is the TEST seam that points the probe
    # at a controllable fake executable (still ambient-path-binding). This value NEVER promotes health or readiness.
    param(
        [Parameter(Mandatory)][string]$HostName,
        [int]$TimeoutSeconds = 6,
        [AllowNull()][string]$CommandOverride
    )
    $result = [ordered]@{ ok = $false; host = ''; version = 'unknown'; source = $script:SpecrewHookVersionSource; problem = $null }
    try {
        $key = ConvertTo-SpecrewHookHealthToken -Value $HostName
        $result.host = $key

        # Arguments are ALWAYS the fixed host-declared vector (never caller-controlled): the spec's args, or the
        # standard --version for a CommandOverride test target. No arbitrary arguments are ever accepted.
        $command = $null
        $vargs = @('--version')
        if (-not [string]::IsNullOrWhiteSpace($CommandOverride)) {
            $command = $CommandOverride
        }
        else {
            $spec = Get-SpecrewHostVersionProbeSpec -HostName $key
            if ($null -eq $spec) {
                $result.problem = ("no version-probe spec for host '{0}'" -f $key)
                return [pscustomobject]$result
            }
            $command = $spec.command
            $vargs = @($spec.args)
        }

        # Bind to the RESOLVED executable (requirement 3: not an unqualified ambient command). A path-like override
        # is used as-is; a bare command name resolves via Get-Command (Application only). Unresolved -> unknown.
        $exePath = $null
        if ((($command -match '[\\/]') -or ($command -match '^[A-Za-z]:')) -and (Test-Path -LiteralPath $command -PathType Leaf)) {
            $exePath = (Resolve-Path -LiteralPath $command).Path
        }
        else {
            $cmd = @(Get-Command -Name $command -CommandType Application -ErrorAction SilentlyContinue) | Select-Object -First 1
            if ($null -ne $cmd) { $exePath = [string]$cmd.Source }
        }
        if ([string]::IsNullOrWhiteSpace($exePath)) {
            $result.problem = ("host executable '{0}' did not resolve" -f $command)
            return [pscustomobject]$result
        }

        $raw = Invoke-SpecrewBoundedVersionProcess -ExecutablePath $exePath -Arguments $vargs -TimeoutSeconds $TimeoutSeconds
        if (-not $raw.ok) { $result.problem = $raw.problem; return [pscustomobject]$result }

        $normalized = ConvertTo-SpecrewNormalizedVersionLine -Stdout $raw.stdout
        if ([string]::IsNullOrWhiteSpace($normalized)) {
            $result.problem = 'version output empty / ambiguous / malformed'
            return [pscustomobject]$result
        }
        $result.ok = $true
        $result.version = $normalized
        return [pscustomobject]$result
    }
    catch {
        $result.ok = $false
        $result.version = 'unknown'
        $result.problem = ("probe error: {0}" -f $_.Exception.Message)
        return [pscustomobject]$result
    }
}

# ------------------------------------------------------------------------------------------------------------
# Path helpers
# ------------------------------------------------------------------------------------------------------------

function ConvertTo-SpecrewHookHealthToken {
    # Normalize a host / surface / event value to a filesystem-safe, lowercase token (receipts are keyed into a
    # filename). Empty -> 'unknown' so a token is always well-defined.
    param([AllowNull()][string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return 'unknown' }
    $token = ($Value.Trim().ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
    if ([string]::IsNullOrWhiteSpace($token)) { return 'unknown' }
    return $token
}

function Get-SpecrewHookHealthStorePath {
    # The receipt store: <ProjectRoot>/.specrew/runtime/hook-health/ (the established gitignored runtime dir).
    param([Parameter(Mandatory)][string]$ProjectRoot)
    return (Join-Path $ProjectRoot '.specrew/runtime/hook-health')
}

function Get-SpecrewHookHealthReceiptPath {
    # One receipt file per (host, surface, event): <host>-<surface>-<event>.json under the store.
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][Alias('Host')][string]$HostName,
        [string]$Surface = $script:SpecrewHookHealthSurface,
        [Parameter(Mandatory)][string]$Event
    )
    $file = ('{0}-{1}-{2}.json' -f (ConvertTo-SpecrewHookHealthToken -Value $HostName), (ConvertTo-SpecrewHookHealthToken -Value $Surface), (ConvertTo-SpecrewHookHealthToken -Value $Event))
    return (Join-Path (Get-SpecrewHookHealthStorePath -ProjectRoot $ProjectRoot) $file)
}

# ------------------------------------------------------------------------------------------------------------
# Sanitization + receipt construction (the WRITE side)
# ------------------------------------------------------------------------------------------------------------

function ConvertTo-SpecrewHookHealthSafeString {
    # Bound a scalar destined for a receipt FIELD: strip CR/LF + control chars, collapse whitespace, cap length.
    # This guarantees a field can never smuggle a multi-line prompt, an argument blob, or an environment dump -
    # a defense-in-depth complement to the field-set allow-list (which already forbids extra keys).
    param([AllowNull()][string]$Value, [int]$MaxLength = 200)
    if ([string]::IsNullOrWhiteSpace($Value)) { return '' }
    $clean = ($Value -replace '[\x00-\x1F\x7F]+', ' ').Trim()
    $clean = ($clean -replace '\s{2,}', ' ')
    if ($clean.Length -gt $MaxLength) { $clean = $clean.Substring(0, $MaxLength).Trim() }
    return $clean
}

function New-SpecrewHookHealthReceiptObject {
    # Build the SANITIZED receipt object field-by-field from ONLY the allowed inputs. No parameter here carries a
    # prompt / arg vector / env table / secret, and nothing but these seven fields is ever emitted. host/surface/
    # event/timestamp = HOOK-LIVENESS evidence; observed_host_version + version_source = the VERSION DIAGNOSTIC.
    param(
        [Parameter(Mandatory)][Alias('Host')][string]$HostName,
        [Parameter(Mandatory)][string]$Event,
        [string]$Surface = $script:SpecrewHookHealthSurface,
        [AllowNull()][string]$ObservedHostVersion,
        [AllowNull()][string]$ObservedVersionSource,
        [AllowNull()][int]$AdapterContractVersion,
        [AllowNull()][datetime]$TimestampUtc
    )
    $contract = if ($PSBoundParameters.ContainsKey('AdapterContractVersion')) { [int]$AdapterContractVersion } else { $script:SpecrewHookHealthAdapterContractVersion }
    $ts = if ($PSBoundParameters.ContainsKey('TimestampUtc') -and $null -ne $TimestampUtc) { $TimestampUtc.ToUniversalTime() } else { (Get-Date).ToUniversalTime() }
    $obsVer = ConvertTo-SpecrewHookHealthSafeString -Value $ObservedHostVersion -MaxLength 200
    # version_source: honor an explicit caller value; else default from whether a real version diagnostic was
    # captured ('ambient-path-binding' when a version is present, 'unavailable' when it is 'unknown'/blank).
    $vsource = if ($PSBoundParameters.ContainsKey('ObservedVersionSource') -and -not [string]::IsNullOrWhiteSpace($ObservedVersionSource)) {
        ConvertTo-SpecrewHookHealthSafeString -Value $ObservedVersionSource -MaxLength 40
    }
    elseif ([string]::IsNullOrWhiteSpace($obsVer) -or $obsVer -ieq 'unknown') { 'unavailable' }
    else { $script:SpecrewHookVersionSource }
    return [pscustomobject][ordered]@{
        host                     = ConvertTo-SpecrewHookHealthSafeString -Value $HostName -MaxLength 64
        surface                  = ConvertTo-SpecrewHookHealthSafeString -Value $Surface -MaxLength 32
        event                    = ConvertTo-SpecrewHookHealthSafeString -Value $Event -MaxLength 64
        observed_host_version    = $obsVer
        version_source           = $vsource
        timestamp                = $ts.ToString('o')
        adapter_contract_version = $contract
    }
}

function Write-SpecrewHookHealthReceipt {
    # Record a SANITIZED hook-health receipt from a REAL host-triggered hook fire (SessionStart/Stop). This is
    # provided FOR the hook path to call (and for tests to exercise) - it does NOT edit the protected hook file.
    # Best-effort / fail-open: a receipt-write failure must never break the hook, so it returns $null on failure.
    # On success returns { Path; Receipt }. Sanitized by construction (see New-SpecrewHookHealthReceiptObject).
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][Alias('Host')][string]$HostName,
        [Parameter(Mandatory)][string]$Event,
        [string]$Surface = $script:SpecrewHookHealthSurface,
        [AllowNull()][string]$ObservedHostVersion,
        [AllowNull()][string]$ObservedVersionSource,
        [AllowNull()][int]$AdapterContractVersion,
        [AllowNull()][datetime]$TimestampUtc
    )
    try {
        $builder = @{ HostName = $HostName; Event = $Event; Surface = $Surface }
        if ($PSBoundParameters.ContainsKey('ObservedHostVersion')) { $builder.ObservedHostVersion = $ObservedHostVersion }
        if ($PSBoundParameters.ContainsKey('ObservedVersionSource')) { $builder.ObservedVersionSource = $ObservedVersionSource }
        if ($PSBoundParameters.ContainsKey('AdapterContractVersion')) { $builder.AdapterContractVersion = $AdapterContractVersion }
        if ($PSBoundParameters.ContainsKey('TimestampUtc')) { $builder.TimestampUtc = $TimestampUtc }
        $receipt = New-SpecrewHookHealthReceiptObject @builder

        $path = Get-SpecrewHookHealthReceiptPath -ProjectRoot $ProjectRoot -HostName $HostName -Surface $Surface -Event $Event
        $dir = Split-Path -Parent $path
        if (-not (Test-Path -LiteralPath $dir -PathType Container)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $json = $receipt | ConvertTo-Json -Depth 4 -Compress
        [System.IO.File]::WriteAllText($path, $json, [System.Text.UTF8Encoding]::new($false))
        return [pscustomobject]@{ Path = $path; Receipt = $receipt }
    }
    catch {
        return $null
    }
}

# ------------------------------------------------------------------------------------------------------------
# Receipt reading + classification (the READ side)
# ------------------------------------------------------------------------------------------------------------

function ConvertTo-SpecrewHookHealthUtcInstant {
    # Resolve a receipt timestamp to a timezone-UNAMBIGUOUS UTC [datetime]. This MUST tolerate the value however
    # ConvertFrom-Json handed it back: PowerShell auto-deserializes an ISO-8601 string into a [datetime] whose
    # Kind is Unspecified (the trailing 'Z' is dropped), so a naive [string] re-parse would mis-read it as LOCAL
    # and skew freshness by the runner's UTC offset. So: a [datetime] Kind=Utc is used as-is; Local is converted;
    # Unspecified is treated as UTC (our writer ALWAYS emits a 'Z'/UTC 'o' string, so an unspecified-kind value is
    # a UTC wall-clock that merely lost its Kind); a [DateTimeOffset] uses its UtcDateTime; a raw string is parsed
    # via DateTimeOffset (which honors 'Z'/offset). Throws only on an unparseable string; callers guard.
    param([Parameter(Mandatory)]$Timestamp)
    if ($Timestamp -is [datetime]) {
        $dt = [datetime]$Timestamp
        switch ($dt.Kind) {
            ([System.DateTimeKind]::Utc) { return $dt }
            ([System.DateTimeKind]::Local) { return $dt.ToUniversalTime() }
            default { return [datetime]::SpecifyKind($dt, [System.DateTimeKind]::Utc) }
        }
    }
    if ($Timestamp -is [System.DateTimeOffset]) { return ([System.DateTimeOffset]$Timestamp).UtcDateTime }
    return ([System.DateTimeOffset]::Parse([string]$Timestamp, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind)).UtcDateTime
}

function Read-SpecrewHookHealthReceiptFile {
    # Parse ONE receipt file into { Path; WellFormed; Receipt; Problem }. WELL-FORMED requires: parseable JSON;
    # EXACTLY the allowed field-set (missing OR extra keys -> malformed - an injected/tampered key is a red flag,
    # never silently tolerated); non-empty host/surface/event/observed_host_version/timestamp; a round-trip
    # timestamp; an integer adapter_contract_version. Never throws.
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return [pscustomobject]@{ Path = $Path; WellFormed = $false; Receipt = $null; Problem = 'absent' }
    }
    $raw = $null
    try { $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 } catch { $raw = $null }
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return [pscustomobject]@{ Path = $Path; WellFormed = $false; Receipt = $null; Problem = 'empty-file' }
    }
    $obj = $null
    try { $obj = $raw | ConvertFrom-Json -ErrorAction Stop } catch { $obj = $null }
    if ($null -eq $obj -or $obj -isnot [psobject]) {
        return [pscustomobject]@{ Path = $Path; WellFormed = $false; Receipt = $null; Problem = 'unparseable-json' }
    }

    # Enumerate names via the pipeline (NOT $obj.PSObject.Properties.Name): member-enumeration of .Name on a
    # zero-property object throws under Set-StrictMode -Version Latest.
    $keys = @($obj.PSObject.Properties | ForEach-Object { $_.Name })
    $required = @($script:SpecrewHookHealthReceiptFields)
    $missing = @($required | Where-Object { $keys -notcontains $_ })
    $extra = @($keys | Where-Object { $required -notcontains $_ })
    if ($missing.Count -gt 0 -or $extra.Count -gt 0) {
        return [pscustomobject]@{ Path = $Path; WellFormed = $false; Receipt = $obj; Problem = ('field-set-mismatch (missing=[{0}] extra=[{1}])' -f ($missing -join ','), ($extra -join ',')) }
    }

    foreach ($stringField in @('host', 'surface', 'event', 'observed_host_version', 'version_source', 'timestamp')) {
        if ([string]::IsNullOrWhiteSpace([string]$obj.$stringField)) {
            return [pscustomobject]@{ Path = $Path; WellFormed = $false; Receipt = $obj; Problem = ("empty required field '{0}'" -f $stringField) }
        }
    }

    # Timestamp validity: a value ConvertFrom-Json already typed as [datetime]/[DateTimeOffset] is valid by
    # construction; a raw string must parse invariantly (culture-independent). This avoids a false 'malformed' on
    # a non-en-US runner where [string]$datetime would render in the local culture but be parsed as invariant.
    $tsValue = $obj.timestamp
    $tsValid = ($tsValue -is [datetime]) -or ($tsValue -is [System.DateTimeOffset])
    if (-not $tsValid) {
        $parsedTs = [System.DateTimeOffset]::MinValue
        $tsValid = [System.DateTimeOffset]::TryParse([string]$tsValue, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind, [ref]$parsedTs)
    }
    if (-not $tsValid) {
        return [pscustomobject]@{ Path = $Path; WellFormed = $false; Receipt = $obj; Problem = 'unparseable-timestamp' }
    }

    $parsedContract = 0
    if (-not [int]::TryParse([string]$obj.adapter_contract_version, [ref]$parsedContract)) {
        return [pscustomobject]@{ Path = $Path; WellFormed = $false; Receipt = $obj; Problem = 'non-integer adapter_contract_version' }
    }

    return [pscustomobject]@{ Path = $Path; WellFormed = $true; Receipt = $obj; Problem = $null }
}

function New-SpecrewHookHealthResult {
    # Uniform verdict shape with INDEPENDENT fields (Prop-145): hook_status (liveness) and version_status
    # (diagnostic) are computed and reported separately - version_status NEVER promotes hook_status. Each is a
    # closed-set member. This is the ONLY constructor for a verdict, so the closed sets can never be circumvented.
    param(
        [Parameter(Mandatory)][string]$HostName,
        [Parameter(Mandatory)][string]$Surface,
        [Parameter(Mandatory)][ValidateSet('healthy', 'stale', 'malformed', 'conflicting', 'absent')][string]$HookStatus,
        [Parameter(Mandatory)][ValidateSet('diagnostic-match', 'diagnostic-drift', 'unavailable', 'untrusted-source')][string]$VersionStatus,
        [string]$VersionSource = '',
        [Parameter(Mandatory)][string]$Reason,
        [AllowNull()]$Receipt
    )
    return [pscustomobject][ordered]@{
        host           = $HostName
        surface        = $Surface
        hook_status    = $HookStatus
        version_status = $VersionStatus
        version_source = $VersionSource
        reason         = $Reason
        receipt        = $Receipt
    }
}

function Resolve-SpecrewHookHealth {
    # Classify a host+surface into INDEPENDENT fields (Prop-145): hook_status (LIVENESS - was the configured hook
    # path recently OBSERVED firing) and version_status (a NON-PROMOTING ambient-path-binding version DIAGNOSTIC).
    # version_status NEVER changes hook_status. Returns { host; surface; hook_status; version_status; version_source;
    # reason; receipt }. Receipts are MONITORING evidence, not authenticated (the store is project-writable and the
    # dispatcher can be invoked directly) - `healthy` is operational confidence, never proof of the host process.
    # PURE (no subprocess): the caller may probe the live host and supply -ExpectedHostVersion for the DIAGNOSTIC
    # only. Never throws.
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][Alias('Host')][string]$HostName,
        [string]$Surface = $script:SpecrewHookHealthSurface,
        [AllowNull()][string]$ExpectedHostVersion,           # a current ambient-path-binding reading, for the version DIAGNOSTIC only (never promotes liveness/readiness)
        [AllowNull()][int]$ExpectedAdapterContractVersion,   # defaults to the current adapter contract version
        [int]$FreshnessHours = $script:SpecrewHookHealthDefaultFreshnessHours,
        [AllowNull()][datetime]$Now
    )

    $nowUtc = if ($PSBoundParameters.ContainsKey('Now')) { $Now.ToUniversalTime() } else { (Get-Date).ToUniversalTime() }
    $currentContract = if ($PSBoundParameters.ContainsKey('ExpectedAdapterContractVersion')) { [int]$ExpectedAdapterContractVersion } else { $script:SpecrewHookHealthAdapterContractVersion }
    $store = Get-SpecrewHookHealthStorePath -ProjectRoot $ProjectRoot
    $hostToken = ConvertTo-SpecrewHookHealthToken -Value $HostName
    $surfaceToken = ConvertTo-SpecrewHookHealthToken -Value $Surface

    $files = @()
    if (Test-Path -LiteralPath $store -PathType Container) {
        $pattern = ('{0}-{1}-*.json' -f $hostToken, $surfaceToken)
        $files = @(Get-ChildItem -LiteralPath $store -Filter $pattern -File -ErrorAction SilentlyContinue)
    }

    # ABSENT: no receipt -> the configured hook path was not observed firing here.
    if ($files.Count -eq 0) {
        return New-SpecrewHookHealthResult -HostName $hostToken -Surface $surfaceToken -HookStatus 'absent' -VersionStatus 'unavailable' -VersionSource '' -Reason 'no hook-health receipt (the configured hook path was not observed firing here: not deployed, host never loaded it, or trust revoked with no subsequent fire).' -Receipt $null
    }

    $parsed = @($files | ForEach-Object { Read-SpecrewHookHealthReceiptFile -Path $_.FullName })

    # MALFORMED: any corrupt / tampered / nonconforming receipt (incl. a pre-v3 receipt missing version_source)
    # cannot be read as liveness.
    $malformed = @($parsed | Where-Object { -not $_.WellFormed })
    if ($malformed.Count -gt 0) {
        return New-SpecrewHookHealthResult -HostName $hostToken -Surface $surfaceToken -HookStatus 'malformed' -VersionStatus 'unavailable' -VersionSource '' -Reason ('a hook-health receipt is malformed ({0}); it cannot be read as liveness - re-fire the hook to rewrite it.' -f $malformed[0].Problem) -Receipt $malformed[0].Receipt
    }

    $good = @($parsed | ForEach-Object { $_.Receipt })

    # WRONG-HOST: a well-formed receipt whose host field disagrees with the requested host (tampered / mis-keyed) is
    # internally inconsistent evidence.
    $hostMismatch = @($good | Where-Object { (ConvertTo-SpecrewHookHealthToken -Value ([string]$_.host)) -ne $hostToken })
    if ($hostMismatch.Count -gt 0) {
        return New-SpecrewHookHealthResult -HostName $hostToken -Surface $surfaceToken -HookStatus 'conflicting' -VersionStatus 'unavailable' -VersionSource '' -Reason ("a receipt's host field ('{0}') disagrees with the requested host ('{1}'); the evidence is internally inconsistent." -f ([string]$hostMismatch[0].host), $hostToken) -Receipt $hostMismatch[0]
    }

    # WRONG-CONTRACT: a receipt written under a different adapter contract does not conform to the current contract.
    $contractMismatch = @($good | Where-Object { [int]$_.adapter_contract_version -ne $currentContract })
    if ($contractMismatch.Count -gt 0) {
        return New-SpecrewHookHealthResult -HostName $hostToken -Surface $surfaceToken -HookStatus 'malformed' -VersionStatus 'unavailable' -VersionSource '' -Reason ('adapter-contract drift (receipt={0}, current={1}); the receipt does not conform to the current contract - re-fire the hook to rewrite it.' -f [int]$contractMismatch[0].adapter_contract_version, $currentContract) -Receipt $contractMismatch[0]
    }

    # CONFLICTING: well-formed SessionStart receipts that disagree on the observed version are internally
    # inconsistent evidence about what fired.
    $sessionStart = @($good | Where-Object { ([string]$_.event).Trim().ToLowerInvariant() -eq 'sessionstart' })
    if ($sessionStart.Count -gt 0) {
        $distinctVersions = @($sessionStart | ForEach-Object { ([string]$_.observed_host_version).Trim() } | Sort-Object -Unique)
        if ($distinctVersions.Count -gt 1) {
            return New-SpecrewHookHealthResult -HostName $hostToken -Surface $surfaceToken -HookStatus 'conflicting' -VersionStatus 'unavailable' -VersionSource '' -Reason ('conflicting SessionStart receipts (observed versions=[{0}]); the evidence disagrees with itself.' -f ($distinctVersions -join ' | ')) -Receipt $null
        }
    }

    # HOOK LIVENESS from the freshest well-formed lifecycle receipt (SessionStart OR Stop - both are the configured
    # hook path being OBSERVED firing). Monitoring evidence, not authenticated.
    $repLive = @($good | Sort-Object { ConvertTo-SpecrewHookHealthUtcInstant -Timestamp $_.timestamp } -Descending)[0]
    $ageLive = ($nowUtc - (ConvertTo-SpecrewHookHealthUtcInstant -Timestamp $repLive.timestamp)).TotalHours
    # FUTURE-dated guard (review finding f2, run 20260714T172315119): a negative age beyond the small
    # explicit clock-skew tolerance means the freshest receipt claims to be from the future - under clock
    # skew or a tampered project-writable store that would stay 'healthy' until <future>+freshness. Such a
    # receipt is MALFORMED (never healthy, so never ready); within-tolerance skew still reads normally.
    $skewToleranceHours = $script:SpecrewHookHealthClockSkewToleranceMinutes / 60.0
    $hookStatus = if ($ageLive -lt (-1.0 * $skewToleranceHours)) { 'malformed' } elseif ($ageLive -gt $FreshnessHours) { 'stale' } else { 'healthy' }

    # VERSION DIAGNOSTIC (INDEPENDENT) from the freshest SessionStart receipt - NEVER changes hook_status. A version
    # probe failure leaves this 'unavailable' but does NOT erase the hook-liveness above.
    $versionStatus = 'unavailable'
    $versionSource = ''
    $repSS = $null
    if ($sessionStart.Count -gt 0) {
        $repSS = @($sessionStart | Sort-Object { ConvertTo-SpecrewHookHealthUtcInstant -Timestamp $_.timestamp } -Descending)[0]
        $versionSource = ([string]$repSS.version_source).Trim()
        $obsVer = ([string]$repSS.observed_host_version).Trim()
        if ($versionSource -eq $script:SpecrewHookVersionSource) {
            # A recognized ambient-path-binding reading: compare against the caller's current ambient reading.
            if ([string]::IsNullOrWhiteSpace($obsVer) -or $obsVer -ieq 'unknown') { $versionStatus = 'unavailable' }
            elseif ([string]::IsNullOrWhiteSpace($ExpectedHostVersion)) { $versionStatus = 'unavailable' }
            elseif ($obsVer -eq $ExpectedHostVersion.Trim()) { $versionStatus = 'diagnostic-match' }
            else { $versionStatus = 'diagnostic-drift' }
        }
        elseif ([string]::IsNullOrWhiteSpace($versionSource) -or $versionSource -ieq 'unavailable') {
            # The SessionStart probe captured no version (recorded 'unavailable') - non-promoting, does not erase liveness.
            $versionStatus = 'unavailable'
        }
        else {
            # An unrecognized version_source (tampered / legacy) - never treated as a valid diagnostic.
            $versionStatus = 'untrusted-source'
        }
    }

    $repReceipt = if ($null -ne $repSS) { $repSS } else { $repLive }
    $livePhrase = switch ($hookStatus) {
        'healthy' { ('hook liveness healthy: a fresh, well-formed receipt shows the configured hook path was observed firing {0:N1}h ago (operational monitoring evidence, not authentication)' -f [Math]::Max(0.0, $ageLive)) }
        'stale' { ('hook liveness stale: the freshest receipt is {0:N1}h old (> {1}h); the hook may have stopped firing (removed / trust revoked)' -f $ageLive, $FreshnessHours) }
        'malformed' { ('hook liveness malformed: the freshest receipt is FUTURE-dated by {0:N1}h (beyond the {1}-minute clock-skew tolerance) - not plausible liveness evidence; never healthy or ready' -f (-1.0 * $ageLive), $script:SpecrewHookHealthClockSkewToleranceMinutes) }
        default { ('hook liveness {0}' -f $hookStatus) }
    }
    $verPhrase = switch ($versionStatus) {
        'diagnostic-match' { 'version diagnostic: match (ambient-path-binding, non-authoritative - both readings resolved an equivalent reported version through the ambient command)' }
        'diagnostic-drift' { 'version diagnostic: drift (ambient-path-binding, non-authoritative - the current ambient reading differs from the SessionStart reading)' }
        'untrusted-source' { "version diagnostic: untrusted source (the receipt's version_source is not the recognized ambient-path-binding diagnostic)" }
        default { 'version diagnostic: unavailable (no ambient version reading to compare; non-promoting)' }
    }
    return New-SpecrewHookHealthResult -HostName $hostToken -Surface $surfaceToken -HookStatus $hookStatus -VersionStatus $versionStatus -VersionSource $versionSource -Reason ("{0}. {1}." -f $livePhrase, $verPhrase) -Receipt $repReceipt
}

# ------------------------------------------------------------------------------------------------------------
# Doctor/status renderer (FR-053 reporting)
# ------------------------------------------------------------------------------------------------------------

function Format-SpecrewHookHealthReport {
    # Renderer for the doctor/status surface (called by the protected surface; this file is NOT protected). Given
    # resolved rows, OR a ProjectRoot + host list to resolve, return a deterministic STRING table + a legend showing
    # the INDEPENDENT fields: hook-liveness status and the NON-AUTHORITATIVE version DIAGNOSTIC. Never promotes: it
    # renders exactly what Resolve-SpecrewHookHealth returned. When resolving from a ProjectRoot it performs the
    # ambient version probe per host for the DIAGNOSTIC ONLY (it never affects liveness). Pre-resolved -Rows bypass
    # the probe (the test/inspection seam). Returns a STRING (no console writes).
    param(
        [object[]]$Rows,
        [string]$ProjectRoot,
        [string[]]$Hosts,
        [string]$Surface = $script:SpecrewHookHealthSurface,
        [AllowNull()][datetime]$Now
    )

    $data = @()
    if ($null -ne $Rows -and @($Rows).Count -gt 0) {
        $data = @($Rows)
    }
    elseif (-not [string]::IsNullOrWhiteSpace($ProjectRoot)) {
        # Default to the CLI-first gated hosts (FR-050) when the caller does not name a host set.
        $hostList = if ($null -ne $Hosts -and @($Hosts).Count -gt 0) { @($Hosts) } else { @('claude', 'codex', 'copilot') }
        foreach ($h in $hostList) {
            $resolveArgs = @{ ProjectRoot = $ProjectRoot; HostName = $h; Surface = $Surface }
            if ($PSBoundParameters.ContainsKey('Now')) { $resolveArgs.Now = $Now }
            # Ambient version probe at this doctor boundary -> feeds the version DIAGNOSTIC ONLY (never liveness).
            if (Get-Command -Name 'Get-SpecrewHostVersionProbe' -ErrorAction SilentlyContinue) {
                $probe = Get-SpecrewHostVersionProbe -HostName $h
                if ($null -ne $probe -and $probe.ok -and -not [string]::IsNullOrWhiteSpace([string]$probe.version) -and ([string]$probe.version) -ne 'unknown') {
                    $resolveArgs.ExpectedHostVersion = [string]$probe.version
                }
            }
            $data += (Resolve-SpecrewHookHealth @resolveArgs)
        }
    }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('=== Specrew hook-health evidence (FR-053) ===')
    [void]$sb.AppendLine('Hook liveness is MONITORING evidence: a fresh receipt shows the configured hook path was observed')
    [void]$sb.AppendLine('firing. The receipt store is project-writable, so this is operational confidence, not authentication.')
    [void]$sb.AppendLine('The version is a NON-AUTHORITATIVE ambient-path-binding diagnostic and never promotes liveness/readiness.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine(('  {0,-9} {1,-8} {2,-12} {3,-18} {4}' -f 'HOST', 'SURFACE', 'HOOK', 'VERSION-DIAG', 'SOURCE'))
    [void]$sb.AppendLine(('  {0,-9} {1,-8} {2,-12} {3,-18} {4}' -f '----', '-------', '----', '------------', '------'))
    foreach ($row in $data) {
        $vsrc = if ([string]::IsNullOrWhiteSpace([string]$row.version_source)) { '-' } else { [string]$row.version_source }
        [void]$sb.AppendLine(('  {0,-9} {1,-8} {2,-12} {3,-18} {4}' -f $row.host, $row.surface, $row.hook_status, $row.version_status, $vsrc))
    }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('Hook liveness:  healthy (fresh receipt observed) | stale | malformed | conflicting | absent')
    [void]$sb.AppendLine('Version diag.:  diagnostic-match | diagnostic-drift | unavailable | untrusted-source (never promotes health)')
    return $sb.ToString()
}

# ------------------------------------------------------------------------------------------------------------
# Codex untrusted-headless governance PREFLIGHT (FR-051 / T036)
# ------------------------------------------------------------------------------------------------------------

function Test-SpecrewCodexHeadlessGovernanceReady {
    # PREFLIGHT for an untrusted HEADLESS `codex exec` relying on Specrew governance. Readiness rests on FRESH
    # HOOK-LIVENESS (a recent, well-formed codex/cli receipt) plus the existing Codex config/trust prerequisites -
    # NOT on the version, which is a non-promoting diagnostic. Readiness is OPERATIONAL CONFIDENCE, not tamper-proof
    # host authentication (the receipt store is project-writable and the dispatcher can be invoked directly).
    # Consults the pure Resolve-SpecrewHookHealth for codex/cli. Returns { ready; host; surface; hook_status;
    # version_status; version_source; reason; instruction; receipt }. NEVER writes ~/.codex, NEVER seeds a
    # trusted_hash, NEVER passes --dangerously-bypass-hook-trust.
    #   fresh hook liveness (hook_status==healthy)          -> ready = $true.
    #   missing / stale / malformed / conflicting liveness  -> ready = $false + the actionable instruction.
    # A caller-supplied -ExpectedHostVersion (an ambient reading) populates the version DIAGNOSTIC only; it never
    # changes readiness.
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [AllowNull()][string]$ExpectedHostVersion,
        [int]$FreshnessHours = $script:SpecrewHookHealthDefaultFreshnessHours,
        [AllowNull()][datetime]$Now
    )
    $resolveArgs = @{ ProjectRoot = $ProjectRoot; HostName = 'codex'; Surface = 'cli'; FreshnessHours = $FreshnessHours }
    if ($PSBoundParameters.ContainsKey('ExpectedHostVersion') -and -not [string]::IsNullOrWhiteSpace($ExpectedHostVersion)) { $resolveArgs.ExpectedHostVersion = $ExpectedHostVersion }
    if ($PSBoundParameters.ContainsKey('Now')) { $resolveArgs.Now = $Now }
    $health = Resolve-SpecrewHookHealth @resolveArgs

    $ready = ($health.hook_status -eq 'healthy')
    $instruction = if ($ready) {
        'A fresh codex/cli hook-liveness receipt was observed, so Specrew governance may be relied upon for this run as OPERATIONAL CONFIDENCE - not tamper-proof host authentication (the receipt store is project-writable). Specrew will NOT write Codex''s trust store, NOT seed a trusted_hash, and NOT pass --dangerously-bypass-hook-trust.'
    }
    else {
        ('NOT ready to govern this headless codex run (hook liveness: {0}). Start Codex interactively ONCE (run `codex` in this project), approve the NATIVE Codex hook-trust prompt for the Specrew hook, let a SessionStart hook fire (which records a hook-liveness monitoring receipt), then re-run. Specrew will NOT write Codex''s trust store, NOT seed a trusted_hash, and NOT pass --dangerously-bypass-hook-trust; readiness is operational confidence, not tamper-proof host authentication.' -f $health.hook_status)
    }

    return [pscustomobject][ordered]@{
        ready          = $ready
        host           = 'codex'
        surface        = 'cli'
        hook_status    = $health.hook_status
        version_status = $health.version_status
        version_source = $health.version_source
        reason         = $health.reason
        instruction    = $instruction
        receipt        = $health.receipt
    }
}

# ------------------------------------------------------------------------------------------------------------
# Stop-gate emission fail-open guard (FR-051 / T036 - the malformed-output regression contract)
# ------------------------------------------------------------------------------------------------------------

function Test-SpecrewHookGateEmissionWellFormed {
    # PURE validator for a Stop-hook gate emission. Codex (and copilot) SILENTLY FAIL OPEN on malformed hook stdout
    # (observed FR-051 evidence: non-JSON stdout = clean pass, gate bypassed, no warning). So Specrew's dispatcher
    # MUST emit a well-formed gate envelope or governance is lost with no signal. This encodes what "well-formed"
    # means, so a regression to a malformed emit is caught. Returns { WellFormed; IsBlock; Decision; Reason; Problem }.
    #   {} (empty object)                                   -> WellFormed, allow (IsBlock=$false)
    #   {"decision":"block"|"continue","reason":<non-empty>} -> WellFormed, IsBlock (the force-continue directive)
    #   {"followup_message":<non-empty>}                     -> WellFormed, IsBlock (cursor best-effort)
    #   unparseable / truncated JSON                         -> NOT WellFormed (the fail-open trap Specrew must avoid)
    #   {"decision":"block"} with no reason                  -> WellFormed=$true but IsBlock=$false (degenerate: no directive)
    #   {"continue":false,...} (Codex-manual no-op shape)     -> WellFormed=$true, IsBlock=$false (does NOT gate; must not be emitted to block)
    param([AllowNull()][string]$Json)

    $result = [ordered]@{ WellFormed = $false; IsBlock = $false; Decision = $null; Reason = $null; Problem = $null }

    if ([string]::IsNullOrWhiteSpace($Json)) {
        $result.Problem = 'empty emission'
        return [pscustomobject]$result
    }
    $obj = $null
    try { $obj = $Json | ConvertFrom-Json -ErrorAction Stop } catch { $obj = $null }
    if ($null -eq $obj -or $obj -isnot [psobject]) {
        # The dominant fail-open trap: non-JSON / truncated stdout the host silently ignores.
        $result.Problem = 'unparseable JSON (a host silently fails OPEN on this - governance lost)'
        return [pscustomobject]$result
    }

    # Pipeline enumeration (NOT .Properties.Name) so an empty object {} does not throw under StrictMode Latest.
    $keys = @($obj.PSObject.Properties | ForEach-Object { $_.Name })

    # followup_message envelope (cursor).
    if ($keys -contains 'followup_message') {
        $msg = [string]$obj.followup_message
        if (-not [string]::IsNullOrWhiteSpace($msg)) {
            $result.WellFormed = $true; $result.IsBlock = $true; $result.Reason = $msg
            return [pscustomobject]$result
        }
        $result.WellFormed = $true; $result.Problem = 'followup_message present but empty (no directive)'
        return [pscustomobject]$result
    }

    # decision envelope (claude/codex/copilot/antigravity).
    if ($keys -contains 'decision') {
        $decision = [string]$obj.decision
        $reason = if ($keys -contains 'reason') { [string]$obj.reason } else { $null }
        $result.Decision = $decision
        $result.Reason = $reason
        if ($script:SpecrewHookHealthAcceptedBlockDecisions -contains $decision) {
            if (-not [string]::IsNullOrWhiteSpace($reason)) {
                $result.WellFormed = $true; $result.IsBlock = $true
                return [pscustomobject]$result
            }
            # A block/continue decision WITHOUT a reason is a degenerate emit (a force-continue with no directive).
            $result.WellFormed = $true; $result.IsBlock = $false; $result.Problem = ("decision '{0}' present but no reason (no directive to carry)" -f $decision)
            return [pscustomobject]$result
        }
        # A recognized-but-non-blocking decision value (e.g. antigravity 'allow', or any other) = a valid allow.
        $result.WellFormed = $true; $result.IsBlock = $false
        return [pscustomobject]$result
    }

    # An empty object {} is the canonical ALLOW (non-block Stop). Well-formed, does not gate.
    if ($keys.Count -eq 0) {
        $result.WellFormed = $true; $result.IsBlock = $false
        return [pscustomobject]$result
    }

    # Parses, but is neither a gate envelope nor a clean allow (e.g. the Codex-manual {"continue":false,...} no-op).
    # It would NOT gate - so if Specrew emitted THIS intending to block, the block is silently lost.
    $result.WellFormed = $true; $result.IsBlock = $false; $result.Problem = 'parses but is not a recognized gate envelope (would NOT force-continue; must never be emitted to block)'
    return [pscustomobject]$result
}
