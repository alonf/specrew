# Review-Signoff — F-174 iteration 011 (DF-3/4/5/7 boundary-authoring + verdict-integrity + FR-028 hook hardening)

**Schema**: v1
**Reviewed**: 2026-06-14
**Boundary**: implement → review-signoff (maintainer-authorized; the verdict to ADVANCE past review-signoff and
to CLOSE the iteration remains the maintainer's). **This artifact is the structured review the maintainer
required at review-signoff (instruction 3); it does NOT close the iteration.**
**Scope**: the full iteration-011 delta, git range `c5756473..HEAD` (~3,100 insertions / 37 files), covering
T001–T012 (FR-022 / FR-026 / FR-027 / FR-028; SC-012..018).
**Method**: a multi-agent Proposal-145 structured review — 7 parallel dimension reviewers (P1 branch hygiene,
P2 FR-022 authoring/capture/clobber, P3 FR-026/027 verdict integrity, P4 FR-028 hook install/discovery, P5 code
quality + PowerShell traps, P6 test integrity, P7 system safety + traceability) → dedup → adversarial
default-refute verification of every HIGH/MEDIUM finding. 10 agents; each reviewer ran the real code + tests,
not just read the diff.

## Result

**14 findings: 0 HIGH, 3 MEDIUM (all confirmed by adversarial verification), 6 LOW, 5 INFO.** No blocking
integrity break. The verdict-integrity core (FR-026/027), the mechanical capture/clobber (FR-022), and the hook
hardening (FR-028) are sound under direct probing; every SC-012..018 traces to code AND a green test. All 3
confirmed MEDIUMs + the cheap LOW/INFO improvements were **remediated in this review-signoff pass** with
regression tests; the remainder are carried with explicit dispositions. **Post-remediation: 50 test suites
green, 0 failed.**

## Coverage matrix (dimension × result)

| Dimension | Result |
| --- | --- |
| P1 branch hygiene / mirror parity / manifest | clean (1 LOW commit-prefix, 2 INFO) |
| P2 FR-022 authoring / capture / clobber (T001/2/3) | sound; **1 MEDIUM fixed** (P2-1 captured-section shred) |
| P3 FR-026/027 verdict integrity (T004/5/6) | sound; **1 MEDIUM fixed** (P3-1 approve-question), 1 LOW fixed (P7-1), 1 LOW carried (P3-2) |
| P4 FR-028 hook install/discovery (T010/11/12) | clean; 1 LOW carried (P4-1), 1 INFO fixed (P4-2) |
| P5 code quality / PowerShell traps | clean; **1 LOW fixed** (P5-1 decision-title regex) |
| P6 test integrity | **1 MEDIUM fixed** (P6-001 SC-016 tautology), 1 LOW fixed (P6-002), 2 INFO |
| P7 system safety / traceability / no-regression | PASS; D-001 safe-degradation independently CONFIRMED in code |

## Confirmed MEDIUM findings — FIXED with regression tests

- **P2-1 (FR-022, SC-012/015)** — `ConvertFrom-SpecrewHandoverFile` shredded the captured boundary packet when
  an inner `## ` header EXACTLY matched a canonical handover title (the section collapsed to the bare marker; a
  resume inherited a useless stub). Safe on the realistic path (the gate-stop skill's headers don't collide) —
  a latent trip-wire. **FIX**: terminal-aware captured-section parse (`HandoverStore.ps1`) — once inside the
  captured section, a `## ` closes it only on a canonical title that sorts AFTER it (none do; captured is last →
  greedy-to-EOF; self-corrects if the order grows). **Regression**: `HookPacketCapture.Tests` case 10 (colliding
  verbose canonical inner header → captured section round-trips intact, canonical section not polluted) — the
  assertion the prior suite structurally could not make.
- **P3-1 (FR-026, SC-013 — INTEGRITY)** — `Test-SpecrewHumanVerdictToken` classified approve-bearing QUESTIONS
  ("approve?", "is this ready to approve?", "can you explain before I approve?") as approvals, the one place that
  could record an authorization the human never gave. **FIX**: reject interrogatives (`$t.EndsWith('?')`) before
  the approval branch (`ConversationCaptureAccessor.ps1`). **Regression**: 4 approve-question cases added to
  `verdict-capture-blocks.tests.ps1` (→ Action='none'); HookVerdictCapture still green.
- **P6-001 (test integrity, SC-016)** — the proactive-provisioning proof was tautological on a PATH-complete
  machine (the old PATH-gated code would pass case 17 identically) — a regression guard that does not guard. The
  FEATURE is correct (the gates are genuinely removed). **FIX**: a deterministic, machine-independent guard
  (`refocus-deploy.tests.ps1` 17b) — the orchestrator MUST enumerate from `Get-SpecrewHookCapableHosts` and have
  exactly ONE `Get-Command` (the registry-fn presence check); a wholesale revert removes the registry call, any
  added host-binary `Get-Command` trips the count.

## LOW / INFO — FIXED (cheap + clearly correct)

- **P7-1 (LOW)** — "approved, no changes needed" / "no further changes required" misclassified as send-back
  (errs safe, but suppresses a legitimate approval on the only marker host). FIX: negative-lookbehind on the
  send-back "changes" clause; 2 approval cases added.
- **P5-1 (LOW)** — the T008 decision-title regex truncated dash-titles at an internal hyphen and missed em-dash.
  FIX: anchor on the `\S+` id token + `[-–—:]`; `WorkshopDecisionRecap.Tests` case 2b (em-dash + internal hyphen
  + colon).
- **P6-002 (LOW)** — SC-014 was proven only by source-grep + isolated renderer. FIX: 2 real-provider→directive
  integration cases in `pending-verdict-surface.tests.ps1` (committed≠authorized surfaces the AWAITING block;
  working==authorized does not).
- **P1-3 (INFO)** — `ProviderMirrorParity.Tests` asserted only 2 of 3 mirror copies. FIX: assert the `.specify/`
  project-side third copy too (5 providers now checked).
- **P4-2 (INFO)** — drift-log D-006 records the T012 Layer-3 surface consolidation (plan named 3 surfaces; the
  spec's Honest-residual + the build ship 1 — correct, now traceable).

## Carried (documented; surfaced for the maintainer — no code change this pass)

- **P3-2 (LOW)** — a non-canonical marker boundary token (e.g. `... -> implement`) indexes to -1; the contiguity
  math is FAIL-SAFE (never authorizes; falls to the pending re-confirm), but it is silent. Optional follow-up:
  journal a `non-canonical-marker-token` record for diagnosability. Not a fabrication risk.
- **P4-1 (LOW)** — `specrew hooks status`'s degradation-diagnostic *peek* self-suppresses in any project with a
  prior runtime trail (the session-blind `Test-SpecrewBootstrapDirectiveArrived` returns true). The integrity
  state table (missing/stale/failed) is unaffected and the helper is correct given a real SessionId; Layer 3 is a
  fallback, never the integrity mechanism. Follow-up: drive the status note off the Layer-2 state result, or
  document the session-blind limitation.
- **P1-1 (LOW)** — 8 of 28 in-range commits use `feat/fix/chore(174):` instead of `boundary(implement):`
  (all carry the Co-Authored-By trailer + name their task). Cosmetic; no rebase warranted on a 61-commit unpushed
  branch. Use the boundary prefix for the remainder.
- **P1-2 (INFO)** — the stray untracked `c:tempcommit_diff.txt` (mangled redirect) is LEFT in place per the
  maintainer's explicit instruction; it is not in any commit.
- **P6-003 / P6-004 (INFO)** — some proofs assert on exact stdout/source strings (benign: drift causes a false
  NEGATIVE, never a false pass) and the Sc012to015 aggregator is a subprocess-exit-0 orchestrator (honest today —
  each sub-proof is an independent end-to-end test). No action.

## Maintainer instructions — status

1. **D-005 accepted** — T001 stays a command (`specrew handover author`), no module export. Honored.
2. **D-001 kept visible** — the review INDEPENDENTLY confirmed in code that non-Claude hosts degrade safely to
   "awaiting verdict" (no marker → no capture → pending re-confirm; integrity-safe, liveness-incomplete). Left
   visible; **maintainer to decide** at closeout: fix host-neutral marker emission before closeout vs. fast-follow.
3. **Not closing** — the structured review is done; the **real-host re-dogfood acceptance gate** and the
   **cap-revert (`capacity_per_iteration` 32 → 20 + validator rerun)** remain. Iteration stays open.
4. **D-002/D-003/D-004 left parked** — confirmed pre-existing (not introduced by this range); no new
   host-coupling-firewall violation, no new capacity/validator break, mirror parity intact.
5. **Stray temp file** — not deleted.

## Verdict (recommendation — the maintainer's to ratify)

The iteration-011 implementation is **internally sound and review-signoff-ready** on the deterministic axis:
every confirmed defect is fixed with a regression test, the integrity guarantees (no fabricated verdict, no
gate-skip, committed≠authorized, mechanical capture/clobber) hold under adversarial probing, and 50 suites are
green. The remaining gates are the maintainer's: the **real-host re-dogfood** (the iteration-010 falsification
lesson — green synthetic tests are necessary, not sufficient) and, at closeout, the **cap-revert**.

## Closeout addendum (2026-06-14) — real-host gate ran; APPROVED + CLOSED

The maintainer ran the **real-host re-dogfood on Claude** (the gate above). It did exactly its job — it surfaced
a **host-delivery + packaging cluster the deterministic suite could not**, because the bootstrap orientation
banner did not surface on the live host:

- **P2 (HIGH, observed live):** the ~58KB SessionStart payload exceeded Claude Code v2.1.177's **10,000-char
  hook-output cap** and was silently dropped. FIX: `Get-SpecrewContractDeliveryMode` puts claude in the POINTER
  arm (contract on disk, not inlined) + a new `Limit-SpecrewInlineBlock` bounds the variable inlined blocks; a
  dispatcher `PAYLOAD_OVERSIZE` WARN added (observability only). Commit `f76014a7`.
- **P1 (clean-install foot-gun):** both providers now resolve bootstrap components from the newest module that
  ACTUALLY CONTAINS `scripts/internal/bootstrap`, not blindly newest. Commit `f76014a7`.
- **`$null.Count` StrictMode crash (the actual banner blocker):** the pre-existing T008 idiom
  `$decisions = if(..){@($v)}else{@()}` collapsed an empty `@()` to `$null` under StrictMode-Latest, so
  `$decisions.Count` THREW on a workshop with done lenses but no parseable decision summaries → empty directive →
  no banner. FIX: direct-assignment; the extraction tests now run under StrictMode + a regression case reproduces
  the exact shape. Commit `9d3564f2`.
- A **2nd Proposal-145 multi-agent review** (5 confirmed / 6 refuted, adversarially verified) drove RES-1
  (interpretive-first handover budget), RES-3 (name every decided lens), INT-1 (real verdict-message test),
  REG-1 (bootstrap suite now CI-gated), and surfaced **CAP-1** (deferred).
- **Real-host result: the banner now SURFACES on Claude** (maintainer-confirmed) — the previously-failing
  acceptance gate now PASSES. Full bootstrap suite 45/45 + integration green.

**Deferred follow-ups (recorded, not in this iteration):** **CAP-1** — the bootstrap + refocus SessionStart
fragments don't compose under 10K at their budget ceilings; the structural fix is a dispatcher fragment-priority
drop (drift D-007, proposal candidate). **Silent-failure hardening** — the provider emits nothing on a swallowed
error, which hid the two bugs above (drift D-008, proposal candidate). **D-001** — host-neutral verdict-marker
emission: **fast-follow** (integrity-safe today; only cross-host liveness is missing).

**Maintainer instruction updates:** #2 (D-001) — **decided: fast-follow**. #3 — the real-host gate + the
cap-revert (`capacity_per_iteration` 32→20, obligation DISCHARGED) are both now done; **iteration CLOSED**.

## Verdict — APPROVED + CLOSED (maintainer, 2026-06-14)

**APPROVE** iteration 011 and CLOSE it. The DF-3/4/5/7 verdict-integrity cluster + the FR-028 hook hardening are
sound and green; the real-host gate ran, found the host-delivery cluster, and that cluster is fixed with the
banner confirmed surfacing on Claude. Iteration 007 is closed (abandoned-superseded) at the same closeout.
F-174 the feature stays OPEN. **Honest residual:** "banner surfaces on Claude" was confirmed on the dev-tree
resolved setup; the published-beta install validation is a later feature-closeout gate. No push/PR/merge performed.
