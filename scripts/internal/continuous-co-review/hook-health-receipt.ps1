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
#   present + fresh + well-formed + host-version-matched + adapter-contract-version-matched  -> healthy
#   MISSING (no receipt: never fired / not deployed / trust revoked with no fresh fire)      -> unverified
#   host-version DRIFT (observed host version no longer matches the receipt)                 -> unverified
#   adapter-contract DRIFT (receipt written under a different Specrew adapter contract)       -> unverified
#   STALE (older than the freshness bound: e.g. trust revoked / hook removed -> no new fire) -> degraded
#   MALFORMED (unparseable / wrong field-set / empty required field / bad timestamp)          -> degraded
#   CONFLICTING (two well-formed receipts disagree on host or adapter-contract version)       -> degraded
# MISSING HEALTH IS NEVER `healthy`. Every non-healthy path returns unverified/degraded - the closed status set
# has NO fail-open-to-healthy branch. This is the false-green this feature exists to prevent (NFR-001).
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
$script:SpecrewHookHealthAdapterContractVersion = 1

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
    # `status` is `healthy` ONLY when a receipt is present + fresh + well-formed + host/adapter-contract matched;
    # EVERY other path returns unverified/degraded (missing health is NEVER healthy). Never throws.
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][Alias('Host')][string]$HostName,
        [string]$Surface = $script:SpecrewHookHealthSurface,
        [AllowNull()][string]$ExpectedHostVersion,           # if supplied, a receipt observing a different version is drift
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

    # 3. CONFLICTING -> degraded. Well-formed receipts that disagree on host version or adapter-contract version
    #    mean the evidence is internally inconsistent (mixed host versions / contracts) - not attestable.
    $distinctHostVersions = @($good | ForEach-Object { ([string]$_.observed_host_version).Trim() } | Sort-Object -Unique)
    $distinctContracts = @($good | ForEach-Object { [int]$_.adapter_contract_version } | Sort-Object -Unique)
    if ($distinctHostVersions.Count -gt 1 -or $distinctContracts.Count -gt 1) {
        return New-SpecrewHookHealthResult -HostName $hostToken -Surface $surfaceToken -Status 'degraded' -Reason ('conflicting hook-health receipts (host versions=[{0}], adapter contracts=[{1}]); the evidence disagrees with itself.' -f ($distinctHostVersions -join ' | '), ($distinctContracts -join ' | ')) -Receipt $null
    }

    # Representative = the freshest well-formed receipt (all agree on version/contract past step 3). Pass the RAW
    # timestamp value (NOT [string]-cast) so ConvertTo-...UtcInstant sees the [datetime] ConvertFrom-Json produced
    # and treats its unspecified Kind as UTC - a [string] cast here would re-drop the 'Z' and skew freshness.
    $representative = @($good | Sort-Object { ConvertTo-SpecrewHookHealthUtcInstant -Timestamp $_.timestamp } -Descending)[0]
    $repTs = ConvertTo-SpecrewHookHealthUtcInstant -Timestamp $representative.timestamp

    # 4. ADAPTER-CONTRACT DRIFT -> unverified. The receipt was written under a different Specrew adapter contract.
    if ([int]$representative.adapter_contract_version -ne $currentContract) {
        return New-SpecrewHookHealthResult -HostName $hostToken -Surface $surfaceToken -Status 'unverified' -Reason ('adapter-contract-version drift (receipt={0}, current={1}); the receipt predates the current adapter contract - re-verify by firing the hook.' -f [int]$representative.adapter_contract_version, $currentContract) -Receipt $representative
    }

    # 5. HOST-VERSION DRIFT -> unverified. The currently observed host version no longer matches the receipt.
    if (-not [string]::IsNullOrWhiteSpace($ExpectedHostVersion)) {
        if (([string]$representative.observed_host_version).Trim() -ne $ExpectedHostVersion.Trim()) {
            return New-SpecrewHookHealthResult -HostName $hostToken -Surface $surfaceToken -Status 'unverified' -Reason ("host-version drift (receipt observed '{0}', now '{1}'); the prior fire does not attest the current host - re-verify by firing the hook." -f ([string]$representative.observed_host_version).Trim(), $ExpectedHostVersion.Trim()) -Receipt $representative
        }
    }

    # 6. STALE -> degraded. The receipt proved the hook fired THEN, not that it fires NOW (this is also how a
    #    removed hook / revoked trust surfaces: no new fire ages the last receipt past the bound).
    $ageHours = ($nowUtc - $repTs).TotalHours
    if ($ageHours -gt $FreshnessHours) {
        return New-SpecrewHookHealthResult -HostName $hostToken -Surface $surfaceToken -Status 'degraded' -Reason ('stale hook-health receipt (age {0:N1}h > freshness bound {1}h); the hook may have stopped firing (removed / trust revoked) - fire it again to refresh.' -f $ageHours, $FreshnessHours) -Receipt $representative
    }

    # 7. HEALTHY - and only now.
    return New-SpecrewHookHealthResult -HostName $hostToken -Surface $surfaceToken -Status 'healthy' -Reason ("present + fresh (age {0:N1}h <= {1}h) + well-formed + host/adapter-contract matched." -f [Math]::Max(0.0, $ageHours), $FreshnessHours) -Receipt $representative
}

# ------------------------------------------------------------------------------------------------------------
# Doctor/status renderer (FR-053 reporting)
# ------------------------------------------------------------------------------------------------------------

function Format-SpecrewHookHealthReport {
    # Renderer for the doctor/status surface (called by the protected surface; this file is NOT protected). Given
    # resolved rows, OR a ProjectRoot + host list to resolve, return a deterministic STRING table + a legend.
    # Never healthy-washes: it renders exactly the status Resolve-SpecrewHookHealth returned. Returns a STRING
    # (testable; no console writes).
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
    # Before an untrusted HEADLESS `codex exec` relies on Specrew governance, PREFLIGHT the expected trusted/observed
    # hook-health state. Consults Resolve-SpecrewHookHealth for codex/cli ONLY (read-only). Returns
    # { ready; host; surface; status; reason; instruction; receipt }.
    #   healthy receipt (present + fresh + matched) -> ready = $true  (governance may be relied upon this run).
    #   anything else                               -> ready = $false + the actionable instruction.
    # This function NEVER writes ~/.codex, NEVER seeds a trusted_hash, NEVER passes --dangerously-bypass-hook-trust,
    # and NEVER reports ready on a missing/stale/malformed/drifted receipt. No current receipt = NOT governed.
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [AllowNull()][string]$ExpectedHostVersion,
        [int]$FreshnessHours = $script:SpecrewHookHealthDefaultFreshnessHours,
        [AllowNull()][datetime]$Now
    )
    $resolveArgs = @{ ProjectRoot = $ProjectRoot; HostName = 'codex'; Surface = 'cli'; FreshnessHours = $FreshnessHours }
    if ($PSBoundParameters.ContainsKey('ExpectedHostVersion')) { $resolveArgs.ExpectedHostVersion = $ExpectedHostVersion }
    if ($PSBoundParameters.ContainsKey('Now')) { $resolveArgs.Now = $Now }
    $health = Resolve-SpecrewHookHealth @resolveArgs

    $ready = ($health.status -eq 'healthy')
    $instruction = if ($ready) {
        'A current trusted/observed hook-health receipt exists for codex/cli; headless governance may be relied upon for this run.'
    }
    else {
        'NOT ready to govern this headless codex run. Start Codex interactively ONCE (run `codex` in this project), approve the NATIVE Codex hook-trust prompt for the Specrew hook, let a SessionStart/Stop hook fire (which records a hook-health receipt), then re-run. Specrew will NOT write Codex''s trust store, NOT seed a trusted_hash, and NOT pass --dangerously-bypass-hook-trust; without a current receipt this run must NOT proceed as governed.'
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
