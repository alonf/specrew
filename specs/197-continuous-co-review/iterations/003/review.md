# Review: Iteration 003 (Always-On Per-Checkpoint Co-Review — Phase A)

**Feature**: 197-continuous-co-review
**Iteration**: 003
**Reviewed**: 2026-06-20
**Boundary**: review-signoff -> retro
**Overall Verdict**: Accepted as an honest PARTIAL / learning close (recommended; awaiting maintainer review-signoff verdict)

## What this review covers

Iteration 003 (Phase A) planned seven tasks (T058-T064): the 197-owned deterministic
gate floor plus the gate-keyed dispatcher, with the live Stop-hook trigger deferred to
a later phase. This review judges what was delivered against FR-024/FR-025/FR-027 and
the iteration goal, with runtime evidence, not effort.

## Honest task status (disk truth)

| Task | Planned | Status | Evidence |
| ---- | ------- | ------ | -------- |
| T058 | Incremental baseline + reviewed_ref/diff_hash on the run record; last-passing resolver | **Done, sound** | Commits `bd6ebebc`, `27343ce5`; review-run-index-writer 5/5, rebaseline 1/1, spine 4/4 |
| T061 | Deterministic gate-floor decision logic (FR-025) | **Done, but model invalidated by co-review** | Commit `717c423f` + fixes `e8493b8a`; 8/8 unit tests — BUT see "Co-review finding" |
| (bonus) | Reviewer-spawn timeout/orphan robustness fix | **Done, sound** | Commit `3230e9e1`; adapter tests 4/4 incl. real-process shim |
| T059 | Gate-review dispatcher + gate-keyed registry | **Not started** | Deferred to Iteration 004 |
| T060 | Wire dispatcher to the reviewer run path | **Not started** | Deferred to Iteration 004 |
| T062 | One-time authorization + blocking->escalation | **Not started** | Deferred to Iteration 004 |
| T063 | Delayed-stdin spawn regression test | **Not started** | Deferred to Iteration 004 |
| T064 | Phase A closeout validation | **Not started** | Superseded by this review + Iteration 004 |

**The iteration did NOT achieve its full planned goal.** It is closed as a partial /
learning iteration, not a full-scope completion. Claiming "complete" would be a hollow
closeout and is explicitly avoided here.

## Co-review finding (the headline — the dogfood loop worked)

The iteration's centerpiece, the FR-025 gate floor (T061), was subjected to two
fresh-context Proposal 145 co-reviews — the feature reviewing its own implementation.
The reviews found the gate model **unsound**, with defects that escalate from the
delivered code:

- **D-197-I003-003 (fixed):** seven findings on the first pass (untracked false-allow,
  missing scope, non-falsifying tests, etc.), all fixed in `e8493b8a` (suite 148/0).
- **Design-panel re-review (NEW, blocking, NOT fixed — drives Iteration 004):**
  - **HOLE A — gitignored-source blindness:** both gate probes (`git diff <baseline>`
    and `git status --untracked-files=all`) are blind to gitignored files; a project
    that gitignores a reviewable tree signs off on un-reviewed source. Live in
    `e8493b8a`.
  - **HOLE B — unanchored operator baseline:** the gate only proves the tree matches
    the diff from an OPERATOR-CHOSEN `--baseline-ref`; nothing verifies that baseline
    was itself reviewed, so a tip-only review can skip the middle. The "baseline
    advances only on a pass" invariant is vacuous in production because no caller
    threads `-RebaselineToLastPass`.

Neither hole is live-exploitable today (the gate is unwired — deferred post-185), so
these are activation-time correctness defects: the model is not sound enough to wire.
**This is the system working as designed** — continuous co-review caught its own gate
model unsound before it shipped, which is precisely the shift-left value F-197 exists
to deliver.

## Claim-ledger honesty

- Proven by runtime evidence: the spawn robustness fix (adapter tests + real-process
  shim), the T058 evidence substrate (resolver/rebaseline/spine tests), and the
  decision-logic-level behavior of the gate (8/8 unit tests).
- NOT claimed: that the gate delivers the FR-025 guarantee. It does not (HOLE A/B). The
  gate's SC-019/SC-020 are NOT demonstrated (the gate is unwired; trace tags were
  corrected to say so).
- Process integrity note: a stray commit (`probe`/`app.txt`) and untracked
  `newsrc.txt` + `.specrew/review/` evidence were found at the branch tip — pollution
  written by the adversarial reviewer sub-agents when asked to "run repros via the real
  command path." Cleaned (reset to `e8493b8a`). Lesson recorded: review agents given
  repro latitude can mutate the repo — the same read-only/mutation-guard concern
  (SEC-003) that F-197 itself enforces for its reviewer.

## Carry-forward to Iteration 004

- The sound, re-architected gate (anchored chain + content-addressed reviewed-state
  identity + the agreed hardening) — supersedes T061's model.
- T059 (dispatcher), T060 (run-wiring), T062 (auth/escalation), T063 (spawn regression
  test).
- The HOLE A gitignored-scope policy decision and the HOLE B baseline-anchoring
  constraint.

## Recommended verdict

**Accept Iteration 003 for review-signoff as an honest partial / learning close**: the
spawn robustness fix and the T058 evidence substrate are accepted durable value; the
T061 gate-floor is accepted as a superseded spike whose co-review invalidation is the
iteration's key learning; the remaining tasks and the gate re-architecture carry to
Iteration 004. Verdict names this exact boundary: **review-signoff -> retro**.
