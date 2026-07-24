# specrew-self-ok: provenance comment citing the self-host feature that established this consumer firewall
# Consumer-side technology and delivery assumption advisory (F-198 / Proposal 205 W7-W8).
#
# This reader uses the same shipped deny-list as the repository lint, but scans the
# consumer project's authored instruction/governance surfaces. Findings are advisory:
# consumer files are never rewritten by this command. A damaged or newer rule surface
# warns instead of pretending to have checked semantics that this reader cannot know.

[CmdletBinding()]
param(
    [string]$ProjectPath = (Get-Location).Path,
    [string]$DenyListPath,
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath $ProjectPath).Path
if ([string]::IsNullOrWhiteSpace($DenyListPath)) {
    $DenyListPath = Join-Path $root '.specify/extensions/specrew-speckit/data/self-leak-deny-list.json'
}

function Get-WholeCommentApplicability {
    param(
        [string[]]$Lines,
        [int]$LineIndex,
        [string]$Path,
        [string[]]$AllowedKinds
    )

    $extension = [System.IO.Path]::GetExtension($Path)
    $pattern = switch -Regex ($extension) {
        '^\.(md|markdown)$' { '<!--\s*specrew-applicability:\s*(?<kind>[a-z-]+)\s*;(?<reason>([^-]|-(?!->))*)-->' ; break }
        '^\.(ps1|psd1|psm1|yml|yaml|sh|py|toml)$' { '^\s*#[^#]*?specrew-applicability:\s*(?<kind>[a-z-]+)\s*;(?<reason>.+)$' ; break }
        '^$' { '^\s*#[^#]*?specrew-applicability:\s*(?<kind>[a-z-]+)\s*;(?<reason>.+)$' ; break }
        default { $null }
    }
    if ($null -eq $pattern) {
        return [pscustomobject]@{ Valid = $false; Failure = 'file kind has no applicability annotation form'; Kind = $null; Reason = $null }
    }

    $found = [System.Collections.ArrayList]::new()
    foreach ($candidateIndex in @($LineIndex, ($LineIndex - 1))) {
        if ($candidateIndex -lt 0 -or $candidateIndex -ge $Lines.Count) { continue }
        foreach ($match in [regex]::Matches($Lines[$candidateIndex], $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            $null = $found.Add($match)
        }
    }
    if ($found.Count -ne 1) {
        return [pscustomobject]@{ Valid = $false; Failure = $(if ($found.Count -eq 0) { 'missing applicability marker' } else { 'multiple applicability markers' }); Kind = $null; Reason = $null }
    }

    $kind = $found[0].Groups['kind'].Value.Trim().ToLowerInvariant()
    $reason = $found[0].Groups['reason'].Value.Trim()
    if ($kind -notin $AllowedKinds) {
        return [pscustomobject]@{ Valid = $false; Failure = "unsupported applicability kind '$kind'"; Kind = $kind; Reason = $reason }
    }
    if ([string]::IsNullOrWhiteSpace($reason)) {
        return [pscustomobject]@{ Valid = $false; Failure = 'applicability marker has no reason'; Kind = $kind; Reason = $reason }
    }
    if ($kind -eq 'example-only' -and $Lines[$LineIndex] -notmatch '(?i)\b(example|illustrative|non-binding|not\s+a\s+mandate)\b') {
        return [pscustomobject]@{ Valid = $false; Failure = 'example-only statement is not visibly non-binding'; Kind = $kind; Reason = $reason }
    }
    [pscustomobject]@{ Valid = $true; Failure = $null; Kind = $kind; Reason = $reason }
}

function Get-ConsumerAssumptionSurface {
    param([string]$Root)

    $extensions = @('.md', '.markdown', '.yml', '.yaml', '.ps1', '.psd1', '.psm1', '.sh', '.py', '.toml', '.json')
    $files = [System.Collections.ArrayList]::new()
    foreach ($relativeRoot in @('.github', '.specify', '.squad', 'specs', 'docs')) {
        $candidate = Join-Path $Root $relativeRoot
        if (-not (Test-Path -LiteralPath $candidate -PathType Container)) { continue }
        foreach ($file in @(Get-ChildItem -LiteralPath $candidate -Recurse -File -ErrorAction SilentlyContinue)) {
            $normalized = $file.FullName.Replace('\', '/')
            if ($normalized -match '/(?:\.git|node_modules|\.specrew/review)/') { continue }
            if ($normalized -match '/\.specify/extensions/specrew-speckit/(?:data|scripts)/') { continue }
            if ($file.Extension.ToLowerInvariant() -notin $extensions) { continue }
            $null = $files.Add($file)
        }
    }
    foreach ($relative in @('AGENTS.md', 'CLAUDE.md')) {
        $candidate = Join-Path $Root $relative
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { $null = $files.Add((Get-Item -LiteralPath $candidate)) }
    }
    @($files | Sort-Object FullName -Unique)
}

$warnings = [System.Collections.ArrayList]::new()
$findings = [System.Collections.ArrayList]::new()
$scannedFiles = 0
$rulesValid = $false

try {
    if (-not (Test-Path -LiteralPath $DenyListPath -PathType Leaf)) { throw "deny-list not found: $DenyListPath" }
    $list = Get-Content -LiteralPath $DenyListPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([string]$list.schema_version -ne '1.0') { throw "unsupported deny-list schema_version '$($list.schema_version)'" }
    $allowedKinds = @($list.applicability_annotation.kinds | ForEach-Object { [string]$_ })
    if ($allowedKinds.Count -ne 4 -or @('project-detected', 'profile-selected', 'provider-gated', 'example-only' | Where-Object { $_ -notin $allowedKinds }).Count -gt 0) {
        throw 'deny-list does not declare the closed applicability kind set'
    }
    $rules = @($list.entries | Where-Object { [string]$_.class -in @('stack-assumption', 'delivery-assumption') } | ForEach-Object {
            [pscustomobject]@{ Class = [string]$_.class; Regex = [regex]::new([string]$_.pattern); Reason = [string]$_.reason }
        })
    if ($rules.Count -ne 2) { throw "expected one stack-assumption and one delivery-assumption rule; found $($rules.Count)" }
    $rulesValid = $true

    foreach ($file in @(Get-ConsumerAssumptionSurface -Root $root)) {
        $scannedFiles++
        $lines = @(Get-Content -LiteralPath $file.FullName -Encoding UTF8)
        for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex++) {
            foreach ($rule in $rules) {
                $match = $rule.Regex.Match($lines[$lineIndex])
                if (-not $match.Success) { continue }
                $annotation = Get-WholeCommentApplicability -Lines $lines -LineIndex $lineIndex -Path $file.FullName -AllowedKinds $allowedKinds
                if ($annotation.Valid) { continue }
                $relative = [System.IO.Path]::GetRelativePath($root, $file.FullName).Replace('\', '/')
                $null = $findings.Add([pscustomobject]@{
                        path = $relative
                        line = $lineIndex + 1
                        class = $rule.Class
                        term = $match.Value
                        failure = $annotation.Failure
                    })
            }
        }
    }
}
catch {
    $null = $warnings.Add("Consumer assumption rules were not evaluated: $($_.Exception.Message)")
}

$result = [pscustomobject]@{
    schema_version = '1.0'
    advisory = $true
    rules_valid = $rulesValid
    scanned_files = $scannedFiles
    finding_count = $findings.Count
    findings = @($findings)
    warnings = @($warnings)
}

foreach ($warning in $warnings) { Write-Warning $warning }
foreach ($finding in $findings) {
    Write-Warning ("Consumer assumption: {0}:{1} [{2}] '{3}' ({4}). Add exactly one adjacent 'specrew-applicability: <kind>; <reason>' whole-comment marker or remove the mandate." -f $finding.path, $finding.line, $finding.class, $finding.term, $finding.failure)
}
if ($rulesValid -and $findings.Count -eq 0) {
    Write-Host ("Consumer assumption advisory: clean ({0} files scanned)." -f $scannedFiles) -ForegroundColor Green
}
elseif ($rulesValid) {
    Write-Host ("Consumer assumption advisory: {0} finding(s); user-authored files were not changed." -f $findings.Count) -ForegroundColor Yellow
}

if ($PassThru) { $result }
exit 0
