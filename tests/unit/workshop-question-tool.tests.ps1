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
#
# T029 (B4F-131, seen again on the 2026-10-20 re-walk): Copilot asked the product-domain question, the first question
# about a new feature, through its question box, and the box answer recorded nothing. The guidance kept the picker for
# "clarify questions" without saying that a question about what to build is not one, never named Copilot's own tool,
# and the Codex and Claude bindings said to use their question tool "for human approval gates". The scan now also covers
# the coordinator template, the refocus files, the commands and the design lenses, and reads the guidance each host is
# actually given.
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
    @(Get-ChildItem -LiteralPath (Join-Path $repoRoot 'templates') -Recurse -File -Include '*.md')
    @(Get-ChildItem -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/refocus') -Recurse -File -Include '*.md')
    @(Get-ChildItem -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/commands') -Recurse -File -Include '*.md')
    @(Get-ChildItem -LiteralPath (Join-Path $repoRoot 'extensions/specrew-speckit/knowledge/design-lenses') -Recurse -File -Include '*.md')
)
Assert-True ($shipped.Count -gt 20) ("the scan covers the shipped instructions ({0} files)" -f $shipped.Count)

# Text that permits a picker or question tool where a workshop question would be asked.
$permitting = @(
    @{ Name = 'a picker in a design discussion stays'; Pattern = '(?is)picker\s+in\s+a\s+design\s+discussion' }
    @{ Name = 'an explicit interactive question'; Pattern = '(?is)explicit\s+interactive\s+question' }
    @{ Name = 'use the question tool or picker for a workshop, lens or design question'; Pattern = '(?is)\buse\s+(?:the\s+|your\s+)?(?:ask_user|AskUserQuestion|question\s+(?:tool|box)|picker)\b[^.\n]{0,80}\b(?:workshop|lens|design)\b' }
    @{ Name = 'use the question tool for human approval gates'; Pattern = '(?is)\buse\b[^.\n]{0,100}\bfor\s+human\s+approval\s+gates' }
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

# Every shipped text that keeps a picker or structured choices for clarify questions also says that a question about
# what to build is never a clarify question, so the first question about a new feature cannot be read as one.
$clarifyPicker = '(?is)clarify\s+questions?[^.\n]{0,120}(?:picker|structured\s+(?:choices|primitive))'
$notClarify = '(?is)never\s+a\s+clarify\s+question'
$keepsPicker = @(foreach ($file in $shipped) {
        $text = [IO.File]::ReadAllText($file.FullName)
        if ($text -match $clarifyPicker -and $text -notmatch $notClarify) { [IO.Path]::GetRelativePath($repoRoot, $file.FullName).Replace('\', '/') }
    })
Assert-True ($keepsPicker.Count -eq 0) ("every text that keeps a picker for clarify questions says a question about what to build is never one ({0})" -f ($keepsPicker -join ', '))

# The guidance each host is given, as the launch composes it.
. (Join-Path $repoRoot 'scripts/internal/detect-hosts.ps1')
. (Join-Path $repoRoot 'scripts/internal/coordinator-prompt-surgery.ps1')
foreach ($hostKind in 'claude', 'codex', 'copilot', 'cursor', 'antigravity') {
    $block = Get-SpecrewHostInteractionGuidanceBlock -HostKind $hostKind
    Assert-True ($block -match '(?is)product-domain[^.]{0,240}\bnever\s+a\s+clarify\s+question') ("[{0}] the guidance says the product-domain question is never a clarify question" -f $hostKind)
    Assert-True ($block -notmatch '(?is)for\s+human\s+approval\s+gates') ("[{0}] the guidance does not offer the question tool for approval gates" -f $hostKind)
}
$copilotBlock = Get-SpecrewHostInteractionGuidanceBlock -HostKind 'copilot'
Assert-True ($copilotBlock -match '(?is)\bask_user\b[^.]{0,200}\b(?:never|not)\b') "[copilot] the guidance names Copilot's question tool, ask_user, and keeps it out of workshop questions"
Assert-True ($copilotBlock -match 'No structured question/menu primitive is declared') '[copilot] ask_user is named without being declared as a structured primitive'

# The product-domain lens itself says how its question is asked.
$lens = [IO.File]::ReadAllText((Join-Path $repoRoot 'extensions/specrew-speckit/knowledge/design-lenses/product-domain.md'))
Assert-True ($lens -match '(?is)visible\s+prose[^.]{0,200}never\s+through\s+a\s+question\s+tool') 'the product-domain lens says its question is visible prose, never through a question tool'

if ($script:Failures -gt 0) { Write-Host ("workshop-question-tool: {0} FAILED" -f $script:Failures); exit 1 }
Write-Host 'workshop-question-tool: all passed'
exit 0
