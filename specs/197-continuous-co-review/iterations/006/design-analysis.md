# Design Analysis: Iteration 006 (the payoff — real reviewer + full-findings reporting)

**Feature**: 197-continuous-co-review
**Iteration**: 006
**Date**: 2026-06-24
**Base**: Iteration 005 close (the async navigator on the general isolated-task launcher)

## The challenge

Iteration 005 delivered the async navigator end-to-end EXCEPT the reviewer itself: the navigator fires
`Build-ContinuousCoReviewNavigatorReviewerCommand`, which today returns a verdict-emitting STUB that
always passes with no findings. Iteration 006 replaces that stub with the REAL policy-driven reviewer
and surfaces its COMPLETE findings durably. The whole iteration is WIRING existing Phase A
infrastructure into the iteration-005 seam — not building reviewer machinery.

Two constraints shape every decision:

1. **The ~20s Stop budget vs. the ~300s reviewer.** The navigator exists precisely because a real host
   review (iteration 002 proved ~300s for codex) cannot run inside the synchronous Stop-hook budget
   (#2885). So the long host call must stay on the detached supervisor path; only cheap, in-repo work
   runs at fire and reap.
2. **The materialized worktree has no `.git` and no real `.specrew/`.** The launcher materializes the
   reviewed tree via `git archive --output <tar>` + `tar -xf` into a `$TEMP` dir
   (`New-SpecrewIsolatedTaskWorktree`, isolated-task-launcher.ps1) — a plain content export, NOT a
   `git worktree`. So the detached reviewer running IN that worktree cannot compute a git diff against
   a baseline, cannot resolve the real-repo merge-base, and cannot write the real `.specrew/review/`.
   Anything that needs git or the real repo root must run in-repo (at fire or reap), not detached.

## F-184 footprint

NONE. Every edit lands in the non-protected `scripts/internal/continuous-co-review/` scripts plus
tests. The iteration-005 dispatcher edits (codex clean-args, stop-block merge) already landed; iteration
006 adds no new protected hook/dispatcher/registry/refocus/shared-governance edit.

## The reuse seam: the `specrew review --live` orchestrator is the blueprint

The Phase A `specrew review --live` path already chains the full pipeline synchronously, in-repo:
`Invoke-ContinuousCoReviewCheckpointReview` (checkpoint-review-orchestrator.ps1) does, in order, at
lines 109-171:

1. compute the checkpoint diff (`Get-ContinuousCoReviewCheckpointDiff`, against the real repo),
2. resolve the catalog and SELECT candidates
   (`Get-ContinuousCoReviewReviewerHostCatalog` -> `Select-ContinuousCoReviewReviewerCandidate`),
3. build the `ReviewRequest` (`New-ContinuousCoReviewRequest`),
4. EXECUTE the reviewer (`Invoke-ContinuousCoReviewReviewerExecution` — the host adapter call, with a
   mutation guard), which RETURNS a FindingsResult and persists NOTHING,
5. PERSIST: write the blackboard (`Write-ContinuousCoReviewBlackboardThread` ->
   `.specrew/review/inline/<run-id>/`), evaluate the gate, write the run index.

The decisive structural fact (primary-sourced): **`Invoke-ContinuousCoReviewReviewerExecution` does not
write to `.specrew/`** — it returns `{ kind, findings_result, provider_invocation, ... }`, and the
ORCHESTRATOR is what calls the blackboard writer afterward (orchestrator line 168). That makes the
execution engine a clean, relocatable unit: it can run detached (emit FindingsResult to stdout, persist
nothing), with persistence pulled back into the in-repo reap.

So iteration 006 does NOT run the whole orchestrator anywhere. It DECOMPOSES the orchestrator at its
three natural seams and places each seam where its resources live:

| Orchestrator seam | Resource it needs | Where it runs in the async split |
| ----------------- | ----------------- | -------------------------------- |
| select candidate | the catalog + install-probe + authorization gate (in-repo state) | FIRE (navigator, in-repo) |
| execute (host call) | only the long codex/claude process + the worktree to review | DETACHED reviewer `-Command` (the `$TEMP` worktree) |
| persist (blackboard / gate) | the real `$RepoRoot` + the parsed FindingsResult | REAP (navigator, in-repo) |

This is "Strategy A — decompose at the execution seam." The rejected alternative ("Strategy B — run the
whole orchestrator inside the detached `-Command`") fails constraint 2: the orchestrator's diff step and
its blackboard/index writes would target the worktree, which has no `.git` and no real `.specrew/`, so
the durable record would land in `$TEMP` and vanish. Strategy A keeps persistence in-repo where DS-002
(`.specrew/review/inline/...` is the system of record) is actually satisfiable.

## T082 — wire the real reviewer

`Build-ContinuousCoReviewNavigatorReviewerCommand` stops returning the stub and instead emits a real
reviewer `-Command`. The wiring, hop by hop:

### At fire (in-repo, navigator)

- **Select the reviewer host.** Call `Select-ContinuousCoReviewReviewerCandidate` against the catalog
  (`Get-ContinuousCoReviewReviewerHostCatalog`) with `-CodeWriterHost <current host>`, which picks a
  code-writer-INDEPENDENT host (claude->codex, codex->claude) and respects `installed` + `allowed` +
  the authorization gate. This MUST run in-repo: the install-probe (`Get-Command`) and the
  authorization state are repo/host facts, not worktree facts. The selected `{host, model, adapter_id}`
  is threaded into the fired `-Command`. If no authorized independent candidate exists, the navigator
  fails open to a no-op (no reviewer to fire) — never the stub.
- **Build the detached `-Command`.** The command embeds the Specrew MODULE BASE resolved at build time
  (the worktree does not contain Specrew's scripts), dot-sources `_load.ps1` from it to bring in the
  execution engine + adapters + contracts, then runs the reviewer.

### In the detached reviewer (the `$TEMP` worktree)

- **Build the diff/request.** The recommended split builds the change-set in the detached command via
  read-only git object access against the real repo (`git --git-dir=<real-repo>/.git diff <baseline>
  <tree-id>` — object reads are safe under concurrent edits), so the fire hop stays cheap. (The
  alternative — building the full request bundle at fire and passing it in — is viable but fattens the
  hot Stop path; recorded as a sub-decision below, not blocking.)
- **Execute.** Call `Invoke-ContinuousCoReviewReviewerExecution -Candidates @($selected) ...`. The
  primary read-only guarantee is the worktree itself: a throwaway `git archive` export OUTSIDE the repo
  with no `.git`, so the reviewer physically cannot reach the real repo or `.specrew/` — nothing to
  mutate. The execution engine's mutation guard (`$guardRepoRoot`, defaulting to the SPECREW repo root,
  overridable via `-ReadOnlyRoot`, reviewer-execution-engine.ps1:352) is the SECONDARY belt-and-
  suspenders that matters on the synchronous in-repo path. **Its scoping on the detached-worktree path
  is a T082 decision to settle empirically, NOT a settled control** — primary-sourced from the guard
  body (`workspace-mutation-guard.ps1`): the guard hashes fixed Specrew-OWN roots
  (`scripts/internal/continuous-co-review`, `tests/continuous-co-review`, `specs/197-continuous-co-review`,
  `.specrew`) and reads `git status`. Those roots do NOT exist inside the reviewed-project worktree and
  the worktree has no `.git`, so pointing `-ReadOnlyRoot` at the worktree makes the guard INERT (empty
  inventories + empty git-status on both sides — it never trips, but it also protects nothing); leaving
  it at the SPECREW repo root would, conversely, watch the live Specrew repo and could false-trip on a
  concurrent human edit during the ~300s review. So the right call is most likely to SKIP the in-repo
  mutation guard on the isolated-worktree path (the read-only export is the guarantee) rather than
  re-aim it — T082 confirms this against the guard body and condition-b STOPs if it cannot. This is
  exactly the green-but-inert class the maintainer is sensitive to, so it is named as a risk here, not
  asserted as done.
- **Emit.** The engine returns a FindingsResult.v1 (or an infrastructure-failure). The `-Command` writes
  that FindingsResult JSON to stdout, which the supervisor's stdio redirect captures to `result.out` —
  the exact channel the reaper already parses (`ConvertFrom-ContinuousCoReviewNavigatorVerdict` accepts
  FindingsResult.v1, navigator.ps1:178-248). Persist nothing in the worktree.

### Timeout

The navigator's `TimeoutSec` default is 120 (continuous-co-review-navigator.ps1:610). Iteration 002's
live codex full-iteration review needed ~300s (a 120s rerun timed out and was not counted). T082 raises
the co-review timeout config so a real reviewer run can complete before the supervisor kills it;
otherwise the reap sees `timed-out`, parses no verdict, and surfaces "ended without a verdict" — the
findings never land. The raised timeout is a config scalar (mirroring `co_review_gate_enforcement`),
with the E2E (T085) exercising it.

### Why T082 carries the iteration's risk

This is NOT a one-line stub swap. Three resolution hazards make it iteration-002-class repair territory
(the first live end-to-end run is where surprises live):

1. **Module-base resolution** — the detached pwsh runs with cwd = the worktree (no Specrew scripts); the
   `-Command` must locate and dot-source Specrew's module base correctly across hosts/platforms.
2. **Candidate threading** — the selected host/model/adapter must reach the execution engine intact
   through the job JSON (the launcher passes `-Command` as a string via the job spec, not
   `-ArgumentList`, to dodge cross-platform quoting — isolated-task-launcher.ps1:240-260).
3. **The live host adapter** — codex `exec --sandbox read-only --output-last-message` behavior, the
   Windows `codex.ps1` shim resolution via `-File` argv, and FindingsResult.v1 normalization were ALL
   sources of real repair in iteration 002 (review.md B-197-I002-001). They are reused, but the first
   run through the DETACHED path (not the synchronous `specrew review --live` path) is unproven.

## T083 — route the full findings to the durable blackboard

The reap done-branch (Invoke-ContinuousCoReviewNavigatorReap, navigator.ps1:311-348) already parses the
verdict and sets `$verdict.raw` to the full parsed FindingsResult. T083 adds, in that branch, BEFORE
`Clear-ContinuousCoReviewNavigatorEntry`:

- call `Write-ContinuousCoReviewBlackboardThread -RepoRoot $RepoRoot -CheckpointId "nav-<run-id>"
  -FindingsResult <normalized $verdict.raw>` (review-blackboard-writer.ps1:249). The writer lands
  `findings-result.json` + `review-thread.json` (+ a redacted-evidence record) at
  `.specrew/review/inline/<run-id>/` (writer:287-305).
- **run_id normalization** — the blackboard writer keys its directory off `FindingsResult.run_id`
  (writer:287), and the iteration-005 PASS-promotion writes the gate record at
  `inline/<registry-run-id>/review-run.json` (navigator.ps1:476). To co-locate findings WITH the gate
  record under ONE `inline/<run-id>/`, normalize `FindingsResult.run_id` to the registry run-id before
  the write. (The reviewer cannot stamp the registry run-id itself — the launcher mints it AFTER the
  `-Command` is built — so the in-repo reap is the right place to normalize.)
- **all severities** — the blackboard records every finding (the writer iterates `findings[]`
  regardless of severity), so advisory and nit findings persist alongside blocking. This is the whole
  point: the stub lost nothing because it had no findings; a real reviewer's advisory findings must not
  be dropped.
- **exclude the stub** — keep the iteration-005 `is_stub` guard (navigator.ps1:230-234, 321-326): a
  stub has no real findings and must never produce a durable record (and never promotes to gate
  evidence).
- **fail-open** — wrap the write so a malformed/absent FindingsResult degrades to the existing one-line
  summary note; the navigator must NEVER throw to the dispatcher (the iteration-005 fail-open contract,
  navigator.ps1:625-629).

### Why this is the SMALL fix (the proven separation)

The reap's `Clear-ContinuousCoReviewNavigatorEntry` does `Remove-Item $runDir` where `$runDir` is
`Get-ContinuousCoReviewNavigatorRunDir` = `.specrew/review/pending/<RunId>/`
(navigator.ps1:63-69, 254-260). The blackboard is `.specrew/review/inline/<run-id>/` — a SEPARATE
durable dir, already gitignored-exempt and tracked (the gate reads it). So the reap deletes only the
`pending/` signaling scratch; the `inline/` findings record it never touches. There is NO reap-ordering
change to make — the "stop deleting it on reap" framing from the closeout note is superseded by this
proven fact (folded in, not re-litigated). Routing the findings to the already-separate `inline/` dir
is the entire fix.

## T084 — surface the blackboard at the inject note

Today the reap surfaces only a summary: a one-line `[co-review] checkpoint review PASSED (run N):
<N finding(s): first comment>` for a pass (navigator.ps1:329), and only blocking-severity findings in
the STOP-BLOCK directive (`Build-ContinuousCoReviewNavigatorStopBlock`, navigator.ps1:510-530). T084
points the inject note (and the STOP-BLOCK body) at the durable blackboard thread T083 just wrote, so
the developer sees ALL findings:

- on a completed real review, the inject note references the blackboard thread path
  (`.specrew/review/inline/<run-id>/review-thread.json` + `findings-result.json`) and summarizes the
  full finding set (count by severity), not just the first comment.
- the blocking STOP-BLOCK directive likewise points at the thread for the complete finding list while
  still naming the blocking findings inline (so the agent can act without opening a file).
- the stub path and the no-parseable-verdict path keep the existing summary note (no thread exists).

T084 and T083 are COUPLED (both edit the reap done-branch) and ship as one semantic commit.

## The live-dispatcher E2E plan (T085)

The acceptance evidence must apply the green-but-inert lesson: a DIRECT function call is blind to
live-wiring gaps (exactly the iteration-005 catalog-drift trap, where fixtures stayed green while the
navigator was inert on live dispatch because the `refocus-scopes.json` row was missing from the
first-loaded copy). So the E2E fires through the LIVE DISPATCHER on a real host:

1. **Drive a real Stop on a real host** so the F-185 dispatcher invokes the `co-review-navigator`
   provider for real (not `Invoke-ContinuousCoReviewNavigator` called directly). Reviewer host: codex
   (live-validated iteration 002), selected via `Select-...ReviewerCandidate` as the code-writer-
   independent host — confirm codex is installed and working (`codex exec` reachable), and use the
   raised ~300s timeout.
2. **Stage a real multi-severity result** — the reviewed increment must contain something a real
   reviewer flags at MULTIPLE severities (at least one blocking + at least one advisory/nit), so the
   "all severities land" claim is actually exercised, not asserted on a no-findings pass. (Iteration
   002's full-iteration codex review produced a `findings`/`blocked` result with multiple findings —
   the same staging works here.)
3. **Prove durability** — after the reap, assert `.specrew/review/inline/<run-id>/findings-result.json`
   and `review-thread.json` exist and carry ALL the findings (every severity), run_id co-located with
   the gate record.
4. **Prove surfacing** — assert the reap inject note / STOP-BLOCK points at the blackboard thread and
   conveys the full finding set, so the developer sees all findings, not just the first.
5. **Prove host-neutrality stayed intact** — the selection went through `Select-...ReviewerCandidate`
   with no host-name literal in the navigator; codex is only the concrete host under test.

This E2E is the iteration's honest proof that the payoff actually reaches the developer on a real host
through the real dispatcher, not just through a unit harness.

## Security note (the trust boundary)

The reviewer is a TRUSTED in-boundary component: it runs a real host (codex/claude) with repo read
access and the inherited environment, in an isolated read-only worktree. The PRIMARY control is the
worktree itself — a throwaway `git archive` export OUTSIDE the repo with no `.git`/`.specrew/`, so the
reviewer cannot mutate real state. Reused controls: the host runs in its native read-only mode (codex
`--sandbox read-only`); and the blackboard's redacted-evidence record persists the findings and the
thread but explicitly marks `raw_provider_transcripts`, `raw_prompts`, and
`secret_or_environment_capture` as not-stored (review-blackboard-writer.ps1:192-218), so surfacing the
full findings does not surface raw transcripts or environment capture. The execution-engine mutation
guard is a secondary in-repo control whose scoping on the detached-worktree path is a T082 decision (see
the Execute bullet above) — most likely SKIPPED on this path since the read-only export is the
guarantee — not asserted here as a settled worktree-scoped control. The hardening-gate carries the
feature-specific Expected Controls for this boundary.

## Sub-decisions (recorded, not blocking)

- **Where the diff/request is built** — in the detached reviewer via read-only `git --git-dir` object
  access (keeps the fire hop light; recommended) vs. building the full request bundle at fire and
  passing it into the `-Command` (heavier hot path, but a thinner embedded command that is easier to
  test). Discriminator: the ~20s fire budget vs. the testability of a fat embedded `-Command`. Lean to
  the lighter hot path; either satisfies the contract.
- **Timeout config name/default** — raise the existing co-review timeout scalar (mirror
  `co_review_gate_enforcement`) to a safe default that clears a real codex run (>=300s), configurable
  per project; do not hard-code 300.

## T086 — the persisted human-authorization seam (the iter-002-class gap the live e2e found)

The live-NOT-mocked e2e setup uncovered that T082's "real reviewer" cannot select a host in production:
the default catalog ships every host `allowed=$false` (`reviewer-host-catalog.ps1:66`),
`New-...ReviewerPlan` calls `Get-...ReviewerHostCatalog` with NO configuration, and nothing persists a
runtime authorization — so `Select-...ReviewerCandidate` returns `$null` and the navigator FAILS OPEN to
no review. T082's deterministic tests (and the 145 accept) MOCKED the selection, so the gap was invisible.
This is the honest completion of T082.

**Design (Option A — maintainer ruling 2026-06-24; REJECT the `a8647528` implementation-rules preference,
which is a design recommendation, not a human runtime authorization):**

- **Provenance: a HUMAN authorizes once via the EXISTING path.** `specrew review --host <h>
  --authorization-ref <ref>` already builds a catalog config with `allowed=$true` + `authorization_ref`
  for the named host (`specrew-review.ps1:302-325`). T086 PERSISTS that built config to
  `.specrew/reviewer-hosts.json` (the catalog shape). The `authorization_ref` is the provenance anchor —
  it records that a HUMAN authorized this host. No agent silently self-authorizes (the Proposal 190 hole):
  the persist happens ONLY on the human's `--authorization-ref` invocation, and the navigator is read-only.
- **The navigator LOADS it read-only.** `New-...ReviewerPlan` reads `.specrew/reviewer-hosts.json` (if
  present + parseable) and passes it to `Get-...ReviewerHostCatalog -Configuration`; an authorized codex is
  then eligible and the policy picks it (independent of the code-writer). Absent / unreadable / no
  authorized host -> the default catalog -> `$null` candidate -> FAIL-OPEN (never a stub). The navigator
  NEVER writes the file.
- **Mandatory non-mocked test (condition d):** a REAL `.specrew/reviewer-hosts.json` (codex `allowed=$true`
  + `authorization_ref`) drives an UN-MOCKED `Select-...ReviewerCandidate` to pick codex; an
  empty/unauthorized config fails open. The test that proves selection does NOT mock selection.
- **Trace:** completes FR-026/030/031 (the navigator now actually fires a real, human-authorized,
  code-writer-independent reviewer). 5 SP; capacity 14 -> 19/20 (in-cap).
