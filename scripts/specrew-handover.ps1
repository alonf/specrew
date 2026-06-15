<#
.SYNOPSIS
  `specrew handover` — the agent-callable surface that persists the rolling session-handover BODY
  (F-174 iteration 011, T001, FR-022 / DF-7; design divergence drift D-005).

.DESCRIPTION
  Subcommands:
    author [--from <file>]   Persist the agent's rich handover BODY into the rolling handover, so a
                             DIFFERENT session / host that resumes this project inherits the AUTHORED
                             context, not placeholders. The INTERPRETIVE sections (open questions +
                             working hypothesis) are the ones NO hook can author — this command is how the
                             agent makes them durable. Reads a markdown file (`--from <file>`) or, with
                             `--stdin`, the piped body — whose `## ` headers name the handover sections
                             (the lead phrases below; short / tolerant headers are accepted).

  Handover sections (`## ` headers the body may carry — only these are written; others are reported + ignored):
    - What I just did
    - Why I'm stopping
    - Open questions
    - Working hypothesis
    - Recommended next step
    - Context the receiving host needs

  Flags (Unix-style, parsed from remaining args): --from <file>, --feature <ref>, --boundary <stage>,
  --host <kind>, --project-path <path>.

  This is the reachable replacement for the bare `Write-SpecrewHandoverContext` function, which is NOT a
  module export — agents invoke `specrew ...`, not module functions, so the callable surface is a command
  (drift D-005). Dispatcher-only (registered in scripts/specrew.ps1): it does NOT gate on project setup and
  is FAIL-OPEN (a missing section / unresolved feature degrades to a best-effort write, never a throw). The
  write goes through the SAME atomic writer the Stop hook uses (Write-SpecrewHandoverContext ->
  Write-SpecrewRollingHandoverContent), so it honors the centralized clobber guard (a hook-captured boundary
  packet is preserved, never clobbered) and keeps session-handover.md.old as the crash backup.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = 'author',

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Unix-style flag parse (the CLI dispatcher forwards --flag tokens, which do not bind PowerShell-style) ---
# NOTE: a flag-looking token ('--help') does NOT bind the positional $Command — it falls into $Rest — so help
# detection must scan $Rest too, not just $Command. And stdin is read ONLY behind an explicit --stdin flag: an
# open-but-empty redirected stdin (a harness / inherited pipe) would otherwise block ReadToEnd() forever.
$fromFile = $null; $feature = $null; $boundary = $null; $targetHost = $null; $projectPath = $null
$useStdin = $false; $showHelp = ($Command -in @('help', '--help', '-h'))
$remaining = @($Rest | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
for ($i = 0; $i -lt $remaining.Count; $i++) {
    $arg = $remaining[$i]
    if ($arg -in @('--help', '-h', 'help')) { $showHelp = $true }
    elseif ($arg -ieq '--stdin') { $useStdin = $true }
    elseif ($arg -match '^--from=(.+)$') { $fromFile = $Matches[1] }
    elseif ($arg -ieq '--from' -and ($i + 1) -lt $remaining.Count) { $fromFile = $remaining[++$i] }
    elseif ($arg -match '^--feature=(.+)$') { $feature = $Matches[1] }
    elseif ($arg -ieq '--feature' -and ($i + 1) -lt $remaining.Count) { $feature = $remaining[++$i] }
    elseif ($arg -match '^--boundary=(.+)$') { $boundary = $Matches[1] }
    elseif ($arg -ieq '--boundary' -and ($i + 1) -lt $remaining.Count) { $boundary = $remaining[++$i] }
    elseif ($arg -match '^--host=(.+)$') { $targetHost = $Matches[1] }
    elseif ($arg -ieq '--host' -and ($i + 1) -lt $remaining.Count) { $targetHost = $remaining[++$i] }
    elseif ($arg -match '^--project-path=(.+)$') { $projectPath = $Matches[1] }
    elseif ($arg -ieq '--project-path' -and ($i + 1) -lt $remaining.Count) { $projectPath = $remaining[++$i] }
}
if ([string]::IsNullOrWhiteSpace($projectPath)) { $projectPath = (Get-Location).Path }
# Normalize to an ABSOLUTE path: the writer's atomic .NET file APIs resolve a relative path against the
# PROCESS cwd, not the PowerShell location (a named Windows/PowerShell trap). Fail-open if it does not exist.
try { $resolved = (Resolve-Path -LiteralPath $projectPath -ErrorAction Stop).Path; if ($resolved) { $projectPath = $resolved } } catch { $null = $_ }

. (Join-Path $PSScriptRoot 'internal/bootstrap/HandoverStore.ps1')

function Write-HandoverError {
    param([string]$Message)
    Write-Host ("ERROR: {0}" -f $Message) -ForegroundColor Red
    Write-Host "Usage: specrew handover author [--from <file>] [--feature <ref>] [--boundary <stage>] [--host <kind>]" -ForegroundColor Yellow
    Write-Host "       (use --stdin to read the markdown body piped on stdin instead of --from)" -ForegroundColor Yellow
    exit 1
}

function Show-HandoverHelp {
    @'
specrew handover - author the rolling cross-session handover body (agent-callable)

Usage:
  specrew handover author [--from <file>] [--feature <ref>] [--boundary <stage>] [--host <kind>]
  <markdown> | specrew handover author --stdin   (reads the body from stdin)

Persist your re-entry / handover body so the NEXT session or host that resumes this project inherits
your AUTHORED context - especially your open questions + working hypothesis, which NO hook can author -
instead of artifact-derived placeholders. feature / boundary / host default to the committed session
state; override with the flags. The write is atomic and honors the clobber guard (a hook-captured
boundary packet is preserved).

The body is markdown; each section is a '## ' header. Recognized sections (short / tolerant headers map):
  ## What I just did
  ## Why I'm stopping
  ## Open questions
  ## Working hypothesis
  ## Recommended next step
  ## Context the receiving host needs
Unrecognized headers are reported and ignored.
'@ | Write-Host
}

function Get-AuthorableTitles {
    # The Pillar-2 handover sections the agent can author: the fixed order MINUS the hook-captured section
    # (the verbatim boundary packet) MINUS the time-scoped conversation tail (both hook-owned, not agent-authored).
    # @()-wrap the captured set: it returns a single-element list PowerShell unwraps to a bare string (see
    # Get-SpecrewHandoverCapturedSections's contract note in HandoverStore.ps1).
    $reserved = @(Get-SpecrewHandoverCapturedSections) + @(Get-SpecrewHandoverTimeScopedSections)
    return @(Get-SpecrewHandoverSectionOrder | Where-Object { $reserved -notcontains $_ })
}

function Resolve-AuthorableTitle {
    # Map an input '## ' header to a canonical authorable title: exact (normalized) first, then a tolerant
    # LEAD-PHRASE match (the canonical title up to its first '(' / '/' / '-' delimiter) so a short or
    # reordered header ('## Open questions', '## Working hypothesis', '## Context') still maps to the full
    # canonical title the writer expects. $null if nothing matches (the caller reports + skips it).
    param([string]$Header, [string[]]$Canonical)
    # Normalize: drop apostrophes (straight + the curly/modifier variants a copy-paste introduces, so a
    # body's "Agent's"/"Why I'm" still matches the canonical), collapse whitespace, lowercase.
    $norm = { param($s) ((($s -replace '[‘’ʼ'']', '') -replace '\s+', ' ').Trim()).ToLowerInvariant() }
    $h = & $norm $Header
    if ([string]::IsNullOrWhiteSpace($h)) { return $null }
    foreach ($c in $Canonical) { if ((& $norm $c) -eq $h) { return $c } }
    foreach ($c in $Canonical) {
        $cn = & $norm $c
        $lead = ((($cn -split '[(/-]', 2)[0]).Trim())
        if ([string]::IsNullOrWhiteSpace($lead)) { $lead = $cn }
        if ($cn.StartsWith($h) -or $h.StartsWith($lead) -or $lead.StartsWith($h)) { return $c }
        if ($h.Length -ge 4 -and ($cn.Contains($h) -or $lead.Contains($h))) { return $c }
    }
    return $null
}

function Invoke-Author {
    # 1. Get the input markdown. --from <file> is the primary path; stdin is read ONLY behind an explicit
    #    --stdin (so an inherited / harness pipe never blocks ReadToEnd on a body that never arrives).
    $raw = $null
    if (-not [string]::IsNullOrWhiteSpace($fromFile)) {
        $fp = $fromFile
        if (-not [System.IO.Path]::IsPathRooted($fp)) { $fp = Join-Path $projectPath $fp }
        if (-not (Test-Path -LiteralPath $fp -PathType Leaf)) { Write-HandoverError ("--from file not found: {0}" -f $fromFile) }
        $raw = Get-Content -LiteralPath $fp -Raw -Encoding UTF8
    }
    elseif ($useStdin) {
        try { $raw = [Console]::In.ReadToEnd() } catch { $raw = $null }
    }
    else {
        Write-HandoverError 'No handover body provided. Pass --from <file> (a markdown packet with `## ` sections), or --stdin to read the body piped on stdin.'
    }
    if ([string]::IsNullOrWhiteSpace($raw)) {
        Write-HandoverError 'The handover body is empty. Provide a markdown packet with `## ` section headers.'
    }

    # 2. Parse the '## ' sections with the SAME reader a resume uses (it handles a frontmatter-less body:
    #    bodyStart=0). Materialize to a temp file because ConvertFrom-SpecrewHandoverFile reads a -Path.
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-handover-in-" + [guid]::NewGuid().ToString('N') + '.md')
    [System.IO.File]::WriteAllText($tmp, $raw, [System.Text.UTF8Encoding]::new($false))
    try { $parsed = ConvertFrom-SpecrewHandoverFile -Path $tmp } finally { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
    if ($null -eq $parsed -or $null -eq $parsed.sections -or $parsed.sections.Count -eq 0) {
        Write-HandoverError 'No `## ` sections found in the input. The body must use `## <section>` markdown headers (run `specrew handover --help` for the section names).'
    }

    # 3. Map input headers -> canonical authorable titles. Unrecognized headers are reported + ignored, never written.
    $authorable = @(Get-AuthorableTitles)
    $sections = @{}
    $mapped = @(); $skipped = @(); $collisions = @()
    foreach ($key in $parsed.sections.Keys) {
        $canon = Resolve-AuthorableTitle -Header $key -Canonical $authorable
        $val = [string]$parsed.sections[$key]
        if ($null -ne $canon -and -not [string]::IsNullOrWhiteSpace($val)) {
            # Signal (don't silently swallow) two input headers that map to the SAME canonical section — the
            # second wins, so the author should know one of their headers was overwritten this write.
            if ($sections.Contains($canon)) { $collisions += ("'{0}' -> {1}" -f $key, $canon) }
            $sections[$canon] = $val; $mapped += $canon
        }
        else { $skipped += $key }
    }
    if ($sections.Count -eq 0) {
        Write-HandoverError 'None of the input `## ` headers matched a handover section. Use the canonical section names (run `specrew handover --help`).'
    }

    # 4. Resolve feature / boundary / host from the committed session state unless overridden by a flag.
    #    Safe property reads (Set-StrictMode throws on a missing property) via a null-tolerant getter.
    $getProp = {
        param($o, $n)
        if ($null -eq $o) { return $null }
        $p = $o.PSObject.Properties[$n]
        if ($p) { return $p.Value } else { return $null }
    }
    $resFeature = $feature; $resBoundary = $boundary; $resHost = $targetHost
    $ctxPath = Join-Path $projectPath '.specrew/start-context.json'
    if (Test-Path -LiteralPath $ctxPath) {
        try {
            $ctx = Get-Content -LiteralPath $ctxPath -Raw | ConvertFrom-Json
            $ss = & $getProp $ctx 'session_state'
            if ([string]::IsNullOrWhiteSpace($resFeature)) { $f = & $getProp $ss 'feature_ref'; if (-not [string]::IsNullOrWhiteSpace([string]$f)) { $resFeature = [string]$f } }
            if ([string]::IsNullOrWhiteSpace($resBoundary)) { $b = & $getProp $ss 'boundary_type'; if (-not [string]::IsNullOrWhiteSpace([string]$b)) { $resBoundary = [string]$b } }
            if ([string]::IsNullOrWhiteSpace($resHost)) {
                $hv = & $getProp $ss 'host'; if ([string]::IsNullOrWhiteSpace([string]$hv)) { $hv = & $getProp $ctx 'host' }
                if (-not [string]::IsNullOrWhiteSpace([string]$hv)) { $resHost = [string]$hv }
            }
        }
        catch { $null = $_ }
    }
    if ([string]::IsNullOrWhiteSpace($resHost)) {
        # Best-effort live-host detection (the handover provider's helper, co-loaded above) -> else the honest 'host'.
        $envHost = Get-SpecrewRuntimeHostFromEnv
        $resHost = if (-not [string]::IsNullOrWhiteSpace($envHost)) { $envHost } else { 'host' }
    }

    $head = ''
    try { $head = ([string](& git -C $projectPath rev-parse --short HEAD 2>$null)).Trim() } catch { $null = $_ }
    $nowUtc = (Get-Date).ToUniversalTime().ToString('o')
    $handoverDir = Join-Path $projectPath '.specrew/handover'

    $written = Write-SpecrewHandoverContext -HandoverDir $handoverDir -FromHost $resHost -RecordedAt $nowUtc `
        -Source 'agent' -FromCommit $head -ActiveFeature $resFeature -ActiveBoundary $resBoundary -Sections $sections

    $featureLabel = if ([string]::IsNullOrWhiteSpace($resFeature)) { '(none)' } else { $resFeature }
    $boundaryLabel = if ([string]::IsNullOrWhiteSpace($resBoundary)) { '(pre-boundary)' } else { $resBoundary }
    Write-Host ''
    Write-Host 'Specrew handover authored' -ForegroundColor Cyan
    Write-Host '-------------------------' -ForegroundColor Cyan
    Write-Host ("  file:     {0}" -f $written) -ForegroundColor Green
    Write-Host ("  feature:  {0}" -f $featureLabel)
    Write-Host ("  boundary: {0}" -f $boundaryLabel)
    Write-Host ("  host:     {0}" -f $resHost)
    Write-Host ("  sections written: {0}" -f (($mapped | Select-Object -Unique) -join ', ')) -ForegroundColor Green
    if ($skipped.Count -gt 0) {
        Write-Host ("  sections ignored (unrecognized header): {0}" -f ($skipped -join ', ')) -ForegroundColor DarkGray
    }
    if ($collisions.Count -gt 0) {
        Write-Host ("  WARNING: multiple headers mapped to one section (last wins): {0}" -f ($collisions -join '; ')) -ForegroundColor Yellow
    }
    Write-Host ''
    Write-Host 'The next session / host that resumes this project will inherit these sections (not placeholders).' -ForegroundColor Cyan
}

if ($showHelp) { Show-HandoverHelp; exit 0 }
# A flag-looking $Command (e.g. '--help') fell into the help path above; otherwise an unknown subcommand errors.
$sub = if ($Command -like '-*') { 'author' } else { $Command.ToLowerInvariant() }
switch ($sub) {
    'author' { Invoke-Author }
    default { Write-HandoverError ("Unknown subcommand '{0}'. Supported: author (run 'specrew handover --help')." -f $Command) }
}
exit 0
