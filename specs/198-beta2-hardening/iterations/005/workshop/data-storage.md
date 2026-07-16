# Data-storage reassessment

**Status**: complete
**Iteration**: 005

## Confirmed storage model

Use dependency-free local JSON records. The expected project-local volume does not justify SQLite or an append-only event-store subsystem.

```text
review-store/
  campaigns/
    <campaign-id>/
      grants/
      reservations/
      spend/
      runs/
        <run-id>/
          requested.json
          running.json
          terminal.json
          result.json
          validation.json
          classification.json
          report.md
  claims/
    <lineage-id>/
      claim-<generation>-held.json
      claim-<generation>-released.json
      claim-<generation>-abandoned.json
```

## Logical relations

```text
ReviewCampaign 1 ---- * ReviewRun 1 ---- 0..1 ValidatedResult
      |                                           |
      |                                           +---- ReviewReport.md
      |
      +---- allowance grants / reservations / spend

ConcurrencyClaim ---- active ReviewRun + lineage
```

- Every reviewer invocation has a unique `run_id` and its own directory. Reviewers never share a result filename.
- The target digest identifies what was reviewed; the run ID identifies the specific provider invocation. A target digest alone is not unique because the same snapshot can be reviewed by different harnesses, scopes, campaigns, or confirmation runs.
- Run lifecycle facts are bounded immutable stage files published once with atomic create/no-overwrite semantics.
- Accepted machine results and Markdown reports are immutable and unique to the run.
- Campaign grants, spend facts, and audit facts are immutable where possible.
- Campaign and run repositories are their records' sole mutation authorities.
- Cross-record workflows use explicit recoverable states rather than claiming a multi-file transaction.
- No separate audit event store is introduced; the agreed durable audit facts live in campaign/run records.

## Confirmed simplicity principle

Unique immutable files are the default. Shared compare-and-mutate behavior is introduced only for facts that truly select a single winner:

- allocating a limited allowance slot;
- holding or retiring the active lineage claim;
- selecting one accepted result for the campaign.

Do not build a generic revision/CAS framework for every JSON document. Run stages and reviewer outputs avoid contention structurally through unique run directories and one-time stage publication.

## Confirmed immutable coordination model

Claims belong to immutable run identities, not launcher or supervisor processes. The process-owner handoff is removed.

```text
claims/<lineage-id>/
  claim-0001-held.json
  claim-0001-released.json
  claim-0002-held.json
  claim-0002-abandoned.json
  claim-0003-held.json       # current
```

- Acquisition reads the highest claim generation. A still-held generation suppresses another run. A released/abandoned generation permits contenders to atomically create the same next-generation held filename; exactly one `CreateNew` wins.
- Terminal publication is followed by one-time creation of the matching released fact. Held facts are never deleted or overwritten.
- A held claim with no terminal run and a provably dead controlling process is retired by one-time creation of an abandoned fact before a new generation may be acquired.
- Process identity is liveness evidence only; it is not claim ownership.
- Pending review targets are immutable request facts rather than a mutable `pending_tree` property.

Campaign allowance uses immutable grants, reservations, invocation/spend facts, and pre-invocation release facts. The one-active-run-per-lineage rule prevents simultaneous campaign reservations. Actual provider invocation creates an immutable spent fact; pre-invocation failure creates a release fact and consumes no round.

Accepted results use unique target-digest plus run-ID facts rather than overwriting one accepted-result file. Current selection follows campaign/run sequence.

This bounded lifecycle journal is not general event sourcing: each fact has a fixed schema and purpose, and readers derive a small state machine rather than replay arbitrary domain events.

## Confirmed interruption recovery

Recovery means reconciling an interrupted review workflow after a crash, timeout, forced termination, or machine restart. It does not recover or mutate the reviewed code.

```text
reserved, not invoked, controller dead  -> publish release; allowance is reusable
invoked, no terminal, reviewer dead     -> publish abandoned terminal; allowance stays spent
terminal, claim still held              -> publish matching claim release
partial result present                  -> validate usable findings as advisory evidence
complete result, validation missing     -> resume validation
validation, classification missing      -> resume classification
classification, selection missing       -> derive/publish campaign selection
```

- Every invoked run publishes one immutable terminal `result.json`, including controller-generated results for timeout and other post-invocation failures. Its completion and runtime-outcome fields distinguish a complete reviewer result from an incomplete controller result containing recovered partial findings.
- A parseable bounded partial candidate is preserved through that terminal result and linked to its interrupted run.
- Individually valid partial findings remain visible to the implementer as advisory evidence with their original identity and severity.
- A partial result never supplies an authoritative campaign verdict and never approves or rejects the reviewed snapshot as a complete review.
- The controller schedules a separate complete review run. It reserves another already-authorized allowance slot automatically when one is available; otherwise it reports that another human allowance grant is required.
- The interrupted invocation remains spent because reviewer time and tokens were consumed. The rerun receives a new `run_id`.
- Finding lineage links matching findings across partial and later complete results so they are not presented as unrelated duplicates.
- Recovery publications use atomic `CreateNew`. An already-present identical fact is idempotent success; a conflicting fact is repository corruption and fails closed. Facts are never silently overwritten or deleted.

## Confirmed schema and retention policy

- Every JSON fact carries a fixed `schema_version`.
- The new review store starts separately from legacy review state. In-flight legacy authority is not automatically migrated; legacy evidence remains read-only and a new campaign is started or explicitly reconciled.
- Readers may support known additive versions, and small explicit migrators may be added when justified. An unsupported or schema-invalid authoritative fact fails closed.
- Compact campaign, allowance, claim, run, result, validation, classification, selection, and finding-lineage facts are retained for the campaign and feature lifecycle.
- Disposable worktrees, temporary files, and uncaptured raw reviewer output are removed promptly after the bounded evidence has been captured.
- Beta2 introduces no automatic pruning or compaction subsystem. Later explicit cleanup may remove only records proven unnecessary for allowance accounting, audit, result applicability, or re-review lineage.

## Rejected storage options

- SQLite: transactions do not justify the added native dependency, packaging, migration, and cross-platform burden for this volume.
- Append-only event log: replay, projections, compaction, and recovery complexity exceed current needs.

## Human agreement

The maintainer confirmed the JSON storage model, immutable coordination generations, bounded recovery behavior, reuse of validated partial findings as advisory evidence, mandatory separate complete reruns, schema handling, and conservative retention policy before this lens was closed.
