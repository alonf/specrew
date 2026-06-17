[CmdletBinding()]
param()

# Unit tests for scripts/internal/instruction-file-merge.ps1 (F-184 iteration 002 / T002).
# Exercises the REAL merge primitive + the single-source fragment accessor: delimited
# managed-section insert/refresh, byte-for-byte preservation of content outside the
# section (FR-012/SC-012), idempotence, the exact FR-013 guard text (SC-013), the lean
# size budget vs the Codex 32 KiB AGENTS.md cap, and the file-deploy round-trip.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; throw $m }

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$sut = Join-Path $repoRoot 'scripts/internal/instruction-file-merge.ps1'
if (-not (Test-Path -LiteralPath $sut)) { Write-Fail "SUT not found: $sut" }
. $sut

$nl = [Environment]::NewLine
$managed = "## Specrew Coordinator" + $nl + $nl + "Guard line and lifecycle contract."

# 1. insert into empty content
$r = Merge-SpecrewManagedInstructionSection -ExistingContent '' -ManagedContent $managed
if ($r -notmatch '<!-- >>> specrew-managed coordinator >>> -->') { Write-Fail "missing begin marker" }
if ($r -notmatch '<!-- <<< specrew-managed coordinator <<< -->') { Write-Fail "missing end marker" }
Write-Pass "inserts the delimited coordinator section into empty content"

# 2. byte-for-byte user-content preservation on append (FR-012/SC-012)
$user = "# My Project" + $nl + $nl + "User rules here." + $nl
$r = Merge-SpecrewManagedInstructionSection -ExistingContent $user -ManagedContent $managed
if (-not $r.StartsWith($user)) { Write-Fail "append did not preserve leading user content byte-for-byte" }
Write-Pass "preserves user content byte-for-byte on append (FR-012/SC-012)"

# 3. refresh in place: preserve outside content, leave exactly one block
$first = Merge-SpecrewManagedInstructionSection -ExistingContent $user -ManagedContent $managed
$refreshed = Merge-SpecrewManagedInstructionSection -ExistingContent $first -ManagedContent ($managed + $nl + 'NEW-MARKER-LINE')
if (-not $refreshed.StartsWith($user)) { Write-Fail "refresh did not preserve the user prefix byte-for-byte" }
if ($refreshed -notmatch 'NEW-MARKER-LINE') { Write-Fail "refresh did not update the managed content" }
$count = ([regex]::Matches($refreshed, 'specrew-managed coordinator >>>')).Count
if ($count -ne 1) { Write-Fail "expected exactly 1 managed block, got $count" }
Write-Pass "refreshes in place, preserves outside content, exactly one block"

# 4. idempotence
$a = Merge-SpecrewManagedInstructionSection -ExistingContent ("user content" + $nl) -ManagedContent $managed
$b = Merge-SpecrewManagedInstructionSection -ExistingContent $a -ManagedContent $managed
if ($b -ne $a) { Write-Fail "merge is not idempotent" }
Write-Pass "idempotent: re-running with the same managed content yields identical output"

# 5. preserve unrelated GEMINI.md-style content outside the section
$user2 = "# AGENTS" + $nl + $nl + "KEEP-THIS-GEMINI-CONTENT" + $nl
$r = Merge-SpecrewManagedInstructionSection -ExistingContent $user2 -ManagedContent $managed
if ($r -notmatch 'KEEP-THIS-GEMINI-CONTENT') { Write-Fail "did not preserve unrelated content" }
Write-Pass "preserves an unrelated GEMINI.md-style block outside the section"

# 6. exact FR-013 guard text in the single-source fragment (SC-013/FR-018)
$frag = Get-SpecrewCoordinatorFragment
if ($frag -notmatch [regex]::Escape('You are the Specrew Crew coordinator.')) { Write-Fail "fragment missing coordinator sentence" }
if ($frag -notmatch [regex]::Escape('Do NOT run the raw specify.exe workflow / bundled SDD engine - it bypasses the governed boundary gates.')) { Write-Fail "fragment missing exact FR-013 guard text" }
Write-Pass "fragment carries the exact FR-013 anti-specify.exe guard text (single source)"

# 7. lean size budget vs the Codex 32 KiB AGENTS.md concatenation cap
$bytes = [System.Text.Encoding]::UTF8.GetByteCount($frag)
if ($bytes -gt 4096) { Write-Fail "fragment $bytes bytes exceeds the lean 4096-byte budget" }
Write-Pass "fragment within the lean size budget ($bytes/4096 bytes)"

# 8. file-deploy round-trip: create, then idempotent no-op
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-instr-" + [System.IO.Path]::GetRandomFileName() + ".md")
try {
    $res1 = Set-SpecrewInstructionFileSection -Path $tmp -ManagedContent $managed
    if (-not $res1.Created) { Write-Fail "first deploy should report Created" }
    if (-not $res1.Changed) { Write-Fail "first deploy should report Changed" }
    $res2 = Set-SpecrewInstructionFileSection -Path $tmp -ManagedContent $managed
    if ($res2.Changed) { Write-Fail "second identical deploy should be a no-op (idempotent)" }
    $onDisk = Get-Content -LiteralPath $tmp -Raw -Encoding UTF8
    if ($onDisk -notmatch 'specrew-managed coordinator') { Write-Fail "deployed file missing the managed section" }
    Write-Pass "Set-SpecrewInstructionFileSection: create + idempotent refresh round-trip"
}
finally {
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
}

Write-Host ""
Write-Host "All instruction-file-merge tests passed." -ForegroundColor Green
