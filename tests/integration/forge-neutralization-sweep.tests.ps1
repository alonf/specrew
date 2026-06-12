[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 182 iteration 003 (T306, SC-008 / FR-019): the no-over-claim sweep.
#
# Asserts that Specrew's DOWNSTREAM-GOVERNING markdown surfaces carry no bare GitHub/PSGallery
# *mandate* — GitHub + PowerShell Gallery may appear ONLY inside a clearly-labeled non-mandatory
# example (marker: "NOT a downstream mandate"). The sweep is SCOPE-AWARE: an explicit allowlist mirrors
# the Iteration-3 neutralization inventory so it does NOT false-positive on the GitHub host adapter,
# Specrew's own infra, or audit docs that merely QUOTE the patterns. (Section-aware: a mandate token is
# allowed only when its markdown section also carries the example marker.)

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

# --- mandate tokens: a bare instruction to use GitHub/a specific registry as THE downstream flow ---
# Generic forge mandates (gh pr ...) could wrongly transfer to ANY downstream project -> require a
# SECTION-level labeled example. Specrew-self-publish + package-registry tokens either literally name
# the `Specrew` module (inherently Specrew-self-referential; a downstream project never installs
# "Specrew") or name a SPECIFIC package registry as Specrew's OWN distribution channel (PSGallery /
# PowerShell Gallery — a downstream project on a different stack would not publish there) -> a
# FILE-level example marker suffices. (Registry names recur across many sections of Specrew's own
# release docs; a per-section marker is neither expected nor authored. iter-3 D-304: the registry-name
# class widens the original 4-token set after the SC-008 broad-verification sweep found a `PSGallery`
# heading-descriptor the narrow set missed in two downstream-governing methodology index docs.)
$forgeMandates  = @('gh pr create', 'gh pr merge')
$specrewPublish = @('Find-Module Specrew', 'Install-Module Specrew', 'PSGallery', 'powershellgallery', 'PowerShell Gallery')
$exampleMarker = 'not a downstream mandate'   # case-insensitive

# --- the downstream-governing markdown surfaces to sweep ---
$surfaceRoots = @(
    'extensions/specrew-speckit/prompts',
    'extensions/specrew-speckit/squad-templates/coordinator',
    'extensions/specrew-speckit/squad-templates/agents',
    'extensions/specrew-speckit/squad-templates/skills',
    'extensions/specrew-speckit/knowledge/design-lenses',
    'docs/methodology'
)

# --- allowlist (mirrors the inventory): paths exempt because they are NOT downstream-governing ---
#     host adapter + Specrew's own infra + audit/quote docs + deploy mirror + seed histories.
$allowListSubstrings = @(
    '/skills/specrew-version/',          # own-infra: Specrew's own version-check skill
    '/skills/specrew-update/',           # own-infra: Specrew's own update skill (PSGallery version-available check)
    'deploy-speckit-extension.ps1',      # own-infra: Specrew's own installer
    '/agents/',                          # seed histories under squad-templates/agents/*/history.md (charters swept separately, clean)
    '.specify/', '.squad/', '.specrew/', 'node_modules/'
)
# charters ARE swept (the /agents/ allowlist would skip them) — re-include them explicitly.
$forceInclude = @('charter.md')

$violations = New-Object System.Collections.Generic.List[string]
$markerFilesSeen = New-Object System.Collections.Generic.List[string]
$scanned = 0

function Get-MarkdownSections {
    param([string[]]$Lines)
    $sections = New-Object System.Collections.Generic.List[string]
    $cur = New-Object System.Collections.Generic.List[string]
    foreach ($line in $Lines) {
        if ($line -match '^#{2,6}\s+') {
            $sections.Add(($cur -join "`n")) | Out-Null
            $cur = New-Object System.Collections.Generic.List[string]
        }
        $cur.Add($line) | Out-Null
    }
    $sections.Add(($cur -join "`n")) | Out-Null
    return $sections
}

foreach ($root in $surfaceRoots) {
    $full = Join-Path $repoRoot $root
    if (-not (Test-Path -LiteralPath $full)) { continue }
    foreach ($file in (Get-ChildItem -LiteralPath $full -Filter '*.md' -Recurse -File)) {
        $rel = $file.FullName.Substring($repoRoot.Length + 1).Replace('\', '/')
        $isCharter = $forceInclude | Where-Object { $rel -like "*$_" }
        if (-not $isCharter) {
            $skip = $false
            foreach ($a in $allowListSubstrings) { if ($rel -like "*$a*") { $skip = $true; break } }
            if ($skip) { continue }
        }
        $scanned++
        $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($content)) { continue }
        $fileHasMarker = ($content -match "(?i)$([regex]::Escape($exampleMarker))")
        if ($fileHasMarker) { $markerFilesSeen.Add($rel) | Out-Null }

        # Specrew-self-publish + package-registry tokens: a FILE-level example marker suffices.
        foreach ($p in $specrewPublish) {
            if ($content -match [regex]::Escape($p) -and -not $fileHasMarker) {
                $violations.Add(("{0}: Specrew-publish/registry token '{1}' appears with no file-level '{2}' example label" -f $rel, $p, $exampleMarker)) | Out-Null
            }
        }
        # Generic forge mandates (gh pr ...): require a SECTION-level example marker.
        $sections = Get-MarkdownSections -Lines ($content -split "`r?`n")
        foreach ($section in $sections) {
            foreach ($p in $forgeMandates) {
                if ($section -match [regex]::Escape($p) -and $section -notmatch "(?i)$([regex]::Escape($exampleMarker))") {
                    $violations.Add(("{0}: forge-mandate token '{1}' appears outside a labeled '{2}' example section" -f $rel, $p, $exampleMarker)) | Out-Null
                }
            }
        }
    }
}

if ($violations.Count -gt 0) {
    Write-Host "OVER-CLAIM / bare-mandate violations (SC-008):" -ForegroundColor Red
    foreach ($v in $violations) { Write-Host "  $v" -ForegroundColor Yellow }
    Write-Fail ("Found {0} bare GitHub/PSGallery mandate(s) in downstream-governing surfaces." -f $violations.Count)
}
Write-Pass ("SC-008 sweep: no bare GitHub/PSGallery mandate across {0} downstream-governing markdown surface(s)." -f $scanned)

# --- positive assertion: the 4 neutralized change-surfaces each carry the labeled example (proves they
#     were neutralized-with-an-example, not silently stripped of all guidance) ---
$mustCarryMarker = @(
    'extensions/specrew-speckit/prompts/coordinator-decision-guidance.md',
    'extensions/specrew-speckit/prompts/coordinator-response.md',
    'extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md',
    'docs/methodology/lifecycle-discipline.md'
)
foreach ($m in $mustCarryMarker) {
    $body = Get-Content -LiteralPath (Join-Path $repoRoot $m) -Raw -Encoding UTF8
    if ($body -notmatch "(?i)$([regex]::Escape($exampleMarker))") {
        Write-Fail "$m must carry the labeled '$exampleMarker' example (DP-1 (b) / DP-2)"
    }
}
Write-Pass ("SC-008 sweep: all {0} neutralized change-surfaces carry the labeled non-mandatory example." -f $mustCarryMarker.Count)

# --- D-304 completion: the two methodology INDEX docs neutralized by REMOVAL (no labeled example —
#     they merely described lifecycle-discipline.md's release section). Assert they carry no
#     registry-name descriptor, proving the broad-verification residual is closed + regression-guarded. ---
$mustBeRegistryClean = @(
    'docs/methodology/README.md',
    'docs/methodology/review-instructions.md'
)
foreach ($m in $mustBeRegistryClean) {
    $body = Get-Content -LiteralPath (Join-Path $repoRoot $m) -Raw -Encoding UTF8
    foreach ($p in @('PSGallery', 'powershellgallery', 'PowerShell Gallery')) {
        if ($body -match [regex]::Escape($p)) {
            Write-Fail "$m must carry NO registry-name descriptor ('$p' found) — it is a downstream-governing index doc with no example label (iter-3 D-304 / T303+T306 completion)"
        }
    }
}
Write-Pass ("SC-008 sweep: the {0} methodology index docs carry no registry-name descriptor (D-304 residual closed)." -f $mustBeRegistryClean.Count)

# --- the host adapter + own-infra are NOT swept here (they legitimately use GitHub) — assert the
#     allowlist is inventory-backed (the inventory file enumerates the same exclusions) ---
$inv = Get-Content -LiteralPath (Join-Path $repoRoot 'specs/182-work-kind-branch-governance/iterations/003/neutralization-inventory.md') -Raw -Encoding UTF8
foreach ($needle in @('specrew-version', 'specrew-update', 'deploy-speckit-extension.ps1', 'templates/github')) {
    if ($inv -notmatch [regex]::Escape($needle)) {
        Write-Fail "SC-008 allowlist drift: '$needle' is exempt in the sweep but not recorded in the neutralization inventory"
    }
}
Write-Pass 'SC-008 sweep: the exemption allowlist is inventory-backed (host-adapter + own-infra recorded in neutralization-inventory.md)'

# --- T307 (SC-013): Specrew's OWN infra is UNCHANGED — it still carries its GitHub usage. The
#     neutralization touched ONLY downstream-governing surfaces, never Specrew's own dev infra. ---
$ownInfra = @(
    @{ Path = '.github/workflows';   Kind = 'dir';      Why = "Specrew's own CI" }
    @{ Path = 'extensions/specrew-speckit/squad-templates/skills/specrew-version/SKILL.md'; Kind = 'contains'; Needle = 'Update-Module Specrew'; Why = "Specrew's own version-check skill" }
    @{ Path = 'extensions/specrew-speckit/scripts/deploy-speckit-extension.ps1'; Kind = 'contains'; Needle = 'Install-Module Specrew'; Why = "Specrew's own installer" }
    @{ Path = 'templates/github/agents/squad.agent.md'; Kind = 'contains'; Needle = 'gh pr'; Why = 'the GitHub host adapter agent' }
)
foreach ($o in $ownInfra) {
    $p = Join-Path $repoRoot $o.Path
    if ($o.Kind -eq 'dir') {
        if (-not (Test-Path -LiteralPath $p -PathType Container)) { Write-Fail ("SC-013: Specrew's own infra changed — {0} ({1}) is missing" -f $o.Path, $o.Why) }
    }
    else {
        $c = if (Test-Path -LiteralPath $p) { Get-Content -LiteralPath $p -Raw -Encoding UTF8 } else { '' }
        if ($c -notmatch [regex]::Escape($o.Needle)) { Write-Fail ("SC-013: Specrew's own infra changed — {0} ({1}) no longer carries '{2}'" -f $o.Path, $o.Why, $o.Needle) }
    }
}
Write-Pass ("SC-013: Specrew's own infra is unchanged — all {0} own-infra/host-adapter surfaces still carry their GitHub usage." -f $ownInfra.Count)

# --- T308: Specrew's OWN closeout flow still works — its governance opts into automated review, and the
#     neutralized change-surfaces still document Specrew's own GitHub + PSGallery steps (as examples). ---
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
$ownOptIn = Get-SpecrewAutomatedReviewOptIn -ProjectRoot $repoRoot
if (-not [bool]$ownOptIn.Enabled) { Write-Fail "T308: Specrew's own governance must still opt into automated review (provider:github Copilot) — own flow regressed" }
Write-Pass ("T308: Specrew's own governance still opts into automated review (provider_suggestion={0}) — own reviewer flow preserved." -f $ownOptIn.ProviderSuggestion)

$exampleFlow = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/prompts/coordinator-decision-guidance.md') -Raw -Encoding UTF8
if ($exampleFlow -notmatch 'gh pr create' -or $exampleFlow -notmatch 'Install-Module Specrew') {
    Write-Fail "T308: the labeled Specrew example must still document Specrew's own gh + PSGallery steps (kept documented/usable, not stripped)"
}
Write-Pass "T308: Specrew's own GitHub + PSGallery closeout steps remain documented in the labeled example (usable for Specrew, example-only for downstream)."

Write-Host "`nForge-neutralization sweep (SC-008 + SC-013 + own-flow): all assertions pass" -ForegroundColor Green
