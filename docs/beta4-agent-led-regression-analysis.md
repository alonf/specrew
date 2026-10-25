# Beta4 regression: the turn-end declaration displaces agent-led conversation

Date: 2026-09-13 Pacific / 2026-09-14 UTC. Investigation requested by the maintainer.
Code examined: `8dc29187`; supplied walk build: `d8ce3ea9`. Their only tracked difference is
`docs/beta4-predictions.md`. No product source was changed by this investigation.

## Finding

The strongest new regression is the beta4 turn-end contract. It instructs the agent to return the
declaration script's output verbatim at the end of every turn, while the workshop independently requires
the agent to show the agenda and ask for confirmation. The script cannot carry that agenda or question.
In the supplied walk, the agent followed the declaration path and omitted the agenda from its reply.
The resulting confirmation failure is downstream of that missing presentation.

This is an instruction-composition and interaction-state defect, with a concrete observed consequence.
The script does not literally erase an existing assistant message; the conflicting instructions cause
the agent to substitute its output for the message it needed to compose. Calling this only an agent
failure to paste the agenda misses the competing instruction newly introduced by beta4.

## Baseline and intended behavior

The latest published prerelease is `v0.40.0-beta3`, tag commit `11f47c4b`, published September 7.
The latest stable release is `v0.38.0`, June 18. Both appear in the
[Gallery version history](https://www.powershellgallery.com/packages/Specrew/0.38.0);
the [beta3 release](https://github.com/alonf/specrew/releases/tag/v0.40.0-beta3) identifies its tag.
The primary comparison was beta3 to HEAD: 185 files, 24,555 insertions and 1,073 deletions.
The stable-to-HEAD comparison is much broader: 1,445 files, 210,457 insertions and 4,135 deletions.
This investigation traces the interaction paths relevant to the walk, rather than claiming a complete
review of that entire delta or a controlled model run on the older releases.

The [workshop methodology](methodology/design-workshop-methodology.md), especially Core Principles 1–4,
says the agent proposes, explains, asks, listens, adapts, records and iterates; infers lens applicability;
shows the complete agenda; and obtains scoped human decisions. The
[workshop skill](../extensions/specrew-speckit/squad-templates/skills/design-workshop.md) explicitly says
ordinary product-domain, agenda and lens questions remain conversational, with generic packets suppressed.
That instruction was already present in beta3 and remains in beta4.

Requirement trace: [Feature 141](../specs/141-design-gate-runtime-hardening/spec.md) FR-025 requires an
interactive, expertise-adapted per-lens workshop; FR-040 requires the agenda to orient the human during
preparation. The changed work item is beta4 fix 2, recorded in PRED-BETA4-011 and commit `dfae6133`.
Boundary content is additionally governed by current launch-contract rule 46.

For this pre-answered walk, the intended flow is straightforward: present the product-domain record for
its scoped confirmation; save it; show the supplied two-lens agenda; receive confirmation; present each
light lens with the supplied answers and receive `move on`; author the spec; present the specify packet.
The agent owns preparation, persistence and transitions. The human answers the current question or
approves a real boundary. No extra instruction to start already-authorized work is needed.

## What the actual walk proves

Source transcript:
`C:/Users/alon/.claude/projects/C--Dev-walks-beta4-final-d8ce3ea9/d054058d-12c8-4046-b616-69b137fb08bf.jsonl`.
Times below are September 14 UTC (September 13 evening Pacific).

| Time | Evidence | Consequence |
| --- | --- | --- |
| 03:33:34–44 | Agent declares product-domain `in-flight`; final text adds another orientation and says `nothing needed` while awaiting the human's answer | The generated status contradicts the actual required action |
| 03:35:32 | Human types `move on` | Product-domain receipt is captured |
| 03:37:24 | Governed lens writer closes product-domain | This checkpoint works; no receipt-exhaustion hypothesis is needed |
| 03:37:40 | `confirm-workshop-agenda.ps1 -RenderOnly` returns the complete agenda | The proposal exists in tool output |
| 03:37:57–03:38:05 | Agent invokes turn-end; its only following reply is `In flight; continuing when agenda awaiting the human typed confirmation; then architecture-core lens, code-implementation lens, spec authoring, specify boundary stop lands; nothing needed.` | No visible agenda and no question to answer |
| 03:43:29 | Human types `yes` | There is no bound agenda digest to authorize |
| 03:44:08 | Agent finally includes the canonical agenda and requests another reply | An avoidable repair turn occurs before the first technical lens |

The saved controller is still `pending-confirmation`. Its product-domain completion is durable and the
authority journal contains that receipt. After the final re-presentation, the question handover contains
the agenda digest. This walk has not yet reached a technical lens or specify, so it cannot demonstrate
the behavior of those later stages.

## The introducing change and its consequences

### 1. Turn-end became a competing owner of the reply

Commit `dfae6133` introduced `declare-turn-end.ps1` and `turn-end-store.ps1`. Later commits refined the
identity token and output wording. The current
[launch contract, rule 46A](../scripts/internal/launch-contract.ps1) replaces beta3's conditional
long-work context packet with an unconditional end-every-turn instruction: output whatever the script
returns, verbatim; no output can be a complete answer. The
[turn-end skill](../extensions/specrew-speckit/squad-templates/skills/turn-end.md) repeats it.
The conformance provider also injects the last-action instruction at prompt time.

The [renderer](../extensions/specrew-speckit/scripts/declare-turn-end.ps1) accepts only:

| Kind | Actual rendering | Missing case |
| --- | --- | --- |
| `conversational` | Empty body; summary is recorded but not displayed | A substantive answer or question after ordinary discussion |
| `in-flight` | `In flight; continuing when <Pending> lands; nothing needed.` | Waiting for a human workshop answer is not background work |
| `boundary` | Fixed six-section packet from summary and crossing metadata | A workshop question is not a lifecycle crossing |

The skill defines `in-flight` as background work and `conversational` as nothing material changed. Closing
a lens writes records and requires a new question, so neither description accurately represents this
ordinary workshop turn. There is no explicit supported rendering path for it.

The agent's choice of `in-flight` was incorrect under that skill's definition. The product defect is that
the universal contract supplies no coherent alternative that preserves the required workshop interaction.

### 2. Later boundary packets lose the information needed for judgment

The renderer accepts a free-form summary, but has no dedicated review-target, substantive discussion,
recommendation or next-stage-content inputs. `What Needs Your Review` prints feature and cursor metadata;
`What Happens Next` says the next stage starts on approval; the only discussion prompt is
`Anything above you want changed, questioned, or done differently.`

This conflicts with rule 46 in the same launch contract, which still requires targeted review surfaces,
high-impact choices, uncertainties, concrete discussion prompts and a preview of the actual next work.
An agent could overload `-Summary` with these details, but the prescribed section content still omits
them and the contract never directs such an encoding. This regression is confirmed by source and renderer
execution; it is not claimed as a later event in the supplied walk.

### 3. A declaration proves generation, not presentation

At `specrew-conformance-provider.ps1:1231`, packet presence is inferred from a current boundary
declaration and its recorded crossing/marker. The renderer writes its orientation receipt because it
returned orientation text. Neither fact alone proves the content reached the assistant's visible reply.
The agenda path still requires actual visible text before binding a digest. These two paths use different
definitions of presentation.

The replay's status-only reply passes Stop even though its `yes` cannot mint an agenda receipt. That is
the integration gap: a successful declaration/allowed Stop is weaker than a usable human interaction.
This does not prove that the boundary authorization gate accepts a nonexistent human approval.

### 4. Orientation has two competing producers

The launch requires orientation first, while turn-end independently emits it on the first declaration
when its receipt is absent. An earlier agent-authored orientation does not satisfy that receipt. The
walk shows the duplicate. The renderer also passes null identity to its orientation function, producing
`this host` rather than the selected host. This is the same ownership conflict at session opening.

## Why the recent repairs and tests did not close it

`b8389069` clarified that the agenda must be pasted into the assistant's message and that natural
confirmations such as `yes` are accepted. `2a78d33a` added prompt-time disclosure when confirmation cannot
bind. These improve the recovery and vocabulary, but leave rule 46A and the renderer unchanged.
The new walk reproduces the missing presentation after those changes. B4F-097's claimed cause closure
therefore needs this qualification; its disclosure fix can work while the initiating defect survives.

Focused checks on this tree:

- `tests/integration/workshop-agenda-vocabulary.tests.ps1`: passed. Its positive fixtures start with a
  question and digest already bound; textual assertions check the strengthened skill sentences.
- `tests/integration/turn-end-update-transition.tests.ps1`: passed. It checks declaration compliance,
  verdict lines, marker position and withholding; it does not test substantive review targets or the
  preservation of a workshop question.
- `tests/unit/capture-disclosure.tests.ps1`: passed, including the captured-verdict directives for
  starting the authorized next stage and the Codex/Claude command rendering.
- Isolated provider replay using the walk's controller, product records, receipt and generated agenda
  proposal: status-only text gives no digest/no `yes` receipt; the visible agenda gives both. Neither
  case is Stop-blocked. Only disposable fixture state was changed.
- Direct renderer probe: waiting for agenda confirmation emits `nothing needed`; a conversational
  summary emits an empty body; a pending boundary emits the generic review/next-step/discussion sections.

The replay initially omitted the generated proposal and therefore could not bind even the positive case.
After creating it through `-RenderOnly`, the fixture's cached Stop result also had to be cleared before
re-evaluation. The final paired result uses the complete prerequisites; those setup failures are not
counted as product findings. The resulting evidence is in
[beta4-agent-led-regression-evidence.json](beta4-agent-led-regression-evidence.json).

One older finding must not be repeated as an unfixed claim: B4F-086's post-verdict handholding has a
current implementation in `Get-SpecrewVerdictCapturedDirective`, wired into prompt-entry capture. It
explicitly tells the agent to begin the authorized next stage in the same turn. Preserve that behavior.

## Recommended bounded repair and acceptance

Separate the turn declaration from authorship of the conversation. Keep token identity, receipts,
crossing binding and missing-artifact guards. Define what the human sees for a workshop question,
background progress, ordinary completed answer and actual boundary, without forcing all four through
the present three canned outputs. The agent must retain responsibility for the useful explanation,
question, recommendation and next step. A completed tool call must not count as visible presentation.

Use one composed response that preserves the current question and, at a boundary, includes the actual
review targets and specific decisions alongside the machine-derived approval phrase and marker. Give
orientation one owner at session opening. Do not repair this by loosening receipt authority, adding more
confirmation turns, or another reminder to paste the agenda while preserving the competing command.

Acceptance must include the integrated conversation:

1. Replay the supplied pre-answered walk: product-domain closes; agenda is shown once; `yes` binds;
   each selected lens closes on its one scoped `move on`; spec and a useful specify packet follow.
2. Assert that waiting for a human never emits `nothing needed`, and that a new question cannot be
   suppressed by generic turn-end output or progress deduplication.
3. At a real boundary, verify visible artifact links, substantive choices/risks, recommendation and
   next-stage behavior, as well as the exact crossing/marker. No approval exists before the human reply.
4. After a captured approval, begin the next authorized work without another start request.
5. Exercise both a fresh feature and a second feature, plus a resumed session. Show orientation once,
   before the first question. Verify the installed package on the actual host, not only synthetic fixtures.

Verdict: the candidate fails its recorded zero-repair-prompts first-run criterion. This investigation
establishes a repair target; it does not claim a fix, a complete beta4 review, or release readiness.
