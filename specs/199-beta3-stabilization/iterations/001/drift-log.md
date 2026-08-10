# Drift Log: Iteration 001

**Schema**: v1

<!--
  Markdown authoring note (Specrew lifecycle convention):

  When you add new drift events to this file, watch for MD032 (blanks-around-lists).
  A sentence ending with a colon, immediately followed by a bullet list, is the most
  common violation. Always put a BLANK LINE between the colon line and the list:

      BAD:                              GOOD:
      Resolution steps:                 Resolution steps:
      - Step one                        <— blank line here
      - Step two                        - Step one
                                        - Step two

  The F-033 pre-boundary markdownlint gate runs markdownlint-cli --fix on .md
  changes before every boundary-sync write, so most violations auto-fix — but the
  blank line you write in the first place avoids the cleanup churn.
-->

## Summary

**Total drift events**: 18 (DRIFT-199-I001-001 through -018)
**Resolution status**: carried per event in each entry's own heading — several are marked open with a
recorded maintainer ruling, so a single rate here would misstate them.
**Specification drift**: None detected; the events are defect and process records.

## Before-implement verdict — ratification clause (maintainer, 2026-08-10)

Recorded verbatim in intent alongside the verdict, so the ledger explains itself without
cross-referencing. The verdict history would otherwise show a jump from `tasks` to
`before-implement` with three implement-labelled commits in between.

> This verdict authorizes ordinary implementation from here forward AND ratifies the
> three exception commits that preceded it — `afe1dd1e` (the activation-premise repair),
> `99860254` (the run-id minter fix), and `477a649c` (the committed verification plan) —
> each ruled in scope by the maintainer individually under the closed-scope exception,
> with its bounded instruction recorded in this drift log.

Hashes verified against `git log` before recording: all three resolve to the commits
named above.

## METHOD RULE — a relayed diagnostic is evidence only if the relayer measured it

Recorded 2026-08-10 at the maintainer's instruction, as a rule in its own right rather than as a
footnote to the defect that produced it.

> A diagnostic handed to the next session carries the authority of a MEASUREMENT only when the
> relayer actually measured it. Reading a function's head and its comment and reporting the result
> as verified is INFERENCE, and inference from a comment inherits whatever that comment gets wrong.

**The instance**: the session-opening brief stated that `Get-ContinuousCoReviewMachineryPaths` called
without `-RepoRoot` "returns the core list only" and ruled the previous session's hypothesis out on
that basis. The claim came from the function's own comment (`omit for the core-only list`). The
comment was false — the bare call returns THIRTEEN entries, three of them the co-review engine
itself — and the false clause was the whole defect (DRIFT-199-I001-016). Re-measuring found in one
probe what the relayed diagnostic had ruled out.

**Why it is worth a rule and not just a correction**: the two other hypotheses in the same brief WERE
measured and were correctly excluded, so the brief was right about everything it had actually run.
The failure mode is specific — a comment read as a result — and it is invisible at the receiving end,
because a relayed conclusion arrives stripped of how it was obtained.

**How to apply**: state the method alongside the claim when relaying a diagnostic ("measured, probe
output below" versus "read from the comment, unverified"), and re-measure anything that arrives
without one before letting it narrow a search.

## Post-boundary spec amendments (surface at review-signoff as a diff-to-approve)

Recorded per the 198 obs-7 lesson: amendments landing after a boundary verdict are
surfaced explicitly at the next boundary, never absorbed silently.

- **2026-08-10, maintainer ruling** — FR-012 and SC-007 amended: acceptance for the
  campaign bootstrap is a fresh project completing a FULL ROUND, not merely passing
  preflight. Rationale recorded in the spec: getting one round to run during this
  feature required clearing seven distinct defects, so the first-run path has never
  been exercised end to end, and a preflight-only criterion would pass while the path
  stayed broken. US5 scenario 1 aligned to the same wording.

## Standing instructions carried from the same verdict

- **T003 fixture case (two-governor collision)**: when T003 resumes, add a fixture
  pinning the adjudication rule the maintainer confirmed — a recorded crossing in
  controller truth WINS over the campaign block's self-describing no-marker clause.
  Evidence: the 2026-08-10 before-implement stop, where the boundary evidence gate
  demanded the verdict marker for `crossing-9b3d255e` while the campaign block
  simultaneously instructed that no marker be emitted.
- **T007 PSModulePath question — measure, do not judge**: every governed project's plan
  carries at least one PowerShell-invoked command (the governance validator), so whether
  the PowerShell stack default carries `PSModulePath` is a stack-default question, not a
  project-specific one. In T007, run the governance validator once under a scrubbed
  environment WITHOUT `PSModulePath` and let the result decide. Record the measurement,
  not the reasoning.

## Events

### DRIFT-199-I001-001 — two-message decision stop at the co-design ask (resolved)

- **Observed**: 2026-08-10. The co-design presentation ended the turn without the
  non-boundary context packet; the Stop hook bounced and the packet was rendered in a
  follow-up message — a live instance of the two-message decision-stop pattern that
  FR-017 (one-message decision stops) drives to zero at the instruction layer.
- **Citation**: FR-017; the 208 rule lineage in the beta3 carry ledger (stop-surface
  family, decision-yield composition).
- **Resolution**: human-decision — recorded as evidence for W8's instruction-layer
  work; subsequent decision-yield stops in this session compose packet + ask in one
  message.

### DRIFT-199-I001-002 — pending-verdict stop artifact not emitted at the plan sync (open)

- **Observed**: 2026-08-10T01:15:50Z. The plan boundary sync recorded the crossing
  (`crossing-eb1123ca...`, clarify -> plan, boundary commit d9b1cc85) in
  `.specrew/start-context.json` but `.specrew/runtime/pending-verdict-stop.md` was
  not written; the two earlier syncs (specify, clarify) emitted it. The preceding
  attempts of the same sync halted at the markdownlint pre-boundary gate and at the
  stale-hash guard — sequence possibly relevant. The boundary stop was rendered from
  the recorded `pending_crossing` (controller truth) with the marker taken from its
  from/to values, per the gate-stop skill's artifact-first rule rationale.
- **Citation**: FR-023 (records state facts); gate-stop skill DRIFT-198-I011-012
  lineage (marker must come from controller truth, never phase inference).
- **Resolution**: deferred — routes to the ledger's beta4 list unless it recurs and
  blocks a boundary (scope-closed feature; the crossing record sufficed here).
  **Human instruction (plan verdict, 2026-08-10)**: if it recurs at the tasks
  boundary, diagnose the root cause and record it here before implementation starts —
  diagnosis only; the fix stays deferred to beta4 unless the diagnosis shows it lands
  inside files this feature already touches.

### DRIFT-199-I001-003 — plan sync recorded without iteration identity (resolved)

- **Observed**: 2026-08-10. The first plan boundary sync omitted `-IterationNumber`;
  the crossing recorded with an empty iteration identity, and the Stop-side evidence
  gate refused the boundary stop (stage evidence not locatable in the bound tree) —
  the FR-068-lineage gate behaving as shipped. No verdict was offered against the
  unverifiable state.
- **Citation**: the beta2 release claim's stage-evidence gate; 199 spec FR-023
  (evidence tools verified before trusted).
- **Resolution**: implementation-reverted (process form) — re-synced with
  `-IterationNumber 001`; fresh crossing `crossing-fd27261c` bound to commit
  ffeea775 with the iteration identity present; the stop re-rendered and the plan
  verdict was given over the verifiable state.

### DRIFT-199-I001-005 — F1 (OneDrive) reproduced live on the maintainer's install (open)

- **Observed**: 2026-08-10, running `specrew review --remediate override-block` through the
  INSTALLED module. Exit 1 with
  `review-runtime-managed-file-link-unsupported:C:\Users\alon\OneDrive - Zionet LTD\Documents\PowerShell\Modules\Specrew\0.40.0\scripts\internal\continuous-co-review\_load.ps1`.
- **Significance beyond ledger F1**: the refusal blocked a SANCTIONED REMEDIATION DOOR,
  not merely a campaign run. T067 recorded campaigns being unusable from a OneDrive
  install; this instance shows the disposition/remediation path is equally unreachable,
  so a consumer on the default CurrentUser install cannot even record a governance
  decision. The repo-script path (`pwsh -File scripts/specrew-review.ps1`) is unaffected
  (local volume), which is how work continued.
- **Citation**: FR-011 (reparse-tag discrimination); ledger T067-F1.
- **Resolution**: in scope, covered by task T007 in the harness queue / T006 in tasks.md —
  the reparse-tag work. This instance is added as a second RED reproduction target: the
  remediation door must work from a cloud-placeholder install.

### DRIFT-199-I001-006 — no expressible off-ramp for the pre-code campaign review demand (open)

- **Observed**: 2026-08-10 at the before-implement boundary. The campaign surface goes
  live at `before-implement` by design (worktree-navigator.ps1:158-174, hardened
  2026-08-08 from the testbeta3 dogfood) on the stated premise that "there is
  implementation to review". At that cursor NO implementation exists yet: the block
  `review-required / no-authoritative-campaign-result` demands a review of the PLANNING
  digest.
- **The inexpressible disposition**: the maintainer ruled to decline the pre-code review
  and spend the review budget on the code at review-signoff. The sanctioned instrument
  (`--remediate override-block`) refuses: "Campaign override-block requires --run-id and
  --ack-reason; the disposition is never implicit." Every remediation choice binds to a
  run, and zero runs exist — so "no review is owed at this cursor" has no expressible
  form. The only mechanical exit is to run (and pay for) the review.
- **Relation to the acceptance bar**: this is the F8 family's missing off-ramp
  (fix-everything default with no sanctioned decline) appearing BEFORE any code exists —
  the pattern ledger finding F8 records as the headline failure, and adjacent to the
  sanctioned-quiet-state semantics the maintainer added at the architecture lens (D3).
- **Citation**: FR-007, FR-008 (single-authority stop surface, sanctioned quiet states);
  ledger F8, F5.
- **Resolution**: human-decision, 2026-08-10 — ruled IN SCOPE under the closed-scope exception
  (an unsatisfiable, undeclinable stop surface is clause two of the acceptance bar failing
  live) with a bounded repair: align activation with the rule's own stated premise, RED-first,
  no gate weakened, no bypass added, nothing broader. Delivered as T003 work landing early,
  not new scope.
  **Amended shipped guarantee (maintainer permission, 2026-08-10)**: the 2026-08-08 cases
  `campaign <before-implement|review-signoff>: the packet gate is STILL consulted from the
  implement window onward` asserted the gate stage-UNCONDITIONALLY, while the rule they protect
  is premise-CONDITIONAL ("there is implementation to review"). The two readings diverge on
  exactly one state — an empty stage. Under the maintainer's conditions the guarantee was made
  STRONGER, not looser: each original case keeps its provenance comment plus the recorded
  sharpening rationale and now asserts the live direction against GENUINE committed work; each
  gained a paired sibling asserting quiet ONLY for a fully-resolved records-only delta; and a
  third pair pins fail-closed behaviour (an unresolvable coverage anchor keeps the gate
  consulted). Evidence: 39/39 green across
  `tests/continuous-co-review/unit/continuous-co-review-navigator.Tests.ps1` and
  `tests/continuous-co-review/unit/campaign-activation-implementation-premise.Tests.ps1`.

### DRIFT-199-I001-007 — the campaign engine rejects the run id it just minted (open)

- **Observed**: 2026-08-10, first authorized campaign round
  (`authorization-ref: beta3-t003-activation-slice-1`). Exit 1 with
  `review-campaign-invalid-run-id:run-20260810T072512585-18f6c6e4`.
- **Root cause (read from source, not inferred from the message)**:
  `review-campaign-orchestrator.ps1:751-752` mints an auto run id from the timestamp
  format `yyyyMMddTHHmmssfff`, which contains a literal UPPERCASE `T`.
  `review-authority-core.ps1:89` validates identifiers with
  `-cmatch '^run-[a-z0-9][a-z0-9-]{0,63}$'` — case-SENSITIVE, lowercase only. The minted
  id can therefore never satisfy the validator, so **every campaign run that does not
  receive an explicit `--run-id` fails before a reviewer is invoked**.
- **Cost**: none. The failure precedes any store write — no campaign facts existed
  afterwards, no allowance consumed, no provider spend.
- **Provenance**: the timestamp format arrived with `cbd7b615`
  ("feat(review): wire campaign command authority").
- **Workaround used (no product change)**: supply an explicit lowercase run id
  (`--run-id run-t003-activation-slice-1`). A second validation gap surfaced immediately
  behind it: `FeatureId` does not auto-resolve for the campaign path, so `--feature` and
  `--iteration` must also be passed explicitly.
- **Consumer impact**: a consumer following the block's own instruction
  ("request-authorized-review") cannot run one from the documented CLI surface without
  discovering two undocumented flags.
- **Resolution**: FIXED in scope 2026-08-10 under the maintainer's closed-scope exception
  (a default campaign invocation that fails is a wedged gate with an unreadable message,
  and it lands in files T001/T008 already own).
  **The MINTER was fixed, never the validator**: run ids become filesystem path segments
  under the authority store, so the lowercase-only case-sensitive identifier rule is a
  path-identity containment rule (the beta2 certify-round-3 class) and must not be
  relaxed. The stamp format became `yyyyMMdd-HHmmssfff` — lowercase-safe, still sortable,
  still unique per run.
  **COVERAGE LESSON (maintainer, recorded as instructed)**: this stayed latent from
  `cbd7b615` until now because every run ever observed supplied an explicit `--run-id`,
  so no fixture exercised the DEFAULT path. The new fixture
  `tests/continuous-co-review/unit/campaign-default-run-id-mint.Tests.ps1` pins the
  default path specifically — identity resolved with NO run id — plus uniqueness and an
  explicit guard that an UPPERCASE id is still refused, so the containment rule cannot be
  loosened later in the name of convenience. Evidence: 3 of 4 cases RED before the fix
  (the guard green from the start), 4/4 green after; 61/61 green across the campaign
  orchestrator and public-command suites.

### DRIFT-199-I001-014 — my path-identity consumer never loaded the primitive (resolved)

- **Observed**: 2026-08-10, wider-suite regression. `path identity primitive: lets no consumer fall
  back to a case rule the volume did not choose (DRIFT-198-I009-018)` failed.
- **Cause**: the round-1 fix routed the activation predicate through
  `Get-ContinuousCoReviewPathComparison`, but `worktree-navigator.ps1` never dot-sourced
  `path-identity.ps1` at file scope, so the call depended on ambient load order. That is the
  SHADOWING class the guard exists to stop — a duplicate primitive loaded later silently
  answers with the OS-family rule, invisibly, at every call site.
- **Significance**: this is the SECOND path-identity defect I introduced in the same day, on the
  same code, immediately after recording that the class recurs. The first was using the wrong
  comparison; this was using the right one unsafely. The guard caught what the review and my own
  attention did not — further evidence for beta4's consolidation.
- **Resolution**: FIXED — file-scope guarded dot-source added, guarded on a name unique to the
  module (DRIFT-198-I009-027). `path-identity.Tests.ps1` and the activation fixture green.

### DRIFT-199-I001-015 — the flush-race analyzer reopened on a signature captured TODAY (open)

- **Observed**: 2026-08-10, wider-suite regression. `T109 flush-race forensic analyzer
  (D-197-I009-003 refuted; reopens on a real signature)` failed with the captured record:

  > `10/08/2026 9:11:11: blocked on a PARTIAL header read (dx_lat_hits=2 of 6, dx_lat_len=3321)
  > - possible mid-flush truncation`

- **What it means**: the suspicion was a flush/read race in the conformance Stop-provider — a
  valid packet on disk read as absent, producing a spurious block or double render. The July
  forensic REFUTED it on the then-corpus, and this analyzer was left in place to reopen the
  question if a real signature ever appeared on any machine. The signature above was captured
  during THIS session, in this repository's own conformance journal.
- **Not a regression of this feature**: the analyzer reads machine-local runtime state
  (`.specrew/runtime/conformance-journal.jsonl`), not code. It shows as "new" against the trunk
  baseline only because the baseline worktree carries a different corpus. No change in this
  feature caused the signature; the session's own stop traffic captured it.
- **Standing consequence**: the suite will keep reporting this while the corpus holds the record,
  so it needs a disposition rather than silence.
- **Resolution**: pending maintainer ruling. The analyzer's own note names the remedy (a cheap
  re-read variant, per the iteration-009 revert note), which is conformance-provider work outside
  this feature's ten items — so the default routing is beta4, unless the spurious-block behaviour
  is judged to hit the acceptance bar's wedged-gate clause.

### DRIFT-199-I001-016 — the records-only predicate asked the machinery resolver with no root, and failed OPEN (resolved)

- **Observed**: 2026-08-10. The T003 case `a delta containing implementation DOES stale it`
  expected `review-stale` and got `review-current`. A delta containing
  `scripts/internal/continuous-co-review/worktree-navigator.ps1` classified as records-only.
- **Hypotheses ruled out first, so the record shows what the cause was NOT**: there are no blank
  entries in the machinery list (a blank root would match every path via `StartsWith`), and the
  predicate's early return for a non-records path was present and correct.
- **The measured cause**: `Get-ContinuousCoReviewMachineryPaths` answers DIFFERENTLY depending on
  the root it is handed, and `Test-ReviewCampaignDeltaIsRecordsOnly` called it BARE. With no root
  it cannot run `Test-ContinuousCoReviewSpecrewSourceRepo`, so it takes the DEPLOYED-project branch
  (worktree-reviewer.ps1:116-125) and appends `scripts/internal/continuous-co-review`,
  `scripts/internal/agent-tasks` and `scripts/internal/atomic-write.ps1` to the machinery list.
  Measured directly rather than reasoned about — the bare call returns THIRTEEN entries, not the
  ten-entry core list:

  > `.specrew .specify .squad .agents .antigravitycli .git .claude/settings.local.json CLAUDE.md`
  > `AGENTS.md GEMINI.md scripts/internal/continuous-co-review scripts/internal/agent-tasks`
  > `scripts/internal/atomic-write.ps1`

- **Severity — it fails in the one direction this feature must never fail in**: in the Specrew
  SOURCE repo those three paths are the feature under review, not machinery. A change to the
  co-review engine itself therefore classified as records-only and left a stale review reading as
  current. Under-staling means a real code change slips past a review; every other rule in this
  feature fails toward staling more.
- **Second defect in the same predicate, found while fixing the first**: the comment above it
  promises the machinery list "can never drift from the digest and worktree strips". It had already
  drifted — the digest strip in `Test-ReviewCampaignFinalizationEnvelope` passes `-RepoRoot`, so the
  two lists were computed from different questions in the same file.
- **Third, same call site**: the case rule came from `Get-ContinuousCoReviewPathComparison -Path
  $PSScriptRoot` — the volume holding the ENGINE, not the volume holding the changed paths. On the
  default CurrentUser install those are routinely different volumes (DRIFT-199-I001-005 is that exact
  split: engine under OneDrive, project on a local disk). Asking the engine's volume for the
  project's case rule is the same wrong-source mistake as an `$IsWindows` shortcut.
- **The comment was the trap, and it is now removed at the FUNCTION** (maintainer ruling
  2026-08-10): fixing only the caller would have left `Get-ContinuousCoReviewMachineryPaths`
  documented as safe to call bare, waiting for the next caller. There is no honest core-only answer
  to return — parts (a) and (b) of the resolver disagree about exactly those three paths depending on
  which repository is being described — so a bare call now REFUSES
  (`review-machinery-paths-requires-repo-root`) instead of guessing a branch, and the false comment
  is replaced by the reason. Verified safe first: every call site in the tree already passes
  `-RepoRoot`, so nothing relied on the removed behaviour. Pinned by a new case in
  `tests/continuous-co-review/unit/worktree-reviewer-machinery-paths.Tests.ps1`.
- **A brittle guard found while pinning it, fixed rather than padded**: that suite's structural case
  sliced a fixed 6000-character window from the function start, so adding a comment silently
  truncated the block and the assertions failed for a reason unrelated to what they guard. It now
  slices to the next top-level function. A structural test that reports the wrong defect is worse
  than none.
- **Citation**: FR-009 (records deltas must not stale a reviewed digest); FR-012 (the one machinery
  resolver); the path-identity volume rule (DRIFT-198-I009-018).
- **Resolution**: FIXED. `-RepoRoot` threaded through `Resolve-ReviewCampaignVerdictPacketDecision`
  into the predicate and on to the resolver, so the answer belongs to the root being classified; the
  comparison now asks the PROJECT's volume; and an absent or unresolvable root fails CLOSED (stales)
  rather than guessing a machinery list, since guessing is what produced this. Not made a mandatory
  parameter on purpose: this runs on the Stop path, where a missing mandatory parameter prompts an
  interactive host and hangs the hook instead of failing.
  **Both directions of the same call are now pinned**, because the fix is "consult the resolver for
  THIS root", not "hardcode the source-repo answer": in the source repo the engine path stales; under
  a non-source root the identical path is records-only; an unresolvable root stales. Evidence: 11/11
  green in `tests/continuous-co-review/unit/campaign-stop-authority.Tests.ps1`, and 88/88 green
  across `review-public-campaign-command`, `review-window-codex-default`,
  `campaign-activation-implementation-premise` and `continuous-co-review-navigator`.

### DRIFT-199-I001-017 — path-identity, THIRD instance in one day; and what the guard actually did (resolved)

- **Observed**: 2026-08-10. `review-signoff-evidence-gate.ps1` calls
  `Get-ContinuousCoReviewPathComparison` but carried NO file-scope dot-sources at all, so the call
  depended on ambient load order — the SHADOWING class where a duplicate primitive loaded later
  silently answers with the OS-family rule, invisibly, at every call site.
- **Third instance of this class in a single day**, in the very file T003 was editing: the first used
  the wrong comparison, the second (DRIFT-199-I001-014, worktree-navigator.ps1) used the right one
  unsafely, this one repeats the second in a different file.
- **Resolution**: FIXED the same way — a file-scope guarded dot-source, guarded on
  `Get-ContinuousCoReviewPathComparison`, the exact function this file calls. Guarding on the exact
  function rather than a sibling name is the sharper form (`review-engine-resolution.ps1` uses it):
  DRIFT-198-I009-027's shadow survived a guard that probed a DIFFERENT name, and a stale copy of
  path-identity.ps1 satisfies the older names while lacking anything added since.

**The guard finding, CORRECTED by measurement — the working assumption was that the guard had missed
this instance, so it was not scanning every file that calls the primitive. It is, and it did not miss
it.** Run against the tree before any fix, `path-identity.Tests.ps1` was already RED, naming the file:

> `because review-signoff-evidence-gate.ps1 must load the primitive into its own scope, but it did
> not match.` (14 passed, 1 failed, 1 skipped)

The guard enumerates its consumers DYNAMICALLY — every `*.ps1` under the co-review directory whose
source matches the primitive's call spelling — so the new consumer was picked up the moment the call
was written. Widening its file enumeration would buy nothing; there is nothing to widen.

**What the real gap is, and why it matters more than the assumed one**: the guard was never RUN. The
previous session added the call and then ran only the T003 fixture, so a red guard sat in the tree and
was committed inside `c14a063f`. The failure was authored, detected, and unobserved. Consequences
recorded as facts:

- **SEVENTEEN is correct for the branch point; EIGHTEEN for commit `c14a063f`, which carried a red
  guard.** Both numbers are right about different trees, and a reader who finds eighteen in the
  history should find this entry rather than suspect the baseline. Confirmed by measurement after the
  fix: **17 failed / 1000 passed** across `tests/continuous-co-review/unit`, failure set identical
  name for name to the recorded seventeen.
- **The lesson, and it is not the one first assumed.** The working assumption was a coverage gap in
  the guard; the maintainer retracted that after the measurement above. The durable lesson is that
  **a guard only guards code whose author runs it** — a per-file edit does not know which class guard
  it just broke, and selection-by-what-the-task-touches will always trail the code.
- **Acted on immediately rather than deferred (maintainer ruling)**: the class-guard suites are now a
  PERMANENT lane in `.specrew/verification-plan.json` (`f199-class-guards`: the path-identity guard,
  the volume differential, and the machinery-path policy), never selected by what a task happens to
  touch. That converts the lesson into a mechanism inside work this feature already owns, and it
  means the next engine edit cannot commit a red guard unnoticed. Roughly 10 s combined, validated
  through the shipped contract (`Test-ContinuousCoReviewVerificationPlan` → valid).
- **Still one more argument for the beta4 consolidation target** already recorded — making the
  primitive the ONLY REACHABLE path rather than the recommended one. The lane catches a red guard
  fast; only unreachability stops the defect being written.

### DRIFT-199-I001-018 — making the pause consult live turned a latent ordering bug into a wedge (resolved)

- **Observed**: 2026-08-10, immediately on wiring the four T003 consults into
  `Get-ReviewCampaignVerdictPacketDecision`. T051's own fixture (`delegates one public operation
  through campaign ports and preserves the exact origin state`) went red: the signoff gate returned
  `block` where it had returned `allow`, with
  `reason=human-pause-decision-outstanding`.
- **Cause, and it is mine**: `Resolve-ReviewCampaignVerdictPacketDecision` evaluated the pending-pause
  quiet BEFORE the latest-result evaluation. That ordering was harmless while nothing supplied
  `-PendingPause`; the wiring made it live. **T001 makes every round end in a pause**, so after any
  completed round a pending pause and that round's clean pass describe the SAME tree at the same
  moment — and the pause short-circuited `boundary-clean`.
- **Why it is a wedge rather than noise**: the boundary packet IS how the human answers a pause.
  Quieting it left them holding a decision with no surface to answer it through, on a tree whose
  review had already passed cleanly. That is the wedge class this feature exists to remove, arriving
  from the direction the pause rule was written to protect.
- **The rule that resolves it**: a pending pause suppresses a DEMAND — do not nag for another review
  or another disposition while one is already sitting with the human — and releasing what they need
  in order to answer is not a demand. So the pause never suppresses a boundary-releasing result.
- **Resolution**: FIXED. The "would this reach a boundary route" question is now ONE predicate,
  `Test-ReviewCampaignResultReleasesBoundary`, consumed by both the pause guard and the
  `boundary-clean` return so the two cannot drift apart; the sequential gates between them stay
  sequential because each owes the consumer a different message. Pinned by a paired fixture — a clean
  pass plus a pause on the same tree returns `boundary-clean`, while the same pause over a findings
  result still returns `pause-pending`, so the fix can never be read as "a pause is ignorable".
- **Method note worth keeping**: this was caught by an EXISTING fixture in a suite I had not changed,
  not by reasoning about my own edit — the same shape as DRIFT-199-I001-014. The wiring's own new
  fixtures were all green while this was broken.

### FR-009 — the expectations it moved, old and new side by side (recorded 2026-08-10 at the maintainer's instruction)

Recorded so a later reader sees a guarantee SHARPENED BY A REQUIREMENT rather than a test bent to fit
new code. All four live in `tests/continuous-co-review/unit/review-public-campaign-command.Tests.ps1`.

**The requirement that moved them** — FR-009: *commits touching only governance/records files MUST NOT
stale a reviewed digest.* Its live evidence is DRIFT-199-I001-013, where a commit whose entire content
was this drift log flipped the surface to `review-stale`: writing down what a review found invalidated
that review, so currency was unachievable by construction.

| Case | Delta | Old assertion | New assertion |
| --- | --- | --- | --- |
| `denies every non-review-evidence finalization path` (spec) | `specs/001-demo/spec.md` | `route = review-stale` | `route = review-current` |
| same (contract) | `specs/001-demo/iterations/007/plan.md` | `route = review-stale` | `route = review-current` |
| same (state) | `specs/001-demo/iterations/007/state.md` | `route = review-stale` | `route = review-current` |
| same (script) | `scripts/change.ps1` | `route = review-stale` | **unchanged** — reviewable content still stales |
| same (test) | `tests/change.Tests.ps1` | `route = review-stale` | **unchanged** |
| `denies an allowlisted envelope chain whose finalization parent is not the reviewed commit` | two commits, both under `specs/001-demo/iterations/007/` | `route = review-stale` | `route = review-current` |

**What did NOT move, in any row**: no boundary packet is released and no finalization fact is
published. Those were previously implied by the route name; they are now asserted EXPLICITLY
(`render_boundary_packet`, `render_verdict_marker`, and the absent finalization fact), which leaves
each case stating its own guarantee instead of borrowing one. The route answers "does the review still
cover this tree"; the assertions answer "was anything authorized". Only the first is what FR-009
speaks to, and separating them is what makes this a sharpening rather than a relaxation.

**Open scope question carried to the maintainer**: the predicate treats ALL of `specs/` as records,
while the recorded requirement in DRIFT-199-I001-013 was narrower — "under the FEATURE'S OWN
`specs/<feature>/` records tree". The difference is visible in row one: a spec change is a
requirements change, and it is arguable that moving the requirements should stale a code review even
though the file is records. Left broad pending a ruling, because FR-009 says "governance/records
files" without qualification and the design record classifies `specs/` as records; narrowing it to the
iteration records tree is a one-line change.

### Measured proof line — T003's two-governor fix, transcribed from a live stop (2026-08-10)

Not drafted ahead of the run. The FIRST stop after `9d93c91c` landed rendered the scoped clause on
the maintainer's own session, on the same collision that had been adjudicated by an agent three times
earlier in this feature:

> `Specrew campaign review — review-stale.`
> `The latest campaign result remains useful evidence but targets a moved or earlier snapshot and`
> `cannot authorize the current tree.`
> `Run: run-20260810-085753967-af5bef76`
> `Implementer action: request-current-digest-review`
> `(This is a campaign review block, not a lifecycle verdict. It does not govern the recorded`
> `crossing crossing-fdfd08331c434810bfb008886e73a3476306c1bf484c84813463914ae4ba0605`
> `(before-implement -> review-signoff), which is still pending your decision: that crossing's`
> `verdict marker applies as normal, and this block does not suppress it.)`

**What it demonstrates, stated narrowly**: the block kept its review position (`review-stale`, and
the same implementer action), stopped claiming authority over the lifecycle marker, and named the
exact crossing it defers to — read from controller truth, not inferred. The adjudication a consumer
could not previously make is now stated ON the surface (FR-007 / SC-003).

**What it does NOT demonstrate, recorded so the evidence is not over-read**: deferring on the marker
is not a marker being OWED. At this stop the crossing's destination is `review-signoff`, whose
evidence (`review.md`) does not exist in the bound tree, so the boundary evidence gate is the governor
that decides — and it has been refusing correctly. The two governors now say compatible things:
"this block does not suppress the crossing's marker" and "that crossing has no evidence to approve
yet" can both be true at once, which is precisely what they could not do before.

### Measured proof line — first successful end-to-end campaign round

Transcribed from the run output, not drafted ahead of it:

> `review terminal elapsed=687.8s remaining<=212.2s tree=dead output=observed
> validated-findings=3 - terminal-result-published`
> Run `run-20260810-085753967-af5bef76`; `Invoked: True`; `Verdict: findings`;
> `Completion: complete`; `Currentness: current`; heartbeats 87.

Shape after the resize: preflight (including the slice verification lane) completed at
245.0 s, leaving ~430 s of the 900 s window for the reviewer — the reviewer received the
majority of the budget, which is the shape the maintainer's sizing rule asks for.

This is the first round in this feature to reach a reviewer at all. Reaching it required
clearing, in order: the pre-code activation demand (DRIFT-199-I001-006), the run-id minter
(-007), the feature-id non-resolution (-009, worked around), the missing verification plan
(-008/-010), and the window/scope mismatch (-012).

### DRIFT-199-I001-013 — a records-only commit staled the review that produced those records (open)

- **Observed**: 2026-08-10, immediately after commit `9a23da56`, whose ENTIRE content is this
  drift log — a records file. The campaign stop surface flipped from `review-required` to
  `review-stale` / `latest-result-not-current`, naming run
  `run-20260810-085753967-af5bef76` and demanding `request-current-digest-review`.
- **The shape**: writing down what the review found is what invalidated the review. The
  ledger's F5 sharpening names this exactly — satisfying the gate moves the target, so
  currency is unachievable by construction.
- **Why the digest moved**: the machinery strip excludes `.specrew`, `.specify`, `.squad`
  and host-mirror dirs, but `specs/` is reviewable content and therefore digest-significant.
  A lifecycle-records commit consequently reads as a source change.
- **Direct evidence for FR-009** ("commits touching only governance/records files MUST NOT
  stale a reviewed digest"): this instance is the T003 fixture — a commit whose entire delta
  is under the feature's own `specs/<feature>/` records tree must leave a reviewed result
  current.

### Round-1 fix ruling and the two method lessons (maintainer, 2026-08-10)

**Why all three were fixed rather than carried** — recorded because it models the rule this
feature is building, not a fix-everything default: each clears the severity floor with a
concrete failure scenario in a SHIPPED surface of this feature. One silences a review gate;
two leaves a consumer requirement unfinished on the path a consumer actually runs; three
makes an acceptance criterion falsely green. Polish would have ridden as a recorded residual.

**Path-identity lesson (finding 1)**: this is the beta2 certify-round-3 path-identity class
RECURRING. The single-source comparer (`path-identity.ps1`) already existed, and it appears in
`reviewed-state-digest.ps1` — a file read while writing the defective fix. The reviewer session
endorsed the predicate without catching it. Vigilance did not catch this class even freshly
named and freshly read; the mechanical comparer would have. That is evidence for beta4's
path-identity consolidation: the fix is routing every containment comparison through the one
primitive, not asking reviewers to remember.
Fixed by routing through `Get-ContinuousCoReviewPathComparison` (the sibling the comparer
wraps, and the shape a `StartsWith`/`Equals` call needs) with `-WhenUndetermined 'distinct'`,
so an undetermined volume keeps the surface LIVE.

**Test-design lesson (finding 3)**: a test that derives its expectation from the same source as
the code under test cannot detect that the source is wrong — it verifies plumbing, not the
requirement. The T011 fixture derived the expected version from the manifest the provider reads
and asserted only that some suffix existed, so it passed while the manifest said `beta2` and
SC-010 (`0.40.0-beta3`) was false. **Rule**: acceptance criteria that fix a LITERAL value get
LITERAL assertions; derived assertions are for invariants only. The manifest prerelease is now
`beta3` (psd1 field only, `extension.yml` left bare per the beta2 precedent;
`validate-versions` re-run clean: Spec Kit 0.12.9, Squad 0.11.0, compatible, exit 0).

### Round-1 findings (held for the maintainer; no fix round started)

Three findings, all severity `major`, recorded in the authority store under the run above:

1. **Case-insensitive path matching can suppress a real review** — the implementation-presence
   classifier added by `afe1dd1e` compares changed paths to the machinery and `specs` roots
   with `OrdinalIgnoreCase`, while this repository derives path case semantics from the target
   volume. On a case-sensitive filesystem a change under a case-distinct root is a genuine
   reviewable path but classifies as records-only; if it is the only delta the navigator
   returns `campaign-not-applicable` and never consults the gate.
2. **The public campaign timeout output still omits the next step** — the consumer-shaped
   text added by T009 sits on the signoff-gate decision route only. The `specrew review
   --live` campaign branch prints the raw failure reason and exits without naming
   `co_review_timeout_seconds`, and `--help` still advertises a 120-second default.
3. **The banner acceptance test blesses the stale manifest** — the manifest still declares
   `Prerelease = 'beta2'`, so the fixed provider renders `0.40.0-beta2`. The T011 fixture
   derives its expectation from that same manifest and only checks that some suffix exists,
   so it passes while SC-010 (`0.40.0-beta3`) is false.

Transcribed from the measurement, not drafted ahead of it (198 method rule). Run locally
at HEAD after the three ratified exception commits:

> `F-198 honesty regression suite: all 95 suites green in 627.685s.` (exit 0; measured
> elapsed 628.5 s, `-PerTestTimeoutSeconds 300`)

This includes `tests/continuous-co-review/unit/continuous-co-review-navigator.Tests.ps1`
(34.560 s) — the file whose 2026-08-08 guarantee was sharpened — so the amended assertions
pass inside the honesty regression lane as well as in isolation.

### DRIFT-199-I001-012 — the slice review's verification budget cannot fit its window (open; authoring error owned)

- **Observed**: 2026-08-10, run `run-20260810-074723936-616f0b0e`. Terminal after 894.6 s
  of a 900 s window: `verification-command-failed:f199-deterministic-registry:
  diagnostics-require-command-scoped-disclosure`. `Invoked: False` — the reviewer was
  never started, so no provider spend; roughly 15 minutes of wall clock was consumed.
- **Cause, established by measurement rather than by unsealing**: the registry command
  needs ~628 s and is fully green (proof line above). The round's total budget was 900 s,
  and the verification command's own `timeout_seconds` was authored at 1200 s — larger
  than the window containing it. The plan could not pass by construction.
- **Authoring error owned**: the 1200 s figure was copied from the beta2 plan, which
  governed SIGNOFF-grade verification where a long window is appropriate. Reusing it for
  a mid-implementation slice review under a 900 s window was the mistake.
- **Second finding, ledger F3 reproduced**: the failure reason was SEALED
  (`diagnostics-require-command-scoped-disclosure`) — the consumer cannot see why their
  verification failed without a human-authorized diagnostic disclosure. FR-013 is the fix;
  this is a live reproduction on the maintainer's own repository.
- **Ruled 2026-08-10 (maintainer)**: no unsealing — the local clock already answered it.
  The registry passes (95/95, 627.7 s), so the sealed failure was the window, not a red
  suite; spending a diagnostic authorization would buy nothing. Resizing rule: size
  verification to fit COMFORTABLY inside the round — more than roughly half the window is
  the wrong shape, since the reviewer needs the remainder (627.7 s of 900 s was 70%).
  Scope rule: the full deterministic registry is the RELEASE GATE lane; a slice review
  points at the suites the slice touches, and the plan legitimately differs between those
  contexts. Both rules recorded in T007's design record.
- **Underlying defect, recorded separately as the durable half**: per-command
  `timeout_seconds` and the round window are unrelated numbers with NO consistency check,
  so the engine accepted a plan that could not possibly pass, ran it for the full window,
  and reported a sealed failure. A consumer authoring their first plan will do exactly
  the same thing with no way to see why. The cheap fix — validate at plan-validation time
  that command timeouts fit the configured window, naming BOTH numbers in the message —
  is recorded in T007's design record; implement only if it is a few lines, else beta4.

### DRIFT-199-I001-011 — ledger F5 (in-flight blindness) reproduced with store evidence (open)

- **Observed**: 2026-08-10, while the authorized round was executing. The campaign stop
  surface emitted `review-required / no-authoritative-campaign-result` with implementer
  action `request-authorized-review` — instructing that a review be requested while one
  was already running under the maintainer's authorization.
- **Store evidence at that moment** (`.specrew/review/authority/campaigns/cmp-199-beta3-stabilization-i001/runs/`):
  - `run-20260810-074723936-616f0b0e` — `requested.json`, `reserved.json`, and NO
    `result.json`: reserved and in flight, not terminal.
  - `run-t003-activation-slice-1` — the earlier terminal `preflight-failed` run.
- **Maintainer ruling 2026-08-10 — this narrows FR-008's work**: the task is NOT "add
  in-flight awareness" but "make the EXISTING `review-running` route recognize a
  reserved, non-terminal run". T003's fixture pins exactly that shape — a run holding
  `requested.json` + `reserved.json` with no `result.json` must suppress the block and
  route to `poll-existing-run` — and it writes itself from the evidence below.
- **Sharper than the ledger's statement**: the classifier already HAS an in-flight route
  (`review-running` / `current-review-in-flight` / `poll-existing-run`,
  `review-signoff-evidence-gate.ps1:366`). The defect is not a missing concept — the
  existing detection did not match this reserved, non-terminal run. T003's FR-008 fixture
  should pin THIS shape: a reserved run with no terminal result must suppress the block
  and route to `poll-existing-run`.
- **Incidental confirmation**: the run id `run-20260810-074723936-616f0b0e` is the fixed
  minter's output (lowercase-safe stamp) reaching the store on the default path, with no
  explicit `--run-id` supplied — the DRIFT-199-I001-007 fix working end to end in the
  shipped flow.

### DRIFT-199-I001-010 — the verification definition is per-machine, not in the repository (sharpens ledger F2)

**Measured 2026-08-10** against `C:\Dev\specrew-beta2-hardening\.specrew\verification-plan.json`
(commands run in that worktree; results transcribed):

| Property | Measurement |
| --- | --- |
| Tracked by git | NO — `git ls-files --error-unmatch` errors; `git status` reports `??` |
| Ignored by git | NO — `git check-ignore -v` returns nothing (it could have been committed) |
| Created / last modified | 2026-07-19 16:02:54 / 2026-07-19 18:54:29 |
| Feature/iteration binding | hardcoded: `plan_id: f198.i008.signoff.v5`, and `-IterationPath specs/198-beta2-hardening/iterations/008` |

Consequences, stated as facts: the definition survives neither a clone, nor a new
worktree, nor a new feature. It is hand-authored and per-machine. This feature's own
worktree had none, which is why the first authorized campaign round terminated
`preflight-failed` (DRIFT-199-I001-008).

**Honest-claims item against the release record**: the three certification rounds that
gated the v0.40.0-beta2 tag verified against a definition that is absent from the
repository. The runs and their results are recorded in the review authority store and
stand as recorded; the verification DECLARATION they executed is not reconstructible from
the repository at any commit. This is a recorded gap in the evidence chain, not a
reopening of the certification and not a claim about the runs' outcomes.

**Resolution for this feature**: `.specrew/verification-plan.json` is authored for
feature 199 and COMMITTED (maintainer ruling: the verification definition must live in
the tree the reviewer reads, not beside it). It carries the deterministic registry lane
plus governance validation pointed at `specs/199-beta3-stabilization/iterations/001`, and
the N4 env_refs list including TMPDIR. One disclosed addition beyond N4: `PSModulePath`,
because this repository's verification commands are PowerShell and resolve modules
through it — exactly the project-specific one-line addition the N4 default anticipates.
Validated through the shipped contract before use (`Test-ContinuousCoReviewVerificationPlan`
returned valid).

### DRIFT-199-I001-009 — the campaign command does not resolve the feature id (deferred)

- **Observed**: 2026-08-10, immediately behind the run-id defect. With `--run-id` supplied
  but no `--feature`, the campaign path failed with
  `Cannot validate argument on parameter 'FeatureId'. The argument "" does not match the
  "^[0-9]+-[a-z0-9][a-z0-9-]*$" pattern.`
- **Cause**: the campaign command does not consult `.specify/feature.json` the way other
  Specrew scripts do, so the feature id arrives empty at a validated parameter. (The
  identity resolver itself has fallbacks — navigator feature root, then branch name — but
  the empty value is rejected before reaching them.)
- **Consumer impact**: a consumer running the review the stop surface demands must
  discover `--feature` and `--iteration` by trial.
- **Resolution**: DEFERRED per the maintainer's ruling — it is not a one-line fix inside
  code already being touched (it sits in the CLI's campaign branch parameter contract,
  not in the identity minter). Routes to the beta4 list.

### DRIFT-199-I001-008 — ledger F2 reproduced: the authorized review cannot run without a verification plan (open)

- **Observed**: 2026-08-10, run `run-t003-activation-slice-1` (codex, 900 s window,
  `authorization-ref: beta3-t003-activation-slice-1`). Terminal state after 134.2 s:
  `runtime_outcome: preflight-failed`,
  `failure_reason: verification-not-configured:no supplier output at
  .specrew/verification-plan.json (FR-049 supplier not configured)`.
- **Significance**: this is ledger finding T067-F2 (fresh projects have no verification
  plan and the campaign preflight cannot proceed) reproducing on the maintainer's own
  repository, and it produces a BOOTSTRAP DEADLOCK at the gate: the campaign stop surface
  demands a review, and the review cannot start without an artifact that only
  `specrew init` scaffolds. Task T007 (FR-012/FR-013) is the fix.
- **Cost measured, not assumed**: `invoked: null` — the reviewer process was never
  started, so no provider spend; and a release fact
  (`releases/res-c7aec2d1e10f88a63c15.json`) returned the reserved slot with the failure
  reason, so no round allowance was consumed.

### Evidence note — ledger F4 did NOT reproduce on this failure class

Ledger finding F4 records infrastructure failures consuming the round allowance. On this
`preflight-failed` run the pre-invocation release path worked: the slot was reserved,
then released, with the failure reason recorded. Stated as a measurement, not a claim
about F4 generally — T008's RED fixture must therefore pin the specific failure classes
that do NOT release, rather than assume every infrastructure failure charges a round.

### THE BRANCH TEST BASELINE IS SEVENTEEN (restated 2026-08-10 by maintainer ruling)

A future measurement reading 17 must not treat it as a fresh regression. The branch baseline is:

> **16 inherited failures at `acbb4366`** (named individually below) **+ 1 T109 flush-race
> analyzer failure**, firing on a preserved real signature dispositioned to beta4.
> Measured total on this branch: **17 failed / 989 passed** across
> `tests/continuous-co-review/unit`.

**Rule recorded with it — a detector that goes green because its evidence was deleted has not
been fixed.** The T109 analyzer reads machine-local journal state
(`.specrew/runtime/conformance-journal.jsonl`). If that corpus rolls over, the test passes again
while the defect is untouched. The DURABLE evidence is the verbatim signature captured below, and
that is what beta4 inherits. A later green is not resolution.

### Flush-race routing ruling (maintainer, 2026-08-10) — beta4

DRIFT-199-I001-015 routes to beta4. Reasoning recorded so the routing stays honest:

- **Not a wedge.** A spurious packet block costs one extra turn and then passes. That is what
  separates it from every defect ruled in scope today, each of which made a state unreachable or
  a requirement false.
- **New territory.** It lives in the conformance provider, a subsystem this feature has not
  touched; taking it would open a fifth exception into new code on the strength of one signature.
- **Cheap in lines, not in risk.** The remedy the analyzer names (a cheap re-read variant) changes
  READ SEMANTICS IN THE STOP PATH — the most safety-critical hook path in the product. Beta4 does
  that deliberately rather than as a fifth in-flight exception.

### Path-identity: what the guard proves (recorded 2026-08-10, maintainer framing)

The counter-story to "vigilance failed". The guard that caught DRIFT-199-I001-014 was written for
a PREVIOUS incident of the same class (DRIFT-198-I009-027). It caught today's defect after both
the reviewer session and the implementer's own attention had missed the class TWICE in one day —
once using the wrong comparison, once using the right one unsafely.

**What this sharpens for beta4's path-identity consolidation**: the target is not "use the
comparer". It is to make the comparer the ONLY REACHABLE PATH. A primitive that can be bypassed by
forgetting a dot-source will be bypassed again — today is the proof, from someone who had just
finished writing the lesson down.

### Named test baseline — inherited failures, measured 2026-08-10 (not this feature's)

Measured at the maintainer's instruction so this feature never inherits credit or blame
for failures it did not cause. Both runs used the identical capture script and path
(`tests/continuous-co-review/unit`).

| Measurement | Commit | Passed | Failed |
| --- | --- | --- | --- |
| Trunk baseline (detached worktree) | `acbb4366` (merge-base with origin/main) | 933 | **16** |
| This branch, after the T003-early repair | `afe1dd1e` | 941 | **16** |

**The two failure sets are IDENTICAL, name for name.** Regressions caused by this
repair: **zero**. The branch also passes 8 more tests than the baseline (the 7 cases this
repair added, plus one further test that runs on the branch and not at the baseline — an
unexplained but non-material delta, recorded rather than smoothed over).

The 16 inherited failures, at `acbb4366`:

1. `T091 inline reviewer spawn - OS-native containment` — the divergent inline `$proc.Kill`
   fallback is DELETED (one kill mechanism)
2. `T026 TG-011 non-convergence escalation` — a ceiling-halt emits a VISIBLE escalation
   finding (false-green guard D-197-I009-010)
3. `navigator "more time" note on a partial reap (T092/R2)` — partial run -> moreTimeNote
   present
4-13. `T067 re-architected co-review signoff gate (FR-025)` — ten cases: blocks with no
   evidence; ALLOWS on a chained pass; BLOCKS HOLE A (gitignored-source staleness);
   BLOCKS HOLE B (unchained pass); A1 multi-hop ALLOWS; A1 multi-hop gap BLOCKS; blocks
   stale after tree drift; blocks when the trunk anchor cannot be resolved (fail-closed);
   allows under a well-formed human-authorized override; ignores a malformed override
14-16. `T073/T074 hard co-review signoff-gate wiring (FR-025/SC-019/SC-020)` — three cases
   on the conditional-Assert seam: (a) no passing run THROWS and persists the block;
   (b) a fresh passing run does not throw; (b2) the allow path returns nothing

Disposition: inherited, out of this feature's closed scope. Routed to the beta4 list
unless one of them blocks the acceptance bar. Not a claim about their cause — only a
measurement of what was already red at the branch point.

### DRIFT-199-I001-004 — plan total arithmetic error (resolved, records-only)

- **Observed**: 2026-08-10, at tasks decomposition. plan.md stated "12.1 SP planned"
  while the W1–W13 table sums to 13.1 SP. The approved table itself was correct and
  is unchanged; only the stated total was wrong.
- **Citation**: honest-state rule (count-claims must match artifacts).
- **Resolution**: spec-updated (records-only) — the total line corrected to 13.1 SP
  with the overcommit against the ~10–12 target made visible; surfaced prominently
  at the tasks boundary stop for the maintainer's ruling.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.
