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
