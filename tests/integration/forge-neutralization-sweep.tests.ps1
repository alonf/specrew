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

# --- iter-4 (FR-022 / SC-015): the full SC-015 token set for the RUNTIME/DEPLOYED surfaces ---
# A runtime/deployed surface (.ps1 launch-prompt/contract generator, or a deployed per-host agent file)
# is clean when it carries NONE of these unlabeled. File-level labeled example suffices (the closeout
# SDLC is one block). Pattern-based: a FUTURE scripts/internal/launch-contract.ps1 (F-174) is caught.
$sc015Tokens = @('gh pr create', 'gh pr merge', 'Find-Module Specrew', 'Install-Module Specrew', 'PSGallery', 'PowerShell Gallery')

function Test-RuntimeSurfaceClean {
    param([string]$Rel, [string]$Content, [string]$Marker, [string[]]$Tokens)
    $local = New-Object System.Collections.Generic.List[string]
    $fileHasMarker = ($Content -match "(?i)$([regex]::Escape($Marker))")
    $isMd = $Rel -like '*.md'
    # F3 (iter-4 review): generic forge mandates (gh pr ...) on a MARKDOWN deployed-agent surface require a
    # SECTION-level marker — one labeled block (e.g. the feature-closeout example) must NOT whitewash a
    # SEPARATE unlabeled `gh pr` in another section (the Squad issue-lifecycle case). Specrew-publish
    # tokens (Find/Install-Module Specrew, PSGallery — inherently Specrew-self-referential) and ALL tokens
    # on a `.ps1` launch-prompt block (one contiguous block, no markdown sections) keep a FILE-level marker.
    $sectionScoped = @('gh pr create', 'gh pr merge')
    foreach ($t in $Tokens) {
        if ($isMd -and ($sectionScoped -contains $t)) {
            foreach ($section in (Get-MarkdownSections -Lines ($Content -split "`r?`n"))) {
                if ($section -match [regex]::Escape($t) -and $section -notmatch "(?i)$([regex]::Escape($Marker))") {
                    $local.Add(("{0}: SC-015 forge-mandate '{1}' appears outside a labeled '{2}' example SECTION" -f $Rel, $t, $Marker)) | Out-Null
                }
            }
        }
        elseif ($Content -match [regex]::Escape($t) -and -not $fileHasMarker) {
            $local.Add(("{0}: SC-015 token '{1}' appears with no file-level '{2}' example label" -f $Rel, $t, $Marker)) | Out-Null
        }
    }
    return , $local
}

# Specrew's OWN CLI / release / deploy tooling — legitimately names Install-Module Specrew / PSGallery
# because it IS Specrew's own machinery (NOT a downstream-governing prompt). Allowlisted by file name.
# A launch-prompt/contract generator (specrew-start.ps1, future launch-contract.ps1) is NOT here -> scanned.
$ps1OwnInfra = @(
    'specrew-init.ps1', 'specrew-update.ps1', 'specrew-version.ps1', 'specrew-install-shell-wrappers.ps1',
    'deploy-speckit-extension.ps1', 'deploy-squad-runtime.ps1', 'sync-boundary-state.ps1',
    'invoke-module-release.ps1', 'test-publish-harness.ps1', 'version-check.ps1', 'preflight.ps1',
    'validate-versions.ps1', 'dashboard-renderer.ps1', 'template-deploy.ps1'
)

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

# === iter-4 (FR-022 / SC-015): WIDEN beyond markdown to the RUNTIME/DEPLOYED surfaces that reach the
#     downstream crew — (a) .ps1 launch-prompt/contract GENERATORS, (b) deployed per-host agent files. ===
$ps1Scanned = 0
$agentScanned = 0

# (a) .ps1 launch-prompt/contract generators (own CLI/release tooling allowlisted by name; .specify mirror skipped).
foreach ($root in @('scripts', 'extensions/specrew-speckit/scripts')) {
    $full = Join-Path $repoRoot $root
    if (-not (Test-Path -LiteralPath $full)) { continue }
    foreach ($file in (Get-ChildItem -LiteralPath $full -Filter '*.ps1' -Recurse -File)) {
        $rel = $file.FullName.Substring($repoRoot.Length + 1).Replace('\', '/')
        if ($rel -match '(^|/)\.specify/') { continue }
        if ($ps1OwnInfra -contains (Split-Path $rel -Leaf)) { continue }
        $ps1Scanned++
        $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($content)) { continue }
        foreach ($v in (Test-RuntimeSurfaceClean -Rel $rel -Content $content -Marker $exampleMarker -Tokens $sc015Tokens)) { $violations.Add($v) | Out-Null }
    }
}

# (b) deployed per-host agent files — the assembled agent the crew actually reads in a project.
foreach ($root in @('.github/agents')) {
    $full = Join-Path $repoRoot $root
    if (-not (Test-Path -LiteralPath $full)) { continue }
    foreach ($file in (Get-ChildItem -LiteralPath $full -Filter '*.md' -Recurse -File)) {
        $rel = $file.FullName.Substring($repoRoot.Length + 1).Replace('\', '/')
        $agentScanned++
        $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($content)) { continue }
        foreach ($v in (Test-RuntimeSurfaceClean -Rel $rel -Content $content -Marker $exampleMarker -Tokens $sc015Tokens)) { $violations.Add($v) | Out-Null }
    }
}

if ($violations.Count -gt 0) {
    Write-Host "OVER-CLAIM / bare-mandate violations (SC-008 / SC-015):" -ForegroundColor Red
    foreach ($v in $violations) { Write-Host "  $v" -ForegroundColor Yellow }
    Write-Fail ("Found {0} bare GitHub/PSGallery/Specrew-release mandate(s) in downstream-governing surfaces." -f $violations.Count)
}
Write-Pass ("SC-008/SC-015 sweep: no bare mandate across {0} markdown + {1} .ps1 + {2} deployed-agent downstream-governing surface(s)." -f $scanned, $ps1Scanned, $agentScanned)

# --- positive assertion: the methodology's explicitly labeled Specrew example remains available,
#     while runtime prompt surfaces now delegate to the recorded release-model resolver. ---
$mustCarryMarker = @(
    'docs/methodology/lifecycle-discipline.md'
)
foreach ($m in $mustCarryMarker) {
    $body = Get-Content -LiteralPath (Join-Path $repoRoot $m) -Raw -Encoding UTF8
    if ($body -notmatch "(?i)$([regex]::Escape($exampleMarker))") {
        Write-Fail "$m must carry the labeled '$exampleMarker' example (DP-1 (b) / DP-2)"
    }
}
Write-Pass ("SC-008 sweep: the methodology retains its labeled non-mandatory example." )

foreach ($runtimePrompt in @(
        'extensions/specrew-speckit/prompts/coordinator-decision-guidance.md',
        'extensions/specrew-speckit/prompts/coordinator-response.md',
        'extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md'
    )) {
    $body = Get-Content -LiteralPath (Join-Path $repoRoot $runtimePrompt) -Raw -Encoding UTF8
    if ($body -notmatch 'Resolved Feature-Closeout Delivery|release[- ]model') {
        Write-Fail "$runtimePrompt must delegate feature closeout to the resolved release-model contract"
    }
}
Write-Pass 'SC-008 sweep: runtime prompts delegate closeout to the project-recorded release model.'

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

# --- T308: Specrew's OWN closeout flow still works — its governance opts into automated review, and
#     its recorded beta-stable model resolves the concrete closeout without leaking it downstream. ---
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
$ownOptIn = Get-SpecrewAutomatedReviewOptIn -ProjectRoot $repoRoot
if (-not [bool]$ownOptIn.Enabled) { Write-Fail "T308: Specrew's own governance must still opt into automated review (provider:github Copilot) — own flow regressed" }
Write-Pass ("T308: Specrew's own governance still opts into automated review (provider_suggestion={0}) — own reviewer flow preserved." -f $ownOptIn.ProviderSuggestion)

$ownReleaseModel = Resolve-SpecrewReleaseModel -ProjectRoot $repoRoot
$ownCloseout = Format-SpecrewFeatureCloseoutReleaseGuidance -ProjectRoot $repoRoot
if ($ownReleaseModel.Model -ne 'beta-stable' -or [string]::IsNullOrWhiteSpace($ownReleaseModel.PublishTarget) -or $ownCloseout -notmatch 'publish a prerelease' -or $ownCloseout -notmatch 'stable') {
    Write-Fail 'T308: Specrew governance must resolve a beta-stable closeout with a concrete publish target and prerelease validation'
}
Write-Pass ("T308: Specrew's own beta-stable closeout resolves from governance (publish_target={0}) without becoming downstream prompt text." -f $ownReleaseModel.PublishTarget)

# --- iter-4 (FR-022 / SC-015): the neutralized RUNTIME/DEPLOYED change-surfaces carry the labeled example
#     (neutralized-with-an-example, not silently stripped). These are F-182-owned current-tree surfaces. ---
$mustCarryMarkerRuntime = @(
    'scripts/specrew-start.ps1',                 # launcher: carries Specrew's own PSGallery update-check, marker-labeled
    '.github/agents/squad.agent.md'              # the deployed per-host agent file
)
foreach ($m in $mustCarryMarkerRuntime) {
    $p = Join-Path $repoRoot $m
    if (-not (Test-Path -LiteralPath $p)) { continue }
    $body = Get-Content -LiteralPath $p -Raw -Encoding UTF8
    if ($body -notmatch "(?i)$([regex]::Escape($exampleMarker))") {
        Write-Fail "$m carries the closeout SDLC but no labeled '$exampleMarker' example — neutralize it (FR-022 / T402)"
    }
}
Write-Pass ("SC-015: the {0} neutralized runtime/deployed change-surfaces carry the labeled non-mandatory example." -f $mustCarryMarkerRuntime.Count)

$launchContractBody = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts/internal/launch-contract.ps1') -Raw -Encoding UTF8
if ($launchContractBody -notmatch 'Format-SpecrewFeatureCloseoutReleaseGuidance' -or $launchContractBody -notmatch '## Resolved Feature-Closeout Delivery') {
    Write-Fail 'scripts/internal/launch-contract.ps1 must resolve closeout from project governance instead of embedding a release example'
}
Write-Pass 'SC-015: launch-contract closeout is resolver-backed rather than an embedded Specrew release example.'

# --- F-174 regression fixture: prove the widened .ps1 scan WOULD catch a future
#     scripts/internal/launch-contract.ps1 site carrying the bare mandate — WITHOUT editing F-174's
#     worktree or owning that file. Synthetic content only; F-174 neutralizes the real file post-rebase. ---
$f174FixtureRel = 'scripts/internal/launch-contract.ps1'
$f174FixtureContent = 'At feature-closeout: Step 6 create the PR with gh pr create; Step 11 PAUSE for Install-Module Specrew -AllowPrerelease validation.'
$f174Hits = Test-RuntimeSurfaceClean -Rel $f174FixtureRel -Content $f174FixtureContent -Marker $exampleMarker -Tokens $sc015Tokens
if (@($f174Hits).Count -lt 1) {
    Write-Fail "F-174 regression: the widened .ps1 sweep MUST flag a launch-contract.ps1-style site carrying the bare mandate (it did not) — F-182's reconciliation guard is broken"
}
Write-Pass ("SC-015 F-174 regression: the .ps1 scan flags a synthetic '{0}' mandate ({1} hit(s)) — F-182's widened sweep WILL catch F-174's site at reconciliation." -f $f174FixtureRel, @($f174Hits).Count)

Write-Host "`nForge-neutralization sweep (SC-008 + SC-013 + SC-015 + own-flow): all assertions pass" -ForegroundColor Green
