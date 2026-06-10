<#
.SYNOPSIS
  Code & Implementation lens manifest writer/validator + catalog/overlay helpers (Feature 177).

  The code-implementation lens captures implementation-craft decisions at design time into a per-feature
  manifest (implementation-rules.yml) that references the canonical catalog (code-rules.yml) by stable id.
  An implement-time guidance skill (specrew-code-rules) reads the manifest and composes baseline + overlay.

  YAML note: PowerShell 7 has no native YAML parser and Specrew deliberately avoids powershell-yaml. The
  manifest uses a CONSTRAINED YAML subset whose emitter (ConvertTo-SpecrewImplementationRulesYaml) and
  reader (ConvertFrom-SpecrewImplementationRulesYaml) are co-designed + round-trip-tested. Schema
  validation projects the parsed object to JSON and uses Test-Json -SchemaFile against
  implementation-rules.schema.json. Catalog/overlay ids are extracted by regex (no full YAML parse).
  Graceful: fail-open reads; the gate decides fail-open vs fail-closed. UTF-8 no-BOM.
#>

Set-StrictMode -Version Latest

$script:SpecrewCodeRuleGroups = @('baseline-default', 'decision-prompt', 'applicability-filtered', 'enforcement-mode')
$script:SpecrewCodeContextScopes = @('feature_standalone', 'product_baseline', 'feature_delta')
$script:SpecrewCodeConfirmations = @('human-confirmed', 'human-delegated', 'human-skipped')
$script:SpecrewCodeConfirmationScopes = @{
    'human-confirmed' = 'lens-question'
    'human-delegated' = 'explicit-delegation'
    'human-skipped'   = 'explicit-skip'
}
$script:SpecrewCodeCustomProvenance = @('free-text', 'pasted-doc', 'from-guideline', 'from-example-project')
$script:SpecrewCodeDependencyStances = @('use-existing-no-new-dependency', 'approved-new-dependencies')
$script:SpecrewCodeDependencyFields = @('name', 'version', 'license', 'source_org', 'canonical_url', 'maintenance_signal', 'security_advisory_status', 'compatibility', 'cost_or_quota', 'coupling_weight', 'replaceability', 'test_implications')

function Get-SpecrewCodeManifestPath {
    param([Parameter(Mandatory = $true)][string]$FeatureDir)
    return (Join-Path $FeatureDir 'implementation-rules.yml')
}

function Get-SpecrewCodeRecordPath {
    param([Parameter(Mandatory = $true)][string]$FeatureDir)
    return (Join-Path (Join-Path $FeatureDir 'workshop') 'code-implementation.md')
}

function Get-SpecrewCodeRuleEscape {
    param([AllowNull()][string]$Value)
    if ($null -eq $Value) { return '' }
    return (($Value -replace '\\', '\\' -replace '"', '\"') -replace '\r?\n', ' ')
}

function Get-SpecrewCodeRuleUnescape {
    param([AllowNull()][string]$Value)
    if ($null -eq $Value) { return '' }
    return ($Value -replace '\\"', '"' -replace '\\\\', '\')
}

function Get-SpecrewCodeMember {
    param([AllowNull()]$Object, [Parameter(Mandatory = $true)][string]$Key)
    if ($null -eq $Object) { return $null }
    if ($Object -is [System.Collections.IDictionary]) { if ($Object.Contains($Key)) { return $Object[$Key] } else { return $null } }
    $p = $Object.PSObject.Properties[$Key]; if ($p) { return $p.Value } else { return $null }
}

function ConvertTo-SpecrewCodeScalar {
    param([AllowNull()]$Value)
    if ($null -eq $Value) { return 'null' }
    if ($Value -is [bool]) { if ($Value) { return 'true' } else { return 'false' } }
    return ('"{0}"' -f (Get-SpecrewCodeRuleEscape -Value ([string]$Value)))
}

function ConvertTo-SpecrewImplementationRulesYaml {
    # Emit the constrained YAML for an implementation-rules manifest object. Deterministic key order,
    # 2-space indent, strings double-quoted, bool true/false, null -> null, enforcement as an inline list.
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][AllowNull()]$Manifest)
    if ($null -eq $Manifest) { return '' }

    $sb = [System.Text.StringBuilder]::new()
    foreach ($k in @('schema_version', 'context_scope', 'resolved_stack', 'product_id', 'product_context_ref')) {
        [void]$sb.AppendLine(('{0}: {1}' -f $k, (ConvertTo-SpecrewCodeScalar (Get-SpecrewCodeMember $Manifest $k))))
    }

    [void]$sb.AppendLine('selections:')
    foreach ($s in @(Get-SpecrewCodeMember $Manifest 'selections')) {
        if ($null -eq $s) { continue }
        [void]$sb.AppendLine(('  - id: {0}' -f (ConvertTo-SpecrewCodeScalar (Get-SpecrewCodeMember $s 'id'))))
        [void]$sb.AppendLine(('    checked: {0}' -f (ConvertTo-SpecrewCodeScalar (Get-SpecrewCodeMember $s 'checked'))))
        $dec = Get-SpecrewCodeMember $s 'decision'
        if ($null -ne $dec) { [void]$sb.AppendLine(('    decision: {0}' -f (ConvertTo-SpecrewCodeScalar $dec))) }
        $enf = @(Get-SpecrewCodeMember $s 'enforcement')
        if ($enf.Count -gt 0) {
            $items = ($enf | ForEach-Object { ConvertTo-SpecrewCodeScalar $_ }) -join ', '
            [void]$sb.AppendLine(('    enforcement: [{0}]' -f $items))
        }
    }

    [void]$sb.AppendLine('custom_rules:')
    foreach ($c in @(Get-SpecrewCodeMember $Manifest 'custom_rules')) {
        if ($null -eq $c) { continue }
        [void]$sb.AppendLine(('  - id: {0}' -f (ConvertTo-SpecrewCodeScalar (Get-SpecrewCodeMember $c 'id'))))
        [void]$sb.AppendLine(('    text: {0}' -f (ConvertTo-SpecrewCodeScalar (Get-SpecrewCodeMember $c 'text'))))
        $sc = Get-SpecrewCodeMember $c 'scope'
        if ($null -ne $sc) { [void]$sb.AppendLine(('    scope: {0}' -f (ConvertTo-SpecrewCodeScalar $sc))) }
        [void]$sb.AppendLine(('    provenance: {0}' -f (ConvertTo-SpecrewCodeScalar (Get-SpecrewCodeMember $c 'provenance'))))
    }

    $dep = Get-SpecrewCodeMember $Manifest 'dependency_policy'
    if ($null -ne $dep) {
        [void]$sb.AppendLine('dependency_policy:')
        [void]$sb.AppendLine(('  stance: {0}' -f (ConvertTo-SpecrewCodeScalar (Get-SpecrewCodeMember $dep 'stance'))))
        [void]$sb.AppendLine('  selected:')
        foreach ($d in @(Get-SpecrewCodeMember $dep 'selected')) {
            if ($null -eq $d) { continue }
            $first = $true
            foreach ($f in $script:SpecrewCodeDependencyFields) {
                $val = Get-SpecrewCodeMember $d $f
                if ($f -eq 'name' -or $null -ne $val) {
                    $prefix = if ($first) { '    - ' } else { '      ' }
                    [void]$sb.AppendLine(('{0}{1}: {2}' -f $prefix, $f, (ConvertTo-SpecrewCodeScalar $val)))
                    $first = $false
                }
            }
        }
    }

    $prov = Get-SpecrewCodeMember $Manifest 'provenance'
    [void]$sb.AppendLine('provenance:')
    [void]$sb.AppendLine(('  confirmation: {0}' -f (ConvertTo-SpecrewCodeScalar (Get-SpecrewCodeMember $prov 'confirmation'))))
    [void]$sb.AppendLine(('  confirmation_scope: {0}' -f (ConvertTo-SpecrewCodeScalar (Get-SpecrewCodeMember $prov 'confirmation_scope'))))

    return $sb.ToString()
}

function ConvertFrom-SpecrewCodeScalar {
    param([AllowNull()][string]$Raw)
    if ($null -eq $Raw) { return $null }
    $t = $Raw.Trim()
    if ($t -eq 'null' -or $t -eq '') { return $null }
    if ($t -eq 'true') { return $true }
    if ($t -eq 'false') { return $false }
    if ($t.StartsWith('"') -and $t.EndsWith('"') -and $t.Length -ge 2) {
        return (Get-SpecrewCodeRuleUnescape -Value $t.Substring(1, $t.Length - 2))
    }
    return $t
}

function ConvertFrom-SpecrewCodeInlineList {
    # Always returns an array. The leading-comma idiom (return ,$items) prevents PowerShell from
    # unwrapping a SINGLE-element array on function return -- otherwise enforcement: [review] is read
    # back as the scalar "review" and fails the schema's array type at the JSON projection. (Found by
    # the F-177 deployed-module dogfood; the unit round-trip only exercised a two-element list.)
    param([AllowNull()][string]$Raw)
    if ([string]::IsNullOrWhiteSpace($Raw)) { return ,@() }
    $t = $Raw.Trim()
    if ($t.StartsWith('[') -and $t.EndsWith(']')) { $t = $t.Substring(1, $t.Length - 2) }
    if ([string]::IsNullOrWhiteSpace($t)) { return ,@() }
    $items = @($t -split ',' | ForEach-Object { ConvertFrom-SpecrewCodeScalar -Raw $_ } | Where-Object { $null -ne $_ })
    return ,$items
}

function ConvertFrom-SpecrewImplementationRulesYaml {
    # Matched reader for the constrained manifest YAML. Returns an ordered hashtable, or $null on a
    # structurally unreadable document (graceful -- the caller fails closed).
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][AllowNull()][AllowEmptyString()][string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }

    $lines = $Text -split '\r?\n'
    $rec = [ordered]@{ selections = @(); custom_rules = @(); provenance = [ordered]@{} }
    $selections = [System.Collections.Generic.List[object]]::new()
    $customs = [System.Collections.Generic.List[object]]::new()
    $depSelected = [System.Collections.Generic.List[object]]::new()
    $dep = $null
    $section = 'top'
    $cur = $null

    foreach ($line in $lines) {
        if ($line -match '^\s*$') { continue }
        # Top-level key
        if ($line -match '^(?<k>[a-z_]+):\s*(?<v>.*)$') {
            $k = $Matches['k']; $v = $Matches['v']
            switch ($k) {
                'selections' { $section = 'selections'; $cur = $null; continue }
                'custom_rules' { $section = 'customs'; $cur = $null; continue }
                'dependency_policy' { $section = 'dep'; $dep = [ordered]@{}; $cur = $null; continue }
                'provenance' { $section = 'provenance'; $cur = $null; continue }
                default { $section = 'top'; $rec[$k] = ConvertFrom-SpecrewCodeScalar -Raw $v; continue }
            }
        }
        if ($section -eq 'selections') {
            if ($line -match '^\s{2}-\s+id:\s*(?<v>.*)$') {
                $cur = [ordered]@{ id = ConvertFrom-SpecrewCodeScalar -Raw $Matches['v'] }
                $selections.Add($cur) | Out-Null; continue
            }
            if ($null -ne $cur -and $line -match '^\s{4}enforcement:\s*(?<v>.*)$') { $cur['enforcement'] = ConvertFrom-SpecrewCodeInlineList -Raw $Matches['v']; continue }
            if ($null -ne $cur -and $line -match '^\s{4}(?<k>[a-z_]+):\s*(?<v>.*)$') { $cur[$Matches['k']] = ConvertFrom-SpecrewCodeScalar -Raw $Matches['v']; continue }
        }
        if ($section -eq 'customs') {
            if ($line -match '^\s{2}-\s+id:\s*(?<v>.*)$') {
                $cur = [ordered]@{ id = ConvertFrom-SpecrewCodeScalar -Raw $Matches['v'] }
                $customs.Add($cur) | Out-Null; continue
            }
            if ($null -ne $cur -and $line -match '^\s{4}(?<k>[a-z_]+):\s*(?<v>.*)$') { $cur[$Matches['k']] = ConvertFrom-SpecrewCodeScalar -Raw $Matches['v']; continue }
        }
        if ($section -eq 'dep') {
            if ($line -match '^\s{2}stance:\s*(?<v>.*)$') { $dep['stance'] = ConvertFrom-SpecrewCodeScalar -Raw $Matches['v']; continue }
            if ($line -match '^\s{2}selected:\s*$') { $cur = $null; continue }
            if ($line -match '^\s{4}-\s+(?<k>[a-z_]+):\s*(?<v>.*)$') {
                $cur = [ordered]@{}; $cur[$Matches['k']] = ConvertFrom-SpecrewCodeScalar -Raw $Matches['v']
                $depSelected.Add($cur) | Out-Null; continue
            }
            if ($null -ne $cur -and $line -match '^\s{6}(?<k>[a-z_]+):\s*(?<v>.*)$') { $cur[$Matches['k']] = ConvertFrom-SpecrewCodeScalar -Raw $Matches['v']; continue }
        }
        if ($section -eq 'provenance' -and $line -match '^\s{2}(?<k>[a-z_]+):\s*(?<v>.*)$') {
            $rec['provenance'][$Matches['k']] = ConvertFrom-SpecrewCodeScalar -Raw $Matches['v']; continue
        }
    }

    $rec['selections'] = $selections.ToArray()
    $rec['custom_rules'] = $customs.ToArray()
    if ($null -ne $dep) { $dep['selected'] = $depSelected.ToArray(); $rec['dependency_policy'] = $dep }
    return $rec
}

function Format-SpecrewCodeImplementationMarkdown {
    # Human-readable record (workshop/code-implementation.md) from a manifest object.
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][AllowNull()]$Manifest)
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('# Code & Implementation Record')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine(('**Resolved stack**: {0}' -f (Get-SpecrewCodeMember $Manifest 'resolved_stack')))
    [void]$sb.AppendLine(('**Context scope**: {0}' -f (Get-SpecrewCodeMember $Manifest 'context_scope')))
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Selected rules')
    [void]$sb.AppendLine('')
    foreach ($s in @(Get-SpecrewCodeMember $Manifest 'selections')) {
        if ($null -eq $s) { continue }
        $mark = if ([bool](Get-SpecrewCodeMember $s 'checked')) { 'x' } else { ' ' }
        $dec = Get-SpecrewCodeMember $s 'decision'
        $decTxt = if ($null -ne $dec) { (' -- {0}' -f $dec) } else { '' }
        [void]$sb.AppendLine(('- [{0}] {1}{2}' -f $mark, (Get-SpecrewCodeMember $s 'id'), $decTxt))
    }
    $customs = @(Get-SpecrewCodeMember $Manifest 'custom_rules')
    if ($customs.Count -gt 0) {
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('## Custom rules')
        [void]$sb.AppendLine('')
        foreach ($c in $customs) { if ($null -ne $c) { [void]$sb.AppendLine(('- {0} ({1}): {2}' -f (Get-SpecrewCodeMember $c 'id'), (Get-SpecrewCodeMember $c 'provenance'), (Get-SpecrewCodeMember $c 'text'))) } }
    }
    $dep = Get-SpecrewCodeMember $Manifest 'dependency_policy'
    if ($null -ne $dep) {
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('## Dependency policy')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine(('- **Stance**: {0}' -f (Get-SpecrewCodeMember $dep 'stance')))
        foreach ($d in @(Get-SpecrewCodeMember $dep 'selected')) {
            if ($null -ne $d) { [void]$sb.AppendLine(('- {0} {1} ({2})' -f (Get-SpecrewCodeMember $d 'name'), (Get-SpecrewCodeMember $d 'version'), (Get-SpecrewCodeMember $d 'license'))) }
        }
    }
    [void]$sb.AppendLine('')
    $prov = Get-SpecrewCodeMember $Manifest 'provenance'
    [void]$sb.AppendLine(('**Confirmation**: {0} / {1}' -f (Get-SpecrewCodeMember $prov 'confirmation'), (Get-SpecrewCodeMember $prov 'confirmation_scope')))
    return $sb.ToString()
}

function New-SpecrewImplementationRulesManifest {
    # FR-004: persist the manifest (.yml) + the human-readable record (.md). Idempotent; UTF-8 no-BOM.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$FeatureDir,
        [Parameter(Mandatory = $true)][AllowNull()]$Manifest,
        [switch]$Force
    )
    if ($null -eq $Manifest) { throw 'New-SpecrewImplementationRulesManifest: -Manifest is required.' }
    $ymlPath = Get-SpecrewCodeManifestPath -FeatureDir $FeatureDir
    $mdPath = Get-SpecrewCodeRecordPath -FeatureDir $FeatureDir
    $mdDir = Split-Path -Parent $mdPath
    if (-not (Test-Path -LiteralPath $mdDir -PathType Container)) { $null = New-Item -ItemType Directory -Path $mdDir -Force }
    $utf8 = [System.Text.UTF8Encoding]::new($false)

    if ((Test-Path -LiteralPath $ymlPath -PathType Leaf) -and -not $Force) {
        if (-not (Test-Path -LiteralPath $mdPath -PathType Leaf)) {
            [System.IO.File]::WriteAllText($mdPath, (Format-SpecrewCodeImplementationMarkdown -Manifest $Manifest), $utf8)
        }
        return $ymlPath
    }
    [System.IO.File]::WriteAllText($ymlPath, (ConvertTo-SpecrewImplementationRulesYaml -Manifest $Manifest), $utf8)
    [System.IO.File]::WriteAllText($mdPath, (Format-SpecrewCodeImplementationMarkdown -Manifest $Manifest), $utf8)
    return $ymlPath
}

function Get-SpecrewCodeRuleIds {
    # Regex-extract the rule ids from a catalog/overlay YAML file (no full YAML parse). Graceful @().
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][AllowNull()][AllowEmptyString()][string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) { return @() }
    $ids = [System.Collections.Generic.List[string]]::new()
    foreach ($line in (Get-Content -LiteralPath $Path -Encoding UTF8)) {
        if ($line -match '^\s*-\s+id:\s*(?<v>\S.*)$') { $ids.Add(($Matches['v'].Trim().Trim('"'))) | Out-Null }
    }
    return $ids.ToArray()
}

function Merge-SpecrewCodeRuleCatalog {
    # FR-012 overlay merge at the id level: shipped ids + overlay added ids, overlay overrides applied,
    # a shipped id is NEVER dropped. Returns @{ merged = string[]; dropped = string[]; added = string[] }.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowNull()][string]$CatalogPath,
        [AllowNull()][string]$OverlayPath
    )
    $shipped = @(Get-SpecrewCodeRuleIds -Path $CatalogPath)
    $overlay = @(Get-SpecrewCodeRuleIds -Path $OverlayPath)
    $merged = [System.Collections.Generic.List[string]]::new()
    foreach ($id in $shipped) { if (-not $merged.Contains($id)) { $merged.Add($id) | Out-Null } }
    $added = [System.Collections.Generic.List[string]]::new()
    foreach ($id in $overlay) { if (-not $merged.Contains($id)) { $merged.Add($id) | Out-Null; $added.Add($id) | Out-Null } }
    # A shipped id is never dropped (additive + override only): dropped is always empty by construction.
    $dropped = @($shipped | Where-Object { -not $merged.Contains($_) })
    return @{ merged = $merged.ToArray(); dropped = @($dropped); added = $added.ToArray() }
}

function Test-SpecrewImplementationRulesManifest {
    # FR-004 / FR-013 / SC-002: validate the persisted manifest. Reads + parses the constrained YAML,
    # projects to JSON, validates against the schema (Test-Json) when present, and enforces invariants
    # (selections reference known ids when a catalog is given; provenance pairing; dependency-stance).
    # Returns string[] of errors (empty = OK). Missing manifest -> single 'missing' error (caller decides).
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowNull()][AllowEmptyString()][string]$Path,
        [AllowNull()][AllowEmptyString()][string]$SchemaPath,
        [AllowNull()][AllowEmptyString()][string]$CatalogPath,
        [AllowNull()][AllowEmptyString()][string]$OverlayPath
    )
    $errors = [System.Collections.Generic.List[string]]::new()
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        $errors.Add(("implementation-rules manifest is missing: {0}" -f $Path)) | Out-Null
        return $errors.ToArray()
    }
    $text = ''
    try { $text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 } catch { $errors.Add('implementation-rules.yml is unreadable.') | Out-Null; return $errors.ToArray() }
    $rec = ConvertFrom-SpecrewImplementationRulesYaml -Text $text
    if ($null -eq $rec) { $errors.Add('implementation-rules.yml could not be parsed.') | Out-Null; return $errors.ToArray() }

    # Schema validation via JSON projection (SC-002), when a schema is available.
    if (-not [string]::IsNullOrWhiteSpace($SchemaPath) -and (Test-Path -LiteralPath $SchemaPath -PathType Leaf)) {
        $json = $null
        try { $json = ($rec | ConvertTo-Json -Depth 10) } catch { $json = $null }
        if ($null -ne $json) {
            $schemaErrors = $null; $ok = $true
            try { $ok = Test-Json -Json $json -SchemaFile $SchemaPath -ErrorVariable schemaErrors -ErrorAction SilentlyContinue } catch { $ok = $false }
            if (-not $ok) {
                $detail = if ($schemaErrors) { ($schemaErrors | ForEach-Object { $_.ToString() }) -join '; ' } else { 'schema mismatch' }
                $errors.Add(("implementation-rules.yml fails the schema: {0}" -f $detail)) | Out-Null
            }
        }
    }

    # Invariant backstops (also in the schema; checked here so the gate is robust without the schema).
    $scope = if ($rec.Contains('context_scope')) { [string]$rec['context_scope'] } else { '' }
    if ($scope -notin $script:SpecrewCodeContextScopes) { $errors.Add(("context_scope must be one of {0} (got '{1}')." -f ($script:SpecrewCodeContextScopes -join ' | '), $scope)) | Out-Null }
    if ([string]::IsNullOrWhiteSpace([string]$rec['resolved_stack'])) { $errors.Add('resolved_stack is required.') | Out-Null }

    $prov = $rec['provenance']
    $conf = [string](Get-SpecrewCodeMember $prov 'confirmation')
    if ($conf -notin $script:SpecrewCodeConfirmations) {
        $errors.Add(("provenance.confirmation must be one of {0} (got '{1}'); a batch 'confirm all' is NOT valid provenance." -f ($script:SpecrewCodeConfirmations -join ' | '), $conf)) | Out-Null
    }
    else {
        $expected = $script:SpecrewCodeConfirmationScopes[$conf]
        $scopeVal = [string](Get-SpecrewCodeMember $prov 'confirmation_scope')
        if ($scopeVal -ne $expected) { $errors.Add(("provenance.confirmation_scope must be '{0}' when confirmation is '{1}' (got '{2}')." -f $expected, $conf, $scopeVal)) | Out-Null }
    }

    foreach ($c in @($rec['custom_rules'])) {
        if ($null -eq $c) { continue }
        $cp = [string](Get-SpecrewCodeMember $c 'provenance')
        if ($cp -notin $script:SpecrewCodeCustomProvenance) { $errors.Add(("a custom rule has an invalid provenance '{0}' (must be {1})." -f $cp, ($script:SpecrewCodeCustomProvenance -join ' | '))) | Out-Null }
    }

    $dep = $rec['dependency_policy']
    if ($null -ne $dep) {
        $stance = [string](Get-SpecrewCodeMember $dep 'stance')
        if ($stance -notin $script:SpecrewCodeDependencyStances) { $errors.Add(("dependency_policy.stance must be one of {0} (got '{1}')." -f ($script:SpecrewCodeDependencyStances -join ' | '), $stance)) | Out-Null }
        foreach ($d in @(Get-SpecrewCodeMember $dep 'selected')) {
            if ($null -ne $d -and [string]::IsNullOrWhiteSpace([string](Get-SpecrewCodeMember $d 'name'))) { $errors.Add('a dependency_policy.selected entry is missing its name.') | Out-Null }
        }
    }

    # Selections reference known catalog/overlay ids OR a declared custom rule id (when a catalog is given).
    if (-not [string]::IsNullOrWhiteSpace($CatalogPath) -and (Test-Path -LiteralPath $CatalogPath -PathType Leaf)) {
        $merge = Merge-SpecrewCodeRuleCatalog -CatalogPath $CatalogPath -OverlayPath $OverlayPath
        $known = [System.Collections.Generic.HashSet[string]]::new()
        foreach ($id in @($merge.merged)) { [void]$known.Add([string]$id) }
        foreach ($c in @($rec['custom_rules'])) { if ($null -ne $c) { [void]$known.Add([string](Get-SpecrewCodeMember $c 'id')) } }
        foreach ($s in @($rec['selections'])) {
            if ($null -eq $s) { continue }
            $sid = [string](Get-SpecrewCodeMember $s 'id')
            if (-not $known.Contains($sid)) { $errors.Add(("selection references unknown rule id '{0}' (not in the catalog/overlay/custom set)." -f $sid)) | Out-Null }
        }
    }

    return $errors.ToArray()
}
