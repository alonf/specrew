# Workshop Record: requirements-nfr (light)

**Feature**: 198-beta2-hardening
**Date**: 2026-07-09
**Confirmation**: human-confirmed ("Yes" + human addition: agent-action
transparency/UX as a design-driving attribute)

## Quality-attribute priorities (agreed)

```text
  #   attribute              binding requirement shape
  ─   ────────────────────   ──────────────────────────────────────────────
  1   honesty / no-false-    every bypass, pass, or label is EARNED by a
      green                  deterministic check or recorded provenance
                             (W13 subset check · W8 machine-observed
                              evidence · W15 independence_source · #2906
                              verdict history)
  2   agent-action           ANY decision or action the agent makes is
      transparency (UX)      legible to the human: what was done/decided,
      [HUMAN ADDITION]       why, and what's next — loud failure is the
                             failure-side instance; teach-don't-trap is the
                             recovery-side instance
  3   loud failure           no silent degradation — refuse, warn, or mark;
                             never swallow (ratchet refusal · containment-
                             violated · W14 downgrade warning · ceiling halt)
  4   host neutrality        teeth live in scripts + data seams; host hooks
                             are surfacing only (A2 covering set)
  5   recoverability /       every enforcement stop TEACHES the sanctioned
      teach-don't-trap       next step (S3 texts · #2906 reconciliation ·
                             W16 timeout records)
  6   evidence > presence    claims verified against runtime evidence, never
                             file existence (repo doctrine)
```

Implication pinned by #2: LEGITIMATE paths are visible too, not just
failures — the W13 bypass announces "tracker-only reconcile, evidence kept
fresh" (a silent bypass violates #2 even though correct); the ratchet refusal
names the skipped boundary and both reconciliation doors; UpdateHealer prints
what it removed and what it left with a WARN; the W5b bootstrap commit
announces itself; the W15 independence label shows its provenance on the
status surface.

## The paired-test rule (agreed — binding acceptance shape)

Every honesty invariant ships as a PAIRED test: one proving the legitimate
path works, one proving the abuse path fails. Message-content assertions for
the transparency attribute ride the same pairs.

- W13: reconcile-toward-truth does not stale + falsify-forward stales.
- W8: observed run records what Pester actually returned + caller-supplied
  numbers are rejected/labeled.
- W12: fix-responsive round does not burn the ceiling + true no-movement
  round does.
- W5: each strip exclusion + its reviewer-can-still-see-it test.
- #2906: delta>1 refuses + retro-approval advances + revert only after
  human confirm.
- W4: origin access marks containment-violated + in-worktree work never
  does (false-kill guard).
- 205: unannotated self-fact reds the lint + the anything-but-Specrew
  fixture renders zero hits.
