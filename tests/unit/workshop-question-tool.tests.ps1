# Feature 202 iteration 002, T021 (FR-032; B4F-131): no instruction shipped to any host permits a question tool for
# workshop questions.
#
# On the 202 live walk, Copilot asked its lens questions through its question box, and a box answer records no receipt,
# so the human was asked again in chat. The workshop skill already said never to; the conflicting rule was elsewhere:
# the boundary-stop skill, which every host also reads, said a picker "in a design discussion ... is doing good work
# and stays", and the launch instructions asked for "an explicit interactive question" where the workshop rule wants
# typed prose. Workshop answers are recorded, so no shipped text may say otherwise.
#
# A text test over every shipped host instruction and skill: the templates the hosts are given, the host bindings, and
# the scripts that compose launch and coordinator instructions. Frozen fixtures under tests/ are not shipped.
$ErrorActionPreference = 'Stop'
$script:Failures = 0
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Host ('  PASS: ' + $Message) } else { Write-Host ('  FAIL: ' + $Message); $script:Failures++ } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Write-Host 'workshop-question-tool'

$shipped = @(
    @(Get-ChildItem -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/squad-templates') -Recurse -File -Include '*.md', '*.yml', '*.yaml', '*.json')
    @(Get-ChildItem -LiteralPath (Join-Path $repoRoot 'hosts') -Recurse -File -Include '*.md', '*.psd1', '*.json')
    @(Get-Item -LiteralPath (Join-Path $repoRoot 'scripts/internal/launch-contract.ps1'))
    @(Get-Item -LiteralPath (Join-Path $repoRoot 'scripts/internal/coordinator-prompt-surgery.ps1'))
)
Assert-True ($shipped.Count -gt 20) ("the scan covers the shipped instructions ({0} files)" -f $shipped.Count)

# Text that permits a picker or question tool where a workshop question would be asked.
$permitting = @(
    @{ Name = 'a picker in a design discussion stays'; Pattern = '(?is)picker\s+in\s+a\s+design\s+discussion' }
    @{ Name = 'an explicit interactive question'; Pattern = '(?is)explicit\s+interactive\s+question' }
    @{ Name = 'use the question tool or picker for a workshop, lens or design question'; Pattern = '(?is)\buse\s+(?:the\s+|your\s+)?(?:ask_user|AskUserQuestion|question\s+(?:tool|box)|picker)\b[^.\n]{0,80}\b(?:workshop|lens|design)\b' }
)
foreach ($rule in $permitting) {
    $hits = @(foreach ($file in $shipped) {
            $text = [IO.File]::ReadAllText($file.FullName)
            if ($text -match $rule.Pattern) { [IO.Path]::GetRelativePath($repoRoot, $file.FullName).Replace('\', '/') }
        })
    Assert-True ($hits.Count -eq 0) ("no shipped instruction says: {0} ({1})" -f $rule.Name, ($hits -join ', '))
}

# The boundary-stop skill keeps pickers for exchanges nothing records, and says workshop questions are not one of them.
$gateStop = [IO.File]::ReadAllText((Join-Path $repoRoot 'extensions/specrew-speckit/squad-templates/skills/gate-stop.md'))
Assert-True ($gateStop -match '(?is)workshop\s+questions?[^.]{0,160}never\s+asked\s+through\s+a\s+picker') 'the boundary-stop skill says workshop questions are never asked through a picker'

if ($script:Failures -gt 0) { Write-Host ("workshop-question-tool: {0} FAILED" -f $script:Failures); exit 1 }
Write-Host 'workshop-question-tool: all passed'
exit 0
