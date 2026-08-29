# Contract: Beta3 Stabilization Public Surfaces

**Feature**: 199-beta3-stabilization
**Stability**: pre-1.0 (versioned; bridge surfaces carry beta4 replacement notes)

## Pause facts (review authority store)

New immutable fact types published under the campaign's run tree.

### Exported API

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `Write-ReviewCampaignPendingPauseFact` | `(campaign, run, treeState, findingsSummary, cost, budget, recommendation) -> fact` | atomic CreateNew pause fact at round terminal | conflicting existing fact = corruption, fail closed |
| `Write-ReviewCampaignPauseDecisionFact` | `(campaign, run, choice) -> fact` | records the human's numbered answer; sole continuation authority | choice outside the closed enum rejected |
| `Get-ReviewCampaignPendingPause` | `(campaign) -> fact or $null` | read for re-render + the stop governor's quiet check | never throws on absence |

### Invariants

- A pending pause with no decision blocks all spend (nothing runs until answered).
- `fix-and-continue` authorizes exactly one round; agents cannot mint continuation.
- Budget: reviewer-invoked rounds only; per campaign; default 4; explicit human reset.

## Stop-authority consult (stale classifier)

| Behavior | Contract |
| --- | --- |
| Consult order | recorded signoff-gate decision first; classifier never contradicts it |
| In-flight | an authorized running review suppresses the stop-block |
| Records-only delta | never stales a reviewed state |
| Pending pause | quiet — no review demand, no disposition demand |

## Consumer message shapes (rendering contract)

- Decision surface: severity groups with locations; minors visibly non-gating; cost
  `N rounds, M minutes`; budget `N of 4 used`; one-line severity-derived
  recommendation; three numbered options with consequences in the option text; the
  literal nothing-runs-until-you-answer sentence.
- Failure messages: what happened -> what it means for your project -> exact next
  step. Timeout names `co_review_timeout_seconds`; env_refs failure shows the exact
  line to add; reparse refusal names the file and the reinstall path.
- Gloss helper: `Format-SpecrewGlossedId -Id <id> -Title <title>` -> `"<id> — <title>"`;
  consumer templates MUST render IDs through it (missing title = error = failing test).
- Banned machinery nouns (consumer surfaces): crossing, mint, marker, digest, boundary
  sync, verdict capture, controller truth, ratchet, claim-ordered, terminalize.
  Lifecycle stage names + approval phrases stay by design.

## Verdict capture (response contract)

- A reply beginning with a recognized approval phrase captures as that verdict;
  trailing instruction wording is carried, never reclassified.
- Scan window: from the boundary marker forward; first verdict-bearing human turn
  wins; non-verdict turns are skipped.
- Boundary-name words as plain English never flip classification.
- Prompt-submit capture is primary (durable before the agent's next turn); Stop is
  fallback. Hooks deploy reconciles missing registered events; hooks status flags
  wiring drift.

## Reviewer prompt contract (verdict-goal)

The reviewer determines whether the artifact is safe to proceed on. A justified clean
verdict naming what was verified is a successful output. Every finding states a
concrete failure scenario (inputs/state -> observable wrong behavior) or is not a
finding. Output ranked by severity, capped. (Consequence tags: beta4.)

## Configuration

| Key | Default | Notes |
| --- | --- | --- |
| round budget (per campaign) | 4 | explicit human reset replenishes |
| `co_review_timeout_seconds` | host catalog; codex 900 | named in every timeout message |
| `env_refs` (scaffolded plan) | N4 list incl. TMPDIR | names-only pass-through |

## Reparse policy (integrity check)

Cloud-files tag family -> hydrate then hash-verify. Junction and symlink -> refuse with the
consumer message. A reparse point that is **neither a link nor a cloud placeholder** ->
**admit as ordinary content, trusted on the hash of the bytes actually read**, and never
executed: read, hash, and containment-check only. Symmetric across module install,
authority store, frozen snapshot.

**AMENDED 2026-08-11 by maintainer ruling**, in step with FR-011 and US4 scenario 3. This
clause previously read *"Junction, symlink, and unknown tags -> refuse"*. It was left behind
when the requirement was amended, so the contract and the shipped policy described
incompatible behaviour — a reader working from the contract would have reintroduced the
OneDrive failure the amendment exists to fix. Refusing every unrecognised tag refused the
real, common case (measured `0x80420` on a live install), and could not be implemented as
written without P/Invoke, because .NET never exposes the reparse tag. See
DRIFT-199-I001-024, -031.

## Iteration 002 additions (the tag batch, FR-024..FR-033 and FR-010)

### Crossing mint gate (FR-024)

- `Set-SpecrewPendingBoundaryCrossingScope` and the `$nextScope` rebind inside
  `Add-SpecrewBoundaryAuthorization` refuse to open a crossing whose FROM stage owes artifacts (per
  `Get-SpecrewBoundaryStageEvidenceContract`) that are absent on the live filesystem; the refusal is
  journaled with the owed paths. `Sync-SpecrewPendingVerdictArtifactAfterAuthorization` withholds
  `pending-verdict-stop.md` when the next stage owes artifacts (the sync-side guard, ported).
- The verdict marker is `<!-- SPECREW-VERDICT-BOUNDARY: <from> -> <to> @ <crossing-id> -->`; the
  capture verifies `<crossing-id>` against `pending_crossing.crossing_id` and refuses a marker for any
  other identity (journaled `MARKER_IDENTITY_MISMATCH`). The bare `<from> -> <to>` form is accepted
  only when no identity is pending for that pair - never against a pending identity.

### Delivery and durability checks (FR-025)

- `pushed-head`: boundaries `iteration-closeout`, `feature-closeout` only; reads `release_model` and
  `repository_governance.enforcement_mode`; statuses: not-applicable (non-delivery boundary;
  local-only; declared-future posture), fail (active enforcement with no origin; unpushed HEAD with
  an origin), pass.
- `verdict-commit-durable`: every boundary; with an origin, `origin/<branch>` at HEAD (fail otherwise,
  detached HEAD fails); without an origin, not-applicable with the honest note. Message texts are
  the accepted report's, verbatim.

### Constrained readers (FR-026)

- `ConvertFrom-SpecrewProductDomainYaml` and `ConvertFrom-SpecrewImplementationRulesYaml` return
  `$null` when a non-empty document matches zero constructs; the validators' parse-failure message
  names the representation (`{`/`[` first character reads as JSON), states the answers are intact,
  and names the re-write action. Backstops never run on `$null`.

### Lens checkpoint writer (FR-027, FR-028)

- `confirm-workshop-lens.ps1 -ProjectRoot -FeatureRef -Lens`: consumes the phase-`lens` receipt for
  that lens from `.specrew/runtime/workshop-authority.jsonl`; requires `workshop/<lens>.md` nonempty;
  runs `Test-SpecrewProductDomainRecord` (product-domain) or `Test-SpecrewImplementationRulesManifest`
  (code-implementation) when applicable; writes `moved_on`, `confirmation`, `confirmation_scope`;
  refreshes the handover with `--source workshop`. Refusals route through
  `New-SpecrewWorkshopAgendaRefusal` (no machinery nouns). `Resolve-SpecrewWorkshopStateTransition`
  gains `confirm-lens`; the table test pins 8 states x 7 operations.
- Instruction contract: after a non-closing lens reply the agent's next message opens with
  `Recorded: "<reply>". This lens stays open until you type "move on" (or "skip"); anything else is
  taken as more input to the lens.` The repair gate's refusal names the received reply and the exact
  phrase `approved for workshop repair`. `-cne` and the response-authority classifier are unchanged.

### Not-yet-authored spec stub (FR-029)

- `create-governed-feature.ps1` overwrites the scaffolded `spec.md` with a stub carrying
  `<!-- specrew:spec-not-yet-authored -->` and no requirement placeholders;
  `Invoke-SpecrewSpecifyBoundaryLensGate` refuses while the sentinel is present.

### Crossing mirrors (FR-030)

- `Add-SpecrewBoundaryAuthorization` writes, for the active iteration when its files exist:
  `state.md` Current Phase = authorized boundary; `state.md` Iteration Status per the canonical map
  (planning for plan/tasks/before-implement, executing during implement, reviewing at review-signoff,
  retro at retro, complete at iteration-closeout); `plan.md` Status per the same map. The sync
  re-mirrors from the store at start. `Get-SpecrewIterationStateTruthIssues` compares every
  enumerated mirror; a mirror may lead the store by exactly the pending crossing; a mirror ahead by
  more, or on a different ladder, is refused with the truth-gate message.

### Seal ordering (FR-031)

- In `sync-boundary-state.ps1` at iteration-closeout: index -> dashboard render -> seal (last).

### Crossing owner (FR-032)

- `pending_crossing.owner` = `host|session` identity (`Get-SpecrewFireIdentity` over the same parts
  the material attribution uses) or `unknown`. The conformance provider's boundary demand fires only
  when the current session is the owner; other sessions receive one informational line naming the
  pending crossing and its owner. With `owner: unknown` the demand keeps project-wide behavior and
  the packet states that the host does not identify sessions and the demand may have reached a
  session that did not produce the work.

### Capture disclosure (FR-010)

- When a pending crossing exists and the last human turn is verdict-shaped but the classifier does
  not accept it (any `Action` other than approve), the capture emits one visible line:
  `Your reply was received but not recorded as a verdict: it reads as "<classification>" because
  "<first 40 chars>" precedes the phrase. To authorize <from> -> <to>, start the reply with:
  approved for <to>` - and journals the same. The classifier is unchanged.
