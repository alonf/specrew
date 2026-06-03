# Lens Evidence: robustness-baseline@v1.0.0 — Iteration 001

**Verdict**: pass
**Recorded**: 2026-06-03

## Concern under review

Resolver fallback to installed modules and marker-based preserve decisions must
not silently hide stale or wrong behavior; failure/fallback semantics must be
explicit.

## Evidence

- **Resolver fallback chain unchanged and explicit**: Path 0 (env override) →
  Path 1 (dev-tree walk-up) → Path 2 (installed module) → actionable throw. The
  fix makes each candidate POSIX-safe; precedence and the stale-install guard are
  untouched (Proposal 160 non-goal honored).
- **Windows symptom root-caused, not papered over**: the installed-over-dev-tree
  resolution observed during F-140 closeout (and live in this iteration) is the
  `$env:SPECREW_MODULE_PATH` override selecting Path 0 by design — documented in
  `../../investigation-evidence.md`, no behavior change required.
- **Edge inputs guarded in the sidecar fix**: missing `CurrentContent`/
  `LegacyContent` properties (slash-command definitions carry no LegacyContent)
  are probed via `PSObject.Properties.Name`; null/empty canonical content is
  excluded; comparisons are ordinal (culture/case-insensitivity cannot produce a
  false managed match).
- **Environment-blocked path exercised in design**: no live Unix host exists in
  this workspace; rather than guessing, the deterministic fixture proves the
  POSIX semantics host-independently, and the test's POSIX branch runs for real
  on the Ubuntu CI lane (wired into `specrew-ci.yml` deterministic-gate).
- **Live end-to-end proof**: the fixed wrapper executed a full boundary-sync on
  Windows (identical-boundary re-sync, success:true) — no regression in the real
  consumer path.
