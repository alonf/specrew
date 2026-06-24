[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 200 T009 (FR-012): parser-collision boundary guard. Proves the collision boundary that
# Feature 200 must hold:
#   (a) scripts/internal/bootstrap/ConversationCaptureAccessor.ps1 has ZERO diff vs HEAD — the
#       forbidden file is never modified by this feature (git diff --exit-code on that path).
#   (b) the UNCHANGED parser consumes the in-package Devin-normalized JSONL (the T008 output).
# Together these show the in-package normalizer reaches the parser's existing shape WITHOUT any
# parser/accessor change (spike outcome 2; no Slice B).

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$accessorRel = 'scripts/internal/bootstrap/ConversationCaptureAccessor.ps1'
$accessorScript = Join-Path $repoRoot ($accessorRel -replace '/', [System.IO.Path]::DirectorySeparatorChar)
$adapterScript = Join-Path $repoRoot 'hosts\devin\handover-adapter.ps1'

foreach ($p in @($accessorScript, $adapterScript)) {
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { Write-Fail "Missing required file: $p" }
}

# --- Test 1 (a): the forbidden accessor file has ZERO diff vs HEAD. ---
# Run git from the repo root; scope the diff to the single forbidden path. --exit-code makes git
# return 1 when there is any (tracked) difference. We check BOTH the unstaged and staged states.
Push-Location $repoRoot
try {
    & git diff --quiet --exit-code -- $accessorRel
    $unstagedClean = ($LASTEXITCODE -eq 0)
    & git diff --quiet --exit-code --cached -- $accessorRel
    $stagedClean = ($LASTEXITCODE -eq 0)
}
finally {
    Pop-Location
}
if (-not $unstagedClean) {
    Write-Fail "FORBIDDEN EDIT: $accessorRel has unstaged changes vs HEAD. Feature 200 (FR-012) must not modify the transcript parser."
}
if (-not $stagedClean) {
    Write-Fail "FORBIDDEN EDIT: $accessorRel has staged changes vs HEAD. Feature 200 (FR-012) must not modify the transcript parser."
}
Write-Pass "ConversationCaptureAccessor.ps1 is zero-diff vs HEAD (FR-012 forbidden file unmodified)"

# --- Test 2 (b): the UNCHANGED parser consumes the in-package normalized JSONL. ---
. $adapterScript
. $accessorScript

$atif = @'
{"atif_version":"1.7","steps":[
  {"source":"user","message":"boundary collision guard probe"},
  {"source":"agent","message":"normalized turn read by the unchanged parser"}
]}
'@
$jsonl = ConvertFrom-DevinAtifToParserJsonl -Atif $atif
$lines = @($jsonl -split "`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
if ($lines.Count -ne 2) { Write-Fail "Normalizer produced $($lines.Count) lines; expected 2." }

$parsed = New-Object System.Collections.Generic.List[object]
foreach ($l in $lines) {
    $tn = Get-SpecrewConversationTurnFromLine -Line $l
    if ($null -ne $tn) { $parsed.Add($tn) | Out-Null }
}
if ($parsed.Count -ne 2) {
    Write-Fail "Unchanged parser consumed $($parsed.Count) turns from the in-package normalized JSONL; expected 2 (collision boundary not proven)."
}
if ([string]$parsed[0].role -ne 'user' -or [string]$parsed[1].role -ne 'assistant') {
    Write-Fail "Parser read unexpected roles: '$($parsed[0].role)','$($parsed[1].role)' (expected user,assistant)."
}
Write-Pass "UNCHANGED parser consumes the in-package Devin-normalized JSONL (collision boundary proven: in-package adapter reaches the existing shape, no parser change)"

Write-Host "`nDevin parser-collision boundary guard: all assertions pass" -ForegroundColor Green
exit 0
