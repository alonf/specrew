# Iteration 004 Review (review-signoff)

**Feature**: 197-continuous-co-review
**Iteration**: 004 (Phase B part 1 — #2885 latency fix + opt-in gate enforcement wiring)
**Date**: 2026-06-23
**Reviewers**: two adversarial, read-only, fresh-context Proposal-145 reviewers (one per change
surface), each told to BREAK the work, then the lead synthesized + remediated.

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

## Disposition

All blocker/major findings RESOLVED (B-MAJOR F1 fixed + covered). All minors fixed, accepted
(fail-safe), or noted. The security-critical bypass/fail-open surface was probed by an adversarial
reviewer and found clean. **Iteration 004 is review-signoff ready.**
