# Iteration 004 Review (review-signoff)

**Feature**: 197-continuous-co-review
**Iteration**: 004 (Phase B part 1 — #2885 latency fix + opt-in gate enforcement wiring)
**Date**: 2026-06-23
**Reviewers**: two adversarial, read-only, fresh-context Proposal-145 reviewers (one per change
surface), each told to BREAK the work, then the lead synthesized + remediated.
**Overall Verdict**: accepted

## Review approach

- **Reviewer A** — T070 (#2885 parse-once refactor) correctness/regression: byte-identical
  behavior, memo leak/mutation, mtime collision, per-host `-Raw` parity, edge transcripts.
- **Reviewer B** — T073/T074 (opt-in gate wiring) security: signoff bypass, fail-open holes,
  the result-pipeline guard, fail-closed gate semantics, config-parse edge cases.

Both ran with zero repo footprint (read-only; repros in temp dirs; per-invocation git identity
in throwaway repos only; the real repo's git config + authorship untouched — verified).

## Reviewer A (T070) — PASS, no blocker/major; 2 MINOR (both fixed)

Verified byte-identical by dot-sourcing the PRE-refactor function from git and diffing the split
(finalize-flag parity confirmed: verdict/packet `-Raw`, tail flatten), and proved parse-once
non-vacuously (3 consumers = 1 parse; warm stop = 0). Closed the advisor's "byte-identical with
an LLM?" concern empirically (a 3-line human approval round-trips with newlines intact).

- **A-MINOR-1 (diagnostic-only):** a zero-byte transcript now reports `Reason='no-turns'` where
  the pre-refactor path reported `'empty'`. `'empty'` is consumed by NO branch (both give
  `Found=$false`), so behavior is unchanged — but the code comment claiming byte-identical was
  inaccurate. **FIXED:** comment corrected to state the diagnostic-only delta honestly.
- **A-MINOR-2 (out-of-band):** a same-mtime-tick stale cache is reproducible only by manually
  pinning the timestamp; real Stop rewrites advance the tick (sub-ms NTFS). **FIXED:** added a
  mtime-resolution assumption note to the memo.

## Reviewer B (T073/T074) — NEEDS-WORK -> 1 MAJOR (fixed) + 2 MINOR; all bypass probes CLEAN

The security core was confirmed sound — **all five bypass/fail-open probes found NO defect**:
no raw-alias bypass (`$BoundaryType` is canonical at the call site, resolved before line 1514);
no deployment fail-open (the extensions copy is a dispatcher shim, not a logic mirror); the
result-pipeline guard holds (`[void]` + `| Out-Null`); fail-CLOSED on
digest/anchor/empty/stale/coverage; the override allow-branch is unreachable via the wired path.

- **B-MAJOR (F1, verdict driver):** the opt-in flag parser silently dropped standard YAML idioms
  — `co_review_gate_enforcement: true  # comment`, `'true'` (single-quoted), and `"true" # on`
  all parsed as OFF when the operator intended ON (fail-open-to-intent on a governance gate). It
  had REGRESSED against the sibling `specrew_version` reader in the same repo reading the same
  `config.yml`. **FIXED:** adopted the proven sibling pattern
  (`['"]?(?<value>[^'"#]+?)['"]?\s*(?:#.*)?$`) + added 4 parse-edge regression tests (the three
  enabling idioms now enable; `false # comment` stays off). Re-verified: signoff-gate-wiring 16/0.
- **B-MINOR (F2, fail-SAFE):** a `co_review_gate_enforcement: true` nested under an unrelated
  parent over-matches (the line-based read has no YAML nesting awareness). It fails SAFE (spurious
  BLOCK, not bypass) and is consistent with the established line-based config readers
  (`Get-SessionMode`, `specrew_version`). **ACCEPTED** — adding YAML nesting for one flag would
  diverge from the repo standard; documented.
- **B-MINOR (F3):** duplicate keys resolve first-wins (vs YAML last-wins) — malformed input many
  parsers reject. **NOTED**, no verdict weight.
- **Non-blocking note:** the wiring uses the default `TrunkName='main'`; a non-`main`-trunk repo
  fails CLOSED (`anchor-unresolvable` -> block), a robustness nit not a bypass. Follow-up if
  non-`main`-trunk projects enter scope for the opt-in.

## Remediation re-verification

- `signoff-gate-wiring.Tests.ps1`: **16/0** (12 original + 4 F1 parse-edge).
- `transcript-parse-once.Tests.ps1`: **28/0** (T070 comment edits behavior-neutral).
- Full continuous-co-review suite remained green; both edited files parse clean.

## Task Verdicts

| Task | Verdict | Evidence |
| ---- | ------- | -------- |
| T070 | pass | #2885 parse-once-and-share refactor of `ConversationCaptureAccessor.ps1` (commit `18777769`, +207 lines); Reviewer A verified byte-identical, 2 MINORs fixed (comment-honesty `384b472d`); 75.5% latency win recorded. |
| T071 | pass | DEFERRED BY DESIGN, no work owed: the conformance-provider memo was measured-unwarranted and subsumed (commit `33964d15`) — the early-exit ~10 ms read would regress vs a forced full-parse; plan.md status = deferred, -1.50 SP. Reviewed: the deferral is sound (verdict `pass` = no concern with the disposition; the task was intentionally not executed). |
| T072 | pass | `transcript-parse-once.Tests.ps1` added (commit `18777769`, +227 lines + goldens; goldens LF-pinned in `32480eaa`); parse-once correctness + timing/regression guard; suite 28/0. |
| T073 | pass | Opt-in signoff gate wired into `sync-boundary-state.ps1` via `signoff-gate-wiring.ps1` (commit `a36f67e2`); Reviewer B bypass/fail-open probes all clean; B-MAJOR F1 config-parser regression fixed (`384b472d`). |
| T074 | pass | `signoff-gate-wiring.Tests.ps1` added (commit `a36f67e2`, +158 lines) + 4 F1 parse-edge regressions (`384b472d`); flag ON refuses without fresh evidence, OFF no-ops; suite 16/0. |
| T075 | pass | Closeout-validation banked (`closeout-validation.md`, commit `916e43af`); full suite 192/0, no F-184 protected-surface edits, Proposal 145 review with 1 MAJOR caught+fixed; iteration formally closed `cdc9d7f8`. |

## Gap Ledger

- A-MINOR-1 (byte-identical comment inaccurate — a zero-byte transcript reports `no-turns` vs the pre-refactor `empty`, behavior unchanged): fixed-now, comment corrected to state the diagnostic-only delta honestly.
- A-MINOR-2 (same-mtime-tick stale cache, reproducible only by manually pinning the timestamp): fixed-now, mtime-resolution assumption note added to the memo.
- B-MAJOR F1 (opt-in flag parser dropped standard YAML idioms — quoted/commented `true` parsed as OFF → fail-open-to-intent on a governance gate): fixed-now, adopted the proven sibling reader pattern + 4 parse-edge regression tests (`384b472d`); signoff-gate-wiring 16/0.

## Carried / Accepted (not iteration-004 gaps)

- B-MINOR F2 (nested `co_review_gate_enforcement: true` over-matches): accepted — it fails SAFE (spurious block, not a bypass) and is consistent with the repo's other line-based config readers; documented.
- B-MINOR F3 (duplicate keys resolve first-wins vs YAML last-wins): noted — malformed input that many parsers reject; no verdict weight.
- Non-blocking TrunkName default (`main`): a non-`main`-trunk repo fails CLOSED (`anchor-unresolvable` → block), a robustness nit not a bypass; follow-up if non-`main`-trunk projects enter scope.

## Disposition

All blocker/major findings RESOLVED (B-MAJOR F1 fixed + covered). All minors fixed, accepted
(fail-safe), or noted. The security-critical bypass/fail-open surface was probed by an adversarial
reviewer and found clean. **Iteration 004 is review-signoff ready.**
