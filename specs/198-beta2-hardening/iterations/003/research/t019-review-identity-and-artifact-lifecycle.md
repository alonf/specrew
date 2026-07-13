# T019 — Review identity, lineage, evidence, and artifact lifecycle (characterization + contracts)

**Status**: characterization/contract slice (T019 steps 1–5), authored 2026-07-13 at the maintainer's
direction: *"Start T019 with characterization and contract work before changing runtime behavior … then
implement against those contracts."* This document + the pure contract functions + the fixtures are the
executable specification. **No shipped runtime path is changed by this slice.** Step 6 ("implement against
those contracts" — wire the navigator / Stop path / orchestrator / retention) is a SEPARATE later slice.

**Owns (this slice)**: `scripts/internal/continuous-co-review/review-identity-contracts.ps1` (PURE, UNWIRED —
deliberately not in `_load.ps1`); `tests/continuous-co-review/unit/t019-identity-contracts.Tests.ps1`;
`tests/continuous-co-review/fixtures/t019/*.json`; this doc; the data-model entities below.

**Requirements**: FR-016 (last-reviewed checkpoint baseline), FR-017 (frozen digest threading + stamp into
EVERY run-record surface + navigator digest-match-before-blocking + in-flight dedup), FR-045 (Stop-ordering),
DRIFT-198-I003-002 (digest-A evidence not injected into a digest-B review) + the retention/cleanup ownership
carried here 2026-07-13.

**Correction pass (maintainer needs-rework review, 2026-07-13)** — the first cut would have encoded stale-authority
and cleanup defects; the contracts below are corrected: (1) `baseline_tree_id` (the auto-fire diff baseline = the
last ACCEPTED reviewed TREE) is SEPARATE from commit ancestry (git ancestry keeps using `reviewed_ref`/`baseline_ref`
commit refs); (2) digest-mismatch precedence is ABSOLUTE across every review outcome — a stale result never blocks,
requests a decision, or authorizes a packet; (3) finding→run joins FAIL CLOSED (`source_run_id` must equal `run_id`,
and the reviewed tree + `baseline_tree_id` must be present); (4) a transient artifact is prunable ONLY after its
owning run is terminal/reaped/abandoned; (5) a deterministic, persisted lineage id + a monotonic authority rule for
same-digest concurrent completions (max `run_id`); (6) injection validates the envelope digest AND every embedded
suite/run digest. The pure contract functions + fixtures reflect these (18/18 green).

---

## Part A — Identity contracts (step 1)

Five identities. For each: **Current** (shipped mechanism, with `file:line`), the **Gap**, and the **Target**
the runtime must satisfy once wired. Field names are the actual on-disk JSON keys.

### A1. Baseline

- **Current — TWO distinct baselines, not conflated:**
  - *Reviewer diff baseline* (what the change-set is computed against): `Resolve-ContinuousCoReviewWorktreeBaseline`
    (`worktree-review-orchestrator.ps1:28`) = `git merge-base HEAD <trunk>`; **fallback = empty tree
    `4b825dc6…`**. Persisted as `baseline_ref` on `status.json` / `review-run.json`.
  - *Last-REVIEWED checkpoint identity* (FR-016/FR-027 incremental anchor): `Get-ContinuousCoReviewLastPassingReviewState`
    (`review-run-index-writer.ps1:623`) → the newest `pass|escalated` run's `reviewed_ref`, git-ancestor filtered.
- **Gap**: FR-016 says the last-reviewed identity is *threaded as the next auto-fire's baseline*, but it is only
  **computed for the gate** (freshness/coverage) — it is **NOT** threaded back into the reviewer's `-BaselineRef`,
  which still uses merge-base-with-trunk.
- **Target (corrected)**: the auto-fire DIFF baseline is a **`baseline_tree_id`** — the last **ACCEPTED** reviewed
  TREE (a tree-id / digest), resolved by `Resolve-ContinuousCoReviewAutoFireBaselineTreeId` (last-accepted = max
  `run_id`); when no accepted run exists it is null and the runtime falls back to the merge-base anchor (a commit
  ref). This is **separate** from **git ancestry**, which continues to use commit refs (`reviewed_ref`/`baseline_ref`)
  for the lineage chain walk. The signoff `--live` merge-base doctrine is unchanged (FR-016). Do NOT conflate the
  tree the auto-fire diffs from (a tree-id) with the commit refs used for ancestry.

### A2. Reviewed digest

- **Current**: `Get-ContinuousCoReviewReviewedStateDigest` (`reviewed-state-digest.ps1:170`) — content-addressed
  tree-id over tracked + force-added gitignored **source**, minus the inclusion denylist and the machinery strip
  (`Get-ContinuousCoReviewMachineryPaths`, the single source shared with the worktree strip). Result keys:
  `ok, tree_id, is_empty, failure_reason`. Stamped as `reviewed_digest_tree_id` (`test-evidence-recorder.ps1:70`;
  `status.json` `orchestrator:722`), `reviewed_tree_id` (durable run record `review-run-index-writer.ps1:175`),
  `tree_id` (pending registry `co-review-service.ps1:108`), `last_fired_tree_id` (navigator dedup state `:239`).
- **Gap**: **three different key spellings** for one concept (`reviewed_digest_tree_id`, `reviewed_tree_id`,
  `tree_id`) split across surfaces, and the findings surface carries none of them at schema level (see A5).
- **Target (FR-017)**: the fire-time checkpoint tree id passes through the detached chain, the child materializes
  exactly that frozen tree, and the reviewed tree id is stamped into **EVERY** run-record surface — including the
  findings result — under one resolvable identity.

### A3. Evidence digest

- **Current**: recorded evidence is keyed by the reviewed digest at `.specrew/review/test-evidence/<treeId>.json`,
  each record carrying `reviewed_digest_tree_id`. Digest-matched lookup `Get-ContinuousCoReviewTestEvidenceForDigest`
  (`test-evidence-recorder.ps1:100`) returns a record **only** on **exact string equality** of the tree-id
  (`:112`). Injection `Copy-ContinuousCoReviewImplementerEvidence` (`:120`) writes `.review/implementer-evidence.json`
  and returns true **only** on a digest match (`"never wrong evidence"`), called `orchestrator:739`.
- **Gap**: the lookup requires a non-empty **`suites`** array (`:112–114`), so the T018 recorded-run **`runs`**
  records are invisible to it; and the exact-match rule handles full mismatch but has no explicit **partial-subset**
  outcome — the DRIFT-002 recurring "saw only a subset" case.
- **Target (DRIFT-198-I003-002, corrected)**: injection validates the **envelope digest AND every embedded
  suite/run digest** (`Test-ContinuousCoReviewEvidenceInjectable -EnvelopeDigest -ReviewDigest -EmbeddedDigests`).
  Injectable ONLY when the envelope AND every embedded `runs[].reviewed_digest_tree_id` equal the reviewed digest;
  an envelope that matches but embeds a foreign digest is `embedded-digest-mismatch-surfaced`; a full or subset
  digest-B injection is a named mismatch, never presented as clean and never as proof the A-runs did not occur;
  empty digests fail closed. Lookup must recognize both `suites` and `runs` records.

### A4. Run lineage

- **Current**: run-id = `yyyyMMddTHHmmssfff-<8hex>` (`isolated-task-launcher.ps1:84`, sortable + unique). A lineage
  chain is encoded on `review-run.json` as `baseline_ref` + `reviewed_ref` and walked by the gate
  (`Get-ContinuousCoReviewChainReachesAnchor` `review-signoff-evidence-gate.ps1:142`). **No lock/mutex.** In-flight
  state = the pending registry `.specrew/review/pending/<run-id>.json` (`status`: `running → done|timed-out|failed|
  reaped|crashed`). Dedup = `last_fired_tree_id` in `.specrew/runtime/co-review-navigator-state.json`
  (`navigator:239`; fire only when the current digest differs, `worktree-navigator.ps1:44`). The reap supersedes an
  un-reaped prior — there is **no pre-fire lock**.
- **Gap**: dedup is by **last-fired DIGEST**, not by an in-flight **lineage** — two drivers (manual `--live` +
  Stop-hook navigator) firing seconds apart on the same lineage are not serialized (the recorded collision, see
  `stop-ordering-defect.md`). "Single tracked in-flight review" (FR-045) has no representation.
- **Target (FR-017, corrected)**: a **deterministic, persisted lineage id** (`Get-ContinuousCoReviewLineageId` over
  the STABLE anchor commit + target, so every run in a lineage computes the same id — the advancing `baseline_tree_id`
  cannot key it); at most one tracked in-flight review **per lineage** (waits/polls, never a duplicate); an obsolete
  out-of-order completion (digest ≠ current) is superseded; and for **same-digest concurrent completions**, a
  **monotonic authority rule** (`Resolve-ContinuousCoReviewSameDigestAuthority` = max `run_id`) makes EXACTLY ONE
  authoritative and supersedes the rest. Lineage is NOT keyed by the per-fire `checkpoint_id` (`nav-<run_id>`).

### A5. Per-finding identity

- **Current**: local `finding_id` (`f1`, `f2`, …, reviewer-produced) + `source_run_id`, plus a content
  `fingerprint` = `sha256:` over `{location, severity, kind, design_reference, comment}` (`reviewer-contracts.ps1:938`).
  `findings-result.schema.json` (feature 197) is `additionalProperties:false` and has **no** `reviewed_tree_id` or
  `baseline`. A finding is bound to its run via `source_run_id`; the run is bound to tree+baseline via
  `review-run.json`.
- **Gap**: findings are not bound to tree/baseline at the finding level, so a MIXED run set (stale replay + valid
  current) cannot be separated per-finding. The navigator stamps `reviewed_tree_id` onto the persisted
  `findings-result.json` **out of schema** (`navigator:456`) by reading `$reg.reviewed_tree_id` (`:586`) — **a
  registry key the live worktree fire path never writes** (see Part D).
- **Target (FR-017 sharpening, corrected — FAIL CLOSED)**: `Get-ContinuousCoReviewFindingIdentity` binds
  `(finding_id, source_run_id)` to the reviewed tree AND `baseline_tree_id` of its run **only when the join is
  valid** — `source_run_id` MUST equal the run's `run_id`, and the reviewed tree + `baseline_tree_id` MUST both be
  present; any violation returns `valid=$false` with a reason (a cross-run smuggle or a missing identity is
  rejected, never silently bound). Only valid joins separate a mixed run set per-finding.

---

## Part B — Artifact lifecycle classes (step 2)

Five classes. **Base class** is path-static (the on-disk family); **disposition** is the state a durable record
moves through as digests advance. The archive-vs-prune *threshold* is a policy knob T019 owns — this slice defines
the classes and the decision inputs, not the window.

| Class | Meaning | Retention rule |
| --- | --- | --- |
| **transient** | machine-local / ephemeral; exists only for a run or cycle | prunable ONLY after the owning run is terminal/reaped/**abandoned** (never while it is running) |
| **durable** | current review evidence for the latest reviewed digest of its lineage | retained; tracked in git |
| **superseded** | a durable record no longer the latest for its lineage | retained until a policy decides archive vs prune |
| **archived** | a superseded record intentionally kept for forensics, moved out of the active set | retained long-term, out of the hot path |
| **prunable** | a transient record, or a superseded record past its retention window with no forensic value | safe to delete |

**On-disk family → base class** (shipped reality, from the `.gitignore` + writers):

| Path family | Base class | git-tracked | Supersedable | Writer / note |
| --- | --- | --- | --- | --- |
| `.specrew/review/inline/<run-id>/` (`findings-result`, `review-thread`, `redacted-evidence`, `review-run`, `gate-verdict`, `degraded-ack`…) | durable | yes (`.gitignore:31` "stays tracked") | yes | blackboard + run-index writers; **nothing prunes it** |
| `.specrew/review/test-evidence/<digest>.json` | durable | yes | yes | recorder; same suite/command REPLACES; **no cross-digest pruning** |
| `.specrew/review/signoff-gate/{latest.json,history/*}` | durable | yes | no | `latest` overwritten, `history/` append-only |
| `.specrew/review/pending/<run-id>{.json,/}` | transient | no (`.gitignore:32`) | n/a | launcher/service/supervisor; deleted by reap/stop |
| `.specrew/runtime/*` (navigator-state, round-state, escalation-latch, pending-verdict-stop.md) | transient | no (`.gitignore:30`) | n/a | rewritten each cycle |
| `.review/*` (in the disposable worktree) | transient | never (temp worktree) | n/a | discarded at run end |
| `.specrew/review/runs/` | — | — | — | **DEAD** — design comment only; no shipped gate reads it |

- **Gap**: durable families (`inline/`, `test-evidence/`) accumulate **unboundedly** — nothing supersedes, archives,
  or prunes them (the 35 `inline/*` + 17 `test-evidence/*.json` session residue). There is no representation of
  "superseded" on disk.
- **Target**: a durable record whose digest is no longer the latest for its lineage becomes `superseded`; T019
  policy decides when superseded records are `archived` (forensic value, e.g. the DRIFT-002 collision runs) vs
  `prunable`. **Retention runtime is step 6.** Until then the residue stays uncommitted and untouched (maintainer
  directive 2026-07-13): keep it, no blanket `.specrew/review/**` ignore, do not curate before the rules exist.

---

## Part C — Fixtures (steps 3–5) and the pure contracts

The fixtures encode the scenarios as data; the pure functions in `review-identity-contracts.ps1` encode the
decisions; `t019-identity-contracts.Tests.ps1` asserts the two agree (**18/18** green after the correction pass).

| Fixture | Proves | Contract function |
| --- | --- | --- |
| `drift-002-digest-a-vs-b.json` (step 3, corr. 6) | injection validates the envelope AND every embedded run digest; a foreign embedded digest, a full/subset digest-B injection, and an empty digest are all refused; only exact-digest is injectable | `Test-ContinuousCoReviewEvidenceInjectable` |
| `inflight-dedup-out-of-order.json` (step 4, corr. 1+5) | dedup (≤1 in-flight per lineage); out-of-order older completion superseded; deterministic lineage id; monotonic same-digest authority (max `run_id`); auto-fire baseline = last-accepted reviewed TREE | `Test-ContinuousCoReviewInFlightDuplicate`, `Test-ContinuousCoReviewResultSuperseded`, `Resolve-ContinuousCoReviewSameDigestAuthority`, `Get-ContinuousCoReviewLineageId`, `Resolve-ContinuousCoReviewAutoFireBaselineTreeId` |
| `fr045-stop-ordering-matrix.json` (step 5, corr. 2) | the 11-state Stop routing with ABSOLUTE digest-mismatch precedence (stale clean/actionable/human-judgment/infra all superseded); exactly one capturable + marker state; `launch_review` never true | `Resolve-ContinuousCoReviewStopRouting` |
| `finding-join-and-disposition.json` (corr. 3+4) | finding→run joins fail closed (mismatched `source_run_id`, missing tree/baseline); transient artifacts prunable only after the owning run is terminal/reaped/abandoned | `Get-ContinuousCoReviewFindingIdentity`, `Resolve-ContinuousCoReviewRecordDisposition` |

Artifact base classes (`Get-ContinuousCoReviewArtifactClass`) are exercised directly.

---

## Part D — Load-bearing gaps this characterization pins (for step 6)

1. **Registry key drift (the DRIFT-002 root).** The live worktree fire path writes `tree_id`
   (`co-review-service.ps1:108`) + `reviewed_digest_tree_id` (`worktree-review-detached-entry.ps1:52`) to the
   pending registry, but the T019a stale-verdict downgrade (`navigator:667`) and the blackboard finding-stamp
   (`:586`) both read **`reviewed_tree_id`** — a key that path never writes. So the digest-match-before-blocking is
   effectively **skipped** in the worktree engine (empty id ⇒ block kept), which is exactly why stale navigator
   blocks recur. Step 6 must resolve ONE reviewed-tree identity readable by promotion, stale-surfacing, and the
   finding stamp alike.
2. **No in-flight gate on the verdict-packet path.** `Sync-SpecrewPendingVerdictStopArtifact`
   (`sync-boundary-state.ps1:551`) is driven solely by pending-*verdict* boundary state; it never consults the
   co-review pending registry. The signoff gate reads durable `inline/` evidence, not in-flight state. So a
   running/pending review neither blocks nor delays the packet + `SPECREW-VERDICT-BOUNDARY` marker — the FR-045
   hole. Step 6 gates the packet on the Stop-routing contract (Part C).
3. **Evidence lookup is `suites`-only.** `Get-ContinuousCoReviewTestEvidenceForDigest` ignores the T018 `runs`
   records; step 6's injection must recognize both.
4. **Findings-result has no in-schema tree/baseline.** Either extend the findings surface or resolve identity at
   read time via `Get-ContinuousCoReviewFindingIdentity`; today it is stamped out-of-schema on an unvalidated path.

---

## Part E — Deferred to step 6 (NOT in this slice)

Wiring the contracts into the runtime: thread the last-reviewed baseline into the auto-fire; unify the reviewed-tree
identity key across writers + stamp it into the findings surface; add per-lineage in-flight dedup + out-of-order
supersession to the navigator; gate the verdict packet on the Stop-routing contract; recognize `runs` evidence in
the digest-matched injection; and implement the retention runtime (supersede → archive/prune) with the policy
window. Each lands with its own paired runtime tests. **Return to the maintainer after THIS slice before any of
that.**
