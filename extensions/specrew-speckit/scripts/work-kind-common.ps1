#!/usr/bin/env pwsh
# Work-kind common helpers (Feature 182).
#
# Focused, dependency-free readers for the work-kind YAML files + a glob matcher. Specrew
# deliberately avoids the powershell-yaml dependency, so these are line-based readers matched to
# the parser-friendly subset the catalog/declaration are authored in (see work-kinds.yml header).
# All readers are fail-open: a structurally unreadable document returns $null and the caller
# decides (the validator degrades to advisory WARN, never a crash).
#
# Library file: it does NOT set a script-wide Set-StrictMode, so dot-sourcing does not change the
# caller's strict-mode posture.

function ConvertFrom-SpecrewWorkKindScalar {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][AllowEmptyString()][AllowNull()][string]$Raw)
    if ($null -eq $Raw) { return $null }
    $v = $Raw.Trim()
    if ($v.Length -eq 0) { return $null }
    # strip a trailing inline comment that is not inside quotes
    if ($v -notmatch '^["'']' -and $v -match '^(?<val>[^#]*?)\s+#.*$') { $v = $Matches['val'].Trim() }
    if ($v.Length -ge 2 -and (($v[0] -eq '"' -and $v[-1] -eq '"') -or ($v[0] -eq "'" -and $v[-1] -eq "'"))) {
        return $v.Substring(1, $v.Length - 2)
    }
    switch -Regex ($v) {
        '^(?i:true)$'  { return $true }
        '^(?i:false)$' { return $false }
        '^(?i:null|~)$' { return $null }
        default { return $v }
    }
}

function ConvertFrom-SpecrewWorkKindCatalog {
    # Reads work-kinds.yml into an ordered hashtable: { schema_version, work_kinds=[..], global_allowlist=[..] }.
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][AllowNull()][AllowEmptyString()][string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }

    $lines = $Text -split '\r?\n'
    $rec = [ordered]@{ schema_version = $null; work_kinds = @(); global_allowlist = @() }
    $kinds = [System.Collections.Generic.List[object]]::new()
    $allow = [System.Collections.Generic.List[string]]::new()
    $section = 'top'
    $cur = $null
    $curList = $null

    foreach ($line in $lines) {
        if ($line -match '^\s*#' -or $line -match '^\s*$') { continue }

        # Top-level key (no indentation)
        if ($line -match '^(?<k>[a-z_]+):\s*(?<v>.*)$') {
            $k = $Matches['k']; $v = $Matches['v']
            switch ($k) {
                'work_kinds' { $section = 'work_kinds'; $cur = $null; $curList = $null; continue }
                'global_allowlist' { $section = 'global_allowlist'; $cur = $null; $curList = $null; continue }
                default { $rec[$k] = ConvertFrom-SpecrewWorkKindScalar -Raw $v; $section = 'top'; continue }
            }
        }

        if ($section -eq 'work_kinds') {
            # new work-kind entry: "  - id: <value>"
            if ($line -match '^\s{2}-\s+id:\s*(?<v>.*)$') {
                $cur = [ordered]@{ id = ConvertFrom-SpecrewWorkKindScalar -Raw $Matches['v']; required_evidence = @(); allowed_scope = @() }
                $kinds.Add($cur) | Out-Null
                $curList = $null
                continue
            }
            if ($null -eq $cur) { continue }
            # nested list item: "      - <value>"
            if ($line -match '^\s{6}-\s+(?<v>.*)$') {
                if ($null -ne $curList) {
                    $existing = [System.Collections.Generic.List[object]]::new()
                    foreach ($e in @($cur[$curList])) { $existing.Add($e) | Out-Null }
                    $existing.Add((ConvertFrom-SpecrewWorkKindScalar -Raw $Matches['v'])) | Out-Null
                    $cur[$curList] = $existing.ToArray()
                }
                continue
            }
            # property: "    key:" (starts nested list) or "    key: value" (scalar)
            if ($line -match '^\s{4}(?<k>[a-z_]+):\s*(?<v>.*)$') {
                $pk = $Matches['k']; $pv = $Matches['v']
                if ([string]::IsNullOrWhiteSpace($pv)) {
                    $curList = $pk
                    if (-not $cur.Contains($pk)) { $cur[$pk] = @() }
                }
                else {
                    $cur[$pk] = ConvertFrom-SpecrewWorkKindScalar -Raw $pv
                    $curList = $null
                }
                continue
            }
        }

        if ($section -eq 'global_allowlist') {
            if ($line -match '^\s{2}-\s+(?<v>.*)$') {
                $allow.Add([string](ConvertFrom-SpecrewWorkKindScalar -Raw $Matches['v'])) | Out-Null
                continue
            }
        }
    }

    $rec['work_kinds'] = $kinds.ToArray()
    $rec['global_allowlist'] = $allow.ToArray()
    return $rec
}

function ConvertFrom-SpecrewWorkKindDeclaration {
    # Reads a .specrew/work-kind.yml declaration: { work_kind, schema_version, notes }.
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][AllowNull()][AllowEmptyString()][string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    $rec = [ordered]@{}
    foreach ($line in ($Text -split '\r?\n')) {
        if ($line -match '^\s*#' -or $line -match '^\s*$') { continue }
        if ($line -match '^(?<k>[a-z_]+):\s*(?<v>.*)$') {
            $rec[$Matches['k']] = ConvertFrom-SpecrewWorkKindScalar -Raw $Matches['v']
        }
    }
    if (-not $rec.Contains('work_kind')) { return $null }
    return $rec
}

function Get-SpecrewWorkKindLifecycle {
    # FR-023 / SC-016: resolve the declared work_kind (.specrew/work-kind.yml) THROUGH the catalog to its
    # lifecycle template, and confirm that template is actually resolvable (deployed / in the module).
    # This is RUNTIME resolution, not file-presence: it proves the crew is pointed to the lifecycle the
    # declaration selected. Returns @{ Declared, Kind, LifecycleTemplate, ResolvedPath, Exists, Reason }.
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $result = [ordered]@{ Declared = $false; Kind = $null; LifecycleTemplate = $null; ResolvedPath = $null; Exists = $false; Reason = $null }
    $resolved = (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction SilentlyContinue)
    if ($null -eq $resolved) { $result.Reason = 'project-root-not-found'; return [pscustomobject]$result }
    $root = $resolved.Path

    $declPath = Join-Path $root '.specrew/work-kind.yml'
    if (-not (Test-Path -LiteralPath $declPath -PathType Leaf)) { $result.Reason = 'no-work-kind-declared'; return [pscustomobject]$result }
    $decl = ConvertFrom-SpecrewWorkKindDeclaration -Text (Get-Content -LiteralPath $declPath -Raw -Encoding UTF8)
    if ($null -eq $decl -or -not $decl.Contains('work_kind')) { $result.Reason = 'declaration-unparseable'; return [pscustomobject]$result }
    $result.Declared = $true
    $result.Kind = [string]$decl['work_kind']

    $catalogPath = @(
        (Join-Path $root 'extensions/specrew-speckit/knowledge/work-kinds.yml'),
        (Join-Path $root '.specify/extensions/specrew-speckit/knowledge/work-kinds.yml')
    ) | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
    if (-not $catalogPath) { $result.Reason = 'catalog-not-found'; return [pscustomobject]$result }
    $catalog = ConvertFrom-SpecrewWorkKindCatalog -Text (Get-Content -LiteralPath $catalogPath -Raw -Encoding UTF8)
    $entry = @($catalog.work_kinds) | Where-Object { [string]$_.id -eq $result.Kind } | Select-Object -First 1
    if ($null -eq $entry) { $result.Reason = ('kind-not-in-catalog: {0}' -f $result.Kind); return [pscustomobject]$result }
    $tmpl = if ($entry.Contains('lifecycle_template')) { [string]$entry['lifecycle_template'] } else { $null }
    if ([string]::IsNullOrWhiteSpace($tmpl)) { $result.Reason = ('no-lifecycle_template-for: {0}' -f $result.Kind); return [pscustomobject]$result }
    $result.LifecycleTemplate = $tmpl

    # lifecycle_template ("templates/lifecycle/<kind>-lifecycle.md") is relative to the EXTENSION ROOT
    # (the catalog's grandparent): the templates ship WITH the extension, so the SAME relative path
    # resolves in the dev tree (extensions/specrew-speckit/...) AND a deployed project
    # (.specify/extensions/specrew-speckit/...). This is the deployed-shape fix (the prior repo-root
    # resolution failed in a real deployment).
    $extRoot = Split-Path -Parent (Split-Path -Parent $catalogPath)   # <ext>/knowledge/work-kinds.yml -> <ext>
    $cand = Join-Path $extRoot $tmpl
    if (Test-Path -LiteralPath $cand -PathType Leaf) {
        $result.ResolvedPath = (Resolve-Path -LiteralPath $cand).Path
        $result.Exists = $true
    }
    else {
        $result.Reason = ('lifecycle-template-not-resolvable: {0} (looked under {1})' -f $tmpl, $extRoot)
    }
    return [pscustomobject]$result
}

function Get-SpecrewWorkKindLifecycleSurface {
    # FR-023 / SC-016: the human-visible line the intake/start/refocus surfaces render so the crew is
    # pointed to the SELECTED work_kind's lifecycle CONTRACT. Returns $null when nothing is declared.
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)
    $r = Get-SpecrewWorkKindLifecycle -ProjectRoot $ProjectRoot
    if (-not $r.Declared) { return $null }
    if ($r.Exists) {
        return ("Work kind: {0} -> lifecycle contract: {1} (resolved). Follow this {0} lifecycle, not improvised ceremony." -f $r.Kind, $r.LifecycleTemplate)
    }
    return ("Work kind: {0} -> lifecycle template '{1}' is declared in the catalog but NOT resolvable ({2}) — deploy the lifecycle templates." -f $r.Kind, $r.LifecycleTemplate, $r.Reason)
}

function Test-SpecrewWorkKindGlob {
    # Minimal gitignore-style glob match: `**` matches any path segments, `*` matches within a
    # segment, `?` one char. Forge-neutral (operates on a normalized forward-slash path).
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Pattern
    )
    $p = ($Path -replace '\\', '/').TrimStart('./')
    $g = ($Pattern -replace '\\', '/').TrimStart('./')
    # Build a regex from the glob. Order matters: handle `**/` (zero-or-more leading/intermediate
    # path segments, gitignore semantics) before the bare `**` and `*`.
    $rx = [System.Text.RegularExpressions.Regex]::Escape($g)
    $rx = $rx -replace '\\\*\\\*/', '(?:.*/)?'       # **/   -> optional path segments (incl. none)
    $rx = $rx -replace '\\\*\\\*', '.*'               # **    -> anything (e.g. trailing /**)
    $rx = $rx -replace '\\\*', '[^/]*'                # *     -> within a segment
    $rx = $rx -replace '\\\?', '[^/]'                 # ?     -> one char
    return [bool]([System.Text.RegularExpressions.Regex]::IsMatch($p, ('^' + $rx + '$')))
}

function Test-SpecrewWorkKindAllowlisted {
    # True if a changed file matches any global_allowlist glob (exempt from scope checks).
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Allowlist
    )
    foreach ($g in $Allowlist) {
        if ([string]::IsNullOrWhiteSpace($g)) { continue }
        if (Test-SpecrewWorkKindGlob -Path $Path -Pattern $g) { return $true }
    }
    return $false
}
