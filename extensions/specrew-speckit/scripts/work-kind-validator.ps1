#!/usr/bin/env pwsh
# Work-Kind CI Validator (Feature 182, Iteration 2).
#
# Provider-NEUTRAL: the core imports no forge tool. It reads the work-kind declaration + the catalog
# + the changed-file set (via a ProviderAdapter's read_pr_context, or the git-diff fallback) + the
# closeout evidence, and emits an advisory|blocking verdict that NAMES THE EXACT GAP (SC-005).
#
# Defaults to ADVISORY (warns, never blocks). Fail-open everywhere: malformed/missing input degrades
# to a WARN, never a crash or a spurious block.
#
# Checks (FR-007):
#   1. exactly one work_kind is declared (.specrew/work-kind.yml; else infer from branch prefix)
#   2. the declared kind exists in the catalog
#   3. changed files are within the kind's allowed_scope (global-allowlist files exempt)  [ChangedFileClassifier]
#   4. required closeout evidence is present; software-feature/bug-bash have no open lifecycle boundary [CloseoutEvidenceChecker]

$script:WkValidatorRoot = $PSScriptRoot
. (Join-Path $script:WkValidatorRoot 'work-kind-common.ps1')
. (Join-Path $script:WkValidatorRoot 'provider-adapter.ps1')

function Get-SpecrewWorkKindFromBranchPrefix {
    # Infer a default work_kind from the branch prefix (docs/, devops/, fix/, feature/) using each
    # kind's branch_prefix_hint. Returns $null when no prefix matches.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$Catalog,
        [Parameter(Mandatory = $true)][AllowNull()][string]$Branch
    )
    if ([string]::IsNullOrWhiteSpace($Branch)) { return $null }
    $b = $Branch.Trim()
    foreach ($wk in @($Catalog.work_kinds)) {
        $hint = [string]$wk.branch_prefix_hint
        if (-not [string]::IsNullOrWhiteSpace($hint) -and $b.StartsWith($hint, [System.StringComparison]::OrdinalIgnoreCase)) {
            return [string]$wk.id
        }
    }
    return $null
}

function Test-SpecrewWorkKindClosed {
    # CloseoutEvidenceChecker (best-effort, fail-open). For software-feature/bug-bash, a closed work
    # item has a feature-closeout marker (closeout-dashboard.md) in its feature dir; otherwise the
    # lifecycle boundary is still open. Returns @{ closed=<bool>; reason=<string> }.
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$ProjectPath, [Parameter(Mandatory = $true)][string]$Branch)
    # Resolve the feature dir from the branch (e.g. 182-foo -> specs/182-foo).
    $featureDir = $null
    if ($Branch -match '^(?<slug>[0-9]{3,}-[A-Za-z0-9-]+)$') {
        $candidate = Join-Path $ProjectPath (Join-Path 'specs' $Matches['slug'])
        if (Test-Path -LiteralPath $candidate -PathType Container) { $featureDir = $candidate }
    }
    if ($null -eq $featureDir) {
        return @{ closed = $true; reason = 'feature dir not resolvable from branch; closeout check skipped (fail-open)' }
    }
    $closeoutMarker = Join-Path $featureDir 'closeout-dashboard.md'
    if (Test-Path -LiteralPath $closeoutMarker) {
        return @{ closed = $true; reason = 'feature-closeout marker present' }
    }
    return @{ closed = $false; reason = "no feature-closeout marker (closeout-dashboard.md) in $featureDir — the work item's lifecycle boundary is still open" }
}

function Invoke-SpecrewWorkKindValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [string]$BaseRef,
        [string]$HeadRef = 'HEAD',
        [ValidateSet('advisory', 'blocking')][string]$Mode = 'advisory',
        [string]$Provider = 'generic',
        [AllowNull()][string[]]$ChangedFiles,
        [AllowNull()][string]$Branch
    )

    $findings = [System.Collections.Generic.List[object]]::new()
    function Add-Finding { param([string]$Check, [string]$Severity, [string]$Message) $findings.Add([ordered]@{ check = $Check; severity = $Severity; message = $Message }) | Out-Null }

    # --- load catalog (fail-open) ---
    $catalogPath = Join-Path $ProjectPath 'extensions/specrew-speckit/knowledge/work-kinds.yml'
    $catalog = $null
    if (Test-Path -LiteralPath $catalogPath) {
        $catalog = ConvertFrom-SpecrewWorkKindCatalog -Text (Get-Content -LiteralPath $catalogPath -Raw -Encoding UTF8)
    }
    if ($null -eq $catalog) {
        Add-Finding 'catalog' 'warn' "work-kinds.yml catalog not found/parseable at $catalogPath; skipping work-kind checks (fail-open)"
        return [ordered]@{ verdict = 'advisory-warn'; kind = $null; mode = $Mode; findings = @($findings.ToArray()) }
    }
    $catalogIds = @($catalog.work_kinds | ForEach-Object { [string]$_.id })

    # --- PR context (changed files + branch): explicit overrides (tests/callers) win; else the
    #     adapter's read_pr_context / git-diff fallback ---
    if ($null -ne $ChangedFiles -or -not [string]::IsNullOrWhiteSpace($Branch)) {
        $changed = @($ChangedFiles)
        $branch = [string]$Branch
    }
    elseif (-not [string]::IsNullOrWhiteSpace($BaseRef)) {
        $ctx = Get-SpecrewPrContext -ProjectPath $ProjectPath -BaseRef $BaseRef -HeadRef $HeadRef
        $changed = @($ctx.changed_files)
        $branch = [string]$ctx.source_branch
    }
    else {
        Add-Finding 'pr-context' 'warn' 'no -BaseRef and no -ChangedFiles/-Branch override; nothing to validate (fail-open)'
        return [ordered]@{ verdict = 'advisory-warn'; kind = $null; mode = $Mode; findings = @($findings.ToArray()) }
    }

    # --- check 1: exactly one declared kind (else infer from branch prefix) ---
    $declPath = Join-Path $ProjectPath '.specrew/work-kind.yml'
    $kind = $null
    if (Test-Path -LiteralPath $declPath) {
        $decl = ConvertFrom-SpecrewWorkKindDeclaration -Text (Get-Content -LiteralPath $declPath -Raw -Encoding UTF8)
        if ($null -ne $decl -and -not [string]::IsNullOrWhiteSpace([string]$decl.work_kind)) {
            $kind = [string]$decl.work_kind
        }
    }
    if ($null -eq $kind) {
        $inferred = Get-SpecrewWorkKindFromBranchPrefix -Catalog $catalog -Branch $branch
        if ($null -ne $inferred) {
            $kind = $inferred
            Add-Finding 'declaration' 'warn' "no .specrew/work-kind.yml; inferred work_kind '$kind' from the branch prefix. Add .specrew/work-kind.yml to make it authoritative."
        }
        else {
            Add-Finding 'declaration' 'warn' "no work_kind declared. Add .specrew/work-kind.yml with 'work_kind: <software-feature|bug-bash|docs-only|devops>' (or use a branch prefix docs/ devops/ fix/ feature/)."
            return [ordered]@{ verdict = 'advisory-warn'; kind = $null; mode = $Mode; findings = @($findings.ToArray()) }
        }
    }

    # --- check 2: declared kind in catalog ---
    if ($kind -notin $catalogIds) {
        Add-Finding 'in-catalog' 'warn' "declared work_kind '$kind' is not in the catalog (known: $($catalogIds -join ', ')). Reclassify (fail-open: skipping scope/evidence checks)."
        return [ordered]@{ verdict = 'advisory-warn'; kind = $kind; mode = $Mode; findings = @($findings.ToArray()) }
    }
    $wk = $catalog.work_kinds | Where-Object { $_.id -eq $kind } | Select-Object -First 1

    # --- check 3: changed-file scope (ChangedFileClassifier) ---
    $allow = @($catalog.global_allowlist)
    $scope = @($wk.allowed_scope)
    foreach ($file in $changed) {
        if ([string]::IsNullOrWhiteSpace($file)) { continue }
        if (Test-SpecrewWorkKindAllowlisted -Path $file -Allowlist $allow) { continue }
        $inScope = $false
        foreach ($g in $scope) { if (Test-SpecrewWorkKindGlob -Path $file -Pattern $g) { $inScope = $true; break } }
        if (-not $inScope) {
            Add-Finding 'changed-file-scope' 'fail' "'$file' is outside the '$kind' allowed scope. $kind allows: $($scope -join ', '). Reclassify the PR, or move this change to a separate work item."
        }
    }

    # --- check 4: closeout evidence (CloseoutEvidenceChecker) ---
    if ($kind -in @('software-feature', 'bug-bash')) {
        $closeout = Test-SpecrewWorkKindClosed -ProjectPath $ProjectPath -Branch $branch
        if (-not [bool]$closeout.closed) {
            Add-Finding 'closeout-evidence' 'fail' "'$kind' PR has an open lifecycle boundary: $($closeout.reason). Required evidence for $kind`: $($wk.required_evidence -join ', '). Close out the work item before merge."
        }
    }

    # --- verdict ---
    $hasFail = @($findings | Where-Object { $_.severity -eq 'fail' }).Count -gt 0
    $verdict = if (-not $hasFail) { if (@($findings).Count -gt 0) { "$Mode-warn" } else { "$Mode-pass" } }
    elseif ($Mode -eq 'blocking') { 'blocking-fail' } else { 'advisory-fail' }

    return [ordered]@{ verdict = $verdict; kind = $kind; mode = $Mode; findings = @($findings.ToArray()) }
}

function Write-SpecrewWorkKindBypassAudit {
    # Emergency/bypass audit (FR-011, SC-009): a bypass leaves a durable artifact, never a silent skip.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$Who,
        [Parameter(Mandatory = $true)][string]$Why,
        [string]$What = 'work-kind validation bypass',
        [string]$When
    )
    if ([string]::IsNullOrWhiteSpace($When)) { $When = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ') }
    $auditDir = Join-Path $ProjectPath '.specrew/bypass-audit'
    if (-not (Test-Path -LiteralPath $auditDir)) { $null = New-Item -ItemType Directory -Path $auditDir -Force }
    $line = "- who: $Who | why: $Why | what: $What | when: $When"
    $auditFile = Join-Path $auditDir 'bypass-log.md'
    if (-not (Test-Path -LiteralPath $auditFile)) {
        $utf8 = [System.Text.UTF8Encoding]::new($false)
        [System.IO.File]::WriteAllText($auditFile, "# Work-Kind Governance Bypass Audit`n`nEach bypass is an authorized escape hatch with a durable record (never a silent skip).`n`n", $utf8)
    }
    Add-Content -LiteralPath $auditFile -Value $line -Encoding UTF8
    return @{ recorded = $true; path = $auditFile; entry = $line }
}

function Format-SpecrewWorkKindVerdict {
    # Human-readable validator output (the ui-ux surface): names the exact gap + allowed scope + fix.
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)]$Result)
    $lines = [System.Collections.Generic.List[string]]::new()
    $kindTxt = if ($null -ne $Result.kind) { "declares work_kind: $($Result.kind)" } else { 'no work_kind' }
    $lines.Add("[work-kind] $kindTxt") | Out-Null
    foreach ($f in @($Result.findings)) {
        $mark = switch ($f.severity) { 'fail' { 'x' } 'warn' { '!' } default { '+' } }
        $lines.Add("  $mark $($f.check): $($f.message)") | Out-Null
    }
    if (@($Result.findings).Count -eq 0) { $lines.Add('  + all checks passed') | Out-Null }
    $blocking = $Result.verdict -like 'blocking-*'
    $tail = if ($blocking) { 'blocking mode' } else { 'not blocking (phased: advisory mode)' }
    $lines.Add("  verdict: $($Result.verdict.ToUpperInvariant()) — $tail") | Out-Null
    return ($lines -join [Environment]::NewLine)
}
