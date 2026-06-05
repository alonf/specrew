[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }
function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { Write-Fail $Message } }
function Assert-Match { param([string]$Text, [string]$Pattern, [string]$Message) if ($Text -notmatch $Pattern) { Write-Fail $Message } }

# Iteration 10 (delivery relocation): the A4/A5/A6 lens conduct moved out of the one-shot launch prompt into
# a re-invokable design-workshop skill + per-lens conduct co-located in the lens md, with the prompt trimmed
# to a pointer. These assertions lock the relocation in place (the runtime QUALITY is the SC-024 dogfood).

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$skillPath = Join-Path $repoRoot 'extensions\specrew-speckit\squad-templates\skills\design-workshop.md'
$lensDir = Join-Path $repoRoot 'extensions\specrew-speckit\knowledge\design-lenses'
$startPath = Join-Path $repoRoot 'scripts\specrew-start.ps1'

# --- The design-workshop skill ---
Assert-True (Test-Path -LiteralPath $skillPath) "the design-workshop skill template exists ($skillPath)"
$skill = Get-Content -LiteralPath $skillPath -Raw

# Frontmatter: name + a description (the always-resident auto-load trigger).
Assert-Match -Text $skill -Pattern '(?ms)^---\s.*\bname:\s*"?specrew-design-workshop"?' 'skill: frontmatter declares name specrew-design-workshop'
Assert-Match -Text $skill -Pattern '(?ms)^---\s.*\bdescription:\s*"' 'skill: frontmatter carries a description (the auto-load trigger)'
# Description carries the literal trigger words a design moment uses (so the model loads it).
$frontMatter = [regex]::Match($skill, '(?ms)^---\s*\n(.*?)\n---').Groups[1].Value
foreach ($trigger in @('design lens', 'workshop', 'design-analysis', 'architecture', 'co-design', 'RE-INVOKE')) {
    Assert-Match -Text $frontMatter -Pattern ([regex]::Escape($trigger)) "skill description includes the trigger '$trigger' (auto-load reliability)"
}
# Body carries the relocated conduct (A/C/D + the per-lens loop + self-reinvocation + self-containment).
Assert-Match -Text $skill -Pattern '(?i)console ASCII' 'skill body: ASCII is the inline default (A — a terminal mermaid block is source text, not a picture)'
Assert-Match -Text $skill -Pattern '(?i)file:///' 'skill body: write richer diagrams to a file and surface the clickable link'
Assert-Match -Text $skill -Pattern '(?i)by name with its (one-line )?responsibility' 'skill body: name components + responsibilities, never a count (C)'
Assert-Match -Text $skill -Pattern '(?i)UI/screen layout|agreed UI' 'skill body: capture the agreed UI layout (D)'
Assert-Match -Text $skill -Pattern 'design-lenses/<lens-id>\.md|design-lenses/<id>\.md' 'skill body: loads each lens md per stage (point-of-use)'
Assert-Match -Text $skill -Pattern '(?i)re-invoke' 'skill body: self-reinvocation — re-invoke for the next lens (the 4 hosts do not document reload)'
Assert-Match -Text $skill -Pattern '(?i)self-contained' 'skill body: self-contained per load'
Write-Pass 'design-workshop skill: frontmatter trigger description + relocated conduct (ASCII-inline, named components, ui-ux capture, per-lens load, self-reinvocation)'

# --- Same-session skill refinements (locked present so a later edit cannot silently drop them) ---
# All three POSTDATE the skill that testLenses6 actually ran: the dogfood hit the OLD SC-021 record shape and
# wrote PROSE diagram fields - proof the deployed skill predated c80e7d58 + 49a9ff39 (and, by the same build
# boundary, a38daa33). So this run confirms the RELOCATION (the skill auto-loads + carries the conduct), NOT
# these refinements. These assertions lock PRESENCE only; behavioral confirmation awaits a fresh-deploy dogfood
# (carried in the i10 review). Reviews on this feature have a track record of missing the said-it/didn't-do-it
# gap; presence-locking is the cheap structural half.
Assert-Match -Text $skill -Pattern '(?i)match the question FORM to the question' 'skill body: match question FORM to the question (MCQ for discrete choices) - a38daa33'
Assert-Match -Text $skill -Pattern '(?i)workshop.{0,12}<lens-id>' 'skill body: pins the workshop -> <lens-id> SC-021 record nesting - c80e7d58'
Assert-Match -Text $skill -Pattern 'NOT a .decisions. array' 'skill body: warns decision is singular, not a decisions array (SC-021) - c80e7d58'
Assert-Match -Text $skill -Pattern 'specs/<feature>/workshop/<lens-id>\.md' 'skill body: persists keeper diagrams to the workshop folder (file ref, not prose) - 49a9ff39'
Write-Pass 'same-session skill refinements present + locked (a38daa33 question-FORM, c80e7d58 SC-021 record shape, 49a9ff39 diagram persistence) - presence-asserted; all three postdate the deployed skill testLenses6 ran, so runtime-unconfirmed pending a fresh-deploy dogfood'

# --- Per-lens conduct co-located in every lens md ---
$lensIds = @('architecture-core','component-design','requirements-nfr','ui-ux','data-storage','security-compliance','integration-api','devops-operations','observability-resilience')
foreach ($id in $lensIds) {
    $p = Join-Path $lensDir "$id.md"
    Assert-True (Test-Path -LiteralPath $p) "lens md exists: $id"
    $m = Get-Content -LiteralPath $p -Raw
    Assert-Match -Text $m -Pattern '(?m)^## Workshop Conduct' "lens md '$id' has a ## Workshop Conduct section (point-of-use conduct)"
    Assert-Match -Text $m -Pattern '(?i)console ASCII' "lens md '$id' Workshop Conduct: ASCII-inline rendering"
    Assert-Match -Text $m -Pattern 'specrew-design-workshop' "lens md '$id' Workshop Conduct: re-invoke the design-workshop skill before the next lens"
}
Write-Pass 'per-lens conduct co-located: all 9 lens md carry a Workshop Conduct section (ASCII-inline + re-invoke)'

# --- The launch prompt is trimmed to a pointer (the conduct relocated, not duplicated verbose) ---
$start = Get-Content -LiteralPath $startPath -Raw
Assert-Match -Text $start -Pattern 'specrew-design-workshop' 'launch prompt: points to the design-workshop skill (the relocation)'
Assert-Match -Text $start -Pattern '(?m)^9a\. \*\*The per-lens design workshop' 'launch prompt: Rule 9a is the skill pointer'
Assert-Match -Text $start -Pattern '(?m)^9b\. \(Folded into' 'launch prompt: Rule 9b trimmed to a folded-into-skill stub'
Assert-Match -Text $start -Pattern '(?m)^9c\. \(Folded into' 'launch prompt: Rule 9c trimmed to a folded-into-skill stub'
# The verbose A5 visuals rule body no longer lives inline as its own rule (relocated to the skill).
Assert-True ($start -notmatch '(?m)^9b\. \*\*Workshop visuals \(Amendment A5\)') 'launch prompt: the verbose 9b visuals rule body was relocated (not left inline)'
Write-Pass 'launch prompt: trimmed to a skill pointer; the verbose 9a/9b/9c conduct relocated to the skill'

# --- Iteration 11 (Amendment A7): confirmation integrity + intake UX conduct (presence-locked) ---
# FR-038 (integrity + count + delegate/skip exception) + FR-039 (provenance field) + FR-040 (intake UX) in the
# skill; the squad.agent.md stopping-completeness rule in the coordinator-governance template; the Rule 9a A7
# clause. Presence only — the behavioral payoff (the agent stops manufacturing agreement) is the SC-027 Squad
# re-dogfood, not unit-provable.
Assert-Match -Text $skill -Pattern '(?i)never manufacture agreement|fabricated' 'skill A7: the never-manufacture-agreement integrity rule (FR-038)'
Assert-Match -Text $skill -Pattern '(?i)confirmation_required' 'skill A7: the confirmation_required marker (FR-039)'
Assert-Match -Text $skill -Pattern 'human-confirmed \| human-delegated \| human-skipped' 'skill A7: the provenance enum incl. the delegate/skip exception (FR-038/FR-039)'
Assert-Match -Text $skill -Pattern '(?i)count self-check' 'skill A7: the count self-check (FR-038)'
Assert-Match -Text $skill -Pattern '(?i)preparing the workshop' 'skill A7: the prep announcement (FR-040)'
Assert-Match -Text $skill -Pattern '(?i)agenda as an assignment' 'skill A7: the agenda assignment (FR-040)'
Assert-Match -Text $skill -Pattern '(?i)preparing lens' 'skill A7: the per-lens lazy-load progress cue (FR-040)'
Write-Pass 'skill A7: confirmation-integrity invariant + count + delegate/skip exception + provenance field + intake UX (presence-locked; SC-027 dogfood is the behavioral gate)'

# The coordinator-governance template (injected into squad.agent.md at deploy) carries the stopping-completeness
# rule — the Squad root-cause lever (the testLenses7 stopping-judgment fix must reach downstream coordinators).
$govPath = Join-Path $repoRoot 'extensions\specrew-speckit\squad-templates\coordinator\specrew-governance.md'
Assert-True (Test-Path -LiteralPath $govPath) "coordinator-governance template exists ($govPath)"
$gov = Get-Content -LiteralPath $govPath -Raw
Assert-Match -Text $gov -Pattern '(?i)every selected lens' 'governance A7: intake not complete until every selected lens is resolved (FR-038 stopping rule)'
Assert-Match -Text $gov -Pattern '(?i)specific enough' 'governance A7: do not declare intake specific-enough early (the root-cause lever)'
Assert-Match -Text $gov -Pattern '(?i)background sub-agent|backfill' 'governance A7: do not delegate to a background sub-agent / backfill'
Write-Pass 'governance A7: the squad.agent.md stopping-completeness rule (the Squad root-cause lever) is in the coordinator-governance template'

# Rule 9a carries the A7 clause (the launch-prompt pointer names A7 + the provenance gate)
Assert-Match -Text $start -Pattern 'A4/A5/A6/A7' 'launch prompt A7: Rule 9a names Amendment A7'
Assert-Match -Text $start -Pattern '(?i)confirmation.{0,20}provenance|SC-026' 'launch prompt A7: Rule 9a carries the confirmation-provenance / SC-026 reference'
Write-Pass 'launch prompt A7: Rule 9a names A7 + the confirmation provenance / SC-026'

Write-Pass 'Lens-conduct delivery relocation (iteration 010) unit tests passed'
exit 0
