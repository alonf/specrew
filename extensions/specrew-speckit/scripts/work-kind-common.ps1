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
