# Lease lifecycle model (per-lineage review lease)

**Status**: SUPERSEDED — historical failed-design evidence only
**Superseded**: 2026-07-16 by the human-confirmed `ReviewCampaign` / `ReviewRun` architecture
**Replacement authority**: file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/005/design-analysis.md

This document describes the mutable process-owned lease that the final authorized review proved architecturally unsound. It MUST NOT guide new implementation, result promotion, or plan/task design. The replacement uses run-owned immutable claim generations only for active execution; durable terminal run/result facts govern later validation and applicability. It removes parent/supervisor handoff, self-adoption, mutable `pending_tree`, owner-token release, and lease-based terminal authority.

**Feature**: 198-beta2-hardening (T019 step 6 piece 2; hardened 2026-07-15)
**Module**: `scripts/internal/continuous-co-review/co-review-lineage-lease.ps1` (+ the service handoff in
`co-review-service.ps1` and the supervisor gate in `worktree-review-detached-entry.ps1`)
**Purpose**: the explicit state machine for the at-most-one-authoritative-reviewer-per-lineage invariant —
every state, transition, and failure mode, each mapped to the test that falsifies it. Written after four
review-discovered defects in this module (token wildcard, same-generation dead-owner suppression, reclaim
race, discarded owner handoff) demonstrated the design was under-modeled; this document is the model the
code is now reconciled against.

## Identity

A lease is ONE file per lineage (`.specrew/review/leases/<sha256(lineage)>.json`) carrying:
`lineage_id`, `generation` (the reviewed-tree digest under review), `run_id`, `owner_token` (a per-acquire
GUID — the ONLY mutation credential), `pid` + `process_start_id` (the owner PROCESS for liveness),
`pending_tree` (the queued newer generation, if any).

**The lease file is the authority.** A supervisor whose lease no longer exists (or no longer carries its
token) is NON-authoritative: its completion degrades to advisory in the navigator reap (the
`Test-ContinuousCoReviewLeasePromotionAuthority` four-condition gate). This is the safe-direction backstop
behind every race below: a lost/displaced lease can waste a reviewer, but can never mint a second
AUTHORITATIVE one.

## States

| State | On disk | Meaning |
|---|---|---|
| `UNHELD` | no lease file | lineage free; the next fire may acquire |
| `HELD(parent)` | lease file; pid = acquiring parent | acquired, supervisor not yet stamped |
| `HELD(supervisor)` | lease file; pid = supervisor | the running reviewer owns the lineage |
| `HELD+QUEUED` | either HELD state with `pending_tree` set | a newer tree waits behind a live owner |
| `ORPHANED` | lease file; owner process dead | crash residue; reclaimable |

## Transitions

| # | Transition | Mechanism | Failure handling |
|---|---|---|---|
| T1 | `UNHELD → HELD(parent)` | atomic `File.Open(CreateNew)` — single winner | loser inspects the incumbent (T2) |
| T2 | inspect incumbent | same-gen + LIVE → `duplicate-same-generation` (no-op); diff-gen + LIVE → queue `pending_tree` (T3); ANY-gen + DEAD → reclaim (T4) | owner liveness = PID **and** process-start identity (PID reuse is not ownership) |
| T3 | queue newer tree | `pending_tree` CAS'd onto the held lease (generation-expected write) | a stale expectation loses silently; the queued tree re-fires on the next checkpoint |
| T4 | `ORPHANED → UNHELD` (reclaim) | **claim-by-rename**: atomic `File.Move` of the exact lease path — single winner; the mover verifies the moved file's token: dead token → dispose; a DIFFERENT token (a concurrent replacement was displaced) → restore by move-back; restore collision → drop LOUDLY (the displaced owner degrades to advisory — never two authoritative) | the loser's `Move` throws and it re-enters the loop against fresh state |
| T5 | `HELD(parent) → HELD(supervisor)` (handoff) | token+generation-matched owner-process rewrite, POST-SPAWN, as a REQUIRED transaction | failure → stop the spawned supervisor, mark the registry failed, release the lease, throw — never `status=running` with an unprotected reviewer |
| T6 | supervisor SELF-ADOPTION (startup) | the detached entry adopts via the same token+generation-matched rewrite (idempotent with T5 — both stamp the supervisor PID) | adoption refused (lease reclaimed/replaced during the crash window) → the supervisor marks its registry failed and EXITS without reviewing |
| T7 | `HELD → UNHELD` (release) | owner-token + generation matched delete; returns `pending_tree` to the caller | non-owner/mismatch → refusal (no-op) |

## Crash matrix (who dies, what happens)

| Crash point | Residue | Recovery | Falsified by |
|---|---|---|---|
| parent dies before spawn | `HELD(parent)`, no supervisor | next fire: T2 dead → T4 reclaim | lease test 7 / 7b |
| parent dies between spawn and handoff | `HELD(parent, dead)` + LIVE supervisor | **T6 self-adoption** claims the lease for the live supervisor before any reclaim can double-spawn; if a racer reclaimed first, T6 refuses and the supervisor exits | lease tests 10a/10b |
| supervisor dies mid-review | `HELD(supervisor, dead)` | next fire: T4 reclaim (same OR different generation) | lease tests 7 / 7b |
| two fires race a dead lease | one `ORPHANED` file | T4 single-winner rename; the replacement lease survives the loser | lease test 7c (two-process barrier race) |
| handoff write fails/races | spawned supervisor, lease still parent-owned | T5 transaction: supervisor stopped, lease released, registry failed, loud throw | service handoff test |
| completion after supersession | none (lease moved on) | the four-condition promotion authority refuses (non-owner / stale generation / superseded) — advisory only | lease tests 5/5b/9 + navigator advisory tests |

## Invariants

1. **At most one AUTHORITATIVE reviewer per lineage** — enforced by the lease file's single-path atomicity
   (CreateNew, Move) plus the promotion-authority gate on completions.
2. **Ownership mutations require the owner token** — release, handoff, adoption, and promotion all
   token+generation-matched; an empty token is never a wildcard.
3. **Liveness gates every suppression** — `duplicate-same-generation` and `queued-newer-tree` apply only to
   LIVE owners; dead owners are always reclaimable regardless of generation.
4. **Displacement degrades, never duplicates** — every race resolution that can strand a party strands it
   toward ADVISORY (a wasted reviewer), never toward a second authoritative one.
5. **A supervisor that cannot prove ownership does not review** (T6).

## Known residual ceilings (documented, accepted)

- POSIX advisory locking is not used; atomicity rests on `CreateNew`/`File.Move` semantics, which hold on
  NTFS and POSIX rename within a directory.
- The T4 restore-collision drop strands a live supervisor as advisory (logged loudly). Frequency: requires a
  three-way race inside a millisecond-scale window; the safe direction is preserved.
- Process-start-identity liveness can mis-read across container/PID-namespace boundaries; reviewers and
  fires run in the same namespace by construction (the service spawns locally).
