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

**Total drift events**: 2
**Resolution rate**: 50% (1/2 resolved)
**Specification drift**: None detected (both events are process observations)

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

### DRIFT-199-I001-011 — ledger F5 (in-flight blindness) reproduced with store evidence (open)

- **Observed**: 2026-08-10, while the authorized round was executing. The campaign stop
  surface emitted `review-required / no-authoritative-campaign-result` with implementer
  action `request-authorized-review` — instructing that a review be requested while one
  was already running under the maintainer's authorization.
- **Store evidence at that moment** (`.specrew/review/authority/campaigns/cmp-199-beta3-stabilization-i001/runs/`):
  - `run-20260810-074723936-616f0b0e` — `requested.json`, `reserved.json`, and NO
    `result.json`: reserved and in flight, not terminal.
  - `run-t003-activation-slice-1` — the earlier terminal `preflight-failed` run.
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
