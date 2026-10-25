# PRED-BETA4-055 / B4F-097, B4F-098: THE AGENDA STEP SAYS "PASTE INTO YOUR OWN MESSAGE"; THE AGENDA ACCEPTS A
# NATURAL CONFIRMATION - ONE RULE, STATED WHERE THE COORDINATOR READS IT AND PINNED WHERE THE RECEIPT IS WRITTEN.
#
# Field, the walk project on e9334af1: the coordinator ran -RenderOnly as a tool call and never carried the block
# into its message ("send the command's complete output" reads, to a coordinator, as satisfied by a tool result);
# then "yes" cost a re-ask while a lens binds any typed reply. The receipt writer already binds any non-skip,
# non-delegation reply on the agenda; the words were never named where the coordinator reads. Through the REAL
# handover provider at UserPromptSubmit on a visible-agenda fixture (digest bound).
# Mutation (recorded, not a switch): the classifier's agenda branch narrowed to the literal `confirm` reds the
# yes/ok/looks-right receipts and nothing else.

$ErrorActionPreference = 'Stop'
$script:Failures = 0
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Host ('  PASS: ' + $Message) } else { Write-Host ('  FAIL: ' + $Message); $script:Failures++ } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$provider = Join-Path $repoRoot 'scripts/internal/specrew-handover-provider.ps1'
$storeSource = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/workshop-authority-store.ps1'
. $storeSource

function New-VisibleAgendaFixture {
    $root = Join-Path ([IO.Path]::GetTempPath()) ('wav-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    $feature = '001-mail-summary'
    foreach ($d in @('.specrew/handover', '.specrew/runtime', '.specify/extensions/specrew-speckit/scripts', "specs/$feature/workshop")) {
        New-Item -ItemType Directory -Path (Join-Path $root $d) -Force | Out-Null
    }
    Copy-Item -LiteralPath $storeSource -Destination (Join-Path $root '.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1') -Force
    Set-Content -LiteralPath (Join-Path $root '.specrew/config.yml') -Value 'version: 1' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root "specs/$feature/spec.md") -Value '# Mail Summary' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root "specs/$feature/workshop/product-domain.md") -Value "# Product`n`ndone" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root "specs/$feature/workshop/product-domain.yml") -Value "schema: v1`n" -Encoding UTF8
    $controller = [ordered]@{ human_turn_contract = 'typed-turns-v1'; agenda_contract = 'complete-coverage-v1'; agenda_status = 'pending-confirmation'; selected = @('architecture-core'); workshop = @{} }
    [IO.File]::WriteAllText((Join-Path $root "specs/$feature/lens-applicability.json"), ($controller | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    $binding = [ordered]@{ selected = @(@{ lens = 'architecture-core'; depth = 'light'; decision = 'the shape' }); skipped = @() }
    $digest = Get-SpecrewWorkshopAgendaDigest -Binding ([pscustomobject]$binding)
    $question = [ordered]@{ schema = 'v3'; status = 'workshop-active'; scope = 'feature'; feature_ref = $feature; iteration_number = ''; lens = ''
        phase = 'agenda'; agenda_status = 'pending-confirmation'; question = 'Confirm the agenda?'; message_hash = ('a' * 64); artifact_path = ''
        agenda_digest = $digest; agenda_binding = $binding }
    [IO.File]::WriteAllText((Join-Path $root '.specrew/handover/workshop-question.json'), ($question | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    $ctx = [ordered]@{ schema = 'v2'; session_state = [ordered]@{ active = $true; feature_ref = $feature; boundary_type = 'specify'; host = 'claude' } }
    [IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    return [pscustomobject]@{ root = $root; digest = $digest }
}
function Invoke-Provider { param([string]$Root, [string]$Reply) return ((& pwsh -NoProfile -File $provider --project-root $Root --host-kind claude --source-event UserPromptSubmit --last-user-message $Reply 2>&1 | ForEach-Object { [string]$_ }) -join "`n") }
function Read-Receipts { param([string]$Root) $p = Join-Path $Root '.specrew/runtime/workshop-authority.jsonl'; if (-not (Test-Path -LiteralPath $p)) { return @() }; return @(Get-Content -LiteralPath $p -Encoding UTF8 | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json }) }

Write-Host 'workshop-agenda-vocabulary'
$fixtures = @()
try {
    Write-Host '  --- case 1: confirm, yes, ok, looks right - each binds the visible agenda as human-confirmed / lens-selection ---'
    foreach ($word in @('confirm', 'yes', 'ok', 'looks right')) {
        $f = New-VisibleAgendaFixture; $fixtures += $f.root
        $null = Invoke-Provider -Root $f.root -Reply $word
        $rows = @(Read-Receipts -Root $f.root | Where-Object { [string]$_.phase -eq 'agenda' })
        $last = if ($rows.Count -gt 0) { $rows[-1] } else { $null }
        $bound = $null -ne $last -and [string]$last.confirmation -ceq 'human-confirmed' -and [string]$last.confirmation_scope -ceq 'lens-selection' -and [string]$last.agenda_digest -ceq $f.digest
        Assert-True $bound ('"{0}" -> receipt {1} / {2}, digest bound: {3}' -f $word, $(if ($last) { $last.confirmation } else { '(none)' }), $(if ($last) { $last.confirmation_scope } else { '-' }), $bound)
    }

    Write-Host '  --- case 2: a delegation is not a confirmation on the agenda ---'
    $f = New-VisibleAgendaFixture; $fixtures += $f.root
    $null = Invoke-Provider -Root $f.root -Reply 'you decide'
    $agendaRows = @(Read-Receipts -Root $f.root | Where-Object { [string]$_.phase -eq 'agenda' })
    $confirmedRows = @($agendaRows | Where-Object { [string]$_.confirmation -ceq 'human-confirmed' })
    Assert-True ($confirmedRows.Count -eq 0) ('"you decide" writes no human-confirmed agenda receipt (agenda rows: {0})' -f $agendaRows.Count)

    Write-Host '  --- case 3: the rule is stated where the coordinator reads it - six skill copies, three refusal Actions ---'
    $pasteSentence = '**Paste the command''s complete output into your own message** as one unchanged, contiguous block - a tool'
    $ruleSentence = 'confirmation the way a lens accepts any typed reply - `confirm`, `yes`, `ok`, `looks right` all bind; only a'
    foreach ($rel in @('extensions/specrew-speckit/squad-templates/skills/design-workshop.md', '.specify/extensions/specrew-speckit/squad-templates/skills/design-workshop.md',
            '.agents/skills/specrew-design-workshop/SKILL.md', '.claude/skills/specrew-design-workshop/SKILL.md', '.cursor/rules/specrew-design-workshop/SKILL.md', '.github/skills/specrew-design-workshop/SKILL.md')) {
        $text = Get-Content -LiteralPath (Join-Path $repoRoot $rel) -Raw -Encoding UTF8
        Assert-True ($text.Contains($pasteSentence) -and $text.Contains($ruleSentence) -and -not $text.Contains("Send the command's complete output")) ($rel + ' carries the paste-into-your-message sentence and the one-rule vocabulary')
    }
    $actionPattern = 'wait for one (?:new )?typed reply - confirm, yes, ok, looks right, or a change\.'
    foreach ($rel in @('extensions/specrew-speckit/scripts/confirm-workshop-agenda.ps1', '.specify/extensions/specrew-speckit/scripts/confirm-workshop-agenda.ps1')) {
        $text = Get-Content -LiteralPath (Join-Path $repoRoot $rel) -Raw -Encoding UTF8
        $count = ([regex]::Matches($text, $actionPattern)).Count
        Assert-True ($count -eq 3) ($rel + (' - three refusal Actions name the four words and the change ({0})' -f $count))
        Assert-True (-not $text.Contains('send its complete output')) ($rel + ' no longer says "send its complete output"')
    }
}
finally {
    foreach ($d in $fixtures) { if (Test-Path -LiteralPath $d) { Remove-Item -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue } }
}

if ($script:Failures -gt 0) { Write-Host ("workshop-agenda-vocabulary: {0} FAILED" -f $script:Failures); exit 1 }
Write-Host 'workshop-agenda-vocabulary: all cases passed'
exit 0
