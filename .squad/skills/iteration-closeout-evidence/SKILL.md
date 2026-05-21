---
name: "iteration-closeout-evidence"
description: "Review iteration closeout claims by confirming the proving artifacts are both contract-compliant and versioned"
domain: "review"
confidence: "high"
source: "earned"
tools:
  - name: "view"
    description: "Read the live closeout artifacts and contract language"
    when: "When checking whether plan, state, or spike artifacts satisfy the stated closeout requirement"
  - name: "powershell"
    description: "Inspect tracked status for the files being used as closure evidence"
    when: "When acceptance depends on whether the evidence is durable in git, not merely present in the worktree"
---

## Context
Use this when a closeout or acceptance note says work is complete because plan/state/spike artifacts now exist. Presence alone is not enough for reviewer acceptance if the evidence files are not versioned with the implementation they certify.

## Patterns
- Read the contract and the live artifact content first; reject empty or malformed proof even if the file is tracked.
- After content review, confirm the proving artifacts are actually tracked in git. Closure evidence must be durable.
- Treat scripts and their proving artifacts as one acceptance set: if the script is tracked but the state or spike proof is untracked, the closeout is still incomplete.
- Separate substantive correctness from persistence. It is possible for an artifact to be well-written and still fail acceptance because it is untracked.
- Generate historical dashboard snapshots only after plan/state truth surfaces have moved to the closeout boundary. Otherwise the artifact can freeze a stale live phase (for example `reviewing`) into what claims to be closeout evidence.
- On rejection, name the exact files that must be versioned and lock out the original closeout author for the next revision cycle.
- For narrow re-reviews, judge only the cited defect. If the exact evidence files named in the rejection are now tracked, close that defect directly instead of reopening already-cleared content questions.

## Examples
- `scripts\specrew-init.ps1` and the two deployment scripts were tracked, but `specs\001-specrew-product\iterations\001\state.md` and `specs\001-specrew-product\iterations\001\spikes.md` remained untracked. Verdict: NEEDS-WORK because the accepted-work evidence was not durable.
- A plan row may truthfully mark a task `done`, but if the spike deliverable cited by that row is still outside version control, the closeout record is incomplete.
- Re-reviewing the same closeout later, `git ls-files` returned both `state.md` and `spikes.md`, and `git status --short` showed them as tracked additions. Verdict: PASS on the prior rejection reason, because the durability defect was the only remaining acceptance gap in scope.

## Anti-Patterns
- Granting PASS because a file exists on disk without checking whether it is part of the repository history.
- Treating a decision memo as a substitute for tracked plan/state/spike artifacts.
- Softening a rejection because only “administrative” tracking work remains; auditability is part of the acceptance requirement.
