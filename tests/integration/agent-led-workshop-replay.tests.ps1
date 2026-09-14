# PRED-BETA4-057: the pre-answered walk crosses presentation, declarations and typed authority together.
# -ModuleRoot permits replay against a disposable mutation without editing the working module.
[CmdletBinding()]
param([string]$ModuleRoot = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent))
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:failures = 0
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { Write-Host "PASS: $Label" }
    else { $script:failures++; Write-Host "FAIL: $Label" }
}
$root = Join-Path ([IO.Path]::GetTempPath()) ('agent-led-' + [guid]::NewGuid().ToString('N'))
$root = [IO.Path]::GetFullPath($root)
$scripts = Join-Path $ModuleRoot 'extensions/specrew-speckit/scripts'
$provider = Join-Path $scripts 'specrew-conformance-provider.ps1'
$declarer = Join-Path $scripts 'declare-turn-end.ps1'
$handover = Join-Path $ModuleRoot 'scripts/internal/specrew-handover-provider.ps1'
$feature = '001-mdlink-checker'
$featureDir = Join-Path $root "specs/$feature"
$transcript = Join-Path $root '.specrew/runtime/replay.jsonl'
$draft = Join-Path $root '.specrew/runtime/authored-message.md'
$priorModule = $env:SPECREW_MODULE_PATH
$env:SPECREW_MODULE_PATH = $ModuleRoot
$script:token = ''
function Add-Turn([string]$Role, [string]$Text) {
    @{ type=$Role; message=@{content=@(@{type='text';text=$Text})} } | ConvertTo-Json -Depth 6 -Compress | Add-Content -LiteralPath $transcript
}
function Invoke-Conformance([string]$Event) {
    Push-Location $root
    try { return (@(& pwsh -NoProfile -File $provider --host-kind claude --source-event $Event --session-id replay --transcript-path $transcript 2>&1) -join "`n") }
    finally { Pop-Location }
}
function Prompt([string]$Text) {
    Add-Turn user $Text
    $start = Invoke-Conformance UserPromptSubmit
    $match = [regex]::Match($start, '-Token (?<token>[a-f0-9]{32})')
    Check $match.Success 'prompt hands this turn its own token'
    $script:token = $match.Groups['token'].Value
    return (@(& pwsh -NoProfile -File $handover --project-root $root --host-kind claude --source-event UserPromptSubmit --last-user-message $Text --transcript-path $transcript --session-id replay 2>&1) -join "`n")
}
function Declare([string]$Text, [string]$Kind = 'conversational', [string[]]$Owed = @()) {
    Set-Content -LiteralPath $draft -Value $Text -Encoding UTF8
    $argsForDeclare = @('-NoProfile','-File',$declarer,'-ProjectRoot',$root,'-Kind',$Kind,'-MessagePath',$draft,'-Token',$script:token,'-AsJson')
    if ($Kind -eq 'in-flight') { $argsForDeclare += @('-Pending','fixture background check') }
    if ($Owed.Count) { $argsForDeclare += @('-Owed',($Owed -join ',')) }
    $out = @(& pwsh @argsForDeclare 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw "Declaration failed: $out" }
    return ($out | ConvertFrom-Json)
}
function Stop-With([string]$Text) { Add-Turn assistant $Text; return Invoke-Conformance Stop }
function Close-Lens([string]$Lens, [string]$Decision) {
    Set-Content -LiteralPath (Join-Path $featureDir "workshop/$Lens.md") -Value "# $Lens`n`n$Decision" -Encoding UTF8
    $out = @(& pwsh -NoProfile -File (Join-Path $scripts 'confirm-workshop-lens.ps1') -ProjectRoot $root -FeatureRef $feature -Lens $Lens -Depth light -Agenda 'Does this pre-answered record stand?' -Decision $Decision 2>&1) -join "`n"
    Check ($LASTEXITCODE -eq 0) ("$Lens closes on its scoped reply: $out")
}
try {
    foreach ($dir in @('.specrew/runtime','.specrew/handover',"specs/$feature/workshop",'.specify/extensions/specrew-speckit')) {
        New-Item -ItemType Directory -Path (Join-Path $root $dir) -Force | Out-Null
    }
    Copy-Item -LiteralPath $scripts -Destination (Join-Path $root '.specify/extensions/specrew-speckit/scripts') -Recurse
    Copy-Item -LiteralPath (Join-Path $ModuleRoot 'extensions/specrew-speckit/knowledge') -Destination (Join-Path $root '.specify/extensions/specrew-speckit/knowledge') -Recurse
    # Give the copied provider a fixture profile without writing to the real user's home.
    # Only the profile path is substituted; the parser and Stop behavior run unchanged.
    $profile = Join-Path $root '.specrew/profile.yml'
    Set-Content $profile "expertise:`n  software_architecture: 10`n  ui_ux: 10`n  product_management: 7`n  ai_research_project_management: 10"
    $provider = Join-Path $root '.specify/extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1'
    $copiedStore = Join-Path $root '.specify/extensions/specrew-speckit/scripts/turn-end-store.ps1'
    $storeText = Get-Content $copiedStore -Raw -Encoding UTF8
    $storeText = $storeText.Replace("(Join-Path ([Environment]::GetFolderPath('UserProfile')) '.specrew/user-profile.yml')", ("'" + $profile.Replace("'", "''") + "'"))
    Set-Content $copiedStore $storeText -Encoding UTF8
    Set-Content (Join-Path $root '.specrew/config.yml') 'version: 1'
    Set-Content (Join-Path $featureDir 'spec.md') "<!-- specrew:spec-not-yet-authored -->`n# Markdown link checker"
    Set-Content (Join-Path $root '.gitignore') ".specrew/`n.specify/"
    & git -C $root init -q -b main
    & git -C $root -c user.name=Test -c user.email=t@example.invalid add -A
    & git -C $root -c user.name=Test -c user.email=t@example.invalid commit -qm baseline
    & (Join-Path $scripts 'initialize-workshop-controller-state.ps1') -ProjectRoot $root -FeatureRef $feature | Out-Null
    Set-Content (Join-Path $root '.specrew/runtime/hook-bootstrap-render-replay.json') '{"source":"startup"}'
    $null = Prompt 'Feature 1: Markdown link checker. Apply my pre-answers, light depth, one question per turn.'
    $opening = @'
Specrew 0.40.0-beta4 is active on Claude. This is new feature intake; artifacts live under specs/001-mdlink-checker.
What I know about you: expert on architecture and UX; mid-level on product strategy. Each boundary needs your typed verdict.
Product-domain, light: solo developer; moved files break Markdown relative links and anchors; manual checking is unreliable.
MVP: recursively scan .md files, check local links and headings, print path/line/target and exit 1 on a broken link.
HTTP, auto-fix, CI and UI are out of scope. PowerShell 7, one script, no dependencies, no false positives.
This familiar tiny utility needs no deeper discovery. Does this record stand? Type move on or a correction.
'@
    $withoutDials = $opening -replace '(?m)^What I know about you:.*\r?\n', ''
    $declared = Declare $withoutDials
    Check ($declared.text -eq '' -and -not $declared.orientation) 'opening declaration does not repeat orientation or replace the question'
    $dialsRepair = Stop-With $withoutDials
    Check ($dialsRepair -match 'add only the missing dials line' -and $dialsRepair -match 'software_architecture=10' -and $dialsRepair -notmatch 'Specrew 0\.40\.0-beta4 is active') 'the orientation gate fills only the missing dials line from the profile'
    # A mutation that wrongly releases Stop consumes the token. Do not fabricate a replacement;
    # keep collecting the independent presentation failures with the real host event sequence.
    if ($dialsRepair -match 'SPECREW-STOP-BLOCK') { $declared = Declare $opening }
    Check ((Stop-With $opening) -notmatch 'SPECREW-STOP-BLOCK') 'agent-authored opening and product question are accepted'
    Check (@(Get-ChildItem (Join-Path $root '.specrew/runtime/conformance-sessions') -Recurse -Filter orientation-rendered.json).Count -eq 1) 'one visible opening earns one session orientation receipt'
    $receiptPath = Join-Path $root '.specrew/runtime/workshop-authority.jsonl'
    Check (-not (Test-Path $receiptPath)) 'no lens receipt exists before the human replies'
    $null = Prompt 'move on'
    $fieldFixture = Join-Path $ModuleRoot 'tests/fixtures/beta4-agenda-clearing/001-mdlink-checker/workshop'
    Copy-Item -LiteralPath (Join-Path $fieldFixture 'product-domain.yml') -Destination (Join-Path $featureDir 'workshop/product-domain.yml')
    Close-Lens product-domain 'The supplied user, pain, MVP, non-goals and PowerShell constraints stand; light depth.'
    $agendaBinding = [ordered]@{
        selected=@(@{lens='architecture-core';depth='light';decision='One script; enumerate files, extract links, resolve and check; no shared state or configuration.'},@{lens='code-implementation';depth='light';decision='Specrew defaults; PowerShell 7; local fixture checks; no dependencies; Codex reviewer with default authorization.'})
        skipped=@('component-design','requirements-nfr','ui-ux','data-storage','security-compliance','integration-api','devops-operations','observability-resilience' | ForEach-Object { @{lens=$_;reason='single-script CLI; nothing to decide at this size.'} })
    } | ConvertTo-Json -Depth 8 -Compress
    $agenda = @(& (Join-Path $scripts 'confirm-workshop-agenda.ps1') -ProjectRoot $root -FeatureRef $feature -AgendaJson $agendaBinding -RenderOnly) -join "`n"
    $declared = Declare $agenda
    Check ($declared.text -eq '') 'agenda declaration emits no status-only replacement'
    $blocked = Stop-With 'In flight; continuing when agenda awaiting the human typed confirmation lands; nothing needed.'
    Check ($blocked -match 'SPECREW-STOP-BLOCK' -and $blocked -match 'include the complete workshop agenda') 'current failing reply is blocked with the agenda remedy'
    Check ((Stop-With $agenda) -notmatch 'SPECREW-STOP-BLOCK') 'the same turn completes when its agenda reaches the assistant message'
    $null = Prompt 'yes'
    $out = @(& (Join-Path $scripts 'confirm-workshop-agenda.ps1') -ProjectRoot $root -FeatureRef $feature -AgendaJson $agendaBinding) -join "`n"
    $controller = Get-Content (Join-Path $featureDir 'lens-applicability.json') -Raw | ConvertFrom-Json
    Check ($controller.agenda_status -eq 'confirmed') 'yes binds and persists the complete agenda once'
    $architecture = 'Architecture-core, light: one script with enumerate files -> extract links -> resolve and check. No shared state or configuration. Does this match your pre-answer? Type move on.'
    $declared = Declare $architecture
    Check ((Stop-With 'Recorded; nothing needed.') -match 'SPECREW-STOP-BLOCK') 'a declared lens question cannot be replaced with a status line'
    Check ((Stop-With $architecture) -notmatch 'SPECREW-STOP-BLOCK') 'the architecture question survives the declaration'
    $null = Prompt 'move on'
    Close-Lens architecture-core 'One script: enumerate files, extract links, resolve and check. No shared state or configuration.'
    $code = 'Code-implementation, light: K1 Specrew defaults; K2 PowerShell 7 and local fixture invocation; K3 zero dependencies; K4 Codex reviewer, default authorization reference. Does this record stand? Type move on.'
    $declared = Declare $code
    Check ((Stop-With $code) -notmatch 'SPECREW-STOP-BLOCK') 'the code lens has its own visible turn'
    $null = Prompt 'move on'
    Set-Content (Join-Path $featureDir 'implementation-rules.yml') @'
schema_version: "1.0"
context_scope: feature_standalone
resolved_stack: powershell-7
selections: []
custom_rules: []
dependency_policy:
  stance: use-existing-no-new-dependency
  dependencies: []
provenance:
  confirmation: human-confirmed
  confirmation_scope: lens-question
reviewer_preference:
  mode: human-selected
  source: code-implementation-workshop
  host: codex
  authorization_ref: default
'@
    Close-Lens code-implementation 'Specrew defaults, PowerShell 7, local fixtures, zero dependencies, Codex reviewer with default authorization.'
    Set-Content (Join-Path $featureDir 'spec.md') "# Markdown link checker`n`nRecursively check relative file links and heading anchors; report path, line and target; exit 1 on failures. HTTP and auto-fix are out of scope."
    & git -C $root add -- specs
    & git -C $root -c user.name=Test -c user.email=t@example.invalid commit -qm 'boundary(specify): authored spec'
    $head = (& git -C $root rev-parse HEAD).Trim()
    $context = [ordered]@{schema='v2';feature_path=$featureDir;session_state=@{active=$true;boundary_type='specify';feature_ref=$feature;host='claude';iteration_number='001';auth_commit_hash=$head;recorded_at='2026-09-14T00:00:00Z'};boundary_enforcement=@{enabled=$true;last_authorized_boundary=$null;pending_next_boundary=$null;verdict_history=@();bypass_history=@()}}
    $context | ConvertTo-Json -Depth 9 | Set-Content (Join-Path $root '.specrew/start-context.json')
    . (Join-Path $scripts 'shared-governance.ps1')
    $null = Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot $root -WorkingBoundary specify -BoundaryCommitHash $head -RecordedAt '2026-09-14T00:00:01Z'
    $context = Get-Content (Join-Path $root '.specrew/start-context.json') -Raw | ConvertFrom-Json
    $crossing = $context.boundary_enforcement.pending_crossing
    $marker = '<!-- SPECREW-VERDICT-BOUNDARY: intake -> specify @ ' + $crossing.crossing_id + ' -->'
    @('Boundary to ask for: intake -> specify','Human approval phrase: approved for specify','Marker last line exactly:',$marker,'Working boundary: specify','Last authorized boundary: intake',"Feature: $feature") | Set-Content (Join-Path $root '.specrew/runtime/pending-verdict-stop.md')
    $specUrl = 'file:///' + ((Join-Path $featureDir 'spec.md') -replace '\\','/')
    $packet = @"
## What I Just Did
Authored the Markdown checker spec from your three confirmed records.
## Why I Stopped
Specify needs your verdict before clarify begins.
## What Needs Your Review
Read $specUrl for anchor handling, output fields and the zero-false-positive constraint.
## What Happens Next
Clarify checks remaining ambiguities in the spec in the same turn after your approval; it produces no code.
## Discussion Prompts
1. I recommend keeping HTTP links out of scope; adding them would require timeout and network-error decisions.
## What I Need From You
Approve this specify scope or identify a correction to the linked requirements.
"@
    $generic = $packet.Replace("Read $specUrl for anchor handling, output fields and the zero-false-positive constraint.", 'The work named above.').Replace('Clarify checks remaining ambiguities in the spec in the same turn after your approval; it produces no code.', 'On approval the next stage starts.').Replace('1. I recommend keeping HTTP links out of scope; adding them would require timeout and network-error decisions.', '1. Anything above you want changed, questioned, or done differently.')
    $declared = Declare $generic boundary
    Check (-not $declared.packet_valid -and $declared.text -eq '') 'the current generic packet earns neither approval line nor marker'
    $declared = Declare $packet boundary
    Check $declared.packet_valid 'agent packet has real review targets, recommendation and next work'
    Check ($declared.text -eq ('approved for specify' + [Environment]::NewLine + $marker)) 'boundary return supplies only the missing approval line and marker'
    Check ((Stop-With 'The packet is ready; nothing needed.') -match 'SPECREW-STOP-BLOCK') 'tool-verified packet missing from the reply blocks Stop'
    $completePacket = $packet + "`n" + $declared.text
    $stop = Stop-With $completePacket
    Check ($stop -notmatch 'SPECREW-STOP-BLOCK') ("specific packet and bound marker pass: $stop")
    $context = Get-Content (Join-Path $root '.specrew/start-context.json') -Raw | ConvertFrom-Json
    Check ([string]::IsNullOrWhiteSpace($context.boundary_enforcement.last_authorized_boundary)) 'packet presentation does not authorize its own crossing'
    $captured = Prompt 'approved for specify'
    Check ($captured -match 'Verdict captured: approved for specify' -and $captured -match 'clarify stage begins in this turn' -and $captured -match 'approval was the instruction') 'captured verdict begins clarify with no second start request'
    $declared = Declare 'I am checking the anchor requirements in clarify.' in-flight
    Check ($declared.text -eq '' -and -not $declared.orientation) 'background declaration emits neither reassurance nor another orientation'
    $declared = Declare $completePacket boundary @('clarifications')
    Check (-not $declared.packet_valid -and $declared.text -eq '') 'missing artifacts withhold approval and marker even in a supplied packet'
    $sourceContract = Get-Content (Join-Path $ModuleRoot 'scripts/internal/launch-contract.ps1') -Raw
    Check ($sourceContract -match 'last tool call' -and $sourceContract -match "never the agent.s reply" -and $sourceContract -notmatch 'nothing is a complete answer') 'the runtime instruction cannot replace the agent reply with the tool return'
}
finally {
    $env:SPECREW_MODULE_PATH = $priorModule
    # Delete only this uniquely allocated fixture beneath the resolved system temporary directory.
    $tempPrefix = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if (-not $root.StartsWith($tempPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'Fixture cleanup escaped the temporary directory.' }
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}
if ($script:failures) { throw "agent-led-workshop-replay: $script:failures failures" }
Write-Host 'agent-led-workshop-replay: all assertions passed'
