# Paired honesty tests for the self-leak firewall lint (F-198 FR-033/FR-037,
# NFR-007): the legitimate path works AND the abuse path fails, with
# message-content assertions (agent-action transparency).

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$lintScript = Join-Path $repoRoot 'scripts\internal\lint-self-leak.ps1'
$shippedDenyList = Join-Path $repoRoot 'extensions\specrew-speckit\data\self-leak-deny-list.json'
$script:failCount = 0

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }

function Invoke-Lint {
    param([string]$FixtureRoot, [string[]]$ExtraArgs = @())
    $output = & pwsh -NoProfile -File $lintScript -ProjectRoot $FixtureRoot -ManifestPath (Join-Path $FixtureRoot 'Fixture.psd1') -DenyListPath (Join-Path $FixtureRoot 'deny-list.json') @ExtraArgs 2>&1 | Out-String
    [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = $output }
}

function New-Fixture {
    param([string]$Name)
    $root = Join-Path ([System.IO.Path]::GetTempPath()) ("self-leak-lint-{0}-{1}" -f $Name, [guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Force -Path (Join-Path $root 'templates') | Out-Null
    # Fixture deny-list: one canonical entry per class, mirroring the shipped
    # taxonomy so the mechanism is proven per class deterministically.
    @'
{
  "schema_version": "1.0",
  "entries": [
    { "pattern": "(?i)FakeGallery", "class": "registry", "reason": "fixture registry fact", "source": "fixture", "added": "2026-07-10" },
    { "pattern": "(?i)fixture-release-mandate", "class": "release-model", "reason": "fixture release fact", "source": "fixture", "added": "2026-07-10" },
    { "pattern": "(?i)owner/self-repo", "class": "repo-ref", "reason": "fixture repo fact", "source": "fixture", "added": "2026-07-10" },
    { "pattern": "(?i)X:\\\\FixtureDev\\\\tool", "class": "dev-path", "reason": "fixture dev path", "source": "fixture", "added": "2026-07-10" },
    { "pattern": "(?i)\\bFIX-42\\b", "class": "feature-id", "reason": "fixture feature id", "source": "fixture", "added": "2026-07-10" },
    { "pattern": "(?i)fixture-proposals/\\d{3}", "class": "decision-ref", "reason": "fixture decision ref", "source": "fixture", "added": "2026-07-10" },
    { "pattern": "(?i)\\bFixtureMaintainer\\b", "class": "maintainer-id", "reason": "fixture maintainer id", "source": "fixture", "added": "2026-07-10" }
  ]
}
'@ | Set-Content -LiteralPath (Join-Path $root 'deny-list.json') -Encoding UTF8
    @'
@{
    ModuleVersion = '0.0.1'
    FileList = @(
        'templates/seeded.md',
        'templates/seeded.yml',
        'templates/clean.md',
        'docs/module-doc.md'
    )
}
'@ | Set-Content -LiteralPath (Join-Path $root 'Fixture.psd1') -Encoding UTF8
    'This template is entirely neutral consumer content.' | Set-Content -LiteralPath (Join-Path $root 'templates\clean.md') -Encoding UTF8
    New-Item -ItemType Directory -Force -Path (Join-Path $root 'docs') | Out-Null
    'Module doc naming FakeGallery on purpose - NOT consumer-deployed, must never be scanned.' | Set-Content -LiteralPath (Join-Path $root 'docs\module-doc.md') -Encoding UTF8
    $root
}

Write-Host "Test 1: shipped deny-list shape (FR-037)"
$shipped = Get-Content -LiteralPath $shippedDenyList -Raw | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace([string]$shipped.schema_version)) { Write-Fail "shipped deny-list has no schema_version" } else { Write-Pass "shipped schema_version present ($($shipped.schema_version))" }
$knownClasses = @('release-model', 'dev-path', 'feature-id', 'maintainer-id', 'registry', 'repo-ref', 'decision-ref')
$shapeOk = $true
foreach ($entry in $shipped.entries) {
    foreach ($field in @('pattern', 'class', 'reason', 'source', 'added')) {
        if ([string]::IsNullOrWhiteSpace([string]$entry.$field)) { Write-Fail "shipped entry missing '$field' ($($entry.pattern))"; $shapeOk = $false }
    }
    if ($entry.class -notin $knownClasses) { Write-Fail "shipped entry class '$($entry.class)' not in the known taxonomy"; $shapeOk = $false }
    try { [regex]::new([string]$entry.pattern) | Out-Null } catch { Write-Fail "shipped pattern does not compile: $($entry.pattern)"; $shapeOk = $false }
}
if ($shapeOk) { Write-Pass "all $(@($shipped.entries).Count) shipped entries carry the full shape, known classes, compiling regexes" }
$coveredClasses = @($shipped.entries | ForEach-Object { $_.class } | Sort-Object -Unique)
if (@($knownClasses | Where-Object { $_ -notin $coveredClasses }).Count -eq 0) { Write-Pass "shipped seed covers all seven classes" } else { Write-Fail "shipped seed misses classes: $(@($knownClasses | Where-Object { $_ -notin $coveredClasses }) -join ', ')" }

Write-Host "Test 2: seeded leak per class -> RED naming file/term/class (paired: abuse fails)"
$seedStrings = @{
    'registry'      = 'install from FakeGallery today'
    'release-model' = 'always follow the fixture-release-mandate'
    'repo-ref'      = 'clone owner/self-repo first'
    'dev-path'      = 'see X:\FixtureDev\tool for details'
    'feature-id'    = 'as FIX-42 established'
    'decision-ref'  = 'read fixture-proposals/031 for rationale'
    'maintainer-id' = 'ask FixtureMaintainer for approval'
}
foreach ($class in $seedStrings.Keys) {
    $fixture = New-Fixture -Name $class
    $seedStrings[$class] | Set-Content -LiteralPath (Join-Path $fixture 'templates\seeded.md') -Encoding UTF8
    'neutral' | Set-Content -LiteralPath (Join-Path $fixture 'templates\seeded.yml') -Encoding UTF8
    $result = Invoke-Lint -FixtureRoot $fixture
    if ($result.ExitCode -ne 1) { Write-Fail "class '$class': expected exit 1, got $($result.ExitCode)" }
    elseif ($result.Output -notmatch [regex]::Escape('templates/seeded.md') -or $result.Output -notmatch [regex]::Escape("class: $class")) { Write-Fail "class '$class': red output does not name the file and class" }
    else { Write-Pass "class '$class': seeded leak reds with file+class named" }
    Remove-Item -Recurse -Force $fixture
}

Write-Host "Test 3: annotations sanction hits (paired: legitimate path works)"
$fixture = New-Fixture -Name 'annotated'
"# specrew-self-ok: fixture same-line reason`ninstall from FakeGallery today" | Set-Content -LiteralPath (Join-Path $fixture 'templates\seeded.yml') -Encoding UTF8
"<!-- specrew-self-ok: fixture line-above reason -->`nask FixtureMaintainer for approval" | Set-Content -LiteralPath (Join-Path $fixture 'templates\seeded.md') -Encoding UTF8
$result = Invoke-Lint -FixtureRoot $fixture
if ($result.ExitCode -ne 0) { Write-Fail "annotated fixture: expected exit 0, got $($result.ExitCode): $($result.Output)" }
elseif ($result.Output -notmatch '\[annotated\]') { Write-Fail "annotated hits are not listed with reasons (transparency)" }
else { Write-Pass "same-line (# yml) and line-above (md HTML) annotations sanction; annotated hits listed" }
Remove-Item -Recurse -Force $fixture

Write-Host "Test 4: annotation WITHOUT reason is unannotated -> RED"
$fixture = New-Fixture -Name 'noreason'
"<!-- specrew-self-ok: -->`nask FixtureMaintainer for approval" | Set-Content -LiteralPath (Join-Path $fixture 'templates\seeded.md') -Encoding UTF8
'neutral' | Set-Content -LiteralPath (Join-Path $fixture 'templates\seeded.yml') -Encoding UTF8
$result = Invoke-Lint -FixtureRoot $fixture
if ($result.ExitCode -ne 1) { Write-Fail "missing-reason annotation: expected exit 1, got $($result.ExitCode)" } else { Write-Pass "missing-reason annotation treated as unannotated (red)" }
Remove-Item -Recurse -Force $fixture

Write-Host "Test 4b: WRONG comment form per file kind is unannotated -> RED (abuse path, review catch b12861a6)"
$fixture = New-Fixture -Name 'wrongform'
"# specrew-self-ok: hash form is not valid in markdown`nask FixtureMaintainer for approval" | Set-Content -LiteralPath (Join-Path $fixture 'templates\seeded.md') -Encoding UTF8
"<!-- specrew-self-ok: html form is not valid in yml -->`ninstall from FakeGallery today" | Set-Content -LiteralPath (Join-Path $fixture 'templates\seeded.yml') -Encoding UTF8
$result = Invoke-Lint -FixtureRoot $fixture
if ($result.ExitCode -ne 1) { Write-Fail "wrong-form annotations: expected exit 1, got $($result.ExitCode): $($result.Output)" }
elseif (($result.Output -notmatch [regex]::Escape('templates/seeded.md')) -or ($result.Output -notmatch [regex]::Escape('templates/seeded.yml'))) { Write-Fail "wrong-form annotations: both malformed suppressions must red" }
else { Write-Pass "hash-in-md and html-in-yml suppressions are rejected (form validated by extension)" }
Remove-Item -Recurse -Force $fixture

Write-Host "Test 5: clean surface -> green; non-consumer files never scanned"
$fixture = New-Fixture -Name 'clean'
'neutral one' | Set-Content -LiteralPath (Join-Path $fixture 'templates\seeded.md') -Encoding UTF8
'neutral two' | Set-Content -LiteralPath (Join-Path $fixture 'templates\seeded.yml') -Encoding UTF8
$result = Invoke-Lint -FixtureRoot $fixture
if ($result.ExitCode -ne 0) { Write-Fail "clean fixture: expected exit 0, got $($result.ExitCode): $($result.Output)" }
else { Write-Pass "clean surface green even though docs/module-doc.md contains a deny term (module docs are not consumer-deployed)" }
Remove-Item -Recurse -Force $fixture

Write-Host "Test 6: unreadable rule surface -> exit 2, loud (never silent green)"
$fixture = New-Fixture -Name 'corrupt'
'{{{ not json' | Set-Content -LiteralPath (Join-Path $fixture 'deny-list.json') -Encoding UTF8
'neutral' | Set-Content -LiteralPath (Join-Path $fixture 'templates\seeded.md') -Encoding UTF8
'neutral' | Set-Content -LiteralPath (Join-Path $fixture 'templates\seeded.yml') -Encoding UTF8
$result = Invoke-Lint -FixtureRoot $fixture
if ($result.ExitCode -ne 2) { Write-Fail "corrupt deny-list: expected exit 2, got $($result.ExitCode)" }
elseif ($result.Output -notmatch 'UNREADABLE RULE SURFACE') { Write-Fail "exit-2 output does not name the unreadable rule surface" }
else { Write-Pass "corrupt deny-list fails loud with exit 2" }
Remove-Item -Recurse -Force (Join-Path $fixture 'deny-list.json')
$result = Invoke-Lint -FixtureRoot $fixture
if ($result.ExitCode -ne 2) { Write-Fail "missing deny-list: expected exit 2, got $($result.ExitCode)" } else { Write-Pass "missing deny-list fails loud with exit 2" }
Remove-Item -Recurse -Force $fixture

Write-Host "Test 7: red output teaches the escape and the rule doc (FR-034)"
$fixture = New-Fixture -Name 'teaching'
'install from FakeGallery today' | Set-Content -LiteralPath (Join-Path $fixture 'templates\seeded.md') -Encoding UTF8
'neutral' | Set-Content -LiteralPath (Join-Path $fixture 'templates\seeded.yml') -Encoding UTF8
$result = Invoke-Lint -FixtureRoot $fixture
if ($result.Output -notmatch [regex]::Escape('specrew-self-ok:') -or $result.Output -notmatch [regex]::Escape('docs/methodology/self-leak-firewall.md')) {
    Write-Fail "red output does not teach the annotation escape + rule doc"
} else { Write-Pass "red output names the escape syntax and docs/methodology/self-leak-firewall.md" }
Remove-Item -Recurse -Force $fixture

Write-Host "Test 8: scan surface == deploy allowlist (manifest-derived; real repo)"
$surface = & pwsh -NoProfile -File $lintScript -ProjectRoot $repoRoot -ListSurfaceOnly 2>&1
if ($LASTEXITCODE -ne 0) { Write-Fail "-ListSurfaceOnly failed: $surface" }
else {
    $manifest = Import-PowerShellDataFile -LiteralPath (Join-Path $repoRoot 'Specrew.psd1')
    $expected = @($manifest.FileList | Where-Object {
            $n = ([string]$_) -replace '\\', '/'
            ($n -like 'templates/*' -or $n -like 'squad-templates/*' -or $n -like 'extensions/specrew-speckit/*') -and
            ($n -ne 'extensions/specrew-speckit/data/self-leak-deny-list.json') -and
            (Test-Path -LiteralPath (Join-Path $repoRoot $_))
        })
    $actual = @($surface | ForEach-Object { [string]$_ })
    $diff = Compare-Object -ReferenceObject $expected -DifferenceObject $actual
    if ($null -eq $diff) { Write-Pass "resolved surface ($($actual.Count) files) == FileList consumer-deployed subset minus the rule file" }
    else { Write-Fail ("surface mismatch: " + (($diff | ForEach-Object { "{0} {1}" -f $_.SideIndicator, $_.InputObject }) -join '; ')) }
}

Write-Host "Test 9: the real repo deploy surface is green (born-clean guard)"
$real = & pwsh -NoProfile -File $lintScript -ProjectRoot $repoRoot 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) { Write-Fail "real repo lint is not green: $real" } else { Write-Pass "real repo deploy surface green (annotated debt recorded with reasons)" }

Write-Host ""
if ($script:failCount -gt 0) { Write-Host "$script:failCount test(s) FAILED" -ForegroundColor Red; exit 1 }
Write-Host "All self-leak-lint paired tests passed." -ForegroundColor Green
exit 0
