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
Assert-Match -Text $skill -Pattern '(?i)(by name with its (one-line )?responsibility|every component named and its one-line\s+responsibility)' 'skill body: name components + responsibilities, never a count (C)'
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
# FR-037 in-band-at-approval tightening (testLenses8 Claude fix): at any approval point the map MUST be rendered
# in-band in the same message, never referenced by a file path or a bare count; the file is written after, not
# instead. Copilot + Antigravity already render in-band; this pulls Claude up to the same bar.
Assert-Match -Text $skill -Pattern '(?i)approves what\s+is on screen' 'skill FR-037: at an approval point the diagram is rendered in-band, not referenced by file/count'
Assert-Match -Text $skill -Pattern '(?i)IN ADDITION TO the\s+in-band render' 'skill FR-037: the workshop file is written AFTER + in addition to the in-band render, never instead'
# General mechanism rule (testLenses11: the lens AGENDA was confirmed by count without rendering — a list, not
# a diagram, so the diagram-scoped rule missed it). Anchored on render-before-the-menu; covers EVERY confirm
# point incl. the agenda; keep-the-menu (good UX, maintainer-directed); be verbose.
Assert-Match -Text $skill -Pattern '(?i)render \+ explain, THEN ask' 'skill FR-037 general: render+explain before the confirm menu (mechanism-anchored, not artifact-enumerated)'
Assert-Match -Text $skill -Pattern '(?i)Be verbose' 'skill FR-037 general: be verbose — explain in prose first + self-explanatory menu wording'
Assert-Match -Text $skill -Pattern '(?i)menu is good UX' 'skill FR-037 general: the menu stays (good UX); the fix is the missing render, never the menu'
Assert-Match -Text $skill -Pattern '(?i)agenda \+ depths' 'skill FR-037 general: the lens agenda + depths is an explicit confirm-point (the testLenses11 gap the diagram-scoped rule missed)'
Write-Pass 'skill FR-037: render+explain before the confirm menu at EVERY confirm point (agenda/diagram/map/options/verdict), verbose, menu kept — the testLenses8/11 Claude under-surfacing fix'
# 165-retarget (2026-06-07 dogfood — the F-171 workshop on the current Claude model). Two host-neutral
# conduct additions: (A) the human-facing chat-path orientation (humans hit dense menus they could not
# follow + had to discover the free-text path themselves); (B) the file:///-links-before-the-menu rule
# (Claude drops the artifact links before an AskUserQuestion, so the human cannot open the spec/record to
# decide; other hosts render them in prose). Presence-locked here; the behavioral payoff is the next dogfood.
Assert-Match -Text $skill -Pattern '(?i)Tell the human they can just talk' 'skill 165-A: the chat-path orientation (human can type a question / ask for a file instead of picking a menu option)'
Assert-Match -Text $skill -Pattern '(?i)instead of picking a menu option' 'skill 165-A: the free-text-instead-of-menu phrasing'
Assert-Match -Text $skill -Pattern '(?i)links go in your prose before the menu' 'skill 165-B: the file:///-links-before-the-confirm-menu rule (the Claude artifact-link drop)'
Assert-Match -Text $skill -Pattern '(?i)does not linkify' 'skill 165-B: names why the menu fields cannot carry the links (the AskUserQuestion UI does not linkify file:///)'
Write-Pass 'skill 165-retarget: chat-path orientation (A) + file:///-links-before-the-menu (B) — the F-171-dogfood host-neutral conduct fix'
# Component-map FORM (testLenses11: the agent referenced "11-component map above" + counted "6 resource accessors"
# instead of rendering the full diagram + a vocabulary-grouped named list). Fix = a prescriptive fill-in TEMPLATE
# the agent completes (form > prose; harder to under-deliver; also helps weaker hosts), rendered before the ask.
Assert-Match -Text $skill -Pattern '(?i)fill-in template' 'skill component-map: a fill-in presentation template (the agent completes it, vs improvising the form)'
Assert-Match -Text $skill -Pattern '(?i)named list grouped by the decomposition vocabulary' 'skill component-map: a named list grouped by the chosen vocabulary (IDesign/DDD/layered/microservices), every component named'
Assert-Match -Text $skill -Pattern 'Proposed component map' 'skill component-map: the template skeleton is present (diagram + vocabulary-grouped named list + key flow)'
Write-Pass 'skill component-map: prescriptive fill-in template (diagram + vocabulary-grouped named list + flow), render-before-ask, re-render-on-change — the testLenses11 form fix'
# Agenda fill-in template (testLenses11: the prose render-before-menu was skimmed at the AGENDA step — the agent
# crammed the lens list into the menu question instead of rendering the agenda-with-decisions in-band). Same
# template lever as the component map (prose skimmed -> template holds).
Assert-Match -Text $skill -Pattern '(?i)Workshop agenda' 'skill agenda: a fill-in agenda template (rendered in-band before the confirm menu, not crammed into the menu question)'
Assert-Match -Text $skill -Pattern '(?i)the decision this lens will ask' 'skill agenda: the agenda template carries each lens depth + the concrete decision it raises (not just the name)'
Write-Pass 'skill agenda: prescriptive fill-in agenda template (lenses + depth + per-lens decision, render-before-menu) — the testLenses11 agenda-render fix'
# A8 / FR-041 (i12 + cross-host dogfood): after i11 proved render-before-the-menu CONDUCT is defeated on Claude
# by the AskUserQuestion tool-gravity. The catalog-at-open front-load was REVERTED (testLenses11 cross-host: it
# SKIMMED on Claude — a before-a-menu render — and was REDUNDANT on prose hosts that render the agenda inline).
# What HELD is the per-lens conduct: open-question-first = the strongest CONDUCT lever (binary — a lens opened
# with a presentation or a menu), dogfood-proven to render the lens content on Claude.
Assert-Match -Text $skill -Pattern '(?i)never a menu first' 'skill A8: open-question-first — never open a lens with a menu (the per-lens render that HELD on Claude)'
Assert-Match -Text $skill -Pattern '(?i)Binary\s+test: did this lens open' 'skill A8: the binary open-question-first test (a lens opened with a presentation, or a menu)'
Assert-Match -Text $skill -Pattern '(?i)governing model' 'skill A8: the governing model (open-discussion renders hold on Claude; before-a-menu renders skim -> hook or host-variance, never another instruction)'
Write-Pass 'skill A8/FR-041: open-question-first (the binary conduct lever, dogfood-proven on Claude) + the before-a-menu governing model; catalog-at-open reverted'
# Pacing (i12 cross-host dogfood — testLenses11): the per-lens presentation WORKED but a dense lens (5 subjects
# bundled into one open question) lands as a wall on EVERY host (Copilot's per-lens was hard for the same
# reason). After presenting, the agent MUST offer all-at-once OR one-at-a-time, cross-host.
Assert-Match -Text $skill -Pattern '(?i)pacing choice' 'skill A8: dense-lens pacing offer (all-at-once or one-at-a-time), mandatory + cross-host'
Assert-Match -Text $skill -Pattern '(?i)one at a time' 'skill A8: the one-at-a-time pacing path (chunk a dense lens decision-by-decision)'
Assert-Match -Text $skill -Pattern '(?i)not optional on a dense lens' 'skill A8: the pacing offer is mandatory on a dense lens, every host'
Write-Pass 'skill A8: open-question-first + MANDATORY cross-host dense-lens pacing; catalog-at-open reverted (the before-a-menu governing model) — the i12 dogfood convergence'

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
