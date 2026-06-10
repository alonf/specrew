<#
.SYNOPSIS
  Product & Problem Domain lens record writer/validator (Feature 176).

  The product-domain lens runs as a first-stage workshop phase before the technical-lens
  applicability selector. It persists a structured record (product-domain.yml) and a
  human-readable record (product-domain.md) per feature, captured at adaptive depth with
  evidence-tagged statements. These functions are pure + deterministic; no network/LLM.

  YAML note: PowerShell 7 has no native YAML parser. The structured record uses a CONSTRAINED
  YAML subset whose emitter (ConvertTo-SpecrewProductDomainYaml) and reader
  (ConvertFrom-SpecrewProductDomainYaml) are co-designed and round-trip-tested. Schema
  validation projects the parsed object to JSON and uses Test-Json -SchemaFile against
  contracts/product-domain.schema.json (SC-008). Graceful degradation everywhere (fail-open
  read, fail-closed gate on a substantive feature) so an absent surface is surfaced, never a
  silent skip.
#>

Set-StrictMode -Version Latest

$script:SpecrewProductDomainDepths = @('light', 'standard', 'deep')
$script:SpecrewProductDomainEvidence = @('known', 'assumed', 'unknown', 'research-needed')
$script:SpecrewProductDomainContextScopes = @('feature_standalone', 'product_baseline', 'feature_delta')
$script:SpecrewProductDomainConfirmations = @('human-confirmed', 'human-delegated', 'human-skipped')
$script:SpecrewProductDomainConfirmationScopes = @{
    'human-confirmed' = 'lens-question'
    'human-delegated' = 'explicit-delegation'
    'human-skipped'   = 'explicit-skip'
}

function Get-SpecrewProductDomainDepth {
    # FR-002 / SC-002: map risk + novelty signals to an adaptive depth. Deterministic; never
    # throws; defaults to 'standard' when ambiguous (the safe middle -- never silently Light).
    [CmdletBinding()]
    param(
        [AllowNull()][AllowEmptyString()][string]$Risk,
        [AllowNull()][AllowEmptyString()][string]$Novelty
    )

    $r = if ([string]::IsNullOrWhiteSpace($Risk)) { '' } else { $Risk.Trim().ToLowerInvariant() }
    $n = if ([string]::IsNullOrWhiteSpace($Novelty)) { '' } else { $Novelty.Trim().ToLowerInvariant() }

    # Deep: new product / regulated / high-risk / migration / new workflow / new segment / pivot.
    $deepSignals = 'new-product|new product|regulated|high-risk|high risk|migration|replacement|pivot|new-segment|new segment|new-workflow|new workflow|multi-team|commercial'
    if ($r -match $deepSignals -or $n -match $deepSignals) { return 'deep' }

    # Light: tiny / bugfix / narrow / spike / personal tool -- only when neither risk nor novelty is high.
    $lightSignals = 'tiny|bug-?fix|narrow|spike|personal|trivial|utility|chore'
    $highRisk = $r -match 'high|elevated|major'
    $knownContext = $n -match 'known|existing|familiar|incremental|low'
    if (($r -match $lightSignals -or $n -match $lightSignals -or $knownContext) -and -not $highRisk) { return 'light' }

    return 'standard'  # safe middle default
}

function Get-SpecrewProductDomainEscape {
    param([AllowNull()][string]$Value)
    if ($null -eq $Value) { return '' }
    # Constrained-YAML double-quoted scalar: escape backslash + quote; collapse newlines to spaces.
    return (($Value -replace '\\', '\\' -replace '"', '\"') -replace '\r?\n', ' ')
}

function Get-SpecrewProductDomainUnescape {
    param([AllowNull()][string]$Value)
    if ($null -eq $Value) { return '' }
    return ($Value -replace '\\"', '"' -replace '\\\\', '\')
}

function ConvertTo-SpecrewProductDomainYaml {
    # Emit the CONSTRAINED YAML for a product-domain record object (ordered hashtable / pscustomobject).
    # Deterministic key order; 2-space indent; strings double-quoted; null -> 'null'; bool -> true/false.
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][AllowNull()]$Record)

    if ($null -eq $Record) { return '' }
    $get = {
        param($obj, $key)
        if ($null -eq $obj) { return $null }
        if ($obj -is [System.Collections.IDictionary]) { if ($obj.Contains($key)) { return $obj[$key] } else { return $null } }
        $p = $obj.PSObject.Properties[$key]; if ($p) { return $p.Value } else { return $null }
    }
    $scalar = {
        param($v)
        if ($null -eq $v) { return 'null' }
        if ($v -is [bool]) { if ($v) { return 'true' } else { return 'false' } }
        return ('"{0}"' -f (Get-SpecrewProductDomainEscape -Value ([string]$v)))
    }

    $sb = [System.Text.StringBuilder]::new()
    foreach ($k in @('schema_version', 'depth', 'depth_reason', 'context_scope', 'product_id', 'product_context_ref')) {
        [void]$sb.AppendLine(('{0}: {1}' -f $k, (& $scalar (& $get $Record $k))))
    }

    # areas: a flat map of string answers
    [void]$sb.AppendLine('areas:')
    $areas = & $get $Record 'areas'
    if ($null -ne $areas) {
        $areaKeys = if ($areas -is [System.Collections.IDictionary]) { $areas.Keys } else { $areas.PSObject.Properties.Name }
        foreach ($ak in $areaKeys) {
            [void]$sb.AppendLine(('  {0}: {1}' -f $ak, (& $scalar (& $get $areas $ak))))
        }
    }

    # statements: list of {text, area, evidence, load_bearing?}
    [void]$sb.AppendLine('statements:')
    foreach ($st in @(& $get $Record 'statements')) {
        if ($null -eq $st) { continue }
        [void]$sb.AppendLine(('  - text: {0}' -f (& $scalar (& $get $st 'text'))))
        [void]$sb.AppendLine(('    area: {0}' -f (& $scalar (& $get $st 'area'))))
        [void]$sb.AppendLine(('    evidence: {0}' -f (& $scalar (& $get $st 'evidence'))))
        $lb = & $get $st 'load_bearing'
        if ($null -ne $lb) { [void]$sb.AppendLine(('    load_bearing: {0}' -f (& $scalar $lb))) }
    }

    # skipped: list of {area, reason}
    [void]$sb.AppendLine('skipped:')
    foreach ($sk in @(& $get $Record 'skipped')) {
        if ($null -eq $sk) { continue }
        [void]$sb.AppendLine(('  - area: {0}' -f (& $scalar (& $get $sk 'area'))))
        [void]$sb.AppendLine(('    reason: {0}' -f (& $scalar (& $get $sk 'reason'))))
    }

    # follow_up_research: list of scalars
    [void]$sb.AppendLine('follow_up_research:')
    foreach ($fr in @(& $get $Record 'follow_up_research')) {
        if ($null -eq $fr) { continue }
        [void]$sb.AppendLine(('  - {0}' -f (& $scalar $fr)))
    }

    [void]$sb.AppendLine(('confirmation: {0}' -f (& $scalar (& $get $Record 'confirmation'))))
    [void]$sb.AppendLine(('confirmation_scope: {0}' -f (& $scalar (& $get $Record 'confirmation_scope'))))

    return $sb.ToString()
}

function ConvertFrom-SpecrewProductDomainScalar {
    param([AllowNull()][string]$Raw)
    if ($null -eq $Raw) { return $null }
    $t = $Raw.Trim()
    if ($t -eq 'null' -or $t -eq '') { return $null }
    if ($t -eq 'true') { return $true }
    if ($t -eq 'false') { return $false }
    if ($t.StartsWith('"') -and $t.EndsWith('"') -and $t.Length -ge 2) {
        return (Get-SpecrewProductDomainUnescape -Value $t.Substring(1, $t.Length - 2))
    }
    return $t
}

function ConvertFrom-SpecrewProductDomainYaml {
    # Matched reader for the constrained YAML emitted above. Returns an ordered hashtable, or
    # $null on a structurally unreadable document (graceful -- the caller fails closed).
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][AllowNull()][AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    $lines = $Text -split '\r?\n'
    $rec = [ordered]@{ areas = [ordered]@{}; statements = @(); skipped = @(); follow_up_research = @() }
    $statements = [System.Collections.Generic.List[object]]::new()
    $skipped = [System.Collections.Generic.List[object]]::new()
    $research = [System.Collections.Generic.List[string]]::new()
    $section = 'top'
    $cur = $null

    foreach ($line in $lines) {
        if ($line -match '^\s*$') { continue }
        # Top-level key (no indent)
        if ($line -match '^(?<k>[a-z_]+):\s*(?<v>.*)$') {
            $k = $Matches['k']; $v = $Matches['v']
            switch ($k) {
                'areas' { $section = 'areas'; continue }
                'statements' { $section = 'statements'; continue }
                'skipped' { $section = 'skipped'; continue }
                'follow_up_research' { $section = 'research'; continue }
                default {
                    $section = 'top'
                    $rec[$k] = ConvertFrom-SpecrewProductDomainScalar -Raw $v
                    continue
                }
            }
        }
        # areas: 2-space indented map entries
        if ($section -eq 'areas' -and $line -match '^\s{2}(?<k>[a-z_]+):\s*(?<v>.*)$') {
            $rec['areas'][$Matches['k']] = ConvertFrom-SpecrewProductDomainScalar -Raw $Matches['v']
            continue
        }
        # statements / skipped: list items "  - key: value" then "    key: value"
        if ($section -eq 'statements' -or $section -eq 'skipped') {
            if ($line -match '^\s{2}-\s+(?<k>[a-z_]+):\s*(?<v>.*)$') {
                $cur = [ordered]@{}
                $cur[$Matches['k']] = ConvertFrom-SpecrewProductDomainScalar -Raw $Matches['v']
                if ($section -eq 'statements') { $statements.Add($cur) | Out-Null } else { $skipped.Add($cur) | Out-Null }
                continue
            }
            if ($null -ne $cur -and $line -match '^\s{4}(?<k>[a-z_]+):\s*(?<v>.*)$') {
                $cur[$Matches['k']] = ConvertFrom-SpecrewProductDomainScalar -Raw $Matches['v']
                continue
            }
        }
        # follow_up_research: "  - scalar"
        if ($section -eq 'research' -and $line -match '^\s{2}-\s+(?<v>.*)$') {
            $val = ConvertFrom-SpecrewProductDomainScalar -Raw $Matches['v']
            if ($null -ne $val) { $research.Add([string]$val) | Out-Null }
            continue
        }
    }

    $rec['statements'] = $statements.ToArray()
    $rec['skipped'] = $skipped.ToArray()
    $rec['follow_up_research'] = $research.ToArray()
    return $rec
}

function Get-SpecrewProductDomainRecordPath {
    param([Parameter(Mandatory = $true)][string]$FeatureDir, [ValidateSet('yml', 'md')][string]$Kind = 'yml')
    return (Join-Path (Join-Path $FeatureDir 'workshop') ('product-domain.{0}' -f $Kind))
}

function Format-SpecrewProductDomainMarkdown {
    # Render the human-readable product-domain.md from a record object (FR-005).
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][AllowNull()]$Record)
    $get = { param($o, $k) if ($null -eq $o) { return $null } if ($o -is [System.Collections.IDictionary]) { if ($o.Contains($k)) { return $o[$k] } else { return $null } } $p = $o.PSObject.Properties[$k]; if ($p) { return $p.Value } else { return $null } }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('# Product-Domain Record')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine(('**Depth**: {0} -- {1}' -f (& $get $Record 'depth'), (& $get $Record 'depth_reason')))
    [void]$sb.AppendLine(('**Context scope**: {0}' -f (& $get $Record 'context_scope')))
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Areas')
    [void]$sb.AppendLine('')
    $areas = & $get $Record 'areas'
    if ($null -ne $areas) {
        $akeys = if ($areas -is [System.Collections.IDictionary]) { $areas.Keys } else { $areas.PSObject.Properties.Name }
        foreach ($ak in $akeys) { [void]$sb.AppendLine(('- **{0}**: {1}' -f $ak, (& $get $areas $ak))) }
    }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Evidence-tagged statements')
    [void]$sb.AppendLine('')
    foreach ($st in @(& $get $Record 'statements')) {
        if ($null -eq $st) { continue }
        $lb = & $get $st 'load_bearing'
        $lbTag = if ($null -ne $lb) { (' [load_bearing: {0}]' -f $lb) } else { '' }
        [void]$sb.AppendLine(('- ({0}{1}) [{2}] {3}' -f (& $get $st 'evidence'), $lbTag, (& $get $st 'area'), (& $get $st 'text')))
    }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine(('**Confirmation**: {0} / {1}' -f (& $get $Record 'confirmation'), (& $get $Record 'confirmation_scope')))
    return $sb.ToString()
}

function New-SpecrewProductDomainRecord {
    # FR-005: scaffold/persist the structured (.yml) + human-readable (.md) records for a feature.
    # Idempotent: re-running with the same record rewrites an equivalent file. UTF-8 no-BOM.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$FeatureDir,
        [Parameter(Mandatory = $true)][AllowNull()]$Record,
        [switch]$Force
    )

    if ($null -eq $Record) { throw 'New-SpecrewProductDomainRecord: -Record is required.' }
    $ymlPath = Get-SpecrewProductDomainRecordPath -FeatureDir $FeatureDir -Kind 'yml'
    $mdPath = Get-SpecrewProductDomainRecordPath -FeatureDir $FeatureDir -Kind 'md'
    $dir = Split-Path -Parent $ymlPath
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) { $null = New-Item -ItemType Directory -Path $dir -Force }

    $utf8 = [System.Text.UTF8Encoding]::new($false)
    if ((Test-Path -LiteralPath $ymlPath -PathType Leaf) -and -not $Force) {
        # Idempotent: keep the existing .yml, but ensure the human-readable .md ALSO exists -- the gate
        # requires BOTH files (FR-005), so a deleted .md must be regenerated on a no-Force re-run.
        if (-not (Test-Path -LiteralPath $mdPath -PathType Leaf)) {
            [System.IO.File]::WriteAllText($mdPath, (Format-SpecrewProductDomainMarkdown -Record $Record), $utf8)
        }
        return $ymlPath
    }

    [System.IO.File]::WriteAllText($ymlPath, (ConvertTo-SpecrewProductDomainYaml -Record $Record), $utf8)
    [System.IO.File]::WriteAllText($mdPath, (Format-SpecrewProductDomainMarkdown -Record $Record), $utf8)
    return $ymlPath
}

function Get-SpecrewProductDomainSchemaPath {
    param([Parameter(Mandatory = $true)][string]$FeatureDir)
    return (Join-Path (Join-Path $FeatureDir 'contracts') 'product-domain.schema.json')
}

function Test-SpecrewProductDomainRecord {
    # FR-004 / FR-010 / SC-003 / SC-008: validate the persisted .yml record. Reads + parses the
    # constrained YAML, projects to JSON, validates against the schema (Test-Json -SchemaFile when
    # the schema is present), and enforces evidence-tag + provenance invariants the schema can also
    # express. Returns a string[] of errors (empty = OK). Graceful: a MISSING record returns a single
    # 'missing' error (the caller decides fail-open vs fail-closed); an UNREADABLE record fails.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][AllowNull()][AllowEmptyString()][string]$Path,
        [AllowNull()][AllowEmptyString()][string]$SchemaPath
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        $errors.Add(("product-domain record is missing: {0}" -f $Path)) | Out-Null
        return $errors.ToArray()
    }

    $text = ''
    try { $text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 } catch { $errors.Add('product-domain.yml is unreadable.') | Out-Null; return $errors.ToArray() }
    $rec = ConvertFrom-SpecrewProductDomainYaml -Text $text
    if ($null -eq $rec) { $errors.Add('product-domain.yml could not be parsed.') | Out-Null; return $errors.ToArray() }

    # Schema validation via the JSON projection (SC-008), when a schema is available.
    $json = $null
    try { $json = ($rec | ConvertTo-Json -Depth 8) } catch { $json = $null }
    if ($null -ne $json -and -not [string]::IsNullOrWhiteSpace($SchemaPath) -and (Test-Path -LiteralPath $SchemaPath -PathType Leaf)) {
        $schemaErrors = $null
        $ok = $true
        try { $ok = Test-Json -Json $json -SchemaFile $SchemaPath -ErrorVariable schemaErrors -ErrorAction SilentlyContinue } catch { $ok = $false }
        if (-not $ok) {
            $detail = if ($schemaErrors) { ($schemaErrors | ForEach-Object { $_.ToString() }) -join '; ' } else { 'schema mismatch' }
            $errors.Add(("product-domain.yml fails the schema: {0}" -f $detail)) | Out-Null
        }
    }

    # Invariant backstops (also expressed in the schema; checked here so the gate is robust even
    # when the schema file is absent).
    $depth = if ($rec.Contains('depth')) { [string]$rec['depth'] } else { '' }
    if ($depth -notin $script:SpecrewProductDomainDepths) { $errors.Add(("depth must be one of {0} (got '{1}')." -f ($script:SpecrewProductDomainDepths -join ' | '), $depth)) | Out-Null }
    if ([string]::IsNullOrWhiteSpace([string]$rec['depth_reason'])) { $errors.Add('depth_reason is required.') | Out-Null }
    $scope = if ($rec.Contains('context_scope')) { [string]$rec['context_scope'] } else { '' }
    if ($scope -notin $script:SpecrewProductDomainContextScopes) { $errors.Add(("context_scope must be one of {0} (got '{1}')." -f ($script:SpecrewProductDomainContextScopes -join ' | '), $scope)) | Out-Null }

    foreach ($st in @($rec['statements'])) {
        if ($null -eq $st) { continue }
        $ev = if ($st.Contains('evidence')) { [string]$st['evidence'] } else { '' }
        if ($ev -notin $script:SpecrewProductDomainEvidence) { $errors.Add(("a statement has an invalid evidence tag '{0}' (must be {1})." -f $ev, ($script:SpecrewProductDomainEvidence -join ' | '))) | Out-Null }
        if ([string]::IsNullOrWhiteSpace([string]$st['text'])) { $errors.Add('a statement is missing its text (untagged/empty material statement).') | Out-Null }
        if ($ev -eq 'research-needed' -and -not $st.Contains('load_bearing')) { $errors.Add('a research-needed statement must declare load_bearing (true|false).') | Out-Null }
    }

    # Provenance: a batch/agenda approval can never satisfy product-domain confirmation (FR-009).
    $conf = if ($rec.Contains('confirmation')) { [string]$rec['confirmation'] } else { '' }
    if ($conf -notin $script:SpecrewProductDomainConfirmations) {
        $errors.Add(("confirmation must be one of {0} (got '{1}'); a batch 'confirm all' is NOT valid provenance." -f ($script:SpecrewProductDomainConfirmations -join ' | '), $conf)) | Out-Null
    }
    else {
        $expectedScope = $script:SpecrewProductDomainConfirmationScopes[$conf]
        $scopeVal = if ($rec.Contains('confirmation_scope')) { [string]$rec['confirmation_scope'] } else { '' }
        if ($scopeVal -ne $expectedScope) { $errors.Add(("confirmation_scope must be '{0}' when confirmation is '{1}' (got '{2}'); lens approval is not product-domain confirmation." -f $expectedScope, $conf, $scopeVal)) | Out-Null }
    }

    return $errors.ToArray()
}

function Test-SpecrewProductDomainResearchBlock {
    # FR-011 / SC-006: return load-bearing research-needed statements that block the plan boundary.
    # A non-load-bearing research-needed statement is NOT returned (recorded + carried). Graceful @().
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][AllowNull()][AllowEmptyString()][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) { return @() }
    $text = ''
    try { $text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 } catch { return @() }
    $rec = ConvertFrom-SpecrewProductDomainYaml -Text $text
    if ($null -eq $rec) { return @() }

    $blocking = [System.Collections.Generic.List[string]]::new()
    foreach ($st in @($rec['statements'])) {
        if ($null -eq $st) { continue }
        $ev = if ($st.Contains('evidence')) { [string]$st['evidence'] } else { '' }
        $lb = if ($st.Contains('load_bearing')) { $st['load_bearing'] } else { $null }
        if ($ev -eq 'research-needed' -and $null -ne $lb -and [bool]$lb) {
            $blocking.Add([string]$st['text']) | Out-Null
        }
    }
    return $blocking.ToArray()
}

function Format-SpecrewProductDomainSummary {
    # FR-006: render the concise spec.md product-domain summary from the persisted record.
    # Graceful 'none recorded' when absent. Pure; markdownlint-safe.
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][AllowNull()][AllowEmptyString()][string]$Path)

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('## Product-Domain Summary')
    [void]$sb.AppendLine('')
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        [void]$sb.AppendLine('*None recorded* (the product-domain phase has not run for this feature).')
        return $sb.ToString().TrimEnd()
    }
    $rec = ConvertFrom-SpecrewProductDomainYaml -Text (Get-Content -LiteralPath $Path -Raw -Encoding UTF8)
    if ($null -eq $rec) { [void]$sb.AppendLine('*None recorded* (the product-domain record could not be parsed).'); return $sb.ToString().TrimEnd() }

    [void]$sb.AppendLine(('- **Depth**: {0} ({1})' -f $rec['depth'], $rec['context_scope']))
    $areas = $rec['areas']
    foreach ($ak in @('users_stakeholders', 'pain_job', 'mvp', 'out_of_scope', 'constraints')) {
        if ($null -ne $areas -and $areas.Contains($ak) -and -not [string]::IsNullOrWhiteSpace([string]$areas[$ak])) {
            [void]$sb.AppendLine(('- **{0}**: {1}' -f $ak, $areas[$ak]))
        }
    }
    $research = @($rec['follow_up_research'])
    if ($research.Count -gt 0) { [void]$sb.AppendLine(('- **Follow-up research**: {0}' -f ($research -join '; '))) }
    [void]$sb.AppendLine('- Full record: see the workshop product-domain.md / product-domain.yml.')
    return $sb.ToString().TrimEnd()
}
