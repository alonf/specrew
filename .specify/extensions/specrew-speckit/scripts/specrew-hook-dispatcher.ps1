# SpecrewHookDispatcher (Feature 171, FR-008/FR-012; T006 core).
# THE single Specrew-registered handler per bound host event. Host hook configs
# register exactly one entry per event pointing here; every Specrew mechanism
# that wants to ride host events is a PROVIDER REGISTRY ROW in refocus-scopes.json
# — never a second registration on the host settings surface (ownership rule).
#
# Contract:
#   -Event <name>      host-neutral event name (SessionStart | PostToolUse | PreToolUse)
#   stdin              host event JSON (Claude shape: {session_id, source, tool_name, ...})
#   stdout             injection output, shaped per event (plain for SessionStart;
#                      hookSpecificOutput JSON for PostToolUse; permissionDecision
#                      JSON for PreToolUse gate providers — DORMANT seat, F-165)
#   exit code          ALWAYS 0 — a refocus failure may never block a session (P1).
#
# Fail-open doctrine: session-blocking failures are forbidden; injection failures
# degrade to silence + one visible stderr WARN ("fail-open for the session,
# fail-quiet-but-loud-once for the automation"). Gate providers fail OPEN to allow.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Event,
    [string]$EventJson,
    [int]$ProviderTimeoutSeconds = 20
)

# KILL SWITCH FIRST (FR-008): this check must precede ANY logic that could itself
# fail — a kill switch placed after catalog/state parsing never gets reached when
# the bug is in catalog/state parsing.
if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_REFOCUS_DISABLE)) { exit 0 }

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Banner = '[specrew-refocus]'

function Write-DispatcherWarn {
    param([string]$Code, [string]$Message)
    [Console]::Error.WriteLine(("{0} WARN {1} {2}" -f $script:Banner, $Code, $Message))
}

function Get-DispatcherProjectRoot {
    $candidate = (Get-Location).Path
    while (-not [string]::IsNullOrWhiteSpace($candidate)) {
        if (Test-Path -LiteralPath (Join-Path $candidate '.specrew') -PathType Container) { return $candidate }
        $parent = Split-Path -Parent $candidate
        if ($parent -eq $candidate) { break }
        $candidate = $parent
    }
    return $null
}

function Get-SanitizedSessionId {
    param([AllowNull()][string]$RawSessionId)
    # Security control (lens 5): the session id becomes part of a FILENAME — strip
    # everything outside [a-zA-Z0-9-] so a hostile id cannot traverse paths.
    if ([string]::IsNullOrWhiteSpace($RawSessionId)) { return 'unknown' }
    $clean = ($RawSessionId -replace '[^a-zA-Z0-9-]', '')
    if ([string]::IsNullOrWhiteSpace($clean)) { return 'unknown' }
    return $clean
}

function Get-DispatcherCatalog {
    param([string]$ProjectRoot)
    foreach ($path in @(
            (Join-Path $ProjectRoot '.specify/extensions/specrew-speckit/refocus-scopes.json'),
            (Join-Path $ProjectRoot 'extensions/specrew-speckit/refocus-scopes.json')
        )) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
        try { return (Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json) }
        catch {
            Write-DispatcherWarn -Code 'CATALOG_SCHEMA' -Message ("catalog unreadable at {0}; automation quiet this event" -f $path)
            return $null
        }
    }
    return $null
}

function Resolve-ProviderCommandPath {
    param([string]$ProjectRoot, [string]$Command)
    # Security control (lens 5 / FR-004): provider commands MUST resolve under the
    # project's deployed extension tree — an out-of-tree command is refused.
    $deployedDir = Join-Path $ProjectRoot '.specify/extensions/specrew-speckit/scripts'
    $candidate = Join-Path $deployedDir (Split-Path -Leaf $Command)
    if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    # Self-host fallback: the Specrew repo's own internal scripts dir.
    $selfHost = Join-Path $ProjectRoot 'scripts/internal'
    $candidate = Join-Path $selfHost (Split-Path -Leaf $Command)
    if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    return $null
}

function Invoke-ProviderProcess {
    param(
        [string]$CommandPath,
        [string[]]$CommandArgs,
        [string]$WorkingDirectory,
        [int]$TimeoutSeconds
    )
    # Child process: provider scripts use `exit` (their CLI contract), which would
    # terminate an in-process caller. Timeout enforced per provider (C3).
    $stdoutPath = [System.IO.Path]::GetTempFileName()
    $stderrPath = [System.IO.Path]::GetTempFileName()
    try {
        $proc = Start-Process -FilePath 'pwsh' `
            -ArgumentList (@('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $CommandPath) + $CommandArgs) `
            -WorkingDirectory $WorkingDirectory -PassThru -NoNewWindow `
            -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
        if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) {
            try { $proc.Kill() } catch { }
            return @{ TimedOut = $true; ExitCode = -1; StdOut = ''; StdErr = '' }
        }
        return @{
            TimedOut = $false
            ExitCode = $proc.ExitCode
            StdOut   = (Get-Content -LiteralPath $stdoutPath -Raw -ErrorAction SilentlyContinue) ?? ''
            StdErr   = (Get-Content -LiteralPath $stderrPath -Raw -ErrorAction SilentlyContinue) ?? ''
        }
    }
    finally {
        Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
    }
}

function Get-RefocusProviderArgs {
    param([string]$EventName, [AllowNull()][string]$Source)
    # RefocusProvider routing (FR-009 surface; B3 state-diff lands in T007):
    #   SessionStart source: compact            -> B1 (general + current stage)
    #   SessionStart source: startup|resume|clear -> B2 (launch grounding)
    #   PostToolUse                              -> B3 (boundary-cross; T007 gates
    #                                               this behind the state-diff)
    switch ($EventName) {
        'SessionStart' {
            if ($Source -eq 'compact') { return @('--trigger', 'b1') }
            return @('--trigger', 'b2')
        }
        'PostToolUse' { return @('--trigger', 'b3') }
        default { return $null }
    }
}

function Write-InjectionOutput {
    param([string]$EventName, [string]$Payload)
    # Per-host event output shaping (C2, Claude shapes; other hosts normalize in
    # their bindings via the research matrix):
    #   SessionStart -> plain stdout is added to context
    #   PostToolUse  -> hookSpecificOutput.additionalContext JSON
    if ($EventName -eq 'PostToolUse') {
        @{ hookSpecificOutput = @{ hookEventName = 'PostToolUse'; additionalContext = $Payload } } | ConvertTo-Json -Depth 4 -Compress | Write-Output
    }
    else {
        Write-Output $Payload
    }
}

# ---------------------------------------------------------------------------
# Main — every failure path inside this try lands on exit 0 (P1).
# ---------------------------------------------------------------------------
try {
    # Self-gate: a stray hook firing outside a Specrew project is a silent no-op.
    $projectRoot = Get-DispatcherProjectRoot
    if ($null -eq $projectRoot) { exit 0 }

    # Host event JSON: -EventJson (tests/bindings) or stdin (Claude hooks).
    $rawEvent = $EventJson
    if ([string]::IsNullOrWhiteSpace($rawEvent) -and -not [Console]::IsInputRedirected) { $rawEvent = '' }
    elseif ([string]::IsNullOrWhiteSpace($rawEvent)) { $rawEvent = [Console]::In.ReadToEnd() }

    $hostEvent = $null
    if (-not [string]::IsNullOrWhiteSpace($rawEvent)) {
        try { $hostEvent = $rawEvent | ConvertFrom-Json }
        catch {
            Write-DispatcherWarn -Code 'EVENT_PARSE' -Message ("host event JSON unreadable for {0}; automation quiet this event (host surface changed? see the research matrix)" -f $Event)
            exit 0
        }
    }

    $sessionId = Get-SanitizedSessionId -RawSessionId $(if ($null -ne $hostEvent -and $hostEvent.PSObject.Properties['session_id']) { [string]$hostEvent.session_id } else { $null })
    $source = if ($null -ne $hostEvent -and $hostEvent.PSObject.Properties['source']) { [string]$hostEvent.source } else { $null }

    $catalog = Get-DispatcherCatalog -ProjectRoot $projectRoot
    if ($null -eq $catalog -or -not $catalog.PSObject.Properties['providers']) { exit 0 }

    # Providers for THIS event, deterministic order (the host runs parallel hooks
    # unordered; Specrew owns ordering internally — the lens-2 dispatcher decision).
    $providers = @($catalog.providers | Where-Object { @($_.events) -contains $Event } | Sort-Object { [int]$_.order })

    $fragments = New-Object System.Collections.Generic.List[string]
    foreach ($provider in $providers) {
        $kind = if ($provider.PSObject.Properties['kind']) { [string]$provider.kind } else { 'inject' }
        $providerId = [string]$provider.id

        $commandPath = Resolve-ProviderCommandPath -ProjectRoot $projectRoot -Command ([string]$provider.command)
        if ($null -eq $commandPath) {
            Write-DispatcherWarn -Code 'SOURCE_CONFINED' -Message ("provider '{0}' command does not resolve under the deployed tree; skipped" -f $providerId)
            continue
        }

        if ($kind -eq 'gate') {
            # DORMANT F-165 seat (FR-008 forward-compat): gate providers run on
            # PreToolUse, receive tool_input, return allow/deny permissionDecision.
            # No gate provider ships in F-171; this path is fixture-tested only.
            if ($Event -ne 'PreToolUse') { continue }
            $result = Invoke-ProviderProcess -CommandPath $commandPath -CommandArgs @('--gate') -WorkingDirectory $projectRoot -TimeoutSeconds $ProviderTimeoutSeconds
            if ($result.TimedOut -or $result.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($result.StdOut)) {
                # Gates fail OPEN to allow — a broken gate never blocks a session.
                Write-DispatcherWarn -Code 'PROVIDER_FAILED' -Message ("gate provider '{0}' failed; failing OPEN to allow" -f $providerId)
                @{ hookSpecificOutput = @{ hookEventName = 'PreToolUse'; permissionDecision = 'allow'; permissionDecisionReason = "specrew gate provider '$providerId' failed open" } } | ConvertTo-Json -Depth 4 -Compress | Write-Output
                continue
            }
            Write-Output $result.StdOut.Trim()
            continue
        }

        # inject providers (refocus is registry row #1; future rows — e.g. 130-P4
        # handover — ride the same path with event JSON on their own contract).
        $commandArgs = $null
        if ($providerId -eq 'refocus') {
            $commandArgs = Get-RefocusProviderArgs -EventName $Event -Source $source
        }
        else {
            $commandArgs = @('--event-json', ($rawEvent ?? ''))
        }
        if ($null -eq $commandArgs) { continue }

        $result = Invoke-ProviderProcess -CommandPath $commandPath -CommandArgs $commandArgs -WorkingDirectory $projectRoot -TimeoutSeconds $ProviderTimeoutSeconds
        if ($result.TimedOut) {
            Write-DispatcherWarn -Code 'PROVIDER_FAILED' -Message ("provider '{0}' timed out; skipped" -f $providerId)
            continue
        }
        if ($result.ExitCode -ne 0) {
            Write-DispatcherWarn -Code 'PROVIDER_FAILED' -Message ("provider '{0}' exited {1}; skipped" -f $providerId, $result.ExitCode)
            continue
        }
        if (-not [string]::IsNullOrWhiteSpace($result.StdOut)) {
            $fragments.Add($result.StdOut.Trim()) | Out-Null
        }
        if (-not [string]::IsNullOrWhiteSpace($result.StdErr)) {
            # Provider WARNs pass through once (visible, attributable).
            [Console]::Error.Write($result.StdErr)
        }
    }

    if ($fragments.Count -gt 0) {
        Write-InjectionOutput -EventName $Event -Payload (($fragments -join "`n`n"))
    }
    exit 0
}
catch {
    Write-DispatcherWarn -Code 'PROVIDER_FAILED' -Message ("dispatcher fail-open: {0}" -f $_.Exception.Message)
    exit 0
}
