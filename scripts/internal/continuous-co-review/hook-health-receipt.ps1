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
# THE HEALTH RULES (critical - a receipt is `healthy` ONLY when EVERY condition holds):
#   present SessionStart probe + fresh + well-formed + adapter-contract matched + the caller-supplied INDEPENDENT
#     current host version MATCHES the SessionStart-observed version                           -> healthy
#   MISSING (no receipt: never fired / not deployed / trust revoked with no fresh fire)        -> unverified
#   NO SessionStart receipt (only a Stop-class receipt: fired, but no version was probed)      -> unverified
#   UNOBSERVED version (the SessionStart probe failed -> observed_host_version 'unknown'/blank) -> unverified
#   NO current version supplied (caller passed no independently probed version to compare)      -> unverified
#   host-version DRIFT (independently probed current version != SessionStart-observed version)  -> unverified
#   adapter-contract DRIFT (receipt written under a different Specrew adapter contract)         -> unverified
#   STALE (SessionStart receipt older than the freshness bound: trust revoked / hook removed)   -> degraded
#   MALFORMED (unparseable / wrong field-set / empty required field / bad timestamp)            -> degraded
#   CONFLICTING (SessionStart receipts disagree on host version or adapter-contract version)    -> degraded
# MISSING HEALTH IS NEVER `healthy`. Every non-healthy path returns unverified/degraded - the closed status set has
# NO fail-open-to-healthy branch, and NO branch reaches healthy without a live current-version match (NFR-001).
# The observed version is a BOUNDED SessionStart PROBE fact (the host CLI's own --version), NEVER an env value.
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
# host adapter's hook contract changes - a receipt written under a DIFFERENT value is drift (-> unverified), so an
# old receipt can never masquerade as current health across a contract change.
# v2 (F-198 iter-005 false-green fix): observed_host_version is now a BOUNDED SessionStart PROBE fact (the host
# CLI's own self-reported version line), NEVER an ambient env value, and `healthy` REQUIRES an independently probed
# CURRENT version to match it. Every pre-fix v1 receipt (env-sourced / unguarded) is therefore drift -> unverified
# until a fresh SessionStart probe rewrites it - the contract bump alone retires the false-green receipts.
$script:SpecrewHookHealthAdapterContractVersion = 2

# Beta2 is CLI-first (FR-050). Receipts describe the CLI surface unless a caller overrides it.
$script:SpecrewHookHealthSurface = 'cli'

# Freshness bound (hours). A receipt older than this is STALE (-> degraded): it proved the hook fired THEN, not
# that it is firing NOW. This is also how hook-removal / trust-revocation is detected - no new fire ages the last
# receipt out. Overridable per call so a governed headless run can demand a tighter window.
$script:SpecrewHookHealthDefaultFreshnessHours = 24

# The EXACT receipt field set. Sanitized BY CONSTRUCTION: the writer builds a receipt field-by-field from ONLY
# these keys, and the reader REJECTS any receipt whose key-set differs (missing OR extra) as MALFORMED. There is
# no code path by which a prompt, a command argument, an environment value, or a secret can enter a receipt.
$script:SpecrewHookHealthReceiptFields = @(
    'host'
    'surface'
    'event'
    'observed_host_version'
    'timestamp'
    'adapter_contract_version'
)

# The closed health status set. There is NO fourth "assume-healthy" value.
$script:SpecrewHookHealthStatusSet = @('healthy', 'unverified', 'degraded')

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

function Get-SpecrewHookHealthStatusSet {
    # The closed health status set (healthy | unverified | degraded).
    return @($script:SpecrewHookHealthStatusSet)
}

# ------------------------------------------------------------------------------------------------------------
# Host CLI version probe (F-198 iter-005 false-green fix) - the SINGLE source of an observed/current host version
# ------------------------------------------------------------------------------------------------------------
#
# WHY (co-review findings 3 + 5, maintainer decision 2026-07-14): the observed host version must NEVER come from an
# ambient environment value (SPECREW_OBSERVED_HOST_VERSION is gone), and `healthy`/`ready` must NEVER be earned
# without an INDEPENDENT current-version comparison. Both the WRITE side (the dispatcher, at SessionStart ONLY) and
# the READ side (the doctor + the Codex preflight, at their explicit boundary) obtain a version through THIS one
# probe: resolve the canonical host executable, run its fixed version argument SHELL-SAFE + cross-platform (a
# native binary or shebang script is exec'd DIRECTLY with an argument vector - genuinely shell-free on every OS;
# a Windows .cmd/.bat shim, the only interpreter-mediated case, is injection-guarded; never a shell string built
# from untrusted input), bound the time, and NORMALIZE stdout to the tool's own self-reported version line. That
# self-reported line IS the minimum sanitized identity needed for comparison (a tool/version change reports a
# different line -> mismatch -> unverified); no user path and no env value is ever persisted. Any failure
# (no spec, unresolved executable, launch failure, timeout, non-zero exit, empty / ambiguous / malformed output)
# fails to 'unknown' -> unverified. NEVER an ambient shell-string, NEVER an env version, NEVER a promotion without a live match.

# The CLI-first gated hosts (FR-050) and the fixed, single version argument each exposes. An unlisted host has no
# probe spec, so its probe fails to 'unknown' (unverified) - support is never assumed.
$script:SpecrewHostVersionProbeSpec = @{
    claude  = @{ command = 'claude';  args = @('--version') }
    codex   = @{ command = 'codex';   args = @('--version') }
    copilot = @{ command = 'copilot'; args = @('--version') }
}

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
    #     kernel execs above). It is hardened to INJECTION-SAFE: the resolved path is REFUSED if it bears any cmd
    #     expansion/operator metacharacter (%, !, &, ^, |, <, >, ") - a legitimate install path never has one; a
    #     metacharacter path is a PATH-hijack red flag - so no untrusted content can reach the interpreter, and the
    #     command line is `/d /c "<refused-safe path>" <fixed args>` (path always quoted, args the fixed --version).
    #     No untrusted input reaches a shell; the injection surface is FALSIFIED by test (never assumed).
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
            $comspec = $env:ComSpec; if ([string]::IsNullOrWhiteSpace($comspec)) { $comspec = 'cmd.exe' }
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
        $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
        $null = $proc.StandardError.ReadToEndAsync()
        if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) {
            try { $proc.Kill($true) } catch { $null = $_ }
            $out.problem = ("version probe timed out after {0}s" -f $TimeoutSeconds)
            return [pscustomobject]$out
        }
        $stdout = ''
        try { $stdout = $stdoutTask.GetAwaiter().GetResult() } catch { $stdout = '' }
        if ($proc.ExitCode -ne 0) {
            $out.problem = ("version probe exited {0}" -f $proc.ExitCode)
            return [pscustomobject]$out
        }
        $out.ok = $true
        $out.stdout = [string]$stdout
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
    # The ONE host-CLI version probe. Resolves the canonical executable for a HostKind and runs its fixed version
    # argument bounded + shell-safe / cross-platform (see Invoke-SpecrewBoundedVersionProcess), then normalizes stdout to the tool's
    # self-reported version line. Returns { ok; host; version; source; problem }. ANY failure -> ok=$false,
    # version='unknown'. NEVER throws, NEVER reads an ambient version env value. `version` is the ONLY value that
    # can promote health, and it can originate ONLY here. -CommandOverride/-ArgsOverride are the TEST seam (point
    # the probe at a controllable fake executable); production callers pass neither and use the spec.
    param(
        [Parameter(Mandatory)][string]$HostName,
        [int]$TimeoutSeconds = 6,
        [AllowNull()][string]$CommandOverride,
        [AllowNull()][string[]]$ArgsOverride
    )
    $result = [ordered]@{ ok = $false; host = ''; version = 'unknown'; source = 'sessionstart-version-probe'; problem = $null }
    try {
        $key = ConvertTo-SpecrewHookHealthToken -Value $HostName
        $result.host = $key

        $command = $null
        $vargs = @('--version')
        if (-not [string]::IsNullOrWhiteSpace($CommandOverride)) {
            $command = $CommandOverride
            if ($null -ne $ArgsOverride) { $vargs = @($ArgsOverride) }
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
    # prompt / arg vector / env table / secret, and nothing but these six fields is ever emitted (FR-053).
    param(
        [Parameter(Mandatory)][Alias('Host')][string]$HostName,
        [Parameter(Mandatory)][string]$Event,
        [string]$Surface = $script:SpecrewHookHealthSurface,
        [AllowNull()][string]$ObservedHostVersion,
        [AllowNull()][int]$AdapterContractVersion,
        [AllowNull()][datetime]$TimestampUtc
    )
    $contract = if ($PSBoundParameters.ContainsKey('AdapterContractVersion')) { [int]$AdapterContractVersion } else { $script:SpecrewHookHealthAdapterContractVersion }
    $ts = if ($PSBoundParameters.ContainsKey('TimestampUtc') -and $null -ne $TimestampUtc) { $TimestampUtc.ToUniversalTime() } else { (Get-Date).ToUniversalTime() }
    return [pscustomobject][ordered]@{
        host                     = ConvertTo-SpecrewHookHealthSafeString -Value $HostName -MaxLength 64
        surface                  = ConvertTo-SpecrewHookHealthSafeString -Value $Surface -MaxLength 32
        event                    = ConvertTo-SpecrewHookHealthSafeString -Value $Event -MaxLength 64
        observed_host_version    = ConvertTo-SpecrewHookHealthSafeString -Value $ObservedHostVersion -MaxLength 200
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
        [AllowNull()][int]$AdapterContractVersion,
        [AllowNull()][datetime]$TimestampUtc
    )
    try {
        $builder = @{ HostName = $HostName; Event = $Event; Surface = $Surface }
        if ($PSBoundParameters.ContainsKey('ObservedHostVersion')) { $builder.ObservedHostVersion = $ObservedHostVersion }
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

    foreach ($stringField in @('host', 'surface', 'event', 'observed_host_version', 'timestamp')) {
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
    # Uniform health verdict shape. `status` is always a closed-set member; a receipt is attached when one is
    # relevant (the representative / offending receipt). This is the ONLY constructor for a health verdict, so
    # the closed set can never be circumvented.
    param(
        [Parameter(Mandatory)][string]$HostName,
        [Parameter(Mandatory)][string]$Surface,
        [Parameter(Mandatory)][ValidateSet('healthy', 'unverified', 'degraded')][string]$Status,
        [Parameter(Mandatory)][string]$Reason,
        [AllowNull()]$Receipt
    )
    return [pscustomobject][ordered]@{
        host    = $HostName
        surface = $Surface
        status  = $Status
        reason  = $Reason
        receipt = $Receipt
    }
}

function Resolve-SpecrewHookHealth {
    # Classify hook-health for a host+surface from its receipt(s). Returns { host; surface; status; reason; receipt }.
    # `status` is `healthy` ONLY when a SessionStart version-probe receipt is present + fresh + well-formed +
    # adapter-contract matched AND the caller-supplied INDEPENDENT current host version (-ExpectedHostVersion)
    # MATCHES the SessionStart-observed version; EVERY other path returns unverified/degraded (missing health is
    # NEVER healthy, and a missing current version is never defaulted to acceptance). PURE (no subprocess) - the
    # caller probes the live host binding and supplies -ExpectedHostVersion. Never throws.
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][Alias('Host')][string]$HostName,
        [string]$Surface = $script:SpecrewHookHealthSurface,
        [AllowNull()][string]$ExpectedHostVersion,           # REQUIRED for healthy: the independently probed CURRENT host version; absent -> unverified (never defaulted to acceptance)
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

    # 1. MISSING -> unverified. No receipt means the hook never fired here (never deployed, host never loaded it,
    #    or trust was revoked with no subsequent fire). Missing health can NEVER be interpreted as healthy.
    if ($files.Count -eq 0) {
        return New-SpecrewHookHealthResult -HostName $hostToken -Surface $surfaceToken -Status 'unverified' -Reason 'no hook-health receipt (the hook never fired here: not deployed, host never loaded it, or trust revoked). Missing health is never healthy - fire the hook once to record a receipt.' -Receipt $null
    }

    $parsed = @($files | ForEach-Object { Read-SpecrewHookHealthReceiptFile -Path $_.FullName })

    # 2. MALFORMED (any candidate) -> degraded. A corrupt/tampered receipt cannot be read as health.
    $malformed = @($parsed | Where-Object { -not $_.WellFormed })
    if ($malformed.Count -gt 0) {
        return New-SpecrewHookHealthResult -HostName $hostToken -Surface $surfaceToken -Status 'degraded' -Reason ('a hook-health receipt is malformed ({0}); cannot attest health - re-fire the hook to rewrite it.' -f $malformed[0].Problem) -Receipt $malformed[0].Receipt
    }

    $good = @($parsed | ForEach-Object { $_.Receipt })

    # 3. VERSION EVIDENCE COMES FROM THE SessionStart RECEIPT ONLY (F-198 iter-005). The host version is PROBED at
    #    SessionStart; a Stop (or any non-SessionStart) receipt proves the hook FIRED but records version='unknown'
    #    and MUST NOT supply or promote the version fact. So the version verdict is computed from the SessionStart
    #    receipt(s) EXCLUSIVELY - a later Stop can never overwrite or promote the SessionStart-observed version.
    $sessionStart = @($good | Where-Object { ([string]$_.event).Trim().ToLowerInvariant() -eq 'sessionstart' })
    if ($sessionStart.Count -eq 0) {
        return New-SpecrewHookHealthResult -HostName $hostToken -Surface $surfaceToken -Status 'unverified' -Reason 'a hook-health receipt exists but none is a SessionStart version probe (a Stop-only receipt proves the hook fired, not WHICH host version fired it). The version-matched half of healthy cannot be attested - start a fresh session so SessionStart records a bounded host-version probe.' -Receipt $good[0]
    }

    # 3b. CONFLICTING SessionStart receipts -> degraded. Well-formed SessionStart receipts that disagree on the
    #     observed host version or the adapter contract are internally inconsistent evidence (mixed versions).
    $distinctHostVersions = @($sessionStart | ForEach-Object { ([string]$_.observed_host_version).Trim() } | Sort-Object -Unique)
    $distinctContracts = @($sessionStart | ForEach-Object { [int]$_.adapter_contract_version } | Sort-Object -Unique)
    if ($distinctHostVersions.Count -gt 1 -or $distinctContracts.Count -gt 1) {
        return New-SpecrewHookHealthResult -HostName $hostToken -Surface $surfaceToken -Status 'degraded' -Reason ('conflicting SessionStart hook-health receipts (host versions=[{0}], adapter contracts=[{1}]); the version evidence disagrees with itself.' -f ($distinctHostVersions -join ' | '), ($distinctContracts -join ' | ')) -Receipt $null
    }

    # Representative = the freshest SessionStart receipt (all agree on version/contract past 3b). Pass the RAW
    # timestamp value (NOT [string]-cast) so ConvertTo-...UtcInstant sees the [datetime] ConvertFrom-Json produced
    # and treats its unspecified Kind as UTC - a [string] cast here would re-drop the 'Z' and skew freshness.
    $representative = @($sessionStart | Sort-Object { ConvertTo-SpecrewHookHealthUtcInstant -Timestamp $_.timestamp } -Descending)[0]
    $repTs = ConvertTo-SpecrewHookHealthUtcInstant -Timestamp $representative.timestamp

    # 4. ADAPTER-CONTRACT DRIFT -> unverified. The receipt was written under a different Specrew adapter contract
    #    (e.g. a pre-fix v1 env-sourced receipt under the current v2 probe contract - retired as drift).
    if ([int]$representative.adapter_contract_version -ne $currentContract) {
        return New-SpecrewHookHealthResult -HostName $hostToken -Surface $surfaceToken -Status 'unverified' -Reason ('adapter-contract-version drift (receipt={0}, current={1}); the receipt predates the current adapter contract - re-verify by starting a fresh session.' -f [int]$representative.adapter_contract_version, $currentContract) -Receipt $representative
    }

    # 4b. UNOBSERVED HOST VERSION -> unverified. A SessionStart receipt whose observed_host_version is 'unknown' or
    #     blank means the bounded version probe FAILED at SessionStart (unresolved executable / timeout / non-zero
    #     exit / empty / ambiguous / malformed output) - the host-version-matched half of healthy is unverifiable.
    #     Unobserved health is never healthy.
    $observedVersion = ([string]$representative.observed_host_version).Trim()
    if ([string]::IsNullOrWhiteSpace($observedVersion) -or $observedVersion -ieq 'unknown') {
        return New-SpecrewHookHealthResult -HostName $hostToken -Surface $surfaceToken -Status 'unverified' -Reason "the SessionStart hook fired but its bounded host-version probe did not observe a real version (observed_host_version is 'unknown'); the host-version-matched half of healthy cannot be attested - start a fresh session where the host CLI '--version' resolves. Unobserved health is never healthy." -Receipt $representative
    }

    # 5. NO INDEPENDENT CURRENT VERSION -> unverified (F-198 iter-005 finding 5, the false-green this fix closes).
    #    `healthy` REQUIRES an INDEPENDENTLY obtained CURRENT host version: the caller (the doctor / the Codex
    #    preflight) probes the LIVE host binding and passes it as -ExpectedHostVersion to compare against the
    #    SessionStart-observed version. A MISSING expected version is NEVER defaulted to acceptance - a bare receipt
    #    with no live comparison cannot earn healthy. The prior code fell straight through to healthy here.
    if ([string]::IsNullOrWhiteSpace($ExpectedHostVersion)) {
        return New-SpecrewHookHealthResult -HostName $hostToken -Surface $surfaceToken -Status 'unverified' -Reason ("no independently probed CURRENT host version was supplied to compare against the SessionStart-observed version ('{0}'); healthy requires a live current-version match, never a bare receipt. The doctor / Codex preflight must probe the host binding and supply it." -f $observedVersion) -Receipt $representative
    }

    # 6. HOST-VERSION DRIFT -> unverified. The independently probed CURRENT version no longer matches the
    #    SessionStart-observed version (a host upgrade, or a changed executable resolution reporting a new version).
    if ($observedVersion -ne $ExpectedHostVersion.Trim()) {
        return New-SpecrewHookHealthResult -HostName $hostToken -Surface $surfaceToken -Status 'unverified' -Reason ("host-version drift (SessionStart observed '{0}', current probe '{1}'); the recorded session does not attest the current host - re-verify by starting a fresh session." -f $observedVersion, $ExpectedHostVersion.Trim()) -Receipt $representative
    }

    # 7. STALE -> degraded. The SessionStart receipt proved the hook fired THEN, not that it fires NOW (this is also
    #    how a removed hook / revoked trust surfaces: no new session ages the last SessionStart receipt past the bound).
    $ageHours = ($nowUtc - $repTs).TotalHours
    if ($ageHours -gt $FreshnessHours) {
        return New-SpecrewHookHealthResult -HostName $hostToken -Surface $surfaceToken -Status 'degraded' -Reason ('stale SessionStart hook-health receipt (age {0:N1}h > freshness bound {1}h); the hook may have stopped firing (removed / trust revoked) - start a fresh session to refresh.' -f $ageHours, $FreshnessHours) -Receipt $representative
    }

    # 8. HEALTHY - present SessionStart probe + fresh + well-formed + adapter-contract matched + the independently
    #    probed CURRENT version MATCHES the SessionStart-observed version. Only now.
    return New-SpecrewHookHealthResult -HostName $hostToken -Surface $surfaceToken -Status 'healthy' -Reason ("present SessionStart version probe + fresh (age {0:N1}h <= {1}h) + well-formed + adapter-contract matched + current-version match ('{2}')." -f [Math]::Max(0.0, $ageHours), $FreshnessHours, $observedVersion) -Receipt $representative
}

# ------------------------------------------------------------------------------------------------------------
# Doctor/status renderer (FR-053 reporting)
# ------------------------------------------------------------------------------------------------------------

function Format-SpecrewHookHealthReport {
    # Renderer for the doctor/status surface (called by the protected surface; this file is NOT protected). Given
    # resolved rows, OR a ProjectRoot + host list to resolve, return a deterministic STRING table + a legend.
    # Never healthy-washes: it renders exactly the status Resolve-SpecrewHookHealth returned. When resolving from a
    # ProjectRoot it INDEPENDENTLY probes each host's live version at this explicit boundary and passes it as the
    # expected current version (finding 5) - a host is healthy only if its live version matches its SessionStart
    # receipt. Pre-resolved -Rows bypass the probe (the test/inspection seam). Returns a STRING (no console writes).
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
            # Independently probe the LIVE host version at this explicit doctor/status boundary (finding 5) and pass
            # it as the expected current version. A failed / 'unknown' probe passes nothing -> the resolver returns
            # unverified (never healthy without a live current-version match).
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
    [void]$sb.AppendLine('A deployed hook config is NOT proof the host loaded it. Health = a REAL host-fired receipt,')
    [void]$sb.AppendLine('sanitized (host; surface; event; observed host version; timestamp; adapter contract version).')
    [void]$sb.AppendLine('Missing / stale / conflicting / malformed / drifted evidence is unverified/degraded - NEVER healthy.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine(('  {0,-9} {1,-8} {2,-11} {3}' -f 'HOST', 'SURFACE', 'STATUS', 'REASON'))
    [void]$sb.AppendLine(('  {0,-9} {1,-8} {2,-11} {3}' -f '----', '-------', '------', '------'))
    foreach ($row in $data) {
        [void]$sb.AppendLine(('  {0,-9} {1,-8} {2,-11} {3}' -f $row.host, $row.surface, $row.status, $row.reason))
    }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('Statuses:')
    [void]$sb.AppendLine('  healthy     - a present + fresh + well-formed receipt matching the current host/adapter contract')
    [void]$sb.AppendLine('  unverified  - no receipt, or host-version / adapter-contract drift (missing health is never healthy)')
    [void]$sb.AppendLine('  degraded    - a stale, malformed, or conflicting receipt (evidence exists but cannot attest health)')
    return $sb.ToString()
}

# ------------------------------------------------------------------------------------------------------------
# Codex untrusted-headless governance PREFLIGHT (FR-051 / T036)
# ------------------------------------------------------------------------------------------------------------

function Test-SpecrewCodexHeadlessGovernanceReady {
    # Before an untrusted HEADLESS `codex exec` relies on Specrew governance, PREFLIGHT the trusted/observed
    # hook-health state. It INDEPENDENTLY probes the live codex version ONCE at this explicit preflight boundary (a
    # bounded probe here is allowed; only a per-Stop probe was rejected) and passes it as the expected current
    # version, then consults the pure Resolve-SpecrewHookHealth for codex/cli. Returns
    # { ready; host; surface; status; reason; instruction; receipt }.
    #   healthy (present SessionStart probe + fresh + matched + live version MATCHES) -> ready = $true.
    #   anything else (incl. a failed live probe)                                     -> ready = $false + instruction.
    # This function NEVER writes ~/.codex, NEVER seeds a trusted_hash, NEVER passes --dangerously-bypass-hook-trust,
    # and NEVER reports ready without a current receipt whose observed version matches the live codex. NOT governed.
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [AllowNull()][string]$ExpectedHostVersion,
        [int]$FreshnessHours = $script:SpecrewHookHealthDefaultFreshnessHours,
        [AllowNull()][datetime]$Now
    )
    # The independently obtained CURRENT codex version to compare against the SessionStart-observed version
    # (finding 5): honor an explicit caller value (test seam), else probe the LIVE codex binding ONCE here. A
    # FAILED probe leaves $expected blank -> the resolver returns unverified -> NOT ready (never defaulted to accept).
    $expected = $null
    $probeProblem = $null
    if ($PSBoundParameters.ContainsKey('ExpectedHostVersion') -and -not [string]::IsNullOrWhiteSpace($ExpectedHostVersion)) {
        $expected = $ExpectedHostVersion.Trim()
    }
    elseif (Get-Command -Name 'Get-SpecrewHostVersionProbe' -ErrorAction SilentlyContinue) {
        $probe = Get-SpecrewHostVersionProbe -HostName 'codex'
        if ($null -ne $probe -and $probe.ok) { $expected = [string]$probe.version }
        elseif ($null -ne $probe) { $probeProblem = [string]$probe.problem }
        else { $probeProblem = 'probe unavailable' }
    }
    else { $probeProblem = 'probe unavailable' }

    $resolveArgs = @{ ProjectRoot = $ProjectRoot; HostName = 'codex'; Surface = 'cli'; FreshnessHours = $FreshnessHours }
    if (-not [string]::IsNullOrWhiteSpace($expected)) { $resolveArgs.ExpectedHostVersion = $expected }
    if ($PSBoundParameters.ContainsKey('Now')) { $resolveArgs.Now = $Now }
    $health = Resolve-SpecrewHookHealth @resolveArgs

    $ready = ($health.status -eq 'healthy')
    $instruction = if ($ready) {
        'A current trusted/observed SessionStart hook-health receipt exists for codex/cli and the live codex version matches it; headless governance may be relied upon for this run.'
    }
    elseif ([string]::IsNullOrWhiteSpace($expected)) {
        ("NOT ready: could not independently probe the current codex version ({0}), so the SessionStart-observed version cannot be confirmed current. Ensure the codex CLI is installed and `codex --version` resolves, then re-run. Specrew will NOT write Codex's trust store, NOT seed a trusted_hash, and NOT pass --dangerously-bypass-hook-trust." -f $(if ([string]::IsNullOrWhiteSpace($probeProblem)) { 'probe unavailable' } else { $probeProblem }))
    }
    else {
        'NOT ready to govern this headless codex run. Start Codex interactively ONCE (run `codex` in this project), approve the NATIVE Codex hook-trust prompt for the Specrew hook, let a SessionStart hook fire (which records a bounded host-version probe receipt), then re-run. Specrew will NOT write Codex''s trust store, NOT seed a trusted_hash, and NOT pass --dangerously-bypass-hook-trust; without a current receipt whose observed version matches the live codex this run must NOT proceed as governed.'
    }

    return [pscustomobject][ordered]@{
        ready       = $ready
        host        = 'codex'
        surface     = 'cli'
        status      = $health.status
        reason      = $health.reason
        instruction = $instruction
        receipt     = $health.receipt
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
