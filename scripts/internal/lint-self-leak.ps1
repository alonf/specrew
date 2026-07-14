# Self-leak firewall lint (F-198 / Proposal 205 W1, FR-033).
#
# Scans EXACTLY what ships to consumers - the module manifest's FileList
# (the deploy allowlist) - against the versioned deny-list of Specrew-SELF
# facts. A deny-listed term without an adjacent `specrew-self-ok: <reason>`
# annotation is a red build.
#
# Exit-code contract (public, CI keys off it):
#   0 = clean (annotated hits are listed with their reasons - visible, per
#       the agent-action transparency NFR)
#   1 = unannotated findings present
#   2 = the deny-list or manifest is unreadable (fails LOUD - a broken rule
#       file can never produce a silent green)
#
# Annotation semantics (same line, or the line immediately above the hit):
#   .md              <!-- specrew-self-ok: <reason> -->
#   .ps1/.psd1/.yml  # specrew-self-ok: <reason>
# A token with no reason text is treated as unannotated.

[CmdletBinding()]
param(
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$DenyListPath,
    [string]$ManifestPath,
    # The consumer-deployed subset of the FileList: what init/update lands INSIDE
    # consumer projects (templates, squad runtime, the deployed extension). The
    # module's OWN docs/bin/engine scripts describe Specrew-the-product to its
    # users and legitimately name self-facts - they never enter a consumer tree.
    # (Proposal 205 W1 scope; the 204-W3/205-W3 deny-by-default manifest makes
    # this list the manifest's own truth in iteration 004.)
    [string[]]$ConsumerDeployedPrefixes = @('templates/', 'squad-templates/', 'extensions/specrew-speckit/'),
    [switch]$ListSurfaceOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ruleDoc = 'docs/methodology/self-leak-firewall.md'

if ([string]::IsNullOrWhiteSpace($DenyListPath)) {
    $DenyListPath = Join-Path $ProjectRoot 'extensions/specrew-speckit/data/self-leak-deny-list.json'
}
if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $ProjectRoot 'Specrew.psd1'
}

function Read-SelfLeakDenyList {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw ("Deny-list not found: {0}" -f $Path)
    }
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $parsed = $raw | ConvertFrom-Json
    if ($null -eq $parsed.schema_version -or [string]::IsNullOrWhiteSpace([string]$parsed.schema_version)) {
        throw ("Deny-list at {0} has no schema_version." -f $Path)
    }
    # The REPO-side reader is version-LOCKED (the asymmetric contract): this lane and the list
    # ship from the same repo, so an unknown schema_version means changed semantics this reader
    # cannot honor - scanning anyway could false-green. Exit-2 loud. (The iteration-004
    # CONSUMER-side reader is the deliberately fail-open-WARN one; codex review catch,
    # run de8951f5.)
    $supportedSchemaVersions = @('1.0')
    if ([string]$parsed.schema_version -notin $supportedSchemaVersions) {
        throw ("Deny-list at {0} has schema_version '{1}' but this lane supports only: {2}. A newer list needs the matching lane." -f $Path, [string]$parsed.schema_version, ($supportedSchemaVersions -join ', '))
    }
    if ($null -eq $parsed.entries -or @($parsed.entries).Count -eq 0) {
        throw ("Deny-list at {0} has no entries." -f $Path)
    }
    $compiled = @()
    foreach ($entry in $parsed.entries) {
        foreach ($required in @('pattern', 'class', 'reason', 'source', 'added')) {
            $value = $entry.PSObject.Properties[$required]
            if ($null -eq $value -or [string]::IsNullOrWhiteSpace([string]$value.Value)) {
                throw ("Deny-list entry missing required field '{0}' (pattern '{1}')." -f $required, $entry.pattern)
            }
        }
        $regex = [regex]::new([string]$entry.pattern)
        $compiled += [pscustomobject]@{
            Pattern = [string]$entry.pattern
            Regex   = $regex
            Class   = [string]$entry.class
            Reason  = [string]$entry.reason
        }
    }
    [pscustomobject]@{ SchemaVersion = [string]$parsed.schema_version; Entries = $compiled }
}

function Get-SelfLeakScanSurface {
    param(
        [Parameter(Mandatory = $true)][string]$ManifestPath,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$DenyListPath,
        [Parameter(Mandatory = $true)][string[]]$ConsumerDeployedPrefixes
    )

    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        throw ("Manifest not found: {0}" -f $ManifestPath)
    }
    $manifest = Import-PowerShellDataFile -LiteralPath $ManifestPath
    if ($null -eq $manifest.FileList -or @($manifest.FileList).Count -eq 0) {
        throw ("Manifest at {0} has no FileList - the lint's scan surface IS the deploy allowlist." -f $ManifestPath)
    }
    $denyListFull = (Resolve-Path -LiteralPath $DenyListPath -ErrorAction SilentlyContinue)?.Path
    $surface = @()
    foreach ($relative in $manifest.FileList) {
        $normalized = ([string]$relative) -replace '\\', '/'
        $isConsumerDeployed = $false
        foreach ($prefix in $ConsumerDeployedPrefixes) {
            if ($normalized.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) { $isConsumerDeployed = $true; break }
        }
        if (-not $isConsumerDeployed) { continue }
        $full = Join-Path $ProjectRoot $relative
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
        $resolved = (Resolve-Path -LiteralPath $full).Path
        if ($denyListFull -and ($resolved -eq $denyListFull)) { continue } # the rule file itself is never its own finding
        $surface += [pscustomobject]@{ Relative = [string]$relative; Full = $resolved }
    }
    $surface
}

function Test-SelfLeakAnnotated {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][AllowEmptyCollection()][string[]]$Lines,
        [Parameter(Mandatory = $true)][int]$LineIndex,
        [Parameter(Mandatory = $true)][string]$FilePath
    )

    # The annotation FORM is part of the contract (a malformed suppression is a false-green
    # authorization path — independent-review catch, run b12861a6): .md sanctions ONLY inside an
    # HTML comment; hash-comment kinds (.ps1/.psd1/.psm1/.yml/.yaml/.sh + extensionless shell
    # wrappers) ONLY as a WHOLE-LINE `#` comment — the line's first non-whitespace character must be
    # the hash (review finding f4, run 20260714T190233598: an annotation-looking token inside a QUOTED
    # VALUE, e.g. $x = 'text # specrew-self-ok: r', previously matched and suppressed a deny-listed
    # leak; a mid-line hash is not provably comment syntax without a language parser, so the sanctioned
    # form is one that cannot sit inside a same-line string value. Residual ceiling: a here-string /
    # YAML block-scalar LINE can still start with '#' — a full parser is out of scope for this lint;
    # every sanctioned annotation in the deploy surface is a whole-line comment). File kinds with no
    # sanctioned form cannot be annotated at all (fail-closed: no bypass without a validatable form).
    $extension = [System.IO.Path]::GetExtension($FilePath)
    $pattern = switch -Regex ($extension) {
        '^\.(md|markdown)$' { '<!--\s*specrew-self-ok:(?<reason>([^-]|-(?!->))*)-->' ; break }
        '^\.(ps1|psd1|psm1|yml|yaml|sh)$' { '^\s*#[^#]*?specrew-self-ok:(?<reason>.+)$' ; break }
        '^$' { '^\s*#[^#]*?specrew-self-ok:(?<reason>.+)$' ; break }   # extensionless shell wrappers
        default { $null }
    }
    if ($null -eq $pattern) { return $false }

    foreach ($candidateIndex in @($LineIndex, ($LineIndex - 1))) {
        if ($candidateIndex -lt 0 -or $candidateIndex -ge $Lines.Count) { continue }
        $match = [regex]::Match($Lines[$candidateIndex], $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if (-not $match.Success) { continue }
        $reason = $match.Groups['reason'].Value.Trim()
        # Return the HUMAN's reason text (not just a boolean): the reason is the audit trail, and
        # the annotated output must surface it (agent-action transparency - a sanction whose
        # recorded WHY never reaches the operator is form without meaning; copilot review catch,
        # run 7b55bbc8).
        if (-not [string]::IsNullOrWhiteSpace($reason)) { return $reason }
    }
    return $null
}

try {
    $denyList = Read-SelfLeakDenyList -Path $DenyListPath
    $surface = Get-SelfLeakScanSurface -ManifestPath $ManifestPath -ProjectRoot $ProjectRoot -DenyListPath $DenyListPath -ConsumerDeployedPrefixes $ConsumerDeployedPrefixes
}
catch {
    Write-Host ("[self-leak-lint] UNREADABLE RULE SURFACE: {0}" -f $_.Exception.Message) -ForegroundColor Red
    Write-Host ("[self-leak-lint] A broken deny-list or manifest can never produce a silent green. See {0}." -f $ruleDoc) -ForegroundColor Red
    exit 2
}

if ($ListSurfaceOnly) {
    $surface | ForEach-Object { $_.Relative }
    exit 0
}

$findings = @()
$annotated = @()
foreach ($file in $surface) {
    $lines = @(Get-Content -LiteralPath $file.Full -Encoding UTF8)
    # An annotation on the hit line, or the line immediately above, sanctions the hit.
    for ($i = 0; $i -lt $lines.Count; $i++) {
        foreach ($entry in $denyList.Entries) {
            $match = $entry.Regex.Match($lines[$i])
            if (-not $match.Success) { continue }
            $annotationReason = Test-SelfLeakAnnotated -Lines $lines -LineIndex $i -FilePath $file.Full
            $record = [pscustomobject]@{
                File             = $file.Relative
                Line             = $i + 1
                Matched          = $match.Value
                Class            = $entry.Class
                Reason           = $entry.Reason
                AnnotationReason = $annotationReason
            }
            if ($null -ne $annotationReason) {
                $annotated += $record
            }
            else {
                $findings += $record
            }
        }
    }
}

if (@($annotated).Count -gt 0) {
    Write-Host ("[self-leak-lint] {0} annotated hit(s) (sanctioned, reasons recorded):" -f @($annotated).Count) -ForegroundColor DarkYellow
    foreach ($hit in $annotated) {
        Write-Host ("  [annotated] {0}:{1} '{2}' ({3}) - reason: {4}" -f $hit.File, $hit.Line, $hit.Matched, $hit.Class, $hit.AnnotationReason)
    }
}

if (@($findings).Count -gt 0) {
    Write-Host ("[self-leak-lint] RED: {0} unannotated Specrew-self fact(s) in the deploy surface:" -f @($findings).Count) -ForegroundColor Red
    foreach ($finding in $findings) {
        Write-Host ("  {0}:{1}" -f $finding.File, $finding.Line) -ForegroundColor Red
        Write-Host ("    matched: '{0}'  class: {1}" -f $finding.Matched, $finding.Class) -ForegroundColor Red
        Write-Host ("    why this is a self-fact: {0}" -f $finding.Reason) -ForegroundColor Red
    }
    Write-Host ""
    Write-Host ("[self-leak-lint] To sanction an intentional self-reference, annotate the hit line (or the line above):") -ForegroundColor Yellow
    Write-Host ("  .md:              <!-- specrew-self-ok: <reason> -->") -ForegroundColor Yellow
    Write-Host ("  .ps1/.psd1/.yml:  # specrew-self-ok: <reason>   (a WHOLE-LINE comment - the line must start with #)") -ForegroundColor Yellow
    Write-Host ("[self-leak-lint] The rule and the resolution-point teaching live in {0}." -f $ruleDoc) -ForegroundColor Yellow
    exit 1
}

Write-Host ("[self-leak-lint] clean: {0} shipped files scanned, {1} deny-list entries (schema {2}), {3} annotated hit(s)." -f @($surface).Count, @($denyList.Entries).Count, $denyList.SchemaVersion, @($annotated).Count) -ForegroundColor Green
exit 0
