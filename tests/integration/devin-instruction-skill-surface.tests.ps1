[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 200 T011 (FR-008): Devin instruction + skill surfaces.
#
# Instructions: Devin targets root AGENTS.md (shared with codex/antigravity/cursor). The host-neutral
# instruction deployer keys dedup by target PATH, so when Devin is promoted it joins the existing
# single-AGENTS.md-block dedup set automatically. This iteration Devin ships `experimental`, so the
# deployer (Deploy-SpecrewCoordinatorInstructions, Status='supported' filter) SKIPS it: there is no
# live Devin instruction deploy in iteration 002. This test asserts (a) the manifest declares
# AGENTS.md, (b) the host-neutral path-keyed dedup over the supported AGENTS.md hosts still produces
# exactly one managed block AND preserves user content byte-for-byte, and (c) Devin is excluded from
# the live supported-host deploy because it is experimental.
#
# Skills: Devin's primary native surface is `.devin/skills/` (manifest SkillRoot); it ALSO supports
# the documented shared `.agents/skills/` surface, which is deployed ambiently to every project
# regardless of host. SharedSkillRootWith=@() is semantically correct (nobody else uses
# `.devin/skills`). Live skill-catalog deployment to `.devin/skills` is deferred to promotion
# (the skill-catalog state iterates SUPPORTED hosts only). This test asserts the real resolver
# returns `.devin/skills` and that the shared `.agents/skills` surface exists ambiently.

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$registryScript = Join-Path $repoRoot 'hosts\_registry.ps1'
$detectHostsScript = Join-Path $repoRoot 'scripts\internal\detect-hosts.ps1'
$instructionDeployScript = Join-Path $repoRoot 'scripts\internal\instruction-deploy.ps1'
$deploySquadRuntimeScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\deploy-squad-runtime.ps1'

foreach ($p in @($registryScript, $detectHostsScript, $instructionDeployScript, $deploySquadRuntimeScript)) {
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { Write-Fail "Missing required file: $p" }
}

. $registryScript
. $detectHostsScript

function Write-NoBom { param([string]$Path, [string]$Text) [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false)) }

# --- Test 1: Devin manifest targets root AGENTS.md (joins the shared AGENTS.md dedup set on promotion). ---
$devinManifest = Get-HostManifest -Kind 'devin'
if ([string]$devinManifest.InstructionsFile -ne 'AGENTS.md') {
    Write-Fail "Devin InstructionsFile should be 'AGENTS.md'; got: $($devinManifest.InstructionsFile)"
}
Write-Pass "Devin manifest declares InstructionsFile = 'AGENTS.md' (shared with codex/antigravity/cursor)"

# --- Test 2: Devin is excluded from the LIVE supported-host instruction deploy (experimental status). ---
if ([string]$devinManifest.Status -ne 'experimental') {
    Write-Fail "Devin is expected to be experimental in iteration 002; got Status='$($devinManifest.Status)'."
}
. $instructionDeployScript
$proj = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-devin-instr-" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $proj -Force | Out-Null
try {
    $nl = [Environment]::NewLine
    $agentsUser = "# My AGENTS" + $nl + $nl + "USER-AGENTS-CONTENT keep me byte-for-byte." + $nl
    $agentsPath = Join-Path $proj 'AGENTS.md'
    Write-NoBom -Path $agentsPath -Text $agentsUser

    $rows = @(Deploy-SpecrewCoordinatorInstructions -ProjectRoot $proj)
    # Devin must NOT appear as a deployed row (experimental -> Status filter excludes it).
    $devinRow = @($rows | Where-Object { $_.Kind -eq 'devin' })
    if ($devinRow.Count -ne 0) {
        Write-Fail "Devin (experimental) must be excluded from the live coordinator-instruction deploy; got a row: $($devinRow | ConvertTo-Json -Compress)"
    }

    # Host-neutral path-keyed dedup over the SUPPORTED AGENTS.md hosts still yields exactly one block,
    # and the user's pre-existing content is preserved byte-for-byte at the head of the file.
    $onDisk = Get-Content -LiteralPath $agentsPath -Raw -Encoding UTF8
    $blocks = ([regex]::Matches($onDisk, 'specrew-managed coordinator')).Count
    if ($blocks -lt 1) { Write-Fail "AGENTS.md should hold the managed coordinator section after deploy; found none." }
    $startBlocks = ([regex]::Matches($onDisk, 'specrew-managed coordinator >>>')).Count
    if ($startBlocks -ne 1) { Write-Fail "AGENTS.md should hold exactly 1 managed block (path-keyed dedup); got $startBlocks." }
    if (-not $onDisk.StartsWith($agentsUser)) { Write-Fail "AGENTS.md did not preserve user content byte-for-byte at the head." }
    Write-Pass 'Devin is excluded from the live deploy (experimental); shared AGENTS.md still dedupes to 1 block + preserves user content'

    # --- Test 3: forcing the Devin kind through the deployer is a graceful no-op (experimental skip). ---
    $devinOnly = @(Deploy-SpecrewCoordinatorInstructions -ProjectRoot $proj -HostKind 'devin')
    if ($devinOnly.Count -ne 0) {
        Write-Fail "Deploying with -HostKind devin should be a graceful no-op (experimental skip); got $($devinOnly.Count) rows."
    }
    Write-Pass 'Deploy-SpecrewCoordinatorInstructions -HostKind devin is a graceful no-op (experimental skip, no shared-core Devin branch)'
}
finally {
    if (Test-Path -LiteralPath $proj) { Remove-Item -Recurse -Force -LiteralPath $proj -ErrorAction SilentlyContinue }
}

# --- Test 4: Devin primary skill root resolves to .devin/skills via the REAL resolver (non-inert). ---
$fakeProject = Join-Path ([System.IO.Path]::GetTempPath()) 'specrew-devin-skillroot-probe'
$devinSkillRoot = Get-SpecrewHostSkillRoot -HostKind 'devin' -ProjectPath $fakeProject
if ($devinSkillRoot.Replace('\', '/') -notlike '*/.devin/skills') {
    Write-Fail "Devin SkillRoot should resolve to .devin/skills; got: $devinSkillRoot"
}
Write-Pass 'Get-SpecrewHostSkillRoot resolves Devin to .devin/skills (primary native surface)'

# --- Test 5: SharedSkillRootWith is semantically correct: nobody shares Devin's .devin/skills. ---
$shared = @($devinManifest.SharedSkillRootWith)
if ($shared.Count -ne 0) {
    Write-Fail "Devin SharedSkillRootWith should be empty (no host uses .devin/skills); got: $($shared -join ',')"
}
Write-Pass 'Devin SharedSkillRootWith = @() (semantically correct: .devin/skills is not shared by another host)'

# --- Test 6: the documented shared .agents/skills surface exists ambiently (Devin reads it too). ---
# The skill-catalog deployer writes to a host-independent set of roots that includes .agents/skills,
# so the shared surface is present in every project regardless of host. We assert the deployer's
# active-root list still names .agents/skills (the surface Devin documents as also-supported).
$deployText = Get-Content -LiteralPath $deploySquadRuntimeScript -Raw -Encoding UTF8
if ($deployText -notmatch [regex]::Escape('.agents\skills') -and $deployText -notmatch [regex]::Escape('.agents/skills')) {
    Write-Fail 'The shared .agents/skills surface is no longer in the skill-catalog active roots; Devin documents it as also-supported.'
}
Write-Pass 'The documented shared .agents/skills surface is deployed ambiently (Devin supports both .devin/skills and .agents/skills)'

Write-Host ''
Write-Host 'Devin instruction + skill surface (T011): all assertions pass' -ForegroundColor Green
exit 0
