# Iteration 006 Review (Proposal 145)

**Feature**: 197-continuous-co-review
**Iteration**: 006 (real reviewer + full-findings reporting)
**Date**: 2026-06-24
**Reviewer**: one adversarial, read-only, fresh-context reviewer; zero repo footprint (git identity
clean, zero commits authored).
**Overall Verdict**: accepted (the NEEDS-WORK MAJOR + minor are both FIXED)

## Verdict trail

The reviewer returned **NEEDS-WORK** with one MAJOR (M1) + two minor (M2, M3); the maintainer chose
Option 1 (fix M1 + M2, then the live e2e). Both are now fixed.

## M1 (MAJOR) — code-writer-independence not wired end-to-end — FIXED `ecf7c768`

The headline "code-writer-independent" selection's independence depended on `$codeWriterHost`, read from
`SPECREW_HOST`/`SPECREW_ACTIVE_HOST` — which **Specrew never sets**. The dispatcher passed `--host-kind`
to the provider, but the provider DISCARDED it, so in production `$codeWriterHost=$null` -> the policy
tiebroke alphabetically -> could pick **claude to review claude's own code**. It held only by
authorization config (codex-only authorized), not by logic. Empirically demonstrated both legs.

**FIX:** the provider (both copies) threads `--host-kind` -> the navigator's new `-CodeWriterHost` param
-> `New-...ReviewerPlan` -> the policy; `SPECREW_HOST`/`SPECREW_ACTIVE_HOST` are fallback-only.
Independence is now real-by-logic. A param-path test proves it with the env UNSET (the production
reality). 233/0 CCR, provider copies in sync.

## M2 (minor) — non-hermetic CONTROL test — FIXED `ecf7c768`

The real-guard CONTROL test snapshotted the LIVE Specrew repo, so concurrent writes between the guard's
before/after snapshots flipped `mutated` true (the iter-005 hermeticity lesson). FIXED to a hermetic
throwaway git repo.

## M3 (minor, out of scope) — the `probe`-authored commits

The known pre-existing main blemish (F-185), already documented in iterations/VALIDATOR-LAG.md and the
iter-005 review; accept + document, do not rewrite protected main. Branch-history hygiene at feature-closeout.

## Probed — no defect (the reviewer's evidence)

A **21/21 no-mocks durability+surfacing harness through the real writer** confirms the core requirement:
all severities persist unfiltered; run_id normalizes to the registry id; blackboard + gate record
co-locate; stub writes nothing; malformed FindingsResult writes nothing and does not throw; the surfaced
ref equals the on-disk dir; the inline thread survives the pending cleanup; promotion is
affirmative-pass-only. Plus: the mutation-guard SKIP is honest (explicit posture marker, not silent);
Hazards A (module-base in the detached worktree) + B (candidate threading, Win+Linux) resolved;
fail-OPEN (never fail-closed, never a stub); the 300s timeout applied to both the navigator + the adapter
per-candidate legs; no reap-ordering regression.

## Disposition

The NEEDS-WORK MAJOR (M1) + minor (M2) are FIXED and verified (233/0 CCR). The delivered real reviewer +
full-findings reporting is sound. **The one remaining acceptance step is the LIVE-dispatcher
multi-severity e2e** (codex) — the meaningful proof that real findings land durably AND surface to the
developer through the live hook path. Recorded in closeout-validation.md.
