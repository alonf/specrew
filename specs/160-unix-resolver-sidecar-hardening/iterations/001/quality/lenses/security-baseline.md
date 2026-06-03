# Lens Evidence: security-baseline@v1.0.0 — Iteration 001

**Verdict**: pass
**Recorded**: 2026-06-03

## Concern under review

Runtime deployment writes agent/runtime files that may be user-owned; the
`.specrew-managed` marker is the trust boundary deciding refresh-from-canonical
vs preserve-user-edits. The fix must never make user-authored content deletable.

## Evidence

- **User-data guard proven**: fixture Case D (both generic and slash kinds) —
  genuinely user-edited front-matter content with no marker stays NOT-managed
  (preserved) before AND after the fix. The fix only adds a managed
  classification for content that byte-matches (ordinal) the definition's
  canonical content, i.e. content with zero user customization.
- **No new privileged operations**: the resolver fix changes path construction
  only; no new file writes, deletes, network access, or elevation paths.
- **No secrets surface**: neither fix touches credentials, tokens, or secret
  storage; no sensitive values logged.
- **Fixtures isolated**: all test fixtures run in `$env:TEMP` scratch dirs with
  GUID names and are removed in `finally`; no writes into `.squad`/`.codex`/
  `.cursor`/`.claude`/`.agents`/`.specrew` runtime dirs.
- **Conservative default retained**: ambiguous content (front matter that does
  not match canonical) still resolves to preserve — the safe direction against
  data loss.
