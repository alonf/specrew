# Specrew Refocus Engine (Feature 171, FR-001/FR-003/FR-004/FR-005/FR-012/FR-017).
# The SINGLE payload engine for every refocus surface: the /specrew-refocus slash
# command, the hook dispatcher's providers, the boundary-sync wrapper emission, and
# humans at a prompt. Pure with respect to payload production: same inputs -> same
# payload; the engine NEVER dedupes (a human asking always gets payload) and never
# writes state on payload paths. Operator commands (--status / --reset-breaker) are
# the contracted exceptions that read/clear runtime state.
#
# Contract (C1): stdout line 1 is the banner
#   [specrew-refocus] trigger=<t> scope=<s> sources=<n> tokens~<est>
# Warnings go to stderr as: [specrew-refocus] WARN <CODE> <message>
# Reason codes (FR-012): EVENT_PARSE, CATALOG_SCHEMA, SOURCE_MISSING, SOURCE_CONFINED,
#   STATE_UNAVAILABLE, BUDGET_EXCEEDED, BREAKER_TRIPPED, PROVIDER_FAILED
# Exit codes: 0 on success AND on every fail-open path; 2 only for human arg errors
# (the dispatcher never passes bad args).
[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# SPECREW-UTF8-OUTPUT (F-174 iter-10, Prop-145 P3): declare UTF-8 stdout so a non-ASCII digest/banner is not
# mangled to '?' by the child pwsh's default OEM console codepage when the dispatcher captures it (the dispatcher
# reads UTF-8 via ProcessStartInfo.StandardOutputEncoding). Fail-open.
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { $null = $_ }  # best-effort: a host that rejects UTF-8 console encoding must still run (fail-open)

$script:Banner = '[specrew-refocus]'
$script:CatalogSchemaVersion = '1'

function Write-RefocusWarn {
    param(
        [Parameter(Mandatory = $true)][string]$Code,
        [Parameter(Mandatory = $true)][string]$Message
    )
    # Error envelope (C1): one line per warning, stderr, machine-greppable code.
    [Console]::Error.WriteLine(("{0} WARN {1} {2}" -f $script:Banner, $Code, $Message))
}

function Get-RefocusProjectRoot {
    # Walk up from the current location to the nearest .specrew project root. The
    # engine is invoked with the project as CWD by every surface (skill, wrapper,
    # dispatcher); walking up tolerates subdirectory invocations.
    $candidate = (Get-Location).Path
    while (-not [string]::IsNullOrWhiteSpace($candidate)) {
        if (Test-Path -LiteralPath (Join-Path $candidate '.specrew') -PathType Container) {
            return $candidate
        }
        $parent = Split-Path -Parent $candidate
        if ($parent -eq $candidate) { break }
        $candidate = $parent
    }
    return $null
}

function Test-RefocusConfinedPath {
    param([Parameter(Mandatory = $true)][string]$RelativePath)
    # FR-004: content sources are repo-relative ONLY. Refuse absolute paths, drive
    # roots, and any '..' traversal segment.
    if ([System.IO.Path]::IsPathRooted($RelativePath)) { return $false }
    $segments = $RelativePath -split '[\\/]'
    foreach ($segment in $segments) {
        if ($segment -eq '..') { return $false }
    }
    return $true
}

function Get-RefocusCatalog {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)
    # Deployed copy first (downstream projects), repo canonical second (self-host).
    # JSON, not YAML: Specrew deliberately avoids the powershell-yaml dependency
    # (see scripts/internal/yaml-list.ps1 + host-history.ps1 precedent); recorded
    # as reconciled drift against FR-003's incidental .yml extension.
    $candidates = @(
        (Join-Path $ProjectRoot '.specify/extensions/specrew-speckit/refocus-scopes.json'),
        (Join-Path $ProjectRoot 'extensions/specrew-speckit/refocus-scopes.json')
    )
    foreach ($path in $candidates) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
        try {
            $catalog = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
        }
        catch {
            Write-RefocusWarn -Code 'CATALOG_SCHEMA' -Message ("catalog unreadable at {0}: {1}" -f $path, $_.Exception.Message)
            return $null
        }
        $declared = if ($catalog.PSObject.Properties['schema_version']) { [string]$catalog.schema_version } else { '' }
        if ($declared -ne $script:CatalogSchemaVersion) {
            Write-RefocusWarn -Code 'CATALOG_SCHEMA' -Message ("catalog schema_version '{0}' does not match engine '{1}' (additive evolution contract); failing open" -f $declared, $script:CatalogSchemaVersion)
            return $null
        }
        return $catalog
    }
    Write-RefocusWarn -Code 'SOURCE_MISSING' -Message 'refocus-scopes.json not found (deployed or canonical); run specrew update'
    return $null
}

function Get-RefocusDigestRoot {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)
    $candidates = @(
        (Join-Path $ProjectRoot '.specify/extensions/specrew-speckit/refocus'),
        (Join-Path $ProjectRoot 'extensions/specrew-speckit/refocus')
    )
    foreach ($path in $candidates) {
        if (Test-Path -LiteralPath $path -PathType Container) { return $path }
    }
    return $null
}

function Read-RefocusDigest {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$DigestRelativePath
    )
    # Returns @{ Body; SourceCount } or $null (with WARN already emitted).
    if (-not (Test-RefocusConfinedPath -RelativePath $DigestRelativePath)) {
        Write-RefocusWarn -Code 'SOURCE_CONFINED' -Message ("digest path '{0}' escapes the repository; refused" -f $DigestRelativePath)
        return $null
    }
    $digestRoot = Get-RefocusDigestRoot -ProjectRoot $ProjectRoot
    $resolved = $null
    if ($null -ne $digestRoot) {
        $candidate = Join-Path $digestRoot (Split-Path -Leaf $DigestRelativePath)
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { $resolved = $candidate }
    }
    if ($null -eq $resolved) {
        # Tolerate catalog entries that carry fuller relative paths.
        $candidate = Join-Path $ProjectRoot $DigestRelativePath
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { $resolved = $candidate }
    }
    if ($null -eq $resolved) {
        Write-RefocusWarn -Code 'SOURCE_MISSING' -Message ("digest '{0}' not found; run specrew update" -f $DigestRelativePath)
        return $null
    }

    $raw = Get-Content -LiteralPath $resolved -Raw -Encoding UTF8
    # Digests cannot bake absolute URLs (they deploy to arbitrary projects); the
    # {{project_root}} placeholder resolves to the live root as a file:/// URL.
    $rootUrl = 'file:///' + ($ProjectRoot -replace '\\', '/')
    $raw = $raw.Replace('{{project_root}}', $rootUrl)
    $body = $raw
    $sourceCount = 0
    # Frontmatter contract (C5): { scope, sources[], reviewed_at }. Strip it from the
    # injected body; count sources for the banner.
    $frontmatterMatch = [regex]::Match($raw, '(?s)^---\r?\n(?<fm>.*?)\r?\n---\r?\n')
    if ($frontmatterMatch.Success) {
        $body = $raw.Substring($frontmatterMatch.Length)
        $sourceCount = ([regex]::Matches($frontmatterMatch.Groups['fm'].Value, '(?m)^\s*-\s+\S')).Count
    }
    return @{ Body = $body.Trim(); SourceCount = $sourceCount }
}

function Get-RefocusStartContext {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)
    $path = Join-Path $ProjectRoot '.specrew/start-context.json'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    try { return Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch { return $null }
}

function Get-RefocusCurrentBoundary {
    param($StartContext)
    if ($null -eq $StartContext) { return $null }
    if ($StartContext.PSObject.Properties['session_state'] -and $null -ne $StartContext.session_state) {
        $boundary = [string]$StartContext.session_state.boundary_type
        if (-not [string]::IsNullOrWhiteSpace($boundary)) { return $boundary }
    }
    if ($StartContext.PSObject.Properties['boundary_enforcement'] -and $null -ne $StartContext.boundary_enforcement) {
        $boundary = [string]$StartContext.boundary_enforcement.last_authorized_boundary
        if (-not [string]::IsNullOrWhiteSpace($boundary)) { return $boundary }
    }
    return $null
}

function Get-RefocusBoundarySuccessor {
    param([AllowNull()][string]$Boundary)
    # Canonical stage order: after syncing boundary X, the work that follows is
    # the successor stage — B3 injects the INCOMING stage's discipline.
    $order = @('specify', 'clarify', 'plan', 'tasks', 'before-implement', 'implement', 'review-signoff', 'retro', 'iteration-closeout', 'feature-closeout')
    if ([string]::IsNullOrWhiteSpace($Boundary)) { return $null }
    $index = $order.IndexOf($Boundary.ToLowerInvariant())
    if ($index -lt 0 -or $index -ge ($order.Count - 1)) { return $null }
    return $order[$index + 1]
}

function Get-RefocusTokenEstimate {
    param([AllowEmptyString()][string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return 0 }
    return [int][math]::Ceiling($Text.Length / 4.0)
}

function Get-RefocusRuntimeStateFiles {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)
    $runtimeDir = Join-Path $ProjectRoot '.specrew/runtime'
    if (-not (Test-Path -LiteralPath $runtimeDir -PathType Container)) { return @() }
    return @(Get-ChildItem -LiteralPath $runtimeDir -Filter 'refocus-state-*.json' -File -ErrorAction SilentlyContinue)
}

function Format-RefocusPayload {
    param(
        [Parameter(Mandatory = $true)][string]$Trigger,
        [Parameter(Mandatory = $true)][string]$Scope,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$Parts,
        [Parameter(Mandatory = $true)][int]$SourceCount,
        [AllowNull()][nullable[int]]$BudgetCap
    )
    # Assembles banner + body under the budget cap (FR-005): clip whole trailing
    # parts first, then lines, and always say so.
    $body = (@($Parts) -join "`n`n").Trim()
    $estimate = Get-RefocusTokenEstimate -Text $body
    if ($null -ne $BudgetCap -and $estimate -gt $BudgetCap) {
        $maxChars = [int]($BudgetCap * 4)
        $lines = $body -split "`n"
        $kept = New-Object System.Collections.Generic.List[string]
        $running = 0
        foreach ($line in $lines) {
            $running += $line.Length + 1
            if ($running -gt $maxChars) { break }
            $kept.Add($line) | Out-Null
        }
        $body = ($kept -join "`n").TrimEnd()
        $body += "`n`n> [specrew-refocus] payload clipped to the catalog budget cap (~{0} tokens); full content at the file:/// pointers above." -f $BudgetCap
        Write-RefocusWarn -Code 'BUDGET_EXCEEDED' -Message ("payload (~{0} tokens) clipped to cap {1} for scope '{2}'" -f $estimate, $BudgetCap, $Scope)
        $estimate = Get-RefocusTokenEstimate -Text $body
    }
    $banner = "{0} trigger={1} scope={2} sources={3} tokens~{4}" -f $script:Banner, $Trigger, $Scope, $SourceCount, $estimate
    return $banner + "`n`n" + $body
}

function Get-RefocusFallbackPointerSet {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)
    # Minimal always-works payload when the catalog or digests are unavailable:
    # point at the canonical corpus instead of going silent (fail-open).
    $rootUrl = 'file:///' + ($ProjectRoot -replace '\\', '/')
    return @(
        '## Specrew refocus (fallback pointer set)',
        '',
        ("- Constitution: {0}/.specrew/constitution.md" -f $rootUrl),
        ("- Coordinator governance: {0}/.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md" -f $rootUrl),
        ("- Methodology: {0}/docs/methodology/" -f $rootUrl),
        ("- Lifecycle prompt: {0}/.specrew/last-start-prompt.md" -f $rootUrl),
        '',
        'Run `specrew update` to restore the refocus digest catalog.'
    ) -join "`n"
}

function Invoke-RefocusScopePayload {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$Trigger,
        [Parameter(Mandatory = $true)][string[]]$ScopeIds
    )
    # ScopeIds are catalog scope keys (e.g. 'general', 'boundary.review-signoff').
    $catalog = Get-RefocusCatalog -ProjectRoot $ProjectRoot
    $parts = New-Object System.Collections.Generic.List[string]
    $sources = 0
    $cap = $null

    if ($null -eq $catalog) {
        $parts.Add((Get-RefocusFallbackPointerSet -ProjectRoot $ProjectRoot)) | Out-Null
        return Format-RefocusPayload -Trigger $Trigger -Scope ($ScopeIds -join '+') -Parts $parts.ToArray() -SourceCount 0 -BudgetCap $null
    }

    if ($catalog.PSObject.Properties['budgets'] -and $null -ne $catalog.budgets -and $catalog.budgets.PSObject.Properties[$Trigger]) {
        $cap = [int]$catalog.budgets.$Trigger
    }

    foreach ($scopeId in $ScopeIds) {
        if (-not ($catalog.PSObject.Properties['scopes'] -and $null -ne $catalog.scopes -and $catalog.scopes.PSObject.Properties[$scopeId])) {
            Write-RefocusWarn -Code 'SOURCE_MISSING' -Message ("scope '{0}' is not in the catalog; substituting the fallback pointer set" -f $scopeId)
            $parts.Add((Get-RefocusFallbackPointerSet -ProjectRoot $ProjectRoot)) | Out-Null
            continue
        }
        foreach ($digestPath in @($catalog.scopes.$scopeId)) {
            $digest = Read-RefocusDigest -ProjectRoot $ProjectRoot -DigestRelativePath ([string]$digestPath)
            if ($null -ne $digest) {
                $parts.Add($digest.Body) | Out-Null
                $sources += [int]$digest.SourceCount
            }
        }
    }

    # FR-023 / SC-016 (iter-4): surface the SELECTED work_kind's lifecycle CONTRACT at session-start /
    # refocus so the crew is pointed to its lifecycle BEFORE work begins (the DF-009 intake gap — the
    # validator runs too late). Guarded (no-op when no work_kind is declared) + fail-open (refocus must
    # never break). The resolver lives in the work-kind extension (same deployed scripts dir, or the
    # dev-tree extension path).
    try {
        $wkCommon = @(
            (Join-Path $PSScriptRoot 'work-kind-common.ps1'),
            (Join-Path $ProjectRoot 'extensions/specrew-speckit/scripts/work-kind-common.ps1'),
            (Join-Path $ProjectRoot '.specify/extensions/specrew-speckit/scripts/work-kind-common.ps1')
        ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
        if ($wkCommon) {
            . $wkCommon
            $lifecycleLine = Get-SpecrewWorkKindLifecycleSurface -ProjectRoot $ProjectRoot
            if (-not [string]::IsNullOrWhiteSpace($lifecycleLine)) {
                $parts.Add(("## Work-kind lifecycle (this work item)`n`n" + $lifecycleLine)) | Out-Null
                $sources += 1
            }
        }
    }
    catch { Write-RefocusWarn -Code 'SOURCE_MISSING' -Message ("work-kind lifecycle surface unavailable: {0}" -f $_.Exception.Message) }

    if ($parts.Count -eq 0) {
        $parts.Add((Get-RefocusFallbackPointerSet -ProjectRoot $ProjectRoot)) | Out-Null
    }
    return Format-RefocusPayload -Trigger $Trigger -Scope ($ScopeIds -join '+') -Parts $parts.ToArray() -SourceCount $sources -BudgetCap $cap
}

function Invoke-RefocusRoleScope {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$RoleName
    )
    # FR-001: --role loads the role charter directly (charters are already compact).
    $candidates = @(
        (Join-Path $ProjectRoot (".specrew/team/agents/{0}.md" -f $RoleName)),
        (Join-Path $ProjectRoot (".squad/agents/{0}/charter.md" -f $RoleName))
    )
    foreach ($path in $candidates) {
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $body = (Get-Content -LiteralPath $path -Raw -Encoding UTF8).Trim()
            return Format-RefocusPayload -Trigger 'manual' -Scope ("role.{0}" -f $RoleName) -Parts @($body) -SourceCount 1 -BudgetCap $null
        }
    }
    Write-RefocusWarn -Code 'SOURCE_MISSING' -Message ("role charter for '{0}' not found under .specrew/team/agents or .squad/agents" -f $RoleName)
    return Format-RefocusPayload -Trigger 'manual' -Scope ("role.{0}" -f $RoleName) -Parts @((Get-RefocusFallbackPointerSet -ProjectRoot $ProjectRoot)) -SourceCount 0 -BudgetCap $null
}

function Invoke-RefocusCompactInstructions {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)
    # FR-017: paste-ready /compact preserve-list from live lifecycle state.
    $ctx = Get-RefocusStartContext -ProjectRoot $ProjectRoot
    if ($null -eq $ctx) {
        Write-RefocusWarn -Code 'STATE_UNAVAILABLE' -Message 'start-context.json unreadable; emitting a generic preserve-list'
        return '/compact preserve: the active Specrew feature, current lifecycle boundary, active role, pending verdicts, and binding constraints; artifacts live under specs/<feature>/'
    }
    $feature = ''
    $boundary = ''
    if ($ctx.PSObject.Properties['session_state'] -and $null -ne $ctx.session_state) {
        $feature = [string]$ctx.session_state.feature_ref
        $boundary = [string]$ctx.session_state.boundary_type
    }
    if ([string]::IsNullOrWhiteSpace($feature)) { $feature = '<active feature>' }
    if ([string]::IsNullOrWhiteSpace($boundary)) { $boundary = '<current boundary>' }
    return ('/compact preserve: feature {0} at the {1} boundary, the active role and its charter rules, all pending human verdicts and binding constraints, boundary-commit discipline, and that artifacts/evidence live under specs/{0}/ (re-read them rather than trusting summary memory)' -f $feature, $boundary)
}

function Invoke-RefocusStatus {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add(("{0} status" -f $script:Banner)) | Out-Null
    $envDisabled = -not [string]::IsNullOrWhiteSpace($env:SPECREW_REFOCUS_DISABLE)
    $lines.Add(("  env SPECREW_REFOCUS_DISABLE: {0}" -f $(if ($envDisabled) { 'SET (all hook triggers silenced)' } else { 'not set' }))) | Out-Null

    $catalog = Get-RefocusCatalog -ProjectRoot $ProjectRoot
    if ($null -ne $catalog -and $catalog.PSObject.Properties['triggers'] -and $null -ne $catalog.triggers) {
        foreach ($prop in $catalog.triggers.PSObject.Properties) {
            $enabled = $true
            if ($prop.Value.PSObject.Properties['enabled']) { $enabled = [bool]$prop.Value.enabled }
            $lines.Add(("  trigger {0}: {1}" -f $prop.Name, $(if ($enabled) { 'enabled' } else { 'DISABLED (catalog)' }))) | Out-Null
        }
    }
    else {
        $lines.Add('  catalog: unavailable (see WARN above)') | Out-Null
    }

    $stateFiles = @(Get-RefocusRuntimeStateFiles -ProjectRoot $ProjectRoot)
    if ($stateFiles.Count -eq 0) {
        $lines.Add('  sessions: no runtime state recorded yet') | Out-Null
    }
    foreach ($file in $stateFiles) {
        try { $state = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json }
        catch {
            $lines.Add(("  session {0}: state unreadable" -f $file.Name)) | Out-Null
            continue
        }
        $trip = 'no trips'
        if ($state.PSObject.Properties['breaker'] -and $null -ne $state.breaker -and $state.breaker.PSObject.Properties['tripped'] -and [bool]$state.breaker.tripped) {
            $trip = ("TRIPPED ({0})" -f [string]$state.breaker.reason)
        }
        $journalCount = 0
        if ($state.PSObject.Properties['journal'] -and $null -ne $state.journal) { $journalCount = @($state.journal).Count }
        $lines.Add(("  session {0}: breaker {1}; journal entries {2}" -f $file.Name, $trip, $journalCount)) | Out-Null
        foreach ($entry in @(if ($journalCount -gt 0) { $state.journal | Select-Object -Last 5 } else { @() })) {
            $lines.Add(("    {0} {1} {2} {3} tokens~{4} {5}" -f [string]$entry.at, [string]$entry.trigger, [string]$entry.scope, [string]$entry.channel, [string]$entry.tokens, [string]$entry.outcome)) | Out-Null
        }
    }
    return ($lines -join "`n")
}

function Invoke-RefocusResetBreaker {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)
    $cleared = 0
    foreach ($file in @(Get-RefocusRuntimeStateFiles -ProjectRoot $ProjectRoot)) {
        try {
            $state = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($state.PSObject.Properties['breaker'] -and $null -ne $state.breaker -and $state.breaker.PSObject.Properties['tripped'] -and [bool]$state.breaker.tripped) {
                $state.breaker = $null
                $json = $state | ConvertTo-Json -Depth 8
                [System.IO.File]::WriteAllText($file.FullName, $json, [System.Text.UTF8Encoding]::new($false))
                $cleared++
            }
        }
        catch {
            Write-RefocusWarn -Code 'STATE_UNAVAILABLE' -Message ("could not reset breaker in {0}: {1}" -f $file.Name, $_.Exception.Message)
        }
    }
    return ("{0} breaker reset: {1} trip flag(s) cleared" -f $script:Banner, $cleared)
}

# ---------------------------------------------------------------------------
# Argument parsing (GNU-style flags so the slash surface reads naturally).
# ---------------------------------------------------------------------------

$projectRoot = Get-RefocusProjectRoot
if ($null -eq $projectRoot) {
    Write-RefocusWarn -Code 'STATE_UNAVAILABLE' -Message 'no .specrew project found from the current directory; refocus is a Specrew-project surface'
    exit 0
}

$tokens = @($Arguments | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
$mode = 'default'
$modeValue = $null

if ($tokens.Count -gt 0) {
    switch -Regex ($tokens[0]) {
        '^--boundary$' {
            if ($tokens.Count -lt 2) { Write-RefocusWarn -Code 'EVENT_PARSE' -Message '--boundary requires a stage name'; exit 2 }
            $mode = 'boundary'; $modeValue = $tokens[1]; break
        }
        '^--role$' {
            if ($tokens.Count -lt 2) { Write-RefocusWarn -Code 'EVENT_PARSE' -Message '--role requires a role name'; exit 2 }
            $mode = 'role'; $modeValue = $tokens[1]; break
        }
        '^--trigger$' {
            if ($tokens.Count -lt 2 -or $tokens[1] -notin @('b1', 'b2', 'b3')) { Write-RefocusWarn -Code 'EVENT_PARSE' -Message '--trigger requires b1|b2|b3'; exit 2 }
            $mode = 'trigger'; $modeValue = $tokens[1]; break
        }
        '^--shape-catalog$' { $mode = 'shape-catalog'; break }
        '^--everything$' { $mode = 'everything'; break }
        '^--compact-instructions$' { $mode = 'compact-instructions'; break }
        '^--status$' { $mode = 'status'; break }
        '^--reset-breaker$' { $mode = 'reset-breaker'; break }
        default {
            Write-RefocusWarn -Code 'EVENT_PARSE' -Message ("unknown argument '{0}'; valid: --boundary <stage> | --role <name> | --trigger <b1|b2|b3> | --shape-catalog | --everything | --compact-instructions | --status | --reset-breaker" -f $tokens[0])
            exit 2
        }
    }
}

switch ($mode) {
    'default' {
        $boundary = Get-RefocusCurrentBoundary -StartContext (Get-RefocusStartContext -ProjectRoot $projectRoot)
        $scopes = @('general')
        if (-not [string]::IsNullOrWhiteSpace($boundary)) { $scopes += ("boundary.{0}" -f $boundary) }
        Invoke-RefocusScopePayload -ProjectRoot $projectRoot -Trigger 'manual' -ScopeIds $scopes
    }
    'boundary' {
        Invoke-RefocusScopePayload -ProjectRoot $projectRoot -Trigger 'manual' -ScopeIds @('general', ("boundary.{0}" -f $modeValue))
    }
    'role' {
        Invoke-RefocusRoleScope -ProjectRoot $projectRoot -RoleName $modeValue
    }
    'trigger' {
        $catalog = Get-RefocusCatalog -ProjectRoot $projectRoot
        $scopes = @('general')
        if ($null -ne $catalog -and $catalog.PSObject.Properties['triggers'] -and $null -ne $catalog.triggers -and $catalog.triggers.PSObject.Properties[$modeValue]) {
            $entry = $catalog.triggers.$modeValue
            # Durable per-trigger disable (kill-switch level: catalog flag). Silence
            # is the OPERATOR'S intent here — no payload, no warning, exit 0; the
            # disable is visible via --status. Applies to every channel that uses
            # trigger semantics (wrapper emission + hook providers); the manual
            # --boundary/--role surfaces are unaffected.
            if ($entry.PSObject.Properties['enabled'] -and -not [bool]$entry.enabled) { exit 0 }
            if ($entry.PSObject.Properties['scopes'] -and $null -ne $entry.scopes) { $scopes = @($entry.scopes | ForEach-Object { [string]$_ }) }
        }
        else {
            # Trigger missing from catalog: fall back to the default composition so
            # the trigger layer still delivers something useful (fail-open).
            $boundary = Get-RefocusCurrentBoundary -StartContext (Get-RefocusStartContext -ProjectRoot $projectRoot)
            if (-not [string]::IsNullOrWhiteSpace($boundary)) { $scopes += ("boundary.{0}" -f $boundary) }
        }
        # Resolve dynamic placeholders the trigger map may carry.
        $boundaryNow = Get-RefocusCurrentBoundary -StartContext (Get-RefocusStartContext -ProjectRoot $projectRoot)
        $boundaryNext = Get-RefocusBoundarySuccessor -Boundary $boundaryNow
        $scopes = @($scopes | ForEach-Object {
            if ($_ -eq 'boundary.current' -and -not [string]::IsNullOrWhiteSpace($boundaryNow)) { "boundary.{0}" -f $boundaryNow }
            elseif ($_ -eq 'boundary.next' -and -not [string]::IsNullOrWhiteSpace($boundaryNext)) { "boundary.{0}" -f $boundaryNext }
            elseif ($_ -in @('boundary.current', 'boundary.next')) { 'general' }
            else { $_ }
        } | Select-Object -Unique)
        Invoke-RefocusScopePayload -ProjectRoot $projectRoot -Trigger $modeValue -ScopeIds $scopes
    }
    'shape-catalog' {
        Invoke-RefocusScopePayload -ProjectRoot $projectRoot -Trigger 'manual' -ScopeIds @('shape-catalog')
    }
    'everything' {
        $catalog = Get-RefocusCatalog -ProjectRoot $projectRoot
        $scopes = @('general')
        if ($null -ne $catalog -and $catalog.PSObject.Properties['scopes'] -and $null -ne $catalog.scopes) {
            $scopes = @($catalog.scopes.PSObject.Properties | ForEach-Object { $_.Name })
        }
        Write-RefocusWarn -Code 'BUDGET_EXCEEDED' -Message '--everything loads the full digest corpus; expect a heavy payload'
        Invoke-RefocusScopePayload -ProjectRoot $projectRoot -Trigger 'manual' -ScopeIds $scopes
    }
    'compact-instructions' {
        Invoke-RefocusCompactInstructions -ProjectRoot $projectRoot
    }
    'status' {
        Invoke-RefocusStatus -ProjectRoot $projectRoot
    }
    'reset-breaker' {
        Invoke-RefocusResetBreaker -ProjectRoot $projectRoot
    }
}

exit 0
