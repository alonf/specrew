# Review: Iteration 003 (Always-On Co-Review — Phase A, Sound Gate Re-Architecture)

**Feature**: 197-continuous-co-review
**Iteration**: 003
**Reviewed**: 2026-06-20
**Boundary**: review-signoff -> retro
**Overall Verdict**: accepted

## Scope reviewed

The complete Phase A always-on co-review slice, including the mid-iteration gate
RE-ARCHITECTURE: T058 (incremental baseline), T065-T069 (content-addressed digest,
lineage/anchor resolver, re-architected gate, producer auto-anchor, diff-hash retirement),
T059/T060 (gate-review dispatcher + wiring), T062 (one-time auth + escalation), T063
(spawn-orphan regression), T064 (closeout validation). 24.00/25 SP.

## The arc (the dogfood loop worked — repeatedly)

1. The first Phase-A gate keyed signoff on a `diff_hash` recomputed from an operator-chosen
   baseline. The feature's OWN fresh-context co-reviews found it unsound: HOLE A (gitignored
   source invisible) and HOLE B (operator baseline never verified as reviewed).
2. Re-architected (maintainer-directed, within Iteration 003) to a **content-addressed
   reviewed-state tree-id** (includes tracked + untracked + gitignored source) **anchored to
   the merge-base with the trunk**, with producer auto-anchoring and a recorded override.
3. An adversarial re-review of the re-architected gate found a BLOCKING false-allow (F1: the
   denylist over-matched source named like a secret) — fixed.
4. A comprehensive 3-dimension Proposal 145 review found a second BLOCKING false-allow (the
   digest IDENTITY strip still excluded real source: `bin/**`, `*.key`/`*.token`/`*.pem`) plus
   a secret-handling finding (F-SEC-1) and governance gaps (B1/B2/B3, A1) — all addressed.
5. The confirming re-review (correctness + conformance) returned APPROVE on both.

This is exactly the shift-left value Proposal 197 exists to deliver: continuous co-review
caught its own gate model unsound — twice — before it could ship.

## Runtime evidence

- **Full `tests/continuous-co-review` suite: 176 passed, 0 failed.**
- **HOLE A blocks**: gitignored-source drift flips the tree-id and the gate returns
  `stale-co-review-evidence`; tracked source named like a secret / under `bin/` stays in the
  identity and its drift blocks (the F1 + correctness false-allow regressions).
- **HOLE B blocks**: a pass not chaining to the merge-base anchor returns `coverage-gap`; the
  multi-hop chain ALLOW + mid-gap are tested; the producer auto-anchors signoff runs.
- **Producer->gate loop** proven end to end (auto-anchor -> tree-id recorded -> allow ->
  drift blocks).
- **SC-023 zero-spawn**: unregistered stages (plan/tasks/spec/design-lens) and casual yields
  run no reviewer and write no evidence; a registered implement checkpoint runs the orchestrator.
- **Spawn robustness (NFR-001)**: a stalled large-stdin child is timed out and its process
  tree killed (no orphan).
- **Fail-closed** on every git/digest/anchor/lineage failure; no fail-open path.
- **SC-006**: protected-surface guard passes; the iteration's committed changes
  (`a8647528..HEAD`) touch only `scripts/internal/continuous-co-review/`, the 197-owned
  `scripts/specrew-review.ps1`, `specs/197-continuous-co-review/`, and `tests/` — **no F-184
  protected-surface edit**.

## Proposal 145 review (3 dimensions, all APPROVE after fixes)

- **Correctness**: false-allows closed (HOLE A, HOLE B, F1, the identity-strip); chain-walk
  sound; no new false-allow. APPROVE.
- **Conformance/traceability**: B1 (FR-025 reworded to the tree-id/anchor model), B2
  (SC-019/SC-020 honestly scoped to decision-logic with a recorded deferral authorization),
  B3 (task statuses + capacity reconciled), A1 (multi-hop tests). APPROVE.
- **Security**: spawn argv-safety, read-only posture, provider authorization, mutation guard
  all pass. F-SEC-1 (secret in the reviewer bundle/diff) was RELAXED by the maintainer's
  trust-boundary decision — the reviewer is a trusted in-boundary component that must read
  repo context and run tests with inherited env + repo access; recorded in the SEC-002
  amendment + Governance Alignment.

## Deferred (recorded, authorized)

- **Gate enforcement WIRING** into `Invoke-SpecrewBoundaryStateSync`: decision logic is
  delivered; the wired advancement block is deferred to coordinate with F-185 (authorized).
  SC-019/SC-020 are satisfied at the decision-logic level.
- **Phase B (Iteration 004)**: the live Stop-hook navigator across five harnesses (incl. the
  reviewer-runs-in-repo-for-tests execution model) and SC-022.
- **F3/F4 override + run-record trust**: binding obligations on the F-185 wiring PR
  (authenticate + persist the override; SEC-009 invalidation test for forged records).
- **SC-012 maintainer real-host validation**: after Phase B.

## Process notes (honest)

- A review sub-agent polluted the repo early (a stray commit + a local git-config change that
  mis-authored 16 commits as "probe"); detected, the stray commit reset, the config restored,
  and the 16 commits re-authored to the maintainer (history rewrite run by the maintainer).
  Lesson recorded for future review fan-outs.
- The multi-agent design/review workflow repeatedly hit stream-idle timeouts on heavy single
  agents; single `reviewer` Agents and inline empirical validation proved reliable and carried
  the design + review work.

## Claim-ledger honesty

- Proven by runtime evidence: the full suite (176/0), every HOLE-A/B/F1/identity false-allow
  blocking in running code, SC-023, the spawn regression, the producer->gate loop, the
  protected-surface diff.
- NOT claimed: wired advancement enforcement (deferred, decision-logic only); hard secret
  sandboxing (relaxed by trust-boundary decision); the live Stop-hook (Phase B).

## Task Verdicts

Reconstructed 2026-07-01 from git; each row is grounded in the iteration-003 commit(s) and
the per-task record in this iteration's `plan.md`. The iteration was formally closed by the
closeout commit `2ac079b2`.

| Task | Verdict | Evidence |
| ---- | ------- | -------- |
| T058 | pass | `bd6ebebc` (record `diff_hash`/`reviewed_ref` + last-passing-state resolver) and `27343ce5` (orchestrator rebaseline, FR-027); resolver/rebaseline/spine tests green. |
| (fix) | pass | `3230e9e1` bounds the reviewer-spawn stdin write and reaps the orphaned child (NFR-001/INT-004); adapter tests 4/4 incl. real-process shim. |
| T061 | pass | Original diff-from-baseline `diff_hash` gate-floor (`717c423f`, 8/8 unit) was INVALIDATED by the feature's own Proposal 145 co-review (HOLE A/B, `e8493b8a`) and SUPERSEDED by the T067 re-architecture (`c51cc44b`); the task objective (a sound freshness gate) was delivered via T067, so the verdict is `pass` = objective met via supersession, not a standalone deliverable. |
| T065 | pass | `cd475364` content-addressed reviewed-state digest helper (temp-index `write-tree`, gitignored-source-in / secret-out, empty-tree guard, FR-025/SEC-002) with determinism/gitignored/secret/drift/empty tests. |
| T066 | pass | `62128509` records `reviewed_tree_id` on the run record and replaces the scope filter with git lineage (`merge-base --is-ancestor`) + chain-to-anchor verification (FR-025/FR-027); tests green. |
| T067 | pass | `c51cc44b` re-architects the gate to tree-id-equality freshness + chain-to-merge-base-anchor + empty-tree guard + fail-closed git handling (supersedes T061); false-allow F1 closed in `36a7c7bf`; HOLE A/HOLE B falsifying tests block. |
| T068 | pass | `a140c8ec` producer auto-anchoring in the orchestrator + `specrew-review.ps1` (merge-base-with-trunk fallback, records the digest, flags exploratory runs non-signoff, configurable trunk, FR-025/FR-027); tests green. |
| T069 | pass | `5d47f773` retires the diff-hash freshness path as the gate key (diff_hash kept as provenance only, NEW-5 dead full-diff removed, change-set provider reconciled, FR-025/NFR-001); tests green. |
| T059 | pass | `2fa35d3c` gate-review dispatcher + gate-keyed registry with `code@implement` as sole registrant (FR-032/SC-023/IMPL-004); dispatcher unit + gate-dispatch integration suites green. |
| T060 | pass | `2fa35d3c` wires the dispatcher to the checkpoint-review orchestrator so a registered implement checkpoint reviews its increment and writes durable evidence (FR-024/INT-004). |
| T062 | pass | `ff529c29` one-time per-project navigator authorization + two-round-cap blocking-finding escalation (FR-028/FR-029/SC-021); onetime-authorization tests green. |
| T063 | pass | `ff529c29` delayed-stdin reviewer-spawn regression proving the timeout bounds a stalled large-stdin child with no orphan (NFR-001/INT-004); reviewer-spawn-timeout tests green. |
| T064 | pass | `53e45537` closeout validation (full CCR suite 173/0, HOLE A/B repros BLOCK, protected-surface guard shows no F-184 edits, traceability), with the comprehensive Proposal 145 review addressed in `4212e61e`; final suite 176/0 (Runtime evidence, above). |

## Gap Ledger

- HOLE A (gitignored source invisible to the `diff_hash` gate): fixed-now, re-architected to a content-addressed reviewed-state tree-id (`c51cc44b`); a falsifying gitignored-drift test blocks.
- HOLE B (operator baseline never verified as reviewed): fixed-now, chain-to-merge-base anchor verification (`62128509`/`c51cc44b`); a coverage-gap test blocks a non-chaining pass.
- F1 false-allow (secret denylist over-matched real source named like a secret): fixed-now (`36a7c7bf`); regression test blocks.
- Identity-strip false-allow (the digest identity excluded real `bin/**` / `*.key` / `*.token` / `*.pem` source): fixed-now, digest identity corrected (`cd475364` + fix); drift regression blocks.
- B1/B2/B3/A1 conformance/traceability gaps: fixed-now (FR-025 reworded to the tree-id/anchor model; SC-019/SC-020 honestly scoped with a recorded deferral authorization; task statuses + capacity reconciled; multi-hop anchor tests added).

## Recommended verdict

**Accept Iteration 003 for review-signoff -> retro.** Phase A delivers the sound,
adversarially-validated content-addressed + anchored gate, the producer, and the gate-keyed
dispatcher in 197-owned non-protected code, with both original false-allows and the
review-found false-allows closed in running code, all governance findings resolved, and the
deferrals explicitly authorized. Verdict names this exact boundary: **review-signoff -> retro**.
